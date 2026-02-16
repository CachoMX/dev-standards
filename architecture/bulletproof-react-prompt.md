# Bulletproof React — New Project Prompt for Claude Code

Copy and paste this prompt into Claude Code when starting a new React application.

---

```
You are a senior React/TypeScript architect. When creating this application, STRICTLY follow the "Bulletproof React" architecture (https://github.com/alan2207/bulletproof-react).

## MANDATORY: Read Before Coding

Before writing ANY code, you MUST follow these rules from our error prevention guide:

### TypeScript Strict Rules (ZERO tolerance)
- Zero `any` types — use `unknown` + type guards or Zod schemas
- Zero `@ts-ignore` or `@ts-expect-error` — fix the actual type error
- Zero non-null assertions (`!`) — use optional chaining (`?.`) and nullish coalescing (`??`)
- All function parameters and return types must be explicit
- Remove all unused imports and variables

### Architecture Rules
- Business logic goes in `features/[feature]/api/`, NEVER in pages/routes
- Features CANNOT import from other features (no cross-feature imports)
- Shared code goes in `components/`, `hooks/`, `lib/`, `types/`, `utils/`
- Compose features only at the `app/` layer
- Use CSS variables for all colors (never hardcoded like `bg-gray-800`)

### Error Handling Rules
- Never swallow errors silently — always log and handle them
- Always provide fallback arrays for nullable query results (`|| []`)
- Add user-facing error messages for all operations
- Implement loading, empty, and error states for every async operation
- Test end-to-end: Frontend → API → Database → UI

## Tech Stack (DO NOT CHANGE)

- **Build:** Vite
- **Framework:** React 19+
- **Language:** TypeScript (strict mode)
- **Architecture:** Bulletproof React (feature-based)
- **Server State:** TanStack Query v5 (React Query)
- **Client State:** Zustand
- **Validation:** Zod
- **UI Components:** shadcn/ui
- **Styling:** Tailwind CSS + CSS Variables (theme-based)
- **Icons:** Lucide React
- **Routing:** React Router v7 (library mode)
- **Testing:** Vitest + React Testing Library

## Project Structure

Generate this EXACT folder structure:

```
src/
├── app/
│   ├── routes/           # Route definitions
│   ├── provider.tsx      # All global providers wrapped
│   └── router.tsx        # Router configuration with lazy loading
├── components/
│   ├── ui/               # shadcn/ui base components
│   ├── layouts/          # Page layouts (sidebar, header, etc.)
│   └── shared/           # Reusable composed components (data-table, charts, etc.)
├── config/
│   └── env.ts            # Environment variables validated with Zod
├── features/
│   └── [feature-name]/
│       ├── api/          # TanStack Query hooks + API calls
│       ├── components/   # Feature-scoped components
│       ├── hooks/        # Feature-scoped hooks
│       ├── stores/       # Feature-scoped Zustand stores
│       ├── types/        # Feature-scoped TypeScript types
│       ├── utils/        # Feature-scoped utilities
│       └── index.ts      # Public API — ONLY export what other layers need
├── hooks/                # Shared custom hooks
├── lib/                  # Pre-configured libraries (supabase, axios, queryClient)
├── stores/               # Global Zustand stores (auth, theme, sidebar)
├── styles/
│   ├── globals.css       # Tailwind directives + theme import
│   └── theme.css         # CSS variables for all colors
├── types/                # Shared TypeScript types and interfaces
└── utils/                # Shared utility functions
```

## Feature Module Structure

Each feature must follow this internal structure:

```
src/features/[feature-name]/
├── api/
│   ├── use-[resource].ts         # TanStack Query hook (useQuery)
│   ├── use-create-[resource].ts  # TanStack Mutation hook (useMutation)
│   ├── use-update-[resource].ts  # TanStack Mutation hook
│   ├── use-delete-[resource].ts  # TanStack Mutation hook
│   └── [resource]-api.ts         # Raw API functions (fetch/axios calls)
├── components/
│   ├── [resource]-list.tsx       # List view
│   ├── [resource]-card.tsx       # Card/row component
│   ├── [resource]-form.tsx       # Create/edit form
│   └── [resource]-detail.tsx     # Detail view
├── hooks/
│   └── use-[feature]-logic.ts    # Feature-specific custom hooks
├── stores/
│   └── [feature]-store.ts        # Zustand store for UI state
├── types/
│   └── index.ts                  # Feature types and interfaces
├── utils/
│   └── [feature]-utils.ts        # Feature utility functions
└── index.ts                      # Public exports ONLY
```

## Import Rules (CRITICAL — ENFORCE WITH ESLINT)

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

## Path Aliases

Configure in both `tsconfig.json` and `vite.config.ts`:

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

## Configuration Files to Generate

### vite.config.ts
- Path alias for `@/`
- React plugin
- Vitest config

### tsconfig.json
- Strict mode enabled
- `noImplicitAny: true`
- `noImplicitReturns: true`
- `noUnusedLocals: true`
- `noUnusedParameters: true`
- `noUncheckedIndexedAccess: true`
- Path aliases

### .eslintrc.cjs
- TypeScript ESLint plugin
- `@typescript-eslint/no-explicit-any: "error"`
- Import boundary rules (no cross-feature imports)
- React hooks rules

### prettier.config.js
- Single quotes
- Semicolons
- 2-space indent
- Print width 100
- Tailwind plugin

### .env.example
- All required environment variables with placeholder values

## Environment Variable Validation

```typescript
// src/config/env.ts
import { z } from 'zod';

const envSchema = z.object({
  VITE_SUPABASE_URL: z.string().url(),
  VITE_SUPABASE_ANON_KEY: z.string().min(1),
  VITE_APP_NAME: z.string().default('My App'),
});

export const env = envSchema.parse(import.meta.env);
```

## Verification Checklist

After generating the project, ensure:

1. `npm install` — completes without errors
2. `npm run dev` — starts dev server
3. `npm run build` — builds without errors
4. `npm run lint` — passes with zero errors
5. `npm run type-check` — passes with zero errors
6. No `any` types in codebase
7. No `@ts-ignore` or `@ts-expect-error` in codebase
8. No cross-feature imports
9. All colors use CSS variables
10. All async operations have loading/error/empty states

## 🎯 PROJECT DESCRIPTION (FILL IN BELOW)

**App Name:** [name]

**Description:**
[what the app does]

**Features to implement:**
1. [feature-name] — [description]
2. [feature-name] — [description]

**Pages/Routes needed:**
- `/` — [description]
- `/[route]` — [description]

**Database/Backend:**
- [Supabase / custom API / etc.]

**Additional requirements:**
- [any special requirements]
```

---

## Usage

1. Copy the prompt above
2. Fill in the PROJECT DESCRIPTION section at the bottom
3. Paste into Claude Code terminal
4. Claude Code will generate the complete project following all standards
