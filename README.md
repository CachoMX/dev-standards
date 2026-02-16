# Dev Standards

Centralized development standards, architecture guides, error patterns, and Claude Code instructions for all projects by Carlos Aragon / AragonAutomates.

## Purpose

This repo serves as the single source of truth for:

- **Architecture patterns** — Bulletproof React structure, stack defaults, and coding standards
- **Error prevention** — Documented errors and lessons learned across all projects
- **Templates** — Reusable CLAUDE.md, .env, and project scaffolding templates
- **Agent configs** — Claude Code agent definitions for automated workflows

## Quick Start

When starting any new project:

1. Read `errors/common-errors-and-lessons.md` — mandatory before writing any code
2. Follow `architecture/stack-defaults.md` for tech stack decisions
3. Use `architecture/bulletproof-react-prompt.md` as your Claude Code prompt
4. Copy `templates/CLAUDE.md.template` into your project root
5. Copy `templates/.env.example.template` and fill in values

## Repo Structure

```
dev-standards/
├── README.md                              # This file
├── architecture/
│   ├── stack-defaults.md                  # Default tech stack for all apps
│   ├── bulletproof-react-prompt.md        # Claude Code prompt for new projects
│   └── bulletproof-react-refactor.md      # Claude Code prompt for refactoring existing projects
├── errors/
│   └── common-errors-and-lessons.md       # Error patterns and prevention (MANDATORY READ)
├── templates/
│   ├── CLAUDE.md.template                 # Template for project-level CLAUDE.md
│   └── .env.example.template              # Template for environment variables
└── agents/
    ├── developer.md                       # Developer agent instructions
    ├── code-reviewer.md                   # Code review agent instructions
    ├── tester.md                          # QA/testing agent instructions
    └── orchestrator.md                    # Multi-agent coordinator instructions
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

### For Claude.ai (Chat)

Upload the relevant files when starting a conversation about a new project or feature.

### For Your Team

Share this repo with Ricardo, Marco, Ruth, and the rest of the team so everyone follows the same standards.

## Rules

1. **This is a living repo** — update it as new patterns emerge
2. **Never commit credentials** — no API keys, tokens, or passwords
3. **Keep it project-agnostic** — specific project details go in project repos, not here
4. **Error docs are mandatory** — every developer must read them before starting work

## Last Updated

February 2026
