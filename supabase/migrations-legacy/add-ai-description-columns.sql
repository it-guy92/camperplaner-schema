-- AI Description System Migration
-- Phase 1: Database Schema Extensions

-- ============================================
-- 1. Add description columns to campsites_cache
-- ============================================

ALTER TABLE campsites_cache 
ADD COLUMN IF NOT EXISTS description TEXT;

ALTER TABLE campsites_cache 
ADD COLUMN IF NOT EXISTS description_source VARCHAR(20) CHECK (
  description_source IN (
    'osm',           -- Directly from OSM tags
    'wikidata',      -- From Wikidata via OSM link
    'google_reviews',-- From Google Reviews via LLM
    'llm_osm',       -- LLM generated from OSM data
    'llm_enhanced',  -- LLM with website scraping
    'user'           -- Manually edited
  )
);

ALTER TABLE campsites_cache 
ADD COLUMN IF NOT EXISTS description_generated_at TIMESTAMPTZ;

ALTER TABLE campsites_cache 
ADD COLUMN IF NOT EXISTS description_version INT DEFAULT 1;

-- ============================================
-- 2. Create indexes for performance
-- ============================================

-- Index for fast lookup of places with descriptions
CREATE INDEX IF NOT EXISTS idx_campsites_cache_description 
ON campsites_cache(place_id) 
WHERE description IS NOT NULL;

-- Index for filtering by source
CREATE INDEX IF NOT EXISTS idx_campsites_cache_description_source 
ON campsites_cache(description_source) 
WHERE description_source IS NOT NULL;

-- ============================================
-- 3. Create description generation jobs table
-- ============================================

CREATE TABLE IF NOT EXISTS description_generation_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  place_id TEXT NOT NULL REFERENCES campsites_cache(place_id) ON DELETE CASCADE,
  status VARCHAR(20) DEFAULT 'pending' CHECK (
    status IN ('pending', 'processing', 'completed', 'failed', 'skipped')
  ),
  priority INT DEFAULT 5 CHECK (priority >= 1 AND priority <= 10),
  attempts INT DEFAULT 0 CHECK (attempts >= 0 AND attempts <= 5),
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  
  UNIQUE(place_id)
);

-- Index for job queue processing
CREATE INDEX IF NOT EXISTS idx_description_jobs_status_priority 
ON description_generation_jobs(status, priority DESC, created_at);

-- Index for finding jobs by place
CREATE INDEX IF NOT EXISTS idx_description_jobs_place_id 
ON description_generation_jobs(place_id);

-- ============================================
-- 4. Enable RLS on jobs table
-- ============================================

ALTER TABLE description_generation_jobs ENABLE ROW LEVEL SECURITY;

-- Only service role can manage jobs
CREATE POLICY "Service role can manage description jobs"
  ON description_generation_jobs FOR ALL
  USING (false)
  WITH CHECK (false);

-- ============================================
-- 5. Create function to auto-update updated_at
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for description_generation_jobs
DROP TRIGGER IF EXISTS update_description_jobs_updated_at 
  ON description_generation_jobs;

CREATE TRIGGER update_description_jobs_updated_at
  BEFORE UPDATE ON description_generation_jobs
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 6. Add metadata tracking
-- ============================================

COMMENT ON TABLE campsites_cache IS 
  'Extended with AI description support (description, description_source, description_generated_at)';

COMMENT ON TABLE description_generation_jobs IS 
  'Queue for background description generation jobs';

COMMENT ON COLUMN campsites_cache.description_source IS 
  'Source of description: osm, wikidata, google_reviews, llm_osm, llm_enhanced, user';

-- ============================================
-- 7. Migration: Populate existing data with null descriptions
-- ============================================

-- Mark all existing records as version 1
UPDATE campsites_cache 
SET description_version = 1 
WHERE description_version IS NULL;

-- Create initial jobs for places without descriptions
-- (Only for places that have been favorited or have user prices - high priority)
INSERT INTO description_generation_jobs (place_id, status, priority)
SELECT 
  cc.place_id,
  'pending',
  CASE 
    WHEN f.place_id IS NOT NULL THEN 2  -- Favorited places = high priority
    WHEN cp.place_id IS NOT NULL THEN 3 -- Places with prices = medium priority
    ELSE 5                              -- Others = normal priority
  END
FROM campsites_cache cc
LEFT JOIN favorites f ON f.place_id = cc.place_id
LEFT JOIN (
  SELECT DISTINCT osm_place_id as place_id 
  FROM campsite_prices
) cp ON cp.place_id = cc.place_id
WHERE cc.description IS NULL
ON CONFLICT (place_id) DO NOTHING;

-- ============================================
-- Verification
-- ============================================

-- Check table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'campsites_cache' 
ORDER BY ordinal_position;

-- Check indexes
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename IN ('campsites_cache', 'description_generation_jobs');

-- Count pending jobs
SELECT status, COUNT(*) 
FROM description_generation_jobs 
GROUP BY status;
