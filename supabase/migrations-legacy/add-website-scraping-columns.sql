-- Website Scraping System Migration
-- Phase 1: Database Schema Extensions

-- ============================================
-- 1. Add scraping columns to campsites_cache
-- ============================================

-- Website URL
ALTER TABLE campsites_cache 
ADD COLUMN IF NOT EXISTS website TEXT;

-- Öffnungszeiten als Text
ALTER TABLE campsites_cache 
ADD COLUMN IF NOT EXISTS opening_hours TEXT;

-- Telefonnummer
ALTER TABLE campsites_cache 
ADD COLUMN IF NOT EXISTS contact_phone TEXT;

-- E-Mail-Adresse
ALTER TABLE campsites_cache 
ADD COLUMN IF NOT EXISTS contact_email TEXT;

-- URL der gescrapten Webseite
ALTER TABLE campsites_cache 
ADD COLUMN IF NOT EXISTS scraped_website_url TEXT;

-- Zeitstempel des letzten Scrapings
ALTER TABLE campsites_cache 
ADD COLUMN IF NOT EXISTS scraped_at TIMESTAMPTZ;

-- Strukturierte Preisdaten als JSON
ALTER TABLE campsites_cache 
ADD COLUMN IF NOT EXISTS scraped_price_info JSONB;

-- Quelle der Scraping-Daten
ALTER TABLE campsites_cache 
ADD COLUMN IF NOT EXISTS scraped_data_source VARCHAR(20) CHECK (
  scraped_data_source IN ('website', 'user', 'osm')
);

-- ============================================
-- 2. Create website_scraping_jobs table
-- ============================================

CREATE TABLE IF NOT EXISTS website_scraping_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  place_id TEXT NOT NULL REFERENCES campsites_cache(place_id) ON DELETE CASCADE,
  website_url TEXT NOT NULL,
  status VARCHAR(20) DEFAULT 'pending' CHECK (
    status IN ('pending', 'processing', 'completed', 'failed')
  ),
  priority INT DEFAULT 5 CHECK (priority >= 1 AND priority <= 10),
  attempts INT DEFAULT 0 CHECK (attempts >= 0 AND attempts <= 3),
  extracted_data JSONB,          -- Vollständiges LLM-Ergebnis
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  
  UNIQUE(place_id)  -- Nur ein Job pro Place
);

-- ============================================
-- 3. Create indexes for performance
-- ============================================

-- Index for job queue processing (status + priority DESC + created_at)
CREATE INDEX IF NOT EXISTS idx_website_scraping_jobs_queue 
ON website_scraping_jobs(status, priority DESC, created_at);

-- Index for finding recently scraped campsites
CREATE INDEX IF NOT EXISTS idx_campsites_cache_scraped_at 
ON campsites_cache(scraped_at) 
WHERE scraped_at IS NOT NULL;

-- Index for finding jobs by website URL
CREATE INDEX IF NOT EXISTS idx_website_scraping_jobs_website_url 
ON website_scraping_jobs(website_url);

-- ============================================
-- 4. Enable RLS on website_scraping_jobs
-- ============================================

ALTER TABLE website_scraping_jobs ENABLE ROW LEVEL SECURITY;

-- Only service role can manage scraping jobs
CREATE POLICY "Service role can manage scraping jobs"
  ON website_scraping_jobs FOR ALL
  USING (false)
  WITH CHECK (false);

-- ============================================
-- 5. Create trigger for auto-update updated_at
-- ============================================

-- Reuse existing function if it exists, otherwise create it
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for website_scraping_jobs
DROP TRIGGER IF EXISTS update_website_scraping_jobs_updated_at 
  ON website_scraping_jobs;

CREATE TRIGGER update_website_scraping_jobs_updated_at
  BEFORE UPDATE ON website_scraping_jobs
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 6. Add column comments
-- ============================================

COMMENT ON COLUMN campsites_cache.opening_hours IS 
  'Öffnungszeiten als Text';

COMMENT ON COLUMN campsites_cache.contact_phone IS 
  'Telefonnummer des Campingplatzes';

COMMENT ON COLUMN campsites_cache.contact_email IS 
  'E-Mail-Adresse des Campingplatzes';

COMMENT ON COLUMN campsites_cache.scraped_website_url IS 
  'URL der gescrapten Webseite';

COMMENT ON COLUMN campsites_cache.scraped_at IS 
  'Zeitstempel des letzten Scrapings';

COMMENT ON COLUMN campsites_cache.scraped_price_info IS 
  'Strukturierte Preisdaten als JSON (z.B. {"adult": 10, "child": 5, "currency": "EUR"})';

COMMENT ON COLUMN campsites_cache.scraped_data_source IS 
  'Quelle der Scraping-Daten: website (automatisch), user (manuell), osm (OpenStreetMap)';

COMMENT ON TABLE website_scraping_jobs IS 
  'Queue für Website-Scraping Jobs mit LLM-Extraktion';

COMMENT ON COLUMN website_scraping_jobs.extracted_data IS 
  'Vollständiges extrahiertes LLM-Ergebnis als JSON';

-- ============================================
-- Verification
-- ============================================

-- Check new columns in campsites_cache
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'campsites_cache' 
  AND column_name IN (
    'opening_hours', 
    'contact_phone', 
    'contact_email', 
    'scraped_website_url', 
    'scraped_at', 
    'scraped_price_info', 
    'scraped_data_source'
  )
ORDER BY column_name;

-- Check website_scraping_jobs table
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'website_scraping_jobs' 
ORDER BY ordinal_position;

-- Check indexes
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename IN ('campsites_cache', 'website_scraping_jobs')
  AND indexname LIKE '%scraping%';
