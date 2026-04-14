# Bulletproof React — Refactor Existing Project Prompt

Use this prompt when you have an EXISTING React project and want to migrate it to Bulletproof React architecture.

---

```
You are Claude Code acting as a senior React/TypeScript architect specializing in codebase refactoring and migration.

## Goal
Analyze my existing React project and refactor it to STRICTLY follow the "Bulletproof React" architecture (alan2207/bulletproof-react). Migrate all existing code to the new structure without breaking functionality.

## MANDATORY: Read Before Refactoring

- `architecture/refactor-playbook.md` (required process and release gates)

### TypeScript Strict Rules (ZERO tolerance)
- Zero `any` types — use `unknown` + type guards or Zod
- Zero `@ts-ignore` or `@ts-expect-error`
- Zero non-null assertions (`!`) — use `?.` and `??`
- All function parameters and return types explicit
- Remove all unused imports and variables

### Architecture Rules
- No cross-feature imports
- Business logic in features/, not in pages
- CSS variables, no hardcoded colors
- Explicit error handling everywhere

---

## 🔍 PHASE 1: ANALYSIS (Do this first, show me the results)

Before making ANY changes, analyze the entire codebase and provide:

### 1. Current Structure Report
- Map out the current folder structure
- List all existing components and where they live
- List all existing hooks, utils, types, stores
- Identify current routing setup
- Identify state management approach
- List all external dependencies

### 2. Feature Identification
- Identify logical "features" in the current codebase
- Group related components/hooks/types that should become a feature module
- List shared/reusable components that should go in `src/components`
- List shared hooks that should go in `src/hooks`

### 3. Migration Plan
Create a step-by-step plan with:
- Files to move (from → to)
- Imports to update
- New files to create (index.ts exports, providers, etc.)
- Dependencies to add/update

**Wait for my approval before proceeding to Phase 2.**

---

## 🔨 PHASE 2: MIGRATION (After approval)

### Step 1: Setup Target Structure
Create the full Bulletproof React folder structure:

```
src/
├── app/
│   ├── routes/
│   ├── provider.tsx
│   └── router.tsx
├── components/
│   ├── ui/
│   ├── layouts/
│   └── shared/
├── config/
│   └── env.ts
├── features/
│   └── [identified-features]/
│       ├── api/
│       ├── components/
│       ├── hooks/
│       ├── stores/
│       ├── types/
│       ├── utils/
│       └── index.ts
├── hooks/
├── lib/
├── stores/
├── styles/
├── types/
└── utils/
```

### Step 2: Migrate Feature Modules
For each identified feature:
1. Create the feature folder with all subfolders
2. Move related components into `features/[name]/components/`
3. Move related hooks into `features/[name]/hooks/`
4. Move related types into `features/[name]/types/`
5. Move related API calls into `features/[name]/api/`
6. Create `index.ts` with public exports
7. Update all imports to use new paths

### Step 3: Migrate Shared Code
1. Move truly shared components to `src/components/`
2. Move truly shared hooks to `src/hooks/`
3. Move truly shared types to `src/types/`
4. Move truly shared utils to `src/utils/`

### Step 4: Setup App Layer
1. Create/migrate `provider.tsx` with all global providers
2. Create/migrate `router.tsx` with route configuration
3. Update `app.tsx` as main app component
4. Organize routes in `app/routes/`

### Step 5: Update Configuration
1. Add path aliases to `tsconfig.json`
2. Update `vite.config.ts` for aliases
3. Add ESLint boundary rules
4. Update any existing ESLint/Prettier configs

### Step 6: Fix All Imports
1. Update all imports to use `@/` path aliases
2. Ensure no cross-feature imports exist
3. Verify unidirectional dependency flow

### Step 7: TypeScript Cleanup
1. Replace all `any` with proper types
2. Remove all `@ts-ignore` / `@ts-expect-error`
3. Replace all `!` with `?.` and `??`
4. Add explicit types to all function parameters and returns
5. Remove unused imports and variables

### Step 8: Styling Cleanup
1. Replace hardcoded colors with CSS variables
2. Create theme.css if it doesn't exist
3. Ensure all colors reference CSS variables

---

## ✅ PHASE 3: VERIFICATION

After migration, verify:

1. **Build Check**
   ```bash
   npm run build
   ```
   Must complete without errors

2. **Lint Check**
   ```bash
   npm run lint
   ```
   Must pass with no errors

3. **Type Check**
   ```bash
   npm run type-check
   ```
   Must pass with no errors

4. **Dev Server**
   ```bash
   npm run dev
   ```
   App must run and all features work

5. **Import Boundary Check**
   - No cross-feature imports
   - No features importing from app
   - No shared modules importing from features

6. **TypeScript Audit**
   - Zero `any` types
   - Zero `@ts-ignore`
   - Zero non-null assertions
   - All functions typed

---

## 📋 MIGRATION RULES

### What Goes Where

| Code Type | Location | Rule |
|---|---|---|
| Feature-specific component | `src/features/[name]/components/` | Only used within that feature |
| Shared UI component | `src/components/ui/` | Used by 2+ features |
| Layout component | `src/components/layouts/` | Page wrappers, navigation |
| Feature-specific hook | `src/features/[name]/hooks/` | Only used within that feature |
| Shared hook | `src/hooks/` | Used by 2+ features |
| Feature-specific types | `src/features/[name]/types/` | Types for that feature's data |
| Shared types | `src/types/` | Used across multiple features |
| API calls for feature | `src/features/[name]/api/` | Endpoints for that feature |
| Feature state | `src/features/[name]/stores/` | UI state for that feature |
| Global state | `src/stores/` | App-wide state (auth, theme, etc.) |
| Library config | `src/lib/` | Supabase, axios, queryClient setup |
| Environment config | `src/config/` | Env vars, app constants |
| Utility functions | `src/utils/` or `src/features/[name]/utils/` | Depends on scope |
```

---

## Usage

1. `cd` into your existing project directory
2. Copy this prompt into Claude Code
3. Claude will analyze, plan, and migrate with your approval at each phase
