SET lock_timeout = '10s';
SET statement_timeout = '15min';

DROP FUNCTION IF EXISTS public.get_place_source_bundle(BIGINT);
