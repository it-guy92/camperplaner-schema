# SUPABASE KNOWLEDGE BASE

## OVERVIEW
Owns SQL migration source of truth for this repository: active migrations in `migrations/`, historical context in `migrations-legacy/`.

## STRUCTURE
```
supabase/
|- migrations/          # active ordered migrations, applied in sequence
|- migrations-legacy/   # archive-only historical SQL files
|- .temp/               # local temp artifacts, non-canonical
`- README.md            # directory-specific operational notes
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Add new schema change | `supabase/migrations/` | Must use timestamped naming |
| Validate migration naming expectations | `.github/workflows/validate-migrations.yml` | CI enforces format and ordering |
| Review latest heavy cutovers | `supabase/migrations/` | Inspect newest multi-step files before extending |
| Check rollback convention | `supabase/migrations/` | Rollback files are exceptional, not normal stream |
| Understand old pre-sequenced SQL | `supabase/migrations-legacy/` | Reference only |

## CONVENTIONS
- Active migration naming: `YYYYMMDDhhmmss_description.sql`.
- Active migrations are append-only and chronological.
- `migrations-legacy/` files are archival context, not active migration stream.
- Complex cutovers may set explicit `lock_timeout` and `statement_timeout`.
- Prefer additive changes; coordinate destructive/breaking changes with consumers and rollback notes.

## ANTI-PATTERNS
- Never place ad-hoc one-off SQL fixes in `migrations/` without timestamp naming.
- Never execute `migrations-legacy/` blindly in production workflows.
- Never reorder, rename, or mutate historical active migration filenames.
- Never bypass CI naming/order checks by using non-timestamp active filenames.

## NOTES
- Current active set is index-heavy; split future large schema + index rollouts when practical.
- Non-timestamp rollback files remain explicit exceptions and should stay rare.
