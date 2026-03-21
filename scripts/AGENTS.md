# SCRIPTS KNOWLEDGE BASE

## OVERVIEW
Operational Node.js scripts for schema generation, verification, migration checks, and targeted remediation tasks.

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Regenerate typed DB contract | `scripts/generate-types.js` | Writes into `generated/` |
| Full schema verification | `scripts/verify-schema.js` | Staging DB checks with evidence output |
| Final migration gate check | `scripts/final-migration-verification.js` | Broad migration success verification |
| Quick migration health | `scripts/check-migration-status.js` | Lightweight status inspection |
| Staging migration execution helper | `scripts/run-staging-migrations.js` | Execution-oriented utility |

## CONVENTIONS
- `check-*` scripts are inspection-oriented and should stay read-focused.
- `verify-*` scripts are assertive validation checks with explicit pass/fail output.
- `generate-types.js` is the canonical generator entrypoint for `generated/` artifacts.
- DB scripts require `SUPABASE_DB_*` credentials; some scripts auto-load `.env.local`, others expect exported env vars.

## ANTI-PATTERNS
- Never embed permanent schema changes in `fix-*` script SQL; use timestamped migrations instead.
- Never treat one-off remediation scripts as durable migration history.
- Never manually edit generated files after running generator scripts.
- Never run migration execution helpers in worker-repo contexts.

## HIGH-RISK SCRIPTS
- `run-staging-migrations.js` and `apply-remaining-migrations.js` mutate staging DB state.
- `fix-rpc-*.js` scripts are remediation utilities and may contain stale migration references.

## NOTES
- Script taxonomy includes generation, verification, checks, execution helpers, and legacy fix scripts.
- Evidence-producing scripts may write artifacts under `.sisyphus/evidence/`.

## COMMANDS
```bash
node scripts/generate-types.js
node scripts/final-migration-verification.js
```
