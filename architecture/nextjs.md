# Next.js App Router Standards

## Overview

Standards and lessons learned from a full GOD-AUDIT pass on a production Next.js App Router project. These rules address real build failures, security gaps, and runtime bugs — not theoretical best practices.

See `architecture/stack-defaults.md` for when to use Next.js vs Vite + React.

---

## 1. When to Use Next.js vs Vite + React

### Use Next.js when:

| Requirement | Why Next.js |
|---|---|
| SSR / SSG needed | Built-in server rendering per route |
| SEO-critical pages | Metadata API, server-rendered HTML |
| API routes (webhooks, Stripe, auth callbacks) | `app/api/*/route.ts` runs on the server |
| Auth middleware (redirect unauthenticated users) | `middleware.ts` intercepts at the edge |
| Stripe webhooks | Needs raw body access, server-only |
| Mixed public + authenticated content | Per-segment rendering strategies |

### Use Vite + React when:

| Requirement | Why Vite |
|---|---|
| Internal dashboards | No SEO needed, no server required |
| Pure SPAs behind auth | Client rendering is simpler and faster to build |
| Admin panels, CRMs, automation UIs | No public-facing pages |
| Prototypes and tools | Less configuration overhead |

**Rule:** If the app is entirely behind a login screen and has no server-side logic, reach for Vite + React. If it has a public homepage, pricing page, or any webhook handler, use Next.js.

---

## 2. Required Files (App Router)

Every Next.js App Router project MUST have these files. Missing them causes build failures or silent runtime crashes.

### Root-level required files

```
app/
├── layout.tsx          ← Root layout — required, wraps every route
├── error.tsx           ← Top-level error boundary
├── not-found.tsx       ← Custom 404 page
└── global-error.tsx    ← Catches errors thrown inside root layout
```

### Per-segment required files

```
app/dashboard/
├── layout.tsx          ← Dashboard layout with auth check + force-dynamic
├── loading.tsx         ← Skeleton shown while async data loads
└── error.tsx           ← Scoped error boundary for dashboard routes
```

Add `loading.tsx` to every route segment that fetches async data. Add `error.tsx` to every segment where you want scoped error recovery (instead of bubbling to the root).

### error.tsx template

Must be a Client Component. Receives `error` and `reset` as props.

```tsx
// app/error.tsx  (or app/dashboard/error.tsx)
'use client';

export default function Error({
  error,
  reset,
}: {
  error: Error;
  reset: () => void;
}) {
  return (
    <div role="alert">
      <h2>Something went wrong</h2>
      <p>{error.message}</p>
      <button onClick={reset}>Try again</button>
    </div>
  );
}
```

### global-error.tsx template

Catches errors thrown inside `app/layout.tsx`. Must render its own `<html>` and `<body>`.

```tsx
// app/global-error.tsx
'use client';

export default function GlobalError({
  error,
  reset,
}: {
  error: Error;
  reset: () => void;
}) {
  return (
    <html lang="en">
      <body>
        <div role="alert">
          <h2>Something went wrong</h2>
          <button onClick={reset}>Try again</button>
        </div>
      </body>
    </html>
  );
}
```

### loading.tsx accessibility

Loading skeletons must include ARIA attributes so screen readers announce the loading state:

```tsx
// app/dashboard/loading.tsx
export default function Loading() {
  return (
    <div role="status" aria-label="Loading dashboard">
      <div aria-hidden="true" className="animate-spin h-8 w-8 ..." />
      <span className="sr-only">Loading...</span>
    </div>
  );
}
```

- `role="status"` on the container — announces loading state
- `aria-label="Loading"` on the container — describes what is loading
- `aria-hidden="true"` on the spinner itself — hides decorative element from screen readers

---

## 3. Server vs Client Components

**Default: Server Component.** Only add `'use client'` when you have a specific reason.

### When to add `'use client'`

Add `'use client'` ONLY when the component needs:

- `useState` / `useReducer`
- `useEffect` / `useLayoutEffect`
- Event handlers (`onClick`, `onChange`, etc.)
- Browser APIs (`window`, `document`, `localStorage`)
- Third-party client-only libraries (toast notifications, rich text editors, charting libraries)
- `useRouter` / `usePathname` / `useSearchParams`

### Decision table

```
SERVER COMPONENT                    CLIENT COMPONENT ('use client')
──────────────────────────────────────────────────────────────────────
Fetch data from Supabase            useState / useEffect
Read env vars (no NEXT_PUBLIC_)     onClick / onChange handlers
Access service role key             useRouter / usePathname
Export metadata                     react-hot-toast / sonner
Call server-only libraries          Third-party widgets (analytics, chat)
Write to database directly          Browser storage (localStorage)
```

### Rules

```
❌ WRONG — secrets in a Client Component
'use client';
import { supabaseAdmin } from '@/lib/supabase/admin'; // service role — server only!

✅ CORRECT — service role stays on the server
// app/api/users/route.ts (no 'use client')
import { supabaseAdmin } from '@/lib/supabase/admin';
```

**Never import `supabaseAdmin` (service role) from any file marked `'use client'`.** The service role key bypasses RLS — if it reaches the browser bundle, it is exposed to every user.

---

## 4. `export const dynamic = 'force-dynamic'`

### What it does

Opts a route or layout out of static rendering at build time. Required for any route that reads auth state, cookies, or request headers at runtime.

```typescript
export const dynamic = 'force-dynamic';
```

### When missing: build-time crash

```
Error: Route /dashboard couldn't be rendered statically because it used
`headers`/`cookies`. See more info here: ...
```

Or Clerk / Supabase auth errors during `next build` — the build system tries to pre-render the page and fails because there is no active session.

### Where to add it

| File | Why |
|---|---|
| `app/dashboard/layout.tsx` | Dashboard reads auth — child pages inherit this |
| `app/ty/layout.tsx` | Thank-you page wraps authenticated content |
| `app/update-payment/layout.tsx` | Payment page reads session |
| Any `app/api/*/route.ts` that calls `auth()` or reads cookies | Route handlers are dynamic by nature but must be explicit |

**Add it to the layout**, not every child page — child segments inherit the parent's rendering strategy.

```typescript
// app/dashboard/layout.tsx
export const dynamic = 'force-dynamic';

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  // auth check, session validation, etc.
  return <>{children}</>;
}
```

---

## 5. API Route Conventions

All API routes live in `app/api/[route]/route.ts`. Every route must follow these four rules.

### a. Always export `force-dynamic`

```typescript
export const dynamic = 'force-dynamic';
```

### b. Validate request bodies with `parseBody`

Define this helper once in `lib/validation/parse-body.ts` and use it in every POST/PATCH route.

```typescript
// lib/validation/parse-body.ts
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

Usage in a route:

```typescript
// app/api/users/route.ts
import { parseBody } from '@/lib/validation/parse-body';
import { z } from 'zod';

const createUserSchema = z.object({
  name: z.string().min(1).max(200),
  email: z.string().email(),
});

export async function POST(req: Request) {
  const parsed = await parseBody(req, createUserSchema);
  if (parsed instanceof NextResponse) return parsed; // validation failed — early return

  const { name, email } = parsed.data; // fully typed, safe to use
  // ...
}
```

### c. Explicit column selects — never `SELECT *`

```typescript
// ❌ WRONG — leaks all columns, breaks typed responses when schema changes
const { data } = await supabaseAdmin.from('tenants').select('*');

// ✅ CORRECT — explicit columns prevent data leakage and bandwidth waste
const { data } = await supabaseAdmin
  .from('tenants')
  .select('id, email, stripe_subscription_id, subscription_status');
```

Why: `SELECT *` leaks sensitive columns added later (tokens, keys, PII). It also breaks typed responses when the schema changes and wastes bandwidth on columns the route never uses.

### d. Idempotency guards — check state before mutating

Never blindly apply a state transition. Read first, guard against duplicates, then act.

```typescript
// ❌ WRONG — allows double-cancel, double-charge, duplicate creates
await stripe.subscriptions.update(id, { cancel_at_period_end: true });

// ✅ CORRECT — guard against duplicate operations
const { data: tenant } = await supabaseAdmin
  .from('tenants')
  .select('subscription_status')
  .eq('id', tenantId)
  .single();

if (tenant.subscription_status === 'canceling') {
  return NextResponse.json(
    { error: 'Subscription is already scheduled for cancellation' },
    { status: 400 },
  );
}

if (tenant.subscription_status !== 'active') {
  return NextResponse.json(
    { error: 'Subscription is not active' },
    { status: 400 },
  );
}

// Now safe to cancel
await stripe.subscriptions.update(id, { cancel_at_period_end: true });
```

### e. Webhook routes — exception to `parseBody`

**Signed webhooks (Stripe, Clerk, custom HMAC, many SaaS providers)** must read the **raw body string** first. `parseBody` / `req.json()` consumes the stream and breaks byte-exact HMAC comparison.

Pattern: `const raw = await request.text()` → verify signature → `JSON.parse(raw)` → Zod. Full template in `architecture/api-patterns.md` ("Read raw body once").

**Middleware:** every new `app/api/webhooks/**` route must be reachable without auth redirects. Add the path to your middleware **public** or **matcher bypass** list (same for duplicate legacy paths). If one URL is protected and a parallel URL is not, attackers use the weak one.

**Crons:** `app/api/cron/**` routes should require `Authorization: Bearer <CRON_SECRET>` (or Vercel Cron's documented header) and return 401 when missing.

---

## 6. Navigation: `router.refresh()` vs `window.location.reload()`

```typescript
// ❌ WRONG — full browser reload, loses all React state, re-downloads JS bundle
window.location.reload();

// ✅ CORRECT — soft server-data refresh, keeps React state, no full page reload
import { useRouter } from 'next/navigation';

const router = useRouter();
router.refresh();
```

Use `router.refresh()` after any client-side action that changes server-side data the current page displays — for example: accepting cookies, submitting a form, connecting an OAuth integration, updating billing settings.

`router.refresh()` re-runs Server Components and re-fetches server data without navigating away or losing client state.

---

## 7. Supabase Client Patterns

Two clients, two purposes. Never mix them.

```
lib/supabase/
├── admin.ts    ← supabaseAdmin (service role) — SERVER ONLY
└── client.ts   ← browser client (anon key) — safe for Client Components
```

```typescript
// lib/supabase/admin.ts — SERVER ONLY
// Never import this from a 'use client' file
import { createClient } from '@supabase/supabase-js';

export const supabaseAdmin = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!, // no NEXT_PUBLIC_ — server only
);
```

```typescript
// lib/supabase/client.ts — safe for Client Components
import { createBrowserClient } from '@supabase/ssr';

export function createSupabaseClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
}
```

### Rules

| Client | Where to use | Key used |
|---|---|---|
| `supabaseAdmin` | API routes, Server Components | `SUPABASE_SERVICE_ROLE_KEY` |
| `createSupabaseClient()` | Client Components, browser | `NEXT_PUBLIC_SUPABASE_ANON_KEY` |

- API routes always use `supabaseAdmin` — they run on the server
- Client Components use `createSupabaseClient()` — RLS enforced via anon key
- If you need to do something in a Client Component that requires elevated access, call an API route instead

---

## 8. Sentry Integration

Every production Next.js project requires Sentry. Three config files: client, server, edge.

```typescript
// sentry.client.config.ts
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  integrations: [Sentry.replayIntegration()],
  tracesSampleRate: 0.1,
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,
  enabled: process.env.NODE_ENV === 'production',
});
```

```typescript
// sentry.server.config.ts
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  tracesSampleRate: 0.1,
  enabled: process.env.NODE_ENV === 'production',
});
```

```typescript
// next.config.ts
import { withSentryConfig } from '@sentry/nextjs';

export default withSentryConfig(nextConfig, {
  org: 'your-org',
  project: 'your-project',
  silent: !process.env.CI,
  widenClientFileUpload: true,
  disableLogger: true,
  autoInstrumentServerFunctions: true,
});
```

### Required environment variables

```bash
NEXT_PUBLIC_SENTRY_DSN=https://xxx@sentry.io/xxx   # public — used by client + server
SENTRY_AUTH_TOKEN=sntrys_xxx                         # server only — source map uploads
SENTRY_ORG=your-org
SENTRY_PROJECT=your-project
```

`SENTRY_AUTH_TOKEN` must NOT have a `NEXT_PUBLIC_` prefix. It is only used during the build process for source map uploads.

---

## 9. Environment Variables

| Prefix | Accessible in | Use for |
|---|---|---|
| `NEXT_PUBLIC_` | Client + Server | Supabase URL, anon key, Sentry DSN, PostHog key |
| _(no prefix)_ | Server only | Service role key, Stripe secret, webhook secrets, Sentry auth token |

**Rule:** If a browser can read it, it is public. Only use `NEXT_PUBLIC_` for values safe to expose in the page source.

### Common mistakes

```bash
# ❌ WRONG — service role key exposed to every browser
NEXT_PUBLIC_SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...

# ✅ CORRECT — server only, no NEXT_PUBLIC_ prefix
SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...

# ❌ WRONG — Stripe secret key in the browser
NEXT_PUBLIC_STRIPE_SECRET_KEY=sk_live_...

# ✅ CORRECT — server only
STRIPE_SECRET_KEY=sk_live_...
```

Validate all required env vars at startup. For Next.js, do this at the top of any server-side module that needs them — the build will fail loudly instead of silently at runtime.

---

## 10. Metadata and SEO

Use Next.js's `Metadata` API on every public-facing page. Do not use `<head>` tags directly.

```typescript
// app/pricing/page.tsx
import { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Pricing — Your App',
  description: 'Simple, transparent pricing. Start free, scale as you grow.',
  alternates: {
    canonical: 'https://www.yourdomain.com/pricing',
  },
};

export default function PricingPage() {
  // ...
}
```

Always set `canonical` on public-facing pages. Without it, crawlers may index both `http://` and `https://` versions, or `www` and non-`www` variants, causing duplicate content penalties.

### Metadata for dynamic pages

```typescript
// app/blog/[slug]/page.tsx
import { Metadata } from 'next';

export async function generateMetadata({
  params,
}: {
  params: { slug: string };
}): Promise<Metadata> {
  const post = await fetchPost(params.slug);

  return {
    title: `${post.title} — Your Blog`,
    description: post.excerpt,
    alternates: {
      canonical: `https://www.yourdomain.com/blog/${params.slug}`,
    },
  };
}
```

---

## 11. Third-Party SDK Type Safety

Many SDKs use union types for reference fields. Never assume a field is a plain string.

Stripe is the most common example — `customer`, `payment_method`, and `invoice` fields on events can be expanded objects or IDs depending on the API call:

```typescript
// PaymentIntent.customer: string | Stripe.Customer | Stripe.DeletedCustomer | null

// ❌ WRONG — breaks when Stripe returns an expanded Customer object
const customerId = paymentIntent.customer; // could be an object, not a string

// ✅ CORRECT — narrow the type before using it
const customerId =
  typeof paymentIntent.customer === 'string'
    ? paymentIntent.customer
    : paymentIntent.customer?.id ?? null;
```

Apply the same pattern to any SDK field typed as `string | SomeObject | null`.

### SDK API version pinning (single source of truth)

If an SDK exposes a typed API version (for example Stripe `LatestApiVersion`), pin it in one shared constant file and reference that constant everywhere.

```typescript
// lib/stripe/webhook-helpers.ts
import Stripe from 'stripe';
export const STRIPE_API_VERSION: Stripe.LatestApiVersion = '2026-02-25.clover';
```

```typescript
// Any route/client file
import { STRIPE_API_VERSION } from '@/lib/stripe/webhook-helpers';
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, { apiVersion: STRIPE_API_VERSION });
```

Rules:

- Do not hardcode API version literals in multiple files.
- Grep for stale literals before release (`apiVersion: '....clover'`).
- Treat `LatestApiVersion` compile errors as release blockers (they indicate SDK/version drift).

### Clerk redirect prop compatibility

Clerk deprecated `afterSignInUrl` / `afterSignUpUrl` in favor of `fallbackRedirectUrl` and `forceRedirectUrl`.

Rules:

- Do not use deprecated redirect props in new code.
- Replace existing deprecated props during auth flow work.
- Any deprecation warning in auth/checkout paths is a release blocker until resolved.

---

## 12. App Router Checklist

### New project setup

- [ ] `app/layout.tsx` exists with `<html lang="en">` and a `<body>`
- [ ] `app/error.tsx` exists — `'use client'`, has `reset` button, uses `role="alert"`
- [ ] `app/not-found.tsx` exists
- [ ] `app/global-error.tsx` exists with its own `<html>` and `<body>`
- [ ] Dashboard layout has `export const dynamic = 'force-dynamic'`
- [ ] `lib/supabase/admin.ts` exists — NOT exported from any `'use client'` file
- [ ] JSON POST/PATCH routes use `parseBody`; **webhook** routes use raw body + signature verification (see §5e)
- [ ] All `/api/webhooks/*` (and any legacy alias paths) covered by middleware public/bypass rules
- [ ] Cron routes validate bearer secret
- [ ] All Supabase queries use explicit column selects — no `SELECT *`
- [ ] Sentry configured with `sentry.client.config.ts` + `sentry.server.config.ts`
- [ ] `NEXT_PUBLIC_SENTRY_DSN` set in Vercel env vars
- [ ] No `window.location.reload()` anywhere — replaced with `router.refresh()`
- [ ] All `loading.tsx` files include `role="status"` and `aria-label`

### Before every deploy

- [ ] `bun run build` passes locally — catches prerender errors and type errors before CI does
- [ ] Build command matches production exactly (for example `next build && next-sitemap`, not a lighter local variant)
- [ ] Clean install build parity verified (`rm -rf node_modules && npm ci && npm run build` in CI or locally)
- [ ] New tables have RLS enabled + policies in the same release (not "table now, policies later")
- [ ] New API routes have `force-dynamic`; body validation via `parseBody` **or** webhook raw-body flow
- [ ] Webhook signing secrets and `CRON_SECRET` set in production env
- [ ] No new `NEXT_PUBLIC_` prefixes on sensitive values
- [ ] Sentry DSN set in production env vars (Vercel dashboard)
- [ ] `bun run lint` passes — no ESLint errors
- [ ] SDK version drift scan passes (no stale hardcoded API versions)
- [ ] Auth-boundary smoke completed for critical flows: signed-out behavior and signed-in behavior both verified
- [ ] No auth/billing deprecation warnings in browser/server logs (Clerk, Stripe SDK, framework warnings)
