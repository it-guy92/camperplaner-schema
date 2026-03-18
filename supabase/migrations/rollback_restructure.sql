-- ============================================
-- ROLLBACK SCRIPT
-- Reverts all schema changes from the restructuring
-- Run in REVERSE order of migrations
-- ============================================

BEGIN;

-- Disable triggers first
DROP TRIGGER IF EXISTS update_campsites_updated_at ON campsites;

-- Drop views (depend on tables)
DROP VIEW IF EXISTS campsite_with_stats;
DROP VIEW IF EXISTS campsite_full;

-- Drop new tables
DROP TABLE IF EXISTS cleanup_log;

-- Restore campsite_prices FK to auth.users
ALTER TABLE campsite_prices 
DROP CONSTRAINT IF EXISTS campsite_prices_user_id_fkey;

ALTER TABLE campsite_prices 
ADD CONSTRAINT campsite_prices_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Drop Google TTL columns from campsites_cache
ALTER TABLE campsites_cache 
DROP COLUMN IF EXISTS google_data_fetched_at,
DROP COLUMN IF EXISTS google_data_expires_at,
DROP COLUMN IF EXISTS google_photos,
DROP COLUMN IF EXISTS google_reviews;

-- Drop indexes created in restructuring
DROP INDEX IF EXISTS idx_campsites_cache_google_expires;
DROP INDEX IF EXISTS idx_campsites_cache_has_google_data;
DROP INDEX IF EXISTS idx_trip_stops_trip_day;
DROP INDEX IF EXISTS idx_trip_stops_trip_order;
DROP INDEX IF EXISTS idx_trips_user_created;
DROP INDEX IF EXISTS idx_trips_dates;
DROP INDEX IF EXISTS idx_trips_shared;
DROP INDEX IF EXISTS idx_campsites_source_updated;
DROP INDEX IF EXISTS idx_campsites_price_source;
DROP INDEX IF EXISTS idx_trip_stops_campsite;

-- Drop PostGIS columns (keep original JSONB coords)
ALTER TABLE trips DROP COLUMN IF EXISTS start_location_geo;
ALTER TABLE trips DROP COLUMN IF EXISTS end_location_geo;
ALTER TABLE trip_stops DROP COLUMN IF EXISTS location_geo;
ALTER TABLE favorites DROP COLUMN IF EXISTS location_geo;
ALTER TABLE google_place_matches DROP COLUMN IF EXISTS osm_location;

-- Drop new FK constraints
ALTER TABLE trip_stops DROP CONSTRAINT IF EXISTS fk_trip_stops_campsite;
ALTER TABLE trip_stops DROP COLUMN IF EXISTS campsite_id;

-- Restore original FK references
ALTER TABLE campsite_reviews 
DROP CONSTRAINT IF EXISTS campsite_reviews_user_id_fkey,
ADD CONSTRAINT campsite_reviews_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE campsite_prices 
DROP CONSTRAINT IF EXISTS fk_campsite_prices_campsite;

ALTER TABLE favorites 
DROP CONSTRAINT IF EXISTS favorites_user_id_fkey,
ADD CONSTRAINT favorites_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Drop ENUM types (convert back to TEXT with CHECK constraints)
ALTER TABLE profiles ALTER COLUMN role TYPE TEXT;
ALTER TABLE trip_stops ALTER COLUMN type TYPE TEXT;
ALTER TABLE trip_stops ALTER COLUMN cost_type TYPE TEXT;
ALTER TABLE description_generation_jobs ALTER COLUMN status TYPE TEXT;

DROP TYPE IF EXISTS user_role;
DROP TYPE IF EXISTS stop_type;
DROP TYPE IF EXISTS cost_type;
DROP TYPE IF EXISTS job_status;
DROP TYPE IF EXISTS price_source_enum;
DROP TYPE IF EXISTS description_source_enum;

-- Remove pg_cron job for cleanup
SELECT cron.unschedule('cleanup-google-data') WHERE EXISTS (
    SELECT 1 FROM cron.job WHERE jobname = 'cleanup-google-data'
);

COMMIT;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================
-- After rollback, verify:
-- SELECT tablename FROM pg_tables WHERE schemaname = 'public';
-- \d campsites_cache
-- \d trip_stops
-- \d campsite_prices
