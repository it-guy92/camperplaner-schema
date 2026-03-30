# Property Table Uniqueness Verification

Run these queries after applying `20260319100000_enforce_single_row_per_place_in_property_tables.sql`.

## 1) Duplicate checks (must return zero rows)

```sql
SELECT place_id, COUNT(*) AS row_count
FROM place_osm_properties
GROUP BY place_id
HAVING COUNT(*) > 1;

SELECT place_id, COUNT(*) AS row_count
FROM place_google_properties
GROUP BY place_id
HAVING COUNT(*) > 1;

SELECT place_id, COUNT(*) AS row_count
FROM place_llm_properties
GROUP BY place_id
HAVING COUNT(*) > 1;
```

## 2) Index checks (must show all three unique indexes)

```sql
SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname IN (
    'uidx_osm_properties_place_unique',
    'uidx_google_properties_place_unique',
    'uidx_llm_properties_place_unique'
  )
ORDER BY indexname;
```

## 3) Cardinality snapshot (optional sanity overview)

```sql
SELECT 'place_osm_properties' AS table_name, COUNT(*) AS rows, COUNT(DISTINCT place_id) AS distinct_places
FROM place_osm_properties
UNION ALL
SELECT 'place_google_properties', COUNT(*), COUNT(DISTINCT place_id)
FROM place_google_properties
UNION ALL
SELECT 'place_llm_properties', COUNT(*), COUNT(DISTINCT place_id)
FROM place_llm_properties;
```
