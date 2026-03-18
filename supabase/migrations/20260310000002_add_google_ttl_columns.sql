-- ============================================
-- MIGRATION: Add Google TTL Columns
-- Purpose: Track Google Places data freshness
-- Google ToS: Photos and Reviews must be refreshed/deleted after 30 days
-- ============================================

-- Add timestamp for when Google data was fetched
ALTER TABLE campsites_cache 
ADD COLUMN IF NOT EXISTS google_data_fetched_at TIMESTAMPTZ;

-- Add computed expiration timestamp (30 days after fetch)
-- Note: Using separate column instead of GENERATED for flexibility
-- We'll set expires_at explicitly when fetching data
ALTER TABLE campsites_cache 
ADD COLUMN IF NOT EXISTS google_data_expires_at TIMESTAMPTZ;

-- Add columns for Google-specific data that needs TTL
-- These will hold Photos and Reviews which have 30-day TTL
ALTER TABLE campsites_cache 
ADD COLUMN IF NOT EXISTS google_photos JSONB;

ALTER TABLE campsites_cache 
ADD COLUMN IF NOT EXISTS google_reviews JSONB;

-- Create index for efficient cleanup queries
CREATE INDEX IF NOT EXISTS idx_campsites_cache_google_expires 
ON campsites_cache(google_data_expires_at) 
WHERE google_data_expires_at IS NOT NULL;

-- Create index for finding records with Google data
CREATE INDEX IF NOT EXISTS idx_campsites_cache_has_google_data 
ON campsites_cache(place_id) 
WHERE google_photos IS NOT NULL OR google_reviews IS NOT NULL;

-- ============================================
-- COMMENTS
-- ============================================
COMMENT ON COLUMN campsites_cache.google_data_fetched_at IS 
  'Timestamp when Google Places data was last fetched';

COMMENT ON COLUMN campsites_cache.google_data_expires_at IS 
  'Google data expires 30 days after fetch (Google ToS requirement)';

COMMENT ON COLUMN campsites_cache.google_photos IS 
  'Google Places photos (JSONB array) - 30 day TTL per Google ToS';

COMMENT ON COLUMN campsites_cache.google_reviews IS 
  'Google Places reviews (JSONB array) - 30 day TTL per Google ToS';

-- ============================================
-- VERIFICATION
-- ============================================
-- Run this to verify after applying:
-- SELECT column_name, data_type 
-- FROM information_schema.columns 
-- WHERE table_name = 'campsites_cache' 
-- AND column_name LIKE 'google_%';
