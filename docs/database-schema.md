# CamperPlaner Database Schema

> **Location:** This is the canonical source of truth for the CamperPlaner database schema.
> **Generated:** 2026-03-21
> **Migration Head:** 20260321000000_create_place_resolved_views.sql

---

## Schema Overview

| Metric | Count |
|--------|-------|
| **Total Tables** | 34 |
| **User Tables** | 27 |
| **System Tables** | 7 (PostGIS) |
| **Views** | 8 |
| **Enums** | 20 |
| **RPC Functions** | 1 |

---

## Tables by Domain

### 1. User & Trip Management

| Table | Description | Primary Key |
|-------|-------------|-------------|
| `profiles` | User profiles extending auth.users | `id` (uuid) |
| `trips` | Trip/route definitions | `id` (uuid) |
| `trip_stops` | Individual stops within trips | `id` (uuid) |
| `trip_reminders` | Trip reminder notifications | `id` (uuid) |
| `vehicle_profiles` | User vehicle configurations | `id` (uuid) |
| `favorites` | User saved favorites | `id` (uuid) |

### 2. Places & Campsites (Core Data)

| Table | Description | Primary Key |
|-------|-------------|-------------|
| `places` | Main places table with canonical data | `id` (bigint) |
| `campsites_cache` | Cached campsite data with Google Places enrichment | `id` (uuid) |
| `campsite_prices` | User-submitted price data | `id` (uuid) |
| `campsite_reviews` | User reviews and ratings | `id` (uuid) |
| `place_enrichment` | Place enrichment data and LLM processing | `id` (bigint) |
| `place_duplicate_candidates` | Potential duplicate detection | `id` (bigint) |
| `google_places_cache` | Cached Google Places API responses | `id` (uuid) |

### 3. Import & Queue System

| Table | Description | Primary Key |
|-------|-------------|-------------|
| `countries` | Country definitions for imports | `iso_code` (text) |
| `country_import_status` | Import status tracking per country | `id` (uuid) |
| `osm_import_queue` | OSM import work queue | `id` (bigint) |
| `osm_import_jobs` | OSM import job tracking | `id` (uuid) |
| `osm_import_runs` | OSM import run history | `id` (bigint) |
| `osm_refresh_jobs` | OSM data refresh jobs | `id` (bigint) |
| `enrichment_jobs` | Data enrichment job queue | `id` (bigint) |

### 4. Audit & Logging

| Table | Description | Primary Key |
|-------|-------------|-------------|
| `app_errors` | Application error tracking | `id` (uuid) |
| `app_settings` | Application configuration | `id` (uuid) |
| `settings_audit_log` | Settings change audit trail | `id` (uuid) |
| `cutover_audit_log` | Database cutover audit trail | `id` (bigint) |

### 5. Phase 1: Enrichment Schema (DEPRECATED - Tables Dropped)

> ⚠️ **DROPPED** in migration `20260318213000_backfill_property_tables_and_drop_deprecated_fact_tables.sql`

The following tables have been **dropped** as part of the Phase 2 schema restructuring:

| Table | Status | Former Description |
|-------|--------|-------------------|
| `place_google_amenities` | **DROPPED** | Google amenities data |
| `place_google_types` | **DROPPED** | Google place types |
| `place_llm_facts` | **DROPPED** | Individual LLM-extracted facts |
| `place_llm_sources` | **DROPPED** | Sources cited by LLM |
| `place_llm_evidence_markers` | **DROPPED** | Trust markers for LLM output |
| `place_source_evidence_runs` | **DROPPED** | Evidence collection audit |
| `place_evidence_sources` | **DROPPED** | Individual fetched sources |
| `place_evidence_markers` | **DROPPED** | Evidence markers from sources |

**Migration that dropped these tables:** `20260318213000_backfill_property_tables_and_drop_deprecated_fact_tables.sql`

### 6. Phase 3: Dropped Import, Job, Cutover, and Source Tables

> ⚠️ **DROPPED** in migration `20260320060000_drop_unused_job_import_and_cutover_tables.sql`

The following application-owned tables have been removed from the canonical schema:

| Table | Status | Former Description |
|-------|--------|-------------------|
| `description_generation_jobs` | **DROPPED** | LLM description generation queue |
| `website_scraping_jobs` | **DROPPED** | Website scraping job queue |
| `osm_source` | **DROPPED** | Legacy OSM source-raw table |
| `osm_type_transitions` | **DROPPED** | OSM type transition tracking |
| `import_snapshot` | **DROPPED** | Import snapshot/checkpoint data |
| `cutover_runtime_flags` | **DROPPED** | Cutover runtime feature flags |
| `cutover_metric_snapshots` | **DROPPED** | Cutover metric snapshots |

**Migration that dropped these tables:** `20260320060000_drop_unused_job_import_and_cutover_tables.sql`

**Coordinated deployment note:** Stop workers before applying this migration. Restart workers only after the refactored worker build that no longer references `osm_source` or `place_osm_properties.osm_source_id` is deployed.

### 7. Aligned Property Tables (NEW)

> ✨ **NEW** in migration `20260318200000_add_property_tables.sql`

Aligned property tables provide a consistent schema for storing place properties from different sources (OSM, Google, LLM, User). Each table shares the same column structure for common fields and has source-specific columns.

#### Shared Column Groups

All four property tables share these column groups:

| Group | Columns |
|-------|---------|
| **Infrastructure** | `id`, `place_id`, `is_current`, `created_at`, `updated_at`, `source_updated_at` |
| **Identity/Content** | `name`, `description`, `place_type`, `source_place_type`, `source_categories` |
| **Address/Location** | `country_code`, `region`, `city`, `postcode`, `address`, `source_lat`, `source_lon` |
| **Contact/Operations** | `website`, `phone`, `email`, `opening_hours`, `fee_info` |
| **Generic Flags** | `wheelchair_accessible`, `family_friendly`, `pets_allowed`, `indoor`, `outdoor`, `entry_fee_required`, `reservation_required`, `overnight_stay_allowed` |
| **General Facilities** | `has_parking`, `has_restrooms`, `has_drinking_water`, `has_wifi`, `has_shop`, `has_restaurant`, `has_cafe` |
| **Camping Permissions** | `caravan_allowed`, `motorhome_allowed`, `tent_allowed` |
| **Camping Facilities** | `has_electricity`, `has_fresh_water`, `has_shower`, `has_laundry`, `has_dishwashing_area` |
| **Disposal/Utilities** | `has_grey_water_disposal`, `has_black_water_disposal`, `has_chemical_toilet_disposal`, `has_dump_station`, `has_waste_disposal`, `has_recycling` |
| **Leisure** | `has_bbq_area`, `has_fire_pit`, `has_playground`, `has_pool`, `has_beach` |
| **Nudism** | `nudism_allowed`, `nudism_only` |
| **Attraction/Museum** | `has_guided_tours`, `has_audio_guide`, `has_visitor_center`, `has_lockers`, `photography_allowed` |

#### Property Tables

| Table | Description | Primary Key | Source-Specific Columns |
|-------|-------------|-------------|------------------------|
| `place_osm_properties` | OSM property data | `id` (bigint) | `osm_id`, `osm_type`, `osm_version`, `osm_timestamp`, `imported_at`, `first_seen_at`, `last_seen_at`, `last_import_run_id`, `source_metadata` |
| `place_google_properties` | Google Places property data | `id` (bigint) | `google_source_id` (legacy lineage), `google_place_id`, `rating`, `review_count`, `business_status`, `expires_at` |
| `place_llm_properties` | LLM-enriched property data | `id` (bigint) | `llm_enrichment_id`, `provider`, `model`, `summary_de`, `trust_score`, `source_urls` |
| `place_user_properties` | User-submitted property corrections | `id` (bigint) | `user_id` (uuid, NOT NULL) |

#### `place_osm_properties`
OSM property data with aligned schema.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigserial | PK, NOT NULL | Unique identifier |
| `place_id` | bigint | FK → places.id, NOT NULL | Parent place |
| `is_current` | boolean | NOT NULL, DEFAULT true | Current/valid row flag |
| `created_at` | timestamptz | NOT NULL, DEFAULT now() | Creation time |
| `updated_at` | timestamptz | NOT NULL, DEFAULT now() | Last update |
| `source_updated_at` | timestamptz | NULL | Source data last update |
| `name` | text | NULL | Place name |
| `description` | text | NULL | Place description |
| `place_type` | text | NULL | Normalized place type |
| `source_place_type` | text | NULL | Original place type |
| `source_categories` | text[] | NULL | Source categories |
| `country_code` | text | NULL | ISO country code |
| `region` | text | NULL | Region/state |
| `city` | text | NULL | City name |
| `postcode` | text | NULL | Postal code |
| `address` | text | NULL | Full address |
| `source_lat` | numeric | NULL | Source latitude |
| `source_lon` | numeric | NULL | Source longitude |
| `website` | text | NULL | Website URL |
| `phone` | text | NULL | Phone number |
| `email` | text | NULL | Email address |
| `opening_hours` | text | NULL | Opening hours |
| `fee_info` | text | NULL | Fee information |
| `wheelchair_accessible` | boolean | NULL | Wheelchair accessible |
| `family_friendly` | boolean | NULL | Family friendly |
| `pets_allowed` | boolean | NULL | Pets allowed |
| `indoor` | boolean | NULL | Indoor location |
| `outdoor` | boolean | NULL | Outdoor location |
| `entry_fee_required` | boolean | NULL | Entry fee required |
| `reservation_required` | boolean | NULL | Reservation required |
| `overnight_stay_allowed` | boolean | NULL | Overnight stay allowed |
| `has_parking` | boolean | NULL | Has parking |
| `has_restrooms` | boolean | NULL | Has restrooms |
| `has_drinking_water` | boolean | NULL | Has drinking water |
| `has_wifi` | boolean | NULL | Has WiFi |
| `has_shop` | boolean | NULL | Has shop |
| `has_restaurant` | boolean | NULL | Has restaurant |
| `has_cafe` | boolean | NULL | Has cafe |
| `caravan_allowed` | boolean | NULL | Caravan allowed |
| `motorhome_allowed` | boolean | NULL | Motorhome allowed |
| `tent_allowed` | boolean | NULL | Tent allowed |
| `has_electricity` | boolean | NULL | Has electricity |
| `has_fresh_water` | boolean | NULL | Has fresh water |
| `has_shower` | boolean | NULL | Has shower |
| `has_laundry` | boolean | NULL | Has laundry |
| `has_dishwashing_area` | boolean | NULL | Has dishwashing area |
| `has_grey_water_disposal` | boolean | NULL | Has grey water disposal |
| `has_black_water_disposal` | boolean | NULL | Has black water disposal |
| `has_chemical_toilet_disposal` | boolean | NULL | Has chemical toilet disposal |
| `has_dump_station` | boolean | NULL | Has dump station |
| `has_waste_disposal` | boolean | NULL | Has waste disposal |
| `has_recycling` | boolean | NULL | Has recycling |
| `has_bbq_area` | boolean | NULL | Has BBQ area |
| `has_fire_pit` | boolean | NULL | Has fire pit |
| `has_playground` | boolean | NULL | Has playground |
| `has_pool` | boolean | NULL | Has pool |
| `has_beach` | boolean | NULL | Has beach |
| `nudism_allowed` | boolean | NULL | Nudism allowed |
| `nudism_only` | boolean | NULL | Nudism only |
| `has_guided_tours` | boolean | NULL | Has guided tours |
| `has_audio_guide` | boolean | NULL | Has audio guide |
| `has_visitor_center` | boolean | NULL | Has visitor center |
| `has_lockers` | boolean | NULL | Has lockers |
| `photography_allowed` | boolean | NULL | Photography allowed |
| `osm_id` | bigint | NULL | OSM object ID |
| `osm_type` | text | NULL | OSM object type (node/way/relation) |
| `osm_version` | integer | NULL | OSM version number |
| `osm_timestamp` | timestamptz | NULL | OSM last edit timestamp |
| `imported_at` | timestamptz | NULL | Original import timestamp migrated from osm_source |
| `first_seen_at` | timestamptz | NULL | First-seen timestamp migrated from osm_source |
| `last_seen_at` | timestamptz | NULL | Last-seen timestamp migrated from osm_source |
| `last_import_run_id` | bigint | NULL | Last osm import run reference migrated from osm_source |
| `source_metadata` | jsonb | NULL, DEFAULT '{}'::jsonb | Source metadata migrated from osm_source |

**Indexes:**
- `uidx_osm_properties_place_unique` (unique) ON `(place_id)`
- `idx_osm_properties_place_id` ON `(place_id)`
- `idx_osm_properties_is_current` ON `(is_current)` WHERE `is_current = true`
- `idx_osm_properties_osm_id` ON `(osm_id)` WHERE `osm_id IS NOT NULL`
- `idx_osm_properties_osm_type_id` ON `(osm_type, osm_id)` WHERE `osm_type IS NOT NULL AND osm_id IS NOT NULL`
- `idx_osm_properties_place_current` ON `(place_id, is_current)` WHERE `is_current = true`

**Cutover note:** Stop worker processes during this migration and restart only the refactored worker version that reads and writes `place_osm_properties` exclusively.

#### `place_google_properties`
Google Places property data with aligned schema.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigserial | PK, NOT NULL | Unique identifier |
| `place_id` | bigint | FK → places.id, NOT NULL | Parent place |
| `is_current` | boolean | NOT NULL, DEFAULT true | Current/valid row flag |
| `created_at` | timestamptz | NOT NULL, DEFAULT now() | Creation time |
| `updated_at` | timestamptz | NOT NULL, DEFAULT now() | Last update |
| `source_updated_at` | timestamptz | NULL | Source data last update |
| `name` | text | NULL | Place name |
| `description` | text | NULL | Place description |
| `place_type` | text | NULL | Normalized place type |
| `source_place_type` | text | NULL | Original place type |
| `source_categories` | text[] | NULL | Source categories |
| `country_code` | text | NULL | ISO country code |
| `region` | text | NULL | Region/state |
| `city` | text | NULL | City name |
| `postcode` | text | NULL | Postal code |
| `address` | text | NULL | Full address |
| `source_lat` | numeric | NULL | Source latitude |
| `source_lon` | numeric | NULL | Source longitude |
| `website` | text | NULL | Website URL |
| `phone` | text | NULL | Phone number |
| `email` | text | NULL | Email address |
| `opening_hours` | text | NULL | Opening hours |
| `fee_info` | text | NULL | Fee information |
| `wheelchair_accessible` | boolean | NULL | Wheelchair accessible |
| `family_friendly` | boolean | NULL | Family friendly |
| `pets_allowed` | boolean | NULL | Pets allowed |
| `indoor` | boolean | NULL | Indoor location |
| `outdoor` | boolean | NULL | Outdoor location |
| `entry_fee_required` | boolean | NULL | Entry fee required |
| `reservation_required` | boolean | NULL | Reservation required |
| `overnight_stay_allowed` | boolean | NULL | Overnight stay allowed |
| `has_parking` | boolean | NULL | Has parking |
| `has_restrooms` | boolean | NULL | Has restrooms |
| `has_drinking_water` | boolean | NULL | Has drinking water |
| `has_wifi` | boolean | NULL | Has WiFi |
| `has_shop` | boolean | NULL | Has shop |
| `has_restaurant` | boolean | NULL | Has restaurant |
| `has_cafe` | boolean | NULL | Has cafe |
| `caravan_allowed` | boolean | NULL | Caravan allowed |
| `motorhome_allowed` | boolean | NULL | Motorhome allowed |
| `tent_allowed` | boolean | NULL | Tent allowed |
| `has_electricity` | boolean | NULL | Has electricity |
| `has_fresh_water` | boolean | NULL | Has fresh water |
| `has_shower` | boolean | NULL | Has shower |
| `has_laundry` | boolean | NULL | Has laundry |
| `has_dishwashing_area` | boolean | NULL | Has dishwashing area |
| `has_grey_water_disposal` | boolean | NULL | Has grey water disposal |
| `has_black_water_disposal` | boolean | NULL | Has black water disposal |
| `has_chemical_toilet_disposal` | boolean | NULL | Has chemical toilet disposal |
| `has_dump_station` | boolean | NULL | Has dump station |
| `has_waste_disposal` | boolean | NULL | Has waste disposal |
| `has_recycling` | boolean | NULL | Has recycling |
| `has_bbq_area` | boolean | NULL | Has BBQ area |
| `has_fire_pit` | boolean | NULL | Has fire pit |
| `has_playground` | boolean | NULL | Has playground |
| `has_pool` | boolean | NULL | Has pool |
| `has_beach` | boolean | NULL | Has beach |
| `nudism_allowed` | boolean | NULL | Nudism allowed |
| `nudism_only` | boolean | NULL | Nudism only |
| `has_guided_tours` | boolean | NULL | Has guided tours |
| `has_audio_guide` | boolean | NULL | Has audio guide |
| `has_visitor_center` | boolean | NULL | Has visitor center |
| `has_lockers` | boolean | NULL | Has lockers |
| `photography_allowed` | boolean | NULL | Photography allowed |
| `google_source_id` | bigint | NULL | Legacy lineage identifier (no active FK) |
| `google_place_id` | text | NULL | Google Places API ID |
| `rating` | numeric | NULL | Google rating (0-5) |
| `review_count` | integer | NULL | Number of Google reviews |
| `business_status` | text | NULL | Business status enum |
| `expires_at` | timestamptz | NULL | Cache expiration time |

**Indexes:**
- `uidx_google_properties_place_unique` (unique) ON `(place_id)`
- `idx_google_properties_place_id` ON `(place_id)`
- `idx_google_properties_is_current` ON `(is_current)` WHERE `is_current = true`
- `idx_google_properties_google_place_id` ON `(google_place_id)` WHERE `google_place_id IS NOT NULL`
- `idx_google_properties_expires` ON `(expires_at)` WHERE `expires_at IS NOT NULL`
- `idx_google_properties_place_current` ON `(place_id, is_current)` WHERE `is_current = true`

#### `place_llm_properties`
LLM-enriched property data with aligned schema.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigserial | PK, NOT NULL | Unique identifier |
| `place_id` | bigint | FK → places.id, NOT NULL | Parent place |
| `is_current` | boolean | NOT NULL, DEFAULT true | Current/valid row flag |
| `created_at` | timestamptz | NOT NULL, DEFAULT now() | Creation time |
| `updated_at` | timestamptz | NOT NULL, DEFAULT now() | Last update |
| `source_updated_at` | timestamptz | NULL | Source data last update |
| `name` | text | NULL | Place name |
| `description` | text | NULL | Place description |
| `place_type` | text | NULL | Normalized place type |
| `source_place_type` | text | NULL | Original place type |
| `source_categories` | text[] | NULL | Source categories |
| `country_code` | text | NULL | ISO country code |
| `region` | text | NULL | Region/state |
| `city` | text | NULL | City name |
| `postcode` | text | NULL | Postal code |
| `address` | text | NULL | Full address |
| `source_lat` | numeric | NULL | Source latitude |
| `source_lon` | numeric | NULL | Source longitude |
| `website` | text | NULL | Website URL |
| `phone` | text | NULL | Phone number |
| `email` | text | NULL | Email address |
| `opening_hours` | text | NULL | Opening hours |
| `fee_info` | text | NULL | Fee information |
| `wheelchair_accessible` | boolean | NULL | Wheelchair accessible |
| `family_friendly` | boolean | NULL | Family friendly |
| `pets_allowed` | boolean | NULL | Pets allowed |
| `indoor` | boolean | NULL | Indoor location |
| `outdoor` | boolean | NULL | Outdoor location |
| `entry_fee_required` | boolean | NULL | Entry fee required |
| `reservation_required` | boolean | NULL | Reservation required |
| `overnight_stay_allowed` | boolean | NULL | Overnight stay allowed |
| `has_parking` | boolean | NULL | Has parking |
| `has_restrooms` | boolean | NULL | Has restrooms |
| `has_drinking_water` | boolean | NULL | Has drinking water |
| `has_wifi` | boolean | NULL | Has WiFi |
| `has_shop` | boolean | NULL | Has shop |
| `has_restaurant` | boolean | NULL | Has restaurant |
| `has_cafe` | boolean | NULL | Has cafe |
| `caravan_allowed` | boolean | NULL | Caravan allowed |
| `motorhome_allowed` | boolean | NULL | Motorhome allowed |
| `tent_allowed` | boolean | NULL | Tent allowed |
| `has_electricity` | boolean | NULL | Has electricity |
| `has_fresh_water` | boolean | NULL | Has fresh water |
| `has_shower` | boolean | NULL | Has shower |
| `has_laundry` | boolean | NULL | Has laundry |
| `has_dishwashing_area` | boolean | NULL | Has dishwashing area |
| `has_grey_water_disposal` | boolean | NULL | Has grey water disposal |
| `has_black_water_disposal` | boolean | NULL | Has black water disposal |
| `has_chemical_toilet_disposal` | boolean | NULL | Has chemical toilet disposal |
| `has_dump_station` | boolean | NULL | Has dump station |
| `has_waste_disposal` | boolean | NULL | Has waste disposal |
| `has_recycling` | boolean | NULL | Has recycling |
| `has_bbq_area` | boolean | NULL | Has BBQ area |
| `has_fire_pit` | boolean | NULL | Has fire pit |
| `has_playground` | boolean | NULL | Has playground |
| `has_pool` | boolean | NULL | Has pool |
| `has_beach` | boolean | NULL | Has beach |
| `nudism_allowed` | boolean | NULL | Nudism allowed |
| `nudism_only` | boolean | NULL | Nudism only |
| `has_guided_tours` | boolean | NULL | Has guided tours |
| `has_audio_guide` | boolean | NULL | Has audio guide |
| `has_visitor_center` | boolean | NULL | Has visitor center |
| `has_lockers` | boolean | NULL | Has lockers |
| `photography_allowed` | boolean | NULL | Photography allowed |
| `llm_enrichment_id` | bigint | NULL | Legacy lineage identifier (table dropped in 20260319083000; no active FK) |
| `provider` | text | NULL | LLM provider (openai/anthropic) |
| `model` | text | NULL | Model identifier |
| `summary_de` | text | NULL | German-language summary |
| `trust_score` | numeric | NULL | Trust score (0-1) |
| `source_urls` | jsonb | NULL | Array of source URLs |

**Indexes:**
- `uidx_llm_properties_place_unique` (unique) ON `(place_id)`
- `idx_llm_properties_place_id` ON `(place_id)`
- `idx_llm_properties_is_current` ON `(is_current)` WHERE `is_current = true`
- `idx_llm_properties_provider` ON `(provider)` WHERE `provider IS NOT NULL`
- `idx_llm_properties_place_current` ON `(place_id, is_current)` WHERE `is_current = true`

#### `place_user_properties`
User-submitted property corrections with aligned schema.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigserial | PK, NOT NULL | Unique identifier |
| `place_id` | bigint | FK → places.id, NOT NULL | Parent place |
| `is_current` | boolean | NOT NULL, DEFAULT true | Current/valid row flag |
| `created_at` | timestamptz | NOT NULL, DEFAULT now() | Creation time |
| `updated_at` | timestamptz | NOT NULL, DEFAULT now() | Last update |
| `source_updated_at` | timestamptz | NULL | Source data last update |
| `name` | text | NULL | Place name |
| `description` | text | NULL | Place description |
| `place_type` | text | NULL | Normalized place type |
| `source_place_type` | text | NULL | Original place type |
| `source_categories` | text[] | NULL | Source categories |
| `country_code` | text | NULL | ISO country code |
| `region` | text | NULL | Region/state |
| `city` | text | NULL | City name |
| `postcode` | text | NULL | Postal code |
| `address` | text | NULL | Full address |
| `source_lat` | numeric | NULL | Source latitude |
| `source_lon` | numeric | NULL | Source longitude |
| `website` | text | NULL | Website URL |
| `phone` | text | NULL | Phone number |
| `email` | text | NULL | Email address |
| `opening_hours` | text | NULL | Opening hours |
| `fee_info` | text | NULL | Fee information |
| `wheelchair_accessible` | boolean | NULL | Wheelchair accessible |
| `family_friendly` | boolean | NULL | Family friendly |
| `pets_allowed` | boolean | NULL | Pets allowed |
| `indoor` | boolean | NULL | Indoor location |
| `outdoor` | boolean | NULL | Outdoor location |
| `entry_fee_required` | boolean | NULL | Entry fee required |
| `reservation_required` | boolean | NULL | Reservation required |
| `overnight_stay_allowed` | boolean | NULL | Overnight stay allowed |
| `has_parking` | boolean | NULL | Has parking |
| `has_restrooms` | boolean | NULL | Has restrooms |
| `has_drinking_water` | boolean | NULL | Has drinking water |
| `has_wifi` | boolean | NULL | Has WiFi |
| `has_shop` | boolean | NULL | Has shop |
| `has_restaurant` | boolean | NULL | Has restaurant |
| `has_cafe` | boolean | NULL | Has cafe |
| `caravan_allowed` | boolean | NULL | Caravan allowed |
| `motorhome_allowed` | boolean | NULL | Motorhome allowed |
| `tent_allowed` | boolean | NULL | Tent allowed |
| `has_electricity` | boolean | NULL | Has electricity |
| `has_fresh_water` | boolean | NULL | Has fresh water |
| `has_shower` | boolean | NULL | Has shower |
| `has_laundry` | boolean | NULL | Has laundry |
| `has_dishwashing_area` | boolean | NULL | Has dishwashing area |
| `has_grey_water_disposal` | boolean | NULL | Has grey water disposal |
| `has_black_water_disposal` | boolean | NULL | Has black water disposal |
| `has_chemical_toilet_disposal` | boolean | NULL | Has chemical toilet disposal |
| `has_dump_station` | boolean | NULL | Has dump station |
| `has_waste_disposal` | boolean | NULL | Has waste disposal |
| `has_recycling` | boolean | NULL | Has recycling |
| `has_bbq_area` | boolean | NULL | Has BBQ area |
| `has_fire_pit` | boolean | NULL | Has fire pit |
| `has_playground` | boolean | NULL | Has playground |
| `has_pool` | boolean | NULL | Has pool |
| `has_beach` | boolean | NULL | Has beach |
| `nudism_allowed` | boolean | NULL | Nudism allowed |
| `nudism_only` | boolean | NULL | Nudism only |
| `has_guided_tours` | boolean | NULL | Has guided tours |
| `has_audio_guide` | boolean | NULL | Has audio guide |
| `has_visitor_center` | boolean | NULL | Has visitor center |
| `has_lockers` | boolean | NULL | Has lockers |
| `photography_allowed` | boolean | NULL | Photography allowed |
| `user_id` | uuid | NOT NULL | User who submitted correction |

**Indexes:**
- `uidx_user_properties_place_user_current` (partial, unique) ON `(place_id, user_id)` WHERE `is_current = true`
- `idx_user_properties_place_id` ON `(place_id)`
- `idx_user_properties_user_id` ON `(user_id)`
- `idx_user_properties_user_current` ON `(user_id, is_current)` WHERE `is_current = true`
- `idx_user_properties_place_user_current` ON `(place_id, user_id, is_current)` WHERE `is_current = true`

### 7. System/Cache Tables

| Table | Description | Primary Key |
|-------|-------------|-------------|
| `google_refresh_claims` | Google Places refresh claim tracking | `place_id` (uuid) |

---

## Detailed Table Schemas

### User & Trip Tables

#### `profiles`
User profiles extending auth.users.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK, NOT NULL | Reference to auth.users.id |
| `email` | text | NOT NULL | User email address |
| `role` | text | NOT NULL | 'user' or 'admin' |
| `created_at` | timestamptz | DEFAULT NOW() | Record creation time |
| `full_name` | text | NULL | User's full name |
| `home_city` | text | NULL | User's home city |
| `home_city_coords` | jsonb | NULL | Home city coordinates |
| `updated_at` | timestamptz | NOT NULL, DEFAULT NOW() | Last update time |

#### `trips`
User trips/routes.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK, NOT NULL | Unique trip identifier |
| `user_id` | uuid | FK → profiles.id, NOT NULL | Trip owner |
| `start_location` | text | NOT NULL | Starting location name |
| `end_location` | text | NOT NULL | Ending location name |
| `start_date` | date | NOT NULL | Trip start date |
| `end_date` | date | NOT NULL | Trip end date |
| `total_distance` | numeric | NOT NULL | Total trip distance |
| `total_cost` | numeric | NOT NULL | Total trip cost |
| `fuel_cost` | numeric | NOT NULL, DEFAULT 0 | Fuel cost estimate |
| `toll_cost` | numeric | NOT NULL, DEFAULT 0 | Toll cost estimate |
| `is_shared` | boolean | DEFAULT false | Whether trip is shared |
| `share_token` | uuid | NULL | Token for sharing |
| `shared_at` | timestamptz | NULL | When trip was shared |
| `start_location_geo` | geography | NULL | Start location as geography |
| `end_location_geo` | geography | NULL | End location as geography |
| `start_coords` | jsonb | DEFAULT '{}' | Start coordinates |
| `end_coords` | jsonb | DEFAULT '{}' | End coordinates |
| `route_geometry` | jsonb | NULL | Full route geometry |
| `name` | text | NULL | Trip name |
| `created_at` | timestamptz | DEFAULT NOW() | Creation time |

#### `trip_stops`
Stops within trips.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK, NOT NULL | Unique stop identifier |
| `trip_id` | uuid | FK → trips.id, NOT NULL | Parent trip |
| `day_number` | integer | NOT NULL | Day number in trip |
| `location_name` | text | NOT NULL | Location name |
| `coordinates` | jsonb | NOT NULL | Stop coordinates |
| `cost` | numeric | NOT NULL | Stop cost |
| `type` | text | NOT NULL | Stop type enum |
| `name` | text | NULL | Stop name |
| `rating` | numeric | NULL | User rating |
| `website` | text | NULL | Website URL |
| `image` | text | NULL | Image URL |
| `amenities` | text[] | DEFAULT '{}' | Array of amenities |
| `order_index` | integer | DEFAULT 0 | Display order |
| `cost_type` | text | DEFAULT 'per_night' | Cost type enum |
| `notes` | text | NULL | User notes |
| `place_id` | text | NULL | Reference to place |
| `location_geo` | geography | NULL | Geography point |

#### `trip_reminders`
Trip reminder settings.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK, NOT NULL | Unique identifier |
| `trip_id` | uuid | FK → trips.id, NOT NULL | Parent trip |
| `user_id` | uuid | FK → profiles.id, NOT NULL | User reference |
| `reminder_days_before` | integer | NOT NULL | Days before to remind |
| `is_active` | boolean | NOT NULL, DEFAULT true | Active flag |
| `last_sent_at` | timestamptz | NULL | Last reminder sent |
| `created_at` | timestamptz | NOT NULL, DEFAULT NOW() | Creation time |

#### `vehicle_profiles`
Saved vehicle configurations.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK, NOT NULL | Unique identifier |
| `user_id` | uuid | FK → profiles.id, NOT NULL | Owner |
| `name` | text | NOT NULL | Profile name |
| `max_speed` | numeric | NULL | Maximum speed |
| `height` | numeric | NULL | Vehicle height |
| `weight` | numeric | NULL | Vehicle weight |
| `fuel_consumption` | numeric | NULL | Fuel consumption |
| `is_default` | boolean | NULL | Default profile flag |
| `created_at` | timestamptz | NOT NULL | Creation time |

#### `favorites`
User saved favorites.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK, NOT NULL | Unique identifier |
| `user_id` | uuid | FK → profiles.id, NOT NULL | Owner |
| `place_id` | uuid | NOT NULL | Place reference |
| `name` | text | NOT NULL | Display name |
| `coordinates` | jsonb | NOT NULL | Location coordinates |
| `type` | text | NOT NULL | Place type |
| `amenities` | text[] | NULL | Array of amenities |
| `rating` | numeric | NULL | User rating |
| `created_at` | timestamptz | NOT NULL | Creation time |
| `location_geo` | geography | NULL | Geography point |

### Places & Campsites Tables

#### `places`
Minimal place identity and geospatial anchor table.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | PK, NOT NULL | Unique place identifier |
| `geom` | geometry | NOT NULL | PostGIS geometry |
| `lat` | numeric | NULL | Latitude |
| `lon` | numeric | NULL | Longitude |
| `is_active` | boolean | NOT NULL | Active flag |
| `created_at` | timestamptz | NOT NULL | Creation time |
| `updated_at` | timestamptz | NOT NULL | Last update |

#### `campsites_cache`
Cached campsite data.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK, NOT NULL | Unique identifier |
| `place_id` | uuid | NULL | Place reference |
| `name` | text | NOT NULL | Campsite name |
| `lat` | numeric | NOT NULL | Latitude |
| `lng` | numeric | NOT NULL | Longitude |
| `rating` | numeric | NULL | Overall rating |
| `photo_url` | text | NULL | Photo URL |
| `estimated_price` | numeric | NULL | Estimated price |
| `place_types` | text[] | NULL | Array of types |
| `last_updated` | timestamptz | NULL | Last update |
| `created_at` | timestamptz | NULL | Creation time |
| `price_source` | text | NULL | Price source |
| `user_price_count` | integer | NULL | Number of user prices |
| `user_price_avg` | numeric | NULL | Average user price |
| `description` | text | NULL | Description |
| `description_source` | text | NULL | Description source |
| `description_generated_at` | timestamptz | NULL | Generation time |
| `description_version` | integer | NULL | Version number |
| `opening_hours` | text | NULL | Opening hours |
| `contact_phone` | text | NULL | Phone number |
| `contact_email` | text | NULL | Email address |
| `scraped_website_url` | text | NULL | Scraped URL |
| `scraped_at` | timestamptz | NULL | Scraping time |
| `scraped_price_info` | jsonb | NULL | Price info JSON |
| `scraped_data_source` | text | NULL | Data source |
| `google_data_fetched_at` | timestamptz | NULL | Google fetch time |
| `google_data_expires_at` | timestamptz | NULL | Google expiry |
| `google_photos` | jsonb | NULL | Google photos JSON |
| `google_reviews` | jsonb | NULL | Google reviews JSON |

#### `campsite_prices`
User-submitted price data.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK, NOT NULL | Unique identifier |
| `place_id` | uuid | NOT NULL | Place reference |
| `user_id` | uuid | NULL | User reference |
| `price_per_night` | numeric | NOT NULL | Price per night |
| `price_type` | text | NULL | Price type |
| `currency` | text | NULL | Currency code |
| `rating` | numeric | NULL | User rating |
| `review_text` | text | NULL | Review text |
| `created_at` | timestamptz | NULL | Creation time |

#### `campsite_reviews`
User reviews and ratings.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK, NOT NULL | Unique identifier |
| `user_id` | uuid | NOT NULL | User reference |
| `place_id` | text | NOT NULL | Place reference |
| `place_name` | text | NOT NULL | Place name |
| `rating` | integer | NOT NULL | Star rating (1-5) |
| `comment` | text | NULL | Review comment |
| `created_at` | timestamptz | NULL | Creation time |

#### `place_enrichment`
Place enrichment data and LLM processing.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | PK, NOT NULL | Unique identifier |
| `place_id` | bigint | NOT NULL | Place reference |
| `status` | text | NOT NULL | Enrichment status |
| `provider` | text | NULL | LLM provider |
| `model` | text | NULL | Model identifier |
| `prompt_version` | text | NULL | Prompt version |
| `source_urls` | jsonb | NOT NULL | Source URLs |
| `extracted` | jsonb | NOT NULL | Extracted data |
| `summary_de` | text | NULL | German summary |
| `confidence` | numeric | NULL | Confidence score |
| `hallucination_risk` | numeric | NULL | Hallucination risk |
| `token_input` | integer | NULL | Input tokens |
| `token_output` | integer | NULL | Output tokens |
| `cost_usd` | numeric | NULL | Cost in USD |
| `validation_errors` | jsonb | NOT NULL | Validation errors |
| `created_at` | timestamptz | NOT NULL | Creation time |
| `completed_at` | timestamptz | NULL | Completion time |
| `source_evidence` | jsonb | NULL | Evidence JSON |
| `evidence_markers` | jsonb | NULL | Evidence markers |
| `collection_status` | text | NULL | Collection status |
| `failure_classification` | text | NULL | Failure category |
| `provider_attempts` | jsonb | NULL | Attempt history |
| `job_cost_usd` | numeric | NULL | Job cost |
| `enrichment_schema_version` | text | NULL | Schema version |

### LLM Enrichment Tables

#### `place_llm_enrichments`
Deprecated and dropped in `20260319083000_drop_llm_enrichments_and_google_sources.sql`.

### Google Sources Tables

#### `place_google_sources`
Deprecated and dropped in `20260319083000_drop_llm_enrichments_and_google_sources.sql`.

#### `place_google_reviews`
Active. Parent relation migrated to `place_google_properties` via `google_property_id` in `20260319083000_drop_llm_enrichments_and_google_sources.sql`.

#### `place_google_photos`
Active. Parent relation migrated to `place_google_properties` via `google_property_id` in `20260319083000_drop_llm_enrichments_and_google_sources.sql`.

### Queue & Import Tables

#### `enrichment_jobs`
Data enrichment job queue.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | PK, NOT NULL | Unique identifier |
| `place_id` | bigint | NOT NULL | Place reference |
| `job_type` | text | NOT NULL | Job type enum |
| `priority` | integer | NOT NULL | Priority level |
| `status` | text | NOT NULL | Job status |
| `attempts` | integer | NOT NULL | Attempt count |
| `max_attempts` | integer | NOT NULL | Max attempts |
| `run_after` | timestamptz | NOT NULL | Run after time |
| `locked_by` | text | NULL | Worker lock |
| `locked_at` | timestamptz | NULL | Lock time |
| `error_message` | text | NULL | Error message |
| `created_at` | timestamptz | NOT NULL | Creation time |
| `updated_at` | timestamptz | NOT NULL | Update time |
| `freshness_bucket` | text | NOT NULL | Freshness bucket |
| `lease_expires_at` | timestamptz | NULL | Lease expiry |
| `heartbeat_at` | timestamptz | NULL | Last heartbeat |
| `payload` | jsonb | NOT NULL | Job payload |
| `context` | jsonb | NOT NULL | Job context |
| `last_error_at` | timestamptz | NULL | Last error time |
| `dead_lettered_at` | timestamptz | NULL | Dead letter time |
| `classification` | text | NULL | Error classification |
| `source_state` | text | NULL | Source state |
| `worker_id` | text | NULL | Worker ID |
| `attempt_number` | integer | NULL | Attempt number |
| `last_error_code` | text | NULL | Error code |
| `last_error_message` | text | NULL | Error message |
| `canonical_place_id` | uuid | NULL | Place UUID |
| `metadata` | jsonb | NULL | Metadata JSON |

#### `countries`
Country definitions for imports.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `iso_code` | text | PK, NOT NULL | ISO country code |
| `name` | text | NOT NULL | Country name |
| `geofabrik_name` | text | NOT NULL | Geofabrik name |
| `geofabrik_url` | text | NOT NULL | Geofabrik URL |
| `bounding_box` | jsonb | NOT NULL | Bounding box JSON |
| `created_at` | timestamptz | NULL | Creation time |

#### `country_import_status`
Import status tracking per country.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK, NOT NULL | Unique identifier |
| `country_code` | text | NOT NULL | Country code |
| `status` | text | NOT NULL | Import status |
| `source_type` | text | NOT NULL | Source type |
| `started_at` | timestamptz | NULL | Start time |
| `completed_at` | timestamptz | NULL | Completion time |
| `poi_count` | integer | NULL | Number of POIs |
| `error_message` | text | NULL | Error message |
| `created_at` | timestamptz | NULL | Creation time |
| `updated_at` | timestamptz | NULL | Update time |

#### `osm_import_jobs`
OSM import job tracking.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK, NOT NULL | Unique identifier |
| `job_type` | text | NOT NULL | Job type |
| `status` | text | NOT NULL | Job status |
| `started_at` | timestamptz | NULL | Start time |
| `completed_at` | timestamptz | NULL | Completion time |
| `result` | jsonb | NULL | Result JSON |
| `error_message` | text | NULL | Error message |
| `created_by` | text | NULL | Creator |
| `created_at` | timestamptz | NOT NULL | Creation time |
| `updated_at` | timestamptz | NOT NULL | Update time |

#### `osm_import_runs`
OSM import run history.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | PK, NOT NULL | Unique identifier |
| `source` | text | NOT NULL | Data source |
| `status` | text | NOT NULL | Run status |
| `bbox` | jsonb | NULL | Bounding box |
| `tile_count` | integer | NOT NULL | Total tiles |
| `fetched_count` | integer | NOT NULL | Fetched count |
| `normalized_count` | integer | NOT NULL | Normalized count |
| `imported_count` | integer | NOT NULL | Imported count |
| `created_count` | integer | NOT NULL | Created count |
| `updated_count` | integer | NOT NULL | Updated count |
| `noop_count` | integer | NOT NULL | No-op count |
| `failed_count` | integer | NOT NULL | Failed count |
| `stale_marked_inactive_count` | integer | NOT NULL | Stale count |
| `error_messages` | jsonb | NOT NULL | Error messages |
| `started_at` | timestamptz | NOT NULL | Start time |
| `finished_at` | timestamptz | NULL | Finish time |
| `run_kind` | text | NOT NULL | Run kind |
| `ingestion_provider` | text | NOT NULL | Provider |
| `tile_key` | text | NULL | Tile key |
| `parent_run_id` | bigint | NULL | Parent run |
| `queue_job_id` | bigint | NULL | Queue job |
| `current_tile` | integer | NULL | Current tile |
| `total_tiles` | integer | NULL | Total tiles |

#### `osm_refresh_jobs`
OSM data refresh jobs.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | PK, NOT NULL | Unique identifier |
| `tile_key` | text | NOT NULL | Tile key |
| `bbox` | jsonb | NOT NULL | Bounding box |
| `source_provider` | text | NOT NULL | Source provider |
| `status` | text | NOT NULL | Job status |
| `attempts` | integer | NOT NULL | Attempt count |
| `max_attempts` | integer | NOT NULL | Max attempts |
| `priority` | integer | NOT NULL | Priority |
| `run_after` | timestamptz | NOT NULL | Run after time |
| `locked_by` | text | NULL | Worker lock |
| `lease_expires_at` | timestamptz | NULL | Lease expiry |
| `last_run_id` | bigint | NULL | Last run ID |
| `error_message` | text | NULL | Error message |
| `created_at` | timestamptz | NOT NULL | Creation time |
| `updated_at` | timestamptz | NOT NULL | Update time |

### Audit & Settings Tables

#### `app_settings`
Application configuration.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK, NOT NULL | Unique identifier |
| `key` | text | NOT NULL | Setting key |
| `category` | text | NOT NULL | Category |
| `type` | text | NOT NULL | Value type |
| `value` | jsonb | NOT NULL | Setting value |
| `encrypted` | boolean | NULL | Encrypted flag |
| `description` | text | NULL | Description |
| `validation_rules` | jsonb | NULL | Validation rules |
| `is_archived` | boolean | NULL | Archived flag |
| `created_by` | text | NULL | Creator |
| `updated_by` | text | NULL | Updater |
| `created_at` | timestamptz | NULL | Creation time |
| `updated_at` | timestamptz | NULL | Update time |
| `version` | integer | NULL | Version |

---

## Views

### `campsite_full`
Canonical API read model combining all sources.

| Column | Type | Description |
|--------|------|-------------|
| `place_id` | text | Place UUID |
| `name` | text | Place name |
| `location` | text | Location description |
| `lat` | numeric | Latitude |
| `lng` | numeric | Longitude |
| `has_toilet` | boolean | Has toilet |
| `has_shower` | boolean | Has shower |
| `has_electricity` | boolean | Has electricity |
| `has_water` | boolean | Has water |
| `has_wifi` | boolean | Has WiFi |
| `has_dogs_allowed` | boolean | Dogs allowed |
| `has_beach` | boolean | Has beach |
| `has_laundry` | boolean | Has laundry |
| `has_restaurant` | boolean | Has restaurant |
| `has_bar` | boolean | Has bar |
| `has_shop` | boolean | Has shop |
| `has_pool` | boolean | Has pool |
| `has_playground` | boolean | Has playground |
| `has_dump_station` | boolean | Has dump station |
| `has_washing_machine` | boolean | Has washing machine |
| `has_dishwasher` | boolean | Has dishwasher |
| `review_count` | bigint | Number of reviews |
| `avg_rating` | numeric | Average rating |
| `favorite_count` | bigint | Number of favorites |
| ... | ... | (plus all other campsite fields) |

### `campsite_review_summary`
Aggregated review statistics.

| Column | Type | Description |
|--------|------|-------------|
| `place_id` | text | Place UUID |
| `place_name` | text | Place name |
| `review_count` | bigint | Number of reviews |
| `avg_rating` | numeric | Average rating |
| `min_rating` | numeric | Minimum rating |
| `max_rating` | numeric | Maximum rating |

### `campsite_price_summary`
Aggregated price statistics.

| Column | Type | Description |
|--------|------|-------------|
| `place_id` | text | Place UUID |
| `osm_place_id` | text | OSM place ID |
| `price_count` | bigint | Number of prices |
| `avg_price` | numeric | Average price |
| `min_price` | numeric | Minimum price |
| `max_price` | numeric | Maximum price |
| `avg_rating` | numeric | Average rating |
| `review_count` | bigint | Review count |

### `campsite_api_read_model`
Legacy read model alias (deprecated).

### `place_resolved_public`
Public-facing read model for list and detail queries. Merges the three non-user property tables (google, osm, llm) using per-column priority coalescing. Excludes user-scoped overrides.

**Priority order:** google > osm > llm

**Column groups:**
- Core place identity: `id`, `geom`, `lat`, `lon`, `is_active`, `place_created_at`, `place_updated_at`
- Identity/Content: `name`, `description`, `place_type`, `source_place_type`, `source_categories`
- Address/Location: `country_code`, `region`, `city`, `postcode`, `address`, `source_lat`, `source_lon`
- Contact/Operations: `website`, `phone`, `email`, `opening_hours`, `fee_info`
- Generic Flags: `wheelchair_accessible`, `family_friendly`, `pets_allowed`, `indoor`, `outdoor`, `entry_fee_required`, `reservation_required`, `overnight_stay_allowed`
- General Facilities: `has_parking`, `has_restrooms`, `has_drinking_water`, `has_wifi`, `has_shop`, `has_restaurant`, `has_cafe`
- Camping Permissions: `caravan_allowed`, `motorhome_allowed`, `tent_allowed`
- Camping Facilities: `has_electricity`, `has_fresh_water`, `has_shower`, `has_laundry`, `has_dishwashing_area`
- Disposal/Utilities: `has_grey_water_disposal`, `has_black_water_disposal`, `has_chemical_toilet_disposal`, `has_dump_station`, `has_waste_disposal`, `has_recycling`
- Leisure: `has_bbq_area`, `has_fire_pit`, `has_playground`, `has_pool`, `has_beach`
- Nudism: `nudism_allowed`, `nudism_only`
- Attraction/Museum: `has_guided_tours`, `has_audio_guide`, `has_visitor_center`, `has_lockers`, `photography_allowed`
- Source tracking: `has_osm`, `has_google`, `has_llm`, `name_source`
- Timestamps: `osm_updated_at`, `google_updated_at`, `llm_updated_at`, `osm_source_updated_at`, `google_source_updated_at`, `llm_source_updated_at`

Canonical coordinates (`lat`, `lon`, `geom`) come from the `places` table. Whitespace-only strings are treated as NULL. Uses LATERAL joins to fetch current-row property data from each source table.

### `place_resolved_my`
Authenticated-user read model for list and detail queries. Same column structure as `place_resolved_public` but inserts the current authenticated user's `place_user_properties` into the priority chain.

**Priority order:** google > user > osm > llm

User override is determined by `auth.uid()`. If no user is authenticated, falls back to google > osm > llm (same result as `place_resolved_public`).

Additional columns beyond `place_resolved_public`:
- `has_user` (boolean): whether the current user has submitted a property override for this place
- `user_updated_at` (timestamptz): when the user's override was last updated
- `user_source_updated_at` (timestamptz): source timestamp from the user's override row

Use for rendering place data that should reflect the authenticated user's personal corrections or additions.

---

## Enums

| Enum Name | Values |
|-----------|--------|
| `user_role` | 'user', 'admin' |
| `stop_type` | 'camping', 'stellplatz', 'poi', 'city', 'address' |
| `cost_type` | 'per_night', 'entry_fee', 'none' |
| `job_status` | 'pending', 'processing', 'completed', 'failed', 'skipped' |
| `place_type_enum` | 'camp_site', 'camper_stop', 'overnight_parking', 'parking', 'attraction' |
| `enrichment_status_enum` | 'pending', 'processing', 'done', 'failed', 'needs_review' |
| `enrichment_job_type_enum` | 'enrich_llm', 'refresh_osm', 'google_places' |
| `job_status_enum` | 'queued', 'running', 'done', 'failed', 'dead' |

---

## RPC Functions

### `get_place_source_bundle(bigint)` → jsonb

Returns a complete source bundle for a place by its bigint id.

**Parameters:**
- `place_id` (bigint): The place ID from the `places` table

**Returns:** JSONB object with structure:
```json
{
  "base": { /* places table row */ },
  "osm": { /* current place_osm_properties row or null */ },
  "llm": { /* current place_llm_properties row or null */ },
  "google": { /* current place_google_properties row or null */ },
  "user": [ /* current place_user_properties rows */ ],
  "user_aggregates": {
    "review_count": 0,
    "avg_rating": null,
    "favorite_count": 0
  }
}
```

**Behavior:**
- Returns `NULL` if place_id does not exist
- Only includes current (is_current = true) source records
- User aggregates computed from `campsite_reviews` and `favorites`

---

## Foreign Key Relationships

### Core Relationships

```
profiles (id)
  ├── trips (user_id)
  ├── trip_reminders (user_id)
  ├── vehicle_profiles (user_id)
  ├── favorites (user_id)
  ├── campsite_reviews (user_id)
  └── campsite_prices (user_id)

trips (id)
  ├── trip_stops (trip_id)
  └── trip_reminders (trip_id)

places (id)
  ├── place_enrichment (place_id)
  ├── place_osm_properties (place_id)
  ├── place_google_properties (place_id)
  ├── place_llm_properties (place_id)
  ├── place_user_properties (place_id)
  └── enrichment_jobs (place_id)
```

### Enrichment Relationships

```
enrichment_jobs (id)
  └── no direct FK from aligned property tables
```

### Property Table Relationships

```
places (id)
  ├── place_osm_properties (place_id)
  ├── place_google_properties (place_id)
  ├── place_llm_properties (place_id)
  └── place_user_properties (place_id, user_id)

place_google_properties (id)
  └── source-specific fields kept on aligned property row
```

---

## Schema Design Patterns

### Amenity Facts Pattern
Hard factual data (amenities, contact info) MUST be stored in typed columns, NOT JSONB.

**Correct:**
```sql
has_electricity boolean NOT NULL DEFAULT false,
phone text,
website text
```

**Incorrect (Forbidden):**
```sql
amenities jsonb,  -- { "has_electricity": true }
contact jsonb     -- { "phone": "...", "website": "..." }
```

### JSONB Justification
JSONB columns are allowed ONLY for specific use cases:

| Use Case | Example |
|----------|---------|
| Evidence storage | `source_evidence`, `evidence_markers` |
| Vendor-specific details | `campsites_cache.google_reviews` |
| Debug metadata | `provider_attempts`, `metadata` |
| Unprocessed source data | `campsites_cache.scraped_price_info` |
| Source URLs array | `place_llm_properties.source_urls` |

### Aligned Property Table Pattern
New Phase 2 schema uses "aligned property tables" - a set of four tables with identical column structures for common fields and source-specific columns:

1. **OSM Family** (`place_osm_properties`)
   - Shared columns: 62 columns covering identity, location, contact, facilities, amenities
   - Source-specific: `osm_id`, `osm_type`, `osm_version`, `osm_timestamp`, `imported_at`, `first_seen_at`, `last_seen_at`, `last_import_run_id`, `source_metadata`

2. **Google Family** (`place_google_properties`)
   - Shared columns: 62 columns (same as OSM)
- Source-specific: `google_source_id` (legacy lineage), `google_place_id`, `rating`, `review_count`, `business_status`, `expires_at`

3. **LLM Family** (`place_llm_properties`)
   - Shared columns: 62 columns (same as OSM)
   - Source-specific: `llm_enrichment_id`, `provider`, `model`, `summary_de`, `trust_score`, `source_urls`

4. **User Family** (`place_user_properties`)
   - Shared columns: 62 columns (same as OSM)
   - Source-specific: `user_id` (uuid, NOT NULL)

### Property Row Cardinality
`place_osm_properties`, `place_google_properties`, and `place_llm_properties` enforce exactly one row per `place_id` using strict unique indexes.

`place_user_properties` remains user-scoped and enforces one current row per `(place_id, user_id)`.

```sql
CREATE UNIQUE INDEX uidx_osm_properties_place_unique
    ON place_osm_properties(place_id);
```

---

## Migration History

| Migration | Date | Description |
|-----------|------|-------------|
| `20260321000000_create_place_resolved_views.sql` | 2026-03-21 00:00 | Add `place_resolved_public` (google > osm > llm priority) and `place_resolved_my` (google > user > osm > llm priority via auth.uid()) views for public and authenticated place list/detail queries |
| `20260320060000_drop_unused_job_import_and_cutover_tables.sql` | 2026-03-20 06:00 | **BREAKING:** Add/backfill OSM provenance fields on `place_osm_properties`, drop `place_osm_properties.osm_source_id`, drop `osm_source`, and remove unused job/import/cutover tables (`description_generation_jobs`, `website_scraping_jobs`, `osm_type_transitions`, `import_snapshot`, `cutover_runtime_flags`, `cutover_metric_snapshots`) |
| `20260319100000_enforce_single_row_per_place_in_property_tables.sql` | 2026-03-19 10:00 | Deduplicate `place_osm_properties`/`place_google_properties`/`place_llm_properties`; enforce strict unique `place_id` cardinality (1 row per place) |
| `20260319083000_drop_llm_enrichments_and_google_sources.sql` | 2026-03-19 08:30 | Rekey `place_google_reviews`/`place_google_photos` to `place_google_properties` via `google_property_id`; drop `place_google_sources` and `place_llm_enrichments` |
| `20260319071000_restore_retained_source_tables.sql` | 2026-03-19 07:10 | Restore retained source-family/raw tables (`osm_source`, `place_llm_enrichments`, `place_google_sources`) and retained Google child tables (`place_google_reviews`, `place_google_photos`) with best-effort backfill from aligned property tables |
| `20260318230000_finalize_property_cutover_and_legacy_cleanup.sql` | 2026-03-18 23:00 | **BREAKING:** Cut over `get_place_source_bundle` + `campsite_full` to aligned property tables; drop legacy source tables (`osm_source`, `place_llm_enrichments`, `place_google_sources`, `place_google_reviews`, `place_google_photos`); trim `places` business columns |
| `20260318214500_backfill_missing_llm_property_rows.sql` | 2026-03-18 21:45 | Backfill missing historical rows from place_llm_enrichments into place_llm_properties |
| `20260318213000_backfill_property_tables_and_drop_deprecated_fact_tables.sql` | 2026-03-18 21:30 | Backfill aligned property tables from existing source data; DROP 8 deprecated tables (place_google_amenities, place_google_types, place_llm_facts, place_llm_sources, place_llm_evidence_markers, place_source_evidence_runs, place_evidence_sources, place_evidence_markers) |
| `20260318200000_add_property_tables.sql` | 2026-03-18 20:00 | Add Phase 2 aligned property tables (place_osm_properties, place_google_properties, place_llm_properties, place_user_properties) with shared columns, source-specific columns, current-row semantics, and proper indexes |
| `20260318130000_fix_get_place_source_bundle_ambiguous.sql` | 2026-03-18 13:00 | Fix ambiguous column issue in get_place_source_bundle RPC |
| `20260317210003_source_family_constraints.sql` | 2026-03-17 21:00 | Add constraints to source family tables |
| `20260317210001_google_refresh_lease.sql` | 2026-03-17 21:00 | Add google_refresh_claims table |
| `20260317210002_source_bundle_rpc.sql` | 2026-03-17 21:00 | Add get_place_source_bundle RPC function |
| `20260316140001_fix_place_id_ambiguity.sql` | 2026-03-16 14:00 | Fix place_id ambiguity in enrichment_jobs |
| `20260316130001_simplify_get_place_enrichment_status.sql` | 2026-03-16 13:00 | Simplify get_place_enrichment_status function |
| `20260316120001_fix_get_place_enrichment_status.sql` | 2026-03-16 12:00 | Fix get_place_enrichment_status function |
| `20260316110004_enrichment_jobs_typed_columns.sql` | 2026-03-16 11:00 | Add typed columns to enrichment_jobs |
| `20260316110003_enrichment_jobs_rpc_update.sql` | 2026-03-16 11:00 | Update enrichment_jobs RPC |
| `20260316110002_add_source_family_tables.sql` | 2026-03-16 11:00 | Add source family tables (Phase 1) |
| `20260316110001_add_get_place_enrichment_status.sql` | 2026-03-16 11:00 | Add get_place_enrichment_status function |
| `20260316000001_add_google_amenities_table.sql` | 2026-03-16 00:00 | Add google amenities table |
| `20260314221355_fix_campsite_full_required_fields_and_amenities.sql` | 2026-03-14 22:13 | Fix campsite_full view |
| `20260314000012_extend_campsite_full_view_amenities.sql` | 2026-03-14 00:12 | Extend campsite_full view amenities |
| `20260314000011_drop_decommissioned_legacy_tables.sql` | 2026-03-14 00:11 | Drop decommissioned legacy tables |
| `20260317000001_fix_enrichment_jobs_types.sql` | 2026-03-17 00:00 | Fix enrichment_jobs types |
| `20260310000010_migrate_campsites_data.sql` | 2026-03-10 00:10 | Migrate campsites data |
| `20260310000009_create_composite_indexes.sql` | 2026-03-10 00:09 | Create composite indexes |
| `20260310000008_create_google_cleanup_job.sql` | 2026-03-10 00:08 | Create google cleanup job |
| `20260310000007_create_campsite_full_view.sql` | 2026-03-10 00:07 | Create campsite_full view |
| `20260310000006_refactor_campsites_cache.sql` | 2026-03-10 00:06 | Refactor campsites_cache |
| `20260310000005_create_campsites_table.sql` | 2026-03-10 00:05 | Create campsites table |
| `20260310000004_migrate_to_postgis.sql` | 2026-03-10 00:04 | Migrate to PostGIS |
| `20260310000003_create_enum_types.sql` | 2026-03-10 00:03 | Create enum types |
| `20260310000002_add_google_ttl_columns.sql` | 2026-03-10 00:02 | Add Google TTL columns |
| `20260310000001_fix_campsite_prices_fk.sql` | 2026-03-10 00:01 | Fix campsite_prices foreign key |
| `20260310000000_baseline_schema.sql` | 2026-03-10 00:00 | Baseline schema |

---

## Last Updated

2026-03-21

---

## Related Documentation

- `docs/er-diagram.md` - Entity Relationship Diagram (Mermaid)
- `docs/database-access-audit.md` - Full access audit
- `docs/worker-schema-migration-guide.md` - Worker migration guide
- `docs/SCHEMA_WORKFLOW.md` - Schema workflow documentation

(End of file - total 1567 lines)
