-- ============================================================================
-- No-op migration to trigger CI validation after workflow fixes
-- Date: 2026-03-18
-- Purpose: Force CI to re-run validate-migrations.yml with fixed grep
--         pattern and naming convention exception. This file does nothing.
-- ============================================================================

-- This migration intentionally does nothing. It exists solely to trigger CI.
-- All actual schema changes are in the timestamped migration files.
SELECT 1 AS noop;
