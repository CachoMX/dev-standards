# CI/CD Guide

## Overview

Every project must have a CI pipeline that runs automatically on every push and PR. This catches errors before they reach production and enforces our code standards without manual review.

## Setup

### 1. Copy the workflow to your project

```bash
mkdir -p .github/workflows
cp dev-standards/ci-cd/ci.yml .github/workflows/ci.yml
```

### 2. Add required npm scripts to package.json

```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "lint": "eslint src/ --ext .ts,.tsx --max-warnings 0",
    "type-check": "tsc --noEmit",
    "test": "vitest",
    "test:run": "vitest run",
    "test:e2e": "playwright test",
    "preview": "vite preview"
  }
}
```

### 3. Protect the main branch

In your GitHub repo → Settings → Branches → Add branch protection rule:

- Branch name pattern: `main`
- Enable: "Require a pull request before merging"
- Enable: "Require status checks to pass before merging"
- Select required checks: `Code Quality`, `Tests`, `Security Audit`
- Enable: "Require branches to be up to date before merging"
- Enable: "Do not allow bypassing the above settings"

This means NO ONE (including you) can push directly to main. Everything goes through a PR that must pass CI.

## Pipeline Jobs

### Code Quality (runs first)
1. Install dependencies
2. TypeScript type-check — catches type errors
3. ESLint — catches code quality issues
4. Forbidden patterns check — catches `any`, `@ts-ignore`, hardcoded colors, console.log
5. Production build — catches build-time errors
6. SDK version drift check — blocks stale hardcoded API versions (for example Stripe `apiVersion`)
7. Environment realism check — blocks placeholder env markers during production-readiness validation

### Tests (runs after quality passes)
1. Unit tests with Vitest
2. E2E tests with Playwright (when configured)

### Security Audit (runs in parallel)
1. npm audit — checks for vulnerable dependencies
2. Secret scanning — checks for hardcoded API keys/passwords
3. Audit failures are blocking by default (no hidden `continue-on-error` for high+ vulnerabilities)

## When CI Fails

If CI fails on your PR:

1. Read the error output — it tells you exactly what failed
2. Fix locally and push again
3. CI will re-run automatically

Common failures and fixes:

| Failure | Fix |
|---|---|
| TypeScript error | Fix the type — don't add `any` or `@ts-ignore` |
| ESLint error | Fix the lint issue — don't disable the rule |
| Forbidden pattern found | Replace `any` with proper type, use CSS variables, etc. |
| Build failure | Check for missing imports, wrong paths |
| SDK version drift failure | Centralize version constants (for example `STRIPE_API_VERSION`) and remove hardcoded literals |
| Placeholder env marker failure | Replace `your-project`/`CHANGE_ME` values before certifying release readiness |
| Test failure | Fix the test or the code it's testing |
| Security audit | Run `npm audit fix` or update the vulnerable package |

## Environment Variables in CI

If your build or tests need environment variables:

1. Go to GitHub repo → Settings → Secrets and variables → Actions
2. Add each variable as a repository secret
3. Reference in the workflow:

```yaml
env:
  VITE_SUPABASE_URL: ${{ secrets.VITE_SUPABASE_URL }}
  VITE_SUPABASE_ANON_KEY: ${{ secrets.VITE_SUPABASE_ANON_KEY }}
```

Never put real secrets in the workflow file itself.

## CD (Continuous Deployment)

### For Vercel projects

Vercel auto-deploys on push to main. No extra config needed — just connect the GitHub repo to Vercel.

- Push to `main` → Production deploy
- Push to `develop` or PR → Preview deploy

### For other hosting

Add a deploy job to the workflow:

```yaml
deploy:
  name: Deploy
  runs-on: ubuntu-latest
  needs: [quality, test]
  if: github.ref == 'refs/heads/main' && github.event_name == 'push'

  steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Setup Node
      uses: actions/setup-node@v4
      with:
        node-version: 20
        cache: 'npm'

    - name: Install and build
      run: |
        npm ci
        npm run build

    # Add your deploy step here (rsync, scp, cloud CLI, etc.)
```
