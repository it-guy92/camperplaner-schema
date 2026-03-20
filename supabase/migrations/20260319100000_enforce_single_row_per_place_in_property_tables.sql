SET lock_timeout = '5s';

WITH ranked AS (
    SELECT
        id,
        row_number() OVER (
            PARTITION BY place_id
            ORDER BY
                is_current DESC,
                source_updated_at DESC NULLS LAST,
                updated_at DESC,
                created_at DESC,
                id DESC
        ) AS rn
    FROM place_osm_properties
)
DELETE FROM place_osm_properties p
USING ranked r
WHERE p.id = r.id
  AND r.rn > 1;

WITH ranked AS (
    SELECT
        id,
        row_number() OVER (
            PARTITION BY place_id
            ORDER BY
                is_current DESC,
                source_updated_at DESC NULLS LAST,
                updated_at DESC,
                created_at DESC,
                id DESC
        ) AS rn
    FROM place_google_properties
)
DELETE FROM place_google_properties p
USING ranked r
WHERE p.id = r.id
  AND r.rn > 1;

WITH ranked AS (
    SELECT
        id,
        row_number() OVER (
            PARTITION BY place_id
            ORDER BY
                is_current DESC,
                source_updated_at DESC NULLS LAST,
                updated_at DESC,
                created_at DESC,
                id DESC
        ) AS rn
    FROM place_llm_properties
)
DELETE FROM place_llm_properties p
USING ranked r
WHERE p.id = r.id
  AND r.rn > 1;

UPDATE place_osm_properties
SET is_current = true
WHERE is_current IS DISTINCT FROM true;

UPDATE place_google_properties
SET is_current = true
WHERE is_current IS DISTINCT FROM true;

UPDATE place_llm_properties
SET is_current = true
WHERE is_current IS DISTINCT FROM true;


DROP INDEX IF EXISTS uidx_osm_properties_place_current;
DROP INDEX IF EXISTS uidx_google_properties_place_current;
DROP INDEX IF EXISTS uidx_llm_properties_place_current;

CREATE UNIQUE INDEX IF NOT EXISTS uidx_osm_properties_place_unique
    ON place_osm_properties(place_id);

CREATE UNIQUE INDEX IF NOT EXISTS uidx_google_properties_place_unique
    ON place_google_properties(place_id);

CREATE UNIQUE INDEX IF NOT EXISTS uidx_llm_properties_place_unique
    ON place_llm_properties(place_id);

COMMENT ON INDEX uidx_osm_properties_place_unique IS
    'Enforces exactly one OSM property row per place_id.';

COMMENT ON INDEX uidx_google_properties_place_unique IS
    'Enforces exactly one Google property row per place_id.';

COMMENT ON INDEX uidx_llm_properties_place_unique IS
    'Enforces exactly one LLM property row per place_id.';
