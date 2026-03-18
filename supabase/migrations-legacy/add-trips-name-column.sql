-- Add name column back to trips table
ALTER TABLE trips ADD COLUMN IF NOT EXISTS name TEXT;

-- Backfill existing trips with start_location -> end_location as name
UPDATE trips 
SET name = start_location || ' → ' || end_location
WHERE name IS NULL;
