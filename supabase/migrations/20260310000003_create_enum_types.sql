CREATE TYPE user_role AS ENUM ('user', 'admin');
CREATE TYPE stop_type AS ENUM ('camping', 'stellplatz', 'poi', 'city', 'address');
CREATE TYPE cost_type AS ENUM ('per_night', 'entry_fee', 'none');
CREATE TYPE job_status AS ENUM ('pending', 'processing', 'completed', 'failed', 'skipped');
CREATE TYPE price_source_enum AS ENUM ('user', 'osm', 'estimated');
CREATE TYPE description_source_enum AS ENUM ('osm', 'wikidata', 'google_reviews', 'llm_osm', 'llm_enhanced', 'user');

UPDATE profiles SET role = 'user' WHERE role IS NULL OR role NOT IN ('user', 'admin');
UPDATE trip_stops SET type = 'camping' WHERE type IS NULL OR type NOT IN ('camping', 'stellplatz', 'poi', 'city', 'address');
UPDATE trip_stops SET cost_type = 'per_night' WHERE cost_type IS NULL OR cost_type NOT IN ('per_night', 'entry_fee', 'none');

DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'trip_stops'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON trip_stops', pol.policyname);
    END LOOP;
END $$;

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "profiles_select_own" ON profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON profiles;

ALTER TABLE profiles ALTER COLUMN role DROP DEFAULT;
ALTER TABLE profiles ALTER COLUMN role TYPE user_role USING role::user_role;
ALTER TABLE profiles ALTER COLUMN role SET DEFAULT 'user'::user_role;

ALTER TABLE trip_stops ALTER COLUMN type TYPE stop_type USING type::stop_type;
ALTER TABLE trip_stops ALTER COLUMN cost_type TYPE cost_type USING cost_type::cost_type;

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "trip_stops_select_own" ON trip_stops
  FOR SELECT
  USING (auth.uid() IN (SELECT user_id FROM trips WHERE trips.id = trip_stops.trip_id));

CREATE POLICY "trip_stops_select_shared" ON trip_stops
  FOR SELECT
  USING (EXISTS (SELECT 1 FROM trips WHERE trips.id = trip_stops.trip_id AND trips.is_shared = true));

CREATE POLICY "trip_stops_insert_own" ON trip_stops
  FOR INSERT
  WITH CHECK (auth.uid() IN (SELECT user_id FROM trips WHERE trips.id = trip_stops.trip_id));

CREATE POLICY "trip_stops_update_own" ON trip_stops
  FOR UPDATE
  USING (auth.uid() IN (SELECT user_id FROM trips WHERE trips.id = trip_stops.trip_id));

CREATE POLICY "trip_stops_delete_own" ON trip_stops
  FOR DELETE
  USING (auth.uid() IN (SELECT user_id FROM trips WHERE trips.id = trip_stops.trip_id));

CREATE POLICY "Users can view their own favorites" ON favorites
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own favorites" ON favorites
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own favorites" ON favorites
  FOR DELETE USING (auth.uid() = user_id);
