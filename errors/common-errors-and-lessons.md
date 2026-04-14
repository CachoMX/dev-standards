# Common Errors and Lessons Learned

## 🚨 MANDATORY: Read Before Starting Any Development

**This document MUST be read before implementing any feature in ANY project.**

### Quick Pre-Development Checklist
Before writing ANY code, verify:

**Database & Schema:**
- [ ] Read database schema/migrations FIRST before writing queries
- [ ] Verify exact field names - never assume
- [ ] Use generated TypeScript types from schema

**API Integration:**
- [ ] Read API documentation thoroughly
- [ ] Implement pagination for external API syncs (never assume first page has all data)
- [ ] Test with all required parameters
- [ ] Log requests/responses for debugging

**TypeScript Strict Rules (ZERO tolerance):**
- [ ] Zero `any` types - use `unknown` + type guards
- [ ] Zero `@ts-ignore` or `@ts-expect-error`
- [ ] Zero non-null assertions (`!`) - use optional chaining (`?.`)
- [ ] All function parameters and return types explicit
- [ ] Remove all unused imports and variables

**Styling & Architecture:**
- [ ] Use CSS variables (not hardcoded colors like `bg-gray-800` or Tailwind palette classes)
- [ ] Chart libraries (Recharts, etc.): no hex/rgba in `fill` / `stroke` / inline styles — map series colors to CSS variables
- [ ] Follow bulletproof-react architecture (no cross-feature imports)
- [ ] Business logic in `features/`, not in `app/` pages

**Error Handling & Data Quality:**
- [ ] Handle null/undefined explicitly (never assume data exists)
- [ ] Never swallow errors silently - always log and handle
- [ ] Test end-to-end flow: Frontend → API → Database → UI
- [ ] Add user-facing error messages
- [ ] Validate data quality before filtering (check actual DB values)

**Next.js Specific (when using App Router):**
- [ ] `app/error.tsx` + `app/not-found.tsx` exist
- [ ] Any layout/route using auth has `export const dynamic = 'force-dynamic'`
- [ ] All **non-webhook** POST/PATCH routes use `parseBody(req, schema)` — **signed webhooks** must use `await request.text()`, verify HMAC/signature, then `JSON.parse` (see `architecture/api-patterns.md`)
- [ ] Every webhook path is authenticated and listed in middleware public/bypass rules if needed
- [ ] No `.select('*')` in any API route — explicit column lists only
- [ ] No `window.location.reload()` — use `router.refresh()` instead

**Build & Deployment:**
- [ ] Run `npm run type-check` successfully
- [ ] Run `npm run lint` successfully
- [ ] Run `npm run build` successfully (catches Next.js prerender errors — dev mode does NOT)
- [ ] No hardcoded mock data in production code

---

## Purpose
This document captures recurring errors and lessons learned during development to prevent Claude Code from repeating the same mistakes in future projects.

---

## Database Schema Mismatches

### ❌ Error: Using non-existent database fields
**What happened:**
- Code tried to insert `author_email` into the `messages` table
- The actual schema only has `author_intercom_id`
- Insert silently failed, returning `null`

**Root cause:**
- Not checking the database schema before writing insert queries
- Assuming field names without verification

**✅ Prevention:**
1. **ALWAYS read the migration files first** before writing any database queries
2. Check `supabase/migrations/*.sql` for exact table schemas
3. Use TypeScript types from generated Supabase types
4. Never assume field names - verify them first

**Files to check:**
- `supabase/migrations/[timestamp]_initial_schema.sql`
- `lib/types/database.types.ts` (if exists)

---

## API Integration Issues

### ❌ Error: Missing required API parameters
**What happened:**
- Intercom API returned "ID is required" error
- The `admin_id` parameter was missing from the request body
- API documentation wasn't fully followed

**Root cause:**
- Not reading API documentation carefully
- Assuming optional parameters when they're actually required

**✅ Prevention:**
1. **Read API documentation thoroughly** before implementing endpoints
2. Look for "required" fields in API docs
3. Test API calls with all documented parameters first
4. Add comprehensive error logging to catch missing parameters early

---

## Import Path Errors

### ❌ Error: Wrong import function names
**What happened:**
- Used `createServerClient` instead of `createClient`
- Led to runtime errors

**Root cause:**
- Not checking the actual exports from the module
- Copy-pasting from examples without verification

**✅ Prevention:**
1. **Always verify exports** before importing: Read the source file or check index.ts
2. Use IDE auto-complete to ensure correct imports
3. Check existing codebase for import patterns before adding new ones

---

## UI State Management

### ❌ Error: Messages not appearing in UI after successful API call
**What happened:**
- Message sent successfully to Intercom
- Message not saved to database due to schema error
- UI expected `data.message` but received `null`
- No error shown to user

**Root cause:**
- Swallowing database errors without proper handling
- Not validating API response structure matches UI expectations
- Optimistic UI updates without proper error rollback

**✅ Prevention:**
1. **Never swallow errors silently** - always log and handle them
2. Validate API response structure matches what UI expects
3. Add error boundaries and user-facing error messages
4. Test the full flow: API → Database → UI update
5. Add comprehensive logging at each step

---

## General Development Best Practices

### 1. **Schema-First Development**
- Always read database migrations BEFORE writing queries
- Generate and use TypeScript types from schema
- Never hardcode field names

### 2. **API Integration**
- Read documentation thoroughly
- Test all required parameters
- Log request/response for debugging
- Handle errors explicitly

### 3. **Error Handling**
- Log errors with context (what operation failed)
- Don't return success when operations fail
- Show user-facing error messages
- Add error boundaries

### 4. **Testing Flow**
- Test end-to-end: Frontend → API → Database → Response → UI
- Add logging at each step
- Verify data structure at each boundary
- Test error cases, not just happy path

### 5. **Import Management**
- Verify exports before importing
- Check existing patterns in codebase
- Use consistent import paths across project

---

## Project-Specific Patterns

### Supabase Client Usage
```typescript
// ✅ Correct - Server-side
import { createClient } from '@/lib/supabase/server'

// ❌ Wrong
import { createServerClient } from '@/lib/supabase/server'
```

### Database Inserts
```typescript
// ✅ Always check schema first
// Read: supabase/migrations/[timestamp]_initial_schema.sql

// ✅ Use exact field names from schema
const { data, error } = await supabase
  .from('messages')
  .insert({
    author_intercom_id: admin.id,  // ✅ Matches schema
    // NOT author_email                // ❌ Doesn't exist
  })

// ✅ Always handle errors
if (error) {
  console.error('Failed to insert:', error)
  throw error  // Don't swallow it
}
```

### API Response Structure
```typescript
// ✅ Ensure response matches UI expectations
return NextResponse.json({
  success: true,
  message: newMessage,  // UI expects this
  error: null
})

// ✅ Never return success with null data
if (!newMessage) {
  throw new Error('Failed to create message')
}
```

---

## Checklist for New Features

Before implementing any new feature that touches the database:

- [ ] Read relevant migration files for exact schema
- [ ] Check existing similar code patterns in the codebase
- [ ] Verify all imports are correct
- [ ] Add comprehensive error logging
- [ ] Test the complete flow end-to-end
- [ ] Verify error handling (don't swallow errors)
- [ ] Check that UI state updates match API responses
- [ ] Add user-facing error messages

---

## How to Use This Document

**For Claude Code:**
When starting a new project or feature:
1. Read this document first
2. Check for similar patterns in "Common Errors"
3. Follow the prevention steps
4. Use the checklists

**For Developers:**
When you find a new recurring error:
1. Document it here with ❌ Error section
2. Explain root cause
3. Add ✅ Prevention steps
4. Include code examples if relevant

---

---

## Patterns from Other Projects

Based on analysis of previous repos (PingItNow, closers-quantum), here are additional recurring errors:

### ❌ Error: Using wrong keys/IDs in data structures
**What happened** (closers-quantum):
- "Fix lead stage rules using wrong key (id instead of name)"
- Used `id` field when API expected `name` field

**✅ Prevention:**
1. Always verify API documentation for exact field names
2. Don't assume field names - check the actual API response structure
3. Add TypeScript types to catch these at compile time

### ❌ Error: Race conditions in webhooks
**What happened** (closers-quantum):
- "Fix duplicate calls from HubSpot webhooks (race condition)"
- Webhooks processed multiple times simultaneously

**✅ Prevention:**
1. Use unique constraints in database
2. Implement idempotency keys
3. Add debouncing or locking mechanisms
4. Test webhook handlers with concurrent requests

### ❌ Error: Stale sessions after OAuth
**What happened** (PingItNow):
- "Fix stale Clerk session after Stripe OAuth reconnect"
- "Fix POST 401 after OAuth: refresh Clerk JWT before mutations"

**✅ Prevention:**
1. Always refresh tokens after OAuth flows
2. Force router refresh after authentication changes
3. Verify session validity before API calls
4. Add token refresh logic to API interceptors

### ❌ Error: RLS (Row Level Security) blocking operations
**What happened** (closers-quantum):
- "Fix lead DELETE to use admin client (bypass RLS)"

**Root cause:**
- Using regular client when admin privileges needed
- RLS policies blocking legitimate operations

**✅ Prevention:**
1. Use admin/service role client for background jobs
2. Understand when RLS applies and when to bypass it
3. Test database operations with different user roles
4. Document which operations need admin access

### ❌ Error: Wrong API endpoints or parameters
**What happened** (closers-quantum):
- "Fix GHL uninstall: use correct marketplace endpoint"
- "Fix GHL uninstall: use base appId without suffix"

**✅ Prevention:**
1. Read API documentation carefully
2. Log request URLs and parameters for debugging
3. Test with API documentation examples first
4. Don't modify IDs/parameters without understanding format

### ❌ Error: Data not syncing properly
**What happened** (closers-quantum):
- "Fix GHL webhook to sync tags to leads"
- "Fix lead tags not syncing from calls"
- "Fix HubSpot contact sync to handle email changes"

**Root cause:**
- Missing fields in sync logic
- Not handling all update scenarios

**✅ Prevention:**
1. Test all CRUD operations (Create, Read, Update, Delete)
2. Test edge cases (empty values, nulls, updates)
3. Add comprehensive logging to sync operations
4. Verify data in both systems after sync

### ❌ Error: TypeScript type conversion errors
**What happened** (mundosolar, multiple projects):
- "Fix Decimal type conversion in dashboard stats"
- "Fix TypeScript iteration errors"
- "Fix TypeScript errors" (recurring pattern across many commits)

**Root cause:**
- Type mismatches between libraries (e.g., Decimal vs number)
- Incorrect iteration over typed arrays/objects
- Missing type definitions

**✅ Prevention:**
1. Use proper type casting when converting between types
2. Add explicit types to function returns and parameters
3. Enable strict TypeScript checking
4. Test with production builds (not just dev mode)
5. Use type guards for runtime type checking

### ❌ Error: Batch processing limits
**What happened** (vet-manager):
- "Fix CSM updates batch processing (100 item limit)"
- API had undocumented batch size limits

**Root cause:**
- Not checking API batch limits
- Processing too many items at once

**✅ Prevention:**
1. Check API documentation for batch size limits
2. Implement pagination for large datasets
3. Add chunking logic for batch operations
4. Test with large datasets (>100 items)
5. Add error handling for batch size exceeded errors

### ❌ Error: Null/undefined handling in sync operations
**What happened** (vet-manager):
- "Fix CSM updates with null creator"
- "Fix CSM updates extraction using linked_items"

**Root cause:**
- Not handling null/undefined values in external data
- Assuming fields always exist

**✅ Prevention:**
1. Add null checks before accessing properties
2. Use optional chaining (?.) and nullish coalescing (??)
3. Validate external data before processing
4. Add default values for nullable fields
5. Test with incomplete/malformed data

### ❌ Error: Suspense boundary issues in Next.js
**What happened** (mundosolar):
- "Fix useSearchParams Suspense boundary error in orders/new page"

**Root cause:**
- Using hooks that require Suspense without proper boundary
- Next.js 13+ App Router Suspense requirements

**✅ Prevention:**
1. Wrap components using `useSearchParams`, `useRouter` in Suspense
2. Use `loading.tsx` files for route segments
3. Test navigation between pages
4. Read Next.js App Router migration guides carefully

### ❌ Error: Security vulnerabilities (CVEs)
**What happened** (mundosolar, kpi-tracker-saas):
- "Fix critical security vulnerabilities"
- "Fix React Server Components CVE vulnerabilities"

**Root cause:**
- Outdated dependencies
- Known security issues in packages

**✅ Prevention:**
1. Run `npm audit` or `pnpm audit` regularly
2. Keep dependencies up to date
3. Use Dependabot or Renovate for automatic updates
4. Subscribe to security advisories
5. Test after security updates

### ❌ Error: Timezone handling in dates
**What happened** (mundosolar, kpi-tracker-saas):
- "Fix CFDI date timezone"
- "Fix submission date to preserve original date when editing"

**Root cause:**
- Not handling timezones properly
- Converting dates incorrectly
- Losing timezone info on edit

**✅ Prevention:**
1. Always store dates in UTC in database
2. Use `date-fns-tz` or `luxon` for timezone handling
3. Test with different timezones
4. Don't convert dates to local time unnecessarily
5. Preserve original date format when editing

### ❌ Error: Next.js prerender crash — missing `force-dynamic`
**What happened** (PingItNow):
- `next build` crashed with: `Error: Route /dashboard couldn't be rendered statically because it used headers`
- Dashboard layout called `auth()` (Clerk) which reads cookies — a runtime-only operation
- Without `force-dynamic`, Next.js tried to prerender the route at build time and failed

**Root cause:**
- Any Next.js route that reads `headers()`, `cookies()`, or calls auth functions must be dynamic
- This includes layouts — if the layout is dynamic, child pages inherit it
- Missing this on ONE layout breaks ALL child routes under it

**✅ Prevention:**
```typescript
// Add to app/dashboard/layout.tsx (and any layout/route using auth)
export const dynamic = 'force-dynamic';
```
Rules:
1. Add `force-dynamic` to any layout wrapping authenticated content
2. Add it to every API route that calls `auth()` or reads cookies
3. Run `bun run build` (or `next build`) locally before PRs — this error only surfaces at build time, not in dev mode

---

### ❌ Error: `window.location.reload()` causes full page reload in Next.js
**What happened** (PingItNow):
- `window.location.reload()` used after accepting cookie consent
- This triggers a full browser reload — re-downloads JS, loses React state, re-runs all analytics initialisation twice

**Root cause:**
- `window.location.reload()` is a browser API that exits the React/Next.js runtime entirely
- In Next.js, `router.refresh()` re-fetches server data and re-renders only what changed

**✅ Prevention:**
```typescript
// ❌ WRONG — full browser reload
window.location.reload();

// ✅ CORRECT — Next.js soft refresh
import { useRouter } from 'next/navigation';
const router = useRouter();
router.refresh();
```
Use `router.refresh()` whenever you need to re-fetch server-side data after a client-side action (cookie consent, settings save, OAuth connect).

---

### ❌ Error: `SELECT *` leaking data through API routes
**What happened** (PingItNow GOD-AUDIT):
- 40+ API routes used `.select('*')` on Supabase tables
- Any new column added to `tenants`, `transactions`, or `payment_links` was immediately exposed through every existing endpoint
- Sensitive columns (tokens, internal flags, raw webhook payloads) were leaking to the client

**Root cause:**
- `SELECT *` fetches everything that exists at query time, including columns added after the route was written
- When a table gains a `webhook_secret` or `stripe_secret_key` column, ALL existing `SELECT *` routes expose it instantly

**✅ Prevention:**
```typescript
// ❌ WRONG
const { data } = await supabaseAdmin.from('tenants').select('*');

// ✅ CORRECT
const { data } = await supabaseAdmin
  .from('tenants')
  .select('id, email, subscription_status, plan_id');
```
Add to code review checklist: "No `.select('*')` in API routes."

---

### ❌ Error: Stripe SDK union types causing TypeScript errors
**What happened** (PingItNow):
- `paymentIntent.customer` assigned to `string` variable — TypeScript error
- Stripe's `PaymentIntent.customer` is typed as `string | Stripe.Customer | Stripe.DeletedCustomer | null`
- The object variant occurs when `expand: ['customer']` is used in the API call

**Root cause:**
- Many Stripe resource fields are "expandable references" — they can be either a bare ID string or a full expanded object
- Assigning without narrowing breaks with strict TypeScript

**✅ Prevention:**
```typescript
// ❌ WRONG — breaks when customer is expanded
const customerId: string = paymentIntent.customer;

// ✅ CORRECT — handle all variants
const customerId =
  typeof paymentIntent.customer === 'string'
    ? paymentIntent.customer
    : paymentIntent.customer?.id ?? null;
```
Apply this pattern to: `PaymentIntent.customer`, `Invoice.customer`, `Subscription.customer`, `Charge.customer`, `PaymentMethod.customer`, and any other expandable Stripe reference.

---

### ❌ Error: Vitest coverage threshold failure from including service wrappers
**What happened** (PingItNow):
- `vitest.config.ts` set `include: ['lib/**/*.ts']`
- This included Supabase, Stripe, and PostHog service wrappers that make real external calls — 0% testable in unit tests
- Overall coverage dropped to 18%, failing all thresholds

**Root cause:**
- Coverage % = (lines tested) / (lines in scope). Including untestable wrappers dilutes the denominator without adding to the numerator.
- Only include files that contain pure logic (validation, utilities, helpers, transformations)

**✅ Prevention:**
```typescript
// vitest.config.ts
coverage: {
  // ✅ Scope to testable logic only
  include: ['lib/validation/**/*.ts', 'lib/utils/**/*.ts'],
  // ❌ NOT 'lib/**/*.ts' — that pulls in Supabase/Stripe/PostHog wrappers
  thresholds: { statements: 80, branches: 80, functions: 80, lines: 80 },
}
```
Rule: Only include directories in coverage that contain pure functions. Service wrappers (Supabase client, Stripe SDK, email providers) should be tested via integration tests, not unit tests.

---

### ❌ Error: Hardcoded colors inside chart / SVG components
**What happened** (multi-tenant dashboard audit):
- Recharts `<Cell fill="#22c55e" />`, heatmaps, and outcome-color maps used raw hex/rgba
- Violates theme systems: charts did not respect dark mode or per-tenant theme switches
- Same issue as Tailwind palette classes — easy to miss because lint only scans some file patterns

**Root cause:**
- Chart libraries encourage inline `fill`/`stroke` strings
- Utility files (`outcome-colors.ts`, etc.) returned hex literals instead of CSS variable names

**✅ Prevention:**
1. Pass color as `var(--color-success)` (or a className + CSS targeting SVG) — verify in browser across themes
2. Run repo CSS audits that include `tsx`/`ts` (hex and `rgba(`), not only CSS files
3. For dynamic series, resolve `getComputedStyle(document.documentElement).getPropertyValue('--token')` in client charts only when necessary; prefer static token names from design system

---

### ❌ Error: `xlsx` / SheetJS for server-side Excel generation
**What happened** (dependency audit):
- `xlsx` (SheetJS) flagged with high-severity issues (prototype pollution / ReDoS) in common audit reports
- Used for commission/report exports — parsing or building workbooks on the server

**Root cause:**
- Default spreadsheet package choice without checking `npm audit` impact

**✅ Prevention:**
1. Prefer **`exceljs`** (or another maintained alternative) for **generating** workbooks on the server
2. Avoid parsing **untrusted** `.xlsx` in the browser; if required, isolate and audit the library choice
3. After swapping libraries, async-ify callers (`writeBuffer` / stream APIs are async in exceljs)

---

### ❌ Error: Vitest tests fail when assigning `process.env.NODE_ENV`
**What happened:**
- Test tried `process.env.NODE_ENV = 'production'` to exercise a branch
- Node/Vitest treats `NODE_ENV` as read-only in some setups — assignment throws or is ignored

**Root cause:**
- Direct mutation of a special-cased environment variable

**✅ Prevention:**
```typescript
import { vi } from 'vitest';

// ✅ Prefer stubbing for the duration of the test
vi.stubEnv('NODE_ENV', 'production');
// ... test ...
vi.unstubAllEnvs();
```

---

### ❌ Error: Stale README / agent instructions vs real repo layout
**What happened** (GOD-AUDIT):
- README still described "Phase 2" features that were already shipped
- Paths in `CLAUDE.md` or tasks docs pointed at `src/...` vs root `app/...` (or the opposite), confusing agents and new contributors

**Root cause:**
- Documentation not updated per release; copy-paste from older stack versions

**✅ Prevention:**
1. After refactors, grep docs for old paths and fix in the same PR when possible
2. Keep a single "source of truth" section in project `CLAUDE.md` (where routes live, where features live)
3. Treat doc drift as tech debt — it causes wrong code to be written confidently

---

### ❌ Error: Pagination filter logic
**What happened** (vet-manager):
- "Fix: Include pipeline staging tasks in pagination filter"
- "Fix pipeline staging filter logic"

**Root cause:**
- Filter not applied correctly to paginated queries
- Missing conditions in where clauses

**✅ Prevention:**
1. Test pagination with filters applied
2. Verify SQL/query logic includes all filter conditions
3. Test edge cases (empty results, first page, last page)
4. Add logging to debug filter application
5. Use query builders or ORMs to avoid SQL mistakes

---

## TypeScript & ESLint Strict Rules

### ❌ Error: Using `any` type
**What happened:**
- TypeScript errors ignored with `any`
- Type safety completely bypassed
- Runtime errors not caught at compile time

**Root cause:**
- Taking shortcuts instead of properly typing
- Not understanding the correct type to use

**✅ Prevention:**
1. **ZERO `any` types allowed** - use `unknown` + type guards if truly needed
2. Use `z.infer<typeof schema>` from Zod schemas
3. Generate types from database schema
4. Use TypeScript utility types: `Partial<T>`, `Pick<T>`, `Omit<T>`, etc.
5. Enable `"noImplicitAny": true` in tsconfig.json

**Examples:**
```typescript
// ❌ WRONG
function processData(data: any) {
  return data.value;
}

// ✅ CORRECT - Use proper types
type Data = { value: string };
function processData(data: Data) {
  return data.value;
}

// ✅ CORRECT - Use unknown + type guard
function processData(data: unknown) {
  if (typeof data === 'object' && data !== null && 'value' in data) {
    return (data as { value: string }).value;
  }
  throw new Error('Invalid data');
}

// ✅ CORRECT - Use Zod
const dataSchema = z.object({ value: z.string() });
type Data = z.infer<typeof dataSchema>;
function processData(data: Data) {
  return data.value;
}
```

### ❌ Error: Using `@ts-ignore` or `@ts-expect-error`
**What happened:**
- TypeScript errors suppressed without fixing root cause
- Hidden bugs that surface at runtime

**Root cause:**
- Taking shortcuts
- Not understanding the type error

**✅ Prevention:**
1. **ZERO `@ts-ignore` or `@ts-expect-error` allowed**
2. Fix the actual type error instead
3. If library types are wrong, create proper type declarations
4. Use type assertions only when absolutely necessary with `as` or `satisfies`

```typescript
// ❌ WRONG
// @ts-ignore
const value = data.unknownField;

// ✅ CORRECT - Fix the type
type Data = { unknownField?: string };
const value = (data as Data).unknownField;

// ✅ BETTER - Use type guard
if ('unknownField' in data) {
  const value = data.unknownField;
}
```

### ❌ Error: Non-null assertions (`!`)
**What happened:**
- Used `!` operator assuming value exists
- Runtime errors when value is actually null/undefined

**Root cause:**
- Not properly checking for null/undefined
- Assuming values always exist

**✅ Prevention:**
1. **ZERO non-null assertions (`!`)** - use proper null checks
2. Use optional chaining (`?.`) and nullish coalescing (`??`)
3. Add runtime checks before accessing properties
4. Use type guards

```typescript
// ❌ WRONG
const name = user!.profile!.name;

// ✅ CORRECT - Use optional chaining
const name = user?.profile?.name;

// ✅ CORRECT - Use null checks
if (user && user.profile) {
  const name = user.profile.name;
}

// ✅ CORRECT - Use nullish coalescing for defaults
const name = user?.profile?.name ?? 'Anonymous';
```

### ❌ Error: Implicit any in function parameters
**What happened:**
- Function parameters without types
- TypeScript infers `any`
- No type safety

**Root cause:**
- Forgetting to type parameters
- Assuming TypeScript will infer correct types

**✅ Prevention:**
1. **All function parameters must have explicit types**
2. **All function return types must be explicit**
3. Enable `"noImplicitAny": true` and `"noImplicitReturns": true`

```typescript
// ❌ WRONG
function calculateTotal(items) {
  return items.reduce((sum, item) => sum + item.price, 0);
}

// ✅ CORRECT
type Item = { price: number };
function calculateTotal(items: Item[]): number {
  return items.reduce((sum, item) => sum + item.price, 0);
}
```

### ❌ Error: Unused variables and imports
**What happened:**
- ESLint errors in build
- Code cluttered with unused imports
- Deployment fails

**Root cause:**
- Not cleaning up after refactoring
- Copy-pasting code without removing unused parts

**✅ Prevention:**
1. Remove all unused imports before committing
2. Remove all unused variables
3. If variable is intentionally unused, prefix with `_` (e.g., `_unused`)
4. Run `npm run lint` before committing
5. Enable `"noUnusedLocals": true` and `"noUnusedParameters": true`

```typescript
// ❌ WRONG
import { useState, useEffect, useMemo } from 'react'; // useMemo unused
function MyComponent() {
  const [count, setCount] = useState(0);
  const unused = 42; // unused variable
  return <div>{count}</div>;
}

// ✅ CORRECT
import { useState } from 'react';
function MyComponent() {
  const [count, setCount] = useState(0);
  return <div>{count}</div>;
}

// ✅ CORRECT - If intentionally unused
function handleEvent(_event: Event, data: Data) {
  // _event prefixed with _ to indicate intentionally unused
  console.log(data);
}
```

### ❌ Error: Missing return types
**What happened:**
- Functions without explicit return types
- TypeScript infers incorrect types
- Breaking changes not caught

**Root cause:**
- Relying on type inference
- Not being explicit about function contracts

**✅ Prevention:**
1. **Always specify explicit return types**
2. Use `Promise<T>` for async functions
3. Use `void` for functions that don't return anything
4. Enable `"noImplicitReturns": true`

```typescript
// ❌ WRONG
async function getUser(id: string) {
  const { data } = await supabase
    .from('users')
    .select('*')
    .eq('id', id)
    .single();
  return data;
}

// ✅ CORRECT
type User = Database['public']['Tables']['users']['Row'];
async function getUser(id: string): Promise<User | null> {
  const { data } = await supabase
    .from('users')
    .select('*')
    .eq('id', id)
    .single();
  return data;
}
```

### ❌ Error: Type assertions with `as` instead of type guards
**What happened:**
- Used `as` to force type without validation
- Runtime errors when assumption is wrong

**Root cause:**
- Not validating data before using it
- Taking shortcuts with type safety

**✅ Prevention:**
1. Prefer `satisfies` over `as` for type checking
2. Use type guards for runtime validation
3. Only use `as` when you're 100% certain (e.g., DOM elements)

```typescript
// ❌ WRONG
const data = response as User; // No validation

// ✅ CORRECT - Use type guard
function isUser(data: unknown): data is User {
  return (
    typeof data === 'object' &&
    data !== null &&
    'id' in data &&
    'email' in data
  );
}

if (isUser(response)) {
  const data: User = response;
}

// ✅ CORRECT - Use Zod validation
const userSchema = z.object({
  id: z.string(),
  email: z.string().email(),
});
const data = userSchema.parse(response);

// ✅ ACCEPTABLE - DOM elements
const button = document.querySelector('.btn') as HTMLButtonElement;
```

### ❌ Error: Not handling null/undefined from database queries
**What happened:**
- Assumed database query always returns data
- Runtime errors when data is null
- UI crashes

**Root cause:**
- Not checking for null/undefined in query results
- Not handling empty states

**✅ Prevention:**
1. Always check for null/undefined after database queries
2. Use optional chaining when accessing nested properties
3. Provide fallback values with nullish coalescing
4. Show proper loading/empty/error states in UI

```typescript
// ❌ WRONG
async function UserProfile({ userId }: { userId: string }) {
  const { data } = await supabase
    .from('users')
    .select('*')
    .eq('id', userId)
    .single();

  return <div>{data.name}</div>; // Crashes if data is null
}

// ✅ CORRECT
async function UserProfile({ userId }: { userId: string }) {
  const { data, error } = await supabase
    .from('users')
    .select('*')
    .eq('id', userId)
    .single();

  if (error) return <div>Error: {error.message}</div>;
  if (!data) return <div>User not found</div>;

  return <div>{data.name}</div>;
}

// ✅ CORRECT - With optional chaining
function UserProfile({ user }: { user?: User }) {
  return <div>{user?.name ?? 'Anonymous'}</div>;
}
```

### ❌ Error: Hardcoded values instead of constants/enums
**What happened:**
- Magic strings and numbers scattered throughout code
- Typos not caught at compile time
- Hard to refactor

**Root cause:**
- Not using TypeScript enums or const objects
- Copy-pasting values

**✅ Prevention:**
1. Use TypeScript enums or const objects for fixed values
2. Use discriminated unions for state machines
3. Generate types from database enums

```typescript
// ❌ WRONG
if (status === 'pending') { /* ... */ }
if (status === 'pening') { /* ... */ } // Typo not caught!

// ✅ CORRECT - Use enum
enum Status {
  Pending = 'pending',
  Approved = 'approved',
  Rejected = 'rejected',
}
if (status === Status.Pending) { /* ... */ }

// ✅ CORRECT - Use const object
const STATUS = {
  PENDING: 'pending',
  APPROVED: 'approved',
  REJECTED: 'rejected',
} as const;
type StatusValue = typeof STATUS[keyof typeof STATUS];

// ✅ CORRECT - Use discriminated union
type State =
  | { status: 'pending' }
  | { status: 'approved'; approvedBy: string }
  | { status: 'rejected'; reason: string };
```

---

## CSS & Styling Rules

### ❌ Error: Hardcoded colors instead of CSS variables
**What happened:**
- Used Tailwind color classes like `bg-gray-800`, `text-blue-500`
- Theme changes require updating every component
- Dark mode doesn't work properly

**Root cause:**
- Not using CSS variables for theming
- Not following design system

**✅ Prevention:**
1. **ALWAYS use CSS variables from theme files**
2. Use `bg-[var(--color-bg-card)]` instead of `bg-gray-800`
3. Define all colors in theme CSS files
4. Use predefined CSS classes from design system

```css
/* ✅ Define in theme file */
:root {
  --color-bg-primary: #ffffff;
  --color-bg-secondary: #f3f4f6;
  --color-text-primary: #111827;
  --color-accent: #3b82f6;
}

[data-theme="dark"] {
  --color-bg-primary: #1f2937;
  --color-bg-secondary: #111827;
  --color-text-primary: #f9fafb;
  --color-accent: #60a5fa;
}
```

```tsx
// ❌ WRONG
<div className="bg-gray-800 text-white">
  <button className="bg-blue-500 hover:bg-blue-600">
    Click me
  </button>
</div>

// ✅ CORRECT - Use CSS variables
<div className="bg-[var(--color-bg-primary)] text-[var(--color-text-primary)]">
  <button className="bg-[var(--color-accent)] hover:bg-[var(--color-accent-hover)]">
    Click me
  </button>
</div>

// ✅ BETTER - Use predefined classes
<div className="card">
  <button className="btn btn-primary">
    Click me
  </button>
</div>
```

### ❌ Error: Inline styles instead of Tailwind/CSS
**What happened:**
- Used `style={{ backgroundColor: '#1f2937' }}`
- Styles not consistent with design system
- Hard to maintain

**Root cause:**
- Taking shortcuts
- Not using design system classes

**✅ Prevention:**
1. Never use inline `style` prop with colors
2. Use Tailwind classes or CSS classes
3. Use CSS variables for dynamic values

```tsx
// ❌ WRONG
<div style={{ backgroundColor: '#1f2937', color: '#ffffff' }}>
  Content
</div>

// ✅ CORRECT
<div className="bg-[var(--color-bg-card)] text-[var(--color-text-primary)]">
  Content
</div>
```

---

## Architecture & Import Rules

### ❌ Error: Cross-feature imports
**What happened:**
- Feature A imports from Feature B directly
- Creates circular dependencies
- Breaks bulletproof-react architecture

**Root cause:**
- Not understanding feature boundaries
- Taking shortcuts

**✅ Prevention:**
1. **Features CANNOT import from other features**
2. Shared code goes in `lib/`, `components/`, `hooks/`, `types/`, `utils/`
3. Compose features at the `app/` layer only
4. Configure ESLint to enforce boundaries

```typescript
// ❌ WRONG
// src/features/leads/components/LeadCard.tsx
import { DealPipeline } from '@/features/deals/components/DealPipeline';

// ✅ CORRECT - Move shared component
// src/components/shared/Pipeline.tsx
export function Pipeline() { /* ... */ }

// Then use in both features:
// src/features/leads/components/LeadCard.tsx
import { Pipeline } from '@/components/shared/Pipeline';

// src/features/deals/components/DealCard.tsx
import { Pipeline } from '@/components/shared/Pipeline';
```

### ❌ Error: Business logic in app/pages
**What happened:**
- Database queries, API calls, calculations in page components
- Hard to test and reuse
- Violates separation of concerns

**Root cause:**
- Not following bulletproof-react architecture
- Putting everything in pages

**✅ Prevention:**
1. Pages should be thin - only routing and composition
2. Business logic goes in `features/[feature]/api/`
3. Use TanStack Query hooks for data fetching
4. Use server actions for mutations

```typescript
// ❌ WRONG - Logic in page
// app/leads/page.tsx
export default async function LeadsPage() {
  const supabase = createClient();
  const { data } = await supabase.from('leads').select('*'); // ❌
  const filteredLeads = data.filter(lead => lead.status === 'active'); // ❌
  return <div>{filteredLeads.map(...)}</div>;
}

// ✅ CORRECT - Logic in feature
// src/features/leads/api/get-leads.ts
export async function getLeads() {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('leads')
    .select('*')
    .eq('status', 'active');
  if (error) throw error;
  return data;
}

// app/leads/page.tsx
import { getLeads } from '@/features/leads/api/get-leads';
import { LeadsList } from '@/features/leads';

export default async function LeadsPage() {
  const leads = await getLeads();
  return <LeadsList leads={leads} />;
}
```

---

## Build & Deployment Errors

### ❌ Error: Build passes locally but fails on Vercel
**What happened:**
- `npm run build` works locally
- Vercel build fails with type errors
- Deployment blocked

**Root cause:**
- Strict mode not enabled locally
- Environment differences
- TypeScript not checking all files

**✅ Prevention:**
1. Run `npm run type-check` before pushing
2. Run `npm run lint` before pushing
3. Enable strict mode in tsconfig.json
4. Test production build locally: `npm run build`
5. Check `.next/` output for errors

```bash
# Run these before committing
npm run type-check  # TypeScript check all files
npm run lint        # ESLint
npm run build       # Production build
```

### ❌ Error: SDK API version drift breaks TypeScript at deploy time
**What happened:**
- Build failed with typed SDK version mismatch (example: Stripe `LatestApiVersion`)
- One file was updated, but many handlers still had old hardcoded `apiVersion` literals
- Local runtime seemed fine until strict type check in production build

**Root cause:**
- API version literals were duplicated across many files
- No single source of truth for SDK versions
- No CI drift scan for hardcoded literals

**✅ Prevention:**
1. Define one shared version constant (example: `STRIPE_API_VERSION`) and import it everywhere
2. Ban hardcoded `apiVersion: '....'` literals outside the shared constants file
3. Add CI drift check that greps for hardcoded version literals
4. Treat `LatestApiVersion` compile failures as release blockers

### ❌ Error: False-positive API smoke from signed-out requests only
**What happened:**
- Smoke tests ran only with signed-out context
- Protected APIs returned middleware rewrite `404` instead of reaching route logic
- Team marked flow "healthy" without validating real signed-in path

**Root cause:**
- No auth-boundary smoke matrix (signed-out + signed-in)
- Curl-only smoke without authenticated session coverage
- Middleware/auth behavior masked route-level issues

**✅ Prevention:**
1. For critical flows, always test both signed-out and signed-in contexts
2. Require explicit expected behavior per context (`401/403` vs success path)
3. Do not certify integrations/billing flows from unsigned smoke evidence alone
4. Capture and review middleware headers (`X-Clerk-Auth-*`, rewrite hints) during smoke

### ❌ Error: Clerk deprecation warnings ignored in auth/billing paths
**What happened:**
- Browser console showed deprecated Clerk props (`afterSignInUrl` / `afterSignUpUrl`)
- Warnings were ignored until checkout/auth behavior drifted

**Root cause:**
- Deprecated API usage remained in production code
- No release gate for auth-path deprecation warnings

**✅ Prevention:**
1. Replace deprecated Clerk redirect props with `fallbackRedirectUrl` / `forceRedirectUrl`
2. Add deprecation warning checks to release smoke on auth and billing pages
3. Treat auth/billing deprecation warnings as HIGH severity until fixed

### ❌ Error: Environment variables not working in production
**What happened:**
- App works locally but crashes in production
- Environment variables undefined

**Root cause:**
- Forgot to add env vars to Vercel
- Used wrong prefix (need `NEXT_PUBLIC_` for client-side)

**✅ Prevention:**
1. Client-side vars MUST start with `NEXT_PUBLIC_`
2. Add all env vars in Vercel dashboard
3. Select "All Environments" when adding vars
4. Validate env vars with Zod at startup

```typescript
// ✅ CORRECT - Validate env vars
import { z } from 'zod';

const envSchema = z.object({
  NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(1),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
});

export const env = envSchema.parse(process.env);
```

---

## Updated Checklist for New Features

Before implementing any feature:

- [ ] Read this document (`common-errors-and-lessons.md`)
- [ ] Read relevant migration files for exact database schema
- [ ] Check existing code patterns in the codebase
- [ ] Verify all imports are correct and respect architecture boundaries
- [ ] Use ZERO `any` types
- [ ] Use ZERO `@ts-ignore` or `@ts-expect-error`
- [ ] Use ZERO non-null assertions (`!`)
- [ ] All function parameters and returns have explicit types
- [ ] All unused variables/imports removed
- [ ] Use CSS variables, not hardcoded colors
- [ ] Follow bulletproof-react architecture (no cross-feature imports)
- [ ] Add comprehensive error logging
- [ ] Test the complete flow end-to-end
- [ ] Run `npm run type-check` successfully
- [ ] Run `npm run lint` successfully
- [ ] Run `npm run build` successfully
- [ ] Verify error handling (don't swallow errors)
- [ ] Check that UI state updates match API responses
- [ ] Add user-facing error messages

---

## Data Sync & Integration Errors

### ❌ Error: API pagination limits causing incomplete data sync
**What happened** (aso-platform):
- HubSpot has 336 deals but only 100 were synced to database
- Dashboard showed 60 deals when it should show 234
- Used `getPage(100)` without pagination loop

**Root cause:**
- Not implementing pagination when syncing from external APIs
- Assuming all data fits in first page
- Hard limit of 100 items in API call

**✅ Prevention:**
1. **ALWAYS implement pagination for external API syncs**
2. Use `do-while` loop with `after` cursor
3. Log page count and total synced items
4. Test with datasets larger than 100 items
5. Add progress logging (e.g., "Page 1...", "Page 2...")

**Example:**
```typescript
// ❌ WRONG - Only gets first 100
const deals = await hubspot.crm.deals.basicApi.getPage(100);

// ✅ CORRECT - Gets all deals with pagination
let after: string | undefined = undefined;
let allDeals = [];
do {
  const response = await hubspot.crm.deals.basicApi.getPage(100, after);
  allDeals.push(...response.results);
  after = response.paging?.next?.after;
} while (after);

console.log(`✅ Synced ${allDeals.length} total deals`);
```

### ❌ Error: Database filtering excludes data with invalid field values
**What happened** (aso-platform):
- Owner Dashboard showed $0 revenue despite 108 deals with amounts
- Filter used `close_date` field which had invalid values (1970-01-01 from epoch 0)
- Date range filter excluded ALL deals
- Used exact match `eq('deal_stage', 'closed_won')` when actual values were `'Closed Won – Solar'`

**Root cause:**
- Not validating data quality before filtering
- Assuming field values are always valid
- Using exact match instead of pattern matching
- Not checking actual data values in database

**✅ Prevention:**
1. **Always run data quality checks BEFORE implementing filters**
2. Use investigation scripts to check actual field values
3. Use pattern matching (`.ilike()`) instead of exact match (`.eq()`) when appropriate
4. Filter by reliable fields (e.g., `created_at` instead of nullable `close_date`)
5. Log query results to debug empty datasets

**Example:**
```typescript
// ❌ WRONG - Filters by unreliable field with exact match
const { data } = await supabase
  .from('deals')
  .select('*')
  .eq('deal_stage', 'closed_won')  // Misses 'Closed Won – Solar'
  .gte('close_date', dateFrom)     // close_date has invalid values
  .lte('close_date', dateTo);

// ✅ CORRECT - Use reliable field and pattern match
const { data } = await supabase
  .from('deals')
  .select('*')
  .ilike('deal_stage', '%Closed Won%')  // Matches all variations
  .gte('created_at', dateFrom)          // created_at always valid
  .lte('created_at', dateTo);

// ✅ BEST - Run investigation first
// Create scripts/check-data-quality.ts
const { data: sample } = await supabase
  .from('deals')
  .select('deal_stage, close_date')
  .limit(10);

console.log('Sample data:', sample);
// Then adjust filter based on actual data
```

### ❌ Error: Missing foreign key mapping in synced data
**What happened** (aso-platform):
- 81 of 100 deals showed "Unknown" contact names and "No phone"
- Deals table had `contact_id` field but 81% were NULL
- Deals were synced without checking if contact exists in database
- Dashboard couldn't display contact information

**Root cause:**
- Not mapping foreign keys during sync
- Not checking if related records exist before insert
- Not handling missing associations gracefully in UI

**✅ Prevention:**
1. **Always build lookup maps for foreign keys before syncing**
2. Check if related records exist in database first
3. Handle NULL foreign keys gracefully in UI (extract from other fields)
4. Log mapping success rate during sync
5. Re-run sync after related tables are populated

**Example:**
```typescript
// ✅ CORRECT - Build contact map first
const { data: contacts } = await supabase
  .from('contacts')
  .select('id, hubspot_id');

const contactMap = new Map(
  contacts.map(c => [c.hubspot_id, c.id])
);

console.log(`📋 Loaded ${contactMap.size} contacts for mapping`);

// Then map during sync
for (const hsDeal of deals) {
  const hsContactId = hsDeal.associations?.contacts?.results[0]?.id;
  const contactId = contactMap.get(hsContactId) || null;

  await supabase.from('deals').upsert({
    hubspot_id: hsDeal.id,
    contact_id: contactId,  // Maps to local DB
    // ...
  });
}

// ✅ Handle NULL in UI with fallback
const contactName = contact
  ? `${contact.first_name} ${contact.last_name}`.trim()
  : deal.deal_name?.replace(/\s*\(.*?\)/, '').trim(); // Extract from deal name
```

### ❌ Error: Demo/seed data mixed with production data
**What happened** (aso-platform):
- Database had 8 demo deals with fake `hubspot_id` values (2001-2008)
- Sync script couldn't update them (IDs don't exist in HubSpot)
- Dashboard showed mix of real and fake data
- Hard to distinguish between test and real data

**Root cause:**
- Seed data uses realistic-looking IDs that clash with real data
- No clear way to identify test vs production records
- Seed data not cleaned before production sync

**✅ Prevention:**
1. **Use clearly fake IDs for seed data** (e.g., "DEMO-001", "TEST-2001")
2. Add `is_demo: boolean` field to tables for filtering
3. Clean seed data before first production sync
4. Use separate test database for development
5. Add script to detect and clean demo data

**Example:**
```typescript
// ❌ WRONG - Demo data looks real
{ hubspot_id: "2001", deal_name: "Solar Install - Doe" }

// ✅ CORRECT - Clearly marked as demo
{ hubspot_id: "DEMO-2001", deal_name: "Solar Install - Doe", is_demo: true }

// ✅ Clean demo data before prod sync
const { data: demoDeals } = await supabase
  .from('deals')
  .select('id, hubspot_id')
  .or('hubspot_id.like.DEMO-%,hubspot_id.like.TEST-%,is_demo.eq.true');

await supabase.from('deals').delete().in('id', demoDeals.map(d => d.id));
console.log(`🗑️  Cleaned ${demoDeals.length} demo deals`);
```

### ❌ Error: Hardcoded mock data in production dashboards
**What happened** (aso-platform):
- Dashboard showed fake names (John Anderson, Sarah Williams, etc.)
- Data was hardcoded in `useState` with mock arrays
- Real API endpoints existed but weren't being called
- User couldn't tell if data was real or fake

**Root cause:**
- Leaving mock data in production code
- Not removing placeholder UI implementations
- Not testing with real data during development

**✅ Prevention:**
1. **NEVER commit hardcoded mock data in production code**
2. Use proper loading states and API calls from the start
3. Add comments `// TODO: Connect to real API` if using mocks temporarily
4. Search codebase for common mock names before launch (John Doe, Test User, etc.)
5. Add empty state messages to distinguish no-data from mock-data

**Example:**
```typescript
// ❌ WRONG - Hardcoded mock data in production
const [users] = useState([
  { id: '1', name: 'John Anderson', email: 'john@example.com' },
  { id: '2', name: 'Sarah Williams', email: 'sarah@example.com' },
]);

// ✅ CORRECT - Fetch real data
const [users, setUsers] = useState<User[]>([]);
const [loading, setLoading] = useState(true);

useEffect(() => {
  async function fetchUsers() {
    const response = await fetch('/api/users');
    const data = await response.json();
    setUsers(data);
    setLoading(false);
  }
  fetchUsers();
}, []);

if (loading) return <LoadingSpinner />;
if (users.length === 0) return <EmptyState message="No users found" />;
```

### ❌ Error: TypeScript null safety issues in API endpoints
**What happened** (aso-platform):
- Build failed: "Type error: 'ownerContacts' is possibly 'null'"
- Used `typeof data` in Record type which included null
- TypeScript couldn't guarantee array methods would work
- Vercel deployment blocked

**Root cause:**
- Not handling null from Supabase queries
- Using `typeof` with potentially null values for types
- Not adding fallback arrays for null results

**✅ Prevention:**
1. **Always provide fallback arrays for null query results**
2. Use intermediate variables with `|| []` for type safety
3. Don't use `typeof nullableValue` in type definitions
4. Test TypeScript compilation locally before pushing

**Example:**
```typescript
// ❌ WRONG - Type includes null
const { data: contacts } = await supabase.from('contacts').select('*');
const contactsByOwner: Record<string, typeof contacts> = {}; // ERROR: contacts can be null
contacts?.forEach(...); // Might be null

// ✅ CORRECT - Safe with fallback
const { data: contacts } = await supabase.from('contacts').select('*');
const safeContacts = contacts || []; // Always array
const contactsByOwner: Record<string, typeof safeContacts> = {};
safeContacts.forEach(...); // Safe to use array methods
```

---

## Patterns from the IPTV Platform Audit (April 2026)

### ❌ Error: Supabase `SECURITY DEFINER` RPCs callable by any authenticated user
**What happened** (iptv-platform):
- `transfer_credits` and `activate_subscription` RPCs used `SECURITY DEFINER` (runs as postgres, bypasses RLS)
- No `REVOKE ALL FROM PUBLIC` and no `auth.uid()` guard
- Any authenticated user could activate subscriptions or transfer credits

**Root cause:**
- Assuming RLS also protects stored functions — it does not
- `SECURITY DEFINER` is a separate privilege layer from table RLS

**✅ Prevention:**
1. After every `CREATE FUNCTION ... SECURITY DEFINER`, immediately add:
   ```sql
   REVOKE ALL ON FUNCTION my_function FROM PUBLIC;
   GRANT EXECUTE ON FUNCTION my_function TO service_role; -- or authenticated
   ```
2. Add `auth.uid()` guard inside the function if callers must be the record owner
3. Audit existing functions: `SELECT routine_name FROM information_schema.routines WHERE routine_schema = 'public' AND security_type = 'DEFINER'`
4. See `security/security-standards.md` — "Supabase RPC Authorization" for full pattern

---

### ❌ Error: Vitest `vi.mock()` factory references uninitialized variable
**What happened** (iptv-platform):
- Declared `const mockFrom = vi.fn()` then used it in `vi.mock('...', () => ({ supabase: { from: mockFrom } }))`
- Error at test run: `ReferenceError: Cannot access 'mockFrom' before initialization`

**Root cause:**
- Vitest hoists `vi.mock()` calls to the top of the file (before any variable declarations) to ensure mocks are registered before imports
- Variables declared with `const`/`let` are NOT hoisted — they're in the temporal dead zone when the factory runs

**✅ Prevention:**
```typescript
// ✅ CORRECT — use vi.hoisted() to declare variables before hoisting
const { mockFrom } = vi.hoisted(() => ({ mockFrom: vi.fn() }))
vi.mock('../lib/supabase', () => ({
  supabase: { from: mockFrom, rpc: vi.fn() },
}))

// ❌ WRONG — mockFrom is not yet initialized when vi.mock factory runs
const mockFrom = vi.fn()
vi.mock('../lib/supabase', () => ({
  supabase: { from: mockFrom }, // ReferenceError!
}))
```

---

### ❌ Error: Vitest global coverage threshold fails when starting from 0%
**What happened** (iptv-platform):
- Set global `thresholds: { lines: 70, functions: 70 }` before writing most tests
- `npm run test:coverage` immediately fails with "coverage does not meet global threshold"
- Blocks the CI pipeline even though newly-written tests have high coverage

**Root cause:**
- Global thresholds apply to ALL included files, including files with 0% coverage
- Starting a test suite from scratch makes global thresholds unreachable until most files are tested

**✅ Prevention:**
```typescript
// vitest.config.ts — use per-file thresholds on tested modules only
thresholds: {
  'src/lib/cache.ts': { lines: 95, functions: 95 },
  'src/lib/validator.ts': { lines: 80, functions: 95 },
  'src/routes/auth.ts': { lines: 50, functions: 55 },
  // Add global threshold only when most files have tests:
  // lines: 70, functions: 70
},
```
Increase thresholds incrementally as test coverage grows. Never set a global threshold you can't currently meet.

---

### ❌ Error: npm audit CVE requires breaking-change major version bump
**What happened** (iptv-platform):
- `fast-jwt` had critical CVE — fix required `@fastify/jwt@10` which requires `fastify@5`
- Blindly running `npm audit fix --force` would break the API server without TypeScript verification

**Root cause:**
- CVE fixes sometimes require framework major version bumps (e.g., fastify v4→v5)
- `npm audit fix --force` applies fixes without checking if the app still compiles or tests pass

**✅ Prevention:**
1. Run audit fix on ALL ecosystem plugins together, not just the vulnerable one:
   ```bash
   npm install fastify@latest @fastify/jwt@latest @fastify/cors@latest \
     @fastify/helmet@latest @fastify/rate-limit@latest --save
   ```
2. Immediately run `npm run build` — catches API changes in the TypeScript compilation
3. Immediately run `npm test` — verifies behavior is unchanged
4. Check the framework's migration guide for breaking changes before assuming the build means success
5. See `architecture/fastify.md` — "Dependency CVE Upgrades with Breaking Changes"

---

## Notes

- This is a living document - update it as new patterns emerge
- Focus on errors that happen repeatedly across projects
- Include specific code examples for clarity
- Keep prevention steps actionable and specific
- Review `CHANGELOG.md` and recent merged PRs for raw incident context and recurrence trends
- **Last updated:** April 10, 2026 — Supabase RPC privilege escalation; Vitest `vi.hoisted()` for mocks; Vitest per-file coverage thresholds; CVE major version upgrade process; (plus earlier: Next.js webhook vs `parseBody` checklist; chart/SVG theming; `exceljs` vs `xlsx`; Vitest `vi.stubEnv`; documentation drift)
