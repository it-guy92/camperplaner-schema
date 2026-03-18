# Decisions: Expand-Contract Policy

## Task 6 Architectural Decisions

### D1: Lock Timeout Value
**Decision:** 5 seconds (`SET lock_timeout = '5s'`)
**Rationale:**
- Long enough for most DDL operations
- Short enough to prevent production lockouts
- Forces batched approach for large tables

### D2: Evidence Gate Before Cleanup
**Decision:** No Phase 3 cleanup without pre-cleanup evidence artifacts
**Rationale:**
- Prevents accidental data loss
- Enables post-mortem recovery
- Shifts from "trust memory" to "trust artifacts"

### D3: Three-Phase Separation
**Decision:** Additive → Transition → Destructive as separate phases
**Rationale:**
- Phase 1 allows safe rollback (just revert migrations)
- Phase 2 validates consumer compatibility
- Phase 3 only after full validation

### D4: Validation Gate P2→P3
**Decision:** Block cleanup until consumers fully migrated
**Rationale:**
- Workers must be on new schema before old is removed
- Prevents runtime errors in production
- Requires 24-hour observation window

### D5: Evidence Artifact Naming
**Decision:** Timestamp-prefixed evidence files
**Format:** `pre-cleanup-{type}-{YYYYMMDD}-{description}.{sql|txt}`
**Rationale:**
- Sortable by date
- Clear purpose in filename
- Easy to locate for post-mortem

---

## Task 2 Architectural Decisions

### D6: Shared Column Count (55 columns)
**Decision:** All four property tables share 55 identical columns
**Rationale:**
- Enables polymorphic read resolution
- Simplifies cross-source comparison
- Categories cover camping, attractions, museums, overnight parking

### D7: Boolean Default = NULL
**Decision:** All boolean property columns default to NULL, never FALSE
**Rationale:**
- NULL preserves "no claim" semantics
- FALSE requires explicit source denial
- Prevents false negatives from missing data

### D8: Minimal Places (6 columns)
**Decision:** places table reduced to id, lat, lon, is_active, created_at, updated_at
**Rationale:**
- Eliminates data redundancy across sources
- Prevents source conflicts on business columns
- lat/lon sufficient for map display without PostGIS

### D9: Read Resolution Priority
**Decision:** User → OSM → Google → LLM
**Rationale:**
- Human corrections highest priority
- Community-verified data (OSM) preferred over commercial (Google)
- AI-generated data (LLM) lowest priority due to hallucination risk

### D10: Current-Row Semantics
**Decision:** OSM/Google/LLM = one per place_id; User = one per (place_id, user_id)
**Rationale:**
- Simplifies read queries (no aggregation needed)
- User corrections scoped per-user to avoid conflicts
- Enforced via partial unique indexes

### D23: Doc Updates Per-Phase
**Decision:** Documentation updates happen during each phase, not after all phases
**Rationale:**
- Phase 1: Add new tables to schema docs and ER diagrams
- Phase 2: Mark deprecated columns, update view documentation
- Phase 3: Document column removals after cleanup executes
- Prevents stale documentation during transition period

### D24: Type Regeneration AFTER Migration
**Decision:** Generate types only after migration executes successfully
**Rationale:**
- Types must reflect actual database state
- Running gen before migration produces stale types
- Must regenerate after each phase (1, 2, and 3)

### D25: Consumer Sync Within 1 Day
**Decision:** Downstream repos sync types within 1 business day of schema merge
**Rationale:**
- Per AGENTS.md contract requirement
- Prevents consumer drift from source of truth
- Enables faster bug detection if types are wrong

---

Last Updated: 2026-03-18

## Task 4 Architectural Decisions

### D11: places as OSM Baseline
**Decision:** Current places business columns migrate to place_osm_properties
**Rationale:**
- OSM is the primary source (source_primary = 'osm' for most places)
- places already contains OSM-sourced data
- Simplifies backfill: copy from places to place_osm_properties

### D12: Google Amenity Flattening Strategy
**Decision:** Each amenity_key maps to a dedicated boolean column
**Rationale:**
- Preserves query performance (no JSONB parsing)
- Enables direct boolean filtering
- Matches Amenity Facts Pattern (hard facts in typed columns)

### D13: Google Type Dual Representation
**Decision:** Primary type → source_place_type; all types → source_categories array
**Rationale:**
- Preserves hierarchical designation (primary type)
- Preserves complete categorization (all types)
- Matches Google's type system design

### D14: LLM Fact Field Mapping
**Decision:** field_name → column_name with value_text parsing
**Rationale:**
- Deterministic mapping (field_name is standardized)
- Type-safe parsing (value_type guides parsing)
- Preserves all business-meaningful facts

### D15: LLM Source URL Aggregation
**Decision:** Aggregate all source_url into source_urls text[]
**Rationale:**
- Preserves complete citation list
- Simple array storage (no normalization needed)
- Domain derivable from URL if needed

### D16: Evidence Marker Discard
**Decision:** place_llm_evidence_markers and place_source_evidence_runs discarded (no target)
**Rationale:**
- Process metadata, not business data
- Trust captured in trust_score
- Debugging data archived to cold storage before drop

### D17: 1:n Table Retention
**Decision:** place_google_reviews and place_google_photos remain as separate tables
**Rationale:**
- 1:n relationships cannot be flattened without data loss
- Reviews and photos are business data, not process metadata
- Property tables contain scalar properties only


## Task 7 Architectural Decisions

### D14: Single Migration File for All Four Tables
**Decision:** Create all four property tables in one migration file
**Rationale:**
- Tables are interdependent (same schema contract)
- Simplifies deployment and rollback
- Reduces migration sequence complexity
- All tables must exist before cross-source resolution works

### D15: Partial Unique Indexes for Current-Row Semantics
**Decision:** Use partial unique indexes instead of triggers or app-level enforcement
**Rationale:**
- PostgreSQL natively enforces this pattern
- Automatically handles concurrent inserts
- No application logic required
- Clear semantics: WHERE clause defines partial uniqueness
- Pattern: `CREATE UNIQUE INDEX ... ON table(columns) WHERE is_current = true`

### D16: User Table Differentiation
**Decision:** User properties use (place_id, user_id) for current-row, not just place_id
**Rationale:**
- Each user can submit multiple corrections over time
- Only latest correction per user should be "current"
- Different users can have different current corrections for same place
- Enables per-user override of source data

### D17: Boolean DEFAULT NULL (No-Claim Semantics)
**Decision:** All boolean columns use DEFAULT NULL, never DEFAULT false
**Rationale:**
- NULL = source made no claim (unknown)
- FALSE = source explicitly denied
- TRUE = source explicitly confirmed
- Prevents false negatives when source simply didn't mention a feature
- Critical for accurate cross-source resolution

### D18: RLS Lockdown Initial Policy
**Decision:** All property tables start with USING (false) / WITH CHECK (false)
**Rationale:**
- Secure by default
- Prevents accidental data exposure
- Can be relaxed later when access patterns are defined
- Service role bypasses RLS anyway

### D19: source_updated_at Column
**Decision:** Add source_updated_at to all property tables
**Rationale:**
- Tracks when source data was last updated (distinct from row updated_at)
- Enables staleness detection
- Useful for cache invalidation
- Separate from created_at/updated_at which track row lifecycle

---

## Task 5 Geometry Audit Decisions

### D20: places.geom Removal Strategy
**Decision:** Remove places.geom, keep lat/lon as NOT NULL
**Rationale:**
- geom is redundant with lat/lon (both store location)
- lat/lon simpler for application code (no PostGIS dependency)
- osm_source.geom retains geometry for OSM tracking
- Other spatial tables (trips, trip_stops, favorites) use independent geography columns

### D21: Geometry Responsibility Split
**Decision:** Geometry lives in source tables, not canonical places
**Allocation:**
- places: lat/lon numeric coordinates only
- osm_source: geom + centroid for OSM geometry tracking
- trips/trip_stops/favorites: independent geography columns
- campsites: independent geography column
**Rationale:**
- Separates concerns: places = canonical data, sources = raw geometry
- Prevents places table from being PostGIS-dependent
- Each source manages its own geometry representation

### D22: Consumer Migration Gate
**Decision:** Block geom removal until 7 product repo files updated
**Files:**
1. apps/web/scripts/analyze-germany.mjs
2. apps/web/scripts/germany-e2e-final-report.mjs
3. apps/web/scripts/germany-e2e-report.mjs
4. apps/web/scripts/germany-e2e-test.mjs
5. apps/web/src/app/api/admin/cutover/metrics/route.ts
6. apps/web/src/app/api/admin/osm/status/route.ts
7. apps/web/e2e/europe-import.spec.ts
**Rationale:**
- Prevents runtime errors in production
- Ensures all consumers use lat/lon before geom disappears
- Worker repo confirmed clean (no geom references)


## Task 9 Architectural Decisions

### D26: Batch Size = 1000 place_ids
**Decision:** Process 1000 place_ids per batch with COMMIT between batches
**Rationale:**
- Balances lock duration vs transaction overhead
- 1000 places ≈ 1-5 seconds per batch (depends on amenity density)
- Allows progress monitoring via RAISE NOTICE
- Enables resume on failure (process unprocessed ranges)

### D27: PROCEDURE over DO Block
**Decision:** Use CREATE PROCEDURE instead of DO block for backfill
**Rationale:**
- DO blocks cannot COMMIT (no autonomous transaction support in plain PL/pgSQL)
- PROCEDURE supports COMMIT for releasing locks between batches
- Idempotent via ON CONFLICT upsert

### D28: LEFT JOIN for Amenities (not INNER JOIN)
**Decision:** LEFT JOIN place_google_amenities, not INNER JOIN
**Rationale:**
- Some places may have Google source but no amenities extracted
- INNER JOIN would exclude places without amenities
- LEFT JOIN + MAX(CASE ...) produces NULL for missing amenities (correct no-claim semantics)

### D29: laundry + washing_machine → has_laundry (COALESCE)
**Decision:** Both 'laundry' and 'washing_machine' amenity keys map to has_laundry
**Rationale:**
- Google uses both keys inconsistently for the same facility
- COALESCE(laundry, washing_machine) preserves either claim
- 'laundry' takes precedence if both present (more specific)

### D30: bar → has_cafe (Semantic Match)
**Decision:** Google 'bar' amenity maps to has_cafe in target schema
**Rationale:**
- Target schema has has_cafe but no has_bar
- Bar is a subset of food/drink service (cafe category)
- Semantic approximation acceptable for backfill

### D31: Reviews/Photos NOT Flattened
**Decision:** place_google_reviews and place_google_photos remain as 1:n child tables
**Rationale:**
- Each review/photo is a distinct entity with individual metadata
- Flattening would lose author names, review text, photo dimensions
- Property table is for scalar properties only
- Join path preserved via google_source_id

### D32: Amenity Metadata Discarded
**Decision:** is_verified, confidence_score, source_section, google_feature_type not migrated
**Rationale:**
- Target schema uses boolean columns (Amenity Facts Pattern)
- Per-amenity confidence replaced by overall data_confidence
- Provenance details are process metadata, not business data
- Google is implicitly a trusted source (no per-amenity verification needed)

---

## Task 10 Architectural Decisions: LLM Backfill

### D33: JSONB Aggregation for Facts Pivot
**Decision:** Use `jsonb_object_agg(field_name, value_text)` to pivot place_llm_facts rows into a single JSONB object per enrichment
**Rationale:**
- Single-pass extraction vs N subqueries per column
- Preserves all facts including non-standard field names
- Enables flexible column extraction via `->>'field_name'`
- LATERAL join keeps query plan efficient

### D34: Trust Score Multiplicative Model
**Decision:** trust_score = confidence * (1 - COALESCE(hallucination_risk, 0))
**Rationale:**
- Penalizes high-hallucination-risk outputs even if confident
- Preserves 0-1 range for consistency with other scores
- NULL confidence → NULL trust_score (no fabrication)
- NULL hallucination_risk → treat as 0 (no penalty if unknown)

### D35: Source URL Ordering by Relevance
**Decision:** Aggregate source_urls with `ORDER BY relevance_score DESC NULLS LAST, id ASC`
**Rationale:**
- Most relevant URLs first for display
- NULLs last (unscored URLs less important)
- id ASC provides stable ordering for ties
- Matches user expectation of "best sources first"

### D36: Field Name Renaming During Pivot
**Decision:** Rename 3 field_name values during facts pivot
**Mappings:**
- pet_friendly → pets_allowed
- has_water → has_drinking_water
- has_toilet → has_restrooms
**Rationale:**
- Old places column names don't match new aligned naming
- Renaming in SQL pivot is deterministic and auditable
- No data loss: semantic meaning preserved

### D37: Completed-Only Backfill Filter
**Decision:** Only backfill enrichments WHERE status = 'completed'
**Rationale:**
- Pending enrichments have no final data
- Failed enrichments have unreliable data
- Skipped enrichments have no data at all
- Prevents partial/corrupt property rows

### D38: Current-Row Direct Propagation
**Decision:** place_llm_properties.is_current = place_llm_enrichments.is_current (direct copy)
**Rationale:**
- No heuristic needed: source already has current-row semantics
- Partial unique index on target enforces constraint
- Historical enrichments get is_current=false property rows
- Deterministic: no ambiguity in selection

### D39: Evidence Markers Full Discard
**Decision:** place_llm_evidence_markers table has NO target in place_llm_properties
**Rationale:**
- Process data (trust verification during enrichment)
- Trust captured in trust_score (derived from confidence)
- Debugging data can be archived to cold storage before drop
- Simplified model doesn't need per-field evidence trails

---


## Task 8 Batched Backfill Decisions

### D33: LEFT JOIN for OSM Source
**Decision:** Use LEFT JOIN osm_source (is_current = true) — not INNER JOIN
**Rationale:**
- Some places have no OSM source row (non-OSM imports, stale data)
- Every place MUST get a place_osm_properties row for cross-source resolution
- NULL OSM columns = "no claim" (valid per spec)
- INNER JOIN would silently drop places without OSM source

### D34: Column Name Mapping (Critical)
**Decision:** Explicit column renames in backfill SQL
**Mappings:**
- places.has_toilet → place_osm_properties.has_restrooms
- places.has_water → place_osm_properties.has_drinking_water AND has_fresh_water
- places.pet_friendly → place_osm_properties.pets_allowed
**Rationale:**
- Semantic names differ between legacy and new schema
- SQL must use target column names, not source names
- has_water maps to TWO target columns (both drinking and fresh water)

### D35: ON CONFLICT DO NOTHING for Idempotency
**Decision:** Use ON CONFLICT (place_id) WHERE is_current = true DO NOTHING
**Rationale:**
- Allows safe re-runs without duplicate rows
- Partial unique index handles the conflict detection
- If row already exists, skip (don't overwrite)

### D36: Batch Size 10,000 with 0.5s Sleep
**Decision:** Process 10,000 places per batch, sleep 0.5s between
**Rationale:**
- Large enough for efficiency (typical DB has 100k-1M places)
- Small enough to avoid long lock contention
- 0.5s sleep allows concurrent queries to proceed
- Matches inherited wisdom from plan

### D37: No-OSM-Source Places Get Full Business Data
**Decision:** Populate shared columns from places even when osm_source is NULL
**Rationale:**
- places business data (name, address, amenities) is still valuable
- Only OSM-specific columns (osm_id, osm_type, etc.) are NULL
- Prevents data loss for non-OSM-imported places
- Future OSM import can fill in OSM-specific columns later

---

## Task 14 Architectural Decisions: RPC Redesign

### D45: Property Tables Replace Source Tables in RPC
**Decision:** RPC returns place_osm_properties, place_google_properties, place_llm_properties instead of osm_source, place_google_sources, place_llm_enrichments
**Rationale:**
- Property tables contain aligned business data (55 shared columns)
- Source tables contain raw import tracking data (not consumer-friendly)
- Property tables have current-row semantics (is_current = true)
- Enables polymorphic read resolution across sources

### D46: Minimal Base (6 Columns)
**Decision:** `base` key returns only id, lat, lon, is_active, created_at, updated_at
**Rationale:**
- All business data (name, address, amenities) lives in property tables
- places table is the canonical anchor, not the data source
- Eliminates data redundancy and source conflicts
- Reduces JSONB payload size

### D47: 1:n Child Tables as Separate Keys
**Decision:** Include google_reviews and google_photos as separate array keys in bundle
**Rationale:**
- 1:n relationships cannot be flattened without data loss
- Reviews have author_name, rating, review_text per review
- Photos have photo_reference, width, height per photo
- Join path via google_source_id is deterministic

### D48: User Properties in Bundle
**Decision:** Include user_properties as separate key with highest resolution priority
**Rationale:**
- User corrections override all automated sources
- Per-user current row (place_id, user_id) enables multi-user scenarios
- NULL values in user_properties fall through to next source in resolution

### D49: Resolution Priority Not Enforced in RPC
**Decision:** RPC returns all sources; consumer implements resolution logic
**Rationale:**
- Different consumers may need different resolution strategies
- RPC is a data retrieval mechanism, not a business logic layer
- Enables flexible resolution (e.g., merge vs override)
- Keeps RPC simple and predictable

### D50: Documentation Must Match Contract Exactly
**Decision:** docs/database-schema.md RPC section must list all 8 keys with exact structure
**Rationale:**
- Documentation is the consumer-facing contract
- Mismatch between docs and implementation causes integration bugs
- Three layers must agree: SQL comment, docs, evidence files
- Breaking changes must be clearly documented

---

## Task 13 Architectural Decisions: View Cutover

### D40: Full 4-Source COALESCE for All Business Fields
**Decision:** Every business field uses COALESCE(user, osm, google, llm) in that order
**Rationale:**
- Consistent resolution prevents confusion
- No per-field exceptions means simpler mental model
- NULL semantics preserved: if all sources NULL, output is NULL (except amenities → false)

### D41: FALSE Fallback for Amenities Only
**Decision:** Amenity booleans default to FALSE when all sources NULL; other fields remain NULL
**Rationale:**
- Amenities: safe to assume absent if no source claims presence
- Name/address: NULL is more honest than 'Unknown' or ''
- Prevents fabricated data in the view output

### D42: Property Table Column Names in COALESCE, View Names in Output
**Decision:** Use property table column names (has_restrooms, pets_allowed) inside COALESCE; alias to view column names (has_toilet, has_dogs_allowed) in SELECT
**Rationale:**
- Property tables are the source of truth for column names
- View output must match consumer expectations (legacy names)
- SQL aliasing makes the mapping explicit and auditable

### D43: Additive Joins (Not Replacements)
**Decision:** Property tables are LEFT JOINed in addition to existing tables, not replacing them
**Rationale:**
- campsites_cache still needed for Google/scraped/description data
- Aggregate subqueries (reviews, prices, favorites) unchanged
- Minimizes blast radius of the view rewrite

### D44: No Breaking Change to View Output
**Decision:** View output shape (column names, types, order) preserved exactly
**Rationale:**
- Consumers query the view directly
- Internal resolution logic is opaque to consumers
- Enables zero-downtime migration (deploy view, then drop columns)

## Task 16 Architectural Decisions: Deprecated Table Drop Planning

### D51: 4-Wave Drop Sequence
**Decision:** Drop deprecated tables in 4 waves respecting FK dependencies
**Wave Order:**
1. Wave 1: Leaf children with no dependents (place_llm_evidence_markers, place_evidence_markers, place_evidence_sources)
2. Wave 2: Leaf children with mapped data (place_google_amenities, place_google_types, place_llm_facts, place_llm_sources)
3. Wave 3: Deprecated parent with archive (place_source_evidence_runs)
4. Wave 4: Post-drop cleanup (types, docs)
**Rationale:** FK constraints require children before parents; waves group by dependency depth

### D52: Archive Only place_source_evidence_runs
**Decision:** Archive source_evidence + evidence_markers to cold storage; discard all other deprecated tables
**Rationale:**
- place_source_evidence_runs contains debugging data potentially needed post-migration
- Other tables (amenities, types, facts, sources) are fully flattened into property tables
- Evidence markers are process data, not business data
- Archive cost is minimal; recovery value is high

### D53: 4-Gate Cleanup Framework
**Decision:** Each deprecated table requires 4 mandatory gates before drop
**Gates:**
1. BACKFILL VERIFIED: Target property table populated
2. READ CUTOVER VERIFIED: No app code reads deprecated table
3. WRITE CUTOVER VERIFIED: No app code writes deprecated table
4. ROLLBACK READINESS: Pre-drop backup exists
**Rationale:** Prevents premature drops; ensures data safety at each step

### D54: CASCADE for All Drops
**Decision:** Use DROP TABLE ... CASCADE for all deprecated tables
**Rationale:**
- All FK constraints point TO deprecated tables (they are children or leaf parents)
- No retained tables depend on deprecated tables
- Views reference retained tables, not deprecated ones
- CASCADE is safe because dependency graph is fully audited

### D55: Gate Failure = Hard Stop
**Decision:** Any gate check failure halts the entire wave
**Rationale:**
- Partial wave completion creates inconsistent state
- Better to fix root cause than proceed with partial safety
- Matches expand-contract principle: no cleanup without full evidence

---

Last Updated: 2026-03-18

## Task 5 Geometry Audit Decisions

### D45: Remove places.geom, Keep lat/lon
**Decision:** Drop `places.geom` (geometry NOT NULL) but retain `places.lat` and `places.lon` (numeric NULL)
**Rationale:**
- geom is redundant with lat/lon — same data, different format
- lat/lon simpler for consumers (no PostGIS dependency in app code)
- osm_source.geom/centroid already handles OSM geometry tracking
- No ST_* functions query places.geom directly

### D46: Keep osm_source Geometry Columns
**Decision:** osm_source.geom, osm_source.centroid, geometry_kind, geometry_hash remain
**Rationale:**
- These track OSM source geometry, not canonical place location
- All NULL in production but schema intent is valid for future OSM imports
- Removing would break source family contract

### D47: Other Spatial Tables Unaffected
**Decision:** trips, trip_stops, favorites, campsites, google_place_matches geography columns untouched
**Rationale:**
- All use independent geography(Point, 4326) columns
- No foreign key or query joins to places.geom
- GIST indexes on these tables serve their own spatial queries

### D48: Consumer Migration Required Before Drop
**Decision:** 7 product repo files must switch from geom to lat/lon before migration executes
**Rationale:**
- analyze-germany.mjs, germany-e2e-*.mjs, admin routes reference places.geom
- Worker repo has zero geom references (safe)
- Breaking change requires coordinated consumer update

---

## Task 17 Architectural Decisions: Downstream Sync and Consumer Migration Sequence

### D56: Three-Actor Sync Order
**Decision:** Schema Repo → Product → Worker (in that order)
**Rationale:**
- Schema repo owns migrations, must lead the sequence
- Product executes migrations, must verify before worker uses schema
- Worker is read-only consumer, depends on product having deployed
- Prevents worker from failing due to missing schema objects

### D57: Consumer Code Cutover Before Cleanup
**Decision:** Phase 3 cleanup blocked until both consumers confirm deprecated field removal
**Rationale:**
- AGENTS.md requires consumers to stop reading deprecated fields BEFORE schema drops them
- Worker cannot deploy code that reads non-existent columns
- Product cannot query tables that no longer exist
- Hard gate prevents production runtime errors

### D58: Type Sync Within 1 Business Day
**Decision:** Product and worker must sync types within 1 business day of schema merge
**Rationale:**
- Per AGENTS.md contract (Section "Post-Merge Consumer Sync Contract")
- Enables faster detection of type mismatches
- Prevents consumer drift from source of truth

### D59: 24-Hour Observation Window Before Cleanup
**Decision:** Phase 3 cleanup requires 24-hour observation after Phase 2 complete
**Rationale:**
- Allows time for issues to surface in production
- Gives consumers time to verify migration success
- Provides rollback buffer if problems emerge

### D60: Explicit Communication Required
**Decision:** Schema repo must post handoff messages before and after each phase
**Rationale:**
- AGENTS.md requires notification before schema changes
- Consumers need explicit signal to sync and update
- Documentation prevents assumptions about "automatic" handoff
