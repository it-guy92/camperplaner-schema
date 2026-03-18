-- Update priority based on favorites and user engagement
-- Higher priority for places that are favorited or have user prices

UPDATE description_generation_jobs
SET priority = CASE
  WHEN place_id IN (
    SELECT place_id FROM favorites
  ) THEN 2
  WHEN place_id IN (
    SELECT DISTINCT osm_place_id FROM campsite_prices
  ) THEN 3
  ELSE 5
END
WHERE status = 'pending';

-- Create function to auto-update priority on insert
CREATE OR REPLACE FUNCTION set_job_priority()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if place is favorited
  IF EXISTS (
    SELECT 1 FROM favorites WHERE place_id = NEW.place_id
  ) THEN
    NEW.priority := 2;
  -- Check if place has user prices
  ELSIF EXISTS (
    SELECT 1 FROM campsite_prices WHERE osm_place_id = NEW.place_id LIMIT 1
  ) THEN
    NEW.priority := 3;
  -- Check if place is a camping site (vs poi)
  ELSIF NEW.place_id LIKE '%camp%' OR NEW.place_id LIKE '%stellplatz%' THEN
    NEW.priority := 4;
  ELSE
    NEW.priority := 5;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-set priority
DROP TRIGGER IF EXISTS trigger_set_job_priority ON description_generation_jobs;

CREATE TRIGGER trigger_set_job_priority
  BEFORE INSERT ON description_generation_jobs
  FOR EACH ROW
  EXECUTE FUNCTION set_job_priority();

-- Add index for faster priority lookups
CREATE INDEX IF NOT EXISTS idx_description_jobs_priority 
ON description_generation_jobs(priority) 
WHERE status = 'pending';
