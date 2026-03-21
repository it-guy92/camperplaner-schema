# GENERATED ARTIFACTS KNOWLEDGE BASE

## OVERVIEW
Contains generated schema artifacts consumed by downstream repositories. These files are outputs, not manual authoring targets.

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| TypeScript database contract | `generated/database.types.ts` | Generated from live schema introspection |
| Artifact/migration sync metadata | `generated/schema-manifest.json` | Tracks latest migration and artifact status |
| Generation mechanism | `scripts/generate-types.js` | Source of file updates |
| CI freshness checks | `.github/workflows/check-artifacts.yml` | Verifies existence and sync |
| Consumer sync automation | `.github/workflows/sync-schema-to-repos.yml` | Opens downstream update PRs |

## CONVENTIONS
- `generated/database.types.ts` should be produced by generation workflow, not hand edits.
- `database.types.ts` updates are coupled to migration evolution.
- `schema-manifest.json` should reflect latest migration timestamp and artifact state (follow current workflow expectations).

## ANTI-PATTERNS
- Never manually patch `generated/database.types.ts` to force compatibility.
- Never leave manifest `latest` out of sync with active migration set.
- Never copy consumer-modified artifacts back into this directory.

## SYNC SOURCE GUARD
- Canonical sync source for consumers is `generated/database.types.ts`.
- Do not reintroduce `packages/database-types` as a live sync path.

## NOTES
- Consumer repos ingest these artifacts via sync commands or automation; flow is schema repo -> consumers.
- CI treats stale generated artifacts as a validation failure.

## COMMANDS
```bash
node scripts/generate-types.js
```
