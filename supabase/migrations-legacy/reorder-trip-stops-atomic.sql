-- Atomically reorder all stops for a trip in a single transaction
CREATE OR REPLACE FUNCTION public.reorder_trip_stops_atomic(
  p_trip_id uuid,
  p_stop_ids uuid[]
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_trip_stop_count integer;
  v_passed_count integer;
  v_belongs_count integer;
  v_updated_count integer;
BEGIN
  IF p_stop_ids IS NULL OR cardinality(p_stop_ids) = 0 THEN
    RAISE EXCEPTION 'stopIds dürfen nicht leer sein';
  END IF;

  IF (
    SELECT COUNT(*) FROM unnest(p_stop_ids) AS stop_id
  ) <> (
    SELECT COUNT(DISTINCT stop_id) FROM unnest(p_stop_ids) AS stop_id
  ) THEN
    RAISE EXCEPTION 'stopIds enthält Duplikate';
  END IF;

  SELECT COUNT(*)
  INTO v_trip_stop_count
  FROM trip_stops
  WHERE trip_id = p_trip_id;

  SELECT COUNT(*)
  INTO v_passed_count
  FROM unnest(p_stop_ids) AS stop_id;

  SELECT COUNT(*)
  INTO v_belongs_count
  FROM trip_stops
  WHERE trip_id = p_trip_id
    AND id = ANY(p_stop_ids);

  IF v_belongs_count <> v_passed_count THEN
    RAISE EXCEPTION 'Ein oder mehrere stopIds gehören nicht zur angegebenen Reise';
  END IF;

  IF v_trip_stop_count <> v_passed_count THEN
    RAISE EXCEPTION 'stopIds muss alle Stops der Reise enthalten';
  END IF;

  WITH ordered_ids AS (
    SELECT
      stop_id,
      ordinality - 1 AS new_order_index,
      ordinality AS new_day_number
    FROM unnest(p_stop_ids) WITH ORDINALITY AS u(stop_id, ordinality)
  ),
  updated AS (
    UPDATE trip_stops ts
    SET
      order_index = o.new_order_index,
      day_number = o.new_day_number
    FROM ordered_ids o
    WHERE ts.id = o.stop_id
      AND ts.trip_id = p_trip_id
    RETURNING ts.id
  )
  SELECT COUNT(*)
  INTO v_updated_count
  FROM updated;

  IF v_updated_count <> v_passed_count THEN
    RAISE EXCEPTION 'Nicht alle Stops konnten aktualisiert werden';
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.reorder_trip_stops_atomic(uuid, uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reorder_trip_stops_atomic(uuid, uuid[]) TO anon;
