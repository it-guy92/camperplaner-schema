-- Backfill aligned property tables and remove deprecated fact/amenity tables
-- This migration is idempotent for backfill inserts via current-row existence checks.

SET lock_timeout = '10s';
SET statement_timeout = '15min';

-- ============================================================================
-- 1) Backfill OSM properties from places + current osm_source
-- ============================================================================

INSERT INTO place_osm_properties (
  place_id,
  is_current,
  created_at,
  updated_at,
  source_updated_at,
  name,
  place_type,
  source_place_type,
  country_code,
  region,
  city,
  postcode,
  address,
  source_lat,
  source_lon,
  website,
  phone,
  email,
  opening_hours,
  fee_info,
  has_restrooms,
  has_shower,
  has_electricity,
  has_fresh_water,
  has_drinking_water,
  has_wifi,
  pets_allowed,
  caravan_allowed,
  motorhome_allowed,
  tent_allowed,
  osm_source_id,
  osm_id,
  osm_type,
  osm_version,
  osm_timestamp
)
SELECT
  p.id,
  true,
  p.created_at,
  p.updated_at,
  COALESCE(os.osm_timestamp, p.updated_at),
  p.name,
  p.place_type,
  p.place_type,
  p.country_code,
  p.region,
  p.city,
  p.postcode,
  p.address,
  p.lat,
  p.lon,
  p.website,
  p.phone,
  p.email,
  p.opening_hours,
  p.fee_info,
  p.has_toilet,
  p.has_shower,
  p.has_electricity,
  p.has_water,
  p.has_water,
  p.has_wifi,
  p.pet_friendly,
  p.caravan_allowed,
  p.motorhome_allowed,
  p.tent_allowed,
  os.id,
  os.osm_id,
  os.osm_type,
  os.osm_version,
  os.osm_timestamp
FROM places p
LEFT JOIN osm_source os
  ON os.place_id = p.id
 AND os.is_current = true
WHERE NOT EXISTS (
  SELECT 1
  FROM place_osm_properties pop
  WHERE pop.place_id = p.id
    AND pop.is_current = true
);

-- ============================================================================
-- 2) Backfill Google properties from current place_google_sources
-- ============================================================================

WITH google_types_agg AS (
  SELECT
    pgt.google_source_id,
    array_agg(pgt.google_type ORDER BY pgt.is_primary DESC, pgt.id) AS source_categories
  FROM place_google_types pgt
  GROUP BY pgt.google_source_id
),
google_amenities_ranked AS (
  SELECT
    pga.google_source_id,
    pga.amenity_key,
    pga.value_boolean,
    ROW_NUMBER() OVER (
      PARTITION BY pga.google_source_id, pga.amenity_key
      ORDER BY pga.updated_at DESC, pga.id DESC
    ) AS rn
  FROM place_google_amenities pga
),
google_amenities_latest AS (
  SELECT
    gar.google_source_id,
    BOOL_OR(CASE WHEN gar.amenity_key IN ('has_toilet', 'has_restrooms') THEN gar.value_boolean END) AS has_restrooms,
    BOOL_OR(CASE WHEN gar.amenity_key IN ('has_shower', 'has_showers') THEN gar.value_boolean END) AS has_shower,
    BOOL_OR(CASE WHEN gar.amenity_key = 'has_electricity' THEN gar.value_boolean END) AS has_electricity,
    BOOL_OR(CASE WHEN gar.amenity_key IN ('has_water', 'has_fresh_water') THEN gar.value_boolean END) AS has_fresh_water,
    BOOL_OR(CASE WHEN gar.amenity_key = 'has_wifi' THEN gar.value_boolean END) AS has_wifi,
    BOOL_OR(CASE WHEN gar.amenity_key IN ('pet_friendly', 'pets_allowed') THEN gar.value_boolean END) AS pets_allowed,
    BOOL_OR(CASE WHEN gar.amenity_key = 'caravan_allowed' THEN gar.value_boolean END) AS caravan_allowed,
    BOOL_OR(CASE WHEN gar.amenity_key = 'motorhome_allowed' THEN gar.value_boolean END) AS motorhome_allowed,
    BOOL_OR(CASE WHEN gar.amenity_key = 'tent_allowed' THEN gar.value_boolean END) AS tent_allowed,
    BOOL_OR(CASE WHEN gar.amenity_key = 'has_playground' THEN gar.value_boolean END) AS has_playground,
    BOOL_OR(CASE WHEN gar.amenity_key = 'has_pool' THEN gar.value_boolean END) AS has_pool,
    BOOL_OR(CASE WHEN gar.amenity_key = 'has_laundry' THEN gar.value_boolean END) AS has_laundry
  FROM google_amenities_ranked gar
  WHERE gar.rn = 1
  GROUP BY gar.google_source_id
)
INSERT INTO place_google_properties (
  place_id,
  is_current,
  created_at,
  updated_at,
  source_updated_at,
  name,
  place_type,
  source_place_type,
  source_categories,
  address,
  source_lat,
  source_lon,
  website,
  phone,
  has_restrooms,
  has_shower,
  has_electricity,
  has_fresh_water,
  has_drinking_water,
  has_wifi,
  pets_allowed,
  caravan_allowed,
  motorhome_allowed,
  tent_allowed,
  has_playground,
  has_pool,
  has_laundry,
  google_source_id,
  google_place_id,
  rating,
  review_count,
  business_status,
  expires_at
)
SELECT
  pgs.place_id,
  true,
  pgs.created_at,
  pgs.updated_at,
  pgs.fetched_at,
  pgs.name,
  p.place_type,
  p.place_type,
  gta.source_categories,
  pgs.formatted_address,
  pgs.lat,
  pgs.lon,
  pgs.website,
  pgs.phone,
  gal.has_restrooms,
  gal.has_shower,
  gal.has_electricity,
  gal.has_fresh_water,
  gal.has_fresh_water,
  gal.has_wifi,
  gal.pets_allowed,
  gal.caravan_allowed,
  gal.motorhome_allowed,
  gal.tent_allowed,
  gal.has_playground,
  gal.has_pool,
  gal.has_laundry,
  pgs.id,
  pgs.google_place_id,
  pgs.rating,
  pgs.review_count,
  pgs.business_status,
  pgs.expires_at
FROM place_google_sources pgs
LEFT JOIN places p
  ON p.id = pgs.place_id
LEFT JOIN google_types_agg gta
  ON gta.google_source_id = pgs.id
LEFT JOIN google_amenities_latest gal
  ON gal.google_source_id = pgs.id
WHERE pgs.is_current = true
  AND NOT EXISTS (
    SELECT 1
    FROM place_google_properties pgp
    WHERE pgp.place_id = pgs.place_id
      AND pgp.is_current = true
  );

-- ============================================================================
-- 3) Backfill LLM properties from current enrichments + facts/sources
-- ============================================================================

WITH llm_sources_agg AS (
  SELECT
    pls.llm_enrichment_id,
    jsonb_agg(pls.source_url ORDER BY pls.id) AS source_urls
  FROM place_llm_sources pls
  GROUP BY pls.llm_enrichment_id
),
llm_facts_ranked AS (
  SELECT
    plf.llm_enrichment_id,
    plf.field_name,
    plf.value_text,
    ROW_NUMBER() OVER (
      PARTITION BY plf.llm_enrichment_id, plf.field_name
      ORDER BY plf.updated_at DESC, plf.id DESC
    ) AS rn
  FROM place_llm_facts plf
),
llm_facts_pivot AS (
  SELECT
    lfr.llm_enrichment_id,
    MAX(CASE WHEN lfr.field_name = 'contact_phone' THEN lfr.value_text END) AS contact_phone,
    MAX(CASE WHEN lfr.field_name = 'contact_email' THEN lfr.value_text END) AS contact_email,
    MAX(CASE WHEN lfr.field_name = 'has_wifi' THEN lower(lfr.value_text) END) AS has_wifi_text,
    MAX(CASE WHEN lfr.field_name = 'has_water' THEN lower(lfr.value_text) END) AS has_water_text,
    MAX(CASE WHEN lfr.field_name = 'has_restrooms' THEN lower(lfr.value_text) END) AS has_restrooms_text,
    MAX(CASE WHEN lfr.field_name = 'has_showers' THEN lower(lfr.value_text) END) AS has_showers_text,
    MAX(CASE WHEN lfr.field_name = 'has_electricity' THEN lower(lfr.value_text) END) AS has_electricity_text,
    MAX(CASE WHEN lfr.field_name = 'has_laundry' THEN lower(lfr.value_text) END) AS has_laundry_text,
    MAX(CASE WHEN lfr.field_name = 'has_playground' THEN lower(lfr.value_text) END) AS has_playground_text,
    MAX(CASE WHEN lfr.field_name = 'has_pool' THEN lower(lfr.value_text) END) AS has_pool_text,
    MAX(CASE WHEN lfr.field_name = 'has_pet_friendly' THEN lower(lfr.value_text) END) AS has_pet_friendly_text,
    MAX(CASE WHEN lfr.field_name = 'has_caravan_sites' THEN lower(lfr.value_text) END) AS has_caravan_sites_text,
    MAX(CASE WHEN lfr.field_name = 'has_campervan_sites' THEN lower(lfr.value_text) END) AS has_campervan_sites_text,
    MAX(CASE WHEN lfr.field_name = 'has_tent_sites' THEN lower(lfr.value_text) END) AS has_tent_sites_text,
    MAX(CASE WHEN lfr.field_name = 'has_handicap_access' THEN lower(lfr.value_text) END) AS has_handicap_access_text
  FROM llm_facts_ranked lfr
  WHERE lfr.rn = 1
  GROUP BY lfr.llm_enrichment_id
)
INSERT INTO place_llm_properties (
  place_id,
  is_current,
  created_at,
  updated_at,
  source_updated_at,
  name,
  description,
  place_type,
  source_place_type,
  country_code,
  region,
  city,
  postcode,
  address,
  source_lat,
  source_lon,
  website,
  phone,
  email,
  opening_hours,
  fee_info,
  wheelchair_accessible,
  pets_allowed,
  has_restrooms,
  has_drinking_water,
  has_wifi,
  caravan_allowed,
  motorhome_allowed,
  tent_allowed,
  has_electricity,
  has_fresh_water,
  has_shower,
  has_laundry,
  has_playground,
  has_pool,
  llm_enrichment_id,
  provider,
  model,
  summary_de,
  trust_score,
  source_urls
)
SELECT
  ple.place_id,
  true,
  ple.created_at,
  ple.updated_at,
  COALESCE(ple.completed_at, ple.updated_at),
  p.name,
  ple.summary_de,
  p.place_type,
  p.place_type,
  p.country_code,
  p.region,
  p.city,
  p.postcode,
  p.address,
  p.lat,
  p.lon,
  p.website,
  lfp.contact_phone,
  lfp.contact_email,
  p.opening_hours,
  p.fee_info,
  CASE WHEN lfp.has_handicap_access_text IN ('true','1','yes','y','ja') THEN true
       WHEN lfp.has_handicap_access_text IN ('false','0','no','n','nein') THEN false
       ELSE NULL END,
  CASE WHEN lfp.has_pet_friendly_text IN ('true','1','yes','y','ja') THEN true
       WHEN lfp.has_pet_friendly_text IN ('false','0','no','n','nein') THEN false
       ELSE NULL END,
  CASE WHEN lfp.has_restrooms_text IN ('true','1','yes','y','ja') THEN true
       WHEN lfp.has_restrooms_text IN ('false','0','no','n','nein') THEN false
       ELSE NULL END,
  CASE WHEN lfp.has_water_text IN ('true','1','yes','y','ja') THEN true
       WHEN lfp.has_water_text IN ('false','0','no','n','nein') THEN false
       ELSE NULL END,
  CASE WHEN lfp.has_wifi_text IN ('true','1','yes','y','ja') THEN true
       WHEN lfp.has_wifi_text IN ('false','0','no','n','nein') THEN false
       ELSE NULL END,
  CASE WHEN lfp.has_caravan_sites_text IN ('true','1','yes','y','ja') THEN true
       WHEN lfp.has_caravan_sites_text IN ('false','0','no','n','nein') THEN false
       ELSE NULL END,
  CASE WHEN lfp.has_campervan_sites_text IN ('true','1','yes','y','ja') THEN true
       WHEN lfp.has_campervan_sites_text IN ('false','0','no','n','nein') THEN false
       ELSE NULL END,
  CASE WHEN lfp.has_tent_sites_text IN ('true','1','yes','y','ja') THEN true
       WHEN lfp.has_tent_sites_text IN ('false','0','no','n','nein') THEN false
       ELSE NULL END,
  CASE WHEN lfp.has_electricity_text IN ('true','1','yes','y','ja') THEN true
       WHEN lfp.has_electricity_text IN ('false','0','no','n','nein') THEN false
       ELSE NULL END,
  CASE WHEN lfp.has_water_text IN ('true','1','yes','y','ja') THEN true
       WHEN lfp.has_water_text IN ('false','0','no','n','nein') THEN false
       ELSE NULL END,
  CASE WHEN lfp.has_showers_text IN ('true','1','yes','y','ja') THEN true
       WHEN lfp.has_showers_text IN ('false','0','no','n','nein') THEN false
       ELSE NULL END,
  CASE WHEN lfp.has_laundry_text IN ('true','1','yes','y','ja') THEN true
       WHEN lfp.has_laundry_text IN ('false','0','no','n','nein') THEN false
       ELSE NULL END,
  CASE WHEN lfp.has_playground_text IN ('true','1','yes','y','ja') THEN true
       WHEN lfp.has_playground_text IN ('false','0','no','n','nein') THEN false
       ELSE NULL END,
  CASE WHEN lfp.has_pool_text IN ('true','1','yes','y','ja') THEN true
       WHEN lfp.has_pool_text IN ('false','0','no','n','nein') THEN false
       ELSE NULL END,
  ple.id,
  ple.provider,
  ple.model,
  ple.summary_de,
  ple.confidence,
  lsa.source_urls
FROM place_llm_enrichments ple
LEFT JOIN places p
  ON p.id = ple.place_id
LEFT JOIN llm_facts_pivot lfp
  ON lfp.llm_enrichment_id = ple.id
LEFT JOIN llm_sources_agg lsa
  ON lsa.llm_enrichment_id = ple.id
WHERE ple.is_current = true
  AND NOT EXISTS (
    SELECT 1
    FROM place_llm_properties plp
    WHERE plp.place_id = ple.place_id
      AND plp.is_current = true
  );

-- ============================================================================
-- 4) Drop deprecated amenity/fact/evidence tables after backfill
-- ============================================================================

DROP TABLE IF EXISTS place_google_amenities;
DROP TABLE IF EXISTS place_google_types;

DROP TABLE IF EXISTS place_llm_evidence_markers;
DROP TABLE IF EXISTS place_llm_sources;
DROP TABLE IF EXISTS place_llm_facts;

DROP TABLE IF EXISTS place_evidence_markers;
DROP TABLE IF EXISTS place_evidence_sources;
DROP TABLE IF EXISTS place_source_evidence_runs;
