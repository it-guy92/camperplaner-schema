# AGENTS.md - CamperPlaner Schema Repository

This repository is the **single source of truth** for all database schema definitions in the CamperPlaner ecosystem.

---

## Repository Type

**SCHEMA REPOSITORY** - Owns all database schema, migrations, and generated artifacts.

---

## Strict Boundaries

### ✅ THIS REPO OWNS

This repository is exclusively responsible for:

1. **Database Migrations**
   - All SQL migration files in `supabase/migrations/`
   - Migration naming and versioning
   - Rollback strategies

2. **Schema Documentation**
   - `docs/database-schema.md` - Main schema overview
   - `docs/database-access-audit.md` - Full access audit
   - Any schema-related documentation

3. **Generated TypeScript Types**
   - `generated/` - Generated `database.types.ts`
   - Type generation from schema (via Supabase CLI)

4. **Schema Change Workflow**
   - Reviewing schema change proposals
   - Merging PRs that alter schema
   - Coordinating with consumers on breaking changes

### ❌ THIS REPO DOES NOT OWN

This repository must NEVER contain:

1. **Application Code** - No Next.js, React, or worker code
2. **UI Components** - No components, pages, or routes
3. **Queue Workers** - No job processing logic
4. **API Routes** - No HTTP endpoints
5. **Package Publishing** - No NPM packages beyond generated types

---

## Mandatory Rule: PR-Only Schema Changes

### Schema changes from product or worker must come through PRs in this repository.

**This is not optional. Direct edits in product or worker repos are forbidden.**

### Why This Rule Exists

- Centralized schema ownership prevents drift and conflicts
- All consumers see schema changes at the same time
- Migration history remains coherent and versioned
- Breaking changes can be coordinated across consumers

### How It Works

1. **Consumer identifies need** for schema change (e.g., new column, new table)
2. **Consumer opens PR in this repository** with:
   - Migration file(s)
   - Updated generated types
   - Updated schema documentation
3. **Schema repo reviews and merges** the PR
4. **Consumers sync** the artifacts after merge

### Example Workflow

```
camperplaner-product (you)
    │
    │ "We need a new column for campsites: is_accessible"
    │
    ▼
camperplaner-schema (this repo)
    │
    │ Create migration + types + docs
    │ Review PR, merge to main
    │
    ▼
camperplaner-product + camperplaner-worker
    │
    │ Sync artifacts (copy types, pull docs)
    │
    ▼
Both consumers updated
```

---

## Consumer Repositories

### camperplaner-product

**Role:** CONSUMER (and migration executor)

**Responsibilities:**
- Execute migrations in staging/production
- Sync `database.types.ts` to `apps/web/src/lib/`
- Reference schema docs for development
- **Open PR to schema repo for any schema changes**

**Sync command after schema merge:**
```bash
cp -r ../camperplaner-schema/generated/* apps/web/src/lib/
```

### camperplaner-worker

**Role:** CONSUMER (read-only, no migration execution)

**Responsibilities:**
- Sync `database.types.ts` to `src/types/`
- Never execute migrations
- **Open PR to schema repo for any schema changes**

**Sync command after schema merge:**
```bash
cp ../camperplaner-schema/generated/database.types.ts src/types/database.types.ts
```

---

## Artifact Generation

### Database Types

After migrations are applied, regenerate types:

```bash
# Using Supabase CLI
supabase gen types typescript --local > generated/database.types.ts
```

If local Docker/Supabase is unavailable but `.env.local` contains
`NEXT_PUBLIC_SUPABASE_URL` and `SUPABASE_DB_PASSWORD`, use the remote path:

```bash
supabase link --project-ref <ref> --password "$SUPABASE_DB_PASSWORD"
supabase db push --linked
node scripts/generate-types.js
```

The consumer sync workflow opens PRs only after `generated/database.types.ts`
changes on a push to `main`.

### Documentation

After any schema change, update:
- `docs/database-schema.md`
- `docs/database-access-audit.md` (if access patterns change)

---

## CI/CD

### What Runs Here

- Migration file validation
- Type generation verification
- Schema docs consistency checks

### What Does NOT Run Here

- No application builds
- No deployment of applications
- No worker processes

---

## Schema Change Workflow (Schema Owner)

This section defines the operational playbook for schema PRs reviewed and merged by schema owners.

### Mandatory PR Checklist

Before any schema PR can be merged, the following items MUST be present:

1. **Migration SQL present**
   - File located in `supabase/migrations/`
   - Follows naming convention: `YYYYMMDD_description.sql`
   - Includes both forward migration and rollback path documented

2. **Generated types updated**
   - `generated/database.types.ts` regenerated via `supabase gen types typescript --local`
   - Types reflect all new columns, tables, and function signatures

3. **Schema docs updated**
   - `docs/database-schema.md` reflects new schema elements
   - Breaking changes clearly marked with `**BREAKING:**` prefix

4. **Backward-compat or breaking-change note**
   - PR description includes impact assessment
   - If breaking: describes migration path for consumers

5. **Rollback note**
   - Documents how to revert this change if needed
   - Includes any data migration considerations

### Merge Gate Requirements

A schema PR MUST meet all of the following before merge:

1. **CI pipeline passes** - All validation workflows green
2. **Reviewer approval** - At least one schema owner approves
3. **No unresolved comments** - All PR discussions resolved
4. **Types generate successfully** - `supabase gen types` completes without errors

### Post-Merge Consumer Sync Contract

After schema PR merges to main, consumers MUST sync artifacts:

**Product Repo sync command:**
```bash
cp -r ../camperplaner-schema/generated/* apps/web/src/lib/
```

**Worker Repo sync command:**
```bash
cp ../camperplaner-schema/generated/database.types.ts src/types/database.types.ts
```

**Timing expectation:** Consumers should sync within 1 business day of schema merge.

### Hotfix Escalation Path

For urgent schema changes (critical bug, security patch):

1. **Create hotfix branch** from main with prefix `hotfix/`
2. **PR with expedited review** - ping schema owners directly
3. **Fast-track approval** - may proceed with single owner approval
4. **Immediate merge** - no waiting for CI if migration is trivial
5. **Post-merge notification** - alert consumers immediately via issue mention

Hotfixes still require:
- Migration SQL present
- Generated types updated
- Rollback note in PR description

---

## Agent Checklist

**When working in this repository:**

1. ✅ Creating or modifying migrations
2. ✅ Generating TypeScript types from schema
3. ✅ Updating schema documentation
4. ✅ Reviewing PRs that change schema
5. ❌ NOT adding application code
6. ❌ NOT creating API routes
7. ❌ NOT adding worker logic

**When working in consumer repos (product/worker):**

- Schema changes must be proposed as PRs in THIS repository
- Direct schema edits in consumer repos are forbidden
- Always sync artifacts after schema changes land here

---

## Cross-Repo Coordination

### Before Schema Changes

1. **Notify consumers** - Post in relevant repo or use issue
2. **Assess impact** - Breaking changes need coordination
3. **Plan migration** - Include backward-compatible steps when possible

### After Schema Changes

1. **Merge to main** - Only via PR, never direct push
2. **Tag release** - Use semantic versioning for significant changes
3. **Notify consumers** - Alert product and worker to sync

---

## Troubleshooting

### "We need a table/column NOW"

- Fast-track PR review is available for urgent changes
- Coordinate with repo maintainers

### "Our types are out of sync"

- Consumer must sync artifacts from this repo
- Check if migration was actually deployed

### "Migration failed"

- Schema repo only provides migration files
- Product repo handles execution
- Check product CI/CD logs

### "Destructive cutover fails on a column drop"

- Check dependent views/functions before dropping the column
- Recreate `campsite_full` / `campsite_api_read_model` if they still depend on
  removed `place_osm_properties` columns

---

**Last Updated:** 2026-03-18
**Enforced:** Schema changes outside this repo will be rejected
