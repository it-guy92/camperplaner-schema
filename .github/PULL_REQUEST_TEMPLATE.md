## Schema Change Checklist

<!--
  Thank you for your contribution to the CamperPlaner schema!
  This repository is the single source of truth for database schema.
  
  IMPORTANT: All schema changes MUST be validated through CI.
-->

### Type of Change

- [ ] New table(s)
- [ ] New column(s) to existing table(s)
- [ ] Index or constraint changes
- [ ] Function or trigger changes
- [ ] View modifications
- [ ] Enum type changes
- [ ] Migration rollback
- [ ] Documentation update only

### Pre-Submit Checklist

#### For Schema Changes (Required)
- [ ] Migration file follows naming convention: `YYYYMMDDhhmmss_description.sql`
- [ ] Migration includes rollback script if destructive (`rollback_description.sql`)
- [ ] SQL syntax has been validated (run locally or check CI)
- [ ] No merge conflict markers in SQL files
- [ ] Downstream impact has been considered (product + worker repos)

#### For Generated Artifacts (Required)
- [ ] Ran `node scripts/generate-types.js` to update TypeScript types
- [ ] Updated `generated/schema-manifest.json` with new migration reference
- [ ] Verified `generated/database.types.ts` is not empty and exports types
- [ ] Contract document updated if breaking changes (see CONTRACT.md)

#### For Communication (Required)
- [ ] Updated CONTRACT.md with change summary for consumers
- [ ] Added migration to AGENTS.md if significant architectural change
- [ ] Noted any breaking changes in PR description

### Post-Deploy Checklist

After this PR is merged and migrations are applied:
- [ ] Verify types published to product repo (`apps/web/src/lib/database.types.ts`)
- [ ] Verify types published to worker repo (`src/types/database.types.ts`)
- [ ] Wait for PostgREST schema cache refresh (30-60 seconds)
- [ ] Run smoke tests in product repo

### Migration Details

**New Migrations:**
<!-- List new migration files in chronological order -->
1. `supabase/migrations/YYYY..._description.sql`
2. ...

**Affected Tables/Views:**
<!-- List tables, views, or functions modified -->
- 

**Breaking Changes:**
<!-- Document any breaking changes for consumers -->
- None / Column X renamed to Y / Function signature changed

**Consumer Impact:**
- [ ] No impact - backward compatible
- [ ] Requires code changes in product repo
- [ ] Requires code changes in worker repo
- [ ] Requires both product and worker updates

### Related Issues

<!--
  Link any related issues or PRs.
  Example: Closes #123, Relates to it-guy92/camperplaner-worker#45
-->

### Additional Notes

<!-- Any other context about the schema changes -->

---

**Reviewers:** Please verify that:
1. Migration naming follows convention
2. Artifacts are fresh (CI checks will validate)
3. Consumer impact is documented
4. Rollback strategy exists for destructive changes
