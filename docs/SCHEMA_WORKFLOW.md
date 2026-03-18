# Schema Change Workflow

> **Canonical Source:** `/home/opencode/camperplaner-schema/docs/SCHEMA_WORKFLOW.md`
> **Status:** OPERATIONAL
> **Last Updated:** 2026-03-18
> **Target Audience:** All contributors, DevOps operators, repository maintainers

---

## Table of Contents

1. [Overview](#overview)
2. [Requesting Schema Changes](#requesting-schema-changes)
3. [PR Review Process](#pr-review-process)
4. [Deployment Order](#deployment-order)
5. [PostgREST Cache Refresh](#postgrest-cache-refresh)
6. [Consumer Artifact Sync](#consumer-artifact-sync)
7. [Rollback Strategy](#rollback-strategy)
8. [In-Flight PR Handling](#in-flight-pr-handling)
9. [Emergency Procedures](#emergency-procedures)

---

## Overview

This document defines the complete workflow for making, reviewing, deploying, and rolling back database schema changes across the CamperPlaner ecosystem. It establishes the schema repository (camperplaner-schema) as the single source of truth and defines the mandatory sequence for propagating changes to consumer repositories.

### Architecture

```
                    SCHEMA REPOSITORY (Owner)
              camperplaner-schema

   Migrations       Generated Types      Documentation
   (SQL)            (TypeScript)         (Markdown)
        |                  |
        v                  v
   PRODUCT REPOSITORY    WORKER REPO
   (Consumer)            (Consumer)
   camperplaner-product  camperplaner-worker

   - Syncs types to      - Syncs types
     apps/web/src/lib/     to src/types/
   - Executes            - Read-only
     migrations
   - References docs
```

### Key Principles

1. **Single Source of Truth:** Only camperplaner-schema may define schema
2. **PR-Only Changes:** All schema changes must go through PR review in this repo
3. **Schema-First Deployment:** Schema deploys before consumers can use it
4. **Cache Awareness:** PostgREST schema cache requires 30-60s refresh after deployment
5. **Coordinated Sync:** Both consumers must sync artifacts after schema changes

---

## Requesting Schema Changes

### Who Can Request

Any contributor from:
- camperplaner-product (main application)
- camperplaner-worker (background jobs)
- camperplaner-schema (schema maintainers)

### Change Request Process

#### Step 1: Identify Need

Before requesting a schema change, confirm:

| Check | Question | Action if No |
|-------|----------|--------------|
| Necessity | Is a schema change actually required? | Consider computed columns, views, or application-level solutions |
| Compatibility | Can this be done additively (no destructive changes)? | Document breaking changes and coordinate with consumers |
| Scope | Does it fit within existing table design? | Propose new table(s) with justification |
| Impact | Which consumers are affected? | List both repos in PR description |

#### Step 2: Create Schema PR

All schema changes must originate as PRs in the schema repository:

```bash
# From the schema repo
cd /home/opencode/camperplaner-schema

# Create feature branch
git checkout -b feat/add-user-preferences

# Create migration (use UTC timestamp)
timestamp=$(date -u +%Y%m%d%H%M%S)
touch "supabase/migrations/${timestamp}_add_user_preferences.sql"

# Edit the migration file
# ... write your SQL ...

# Generate artifacts
node scripts/generate-types.js

# Commit and push
git add .
git commit -m "feat(schema): add user preferences table"
git push origin feat/add-user-preferences
```

#### Step 3: Fill Out PR Template

The PR template requires:
- Type of change (checkboxes for tables, columns, indexes, etc.)
- Pre-submit checklist (migration naming, SQL validation, downstream impact)
- Generated artifacts checklist (types, manifest, contract updates)
- Communication checklist (contract.md, breaking changes noted)
- Migration details (file list, affected tables, breaking changes)
- Consumer impact assessment

#### Step 4: Cross-Repo Coordination (if breaking)

For breaking changes, open coordinating issues in consumer repos before merging.

---

## PR Review Process

### Review Requirements

| Change Type | Required Reviewers | CI Checks |
|-------------|-------------------|-----------|
| Additive (new tables/columns) | 1 schema maintainer | All green |
| Index/constraints | 1 schema maintainer | All green |
| Breaking changes | 2 reviewers + consumer sign-off | All green |
| Rollback migrations | 2 reviewers + manual test | All green |
| Documentation only | 1 reviewer | Docs check |

### Review Checklist for Maintainers

**Migration Quality:**
- Naming follows convention: YYYYMMDDhhmmss_description.sql
- SQL syntax is valid (check CI)
- No destructive changes without rollback plan
- Migration is additive where possible
- No merge conflict markers in SQL

**Artifact Completeness:**
- generated/database.types.ts is updated
- generated/schema-manifest.json reflects new migration
- Types export new tables/columns correctly

**Consumer Impact:**
- Breaking changes documented in PR description
- Consumer impact assessment is accurate
- CONTRACT.md updated if contract changes

**Rollback Safety:**
- Destructive changes have rollback script
- Rollback tested locally or documented

### CI Validation

All PRs run these checks:

1. **Migration Naming** - Validates YYYYMMDDhhmmss_description.sql format
2. **SQL Syntax** - Basic syntax validation
3. **Timestamp Ordering** - Ensures chronological order, no duplicates
4. **Conflict Markers** - Detects unresolved git conflicts
5. **Manifest Sync** - Verifies schema-manifest.json matches migrations
6. **Types Exist** - Ensures database.types.ts exists and exports types
7. **Doc Linkage** - Checks CONTRACT.md and AGENTS.md references

### Approval Gates

PR cannot merge until:
- All CI checks pass
- Required reviewers approve
- No unresolved review comments
- Branch is up to date with main


---

## Deployment Order

### Critical Rule: Schema-First Deployment

Schema changes MUST be deployed and cached before consumers can use them. The order is non-negotiable.

### Standard Deployment Sequence

| Step | Repository | Action | Duration | Wait Time |
|------|------------|--------|----------|-----------|
| 1 | camperplaner-schema | Merge PR, migrations land | 1 min | - |
| 2 | camperplaner-product | Apply migration to database | 2-4 min | - |
| 3 | - | Wait for PostgREST cache | - | 30-60 sec |
| 4 | camperplaner-product | Sync types to apps/web/src/lib/ | 1 min | - |
| 5 | camperplaner-worker | Sync types to src/types/ | 1 min | - |
| **Total** | | | **5-8 min** | **30-60 sec** |

### Deployment Commands

**Step 1: Schema PR Merges**
```bash
# In camperplaner-schema repo
# PR is merged via GitHub UI
# Migrations now in supabase/migrations/
```

**Step 2: Product Applies Migration**
```bash
# In camperplaner-product repo
git pull origin main  # Get latest

# Deploy migrations via CI/CD or manually
supabase db push

# Or if using custom deployment
psql $DATABASE_URL -f supabase/migrations/[timestamp]_description.sql
```

**Step 3: Verify Migration Applied**
```sql
-- Check new table exists
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'new_table_name';

-- Check new column exists
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'existing_table' 
AND column_name = 'new_column';
```

**Step 4: Wait for PostgREST Cache**
```bash
# Wait 30-60 seconds
echo "Waiting for PostgREST cache refresh..."
sleep 45
```

**Step 5: Sync Product Artifacts**
```bash
# In camperplaner-product repo
cp ../camperplaner-schema/generated/database.types.ts apps/web/src/lib/

# Verify types compile
npm run typecheck

git add apps/web/src/lib/database.types.ts
git commit -m "chore(types): sync schema from camperplaner-schema"
git push origin main
```

**Step 6: Sync Worker Artifacts**
```bash
# In camperplaner-worker repo
cp ../camperplaner-schema/generated/database.types.ts src/types/

# Verify types compile
npm run typecheck

git add src/types/database.types.ts
git commit -m "chore(types): sync schema from camperplaner-schema"
git push origin main
```

---

## PostgREST Cache Refresh

### Why Cache Refresh Matters

Supabase uses PostgREST to expose database tables via REST API. PostgREST caches the database schema for performance. After applying migrations, the cache must expire and refresh before new tables/columns are accessible via the API.

### Cache Behavior

- **Cache TTL:** ~30-60 seconds (variable)
- **Cache Scope:** Per-connection, eventually consistent
- **Impact:** Queries to new tables fail with "relation does not exist" until refresh

### Verification Commands

**Check Cache Status:**
```sql
-- Query should return count (not error)
SELECT COUNT(*) FROM new_table_name;

-- If this fails, cache not refreshed yet
```

**Force Cache Reload (if needed):**
```sql
-- Requires admin privileges
NOTIFY pgrst, 'reload schema';
```

**Alternative: Restart PostgREST Service**
- Via Supabase Dashboard: Database -> Restart PostgREST
- Via CLI: supabase projects api pause && supabase projects api resume

### Cache Refresh Checklist

Before proceeding after migration:
- [ ] Wait minimum 30 seconds after migration applied
- [ ] Run verification query successfully
- [ ] Confirm no "relation does not exist" errors
- [ ] Check that new columns are queryable


---

## Consumer Artifact Sync

### What Gets Synced

| Artifact | Schema Location | Product Target | Worker Target |
|----------|-----------------|----------------|---------------|
| Database Types | generated/database.types.ts | apps/web/src/lib/database.types.ts | src/types/database.types.ts |
| Schema Manifest | generated/schema-manifest.json | Reference only | Reference only |
| Documentation | docs/*.md | Reference via pointer | Reference via pointer |

### Sync Frequency

| Scenario | Sync Required | Priority |
|----------|---------------|----------|
| New table added | Yes | High |
| New column added | Yes | High |
| Column type changed | Yes | Critical |
| Column dropped | Yes | Critical |
| Index added | No | Low |
| Constraint added | No | Medium |
| Documentation only | No | N/A |

### Sync Commands Reference

**Product Repository:**
```bash
cd /home/opencode/camperplaner-product

# Copy types
cp ../camperplaner-schema/generated/database.types.ts apps/web/src/lib/

# Copy types from packages (alternative)
cp -r ../camperplaner-schema/packages/database-types/* apps/web/src/lib/

# Verify compilation
npm run typecheck

# Commit
git add apps/web/src/lib/database.types.ts
git commit -m "chore(types): sync schema from camperplaner-schema"
```

**Worker Repository:**
```bash
cd /home/opencode/camperplaner-worker

# Copy types
cp ../camperplaner-schema/generated/database.types.ts src/types/

# Verify compilation
npm run typecheck

# Commit
git add src/types/database.types.ts
git commit -m "chore(types): sync schema from camperplaner-schema"
```

### Sync Automation Options

**Option 1: Manual Sync (Current)**
- Consumers manually copy files after schema merge
- Documented in AGENTS.md of each repo
- Requires explicit action

**Option 2: CI-Triggered Sync (Future)**
- GitHub Actions workflow watches schema repo
- Opens auto-PRs in consumer repos when types change
- Requires repository-level permissions

**Option 3: Git Submodules (Not Recommended)**
- Schema repo as submodule
- Complex for non-technical contributors
- Merge conflict risks

---

## Rollback Strategy

### Rollback Scenarios

| Scenario | Rollback Target | Risk Level | Time Required |
|----------|----------------|------------|---------------|
| Schema migration failed | Revert migration | Medium | 5-10 min |
| Consumer types broken | Revert consumer PR | Low | 2-3 min |
| PostgREST cache issues | Restart service | Low | 1-2 min |
| Breaking change in prod | Full rollback (complex) | High | 15-30 min |

### Migration Rollback

#### For Additive Changes (No Data Loss)

If migration was purely additive (new tables/columns):

```sql
-- Option 1: Leave as-is (safe)
-- New tables/columns won't break existing code

-- Option 2: Drop if truly needed
DROP TABLE IF EXISTS new_table;
ALTER TABLE existing_table DROP COLUMN IF EXISTS new_column;
```

#### For Destructive Changes (Requires Rollback Script)

Always create rollback migration for destructive changes:

```bash
# Create rollback file alongside main migration
# Naming: rollback_[description].sql

# Example rollback_20260318_restructure.sql
```

**Example Rollback Migration:**
```sql
-- Rollback: Remove new table and restore old structure
BEGIN;

-- 1. Migrate data back if needed
INSERT INTO old_table (col1, col2)
SELECT col1, col2 FROM new_table;

-- 2. Drop new table
DROP TABLE IF EXISTS new_table;

-- 3. Restore dropped column if applicable
ALTER TABLE existing_table ADD COLUMN dropped_column TYPE;

COMMIT;
```

### Consumer Rollback

**If types sync causes issues:**

```bash
# In consumer repo
git revert HEAD  # Revert the types sync commit
git push origin main

# Or checkout previous version
git checkout HEAD~1 -- apps/web/src/lib/database.types.ts
git commit -m "revert(types): rollback to previous schema version"
```

### Full System Rollback

**Only for critical issues affecting production:**

```
1. Stop all consumers (product app, worker)
2. Revert schema migration (if safe)
3. Revert consumer code to pre-schema version
4. Verify database state
5. Restart consumers
```

### Rollback Decision Matrix

| Issue | Immediate Action | Rollback Scope | Verification |
|-------|-----------------|---------------|--------------|
| Migration fails mid-run | Stop, assess, retry or rollback | Schema only | Check logs |
| PostgREST cache stuck | Restart PostgREST | None | Query test |
| Types don't compile | Revert types sync | Consumer only | Build check |
| Breaking change discovered | Coordinate full rollback | Schema + Consumers | Integration tests |
| Data corruption suspected | Emergency stop + restore from backup | Full system | Data integrity checks |


---

## In-Flight PR Handling

### Definition

In-flight PRs are pull requests in consumer repositories that:
- Were opened before schema changes merged
- Reference old schema assumptions
- May conflict with new migrations

### Detection

**Before merging schema PR, check for:**
- Open PRs in product repo touching database queries
- Open PRs in worker repo using table schemas
- Staging branches with schema-dependent features

### Coordination Process

#### Step 1: Identify Affected PRs

```bash
# In product repo - search for PRs touching schema-related files
git log --oneline --all --grep="database\|schema\|table\|migration"

# List open PRs (via GitHub CLI)
gh pr list --repo it-guy92/camperplaner-product --state open
```

#### Step 2: Notify Contributors

Comment on affected PRs:
```markdown
## Schema Change Notice

A schema change has been merged that may affect this PR:
- **Schema PR:** #45 (adds user_preferences table)
- **Impact:** This PR references users table which now has new foreign key

**Required Actions:**
1. Sync latest types: cp ../camperplaner-schema/generated/database.types.ts apps/web/src/lib/
2. Rebase on main
3. Verify build passes: npm run typecheck

Please update before merging this PR.
```

#### Step 3: Hold or Fast-Track

| Situation | Action | Reason |
|-----------|--------|--------|
| Schema PR is additive only | Can merge independently | No conflicts expected |
| Schema PR modifies existing columns | Coordinate timing | Prevent broken builds |
| Schema PR is breaking change | Hold consumer PRs | Require updates first |
| Schema PR renames tables/columns | Merge together | Atomic transition |

#### Step 4: Post-Schema Update

After schema PR merges:

```bash
# For each affected consumer PR
# (Contributors should do this)

git fetch origin
git rebase origin/main

# Sync types
cp ../camperplaner-schema/generated/database.types.ts apps/web/src/lib/

# Fix any conflicts
git add .
git rebase --continue

# Verify
git push origin feature-branch --force-with-lease
```

### In-Flight PR Checklist

For schema PR author:
- [ ] Searched open PRs in consumer repos for potential conflicts
- [ ] Listed affected PRs in schema PR description
- [ ] Notified contributors of upcoming change
- [ ] Provided sync commands in notifications
- [ ] Coordinated timing with critical PRs

For consumer PR authors:
- [ ] Checked for pending schema PRs before opening
- [ ] Subscribed to schema repo notifications
- [ ] Can apply sync commands when notified
- [ ] Updated PR after schema changes land

---

## Emergency Procedures

### Emergency Contacts

| Issue Type | Contact | Response Time |
|------------|---------|---------------|
| Production database down | Database Admin | Immediate |
| Schema corruption | Schema Maintainer | 15 min |
| Consumer builds broken | On-call Engineer | 30 min |
| Security incident | Security Lead | Immediate |

### Scenario 1: Schema Migration Causes Production Outage

**Symptoms:**
- Application returning 500 errors
- Database errors in logs
- User reports of broken features

**Immediate Response:**

1. **Stop the bleeding (1 minute)**
   - If using Coolify, pause deployment
   - If using Supabase, check dashboard for active issues

2. **Assess the damage (2 minutes)**
   ```bash
   # Check application logs
   tail -f /var/log/app/error.log
   
   # Check database connectivity
   psql $DATABASE_URL -c "SELECT 1"
   ```

3. **Decision point:**
   - If migration failed mid-way: Rollback to previous version
   - If migration succeeded but breaks app: Revert application code
   - If data corruption: Restore from backup

4. **Execute rollback**
   ```bash
   # Revert application code first (fastest fix)
   cd camperplaner-product
   git revert HEAD
   git push origin main
   
   # Or revert schema (if safe and necessary)
   psql $DATABASE_URL -f supabase/migrations/rollback_fix.sql
   ```

5. **Verify recovery**
   ```bash
   # Check health endpoint
   curl https://api.camperplaner.com/health
   
   # Monitor error rates
   # (via your monitoring dashboard)
   ```

### Scenario 2: PostgREST Cache Not Refreshing

**Symptoms:**
- "relation does not exist" errors after 60+ seconds
- New tables visible in psql but not via API
- Intermittent 404s on new endpoints

**Response:**

1. **Verify cache issue**
   ```sql
   -- Direct database check (should work)
   SELECT COUNT(*) FROM new_table;
   
   -- API check (may fail)
   curl https://[project].supabase.co/rest/v1/new_table
   ```

2. **Force cache reload**
   ```sql
   NOTIFY pgrst, 'reload schema';
   ```

3. **If still failing, restart PostgREST**
   - Supabase Dashboard: Database -> Restart PostgREST
   - Or CLI: supabase projects api restart

4. **Verify fix**
   ```bash
   sleep 10
   curl https://[project].supabase.co/rest/v1/new_table
   ```

### Scenario 3: Breaking Change Deployed Without Coordination

**Symptoms:**
- Worker crashes with "column does not exist"
- TypeScript compilation errors in production build
- Database constraint violations

**Response:**

1. **Identify the breaking change**
   ```bash
   # Check recent schema commits
   git log --oneline -5 -- camperplaner-schema/
   
   # Identify the breaking migration
   ls -la supabase/migrations/ | tail -5
   ```

2. **Quick fix: Revert consumers**
   ```bash
   # Revert worker immediately
   cd camperplaner-worker
   git revert HEAD
   git push origin main
   
   # Revert product if needed
   cd camperplaner-product
   git revert HEAD
   git push origin main
   ```

3. **Long-term fix:**
   - Make schema change backward-compatible
   - Or coordinate breaking change properly
   - Deploy schema first, then consumer updates

### Scenario 4: Data Corruption After Migration

**Symptoms:**
- Incorrect data in tables
- Foreign key violations
- Unexpected null values

**Response:**

1. **Stop all writes immediately**
   - Put app in maintenance mode
   - Or scale workers to zero

2. **Assess corruption scope**
   ```sql
   -- Check affected rows
   SELECT COUNT(*) FROM affected_table WHERE suspect_condition;
   
   -- Sample corrupted data
   SELECT * FROM affected_table WHERE suspect_condition LIMIT 10;
   ```

3. **Restore from backup if necessary**
   - Supabase point-in-time recovery
   - Or restore from manual backup

4. **Fix forward if possible**
   ```sql
   -- Write fix migration
   UPDATE affected_table SET column = correct_value WHERE condition;
   ```

### Scenario 5: Schema Repo Compromised

**Symptoms:**
- Unauthorized migrations in repo
- Suspicious schema changes
- Unknown commits on main branch

**Response:**

1. **Lock the repository**
   - Enable branch protection
   - Require PR reviews
   - Disable force pushes

2. **Audit changes**
   ```bash
   git log --all --since="1 week ago" --stat
   ```

3. **Rollback unauthorized changes**
   ```bash
   git revert [unauthorized-commit]
   git push origin main
   ```

4. **Rotate credentials**
   - Database passwords
   - Supabase service keys
   - CI/CD tokens


### Emergency Command Reference

```bash
# Check database connectivity
psql $DATABASE_URL -c "SELECT 1"

# List recent migrations
ls -la supabase/migrations/ | tail -10

# Check current migration state
psql $DATABASE_URL -c "SELECT * FROM schema_migrations ORDER BY version DESC LIMIT 5"

# Force PostgREST cache reload
psql $DATABASE_URL -c "NOTIFY pgrst, 'reload schema'"

# Quick revert (application)
git revert HEAD
git push origin main

# Emergency type sync
cp ../camperplaner-schema/generated/database.types.ts apps/web/src/lib/
npm run typecheck

# Check application health
curl https://api.camperplaner.com/health
```

### Post-Emergency Review

After any emergency:

1. **Document the incident**
   - What happened
   - Root cause
   - Response actions
   - Time to resolution

2. **Update procedures**
   - Add new scenarios to this document
   - Update monitoring alerts
   - Improve detection

3. **Prevent recurrence**
   - Add CI checks that would have caught the issue
   - Update review requirements
   - Improve coordination process

---

## Appendix: Quick Reference

### Migration Naming Convention

| Valid | Invalid | Reason |
|-------|---------|--------|
| 20260318143000_add_users.sql | 001_add_users.sql | Missing timestamp |
| 20260318143000_fix_indexes.sql | add_users.sql | No timestamp |
| 20260318143000_user_profiles.sql | 20260318143000-user-profiles.sql | Dashes not allowed |
| rollback_fix_users.sql | rollback.sql | Special file, descriptive name required |

### File Locations

| File Type | Schema Repo | Product Repo | Worker Repo |
|-----------|-------------|--------------|-------------|
| Migrations | supabase/migrations/ | Execute only | Never |
| Types | generated/database.types.ts | apps/web/src/lib/ | src/types/ |
| Schema Docs | docs/database-schema.md | Reference pointer | Reference pointer |
| Workflow | .github/workflows/ | .github/workflows/ | .github/workflows/ |

### Sync Status Verification

```bash
# Check if types are in sync
diff camperplaner-schema/generated/database.types.ts \
     camperplaner-product/apps/web/src/lib/database.types.ts

# Check manifest
cat camperplaner-schema/generated/schema-manifest.json | grep latest

# Check migration count
ls camperplaner-schema/supabase/migrations/*.sql | wc -l
```

### Communication Templates

**Schema Change Announcement:**
```markdown
## Schema Change Deployed

**Migration:** 20260318143000_add_user_preferences.sql
**Impact:** New table user_preferences
**Breaking:** No
**Consumers:** Both product and worker

**Required Actions:**
- [ ] Product: Sync types
- [ ] Worker: Sync types when ready

**Timeline:** Types should be synced within 24 hours.
```

**Breaking Change Notice:**
```markdown
## BREAKING Schema Change - Action Required

**Migration:** 20260318143000_rename_user_columns.sql
**Breaking:** YES - Column user_name renamed to display_name
**Impact:** Both product and worker
**Deploy Date:** 2026-03-20

**Required Actions:**
- [ ] Product: Update all queries (PR #123)
- [ ] Worker: Update job processors (PR #45)
- [ ] Sync types after schema deploy
- [ ] Deploy together on 2026-03-20

**Rollback Plan:** Revert migration with rollback_20260318_rename_user_columns.sql
```

---

## Document History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-03-18 | Initial creation | Sisyphus |

---

## Related Documents

- [AGENTS.md](./AGENTS.md) - Schema repository agent instructions
- [CONTRACT.md](./CONTRACT.md) - Consumer contract definitions
- [docs/database-schema.md](./database-schema.md) - Full schema documentation
- [docs/worker-schema-migration-guide.md](./worker-schema-migration-guide.md) - Worker-specific guidance
- [../camperplaner-product/AGENTS.md](../camperplaner-product/AGENTS.md) - Product repo instructions
- [../camperplaner-worker/AGENTS.md](../camperplaner-worker/AGENTS.md) - Worker repo instructions

---

*This document is the canonical source for schema workflow procedures. Updates must be made via PR to camperplaner-schema.*
