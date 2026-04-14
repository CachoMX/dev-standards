# Stack Defaults

**Last updated:** April 2026

## Default Tech Stack for All Apps

Unless explicitly specified otherwise, every app is built with this stack:

### Standard Build Profiles

Use this matrix before you scaffold:

| Profile | Use when | Primary docs |
|---|---|---|
| Vite + React App (default) | Authenticated dashboards, internal tools, admin panels | `architecture/stack-defaults.md`, `architecture/api-patterns.md` |
| Next.js App Router | Public pages, SEO, webhooks, auth middleware, billing pages | `architecture/nextjs.md`, `architecture/api-patterns.md` |
| Fastify API Service | Dedicated backend, streaming, heavy webhook/worker workloads | `architecture/fastify.md`, `security/security-standards.md` |

If a project includes more than one profile (for example Next.js frontend + Fastify API), apply both standards sets and keep shared contracts in `architecture/api-patterns.md`.

### Core

| Layer | Tool | Why |
|---|---|---|
| Build | Vite | Fastest dev server, HMR, modern ESM |
| Framework | React 19+ | Component model, ecosystem |
| Language | TypeScript (strict) | Type safety, catch errors at compile time |
| Architecture | Bulletproof React | Feature-based, scalable, unidirectional |

### State & Data

| Layer | Tool | Why |
|---|---|---|
| Server state | TanStack Query (React Query) | Caching, background updates, mutations |
| Client state | Zustand | Lightweight, no boilerplate, TypeScript-first |
| Schema validation | Zod | Runtime validation + TypeScript inference |

### UI

| Layer | Tool | Why |
|---|---|---|
| Component library | shadcn/ui | Composable, accessible, customizable |
| Styling | Tailwind CSS + CSS variables | Utility-first + themeable |
| Icons | Lucide React | Consistent, tree-shakeable |

### Routing

| Layer | Tool | Why |
|---|---|---|
| Router | React Router v7 (library mode) | Mature, flexible, Vite-compatible |

### Testing

| Layer | Tool | Why |
|---|---|---|
| Unit tests | Vitest | Jest-compatible, Vite-native, fast |
| Component tests | React Testing Library | Tests behavior, not implementation |
| E2E tests | Playwright | Cross-browser, reliable |

### Code Quality

| Layer | Tool | Why |
|---|---|---|
| Linting | ESLint | Catch bugs, enforce patterns |
| Formatting | Prettier | Consistent code style |
| Type checking | TypeScript strict mode | Zero any, explicit types |

---

## Project Structure (Bulletproof React)

```
src/
├── app/              # Routes, providers, app entry
│   ├── routes/       # Route definitions
│   ├── provider.tsx  # All global providers wrapped
│   └── router.tsx    # Router configuration
├── components/       # Shared UI components (shadcn/ui)
│   ├── ui/           # shadcn/ui base components
│   ├── layouts/      # Page layouts, navigation
│   └── shared/       # Reusable composed components
├── config/           # Environment and app configuration
├── features/         # Feature modules (THE CORE)
│   └── [feature]/
│       ├── api/          # TanStack Query hooks + API calls
│       ├── components/   # Feature-scoped components
│       ├── hooks/        # Feature-scoped hooks
│       ├── stores/       # Feature-scoped Zustand stores
│       ├── types/        # Feature-scoped types
│       ├── utils/        # Feature-scoped utilities
│       └── index.ts      # Public API exports
├── hooks/            # Shared custom hooks
├── lib/              # Pre-configured libraries (supabase, axios, etc.)
├── stores/           # Global Zustand stores
├── types/            # Shared TypeScript types
└── utils/            # Shared utility functions
```

---

## Import Rules (CRITICAL)

```
✅ ALLOWED:
  features → shared (components, hooks, lib, types, utils)
  app → features + shared

❌ FORBIDDEN:
  features → other features (NO cross-feature imports!)
  features → app
  shared → features
  shared → app
```

### Path Aliases (tsconfig.json)

```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

Usage:
- `@/components/*` — Shared components
- `@/features/*` — Feature modules
- `@/hooks/*` — Shared hooks
- `@/lib/*` — Libraries
- `@/types/*` — Shared types
- `@/utils/*` — Shared utilities
- `@/stores/*` — Global stores
- `@/config/*` — Configuration

---

## TypeScript Configuration (tsconfig.json)

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true,
    "exactOptionalPropertyTypes": false,
    "noUncheckedIndexedAccess": true
  }
}
```

---

## When to Use a Different Stack

| Scenario | Use instead |
|---|---|
| SEO-critical public site (marketing, e-commerce, blog) | Next.js |
| Full-stack with SSR needed | React Router v7 (framework mode) |
| Type-safety obsessed + TanStack Query heavy | TanStack Start (when stable) |
| Simple static site | Astro |
| Mobile app | React Native + Expo |

The Bulletproof React + Vite stack is ideal for dashboards, internal tools, admin panels, CRMs, automation UIs, and any app behind authentication where SEO is not a priority.

---

## CSS / Theming Rules

1. Define all colors as CSS variables in a theme file
2. Use `bg-[var(--color-name)]` syntax in Tailwind, never hardcoded like `bg-gray-800`
3. Support dark mode via `[data-theme="dark"]` CSS variable overrides
4. Use shadcn/ui components as the base — customize via CSS variables

```css
/* styles/theme.css */
:root {
  --color-bg-primary: #ffffff;
  --color-bg-secondary: #f3f4f6;
  --color-bg-card: #ffffff;
  --color-text-primary: #111827;
  --color-text-secondary: #6b7280;
  --color-accent: #3b82f6;
  --color-accent-hover: #2563eb;
  --color-border: #e5e7eb;
  --color-success: #10b981;
  --color-warning: #f59e0b;
  --color-error: #ef4444;
}

[data-theme="dark"] {
  --color-bg-primary: #0f172a;
  --color-bg-secondary: #1e293b;
  --color-bg-card: #1e293b;
  --color-text-primary: #f8fafc;
  --color-text-secondary: #94a3b8;
  --color-accent: #60a5fa;
  --color-accent-hover: #3b82f6;
  --color-border: #334155;
}
```

---

## Error Handling Standard

Every app must implement:

1. **Global error boundary** at the app level
2. **Feature-level error boundaries** for each major section
3. **TanStack Query error handling** via `onError` callbacks
4. **User-facing error messages** — never show raw errors to users
5. **Logging** at every data boundary (API call, DB query, external service)
6. **Loading states** for every async operation
7. **Empty states** when no data exists
8. **Fallback arrays** for nullable query results (`|| []`)

See `errors/common-errors-and-lessons.md` for specific patterns and examples.
