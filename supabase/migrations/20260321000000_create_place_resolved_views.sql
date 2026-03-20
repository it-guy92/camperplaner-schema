-- ============================================================================
-- Migration: Create place_resolved Views
-- Date: 2026-03-21
-- Purpose: Add resolved property views that merge aligned property tables
--          with priority-based coalescing per column
-- ============================================================================

SET lock_timeout = '5s';

-- ============================================================================
-- Helper: NULLIF empty string helper (reuse pattern)
-- Using COALESCE(NULLIF(trim(col), ''), NULL) to treat whitespace-only
-- strings as NULL alongside truly empty strings
-- ============================================================================

-- ============================================================================
-- VIEW: place_resolved_public
-- Merges places with google > osm > llm property sources using per-column
-- priority. Canonical coordinates (lat/lon/geom) come from places table.
-- ============================================================================

CREATE OR REPLACE VIEW public.place_resolved_public AS
SELECT
    -- 1. Core place identity and geometry (canonical from places)
    p.id,
    p.geom,
    p.lat,
    p.lon,
    p.is_active,
    p.created_at AS place_created_at,
    p.updated_at AS place_updated_at,

    -- 2. Identity / Content (priority: google > osm > llm)
    NULLIF(TRIM(COALESCE(pgp.name, pop.name, plp.name)), '') AS name,
    NULLIF(TRIM(COALESCE(pgp.description, pop.description, plp.description)), '') AS description,
    NULLIF(TRIM(COALESCE(pgp.place_type, pop.place_type, plp.place_type)), '') AS place_type,
    NULLIF(TRIM(COALESCE(pgp.source_place_type, pop.source_place_type, plp.source_place_type)), '') AS source_place_type,
    COALESCE(pgp.source_categories, pop.source_categories, plp.source_categories) AS source_categories,

    -- 3. Address / Location (priority: google > osm > llm)
    NULLIF(TRIM(COALESCE(pgp.country_code, pop.country_code, plp.country_code)), '') AS country_code,
    NULLIF(TRIM(COALESCE(pgp.region, pop.region, plp.region)), '') AS region,
    NULLIF(TRIM(COALESCE(pgp.city, pop.city, plp.city)), '') AS city,
    NULLIF(TRIM(COALESCE(pgp.postcode, pop.postcode, plp.postcode)), '') AS postcode,
    NULLIF(TRIM(COALESCE(pgp.address, pop.address, plp.address)), '') AS address,
    COALESCE(pgp.source_lat, pop.source_lat, plp.source_lat) AS source_lat,
    COALESCE(pgp.source_lon, pop.source_lon, plp.source_lon) AS source_lon,

    -- 4. Contact / Operations (priority: google > osm > llm)
    NULLIF(TRIM(COALESCE(pgp.website, pop.website, plp.website)), '') AS website,
    NULLIF(TRIM(COALESCE(pgp.phone, pop.phone, plp.phone)), '') AS phone,
    NULLIF(TRIM(COALESCE(pgp.email, pop.email, plp.email)), '') AS email,
    NULLIF(TRIM(COALESCE(pgp.opening_hours, pop.opening_hours, plp.opening_hours)), '') AS opening_hours,
    NULLIF(TRIM(COALESCE(pgp.fee_info, pop.fee_info, plp.fee_info)), '') AS fee_info,

    -- 5. Generic Flags (priority: google > osm > llm)
    COALESCE(pgp.wheelchair_accessible, pop.wheelchair_accessible, plp.wheelchair_accessible) AS wheelchair_accessible,
    COALESCE(pgp.family_friendly, pop.family_friendly, plp.family_friendly) AS family_friendly,
    COALESCE(pgp.pets_allowed, pop.pets_allowed, plp.pets_allowed) AS pets_allowed,
    COALESCE(pgp.indoor, pop.indoor, plp.indoor) AS indoor,
    COALESCE(pgp.outdoor, pop.outdoor, plp.outdoor) AS outdoor,
    COALESCE(pgp.entry_fee_required, pop.entry_fee_required, plp.entry_fee_required) AS entry_fee_required,
    COALESCE(pgp.reservation_required, pop.reservation_required, plp.reservation_required) AS reservation_required,
    COALESCE(pgp.overnight_stay_allowed, pop.overnight_stay_allowed, plp.overnight_stay_allowed) AS overnight_stay_allowed,

    -- 6. General Facilities (priority: google > osm > llm)
    COALESCE(pgp.has_parking, pop.has_parking, plp.has_parking) AS has_parking,
    COALESCE(pgp.has_restrooms, pop.has_restrooms, plp.has_restrooms) AS has_restrooms,
    COALESCE(pgp.has_drinking_water, pop.has_drinking_water, plp.has_drinking_water) AS has_drinking_water,
    COALESCE(pgp.has_wifi, pop.has_wifi, plp.has_wifi) AS has_wifi,
    COALESCE(pgp.has_shop, pop.has_shop, plp.has_shop) AS has_shop,
    COALESCE(pgp.has_restaurant, pop.has_restaurant, plp.has_restaurant) AS has_restaurant,
    COALESCE(pgp.has_cafe, pop.has_cafe, plp.has_cafe) AS has_cafe,

    -- 7. Camping Permissions (priority: google > osm > llm)
    COALESCE(pgp.caravan_allowed, pop.caravan_allowed, plp.caravan_allowed) AS caravan_allowed,
    COALESCE(pgp.motorhome_allowed, pop.motorhome_allowed, plp.motorhome_allowed) AS motorhome_allowed,
    COALESCE(pgp.tent_allowed, pop.tent_allowed, plp.tent_allowed) AS tent_allowed,

    -- 8. Camping Facilities (priority: google > osm > llm)
    COALESCE(pgp.has_electricity, pop.has_electricity, plp.has_electricity) AS has_electricity,
    COALESCE(pgp.has_fresh_water, pop.has_fresh_water, plp.has_fresh_water) AS has_fresh_water,
    COALESCE(pgp.has_shower, pop.has_shower, plp.has_shower) AS has_shower,
    COALESCE(pgp.has_laundry, pop.has_laundry, plp.has_laundry) AS has_laundry,
    COALESCE(pgp.has_dishwashing_area, pop.has_dishwashing_area, plp.has_dishwashing_area) AS has_dishwashing_area,

    -- 9. Disposal / Utilities (priority: google > osm > llm)
    COALESCE(pgp.has_grey_water_disposal, pop.has_grey_water_disposal, plp.has_grey_water_disposal) AS has_grey_water_disposal,
    COALESCE(pgp.has_black_water_disposal, pop.has_black_water_disposal, plp.has_black_water_disposal) AS has_black_water_disposal,
    COALESCE(pgp.has_chemical_toilet_disposal, pop.has_chemical_toilet_disposal, plp.has_chemical_toilet_disposal) AS has_chemical_toilet_disposal,
    COALESCE(pgp.has_dump_station, pop.has_dump_station, plp.has_dump_station) AS has_dump_station,
    COALESCE(pgp.has_waste_disposal, pop.has_waste_disposal, plp.has_waste_disposal) AS has_waste_disposal,
    COALESCE(pgp.has_recycling, pop.has_recycling, plp.has_recycling) AS has_recycling,

    -- 10. Leisure (priority: google > osm > llm)
    COALESCE(pgp.has_bbq_area, pop.has_bbq_area, plp.has_bbq_area) AS has_bbq_area,
    COALESCE(pgp.has_fire_pit, pop.has_fire_pit, plp.has_fire_pit) AS has_fire_pit,
    COALESCE(pgp.has_playground, pop.has_playground, plp.has_playground) AS has_playground,
    COALESCE(pgp.has_pool, pop.has_pool, plp.has_pool) AS has_pool,
    COALESCE(pgp.has_beach, pop.has_beach, plp.has_beach) AS has_beach,

    -- 11. Nudism (priority: google > osm > llm)
    COALESCE(pgp.nudism_allowed, pop.nudism_allowed, plp.nudism_allowed) AS nudism_allowed,
    COALESCE(pgp.nudism_only, pop.nudism_only, plp.nudism_only) AS nudism_only,

    -- 12. Attraction / Museum (priority: google > osm > llm)
    COALESCE(pgp.has_guided_tours, pop.has_guided_tours, plp.has_guided_tours) AS has_guided_tours,
    COALESCE(pgp.has_audio_guide, pop.has_audio_guide, plp.has_audio_guide) AS has_audio_guide,
    COALESCE(pgp.has_visitor_center, pop.has_visitor_center, plp.has_visitor_center) AS has_visitor_center,
    COALESCE(pgp.has_lockers, pop.has_lockers, plp.has_lockers) AS has_lockers,
    COALESCE(pgp.photography_allowed, pop.photography_allowed, plp.photography_allowed) AS photography_allowed,

    -- 13. Source presence booleans (for filtering/debugging)
    (pop.id IS NOT NULL) AS has_osm,
    (pgp.id IS NOT NULL) AS has_google,
    (plp.id IS NOT NULL) AS has_llm,

    -- 14. Name source tracking (which source provided the resolved name)
    CASE
        WHEN pgp.name IS NOT NULL AND NULLIF(TRIM(pgp.name), '') IS NOT NULL THEN 'google'
        WHEN pop.name IS NOT NULL AND NULLIF(TRIM(pop.name), '') IS NOT NULL THEN 'osm'
        WHEN plp.name IS NOT NULL AND NULLIF(TRIM(plp.name), '') IS NOT NULL THEN 'llm'
        ELSE NULL
    END AS name_source,

    -- 15. Property table timestamps (for staleness detection)
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
    'Resolved place properties with google > osm > llm priority per column. Canonical lat/lon/geom from places table. Use for public-facing read-only queries.';

-- ============================================================================
-- VIEW: place_resolved_my
-- Merges places with google > current_user > osm > llm property sources.
-- current_user is determined by auth.uid(). If no user is authenticated,
-- this view returns the same as place_resolved_public (no user override).
-- Canonical coordinates (lat/lon/geom) come from places table.
-- ============================================================================

CREATE OR REPLACE VIEW public.place_resolved_my AS
SELECT
    -- 1. Core place identity and geometry (canonical from places)
    p.id,
    p.geom,
    p.lat,
    p.lon,
    p.is_active,
    p.created_at AS place_created_at,
    p.updated_at AS place_updated_at,

    -- 2. Identity / Content (priority: google > user > osm > llm)
    NULLIF(TRIM(COALESCE(pgp.name, pup.name, pop.name, plp.name)), '') AS name,
    NULLIF(TRIM(COALESCE(pgp.description, pup.description, pop.description, plp.description)), '') AS description,
    NULLIF(TRIM(COALESCE(pgp.place_type, pup.place_type, pop.place_type, plp.place_type)), '') AS place_type,
    NULLIF(TRIM(COALESCE(pgp.source_place_type, pup.source_place_type, pop.source_place_type, plp.source_place_type)), '') AS source_place_type,
    COALESCE(pgp.source_categories, pup.source_categories, pop.source_categories, plp.source_categories) AS source_categories,

    -- 3. Address / Location (priority: google > user > osm > llm)
    NULLIF(TRIM(COALESCE(pgp.country_code, pup.country_code, pop.country_code, plp.country_code)), '') AS country_code,
    NULLIF(TRIM(COALESCE(pgp.region, pup.region, pop.region, plp.region)), '') AS region,
    NULLIF(TRIM(COALESCE(pgp.city, pup.city, pop.city, plp.city)), '') AS city,
    NULLIF(TRIM(COALESCE(pgp.postcode, pup.postcode, pop.postcode, plp.postcode)), '') AS postcode,
    NULLIF(TRIM(COALESCE(pgp.address, pup.address, pop.address, plp.address)), '') AS address,
    COALESCE(pgp.source_lat, pup.source_lat, pop.source_lat, plp.source_lat) AS source_lat,
    COALESCE(pgp.source_lon, pup.source_lon, pop.source_lon, plp.source_lon) AS source_lon,

    -- 4. Contact / Operations (priority: google > user > osm > llm)
    NULLIF(TRIM(COALESCE(pgp.website, pup.website, pop.website, plp.website)), '') AS website,
    NULLIF(TRIM(COALESCE(pgp.phone, pup.phone, pop.phone, plp.phone)), '') AS phone,
    NULLIF(TRIM(COALESCE(pgp.email, pup.email, pop.email, plp.email)), '') AS email,
    NULLIF(TRIM(COALESCE(pgp.opening_hours, pup.opening_hours, pop.opening_hours, plp.opening_hours)), '') AS opening_hours,
    NULLIF(TRIM(COALESCE(pgp.fee_info, pup.fee_info, pop.fee_info, plp.fee_info)), '') AS fee_info,

    -- 5. Generic Flags (priority: google > user > osm > llm)
    COALESCE(pgp.wheelchair_accessible, pup.wheelchair_accessible, pop.wheelchair_accessible, plp.wheelchair_accessible) AS wheelchair_accessible,
    COALESCE(pgp.family_friendly, pup.family_friendly, pop.family_friendly, plp.family_friendly) AS family_friendly,
    COALESCE(pgp.pets_allowed, pup.pets_allowed, pop.pets_allowed, plp.pets_allowed) AS pets_allowed,
    COALESCE(pgp.indoor, pup.indoor, pop.indoor, plp.indoor) AS indoor,
    COALESCE(pgp.outdoor, pup.outdoor, pop.outdoor, plp.outdoor) AS outdoor,
    COALESCE(pgp.entry_fee_required, pup.entry_fee_required, pop.entry_fee_required, plp.entry_fee_required) AS entry_fee_required,
    COALESCE(pgp.reservation_required, pup.reservation_required, pop.reservation_required, plp.reservation_required) AS reservation_required,
    COALESCE(pgp.overnight_stay_allowed, pup.overnight_stay_allowed, pop.overnight_stay_allowed, plp.overnight_stay_allowed) AS overnight_stay_allowed,

    -- 6. General Facilities (priority: google > user > osm > llm)
    COALESCE(pgp.has_parking, pup.has_parking, pop.has_parking, plp.has_parking) AS has_parking,
    COALESCE(pgp.has_restrooms, pup.has_restrooms, pop.has_restrooms, plp.has_restrooms) AS has_restrooms,
    COALESCE(pgp.has_drinking_water, pup.has_drinking_water, pop.has_drinking_water, plp.has_drinking_water) AS has_drinking_water,
    COALESCE(pgp.has_wifi, pup.has_wifi, pop.has_wifi, plp.has_wifi) AS has_wifi,
    COALESCE(pgp.has_shop, pup.has_shop, pop.has_shop, plp.has_shop) AS has_shop,
    COALESCE(pgp.has_restaurant, pup.has_restaurant, pop.has_restaurant, plp.has_restaurant) AS has_restaurant,
    COALESCE(pgp.has_cafe, pup.has_cafe, pop.has_cafe, plp.has_cafe) AS has_cafe,

    -- 7. Camping Permissions (priority: google > user > osm > llm)
    COALESCE(pgp.caravan_allowed, pup.caravan_allowed, pop.caravan_allowed, plp.caravan_allowed) AS caravan_allowed,
    COALESCE(pgp.motorhome_allowed, pup.motorhome_allowed, pop.motorhome_allowed, plp.motorhome_allowed) AS motorhome_allowed,
    COALESCE(pgp.tent_allowed, pup.tent_allowed, pop.tent_allowed, plp.tent_allowed) AS tent_allowed,

    -- 8. Camping Facilities (priority: google > user > osm > llm)
    COALESCE(pgp.has_electricity, pup.has_electricity, pop.has_electricity, plp.has_electricity) AS has_electricity,
    COALESCE(pgp.has_fresh_water, pup.has_fresh_water, pop.has_fresh_water, plp.has_fresh_water) AS has_fresh_water,
    COALESCE(pgp.has_shower, pup.has_shower, pop.has_shower, plp.has_shower) AS has_shower,
    COALESCE(pgp.has_laundry, pup.has_laundry, pop.has_laundry, plp.has_laundry) AS has_laundry,
    COALESCE(pgp.has_dishwashing_area, pup.has_dishwashing_area, pop.has_dishwashing_area, plp.has_dishwashing_area) AS has_dishwashing_area,

    -- 9. Disposal / Utilities (priority: google > user > osm > llm)
    COALESCE(pgp.has_grey_water_disposal, pup.has_grey_water_disposal, pop.has_grey_water_disposal, plp.has_grey_water_disposal) AS has_grey_water_disposal,
    COALESCE(pgp.has_black_water_disposal, pup.has_black_water_disposal, pop.has_black_water_disposal, plp.has_black_water_disposal) AS has_black_water_disposal,
    COALESCE(pgp.has_chemical_toilet_disposal, pup.has_chemical_toilet_disposal, pop.has_chemical_toilet_disposal, plp.has_chemical_toilet_disposal) AS has_chemical_toilet_disposal,
    COALESCE(pgp.has_dump_station, pup.has_dump_station, pop.has_dump_station, plp.has_dump_station) AS has_dump_station,
    COALESCE(pgp.has_waste_disposal, pup.has_waste_disposal, pop.has_waste_disposal, plp.has_waste_disposal) AS has_waste_disposal,
    COALESCE(pgp.has_recycling, pup.has_recycling, pop.has_recycling, plp.has_recycling) AS has_recycling,

    -- 10. Leisure (priority: google > user > osm > llm)
    COALESCE(pgp.has_bbq_area, pup.has_bbq_area, pop.has_bbq_area, plp.has_bbq_area) AS has_bbq_area,
    COALESCE(pgp.has_fire_pit, pup.has_fire_pit, pop.has_fire_pit, plp.has_fire_pit) AS has_fire_pit,
    COALESCE(pgp.has_playground, pup.has_playground, pop.has_playground, plp.has_playground) AS has_playground,
    COALESCE(pgp.has_pool, pup.has_pool, pop.has_pool, plp.has_pool) AS has_pool,
    COALESCE(pgp.has_beach, pup.has_beach, pop.has_beach, plp.has_beach) AS has_beach,

    -- 11. Nudism (priority: google > user > osm > llm)
    COALESCE(pgp.nudism_allowed, pup.nudism_allowed, pop.nudism_allowed, plp.nudism_allowed) AS nudism_allowed,
    COALESCE(pgp.nudism_only, pup.nudism_only, pop.nudism_only, plp.nudism_only) AS nudism_only,

    -- 12. Attraction / Museum (priority: google > user > osm > llm)
    COALESCE(pgp.has_guided_tours, pup.has_guided_tours, pop.has_guided_tours, plp.has_guided_tours) AS has_guided_tours,
    COALESCE(pgp.has_audio_guide, pup.has_audio_guide, pop.has_audio_guide, plp.has_audio_guide) AS has_audio_guide,
    COALESCE(pgp.has_visitor_center, pup.has_visitor_center, pop.has_visitor_center, plp.has_visitor_center) AS has_visitor_center,
    COALESCE(pgp.has_lockers, pup.has_lockers, pop.has_lockers, plp.has_lockers) AS has_lockers,
    COALESCE(pgp.photography_allowed, pup.photography_allowed, pop.photography_allowed, plp.photography_allowed) AS photography_allowed,

    -- 13. Source presence booleans (for filtering/debugging)
    (pop.id IS NOT NULL) AS has_osm,
    (pgp.id IS NOT NULL) AS has_google,
    (plp.id IS NOT NULL) AS has_llm,
    (pup.id IS NOT NULL) AS has_user,

    -- 14. Name source tracking (which source provided the resolved name)
    CASE
        WHEN pgp.name IS NOT NULL AND NULLIF(TRIM(pgp.name), '') IS NOT NULL THEN 'google'
        WHEN pup.name IS NOT NULL AND NULLIF(TRIM(pup.name), '') IS NOT NULL THEN 'user'
        WHEN pop.name IS NOT NULL AND NULLIF(TRIM(pop.name), '') IS NOT NULL THEN 'osm'
        WHEN plp.name IS NOT NULL AND NULLIF(TRIM(plp.name), '') IS NOT NULL THEN 'llm'
        ELSE NULL
    END AS name_source,

    -- 15. Property table timestamps (for staleness detection)
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
    'Resolved place properties with google > user > osm > llm priority per column. User override via auth.uid(). Canonical lat/lon/geom from places table. Use for authenticated user-specific queries.';
