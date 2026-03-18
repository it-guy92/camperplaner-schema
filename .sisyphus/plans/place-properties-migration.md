# Migrate To Source Property Tables

## TL;DR

> **Quick Summary**: Replace the overloaded `places` schema with a minimal core table plus four aligned source-specific property tables, then cut reads over in phases and remove deprecated schema after validation.
>
> **Deliverables**:
> - New tables: `place_osm_properties`, `place_google_properties`, `place_llm_properties`, `place_user_properties`
> - Minimal `places` table containing only `id`, `lat`, `lon`, `is_active`, `created_at`, `updated_at`
> - Updated read models / RPCs that read from the new property tables
> - Removal of deprecated fact / amenity / marker / type tables after cutover
>
> **Estimated Effort**: Large
> **Parallel Execution**: YES - 3 main waves + final verification
> **Critical Path**: preflight audit -> additive schema -> deterministic backfill -> read-model cutover -> cleanup

---

## Context

### Original Request
Create a migration plan that simplifies the place schema so `places` becomes minimal and source-specific information moves into broad, aligned property tables. Remove the old Google/LLM amenity/fact/marker/type tables and add `place_user_properties` for user-submitted corrections.

### Interview Summary
**Key Discussions**:
- `places` must be minimal and non-redundant; it should not remain the canonical business-data projection.
- Geometry is intentionally removed from `places`; only `lat` / `lon` remain there.
- Source tables should use a broad column layout instead of key/value amenity facts for readability and performance.
- The common model must cover camping, overnight parking, attractions, museums, and similar POIs.
- `place_user_properties` should match the source-property schema and add `user_id` for corrections.

**Research Findings**:
- Current schema stores many business columns on `places` and projects them into `campsite_full`.
- Google and LLM currently use source-family tables and child tables that would be collapsed into wider property tables.
- Existing read paths such as `campsite_full` and `get_place_source_bundle` must be migrated before columns/tables are dropped.
- Metis recommends an expand-contract migration with explicit safety guardrails, deterministic mappings, and rollback points.

### Metis Review
**Identified Gaps** (addressed in this plan):
- Consumer impact must be audited before dropping fields from `places`.
- Geometry removal must be guarded by a dependency audit before cleanup.
- Backfills must preserve `NULL = no claim` semantics for source-specific booleans.
- Rollback checkpoints and validation queries must exist before destructive cleanup begins.

---

## Work Objectives

### Core Objective
Restructure the schema so source-derived place data lives in aligned `place_*_properties` tables while `places` shrinks to a minimal identity/location table. Execute the migration via additive expansion first, then cut reads over, then remove deprecated schema only after validation.

### Concrete Deliverables
- New schema tables: `place_osm_properties`, `place_google_properties`, `place_llm_properties`, `place_user_properties`
- Updated docs and generated types reflecting the new model
- Updated view / RPC plan for `campsite_full` and `get_place_source_bundle`
- Removal plan for deprecated tables and deprecated `places` columns

### Definition of Done
- [ ] All four property tables exist with aligned shared columns and source-specific metadata.
- [ ] Deterministic backfill rules exist for every migrated column and deprecated table.
- [ ] Read models no longer depend on removable business columns in `places`.
- [ ] Deprecated tables/columns are only removed after validation and rollback readiness.
- [ ] Schema docs and generated types reflect the final simplified model.

### Must Have
- Expand-contract rollout with additive migration before destructive cleanup
- Minimal `places` table with only `id`, `lat`, `lon`, `is_active`, `created_at`, `updated_at`
- One-current-row semantics for OSM/Google/LLM properties and one-current-row-per-user semantics for user properties
- Preservation of 1:n tables such as `place_google_reviews` and `place_google_photos`
- Default read-resolution priority for overlapping fields: user -> OSM -> Google -> LLM, unless consumer audit proves a required exception

### Must NOT Have (Guardrails)
- No direct destructive drop of existing `places` business columns in the first migration wave
- No implicit conversion of unknown source booleans into `false`
- No loss of existing read functionality for `campsite_full` / `get_place_source_bundle`
- No new JSONB key/value amenity blobs for standard properties
- No multi-concern tasks that mix additive schema creation with destructive cleanup in the same execution step

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** - verification must be executable by the worker using SQL, Supabase tooling, generated types, and schema docs checks.

### Test Decision
- **Infrastructure exists**: Partial schema validation only; no dedicated unit-test suite was detected in this repository.
- **Automated tests**: Tests-after / migration verification scripts
- **Framework**: SQL verification + type generation + schema doc checks
- **Default Applied**: Use migration verification commands and generated type checks instead of TDD

### QA Policy
Every task must include executable SQL or command-based verification. Evidence should be saved under `.sisyphus/evidence/`.

- **Schema verification**: `supabase db` / `psql` queries for tables, columns, indexes, row counts
- **Type verification**: regenerate `generated/database.types.ts` and confirm expected tables/columns
- **Read-model verification**: query updated views/RPCs and compare row counts / shape
- **Safety verification**: check for orphan rows, missing columns, and deprecated-object references

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately - audits, target contracts, additive design)
├── Task 1: Audit all consumers of existing `places` business columns [deep]
├── Task 2: Define final shared/source-specific property schema contract [deep]
├── Task 3: Design one-current-row constraints, indexes, and null semantics [quick]
├── Task 4: Map deprecated tables/columns to their target property columns [deep]
├── Task 5: Audit geometry/spatial dependencies before removing `geom` [unspecified-high]
└── Task 6: Design rollback, cutover, and evidence strategy [quick]

Wave 2 (After Wave 1 - additive schema + backfill plan)
├── Task 7: Create additive migration for all four property tables [unspecified-high]
├── Task 8: Design batched backfill for OSM data into `place_osm_properties` [deep]
├── Task 9: Design batched backfill for Google data into `place_google_properties` [deep]
├── Task 10: Design batched backfill for LLM data into `place_llm_properties` [deep]
├── Task 11: Design user-correction insertion model for `place_user_properties` [quick]
└── Task 12: Update docs/types migration plan for new tables and deprecated tables [writing]

Wave 3 (After Wave 2 - read cutover + cleanup)
├── Task 13: Redesign `campsite_full` to resolve data from property tables [deep]
├── Task 14: Redesign `get_place_source_bundle` and related RPC expectations [deep]
├── Task 15: Plan minimal-column cleanup for `places` [unspecified-high]
├── Task 16: Plan removal of deprecated tables after cutover validation [unspecified-high]
└── Task 17: Plan downstream sync and consumer migration sequence [writing]

Wave FINAL (After ALL tasks - 4 parallel reviews)
├── Task F1: Plan compliance audit (oracle)
├── Task F2: Schema-quality review (unspecified-high)
├── Task F3: Verification rehearsal review (unspecified-high)
└── Task F4: Scope fidelity check (deep)
```

### Dependency Matrix

- **1**: — -> 13, 14, 15, 16
- **2**: — -> 7, 8, 9, 10, 11, 13, 14
- **3**: — -> 7, 13, 14, 15, 16
- **4**: — -> 8, 9, 10, 15, 16
- **5**: — -> 15
- **6**: — -> 15, 16, 17
- **7**: 2, 3 -> 8, 9, 10, 11, 12, 13, 14
- **8**: 2, 4, 7 -> 13, 15
- **9**: 2, 4, 7 -> 13, 14, 15
- **10**: 2, 4, 7 -> 13, 14, 15
- **11**: 2, 7 -> 13, 17
- **12**: 7 -> 17
- **13**: 1, 2, 3, 7, 8, 9, 10, 11 -> 15, 16, 17
- **14**: 1, 2, 3, 7, 9, 10 -> 15, 16, 17
- **15**: 1, 3, 4, 5, 6, 8, 9, 10, 13, 14 -> 16
- **16**: 1, 3, 4, 6, 13, 14, 15 -> 17
- **17**: 6, 11, 12, 13, 14, 16 -> FINAL

### Agent Dispatch Summary

- **Wave 1**: T1 `deep`, T2 `deep`, T3 `quick`, T4 `deep`, T5 `unspecified-high`, T6 `quick`
- **Wave 2**: T7 `unspecified-high`, T8-T10 `deep`, T11 `quick`, T12 `writing`
- **Wave 3**: T13-T14 `deep`, T15-T16 `unspecified-high`, T17 `writing`
- **FINAL**: F1 `oracle`, F2 `unspecified-high`, F3 `unspecified-high`, F4 `deep`

---

## TODOs

- [x] 1. Audit all consumers of existing `places` business columns

  **What to do**:
  - Inventory every view, RPC, migration, generated type, and downstream consumer that reads columns planned for removal from `places`.
  - Produce a dependency list covering at minimum `campsite_full`, `get_place_source_bundle`, docs, generated types, and downstream sync expectations.

  **Must NOT do**:
  - Do not remove columns or update the schema yet.
  - Do not assume only this repository reads deprecated columns.

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: requires cross-artifact dependency mapping and breakage analysis.
  - **Skills**: `[]`
  - **Skills Evaluated but Omitted**:
    - `playwright`: no browser work involved.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 2-6)
  - **Blocks**: 13, 14, 15, 16
  - **Blocked By**: None

  **References**:
  - `docs/database-schema.md` - current documented shape of `places`, source-family tables, and views.
  - `supabase/migrations/20260314221355_fix_campsite_full_required_fields_and_amenities.sql` - current `campsite_full` dependency on `places` business columns.
  - `supabase/migrations/20260318_fix_get_place_source_bundle_signature.sql` - current RPC dependency on `places`, `osm_source`, `place_llm_enrichments`, and `place_google_sources`.
  - `generated/database.types.ts` - generated public contract that will change after migration.

  **Acceptance Criteria**:
  - [ ] A complete dependency inventory exists for every `places` field planned for removal.
  - [ ] The plan explicitly lists which read models must be redesigned before cleanup.

  **QA Scenarios**:
  ```text
  Scenario: Deprecated column dependency inventory completes
    Tool: Bash (grep)
    Preconditions: Repository checkout is searchable
    Steps:
      1. Search for representative deprecated columns such as `has_wifi`, `source_primary`, `place_type`, and `website`.
      2. Capture every matching schema/doc/generated-type reference.
      3. Compare matches against the dependency list produced for the task.
    Expected Result: Every match is accounted for in the inventory or explicitly excluded with rationale.
    Failure Indicators: Unexplained matches remain outside the inventory.
    Evidence: .sisyphus/evidence/task-1-dependency-audit.txt

  Scenario: RPC/view breakpoints are identified
    Tool: Bash (grep)
    Preconditions: Inventory draft exists
    Steps:
      1. Search for `campsite_full` and `get_place_source_bundle` in migrations/docs.
      2. Confirm the task output names both as migration dependencies.
    Expected Result: Both read models are explicitly flagged for cutover work.
    Failure Indicators: Either read model is missing from the dependency list.
    Evidence: .sisyphus/evidence/task-1-read-model-breakpoints.txt
  ```

  **Commit**: NO

- [x] 2. Define the final shared and source-specific property schema contract

  **What to do**:
  - Freeze the shared column set for all four `place_*_properties` tables.
  - Freeze the source-specific columns for OSM, Google, LLM, and user corrections.
  - Define naming and semantic rules for all boolean/property columns.

  **Must NOT do**:
  - Do not reintroduce business redundancy into `places`.
  - Do not add generic JSONB blobs for standard fields.

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: this task establishes the core data contract that all later tasks depend on.
  - **Skills**: `[]`
  - **Skills Evaluated but Omitted**:
    - `writing`: the task is schema design first, documentation second.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 3-6)
  - **Blocks**: 7, 8, 9, 10, 11, 13, 14
  - **Blocked By**: None

  **References**:
  - `.sisyphus/drafts/place-properties-migration.md` - confirmed target design and final shared property field set.
  - `docs/database-schema.md` - current source-family and amenity-facts patterns that this migration replaces.
  - `generated/database.types.ts` - current place/google/llm table shapes that inform the new aligned schema.

  **Acceptance Criteria**:
  - [ ] Shared columns are fixed once and reused across all four property tables.
  - [ ] Source-specific columns are listed separately for OSM, Google, LLM, and user properties.
  - [ ] Boolean semantics (`NULL` vs `false`) are explicitly documented.

  **QA Scenarios**:
  ```text
  Scenario: Shared property contract is complete
    Tool: Bash (grep)
    Preconditions: Contract document or migration draft exists
    Steps:
      1. Verify the shared field set includes identity, address, contact, general facilities, camping facilities, disposal fields, nudism flags, and attraction flags.
      2. Verify each source-specific table definition references the shared set plus only its own extra fields.
    Expected Result: No agreed field is missing from the target contract.
    Failure Indicators: Shared fields differ between property tables without an explicit reason.
    Evidence: .sisyphus/evidence/task-2-schema-contract.txt

  Scenario: Minimal `places` contract remains minimal
    Tool: Bash (grep)
    Preconditions: Target schema contract exists
    Steps:
      1. Inspect the target `places` definition.
      2. Confirm only `id`, `lat`, `lon`, `is_active`, `created_at`, and `updated_at` remain.
    Expected Result: No business columns remain on `places`.
    Failure Indicators: Any contact, address, type, amenity, or confidence column persists in the target contract.
    Evidence: .sisyphus/evidence/task-2-minimal-places.txt
  ```

  **Commit**: NO

- [x] 3. Design one-current-row constraints, indexes, and null semantics

  **What to do**:
  - Specify unique-current-row constraints for OSM/Google/LLM and per-user current rows for user properties.
  - Specify mandatory indexes for `place_id`, current-row lookups, and source-specific identifiers.
  - Document that booleans default to `NULL` to preserve no-claim semantics.

  **Must NOT do**:
  - Do not default source-property booleans to `false`.
  - Do not leave current-row semantics implicit.

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: focused schema-constraint design with limited surface area.
  - **Skills**: `[]`
  - **Skills Evaluated but Omitted**:
    - `oracle`: not needed unless constraint strategy becomes contentious.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 4-6)
  - **Blocks**: 7, 13, 14, 15, 16
  - **Blocked By**: None

  **References**:
  - `supabase/migrations/20260317210003_source_family_constraints.sql` - current partial-index/current-row patterns.
  - `supabase/migrations/20260316110002_add_source_family_tables.sql` - current source-family parent relationships.

  **Acceptance Criteria**:
  - [ ] OSM/Google/LLM current-row constraints are explicitly defined.
  - [ ] User current-row constraint is explicitly defined on (`place_id`, `user_id`).
  - [ ] Index plan exists for primary query paths and source identifiers.

  **QA Scenarios**:
  ```text
  Scenario: Current-row semantics are enforceable
    Tool: Bash (grep)
    Preconditions: Constraint draft exists
    Steps:
      1. Inspect the plan for partial unique index definitions or equivalent constraint language.
      2. Confirm OSM/Google/LLM use one current row per `place_id` and user properties use one current row per (`place_id`,`user_id`).
    Expected Result: Every property table has explicit current-row enforcement.
    Failure Indicators: Any property table lacks clear enforcement rules.
    Evidence: .sisyphus/evidence/task-3-current-row-rules.txt

  Scenario: Null semantics are preserved
    Tool: Bash (grep)
    Preconditions: Constraint draft exists
    Steps:
      1. Search the plan for boolean default semantics.
      2. Confirm it states `NULL = source made no claim` and rejects `DEFAULT false`.
    Expected Result: Source-property booleans are documented with no-claim semantics.
    Failure Indicators: Boolean defaults are ambiguous or set to `false`.
    Evidence: .sisyphus/evidence/task-3-null-semantics.txt
  ```

  **Commit**: NO

- [x] 4. Map every deprecated table and `places` column to a deterministic target field

  **What to do**:
  - Build the authoritative mapping from old columns/tables into the new property tables.
  - Cover `places` business fields, `place_google_amenities`, `place_google_types`, `place_llm_facts`, `place_llm_sources`, and other removed structures.
  - Flag any field with no clean target and define the migration decision.

  **Must NOT do**:
  - Do not leave any dropped field without a target, archive decision, or explicit discard rationale.
  - Do not use undocumented implicit mappings.

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: requires deterministic source-to-target mapping across multiple old schemas.
  - **Skills**: `[]`
  - **Skills Evaluated but Omitted**:
    - `writing`: mapping correctness matters more than prose polish.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1-3, 5-6)
  - **Blocks**: 8, 9, 10, 15, 16
  - **Blocked By**: None

  **References**:
  - `docs/database-schema.md` - current column inventory for `places`, Google, and LLM tables.
  - `generated/database.types.ts` - generated field-level source of truth for current columns.
  - `supabase/migrations/20260316000001_add_google_amenities_table.sql` - Google amenity keys and source metadata.
  - `supabase/migrations/20260316110002_add_source_family_tables.sql` - current LLM facts/source table structure.

  **Acceptance Criteria**:
  - [ ] Every deprecated field/table is mapped to a target column, retained raw table, archive strategy, or explicit discard decision.
  - [ ] Google type and amenity mappings are deterministic.
  - [ ] LLM source URL and trust data mappings are deterministic.

  **QA Scenarios**:
  ```text
  Scenario: Deprecated object mapping is complete
    Tool: Bash (grep)
    Preconditions: Mapping matrix exists
    Steps:
      1. List all deprecated tables and removed `places` business columns.
      2. Compare the list to the mapping matrix.
      3. Confirm every source object has an explicit target or discard note.
    Expected Result: No deprecated object lacks a deterministic plan.
    Failure Indicators: Any removed field/table is unaccounted for.
    Evidence: .sisyphus/evidence/task-4-mapping-matrix.txt

  Scenario: LLM and Google reductions preserve needed meaning
    Tool: Bash (grep)
    Preconditions: Mapping matrix exists
    Steps:
      1. Inspect mappings for `place_google_types`, `place_google_amenities`, `place_llm_facts`, and `place_llm_sources`.
      2. Confirm their meaning is preserved in target columns such as `source_categories`, boolean flags, `trust_score`, and `source_urls`.
    Expected Result: Target fields preserve the agreed business meaning.
    Failure Indicators: Source meaning is collapsed without a replacement field.
    Evidence: .sisyphus/evidence/task-4-source-meaning.txt
  ```

  **Commit**: NO

- [x] 5. Audit geometry and spatial dependencies before removing `geom`

  **What to do**:
  - Search for all schema/docs/generated-type references to `geom` and PostGIS-dependent logic.
  - Confirm whether any remaining workflow requires geometry after `places.geom` is removed.
  - If geometry remains necessary, move the requirement to a source/raw table and keep it out of minimal `places`.

  **Must NOT do**:
  - Do not drop `geom` blindly without proving no active dependency remains.
  - Do not reintroduce geometry to minimal `places` as a convenience field.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: spatial impact can break search and data contracts if missed.
  - **Skills**: `[]`
  - **Skills Evaluated but Omitted**:
    - `oracle`: reserve for final review, not initial dependency auditing.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1-4, 6)
  - **Blocks**: 15
  - **Blocked By**: None

  **References**:
  - `docs/database-schema.md` - current `places.geom` and `osm_source.geom` documentation.
  - `generated/database.types.ts` - generated type exposure of geometry fields.
  - `docs/er-diagram.md` - documented place/source geometry relationships.

  **Acceptance Criteria**:
  - [ ] All `geom` dependencies are inventoried.
  - [ ] The cleanup phase contains an explicit geometry-removal guardrail.

  **QA Scenarios**:
  ```text
  Scenario: Geometry dependency search completes
    Tool: Bash (grep)
    Preconditions: Repository checkout is searchable
    Steps:
      1. Search for `geom`, `geometry`, and common `ST_` function names.
      2. Compare matches against the geometry dependency report.
    Expected Result: Every spatial dependency is listed or explicitly dismissed.
    Failure Indicators: Search results show undocumented geometry usage.
    Evidence: .sisyphus/evidence/task-5-geometry-audit.txt

  Scenario: Minimal `places` remains geometry-free
    Tool: Bash (grep)
    Preconditions: Cleanup plan draft exists
    Steps:
      1. Inspect the cleanup phase for `places` column retention.
      2. Confirm `geom` is absent and any retained spatial data lives elsewhere.
    Expected Result: `places` stays minimal without silent geometry carryover.
    Failure Indicators: The plan keeps `geom` in `places` without an explicit reversal decision.
    Evidence: .sisyphus/evidence/task-5-places-geometry-check.txt
  ```

  **Commit**: NO

- [x] 6. Design rollback checkpoints, lock safety, and migration evidence policy

  **What to do**:
  - Define expand-contract phases, rollback checkpoints, and evidence requirements before destructive cleanup.
  - Require lock-safe execution notes for DDL, phased backfill checkpoints, and proof of cutover readiness.
  - Define what evidence must exist before cleanup tasks can proceed.

  **Must NOT do**:
  - Do not allow additive and destructive steps in the same execution window without rollback checkpoints.
  - Do not rely on manual memory instead of explicit evidence artifacts.

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: focused operational policy task anchored by metis findings.
  - **Skills**: `[]`
  - **Skills Evaluated but Omitted**:
    - `writing`: useful but not necessary for the core operational structure.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1-5)
  - **Blocks**: 15, 16, 17
  - **Blocked By**: None

  **References**:
  - `.sisyphus/drafts/place-properties-migration.md` - metis findings already recorded.
  - `docs/worker-schema-migration-guide.md` - repository migration coordination context.

  **Acceptance Criteria**:
  - [ ] The plan names additive, transition, and cleanup checkpoints.
  - [ ] Cleanup is blocked on explicit evidence and validation conditions.
  - [ ] Rollback triggers are explicitly documented.

  **QA Scenarios**:
  ```text
  Scenario: Expand-contract checkpoints are explicit
    Tool: Bash (grep)
    Preconditions: Plan draft exists
    Steps:
      1. Search the plan for additive, transition, and cleanup checkpoints.
      2. Confirm each destructive step references a preceding validation gate.
    Expected Result: No cleanup action appears before its validation gate.
    Failure Indicators: Cleanup steps lack blocking conditions.
    Evidence: .sisyphus/evidence/task-6-checkpoints.txt

  Scenario: Rollback conditions are actionable
    Tool: Bash (grep)
    Preconditions: Rollback section exists
    Steps:
      1. Inspect rollback language for concrete abort triggers and rollback windows.
      2. Confirm evidence requirements are named before proceeding to destructive work.
    Expected Result: Rollback can be triggered by objective criteria.
    Failure Indicators: Rollback wording is vague or lacks evidence prerequisites.
    Evidence: .sisyphus/evidence/task-6-rollback-rules.txt
  ```

  **Commit**: NO

- [x] 7. Create the additive migration design for all four property tables

  **What to do**:
  - Specify the additive migration that creates `place_osm_properties`, `place_google_properties`, `place_llm_properties`, and `place_user_properties`.
  - Include aligned shared columns, source-specific columns, FK behavior, timestamps, and current-row support.
  - Keep this phase additive only; no legacy objects are dropped here.

  **Must NOT do**:
  - Do not remove columns from `places` in this task.
  - Do not drop deprecated tables in this task.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: additive schema scaffold is large and foundational.
  - **Skills**: `[]`
  - **Skills Evaluated but Omitted**:
    - `deep`: helpful, but this task is primarily structured DDL planning once the contract is frozen.

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential start of Wave 2
  - **Blocks**: 8, 9, 10, 11, 12, 13, 14
  - **Blocked By**: 2, 3

  **References**:
  - `.sisyphus/drafts/place-properties-migration.md` - agreed target schema.
  - `supabase/migrations/20260316110002_add_source_family_tables.sql` - current style for source-family table creation and FKs.
  - `supabase/migrations/20260316000001_add_google_amenities_table.sql` - current Google amenity structure being replaced.

  **Acceptance Criteria**:
  - [ ] All four additive table definitions exist in the migration plan.
  - [ ] Shared columns are aligned and source-specific columns are correctly separated.
  - [ ] No destructive action appears in this additive phase.

  **QA Scenarios**:
  ```text
  Scenario: Additive schema migration defines all four property tables
    Tool: Bash (grep)
    Preconditions: Additive migration draft exists
    Steps:
      1. Inspect the draft for all four `place_*_properties` table definitions.
      2. Confirm each includes timestamps, `place_id`, and current-row fields.
    Expected Result: All four tables are present and structurally aligned.
    Failure Indicators: Any target table is missing or structurally divergent without reason.
    Evidence: .sisyphus/evidence/task-7-additive-tables.txt

  Scenario: Additive phase remains non-breaking
    Tool: Bash (grep)
    Preconditions: Additive migration draft exists
    Steps:
      1. Search the draft for destructive SQL verbs affecting legacy objects.
      2. Confirm cleanup statements are absent from the additive migration.
    Expected Result: Phase 1 contains no drops of legacy tables or columns.
    Failure Indicators: `DROP` or destructive `ALTER TABLE ... DROP COLUMN` statements appear in the additive phase.
    Evidence: .sisyphus/evidence/task-7-nonbreaking-check.txt
  ```

  **Commit**: YES
  - Message: `feat(schema): add property tables scaffold`
  - Files: `supabase/migrations/*`, `docs/database-schema.md`, `generated/database.types.ts`
  - Pre-commit: `supabase db reset && supabase gen types typescript --local > generated/database.types.ts`

- [x] 8. Design batched backfill from current `places` and `osm_source` into `place_osm_properties`

  **What to do**:
  - Define the row source, precedence, and field-level mappings for OSM properties.
  - Backfill current shared business data from legacy `places` plus OSM metadata from `osm_source`.
  - Preserve `NULL` semantics and current-row behavior.

  **Must NOT do**:
  - Do not assume every place has an OSM source row.
  - Do not convert missing OSM claims into `false`.

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: this task requires deterministic field mapping and edge-case handling.
  - **Skills**: `[]`
  - **Skills Evaluated but Omitted**:
    - `quick`: insufficient for the number of mapping decisions involved.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 9-12 after Task 7)
  - **Blocks**: 13, 15
  - **Blocked By**: 2, 4, 7

  **References**:
  - `docs/database-schema.md` - current `places` and `osm_source` columns.
  - `generated/database.types.ts` - current typed shape for the same tables.

  **Acceptance Criteria**:
  - [ ] Every `place_osm_properties` field has a deterministic source.
  - [ ] Places without current OSM rows have an explicit handling rule.
  - [ ] Batched backfill and validation checks are documented.

  **QA Scenarios**:
  ```text
  Scenario: OSM backfill mapping covers every target column
    Tool: Bash (grep)
    Preconditions: OSM backfill plan exists
    Steps:
      1. Compare the `place_osm_properties` target columns against the OSM mapping section.
      2. Confirm each target column has a source field, transform rule, or explicit `NULL` policy.
    Expected Result: The mapping table is complete.
    Failure Indicators: Any target field lacks an OSM backfill rule.
    Evidence: .sisyphus/evidence/task-8-osm-mapping.txt

  Scenario: No-OSM-source edge case is handled
    Tool: Bash (grep)
    Preconditions: OSM backfill plan exists
    Steps:
      1. Inspect the edge-case section for places without a current `osm_source` row.
      2. Confirm the plan keeps the migration valid without inventing false claims.
    Expected Result: The edge case has an explicit fallback strategy.
    Failure Indicators: The plan assumes every place has current OSM source data.
    Evidence: .sisyphus/evidence/task-8-no-osm-edgecase.txt
  ```

  **Commit**: NO

- [x] 9. Design batched backfill from Google source tables into `place_google_properties`

  **What to do**:
  - Map `place_google_sources`, `place_google_amenities`, and `place_google_types` into the wide Google property table.
  - Define deterministic transforms for categories, booleans, ratings, and expiry fields.
  - Keep Google reviews/photos out of the wide property table.

  **Must NOT do**:
  - Do not collapse Google review/photo child tables into the property row.
  - Do not lose amenity/type meaning during flattening.

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: flattening Google source families into one wide table needs deterministic meaning-preserving mapping.
  - **Skills**: `[]`
  - **Skills Evaluated but Omitted**:
    - `writing`: the core challenge is mapping correctness.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 8, 10-12 after Task 7)
  - **Blocks**: 13, 14, 15
  - **Blocked By**: 2, 4, 7

  **References**:
  - `supabase/migrations/20260316110002_add_source_family_tables.sql` - current Google source table shape.
  - `supabase/migrations/20260316000001_add_google_amenities_table.sql` - current Google amenity fact model.
  - `docs/database-schema.md` - documented Google source child tables and current columns.

  **Acceptance Criteria**:
  - [ ] Google source, amenity, and type data are all mapped to target columns without ambiguity.
  - [ ] Reviews/photos are explicitly retained outside `place_google_properties`.
  - [ ] Google current-row and expiry semantics are preserved.

  **QA Scenarios**:
  ```text
  Scenario: Google flattening preserves categories and amenities
    Tool: Bash (grep)
    Preconditions: Google backfill plan exists
    Steps:
      1. Compare Google source/type/amenity inputs against the Google property target fields.
      2. Confirm `source_categories`, `source_place_type`, amenity booleans, and metadata fields all have mapping rules.
    Expected Result: No Google meaning is lost when child tables are flattened.
    Failure Indicators: Any input category/type/amenity lacks a target representation.
    Evidence: .sisyphus/evidence/task-9-google-mapping.txt

  Scenario: Reviews/photos remain 1:n tables
    Tool: Bash (grep)
    Preconditions: Google backfill plan exists
    Steps:
      1. Inspect the Google migration section for retained child tables.
      2. Confirm `place_google_reviews` and `place_google_photos` remain outside the wide property table.
    Expected Result: 1:n Google child tables are preserved.
    Failure Indicators: Reviews or photos are incorrectly folded into `place_google_properties`.
    Evidence: .sisyphus/evidence/task-9-google-children.txt
  ```

  **Commit**: NO

- [x] 10. Design batched backfill from LLM tables into `place_llm_properties`

  **What to do**:
  - Map `place_llm_enrichments`, `place_llm_facts`, and `place_llm_sources` into the wide LLM property table.
  - Preserve provider/model/summary/trust information and flatten URLs into `source_urls`.
  - Decide how current enrichment rows map to current LLM property rows.

  **Must NOT do**:
  - Do not lose trust/source provenance agreed for the simplified model.
  - Do not preserve obsolete LLM child tables after their data has a target home.

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: LLM flattening combines process metadata, facts, and provenance into one target row.
  - **Skills**: `[]`
  - **Skills Evaluated but Omitted**:
    - `quick`: too many coupled mapping rules.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 8, 9, 11-12 after Task 7)
  - **Blocks**: 13, 14, 15
  - **Blocked By**: 2, 4, 7

  **References**:
  - `supabase/migrations/20260316110002_add_source_family_tables.sql` - current LLM enrichment/fact/source structures.
  - `docs/database-schema.md` - documented LLM enrichment child tables.

  **Acceptance Criteria**:
  - [ ] All LLM property-relevant facts have a deterministic destination column.
  - [ ] `trust_score` and `source_urls` are clearly derived.
  - [ ] Current-row selection from existing LLM enrichments is explicitly defined.

  **QA Scenarios**:
  ```text
  Scenario: LLM flattening preserves property and trust fields
    Tool: Bash (grep)
    Preconditions: LLM backfill plan exists
    Steps:
      1. Compare `place_llm_enrichments`, `place_llm_facts`, and `place_llm_sources` inputs against `place_llm_properties` target fields.
      2. Confirm provider/model/summary/trust/source-URL data all have deterministic mappings.
    Expected Result: LLM simplification preserves the agreed target information.
    Failure Indicators: Trust or source URL data has no explicit target.
    Evidence: .sisyphus/evidence/task-10-llm-mapping.txt

  Scenario: Current enrichment selection is explicit
    Tool: Bash (grep)
    Preconditions: LLM backfill plan exists
    Steps:
      1. Inspect the plan for `is_current` handling.
      2. Confirm the plan states how a single current LLM property row is chosen per place.
    Expected Result: There is one deterministic rule for current LLM property rows.
    Failure Indicators: Current-row selection is ambiguous.
    Evidence: .sisyphus/evidence/task-10-llm-current-row.txt
  ```

  **Commit**: NO

- [x] 11. Define the user correction model for `place_user_properties`

  **What to do**:
  - Specify how user-submitted corrections are stored, versioned as current, and linked to `profiles`.
  - Define the one-current-row-per-(`place_id`,`user_id`) rule.
  - Define how user rows participate in downstream read resolution without bloating `places`.

  **Must NOT do**:
  - Do not make `place_user_properties` structurally different from the shared property schema except for `user_id`.
  - Do not push resolved user corrections back into `places` as redundant business columns.

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: focused modeling task with clear constraints once the shared schema is frozen.
  - **Skills**: `[]`
  - **Skills Evaluated but Omitted**:
    - `deep`: not necessary unless conflict-resolution scope expands.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 8-10, 12 after Task 7)
  - **Blocks**: 13, 17
  - **Blocked By**: 2, 7

  **References**:
  - `docs/database-schema.md` - `profiles` ownership and current user-facing place tables.
  - `.sisyphus/drafts/place-properties-migration.md` - agreed user-correction requirement.

  **Acceptance Criteria**:
  - [ ] `place_user_properties` matches the shared property schema plus `user_id`.
  - [ ] Current-row rules per (`place_id`,`user_id`) are explicit.
  - [ ] Read-resolution responsibilities are documented without re-bloating `places`.

  **QA Scenarios**:
  ```text
  Scenario: User property schema aligns with shared contract
    Tool: Bash (grep)
    Preconditions: User property design exists
    Steps:
      1. Compare the shared property field list with `place_user_properties`.
      2. Confirm the only required extra field is `user_id` plus standard metadata/current-row fields.
    Expected Result: User properties are aligned with the shared contract.
    Failure Indicators: User properties diverge unexpectedly from the shared schema.
    Evidence: .sisyphus/evidence/task-11-user-schema.txt

  Scenario: Current user correction semantics are explicit
    Tool: Bash (grep)
    Preconditions: User property design exists
    Steps:
      1. Inspect the plan for the (`place_id`,`user_id`) uniqueness rule.
      2. Confirm outdated rows can be superseded without violating current-row semantics.
    Expected Result: User correction current-row behavior is fully specified.
    Failure Indicators: No clear rule exists for multiple corrections by the same user.
    Evidence: .sisyphus/evidence/task-11-user-current-row.txt
  ```

  **Commit**: NO

- [x] 12. Update documentation and generated type migration strategy

  **What to do**:
  - Plan all doc updates required in `docs/database-schema.md`, `docs/er-diagram.md`, and related migration guidance.
  - Plan type regeneration and downstream sync steps after additive changes and after cleanup.
  - Explicitly document deprecated tables and cleanup timing.

  **Must NOT do**:
  - Do not leave docs/types updates until after destructive cleanup.
  - Do not describe dropped tables as current once the additive phase lands.

  **Recommended Agent Profile**:
  - **Category**: `writing`
    - Reason: documentation/type handoff clarity is the core outcome.
  - **Skills**: `[]`
  - **Skills Evaluated but Omitted**:
    - `deep`: the design inputs come from prior tasks; this is now communication and contract work.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 8-11 after Task 7)
  - **Blocks**: 17
  - **Blocked By**: 7

  **References**:
  - `docs/database-schema.md` - canonical schema doc to update.
  - `docs/er-diagram.md` - relationship diagram to update.
  - `generated/database.types.ts` - generated contract to refresh.
  - `AGENTS.md` - schema-repo ownership and downstream sync rules.

  **Acceptance Criteria**:
  - [ ] Doc updates are planned for every schema phase.
  - [ ] Type regeneration and downstream sync steps are explicitly sequenced.
  - [ ] Deprecated-table documentation is explicit during the transition period.

  **QA Scenarios**:
  ```text
  Scenario: Documentation update scope is complete
    Tool: Bash (grep)
    Preconditions: Documentation migration strategy exists
    Steps:
      1. Inspect the plan for `database-schema`, `er-diagram`, and migration-guide update steps.
      2. Confirm each schema phase has matching documentation actions.
    Expected Result: No schema phase lacks its corresponding documentation update.
    Failure Indicators: Any changed schema object lacks doc-update coverage.
    Evidence: .sisyphus/evidence/task-12-doc-scope.txt

  Scenario: Type regeneration and sync sequence is explicit
    Tool: Bash (grep)
    Preconditions: Type migration strategy exists
    Steps:
      1. Search the plan for type generation and downstream sync actions.
      2. Confirm additive and cleanup phases both address type contract changes.
    Expected Result: Consumer type updates are fully sequenced.
    Failure Indicators: Type regeneration is missing or only partially covered.
    Evidence: .sisyphus/evidence/task-12-type-sync.txt
  ```

  **Commit**: YES
  - Message: `docs(schema): document property-table migration`
  - Files: `docs/database-schema.md`, `docs/er-diagram.md`, `generated/database.types.ts`
  - Pre-commit: `supabase gen types typescript --local > generated/database.types.ts`

- [x] 13. Redesign `campsite_full` to resolve data from property tables instead of `places`

  **What to do**:
  - Define the new read-model inputs for `campsite_full` using `place_*_properties` tables plus retained 1:n tables.
  - Define deterministic resolution priority for overlapping fields in the view.
  - Preserve expected output shape while removing dependency on deprecated `places` business columns.

  **Must NOT do**:
  - Do not keep `campsite_full` coupled to removable `places` business fields.
  - Do not let the view silently invent defaults for missing source claims.

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: this is the main read-model cutover and requires careful cross-source resolution.
  - **Skills**: `[]`
  - **Skills Evaluated but Omitted**:
    - `writing`: this is logic and contract design, not just prose.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 14-17 after Wave 2)
  - **Blocks**: 15, 16, 17
  - **Blocked By**: 1, 2, 3, 7, 8, 9, 10, 11

  **References**:
  - `supabase/migrations/20260314221355_fix_campsite_full_required_fields_and_amenities.sql` - current view definition to replace.
  - `docs/database-schema.md` - current documented view contract.

  **Acceptance Criteria**:
  - [ ] The view no longer depends on deprecated `places` business columns.
  - [ ] Resolution priority is explicit for overlapping fields.
  - [ ] View output compatibility expectations are documented.

  **QA Scenarios**:
  ```text
  Scenario: `campsite_full` no longer reads deprecated place columns
    Tool: Bash (grep)
    Preconditions: Updated view draft exists
    Steps:
      1. Inspect the redesigned view definition.
      2. Confirm business fields are sourced from property tables rather than legacy `places` columns.
    Expected Result: The view is cut over to the new source-property model.
    Failure Indicators: Deprecated `places` fields still power the view.
    Evidence: .sisyphus/evidence/task-13-view-cutover.txt

  Scenario: Field-resolution priority is deterministic
    Tool: Bash (grep)
    Preconditions: Updated view draft exists
    Steps:
      1. Inspect the view-resolution notes for overlapping fields like `name`, `website`, `opening_hours`, and amenity booleans.
      2. Confirm a single priority order is used consistently.
    Expected Result: Overlapping fields resolve deterministically.
    Failure Indicators: Resolution order is missing or inconsistent.
    Evidence: .sisyphus/evidence/task-13-resolution-order.txt
  ```

  **Commit**: YES
  - Message: `refactor(schema): move campsite_full to property tables`
  - Files: `supabase/migrations/*`, `docs/database-schema.md`, `generated/database.types.ts`
  - Pre-commit: `supabase db reset && supabase gen types typescript --local > generated/database.types.ts`

- [x] 14. Redesign `get_place_source_bundle` and related RPC expectations

  **What to do**:
  - Update the source-bundle contract so it returns minimal `places` plus the new property tables.
  - Decide which legacy tables still appear in the bundle and which are replaced by property rows.
  - Align documentation and expected JSON keys with the new target state.

  **Must NOT do**:
  - Do not leave the RPC returning deprecated child-table structures after their replacement is defined.
  - Do not let the RPC depend on removed `places` business columns.

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: RPC contract changes affect every consumer of the source bundle.
  - **Skills**: `[]`
  - **Skills Evaluated but Omitted**:
    - `quick`: contract redesign is too broad for a quick-pass task.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 13, 15-17 after Wave 2)
  - **Blocks**: 15, 16, 17
  - **Blocked By**: 1, 2, 3, 7, 9, 10

  **References**:
  - `supabase/migrations/20260318_fix_get_place_source_bundle_signature.sql` - current RPC contract.
  - `supabase/migrations/20260317210002_source_bundle_rpc.sql` - source-bundle intent and keys.

  **Acceptance Criteria**:
  - [ ] The RPC contract names the new property tables as sources.
  - [ ] Deprecated Google/LLM child-table structures are removed from the bundle where replaced.
  - [ ] Bundle output remains documented and machine-verifiable.

  **QA Scenarios**:
  ```text
  Scenario: Source bundle returns new property families
    Tool: Bash (grep)
    Preconditions: Updated RPC draft exists
    Steps:
      1. Inspect the target RPC contract.
      2. Confirm it returns minimal `places` plus the new property rows instead of deprecated substructures.
    Expected Result: The source bundle reflects the new schema model.
    Failure Indicators: The bundle still centers deprecated tables or removed `places` fields.
    Evidence: .sisyphus/evidence/task-14-bundle-contract.txt

  Scenario: RPC docs match the target JSON shape
    Tool: Bash (grep)
    Preconditions: Updated RPC doc notes exist
    Steps:
      1. Compare the documented JSON keys to the planned RPC output.
      2. Confirm renamed/removed source tables are reflected in the docs.
    Expected Result: Docs and RPC contract agree exactly.
    Failure Indicators: Docs still mention removed tables or missing new keys.
    Evidence: .sisyphus/evidence/task-14-bundle-docs.txt
  ```

  **Commit**: YES
  - Message: `refactor(schema): update source bundle for property tables`
  - Files: `supabase/migrations/*`, `docs/database-schema.md`, `generated/database.types.ts`
  - Pre-commit: `supabase db reset && supabase gen types typescript --local > generated/database.types.ts`

- [x] 15. Plan cleanup of `places` down to its minimal final shape

  **What to do**:
  - Sequence the removal of deprecated `places` business columns after cutover validation.
  - Confirm `places` ends with only `id`, `lat`, `lon`, `is_active`, `created_at`, `updated_at`.
  - Include geometry-removal safeguards and post-cutover validation requirements.

  **Must NOT do**:
  - Do not schedule column drops before read cutover is verified.
  - Do not keep convenience duplicates in `places` once source-property reads are live.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: destructive cleanup is high-risk and depends on many prior validations.
  - **Skills**: `[]`
  - **Skills Evaluated but Omitted**:
    - `quick`: destructive cleanup sequencing needs more rigor than a quick change.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 13, 14, 16-17 after Wave 2)
  - **Blocks**: 16
  - **Blocked By**: 1, 3, 4, 5, 6, 8, 9, 10, 13, 14

  **References**:
  - `docs/database-schema.md` - current `places` schema and target cleanup delta.
  - `generated/database.types.ts` - current field inventory that will shrink.

  **Acceptance Criteria**:
  - [ ] Cleanup removes all agreed deprecated columns and nothing else.
  - [ ] Cleanup is explicitly gated on read-model validation and rollback readiness.
  - [ ] Final `places` schema matches the minimal target exactly.

  **QA Scenarios**:
  ```text
  Scenario: Final `places` schema is minimal and exact
    Tool: Bash (grep)
    Preconditions: Cleanup draft exists
    Steps:
      1. Inspect the final `places` column list in the cleanup section.
      2. Compare it against the agreed minimal target.
    Expected Result: Only the six agreed columns remain.
    Failure Indicators: Extra business columns remain or required minimal columns are missing.
    Evidence: .sisyphus/evidence/task-15-final-places.txt

  Scenario: Cleanup is blocked on cutover validation
    Tool: Bash (grep)
    Preconditions: Cleanup draft exists
    Steps:
      1. Inspect the cleanup prerequisites.
      2. Confirm they require validated cutover of views/RPCs and rollback readiness.
    Expected Result: Destructive cleanup cannot proceed without objective readiness evidence.
    Failure Indicators: The plan permits dropping columns without validation gates.
    Evidence: .sisyphus/evidence/task-15-cleanup-gates.txt
  ```

  **Commit**: YES
  - Message: `chore(schema): slim places after property cutover`
  - Files: `supabase/migrations/*`, `docs/database-schema.md`, `generated/database.types.ts`
  - Pre-commit: `supabase db reset && supabase gen types typescript --local > generated/database.types.ts`

- [x] 16. Plan removal of deprecated tables after cutover validation

  **What to do**:
  - Sequence the removal of deprecated tables only after backfills and read cutovers are verified.
  - Cover `place_google_amenities`, `place_google_types`, `place_llm_facts`, `place_llm_sources`, `place_llm_evidence_markers`, and `place_source_evidence_runs`.
  - Define any archive/no-archive decisions before final drop.

  **Must NOT do**:
  - Do not drop deprecated tables while their data is still the only source of truth.
  - Do not remove tables without proving their target fields are populated and read paths are cut over.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: destructive table cleanup is the highest-risk schema contraction step.
  - **Skills**: `[]`
  - **Skills Evaluated but Omitted**:
    - `oracle`: use in final verification instead of initial cleanup planning.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 13-15, 17 after Wave 2)
  - **Blocks**: 17
  - **Blocked By**: 1, 3, 4, 6, 13, 14, 15

  **References**:
  - `.sisyphus/drafts/place-properties-migration.md` - final list of deprecated tables.
  - `docs/database-schema.md` - current table inventory to contract.
  - `generated/database.types.ts` - current deprecated table exposure.

  **Acceptance Criteria**:
  - [ ] Every deprecated table has a cleanup gate and explicit removal order.
  - [ ] Drop timing only occurs after validated replacement data exists.
  - [ ] Archive/discard decisions are explicit for each removed table.

  **QA Scenarios**:
  ```text
  Scenario: Deprecated table cleanup order is complete
    Tool: Bash (grep)
    Preconditions: Cleanup plan exists
    Steps:
      1. Compare the deprecated-table list to the cleanup sequence.
      2. Confirm every table appears exactly once with a gate and removal step.
    Expected Result: No deprecated table is missing from cleanup planning.
    Failure Indicators: Cleanup omits or duplicates removed tables.
    Evidence: .sisyphus/evidence/task-16-drop-sequence.txt

  Scenario: Replacement data exists before table removal
    Tool: Bash (grep)
    Preconditions: Cleanup plan exists
    Steps:
      1. Inspect each deprecated table removal step.
      2. Confirm it references completed backfill and read-cutover verification.
    Expected Result: No table is removed before replacement data is in use.
    Failure Indicators: The plan allows drops before proven replacement readiness.
    Evidence: .sisyphus/evidence/task-16-replacement-gates.txt
  ```

  **Commit**: YES
  - Message: `chore(schema): remove deprecated place source tables`
  - Files: `supabase/migrations/*`, `docs/database-schema.md`, `generated/database.types.ts`
  - Pre-commit: `supabase db reset && supabase gen types typescript --local > generated/database.types.ts`

- [x] 17. Plan downstream sync and consumer migration sequence

  **What to do**:
  - Define the order in which this repo, product, and worker consumers adopt additive and cleanup changes.
  - Specify when generated types are synced downstream and when consumer code must stop reading deprecated fields.
  - Include the communication/handoff notes required by this schema repo’s ownership rules.

  **Must NOT do**:
  - Do not treat this repository migration as isolated from product/worker consumers.
  - Do not allow cleanup before consumer sync is complete.

  **Recommended Agent Profile**:
  - **Category**: `writing`
    - Reason: this is a coordination and handoff plan across repositories.
  - **Skills**: `[]`
  - **Skills Evaluated but Omitted**:
    - `deep`: prior tasks already establish the technical changes; this task focuses on rollout communication.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 13-16 after Wave 2)
  - **Blocks**: FINAL
  - **Blocked By**: 6, 11, 12, 13, 14, 16

  **References**:
  - `AGENTS.md` - schema ownership and downstream sync contract.
  - `README.md` - repository sync workflow summary.
  - `docs/worker-schema-migration-guide.md` - consumer coordination context.

  **Acceptance Criteria**:
  - [ ] Product/worker sync order is explicit for additive and cleanup phases.
  - [ ] Type regeneration and consumer cutover timing are explicit.
  - [ ] Cleanup is blocked until downstream consumers are confirmed migrated.

  **QA Scenarios**:
  ```text
  Scenario: Downstream rollout order is explicit
    Tool: Bash (grep)
    Preconditions: Rollout section exists
    Steps:
      1. Inspect the rollout plan for schema repo, product repo, and worker repo sequencing.
      2. Confirm additive and cleanup phases each have downstream coordination steps.
    Expected Result: Consumer rollout is fully sequenced.
    Failure Indicators: Any consumer is omitted or cleanup proceeds without sync steps.
    Evidence: .sisyphus/evidence/task-17-downstream-sequence.txt

  Scenario: Consumer cleanup gate is enforced
    Tool: Bash (grep)
    Preconditions: Rollout section exists
    Steps:
      1. Inspect cleanup prerequisites for downstream confirmation.
      2. Confirm product/worker migration completion is named as a gate.
    Expected Result: Destructive cleanup waits for consumer adoption.
    Failure Indicators: Cleanup can proceed before downstream migration is complete.
    Evidence: .sisyphus/evidence/task-17-consumer-gate.txt
  ```

  **Commit**: NO

---

## Final Verification Wave

> Four review agents run in parallel after all implementation tasks. All must approve before the work is considered complete.

- [x] F1. **Plan Compliance Audit** - `oracle`

  **What to do**:
  Verify that every target table exists, every retained table matches the agreed design, and no prohibited deprecated objects remain.

  **QA Scenarios**:
  ```text
  Scenario: Target property tables exist with aligned schema
    Tool: Bash (psql)
    Preconditions: Migration has been applied to local database
    Steps:
      1. Query table existence: `\dt place_*_properties`
      2. Verify each table has the agreed shared columns (place_id, name, description, etc.)
      3. Verify source-specific columns are present (osm_* for OSM, google_* for Google, etc.)
    Expected Result: All 4 tables exist with correct column sets per the schema contract.
    Failure Indicators: Any table missing or columns misaligned with Task 2 contract.
    Evidence: .sisyphus/evidence/f1-table-compliance.txt

  Scenario: Minimal places schema verified
    Tool: Bash (psql)
    Preconditions: Cleanup phase completed
    Steps:
      1. Query `\d places` and extract column list.
      2. Verify only id, lat, lon, is_active, created_at, updated_at remain.
    Expected Result: Exactly 6 columns in places table.
    Failure Indicators: Business columns (website, has_*, etc.) still present.
    Evidence: .sisyphus/evidence/f1-places-minimal.txt

  Scenario: Deprecated tables removed
    Tool: Bash (psql)
    Preconditions: Cleanup phase completed
    Steps:
      1. Attempt to query each deprecated table: `SELECT 1 FROM place_google_amenities LIMIT 1`
      2. Repeat for place_google_types, place_llm_facts, place_llm_sources, place_llm_evidence_markers, place_source_evidence_runs
    Expected Result: All queries fail with "relation does not exist" error.
    Failure Indicators: Any deprecated table still queryable.
    Evidence: .sisyphus/evidence/f1-deprecated-removed.txt
  ```

  **Commit**: NO

- [x] F2. **Schema-Quality Review** - `unspecified-high`

  **What to do**:
  Verify migration safety patterns, constraint/index coverage, and no hidden redundancy.

  **QA Scenarios**:
  ```text
  Scenario: One-current-row constraints are enforced
    Tool: Bash (psql)
    Preconditions: Property tables populated with test data
    Steps:
      1. Attempt to insert duplicate current row for same place_id in place_osm_properties.
      2. Verify unique constraint violation occurs.
      3. Repeat for place_google_properties and place_llm_properties.
      4. For place_user_properties, attempt duplicate (place_id, user_id) with is_current=true.
    Expected Result: All duplicate current-row inserts are blocked by constraints.
    Failure Indicators: Duplicate current rows allowed in any property table.
    Evidence: .sisyphus/evidence/f2-current-row-constraints.txt

  Scenario: Critical indexes exist
    Tool: Bash (psql)
    Preconditions: Property tables created
    Steps:
      1. Query `\di place_osm_properties*`, `\di place_google_properties*`, etc.
      2. Verify indexes exist on place_id and is_current for each table.
      3. Verify source-specific indexes exist (osm_id, google_place_id, etc.).
    Expected Result: All planned indexes from Task 3 are present.
    Failure Indicators: Missing indexes on query-critical columns.
    Evidence: .sisyphus/evidence/f2-index-coverage.txt

  Scenario: Boolean semantics preserved
    Tool: Bash (psql)
    Preconditions: Backfill completed
    Steps:
      1. Sample 100 random rows from each property table.
      2. Verify boolean columns default to NULL, not false.
      3. Verify rows with explicit false values are intentional (source explicitly said no).
    Expected Result: No unintended false defaults; NULL means "source made no claim".
    Failure Indicators: Booleans defaulting to false or NULL semantics violated.
    Evidence: .sisyphus/evidence/f2-boolean-semantics.txt
  ```

  **Commit**: NO

- [x] F3. **Verification Rehearsal Review** - `unspecified-high`

  **What to do**:
  Execute all verification queries from the plan and confirm evidence paths exist.

  **QA Scenarios**:
  ```text
  Scenario: All task evidence files are generated
    Tool: Bash (find)
    Preconditions: All 17 tasks completed
    Steps:
      1. List expected evidence files: task-{1..17}-*.txt patterns.
      2. Verify each exists in .sisyphus/evidence/.
    Expected Result: Every task has at least one evidence file.
    Failure Indicators: Missing evidence for any completed task.
    Evidence: .sisyphus/evidence/f3-evidence-inventory.txt

  Scenario: Row count validation passes
    Tool: Bash (psql)
    Preconditions: Backfill completed for all sources
    Steps:
      1. Count rows in places table.
      2. Count current rows in each property table.
      3. Verify counts match (allowing for places without certain source types).
    Expected Result: Property table current-row counts align with places count within expected variance.
    Failure Indicators: Significant row count mismatches indicate data loss.
    Evidence: .sisyphus/evidence/f3-row-counts.txt

  Scenario: No orphaned property rows
    Tool: Bash (psql)
    Preconditions: Foreign keys enforced
    Steps:
      1. Run orphan check query for each property table.
      2. Verify zero orphaned rows (place_id not in places).
    Expected Result: Zero orphaned rows across all property tables.
    Failure Indicators: Orphaned rows indicate FK violations or incomplete cleanup.
    Evidence: .sisyphus/evidence/f3-no-orphans.txt
  ```

  **Commit**: NO

- [x] F4. **Scope Fidelity Check** - `deep`

  **What to do**:
  Confirm exactly the deprecated schema is removed, required tables are preserved, and no scope creep occurred.

  **QA Scenarios**:
  ```text
  Scenario: Google child tables preserved
    Tool: Bash (psql)
    Preconditions: Cleanup phase completed
    Steps:
      1. Query `\dt place_google_reviews` and `\dt place_google_photos`.
      2. Verify both tables exist and are queryable.
      3. Verify they still have expected columns and foreign keys.
    Expected Result: Both tables present with intact schema.
    Failure Indicators: Reviews or photos tables missing or damaged.
    Evidence: .sisyphus/evidence/f4-google-children-preserved.txt

  Scenario: No unauthorized schema additions
    Tool: Bash (psql)
    Preconditions: Migration completed
    Steps:
      1. List all tables matching `place_*` pattern.
      2. Compare against authorized list: places, place_osm_properties, place_google_properties, place_llm_properties, place_user_properties, place_google_reviews, place_google_photos.
      3. Flag any unexpected tables.
    Expected Result: Only authorized tables exist.
    Failure Indicators: New tables not in the plan (scope creep).
    Evidence: .sisyphus/evidence/f4-no-scope-creep.txt

  Scenario: Migration follows expand-contract pattern
    Tool: Bash (git log)
    Preconditions: All commits pushed
    Steps:
      1. Review commit sequence for additive commits before destructive commits.
      2. Verify no destructive changes (DROP TABLE, DROP COLUMN) appear before cutover validation.
    Expected Result: Expand-contract phases respected in commit history.
    Failure Indicators: Destructive changes without prior additive migration.
    Evidence: .sisyphus/evidence/f4-expand-contract-respected.txt
  ```

  **Commit**: NO

---

## Commit Strategy

- **1**: `feat(schema): add source property tables scaffold` - additive migration only
- **2**: `refactor(schema): cut reads to property tables` - views/RPC/docs/types
- **3**: `chore(schema): remove deprecated place fields and legacy tables` - destructive cleanup after verification

---

## Success Criteria

### Verification Commands
```bash
supabase db reset
supabase gen types typescript --local > generated/database.types.ts
```

### Final Checklist
- [ ] `places` only contains minimal core columns
- [ ] All four property tables exist with aligned shared columns
- [ ] Backfill rules cover every migrated source column/table
- [ ] `campsite_full` and `get_place_source_bundle` no longer depend on deprecated columns/tables
- [ ] Deprecated tables are removed only after cutover validation
- [ ] Docs and generated types match the final schema
