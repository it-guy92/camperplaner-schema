CREATE INDEX IF NOT EXISTS idx_trip_stops_trip_day ON trip_stops(trip_id, day_number);
CREATE INDEX IF NOT EXISTS idx_trip_stops_trip_order ON trip_stops(trip_id, order_index);
CREATE INDEX IF NOT EXISTS idx_trips_user_created ON trips(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_campsites_source_updated ON campsites(source_type, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_campsites_price_source ON campsites(price_source) WHERE price_source = 'user';

CREATE INDEX IF NOT EXISTS idx_trips_dates ON trips(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_trips_shared ON trips(share_token) WHERE is_shared = true;

DROP INDEX IF EXISTS idx_campsites_cache_google_expires;
CREATE INDEX idx_campsites_cache_google_expires 
ON campsites_cache(google_data_expires_at) 
WHERE google_data_expires_at IS NOT NULL;

ANALYZE trip_stops;
ANALYZE trips;
ANALYZE campsites;
