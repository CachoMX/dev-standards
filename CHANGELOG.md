# Changelog

All notable changes to dev-standards are documented here.

---

## [Unreleased]

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
