# Problems: Expand-Contract Migration (Unresolved)

## Task 6 Open Items

### Problem 1: CI Validation for Lock Timeout
**Status:** NOT IMPLEMENTED
**Description:** No CI check to verify DDL files include `lock_timeout`
**Next:** Add workflow step to grep for `lock_timeout` in migration files

### Problem 2: Evidence Artifact Generation Script
**Status:** NOT IMPLEMENTED
**Description:** No script to auto-generate pre-cleanup evidence
**Next:** Create `scripts/generate-cleanup-evidence.js`

### Problem 3: Batch Size Defaults
**Status:** NOT DEFINED
**Description:** No standard batch size for large table migrations
**Next:** Define batch size (10k recommended) in migration guide

### Problem 4: Consumer Migration Status Tracking
**Status:** NOT IMPLEMENTED
**Description:** No way to verify all consumers on new schema before cleanup
**Next:** Add version tracking in schema (e.g., `schema_version` table)

### Problem 5: 24-Hour Observation Window
**Status:** NOT AUTOMATED
**Description:** Manual check, not automated gate
**Next:** Add timestamp check in CI before Phase 3

---

Last Updated: 2026-03-18

## Task 4 Open Items

### Problem 6: Amenity Key Coverage Verification
**Status:** NOT VERIFIED
**Description:** Mapping assumes 17 standard amenity keys; actual keys in production may differ
**Next:** Query production place_google_amenities for distinct amenity_key values

### Problem 7: LLM Fact Field Name Coverage
**Status:** NOT VERIFIED
**Description:** Mapping assumes standard field names; actual field_name values may include custom fields
**Next:** Query production place_llm_facts for distinct field_name values

### Problem 8: Cold Storage Archive Strategy
**Status:** NOT DEFINED
**Description:** No decision on where/how to archive source_evidence and evidence_markers
**Next:** Define archive format (JSON export?) and storage location (S3 bucket?)

### Problem 9: Confidence Aggregation Function
**Status:** NOT DEFINED
**Description:** No decision on how to aggregate per-fact confidence into data_confidence
**Next:** Define aggregation function (average, max, weighted average)

### Problem 10: Backfill NULL Preservation Verification
**Status:** NOT VERIFIED
**Description:** Must verify backfill scripts preserve NULL = no-claim semantics
**Next:** Add validation query to check for unexpected false values in backfilled data

