# Refactor Playbook

## Purpose

Use this playbook when changing structure, boundaries, or shared patterns in an existing app. The goal is to improve architecture without breaking behavior.

This is mandatory for:
- Any `refactor/*` branch
- Any migration to Bulletproof React
- Any "large cleanup" touching multiple features
- Any auth, billing, or integration flow refactor

See also:
- `architecture/stack-defaults.md`
- `architecture/api-patterns.md`
- `testing/testing-strategy.md`
- `deployment/deploy-checklist.md`
- `errors/common-errors-and-lessons.md`

---

## Refactor Principles

1. Preserve behavior first, improve structure second.
2. Avoid big-bang rewrites. Ship in small, reversible slices.
3. Keep data and billing mutations idempotent.
4. `GET`/`HEAD` routes remain side-effect free.
5. No cross-feature imports after each slice.
6. Treat auth/billing warnings and deprecations as release blockers.

---

## Phase 0: Baseline Snapshot

Before moving code, capture current behavior.

```bash
npm run type-check
npm run lint
npm run build
npm run test -- --run
```

Record:
- Current critical user flows
- Existing API contracts (status codes + response shape)
- Known warnings in browser/server logs
- Current performance baseline for the most important page(s)

If baseline is already broken, document exact failures first and keep scope limited to those repairs.

---

## Phase 1: Discovery and Risk Map

Create a short inventory:
- Features touched
- Shared modules touched
- API routes touched
- External integrations touched
- Database tables and mutations touched

Classify risk:
- Low: UI-only or internal structure move
- Medium: feature logic or query changes
- High: auth, billing, subscriptions, webhooks, cron jobs, tenant isolation

For Medium/High risk slices, define:
- Primary success metric
- Rollback plan
- Owner for verification

---

## Phase 2: Plan Slices

Build small slices with clear boundaries:

1. Skeleton and boundaries
   - Create target folders/modules
   - Add `index.ts` public exports
   - Add lint boundary rules if missing
2. Move pure/shared code
   - `types`, `utils`, static helpers
3. Move feature internals
   - `api`, `hooks`, `components`, `stores`
4. Update app composition
   - routes/providers/layout composition only
5. Remove dead paths
   - delete unused files and stale imports

Rules per slice:
- One logical outcome per PR
- No refactor + feature behavior change in the same PR unless explicitly approved
- Keep old and new paths from diverging for long periods

---

## Phase 3: Execution Rules

- Use explicit column selects in API routes (never `select('*')`).
- Validate all mutation bodies with Zod (`parseBody` in Next.js JSON routes).
- Signed webhooks use `request.text()` + signature verification before JSON parse.
- Keep protected endpoint failures explicit (`401`/`403`) and test both signed-out and signed-in paths.
- Replace deprecated API/auth props while touching affected flows.
- Remove temporary toggles and migration shims before closing the final slice unless intentionally kept with an owner and expiry date.

---

## Phase 4: Verification Gates (Blocking)

Every refactor PR must pass:

```bash
npm run type-check
npm run lint
npm run build
npm run test -- --run
```

Required verification:
- Auth-boundary smoke for critical endpoints (signed-out and signed-in)
- Billing/subscription consistency check if payments are involved
- No new deprecation warnings in auth/billing/integration paths
- No secret leaks or placeholder envs in release environments

Additional gates by stack:

Vite + React:
- Feature import boundaries enforced
- No `any`, `@ts-ignore`, or non-null assertions in touched files

Next.js:
- `force-dynamic` on auth/cookie/header dependent routes/layouts
- Webhook raw-body verification and middleware public-path coverage
- `router.refresh()` used instead of full reload when updating server data

Fastify:
- Auth preHandlers and tenant scoping preserved
- `npm audit` fixes verified with build + tests after dependency upgrades

---

## Phase 5: Release and Rollback

Before merge:
- Include "Refactor Risk Notes" in PR description
- Include test evidence and smoke evidence
- Confirm rollback path for schema/API changes

After deploy:
- Re-run critical smoke (auth, billing, integrations)
- Confirm no warning spikes or 401/403 storms
- If regression appears, rollback first, then patch forward

---

## Definition of Done

A refactor is complete only when all are true:
- Behavior is preserved (or explicitly changed and documented)
- Architecture boundaries are cleaner than before
- CI and smoke gates pass
- Dead code from old paths is removed
- Docs are updated (`CHANGELOG`, affected standards docs, and project notes)
