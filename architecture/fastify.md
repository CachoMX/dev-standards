# Fastify API Server Standards

## Overview

Patterns for building Fastify-based API servers — applicable when Next.js is not the right fit (e.g., a dedicated API layer separate from the frontend, media-proxying, or Android TV backends). These complement `architecture/api-patterns.md`.

---

## 1. When to Use Fastify vs Next.js API Routes

| Scenario | Use |
|---|---|
| Dedicated API server (separate from frontend) | Fastify |
| Media streaming / proxying | Fastify (native stream support) |
| Android TV / mobile backend | Fastify |
| Webhook receiver + admin panel combined | Next.js API routes |
| Pure frontend + Supabase direct | Next.js API routes or none |

---

## 2. App Bootstrap Pattern

Always validate required env vars before creating the server. Fail fast with clear errors — not silently at the first request.

```typescript
// src/index.ts
import 'dotenv/config'
import Fastify from 'fastify'
import cors from '@fastify/cors'
import jwt from '@fastify/jwt'
import helmet from '@fastify/helmet'
import rateLimit from '@fastify/rate-limit'

// Fail immediately if critical env vars are missing
if (!process.env.JWT_SECRET) throw new Error('JWT_SECRET is required')
if (!process.env.STREAM_SIGNING_SECRET) throw new Error('STREAM_SIGNING_SECRET is required')

const server = Fastify({
  logger: {
    transport: { target: 'pino-pretty', options: { colorize: true, ignore: 'pid,hostname' } },
  },
  genReqId: () => crypto.randomUUID(),
})

server.register(helmet, { /* CSP, CORP, referrer policy */ })
server.register(cors, { origin: process.env.CORS_ORIGIN || 'http://localhost:3000', credentials: true })
server.register(rateLimit, { global: true, max: 100, timeWindow: '1 minute' })
server.register(jwt, { secret: process.env.JWT_SECRET })

// Routes with prefixes
server.register(authRoutes, { prefix: '/auth' })
server.register(contentRoutes, { prefix: '/content' })
```

**Rules:**
- CORS `origin` always from env var — never hardcode, never `*` in production
- Register `helmet` before CORS and routes
- Use `genReqId: () => crypto.randomUUID()` for traceable request IDs

---

## 3. Route File Structure (Monolith Split)

Any route file over ~400 lines signals a monolith. Split by domain:

```
src/routes/
├── auth.ts            ← login, refresh, /me, device binding
├── watchhistory.ts    ← watch progress CRUD
├── downloads.ts       ← download management
└── content/
    ├── index.ts       ← router + shared preHandler + image/stream/home/search/live
    ├── movies.ts      ← movie list, detail, filter
    ├── series.ts      ← series list, episodes
    ├── adults.ts      ← adult content (separate auth enforcement)
    └── shared.ts      ← shared types/helpers between content submodules
```

Each sub-plugin inherits hooks from the parent plugin:

```typescript
// content/index.ts
const contentRoutes: FastifyPluginAsync = async (fastify) => {
  // Auth preHandler applies to all sub-plugins
  fastify.addHook('preHandler', async (request, reply) => {
    const url = request.url || ''
    // Skip auth for public endpoints (streams, images)
    if (url.includes('/stream/play/') || url.includes('/image/')) return
    try {
      await request.jwtVerify()
    } catch (err) {
      return reply.send(err)
    }
  })

  // Sub-plugins inherit the preHandler hook
  fastify.register(moviesRoutes, { prefix: '/movies' })
  fastify.register(seriesRoutes, { prefix: '/series' })
  fastify.register(adultsRoutes, { prefix: '/adults' })
}
```

---

## 4. JWT Authentication Pattern

```typescript
// In route file — no inline try/catch boilerplate on every route
// Add to plugin's preHandler instead:
fastify.addHook('preHandler', async (request, reply) => {
  try {
    await request.jwtVerify()
  } catch (err) {
    return reply.send(err) // Fastify JWT formats error correctly (401)
  }
})

// In individual route — access typed user:
interface JWTPayload { sub: string; email: string; role: string }
const user = request.user as JWTPayload
```

**Per-route rate limiting override:**
```typescript
server.post('/login', {
  config: { rateLimit: { max: 10, timeWindow: '1 minute' } }, // overrides global
}, handler)
```

---

## 5. HMAC-Signed Short-Lived URLs (Stream Authorization)

For proxied media where you can't use JWT in the URL (TV apps, M3U players):

```typescript
import { createHmac, timingSafeEqual } from 'crypto'

// 1. Generate signed URL (requires auth)
const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString()
const payload = `${type}:${id}:${userId}:${expiresAt}`
const sig = createHmac('sha256', process.env.STREAM_SIGNING_SECRET).update(payload).digest('hex')
const streamUrl = `/content/stream/play/${type}/${id}?uid=${userId}&exp=${expiresAt}&sig=${sig}`

// 2. Validate at proxy endpoint (no auth required — signature IS the auth)
const expiresAt = new Date(decodeURIComponent(exp))
if (Date.now() > expiresAt.getTime()) return reply.status(403).send({ error: 'Expired' })

const expected = createHmac('sha256', secret).update(`${type}:${id}:${uid}:${exp}`).digest('hex')
if (sig !== expected) return reply.status(403).send({ error: 'Invalid signature' })
```

**Rules:**
- Short expiry (5 minutes max) — prevents link sharing
- Include `userId` in payload — ties URL to specific user
- Use `timingSafeEqual` when comparing digests if using Buffer comparison

---

## 6. Stream Proxy Pattern

Pipe upstream media through Fastify without loading it into memory:

```typescript
import { Readable } from 'stream'

fastify.get('/stream/play/:type/:id', async (request, reply) => {
  // ... signature validation ...

  const upstream = await fetch(jellyfinUrl, {
    headers: { 'X-Emby-Token': apiKey, ...(range ? { Range: range } : {}) },
    signal: AbortSignal.timeout(30_000),
  })

  // Forward headers before sending body
  reply.raw.setHeader('Content-Type', upstream.headers.get('content-type') || 'video/mp4')
  reply.raw.setHeader('Cache-Control', 'no-store')
  const contentLength = upstream.headers.get('content-length')
  if (contentLength) reply.raw.setHeader('Content-Length', contentLength)
  reply.raw.statusCode = upstream.status

  // Pipe web stream as Node.js readable — no buffering
  return reply.send(Readable.fromWeb(upstream.body as any))
})
```

---

## 7. Health Check Endpoint

Every API must have `/health` that checks real dependencies:

```typescript
server.get('/health', async () => {
  let jellyfinReachable = false
  let dbReachable = false

  await Promise.allSettled([
    fetch(`${process.env.JELLYFIN_URL}/health`, { signal: AbortSignal.timeout(2000) })
      .then(() => { jellyfinReachable = true }).catch(() => {}),
    fetch(`${process.env.SUPABASE_URL}/rest/v1/`, { signal: AbortSignal.timeout(2000) })
      .then(r => { dbReachable = r.status < 500 }).catch(() => {}),
  ])

  return {
    status: 'ok',
    uptime_seconds: Math.round(process.uptime()),
    jellyfin_reachable: jellyfinReachable,
    db_reachable: dbReachable,
    timestamp: new Date().toISOString(),
  }
})
```

---

## 8. Testing Fastify Routes (Vitest + inject)

Use `fastify.inject()` — no real HTTP server needed, no port conflicts in CI:

```typescript
// __tests__/helpers/buildTestApp.ts
import Fastify from 'fastify'
import jwtPlugin from '@fastify/jwt'
import rateLimitPlugin from '@fastify/rate-limit'

export const TEST_JWT_SECRET = 'test-secret-32-chars-minimum-length'

export async function buildTestApp() {
  const app = Fastify({ logger: false })
  await app.register(jwtPlugin, { secret: TEST_JWT_SECRET })
  await app.register(rateLimitPlugin, { global: false }) // disable global in tests
  return app
}
```

```typescript
// __tests__/routes/auth.test.ts
describe('POST /auth/login', () => {
  let app: FastifyInstance

  beforeEach(async () => {
    vi.clearAllMocks()
    app = await buildTestApp()
    await app.register(authRoutes)
    await app.ready()
  })

  afterAll(async () => { await app?.close() })

  it('returns 400 for missing fields', async () => {
    const res = await app.inject({ method: 'POST', url: '/login', payload: {} })
    expect(res.statusCode).toBe(400)
  })
})
```

**Mocking Supabase in Fastify tests — `vi.hoisted()` is required:**

```typescript
// vi.mock is hoisted to the top of the file by Vitest.
// Variables declared AFTER vi.mock() are not yet initialized when the factory runs.
// Use vi.hoisted() to declare them before hoisting:

const { mockFrom } = vi.hoisted(() => ({ mockFrom: vi.fn() }))

vi.mock('../lib/supabase', () => ({
  supabase: { from: mockFrom, rpc: vi.fn() },
}))
// ❌ WRONG — mockFrom is not initialized when factory runs:
// const mockFrom = vi.fn()
// vi.mock('../lib/supabase', () => ({ supabase: { from: mockFrom } }))
// → ReferenceError: Cannot access 'mockFrom' before initialization
```

---

## 9. Dependency CVE Upgrades with Breaking Changes

When `npm audit` reports CVEs requiring major version bumps (e.g., fastify v4→v5, @fastify/jwt v8→v10):

1. **Check what the audit fix installs:** `npm audit fix --force --dry-run`
2. **Update all ecosystem plugins together** — upgrading fastify without its plugins causes peer dependency errors:
   ```bash
   npm install fastify@latest @fastify/jwt@latest @fastify/cors@latest \
     @fastify/helmet@latest @fastify/rate-limit@latest --save
   ```
3. **Run TypeScript build immediately:** `npm run build` — catches breaking API changes
4. **Run tests:** `npm test` — verify behavior is unchanged
5. **Check for removed APIs** in the framework's migration guide before assuming the build is complete

**Do not** use `npm audit fix --force` blindly on production code without verifying the build and tests pass.

---

## 10. Fastify Checklist

### New project

- [ ] Env vars validated at startup — throw if missing
- [ ] `@fastify/helmet` registered before routes
- [ ] `@fastify/cors` uses env var for origin, never `*`
- [ ] `@fastify/rate-limit` global + per-route overrides for sensitive endpoints
- [ ] `@fastify/jwt` registered with env secret
- [ ] All routes behind auth use `request.jwtVerify()` in preHandler
- [ ] All route input validated with Zod before any DB call
- [ ] `/health` endpoint checks real dependencies

### Before deploy

- [ ] `npm audit` — zero high/critical
- [ ] `npm run build` (TypeScript) — zero errors
- [ ] All tests pass (`npm test`)
- [ ] CORS origin matches production domain (not localhost)
- [ ] Stream signing secret set in production env
