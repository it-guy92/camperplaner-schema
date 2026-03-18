# CamperPlaner Database Schema

> **Location:** This is the canonical source of truth for the CamperPlaner database schema.
> **Generated:** 2026-03-18
> **Migration Head:** 20260318_fix_get_place_source_bundle_signature.sql

---

## Schema Overview

| Metric | Count |
|--------|-------|
| **Total Tables** | 45 |
| **User Tables** | 38 |
| **System Tables** | 7 (PostGIS) |
| **Views** | 6 |
| **Enums** | 13 |
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
| `osm_source` | OSM source data tracking | `id` (bigint) |
| `osm_import_queue` | OSM import work queue | `id` (bigint) |
| `osm_import_jobs` | OSM import job tracking | `id` (uuid) |
| `osm_import_runs` | OSM import run history | `id` (bigint) |
| `osm_refresh_jobs` | OSM data refresh jobs | `id` (bigint) |
| `osm_type_transitions` | OSM place type transition rules | `id` (bigint) |
| `import_snapshot` | Import snapshots for recovery | `id` (uuid) |
| `description_generation_jobs` | LLM description generation queue | `id` (uuid) |
| `enrichment_jobs` | Data enrichment job queue | `id` (bigint) |
| `website_scraping_jobs` | Website scraping job queue | `id` (uuid) |

### 4. Audit & Logging

| Table | Description | Primary Key |
|-------|-------------|-------------|
| `app_errors` | Application error tracking | `id` (uuid) |
| `app_settings` | Application configuration | `id` (uuid) |
| `settings_audit_log` | Settings change audit trail | `id` (uuid) |
| `cutover_audit_log` | Database cutover audit trail | `id` (bigint) |
| `cutover_metric_snapshots` | Cutover performance metrics | `id` (bigint) |
| `cutover_runtime_flags` | Cutover feature flags | `key` (text) |

### 5. Phase 1: Enrichment Schema (NEW)

#### Parent Tables (Source Families)

| Table | Description | Primary Key |
|-------|-------------|-------------|
| `place_llm_enrichments` | LLM output storage | `id` (bigint) |
| `place_source_evidence_runs` | Evidence collection audit | `id` (bigint) |
| `place_google_sources` | Google Places API cache | `id` (bigint) |

#### Child Tables (LLM Enrichments)

| Table | Description | Primary Key | Parent |
|-------|-------------|-------------|--------|
| `place_llm_facts` | Individual LLM-extracted facts | `id` (bigint) | place_llm_enrichments |
| `place_llm_sources` | Sources cited by LLM | `id` (bigint) | place_llm_enrichments |
| `place_llm_evidence_markers` | Trust markers for LLM output | `id` (bigint) | place_llm_enrichments |

#### Child Tables (Evidence Collection)

| Table | Description | Primary Key | Parent |
|-------|-------------|-------------|--------|
| `place_evidence_sources` | Individual fetched sources | `id` (bigint) | place_source_evidence_runs |
| `place_evidence_markers` | Evidence markers from sources | `id` (bigint) | place_source_evidence_runs |

#### Child Tables (Google Sources)

| Table | Description | Primary Key | Parent |
|-------|-------------|-------------|--------|
| `place_google_reviews` | Individual Google reviews | `id` (bigint) | place_google_sources |
| `place_google_photos` | Google place photos | `id` (bigint) | place_google_sources |
| `place_google_types` | Google place types | `id` (bigint) | place_google_sources |
| `place_google_amenities` | Google amenities data | `id` (bigint) | place_google_sources |

### 6. System/Cache Tables

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
Main places table with canonical data.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | PK, NOT NULL | Unique place identifier |
| `place_type` | text | NOT NULL | Place type enum |
| `name` | text | NOT NULL | Place name |
| `geom` | geometry | NOT NULL | PostGIS geometry |
| `lat` | numeric | NULL | Latitude |
| `lon` | numeric | NULL | Longitude |
| `country_code` | text | NULL | ISO country code |
| `region` | text | NULL | Region/state |
| `city` | text | NULL | City name |
| `postcode` | text | NULL | Postal code |
| `address` | text | NULL | Full address |
| `has_toilet` | boolean | NOT NULL | Has toilet facility |
| `has_shower` | boolean | NOT NULL | Has shower facility |
| `has_electricity` | boolean | NOT NULL | Has electricity |
| `has_water` | boolean | NOT NULL | Has water |
| `has_wifi` | boolean | NOT NULL | Has WiFi |
| `pet_friendly` | boolean | NOT NULL | Pet friendly |
| `caravan_allowed` | boolean | NOT NULL | Caravan allowed |
| `motorhome_allowed` | boolean | NOT NULL | Motorhome allowed |
| `tent_allowed` | boolean | NOT NULL | Tent allowed |
| `website` | text | NULL | Website URL |
| `phone` | text | NULL | Phone number |
| `email` | text | NULL | Email address |
| `opening_hours` | text | NULL | Opening hours |
| `fee_info` | text | NULL | Fee information |
| `source_primary` | text | NOT NULL | Primary data source |
| `data_confidence` | numeric | NULL | Confidence score |
| `last_seen_at` | timestamptz | NULL | Last observed |
| `last_enriched_at` | timestamptz | NULL | Last enriched |
| `is_active` | boolean | NOT NULL | Active flag |
| `created_at` | timestamptz | NOT NULL | Creation time |
| `updated_at` | timestamptz | NOT NULL | Last update |

#### `osm_source`
OSM source data tracking.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | PK, NOT NULL | Unique identifier |
| `place_id` | bigint | FK → places.id, NOT NULL | Parent place |
| `osm_type` | text | NOT NULL | OSM object type |
| `osm_id` | bigint | NOT NULL | OSM object ID |
| `osm_version` | integer | NULL | OSM version |
| `tags` | jsonb | NOT NULL | OSM tags |
| `raw_name` | text | NULL | Raw OSM name |
| `source_snapshot_date` | timestamptz | NULL | Snapshot date |
| `imported_at` | timestamptz | NOT NULL | Import timestamp |
| `first_seen_at` | timestamptz | NOT NULL | First seen |
| `last_seen_at` | timestamptz | NOT NULL | Last seen |
| `last_import_run_id` | bigint | NULL | Import run reference |
| `geometry_kind` | text | NULL | Geometry type |
| `geometry_hash` | text | NULL | Geometry hash |
| `centroid` | geometry | NULL | Centroid point |
| `geom` | geometry | NULL | Full geometry |
| `osm_timestamp` | timestamptz | NULL | OSM timestamp |
| `osmium_unique_id` | text | NULL | Osmium unique ID |
| `first_seen_snapshot_id` | text | NULL | First snapshot ID |
| `last_seen_snapshot_id` | text | NULL | Last snapshot ID |
| `is_current` | boolean | NOT NULL | Current flag |
| `source_metadata` | jsonb | NOT NULL | Source metadata |

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
LLM output storage (parent table).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | PK, NOT NULL | Unique identifier |
| `place_id` | bigint | FK → places.id, NOT NULL | Parent place |
| `job_id` | bigint | FK → enrichment_jobs.id, NULL | Job reference |
| `provider` | text | NOT NULL | LLM provider |
| `model` | text | NOT NULL | Model identifier |
| `prompt_version` | text | NULL | Prompt version |
| `summary_de` | text | NULL | German summary |
| `confidence` | numeric | NULL | Confidence (0-1) |
| `hallucination_risk` | numeric | NULL | Hallucination risk (0-1) |
| `token_input` | integer | NULL | Input tokens |
| `token_output` | integer | NULL | Output tokens |
| `cost_usd` | numeric | NULL | Cost in USD |
| `status` | text | NOT NULL | Processing status |
| `started_at` | timestamptz | NULL | Start time |
| `completed_at` | timestamptz | NULL | Completion time |
| `is_current` | boolean | NOT NULL | Current flag |
| `created_at` | timestamptz | NOT NULL | Creation time |
| `updated_at` | timestamptz | NOT NULL | Update time |
| `created_by` | text | NULL | Creator reference |

#### `place_llm_facts`
Individual LLM-extracted facts.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | PK, NOT NULL | Unique identifier |
| `llm_enrichment_id` | bigint | FK → place_llm_enrichments.id, NOT NULL | Parent enrichment |
| `field_name` | text | NOT NULL | Field name |
| `value_text` | text | NULL | Value as text |
| `value_type` | text | NOT NULL | Value type |
| `confidence` | numeric | NULL | Confidence score |
| `provenance_kind` | text | NULL | Provenance type |
| `created_at` | timestamptz | NOT NULL | Creation time |
| `updated_at` | timestamptz | NOT NULL | Update time |

#### `place_llm_sources`
Sources cited by LLM.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | PK, NOT NULL | Unique identifier |
| `llm_enrichment_id` | bigint | FK → place_llm_enrichments.id, NOT NULL | Parent enrichment |
| `source_url` | text | NOT NULL | Source URL |
| `source_domain` | text | NULL | Domain |
| `source_kind` | text | NOT NULL | Source type |
| `trusted` | boolean | NULL | Trusted flag |
| `relevance_score` | numeric | NULL | Relevance (0-1) |
| `fetched_at` | timestamptz | NULL | Fetch time |
| `created_at` | timestamptz | NOT NULL | Creation time |

#### `place_llm_evidence_markers`
Trust markers for LLM output.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | PK, NOT NULL | Unique identifier |
| `llm_enrichment_id` | bigint | FK → place_llm_enrichments.id, NOT NULL | Parent enrichment |
| `field_name` | text | NOT NULL | Field name |
| `marker_text` | text | NOT NULL | Marker text |
| `marker_type` | text | NOT NULL | Marker type |
| `confidence` | numeric | NULL | Confidence |
| `created_at` | timestamptz | NOT NULL | Creation time |

### Evidence Collection Tables

#### `place_source_evidence_runs`
Evidence collection audit.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | PK, NOT NULL | Unique identifier |
| `place_id` | bigint | FK → places.id, NOT NULL | Parent place |
| `job_id` | bigint | FK → enrichment_jobs.id, NULL | Job reference |
| `worker_id` | text | NULL | Worker ID |
| `attempt_number` | integer | NOT NULL | Attempt count |
| `collection_status` | text | NOT NULL | Collection status |
| `source_urls` | jsonb | NULL | Source URLs array |
| `source_evidence` | jsonb | NULL | Scraped content |
| `evidence_markers` | jsonb | NULL | Evidence markers |
| `trusted_source_count` | integer | NULL | Trusted source count |
| `created_at` | timestamptz | NOT NULL | Creation time |
| `updated_at` | timestamptz | NOT NULL | Update time |

#### `place_evidence_sources`
Individual fetched sources.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | PK, NOT NULL | Unique identifier |
| `evidence_run_id` | bigint | FK → place_source_evidence_runs.id, NOT NULL | Parent run |
| `source_url` | text | NOT NULL | URL fetched |
| `source_domain` | text | NULL | Domain |
| `fetch_status` | text | NOT NULL | Fetch status |
| `http_status` | integer | NULL | HTTP response code |
| `trusted` | boolean | NULL | Trusted flag |
| `content_type` | text | NULL | Content type |
| `fetched_at` | timestamptz | NULL | Fetch time |
| `content_length` | integer | NULL | Content length |
| `error_message` | text | NULL | Error message |
| `created_at` | timestamptz | NOT NULL | Creation time |
| `updated_at` | timestamptz | NOT NULL | Update time |

#### `place_evidence_markers`
Evidence markers from sources.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | PK, NOT NULL | Unique identifier |
| `evidence_run_id` | bigint | FK → place_source_evidence_runs.id, NOT NULL | Parent run |
| `field_name` | text | NOT NULL | Field name |
| `marker_text` | text | NOT NULL | Marker text |
| `marker_type` | text | NOT NULL | Marker type |
| `confidence` | numeric | NULL | Confidence |
| `source_url` | text | NULL | Source URL |
| `context_before` | text | NULL | Context before |
| `context_after` | text | NULL | Context after |
| `created_at` | timestamptz | NOT NULL | Creation time |

### Google Sources Tables

#### `place_google_sources`
Google Places API cache (parent table).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | PK, NOT NULL | Unique identifier |
| `place_id` | bigint | FK → places.id, NOT NULL | Parent place |
| `google_place_id` | text | NOT NULL | Google Place ID |
| `name` | text | NULL | Place name |
| `formatted_address` | text | NULL | Full address |
| `phone` | text | NULL | Phone number |
| `website` | text | NULL | Website URL |
| `rating` | numeric | NULL | Google rating |
| `review_count` | integer | NULL | Number of reviews |
| `business_status` | text | NULL | Business status |
| `lat` | numeric | NULL | Latitude |
| `lon` | numeric | NULL | Longitude |
| `raw_payload` | jsonb | NULL | Full API response |
| `fetched_at` | timestamptz | NOT NULL | Fetch time |
| `expires_at` | timestamptz | NULL | Expiration time |
| `is_current` | boolean | NOT NULL | Current flag |
| `created_at` | timestamptz | NOT NULL | Creation time |
| `updated_at` | timestamptz | NOT NULL | Update time |

#### `place_google_reviews`
Individual Google reviews.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | PK, NOT NULL | Unique identifier |
| `google_source_id` | bigint | FK → place_google_sources.id, NOT NULL | Parent source |
| `author_name` | text | NULL | Reviewer name |
| `rating` | integer | NULL | Star rating |
| `language_code` | text | NULL | Language code |
| `review_text` | text | NULL | Review content |
| `review_time` | timestamptz | NULL | Review timestamp |
| `relative_time_description` | text | NULL | Relative time |
| `google_review_id` | text | NULL | Google review ID |
| `created_at` | timestamptz | NOT NULL | Creation time |

#### `place_google_photos`
Google place photos.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | PK, NOT NULL | Unique identifier |
| `google_source_id` | bigint | FK → place_google_sources.id, NOT NULL | Parent source |
| `photo_reference` | text | NOT NULL | Google photo token |
| `width` | integer | NULL | Photo width |
| `height` | integer | NULL | Photo height |
| `attribution` | text | NULL | Attribution text |
| `google_photo_id` | text | NULL | Google photo ID |
| `created_at` | timestamptz | NOT NULL | Creation time |

#### `place_google_types`
Google place types.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | PK, NOT NULL | Unique identifier |
| `google_source_id` | bigint | FK → place_google_sources.id, NOT NULL | Parent source |
| `google_type` | text | NOT NULL | Google type |
| `is_primary` | boolean | NOT NULL | Primary flag |
| `created_at` | timestamptz | NOT NULL | Creation time |

#### `place_google_amenities`
Google amenities data.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | PK, NOT NULL | Unique identifier |
| `google_source_id` | bigint | FK → place_google_sources.id, NOT NULL | Parent source |
| `amenity_key` | text | NOT NULL | Amenity key |
| `value_text` | text | NULL | Text value |
| `value_boolean` | boolean | NULL | Boolean value |
| `value_numeric` | numeric | NULL | Numeric value |
| `value_type` | text | NOT NULL | Value type enum |
| `google_feature_type` | text | NULL | Feature type |
| `is_verified` | boolean | NOT NULL | Verified flag |
| `confidence_score` | numeric | NULL | Confidence |
| `source_section` | text | NULL | Source section |
| `created_at` | timestamptz | NOT NULL | Creation time |
| `updated_at` | timestamptz | NOT NULL | Update time |

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

#### `description_generation_jobs`
LLM description generation queue.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK, NOT NULL | Unique identifier |
| `place_id` | uuid | NOT NULL | Place reference |
| `status` | text | NULL | Job status |
| `priority` | integer | NULL | Priority level |
| `attempts` | integer | NULL | Attempt count |
| `error_message` | text | NULL | Error message |
| `created_at` | timestamptz | NULL | Creation time |
| `updated_at` | timestamptz | NULL | Update time |
| `completed_at` | timestamptz | NULL | Completion time |

#### `website_scraping_jobs`
Website scraping job queue.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK, NOT NULL | Unique identifier |
| `place_id` | uuid | NOT NULL | Place reference |
| `website_url` | text | NOT NULL | URL to scrape |
| `status` | text | NULL | Job status |
| `priority` | integer | NULL | Priority level |
| `attempts` | integer | NULL | Attempt count |
| `extracted_data` | jsonb | NULL | Extracted data |
| `error_message` | text | NULL | Error message |
| `created_at` | timestamptz | NULL | Creation time |
| `updated_at` | timestamptz | NULL | Update time |
| `completed_at` | timestamptz | NULL | Completion time |

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
  "osm": { /* current osm_source row or null */ },
  "llm": { /* current place_llm_enrichments row or null */ },
  "google": { /* current place_google_sources row or null */ },
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
  ├── osm_source (place_id)
  ├── place_enrichment (place_id)
  ├── place_llm_enrichments (place_id)
  ├── place_source_evidence_runs (place_id)
  ├── place_google_sources (place_id)
  └── enrichment_jobs (place_id)
```

### Enrichment Relationships

```
enrichment_jobs (id)
  ├── place_llm_enrichments (job_id)
  └── place_source_evidence_runs (job_id)

place_llm_enrichments (id)
  ├── place_llm_facts (llm_enrichment_id)
  ├── place_llm_sources (llm_enrichment_id)
  └── place_llm_evidence_markers (llm_enrichment_id)

place_source_evidence_runs (id)
  ├── place_evidence_sources (evidence_run_id)
  └── place_evidence_markers (evidence_run_id)

place_google_sources (id)
  ├── place_google_reviews (google_source_id)
  ├── place_google_photos (google_source_id)
  ├── place_google_types (google_source_id)
  └── place_google_amenities (google_source_id)
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
| Vendor-specific details | `place_google_sources.raw_payload` |
| Debug metadata | `provider_attempts`, `metadata` |
| Unprocessed source data | `osm_source.tags` |

### Source Family Pattern
New enrichment schema uses "source families" - parent tables that group related data:

1. **LLM Family** (`place_llm_enrichments`)
   - Parent: place_llm_enrichments
   - Children: place_llm_facts, place_llm_sources, place_llm_evidence_markers

2. **Evidence Family** (`place_source_evidence_runs`)
   - Parent: place_source_evidence_runs
   - Children: place_evidence_sources, place_evidence_markers

3. **Google Family** (`place_google_sources`)
   - Parent: place_google_sources
   - Children: place_google_reviews, place_google_photos, place_google_types, place_google_amenities

---

## Last Updated

2026-03-18

---

## Related Documentation

- `docs/er-diagram.md` - Entity Relationship Diagram (Mermaid)
- `docs/database-access-audit.md` - Full access audit
- `docs/worker-schema-migration-guide.md` - Worker migration guide
- `docs/SCHEMA_WORKFLOW.md` - Schema workflow documentation
