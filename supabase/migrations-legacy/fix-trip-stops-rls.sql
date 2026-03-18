-- Fix RLS policies for trip_stops table
-- Allow users to read stops for their own trips
CREATE POLICY "Users can read own trip stops"
ON trip_stops FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM trips
    WHERE trips.id = trip_stops.trip_id
    AND trips.user_id = auth.uid()
  )
);

-- Allow users to insert stops for their own trips
CREATE POLICY "Users can insert own trip stops"
ON trip_stops FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM trips
    WHERE trips.id = trip_stops.trip_id
    AND trips.user_id = auth.uid()
  )
);

-- Allow users to update own trip stops
CREATE POLICY "Users can update own trip stops"
ON trip_stops FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM trips
    WHERE trips.id = trip_stops.trip_id
    AND trips.user_id = auth.uid()
  )
);

-- Allow users to delete own trip stops
CREATE POLICY "Users can delete own trip stops"
ON trip_stops FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM trips
    WHERE trips.id = trip_stops.trip_id
    AND trips.user_id = auth.uid()
  )
);

-- Service role full access
CREATE POLICY "Service role full access on trip_stops"
ON trip_stops FOR ALL
USING (true)
WITH CHECK (true);
