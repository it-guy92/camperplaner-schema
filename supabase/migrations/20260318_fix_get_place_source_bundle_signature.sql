-- Migration: Fix get_place_source_bundle function signature
-- Purpose: Change parameter from UUID to BIGINT to match places.id type

-- Drop old function with incorrect UUID signature (if exists from broken comment)
DROP FUNCTION IF EXISTS get_place_source_bundle(UUID);

-- Drop function with new signature if exists (for idempotency)
DROP FUNCTION IF EXISTS get_place_source_bundle(BIGINT);

-- Create corrected function with BIGINT parameter
CREATE OR REPLACE FUNCTION get_place_source_bundle(place_id BIGINT)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result JSONB;
BEGIN
    -- Check if place exists
    IF NOT EXISTS (SELECT 1 FROM places WHERE id = place_id) THEN
        RETURN NULL;
    END IF;

    -- Build the source bundle by querying all source families
    SELECT jsonb_build_object(
        'base', (
            SELECT to_jsonb(p.*)
            FROM places p
            WHERE p.id = place_id
        ),
        'osm', (
            SELECT to_jsonb(osm.*)
            FROM osm_source osm
            WHERE osm.place_id = place_id
            AND osm.is_current = true
            LIMIT 1
        ),
        'llm', (
            SELECT to_jsonb(llm.*)
            FROM place_llm_enrichments llm
            WHERE llm.place_id = place_id
            AND llm.is_current = true
            LIMIT 1
        ),
        'google', (
            SELECT to_jsonb(goog.*)
            FROM place_google_sources goog
            WHERE goog.place_id = place_id
            AND goog.is_current = true
            LIMIT 1
        ),
        'user_aggregates', jsonb_build_object(
            'review_count', COALESCE(
                (SELECT COUNT(*)::int FROM campsite_reviews WHERE place_id = place_id),
                0
            ),
            'avg_rating', (
                SELECT AVG(rating)::numeric(3,2)
                FROM campsite_reviews
                WHERE place_id = place_id
            ),
            'favorite_count', COALESCE(
                (SELECT COUNT(*)::int FROM favorites WHERE place_id = place_id),
                0
            )
        )
    ) INTO result;

    RETURN result;
END;
$$;

-- Fix comment to reference correct BIGINT parameter type
COMMENT ON FUNCTION get_place_source_bundle(BIGINT) IS
'Returns a complete source bundle for a place by its BIGINT id.
Returns JSONB with keys: base (places table), osm (current osm_source),
llm (current place_llm_enrichments), google (current place_google_sources),
and user_aggregates (review_count, avg_rating, favorite_count).';
