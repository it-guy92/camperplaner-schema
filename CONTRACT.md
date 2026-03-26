# Schema Repository Contract

**Repository:** `camperplaner-schema`  
**Purpose:** Single source of truth for database schema artifacts  
**Version:** 1.0.0

---

## 1. Authoritative Artifacts (Owned by Schema Repo)

These files are **owned** by this repository and are the canonical source:

| Path | Description | Consumers |
|------|-------------|-----------|
| `supabase/migrations/*.sql` | SQL migration files | Product, Worker (read-only) |
| `supabase/migrations-legacy/*.sql` | Deprecated/archived migrations | Reference only |
| `docs/*.md` | Schema documentation | Product, Worker, external |
| `scripts/*.sql` | Utility/ad-hoc SQL scripts | Product, Worker |
| `generated/schema-manifest.json` | Pinned artifact manifest | Product, Worker |

---

## 2. Copied Artifacts (Generated/Exported)

These files are **generated** from authoritative sources and must be copied into consuming repos:

| Generated File | Source | Copy Target (Product) | Copy Target (Worker) |
|----------------|--------|----------------------|---------------------|
| `database.types.ts` | `supabase migrations` | `apps/web/src/lib/database.types.ts` | `src/types/database.types.ts` |
| `schema.sql` | `supabase migrations` | (reference only) | (reference only) |

---

## 3. Copy-Based Contract

**Rule:** Consumer repositories (product, worker) MUST NOT edit copied artifacts directly.

### Workflow:
1. **Schema Repo** owns migrations and generates `database.types.ts`
2. **Export Step** copies `database.types.ts` → Product/Worker repos
3. **Consumer Repos** use copied file locally (never edit manually)
4. **Schema Changes** flow only forward: Schema Repo → Consumers

### Copy Commands (documented in consumer repos):
```bash
# From schema repo root
cp generated/database.types.ts ../camperplaner-product/apps/web/src/lib/
cp generated/database.types.ts ../camperplaner-worker/src/types/
```

---

## 4. Schema Manifest

`generated/schema-manifest.json` serves as the pinned artifact record:

```json
{
  "version": "1.0.0",
  "schema_hash": "abc123...",
  "generated_at": "2026-03-18T12:00:00Z",
  "artifacts": [
    {
      "name": "database.types.ts",
      "source": "supabase migrations",
      "checksum": "sha256:..."
    }
  ],
  "migrations": {
    "latest": "20260318_add_xyz.sql",
    "count": 47
  }
}
```

**Purpose:** Enables consumers to detect schema drift and verify artifact sync.

---

## 5. Directory Purposes

| Directory | Purpose |
|-----------|---------|
| `supabase/migrations/` | Active SQL migrations (authoritative) |
| `supabase/migrations-legacy/` | Archived/deprecated migrations |
| `docs/` | Schema documentation, ER diagrams |
| `scripts/` | Ad-hoc SQL utilities, seed scripts |
| `generated/` | Generated TypeScript types, manifest |

---

## 6. CI/CD Integration

Schema repo CI should:
1. Validate all SQL migrations (syntax check)
2. Generate `database.types.ts` from live schema
3. Update `schema-manifest.json` with new checksums
4. Tag release (e.g., `v1.2.3`)

Consumer repos CI should:
1. Optionally verify `schema-manifest.json` matches expected version
2. Copy new artifacts after schema repo tags

---

## 7. Migration Path

For existing schema artifacts in product repo:
- `supabase/migrations/` → Copy to `camperplaner-schema/supabase/migrations/`
- `docs/database-schema.md` → Copy to `camperplaner-schema/docs/`
- Generated types → Regenerate from schema repo after transfer

---

**Latest migration reference:** `20260326090000_create_place_media_assets.sql`
**Last Updated:** 2026-03-26
