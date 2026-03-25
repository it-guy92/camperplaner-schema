SET lock_timeout = '10s';
SET statement_timeout = '15min';

-- NOTE:
--   This migration introduces canonical_place_type_enum-backed classification.
--   place_resolved_public.place_type and place_resolved_my.place_type now expose
--   canonical normalized values; campsite_full.type now exposes canonical values
--   like 'campsite' / 'camper_stop' instead of the legacy 'camping' / 'stellplatz'.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type
        WHERE typnamespace = 'public'::regnamespace
          AND typname = 'canonical_place_type_enum'
    ) THEN
        CREATE TYPE public.canonical_place_type_enum AS ENUM (
            'campsite',
            'camper_stop',
            'overnight_parking',
            'parking',
            'attraction',
            'museum',
            'viewpoint',
            'beach',
            'castle',
            'marina',
            'restaurant',
            'shop',
            'nature_spot',
            'poi'
        );
    END IF;
END $$;

COMMENT ON TYPE public.canonical_place_type_enum IS
'Canonical one-dimensional place type enum used for normalized product-facing classification.';

CREATE OR REPLACE FUNCTION public.normalize_place_type(
    p_place_type text,
    p_source_place_type text DEFAULT NULL,
    p_source_categories text[] DEFAULT NULL
)
RETURNS public.canonical_place_type_enum
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    raw_place_type text := lower(trim(coalesce(p_place_type, '')));
    raw_source_place_type text := lower(trim(coalesce(p_source_place_type, '')));
    raw_categories text := lower(trim(coalesce(array_to_string(p_source_categories, ' '), '')));
    combined text := lower(trim(concat_ws(' ', coalesce(p_place_type, ''), coalesce(p_source_place_type, ''), coalesce(array_to_string(p_source_categories, ' '), ''))));
BEGIN
    IF raw_place_type IN (
        'campsite', 'camper_stop', 'overnight_parking', 'parking', 'attraction', 'museum',
        'viewpoint', 'beach', 'castle', 'marina', 'restaurant', 'shop', 'nature_spot', 'poi'
    ) THEN
        RETURN raw_place_type::public.canonical_place_type_enum;
    END IF;

    IF raw_source_place_type IN (
        'campsite', 'camper_stop', 'overnight_parking', 'parking', 'attraction', 'museum',
        'viewpoint', 'beach', 'castle', 'marina', 'restaurant', 'shop', 'nature_spot', 'poi'
    ) THEN
        RETURN raw_source_place_type::public.canonical_place_type_enum;
    END IF;

    IF combined = '' THEN
        RETURN 'poi';
    END IF;

    IF combined LIKE '%camper_stop%'
       OR combined LIKE '%stellplatz%'
       OR combined LIKE '%wohnmobil%'
       OR combined LIKE '%motorhome%'
       OR combined LIKE '%campervan%'
       OR combined LIKE '%camper place%'
       OR combined LIKE '%camper pitch%'
       OR combined LIKE '%camperplaats%'
       OR combined LIKE '%camper park%'
       OR combined LIKE '%aire de camping-car%'
       OR combined LIKE '%aire de camping car%'
       OR combined LIKE '%aire camping car%'
       OR combined LIKE '%aire d''etape%'
       OR combined LIKE '%aire d’étape%'
       OR combined LIKE '%aire d''étape%'
       OR combined LIKE '%area sosta camper%'
       OR combined LIKE '%reisemobil%'
       OR combined LIKE '%wohnmobil-stellplatz%'
       OR combined LIKE '%wohnmobilstellplatz%'
    THEN
        RETURN 'camper_stop';
    END IF;

    IF combined LIKE '%overnight_parking%'
       OR combined LIKE '%overnight parking%'
       OR combined LIKE '%night parking%'
       OR combined LIKE '%übernachtungsparkplatz%'
       OR combined LIKE '%uebernachtungsparkplatz%'
    THEN
        RETURN 'overnight_parking';
    END IF;

    IF combined LIKE '%camp_site%'
       OR combined LIKE '%camp site%'
       OR combined LIKE '%campingplatz%'
       OR combined LIKE '%campsite%'
       OR combined LIKE '%campground%'
       OR combined LIKE '%camping%'
       OR combined LIKE '%glamping%'
       OR combined LIKE '%minicamping%'
       OR combined LIKE '%zeltplatz%'
       OR combined LIKE '%trekkingplatz%'
       OR combined LIKE '%campamento%'
    THEN
        RETURN 'campsite';
    END IF;

    IF raw_place_type = 'parking'
       OR raw_source_place_type = 'parking'
       OR combined LIKE '%parkplatz%'
       OR combined LIKE '%parking lot%'
       OR combined LIKE '%parking area%'
       OR combined LIKE '%car park%'
       OR combined LIKE '% parking %'
       OR combined LIKE 'parking %'
       OR combined LIKE '% parking'
    THEN
        RETURN 'parking';
    END IF;

    IF combined LIKE '%museum%' THEN
        RETURN 'museum';
    END IF;

    IF combined LIKE '%viewpoint%'
       OR combined LIKE '%lookout%'
       OR combined LIKE '%aussichtspunkt%'
       OR combined LIKE '%belvedere%'
       OR combined LIKE '%panorama%'
    THEN
        RETURN 'viewpoint';
    END IF;

    IF combined LIKE '%beach%'
       OR combined LIKE '%strand%'
       OR combined LIKE '%plage%'
    THEN
        RETURN 'beach';
    END IF;

    IF combined LIKE '%castle%'
       OR combined LIKE '%schloss%'
       OR combined LIKE '%burg%'
       OR combined LIKE '%chateau%'
       OR combined LIKE '%fortress%'
       OR combined LIKE '%fort %'
    THEN
        RETURN 'castle';
    END IF;

    IF combined LIKE '%marina%'
       OR combined LIKE '%harbour%'
       OR combined LIKE '%harbor%'
       OR combined LIKE '%jachthaven%'
       OR combined LIKE '%yachthafen%'
    THEN
        RETURN 'marina';
    END IF;

    IF combined LIKE '%restaurant%'
       OR combined LIKE '%pizzeria%'
       OR combined LIKE '%bistro%'
       OR combined LIKE '%gaststätte%'
       OR combined LIKE '%gaststaette%'
       OR combined LIKE '%cafe%'
       OR combined LIKE '%café%'
    THEN
        RETURN 'restaurant';
    END IF;

    IF combined LIKE '%shop%'
       OR combined LIKE '%store%'
       OR combined LIKE '%supermarket%'
       OR combined LIKE '%markt%'
       OR combined LIKE '%market%'
    THEN
        RETURN 'shop';
    END IF;

    IF combined LIKE '%nature%'
       OR combined LIKE '%natural%'
       OR combined LIKE '%national park%'
       OR combined LIKE '%nature reserve%'
       OR combined LIKE '%waterfall%'
       OR combined LIKE '%lake%'
       OR combined LIKE '%forest%'
       OR combined LIKE '%scenic area%'
       OR combined LIKE '%natural_feature%'
    THEN
        RETURN 'nature_spot';
    END IF;

    IF combined LIKE '%attraction%'
       OR combined LIKE '%tourist attraction%'
       OR combined LIKE '%tourist_attraction%'
       OR combined LIKE '%sehenswürdigkeit%'
       OR combined LIKE '%theme park%'
       OR combined LIKE '%zoo%'
    THEN
        RETURN 'attraction';
    END IF;

    RETURN 'poi';
END;
$$;

COMMENT ON FUNCTION public.normalize_place_type(text, text, text[]) IS
'Normalizes legacy/raw place type inputs into the canonical_place_type_enum.';

CREATE OR REPLACE FUNCTION public.resolve_canonical_place_type(
    p_primary public.canonical_place_type_enum,
    p_secondary public.canonical_place_type_enum DEFAULT NULL,
    p_tertiary public.canonical_place_type_enum DEFAULT NULL,
    p_quaternary public.canonical_place_type_enum DEFAULT NULL
)
RETURNS public.canonical_place_type_enum
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT COALESCE(
        NULLIF(p_primary, 'poi'::public.canonical_place_type_enum),
        NULLIF(p_secondary, 'poi'::public.canonical_place_type_enum),
        NULLIF(p_tertiary, 'poi'::public.canonical_place_type_enum),
        NULLIF(p_quaternary, 'poi'::public.canonical_place_type_enum),
        p_primary,
        p_secondary,
        p_tertiary,
        p_quaternary
    )
$$;

COMMENT ON FUNCTION public.resolve_canonical_place_type(public.canonical_place_type_enum, public.canonical_place_type_enum, public.canonical_place_type_enum, public.canonical_place_type_enum) IS
'Resolves canonical place type across prioritized sources while preferring specific values over fallback poi.';

CREATE OR REPLACE FUNCTION public.sync_canonical_place_type()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.canonical_place_type := public.normalize_place_type(
        NEW.place_type,
        NEW.source_place_type,
        NEW.source_categories
    );
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.sync_canonical_place_type() IS
'Trigger helper to keep canonical_place_type synchronized with raw/source type fields.';

ALTER TABLE public.place_osm_properties
    ADD COLUMN IF NOT EXISTS canonical_place_type public.canonical_place_type_enum;

ALTER TABLE public.place_google_properties
    ADD COLUMN IF NOT EXISTS canonical_place_type public.canonical_place_type_enum;

ALTER TABLE public.place_llm_properties
    ADD COLUMN IF NOT EXISTS canonical_place_type public.canonical_place_type_enum;

ALTER TABLE public.place_user_properties
    ADD COLUMN IF NOT EXISTS canonical_place_type public.canonical_place_type_enum;

DROP TRIGGER IF EXISTS trg_sync_canonical_place_type_osm ON public.place_osm_properties;
CREATE TRIGGER trg_sync_canonical_place_type_osm
    BEFORE INSERT OR UPDATE ON public.place_osm_properties
    FOR EACH ROW
    EXECUTE FUNCTION public.sync_canonical_place_type();

DROP TRIGGER IF EXISTS trg_sync_canonical_place_type_google ON public.place_google_properties;
CREATE TRIGGER trg_sync_canonical_place_type_google
    BEFORE INSERT OR UPDATE ON public.place_google_properties
    FOR EACH ROW
    EXECUTE FUNCTION public.sync_canonical_place_type();

DROP TRIGGER IF EXISTS trg_sync_canonical_place_type_llm ON public.place_llm_properties;
CREATE TRIGGER trg_sync_canonical_place_type_llm
    BEFORE INSERT OR UPDATE ON public.place_llm_properties
    FOR EACH ROW
    EXECUTE FUNCTION public.sync_canonical_place_type();

DROP TRIGGER IF EXISTS trg_sync_canonical_place_type_user ON public.place_user_properties;
CREATE TRIGGER trg_sync_canonical_place_type_user
    BEFORE INSERT OR UPDATE ON public.place_user_properties
    FOR EACH ROW
    EXECUTE FUNCTION public.sync_canonical_place_type();

UPDATE public.place_osm_properties
SET canonical_place_type = public.normalize_place_type(place_type, source_place_type, source_categories)
WHERE canonical_place_type IS NULL;

UPDATE public.place_google_properties
SET canonical_place_type = public.normalize_place_type(place_type, source_place_type, source_categories)
WHERE canonical_place_type IS NULL;

UPDATE public.place_llm_properties
SET canonical_place_type = public.normalize_place_type(place_type, source_place_type, source_categories)
WHERE canonical_place_type IS NULL;

UPDATE public.place_user_properties
SET canonical_place_type = public.normalize_place_type(place_type, source_place_type, source_categories)
WHERE canonical_place_type IS NULL;

UPDATE public.place_osm_properties
SET canonical_place_type = 'poi'
WHERE canonical_place_type IS NULL;

UPDATE public.place_google_properties
SET canonical_place_type = 'poi'
WHERE canonical_place_type IS NULL;

UPDATE public.place_llm_properties
SET canonical_place_type = 'poi'
WHERE canonical_place_type IS NULL;

UPDATE public.place_user_properties
SET canonical_place_type = 'poi'
WHERE canonical_place_type IS NULL;

ALTER TABLE public.place_osm_properties
    ALTER COLUMN canonical_place_type SET DEFAULT 'poi',
    ALTER COLUMN canonical_place_type SET NOT NULL;

ALTER TABLE public.place_google_properties
    ALTER COLUMN canonical_place_type SET DEFAULT 'poi',
    ALTER COLUMN canonical_place_type SET NOT NULL;

ALTER TABLE public.place_llm_properties
    ALTER COLUMN canonical_place_type SET DEFAULT 'poi',
    ALTER COLUMN canonical_place_type SET NOT NULL;

ALTER TABLE public.place_user_properties
    ALTER COLUMN canonical_place_type SET DEFAULT 'poi',
    ALTER COLUMN canonical_place_type SET NOT NULL;

COMMENT ON COLUMN public.place_osm_properties.canonical_place_type IS
'Canonical normalized place type derived from raw/source place type fields.';

COMMENT ON COLUMN public.place_google_properties.canonical_place_type IS
'Canonical normalized place type derived from raw/source place type fields.';

COMMENT ON COLUMN public.place_llm_properties.canonical_place_type IS
'Canonical normalized place type derived from raw/source place type fields.';

COMMENT ON COLUMN public.place_user_properties.canonical_place_type IS
'Canonical normalized place type derived from raw/source place type fields.';

CREATE INDEX IF NOT EXISTS idx_place_osm_properties_canonical_place_type_current
    ON public.place_osm_properties(canonical_place_type)
    WHERE is_current = true;

CREATE INDEX IF NOT EXISTS idx_place_google_properties_canonical_place_type_current
    ON public.place_google_properties(canonical_place_type)
    WHERE is_current = true;

CREATE INDEX IF NOT EXISTS idx_place_llm_properties_canonical_place_type_current
    ON public.place_llm_properties(canonical_place_type)
    WHERE is_current = true;

CREATE INDEX IF NOT EXISTS idx_place_user_properties_canonical_place_type_current
    ON public.place_user_properties(canonical_place_type)
    WHERE is_current = true;

CREATE OR REPLACE VIEW public.place_resolved_public AS
SELECT
    p.id,
    p.geom,
    p.lat,
    p.lon,
    p.is_active,
    p.created_at AS place_created_at,
    p.updated_at AS place_updated_at,
    NULLIF(TRIM(COALESCE(pgp.name, pop.name, plp.name)), '') AS name,
    NULLIF(TRIM(COALESCE(pgp.description, pop.description, plp.description)), '') AS description,
    public.resolve_canonical_place_type(pgp.canonical_place_type, pop.canonical_place_type, plp.canonical_place_type)::text AS place_type,
    NULLIF(TRIM(COALESCE(pgp.source_place_type, pop.source_place_type, plp.source_place_type)), '') AS source_place_type,
    COALESCE(pgp.source_categories, pop.source_categories, plp.source_categories) AS source_categories,
    NULLIF(TRIM(COALESCE(pgp.country_code, pop.country_code, plp.country_code)), '') AS country_code,
    NULLIF(TRIM(COALESCE(pgp.region, pop.region, plp.region)), '') AS region,
    NULLIF(TRIM(COALESCE(pgp.city, pop.city, plp.city)), '') AS city,
    NULLIF(TRIM(COALESCE(pgp.postcode, pop.postcode, plp.postcode)), '') AS postcode,
    NULLIF(TRIM(COALESCE(pgp.address, pop.address, plp.address)), '') AS address,
    COALESCE(pgp.source_lat, pop.source_lat, plp.source_lat) AS source_lat,
    COALESCE(pgp.source_lon, pop.source_lon, plp.source_lon) AS source_lon,
    NULLIF(TRIM(COALESCE(pgp.website, pop.website, plp.website)), '') AS website,
    NULLIF(TRIM(COALESCE(pgp.phone, pop.phone, plp.phone)), '') AS phone,
    NULLIF(TRIM(COALESCE(pgp.email, pop.email, plp.email)), '') AS email,
    NULLIF(TRIM(COALESCE(pgp.opening_hours, pop.opening_hours, plp.opening_hours)), '') AS opening_hours,
    NULLIF(TRIM(COALESCE(pgp.fee_info, pop.fee_info, plp.fee_info)), '') AS fee_info,
    COALESCE(pgp.wheelchair_accessible, pop.wheelchair_accessible, plp.wheelchair_accessible) AS wheelchair_accessible,
    COALESCE(pgp.family_friendly, pop.family_friendly, plp.family_friendly) AS family_friendly,
    COALESCE(pgp.pets_allowed, pop.pets_allowed, plp.pets_allowed) AS pets_allowed,
    COALESCE(pgp.indoor, pop.indoor, plp.indoor) AS indoor,
    COALESCE(pgp.outdoor, pop.outdoor, plp.outdoor) AS outdoor,
    COALESCE(pgp.entry_fee_required, pop.entry_fee_required, plp.entry_fee_required) AS entry_fee_required,
    COALESCE(pgp.reservation_required, pop.reservation_required, plp.reservation_required) AS reservation_required,
    COALESCE(pgp.overnight_stay_allowed, pop.overnight_stay_allowed, plp.overnight_stay_allowed) AS overnight_stay_allowed,
    COALESCE(pgp.has_parking, pop.has_parking, plp.has_parking) AS has_parking,
    COALESCE(pgp.has_restrooms, pop.has_restrooms, plp.has_restrooms) AS has_restrooms,
    COALESCE(pgp.has_drinking_water, pop.has_drinking_water, plp.has_drinking_water) AS has_drinking_water,
    COALESCE(pgp.has_wifi, pop.has_wifi, plp.has_wifi) AS has_wifi,
    COALESCE(pgp.has_shop, pop.has_shop, plp.has_shop) AS has_shop,
    COALESCE(pgp.has_restaurant, pop.has_restaurant, plp.has_restaurant) AS has_restaurant,
    COALESCE(pgp.has_cafe, pop.has_cafe, plp.has_cafe) AS has_cafe,
    COALESCE(pgp.caravan_allowed, pop.caravan_allowed, plp.caravan_allowed) AS caravan_allowed,
    COALESCE(pgp.motorhome_allowed, pop.motorhome_allowed, plp.motorhome_allowed) AS motorhome_allowed,
    COALESCE(pgp.tent_allowed, pop.tent_allowed, plp.tent_allowed) AS tent_allowed,
    COALESCE(pgp.has_electricity, pop.has_electricity, plp.has_electricity) AS has_electricity,
    COALESCE(pgp.has_fresh_water, pop.has_fresh_water, plp.has_fresh_water) AS has_fresh_water,
    COALESCE(pgp.has_shower, pop.has_shower, plp.has_shower) AS has_shower,
    COALESCE(pgp.has_laundry, pop.has_laundry, plp.has_laundry) AS has_laundry,
    COALESCE(pgp.has_dishwashing_area, pop.has_dishwashing_area, plp.has_dishwashing_area) AS has_dishwashing_area,
    COALESCE(pgp.has_grey_water_disposal, pop.has_grey_water_disposal, plp.has_grey_water_disposal) AS has_grey_water_disposal,
    COALESCE(pgp.has_black_water_disposal, pop.has_black_water_disposal, plp.has_black_water_disposal) AS has_black_water_disposal,
    COALESCE(pgp.has_chemical_toilet_disposal, pop.has_chemical_toilet_disposal, plp.has_chemical_toilet_disposal) AS has_chemical_toilet_disposal,
    COALESCE(pgp.has_dump_station, pop.has_dump_station, plp.has_dump_station) AS has_dump_station,
    COALESCE(pgp.has_waste_disposal, pop.has_waste_disposal, plp.has_waste_disposal) AS has_waste_disposal,
    COALESCE(pgp.has_recycling, pop.has_recycling, plp.has_recycling) AS has_recycling,
    COALESCE(pgp.has_bbq_area, pop.has_bbq_area, plp.has_bbq_area) AS has_bbq_area,
    COALESCE(pgp.has_fire_pit, pop.has_fire_pit, plp.has_fire_pit) AS has_fire_pit,
    COALESCE(pgp.has_playground, pop.has_playground, plp.has_playground) AS has_playground,
    COALESCE(pgp.has_pool, pop.has_pool, plp.has_pool) AS has_pool,
    COALESCE(pgp.has_beach, pop.has_beach, plp.has_beach) AS has_beach,
    COALESCE(pgp.nudism_allowed, pop.nudism_allowed, plp.nudism_allowed) AS nudism_allowed,
    COALESCE(pgp.nudism_only, pop.nudism_only, plp.nudism_only) AS nudism_only,
    COALESCE(pgp.has_guided_tours, pop.has_guided_tours, plp.has_guided_tours) AS has_guided_tours,
    COALESCE(pgp.has_audio_guide, pop.has_audio_guide, plp.has_audio_guide) AS has_audio_guide,
    COALESCE(pgp.has_visitor_center, pop.has_visitor_center, plp.has_visitor_center) AS has_visitor_center,
    COALESCE(pgp.has_lockers, pop.has_lockers, plp.has_lockers) AS has_lockers,
    COALESCE(pgp.photography_allowed, pop.photography_allowed, plp.photography_allowed) AS photography_allowed,
    (pop.id IS NOT NULL) AS has_osm,
    (pgp.id IS NOT NULL) AS has_google,
    (plp.id IS NOT NULL) AS has_llm,
    CASE
        WHEN pgp.name IS NOT NULL AND NULLIF(TRIM(pgp.name), '') IS NOT NULL THEN 'google'
        WHEN pop.name IS NOT NULL AND NULLIF(TRIM(pop.name), '') IS NOT NULL THEN 'osm'
        WHEN plp.name IS NOT NULL AND NULLIF(TRIM(plp.name), '') IS NOT NULL THEN 'llm'
        ELSE NULL
    END AS name_source,
    pop.updated_at AS osm_updated_at,
    pgp.updated_at AS google_updated_at,
    plp.updated_at AS llm_updated_at,
    pop.source_updated_at AS osm_source_updated_at,
    pgp.source_updated_at AS google_source_updated_at,
    plp.source_updated_at AS llm_source_updated_at
FROM public.places p
LEFT JOIN LATERAL (
    SELECT pop1.*
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
) plp ON true;

COMMENT ON VIEW public.place_resolved_public IS
'Resolved place properties with google > osm > llm priority per column. place_type is exposed as canonical normalized text backed by canonical_place_type_enum; source_place_type remains raw source text.';

CREATE OR REPLACE VIEW public.place_resolved_my AS
SELECT
    p.id,
    p.geom,
    p.lat,
    p.lon,
    p.is_active,
    p.created_at AS place_created_at,
    p.updated_at AS place_updated_at,
    NULLIF(TRIM(COALESCE(pgp.name, pup.name, pop.name, plp.name)), '') AS name,
    NULLIF(TRIM(COALESCE(pgp.description, pup.description, pop.description, plp.description)), '') AS description,
    public.resolve_canonical_place_type(pgp.canonical_place_type, pup.canonical_place_type, pop.canonical_place_type, plp.canonical_place_type)::text AS place_type,
    NULLIF(TRIM(COALESCE(pgp.source_place_type, pup.source_place_type, pop.source_place_type, plp.source_place_type)), '') AS source_place_type,
    COALESCE(pgp.source_categories, pup.source_categories, pop.source_categories, plp.source_categories) AS source_categories,
    NULLIF(TRIM(COALESCE(pgp.country_code, pup.country_code, pop.country_code, plp.country_code)), '') AS country_code,
    NULLIF(TRIM(COALESCE(pgp.region, pup.region, pop.region, plp.region)), '') AS region,
    NULLIF(TRIM(COALESCE(pgp.city, pup.city, pop.city, plp.city)), '') AS city,
    NULLIF(TRIM(COALESCE(pgp.postcode, pup.postcode, pop.postcode, plp.postcode)), '') AS postcode,
    NULLIF(TRIM(COALESCE(pgp.address, pup.address, pop.address, plp.address)), '') AS address,
    COALESCE(pgp.source_lat, pup.source_lat, pop.source_lat, plp.source_lat) AS source_lat,
    COALESCE(pgp.source_lon, pup.source_lon, pop.source_lon, plp.source_lon) AS source_lon,
    NULLIF(TRIM(COALESCE(pgp.website, pup.website, pop.website, plp.website)), '') AS website,
    NULLIF(TRIM(COALESCE(pgp.phone, pup.phone, pop.phone, plp.phone)), '') AS phone,
    NULLIF(TRIM(COALESCE(pgp.email, pup.email, pop.email, plp.email)), '') AS email,
    NULLIF(TRIM(COALESCE(pgp.opening_hours, pup.opening_hours, pop.opening_hours, plp.opening_hours)), '') AS opening_hours,
    NULLIF(TRIM(COALESCE(pgp.fee_info, pup.fee_info, pop.fee_info, plp.fee_info)), '') AS fee_info,
    COALESCE(pgp.wheelchair_accessible, pup.wheelchair_accessible, pop.wheelchair_accessible, plp.wheelchair_accessible) AS wheelchair_accessible,
    COALESCE(pgp.family_friendly, pup.family_friendly, pop.family_friendly, plp.family_friendly) AS family_friendly,
    COALESCE(pgp.pets_allowed, pup.pets_allowed, pop.pets_allowed, plp.pets_allowed) AS pets_allowed,
    COALESCE(pgp.indoor, pup.indoor, pop.indoor, plp.indoor) AS indoor,
    COALESCE(pgp.outdoor, pup.outdoor, pop.outdoor, plp.outdoor) AS outdoor,
    COALESCE(pgp.entry_fee_required, pup.entry_fee_required, pop.entry_fee_required, plp.entry_fee_required) AS entry_fee_required,
    COALESCE(pgp.reservation_required, pup.reservation_required, pop.reservation_required, plp.reservation_required) AS reservation_required,
    COALESCE(pgp.overnight_stay_allowed, pup.overnight_stay_allowed, pop.overnight_stay_allowed, plp.overnight_stay_allowed) AS overnight_stay_allowed,
    COALESCE(pgp.has_parking, pup.has_parking, pop.has_parking, plp.has_parking) AS has_parking,
    COALESCE(pgp.has_restrooms, pup.has_restrooms, pop.has_restrooms, plp.has_restrooms) AS has_restrooms,
    COALESCE(pgp.has_drinking_water, pup.has_drinking_water, pop.has_drinking_water, plp.has_drinking_water) AS has_drinking_water,
    COALESCE(pgp.has_wifi, pup.has_wifi, pop.has_wifi, plp.has_wifi) AS has_wifi,
    COALESCE(pgp.has_shop, pup.has_shop, pop.has_shop, plp.has_shop) AS has_shop,
    COALESCE(pgp.has_restaurant, pup.has_restaurant, pop.has_restaurant, plp.has_restaurant) AS has_restaurant,
    COALESCE(pgp.has_cafe, pup.has_cafe, pop.has_cafe, plp.has_cafe) AS has_cafe,
    COALESCE(pgp.caravan_allowed, pup.caravan_allowed, pop.caravan_allowed, plp.caravan_allowed) AS caravan_allowed,
    COALESCE(pgp.motorhome_allowed, pup.motorhome_allowed, pop.motorhome_allowed, plp.motorhome_allowed) AS motorhome_allowed,
    COALESCE(pgp.tent_allowed, pup.tent_allowed, pop.tent_allowed, plp.tent_allowed) AS tent_allowed,
    COALESCE(pgp.has_electricity, pup.has_electricity, pop.has_electricity, plp.has_electricity) AS has_electricity,
    COALESCE(pgp.has_fresh_water, pup.has_fresh_water, pop.has_fresh_water, plp.has_fresh_water) AS has_fresh_water,
    COALESCE(pgp.has_shower, pup.has_shower, pop.has_shower, plp.has_shower) AS has_shower,
    COALESCE(pgp.has_laundry, pup.has_laundry, pop.has_laundry, plp.has_laundry) AS has_laundry,
    COALESCE(pgp.has_dishwashing_area, pup.has_dishwashing_area, pop.has_dishwashing_area, plp.has_dishwashing_area) AS has_dishwashing_area,
    COALESCE(pgp.has_grey_water_disposal, pup.has_grey_water_disposal, pop.has_grey_water_disposal, plp.has_grey_water_disposal) AS has_grey_water_disposal,
    COALESCE(pgp.has_black_water_disposal, pup.has_black_water_disposal, pop.has_black_water_disposal, plp.has_black_water_disposal) AS has_black_water_disposal,
    COALESCE(pgp.has_chemical_toilet_disposal, pup.has_chemical_toilet_disposal, pop.has_chemical_toilet_disposal, plp.has_chemical_toilet_disposal) AS has_chemical_toilet_disposal,
    COALESCE(pgp.has_dump_station, pup.has_dump_station, pop.has_dump_station, plp.has_dump_station) AS has_dump_station,
    COALESCE(pgp.has_waste_disposal, pup.has_waste_disposal, pop.has_waste_disposal, plp.has_waste_disposal) AS has_waste_disposal,
    COALESCE(pgp.has_recycling, pup.has_recycling, pop.has_recycling, plp.has_recycling) AS has_recycling,
    COALESCE(pgp.has_bbq_area, pup.has_bbq_area, pop.has_bbq_area, plp.has_bbq_area) AS has_bbq_area,
    COALESCE(pgp.has_fire_pit, pup.has_fire_pit, pop.has_fire_pit, plp.has_fire_pit) AS has_fire_pit,
    COALESCE(pgp.has_playground, pup.has_playground, pop.has_playground, plp.has_playground) AS has_playground,
    COALESCE(pgp.has_pool, pup.has_pool, pop.has_pool, plp.has_pool) AS has_pool,
    COALESCE(pgp.has_beach, pup.has_beach, pop.has_beach, plp.has_beach) AS has_beach,
    COALESCE(pgp.nudism_allowed, pup.nudism_allowed, pop.nudism_allowed, plp.nudism_allowed) AS nudism_allowed,
    COALESCE(pgp.nudism_only, pup.nudism_only, pop.nudism_only, plp.nudism_only) AS nudism_only,
    COALESCE(pgp.has_guided_tours, pup.has_guided_tours, pop.has_guided_tours, plp.has_guided_tours) AS has_guided_tours,
    COALESCE(pgp.has_audio_guide, pup.has_audio_guide, pop.has_audio_guide, plp.has_audio_guide) AS has_audio_guide,
    COALESCE(pgp.has_visitor_center, pup.has_visitor_center, pop.has_visitor_center, plp.has_visitor_center) AS has_visitor_center,
    COALESCE(pgp.has_lockers, pup.has_lockers, pop.has_lockers, plp.has_lockers) AS has_lockers,
    COALESCE(pgp.photography_allowed, pup.photography_allowed, pop.photography_allowed, plp.photography_allowed) AS photography_allowed,
    (pop.id IS NOT NULL) AS has_osm,
    (pgp.id IS NOT NULL) AS has_google,
    (plp.id IS NOT NULL) AS has_llm,
    (pup.id IS NOT NULL) AS has_user,
    CASE
        WHEN pgp.name IS NOT NULL AND NULLIF(TRIM(pgp.name), '') IS NOT NULL THEN 'google'
        WHEN pup.name IS NOT NULL AND NULLIF(TRIM(pup.name), '') IS NOT NULL THEN 'user'
        WHEN pop.name IS NOT NULL AND NULLIF(TRIM(pop.name), '') IS NOT NULL THEN 'osm'
        WHEN plp.name IS NOT NULL AND NULLIF(TRIM(plp.name), '') IS NOT NULL THEN 'llm'
        ELSE NULL
    END AS name_source,
    pop.updated_at AS osm_updated_at,
    pgp.updated_at AS google_updated_at,
    plp.updated_at AS llm_updated_at,
    pup.updated_at AS user_updated_at,
    pop.source_updated_at AS osm_source_updated_at,
    pgp.source_updated_at AS google_source_updated_at,
    plp.source_updated_at AS llm_source_updated_at,
    pup.source_updated_at AS user_source_updated_at
FROM public.places p
LEFT JOIN LATERAL (
    SELECT pop1.*
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
    SELECT pup1.*
    FROM public.place_user_properties pup1
    WHERE pup1.place_id = p.id
      AND pup1.user_id = auth.uid()
      AND pup1.is_current = true
    ORDER BY pup1.updated_at DESC, pup1.id DESC
    LIMIT 1
) pup ON true
LEFT JOIN LATERAL (
    SELECT plp1.*
    FROM public.place_llm_properties plp1
    WHERE plp1.place_id = p.id
      AND plp1.is_current = true
    ORDER BY plp1.updated_at DESC, plp1.id DESC
    LIMIT 1
) plp ON true;

COMMENT ON VIEW public.place_resolved_my IS
'Resolved place properties with google > user > osm > llm priority per column. place_type is exposed as canonical normalized text backed by canonical_place_type_enum; source_place_type remains raw source text.';

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
        'place_type', public.resolve_canonical_place_type(pop.canonical_place_type, pgp.canonical_place_type, plp.canonical_place_type)::text,
        'source_place_type', COALESCE(pop.source_place_type, pgp.source_place_type, plp.source_place_type),
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
        WHEN public.resolve_canonical_place_type(pop.canonical_place_type, pgp.canonical_place_type, plp.canonical_place_type) IS NOT NULL
            THEN ARRAY[public.resolve_canonical_place_type(pop.canonical_place_type, pgp.canonical_place_type, plp.canonical_place_type)::text]
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
    COALESCE(public.resolve_canonical_place_type(pop.canonical_place_type, pgp.canonical_place_type, plp.canonical_place_type), 'poi'::public.canonical_place_type_enum)::text AS type,
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
    SELECT pop1.*
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
