# Worker Schema Migration Guide (Schema Repo - Canonical)

> **Location:** This is the canonical source. Product repo references this file.
> **Document Status:** HISTORICAL (Phase 1 reference)  
> **Date:** 2026-03-16  
> **Scope:** Phase 1 Enrichment Schema Migration (superseded by later contraction phases)  
> **Target Audience:** DevOps Operators, Worker Maintainers  

---

## Table of Contents

1. [Overview](#overview)
2. [Rollout Playbook](#rollout-playbook)
3. [Rollback Procedures](#rollback-procedures)
4. [Worker Agent Documentation](#worker-agent-documentation)
5. [Worker Follow-Up Responsibilities](#worker-follow-up-responsibilities)
6. [Verification Commands](#verification-commands)
7. [Emergency Procedures](#emergency-procedures)

---

## Overview

This guide covers the complete deployment sequence for Phase 1 of the enrichment schema migration. The migration is **additive-only**, meaning no destructive changes are made. This design choice ensures zero-downtime deployment and safe rollback capabilities.

> **Current Schema Note (2026-03-19):** `place_llm_enrichments` and `place_google_sources` were dropped in `20260319083000_drop_llm_enrichments_and_google_sources.sql`. Use `place_llm_properties` and `place_google_properties` as the active source tables; Google child tables now link to `place_google_properties`.

### What Changes in Phase 1

| Category | Changes |
|----------|---------|
| New Tables | `place_llm_enrichments`, `place_google_sources`, `place_source_evidence_runs` |
| New Columns | 7 runtime fields added to `place_enrichment` |
| Queue Metadata | 7 typed columns added to `enrichment_jobs` |
| Enum Values | None (preserves existing `enrich_llm` value) |

### Cross-Repo Dependencies

```
camperplaner-product (this repo)
    │
    ├── Creates schema (migrations)
    ├── Exposes new tables/columns
    └── Must deploy BEFORE worker

camperplaner-worker (separate repo)
    │
    ├── Consumes schema
    ├── Writes to new tables/columns
    └── Must deploy AFTER schema cache refresh
```

---

## Rollout Playbook

This playbook is for operators executing the deployment. Follow each step in order.

### Prerequisites

- Access to both repositories
- Supabase admin access
- Coolify dashboard access for worker
- Slack/notification channel for status updates

### Step 1: Deploy Product Schema

**Repository:** `camperplaner-product`  
**Action:** Apply database migrations

```bash
# Navigate to product repo
cd camperplaner-product

# Verify migration files exist
ls -la supabase/migrations/

# Deploy migrations (via CI/CD or local)
git add supabase/migrations/
git commit -m "Add Phase 1 enrichment schema tables"
git push origin main
```

**Verification:**

```sql
-- Check new tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('place_llm_enrichments', 'place_google_sources', 'place_source_evidence_runs');

-- Check new columns in place_enrichment
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'place_enrichment' 
AND column_name IN ('source_evidence', 'evidence_markers', 'collection_status', 
  'failure_classification', 'provider_attempts', 'job_cost_usd', 'enrichment_schema_version');
```

**Expected Result:** All tables and columns visible  
**Time:** 2-4 minutes (CI/CD pipeline)

### Step 2: Wait for PostgREST Cache Refresh

**Critical:** Do not proceed until cache refreshes. Supabase's PostgREST caches the database schema and won't see new tables/columns until the cache expires.

```bash
# Wait 30-60 seconds
echo "Waiting for PostgREST cache refresh..."
sleep 45
```

**Verification:**

```sql
-- Test query on new table (should return 0 or count, not relation does not exist)
SELECT COUNT(*) FROM place_llm_enrichments;

-- Test query on new column (should return data or null, not column does not exist)
SELECT source_evidence FROM place_enrichment LIMIT 1;

-- Verify typed columns exist in enrichment_jobs
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'enrichment_jobs' 
AND column_name = 'classification';
```

**Expected Result:** No "relation does not exist" or "column does not exist" errors  
**Time:** 30-60 seconds

### Step 3: Update Types and Documentation

**Repository:** `camperplaner-product`  
**Action:** Regenerate TypeScript types

```bash
# Regenerate types (if using supabase generate)
npx supabase gen types typescript --local > apps/web/src/lib/database.types.ts

# Update documentation
# Edit docs/database-schema.md to reflect new tables

git add .
git commit -m "Regenerate types and docs for Phase 1 schema"
git push origin main
```

**Verification:**

```bash
# Verify TypeScript compiles
cd apps/web
npm run typecheck
```

**Expected Result:** No type errors  
**Time:** 2-4 minutes (CI/CD pipeline)

### Step 4: Deploy Worker Update

**Repository:** `camperplaner-worker`  
**Action:** Deploy updated worker code

```bash
# Navigate to worker repo
cd camperplaner-worker

# Copy updated types from product repo
cp ../camperplaner-product/apps/web/src/lib/database.types.ts src/types/

# Update job processor to write to new schema
# (See Worker Agent Documentation section)

# Commit and push
git add .
git commit -m "Update for Phase 1 schema compatibility"
git push origin main
```

**Verification:**

```bash
# Check worker logs
# Look for successful job processing

# Test enrichment job manually
# (See QA Verification Scenarios)
```

**Expected Result:** Worker processes jobs without schema errors  
**Time:** 1-2 minutes (Coolify auto-deploy)

### Rollout Gate Checklist

Before proceeding from each step, verify:

| Gate | Check | Command |
|------|-------|---------|
| G1 | Schema deployed | `\dt place_*` shows new tables |
| G2 | Cache refreshed | Query new table succeeds |
| G3 | Types compile | `npm run typecheck` passes |
| G4 | Worker running | Jobs process without errors |

---

## Rollback Procedures

### Understanding Rollback Constraints

Phase 1 is **additive-only**, which means:
- New tables can be added without breaking old code
- New columns can be added without breaking old queries
- Worker can be rolled back independently

**Safe Rollback Scenarios:**

| Scenario | Rollback Action | Risk |
|----------|----------------|------|
| Worker errors | Revert worker commit | Low (schema unchanged) |
| Type errors | Revert types commit | Low (schema unchanged) |
| Schema errors | Revert migrations | Medium (data in new tables lost) |

### Worker Rollback (Fast)

If worker experiences issues after deployment:

```bash
cd camperplaner-worker

# Revert to previous commit
git revert HEAD
git push origin main

# Coolify auto-deploys
```

**Time:** 1-2 minutes  
**Data Impact:** None (no data written to new schema yet)

### Schema Rollback (Complex)

Only if absolutely necessary (e.g., critical data corruption):

```sql
-- CAUTION: This is destructive
-- Only execute if explicitly instructed

-- Remove new columns from place_enrichment
ALTER TABLE place_enrichment DROP COLUMN IF EXISTS source_evidence;
ALTER TABLE place_enrichment DROP COLUMN IF EXISTS evidence_markers;
ALTER TABLE place_enrichment DROP COLUMN IF EXISTS collection_status;
ALTER TABLE place_enrichment DROP COLUMN IF EXISTS failure_classification;
ALTER TABLE place_enrichment DROP COLUMN IF EXISTS provider_attempts;
ALTER TABLE place_enrichment DROP COLUMN IF EXISTS job_cost_usd;
ALTER TABLE place_enrichment DROP COLUMN IF EXISTS enrichment_schema_version;

-- Remove new columns from enrichment_jobs
ALTER TABLE enrichment_jobs DROP COLUMN IF EXISTS classification;
ALTER TABLE enrichment_jobs DROP COLUMN IF EXISTS source_state;
ALTER TABLE enrichment_jobs DROP COLUMN IF EXISTS worker_id;
ALTER TABLE enrichment_jobs DROP COLUMN IF EXISTS attempt_number;
ALTER TABLE enrichment_jobs DROP COLUMN IF EXISTS last_error_code;
ALTER TABLE enrichment_jobs DROP COLUMN IF EXISTS last_error_message;
ALTER TABLE enrichment_jobs DROP COLUMN IF EXISTS canonical_place_id;

-- Drop new tables
-- NOTE: place_llm_enrichments and place_google_sources were later dropped in
--       20260319083000_drop_llm_enrichments_and_google_sources.sql.
DROP TABLE IF EXISTS place_source_evidence_runs;
```

**Time:** 30-60 seconds  
**Data Impact:** Data in new tables/columns is lost

### Checkpoint Strategy

To enable safe rollback at checkpoints:

1. **Before Phase 1 deploy:** Note current `enrichment_jobs` count
2. **After schema deploy:** Verify new tables exist but are empty
3. **After worker deploy:** Monitor for 5 minutes before declaring success
4. **After 24 hours:** Archive checkpoint, consider cleaning old data

---

## Worker Agent Documentation

This section is for agents maintaining the `camperplaner-worker` repository.

### Schema Changes Summary

Phase 1 introduces these schema changes:

#### New Tables

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `place_llm_enrichments` | Structured LLM output storage | place_id, job_id, provider, model, prompt_version, summary_de, confidence, token_input, token_output, cost_usd |
| `place_google_sources` | Google Places API cache | google_place_id, name, rating, review_count, opening_hours JSONB, photos JSONB, raw_payload JSONB, fetched_at, expires_at |
| `place_source_evidence_runs` | Evidence collection audit | place_id, job_id, worker_id, attempt_number, collection_status, source_urls JSONB, source_evidence JSONB, evidence_markers JSONB, trusted_source_count |

#### New Columns in Existing Tables

**place_enrichment:**

| Column | Type | Purpose |
|--------|------|---------|
| `source_evidence` | JSONB | Evidence collection logging |
| `evidence_markers` | JSONB | Trust markers for validation |
| `collection_status` | text | Standardized status values |
| `failure_classification` | text | Error categorization |
| `provider_attempts` | JSONB | Retry tracking |
| `job_cost_usd` | numeric | Cost tracking |
| `enrichment_schema_version` | text | Schema versioning |

**enrichment_jobs:**

| Column | Type | Purpose |
|--------|------|---------|
| `classification` | text | Error/failure classification |
| `source_state` | text | Source processing state |
| `worker_id` | text | Claiming worker identifier |
| `attempt_number` | integer | Current attempt count |
| `last_error_code` | text | Structured error code |
| `last_error_message` | text | Human-readable error |
| `canonical_place_id` | uuid | Reference for queue flow |

### Child Table Relationships

The new schema follows a parent-child relationship:

```
place_enrichment (parent)
    │
    ├── place_llm_enrichments (child) - LLM-specific outputs
    │
    ├── place_source_evidence_runs (child) - Evidence collection runs
    │
    └── place_google_sources (child) - Cached Google data

enrichment_jobs (parent)
    │
    └── place_enrichment (child) - Results per job
```

**Writing to Child Tables:**

```typescript
// Example: Writing to place_llm_enrichments
// NOTE: For structured facts, use child tables (place_llm_facts, place_llm_sources, place_llm_evidence_markers)
// DO NOT use structured_facts - this field does NOT exist in the live schema
await supabase.from('place_llm_enrichments').insert({
  place_id: placeId,
  job_id: jobId,
  provider: 'openai',
  model: 'gpt-4-turbo',
  prompt_version: 'v1',
  summary_de: generatedSummary,
  confidence: 0.85,
  token_input: 500,
  token_output: 200,
  cost_usd: 0.015,
  created_at: new Date().toISOString()
});
```

### Amenity Facts Pattern

Hard factual data (amenities, contact info) MUST be stored in typed columns, not JSONB.

**Correct:**

```sql
has_electricity boolean NOT NULL DEFAULT false,
has_water boolean NOT NULL DEFAULT false,
phone text,
website text
```

**Incorrect (violates pattern):**

```sql
amenities jsonb,  -- { "has_electricity": true }
contact jsonb     -- { "phone": "...", "website": "..." }
```

### JSONB Minimization Rules

JSONB columns are allowed ONLY for:

1. **Debug metadata** - Non-operational tracing
2. **Changing payload fragments** - LLM output structures that vary by model
3. **Vendor-specific details** - Raw Google Places responses
4. **Evidence storage** - Scraped content that varies by URL

JSONB is FORBIDDEN for:
- Query filters (WHERE clauses)
- Join conditions (FK relationships)
- Analytics aggregations (GROUP BY, COUNT)
- UI display (user-facing text)

---

## Explicit Table Classification: Active vs Deferred

This section clarifies which tables are actively populated by the Phase 1 LLM path and which remain deferred/out-of-scope.

### ACTIVE-NOW: Tables Populated by Phase 1 LLM Worker

| Table | Status | Population | Notes |
|-------|--------|------------|-------|
| `place_llm_enrichments` | ACTIVE | Worker writes directly | Stores LLM output with typed columns |
| `place_enrichment` | ACTIVE | Worker writes + new typed columns | Parent table with 7 new runtime fields |
| `enrichment_jobs` | ACTIVE | Queue + new typed columns | Job queue with 7 new metadata columns |
| `place_llm_facts` | OPTIONAL | Worker may write | Child table for structured facts |
| `place_llm_sources` | OPTIONAL | Worker may write | Child table for LLM citations |
| `place_llm_evidence_markers` | OPTIONAL | Worker may write | Child table for trust markers |

### DEFERRED-LATER: Tables NOT Populated in Phase 1

| Table | Status | Reason | Blocker |
|-------|--------|--------|---------|
| `place_source_evidence_runs` | DEFERRED | Evidence collection worker | Requires evidence collection implementation |
| `place_evidence_sources` | DEFERRED | Individual source tracking | Requires evidence collection implementation |
| `place_evidence_markers` | DEFERRED | Evidence extraction | Requires evidence collection implementation |
| `place_google_sources` | DEFERRED | Google Places API cache | Phase 2 Google path |
| `place_google_reviews` | DEFERRED | Individual Google reviews | Phase 2 Google path |
| `place_google_photos` | DEFERRED | Google place photos | Phase 2 Google path |
| `place_google_types` | DEFERRED | Google place types | Phase 2 Google path |

**Critical:** Do NOT write to deferred tables - they exist in schema but have no population logic. Writing to them will create orphaned data with no consumer.

---

## Replay and Backfill Guardrails

When replaying or backfilling enrichment jobs, follow these guardrails to prevent data explosion and ensure idempotency.

### Guardrail 1: Idempotent Writes Required

All write operations must be idempotent (safe to run multiple times):

```typescript
// WRONG: Blind insert creates duplicates on replay
await supabase.from('place_llm_enrichments').insert({...});

// RIGHT: Check-then-insert pattern
const existing = await supabase.from('place_llm_enrichments')
  .select('id')
  .eq('place_id', placeId)
  .eq('job_id', jobId)
  .maybeSingle();
  
if (!existing) {
  await supabase.from('place_llm_enrichments').insert({...});
}
```

### Guardrail 2: Bounded Scope - Only IN-SCOPE-NOW Tables

Only replay/backfill these tables:
- `enrichment_jobs` (typed columns only)
- `place_enrichment` (typed columns only)
- `place_llm_enrichments`

Do NOT attempt to backfill:
- Deferred tables (no population logic exists)
- JSONB columns (already have data in `context` or `extracted`)

### Guardrail 3: is_current Reset on Upsert

When backfilling `place_llm_enrichments`, reset old records:

```sql
-- Before inserting new current record, mark existing as not current
UPDATE place_llm_enrichments 
SET is_current = false 
WHERE place_id = :placeId AND is_current = true;
```

### Guardrail 4: Audit Script Available

Run the audit script to verify before/after state:

```bash
# In worker repo
npm run audit-enrichment-schema
```

This reports:
- Row counts per table
- Null-density for typed columns
- Recent write timestamps

### Guardrail 5: Bounded Time Window

Backfill only recent jobs to limit blast radius:

```sql
-- Only backfill jobs from last 7 days
WHERE created_at > NOW() - INTERVAL '7 days'
AND status = 'completed';
```

---

## Worker Follow-Up Responsibilities

After Phase 1 schema is deployed, the worker must:

### 1. Adopt Dual-Write Pattern

During transition, write to both legacy and new tables:

```typescript
// Write to legacy table (required for backward compatibility)
await supabase.from('place_enrichment').insert({
  place_id: placeId,
  summary_de: generatedSummary,
  // ... other legacy fields
});

// ALSO write to new child table
// NOTE: Use child tables for structured data (place_llm_facts, place_llm_sources)
// DO NOT use structured_facts field - it does NOT exist
await supabase.from('place_llm_enrichments').insert({
  place_id: placeId,
  job_id: jobId,
  provider: 'openai',
  model: 'gpt-4-turbo',
  prompt_version: 'v1',
  summary_de: generatedSummary,
  // For structured facts, write to place_llm_facts child table instead
  confidence: 0.85,
  token_input: result.usage.prompt_tokens,
  token_output: result.usage.completion_tokens,
  cost_usd: cost
});
```

### 2. Populate Child Tables

When processing enrichment jobs:

1. **Extract structured data** from LLM response
2. **Write to `place_llm_enrichments`** with typed columns
3. **Write evidence runs** to `place_source_evidence_runs`
4. **Update parent record** with reference to child records

### 3. Update Job Processor

Update `job-processor.ts` to write typed columns:

```typescript
// Before (runtime fields only)
await supabase.from('place_enrichment').insert({
  place_id: placeId,
  summary_de: result.summary,
  extracted: result.structured  // JSONB
});

// After (typed columns + child table)
await supabase.from('place_enrichment').insert({
  place_id: placeId,
  summary_de: result.summary,
  extracted: result.structured,
  // New typed columns
  source_evidence: evidence,
  evidence_markers: markers,
  collection_status: 'completed',
  failure_classification: null,
  provider_attempts: attempts,
  job_cost_usd: cost,
  enrichment_schema_version: '1.0'
});

// Also write to child table
// NOTE: Use token_input and token_output (NOT prompt_tokens/completion_tokens/total_tokens)
// For structured facts, write to place_llm_facts child table (NOT structured_facts column)
await supabase.from('place_llm_enrichments').insert({
  place_id: placeId,
  job_id: jobId,
  provider: 'openai',
  model: 'gpt-4-turbo',
  prompt_version: 'v1',
  summary_de: result.summary,
  confidence: result.confidence,
  token_input: result.usage.prompt_tokens,
  token_output: result.usage.completion_tokens,
  cost_usd: cost
});
```

### 4. Maintain enrich_llm Compatibility

The worker must continue supporting the `enrich_llm` job type:

```typescript
// Worker normalizes internally but database accepts both
const normalizedJobType = jobType === 'enrich_llm' ? 'llm_description' : jobType;
```

### 5. Implement Evidence Collection

For evidence collection jobs:

```typescript
// Write evidence run record
await supabase.from('place_source_evidence_runs').insert({
  place_id: placeId,
  job_id: jobId,
  worker_id: workerId,
  attempt_number: attemptNumber,
  collection_status: 'completed',
  source_urls: collectedUrls,
  source_evidence: scrapedContent,
  evidence_markers: trustMarkers,
  trusted_source_count: trustedCount
});
```

---

## Verification Commands

### Pre-Deployment Checks

```bash
# Verify migrations are valid
supabase db lint

# Check for destructive changes
supabase db diff --schema-only
```

### Post-Deployment Verification

```sql
-- List new tables
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name LIKE 'place_%';

-- Verify typed columns in place_enrichment (7 new columns)
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'place_enrichment' 
AND column_name IN ('source_evidence', 'evidence_markers', 'collection_status',
  'failure_classification', 'provider_attempts', 'job_cost_usd', 
  'enrichment_schema_version');

-- Verify typed columns in enrichment_jobs (7 new columns)
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'enrichment_jobs' 
AND column_name IN ('classification', 'source_state', 'worker_id', 
  'attempt_number', 'last_error_code', 'last_error_message', 'canonical_place_id');

-- Verify place_llm_enrichments schema
SELECT column_name, data_type, is_nullable FROM information_schema.columns 
WHERE table_name = 'place_llm_enrichments' 
ORDER BY ordinal_position;
```

### Typed-Column Verification Commands

These commands verify that typed columns are properly populated vs stored in JSONB:

```sql
-- Check enrichment_jobs typed column density
SELECT 
  'classification' as column_name,
  ROUND((COUNT(*) - COUNT(classification))::numeric / NULLIF(COUNT(*), 0) * 100, 1) as null_pct
FROM enrichment_jobs
UNION ALL
SELECT 
  'source_state',
  ROUND((COUNT(*) - COUNT(source_state))::numeric / NULLIF(COUNT(*), 0) * 100, 1)
FROM enrichment_jobs
UNION ALL
SELECT 
  'worker_id',
  ROUND((COUNT(*) - COUNT(worker_id))::numeric / NULLIF(COUNT(*), 0) * 100, 1)
FROM enrichment_jobs
UNION ALL
SELECT 
  'attempt_number',
  ROUND((COUNT(*) - COUNT(attempt_number))::numeric / NULLIF(COUNT(*), 0) * 100, 1)
FROM enrichment_jobs;

-- Check place_llm_enrichments typed column density
SELECT 
  'prompt_version' as column_name,
  ROUND((COUNT(*) - COUNT(prompt_version))::numeric / NULLIF(COUNT(*), 0) * 100, 1) as null_pct
FROM place_llm_enrichments
UNION ALL
SELECT 'token_input', ROUND((COUNT(*) - COUNT(token_input))::numeric / NULLIF(COUNT(*), 0) * 100, 1)
FROM place_llm_enrichments
UNION ALL
SELECT 'token_output', ROUND((COUNT(*) - COUNT(token_output))::numeric / NULLIF(COUNT(*), 0) * 100, 1)
FROM place_llm_enrichments
UNION ALL
SELECT 'summary_de', ROUND((COUNT(*) - COUNT(summary_de))::numeric / NULLIF(COUNT(*), 0) * 100, 1)
FROM place_llm_enrichments
UNION ALL
SELECT 'confidence', ROUND((COUNT(*) - COUNT(confidence))::numeric / NULLIF(COUNT(*), 0) * 100, 1)
FROM place_llm_enrichments;
```

### Worker Verification

```bash
# Verify types compile
npm run typecheck

# Run worker tests
npm test

# Verify database connection
npm run db:verify
```

### Integration Verification

```sql
-- Test enrichment job flow
INSERT INTO enrichment_jobs (place_id, job_type, status, priority)
VALUES (gen_random_uuid(), 'enrich_llm', 'queued', 5)
RETURNING id, job_type;

-- Query after worker processes
SELECT * FROM place_enrichment WHERE place_id = ?;
SELECT * FROM place_llm_enrichments WHERE place_id = ?;
```

---

## Emergency Procedures

### Scenario 1: Worker Crashes with Schema Error

**Symptoms:** Worker logs show "column does not exist" or "relation does not exist" errors

**Response:**

1. **Immediately rollback worker:**
   ```bash
   cd camperplaner-worker
   git revert HEAD
   git push origin main
   ```

2. **Verify worker is healthy:**
   - Check Coolify logs
   - Verify jobs are processing

3. **Investigate:**
   - Did types get copied correctly from product repo?
   - Are new columns visible in database? Run:
     ```sql
     SELECT column_name FROM information_schema.columns 
     WHERE table_name = 'place_llm_enrichments';
     ```
   - Is PostgREST cache refreshed? Run:
     ```sql
     SELECT COUNT(*) FROM place_llm_enrichments;
     ```

4. **Fix and redeploy** once issue is resolved

### Scenario 2: PostgREST Cache Not Refreshing

**Symptoms:** Queries fail with "relation does not exist" after 60+ seconds

**Response:**

1. **Restart PostgREST:**
   - In Supabase dashboard, go to Database
   - Find postgrest service and restart
   - Or use Supabase CLI: `supabase projects api pause && supabase projects api resume`

2. **Verify cache refresh:**
   ```sql
   SELECT COUNT(*) FROM place_llm_enrichments;
   SELECT column_name FROM information_schema.columns WHERE table_name = 'place_llm_enrichments';
   ```

3. **Force schema reload:**
   ```sql
   NOTIFY pgrst, 'reload schema';
   ```

4. **Proceed with deployment** once cache is refreshed

### Scenario 3: Data Inconsistency Detected

**Symptoms:** Parent and child table data out of sync

**Response:**

1. **Pause worker:**
   ```bash
   # In Coolify, stop worker container
   ```

2. **Run reconciliation script:**
   ```sql
   -- Sync missing records from parent to child
   -- (Implement based on specific inconsistency)
   ```

3. **Resume worker** once reconciled

### Scenario 4: Complete Rollback Required

**Symptoms:** Critical schema error affecting production

**Response:**

1. **Stop worker immediately:**
   ```bash
   # Coolify: stop worker container
   ```

2. **Revert product schema:**
   ```sql
   -- Run rollback SQL (see Rollback Procedures section)
   ```

3. **Revert worker to pre-Phase-1 version:**
   ```bash
   cd camperplaner-worker
   git log --oneline -5
   git revert HEAD  # Repeat until at pre-Phase-1 commit
   git push origin main
   ```

4. **Verify system is operational:**
   ```sql
   -- Test basic enrichment flow
   ```

5. **Investigate and plan fix** before attempting again

---

## References

- AGENTS.md - Deployment section (line 147)
- task-2-rollout-sequence.txt - Detailed rollout gates
- phase-1-compatibility-decisions.md - Architecture decisions
- docs/database-schema.md - Full schema documentation

---

## Appendix: Timing Summary

| Step | Duration | Wait Time |
|------|----------|-----------|
| Product schema deploy (CI/CD) | 2-4 min | - |
| PostgREST cache refresh | - | 30-60 sec |
| Types/docs update (CI/CD) | 2-4 min | - |
| Worker deploy (Coolify) | 1-2 min | - |
| **Total** | **5-10 min** | **30-60 sec** |

---

**Document Version:** 1.0  
**Last Updated:** 2026-03-16  
**Next Review:** After Phase 2 scope defined
