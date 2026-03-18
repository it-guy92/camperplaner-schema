CREATE EXTENSION IF NOT EXISTS postgis;

ALTER TABLE trips ADD COLUMN IF NOT EXISTS start_location_geo GEOGRAPHY(POINT, 4326);
ALTER TABLE trips ADD COLUMN IF NOT EXISTS end_location_geo GEOGRAPHY(POINT, 4326);

UPDATE trips 
SET start_location_geo = ST_SetSRID(ST_MakePoint(
    (start_coords->>'lng')::float, 
    (start_coords->>'lat')::float
), 4326)::geography
WHERE start_coords IS NOT NULL AND start_location_geo IS NULL;

UPDATE trips 
SET end_location_geo = ST_SetSRID(ST_MakePoint(
    (end_coords->>'lng')::float, 
    (end_coords->>'lat')::float
), 4326)::geography
WHERE end_coords IS NOT NULL AND end_location_geo IS NULL;

CREATE INDEX IF NOT EXISTS idx_trips_start_location ON trips USING GIST(start_location_geo);
CREATE INDEX IF NOT EXISTS idx_trips_end_location ON trips USING GIST(end_location_geo);

ALTER TABLE trip_stops ADD COLUMN IF NOT EXISTS location_geo GEOGRAPHY(POINT, 4326);

UPDATE trip_stops 
SET location_geo = ST_SetSRID(ST_MakePoint(
    (coordinates->>'lng')::float, 
    (coordinates->>'lat')::float
), 4326)::geography
WHERE coordinates IS NOT NULL AND location_geo IS NULL;

CREATE INDEX IF NOT EXISTS idx_trip_stops_location ON trip_stops USING GIST(location_geo);

ALTER TABLE favorites ADD COLUMN IF NOT EXISTS location_geo GEOGRAPHY(POINT, 4326);

UPDATE favorites 
SET location_geo = ST_SetSRID(ST_MakePoint(
    (coordinates->>'lng')::float, 
    (coordinates->>'lat')::float
), 4326)::geography
WHERE coordinates IS NOT NULL AND location_geo IS NULL;

CREATE INDEX IF NOT EXISTS idx_favorites_location ON favorites USING GIST(location_geo);

ALTER TABLE google_place_matches ADD COLUMN IF NOT EXISTS osm_location GEOGRAPHY(POINT, 4326);

UPDATE google_place_matches 
SET osm_location = ST_SetSRID(ST_MakePoint(osm_lng, osm_lat), 4326)::geography
WHERE osm_location IS NULL;

CREATE INDEX IF NOT EXISTS idx_google_place_matches_location ON google_place_matches USING GIST(osm_location);
