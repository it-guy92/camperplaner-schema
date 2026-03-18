-- ============================================
-- BASELINE MIGRATION
-- Captures the current database schema state
-- Generated: 2026-03-10
-- ============================================

-- This migration represents the baseline state before restructuring.
-- All future migrations will build upon this foundation.

-- Note: This file documents the existing schema. The actual tables
-- were created via the SQL files in the project root.

-- ============================================
-- EXISTING TABLES (as of baseline)
-- ============================================

-- profiles: User profiles extending auth.users
-- trips: Trip/route data
-- trip_stops: Daily stops for trips
-- campsites_cache: POI cache (to be restructured)
-- campsite_prices: User-submitted prices
-- campsite_reviews: User reviews
-- favorites: User favorites
-- vehicle_profiles: Vehicle configurations
-- trip_reminders: Trip reminders
-- app_errors: Error tracking
-- google_place_matches: OSM to Google mapping
-- description_generation_jobs: AI description queue
-- website_scraping_jobs: Website scraping queue

-- ============================================
-- MIGRATION NOTES
-- ============================================

-- Wave 1 migrations (this baseline + immediate fixes):
--   20260310000001_fix_campsite_prices_fk.sql
--   20260310000002_add_google_ttl_columns.sql

-- Wave 2 migrations:
--   20260310000003_create_enum_types.sql
--   20260310000004_migrate_to_postgis.sql

-- Wave 3 migrations:
--   20260310000005_create_campsites_table.sql
--   20260310000006_refactor_campsites_cache.sql
--   20260310000007_create_campsite_full_view.sql
--   20260310000008_create_google_cleanup_job.sql

-- Wave 4 migrations:
--   20260310000009_create_composite_indexes.sql
--   20260310000010_migrate_campsites_data.sql
