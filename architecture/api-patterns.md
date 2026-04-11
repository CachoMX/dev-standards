# API Design Patterns

## Overview

Consistent API patterns across projects mean less guessing, fewer bugs, and faster onboarding. Whether you're building Supabase Edge Functions, n8n webhook handlers, or any custom API — follow these conventions.

---

## Response Format

Every API response follows the same structure:

```typescript
// Success
{
  "data": { ... } | [ ... ],
  "meta": {
    "total": 150,
    "page": 1,
    "per_page": 20,
    "total_pages": 8
  }
}

// Error
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email is required",
    "details": [
      { "field": "email", "message": "This field is required" }
    ]
  }
}
```

### TypeScript Types

```typescript
// src/types/api.ts

interface ApiSuccessResponse<T> {
  data: T;
  meta?: PaginationMeta;
}

interface ApiErrorResponse {
  error: {
    code: string;
    message: string;
    details?: Array<{ field: string; message: string }>;
  };
}

type ApiResponse<T> = ApiSuccessResponse<T> | ApiErrorResponse;

interface PaginationMeta {
  total: number;
  page: number;
  per_page: number;
  total_pages: number;
}
```

---

## Error Codes

Use consistent error codes across all projects:

| Code | HTTP Status | When |
|---|---|---|
| `VALIDATION_ERROR` | 400 | Input failed Zod validation |
| `UNAUTHORIZED` | 401 | No auth token or expired session |
| `FORBIDDEN` | 403 | Authenticated but no permission |
| `NOT_FOUND` | 404 | Resource doesn't exist |
| `CONFLICT` | 409 | Duplicate entry, state conflict |
| `RATE_LIMITED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Unexpected server error |
| `SERVICE_UNAVAILABLE` | 503 | External dependency down |

### Client-Side Error Handling

```typescript
// src/lib/api-client.ts

class ApiError extends Error {
  constructor(
    public code: string,
    message: string,
    public status: number,
    public details?: Array<{ field: string; message: string }>,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

async function apiRequest<T>(
  url: string,
  options?: RequestInit,
): Promise<T> {
  const response = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
  });

  const body = await response.json();

  if (!response.ok) {
    throw new ApiError(
      body.error?.code ?? 'UNKNOWN_ERROR',
      body.error?.message ?? 'An unexpected error occurred',
      response.status,
      body.error?.details,
    );
  }

  return body.data;
}
```

---

## Next.js App Router API Routes

When building with Next.js (not Vite + React), API routes live in `app/api/[route]/route.ts`. Every route must follow these conventions.

### Mandatory Route Template

```typescript
// app/api/example/route.ts
import { NextResponse } from 'next/server';
import { auth } from '@clerk/nextjs/server'; // or your auth provider
import { supabaseAdmin } from '@/lib/supabase/admin';
import { z } from 'zod';
import { parseBody } from '@/lib/validation/schemas';

// Required on every route that reads auth/cookies
export const dynamic = 'force-dynamic';

const bodySchema = z.object({
  name: z.string().min(1).max(200),
  email: z.string().email(),
});

export async function POST(req: Request) {
  const { userId } = await auth();
  if (!userId) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  // ✅ Validate body before touching DB
  const parsed = await parseBody(req, bodySchema);
  if (parsed instanceof NextResponse) return parsed;
  const { name, email } = parsed.data;

  // ✅ Explicit column selects — no SELECT *
  const { data: tenant } = await supabaseAdmin
    .from('tenants')
    .select('id, plan_id, subscription_status')
    .eq('clerk_user_id', userId)
    .single();

  // ✅ Idempotency guard before mutating
  if (tenant?.subscription_status === 'canceling') {
    return NextResponse.json({ error: 'Already in progress' }, { status: 409 });
  }

  // ... business logic ...

  return NextResponse.json({ success: true });
}
```

### The Three Rules

| Rule | Why |
|------|-----|
| `export const dynamic = 'force-dynamic'` | Routes using auth/headers crash at build time without it |
| `parseBody(req, schema)` before any DB write | Malformed input returns 400 before touching the database |
| Explicit `.select('id, col1, col2')` never `'*'` | `SELECT *` leaks columns added later; breaks typed responses |

**Webhook routes are excluded from `parseBody` for the initial read** — use `await req.text()`, verify the signature, then `JSON.parse` and Zod (see "Read raw body once" below).

### `parseBody` Helper

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

---

## Pagination

### Request Format

```
GET /api/leads?page=1&per_page=20&sort=created_at&order=desc
```

| Parameter | Default | Max | Description |
|---|---|---|---|
| `page` | 1 | — | Page number |
| `per_page` | 20 | 100 | Items per page |
| `sort` | `created_at` | — | Sort field |
| `order` | `desc` | — | `asc` or `desc` |

### Supabase Implementation

```typescript
async function fetchLeadsPaginated(page: number, perPage: number) {
  const from = (page - 1) * perPage;
  const to = from + perPage - 1;

  const { data, error, count } = await supabase
    .from('leads')
    .select('*', { count: 'exact' })
    .order('created_at', { ascending: false })
    .range(from, to);

  if (error) throw error;

  return {
    data: data ?? [],
    meta: {
      total: count ?? 0,
      page,
      per_page: perPage,
      total_pages: Math.ceil((count ?? 0) / perPage),
    },
  };
}
```

### TanStack Query Integration

```typescript
function useLeads(page: number, perPage = 20) {
  return useQuery({
    queryKey: ['leads', { page, perPage }],
    queryFn: () => fetchLeadsPaginated(page, perPage),
    placeholderData: keepPreviousData, // Smooth page transitions
  });
}
```

---

## Filtering

### Request Format

```
GET /api/leads?status=active&source=web,referral&created_after=2025-01-01
```

### Implementation Pattern

```typescript
// Build query dynamically from filters
interface LeadFilters {
  status?: string;
  source?: string[];
  created_after?: string;
  created_before?: string;
  search?: string;
}

function buildLeadsQuery(filters: LeadFilters) {
  let query = supabase
    .from('leads')
    .select('*', { count: 'exact' });

  if (filters.status) {
    query = query.eq('status', filters.status);
  }

  if (filters.source?.length) {
    query = query.in('source', filters.source);
  }

  if (filters.created_after) {
    query = query.gte('created_at', filters.created_after);
  }

  if (filters.created_before) {
    query = query.lte('created_at', filters.created_before);
  }

  if (filters.search) {
    query = query.or(
      `name.ilike.%${filters.search}%,email.ilike.%${filters.search}%`,
    );
  }

  return query;
}
```

---

## External API Integration (n8n, webhooks)

### Read raw body once (HMAC / signature verification)

**You cannot call `req.json()` before verifying a signature** — the HMAC must be computed over the exact bytes the provider sent. In Next.js App Router, read the body as text first, verify, then parse JSON.

```typescript
// ✅ CORRECT — single read, verify, then parse
export async function POST(request: NextRequest) {
  const rawBody = await request.text();

  if (!verifyWebhookSignature(request, rawBody)) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  let payload: unknown;
  try {
    payload = JSON.parse(rawBody);
  } catch {
    return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 });
  }

  const result = webhookPayloadSchema.safeParse(payload);
  // ...
}
```

```typescript
// ❌ WRONG — signature verification after json() consumes / alters stream semantics
const body = await request.json();
verifySignature(header, JSON.stringify(body)); // often fails — whitespace/order differs
```

Use `timingSafeEqual` (Node `crypto`) for comparing digests. If the provider documents a header name (e.g. `x-wh-signature`, `Stripe-Signature`), implement exactly that; if they only support a **shared secret in the URL** (`?secret=` / `?token=`), that is acceptable as a second line of defense when HMAC is unavailable — but **require the secret in production** (reject or 503 if unset).

### Multiple webhook URLs for the same provider

Legacy and new routes sometimes both receive events (e.g. `/api/webhooks/ghl` and `/api/integrations/ghl/webhook`). **Apply identical authentication and validation on every entry point** — attackers probe the path that is still unauthenticated.

### Business timestamps from integrations (two different meanings)

Scheduling integrations often expose two different times; mixing them breaks analytics and billing.

| Concept | Typical meaning | Map from providers (examples) |
|--------|------------------|-------------------------------|
| **Booked / created** | When the user created the appointment or record | Calendly `created_at`, GHL `dateAdded`, HubSpot create date |
| **Scheduled / start** | When the event is supposed to occur | Calendly `start_time`, GHL `startTime`, HubSpot meeting start |

Document the mapping **per provider** in code comments or a single integration module; never store both in one field without naming which semantic it carries.

### Webhook Handler Pattern

```typescript
// Supabase Edge Function or any webhook handler

import { z } from 'zod';

// 1. Define expected payload schema
const webhookPayloadSchema = z.object({
  event: z.enum(['lead.created', 'lead.updated', 'deal.closed']),
  data: z.record(z.unknown()),
  timestamp: z.string().datetime(),
});

// 2. Validate before processing (read raw body once — see section above)
export async function handleWebhook(req: Request) {
  const rawBody = await req.text();
  const signature = req.headers.get('x-webhook-signature');
  if (!verifySignature(signature, rawBody)) {
    return new Response(JSON.stringify({
      error: { code: 'UNAUTHORIZED', message: 'Invalid signature' }
    }), { status: 401 });
  }

  let body: unknown;
  try {
    body = JSON.parse(rawBody);
  } catch {
    return new Response(JSON.stringify({
      error: { code: 'VALIDATION_ERROR', message: 'Invalid JSON' }
    }), { status: 400 });
  }

  const result = webhookPayloadSchema.safeParse(body);

  if (!result.success) {
    return new Response(JSON.stringify({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid payload',
        details: result.error.flatten().fieldErrors,
      }
    }), { status: 400 });
  }

  // Process the event
  try {
    await processEvent(result.data);
    return new Response(JSON.stringify({ data: { received: true } }), {
      status: 200,
    });
  } catch (error) {
    console.error('Webhook processing failed:', error);
    return new Response(JSON.stringify({
      error: { code: 'INTERNAL_ERROR', message: 'Processing failed' }
    }), { status: 500 });
  }
}
```

### Rate Limiting for External APIs

```typescript
// Simple rate limiter for external API calls (e.g., HubSpot, TikTok)
class RateLimiter {
  private timestamps: number[] = [];

  constructor(
    private maxRequests: number,
    private windowMs: number,
  ) {}

  async waitForSlot(): Promise<void> {
    const now = Date.now();
    this.timestamps = this.timestamps.filter(t => t > now - this.windowMs);

    if (this.timestamps.length >= this.maxRequests) {
      const waitTime = this.timestamps[0] + this.windowMs - now;
      await new Promise(resolve => setTimeout(resolve, waitTime));
    }

    this.timestamps.push(Date.now());
  }
}

// Usage with HubSpot (100 req/10s)
const hubspotLimiter = new RateLimiter(100, 10_000);

async function fetchFromHubSpot(endpoint: string) {
  await hubspotLimiter.waitForSlot();
  return fetch(`https://api.hubapi.com${endpoint}`, { ... });
}
```

### Retry Pattern

```typescript
async function fetchWithRetry<T>(
  fn: () => Promise<T>,
  maxRetries = 3,
  baseDelay = 1000,
): Promise<T> {
  let lastError: Error | undefined;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error));

      // Don't retry client errors (4xx) except 429
      if (error instanceof ApiError && error.status < 500 && error.status !== 429) {
        throw error;
      }

      if (attempt < maxRetries) {
        const delay = baseDelay * Math.pow(2, attempt); // Exponential backoff
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
  }

  throw lastError;
}
```

---

## Naming Conventions

### Endpoints

```
# Collections (plural nouns)
GET    /api/leads          → List leads
POST   /api/leads          → Create lead
GET    /api/leads/:id      → Get single lead
PATCH  /api/leads/:id      → Update lead
DELETE /api/leads/:id      → Delete lead

# Nested resources
GET    /api/leads/:id/notes    → List notes for a lead
POST   /api/leads/:id/notes    → Create note for a lead

# Actions (when CRUD doesn't fit)
POST   /api/leads/:id/convert  → Convert lead to deal
POST   /api/reports/generate   → Generate a report
```

### Query Parameters

- Use `snake_case`: `created_at`, `per_page`, `sort_by`
- Use comma for multiple values: `?status=active,pending`
- Use ISO 8601 for dates: `?created_after=2025-01-01T00:00:00Z`
