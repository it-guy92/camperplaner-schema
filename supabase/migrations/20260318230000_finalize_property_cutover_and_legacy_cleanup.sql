SET lock_timeout = '10s';
SET statement_timeout = '15min';

DROP FUNCTION IF EXISTS get_place_source_bundle(BIGINT);

CREATE FUNCTION get_place_source_bundle(p_place_id BIGINT)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result JSONB;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM places WHERE id = p_place_id) THEN
        RETURN NULL;
    END IF;

    SELECT jsonb_build_object(
        'base', (
            SELECT to_jsonb(p.*)
            FROM places p
            WHERE p.id = p_place_id
        ),
        'osm', (
            SELECT to_jsonb(pop.*)
            FROM place_osm_properties pop
            WHERE pop.place_id = p_place_id
              AND pop.is_current = true
            ORDER BY pop.updated_at DESC, pop.id DESC
            LIMIT 1
        ),
        'llm', (
            SELECT to_jsonb(plp.*)
            FROM place_llm_properties plp
            WHERE plp.place_id = p_place_id
              AND plp.is_current = true
            ORDER BY plp.updated_at DESC, plp.id DESC
            LIMIT 1
        ),
        'google', (
            SELECT to_jsonb(pgp.*)
            FROM place_google_properties pgp
            WHERE pgp.place_id = p_place_id
              AND pgp.is_current = true
            ORDER BY pgp.updated_at DESC, pgp.id DESC
            LIMIT 1
        ),
        'user', (
            SELECT COALESCE(jsonb_agg(to_jsonb(pup.*) ORDER BY pup.updated_at DESC, pup.id DESC), '[]'::jsonb)
            FROM place_user_properties pup
            WHERE pup.place_id = p_place_id
              AND pup.is_current = true
        ),
        'user_aggregates', jsonb_build_object(
            'review_count', COALESCE(
                (SELECT COUNT(*)::int FROM campsite_reviews cr WHERE cr.place_id = p_place_id),
                0
            ),
            'avg_rating', (
                SELECT AVG(cr2.rating)::numeric(3,2)
                FROM campsite_reviews cr2
                WHERE cr2.place_id = p_place_id
            ),
            'favorite_count', COALESCE(
                (SELECT COUNT(*)::int FROM favorites f WHERE f.place_id = p_place_id),
                0
            )
        )
    ) INTO result;

    RETURN result;
END;
$$;

COMMENT ON FUNCTION get_place_source_bundle(BIGINT) IS
'Returns a complete source bundle for a place by BIGINT id.
Returns JSONB with keys: base (places), osm (current place_osm_properties),
llm (current place_llm_properties), google (current place_google_properties),
user (current place_user_properties rows), and user_aggregates.';

CREATE OR REPLACE VIEW campsite_full AS
SELECT
    p.id::text AS place_id,
    COALESCE(pop.name, pgp.name, plp.name, 'Place ' || p.id::text) AS name,
    COALESCE(
        NULLIF(
            TRIM(
                CONCAT_WS(
                    ', ',
                    COALESCE(pop.city, pgp.city, plp.city),
                    COALESCE(pop.region, pgp.region, plp.region),
                    COALESCE(pop.country_code, pgp.country_code, plp.country_code)
                )
            ),
            ''
        ),
        COALESCE(pop.address, pgp.address, plp.address),
        COALESCE(pop.name, pgp.name, plp.name, 'Place ' || p.id::text)
    ) AS location,
    p.lat,
    p.lon AS lng,
    COALESCE(
        CASE WHEN pop.id IS NOT NULL THEN 'osm' END,
        CASE WHEN pgp.id IS NOT NULL THEN 'google' END,
        CASE WHEN plp.id IS NOT NULL THEN 'llm' END,
        'unknown'
    ) AS source_type,
    pop.osm_id::text AS osm_id,
    jsonb_build_object(
        'source_primary', COALESCE(
            CASE WHEN pop.id IS NOT NULL THEN 'osm' END,
            CASE WHEN pgp.id IS NOT NULL THEN 'google' END,
            CASE WHEN plp.id IS NOT NULL THEN 'llm' END,
            'unknown'
        ),
        'place_type', COALESCE(pop.place_type, pgp.place_type, plp.place_type),
        'country_code', COALESCE(pop.country_code, pgp.country_code, plp.country_code),
        'city', COALESCE(pop.city, pgp.city, plp.city)
    ) AS osm_tags,
    COALESCE(pop.website, pgp.website, plp.website) AS website,
    COALESCE(pop.opening_hours, pgp.opening_hours, plp.opening_hours) AS opening_hours,
    COALESCE(pop.phone, pgp.phone, plp.phone) AS contact_phone,
    COALESCE(pop.email, pgp.email, plp.email) AS contact_email,
    cc.scraped_website_url,
    cc.scraped_at,
    cc.scraped_price_info,
    cc.scraped_data_source::text AS scraped_data_source,
    cc.description,
    cc.description_source::text AS description_source,
    cc.description_generated_at,
    cc.description_version,
    cc.estimated_price::numeric AS estimated_price,
    cc.price_source::text AS price_source,
    cc.user_price_count::bigint AS user_price_count,
    cc.user_price_avg::numeric AS user_price_avg,
    CASE
        WHEN cc.place_types IS NOT NULL THEN cc.place_types
        WHEN COALESCE(pop.place_type, pgp.place_type, plp.place_type) IS NOT NULL
            THEN ARRAY[COALESCE(pop.place_type, pgp.place_type, plp.place_type)]::text[]
        ELSE NULL
    END AS place_types,
    p.created_at,
    p.updated_at,
    cc.place_id AS google_place_id,
    cc.google_photos,
    cc.google_reviews,
    cc.google_data_fetched_at,
    cc.google_data_expires_at,
    CASE
        WHEN cc.google_data_expires_at IS NOT NULL AND cc.google_data_expires_at < NOW()
        THEN true
        ELSE false
    END AS google_data_expired,
    COALESCE(r.review_count, 0) AS review_count,
    r.avg_rating,
    COALESCE(cp.price_count, 0) AS user_price_entries,
    COALESCE(f.favorite_count, 0) AS favorite_count,
    cc.rating::numeric AS google_rating,
    COALESCE(cc.rating::numeric, r.avg_rating) AS rating,
    CASE
        WHEN COALESCE(pop.place_type, pgp.place_type, plp.place_type)::text = 'camp_site' THEN 'camping'
        WHEN COALESCE(pop.place_type, pgp.place_type, plp.place_type)::text = 'camper_stop' THEN 'stellplatz'
        ELSE 'poi'
    END AS type,
    COALESCE(pop.has_restrooms, pgp.has_restrooms, plp.has_restrooms, false) AS has_toilet,
    COALESCE(pop.has_shower, pgp.has_shower, plp.has_shower, false) AS has_shower,
    COALESCE(pop.has_electricity, pgp.has_electricity, plp.has_electricity, false) AS has_electricity,
    COALESCE(pop.pets_allowed, pgp.pets_allowed, plp.pets_allowed, false) AS has_dogs_allowed,
    COALESCE(pop.has_wifi, pgp.has_wifi, plp.has_wifi, false) AS has_wifi,
    COALESCE(pop.has_beach, pgp.has_beach, plp.has_beach, false) AS has_beach,
    COALESCE(pop.has_laundry, pgp.has_laundry, plp.has_laundry, false) AS has_laundry,
    COALESCE(pop.has_restaurant, pgp.has_restaurant, plp.has_restaurant, false) AS has_restaurant,
    false AS has_bar,
    COALESCE(pop.has_shop, pgp.has_shop, plp.has_shop, false) AS has_shop,
    COALESCE(pop.has_pool, pgp.has_pool, plp.has_pool, false) AS has_pool,
    COALESCE(pop.has_playground, pgp.has_playground, plp.has_playground, false) AS has_playground,
    COALESCE(pop.has_dump_station, pgp.has_dump_station, plp.has_dump_station, false) AS has_dump_station,
    COALESCE(
        pop.has_drinking_water,
        pop.has_fresh_water,
        pgp.has_drinking_water,
        pgp.has_fresh_water,
        plp.has_drinking_water,
        plp.has_fresh_water,
        false
    ) AS has_water,
    false AS has_washing_machine,
    false AS has_dishwasher
FROM places p
LEFT JOIN LATERAL (
    SELECT pop1.*
    FROM place_osm_properties pop1
    WHERE pop1.place_id = p.id
      AND pop1.is_current = true
    ORDER BY pop1.updated_at DESC, pop1.id DESC
    LIMIT 1
) pop ON true
LEFT JOIN LATERAL (
    SELECT pgp1.*
    FROM place_google_properties pgp1
    WHERE pgp1.place_id = p.id
      AND pgp1.is_current = true
    ORDER BY pgp1.updated_at DESC, pgp1.id DESC
    LIMIT 1
) pgp ON true
LEFT JOIN LATERAL (
    SELECT plp1.*
    FROM place_llm_properties plp1
    WHERE plp1.place_id = p.id
      AND plp1.is_current = true
    ORDER BY plp1.updated_at DESC, plp1.id DESC
    LIMIT 1
) plp ON true
LEFT JOIN campsites_cache cc ON cc.place_id = p.id::text
LEFT JOIN (
    SELECT place_id, COUNT(*) AS review_count, AVG(rating) AS avg_rating
    FROM campsite_reviews
    GROUP BY place_id
) r ON r.place_id = p.id::text
LEFT JOIN (
    SELECT place_id, COUNT(*) AS price_count
    FROM campsite_prices
    GROUP BY place_id
) cp ON cp.place_id = p.id::text
LEFT JOIN (
    SELECT place_id, COUNT(*) AS favorite_count
    FROM favorites
    GROUP BY place_id
) f ON f.place_id = p.id::text;

CREATE OR REPLACE VIEW campsite_api_read_model AS
SELECT *
FROM campsite_full;

DROP TABLE IF EXISTS place_google_reviews;
DROP TABLE IF EXISTS place_google_photos;
DROP TABLE IF EXISTS place_google_sources;
DROP TABLE IF EXISTS place_llm_enrichments;
DROP TABLE IF EXISTS osm_source;

ALTER TABLE IF EXISTS places
    DROP COLUMN IF EXISTS place_type,
    DROP COLUMN IF EXISTS name,
    DROP COLUMN IF EXISTS country_code,
    DROP COLUMN IF EXISTS region,
    DROP COLUMN IF EXISTS city,
    DROP COLUMN IF EXISTS postcode,
    DROP COLUMN IF EXISTS address,
    DROP COLUMN IF EXISTS has_toilet,
    DROP COLUMN IF EXISTS has_shower,
    DROP COLUMN IF EXISTS has_electricity,
    DROP COLUMN IF EXISTS has_water,
    DROP COLUMN IF EXISTS has_wifi,
    DROP COLUMN IF EXISTS pet_friendly,
    DROP COLUMN IF EXISTS caravan_allowed,
    DROP COLUMN IF EXISTS motorhome_allowed,
    DROP COLUMN IF EXISTS tent_allowed,
    DROP COLUMN IF EXISTS website,
    DROP COLUMN IF EXISTS phone,
    DROP COLUMN IF EXISTS email,
    DROP COLUMN IF EXISTS opening_hours,
    DROP COLUMN IF EXISTS fee_info,
    DROP COLUMN IF EXISTS source_primary,
    DROP COLUMN IF EXISTS data_confidence,
    DROP COLUMN IF EXISTS last_seen_at,
    DROP COLUMN IF EXISTS last_enriched_at;
