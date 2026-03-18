-- Add cost breakdown columns to trips table
-- This enables storing fuel, toll, and accommodation costs separately
-- instead of only storing total_cost

ALTER TABLE trips 
ADD COLUMN IF NOT EXISTS fuel_cost NUMERIC(10, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS toll_cost NUMERIC(10, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS accommodation_cost NUMERIC(10, 2) DEFAULT 0;

-- Add indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_trips_fuel_cost ON trips(fuel_cost);
CREATE INDEX IF NOT EXISTS idx_trips_toll_cost ON trips(toll_cost);
CREATE INDEX IF NOT EXISTS idx_trips_accommodation_cost ON trips(accommodation_cost);
