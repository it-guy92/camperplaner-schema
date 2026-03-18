# Database Access Audit (Schema Repo - Canonical)

> **Location:** This is the canonical source. Product repo references this file.
> **Generated on:** 2026-03-14 from live Supabase `public` schema, `camperplaner-product`, and `camperplaner-worker`.

## Scope

- Live schema objects inspected: **35 tables + 6 views** in `public`
- Code scanned: non-generated `.ts/.tsx/.js/.mjs/.cjs/.sql` files in both repos
- Access modes covered: direct Supabase `.from(...)`, `.rpc(...)`, and raw SQL found in code
- DB-side access covered: public views, public SQL functions, and table triggers
- Test files were also scanned and are labeled separately where relevant

## Summary

- Business tables documented: **34**
- System/PostGIS tables documented separately: **1**
- Views documented as DB-side readers where applicable: **6**
- Code references to missing live objects: **0 in product runtime** (worker legacy refs may remain)
- Code references to non-public system catalogs: **2**

## Legacy Objects Decommissioned or Removed From Product Runtime

### `place_features`
- Zweck: Legacy secondary features table.
- Status in this repo: Dropped by migration `20260314000011_drop_decommissioned_legacy_tables.sql`.
- Product runtime readers/writers: none.

### `google_place_matches`
- Zweck: Legacy OSM-to-Google mapping table.
- Status in this repo: Dropped by migration `20260314000011_drop_decommissioned_legacy_tables.sql`.
- Product runtime readers/writers: none.

### `external_place_cache`
- Zweck: Legacy external provider cache.
- Status in this repo: Dropped by migration `20260314000011_drop_decommissioned_legacy_tables.sql`.
- Product runtime readers/writers: none (cutover checks now read `google_places_cache`).

### `place_legacy_id_map`
- Zweck: Legacy place ID mapping object.
- Product runtime readers/writers: none.
- Note: Worker references may still exist and must be handled in `camperplaner-worker`.

### `campsites`
- Zweck: Legacy table name retained in historical docs/migrations.
- Product runtime readers/writers: none (product runtime uses `campsites_cache`, `campsite_full`, and `campsite_api_read_model`).

## Non-public System Catalog References

### `pg_policies`
- Zweck: PostgreSQL system catalog view for row-level security policies.
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId
- Runtime writers:
  - none

### `pg_tables`
- Zweck: PostgreSQL system catalog view for table metadata.
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId
- Runtime writers:
  - none

## Business Tables

## `profiles`

- Typ: table
- Zweck: User profile extension table for auth users.
- Live rows: 1
- Primary key: `id`
- Outgoing foreign keys: none
- Incoming foreign keys: `trips.user_id`, `favorites.user_id`, `vehicle_profiles.user_id`, `trip_reminders.user_id`, `campsite_reviews.user_id`, `campsite_prices.user_id`
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: `handle_new_user`, `promote_to_admin`
- Triggers on this object: none
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/scripts/fix-policies.mjs#client
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/descriptions/jobs/route.ts#userSupabase
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#verifyAdminAccess
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/[code]/status/route.ts#verifyAdminAccess
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#verifyAdminAccess
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/route.ts#verifyAdminAccess
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#verifyAdminAccess
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/statistics/route.ts#type
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/stats/route.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/users/[userId]/route.ts#tripIds
  - product/runtime camperplaner-product/apps/web/src/app/auth/callback/route.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/app/profile/page.tsx#loadProfile
  - product/runtime camperplaner-product/apps/web/src/app/profile/page.tsx#profilePayload
  - product/runtime camperplaner-product/apps/web/src/components/route-planner.tsx#supabase
  - product/runtime camperplaner-product/apps/web/src/contexts/auth-context.tsx#cachedRole
  - product/runtime camperplaner-product/apps/web/src/lib/admin-statistics-cache.ts#type
  - product/runtime camperplaner-product/apps/web/src/middleware/admin.ts#supabase
- Runtime writers:
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/users/[userId]/route.ts#tripIds
  - product/runtime camperplaner-product/apps/web/src/app/auth/callback/route.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/app/profile/page.tsx#profilePayload
  - product/runtime camperplaner-product/apps/web/src/contexts/auth-context.tsx#signUp

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `uuid` | Primary key | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/descriptions/jobs/route.ts#userSupabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#verifyAdminAccess`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/[code]/status/route.ts#verifyAdminAccess`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#verifyAdminAccess`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/route.ts#verifyAdminAccess`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#verifyAdminAccess`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/stats/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/users/[userId]/route.ts#tripIds`<br>`product/runtime camperplaner-product/apps/web/src/app/auth/callback/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/profile/page.tsx#loadProfile`<br>`product/runtime camperplaner-product/apps/web/src/app/profile/page.tsx#profilePayload`<br>`product/runtime camperplaner-product/apps/web/src/components/route-planner.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/contexts/auth-context.tsx#cachedRole`<br>`product/runtime camperplaner-product/apps/web/src/middleware/admin.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/app/auth/callback/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/profile/page.tsx#profilePayload` | none | not null |
| `email` | `text` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/stats/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/middleware/admin.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/app/auth/callback/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/profile/page.tsx#profilePayload` | none | not null |
| `role` | `text` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/descriptions/jobs/route.ts#userSupabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#verifyAdminAccess`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/[code]/status/route.ts#verifyAdminAccess`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#verifyAdminAccess`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/route.ts#verifyAdminAccess`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#verifyAdminAccess`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/stats/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/contexts/auth-context.tsx#cachedRole`<br>`product/runtime camperplaner-product/apps/web/src/middleware/admin.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/app/auth/callback/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/profile/page.tsx#profilePayload` | none | not null |
| `created_at` | `timestamp with time zone | null` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/statistics/route.ts#type`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/stats/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/admin-statistics-cache.ts#type` | none | none | default: CURRENT_TIMESTAMP |
| `full_name` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/profile/page.tsx#loadProfile` | none | none | — |
| `home_city` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/profile/page.tsx#loadProfile`<br>`product/runtime camperplaner-product/apps/web/src/components/route-planner.tsx#supabase` | none | none | — |
| `home_city_coords` | `jsonb | null` | JSON payload | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/profile/page.tsx#loadProfile`<br>`product/runtime camperplaner-product/apps/web/src/components/route-planner.tsx#supabase` | none | none | — |
| `updated_at` | `timestamp with time zone` | Timestamp | observed in schema | none | none | none | default: now(); not null |

## `trips`

- Typ: table
- Zweck: User trips/routes.
- Live rows: 10
- Primary key: `id`
- Outgoing foreign keys: `user_id` -> `profiles.id`
- Incoming foreign keys: `trip_stops.trip_id`, `trip_reminders.trip_id`
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: none
- Triggers on this object: none
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#debugTripStops
  - product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId
  - product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#testWithAnonKey
  - product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/stats/route.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/users/[userId]/route.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/users/[userId]/route.ts#tripIds
  - product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#body
  - product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/share/route.ts#shareToken
  - product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/share/route.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/share/route.ts#updateResult
  - product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/[stopId]/route.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/reorder/route.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#supabase
  - product/runtime camperplaner-product/apps/web/src/components/profile-hub/expenses-tab.tsx#supabase
  - product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase
  - product/runtime camperplaner-product/apps/web/src/components/share-dialog.tsx#supabase
  - product/runtime camperplaner-product/apps/web/src/hooks/use-save-route.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/hooks/useRouteLogic.ts#routeGeo
  - product/runtime camperplaner-product/apps/web/src/hooks/useRouteLogic.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#costs
  - product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#recalculateAndPersistTripCosts
- Runtime writers:
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/users/[userId]/route.ts#tripIds
  - product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/share/route.ts#shareToken
  - product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/share/route.ts#updateResult
  - product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase
  - product/runtime camperplaner-product/apps/web/src/hooks/use-save-route.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/hooks/useRouteLogic.ts#routeGeo
  - product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#costs

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `uuid` | Primary key | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#debugTripStops`<br>`product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#testWithAnonKey`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/users/[userId]/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/share/route.ts#shareToken`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/share/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/share/route.ts#updateResult`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/[stopId]/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/reorder/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/expenses-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/share-dialog.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/hooks/useRouteLogic.ts#routeGeo`<br>`product/runtime camperplaner-product/apps/web/src/hooks/useRouteLogic.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#costs`<br>`product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#recalculateAndPersistTripCosts` | none | none | default: uuid_generate_v4(); not null |
| `user_id` | `uuid` | FK -> profiles.id | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#debugTripStops`<br>`product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#testWithAnonKey`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/users/[userId]/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/users/[userId]/route.ts#tripIds`<br>`product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/share/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/[stopId]/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/reorder/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/expenses-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/hooks/useRouteLogic.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/hooks/use-save-route.ts#supabase` | none | not null |
| `start_location` | `text` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#debugTripStops`<br>`product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#testWithAnonKey`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/expenses-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/hooks/useRouteLogic.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/hooks/use-save-route.ts#supabase` | none | not null |
| `end_location` | `text` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#debugTripStops`<br>`product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#testWithAnonKey`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/expenses-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/hooks/useRouteLogic.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/hooks/use-save-route.ts#supabase` | none | not null |
| `start_date` | `date` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/expenses-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/hooks/useRouteLogic.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/hooks/use-save-route.ts#supabase` | none | not null |
| `end_date` | `date` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/expenses-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/hooks/useRouteLogic.ts#supabase` | none | none | not null |
| `total_distance` | `numeric` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/expenses-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/hooks/useRouteLogic.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#costs` | none | not null |
| `total_cost` | `numeric` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/expenses-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/hooks/useRouteLogic.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#costs` | none | not null |
| `created_at` | `timestamp with time zone | null` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/expenses-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/hooks/useRouteLogic.ts#supabase` | none | none | default: CURRENT_TIMESTAMP |
| `start_coords` | `jsonb | null` | JSON payload | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/expenses-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/hooks/useRouteLogic.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#recalculateAndPersistTripCosts` | `product/runtime camperplaner-product/apps/web/src/hooks/use-save-route.ts#supabase` | none | default: '{}'::jsonb |
| `end_coords` | `jsonb | null` | JSON payload | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/expenses-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/hooks/useRouteLogic.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#recalculateAndPersistTripCosts` | `product/runtime camperplaner-product/apps/web/src/hooks/use-save-route.ts#supabase` | none | default: '{}'::jsonb |
| `route_geometry` | `jsonb | null` | JSON payload | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/expenses-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/hooks/useRouteLogic.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/hooks/use-save-route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/hooks/useRouteLogic.ts#routeGeo` | none | — |
| `fuel_cost` | `numeric` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/expenses-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/hooks/useRouteLogic.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#costs` | none | default: 0; not null |
| `toll_cost` | `numeric` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/expenses-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/hooks/useRouteLogic.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#costs` | none | default: 0; not null |
| `is_shared` | `boolean | null` | Boolean flag | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/share/route.ts#shareToken`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/share/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/expenses-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/share-dialog.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/hooks/useRouteLogic.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/share/route.ts#shareToken`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/share/route.ts#updateResult` | none | default: false |
| `share_token` | `uuid | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/share/route.ts#shareToken`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/share/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/expenses-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/share-dialog.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/hooks/useRouteLogic.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/share/route.ts#shareToken`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/share/route.ts#updateResult` | none | — |
| `shared_at` | `timestamp without time zone | null` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/share/route.ts#shareToken`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/expenses-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/hooks/useRouteLogic.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/share/route.ts#shareToken`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/share/route.ts#updateResult` | none | — |
| `start_location_geo` | `geography | null` | Spatial data | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/expenses-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/hooks/useRouteLogic.ts#supabase` | none | none | — |
| `end_location_geo` | `geography | null` | Spatial data | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/expenses-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/hooks/useRouteLogic.ts#supabase` | none | none | — |
| `name` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/expenses-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/hooks/useRouteLogic.ts#supabase` | none | none | — |

## `trip_stops`

- Typ: table
- Zweck: Stops belonging to trips.
- Live rows: 29
- Primary key: `id`
- Outgoing foreign keys: `trip_id` -> `trips.id`
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: `reorder_trip_stops_atomic`
- DB functions writing this object: `reorder_trip_stops_atomic`
- Triggers on this object: none
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/scripts/backfill-place-ids.mjs#backfillPlaceIds
  - product/runtime camperplaner-product/apps/web/scripts/backfill-place-ids.mjs#displayName
  - product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId
  - product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/stats/route.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/users/[userId]/route.ts#tripIds
  - product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/[stopId]/route.ts#newOrderIndex
  - product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/[stopId]/route.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/reorder/route.ts#body
  - product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#insertData
  - product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#resolvedLegacyPlaceId
  - product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#trip
  - product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase
  - product/runtime camperplaner-product/apps/web/src/hooks/use-save-route.ts#stopsToInsert
  - product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#recalculateAndPersistTripCosts
- Runtime writers:
  - product/runtime camperplaner-product/apps/web/scripts/backfill-place-ids.mjs#displayName
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/users/[userId]/route.ts#tripIds
  - product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/[stopId]/route.ts#newOrderIndex
  - product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/[stopId]/route.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#insertData
  - product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase
  - product/runtime camperplaner-product/apps/web/src/hooks/use-save-route.ts#stopsToInsert
- Indirect readers via RPC:
  - reorder_trip_stops_atomic <= product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/reorder/route.ts#body
- Indirect writers via RPC:
  - reorder_trip_stops_atomic <= product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/reorder/route.ts#body

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `uuid` | Primary key | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/backfill-place-ids.mjs#displayName`<br>`product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/[stopId]/route.ts#newOrderIndex`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/[stopId]/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/reorder/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#trip`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#recalculateAndPersistTripCosts` | none | none | default: uuid_generate_v4(); not null |
| `trip_id` | `uuid` | FK -> trips.id | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/users/[userId]/route.ts#tripIds`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/[stopId]/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/reorder/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#resolvedLegacyPlaceId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#trip`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#recalculateAndPersistTripCosts` | none | none | not null |
| `day_number` | `integer` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/reorder/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#trip`<br>`product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#recalculateAndPersistTripCosts` | none | none | not null |
| `location_name` | `text` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/reorder/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#trip`<br>`product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#recalculateAndPersistTripCosts` | none | none | not null |
| `coordinates` | `jsonb` | JSON payload | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/reorder/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#trip`<br>`product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#recalculateAndPersistTripCosts` | none | none | not null |
| `cost` | `numeric` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/reorder/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#trip`<br>`product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#recalculateAndPersistTripCosts` | none | none | not null |
| `type` | `text` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/reorder/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#trip`<br>`product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#recalculateAndPersistTripCosts` | none | none | not null |
| `name` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/reorder/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#trip`<br>`product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#recalculateAndPersistTripCosts` | none | none | — |
| `rating` | `numeric | null` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/reorder/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#trip`<br>`product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#recalculateAndPersistTripCosts` | none | none | — |
| `website` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/reorder/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#trip`<br>`product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#recalculateAndPersistTripCosts` | none | none | — |
| `image` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/reorder/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#trip`<br>`product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#recalculateAndPersistTripCosts` | none | none | — |
| `amenities` | `ARRAY | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/reorder/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#trip`<br>`product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#recalculateAndPersistTripCosts` | none | none | default: '{}'::text[] |
| `order_index` | `integer | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/[stopId]/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/reorder/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#resolvedLegacyPlaceId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#trip`<br>`product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#recalculateAndPersistTripCosts` | `product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/[stopId]/route.ts#newOrderIndex` | none | default: 0 |
| `cost_type` | `text | null` | Classifier | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/reorder/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#trip`<br>`product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#recalculateAndPersistTripCosts` | none | none | default: 'per_night'::text |
| `notes` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/reorder/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/share/[token]/page.tsx#trip`<br>`product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#recalculateAndPersistTripCosts` | none | none | — |
| `place_id` | `text | null` | Identifier | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/backfill-place-ids.mjs#backfillPlaceIds`<br>`product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/reorder/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#recalculateAndPersistTripCosts` | `product/runtime camperplaner-product/apps/web/scripts/backfill-place-ids.mjs#displayName` | none | — |
| `location_geo` | `geography | null` | Spatial data | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-trip-stops.mjs#testTripId`<br>`product/runtime camperplaner-product/apps/web/scripts/test-anon-key.mjs#tripId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/reorder/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/trips/[id]/stops/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/trip-costs.ts#recalculateAndPersistTripCosts` | none | none | — |

## `trip_reminders`

- Typ: table
- Zweck: Reminder settings and send state per trip.
- Live rows: 0
- Primary key: `id`
- Outgoing foreign keys: `trip_id` -> `trips.id`, `user_id` -> `profiles.id`
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: none
- Triggers on this object: none
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#body
  - product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#id
  - product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#trip_id
  - product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase
  - product/runtime camperplaner-product/apps/web/src/lib/reminders.ts#supabase
- Runtime writers:
  - product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#body
  - product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#id
  - product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase
  - product/runtime camperplaner-product/apps/web/src/lib/reminders.ts#supabase

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `uuid` | Primary key | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#id`<br>`product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#trip_id`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/reminders.ts#supabase` | none | none | default: gen_random_uuid(); not null |
| `trip_id` | `uuid` | FK -> trips.id | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#trip_id`<br>`product/runtime camperplaner-product/apps/web/src/components/profile-hub/routes-tab.tsx#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/reminders.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/lib/reminders.ts#supabase` | none | not null |
| `user_id` | `uuid` | FK -> profiles.id | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#id`<br>`product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#trip_id`<br>`product/runtime camperplaner-product/apps/web/src/lib/reminders.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/lib/reminders.ts#supabase` | none | not null |
| `reminder_days_before` | `integer` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#trip_id`<br>`product/runtime camperplaner-product/apps/web/src/lib/reminders.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/lib/reminders.ts#supabase` | none | not null |
| `is_active` | `boolean` | Boolean flag | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#trip_id`<br>`product/runtime camperplaner-product/apps/web/src/lib/reminders.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/lib/reminders.ts#supabase` | none | default: true; not null |
| `last_sent_at` | `timestamp with time zone | null` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#trip_id`<br>`product/runtime camperplaner-product/apps/web/src/lib/reminders.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/lib/reminders.ts#supabase` | none | — |
| `created_at` | `timestamp with time zone` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/reminders/route.ts#trip_id`<br>`product/runtime camperplaner-product/apps/web/src/lib/reminders.ts#supabase` | none | none | default: now(); not null |

## `vehicle_profiles`

- Typ: table
- Zweck: Saved vehicle configurations per user.
- Live rows: 0
- Primary key: `id`
- Outgoing foreign keys: `user_id` -> `profiles.id`
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: none
- Triggers on this object: none
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#createVehicleProfile
  - product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#deleteVehicleProfile
  - product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#getDefaultVehicleProfile
  - product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#getVehicleProfiles
  - product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#setDefaultVehicleProfile
  - product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#updateVehicleProfile
- Runtime writers:
  - product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#createVehicleProfile
  - product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#deleteVehicleProfile
  - product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#setDefaultVehicleProfile
  - product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#updateVehicleProfile

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `uuid` | Primary key | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#deleteVehicleProfile`<br>`product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#getDefaultVehicleProfile`<br>`product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#getVehicleProfiles`<br>`product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#setDefaultVehicleProfile`<br>`product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#updateVehicleProfile` | none | none | default: gen_random_uuid(); not null |
| `user_id` | `uuid` | FK -> profiles.id | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#createVehicleProfile`<br>`product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#deleteVehicleProfile`<br>`product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#getDefaultVehicleProfile`<br>`product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#getVehicleProfiles`<br>`product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#setDefaultVehicleProfile`<br>`product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#updateVehicleProfile` | `product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#createVehicleProfile` | none | not null |
| `name` | `text` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#getDefaultVehicleProfile`<br>`product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#getVehicleProfiles` | `product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#createVehicleProfile` | none | not null |
| `max_speed` | `numeric | null` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#getDefaultVehicleProfile`<br>`product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#getVehicleProfiles` | `product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#createVehicleProfile` | none | default: 130 |
| `height` | `numeric | null` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#getDefaultVehicleProfile`<br>`product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#getVehicleProfiles` | `product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#createVehicleProfile` | none | default: 3.5 |
| `weight` | `numeric | null` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#getDefaultVehicleProfile`<br>`product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#getVehicleProfiles` | `product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#createVehicleProfile` | none | default: 3500 |
| `fuel_consumption` | `numeric | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#getDefaultVehicleProfile`<br>`product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#getVehicleProfiles` | `product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#createVehicleProfile` | none | default: 10 |
| `is_default` | `boolean | null` | Boolean flag | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#getDefaultVehicleProfile`<br>`product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#getVehicleProfiles` | `product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#createVehicleProfile`<br>`product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#setDefaultVehicleProfile`<br>`product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#updateVehicleProfile` | none | default: false |
| `created_at` | `timestamp with time zone` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#getDefaultVehicleProfile`<br>`product/runtime camperplaner-product/apps/web/src/lib/vehicle-profiles.ts#getVehicleProfiles` | none | none | default: now(); not null |

## `favorites`

- Typ: table
- Zweck: User favorite places.
- Live rows: 0
- Primary key: `id`
- Outgoing foreign keys: `user_id` -> `profiles.id`
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: `set_job_priority`
- DB functions writing this object: none
- Triggers on this object: none
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#getFavoriteIds
  - product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#getFavorites
  - product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#resolution
- Runtime writers:
  - product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#resolution

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `uuid` | Primary key | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#getFavorites`<br>`product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#resolution` | none | none | default: gen_random_uuid(); not null |
| `user_id` | `uuid` | FK -> profiles.id | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#getFavoriteIds`<br>`product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#getFavorites`<br>`product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#resolution` | `product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#resolution` | none | not null |
| `place_id` | `text` | Identifier | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#getFavoriteIds`<br>`product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#getFavorites`<br>`product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#resolution` | `product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#resolution` | none | not null |
| `name` | `text` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#getFavorites` | `product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#resolution` | none | not null |
| `coordinates` | `jsonb` | JSON payload | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#getFavorites` | `product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#resolution` | none | default: '{}'::jsonb; not null |
| `type` | `text` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#getFavorites` | `product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#resolution` | none | not null |
| `amenities` | `ARRAY | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#getFavorites` | `product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#resolution` | none | default: '{}'::text[] |
| `rating` | `numeric | null` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#getFavorites` | `product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#resolution` | none | — |
| `created_at` | `timestamp with time zone` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#getFavorites` | none | none | default: now(); not null |
| `location_geo` | `geography | null` | Spatial data | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/favorites.ts#getFavorites` | none | none | — |

## `places`

- Typ: table
- Zweck: Canonical place table used by the new read/write model.
- Live rows: 205288
- Primary key: `id`
- Outgoing foreign keys: none
- Incoming foreign keys: `osm_source.place_id`, `place_enrichment.place_id`, `enrichment_jobs.place_id`, `osm_type_transitions.merged_place_id`, `place_duplicate_candidates.primary_place_id`, `place_duplicate_candidates.duplicate_place_id`
- DB views reading this object: `campsite_api_read_model`
- DB functions reading this object: `find_similar_places`, `get_poi_by_country`, `get_poi_statistics`, `mark_stale_sources`, `schedule_enrichment_refresh`
- DB functions writing this object: none
- Triggers on this object: `trg_places_set_updated_at -> set_updated_at_timestamp`
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData
  - product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#jobIds
  - product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#progress
  - product/runtime camperplaner-product/apps/web/scripts/cutover-check.mjs#loadMetrics
  - product/runtime camperplaner-product/apps/web/scripts/db-verify-schema.cjs#result3
  - product/runtime camperplaner-product/apps/web/scripts/db-verify-schema.cjs#result4
  - product/runtime camperplaner-product/apps/web/scripts/db-verify-schema.cjs#result7
  - product/runtime camperplaner-product/apps/web/scripts/db-verify-schema.cjs#result8
  - product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag
  - product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution
  - product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code
  - product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#getFullReport
  - product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#getInitialState
  - product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg
  - product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#verifyResults
  - product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#allPlaceIds
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/descriptions/route.ts#canonicalPublicPlaceId
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit
  - product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#isCanonicalUuid
  - product/runtime camperplaner-product/apps/web/src/lib/google-places-server.ts#resolvePlaceByPublicId
  - worker/runtime camperplaner-worker/src/services/edge-cases.ts#sourceIds
  - worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#hasNoTags
  - worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#seenAt
  - worker/runtime camperplaner-worker/src/services/source-management.ts#wktPoint
  - worker/runtime camperplaner-worker/src/workers/enrichment-queue-worker.ts#nowIso
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#baseQuery
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#existingSource
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#noop
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#touchPlaceSeenAt
  - worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#<module>
  - worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#placePayload
  - worker/runtime camperplaner-worker/src/workers/schedule-enrichment-jobs.ts#scheduleEnrichmentJobs
- Runtime writers:
  - product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#jobIds
  - worker/runtime camperplaner-worker/src/services/edge-cases.ts#sourceIds
  - worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#hasNoTags
  - worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#seenAt
  - worker/runtime camperplaner-worker/src/services/source-management.ts#wktPoint
  - worker/runtime camperplaner-worker/src/workers/enrichment-queue-worker.ts#nowIso
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#baseQuery
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#existingSource
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#noop
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#touchPlaceSeenAt
  - worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#<module>
  - worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#placePayload
- Indirect readers via RPC:
  - find_similar_places <= worker/runtime camperplaner-worker/src/utils/matching.ts#proximityResult, worker/runtime camperplaner-worker/src/utils/matching.ts#result
  - get_poi_by_country <= product/runtime camperplaner-product/apps/web/src/app/api/admin/statistics/route.ts#stats
  - get_poi_statistics <= product/runtime camperplaner-product/apps/web/src/app/api/admin/statistics/route.ts#supabase, product/runtime camperplaner-product/apps/web/src/lib/admin-statistics-cache.ts#supabase
  - mark_stale_sources <= worker/runtime camperplaner-worker/src/services/import-runner.ts#newPlaceId
  - schedule_enrichment_refresh <= product/runtime camperplaner-product/apps/web/src/app/api/admin/descriptions/batch/route.ts#freshness
- Test readers:
  - product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key
- Test writers:
  - product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `bigint` | Primary key | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#allPlaceIds`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/descriptions/route.ts#canonicalPublicPlaceId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#isCanonicalUuid`<br>`product/runtime camperplaner-product/apps/web/src/lib/google-places-server.ts#resolvePlaceByPublicId`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key`<br>`worker/runtime camperplaner-worker/src/services/edge-cases.ts#sourceIds`<br>`worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#hasNoTags`<br>`worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#seenAt`<br>`worker/runtime camperplaner-worker/src/services/source-management.ts#wktPoint`<br>`worker/runtime camperplaner-worker/src/workers/enrichment-queue-worker.ts#nowIso`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#existingSource`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#noop`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#touchPlaceSeenAt`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#<module>`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#placePayload`<br>`worker/runtime camperplaner-worker/src/workers/schedule-enrichment-jobs.ts#scheduleEnrichmentJobs` | none | `campsite_api_read_model` | default: nextval('places_id_seq'::regclass); not null |
| `place_type` | `place_type_enum` | Classifier | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#getFullReport`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#allPlaceIds`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | `campsite_api_read_model` | not null |
| `name` | `text` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#allPlaceIds`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/runtime camperplaner-product/apps/web/src/lib/google-places-server.ts#resolvePlaceByPublicId`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | `campsite_api_read_model` | not null |
| `geom` | `geography` | Spatial data | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | none | not null |
| `lat` | `double precision | null` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#allPlaceIds`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/runtime camperplaner-product/apps/web/src/lib/google-places-server.ts#resolvePlaceByPublicId`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | `campsite_api_read_model` | — |
| `lon` | `double precision | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#allPlaceIds`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/runtime camperplaner-product/apps/web/src/lib/google-places-server.ts#resolvePlaceByPublicId`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | `campsite_api_read_model` | — |
| `country_code` | `text | null` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#jobIds`<br>`product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#progress`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#getFullReport`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#getInitialState`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#verifyResults`<br>`product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#allPlaceIds`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | `campsite_api_read_model` | — |
| `region` | `text | null` | Data field | all values NULL | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | `campsite_api_read_model` | all live values NULL |
| `city` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#allPlaceIds`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | `campsite_api_read_model` | — |
| `postcode` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | none | — |
| `address` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | `campsite_api_read_model` | — |
| `has_toilet` | `boolean` | Boolean flag | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | none | default: false; not null |
| `has_shower` | `boolean` | Boolean flag | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | none | default: false; not null |
| `has_electricity` | `boolean` | Boolean flag | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | none | default: false; not null |
| `has_water` | `boolean` | Boolean flag | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | none | default: false; not null |
| `has_wifi` | `boolean` | Boolean flag | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | none | default: false; not null |
| `pet_friendly` | `boolean` | Boolean flag | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | none | default: false; not null |
| `caravan_allowed` | `boolean` | Boolean flag | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | none | default: false; not null |
| `motorhome_allowed` | `boolean` | Boolean flag | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | none | default: false; not null |
| `tent_allowed` | `boolean` | Boolean flag | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | none | default: false; not null |
| `website` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | `campsite_api_read_model` | — |
| `phone` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | `campsite_api_read_model` | — |
| `email` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | `campsite_api_read_model` | — |
| `opening_hours` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | `campsite_api_read_model` | — |
| `fee_info` | `text | null` | Data field | all values NULL | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | none | all live values NULL |
| `source_primary` | `text` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#allPlaceIds`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#baseQuery` | none | `campsite_api_read_model` | not null |
| `data_confidence` | `numeric | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | none | — |
| `last_seen_at` | `timestamp with time zone | null` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#baseQuery` | `worker/runtime camperplaner-worker/src/workers/osm-import.ts#touchPlaceSeenAt` | none | default: now() |
| `last_enriched_at` | `timestamp with time zone | null` | Timestamp | all values NULL | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key`<br>`worker/runtime camperplaner-worker/src/workers/schedule-enrichment-jobs.ts#scheduleEnrichmentJobs` | `worker/runtime camperplaner-worker/src/workers/enrichment-queue-worker.ts#nowIso` | none | all live values NULL |
| `is_active` | `boolean` | Boolean flag | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#baseQuery`<br>`worker/runtime camperplaner-worker/src/workers/schedule-enrichment-jobs.ts#scheduleEnrichmentJobs` | `worker/runtime camperplaner-worker/src/services/edge-cases.ts#sourceIds`<br>`worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#hasNoTags`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#baseQuery`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#touchPlaceSeenAt` | `campsite_api_read_model` | default: true; not null |
| `created_at` | `timestamp with time zone` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | `campsite_api_read_model` | default: now(); not null |
| `updated_at` | `timestamp with time zone` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#analyzeData`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#flag`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#testExecution`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#code`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#msg`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | `worker/runtime camperplaner-worker/src/services/edge-cases.ts#sourceIds`<br>`worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#hasNoTags`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#baseQuery` | `campsite_api_read_model` | default: now(); not null |

## `campsites_cache`

- Typ: table
- Zweck: Legacy/cache table for campsite-centric read data and Google-derived fields.
- Live rows: 355
- Primary key: `id`
- Outgoing foreign keys: none
- Incoming foreign keys: `description_generation_jobs.place_id`, `website_scraping_jobs.place_id`
- DB views reading this object: none
- DB functions reading this object: `get_cached_campsite`
- DB functions writing this object: `update_campsite_price_stats`
- Triggers on this object: none
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/src/app/api/places/[placeId]/description/route.ts#repository
  - product/runtime camperplaner-product/apps/web/src/lib/descriptions/index.ts#saveDescriptionToCache
  - product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#structuredFieldUpdates
  - product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#updateData
- Runtime writers:
  - product/runtime camperplaner-product/apps/web/src/app/api/places/[placeId]/description/route.ts#repository
  - product/runtime camperplaner-product/apps/web/src/lib/descriptions/index.ts#saveDescriptionToCache
  - product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#structuredFieldUpdates
  - product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#updateData

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `uuid` | Primary key | observed in schema | none | none | none | default: uuid_generate_v4(); not null |
| `place_id` | `text | null` | Identifier | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/places/[placeId]/description/route.ts#repository`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/index.ts#saveDescriptionToCache`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#structuredFieldUpdates`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#updateData` | none | none | — |
| `name` | `text` | Data field | observed in schema | none | none | none | not null |
| `lat` | `double precision` | Metric/value | observed in schema | none | none | none | not null |
| `lng` | `double precision` | Metric/value | observed in schema | none | none | none | not null |
| `rating` | `double precision | null` | Metric/value | observed in schema | none | none | none | — |
| `photo_url` | `text | null` | Data field | all values NULL | none | none | none | all live values NULL |
| `estimated_price` | `numeric | null` | Data field | observed in schema | none | none | none | — |
| `place_types` | `ARRAY | null` | Data field | observed in schema | none | none | none | — |
| `last_updated` | `timestamp with time zone | null` | Data field | observed in schema | none | none | none | default: CURRENT_TIMESTAMP |
| `created_at` | `timestamp with time zone | null` | Timestamp | observed in schema | none | none | none | default: CURRENT_TIMESTAMP |
| `price_source` | `text | null` | Classifier | observed in schema | none | none | none | default: 'estimated'::text |
| `user_price_count` | `integer | null` | Metric/value | observed in schema | none | none | none | default: 0 |
| `user_price_avg` | `numeric | null` | Metric/value | all values NULL | none | none | none | all live values NULL |
| `description` | `text | null` | Data field | observed in schema | none | `product/runtime camperplaner-product/apps/web/src/app/api/places/[placeId]/description/route.ts#repository` | none | — |
| `description_source` | `character varying | null` | Classifier | observed in schema | none | `product/runtime camperplaner-product/apps/web/src/app/api/places/[placeId]/description/route.ts#repository`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/index.ts#saveDescriptionToCache` | none | — |
| `description_generated_at` | `timestamp with time zone | null` | Timestamp | observed in schema | none | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/index.ts#saveDescriptionToCache` | none | — |
| `description_version` | `integer | null` | Metric/value | observed in schema | none | none | none | default: 1 |
| `opening_hours` | `text | null` | Data field | all values NULL | none | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#updateData` | none | all live values NULL |
| `contact_phone` | `text | null` | Data field | observed in schema | none | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#updateData` | none | — |
| `contact_email` | `text | null` | Data field | observed in schema | none | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#updateData` | none | — |
| `scraped_website_url` | `text | null` | Data field | observed in schema | none | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#updateData` | none | — |
| `scraped_at` | `timestamp with time zone | null` | Timestamp | observed in schema | none | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#updateData` | none | — |
| `scraped_price_info` | `jsonb | null` | JSON payload | all values NULL | none | none | none | all live values NULL |
| `scraped_data_source` | `character varying | null` | Classifier | observed in schema | none | none | none | — |
| `google_data_fetched_at` | `timestamp with time zone | null` | Timestamp | all values NULL | none | none | none | all live values NULL |
| `google_data_expires_at` | `timestamp with time zone | null` | Timestamp | all values NULL | none | none | none | all live values NULL |
| `google_photos` | `jsonb | null` | JSON payload | all values NULL | none | none | none | all live values NULL |
| `google_reviews` | `jsonb | null` | JSON payload | all values NULL | none | none | none | all live values NULL |

## `campsite_prices`

- Typ: table
- Zweck: User-submitted campsite price entries.
- Live rows: 0
- Primary key: `id`
- Outgoing foreign keys: `user_id` -> `profiles.id`
- Incoming foreign keys: none
- DB views reading this object: `campsite_price_summary`
- DB functions reading this object: `set_job_priority`, `update_campsite_price_stats`
- DB functions writing this object: none
- Triggers on this object: `trigger_update_campsite_price_stats -> update_campsite_price_stats`
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/src/app/api/campsite-prices/route.ts#effectivePlaceId
  - product/runtime camperplaner-product/apps/web/src/app/api/campsite-prices/route.ts#supabase
- Runtime writers:
  - product/runtime camperplaner-product/apps/web/src/app/api/campsite-prices/route.ts#effectivePlaceId

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `uuid` | Primary key | observed in schema | none | none | none | default: gen_random_uuid(); not null |
| `place_id` | `text` | Identifier | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/campsite-prices/route.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/app/api/campsite-prices/route.ts#effectivePlaceId` | `campsite_price_summary` | not null |
| `user_id` | `uuid | null` | FK -> profiles.id | observed in schema | none | `product/runtime camperplaner-product/apps/web/src/app/api/campsite-prices/route.ts#effectivePlaceId` | none | — |
| `price_per_night` | `numeric` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/campsite-prices/route.ts#supabase` | none | `campsite_price_summary` | not null |
| `price_type` | `text | null` | Classifier | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/campsite-prices/route.ts#supabase` | none | none | default: 'per_night'::text |
| `currency` | `text | null` | Data field | observed in schema | none | none | none | default: 'EUR'::text |
| `rating` | `numeric | null` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/campsite-prices/route.ts#supabase` | none | `campsite_price_summary` | — |
| `review_text` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/campsite-prices/route.ts#supabase` | none | `campsite_price_summary` | — |
| `created_at` | `timestamp with time zone | null` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/campsite-prices/route.ts#supabase` | none | none | default: now() |

## `campsite_reviews`

- Typ: table
- Zweck: User-submitted campsite reviews.
- Live rows: 0
- Primary key: `id`
- Outgoing foreign keys: `user_id` -> `profiles.id`
- Incoming foreign keys: none
- DB views reading this object: `campsite_review_summary`
- DB functions reading this object: none
- DB functions writing this object: none
- Triggers on this object: none
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/src/app/api/campsite-reviews/route.ts#body
  - product/runtime camperplaner-product/apps/web/src/app/api/campsite-reviews/route.ts#reviewId
  - product/runtime camperplaner-product/apps/web/src/app/api/campsite-reviews/route.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/lib/campsite-reviews.ts#resolution
  - product/runtime camperplaner-product/apps/web/src/lib/campsite-reviews.ts#supabase
- Runtime writers:
  - product/runtime camperplaner-product/apps/web/src/app/api/campsite-reviews/route.ts#body
  - product/runtime camperplaner-product/apps/web/src/app/api/campsite-reviews/route.ts#reviewId
  - product/runtime camperplaner-product/apps/web/src/lib/campsite-reviews.ts#resolution
  - product/runtime camperplaner-product/apps/web/src/lib/campsite-reviews.ts#supabase

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `uuid` | Primary key | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/campsite-reviews/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/campsite-reviews/route.ts#reviewId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/campsite-reviews/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/campsite-reviews.ts#resolution`<br>`product/runtime camperplaner-product/apps/web/src/lib/campsite-reviews.ts#supabase` | none | none | default: gen_random_uuid(); not null |
| `user_id` | `uuid` | FK -> profiles.id | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/campsite-reviews/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/app/api/campsite-reviews/route.ts#reviewId`<br>`product/runtime camperplaner-product/apps/web/src/app/api/campsite-reviews/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/campsite-reviews.ts#resolution`<br>`product/runtime camperplaner-product/apps/web/src/lib/campsite-reviews.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/app/api/campsite-reviews/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/lib/campsite-reviews.ts#resolution` | none | not null |
| `place_id` | `text` | Identifier | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/campsite-reviews/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/campsite-reviews.ts#resolution` | `product/runtime camperplaner-product/apps/web/src/lib/campsite-reviews.ts#resolution` | `campsite_review_summary` | not null |
| `place_name` | `text` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/campsite-reviews/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/campsite-reviews.ts#resolution` | `product/runtime camperplaner-product/apps/web/src/lib/campsite-reviews.ts#resolution` | `campsite_review_summary` | not null |
| `rating` | `integer` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/campsite-reviews/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/campsite-reviews.ts#resolution` | none | `campsite_review_summary` | not null |
| `comment` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/campsite-reviews/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/campsite-reviews.ts#resolution` | `product/runtime camperplaner-product/apps/web/src/app/api/campsite-reviews/route.ts#body`<br>`product/runtime camperplaner-product/apps/web/src/lib/campsite-reviews.ts#resolution`<br>`product/runtime camperplaner-product/apps/web/src/lib/campsite-reviews.ts#supabase` | none | — |
| `created_at` | `timestamp with time zone | null` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/campsite-reviews/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/campsite-reviews.ts#resolution` | none | none | default: now() |

## `google_place_matches`

- Typ: table
- Zweck: Mapping between canonical/OSM places and Google Place IDs.
- Live rows: 14
- Primary key: `id`
- Outgoing foreign keys: none
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: none
- Triggers on this object: none
- Runtime readers:
  - none
- Runtime writers:
  - none

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `uuid` | Primary key | observed in schema | none | none | none | default: gen_random_uuid(); not null |
| `osm_id` | `text` | Identifier | observed in schema | none | none | none | not null |
| `osm_name` | `text` | Data field | observed in schema | none | none | none | not null |
| `osm_lat` | `double precision` | Metric/value | observed in schema | none | none | none | not null |
| `osm_lng` | `double precision` | Metric/value | observed in schema | none | none | none | not null |
| `google_place_id` | `text | null` | Identifier | observed in schema | none | none | none | — |
| `google_place_name` | `text | null` | Data field | observed in schema | none | none | none | — |
| `google_place_address` | `text | null` | Data field | observed in schema | none | none | none | — |
| `matched_at` | `timestamp with time zone | null` | Timestamp | observed in schema | none | none | none | default: now() |
| `match_confidence` | `double precision | null` | Data field | observed in schema | none | none | none | — |
| `status` | `text | null` | Status field | observed in schema | none | none | none | default: 'matched'::text |
| `created_at` | `timestamp with time zone | null` | Timestamp | observed in schema | none | none | none | default: now() |
| `updated_at` | `timestamp with time zone | null` | Timestamp | observed in schema | none | none | none | default: now() |
| `osm_location` | `geography | null` | Spatial data | observed in schema | none | none | none | — |

## `google_places_cache`

- Typ: table
- Zweck: Cached raw Google Places responses.
- Live rows: 13
- Primary key: `id`
- Outgoing foreign keys: none
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: none
- Triggers on this object: none
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/lib/google-places-server.ts#readGoogleBridgeCache
- Runtime writers:
  - product/runtime camperplaner-product/apps/web/src/lib/google-places-server.ts#persistGoogleBridge

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `uuid` | Primary key | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase` | none | none | default: gen_random_uuid(); not null |
| `place_id` | `character varying` | Identifier | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/google-places-server.ts#readGoogleBridgeCache` | `product/runtime camperplaner-product/apps/web/src/lib/google-places-server.ts#persistGoogleBridge` | none | not null |
| `name` | `character varying | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/google-places-server.ts#readGoogleBridgeCache` | `product/runtime camperplaner-product/apps/web/src/lib/google-places-server.ts#persistGoogleBridge` | none | — |
| `data` | `jsonb | null` | JSON payload | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/google-places-server.ts#readGoogleBridgeCache` | `product/runtime camperplaner-product/apps/web/src/lib/google-places-server.ts#persistGoogleBridge` | none | — |
| `fetched_at` | `timestamp with time zone | null` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/google-places-server.ts#readGoogleBridgeCache` | `product/runtime camperplaner-product/apps/web/src/lib/google-places-server.ts#persistGoogleBridge` | none | default: CURRENT_TIMESTAMP |
| `expires_at` | `timestamp with time zone | null` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/google-places-server.ts#readGoogleBridgeCache` | `product/runtime camperplaner-product/apps/web/src/lib/google-places-server.ts#persistGoogleBridge` | none | — |

## `place_enrichment`

- Typ: table
- Zweck: Stored enrichment payloads and generation results for places.
- Live rows: 0
- Primary key: `id`
- Outgoing foreign keys: `place_id` -> `places.id`
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: none
- Triggers on this object: none
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/scripts/cutover-check.mjs#loadMetrics
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#failureMessage
  - product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#readLatestEnrichmentEvidence
  - product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#structuredFieldUpdates
  - worker/runtime camperplaner-worker/src/lib/descriptions/job-processor.ts#result
- Runtime writers:
  - product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#failureMessage
  - product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#structuredFieldUpdates
  - product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#upsertEnrichmentEvidenceRow
  - worker/runtime camperplaner-worker/src/lib/descriptions/job-processor.ts#sb

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `bigint` | Primary key | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase` | none | none | default: nextval('place_enrichment_id_seq'::regclass); not null |
| `place_id` | `bigint` | FK -> places.id | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#failureMessage`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#readLatestEnrichmentEvidence`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#structuredFieldUpdates`<br>`worker/runtime camperplaner-worker/src/lib/descriptions/job-processor.ts#result` | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#upsertEnrichmentEvidenceRow`<br>`worker/runtime camperplaner-worker/src/lib/descriptions/job-processor.ts#sb` | none | not null |
| `status` | `enrichment_status_enum` | Status field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#failureMessage`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#structuredFieldUpdates`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#upsertEnrichmentEvidenceRow`<br>`worker/runtime camperplaner-worker/src/lib/descriptions/job-processor.ts#sb` | none | default: 'pending'::enrichment_status_enum; not null |
| `provider` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase` | none | none | — |
| `model` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase` | none | none | — |
| `prompt_version` | `text | null` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase` | none | none | — |
| `source_urls` | `jsonb` | JSON payload | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#readLatestEnrichmentEvidence`<br>`worker/runtime camperplaner-worker/src/lib/descriptions/job-processor.ts#result` | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#structuredFieldUpdates`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#upsertEnrichmentEvidenceRow`<br>`worker/runtime camperplaner-worker/src/lib/descriptions/job-processor.ts#sb` | none | default: '[]'::jsonb; not null |
| `extracted` | `jsonb` | JSON payload | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#structuredFieldUpdates`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#upsertEnrichmentEvidenceRow`<br>`worker/runtime camperplaner-worker/src/lib/descriptions/job-processor.ts#sb` | none | default: '{}'::jsonb; not null |
| `summary_de` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase` | none | none | — |
| `confidence` | `numeric | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase` | none | none | — |
| `hallucination_risk` | `numeric | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase` | none | none | — |
| `token_input` | `integer | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase` | none | none | — |
| `token_output` | `integer | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase` | none | none | — |
| `cost_usd` | `numeric | null` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase` | none | none | — |
| `validation_errors` | `jsonb` | JSON payload | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#failureMessage`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#upsertEnrichmentEvidenceRow`<br>`worker/runtime camperplaner-worker/src/lib/descriptions/job-processor.ts#sb` | none | default: '[]'::jsonb; not null |
| `created_at` | `timestamp with time zone` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#readLatestEnrichmentEvidence`<br>`worker/runtime camperplaner-worker/src/lib/descriptions/job-processor.ts#result` | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#upsertEnrichmentEvidenceRow`<br>`worker/runtime camperplaner-worker/src/lib/descriptions/job-processor.ts#sb` | none | default: now(); not null |
| `completed_at` | `timestamp with time zone | null` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#failureMessage`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#structuredFieldUpdates` | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#failureMessage` | none | — |

## `place_features`

- Typ: table
- Zweck: Secondary place-features table; currently looks unused.
- Live rows: 0
- Primary key: `place_id`
- Outgoing foreign keys: `place_id` -> `places.id`
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: none
- Triggers on this object: `trg_place_features_set_updated_at -> set_updated_at_timestamp`
- Runtime readers:
  - none
- Runtime writers:
  - none

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `place_id` | `bigint` | Primary key | observed in schema | none | none | none | not null |
| `max_vehicle_length_m` | `numeric | null` | Data field | observed in schema | none | none | none | — |
| `number_of_pitches` | `integer | null` | Data field | observed in schema | none | none | none | — |
| `has_dump_station` | `boolean | null` | Boolean flag | observed in schema | none | none | none | — |
| `has_waste_disposal` | `boolean | null` | Boolean flag | observed in schema | none | none | none | — |
| `noise_level` | `smallint | null` | Data field | observed in schema | none | none | none | — |
| `family_friendly` | `smallint | null` | Data field | observed in schema | none | none | none | — |
| `scenic_score` | `smallint | null` | Data field | observed in schema | none | none | none | — |
| `updated_at` | `timestamp with time zone` | Timestamp | observed in schema | none | none | none | default: now(); not null |

## `place_duplicate_candidates`

- Typ: table
- Zweck: Candidate duplicates detected during cutover/deduplication.
- Live rows: 0
- Primary key: `id`
- Outgoing foreign keys: `primary_place_id` -> `places.id`, `duplicate_place_id` -> `places.id`
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: none
- Triggers on this object: none
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#fetchCandidates
  - product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#handleResolution
  - worker/runtime camperplaner-worker/src/services/edge-cases.ts#now
  - worker/runtime camperplaner-worker/src/services/edge-cases.ts#sourceIds
- Runtime writers:
  - product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#handleResolution
  - worker/runtime camperplaner-worker/src/services/edge-cases.ts#now
  - worker/runtime camperplaner-worker/src/services/edge-cases.ts#sourceIds
  - worker/runtime camperplaner-worker/src/services/import-runner.ts#insertData

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `bigint` | Primary key | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#fetchCandidates`<br>`product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#handleResolution`<br>`worker/runtime camperplaner-worker/src/services/edge-cases.ts#now` | none | none | default: nextval('place_duplicate_candidates_id_seq'::regclass); not null |
| `primary_place_id` | `bigint` | FK -> places.id | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#fetchCandidates`<br>`worker/runtime camperplaner-worker/src/services/edge-cases.ts#now`<br>`worker/runtime camperplaner-worker/src/services/edge-cases.ts#sourceIds` | none | none | not null |
| `duplicate_place_id` | `bigint | null` | FK -> places.id | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#fetchCandidates`<br>`worker/runtime camperplaner-worker/src/services/edge-cases.ts#now`<br>`worker/runtime camperplaner-worker/src/services/edge-cases.ts#sourceIds` | none | none | — |
| `candidate_osm_type` | `text | null` | Classifier | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#fetchCandidates`<br>`worker/runtime camperplaner-worker/src/services/edge-cases.ts#now` | none | none | — |
| `candidate_osm_id` | `bigint | null` | Identifier | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#fetchCandidates`<br>`worker/runtime camperplaner-worker/src/services/edge-cases.ts#now` | none | none | — |
| `candidate_geometry_kind` | `text | null` | Classifier | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#fetchCandidates`<br>`worker/runtime camperplaner-worker/src/services/edge-cases.ts#now` | none | none | — |
| `match_type` | `text` | Classifier | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#fetchCandidates`<br>`worker/runtime camperplaner-worker/src/services/edge-cases.ts#now` | none | none | not null |
| `match_score` | `numeric` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#fetchCandidates`<br>`worker/runtime camperplaner-worker/src/services/edge-cases.ts#now` | none | none | not null |
| `distance_meters` | `numeric | null` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#fetchCandidates`<br>`worker/runtime camperplaner-worker/src/services/edge-cases.ts#now` | none | none | — |
| `name_similarity` | `numeric | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#fetchCandidates`<br>`worker/runtime camperplaner-worker/src/services/edge-cases.ts#now` | none | none | — |
| `detected_at` | `timestamp with time zone` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#fetchCandidates`<br>`worker/runtime camperplaner-worker/src/services/edge-cases.ts#now` | none | none | default: now(); not null |
| `reviewed_at` | `timestamp with time zone | null` | Timestamp | observed in schema | `worker/runtime camperplaner-worker/src/services/edge-cases.ts#now` | `worker/runtime camperplaner-worker/src/services/edge-cases.ts#now`<br>`worker/runtime camperplaner-worker/src/services/edge-cases.ts#sourceIds` | none | — |
| `reviewed_by` | `uuid | null` | Data field | observed in schema | `worker/runtime camperplaner-worker/src/services/edge-cases.ts#now` | `worker/runtime camperplaner-worker/src/services/edge-cases.ts#now` | none | — |
| `resolution` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#fetchCandidates`<br>`worker/runtime camperplaner-worker/src/services/edge-cases.ts#now`<br>`worker/runtime camperplaner-worker/src/services/edge-cases.ts#sourceIds` | `product/runtime camperplaner-product/apps/web/src/app/admin/duplicates/page.tsx#handleResolution`<br>`worker/runtime camperplaner-worker/src/services/edge-cases.ts#now`<br>`worker/runtime camperplaner-worker/src/services/edge-cases.ts#sourceIds` | none | — |
| `resolution_notes` | `text | null` | Data field | observed in schema | `worker/runtime camperplaner-worker/src/services/edge-cases.ts#now` | `worker/runtime camperplaner-worker/src/services/edge-cases.ts#now`<br>`worker/runtime camperplaner-worker/src/services/edge-cases.ts#sourceIds` | none | — |

## `countries`

- Typ: table
- Zweck: Master data for importable countries and Geofabrik metadata.
- Live rows: 49
- Primary key: `iso_code`
- Outgoing foreign keys: none
- Incoming foreign keys: `osm_import_queue.country_code`, `country_import_status.country_code`
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: none
- Triggers on this object: none
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/[code]/status/route.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/route.ts#supabase
  - worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#supabase
- Runtime writers:
  - none

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `iso_code` | `character varying` | Primary key | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/[code]/status/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/route.ts#supabase`<br>`worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#supabase` | none | none | not null |
| `name` | `character varying` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/[code]/status/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/route.ts#supabase` | none | none | not null |
| `geofabrik_name` | `character varying` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#supabase` | none | none | not null |
| `geofabrik_url` | `text` | Data field | observed in schema | none | none | none | not null |
| `bounding_box` | `jsonb` | JSON payload | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/[code]/status/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/route.ts#supabase` | none | none | not null |
| `created_at` | `timestamp with time zone | null` | Timestamp | observed in schema | none | none | none | default: now() |

## `country_import_status`

- Typ: table
- Zweck: Per-country import status tracking for OSM imports.
- Live rows: 49
- Primary key: `id`
- Outgoing foreign keys: `country_code` -> `countries.iso_code`
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: none
- Triggers on this object: `trg_country_import_status_updated_at -> update_country_import_status_updated_at`
- Runtime readers:
  - none
- Runtime writers:
  - worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#updateCountryImportStatus

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `uuid` | Primary key | observed in schema | none | none | none | default: gen_random_uuid(); not null |
| `country_code` | `character varying` | FK -> countries.iso_code | observed in schema | none | `worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#updateCountryImportStatus` | none | not null |
| `status` | `character varying` | Status field | observed in schema | none | none | none | default: 'pending'::character varying; not null |
| `source_type` | `character varying` | Classifier | observed in schema | none | none | none | default: 'geofabrik'::character varying; not null |
| `started_at` | `timestamp with time zone | null` | Timestamp | observed in schema | none | none | none | — |
| `completed_at` | `timestamp with time zone | null` | Timestamp | observed in schema | none | none | none | — |
| `poi_count` | `integer | null` | Metric/value | observed in schema | none | none | none | default: 0 |
| `error_message` | `text | null` | Data field | observed in schema | none | none | none | — |
| `created_at` | `timestamp with time zone | null` | Timestamp | observed in schema | none | none | none | default: now() |
| `updated_at` | `timestamp with time zone | null` | Timestamp | observed in schema | none | none | none | default: now() |

## `osm_source`

- Typ: table
- Zweck: Source-of-truth raw OSM records that back canonical places.
- Live rows: 205284
- Primary key: `id`
- Outgoing foreign keys: `place_id` -> `places.id`, `last_import_run_id` -> `osm_import_runs.id`
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: `mark_stale_sources`
- Triggers on this object: none
- Runtime readers:
  - worker/runtime camperplaner-worker/src/services/edge-cases.ts#now
  - worker/runtime camperplaner-worker/src/services/edge-cases.ts#sourceIds
  - worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#osmId
  - worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#seenAt
  - worker/runtime camperplaner-worker/src/services/source-management.ts#wktPoint
  - worker/runtime camperplaner-worker/src/utils/matching.ts#geometryHashResult
  - worker/runtime camperplaner-worker/src/utils/matching.ts#sourceKeyResult
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#findExistingSource
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#updateSourceMetadata
  - worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#<module>
  - worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#placePayload
- Runtime writers:
  - worker/runtime camperplaner-worker/src/services/edge-cases.ts#sourceIds
  - worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#seenAt
  - worker/runtime camperplaner-worker/src/services/source-management.ts#wktPoint
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#existingSource
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#updateSourceMetadata
  - worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#<module>
  - worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#placePayload
- Indirect writers via RPC:
  - mark_stale_sources <= worker/runtime camperplaner-worker/src/services/import-runner.ts#newPlaceId

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `bigint` | Primary key | observed in schema | `worker/runtime camperplaner-worker/src/services/edge-cases.ts#now`<br>`worker/runtime camperplaner-worker/src/services/edge-cases.ts#sourceIds`<br>`worker/runtime camperplaner-worker/src/services/source-management.ts#wktPoint` | none | none | default: nextval('osm_source_id_seq'::regclass); not null |
| `place_id` | `bigint` | FK -> places.id | observed in schema | `worker/runtime camperplaner-worker/src/services/edge-cases.ts#now`<br>`worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#osmId`<br>`worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#seenAt`<br>`worker/runtime camperplaner-worker/src/utils/matching.ts#geometryHashResult`<br>`worker/runtime camperplaner-worker/src/utils/matching.ts#sourceKeyResult`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#findExistingSource`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#<module>`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#placePayload` | `worker/runtime camperplaner-worker/src/services/edge-cases.ts#sourceIds`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#placePayload` | none | not null |
| `osm_type` | `text` | Classifier | observed in schema | `worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#osmId`<br>`worker/runtime camperplaner-worker/src/utils/matching.ts#sourceKeyResult`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#findExistingSource`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#updateSourceMetadata`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#placePayload` | `worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#placePayload` | none | not null |
| `osm_id` | `bigint` | Identifier | observed in schema | `worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#osmId`<br>`worker/runtime camperplaner-worker/src/utils/matching.ts#sourceKeyResult`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#findExistingSource`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#updateSourceMetadata`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#placePayload` | `worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#placePayload` | none | not null |
| `osm_version` | `integer | null` | Metric/value | all values NULL | `worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#osmId` | `worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#seenAt`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#updateSourceMetadata`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#placePayload` | none | all live values NULL |
| `tags` | `jsonb` | JSON payload | observed in schema | `worker/runtime camperplaner-worker/src/workers/osm-import.ts#findExistingSource` | `worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#seenAt`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#updateSourceMetadata`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#<module>`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#placePayload` | none | default: '{}'::jsonb; not null |
| `raw_name` | `text | null` | Data field | observed in schema | `worker/runtime camperplaner-worker/src/workers/osm-import.ts#findExistingSource` | `worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#seenAt`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#updateSourceMetadata`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#<module>`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#placePayload` | none | — |
| `source_snapshot_date` | `date | null` | Data field | observed in schema | `worker/runtime camperplaner-worker/src/workers/osm-import.ts#findExistingSource` | `worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#seenAt`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#updateSourceMetadata`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#<module>`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#placePayload` | none | — |
| `imported_at` | `timestamp with time zone` | Timestamp | observed in schema | none | none | none | default: now(); not null |
| `first_seen_at` | `timestamp with time zone` | Timestamp | observed in schema | none | none | none | default: now(); not null |
| `last_seen_at` | `timestamp with time zone` | Timestamp | observed in schema | none | `worker/runtime camperplaner-worker/src/services/edge-cases.ts#sourceIds` | none | default: now(); not null |
| `last_import_run_id` | `bigint | null` | FK -> osm_import_runs.id | observed in schema | none | none | none | — |
| `geometry_kind` | `text | null` | Classifier | all values NULL | `worker/runtime camperplaner-worker/src/utils/matching.ts#sourceKeyResult` | none | none | all live values NULL |
| `geometry_hash` | `text | null` | Data field | all values NULL | `worker/runtime camperplaner-worker/src/utils/matching.ts#geometryHashResult` | none | none | all live values NULL |
| `centroid` | `geography | null` | Spatial data | all values NULL | none | none | none | all live values NULL |
| `geom` | `geometry | null` | Spatial data | all values NULL | none | none | none | all live values NULL |
| `osm_timestamp` | `timestamp with time zone | null` | Data field | all values NULL | none | none | none | all live values NULL |
| `osmium_unique_id` | `text | null` | Identifier | all values NULL | none | none | none | all live values NULL |
| `first_seen_snapshot_id` | `uuid | null` | Identifier | all values NULL | none | none | none | all live values NULL |
| `last_seen_snapshot_id` | `uuid | null` | Identifier | all values NULL | none | none | none | all live values NULL |
| `is_current` | `boolean` | Boolean flag | observed in schema | `worker/runtime camperplaner-worker/src/services/edge-cases.ts#now`<br>`worker/runtime camperplaner-worker/src/utils/matching.ts#geometryHashResult`<br>`worker/runtime camperplaner-worker/src/utils/matching.ts#sourceKeyResult` | `worker/runtime camperplaner-worker/src/services/edge-cases.ts#sourceIds` | none | default: true; not null |
| `source_metadata` | `jsonb` | JSON payload | observed in schema | none | none | none | default: '{}'::jsonb; not null |

## `osm_import_queue`

- Typ: table
- Zweck: Database-backed work queue for OSM imports.
- Live rows: 54
- Primary key: `id`
- Outgoing foreign keys: `job_reference_id` -> `osm_import_jobs.id`, `country_code` -> `countries.iso_code`
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: `claim_osm_import_job`
- DB functions writing this object: `claim_osm_import_job`, `increment_job_retry`
- Triggers on this object: `trg_osm_import_queue_updated_at -> update_osm_import_queue_updated_at`
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords
  - product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#jobIds
  - product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#duration
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#cancelledAt
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#bbox
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#staleJobIds
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit
  - worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#completeJob
  - worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#failJob
  - worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#resetJobToQueued
- Runtime writers:
  - product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#jobIds
  - product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#triggerImport
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#cancelledAt
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#staleJobIds
  - worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#completeJob
  - worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#failJob
  - worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#resetJobToQueued
- Indirect readers via RPC:
  - claim_osm_import_job <= worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#claimJob
- Indirect writers via RPC:
  - claim_osm_import_job <= worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#claimJob
  - increment_job_retry <= worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#incrementRetryCounter
- Test readers:
  - product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#jobIds
- Test writers:
  - product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#jobIds

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `bigint` | Primary key | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#duration`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#cancelledAt`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#bbox`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#staleJobIds`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#jobIds`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#completeJob`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#failJob`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#resetJobToQueued` | none | none | default: nextval('osm_import_queue_id_seq'::regclass); not null |
| `job_type` | `character varying` | Classifier | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#duration`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | `product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#jobIds`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#triggerImport`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#staleJobIds` | none | not null |
| `status` | `character varying` | Status field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#duration`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#cancelledAt`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#bbox`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | `product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#jobIds`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#triggerImport`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#cancelledAt`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#staleJobIds`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#completeJob`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#failJob`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#resetJobToQueued` | none | default: 'queued'::character varying; not null |
| `bbox` | `jsonb | null` | JSON payload | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#duration`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | `product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#triggerImport` | none | — |
| `options` | `jsonb | null` | JSON payload | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#duration`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | `product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#jobIds`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#triggerImport`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#staleJobIds` | none | default: '{}'::jsonb |
| `priority` | `integer | null` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#duration`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | `product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#jobIds`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#triggerImport`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#staleJobIds` | none | default: 0 |
| `worker_id` | `character varying | null` | Identifier | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#duration`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | `worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#resetJobToQueued` | none | — |
| `job_reference_id` | `uuid | null` | FK -> osm_import_jobs.id | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#jobIds`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#duration`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#cancelledAt`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#bbox`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#jobIds`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#completeJob`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#failJob` | `product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#jobIds`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#triggerImport`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#staleJobIds` | none | — |
| `error_message` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#duration`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#cancelledAt` | none | — |
| `created_at` | `timestamp with time zone` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#duration`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#cancelledAt`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | none | none | default: now(); not null |
| `started_at` | `timestamp with time zone | null` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#duration`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | `worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#resetJobToQueued` | none | — |
| `completed_at` | `timestamp with time zone | null` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#duration`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#cancelledAt`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#completeJob`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#failJob` | none | — |
| `updated_at` | `timestamp with time zone` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#duration`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | none | none | default: now(); not null |
| `country_code` | `character varying | null` | FK -> countries.iso_code | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#duration`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#bbox`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#staleJobIds` | none | — |
| `source_type` | `character varying | null` | Classifier | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#duration`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#bbox`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#staleJobIds` | none | default: 'geofabrik'::character varying |
| `retry_count` | `integer` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#duration`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | none | none | default: 0; not null |

## `osm_import_jobs`

- Typ: table
- Zweck: Top-level OSM import jobs visible to product/admin UI.
- Live rows: 47
- Primary key: `id`
- Outgoing foreign keys: none
- Incoming foreign keys: `osm_import_queue.job_reference_id`
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: none
- Triggers on this object: `update_osm_import_jobs_updated_at -> update_osm_import_jobs_updated_at`
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords
  - product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#<module>
  - product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#availableKB
  - product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#jobIds
  - product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#startTime
  - product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#lons
  - product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#maxLon
  - product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#getInitialState
  - product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#maxAttempts
  - product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#triggerImport
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#<module>
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#cancelledAt
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/[code]/status/route.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#staleJobIds
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/route.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit
  - worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#completeJob
  - worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#failJob
- Runtime writers:
  - product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#<module>
  - product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#jobIds
  - product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#triggerImport
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#<module>
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#staleJobIds
  - worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#completeJob
  - worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#failJob
- Test readers:
  - product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#jobIds
  - product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key
- Test writers:
  - product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#jobIds

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `uuid` | Primary key | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#<module>`<br>`product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#availableKB`<br>`product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#jobIds`<br>`product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#startTime`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#lons`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#maxLon`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#getInitialState`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#maxAttempts`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#<module>`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#cancelledAt`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/[code]/status/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#staleJobIds`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#jobIds`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#completeJob`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#failJob` | none | none | default: gen_random_uuid(); not null |
| `job_type` | `character varying` | Classifier | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#startTime`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#lons`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#maxLon`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#getInitialState`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#maxAttempts`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/[code]/status/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | `product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#jobIds`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#triggerImport`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#staleJobIds` | none | not null |
| `status` | `character varying` | Status field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#startTime`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#lons`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#maxLon`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#getInitialState`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#maxAttempts`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#<module>`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#cancelledAt`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/[code]/status/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#staleJobIds`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | `product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#jobIds`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#triggerImport`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#<module>`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#staleJobIds`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#completeJob`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#failJob` | none | default: 'pending'::character varying; not null |
| `started_at` | `timestamp with time zone | null` | Timestamp | all values NULL | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#startTime`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#lons`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#maxLon`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#getInitialState`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#maxAttempts`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/[code]/status/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | `product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#jobIds`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#triggerImport` | none | all live values NULL |
| `completed_at` | `timestamp with time zone | null` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#startTime`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#lons`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#maxLon`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#getInitialState`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#maxAttempts`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/[code]/status/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#<module>`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#staleJobIds`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#completeJob`<br>`worker/runtime camperplaner-worker/src/workers/osm-queue-worker.ts#failJob` | none | — |
| `result` | `jsonb | null` | JSON payload | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#startTime`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#lons`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#maxLon`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#getInitialState`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#maxAttempts`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/[code]/status/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#staleJobIds` | none | — |
| `error_message` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#startTime`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#lons`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#maxLon`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#getInitialState`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#maxAttempts`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/[code]/status/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#<module>`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#staleJobIds` | none | — |
| `created_by` | `uuid | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#startTime`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#lons`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#maxLon`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#getInitialState`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#maxAttempts`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/import/route.ts#staleJobIds` | none | — |
| `created_at` | `timestamp with time zone` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#startTime`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#lons`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#maxLon`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#getInitialState`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#maxAttempts`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#cancelledAt`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/[code]/status/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/countries/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | none | default: now(); not null |
| `updated_at` | `timestamp with time zone` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/analyze-germany.mjs#withCoords`<br>`product/runtime camperplaner-product/apps/web/scripts/benchmarks/osm-import-benchmark.mjs#startTime`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-final-report.mjs#lons`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-report.mjs#maxLon`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#getInitialState`<br>`product/runtime camperplaner-product/apps/web/scripts/germany-e2e-test.mjs#maxAttempts`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`product/test camperplaner-product/apps/web/e2e/europe-import.spec.ts#key` | none | none | default: now(); not null |

## `osm_import_runs`

- Typ: table
- Zweck: Detailed execution log for OSM import runs.
- Live rows: 9
- Primary key: `id`
- Outgoing foreign keys: `parent_run_id` -> `osm_import_runs.id`
- Incoming foreign keys: `osm_import_runs.parent_run_id`, `osm_source.last_import_run_id`, `osm_refresh_jobs.last_run_id`
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: none
- Triggers on this object: none
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#<module>
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#cancelledAt
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#checkIfRunCancelled
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#finishImportRun
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#startImportRun
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#updateImportRunProgress
- Runtime writers:
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#<module>
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#finishImportRun
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#startImportRun
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#updateImportRunProgress

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `bigint` | Primary key | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#<module>`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#cancelledAt`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#checkIfRunCancelled`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#finishImportRun`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#startImportRun`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#updateImportRunProgress` | none | none | default: nextval('osm_import_runs_id_seq'::regclass); not null |
| `source` | `text` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | `worker/runtime camperplaner-worker/src/workers/osm-import.ts#startImportRun` | none | default: 'overpass'::text; not null |
| `status` | `text` | Status field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#<module>`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#cancelledAt`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#checkIfRunCancelled` | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#<module>`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#startImportRun` | none | default: 'running'::text; not null |
| `bbox` | `jsonb | null` | JSON payload | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | none | none | — |
| `tile_count` | `integer` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | `worker/runtime camperplaner-worker/src/workers/osm-import.ts#startImportRun` | none | default: 0; not null |
| `fetched_count` | `integer` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | none | none | default: 0; not null |
| `normalized_count` | `integer` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | none | none | default: 0; not null |
| `imported_count` | `integer` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | none | none | default: 0; not null |
| `created_count` | `integer` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | none | none | default: 0; not null |
| `updated_count` | `integer` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | none | none | default: 0; not null |
| `noop_count` | `integer` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | none | none | default: 0; not null |
| `failed_count` | `integer` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | none | none | default: 0; not null |
| `stale_marked_inactive_count` | `integer` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | none | none | default: 0; not null |
| `error_messages` | `jsonb` | JSON payload | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#<module>` | none | default: '[]'::jsonb; not null |
| `started_at` | `timestamp with time zone` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#cancelledAt`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | `worker/runtime camperplaner-worker/src/workers/osm-import.ts#startImportRun` | none | default: now(); not null |
| `finished_at` | `timestamp with time zone | null` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/cancel/route.ts#<module>` | none | — |
| `run_kind` | `text` | Classifier | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | `worker/runtime camperplaner-worker/src/workers/osm-import.ts#startImportRun` | none | default: 'bootstrap'::text; not null |
| `ingestion_provider` | `text` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | `worker/runtime camperplaner-worker/src/workers/osm-import.ts#startImportRun` | none | default: 'overpass'::text; not null |
| `tile_key` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | `worker/runtime camperplaner-worker/src/workers/osm-import.ts#startImportRun` | none | — |
| `parent_run_id` | `bigint | null` | FK -> osm_import_runs.id | all values NULL | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | `worker/runtime camperplaner-worker/src/workers/osm-import.ts#startImportRun` | none | all live values NULL |
| `queue_job_id` | `bigint | null` | Identifier | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | `worker/runtime camperplaner-worker/src/workers/osm-import.ts#startImportRun` | none | — |
| `current_tile` | `integer | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | none | none | default: 0 |
| `total_tiles` | `integer | null` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | none | none | default: 0 |

## `osm_refresh_jobs`

- Typ: table
- Zweck: Refresh job tracker for OSM source refreshes.
- Live rows: 56
- Primary key: `id`
- Outgoing foreign keys: `last_run_id` -> `osm_import_runs.id`
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: none
- Triggers on this object: `trg_osm_refresh_jobs_set_updated_at -> set_osm_refresh_updated_at`
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#completeRefreshTileJob
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#failRefreshTileJob
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#key
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#nowIso
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#rows
- Runtime writers:
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#completeRefreshTileJob
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#failRefreshTileJob
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#key
  - worker/runtime camperplaner-worker/src/workers/osm-import.ts#rows

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `bigint` | Primary key | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#completeRefreshTileJob`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#failRefreshTileJob`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#key`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#nowIso`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#rows` | none | none | default: nextval('osm_refresh_jobs_id_seq'::regclass); not null |
| `tile_key` | `text` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#key`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#nowIso` | `worker/runtime camperplaner-worker/src/workers/osm-import.ts#key` | none | not null |
| `bbox` | `jsonb` | JSON payload | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#nowIso` | `worker/runtime camperplaner-worker/src/workers/osm-import.ts#key` | none | not null |
| `source_provider` | `text` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | `worker/runtime camperplaner-worker/src/workers/osm-import.ts#key` | none | default: 'overpass'::text; not null |
| `status` | `text` | Status field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#key`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#nowIso`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#rows` | `worker/runtime camperplaner-worker/src/workers/osm-import.ts#completeRefreshTileJob`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#failRefreshTileJob`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#key`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#rows` | none | default: 'queued'::text; not null |
| `attempts` | `integer` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#nowIso` | `worker/runtime camperplaner-worker/src/workers/osm-import.ts#key`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#rows` | none | default: 0; not null |
| `max_attempts` | `integer` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#nowIso` | none | none | default: 8; not null |
| `priority` | `smallint` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | none | none | default: 100; not null |
| `run_after` | `timestamp with time zone` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#nowIso` | `worker/runtime camperplaner-worker/src/workers/osm-import.ts#completeRefreshTileJob`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#failRefreshTileJob`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#key` | none | default: now(); not null |
| `locked_by` | `text | null` | Data field | all values NULL | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | `worker/runtime camperplaner-worker/src/workers/osm-import.ts#key`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#rows` | none | all live values NULL |
| `lease_expires_at` | `timestamp with time zone | null` | Timestamp | all values NULL | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | `worker/runtime camperplaner-worker/src/workers/osm-import.ts#key`<br>`worker/runtime camperplaner-worker/src/workers/osm-import.ts#rows` | none | all live values NULL |
| `last_run_id` | `bigint | null` | FK -> osm_import_runs.id | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | none | none | — |
| `error_message` | `text | null` | Data field | all values NULL | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | none | none | all live values NULL |
| `created_at` | `timestamp with time zone` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | none | none | default: now(); not null |
| `updated_at` | `timestamp with time zone` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/osm/status/route.ts#limit` | none | none | default: now(); not null |

## `osm_type_transitions`

- Typ: table
- Zweck: Records merged/transitioned OSM type changes and edge cases.
- Live rows: 0
- Primary key: `id`
- Outgoing foreign keys: `merged_place_id` -> `places.id`
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: none
- Triggers on this object: none
- Runtime readers:
  - none
- Runtime writers:
  - worker/runtime camperplaner-worker/src/services/edge-cases.ts#classification

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `bigint` | Primary key | observed in schema | none | none | none | default: nextval('osm_type_transitions_id_seq'::regclass); not null |
| `old_osm_type` | `text` | Classifier | observed in schema | none | `worker/runtime camperplaner-worker/src/services/edge-cases.ts#classification` | none | not null |
| `old_osm_id` | `bigint` | Identifier | observed in schema | none | `worker/runtime camperplaner-worker/src/services/edge-cases.ts#classification` | none | not null |
| `new_osm_type` | `text` | Classifier | observed in schema | none | `worker/runtime camperplaner-worker/src/services/edge-cases.ts#classification` | none | not null |
| `new_osm_id` | `bigint` | Identifier | observed in schema | none | `worker/runtime camperplaner-worker/src/services/edge-cases.ts#classification` | none | not null |
| `detected_at` | `timestamp with time zone` | Timestamp | observed in schema | none | none | none | default: now(); not null |
| `transition_type` | `text | null` | Classifier | observed in schema | none | `worker/runtime camperplaner-worker/src/services/edge-cases.ts#classification` | none | — |
| `confidence` | `numeric | null` | Data field | observed in schema | none | `worker/runtime camperplaner-worker/src/services/edge-cases.ts#classification` | none | — |
| `merge_decision` | `text | null` | Data field | observed in schema | none | `worker/runtime camperplaner-worker/src/services/edge-cases.ts#classification` | none | — |
| `merged_place_id` | `bigint | null` | FK -> places.id | observed in schema | none | `worker/runtime camperplaner-worker/src/services/edge-cases.ts#classification` | none | — |

## `import_snapshot`

- Typ: table
- Zweck: Snapshot table for import run summaries/checkpoints.
- Live rows: 0
- Primary key: `id`
- Outgoing foreign keys: none
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: none
- Triggers on this object: none
- Runtime readers:
  - worker/runtime camperplaner-worker/src/services/import-runner.ts#updateSnapshotStats
- Runtime writers:
  - worker/runtime camperplaner-worker/src/services/import-runner.ts#updateSnapshotStats

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `uuid` | Primary key | observed in schema | `worker/runtime camperplaner-worker/src/services/import-runner.ts#updateSnapshotStats` | none | none | not null |
| `region` | `text` | Data field | observed in schema | none | none | none | not null |
| `source_name` | `text` | Data field | observed in schema | none | none | none | not null |
| `source_pbf_date` | `date | null` | Data field | observed in schema | none | none | none | — |
| `source_state` | `text | null` | Data field | observed in schema | none | none | none | — |
| `imported_at` | `timestamp with time zone` | Timestamp | observed in schema | none | none | none | default: now(); not null |
| `matched_count` | `integer | null` | Metric/value | observed in schema | none | `worker/runtime camperplaner-worker/src/services/import-runner.ts#updateSnapshotStats` | none | default: 0 |
| `created_count` | `integer | null` | Metric/value | observed in schema | none | `worker/runtime camperplaner-worker/src/services/import-runner.ts#updateSnapshotStats` | none | default: 0 |
| `stale_count` | `integer | null` | Metric/value | observed in schema | none | `worker/runtime camperplaner-worker/src/services/import-runner.ts#updateSnapshotStats` | none | default: 0 |
| `duplicate_candidates_count` | `integer | null` | Metric/value | observed in schema | none | none | none | default: 0 |
| `error_count` | `integer | null` | Metric/value | observed in schema | none | `worker/runtime camperplaner-worker/src/services/import-runner.ts#updateSnapshotStats` | none | default: 0 |

## `description_generation_jobs`

- Typ: table
- Zweck: Queue/status table for description generation jobs.
- Live rows: 353
- Primary key: `id`
- Outgoing foreign keys: `place_id` -> `campsites_cache.place_id`
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: none
- Triggers on this object: `trigger_set_job_priority -> set_job_priority`, `update_description_jobs_updated_at -> update_updated_at_column`
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#failureMessage
  - product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#structuredFieldUpdates
- Runtime writers:
  - product/runtime camperplaner-product/apps/web/src/lib/descriptions/index.ts#createGenerationJob
  - product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#failureMessage
  - product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#structuredFieldUpdates

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `uuid` | Primary key | observed in schema | none | none | none | default: gen_random_uuid(); not null |
| `place_id` | `text` | FK -> campsites_cache.place_id | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#failureMessage`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#structuredFieldUpdates` | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/index.ts#createGenerationJob` | none | not null |
| `status` | `character varying | null` | Status field | observed in schema | none | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/index.ts#createGenerationJob`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#failureMessage`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#structuredFieldUpdates` | none | default: 'pending'::character varying |
| `priority` | `integer | null` | Metric/value | observed in schema | none | none | none | default: 5 |
| `attempts` | `integer | null` | Metric/value | observed in schema | none | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/index.ts#createGenerationJob` | none | default: 0 |
| `error_message` | `text | null` | Data field | all values NULL | none | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#failureMessage`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#structuredFieldUpdates` | none | all live values NULL |
| `created_at` | `timestamp with time zone | null` | Timestamp | observed in schema | none | none | none | default: now() |
| `updated_at` | `timestamp with time zone | null` | Timestamp | observed in schema | none | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/index.ts#createGenerationJob`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#failureMessage` | none | default: now() |
| `completed_at` | `timestamp with time zone | null` | Timestamp | all values NULL | none | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/job-processor.ts#structuredFieldUpdates` | none | all live values NULL |

## `enrichment_jobs`

- Typ: table
- Zweck: Queue/status table for place enrichment jobs.
- Live rows: 0
- Primary key: `id`
- Outgoing foreign keys: `place_id` -> `places.id`
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: `claim_enrichment_jobs`, `fail_enrichment_job`
- DB functions writing this object: `claim_enrichment_jobs`, `complete_enrichment_job`, `enqueue_enrichment_job`, `fail_enrichment_job`, `heartbeat_enrichment_job`
- Triggers on this object: `trg_enrichment_jobs_set_updated_at -> set_updated_at_timestamp`
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/scripts/cutover-check.mjs#loadMetrics
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/descriptions/jobs/route.ts#queueStatus
- Runtime writers:
  - none
- Indirect readers via RPC:
  - claim_enrichment_jobs <= worker/runtime camperplaner-worker/src/workers/enrichment-queue-worker.ts#createSupabaseEnrichmentQueueClient
  - fail_enrichment_job <= worker/runtime camperplaner-worker/src/workers/enrichment-queue-worker.ts#createSupabaseEnrichmentQueueClient
- Indirect writers via RPC:
  - claim_enrichment_jobs <= worker/runtime camperplaner-worker/src/workers/enrichment-queue-worker.ts#createSupabaseEnrichmentQueueClient
  - complete_enrichment_job <= worker/runtime camperplaner-worker/src/workers/enrichment-queue-worker.ts#createSupabaseEnrichmentQueueClient
  - enqueue_enrichment_job <= product/runtime camperplaner-product/apps/web/src/app/api/admin/descriptions/route.ts#canonicalPublicPlaceId, worker/runtime camperplaner-worker/src/workers/schedule-enrichment-jobs.ts#scheduleEnrichmentJobs
  - fail_enrichment_job <= worker/runtime camperplaner-worker/src/workers/enrichment-queue-worker.ts#createSupabaseEnrichmentQueueClient
  - heartbeat_enrichment_job <= worker/runtime camperplaner-worker/src/workers/enrichment-queue-worker.ts#createSupabaseEnrichmentQueueClient

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `bigint` | Primary key | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/descriptions/jobs/route.ts#queueStatus` | none | none | default: nextval('enrichment_jobs_id_seq'::regclass); not null |
| `place_id` | `bigint` | FK -> places.id | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/descriptions/jobs/route.ts#queueStatus` | none | none | not null |
| `job_type` | `enrichment_job_type_enum` | Classifier | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/descriptions/jobs/route.ts#queueStatus` | none | none | not null |
| `priority` | `smallint` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/descriptions/jobs/route.ts#queueStatus` | none | none | default: 100; not null |
| `status` | `job_status_enum` | Status field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/descriptions/jobs/route.ts#queueStatus` | none | none | default: 'queued'::job_status_enum; not null |
| `attempts` | `integer` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/descriptions/jobs/route.ts#queueStatus` | none | none | default: 0; not null |
| `max_attempts` | `integer` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/descriptions/jobs/route.ts#queueStatus` | none | none | default: 5; not null |
| `run_after` | `timestamp with time zone` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/descriptions/jobs/route.ts#queueStatus` | none | none | default: now(); not null |
| `locked_by` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/descriptions/jobs/route.ts#queueStatus` | none | none | — |
| `locked_at` | `timestamp with time zone | null` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase` | none | none | — |
| `error_message` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/descriptions/jobs/route.ts#queueStatus` | none | none | — |
| `created_at` | `timestamp with time zone` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/descriptions/jobs/route.ts#queueStatus` | none | none | default: now(); not null |
| `updated_at` | `timestamp with time zone` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/descriptions/jobs/route.ts#queueStatus` | none | none | default: now(); not null |
| `freshness_bucket` | `timestamp with time zone` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase` | none | none | default: date_trunc('hour'::text, now()); not null |
| `lease_expires_at` | `timestamp with time zone | null` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/descriptions/jobs/route.ts#queueStatus` | none | none | — |
| `heartbeat_at` | `timestamp with time zone | null` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase` | none | none | — |
| `payload` | `jsonb` | JSON payload | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase` | none | none | default: '{}'::jsonb; not null |
| `context` | `jsonb` | JSON payload | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase` | none | none | default: '{}'::jsonb; not null |
| `last_error_at` | `timestamp with time zone | null` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase` | none | none | — |
| `dead_lettered_at` | `timestamp with time zone | null` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase` | none | none | — |

## `external_place_cache`

- Typ: table
- Zweck: Legacy cache table; decommissioned in product runtime.
- Live rows: 0
- Primary key: `id`
- Outgoing foreign keys: `place_id` -> `places.id`
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: none
- Triggers on this object: none
- Runtime readers:
  - none
- Runtime writers:
  - none

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `bigint` | Primary key | observed in schema | none | none | none | default: nextval('external_place_cache_id_seq'::regclass); not null |
| `place_id` | `bigint | null` | FK -> places.id | observed in schema | none | none | none | — |
| `provider` | `text` | Data field | observed in schema | none | none | none | not null |
| `external_id` | `text` | Identifier | observed in schema | none | none | none | not null |
| `payload` | `jsonb` | JSON payload | observed in schema | none | none | none | default: '{}'::jsonb; not null |
| `fetched_at` | `timestamp with time zone` | Timestamp | observed in schema | none | none | none | default: now(); not null |
| `expires_at` | `timestamp with time zone | null` | Timestamp | observed in schema | none | none | none | — |

## `website_scraping_jobs`

- Typ: table
- Zweck: Queue/status table for website scraping jobs.
- Live rows: 2
- Primary key: `id`
- Outgoing foreign keys: `place_id` -> `campsites_cache.place_id`
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: none
- Triggers on this object: `update_website_scraping_jobs_updated_at -> update_updated_at_column`
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/src/app/api/places/[placeId]/scraped-data/route.ts#data
  - product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#errorMessage
  - product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#updateData
- Runtime writers:
  - product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#errorMessage
  - product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#updateData

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `uuid` | Primary key | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#supabase` | none | none | default: gen_random_uuid(); not null |
| `place_id` | `text` | FK -> campsites_cache.place_id | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/places/[placeId]/scraped-data/route.ts#data`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#errorMessage`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#updateData` | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#supabase` | none | not null |
| `website_url` | `text` | Data field | observed in schema | none | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#supabase` | none | not null |
| `status` | `character varying | null` | Status field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/places/[placeId]/scraped-data/route.ts#data` | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#errorMessage`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#updateData` | none | default: 'pending'::character varying |
| `priority` | `integer | null` | Metric/value | observed in schema | none | none | none | default: 5 |
| `attempts` | `integer | null` | Metric/value | observed in schema | none | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#supabase` | none | default: 0 |
| `extracted_data` | `jsonb | null` | JSON payload | observed in schema | none | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#updateData` | none | — |
| `error_message` | `text | null` | Data field | all values NULL | `product/runtime camperplaner-product/apps/web/src/app/api/places/[placeId]/scraped-data/route.ts#data` | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#errorMessage` | none | all live values NULL |
| `created_at` | `timestamp with time zone | null` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/places/[placeId]/scraped-data/route.ts#data` | none | none | default: now() |
| `updated_at` | `timestamp with time zone | null` | Timestamp | observed in schema | none | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#errorMessage`<br>`product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#supabase` | none | default: now() |
| `completed_at` | `timestamp with time zone | null` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/places/[placeId]/scraped-data/route.ts#data` | `product/runtime camperplaner-product/apps/web/src/lib/descriptions/website-scraping-processor.ts#updateData` | none | — |

## `app_settings`

- Typ: table
- Zweck: Central key-value store for application settings and feature configuration.
- Live rows: 16
- Primary key: `id`
- Outgoing foreign keys: none
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: none
- Triggers on this object: `trigger_settings_audit -> settings_audit_trigger`
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/src/lib/settings.ts#dbValue
  - product/runtime camperplaner-product/apps/web/src/lib/settings.ts#existing
  - product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/lib/settings.ts#type
  - worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#stateKey
- Runtime writers:
  - product/runtime camperplaner-product/apps/web/src/lib/settings.ts#dbValue
  - product/runtime camperplaner-product/apps/web/src/lib/settings.ts#existing
  - product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/lib/settings.ts#type
  - worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#nowIso

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `uuid` | Primary key | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase` | none | none | default: gen_random_uuid(); not null |
| `key` | `text` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/settings.ts#existing`<br>`product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase`<br>`product/runtime camperplaner-product/apps/web/src/lib/settings.ts#type`<br>`worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#stateKey` | `product/runtime camperplaner-product/apps/web/src/lib/settings.ts#dbValue`<br>`product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase`<br>`worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#nowIso` | none | not null |
| `category` | `text` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase`<br>`worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#stateKey` | `product/runtime camperplaner-product/apps/web/src/lib/settings.ts#dbValue`<br>`product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase`<br>`worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#nowIso` | none | not null |
| `type` | `text` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/lib/settings.ts#dbValue`<br>`product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase`<br>`worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#nowIso` | none | not null |
| `value` | `jsonb` | JSON payload | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase`<br>`worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#stateKey` | `product/runtime camperplaner-product/apps/web/src/lib/settings.ts#dbValue`<br>`product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase`<br>`worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#nowIso` | none | not null |
| `encrypted` | `boolean | null` | Boolean flag | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/lib/settings.ts#dbValue`<br>`product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase` | none | default: false |
| `description` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/lib/settings.ts#dbValue`<br>`product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase`<br>`worker/runtime camperplaner-worker/src/services/geofabrik-update.ts#nowIso` | none | — |
| `validation_rules` | `jsonb | null` | JSON payload | all values NULL | `product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/lib/settings.ts#dbValue`<br>`product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase` | none | all live values NULL |
| `is_archived` | `boolean | null` | Boolean flag | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/lib/settings.ts#existing` | none | default: false |
| `created_by` | `uuid | null` | Data field | all values NULL | `product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/lib/settings.ts#dbValue`<br>`product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase` | none | all live values NULL |
| `updated_by` | `uuid | null` | Data field | all values NULL | `product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/lib/settings.ts#dbValue`<br>`product/runtime camperplaner-product/apps/web/src/lib/settings.ts#existing`<br>`product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase` | none | all live values NULL |
| `created_at` | `timestamp with time zone | null` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase` | none | none | default: now() |
| `updated_at` | `timestamp with time zone | null` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase` | none | none | default: now() |
| `version` | `integer | null` | Metric/value | observed in schema | `product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase` | `product/runtime camperplaner-product/apps/web/src/lib/settings.ts#dbValue`<br>`product/runtime camperplaner-product/apps/web/src/lib/settings.ts#existing`<br>`product/runtime camperplaner-product/apps/web/src/lib/settings.ts#supabase` | none | default: 1 |

## `settings_audit_log`

- Typ: table
- Zweck: Audit log for settings changes.
- Live rows: 18
- Primary key: `id`
- Outgoing foreign keys: none
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: `settings_audit_trigger`
- Triggers on this object: none
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/settings/audit/route.ts#offset
- Runtime writers:
  - none

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `uuid` | Primary key | observed in schema | none | none | none | default: gen_random_uuid(); not null |
| `setting_key` | `text` | Data field | observed in schema | none | none | none | not null |
| `operation` | `text` | Data field | observed in schema | none | none | none | not null |
| `old_value` | `jsonb | null` | JSON payload | observed in schema | none | none | none | — |
| `new_value` | `jsonb | null` | JSON payload | observed in schema | none | none | none | — |
| `performed_by` | `uuid | null` | Data field | all values NULL | none | none | none | all live values NULL |
| `performed_at` | `timestamp with time zone | null` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/settings/audit/route.ts#offset` | none | none | default: now() |
| `client_ip` | `text | null` | Data field | observed in schema | none | none | none | — |

## `app_errors`

- Typ: table
- Zweck: Application error log from frontend/backend error reporting.
- Live rows: 5
- Primary key: `id`
- Outgoing foreign keys: none
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: none
- Triggers on this object: none
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/scripts/debug-errors.mjs#testTable
  - product/runtime camperplaner-product/apps/web/scripts/get-errors.mjs#getErrors
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/statistics/route.ts#countryData
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/statistics/route.ts#type
  - product/runtime camperplaner-product/apps/web/src/lib/admin-statistics-cache.ts#stats
  - product/runtime camperplaner-product/apps/web/src/lib/admin-statistics-cache.ts#type
  - product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#getUnresolvedErrors
  - product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#markErrorAsFixed
  - product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#markErrorAsReviewed
- Runtime writers:
  - product/runtime camperplaner-product/apps/web/scripts/debug-errors.mjs#testTable
  - product/runtime camperplaner-product/apps/web/src/lib/client-error-logger.ts#url
  - product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#logError
  - product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#markErrorAsFixed
  - product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#markErrorAsReviewed

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `uuid` | Primary key | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-errors.mjs#testTable`<br>`product/runtime camperplaner-product/apps/web/scripts/get-errors.mjs#getErrors`<br>`product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#getUnresolvedErrors`<br>`product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#markErrorAsFixed`<br>`product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#markErrorAsReviewed` | none | none | default: gen_random_uuid(); not null |
| `error_type` | `text` | Classifier | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-errors.mjs#testTable`<br>`product/runtime camperplaner-product/apps/web/scripts/get-errors.mjs#getErrors`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/statistics/route.ts#countryData`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/statistics/route.ts#type`<br>`product/runtime camperplaner-product/apps/web/src/lib/admin-statistics-cache.ts#stats`<br>`product/runtime camperplaner-product/apps/web/src/lib/admin-statistics-cache.ts#type`<br>`product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#getUnresolvedErrors` | `product/runtime camperplaner-product/apps/web/scripts/debug-errors.mjs#testTable`<br>`product/runtime camperplaner-product/apps/web/src/lib/client-error-logger.ts#url`<br>`product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#logError` | none | not null |
| `message` | `text` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-errors.mjs#testTable`<br>`product/runtime camperplaner-product/apps/web/scripts/get-errors.mjs#getErrors`<br>`product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#getUnresolvedErrors` | `product/runtime camperplaner-product/apps/web/scripts/debug-errors.mjs#testTable`<br>`product/runtime camperplaner-product/apps/web/src/lib/client-error-logger.ts#url`<br>`product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#logError` | none | not null |
| `stack_trace` | `text | null` | Data field | all values NULL | `product/runtime camperplaner-product/apps/web/scripts/debug-errors.mjs#testTable`<br>`product/runtime camperplaner-product/apps/web/scripts/get-errors.mjs#getErrors`<br>`product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#getUnresolvedErrors` | `product/runtime camperplaner-product/apps/web/scripts/debug-errors.mjs#testTable`<br>`product/runtime camperplaner-product/apps/web/src/lib/client-error-logger.ts#url`<br>`product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#logError` | none | all live values NULL |
| `location` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-errors.mjs#testTable`<br>`product/runtime camperplaner-product/apps/web/scripts/get-errors.mjs#getErrors`<br>`product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#getUnresolvedErrors` | `product/runtime camperplaner-product/apps/web/scripts/debug-errors.mjs#testTable`<br>`product/runtime camperplaner-product/apps/web/src/lib/client-error-logger.ts#url`<br>`product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#logError` | none | — |
| `user_id` | `uuid | null` | Identifier | all values NULL | `product/runtime camperplaner-product/apps/web/scripts/debug-errors.mjs#testTable`<br>`product/runtime camperplaner-product/apps/web/scripts/get-errors.mjs#getErrors`<br>`product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#getUnresolvedErrors` | `product/runtime camperplaner-product/apps/web/scripts/debug-errors.mjs#testTable`<br>`product/runtime camperplaner-product/apps/web/src/lib/client-error-logger.ts#url`<br>`product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#logError` | none | all live values NULL |
| `user_agent` | `text | null` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-errors.mjs#testTable`<br>`product/runtime camperplaner-product/apps/web/scripts/get-errors.mjs#getErrors`<br>`product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#getUnresolvedErrors` | `product/runtime camperplaner-product/apps/web/scripts/debug-errors.mjs#testTable`<br>`product/runtime camperplaner-product/apps/web/src/lib/client-error-logger.ts#url`<br>`product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#logError` | none | — |
| `metadata` | `jsonb | null` | JSON payload | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-errors.mjs#testTable`<br>`product/runtime camperplaner-product/apps/web/scripts/get-errors.mjs#getErrors`<br>`product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#getUnresolvedErrors` | `product/runtime camperplaner-product/apps/web/scripts/debug-errors.mjs#testTable`<br>`product/runtime camperplaner-product/apps/web/src/lib/client-error-logger.ts#url`<br>`product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#logError` | none | default: '{}'::jsonb |
| `status` | `text` | Status field | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-errors.mjs#testTable`<br>`product/runtime camperplaner-product/apps/web/scripts/get-errors.mjs#getErrors`<br>`product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#getUnresolvedErrors` | `product/runtime camperplaner-product/apps/web/scripts/debug-errors.mjs#testTable`<br>`product/runtime camperplaner-product/apps/web/src/lib/client-error-logger.ts#url`<br>`product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#logError`<br>`product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#markErrorAsFixed`<br>`product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#markErrorAsReviewed` | none | default: 'new'::text; not null |
| `created_at` | `timestamp with time zone | null` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/scripts/debug-errors.mjs#testTable`<br>`product/runtime camperplaner-product/apps/web/scripts/get-errors.mjs#getErrors`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/statistics/route.ts#countryData`<br>`product/runtime camperplaner-product/apps/web/src/app/api/admin/statistics/route.ts#type`<br>`product/runtime camperplaner-product/apps/web/src/lib/admin-statistics-cache.ts#stats`<br>`product/runtime camperplaner-product/apps/web/src/lib/admin-statistics-cache.ts#type`<br>`product/runtime camperplaner-product/apps/web/src/lib/error-logger.ts#getUnresolvedErrors` | none | none | default: CURRENT_TIMESTAMP |

## `cutover_audit_log`

- Typ: table
- Zweck: Audit trail for cutover/canonical migration tooling.
- Live rows: 0
- Primary key: `id`
- Outgoing foreign keys: none
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: none
- Triggers on this object: none
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/audit/route.ts#limit
- Runtime writers:
  - product/runtime camperplaner-product/apps/web/scripts/cutover-check.mjs#hasFailure
  - product/runtime camperplaner-product/apps/web/scripts/cutover-mode.mjs#content
  - product/runtime camperplaner-product/apps/web/scripts/cutover-smoke.mjs#payload

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `bigint` | Primary key | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/audit/route.ts#limit` | none | none | default: nextval('cutover_audit_log_id_seq'::regclass); not null |
| `event_type` | `text` | Classifier | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/audit/route.ts#limit` | `product/runtime camperplaner-product/apps/web/scripts/cutover-check.mjs#hasFailure`<br>`product/runtime camperplaner-product/apps/web/scripts/cutover-mode.mjs#content`<br>`product/runtime camperplaner-product/apps/web/scripts/cutover-smoke.mjs#payload` | none | not null |
| `level` | `text` | Data field | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/audit/route.ts#limit` | `product/runtime camperplaner-product/apps/web/scripts/cutover-check.mjs#hasFailure` | none | default: 'info'::text; not null |
| `payload` | `jsonb` | JSON payload | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/audit/route.ts#limit` | `product/runtime camperplaner-product/apps/web/scripts/cutover-check.mjs#hasFailure`<br>`product/runtime camperplaner-product/apps/web/scripts/cutover-mode.mjs#content`<br>`product/runtime camperplaner-product/apps/web/scripts/cutover-smoke.mjs#payload` | none | default: '{}'::jsonb; not null |
| `created_at` | `timestamp with time zone` | Timestamp | observed in schema | `product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/audit/route.ts#limit` | none | none | default: now(); not null |

## `cutover_metric_snapshots`

- Typ: table
- Zweck: Persisted metrics snapshots for cutover health checks.
- Live rows: 0
- Primary key: `id`
- Outgoing foreign keys: none
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: none
- Triggers on this object: none
- Runtime readers:
  - none
- Runtime writers:
  - product/runtime camperplaner-product/apps/web/scripts/cutover-check.mjs#hasFailure

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `id` | `bigint` | Primary key | observed in schema | none | none | none | default: nextval('cutover_metric_snapshots_id_seq'::regclass); not null |
| `import_coverage_ratio` | `numeric` | Data field | observed in schema | none | `product/runtime camperplaner-product/apps/web/scripts/cutover-check.mjs#hasFailure` | none | not null |
| `queue_backlog` | `integer` | Data field | observed in schema | none | `product/runtime camperplaner-product/apps/web/scripts/cutover-check.mjs#hasFailure` | none | not null |
| `job_failures_24h` | `integer` | Data field | observed in schema | none | `product/runtime camperplaner-product/apps/web/scripts/cutover-check.mjs#hasFailure` | none | not null |
| `freshness_stale_count` | `integer` | Metric/value | observed in schema | none | `product/runtime camperplaner-product/apps/web/scripts/cutover-check.mjs#hasFailure` | none | not null |
| `enrichment_spend_usd_24h` | `numeric` | Data field | observed in schema | none | `product/runtime camperplaner-product/apps/web/scripts/cutover-check.mjs#hasFailure` | none | not null |
| `google_calls_24h` | `integer` | Data field | observed in schema | none | `product/runtime camperplaner-product/apps/web/scripts/cutover-check.mjs#hasFailure` | none | not null |
| `canonical_legacy_divergence` | `integer` | Data field | observed in schema | none | `product/runtime camperplaner-product/apps/web/scripts/cutover-check.mjs#hasFailure` | none | not null |
| `unresolved_mappings` | `integer` | Data field | observed in schema | none | `product/runtime camperplaner-product/apps/web/scripts/cutover-check.mjs#hasFailure` | none | not null |
| `created_at` | `timestamp with time zone` | Timestamp | observed in schema | none | none | none | default: now(); not null |

## `cutover_runtime_flags`

- Typ: table
- Zweck: Runtime flags used by cutover scripts and switching logic.
- Live rows: 0
- Primary key: `key`
- Outgoing foreign keys: none
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: none
- DB functions writing this object: none
- Triggers on this object: none
- Runtime readers:
  - none
- Runtime writers:
  - product/runtime camperplaner-product/apps/web/scripts/cutover-mode.mjs#content

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `key` | `text` | Primary key | observed in schema | none | `product/runtime camperplaner-product/apps/web/scripts/cutover-mode.mjs#content` | none | not null |
| `value` | `text` | Data field | observed in schema | none | `product/runtime camperplaner-product/apps/web/scripts/cutover-mode.mjs#content` | none | not null |
| `updated_at` | `timestamp with time zone` | Timestamp | observed in schema | none | `product/runtime camperplaner-product/apps/web/scripts/cutover-mode.mjs#content` | none | default: now(); not null |

## System-managed Tables

## `spatial_ref_sys`

- Typ: table
- Zweck: PostGIS system table for spatial reference systems.
- Live rows: 8500
- Primary key: `srid`
- Outgoing foreign keys: none
- Incoming foreign keys: none
- DB views reading this object: none
- DB functions reading this object: `addgeometrycolumn`, `get_proj4_from_srid`, `st_transform`, `updategeometrysrid`
- DB functions writing this object: none
- Triggers on this object: none
- Runtime readers:
  - none
- Runtime writers:
  - none

### Columns

| Column | Type | Role | Data signal | Direct readers | Direct writers | DB views | Notes |
|---|---|---|---|---|---|---|---|
| `srid` | `integer` | Primary key | observed in schema | none | none | none | not null |
| `auth_name` | `character varying | null` | Data field | observed in schema | none | none | none | — |
| `auth_srid` | `integer | null` | Data field | observed in schema | none | none | none | — |
| `srtext` | `character varying | null` | Data field | observed in schema | none | none | none | — |
| `proj4text` | `character varying | null` | Data field | observed in schema | none | none | none | — |

## Views

### `campsite_api_read_model`
- Zweck: View that exposes the canonical place model in an API-friendly campsite shape.
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase
- Runtime writers:
  - none

### `campsite_full`
- Zweck: View that combines canonical place data with enrichment/cache fields for detail reads.
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/scripts/cutover-check.mjs#loadMetrics
  - product/runtime camperplaner-product/apps/web/src/app/api/admin/cutover/metrics/route.ts#supabase
  - product/runtime camperplaner-product/apps/web/src/app/places/[place_id]/page.tsx#supabase
- Runtime writers:
  - none

### `campsite_price_summary`
- Zweck: View with aggregated campsite price statistics.
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/src/app/api/campsite-prices/route.ts#supabase
- Runtime writers:
  - none

### `campsite_review_summary`
- Zweck: View with aggregated campsite review metrics.
- Runtime readers:
  - product/runtime camperplaner-product/apps/web/src/app/api/campsite-reviews/route.ts#supabase
- Runtime writers:
  - none

### `geography_columns`
- Zweck: PostGIS system view for geography column metadata.
- Runtime readers:
  - none
- Runtime writers:
  - none

### `geometry_columns`
- Zweck: PostGIS system view for geometry column metadata.
- Runtime readers:
  - none
- Runtime writers:
  - none
