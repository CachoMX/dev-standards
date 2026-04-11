# Changelog

All notable changes to dev-standards are documented here.

---

## [Unreleased]

---

## [1.4.1] — 2026-04-10

### Added
- `architecture/accessibility.md` — WCAG 2.1 AA standards (was present locally, now tracked)

### Removed
- Stray `*.sync-conflict-*` copies (README, `ci-cd/ci.yml`, `deploy-checklist.md`) from an old sync tool

### Changed
- `README.md` — repo tree lists `performance.md` and `accessibility.md`

---

## [1.4.0] — 2026-04-10

### Added
- `architecture/nextjs.md` — §5e webhook routes (raw body vs `parseBody`), middleware public paths for webhooks, cron bearer secret; checklist/deploy items for RLS same-release, webhook/cron env
- `architecture/performance.md` — dashboard/chart-heavy pages: minimize `'use client'` boundaries, memoization, virtualization, Next cache note
- `security/security-standards.md` — service-role tenant scoping + grep audit; app-layer permissions when RLS cannot encode role matrix; webhooks/crons/debug persistence (PII redaction); cron `CRON_SECRET`; nuanced rule for provider webhook URLs vs user-facing URL secrets; `npm audit` / `continue-on-error` + `exceljs` vs `xlsx` in checklist
- `deployment/deploy-checklist.md` — CI audit visibility; RLS policies same release as tables; webhook + cron env; service-role grep; Supabase types regen; optional hex grep; failure table rows for charts/webhooks
- `errors/common-errors-and-lessons.md` — chart/SVG hardcoded colors; `xlsx` vs `exceljs`; Vitest `vi.stubEnv`; documentation drift; checklist fixes for webhooks vs `parseBody`

### Improved
- `architecture/api-patterns.md` — webhook handler example uses single `req.text()` + verify + parse; "Three Rules" footnote excluding webhooks from `parseBody` on first read

---

## [1.3.0] — 2026-04-10

### Added
- `architecture/nextjs.md` — Next.js App Router standards: required files (`error.tsx`, `not-found.tsx`, `loading.tsx`), server vs client components, `force-dynamic`, `parseBody` Zod helper, explicit column selects, idempotency guards, `router.refresh()` pattern, Supabase two-client model, Sentry integration, SDK union type safety, full checklist

### Improved
- `security/security-standards.md` — added "Explicit Column Selects" (no `SELECT *`), "Idempotency Guards", and "API Route Validation (Next.js)" sections with `parseBody` helper; updated security review checklist
- `architecture/api-patterns.md` — added "Next.js App Router API Routes" section with mandatory route template, `parseBody` helper, and the three rules (force-dynamic / parseBody / explicit selects)
- `deployment/deploy-checklist.md` — security section: explicit selects + idempotency guards; data section: migration + rollback script requirement; monitoring section: Sentry DSN env vars + `error.tsx` / `not-found.tsx` checks
- `errors/common-errors-and-lessons.md` — added 5 new error patterns from PingItNow GOD-AUDIT: Next.js prerender crash (force-dynamic), `window.location.reload()` vs `router.refresh()`, `SELECT *` data leakage, Stripe SDK union types, Vitest coverage threshold misconfiguration; updated pre-development checklist with Next.js section
- `README.md` — added `nextjs.md` to repo structure; updated Quick Start to reference it for Next.js projects

---

## [1.2.0] — 2026-02-16

### Added
- `scripts/setup-new-project.sh` — automated project setup script
- `testing/testing-strategy.md` — Playwright E2E test examples (login, CRUD, filters, helpers)
- `templates/CLAUDE.md.template` — common feature patterns (auth, CRUD, forms, URL state, external APIs)

### Improved
- `deployment/deploy-checklist.md` — performance metrics, monitoring alerts, common failures table, post-deploy communication
- `testing/testing-strategy.md` — test coverage goals, playwright config

---

## [1.1.0] — 2026-02-16

### Added
- `architecture/api-patterns.md` — standard response format, pagination, error codes, rate limiting, retry
- `ci-cd/ci.yml` — GitHub Actions workflow (quality, tests, security jobs)
- `ci-cd/ci-cd-guide.md` — setup guide, branch protection, CD patterns
- `git/git-workflow.md` — branch strategy, commit conventions, PR process, release flow
- `security/security-standards.md` — env vars, RLS, input validation, auth, dependencies
- `testing/testing-strategy.md` — test pyramid, Vitest patterns, minimum requirements
- `deployment/deploy-checklist.md` — pre-deploy checklist, rollback procedures

### Improved
- `agents/code-reviewer.md` — added API patterns, security, and test coverage checks
- `agents/developer.md` — added API response format, security rules, git conventions
- `agents/orchestrator.md` — structured workflow phases with gates and decision tables
- `agents/tester.md` — added testing-strategy.md reference and automated verification
- `README.md` — new repo structure, setup sequence, and usage examples
- `templates/CLAUDE.md.template` — added API response format and security sections

---

## [1.0.0] — 2026-02-16

### Added
- Initial commit
- `architecture/stack-defaults.md` — tech stack defaults (React 19, Vite, TypeScript, TanStack Query, Zustand, shadcn/ui)
- `architecture/bulletproof-react-prompt.md` — Claude Code prompt for new projects
- `architecture/bulletproof-react-refactor.md` — Claude Code prompt for refactoring
- `errors/common-errors-and-lessons.md` — recurring error patterns from PingItNow, closers-quantum, aso-platform, vet-manager, mundosolar, kpi-tracker-saas
- `templates/CLAUDE.md.template` — base project CLAUDE.md template
- `templates/.env.example.template` — environment variable template
- `agents/developer.md` — developer agent instructions
- `agents/code-reviewer.md` — code review agent instructions
- `agents/tester.md` — QA agent instructions
- `agents/orchestrator.md` — multi-agent coordinator
