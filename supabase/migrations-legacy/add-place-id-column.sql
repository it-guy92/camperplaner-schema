-- Add place_id column to trip_stops for AI descriptions
ALTER TABLE trip_stops 
ADD COLUMN IF NOT EXISTS place_id TEXT;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_trip_stops_place_id ON trip_stops(place_id);

-- Comment
COMMENT ON COLUMN trip_stops.place_id IS 'Google Places or OSM place ID for fetching descriptions';
