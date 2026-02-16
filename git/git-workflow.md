# Git Workflow

## Branch Strategy

```
main          ← Production. Protected. Only merges from develop or hotfix.
develop       ← Integration branch. All features merge here first.
feature/*     ← New features
fix/*         ← Bug fixes
hotfix/*      ← Urgent production fixes (branch from main)
refactor/*    ← Code refactoring (no behavior change)
chore/*       ← Config, dependencies, CI, docs
```

### Branch Naming

Format: `type/short-description`

```bash
# Good
feature/lead-dashboard
feature/auth-supabase
fix/pagination-filter
fix/null-contact-name
hotfix/api-key-exposed
refactor/migrate-bulletproof
chore/update-dependencies
chore/add-ci-pipeline

# Bad
my-branch
update
fix
new-feature
carlos-working-on-stuff
```

---

## Commit Messages

### Format

```
type(scope): short description

[optional body — what and why, not how]

[optional footer — breaking changes, ticket references]
```

### Types

| Type | When |
|---|---|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `style` | Formatting, CSS, no logic change |
| `docs` | Documentation only |
| `test` | Adding or fixing tests |
| `chore` | Build, CI, dependencies, config |
| `perf` | Performance improvement |
| `security` | Security fix |

### Examples

```bash
# Good
feat(leads): add pipeline filter to dashboard
fix(deals): handle null close_date in date range filter
refactor(auth): migrate to Supabase Auth v2
chore(deps): update TanStack Query to v5.20
security(api): validate user input on deal creation
fix(sync): implement pagination for HubSpot deals API
test(leads): add unit tests for lead-utils

# Bad
fixed stuff
update
WIP
asdfasdf
changes
```

### Rules

1. Use present tense: "add feature" not "added feature"
2. Use imperative mood: "fix bug" not "fixes bug"
3. First line under 72 characters
4. Reference issue/ticket if applicable: `fix(deals): handle null dates (fixes #42)`
5. If the commit is a breaking change, add `BREAKING CHANGE:` in the footer

---

## Pull Request Process

### Before Creating a PR

```bash
# 1. Make sure you're up to date with develop
git checkout develop
git pull origin develop
git checkout your-branch
git rebase develop

# 2. Run all checks locally
npm run type-check
npm run lint
npm run build
npm run test -- --run

# 3. Review your own changes
git diff develop..your-branch
```

### PR Title Format

Same as commit messages:

```
feat(leads): add pipeline filter to dashboard
fix(deals): handle null close_date in date range filter
```

### PR Description Template

```markdown
## What
[Brief description of what this PR does]

## Why
[Why is this change needed? Link to issue/ticket if applicable]

## Changes
- [List of specific changes]
- [Another change]

## Testing
- [ ] type-check passes
- [ ] lint passes
- [ ] build passes
- [ ] unit tests pass
- [ ] Manually tested [describe what you tested]

## Screenshots (if UI changes)
[Before/After screenshots]
```

### PR Rules

1. Every PR must target `develop` (not `main`, unless hotfix)
2. PR must pass CI before merge
3. PR should be small and focused — one feature or fix per PR
4. Don't mix refactoring with feature work in the same PR
5. Delete branch after merge

### Code Review Checklist

Before approving a PR, verify:

- [ ] Code follows Bulletproof React architecture
- [ ] No cross-feature imports
- [ ] Zero `any` types
- [ ] Error handling exists for all async operations
- [ ] UI has loading/empty/error states
- [ ] CSS uses variables, not hardcoded colors
- [ ] No console.log left in production code
- [ ] No hardcoded secrets or API keys

---

## Release Process

### Regular Release (develop → main)

```bash
# 1. Ensure develop is stable and CI passes
git checkout develop
git pull origin develop

# 2. Create PR from develop to main
# Title: "Release: v1.x.x"
# List all features and fixes since last release

# 3. After merge, tag the release
git checkout main
git pull origin main
git tag -a v1.x.x -m "Release v1.x.x: [brief description]"
git push origin v1.x.x
```

### Hotfix (urgent production fix)

```bash
# 1. Branch from main
git checkout main
git pull origin main
git checkout -b hotfix/critical-bug-description

# 2. Fix the issue, commit, push
git commit -m "hotfix(scope): fix critical bug description"
git push origin hotfix/critical-bug-description

# 3. Create PR to main AND develop
# Both PRs must pass CI before merge
```

---

## .gitignore Standard

Every project must include these at minimum:

```gitignore
# Dependencies
node_modules/

# Build
dist/
.next/
build/

# Environment (NEVER commit)
.env
.env.local
.env.production
.env.*.local

# OS
.DS_Store
Thumbs.db

# Editor
.vscode/settings.json
.idea/

# Debug
*.log
npm-debug.log*

# Testing
coverage/
playwright-report/

# Temp
*.tmp
*.swp
```
