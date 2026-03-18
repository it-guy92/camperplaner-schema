CREATE OR REPLACE VIEW campsite_full AS
SELECT
    p.id::text AS place_id,
    p.name,
    COALESCE(
        NULLIF(TRIM(CONCAT_WS(', ', p.city, p.region, p.country_code)), ''),
        p.address,
        p.name
    ) AS location,
    p.lat,
    p.lon AS lng,
    p.source_primary::text AS source_type,
    NULL::text AS osm_id,
    jsonb_build_object(
        'source_primary', p.source_primary,
        'place_type', p.place_type,
        'country_code', p.country_code,
        'city', p.city
    ) AS osm_tags,
    p.website,
    p.opening_hours,
    p.phone AS contact_phone,
    p.email AS contact_email,
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
    COALESCE(cc.place_types, ARRAY[p.place_type]::text[]) AS place_types,
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
        WHEN p.place_type::text = 'camp_site' THEN 'camping'
        WHEN p.place_type::text = 'camper_stop' THEN 'stellplatz'
        ELSE 'poi'
    END AS type,
    COALESCE(p.has_toilet, false) AS has_toilet,
    COALESCE(p.has_shower, false) AS has_shower,
    COALESCE(p.has_electricity, false) AS has_electricity,
    COALESCE(p.pet_friendly, false) AS has_dogs_allowed,
    COALESCE(p.has_wifi, false) AS has_wifi,
    false AS has_beach,
    false AS has_laundry,
    false AS has_restaurant,
    false AS has_bar,
    false AS has_shop,
    false AS has_pool,
    false AS has_playground,
    false AS has_dump_station,
    COALESCE(p.has_water, false) AS has_water,
    false AS has_washing_machine,
    false AS has_dishwasher
FROM places p
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
