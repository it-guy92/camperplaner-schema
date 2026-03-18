-- Backfill missing historical rows from place_llm_enrichments into place_llm_properties.
-- Keeps one-current-row semantics by forcing additional rows to is_current=false when needed.

SET lock_timeout = '10s';
SET statement_timeout = '15min';

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
  opening_hours,
  fee_info,
  llm_enrichment_id,
  provider,
  model,
  summary_de,
  trust_score,
  source_urls
)
SELECT
  ple.place_id,
  CASE
    WHEN ple.is_current = true
      AND NOT EXISTS (
        SELECT 1
        FROM place_llm_properties plp_current
        WHERE plp_current.place_id = ple.place_id
          AND plp_current.is_current = true
      )
    THEN true
    ELSE false
  END AS is_current,
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
  p.opening_hours,
  p.fee_info,
  ple.id,
  ple.provider,
  ple.model,
  ple.summary_de,
  ple.confidence,
  NULL::jsonb
FROM place_llm_enrichments ple
LEFT JOIN places p
  ON p.id = ple.place_id
WHERE NOT EXISTS (
  SELECT 1
  FROM place_llm_properties plp
  WHERE plp.llm_enrichment_id = ple.id
);
