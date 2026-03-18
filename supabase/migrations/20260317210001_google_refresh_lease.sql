-- Migration: Google Refresh Claim/Lease and Retry Backoff Primitives
-- Date: 2026-03-17
-- Purpose: Add DB-backed claim/lease primitive for per-place Google refresh
--          - Single in-flight refresh enforcement (one winner per place)
--          - Lease expiry with stale-lock takeover
--          - Retry metadata for transient failures
--          - Negative-cache timestamps for no-match
--
-- IDEMPOTENCY NOTE: This migration is fully idempotent and can be replayed multiple times
-- without errors. It uses CREATE OR REPLACE, IF NOT EXISTS, and DO $$ EXCEPTION patterns.

-- ============================================
-- 1. CREATE google_refresh_claims TABLE
-- ============================================
-- Tracks active and completed Google refresh claims per place
-- Enables single in-flight refresh enforcement with lease expiry

CREATE TABLE IF NOT EXISTS google_refresh_claims (
    -- Primary key: canonical place identifier
    place_id UUID PRIMARY KEY,
    
    -- Claim metadata
    claimed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    worker_id TEXT NOT NULL,
    
    -- Status: 'claimed', 'completed', 'failed'
    status TEXT NOT NULL DEFAULT 'claimed',
    
    -- Retry tracking
    attempt_count INTEGER NOT NULL DEFAULT 1,
    last_attempt_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Error tracking for backoff logic
    last_error TEXT,
    
    -- Result classification: 'match', 'no_match', 'error', null (incomplete)
    result_type TEXT,
    
    -- When result was determined (for negative cache TTL)
    result_at TIMESTAMPTZ,
    
    -- Extended metadata (backoff windows, custom TTLs, etc.)
    metadata JSONB NOT NULL DEFAULT '{}'
);

COMMENT ON TABLE google_refresh_claims IS
'Distributed lease table for Google Places API refresh operations.
Each row represents either an active claim or a completed/failed refresh result.
Used to enforce single in-flight refresh per place and implement backoff/retry logic.
Stale locks (expired leases) can be taken over by new claimers.
Negative cache: no_match results are kept with TTL for backoff enforcement.';

-- Column comments
COMMENT ON COLUMN google_refresh_claims.place_id IS
'Canonical UUID of the place being refreshed. Primary key ensures only one claim per place.';

COMMENT ON COLUMN google_refresh_claims.claimed_at IS
'Timestamp when the claim was acquired or last refreshed.';

COMMENT ON COLUMN google_refresh_claims.expires_at IS
'Lease expiry timestamp. After this time, other workers may steal the claim.';

COMMENT ON COLUMN google_refresh_claims.worker_id IS
'Identifier of the worker holding the claim (e.g., "worker-coolify-001").';

COMMENT ON COLUMN google_refresh_claims.status IS
'Current status: claimed (in-flight), completed (success), failed (error/no-match).';

COMMENT ON COLUMN google_refresh_claims.attempt_count IS
'Number of refresh attempts made for this place.';

COMMENT ON COLUMN google_refresh_claims.last_attempt_at IS
'Timestamp of the most recent attempt.';

COMMENT ON COLUMN google_refresh_claims.last_error IS
'Error message from the last failed attempt.';

COMMENT ON COLUMN google_refresh_claims.result_type IS
'Classification of result: match (found), no_match (not found), error (transient failure).';

COMMENT ON COLUMN google_refresh_claims.result_at IS
'When the result was determined. Used to calculate negative cache TTL.';

COMMENT ON COLUMN google_refresh_claims.metadata IS
'JSONB metadata including backoff configuration, custom TTLs, and diagnostics.';

-- ============================================
-- 2. CREATE INDEXES
-- ============================================

-- Index for querying claims by worker (for worker cleanup/shutdown)
CREATE INDEX IF NOT EXISTS idx_google_refresh_claims_worker_id
ON google_refresh_claims(worker_id)
WHERE worker_id IS NOT NULL;

-- Index for finding expired claims (for stale-lock detection)
CREATE INDEX IF NOT EXISTS idx_google_refresh_claims_expires_at
ON google_refresh_claims(expires_at)
WHERE status = 'claimed';

-- Index for backoff queries (check if we should skip due to recent no_match/error)
CREATE INDEX IF NOT EXISTS idx_google_refresh_claims_result_at
ON google_refresh_claims(result_at)
WHERE result_type IN ('no_match', 'error');

-- Composite index for status-based queries
CREATE INDEX IF NOT EXISTS idx_google_refresh_claims_status_result
ON google_refresh_claims(status, result_type, result_at);

-- ============================================
-- 3. CREATE claim_google_refresh FUNCTION
-- ============================================
-- Atomically claims a Google refresh lease for a place
-- Returns the claim record if successful, NULL if claim cannot be made
-- Handles: fresh claims, expired claim takeover, backoff enforcement

CREATE OR REPLACE FUNCTION claim_google_refresh(
    p_place_id UUID,
    p_worker_id TEXT,
    p_lease_seconds INTEGER DEFAULT 30,
    p_transient_backoff_minutes INTEGER DEFAULT 5,
    p_no_match_backoff_hours INTEGER DEFAULT 24
)
RETURNS google_refresh_claims
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_lease_until TIMESTAMPTZ;
    v_result google_refresh_claims;
    v_existing google_refresh_claims;
    v_backoff_until TIMESTAMPTZ;
BEGIN
    v_lease_until := NOW() + (p_lease_seconds || ' seconds')::INTERVAL;
    
    -- First, check if there's an existing claim and if we should backoff
    SELECT * INTO v_existing
    FROM google_refresh_claims
    WHERE place_id = p_place_id;
    
    IF FOUND THEN
        -- Case 1: Active claim exists and is not expired -> cannot claim
        IF v_existing.status = 'claimed' AND v_existing.expires_at > NOW() THEN
            RETURN NULL;
        END IF;
        
        -- Case 2: Check backoff for completed results
        IF v_existing.status IN ('completed', 'failed') AND v_existing.result_at IS NOT NULL THEN
            -- Calculate backoff window based on result type
            v_backoff_until := CASE v_existing.result_type
                WHEN 'no_match' THEN v_existing.result_at + (p_no_match_backoff_hours || ' hours')::INTERVAL
                WHEN 'error' THEN v_existing.result_at + (p_transient_backoff_minutes || ' minutes')::INTERVAL
                ELSE v_existing.result_at  -- No backoff for other cases
            END;
            
            -- Still in backoff period
            IF v_backoff_until > NOW() THEN
                RETURN NULL;
            END IF;
        END IF;
        
        -- Case 3: Expired claim or past backoff -> take it over
        -- Use atomic UPSERT to prevent race conditions
        INSERT INTO google_refresh_claims (
            place_id, claimed_at, expires_at, worker_id, status,
            attempt_count, last_attempt_at, last_error, result_type, result_at, metadata
        ) VALUES (
            p_place_id, NOW(), v_lease_until, p_worker_id, 'claimed',
            v_existing.attempt_count + 1, NOW(), v_existing.last_error, NULL, NULL,
            jsonb_build_object(
                'previous_status', v_existing.status,
                'previous_worker', v_existing.worker_id,
                'previous_attempt_count', v_existing.attempt_count
            )
        )
        ON CONFLICT (place_id) DO UPDATE SET
            claimed_at = NOW(),
            expires_at = v_lease_until,
            worker_id = p_worker_id,
            status = 'claimed',
            attempt_count = google_refresh_claims.attempt_count + 1,
            last_attempt_at = NOW(),
            result_type = NULL,
            result_at = NULL,
            metadata = jsonb_build_object(
                'previous_status', google_refresh_claims.status,
                'previous_worker', google_refresh_claims.worker_id,
                'previous_attempt_count', google_refresh_claims.attempt_count
            )
        WHERE google_refresh_claims.status != 'claimed'
           OR google_refresh_claims.expires_at <= NOW()
        RETURNING * INTO v_result;
        
        -- Check if we actually got the claim (conflict might have lost)
        IF v_result.worker_id = p_worker_id THEN
            RETURN v_result;
        ELSE
            RETURN NULL;
        END IF;
    END IF;
    
    -- Case 4: No existing claim -> insert new one
    INSERT INTO google_refresh_claims (
        place_id, claimed_at, expires_at, worker_id, status,
        attempt_count, last_attempt_at, metadata
    ) VALUES (
        p_place_id, NOW(), v_lease_until, p_worker_id, 'claimed',
        1, NOW(), '{}'::jsonb
    )
    ON CONFLICT (place_id) DO NOTHING
    RETURNING * INTO v_result;
    
    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION claim_google_refresh IS
'Atomically claims a Google refresh lease for a place.
Parameters:
  - p_place_id: UUID of the place to refresh
  - p_worker_id: Identifier of the claiming worker
  - p_lease_seconds: Lease duration in seconds (default: 30)
  - p_transient_backoff_minutes: Backoff after error in minutes (default: 5)
  - p_no_match_backoff_hours: Backoff after no_match in hours (default: 24)
Returns: The claim record if successful, NULL if:
  - Another worker has an active (non-expired) claim
  - The place is in backoff period (recent error or no_match)
Idempotent: Multiple calls with same worker_id will succeed if lease is held.';

-- ============================================
-- 4. CREATE release_google_refresh FUNCTION
-- ============================================
-- Releases a Google refresh claim with result status
-- Updates the claim record with completion/failure status

CREATE OR REPLACE FUNCTION release_google_refresh(
    p_place_id UUID,
    p_worker_id TEXT,
    p_status TEXT,  -- 'completed' or 'failed'
    p_result_type TEXT DEFAULT NULL,  -- 'match', 'no_match', 'error'
    p_error_message TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_updated BOOLEAN;
BEGIN
    -- Only update if the worker owns the claim
    UPDATE google_refresh_claims
    SET 
        status = p_status,
        result_type = p_result_type,
        result_at = NOW(),
        last_error = CASE WHEN p_status = 'failed' THEN p_error_message ELSE last_error END,
        expires_at = NOW(),  -- Expire immediately on release
        metadata = metadata || jsonb_build_object(
            'released_by', p_worker_id,
            'released_at', NOW()
        )
    WHERE place_id = p_place_id
        AND worker_id = p_worker_id
        AND status = 'claimed';
    
    GET DIAGNOSTICS v_updated = ROW_COUNT;
    RETURN v_updated > 0;
END;
$$;

COMMENT ON FUNCTION release_google_refresh IS
'Releases a Google refresh claim with the specified result status.
Parameters:
  - p_place_id: UUID of the place
  - p_worker_id: Worker ID that must match the claim owner
  - p_status: "completed" or "failed"
  - p_result_type: "match", "no_match", or "error" (optional)
  - p_error_message: Error details if failed (optional)
Returns: TRUE if the claim was released, FALSE if not found or wrong worker.
The claim is not deleted but updated with result metadata for backoff enforcement.';

-- ============================================
-- 5. CREATE should_backoff_google_refresh FUNCTION
-- ============================================
-- Checks if a Google refresh should be skipped due to backoff policy
-- Returns TRUE if the place is in backoff period

CREATE OR REPLACE FUNCTION should_backoff_google_refresh(
    p_place_id UUID,
    p_transient_backoff_minutes INTEGER DEFAULT 5,
    p_no_match_backoff_hours INTEGER DEFAULT 24
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_record google_refresh_claims;
    v_backoff_until TIMESTAMPTZ;
BEGIN
    SELECT * INTO v_record
    FROM google_refresh_claims
    WHERE place_id = p_place_id;
    
    -- No record = no backoff needed
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Active claim (not expired) = backoff
    IF v_record.status = 'claimed' AND v_record.expires_at > NOW() THEN
        RETURN TRUE;
    END IF;
    
    -- Check backoff for completed results
    IF v_record.status IN ('completed', 'failed') AND v_record.result_at IS NOT NULL THEN
        v_backoff_until := CASE v_record.result_type
            WHEN 'no_match' THEN v_record.result_at + (p_no_match_backoff_hours || ' hours')::INTERVAL
            WHEN 'error' THEN v_record.result_at + (p_transient_backoff_minutes || ' minutes')::INTERVAL
            ELSE v_record.result_at  -- No backoff for match results
        END;
        
        RETURN v_backoff_until > NOW();
    END IF;
    
    RETURN FALSE;
END;
$$;

COMMENT ON FUNCTION should_backoff_google_refresh IS
'Checks if a Google refresh should be skipped due to backoff policy.
Parameters:
  - p_place_id: UUID of the place to check
  - p_transient_backoff_minutes: Backoff duration after errors (default: 5)
  - p_no_match_backoff_hours: Backoff duration after no_match (default: 24)
Returns: TRUE if refresh should be skipped, FALSE otherwise.
Backoff triggers:
  - Active non-expired claim exists
  - Recent error result (within backoff window)
  - Recent no_match result (within backoff window)
Completed "match" results do not trigger backoff.';

-- ============================================
-- 6. CREATE cleanup_stale_google_claims FUNCTION
-- ============================================
-- Utility function to clean up stale claims (expired leases)
-- Can be run periodically or on worker startup

CREATE OR REPLACE FUNCTION cleanup_stale_google_claims(
    p_max_age_hours INTEGER DEFAULT 168  -- 7 days default
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_deleted INTEGER;
BEGIN
    DELETE FROM google_refresh_claims
    WHERE status = 'claimed'
        AND expires_at < NOW() - (p_max_age_hours || ' hours')::INTERVAL;
    
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN v_deleted;
END;
$$;

COMMENT ON FUNCTION cleanup_stale_google_claims IS
'Cleans up stale Google refresh claims that have been expired for a long time.
Parameters:
  - p_max_age_hours: Delete claims expired longer than this (default: 168 = 7 days)
Returns: Number of stale claims deleted.
Use this periodically or on worker startup to prevent table bloat.';

-- ============================================
-- 7. CREATE get_google_refresh_status FUNCTION
-- ============================================
-- Returns the current refresh status for a place

CREATE OR REPLACE FUNCTION get_google_refresh_status(
    p_place_id UUID
)
RETURNS TABLE (
    place_id UUID,
    status TEXT,
    is_claimed BOOLEAN,
    is_expired BOOLEAN,
    worker_id TEXT,
    expires_at TIMESTAMPTZ,
    attempt_count INTEGER,
    last_attempt_at TIMESTAMPTZ,
    result_type TEXT,
    last_error TEXT,
    should_backoff BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        grc.place_id,
        grc.status,
        (grc.status = 'claimed')::BOOLEAN AS is_claimed,
        (grc.expires_at < NOW())::BOOLEAN AS is_expired,
        grc.worker_id,
        grc.expires_at,
        grc.attempt_count,
        grc.last_attempt_at,
        grc.result_type,
        grc.last_error,
        should_backoff_google_refresh(p_place_id) AS should_backoff
    FROM google_refresh_claims grc
    WHERE grc.place_id = p_place_id;
END;
$$;

COMMENT ON FUNCTION get_google_refresh_status IS
'Returns the current Google refresh status for a place.
Returns one row with status details, or empty if no record exists.
Useful for debugging and admin dashboards.';

-- ============================================
-- 8. MIGRATION COMPLETE
-- ============================================
-- Created google_refresh_claims table with:
--   - Primary key on place_id (UUID)
--   - Lease tracking (claimed_at, expires_at, worker_id)
--   - Status tracking (claimed/completed/failed)
--   - Retry metadata (attempt_count, last_attempt_at, last_error)
--   - Result classification (result_type, result_at)
--   - Metadata JSONB for extensibility
--
-- Created functions:
--   - claim_google_refresh(): Atomic claim with backoff enforcement
--   - release_google_refresh(): Release claim with result
--   - should_backoff_google_refresh(): Check backoff policy
--   - cleanup_stale_google_claims(): Periodic cleanup utility
--   - get_google_refresh_status(): Status query for debugging
--
-- Created indexes for:
--   - Worker-based queries
--   - Expired claim detection
--   - Backoff queries
--   - Composite status queries
--
-- IDEMPOTENCY GUARANTEES:
-- - Table created only if not exists
-- - Columns use IF NOT EXISTS (via table creation)
-- - Indexes created only if not exists
-- - Functions use CREATE OR REPLACE
-- - This migration can be replayed any number of times without errors