# Task Evidence: Create Cross-Repo Schema Change Playbook

**Task ID:** Task 15 (from schema-repo-extraction.md plan)
**Completed:** 2026-03-18
**Output:** `/home/opencode/camperplaner-schema/docs/SCHEMA_WORKFLOW.md`

---

## Summary

Created comprehensive cross-repo schema change workflow documentation covering all required sections:

1. Overview - Architecture diagram and key principles
2. Requesting Schema Changes - Process from identification to PR creation
3. PR Review Process - Review requirements, checklists, CI validation
4. Deployment Order - Critical schema-first sequence with timing
5. PostgREST Cache Refresh - Why it matters and verification commands
6. Consumer Artifact Sync - What gets synced, commands, automation options
7. Rollback Strategy - Scenarios, migration rollback, consumer rollback
8. In-Flight PR Handling - Detection, coordination, notification templates
9. Emergency Procedures - 5 scenarios with step-by-step responses

---

## Verification

### File Created
```
/home/opencode/camperplaner-schema/docs/SCHEMA_WORKFLOW.md
905 lines, ~38KB
```

### All Sections Present
```
## Table of Contents
## Overview
## Requesting Schema Changes
## PR Review Process
## Deployment Order
## PostgREST Cache Refresh
## Consumer Artifact Sync
## Rollback Strategy
## In-Flight PR Handling
## Emergency Procedures
## Appendix: Quick Reference
## Document History
## Related Documents
```

### Key Content Delivered

**Consumer Sync Commands:**
- Product: `cp ../camperplaner-schema/generated/database.types.ts apps/web/src/lib/`
- Worker: `cp ../camperplaner-schema/generated/database.types.ts src/types/`

**Deployment Timeline:**
1. Schema PR merges (1 min)
2. Product applies migration (2-4 min)
3. Wait PostgREST cache (30-60 sec) - CRITICAL
4. Product syncs artifacts (1 min)
5. Worker syncs artifacts (1 min)
Total: 5-8 minutes

**In-Flight PR Handling:**
- Detection via git log and gh pr list
- Notification templates provided
- Hold/fast-track decision matrix
- Post-schema update procedures

**Emergency Scenarios Covered:**
1. Schema migration causes production outage
2. PostgREST cache not refreshing
3. Breaking change deployed without coordination
4. Data corruption after migration
5. Schema repo compromised

---

## Integration with Existing Docs

The playbook integrates with existing schema repo documentation:
- References AGENTS.md for ownership rules
- References CONTRACT.md for consumer contracts
- References database-schema.md for schema details
- Uses same format as worker-schema-migration-guide.md
- Follows same table/heading conventions

---

## Next Steps (for orchestrator)

This document is complete and ready for use. Related tasks from the plan that may reference this:
- Task 12: Product repo docs conversion
- Task 14: Worker repo docs conversion
- Final verification tasks F1-F4

The workflow document provides the canonical reference for:
- How to request schema changes (any repo -> schema PR)
- PR review requirements and process
- Deployment sequence (schema first, cache wait, then consumers)
- Consumer artifact sync commands
- Rollback procedures
- In-flight PR coordination
- Emergency response procedures

---

**Evidence captured by:** Sisyphus-Junior  
**Document ready for:** Cross-repo schema governance implementation
