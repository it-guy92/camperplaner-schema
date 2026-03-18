INSERT INTO campsites (
    place_id,
    name,
    location,
    source_type,
    osm_tags,
    website,
    opening_hours,
    contact_phone,
    contact_email,
    scraped_website_url,
    scraped_at,
    scraped_price_info,
    scraped_data_source,
    description,
    description_source,
    description_generated_at,
    description_version,
    estimated_price,
    price_source,
    user_price_count,
    user_price_avg,
    place_types,
    created_at,
    updated_at
)
SELECT 
    place_id,
    name,
    ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography,
    CASE 
        WHEN scraped_data_source IS NOT NULL THEN 'scraped'
        ELSE 'osm'
    END,
    '{}'::jsonb,
    website,
    opening_hours,
    contact_phone,
    contact_email,
    scraped_website_url,
    scraped_at,
    scraped_price_info,
    scraped_data_source,
    description,
    description_source,
    description_generated_at,
    COALESCE(description_version, 1),
    estimated_price,
    price_source,
    user_price_count,
    user_price_avg,
    place_types,
    COALESCE(last_updated, NOW()),
    COALESCE(last_updated, NOW())
FROM campsites_cache
WHERE place_id NOT IN (SELECT place_id FROM campsites)
ON CONFLICT (place_id) DO NOTHING;

UPDATE campsites_cache cc
SET campsite_id = cc.place_id
WHERE campsite_id IS NULL;

UPDATE campsites_cache cc
SET 
    google_data_fetched_at = cc.last_updated,
    google_data_expires_at = cc.last_updated + INTERVAL '30 days'
WHERE photo_url IS NOT NULL 
   OR rating IS NOT NULL
   AND google_data_fetched_at IS NULL;
