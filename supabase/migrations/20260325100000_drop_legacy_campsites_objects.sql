SET lock_timeout = '5s';
SET statement_timeout = '60s';

DROP VIEW IF EXISTS public.campsite_api_read_model;

ALTER TABLE IF EXISTS public.trip_stops
    DROP CONSTRAINT IF EXISTS fk_trip_stops_campsite;

ALTER TABLE IF EXISTS public.trip_stops
    DROP CONSTRAINT IF EXISTS trip_stops_campsite_id_fkey;

ALTER TABLE IF EXISTS public.description_generation_jobs
    DROP CONSTRAINT IF EXISTS fk_description_jobs_campsite;

ALTER TABLE IF EXISTS public.description_generation_jobs
    DROP CONSTRAINT IF EXISTS description_generation_jobs_place_id_fkey;

ALTER TABLE IF EXISTS public.website_scraping_jobs
    DROP CONSTRAINT IF EXISTS fk_scraping_jobs_campsite;

ALTER TABLE IF EXISTS public.website_scraping_jobs
    DROP CONSTRAINT IF EXISTS website_scraping_jobs_place_id_fkey;

ALTER TABLE IF EXISTS public.campsites_cache
    DROP CONSTRAINT IF EXISTS fk_campsites_cache_campsite;

ALTER TABLE IF EXISTS public.campsites_cache
    DROP CONSTRAINT IF EXISTS campsites_cache_campsite_id_fkey;

ALTER TABLE IF EXISTS public.campsites_cache
    DROP COLUMN IF EXISTS campsite_id;

DROP TABLE IF EXISTS public.campsites;

DO $$
DECLARE
    rel_kind "char";
BEGIN
    SELECT c.relkind
    INTO rel_kind
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'place_legacy_id_map';

    IF rel_kind IN ('r', 'p') THEN
        EXECUTE 'DROP TABLE public.place_legacy_id_map';
    ELSIF rel_kind = 'v' THEN
        EXECUTE 'DROP VIEW public.place_legacy_id_map';
    ELSIF rel_kind = 'm' THEN
        EXECUTE 'DROP MATERIALIZED VIEW public.place_legacy_id_map';
    ELSIF rel_kind = 'f' THEN
        EXECUTE 'DROP FOREIGN TABLE public.place_legacy_id_map';
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'trip_stops'
          AND column_name = 'campsite_id'
    ) THEN
        EXECUTE $sql$
            COMMENT ON COLUMN public.trip_stops.campsite_id IS
            'Legacy compatibility alias for trip_stops.place_id after dropping public.campsites.'
        $sql$;
    END IF;
END $$;
