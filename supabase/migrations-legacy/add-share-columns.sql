-- Add share columns to trips table if they don't exist
ALTER TABLE trips ADD COLUMN IF NOT EXISTS is_shared BOOLEAN DEFAULT false;
ALTER TABLE trips ADD COLUMN IF NOT EXISTS share_token UUID UNIQUE;
ALTER TABLE trips ADD COLUMN IF NOT EXISTS shared_at TIMESTAMPTZ;

-- Create index for faster share token lookups
CREATE INDEX IF NOT EXISTS idx_trips_share_token ON trips(share_token) WHERE share_token IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_trips_is_shared ON trips(is_shared) WHERE is_shared = true;

-- Enable RLS on trips if not already enabled
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;

-- Create policy for public read access to shared trips
DROP POLICY IF EXISTS "Anyone can view shared trips" ON trips;
CREATE POLICY "Anyone can view shared trips" ON trips
  FOR SELECT USING (is_shared = true);

-- Ensure existing RLS policies still work
-- (Existing policies should remain - this only adds public access for shared trips)
