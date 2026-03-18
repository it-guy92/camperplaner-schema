-- Migration: Create get_place_source_bundle RPC function
-- Purpose: Return all source-family data for a place in a single JSONB bundle
-- Created: 2026-03-17

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
        -- Base place data
        'base', (
            SELECT to_jsonb(p.*)
            FROM places p
            WHERE p.id = place_id
        ),

        -- OSM source (current only)
        'osm', (
            SELECT to_jsonb(osm.*)
            FROM osm_source osm
            WHERE osm.place_id = place_id
            AND osm.is_current = true
            LIMIT 1
        ),

        -- LLM enrichment (current only)
        'llm', (
            SELECT to_jsonb(llm.*)
            FROM place_llm_enrichments llm
            WHERE llm.place_id = place_id
            AND llm.is_current = true
            LIMIT 1
        ),

        -- Google source (current only)
        'google', (
            SELECT to_jsonb(goog.*)
            FROM place_google_sources goog
            WHERE goog.place_id = place_id
            AND goog.is_current = true
            LIMIT 1
        ),

        -- User aggregates
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

-- Add comment for documentation
COMMENT ON FUNCTION get_place_source_bundle(UUID) IS 
'Returns a complete source bundle for a place by its public UUID.
Returns JSONB with keys: base (places table), osm (current osm_source), 
llm (current place_llm_enrichments), google (current place_google_sources),
and user_aggregates (review_count, avg_rating, favorite_count).';
