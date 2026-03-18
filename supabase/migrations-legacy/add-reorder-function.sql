-- Function to atomically reorder trip stops
CREATE OR REPLACE FUNCTION reorder_trip_stops_atomic(p_trip_id UUID, p_stop_ids UUID[])
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  stop_order INTEGER;
  stop_id UUID;
BEGIN
  -- Validate that all stops belong to the trip
  PERFORM 1 FROM trip_stops 
  WHERE trip_id = p_trip_id 
  AND id = ANY(p_stop_ids)
  GROUP BY trip_id
  HAVING COUNT(*) = array_length(p_stop_ids, 1);

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid stop IDs or stops do not belong to this trip';
  END IF;

  -- Update order_index for each stop based on position in array
  stop_order := 0;
  FOREACH stop_id IN ARRAY p_stop_ids
  LOOP
    UPDATE trip_stops 
    SET order_index = stop_order 
    WHERE id = stop_id AND trip_id = p_trip_id;
    
    stop_order := stop_order + 1;
  END LOOP;
END;
$$;
