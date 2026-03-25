SET lock_timeout = '10s';
SET statement_timeout = '10min';

CREATE OR REPLACE FUNCTION public.canonical_place_type_priority(
    p_type public.canonical_place_type_enum
)
RETURNS integer
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT CASE p_type
        WHEN 'camper_stop'::public.canonical_place_type_enum THEN 140
        WHEN 'campsite'::public.canonical_place_type_enum THEN 130
        WHEN 'overnight_parking'::public.canonical_place_type_enum THEN 120
        WHEN 'parking'::public.canonical_place_type_enum THEN 110
        WHEN 'shop'::public.canonical_place_type_enum THEN 100
        WHEN 'restaurant'::public.canonical_place_type_enum THEN 90
        WHEN 'marina'::public.canonical_place_type_enum THEN 80
        WHEN 'beach'::public.canonical_place_type_enum THEN 70
        WHEN 'viewpoint'::public.canonical_place_type_enum THEN 60
        WHEN 'museum'::public.canonical_place_type_enum THEN 50
        WHEN 'castle'::public.canonical_place_type_enum THEN 40
        WHEN 'nature_spot'::public.canonical_place_type_enum THEN 30
        WHEN 'attraction'::public.canonical_place_type_enum THEN 20
        WHEN 'poi'::public.canonical_place_type_enum THEN 10
        ELSE 0
    END
$$;

COMMENT ON FUNCTION public.canonical_place_type_priority(public.canonical_place_type_enum) IS
'Priority ranking for canonical place types. Higher wins when multiple sources disagree.';

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
    SELECT ranked.place_type
    FROM (
        SELECT t AS place_type
        FROM unnest(ARRAY[p_primary, p_secondary, p_tertiary, p_quaternary]) AS t
        WHERE t IS NOT NULL
        ORDER BY public.canonical_place_type_priority(t) DESC
        LIMIT 1
    ) AS ranked
$$;

COMMENT ON FUNCTION public.resolve_canonical_place_type(public.canonical_place_type_enum, public.canonical_place_type_enum, public.canonical_place_type_enum, public.canonical_place_type_enum) IS
'Resolves canonical place type across prioritized sources using explicit product-facing type priority.';

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
        'campsite', 'camper_stop', 'overnight_parking', 'attraction', 'museum',
        'viewpoint', 'beach', 'castle', 'marina', 'restaurant', 'shop', 'nature_spot', 'poi'
    ) THEN
        RETURN raw_place_type::public.canonical_place_type_enum;
    END IF;

    IF raw_source_place_type IN (
        'campsite', 'camper_stop', 'overnight_parking', 'attraction', 'museum',
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

    IF combined LIKE '%shop%'
       OR combined LIKE '%store%'
       OR combined LIKE '%supermarket%'
       OR combined LIKE '%markt%'
       OR combined LIKE '%market%'
    THEN
        RETURN 'shop';
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

    IF combined LIKE '%marina%'
       OR combined LIKE '%harbour%'
       OR combined LIKE '%harbor%'
       OR combined LIKE '%jachthaven%'
       OR combined LIKE '%yachthafen%'
    THEN
        RETURN 'marina';
    END IF;

    IF combined LIKE '%beach%'
       OR combined LIKE '%strand%'
       OR combined LIKE '%plage%'
    THEN
        RETURN 'beach';
    END IF;

    IF combined LIKE '%viewpoint%'
       OR combined LIKE '%lookout%'
       OR combined LIKE '%aussichtspunkt%'
       OR combined LIKE '%belvedere%'
       OR combined LIKE '%panorama%'
    THEN
        RETURN 'viewpoint';
    END IF;

    IF combined LIKE '%museum%' THEN
        RETURN 'museum';
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

    IF raw_place_type = 'parking'
       OR raw_source_place_type = 'parking'
       OR raw_categories = 'parking'
       OR raw_categories LIKE '% parking %'
       OR raw_categories LIKE 'parking %'
       OR raw_categories LIKE '% parking'
       OR combined LIKE '%parking lot%'
       OR combined LIKE '%parking area%'
       OR combined LIKE '%parking facility%'
       OR combined LIKE '%car park%'
       OR combined LIKE '%parkplatz%'
       OR combined LIKE '%parcheggio%'
       OR combined LIKE '%parkeergelegenheid%'
    THEN
        RETURN 'parking';
    END IF;

    RETURN 'poi';
END;
$$;

COMMENT ON FUNCTION public.normalize_place_type(text, text, text[]) IS
'Normalizes legacy/raw place type inputs into the canonical_place_type_enum using specific matches before broad parking fallback.';

UPDATE public.place_osm_properties
SET canonical_place_type = public.normalize_place_type(place_type, source_place_type, source_categories)
WHERE canonical_place_type IS DISTINCT FROM public.normalize_place_type(place_type, source_place_type, source_categories);

UPDATE public.place_google_properties
SET canonical_place_type = public.normalize_place_type(place_type, source_place_type, source_categories)
WHERE canonical_place_type IS DISTINCT FROM public.normalize_place_type(place_type, source_place_type, source_categories);

UPDATE public.place_llm_properties
SET canonical_place_type = public.normalize_place_type(place_type, source_place_type, source_categories)
WHERE canonical_place_type IS DISTINCT FROM public.normalize_place_type(place_type, source_place_type, source_categories);

UPDATE public.place_user_properties
SET canonical_place_type = public.normalize_place_type(place_type, source_place_type, source_categories)
WHERE canonical_place_type IS DISTINCT FROM public.normalize_place_type(place_type, source_place_type, source_categories);
