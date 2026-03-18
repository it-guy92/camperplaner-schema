-- Add cost_type column to trip_stops
ALTER TABLE trip_stops 
ADD COLUMN IF NOT EXISTS cost_type TEXT DEFAULT 'per_night';

-- Add notes column to trip_stops
ALTER TABLE trip_stops 
ADD COLUMN IF NOT EXISTS notes TEXT DEFAULT '';

-- Update type column to allow more values
ALTER TABLE trip_stops 
ALTER COLUMN type TYPE TEXT;

-- Add check constraint for valid type values (optional, keeps data clean)
DO $$ 
BEGIN
   IF NOT EXISTS (
      SELECT 1 FROM pg_constraint 
      WHERE conname = 'trip_stops_type_check'
   ) THEN
      ALTER TABLE trip_stops 
      ADD CONSTRAINT trip_stops_type_check 
      CHECK (type IN ('camping', 'stellplatz', 'poi', 'city', 'address'));
   END IF;
END $$;

-- Update existing records with invalid types to valid ones
UPDATE trip_stops 
SET type = 'stellplatz' 
WHERE type NOT IN ('camping', 'stellplatz', 'poi', 'city', 'address');

-- Grant necessary permissions (if not already granted)
GRANT ALL ON trip_stops TO authenticated;
GRANT ALL ON trip_stops TO anon;
