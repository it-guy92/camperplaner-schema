-- Migration: Add Typed Operational Columns to enrichment_jobs
-- Date: 2026-03-16
-- Purpose: Extend enrichment_jobs with typed operational columns per worker proposal section 4.C.1
--          These columns support filtering, retry logic, and dashboards while preserving context JSONB
--
-- IDEMPOTENCY NOTE: This migration uses IF NOT EXISTS patterns and can be replayed safely.
-- Table creation is guarded to ensure this migration can run before or after RPC migration.

-- ============================================
-- 0. ENSURE TABLE EXISTS (Idempotent Guard)
-- ============================================
-- This guard allows this migration to run even if the RPC migration hasn't run yet
-- or if running on a fresh database. All operations use IF NOT EXISTS.

CREATE TABLE IF NOT EXISTS enrichment_jobs (
    id SERIAL PRIMARY KEY
);

-- ============================================
-- 1. ADD NEW TYPED OPERATIONAL COLUMNS
-- ============================================

-- Classification: Error/failure classification for filtering and dashboards
ALTER TABLE enrichment_jobs 
ADD COLUMN IF NOT EXISTS classification TEXT;

COMMENT ON COLUMN enrichment_jobs.classification IS 
'Error or failure classification (e.g., "rate_limit", "timeout", "validation_error"). Used for filtering and dashboards.';

-- Source State: Source processing state tracking
ALTER TABLE enrichment_jobs 
ADD COLUMN IF NOT EXISTS source_state TEXT;

COMMENT ON COLUMN enrichment_jobs.source_state IS 
'Source-specific processing state (e.g., "fetched", "enriched", "failed_validation"). Provides granular job tracking.';

-- Worker ID: Claiming worker identifier
ALTER TABLE enrichment_jobs 
ADD COLUMN IF NOT EXISTS worker_id TEXT;

COMMENT ON COLUMN enrichment_jobs.worker_id IS 
'Identifier of the worker that claimed this job (e.g., "worker-coolify-001"). Used for debugging and worker attribution.';

-- Attempt Number: Current attempt count (distinct from attempts which is legacy)
ALTER TABLE enrichment_jobs 
ADD COLUMN IF NOT EXISTS attempt_number INTEGER DEFAULT 0;

COMMENT ON COLUMN enrichment_jobs.attempt_number IS 
'Current attempt count for this job execution. Supports detailed retry tracking.';

-- Last Error Code: Structured error code
ALTER TABLE enrichment_jobs 
ADD COLUMN IF NOT EXISTS last_error_code TEXT;

COMMENT ON COLUMN enrichment_jobs.last_error_code IS 
'Machine-readable error code (e.g., "OPENAI_RATE_LIMIT", "VALIDATION_FAILED"). Enables programmatic error handling.';

-- Last Error Message: Human-readable error description
ALTER TABLE enrichment_jobs 
ADD COLUMN IF NOT EXISTS last_error_message TEXT;

COMMENT ON COLUMN enrichment_jobs.last_error_message IS 
'Human-readable error message for debugging and monitoring dashboards.';

-- Canonical Place ID: Reference for queue flow
ALTER TABLE enrichment_jobs 
ADD COLUMN IF NOT EXISTS canonical_place_id UUID;

COMMENT ON COLUMN enrichment_jobs.canonical_place_id IS 
'Canonical UUID reference for the place being enriched. Supports queue flow and cross-reference tracking.';

-- ============================================
-- 2. ADD METADATA BRIDGE COLUMN (Optional)
-- ============================================
-- This column provides a bridge between legacy context usage and future structured approach
-- Can store non-operational data while operational data goes to typed columns

ALTER TABLE enrichment_jobs 
ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';

COMMENT ON COLUMN enrichment_jobs.metadata IS 
'Optional metadata bridge column for non-operational data. Operational data should use typed columns.';

-- Status: Job status (guarding for order-independent migration)
ALTER TABLE enrichment_jobs 
ADD COLUMN IF NOT EXISTS status TEXT;

COMMENT ON COLUMN enrichment_jobs.status IS 
'Job status (e.g., "queued", "running", "completed", "failed"). Guarded here for migration order independence.';

-- ============================================
-- 3. CREATE INDEXES FOR NEW COLUMNS
-- ============================================

-- Index on worker_id for filtering jobs by worker
CREATE INDEX IF NOT EXISTS idx_enrichment_jobs_worker_id 
ON enrichment_jobs(worker_id) 
WHERE worker_id IS NOT NULL;

COMMENT ON INDEX idx_enrichment_jobs_worker_id IS 
'Supports filtering and debugging by worker identifier.';

-- Index on classification for dashboard filtering
CREATE INDEX IF NOT EXISTS idx_enrichment_jobs_classification 
ON enrichment_jobs(classification) 
WHERE classification IS NOT NULL;

COMMENT ON INDEX idx_enrichment_jobs_classification IS 
'Supports dashboard filtering by error/failure classification.';

-- Index on attempt_number for retry analysis
CREATE INDEX IF NOT EXISTS idx_enrichment_jobs_attempt_number 
ON enrichment_jobs(attempt_number) 
WHERE attempt_number > 0;

COMMENT ON INDEX idx_enrichment_jobs_attempt_number IS 
'Supports retry analysis and identifying problematic jobs.';

-- Index on status + classification for common dashboard queries
CREATE INDEX IF NOT EXISTS idx_enrichment_jobs_status_classification 
ON enrichment_jobs(status, classification) 
WHERE classification IS NOT NULL;

COMMENT ON INDEX idx_enrichment_jobs_status_classification IS 
'Composite index for dashboard queries filtering by status and classification.';

-- Index on canonical_place_id for queue flow queries
CREATE INDEX IF NOT EXISTS idx_enrichment_jobs_canonical_place_id 
ON enrichment_jobs(canonical_place_id) 
WHERE canonical_place_id IS NOT NULL;

COMMENT ON INDEX idx_enrichment_jobs_canonical_place_id IS 
'Supports queue flow and cross-reference queries.';

-- ============================================
-- 4. BACKWARD COMPATIBILITY NOTES
-- ============================================
-- 
-- The existing 'context' column is PRESERVED and remains for backward compatibility.
-- It is recommended to migrate operational data from context to typed columns over time.
-- 
-- The existing 'attempts' column remains functional but 'attempt_number' provides
-- a more explicit alternative for new implementations.
--
-- The existing 'error_message' column remains functional but 'last_error_message'
-- provides a more explicit alternative with 'last_error_code' for structured errors.

-- ============================================
-- 5. RPC SIGNATURE STABILITY
-- ============================================
--
-- This migration adds columns to the table. RPC functions that return table rows
-- (like claim_enrichment_jobs) will automatically include new columns.
-- 
-- If any RPC functions explicitly list column names, they may need updating.
-- The following verification query can be run to check:

-- SELECT routine_name, routine_definition 
-- FROM information_schema.routines 
-- WHERE routine_schema = 'public' 
-- AND routine_definition LIKE '%enrichment_jobs%'
-- AND routine_type = 'FUNCTION';

-- ============================================
-- 6. VERIFICATION QUERIES (for documentation)
-- ============================================

-- Verify new columns exist:
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_name = 'enrichment_jobs'
-- AND column_name IN ('classification', 'source_state', 'worker_id', 
--                     'attempt_number', 'last_error_code', 'last_error_message', 
--                     'canonical_place_id', 'metadata')
-- ORDER BY ordinal_position;

-- Verify indexes exist:
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE tablename = 'enrichment_jobs'
-- AND indexname LIKE 'idx_enrichment_jobs_%';

-- Verify context column still exists:
-- SELECT column_name, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'enrichment_jobs'
-- AND column_name = 'context';

-- ============================================
-- MIGRATION COMPLETE
-- ============================================
-- Added 7 typed operational columns + 1 optional metadata bridge
-- Added 5 performance indexes
-- Preserved context column for backward compatibility
-- RPC signatures remain stable (functions return all columns)
