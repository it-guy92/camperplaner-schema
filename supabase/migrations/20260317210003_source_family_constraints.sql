-- ============================================================================
-- Migration: Add Source Family Current-Row Constraints and Hot-Path Indexes
-- Date: 2026-03-17
-- Purpose: Add partial unique constraints for current-row semantics and
--          composite indexes for detail query hot paths
-- ============================================================================

-- ============================================================================
-- PART 1: Partial Unique Constraints for Current-Row Semantics
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1.1 place_google_sources: One current source per place
-- ----------------------------------------------------------------------------
-- Use DROP IF EXISTS for idempotency - indexes don't support IF NOT EXISTS
DROP INDEX IF EXISTS uidx_google_sources_place_current;

CREATE UNIQUE INDEX uidx_google_sources_place_current 
    ON place_google_sources(place_id) 
    WHERE is_current = true;

COMMENT ON INDEX uidx_google_sources_place_current IS 
    'Partial unique constraint: one current Google source per place';

-- ----------------------------------------------------------------------------
-- 1.2 place_llm_enrichments: One current COMPLETED enrichment per place
-- ----------------------------------------------------------------------------
DROP INDEX IF EXISTS uidx_llm_enrichments_place_current_completed;

CREATE UNIQUE INDEX uidx_llm_enrichments_place_current_completed 
    ON place_llm_enrichments(place_id) 
    WHERE is_current = true AND status = 'completed';

COMMENT ON INDEX uidx_llm_enrichments_place_current_completed IS 
    'Partial unique constraint: one current completed LLM enrichment per place';

-- ----------------------------------------------------------------------------
-- 1.3 osm_source: One current OSM source per place
-- ----------------------------------------------------------------------------
DROP INDEX IF EXISTS uidx_osm_source_place_current;

CREATE UNIQUE INDEX uidx_osm_source_place_current 
    ON osm_source(place_id) 
    WHERE is_current = true;

COMMENT ON INDEX uidx_osm_source_place_current IS 
    'Partial unique constraint: one current OSM source per place';

-- ============================================================================
-- PART 2: Composite Indexes for Hot-Path Detail Queries
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 2.1 place_llm_facts: Composite for field lookup per enrichment
-- ----------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_llm_facts_enrichment_field;

CREATE INDEX idx_llm_facts_enrichment_field 
    ON place_llm_facts(llm_enrichment_id, field_name);

COMMENT ON INDEX idx_llm_facts_enrichment_field IS 
    'Composite index for fetching all facts for a specific field across enrichments';

-- ----------------------------------------------------------------------------
-- 2.2 place_llm_sources: Composite for enrichment source lookups
-- ----------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_llm_sources_enrichment_trusted;

CREATE INDEX idx_llm_sources_enrichment_trusted 
    ON place_llm_sources(llm_enrichment_id, trusted);

COMMENT ON INDEX idx_llm_sources_enrichment_trusted IS 
    'Composite index for fetching sources with trust status per enrichment';

-- ----------------------------------------------------------------------------
-- 2.3 place_llm_evidence_markers: Composite for evidence lookup
-- ----------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_llm_evidence_enrichment_field;

CREATE INDEX idx_llm_evidence_enrichment_field 
    ON place_llm_evidence_markers(llm_enrichment_id, field_name);

COMMENT ON INDEX idx_llm_evidence_enrichment_field IS 
    'Composite index for fetching evidence markers per field per enrichment';

-- ----------------------------------------------------------------------------
-- 2.4 place_google_sources: Index for cache expiry lookups
-- ----------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_google_sources_place_expires;

CREATE INDEX idx_google_sources_place_expires 
    ON place_google_sources(place_id, expires_at);

COMMENT ON INDEX idx_google_sources_place_expires IS 
    'Composite index for finding expiring caches per place';

-- ----------------------------------------------------------------------------
-- 2.5 osm_source: Index for current OSM source lookups
-- ----------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_osm_source_place_type;

CREATE INDEX idx_osm_source_place_type 
    ON osm_source(place_id, osm_type);

COMMENT ON INDEX idx_osm_source_place_type IS 
    'Composite index for fetching OSM sources by type per place';

-- ----------------------------------------------------------------------------
-- 2.6 place_llm_enrichments: Index for completed enrichments by place
-- ----------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_llm_enrichments_place_status_completed;

CREATE INDEX idx_llm_enrichments_place_status_completed 
    ON place_llm_enrichments(place_id, status) 
    WHERE status = 'completed';

COMMENT ON INDEX idx_llm_enrichments_place_status_completed IS 
    'Partial index for completed enrichments per place';

-- ============================================================================
-- PART 3: Verify Indexes Exist (Idempotent Check)
-- ============================================================================

DO $$
BEGIN
    -- Verify partial unique constraints were created
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'uidx_google_sources_place_current'
    ) THEN
        RAISE EXCEPTION 'Failed to create uidx_google_sources_place_current';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'uidx_llm_enrichments_place_current_completed'
    ) THEN
        RAISE EXCEPTION 'Failed to create uidx_llm_enrichments_place_current_completed';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'uidx_osm_source_place_current'
    ) THEN
        RAISE EXCEPTION 'Failed to create uidx_osm_source_place_current';
    END IF;

    RAISE NOTICE 'All partial unique constraints created successfully';
END $$;

-- ============================================================================
-- PART 4: Verification Queries (for post-migration validation)
-- ============================================================================

-- Verify indexes exist:
-- SELECT indexname, indexdef 
-- FROM pg_indexes 
-- WHERE schemaname = 'public' 
-- AND indexname IN (
--     'uidx_google_sources_place_current',
--     'uidx_llm_enrichments_place_current_completed',
--     'uidx_osm_source_place_current',
--     'idx_llm_facts_enrichment_field',
--     'idx_llm_sources_enrichment_trusted',
--     'idx_llm_evidence_enrichment_field',
--     'idx_google_sources_place_expires',
--     'idx_osm_source_place_type',
--     'idx_llm_enrichments_place_status_completed'
-- );

-- Test constraint enforcement (should fail with duplicate current):
-- -- This should FAIL (constraint violation):
-- -- INSERT INTO place_google_sources (place_id, google_place_id, is_current) 
-- -- VALUES (1, 'google123', true);
-- -- INSERT INTO place_google_sources (place_id, google_place_id, is_current) 
-- -- VALUES (1, 'google456', true);

-- Test partial unique behavior (should succeed - different place_id):
-- -- This should SUCCEED:
-- -- INSERT INTO place_google_sources (place_id, google_place_id, is_current) 
-- -- VALUES (2, 'google789', true);
