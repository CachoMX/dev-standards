# Dev Standards

![CI](https://github.com/CachoMX/dev-standards/actions/workflows/ci.yml/badge.svg)

Centralized development standards, architecture guides, error patterns, and Claude Code instructions for all projects by Carlos Aragon / AragonAutomates.

## Purpose

This repo serves as the single source of truth for:

- **Architecture patterns** — Bulletproof React structure, stack defaults, API design, and coding standards
- **Error prevention** — Documented errors and lessons learned across all projects
- **CI/CD** — GitHub Actions pipeline and deployment automation
- **Git workflow** — Branch strategy, commit conventions, PR process
- **Security** — Environment variables, RLS, input validation, dependency audit
- **Testing** — Test strategy, patterns, minimum requirements
- **Deployment** — Pre-deploy checklist and rollback procedures
- **Templates** — Reusable CLAUDE.md, .env, and project scaffolding templates
- **Agent configs** — Claude Code agent definitions for automated workflows

## Quick Start

When starting any new project:

1. Read `errors/common-errors-and-lessons.md` — mandatory before writing any code
2. Follow `architecture/stack-defaults.md` for tech stack decisions (Vite + React) or `architecture/nextjs.md` for Next.js App Router projects
3. Use `architecture/bulletproof-react-prompt.md` as your Claude Code prompt (Vite projects)
4. Copy `templates/CLAUDE.md.template` into your project root and fill in project details
5. Copy `templates/.env.example.template` and fill in values
6. Copy `ci-cd/ci.yml` to `.github/workflows/ci.yml`
7. Set up branch protection following `ci-cd/ci-cd-guide.md`
8. Share `git/git-workflow.md` with the team

When deploying:

1. Run through `deployment/deploy-checklist.md`
2. Run through `security/security-standards.md` security review checklist

## Repo Structure

```
dev-standards/
├── README.md                              # This file
├── architecture/
│   ├── stack-defaults.md                  # Default tech stack for all apps
│   ├── api-patterns.md                    # API response format, pagination, error codes
│   ├── nextjs.md                          # Next.js App Router standards (force-dynamic, parseBody, Sentry, etc.)
│   ├── bulletproof-react-prompt.md        # Claude Code prompt for new projects
│   └── bulletproof-react-refactor.md      # Claude Code prompt for refactoring existing projects
├── ci-cd/
│   ├── ci.yml                             # GitHub Actions workflow (copy to .github/workflows/)
│   └── ci-cd-guide.md                     # CI/CD setup, configuration, and troubleshooting
├── git/
│   └── git-workflow.md                    # Branch strategy, commits, PRs, releases
├── security/
│   └── security-standards.md              # Env vars, RLS, input validation, auth, dependencies
├── testing/
│   └── testing-strategy.md                # Test pyramid, patterns, Vitest config, minimum reqs
├── deployment/
│   └── deploy-checklist.md                # Pre-deploy verification and rollback procedures
├── errors/
│   └── common-errors-and-lessons.md       # Error patterns and prevention (MANDATORY READ)
├── templates/
│   ├── CLAUDE.md.template                 # Template for project-level CLAUDE.md
│   └── .env.example.template              # Template for environment variables
├── scripts/
│   └── setup-new-project.sh               # Automated new project setup
├── agents/
│   ├── developer.md                       # Developer agent instructions
│   ├── code-reviewer.md                   # Code review agent instructions
│   ├── tester.md                          # QA/testing agent instructions
│   └── orchestrator.md                    # Multi-agent coordinator instructions
└── CHANGELOG.md                           # Version history
```

## How to Use

### For Claude Code (Terminal)

Reference files directly in your prompts:

```bash
# When starting a new project
claude "Read dev-standards/architecture/bulletproof-react-prompt.md and create the app described below: ..."

# When working on any feature
claude "Read dev-standards/errors/common-errors-and-lessons.md before implementing this feature: ..."
```

Or add to your project's CLAUDE.md:

```markdown
## External Standards
Before any development, read these files from the dev-standards repo:
- `../dev-standards/errors/common-errors-and-lessons.md`
- `../dev-standards/architecture/stack-defaults.md`
- `../dev-standards/security/security-standards.md`
```

### For Claude.ai (Chat)

Upload the relevant files when starting a conversation about a new project or feature. Key files are already reflected in Claude's memory.

### For Your Team

Share this repo with Ricardo, Marco, Ruth, and the rest of the team:
- Everyone reads `errors/common-errors-and-lessons.md` before starting
- Everyone follows `git/git-workflow.md` for branches and commits
- CI pipeline enforces standards automatically via `ci-cd/ci.yml`
- `deployment/deploy-checklist.md` is the go/no-go for production

## New Project Setup Sequence

**Option A — Automated (recommended):**
```bash
# From the directory where your projects live
./dev-standards/scripts/setup-new-project.sh my-new-app
```

**Option B — Manual:**
```
1. Clone dev-standards repo alongside your project
2. Copy CLAUDE.md.template → project/CLAUDE.md
3. Copy .env.example.template → project/.env.example
4. Copy ci.yml → project/.github/workflows/ci.yml
5. Set up branch protection on main (see ci-cd-guide.md)
6. Initialize project with bulletproof-react-prompt.md
7. Run security checklist before first deploy
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                      app/ (thin)                         │
│  routes/ + providers/ — imports features, no logic       │
└──────────────┬──────────────────────────────────────────┘
               │ imports
┌──────────────▼──────────────────────────────────────────┐
│                   features/ (THE CORE)                   │
│  ┌────────────┐  ┌────────────┐  ┌────────────────────┐ │
│  │   leads/   │  │   deals/   │  │   auth/            │ │
│  │ api/       │  │ api/       │  │ api/               │ │
│  │ components/│  │ components/│  │ hooks/             │ │
│  │ hooks/     │  │ hooks/     │  │ components/        │ │
│  │ types/     │  │ types/     │  │ index.ts           │ │
│  │ index.ts   │  │ index.ts   │  └────────────────────┘ │
│  └────────────┘  └────────────┘                         │
│         ❌ NO cross-feature imports                       │
└──────────────┬──────────────────────────────────────────┘
               │ imports
┌──────────────▼──────────────────────────────────────────┐
│                    shared/ (reusable)                    │
│  components/  hooks/  lib/  types/  utils/  stores/     │
└─────────────────────────────────────────────────────────┘
```

## Rules

1. **This is a living repo** — update it as new patterns emerge
2. **Never commit credentials** — no API keys, tokens, or passwords
3. **Keep it project-agnostic** — specific project details go in project repos, not here
4. **Error docs are mandatory** — every developer must read them before starting work
5. **CI must pass** — no merging to main without green CI
6. **Security review before deploy** — run the checklist, no shortcuts

## Last Updated

April 2026
