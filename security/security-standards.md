# Security Standards

## Overview

Every project handling client data must follow these security practices. This is not optional — a security leak at CQ Marketing or any client project damages trust permanently.

---

## Environment Variables

### Rules

1. **NEVER commit `.env` files** — verify `.gitignore` includes all `.env*` patterns
2. **NEVER hardcode secrets** — no API keys, tokens, passwords, or connection strings in source code
3. **NEVER log secrets** — no `console.log(apiKey)` or similar, even during debugging
4. **NEVER put secrets in user-facing URLs** — no `?api_key=xxx` in links users click, share, or that appear in browser history. **Exception:** some vendors only support a **shared secret on the webhook callback URL** configured in *their* dashboard (server-to-server). That is acceptable if the secret is **required in production**, **rotated if leaked**, and **never logged** (log path without query). Prefer HMAC headers when the provider supports them (see `architecture/api-patterns.md`).
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

### Explicit Column Selects — No `SELECT *`

**Never use `.select('*')` in production API routes.** Always name the columns you need.

```typescript
// ❌ WRONG — leaks future columns, breaks typed responses, costs bandwidth
const { data } = await supabaseAdmin.from('tenants').select('*');

// ✅ CORRECT — explicit columns; adding a secrets column later won't leak it
const { data } = await supabaseAdmin
  .from('tenants')
  .select('id, email, stripe_subscription_id, subscription_status, plan_id');
```

Why this matters:
- A `payments` table today has no secrets. Tomorrow someone adds a `raw_card_data` column — `SELECT *` immediately exposes it through every existing API endpoint.
- The same applies to Supabase's auto-generated types: explicit selects keep your TypeScript inference accurate when the schema evolves.

**Rule:** The only place `select('*')` is acceptable is in admin scripts/migrations and local debugging — never in shipped API routes.

### Idempotency Guards

Before any state-changing operation, verify the resource is in the expected state. This prevents double-charges, double-cancels, and duplicate creates.

```typescript
// ❌ WRONG — blindly applies state transition
await stripe.subscriptions.update(id, { cancel_at_period_end: true });

// ✅ CORRECT — guard every transition
if (tenant.subscription_status === 'canceling') {
  return NextResponse.json(
    { error: 'Subscription is already scheduled for cancellation' },
    { status: 400 },
  );
}
if (tenant.subscription_status !== 'active') {
  return NextResponse.json({ error: 'Subscription is not active' }, { status: 400 });
}
// Safe to proceed
await stripe.subscriptions.update(id, { cancel_at_period_end: true });
```

Apply this pattern to: subscription state changes, payment retries, OAuth connections, any "activate / deactivate" toggle.

### Service role: always scope by tenant / organization

The Supabase **service role** bypasses RLS. Every `createAdminClient()` / `supabaseAdmin` query must still filter by `organization_id` (or equivalent tenant key) unless the operation is truly global platform admin.

```typescript
// ❌ WRONG — returns every org's rows if RLS is bypassed
const { data } = await supabaseAdmin.from('commissions').select('id, amount');

// ✅ CORRECT — explicit tenant boundary
const { data } = await supabaseAdmin
  .from('commissions')
  .select('id, amount')
  .eq('organization_id', organizationId);
```

**Audit:** periodically `grep -rE 'createAdminClient|supabaseAdmin' src/ app/` (adjust paths) and verify each call path includes tenant scoping.

### App-layer permissions when RLS does not encode role matrix

If fine-grained roles (e.g. sub-users, JSON permission blobs) live **only** in application code, RLS cannot enforce them. API routes must **re-check** permissions after auth — same checks for every entry point (REST route, Server Action, cron job).

---

## Webhooks, crons, and debug persistence

### Verify inbound webhooks

- Implement the provider's documented verification (HMAC header, signing secret, or required query secret).
- Protect **every** URL that accepts the same provider's events (legacy + new paths).

### Do not store raw PII from webhooks in debug tables

If you persist webhook bodies for debugging or replay:

- Redact emails, phones, names, addresses, tokens, and free-text notes **before** insert
- Prefer storing `event_id`, `provider`, `status`, and a **sanitized** payload shape
- Restrict read access to admin roles; add retention (delete after N days)

### Cron / scheduled route authentication

Protect `app/api/cron/*` (or similar) with a shared secret — e.g. compare `request.headers.get('authorization')` to `` `Bearer ${process.env.CRON_SECRET}` ``. Reject if missing or wrong. **Never** expose `CRON_SECRET` to the client.

---

## API Route Validation (Next.js)

For Next.js App Router API routes, use a `parseBody` helper to validate every `POST`/`PATCH`/`PUT` request body with Zod before touching any data:

```typescript
// lib/validation/schemas.ts
import { z, ZodSchema } from 'zod';
import { NextResponse } from 'next/server';

export async function parseBody<T>(
  req: Request,
  schema: ZodSchema<T>,
): Promise<{ data: T } | NextResponse> {
  let raw: unknown;
  try {
    raw = await req.json();
  } catch {
    return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 });
  }
  const result = schema.safeParse(raw);
  if (!result.success) {
    return NextResponse.json(
      { error: 'Validation failed', details: result.error.flatten() },
      { status: 400 },
    );
  }
  return { data: result.data };
}
```

```typescript
// Usage in any POST route:
export async function POST(req: Request) {
  const parsed = await parseBody(req, z.object({
    name: z.string().min(1).max(200),
    email: z.string().email(),
  }));
  if (parsed instanceof NextResponse) return parsed; // validation error returned
  const { name, email } = parsed.data; // fully typed, safe to use
}
```

This ensures: malformed JSON returns 400 immediately, every field is validated before any DB write, and error details are machine-readable for client-side field highlighting.

**Webhook routes:** do not use this helper for the initial read — use `await req.text()`, verify the signature, then `JSON.parse` (see `architecture/api-patterns.md`).

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
- [ ] RLS enabled on ALL tables (including new tables added this release)
- [ ] RLS policies tested with different user roles
- [ ] Service role key NOT used in client code
- [ ] No raw SQL with string concatenation (use parameterized queries)
- [ ] **No `SELECT *`** — all Supabase queries use explicit column lists
- [ ] Idempotency guards on all state-changing operations (subscriptions, payments, activations)

### Input
- [ ] All user inputs validated with Zod schemas
- [ ] Next.js JSON API routes use `parseBody` — **except signed webhooks**, which use `request.text()` + verify + `JSON.parse` (see `architecture/api-patterns.md`)
- [ ] No `dangerouslySetInnerHTML` without DOMPurify
- [ ] No open redirects
- [ ] File uploads validated (type, size) if applicable

### Auth
- [ ] Auth guards on all protected routes
- [ ] Session expiry handled gracefully
- [ ] `getUser()` used for authorization (not `getSession()`)

### Dependencies
- [ ] `npm audit` shows no high/critical vulnerabilities (or team has documented why CI uses a stricter/softer threshold while upstream fixes land)
- [ ] CI does not hide audit failures with `continue-on-error: true` **without** an explicit policy comment — green pipelines must not silently ignore security jobs
- [ ] Spreadsheet generation on the server avoids known-vulnerable `xlsx` where audits flag issues — prefer **`exceljs`** or an actively patched alternative
- [ ] No unnecessary dependencies
- [ ] Lockfile committed (`package-lock.json`)

### Headers (if applicable)
- [ ] HTTPS enforced
- [ ] CORS configured correctly (not `*` in production)
- [ ] CSP headers set if serving user content
