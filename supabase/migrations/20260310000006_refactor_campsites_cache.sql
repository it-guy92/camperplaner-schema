ALTER TABLE campsite_reviews DROP CONSTRAINT IF EXISTS campsite_reviews_user_id_fkey;
ALTER TABLE campsite_reviews ADD CONSTRAINT campsite_reviews_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;

ALTER TABLE campsite_prices DROP CONSTRAINT IF EXISTS campsite_prices_osm_place_id_fkey;
ALTER TABLE campsite_prices RENAME COLUMN osm_place_id TO place_id;

ALTER TABLE favorites DROP CONSTRAINT IF EXISTS favorites_user_id_fkey;
ALTER TABLE favorites ADD CONSTRAINT favorites_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;

ALTER TABLE trip_stops ADD COLUMN IF NOT EXISTS campsite_id TEXT;
ALTER TABLE trip_stops ADD CONSTRAINT fk_trip_stops_campsite 
    FOREIGN KEY (campsite_id) REFERENCES campsites(place_id) ON DELETE SET NULL;

ALTER TABLE description_generation_jobs DROP CONSTRAINT IF EXISTS description_generation_jobs_place_id_fkey;
ALTER TABLE description_generation_jobs ADD CONSTRAINT fk_description_jobs_campsite
    FOREIGN KEY (place_id) REFERENCES campsites(place_id) ON DELETE CASCADE;

ALTER TABLE website_scraping_jobs DROP CONSTRAINT IF EXISTS website_scraping_jobs_place_id_fkey;
ALTER TABLE website_scraping_jobs ADD CONSTRAINT fk_scraping_jobs_campsite
    FOREIGN KEY (place_id) REFERENCES campsites(place_id) ON DELETE CASCADE;

ALTER TABLE campsites_cache ADD COLUMN IF NOT EXISTS campsite_id TEXT;
ALTER TABLE campsites_cache ADD CONSTRAINT fk_campsites_cache_campsite
    FOREIGN KEY (campsite_id) REFERENCES campsites(place_id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_campsite_reviews_place ON campsite_reviews(place_id);
CREATE INDEX IF NOT EXISTS idx_campsite_prices_place ON campsite_prices(place_id);
CREATE INDEX IF NOT EXISTS idx_favorites_place ON favorites(place_id);
CREATE INDEX IF NOT EXISTS idx_trip_stops_campsite ON trip_stops(campsite_id) WHERE campsite_id IS NOT NULL;
