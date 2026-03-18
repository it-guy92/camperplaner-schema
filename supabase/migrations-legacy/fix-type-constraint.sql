-- Drop and recreate constraint with correct values
ALTER TABLE trip_stops DROP CONSTRAINT IF EXISTS trip_stops_type_check;

ALTER TABLE trip_stops 
ADD CONSTRAINT trip_stops_type_check 
CHECK (type IN ('camping', 'stellplatz', 'poi', 'city', 'address'));

-- Verify
SELECT conname, pg_get_constraintdef(oid) as def 
FROM pg_constraint 
WHERE conrelid = 'trip_stops'::regclass AND contype = 'c';
