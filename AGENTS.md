# PROJECT KNOWLEDGE BASE

**Generated:** 2026-03-21T07:39:19Z
**Commit:** b07a693
**Branch:** main

## OVERVIEW
Schema-only repository for CamperPlaner. Owns migrations, schema docs, and generated database artifacts consumed by product and worker repos.

## STRUCTURE
```
camperplaner-schema/
|- supabase/                # active + legacy SQL migrations
|- scripts/                 # schema verification + maintenance scripts
|- generated/               # generated database types + manifest
|- docs/                    # schema reference and workflow docs
|- .github/workflows/       # migration/artifact validation + sync automation
`- .sisyphus/               # planning/evidence workspace (internal)
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Add schema change | `supabase/migrations/` | Use `YYYYMMDDhhmmss_description.sql` |
| Check old migration context | `supabase/migrations-legacy/` | Archive only; do not execute blindly |
| Regenerate types | `scripts/generate-types.js` | Writes to `generated/` |
| Validate migration state | `scripts/final-migration-verification.js` | Uses staging DB creds |
| Consumer sync contract | `CONTRACT.md` | Copy-based forward-only flow |
| Deployment/order rules | `docs/SCHEMA_WORKFLOW.md` | Canonical operational playbook |
| CI constraints | `.github/workflows/` | Naming, timestamp, artifacts, sync |

## CODE MAP
| Symbol | Type | Location | Refs | Role |
|--------|------|----------|------|------|
| `generateTypes` | function | `scripts/generate-types.js` | high | Builds TypeScript DB model |
| `mapPostgresType` | function | `scripts/generate-types.js` | high | Maps SQL types to TS types |
| `Database` | interface | `generated/database.types.ts` | high | Canonical generated type root |

## CONVENTIONS
- Schema changes are PR-only in this repository, never in consumer repos.
- `supabase/migrations/` is authoritative; `migrations-legacy/` is historical reference.
- Generated artifacts in `generated/` are outputs, not hand-edited source files.
- CI checks migration naming, timestamp order, manifest freshness, and artifact presence.

## ANTI-PATTERNS (THIS PROJECT)
- Never add app code, UI components, worker logic, or API routes here.
- Never push schema-breaking edits directly to consumer repos.
- Never bypass migration naming (`YYYYMMDDhhmmss_description.sql`) or ordering rules.
- Never treat `docs/worker-schema-migration-guide.md` as current canonical schema state.
- Never manually patch `generated/database.types.ts` instead of regenerating it.

## UNIQUE STYLES
- Heavy use of operational Markdown as canonical source documents.
- Verification scripts favor explicit staging checks over framework test runners.
- Sync model is schema-repo-first with downstream PR automation to consumers.

## COMMANDS
```bash
# generate artifacts
node scripts/generate-types.js

# schema verification
node scripts/verify-schema.js
node scripts/final-migration-verification.js

# list migration/artifact checks in CI
ls .github/workflows
```

## NOTES
- This repo validates and publishes schema artifacts; it does not run product/worker builds.
- Some historical docs/scripts describe superseded migration phases; prefer latest migration and workflow docs.
- `README.md` still references `packages/database-types`; current generated types live in `generated/`.
