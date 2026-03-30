# Premium Billing Schema Handoff

> **Location:** `/home/opencode/camperplaner-schema/docs/premium-billing-schema-handoff.md`
> **Status:** PROPOSED
> **Last Updated:** 2026-03-28
> **Target Audience:** Schema maintainers, product engineers, worker maintainers

---

## Table of Contents

1. [Overview](#overview)
2. [Problem Statement](#problem-statement)
3. [Scope](#scope)
4. [Non-Scope](#non-scope)
5. [Consumer Context](#consumer-context)
6. [Proposed Schema Shape](#proposed-schema-shape)
7. [Recommended Table Designs](#recommended-table-designs)
8. [Recommended RLS / Access Model](#recommended-rls--access-model)
9. [Recommended RPC / View Shape](#recommended-rpc--view-shape)
10. [Deployment Order](#deployment-order)
11. [Rollback / Failure Handling](#rollback--failure-handling)
12. [Open Questions](#open-questions)
13. [Implementation Checklist for Schema Agent](#implementation-checklist-for-schema-agent)
14. [References](#references)

---

## Overview

CamperPlaner Product now contains the first application scaffolding for a Premium membership rollout:

- pricing page
- profile “plan” area
- premium upgrade dialogs
- gated server-side flows for saved trips, vehicle profiles, favorites, and exports
- Stripe checkout / portal / webhook preparation

What is still missing is the canonical schema support for:

- billing customer linkage
- subscription state storage
- product entitlement resolution
- support/debug visibility into billing state

This document is the handoff for the schema repository so the schema agent can implement the missing database contract.

---

## Problem Statement

The product repository can already:

- initiate Stripe checkout
- open Billing Portal
- verify Stripe webhooks
- present premium-gated UI flows

But it still resolves plan state from a scaffold fallback because the database lacks authoritative persistence for:

- Stripe customer identity
- Stripe subscription lifecycle state
- resolved product entitlements

Without this schema work, the application cannot safely answer:

- Does this user currently have Premium?
- Which plan is active?
- Which limits and capabilities apply?
- Did a webhook update succeed?

---

## Scope

This handoff proposes additive schema support for:

1. user ↔ Stripe customer mapping
2. subscription persistence
3. resolved entitlement snapshots
4. optional helper RPC/view for consumer repos
5. generated types for product/worker sync

---

## Non-Scope

This handoff does **not** request:

- UI changes
- worker runtime changes
- family/team billing
- comments / likes / creator monetization
- usage-based billing

---

## Consumer Context

### Product repo expectations

The product repo expects the schema eventually to support a durable current plan lookup for an authenticated user and entitlement-based checks for:

- saved trip limits
- vehicle profile limits
- favorite limits
- export capability
- advanced filters capability
- later: trip templates capability

### Worker repo expectations

No immediate worker dependency is required, but generated types may later be used for reconciliation or audit jobs.

---

## Proposed Schema Shape

### Design goals

- additive only
- minimal but durable
- product-code-friendly
- auditable enough for support
- no UI coupling to raw Stripe payloads

### Required concepts

1. Billing customer identity
2. Subscription state
3. Entitlement snapshot
4. Stable consumer access surface

---

## Recommended Table Designs

## 1. `billing_customers`

### Purpose

Maps a CamperPlaner user to a Stripe customer.

### Recommended columns

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | uuid | PK, default gen_random_uuid() | internal id |
| `user_id` | uuid | FK → `profiles.id`, unique, not null | one billing customer per user |
| `provider` | text | not null, default `'stripe'` | future-proofing |
| `provider_customer_id` | text | unique, not null | Stripe customer id |
| `email_snapshot` | text | null | optional debug field |
| `created_at` | timestamptz | not null, default now() | |
| `updated_at` | timestamptz | not null, default now() | |

## 2. `billing_subscriptions`

### Purpose

Stores the latest normalized subscription state per Stripe subscription.

### Recommended columns

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | uuid | PK, default gen_random_uuid() | internal id |
| `user_id` | uuid | FK → `profiles.id`, not null | owner |
| `billing_customer_id` | uuid | FK → `billing_customers.id`, not null | normalized linkage |
| `provider` | text | not null, default `'stripe'` | |
| `provider_subscription_id` | text | unique, not null | Stripe subscription id |
| `provider_price_id` | text | null | Stripe price id |
| `plan_code` | text | not null | `free`, `premium_monthly`, `premium_yearly` |
| `status` | text | not null | normalized Stripe status |
| `current_period_start` | timestamptz | null | |
| `current_period_end` | timestamptz | null | |
| `cancel_at_period_end` | boolean | not null, default false | |
| `canceled_at` | timestamptz | null | |
| `trial_end` | timestamptz | null | optional |
| `last_webhook_event_id` | text | null | support/debug aid |
| `last_synced_at` | timestamptz | not null, default now() | |
| `created_at` | timestamptz | not null, default now() | |
| `updated_at` | timestamptz | not null, default now() | |

### Recommended indexes

- unique index on `provider_subscription_id`
- index on `user_id`
- index on `(user_id, status)`

## 3. `user_entitlements`

### Purpose

Stores the product-readable current entitlement snapshot.

### Recommended columns

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | uuid | PK, default gen_random_uuid() | internal id |
| `user_id` | uuid | FK → `profiles.id`, unique, not null | one current snapshot per user |
| `plan_code` | text | not null | current resolved plan |
| `is_premium` | boolean | not null, default false | fast check |
| `features` | jsonb | not null, default `'{}'::jsonb` | capability map |
| `limits` | jsonb | not null, default `'{}'::jsonb` | limit map |
| `source_subscription_id` | uuid | FK → `billing_subscriptions.id`, null | provenance |
| `effective_from` | timestamptz | not null, default now() | |
| `effective_until` | timestamptz | null | optional |
| `updated_at` | timestamptz | not null, default now() | |

### Recommended `features` payload

```json
{
  "can_export_trip": true,
  "can_use_advanced_filters": true,
  "can_use_trip_templates": false
}
```

### Recommended `limits` payload

```json
{
  "max_saved_trips": null,
  "max_vehicle_profiles": 5,
  "max_favorites": null
}
```

### Free defaults

```json
{
  "plan_code": "free",
  "is_premium": false,
  "features": {
    "can_export_trip": false,
    "can_use_advanced_filters": false,
    "can_use_trip_templates": false
  },
  "limits": {
    "max_saved_trips": 2,
    "max_vehicle_profiles": 1,
    "max_favorites": 20
  }
}
```

---

## Recommended RLS / Access Model

### `billing_customers`

- authenticated user may `select` only their own row
- no direct client insert/update/delete

### `billing_subscriptions`

- authenticated user may `select` only their own rows if needed
- no direct client insert/update/delete
- webhook / service-role path owns writes

### `user_entitlements`

- authenticated user may `select` only their own row
- normal clients should not mutate it
- service role / trusted server path owns writes

---

## Recommended RPC / View Shape

Optional but strongly recommended.

## Option A — `current_user_entitlements` view

Suggested fields:

- `user_id`
- `plan_code`
- `is_premium`
- `features`
- `limits`
- `subscription_status`
- `current_period_end`
- `cancel_at_period_end`

## Option B — RPC `get_current_user_entitlements()`

Preferred if maintainers want a tighter read contract.

Recommendation: if only one helper is added, prefer the RPC because product repos should not know too much about internal joins.

---

## Deployment Order

1. Schema PR merges
2. Product repo syncs generated types
3. Product webhook begins writing `billing_customers`, `billing_subscriptions`, `user_entitlements`
4. Product billing summary switches from scaffold to DB-backed state
5. Premium rollout flag can be enabled for real subscriptions

---

## Rollback / Failure Handling

### Recommended safety rules

- additive migrations only
- do not remove or repurpose existing product tables
- free-state fallback remains possible if entitlement rows are missing

### Product-side fallback expectation

If a user has no entitlement row yet, product should safely treat them as:

- `plan_code = free`
- `is_premium = false`

---

## Open Questions

1. Snapshot table vs derived view vs RPC?
2. Single active subscription vs full history?
3. Do we want a webhook audit table?
4. Where should plan-code normalization live?
5. Should `user_entitlements` be rebuilt idempotently from subscription state? Recommended: yes.

---

## Implementation Checklist for Schema Agent

- [ ] Add migration for `billing_customers`
- [ ] Add migration for `billing_subscriptions`
- [ ] Add migration for `user_entitlements`
- [ ] Add indexes and constraints
- [ ] Add RLS policies
- [ ] Add updated_at triggers if repo conventions require them
- [ ] Add either a view or RPC for current entitlement reads
- [ ] Regenerate `generated/database.types.ts`
- [ ] Regenerate required manifest outputs
- [ ] Document consumer impact in the implementation PR

### Recommended implementation PR title

`feat(schema): add premium billing and entitlement tables`

### Recommended migration naming direction

`YYYYMMDDhhmmss_add_premium_billing_and_entitlements.sql`

---

## References

- `CONTRACT.md`
- `docs/SCHEMA_WORKFLOW.md`
- `docs/database-schema.md`
- Product-side planning docs in `/home/opencode/camperplaner-product/docs/`
  - `premium-v1-decision-record.md`
  - `premium-billing-entitlements-implementation-plan.md`
  - `premium-usage-limits-gating-plan.md`
