# Deployment Checklist

## Before Every Production Deploy

Run through this checklist EVERY time before deploying to production. No shortcuts.

---

## 1. Code Quality

```bash
# Run all checks — ALL must pass
npm run type-check    # Zero TypeScript errors
npm run lint          # Zero lint errors/warnings
npm run build         # Clean production build
npm run test -- --run # All tests pass
```

- [ ] TypeScript: zero errors
- [ ] ESLint: zero errors, zero warnings
- [ ] Build: succeeds without warnings
- [ ] Tests: all passing

---

## 2. Forbidden Patterns

```bash
# Quick grep checks — zero results expected for each
grep -rn ": any" src/ --include="*.ts" --include="*.tsx" | grep -v ".d.ts"
grep -rn "@ts-ignore\|@ts-expect-error" src/ --include="*.ts" --include="*.tsx"
grep -rn "console\.log" src/ --include="*.ts" --include="*.tsx"
grep -rn "TODO\|FIXME\|HACK\|XXX" src/ --include="*.ts" --include="*.tsx"
```

- [ ] Zero `any` types
- [ ] Zero `@ts-ignore` / `@ts-expect-error`
- [ ] No `console.log` left (use logger utility if needed)
- [ ] No `TODO` / `FIXME` / `HACK` left unresolved

---

## 3. Environment

- [ ] All env vars defined in hosting platform (Vercel, etc.)
- [ ] Env validation with Zod passes on startup
- [ ] No hardcoded API keys, tokens, or URLs in source code
- [ ] `.env` files are in `.gitignore`
- [ ] Production env vars point to production services (not staging/dev)

---

## 4. Security

- [ ] `npm audit` — no high/critical vulnerabilities
- [ ] RLS enabled on all Supabase tables
- [ ] No `SUPABASE_SERVICE_ROLE_KEY` in client code
- [ ] Auth guards on all protected routes
- [ ] Input validation on all forms and API endpoints
- [ ] No `dangerouslySetInnerHTML` without DOMPurify

---

## 5. Data

- [ ] Database migrations applied to production
- [ ] Schema matches what the code expects
- [ ] Seed data / test data removed from production
- [ ] No hardcoded mock data in production builds
- [ ] Pagination implemented for all list views
- [ ] Foreign key lookups use pre-built maps (not N+1 queries)

---

## 6. UX / UI

- [ ] All async operations have loading states
- [ ] All data views have empty states
- [ ] All errors show user-friendly messages (not raw error objects)
- [ ] Forms show validation errors inline
- [ ] Mobile responsive (if applicable)
- [ ] Favicon and page titles set correctly

---

## 7. Performance

- [ ] No unnecessary re-renders (check React DevTools if uncertain)
- [ ] Images optimized (WebP, proper sizing, lazy loading)
- [ ] Bundle size reasonable (check with `npx vite-bundle-visualizer`)
- [ ] API calls use pagination (not fetching entire tables)
- [ ] TanStack Query has appropriate `staleTime` / `gcTime` settings
- [ ] Lighthouse score > 90 on staging
- [ ] First Contentful Paint < 1.5s
- [ ] Time to Interactive < 3.5s
- [ ] Critical API endpoints < 500ms response time

---

## 8. Monitoring (if applicable)

- [ ] Error tracking configured (Sentry, LogRocket, etc.)
- [ ] Critical flows have logging
- [ ] Health check endpoint exists (for APIs)
- [ ] Alerts configured for:
  - Server errors (5xx)
  - High response times (>1s)
  - Failed authentication attempts
  - External API failures

---

## Post-Deploy Verification

After deploying:

1. [ ] Open production URL — does it load?
2. [ ] Login works
3. [ ] Main feature works (create/read/update/delete)
4. [ ] Check browser console — no errors
5. [ ] Check network tab — no failed requests
6. [ ] Test on mobile (quick check)
7. [ ] Verify external integrations still work (Supabase, APIs)

---

## Rollback Plan

If something breaks in production:

### Vercel
```bash
# Instant rollback to previous deployment
# Go to Vercel Dashboard → Deployments → Click previous → Promote to Production
```

### Manual
```bash
# Revert to last known good commit
git revert HEAD
git push origin main

# Or reset to specific commit
git reset --hard <last-good-commit>
git push origin main --force  # Use with caution
```

### Database
If you ran a migration that broke things:
1. Do NOT run a "down" migration blindly
2. Assess the damage — what data was affected?
3. Restore from backup if available
4. Write a forward migration to fix the issue

---

## Common Deployment Failures

| Issue | Symptom | Quick Fix |
|---|---|---|
| Missing env var | Build fails or app crashes | Add env var in hosting dashboard |
| Type error | Build fails in CI | Run `npm run type-check` locally |
| RLS too restrictive | Users can't access data | Test RLS with non-admin user |
| Migration fails | App crashes on data access | Rollback migration, fix, redeploy |
| API rate limit | External calls fail | Implement rate limiting/retry |
| Bundle too large | Slow page loads | Run bundle visualizer, remove deps |

---

## Post-Deployment Communication

After successful deploy:

1. **Notify team in Slack/Discord:**
   ```
   ✅ Deployed v1.x.x to production
   Changes: [brief summary]
   Verification: [tested login, main feature, no errors]
   ```

2. **Update changelog** (if applicable)

3. **Tag release in GitHub:**
   ```bash
   git tag -a v1.x.x -m "Release v1.x.x: [description]"
   git push origin v1.x.x
   ```

---

## Deploy Frequency

- **Hotfixes**: Deploy immediately after testing
- **Features**: Deploy after PR is approved and merged to main
- **Batch releases**: Weekly if multiple features are ready

Never deploy on Fridays unless it's a critical hotfix.

---

## Last Updated

February 2026
