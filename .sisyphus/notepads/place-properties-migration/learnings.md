## Task 15: Places Cleanup Planning

### Cleanup Scope
- **Current:** 30 columns in places table
- **Target:** 6 columns (id, lat, lon, is_active, created_at, updated_at)
- **Removals:** 26 columns (19 business + 1 geometry + 4 source tracking + 2 identity)

### Removal Sequencing
1. **Phase 1:** Business data columns (19) - address, contact, amenities, identity
2. **Phase 2:** Geometry column (1) + idx_places_geom index
3. **Phase 3:** Source tracking columns (4)

### Validation Gates (12 total)
- Gates 1-8: Pre-cleanup (Phase 2→3 transition)
- Gates 9-12: Post-cleanup verification
- **1 gate done:** Geometry audit (Gate 4)
- **11 gates required** before cleanup can proceed

### Key Dependencies
- campsite_full view must be rewritten first
- get_place_source_bundle RPC must be updated first
- 7 product repo files reference places.geom (must migrate to lat/lon)
- Worker repo clean (no places.geom references)

### Evidence Artifacts
- task-15-final-places.txt: Final schema definition
- task-15-cleanup-gates.txt: Validation gate definitions
- task-5-geometry-audit.txt: Geometry dependency audit (DONE)
- task-6-checkpoints.txt: Expand-contract checkpoint gates (DONE)

### Blocking Conditions (7)
1. campsite_full view still references deprecated columns
2. get_place_source_bundle RPC still returns deprecated columns
3. Rollback plan not documented/tested
4. Consumer repos not notified
5. Pre-cleanup row count snapshot missing
6. FK dependency audit incomplete
7. Index inventory incomplete

Last Updated: 2026-03-18

## Task 16 Findings: Deprecated Table Drop Planning

### Drop Sequence Patterns

1. **FK-Ordered Wave Drops**
   - Group tables by dependency depth (leaves first, parents last)
   - Each wave is atomic: all tables in wave drop together or none drop
   - Wave boundaries align with FK constraint layers
   - Pattern: Wave 1 (leaves) → Wave 2 (mapped children) → Wave 3 (parent) → Wave 4 (cleanup)

2. **Archive-Before-Drop for Audit Tables**
   - Tables containing debugging/audit data (place_source_evidence_runs) need archive
   - Archive to cold storage (S3/blob) with checksum verification
   - Document archive location in cutover_audit_log before drop
   - Other deprecated tables (amenities, types, facts, sources) are fully flattened — no archive needed

3. **4-Gate Cleanup Framework**
   - BACKFILL: Verify target property table has data for all places
   - READ CUTOVER: grep consumer repos for deprecated table references
   - WRITE CUTOVER: Verify worker logs show zero writes for 24h
   - ROLLBACK: Pre-drop backup exists and verified
   - All 4 gates must pass; any failure = hard stop

4. **Current State Assessment**
   - 7 of 8 deprecated tables already excluded from generated/database.types.ts
   - Only place_source_evidence_runs is in types (must remove after drop)
   - All deprecated tables still documented in docs/database-schema.md
   - Views (campsite_full) already reference retained tables, not deprecated ones

### Anti-Patterns Avoided

1. **Premature Drop Without Backfill Verification**
   - WRONG: Drop place_google_amenities before place_google_properties populated
   - RIGHT: Verify backfill completeness via row count comparison + spot checks

2. **Partial Wave Completion**
   - WRONG: Drop 2 of 3 Wave 1 tables, defer third
   - RIGHT: All-or-nothing per wave; fix issues before proceeding

3. **Archive After Drop**
   - WRONG: Drop place_source_evidence_runs, then realize archive was needed
   - RIGHT: Archive FIRST, verify integrity, THEN drop

---

Last Updated: 2026-03-18

## Task 5 Geometry Audit Learnings

### Spatial Column Inventory Pattern
- **geometry vs geography**: places.geom uses geometry(Point, 4326); trips/favorites use geography(Point, 4326)
- **GIST indexes**: Each spatial column needs its own GIST index; dropping column requires dropping index
- **Redundant storage**: places.geom + places.lat/lon is redundant — pick one canonical format

### Dependency Discovery Method
1. Grep for `geom`, `geometry`, `ST_*`, `GIST`, `geography`, `PostGIS` across all SQL/MD/TS
2. Read generated types to confirm field exposure
3. Check ER diagram for relationship lines
4. Cross-reference access audit for consumer usage

### Key Finding: No Active ST_* Dependencies on places.geom
- Zero migrations use ST_DWithin/ST_Distance/ST_Intersects on places.geom
- campsite_full view uses campsites.location, not places.geom
- Consumer references are SELECT-only (fetching geom value), not spatial queries

### Evidence Artifacts Created
- `.sisyphus/evidence/task-5-geometry-audit.txt`: Full spatial inventory
- `.sisyphus/evidence/task-5-places-geometry-check.txt`: Dependency checklist + guardrail

## F3 Verification Rehearsal Review

### Evidence Inventory Results
- **T1-T17**: All 17 tasks have 2 evidence files each (34 total) ✅
- **F1**: 3 evidence files exist (f1-table-compliance.txt, f1-places-minimal.txt, f1-deprecated-removed.txt) ✅
- **F2**: 3 evidence files exist (f2-boolean-semantics.txt, f2-index-coverage.txt, f2-current-row-constraints.txt) ✅
- **F3**: 3 evidence files created (f3-evidence-inventory.txt, f3-row-counts.txt, f3-no-orphans.txt) ✅
- **F4**: 3 evidence files exist (f4-google-children-preserved.txt, f4-no-scope-creep.txt, f4-expand-contract-respected.txt) ✅

### Verification Queries Documented
1. **Row Count Validation**: 6 queries comparing places count vs property table current-row counts
2. **Orphan Detection**: 7 queries checking for property rows with invalid place_id references
3. **FK Constraint Verification**: 1 query confirming FK constraints exist on property tables

### Key Findings
- All T1-T17 evidence paths exist and are complete (34 files)
- Row count validation queries document expected variance rules (property counts ≤ places count)
- Orphan check queries cover all 4 property tables + 2 retained 1:n tables (reviews, photos)
- All F1-F4 evidence files present (12 files total)
- Extra files found: task-15-schema-workflow-doc.md, task-10-schema-ci.txt (bonus, not harmful)
- Total evidence files: 48 (34 task + 12 final review + 2 extra)

### Evidence Files Created
- `.sisyphus/evidence/f3-evidence-inventory.txt`: Complete T1-T17 evidence file inventory
- `.sisyphus/evidence/f3-row-counts.txt`: Row count validation queries with variance rules
- `.sisyphus/evidence/f3-no-orphans.txt`: Orphan detection queries for all property tables

## Task F2 Findings: Schema Quality Review

### Constraint Verification Pattern
- All 4 partial unique indexes match spec exactly
- OSM/Google/LLM: `UNIQUE(place_id) WHERE is_current = true`
- User: `UNIQUE(place_id, user_id) WHERE is_current = true` (composite key for per-user corrections)
- Pattern is consistent with existing source tables (osm_source, place_google_sources, place_llm_enrichments)

### Index Coverage Completeness
- 17 total indexes across 4 tables (4+5+4+4)
- Common pattern: place_id index + is_current partial + place_id+is_current composite
- Source-specific: osm_id, google_place_id, expires_at, provider
- All sparse column indexes use WHERE IS NOT NULL filters (optimization)

### Boolean Semantics Preservation
- All 37 feature booleans per table use DEFAULT NULL (no false defaults)
- is_current correctly uses NOT NULL DEFAULT true (infrastructure flag, not a claim)
- Three-state semantics preserved: NULL=no claim, FALSE=explicit no, TRUE=explicit yes
- No unintended DEFAULT false anywhere in migration

### Evidence Artifacts Created
- `.sisyphus/evidence/f2-current-row-constraints.txt`: Constraint verification matrix
- `.sisyphus/evidence/f2-index-coverage.txt`: Index coverage verification
- `.sisyphus/evidence/f2-boolean-semantics.txt`: Boolean semantics analysis

## Task F1 Findings: Plan Compliance Audit

### Property Table Compliance Results
- **All 4 property tables verified**: place_osm_properties, place_google_properties, place_llm_properties, place_user_properties
- **Shared column alignment**: 55 columns match schema contract exactly
- **Source-specific columns**: OSM (5), Google (6), LLM (6), User (1) — all present
- **Total column counts**: 60, 61, 61, 56 — matches contract
- **Boolean semantics**: All nullable with DEFAULT NULL — correct
- **Current-row indexes**: 4 partial unique indexes — correct
- **Foreign keys**: All reference places(id) with CASCADE — correct

### Places Minimal Target Verification
- **Current state**: 32 columns in places table
- **Target state**: 6 columns (id, lat, lon, is_active, created_at, updated_at)
- **Columns to remove**: 26 (19 business + 1 geometry + 4 source tracking + 2 identity)
- **Business column mapping**: All 19 columns have homes in property tables
- **Column name changes**: has_toilet→has_restrooms, has_water→has_fresh_water, pet_friendly→pets_allowed
- **Migration status**: Cleanup migration NOT yet created (expected — property tables must validate first)

### Deprecated Table Verification
- **All 8 deprecated tables found**: 136 grep matches across 4 SQL files
- **Drop sequence correct**: 4 waves respecting FK dependencies
- **Archive decision**: place_source_evidence_runs → cold storage; others → discard
- **Data migration paths**: All verified (flattened into property tables or archived)
- **Retained tables safe**: None of the retained tables appear in drop sequence
- **Migration status**: Drop migration NOT yet created (expected — after validation gates)

### Evidence Files Created
- `.sisyphus/evidence/f1-table-compliance.txt`: Property table column alignment verification
- `.sisyphus/evidence/f1-places-minimal.txt`: Places target 6-column verification
- `.sisyphus/evidence/f1-deprecated-removed.txt`: Deprecated table drop sequence verification

### Key Patterns Discovered
1. **Column name semantic mapping**: Some places columns renamed in property tables (has_toilet→has_restrooms, has_water→has_fresh_water, pet_friendly→pets_allowed) — must document for consumer migration
2. **Wave-based drop safety**: FK dependency ordering ensures no orphaned references
3. **Archive-before-drop**: place_source_evidence_runs requires cold storage archive before drop
4. **Conditional pass**: Both places cleanup and deprecated drops are pending migration creation — this is correct sequencing (validate property tables first)

## F4 Scope Fidelity Verification

### Google Child Tables Preservation
- **place_google_reviews**: RETAINED ✅ - 1:n relationship, individual reviews needed for display
- **place_google_photos**: RETAINED ✅ - 1:n relationship, individual photos needed for gallery
- **place_google_types**: DEPRECATED (flattened to source_categories + source_place_type)
- **place_google_amenities**: DEPRECATED (flattened to boolean columns)
- Join path preserved: place_google_properties.google_source_id → place_google_sources → reviews/photos

### Scope Creep Check
- Migration creates exactly 4 tables: place_osm_properties, place_google_properties, place_llm_properties, place_user_properties
- All 4 tables are authorized per plan
- Zero unauthorized tables detected
- No scope creep

### Expand-Contract Pattern Verification
- **Phase 1 (EXPAND)**: ✅ Complete - additive migration only (CREATE TABLE, CREATE INDEX, CREATE TRIGGER, CREATE POLICY)
- **Phase 2 (MIGRATE)**: ⏳ Pending - consumers need to sync types and update code
- **Phase 3 (CONTRACT)**: ⏳ Pending - drop sequence documented in task-16-drop-sequence.txt, not executed
- Migration contains ZERO destructive operations (no DROP TABLE, no ALTER DROP)
- Drop sequence respects FK dependencies (4 waves: leaves → mapped children → parent → cleanup)

### Evidence Artifacts Created
- `.sisyphus/evidence/f4-google-children-preserved.txt`: Google child table retention verification
- `.sisyphus/evidence/f4-no-scope-creep.txt`: Unauthorized table detection
- `.sisyphus/evidence/f4-expand-contract-respected.txt`: Expand-contract pattern verification

### Key Findings
1. Migration is purely additive - safe to deploy without breaking existing functionality
2. Deprecated tables are NOT dropped in this migration (correct expand-contract sequencing)
3. Drop sequence is documented separately with 4-gate verification framework
4. Google child tables maintain FK chain via google_source_id for backward compatibility

Last Updated: 2026-03-18
