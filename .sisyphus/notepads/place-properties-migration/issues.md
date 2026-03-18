# Issues: Expand-Contract Migration

## Task 6 Issues Identified

### Issue 1: Manual Memory vs Artifacts
**Problem:** Past migrations relied on manual memory for rollback evidence
**Impact:** No audit trail, difficult post-mortem
**Resolution:** Task 6 mandates explicit artifact files

### Issue 2: No Lock Timeout Standard
**Problem:** DDL could cause production lockouts
**Impact:** Workers timeout, unresponsive app
**Resolution:** Task 6 mandates `lock_timeout = '5s'` for all DDL

### Issue 3: Additive + Destructive in Same Window
**Problem:** Some migrations mixed CREATE and DROP
**Impact:** Hard to isolate failures, risky rollbacks
**Resolution:** Task 6 enforces 3-phase separation

### Issue 4: Missing Validation Gate
**Problem:** No explicit gate between consumer transition and cleanup
**Impact:** Cleanup runs before consumers ready
**Resolution:** Task 6 requires evidence before Phase 3

### Issue 5: FK Dependency Unknown
**Problem:** Dropping columns without FK audit
**Impact:** FK constraint failures block migrations
**Resolution:** Task 6 mandates pre-cleanup FK audit

---

## Task 2 Issues Identified

### Issue 6: Geometry Removal Risk
**Problem:** Removing geom from places may break spatial queries
**Impact:** Search radius, map clustering, proximity features
**Resolution:** Audit all ST_ function usage before cleanup (Task 5)

### Issue 7: Boolean NULL Semantics Complexity
**Problem:** Application code must distinguish NULL from FALSE
**Impact:** UI must show "unknown" vs "no" states
**Resolution:** Document semantics clearly; consumer code must handle tri-state

### Issue 8: Source Conflict Resolution
**Problem:** Multiple sources may provide conflicting data
**Impact:** Which source wins for overlapping fields?
**Resolution:** Defined priority: User → OSM → Google → LLM

### Issue 9: Backfill NULL Preservation
**Problem:** Backfill logic may incorrectly convert NULL to FALSE
**Impact:** False negatives in property data
**Resolution:** Explicit NULL preservation rules in backfill scripts

### Issue 10: Consumer Type Contract Changes
**Problem:** Removing 25 columns from places breaks generated types
**Impact:** Product and worker repos must update type imports
**Resolution:** Downstream sync PRs after schema merge

---

Last Updated: 2026-03-18

## Task 4 Issues Identified

### Issue 11: Amenity Key Standardization
**Problem:** Google amenity keys may not match target column names exactly
**Impact:** Mapping requires explicit key→column translation table
**Resolution:** Defined deterministic mapping in task-4-mapping-matrix.txt (17 keys mapped)

### Issue 12: LLM Fact Type Parsing
**Problem:** LLM facts store values as text regardless of value_type
**Impact:** Backfill must parse value_text according to value_type for boolean/numeric fields
**Resolution:** Transform rules defined per field_name in mapping matrix

### Issue 13: Source URL Aggregation Strategy
**Problem:** Multiple LLM sources per enrichment need aggregation into single array
**Impact:** Must decide on deduplication and ordering
**Resolution:** Aggregate all source_url values into source_urls text[] (no deduplication)

### Issue 14: Confidence Score Aggregation
**Problem:** Per-fact/per-amenity confidence needs aggregation to single data_confidence
**Impact:** Must define aggregation function (average, max, weighted)
**Resolution:** Use average confidence from current enrichment/amenity rows

### Issue 15: Evidence Archive Before Drop
**Problem:** place_source_evidence_runs contains debugging data that may be needed post-migration
**Impact:** Dropping table loses audit trail
**Resolution:** Archive source_evidence and evidence_markers to cold storage before table drop

---

## Task 1 Issues Identified

### Issue 16: campsite_full VIEW Blocks Column Removal
**Problem:** campsite_full VIEW reads 21 deprecated columns directly from places table
**Impact:** Column DROP will break the view and all product queries using it
**Resolution:** Rewrite view to join source tables (osm_source, place_google_sources, place_llm_enrichments) BEFORE dropping columns

### Issue 17: get_place_source_bundle Uses SELECT *
**Problem:** RPC uses `SELECT to_jsonb(p.*)` which includes all deprecated columns
**Impact:** JSONB output shape changes when columns are removed; worker may break
**Resolution:** Replace with explicit column list OR document as breaking change with consumer migration guide

### Issue 18: Documentation Drift Risk
**Problem:** 5 documentation files reference deprecated columns extensively
**Impact:** Docs will be inaccurate after migration; confuses developers
**Resolution:** Update all 5 docs as part of migration PR (not after)

### Issue 19: Generated Types Must Regenerate AFTER Migration
**Problem:** Types cannot be regenerated until migration is applied
**Impact:** If types regenerated before migration, they'll still include deprecated columns
**Resolution:** Migration PR must include: (1) SQL migration, (2) apply migration, (3) regenerate types, (4) commit types

---

## Task 11 Issues Identified

### Issue 20: Missing FK Constraint on user_id
**Problem:** place_user_properties.user_id is defined as `uuid NOT NULL` but lacks FK to profiles(id)
**Impact:** No referential integrity; orphaned user corrections if profile deleted; inconsistent with other property tables
**Resolution:** Add migration to create FK: `CONSTRAINT fk_user_properties_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE`


## Task 16 Issues Identified

### Issue 21: place_source_evidence_runs in Generated Types
**Problem:** place_source_evidence_runs is the only deprecated table still in generated/database.types.ts
**Impact:** Types will be stale after drop; consumer repos will have broken type references
**Resolution:** Remove from types AFTER drop migration executes; regenerate types as Wave 4 step

### Issue 22: Archive Storage Location Undefined
**Problem:** No cold storage bucket/path defined for place_source_evidence_runs archive
**Impact:** Cannot execute Wave 3 drop without archive target
**Resolution:** Define archive target (e.g., s3://camperplaner-archive/evidence-runs/) before Wave 3

### Issue 23: Backfill Verification Queries Not Automated
**Problem:** Gate checks require manual SQL queries against production database
**Impact:** Human error risk; slow verification process
**Resolution:** Consider creating automated gate-check script that runs all verification queries

### Issue 24: 24-Hour Observation Window Not Scheduled
**Problem:** Write cutover gate requires 24h observation but no schedule defined
**Impact:** May proceed with drops before observation window completes
**Resolution:** Schedule observation window start after read cutover; document in cutover_audit_log

### Issue 25: Consumer Repo Sync Timing Unclear
**Problem:** Wave 4 requires type regeneration + consumer sync but timing is unclear
**Impact:** Consumer repos may have stale types during drop window
**Resolution:** Regenerate types immediately after drop; open downstream sync PRs within 1 business day

---

## Task F2 Issues Identified

### Issue 26: Feature Booleans Missing NOT NULL Constraint
**Problem:** Spec requires `boolean NOT NULL DEFAULT NULL` but migration uses `boolean DEFAULT NULL`
**Impact:** Missing data integrity guardrail; application can explicitly INSERT NULL
**Severity:** LOW - semantic correctness preserved (DEFAULT NULL is correct), only integrity constraint missing
**Resolution:** Consider follow-up migration to add NOT NULL constraint to all 37 feature boolean columns per table (148 total)
**Evidence:** `.sisyphus/evidence/f2-boolean-semantics.txt` Section 2.2

---

Last Updated: 2026-03-18
