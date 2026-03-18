-- Add RLS policies for trip_stops
-- Allow authenticated users to insert their own stops
CREATE POLICY "Users can insert stops for their own trips"
  ON trip_stops FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM trips
      WHERE trips.id = trip_stops.trip_id
      AND trips.user_id = auth.uid()
    )
  );

-- Allow users to select their own trip stops
CREATE POLICY "Users can view stops for their own trips"
  ON trip_stops FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM trips
      WHERE trips.id = trip_stops.trip_id
      AND trips.user_id = auth.uid()
    )
  );

-- Allow users to update their own trip stops
CREATE POLICY "Users can update stops for their own trips"
  ON trip_stops FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM trips
      WHERE trips.id = trip_stops.trip_id
      AND trips.user_id = auth.uid()
    )
  );

-- Allow users to delete their own trip stops
CREATE POLICY "Users can delete stops for their own trips"
  ON trip_stops FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM trips
      WHERE trips.id = trip_stops.trip_id
      AND trips.user_id = auth.uid()
    )
  );
