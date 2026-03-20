-- Destructive cutover migration: fully decommission osm_source and remove
-- unused job/import/cutover tables in one coordinated rollout.
--
-- Cutover notes:
--   1. Stop all worker processes before running this migration.
--   2. Apply this migration.
--   3. Restart only the refactored worker version that reads/writes
--      place_osm_properties exclusively.

SET lock_timeout = '5s';
SET statement_timeout = '5min';

ALTER TABLE public.place_osm_properties
    ADD COLUMN IF NOT EXISTS imported_at timestamptz,
    ADD COLUMN IF NOT EXISTS first_seen_at timestamptz,
    ADD COLUMN IF NOT EXISTS last_seen_at timestamptz,
    ADD COLUMN IF NOT EXISTS last_import_run_id bigint,
    ADD COLUMN IF NOT EXISTS source_metadata jsonb;

ALTER TABLE public.place_osm_properties
    ALTER COLUMN imported_at SET DEFAULT now(),
    ALTER COLUMN first_seen_at SET DEFAULT now(),
    ALTER COLUMN last_seen_at SET DEFAULT now(),
    ALTER COLUMN source_metadata SET DEFAULT '{}'::jsonb;

UPDATE public.place_osm_properties AS pop
SET imported_at = COALESCE(pop.imported_at, os.imported_at),
    first_seen_at = COALESCE(pop.first_seen_at, os.first_seen_at),
    last_seen_at = COALESCE(pop.last_seen_at, os.last_seen_at),
    last_import_run_id = COALESCE(pop.last_import_run_id, os.last_import_run_id),
    source_metadata = COALESCE(pop.source_metadata, os.source_metadata, '{}'::jsonb)
FROM public.osm_source AS os
WHERE os.place_id = pop.place_id
  AND (
      pop.imported_at IS NULL
      OR pop.first_seen_at IS NULL
      OR pop.last_seen_at IS NULL
      OR pop.last_import_run_id IS NULL
      OR pop.source_metadata IS NULL
  );

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_osm_properties_last_import_run'
          AND conrelid = 'public.place_osm_properties'::regclass
    ) THEN
        ALTER TABLE public.place_osm_properties
            ADD CONSTRAINT fk_osm_properties_last_import_run
            FOREIGN KEY (last_import_run_id)
            REFERENCES public.osm_import_runs(id)
            ON DELETE SET NULL;
    END IF;
END
$$;

COMMENT ON COLUMN public.place_osm_properties.imported_at IS
    'Original import timestamp migrated from osm_source during destructive cutover.';
COMMENT ON COLUMN public.place_osm_properties.first_seen_at IS
    'First-seen timestamp migrated from osm_source during destructive cutover.';
COMMENT ON COLUMN public.place_osm_properties.last_seen_at IS
    'Last-seen timestamp migrated from osm_source during destructive cutover.';
COMMENT ON COLUMN public.place_osm_properties.last_import_run_id IS
    'Last osm_import_runs.id reference migrated from osm_source during destructive cutover.';
COMMENT ON COLUMN public.place_osm_properties.source_metadata IS
    'Source metadata migrated from osm_source during destructive cutover.';

CREATE OR REPLACE VIEW public.campsite_full AS
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
FROM public.places p
LEFT JOIN LATERAL (
    SELECT
        pop1.id,
        pop1.place_id,
        pop1.name,
        pop1.city,
        pop1.region,
        pop1.country_code,
        pop1.address,
        pop1.osm_id,
        pop1.place_type,
        pop1.website,
        pop1.opening_hours,
        pop1.phone,
        pop1.email,
        pop1.has_restrooms,
        pop1.has_shower,
        pop1.has_electricity,
        pop1.pets_allowed,
        pop1.has_wifi,
        pop1.has_beach,
        pop1.has_laundry,
        pop1.has_restaurant,
        pop1.has_shop,
        pop1.has_pool,
        pop1.has_playground,
        pop1.has_dump_station,
        pop1.has_drinking_water,
        pop1.has_fresh_water,
        pop1.updated_at
    FROM public.place_osm_properties pop1
    WHERE pop1.place_id = p.id
      AND pop1.is_current = true
    ORDER BY pop1.updated_at DESC, pop1.id DESC
    LIMIT 1
) pop ON true
LEFT JOIN LATERAL (
    SELECT pgp1.*
    FROM public.place_google_properties pgp1
    WHERE pgp1.place_id = p.id
      AND pgp1.is_current = true
    ORDER BY pgp1.updated_at DESC, pgp1.id DESC
    LIMIT 1
) pgp ON true
LEFT JOIN LATERAL (
    SELECT plp1.*
    FROM public.place_llm_properties plp1
    WHERE plp1.place_id = p.id
      AND plp1.is_current = true
    ORDER BY plp1.updated_at DESC, plp1.id DESC
    LIMIT 1
) plp ON true
LEFT JOIN public.campsites_cache cc ON cc.place_id = p.id::text
LEFT JOIN (
    SELECT place_id, COUNT(*) AS review_count, AVG(rating) AS avg_rating
    FROM public.campsite_reviews
    GROUP BY place_id
) r ON r.place_id = p.id::text
LEFT JOIN (
    SELECT place_id, COUNT(*) AS price_count
    FROM public.campsite_prices
    GROUP BY place_id
) cp ON cp.place_id = p.id::text
LEFT JOIN (
    SELECT place_id, COUNT(*) AS favorite_count
    FROM public.favorites
    GROUP BY place_id
) f ON f.place_id = p.id::text;

CREATE OR REPLACE VIEW public.campsite_api_read_model AS
SELECT *
FROM public.campsite_full;

ALTER TABLE public.place_osm_properties
    DROP CONSTRAINT IF EXISTS fk_osm_properties_osm_source;

ALTER TABLE public.place_osm_properties
    DROP COLUMN IF EXISTS osm_source_id;

DROP TABLE IF EXISTS public.osm_source;

CREATE INDEX IF NOT EXISTS idx_osm_properties_osm_type_id
    ON public.place_osm_properties(osm_type, osm_id)
    WHERE osm_type IS NOT NULL AND osm_id IS NOT NULL;

COMMENT ON INDEX public.idx_osm_properties_osm_type_id IS
    'Supports post-cutover OSM identity lookups on place_osm_properties.';

DROP TABLE IF EXISTS public.description_generation_jobs;
DROP TABLE IF EXISTS public.website_scraping_jobs;
DROP TABLE IF EXISTS public.osm_type_transitions;
DROP TABLE IF EXISTS public.import_snapshot;
DROP TABLE IF EXISTS public.cutover_runtime_flags;
DROP TABLE IF EXISTS public.cutover_metric_snapshots;
