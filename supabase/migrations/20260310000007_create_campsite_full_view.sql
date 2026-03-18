CREATE OR REPLACE VIEW campsite_full AS
SELECT 
    c.place_id,
    c.name,
    c.location,
    ST_Y(c.location::geometry) AS lat,
    ST_X(c.location::geometry) AS lng,
    c.source_type,
    c.osm_id,
    c.osm_tags,
    c.website,
    c.opening_hours,
    c.contact_phone,
    c.contact_email,
    c.scraped_website_url,
    c.scraped_at,
    c.scraped_price_info,
    c.scraped_data_source,
    c.description,
    c.description_source,
    c.description_generated_at,
    c.description_version,
    c.estimated_price,
    c.price_source,
    c.user_price_count,
    c.user_price_avg,
    c.place_types,
    c.created_at,
    c.updated_at,
    cc.google_place_id,
    cc.google_photos,
    cc.google_reviews,
    cc.google_data_fetched_at,
    cc.google_data_expires_at,
    CASE 
        WHEN cc.google_data_expires_at IS NOT NULL AND cc.google_data_expires_at < NOW() 
        THEN true 
        ELSE false 
    END AS google_data_expired
FROM campsites c
LEFT JOIN campsites_cache cc ON c.place_id = cc.campsite_id;

CREATE OR REPLACE VIEW campsite_with_stats AS
SELECT 
    c.*,
    COALESCE(r.review_count, 0) AS review_count,
    COALESCE(r.avg_rating, NULL) AS avg_rating,
    COALESCE(p.price_count, 0) AS user_price_entries,
    f.favorite_count AS favorite_count
FROM campsites c
LEFT JOIN (
    SELECT place_id, COUNT(*) AS review_count, AVG(rating) AS avg_rating
    FROM campsite_reviews
    GROUP BY place_id
) r ON c.place_id = r.place_id
LEFT JOIN (
    SELECT place_id, COUNT(*) AS price_count
    FROM campsite_prices
    GROUP BY place_id
) p ON c.place_id = p.place_id
LEFT JOIN (
    SELECT place_id, COUNT(*) AS favorite_count
    FROM favorites
    GROUP BY place_id
) f ON c.place_id = f.place_id;
