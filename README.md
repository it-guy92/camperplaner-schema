# CamperPlaner Schema Repository

This repository is the **single source of truth** for all database schema definitions, migrations, and generated artifacts in the CamperPlaner ecosystem.

## Purpose

The schema repository owns and manages:

- **Database Migrations** - All Supabase/PostgreSQL migrations
- **Schema Documentation** - `docs/database-schema.md` and related docs
- **Generated TypeScript Types** - `database.types.ts` generated from schema
- **Access Control Definitions** - RLS policies, table permissions

## Canonical Artifacts

This repository produces the following artifacts that consumers must sync:

| Artifact | Location | Description |
|----------|----------|-------------|
| Migrations | `supabase/migrations/` | SQL migration files |
| Database Types | `packages/database-types/` | Generated TypeScript types |
| Schema Docs | `docs/` | Database schema documentation |

## Consumer Repositories

Two repositories consume artifacts from this schema repository:

### 1. camperplaner-product

The main web application. Syncs:
- `database.types.ts` → `apps/web/src/lib/`
- Schema docs for development reference

### 2. camperplaner-worker

The background job worker. Syncs:
- `database.types.ts` → `src/types/`
- No migration execution (product handles this)

## Sync Workflow

When schema changes land in this repository:

1. **Migration deployed** by product repo CI/CD
2. **Types regenerated** and committed here
3. **Consumers sync** artifacts via git pull or copy

### Sync Commands

**Product Repo:**
```bash
# After schema changes land
cd camperplaner-product
cp -r ../camperplaner-schema/packages/database-types/* apps/web/src/lib/
```

**Worker Repo:**
```bash
# After schema changes land
cd camperplaner-worker
cp ../camperplaner-schema/packages/database-types/database.types.ts src/types/
```

## Repository Structure

```
camperplaner-schema/
├── supabase/
│   └── migrations/      # Database migrations
├── packages/
│   └── database-types/ # Generated TypeScript types
├── docs/               # Schema documentation
└── .github/            # CI/CD workflows
```

## Related Repositories

- **Product**: https://github.com/it-guy92/CamperPlaner
- **Worker**: https://github.com/it-guy92/camperplaner-worker

## License

MIT
