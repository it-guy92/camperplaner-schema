-- Migration: Fix ambiguous place_id reference
-- Date: 2026-03-16

DROP FUNCTION IF EXISTS get_place_enrichment_status(INTEGER);

CREATE OR REPLACE FUNCTION get_place_enrichment_status(
    p_place_id INTEGER
)
RETURNS TABLE (
    place_id INTEGER,
    has_description BOOLEAN,
    description_source TEXT,
    ai_description TEXT,
    description_generated_at TIMESTAMPTZ,
    enrichment_job_count BIGINT,
    last_enrichment_status TEXT,
    last_enrichment_at TIMESTAMPTZ,
    last_error_message TEXT,
    pending_jobs BIGINT,
    completed_jobs BIGINT,
    failed_jobs BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_pending BIGINT;
    v_completed BIGINT;
    v_failed BIGINT;
    v_total BIGINT;
    v_last_status TEXT;
    v_last_updated TIMESTAMPTZ;
    v_last_error TEXT;
BEGIN
    -- Get job stats
    SELECT
        COUNT(*) FILTER (WHERE enrichment_jobs.status = 'queued'),
        COUNT(*) FILTER (WHERE enrichment_jobs.status = 'done'),
        COUNT(*) FILTER (WHERE enrichment_jobs.status = 'dead' OR enrichment_jobs.status = 'failed'),
        COUNT(*)
    INTO v_pending, v_completed, v_failed, v_total
    FROM enrichment_jobs
    WHERE enrichment_jobs.place_id = p_place_id;
    
    -- Get last job info
    SELECT 
        enrichment_jobs.status,
        enrichment_jobs.updated_at,
        enrichment_jobs.error_message
    INTO v_last_status, v_last_updated, v_last_error
    FROM enrichment_jobs
    WHERE enrichment_jobs.place_id = p_place_id
    ORDER BY enrichment_jobs.updated_at DESC
    LIMIT 1;
    
    RETURN QUERY SELECT 
        p_place_id,
        FALSE,
        NULL::TEXT,
        NULL::TEXT,
        NULL::TIMESTAMPTZ,
        COALESCE(v_total, 0::BIGINT),
        v_last_status,
        v_last_updated,
        v_last_error,
        COALESCE(v_pending, 0::BIGINT),
        COALESCE(v_completed, 0::BIGINT),
        COALESCE(v_failed, 0::BIGINT);
END;
$$;

COMMENT ON FUNCTION get_place_enrichment_status IS
'Returns enrichment job statistics for a specific place.';
