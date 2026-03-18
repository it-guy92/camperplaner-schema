-- Migration: Simplify get_place_enrichment_status to only return job stats
-- Date: 2026-03-16
-- Purpose: Remove dependencies on columns that may not exist

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
BEGIN
    RETURN QUERY
    WITH job_stats AS (
        SELECT
            COUNT(*) FILTER (WHERE status = 'queued') AS pending,
            COUNT(*) FILTER (WHERE status = 'done') AS completed,
            COUNT(*) FILTER (WHERE status = 'dead' OR status = 'failed') AS failed,
            COUNT(*) AS total_jobs
        FROM enrichment_jobs
        WHERE enrichment_jobs.place_id = p_place_id
    ),
    last_job AS (
        SELECT
            status,
            error_message,
            updated_at
        FROM enrichment_jobs
        WHERE place_id = p_place_id
        ORDER BY updated_at DESC
        LIMIT 1
    )
    SELECT
        p_place_id,
        FALSE,  -- has_description (placeholder)
        NULL,   -- description_source
        NULL,   -- ai_description
        NULL,   -- description_generated_at
        COALESCE(js.total_jobs, 0),
        lj.status,
        lj.updated_at,
        lj.error_message,
        COALESCE(js.pending, 0),
        COALESCE(js.completed, 0),
        COALESCE(js.failed, 0)
    FROM job_stats js
    LEFT JOIN last_job lj ON TRUE;
END;
$$;

COMMENT ON FUNCTION get_place_enrichment_status IS
'Returns enrichment job statistics for a specific place.
Used by admin dashboard to display enrichment progress.
Returns job counts by status and last error message.
Note: Place description metadata columns are placeholders until schema is finalized.';
