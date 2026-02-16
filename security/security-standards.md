# Security Standards

## Overview

Every project handling client data must follow these security practices. This is not optional — a security leak at CQ Marketing or any client project damages trust permanently.

---

## Environment Variables

### Rules

1. **NEVER commit `.env` files** — verify `.gitignore` includes all `.env*` patterns
2. **NEVER hardcode secrets** — no API keys, tokens, passwords, or connection strings in source code
3. **NEVER log secrets** — no `console.log(apiKey)` or similar, even during debugging
4. **NEVER put secrets in URLs** — no `?api_key=xxx` query parameters
5. **NEVER share secrets in Slack/email** — use a password manager or GitHub Secrets

### Validation

Every project must validate environment variables at startup using Zod:

```typescript
// src/config/env.ts
import { z } from 'zod';

const envSchema = z.object({
  VITE_SUPABASE_URL: z.string().url(),
  VITE_SUPABASE_ANON_KEY: z.string().min(1),
  VITE_API_BASE_URL: z.string().url().optional(),
});

export const env = envSchema.parse({
  VITE_SUPABASE_URL: import.meta.env.VITE_SUPABASE_URL,
  VITE_SUPABASE_ANON_KEY: import.meta.env.VITE_SUPABASE_ANON_KEY,
  VITE_API_BASE_URL: import.meta.env.VITE_API_BASE_URL,
});
```

If a required variable is missing, the app crashes immediately at startup with a clear error — not silently at runtime when a user triggers the feature.

### Sensitive vs Public Variables

```
# PUBLIC (safe for client-side / VITE_ prefix)
VITE_SUPABASE_URL=https://xxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGci...          # anon key is safe, RLS protects data

# SENSITIVE (server-side ONLY — never VITE_ prefix)
SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...        # bypasses RLS — NEVER expose
DATABASE_URL=postgresql://...                 # direct DB access
API_SECRET_KEY=sk-...                         # third-party API secrets
HYROS_API_KEY=APLe...                         # attribution API
GOOGLE_ADS_REFRESH_TOKEN=1//...               # OAuth tokens
```

**Rule:** If a variable starts with `VITE_`, it is bundled into the client JavaScript and visible to anyone. Only use `VITE_` for truly public values.

---

## Supabase / Database Security

### Row Level Security (RLS)

**Every table must have RLS enabled.** No exceptions.

```sql
-- Enable RLS on every table
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;

-- Default deny — if no policy matches, access is denied
-- This is Supabase's default behavior, but be explicit:

-- Users can only read their own organization's data
CREATE POLICY "Users read own org data"
  ON leads FOR SELECT
  USING (organization_id = auth.jwt() ->> 'organization_id');

-- Users can only insert into their own organization
CREATE POLICY "Users insert own org data"
  ON leads FOR INSERT
  WITH CHECK (organization_id = auth.jwt() ->> 'organization_id');

-- Users can only update their own organization's data
CREATE POLICY "Users update own org data"
  ON leads FOR UPDATE
  USING (organization_id = auth.jwt() ->> 'organization_id');

-- Users can only delete their own organization's data
CREATE POLICY "Users delete own org data"
  ON leads FOR DELETE
  USING (organization_id = auth.jwt() ->> 'organization_id');
```

### RLS Checklist

- [ ] Every table has RLS enabled
- [ ] Every table has at least a SELECT policy
- [ ] Policies use `auth.uid()` or JWT claims — never trust client-sent IDs
- [ ] Service role key is NEVER used in client code
- [ ] Test with different user accounts to verify isolation

### Query Safety

```typescript
// WRONG — trusting client-sent user ID
const { data } = await supabase
  .from('leads')
  .select('*')
  .eq('user_id', userId); // userId came from the client — attacker can change it

// RIGHT — RLS handles authorization automatically
const { data } = await supabase
  .from('leads')
  .select('*');
// RLS policy ensures user only sees their own data
```

---

## Input Validation

### Never Trust Client Input

Validate ALL inputs server-side (or in Supabase Edge Functions / RLS):

```typescript
// Define schema for ALL user inputs
const createLeadSchema = z.object({
  name: z.string().min(1).max(200).trim(),
  email: z.string().email(),
  phone: z.string().regex(/^\+?[\d\s-()]+$/).optional(),
  source: z.enum(['web', 'referral', 'ad', 'cold']),
  notes: z.string().max(5000).optional(),
});

// Validate before doing anything
function handleCreateLead(rawInput: unknown) {
  const result = createLeadSchema.safeParse(rawInput);
  if (!result.success) {
    // Show user-friendly error, log details
    return { error: result.error.flatten() };
  }
  // Now result.data is typed and safe
  return createLead(result.data);
}
```

### XSS Prevention

```typescript
// WRONG — rendering raw user input as HTML
<div dangerouslySetInnerHTML={{ __html: userComment }} />

// RIGHT — React escapes by default, just render normally
<div>{userComment}</div>

// If you MUST render HTML (e.g., rich text editor output),
// sanitize first with DOMPurify:
import DOMPurify from 'dompurify';
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(richContent) }} />
```

### URL/Redirect Validation

```typescript
// WRONG — open redirect vulnerability
const redirectTo = searchParams.get('redirect');
window.location.href = redirectTo; // attacker can set ?redirect=https://evil.com

// RIGHT — validate against allowlist
const ALLOWED_REDIRECTS = ['/dashboard', '/settings', '/leads'];
const redirectTo = searchParams.get('redirect');
if (redirectTo && ALLOWED_REDIRECTS.includes(redirectTo)) {
  navigate(redirectTo);
} else {
  navigate('/dashboard');
}
```

---

## Authentication

### Supabase Auth Rules

1. Always use `supabase.auth.getUser()` (server-verified) over `supabase.auth.getSession()` (client-side, can be spoofed) for authorization decisions
2. Implement proper session refresh handling
3. Protect routes with auth guards
4. Handle expired sessions gracefully — redirect to login, don't crash

```typescript
// Auth guard pattern
function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, isLoading } = useAuth();

  if (isLoading) return <LoadingSpinner />;
  if (!user) return <Navigate to="/login" replace />;

  return <>{children}</>;
}
```

### Password/Token Rules

1. Never store passwords in state or localStorage
2. Never display API keys in the UI (mask them: `sk-...a4b5`)
3. Implement session timeout for sensitive applications
4. Use PKCE flow for OAuth (Supabase does this by default)

---

## Dependencies

### Audit Regularly

```bash
# Check for known vulnerabilities
npm audit

# Fix what can be auto-fixed
npm audit fix

# For breaking changes that need manual intervention
npm audit --audit-level=high
```

### Rules

1. CI runs `npm audit` on every PR
2. Don't install packages you don't need — every dependency is an attack surface
3. Pin exact versions in production (`"zod": "3.22.4"` not `"^3.22.4"`)
4. Review what a package does before installing — check npm page, GitHub stars, maintenance activity
5. Prefer well-known, maintained packages over obscure ones

---

## API Keys for External Services

### Storage

| Context | Where to Store |
|---|---|
| Local development | `.env.local` (gitignored) |
| CI/CD | GitHub Secrets |
| Production | Hosting platform env vars (Vercel, etc.) |
| n8n workflows | n8n credentials manager |
| Shared team access | Password manager (1Password, Bitwarden) |

### Rotation

If a key is exposed (committed to git, shared in Slack, etc.):

1. **Immediately** rotate/regenerate the key in the provider's dashboard
2. Update the key everywhere it's used (env vars, CI, n8n, etc.)
3. Check git history — if committed, the key is in the history even after removal
4. If the repo is public, consider the key permanently compromised

---

## Security Review Checklist (Per Project)

Run this checklist before any production deploy:

### Environment
- [ ] No `.env` files committed (check `git log --all -- '*.env*'`)
- [ ] All env vars validated with Zod at startup
- [ ] No secrets in client-side code (no `VITE_` prefix on sensitive keys)
- [ ] No secrets in logs or error messages

### Database
- [ ] RLS enabled on ALL tables
- [ ] RLS policies tested with different user roles
- [ ] Service role key NOT used in client code
- [ ] No raw SQL with string concatenation (use parameterized queries)

### Input
- [ ] All user inputs validated with Zod schemas
- [ ] No `dangerouslySetInnerHTML` without DOMPurify
- [ ] No open redirects
- [ ] File uploads validated (type, size) if applicable

### Auth
- [ ] Auth guards on all protected routes
- [ ] Session expiry handled gracefully
- [ ] `getUser()` used for authorization (not `getSession()`)

### Dependencies
- [ ] `npm audit` shows no high/critical vulnerabilities
- [ ] No unnecessary dependencies
- [ ] Lockfile committed (`package-lock.json`)

### Headers (if applicable)
- [ ] HTTPS enforced
- [ ] CORS configured correctly (not `*` in production)
- [ ] CSP headers set if serving user content
