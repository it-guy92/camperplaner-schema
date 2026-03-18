# Supabase Schema Assets

This directory contains database schema assets for the CamperPlaner project.

## Structure

```
supabase/
├── migrations/          # Organized, timestamped migrations
│   ├── 20260310000000_baseline_schema.sql
│   ├── 20260310000001_fix_campsite_prices_fk.sql
│   └── ...
└── migrations-legacy/   # Loose SQL files (quarantined)
    ├── add-ai-description-columns.sql
    ├── campsite-prices-table.sql
    └── ...
```

## migrations/

Ordered migration files. These are properly named with timestamps and should be applied in order by Supabase.

## migrations-legacy/

Loose SQL files. These were not part of the organized migration sequence and are stored here for reference/audit purposes. These files should NOT be run directly - they represent ad-hoc schema changes that may need manual review before any future application.

## Ownership

This is the **SCHEMA SOURCE OF TRUTH** repository for CamperPlaner.

- All schema changes must be made here first
- Deployed to production via Supabase CLI
- Product and worker repositories are CONSUMERS of this schema

## Origin

- Original Source: `CamperPlaner-places-sights-favorites`
- Migrated: 2026-03-13
- Schema Repository Extraction: 2026-03-18
