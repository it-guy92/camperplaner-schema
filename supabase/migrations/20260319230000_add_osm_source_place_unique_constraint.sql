SET lock_timeout = '5s';

-- Add unique constraint on osm_source.place_id for upsert operations
-- This was missing after the table was restored in 20260319071000

DROP INDEX IF EXISTS idx_osm_source_place_id;
DROP INDEX IF EXISTS uidx_osm_source_place_current;

-- Create unique index for upsert operations (one osm_source per place)
CREATE UNIQUE INDEX uidx_osm_source_place_unique
    ON osm_source(place_id);

COMMENT ON INDEX uidx_osm_source_place_unique IS
    'Enforces exactly one OSM source row per place_id. Required for upsert operations.';
