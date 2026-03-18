-- Allow shared trip stops to be selectable by the public share view
DROP POLICY IF EXISTS "Anyone can view shared trip stops" ON trip_stops;
CREATE POLICY "Anyone can view shared trip stops" ON trip_stops
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM trips
      WHERE trips.id = trip_stops.trip_id
      AND trips.is_shared = true
    )
  );
