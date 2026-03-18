-- Migration: Add get_place_enrichment_status RPC Function
-- Date: 2026-03-16
-- Purpose: Provide place enrichment status for admin dashboard
--          Returns enrichment statistics and job status for a specific place

-- ============================================
-- 1. CREATE get_place_enrichment_status FUNCTION
-- ============================================
-- Returns enrichment status and statistics for a specific place
-- Used by admin dashboard to display enrichment progress and status

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
    WITH place_info AS (
        SELECT
            p.id AS pid,
            -- Check for description in place_enrichment table instead
            EXISTS (
                SELECT 1 FROM place_enrichment pe 
                WHERE pe.place_id = p.id 
                AND pe.ai_description IS NOT NULL 
                AND pe.ai_description != ''
            ) AS has_desc,
            (SELECT pe.description_source FROM place_enrichment pe 
             WHERE pe.place_id = p.id 
             ORDER BY pe.updated_at DESC LIMIT 1) AS desc_source,
            (SELECT pe.ai_description FROM place_enrichment pe 
             WHERE pe.place_id = p.id 
             ORDER BY pe.updated_at DESC LIMIT 1) AS ai_desc,
            (SELECT pe.description_generated_at FROM place_enrichment pe 
             WHERE pe.place_id = p.id 
             ORDER BY pe.updated_at DESC LIMIT 1) AS desc_gen_at
        FROM places p
        WHERE p.id = p_place_id
    ),
    job_stats AS (
        SELECT
            COUNT(*) FILTER (WHERE status = 'queued') AS pending,
            COUNT(*) FILTER (WHERE status = 'done') AS completed,
            COUNT(*) FILTER (WHERE status = 'dead' OR status = 'failed') AS failed,
            COUNT(*) AS total_jobs,
            MAX(updated_at) FILTER (WHERE status = 'done' OR status = 'dead') AS last_update
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
        COALESCE(pi.has_desc, FALSE),
        pi.desc_source,
        pi.ai_desc,
        pi.desc_gen_at,
        COALESCE(js.total_jobs, 0),
        lj.status,
        lj.updated_at,
        lj.error_message,
        COALESCE(js.pending, 0),
        COALESCE(js.completed, 0),
        COALESCE(js.failed, 0)
    FROM place_info pi
    CROSS JOIN job_stats js
    LEFT JOIN last_job lj ON TRUE;
END;
$$;

COMMENT ON FUNCTION get_place_enrichment_status IS
'Returns enrichment status and statistics for a specific place.
Used by admin dashboard to display enrichment progress.
Returns job counts by status, last error message, and place description metadata.
Idempotent: Function can be replaced without affecting existing data.';

-- ============================================
-- 2. CREATE INDEX FOR PERFORMANCE (if not exists)
-- ============================================
-- Ensure fast lookups by place_id for enrichment jobs

CREATE INDEX IF NOT EXISTS idx_enrichment_jobs_place_id
ON enrichment_jobs(place_id);

COMMENT ON INDEX idx_enrichment_jobs_place_id IS
'Supports get_place_enrichment_status queries by place_id.';

-- ============================================
-- 3. MIGRATION COMPLETE
-- ============================================
-- Added get_place_enrichment_status RPC function
-- Added supporting index for place_id lookups
-- Function returns HTTP 200 with structured enrichment status data
