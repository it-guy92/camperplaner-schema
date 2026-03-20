# Database Audit Summary (Schema Repo - Canonical)

> **Location:** This is the canonical source. Product repo references this file.

Short, actionable summary of the full audit in `docs/database-access-audit.md`.

## What Was Audited

- Live Supabase `public` schema
- Product runtime code (`camperplaner-product`)
- Worker runtime code (`camperplaner-worker`)
- Table-level and column-level access (read/write), plus DB-side access via views/functions/triggers

## High-Priority Findings

- Decommissioned in migration `20260314000011_drop_decommissioned_legacy_tables.sql`:
  - `place_features`
  - `google_place_matches`
  - `external_place_cache`
  - App feature logic remains served from `places` feature columns (`has_toilet`, `has_shower`, `has_electricity`, `has_water`, `has_wifi`, `pet_friendly`, `caravan_allowed`, `motorhome_allowed`, `tent_allowed`)

- `google_places_cache` is now the canonical runtime cache path
  - Contains live/fresh entries (`13` rows, `max(fetched_at)=2026-03-09`, no expired rows)
  - Product runtime now reads/writes this table directly in `google-places-server.ts`
  - TTL path remains active via `fetched_at`/`expires_at` and 30-day expiry logic
  - Classification: `KEEP_ACTIVE`

- Legacy runtime references removed from product/worker code:
  - `campsites` runtime calls migrated to current tables (`campsites_cache` / `places`)
  - `place_legacy_id_map` runtime alias resolution removed
  - `osm_refresh_queue` migrated to `osm_refresh_jobs`
  - `country_sequence_state` migrated to `app_settings` JSON state keys (`geofabrik_sequence_<COUNTRY>`)

- `osm_source` is decommissioned in migration `20260320060000_drop_unused_job_import_and_cutover_tables.sql`
  - Selected provenance fields move to `place_osm_properties`
  - `place_osm_properties` becomes the sole OSM source-of-truth table
  - Coordinated rollout required: stop workers during migration, restart only the refactored worker version afterward

- System catalog usage detected in scripts (not business tables):
  - `pg_policies`
  - `pg_tables`

## Important Non-Leichen (Do Not Drop)

- `osm_refresh_jobs`
- `country_import_status`

These remain active in worker runtime paths and/or import flows.

## Where to Look Next

- Full details by table and column: `docs/database-access-audit.md`
- Current schema overview: `docs/database-schema.md`

## Suggested Follow-up

1. Deploy migration and regenerate DB types
2. Update product/worker consumers to remove dropped-table references
3. Re-run import and enrichment smoke checks after deployment
