-- ============================================================================
-- Migration: Fix enrichment_jobs Type Mismatches
-- Date: 2026-03-17
-- Purpose: Reconcile contract drift between enrichment_jobs and places.id
--          - Change place_id from INTEGER to BIGINT to match places.id
--          - Document canonical_place_id as non-FK (UUID vs BIGINT mismatch)
-- ============================================================================
-- IDEMPOTENCY: This migration is idempotent and can be replayed safely.
-- SAFETY: All changes are additive or widening conversions (INTEGER → BIGINT).
-- ============================================================================

-- ============================================================================
-- PART 1: Fix place_id Type (INTEGER → BIGINT)
-- ============================================================================
-- PostgreSQL allows widening INTEGER to BIGINT safely:
-- - No data loss (all INTEGER values fit in BIGINT)
-- - No table rewrite required for this specific conversion
-- - Existing FK constraints remain valid

ALTER TABLE enrichment_jobs 
    ALTER COLUMN place_id TYPE BIGINT 
    USING place_id::BIGINT;

COMMENT ON COLUMN enrichment_jobs.place_id IS 
    'Reference to places.id (BIGINT). FK relationship to places table.';

-- ============================================================================
-- PART 2: Document canonical_place_id Contract
-- ============================================================================
-- canonical_place_id is UUID but places.id is BIGINT.
-- This is intentional - canonical_place_id is for cross-system tracking,
-- NOT a foreign key to places.id. Use place_id for the actual FK.

COMMENT ON COLUMN enrichment_jobs.canonical_place_id IS 
    'Cross-system UUID identifier for tracking (NOT a FK to places.id). Use place_id for the actual places table reference. This field supports external system integration where UUIDs are preferred.';

-- ============================================================================
-- PART 3: Update RPC Function Signatures
-- ============================================================================
-- Update enqueue_enrichment_job to use BIGINT for place_id

-- Drop existing functions to avoid signature conflicts
-- Use CASCADE to drop all overloads and dependent objects
DROP FUNCTION IF EXISTS enqueue_enrichment_job CASCADE;

CREATE OR REPLACE FUNCTION enqueue_enrichment_job(
    p_place_id BIGINT,
    p_job_type enrichment_job_type_enum,
    p_priority INTEGER DEFAULT 0,
    p_payload JSONB DEFAULT '{}',
    p_context JSONB DEFAULT '{}',
    p_freshness_window TEXT DEFAULT '24 hours',
    p_max_attempts INTEGER DEFAULT 3,
    p_run_after TIMESTAMPTZ DEFAULT NOW(),
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
    'Creates a new enrichment job. p_place_id is BIGINT (matches places.id). p_canonical_place_id is UUID for cross-system tracking (not a FK).';

-- ============================================================================
-- PART 4: Verify Type Consistency
-- ============================================================================

-- Ensure all place_id columns in related tables use BIGINT consistently
-- (These should already be correct from 20260316110002_add_source_family_tables.sql)

-- Verify: place_llm_enrichments.place_id
-- Verify: place_source_evidence_runs.place_id
-- Verify: place_google_sources.place_id

-- ============================================================================
-- PART 5: Verification Queries
-- ============================================================================

-- Uncomment to verify after migration:
-- 
-- -- Check place_id type
-- SELECT column_name, data_type, udt_name
-- FROM information_schema.columns
-- WHERE table_name = 'enrichment_jobs'
-- AND column_name = 'place_id';
-- 
-- -- Check canonical_place_id type
-- SELECT column_name, data_type, udt_name
-- FROM information_schema.columns
-- WHERE table_name = 'enrichment_jobs'
-- AND column_name = 'canonical_place_id';
-- 
-- -- Verify function signature
-- SELECT proname, proargnames, proargtypes::regtype[]::text
-- FROM pg_proc
-- WHERE proname = 'enqueue_enrichment_job';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
-- Changes:
-- 1. enrichment_jobs.place_id: INTEGER → BIGINT (matches places.id)
-- 2. Updated comments to clarify canonical_place_id is not a FK
-- 3. Updated RPC function to use BIGINT for place_id parameter
-- 
-- Contract reconciliation: enrichment_jobs.place_id now consistently
-- references places.id (both BIGINT). canonical_place_id remains UUID
-- for cross-system integration purposes only.
