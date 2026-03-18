-- Google Place Matches Cache Table
-- Caches successful (and failed) OSM to Google Places matches to avoid repeated API calls

CREATE TABLE IF NOT EXISTS google_place_matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  osm_id TEXT NOT NULL,
  osm_name TEXT NOT NULL,
  osm_lat FLOAT NOT NULL,
  osm_lng FLOAT NOT NULL,
  google_place_id TEXT,
  google_place_name TEXT,
  google_place_address TEXT,
  matched_at TIMESTAMPTZ DEFAULT NOW(),
  match_confidence FLOAT,
  status TEXT DEFAULT 'matched' CHECK (status IN ('matched', 'no_match', 'needs_review')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(osm_id, osm_lat, osm_lng)
);

-- Index for fast lookups by OSM coordinates
CREATE INDEX IF NOT EXISTS idx_google_place_matches_osm_coords 
ON google_place_matches (osm_lat, osm_lng);

-- Index for lookups by OSM ID
CREATE INDEX IF NOT EXISTS idx_google_place_matches_osm_id 
ON google_place_matches (osm_id);

-- Index for finding unmatched entries that could be retried
CREATE INDEX IF NOT EXISTS idx_google_place_matches_status 
ON google_place_matches (status) 
WHERE status = 'no_match';
