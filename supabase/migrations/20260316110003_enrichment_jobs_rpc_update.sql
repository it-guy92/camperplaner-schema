-- Migration: Update RPC Functions for Enrichment Jobs Typed Columns
-- Date: 2026-03-16
-- Purpose: Update RPC functions to support new typed operational columns while maintaining backward compatibility
--          Part of Phase 1 compatibility layer for queue/job-type safety
-- 
-- IDEMPOTENCY NOTE: This migration is fully idempotent and can be replayed multiple times
-- without errors. It uses CREATE OR REPLACE, IF NOT EXISTS, and DO $$ EXCEPTION patterns.

-- ============================================
-- 0. ENSURE DEPENDENCIES EXIST (Idempotent)
-- ============================================
-- These guards ensure the migration can run on fresh databases or be replayed safely

-- Create enum type if it doesn't exist (PostgreSQL doesn't support IF NOT EXISTS for types)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'enrichment_job_type_enum') THEN
        CREATE TYPE enrichment_job_type_enum AS ENUM (
            'enrich_llm',
            'refresh_data',
            'sync_external',
            'cleanup_old'
        );
        RAISE NOTICE 'Created enrichment_job_type_enum type';
    ELSE
        RAISE NOTICE 'enrichment_job_type_enum type already exists';
    END IF;
END $$;

COMMENT ON TYPE enrichment_job_type_enum IS 
'Enumeration of supported enrichment job types. Used by queue system for type safety.';

-- Create enrichment_jobs table if it doesn't exist
-- This provides order-independence: migration can run before or after typed_columns migration
CREATE TABLE IF NOT EXISTS enrichment_jobs (
    id SERIAL PRIMARY KEY,
    place_id INTEGER NOT NULL,
    job_type enrichment_job_type_enum NOT NULL,
    priority INTEGER NOT NULL DEFAULT 0,
    payload JSONB NOT NULL DEFAULT '{}',
    context JSONB NOT NULL DEFAULT '{}',
    freshness_bucket TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    max_attempts INTEGER NOT NULL DEFAULT 3,
    run_after TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'queued',
    attempts INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    locked_by TEXT,
    locked_at TIMESTAMPTZ,
    lease_expires_at TIMESTAMPTZ,
    error_message TEXT,
    dead_lettered_at TIMESTAMPTZ,
    heartbeat_at TIMESTAMPTZ,
    -- Typed operational columns (Phase 1)
    worker_id TEXT,
    attempt_number INTEGER DEFAULT 0,
    last_error_code TEXT,
    last_error_message TEXT,
    last_error_at TIMESTAMPTZ,
    canonical_place_id UUID,
    metadata JSONB DEFAULT '{}',
    classification TEXT,
    source_state TEXT
);

COMMENT ON TABLE enrichment_jobs IS 
'Queue table for enrichment jobs. Supports LLM enrichment, data refresh, and external sync operations.';

-- ============================================
-- 0.5 ENSURE ALL COLUMNS EXIST (Idempotent)
-- ============================================
-- These guards ensure all base columns exist regardless of migration run order
-- Safe to run multiple times - columns are only added if missing
-- This makes the migration order-independent with typed_columns migration

-- Base queue columns (ensure table can work even if created with minimal schema)
ALTER TABLE enrichment_jobs
    ADD COLUMN IF NOT EXISTS place_id INTEGER,
    ADD COLUMN IF NOT EXISTS job_type enrichment_job_type_enum,
    ADD COLUMN IF NOT EXISTS priority INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS payload JSONB DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS context JSONB DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS freshness_bucket TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS max_attempts INTEGER DEFAULT 3,
    ADD COLUMN IF NOT EXISTS run_after TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'queued',
    ADD COLUMN IF NOT EXISTS attempts INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS locked_by TEXT,
    ADD COLUMN IF NOT EXISTS locked_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS lease_expires_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS error_message TEXT,
    ADD COLUMN IF NOT EXISTS dead_lettered_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS heartbeat_at TIMESTAMPTZ;

-- Typed operational columns (Phase 1) - order-independent guards
ALTER TABLE enrichment_jobs 
    ADD COLUMN IF NOT EXISTS classification TEXT,
    ADD COLUMN IF NOT EXISTS source_state TEXT,
    ADD COLUMN IF NOT EXISTS worker_id TEXT,
    ADD COLUMN IF NOT EXISTS attempt_number INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS last_error_code TEXT,
    ADD COLUMN IF NOT EXISTS last_error_message TEXT,
    ADD COLUMN IF NOT EXISTS last_error_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS canonical_place_id UUID,
    ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';

-- Add comments for typed columns (idempotent - comments are replaced)
COMMENT ON COLUMN enrichment_jobs.classification IS 
'Error or failure classification (e.g., "rate_limit", "timeout", "validation_error"). Used for filtering and dashboards.';

COMMENT ON COLUMN enrichment_jobs.source_state IS 
'Source-specific processing state (e.g., "fetched", "enriched", "failed_validation"). Provides granular job tracking.';

COMMENT ON COLUMN enrichment_jobs.worker_id IS 
'Identifier of the worker that claimed this job (e.g., "worker-coolify-001"). Used for debugging and worker attribution.';

COMMENT ON COLUMN enrichment_jobs.attempt_number IS 
'Current attempt count for this job execution. Supports detailed retry tracking.';

COMMENT ON COLUMN enrichment_jobs.last_error_code IS 
'Machine-readable error code (e.g., "OPENAI_RATE_LIMIT", "VALIDATION_FAILED"). Enables programmatic error handling.';

COMMENT ON COLUMN enrichment_jobs.last_error_message IS 
'Human-readable error message for debugging and monitoring dashboards.';

COMMENT ON COLUMN enrichment_jobs.last_error_at IS 
'Timestamp of the last error occurrence. Used for error tracking and retry timing analysis.';

COMMENT ON COLUMN enrichment_jobs.canonical_place_id IS 
'Canonical UUID reference for the place being enriched. Supports queue flow and cross-reference tracking.';

COMMENT ON COLUMN enrichment_jobs.metadata IS 
'Optional metadata bridge column for non-operational data. Operational data should use typed columns.';

-- ============================================
-- 0.6 ENSURE INDEXES EXIST (Idempotent)
-- ============================================

CREATE INDEX IF NOT EXISTS idx_enrichment_jobs_worker_id 
ON enrichment_jobs(worker_id) 
WHERE worker_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_enrichment_jobs_classification 
ON enrichment_jobs(classification) 
WHERE classification IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_enrichment_jobs_attempt_number 
ON enrichment_jobs(attempt_number) 
WHERE attempt_number > 0;

CREATE INDEX IF NOT EXISTS idx_enrichment_jobs_status_classification 
ON enrichment_jobs(status, classification) 
WHERE classification IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_enrichment_jobs_canonical_place_id 
ON enrichment_jobs(canonical_place_id) 
WHERE canonical_place_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_enrichment_jobs_status_priority 
ON enrichment_jobs(status, priority DESC, created_at ASC) 
WHERE status = 'queued';

-- ============================================
-- 1. UPDATE enqueue_enrichment_job FUNCTION
-- ============================================
-- Adds optional parameters for new typed columns
-- All new parameters have defaults for backward compatibility

CREATE OR REPLACE FUNCTION enqueue_enrichment_job(
    -- Existing parameters (unchanged for compatibility)
    p_place_id INTEGER,
    p_job_type enrichment_job_type_enum,
    p_priority INTEGER DEFAULT 0,
    p_payload JSONB DEFAULT '{}',
    p_context JSONB DEFAULT '{}',
    p_freshness_window TEXT DEFAULT '24 hours',
    p_max_attempts INTEGER DEFAULT 3,
    p_run_after TIMESTAMPTZ DEFAULT NOW(),
    -- New optional parameters for typed columns (Phase 1 additive)
    p_classification TEXT DEFAULT NULL,
    p_source_state TEXT DEFAULT NULL,
    p_canonical_place_id UUID DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'
)
RETURNS enrichment_jobs
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_freshness_bucket TIMESTAMPTZ;
    v_job enrichment_jobs;
BEGIN
    -- Calculate freshness bucket from window (returns timestamptz)
    v_freshness_bucket := CASE 
        WHEN p_freshness_window = '1 hour' THEN NOW() + INTERVAL '1 hour'
        WHEN p_freshness_window = '6 hours' THEN NOW() + INTERVAL '6 hours'
        WHEN p_freshness_window = '12 hours' THEN NOW() + INTERVAL '12 hours'
        WHEN p_freshness_window = '24 hours' THEN NOW() + INTERVAL '24 hours'
        WHEN p_freshness_window = '7 days' THEN NOW() + INTERVAL '7 days'
        WHEN p_freshness_window = '30 days' THEN NOW() + INTERVAL '30 days'
        ELSE NOW() + INTERVAL '24 hours'
    END;

    -- Insert the job with all columns
    INSERT INTO enrichment_jobs (
        place_id,
        job_type,
        priority,
        payload,
        context,
        freshness_bucket,
        max_attempts,
        run_after,
        status,
        attempts,
        created_at,
        updated_at,
        -- New typed columns
        classification,
        source_state,
        canonical_place_id,
        metadata
    ) VALUES (
        p_place_id,
        p_job_type,
        p_priority,
        p_payload,
        p_context,
        v_freshness_bucket,
        p_max_attempts,
        p_run_after,
        'queued',
        0,
        NOW(),
        NOW(),
        -- New typed column values
        p_classification,
        p_source_state,
        p_canonical_place_id,
        COALESCE(p_metadata, '{}')
    )
    RETURNING * INTO v_job;

    RETURN v_job;
END;
$$;

COMMENT ON FUNCTION enqueue_enrichment_job IS 
'Creates a new enrichment job with optional typed operational columns.
Backward compatible: existing callers using only original parameters continue to work.
New typed columns (classification, source_state, canonical_place_id, metadata) are optional.
Idempotent: Function can be replaced without affecting existing data.';

-- ============================================
-- 2. UPDATE claim_enrichment_jobs FUNCTION
-- ============================================
-- Returns all columns including new typed columns automatically
-- This function uses RETURN TABLE/SELECT * which automatically includes new columns

CREATE OR REPLACE FUNCTION claim_enrichment_jobs(
    p_worker_id TEXT,
    p_limit INTEGER DEFAULT 1,
    p_lease_seconds INTEGER DEFAULT 300
)
RETURNS SETOF enrichment_jobs
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_lease_until TIMESTAMPTZ;
BEGIN
    v_lease_until := NOW() + (p_lease_seconds || ' seconds')::INTERVAL;

    RETURN QUERY
    WITH claimed_jobs AS (
        UPDATE enrichment_jobs
        SET
            status = 'running',
            locked_by = p_worker_id,
            locked_at = NOW(),
            lease_expires_at = v_lease_until,
            worker_id = p_worker_id,  -- Set the worker_id typed column
            updated_at = NOW()
        WHERE id IN (
            SELECT id
            FROM enrichment_jobs
            WHERE status = 'queued'
                AND run_after <= NOW()
                AND (locked_by IS NULL OR lease_expires_at < NOW())
                AND attempts < max_attempts
            ORDER BY
                priority DESC,
                created_at ASC
            LIMIT p_limit
            FOR UPDATE SKIP LOCKED
        )
        RETURNING *
    )
    SELECT * FROM claimed_jobs
    ORDER BY priority DESC, created_at ASC;
END;
$$;

COMMENT ON FUNCTION claim_enrichment_jobs IS
'Claims up to p_limit queued enrichment jobs for the specified worker.
Sets status to running, assigns lease, and returns all job data including new typed columns.
Automatically includes new columns (classification, source_state, worker_id, etc.) via RETURN TABLE pattern.
Idempotent: Function can be replaced without affecting existing data.';

-- ============================================
-- 3. UPDATE complete_enrichment_job TO WRITE TYPED COLUMNS
-- ============================================
-- This function now writes typed operational columns from context_patch
-- while maintaining backward compatibility with the existing signature

CREATE OR REPLACE FUNCTION complete_enrichment_job(
    p_job_id INTEGER,
    p_worker_id TEXT,
    p_context_patch JSONB DEFAULT '{}'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_classification TEXT;
    v_source_state TEXT;
    v_attempt_number INTEGER;
    v_metadata JSONB;
BEGIN
    -- Extract typed fields from context_patch if present
    v_classification := p_context_patch->>'classification';
    v_source_state := p_context_patch->>'source_state';
    v_attempt_number := (p_context_patch->>'attempt_number')::INTEGER;
    v_metadata := p_context_patch->'metadata';

    UPDATE enrichment_jobs
    SET 
        status = 'done',
        locked_by = NULL,
        locked_at = NULL,
        lease_expires_at = NULL,
        error_message = NULL,
        context = context || p_context_patch,
        updated_at = NOW(),
        -- Write typed operational columns from context_patch
        worker_id = p_worker_id,
        attempt_number = COALESCE(v_attempt_number, attempt_number, 0),
        classification = COALESCE(v_classification, classification),
        source_state = COALESCE(v_source_state, source_state),
        metadata = COALESCE(v_metadata, metadata, '{}')
    WHERE id = p_job_id
        AND locked_by = p_worker_id
        AND status = 'running';

    RETURN FOUND;
END;
$$;

COMMENT ON FUNCTION complete_enrichment_job IS 
'Marks an enrichment job as completed by the specified worker.
Writes typed operational columns (worker_id, attempt_number, classification, source_state, metadata)
from context_patch values to enable filtering and dashboards.
Preserves backward compatibility - signature unchanged.
Merges context_patch into existing context JSONB.
Idempotent: Function can be replaced without affecting existing data.';

-- ============================================
-- 4. ENSURE fail_enrichment_job UPDATES TYPED COLUMNS
-- ============================================
-- This function signature is unchanged but we update implementation
-- to properly set new typed columns for error tracking

CREATE OR REPLACE FUNCTION fail_enrichment_job(
    p_job_id INTEGER,
    p_worker_id TEXT,
    p_error_message TEXT,
    p_context_patch JSONB DEFAULT '{}',
    p_retry_delay_seconds INTEGER DEFAULT 60
)
RETURNS enrichment_jobs
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_job enrichment_jobs;
    v_new_attempts INTEGER;
    v_should_dead_letter BOOLEAN;
BEGIN
    -- Get current job state
    SELECT * INTO v_job
    FROM enrichment_jobs
    WHERE id = p_job_id AND locked_by = p_worker_id;

    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    v_new_attempts := v_job.attempts + 1;
    v_should_dead_letter := v_new_attempts >= v_job.max_attempts;

    UPDATE enrichment_jobs
    SET 
        status = CASE WHEN v_should_dead_letter THEN 'dead' ELSE 'queued' END,
        attempts = v_new_attempts,
        attempt_number = v_new_attempts,
        error_message = p_error_message,
        last_error_message = p_error_message,
        last_error_at = NOW(),
        locked_by = NULL,
        locked_at = NULL,
        lease_expires_at = NULL,
        dead_lettered_at = CASE WHEN v_should_dead_letter THEN NOW() ELSE NULL END,
        run_after = CASE 
            WHEN v_should_dead_letter THEN run_after
            ELSE NOW() + (p_retry_delay_seconds || ' seconds')::INTERVAL
        END,
        context = context || p_context_patch,
        -- Extract error code from message if it follows pattern "CODE: message"
        last_error_code = CASE 
            WHEN p_error_message ~ '^[A-Z_]+:' THEN split_part(p_error_message, ':', 1)
            ELSE NULL
        END,
        -- Extract classification and source_state from context_patch for typed columns
        classification = COALESCE(p_context_patch->>'classification', classification),
        source_state = COALESCE(p_context_patch->>'sourceState', p_context_patch->>'source_state', source_state),
        worker_id = p_worker_id,
        updated_at = NOW()
    WHERE id = p_job_id
        AND locked_by = p_worker_id
    RETURNING * INTO v_job;

    RETURN v_job;
END;
$$;

COMMENT ON FUNCTION fail_enrichment_job IS 
'Marks an enrichment job as failed by the specified worker.
Preserves backward compatibility - signature unchanged.
Automatically updates typed columns (attempt_number, last_error_message, last_error_code, classification, source_state, worker_id).
Extracts classification and source_state from context_patch JSONB.
Returns the updated job row including all typed columns.
Idempotent: Function can be replaced without affecting existing data.';

-- ============================================
-- 5. HEARTBEAT FUNCTION (UNCHANGED SIGNATURE)
-- ============================================
-- Heartbeat behavior is preserved - only extends lease

CREATE OR REPLACE FUNCTION heartbeat_enrichment_job(
    p_job_id INTEGER,
    p_worker_id TEXT,
    p_lease_extension_seconds INTEGER DEFAULT 300
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE enrichment_jobs
    SET 
        heartbeat_at = NOW(),
        lease_expires_at = NOW() + (p_lease_extension_seconds || ' seconds')::INTERVAL,
        updated_at = NOW()
    WHERE id = p_job_id
        AND locked_by = p_worker_id
        AND status = 'running';

    RETURN FOUND;
END;
$$;

COMMENT ON FUNCTION heartbeat_enrichment_job IS 
'Extends the lease on a running enrichment job.
Preserves backward compatibility - signature unchanged.
Updates heartbeat_at and extends lease_expires_at.
Idempotent: Function can be replaced without affecting existing data.';

-- ============================================
-- 6. BACKWARD COMPATIBILITY VERIFICATION
-- ============================================

-- Verify function signatures are preserved:
-- SELECT proname, proargnames, proargtypes::regtype[]::text
-- FROM pg_proc
-- WHERE proname IN ('enqueue_enrichment_job', 'claim_enrichment_jobs', 
--                   'complete_enrichment_job', 'fail_enrichment_job', 
--                   'heartbeat_enrichment_job')
-- ORDER BY proname;

-- Verify claim_enrichment_jobs returns all columns:
-- SELECT * FROM claim_enrichment_jobs('test-worker', 0) LIMIT 0;
-- \d enrichment_jobs

-- ============================================
-- 7. MIGRATION COMPLETE
-- ============================================
-- RPC functions updated with:
-- - enqueue_enrichment_job: New optional typed column params added
-- - claim_enrichment_jobs: Returns all columns including new typed columns
-- - complete_enrichment_job: Signature unchanged, implementation preserves context
-- - fail_enrichment_job: Signature unchanged, implementation updates typed columns
-- - heartbeat_enrichment_job: Completely unchanged
-- 
-- All existing callers remain compatible:
-- - Product callers using enrich_llm job type continue to work
-- - Worker claim/fail/heartbeat flows remain compatible
-- - RPC signatures are backward compatible (new params have defaults)
-- 
-- IDEMPOTENCY GUARANTEES:
-- - Enum created only if not exists (via DO $$ EXCEPTION block)
-- - Table created only if not exists
-- - Columns added only if not exists
-- - Indexes created only if not exists
-- - Functions use CREATE OR REPLACE
-- - This migration can be replayed any number of times without errors
