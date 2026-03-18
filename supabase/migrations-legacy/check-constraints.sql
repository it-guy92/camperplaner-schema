-- Check current constraints on trip_stops
SELECT 
    conname,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'trip_stops'::regclass;
