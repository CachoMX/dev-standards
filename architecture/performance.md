# Performance Optimization

**Last updated:** February 2026

## Overview

Performance is a feature, not an afterthought. Every 100ms delay can reduce conversions by 7%. This document defines performance budgets, optimization strategies, and monitoring requirements for all projects.

**Key Metrics:**
- First Contentful Paint (FCP) < 1.5s
- Largest Contentful Paint (LCP) < 2.5s
- Interaction to Next Paint (INP) < 200ms
- Cumulative Layout Shift (CLS) < 0.1
- Time to Interactive (TTI) < 3.5s

---

## Performance Budgets

Performance budgets are hard limits that prevent regressions. CI should fail if budgets are exceeded.

### Bundle Size Budgets

| Asset Type | Target | Maximum | Notes |
|---|---|---|---|
| **Initial JS** | < 150KB | 200KB | Compressed (gzip/brotli) |
| **Total JS** | < 400KB | 500KB | All chunks combined |
| **CSS** | < 20KB | 30KB | Critical + async |
| **Images (per page)** | < 300KB | 500KB | Optimized formats |
| **Total Page Weight** | < 500KB | 800KB | First load |

### Core Web Vitals Targets

Based on 75th percentile of real user data:

| Metric | Good | Needs Improvement | Poor |
|---|---|---|---|
| **LCP** (Largest Contentful Paint) | < 2.5s | 2.5s - 4s | > 4s |
| **INP** (Interaction to Next Paint) | < 200ms | 200ms - 500ms | > 500ms |
| **CLS** (Cumulative Layout Shift) | < 0.1 | 0.1 - 0.25 | > 0.25 |

**Target:** All metrics in "Good" range on 3G mobile (simulated).

### Time-Based Budgets

| Metric | Target | Maximum |
|---|---|---|
| **FCP** (First Contentful Paint) | < 1.0s | 1.5s |
| **TTI** (Time to Interactive) | < 2.5s | 3.5s |
| **Speed Index** | < 2.0s | 3.0s |
| **API Response Time** | < 300ms | 500ms |

---

## Enforcing Budgets

### 1. Webpack/Vite Performance Hints

```ts
// vite.config.ts
export default defineConfig({
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          router: ['react-router-dom'],
          query: ['@tanstack/react-query'],
        },
      },
    },
    chunkSizeWarningLimit: 200, // KB (will warn, not fail)
  },
});
```

### 2. bundlesize Package

```bash
npm install --save-dev bundlesize
```

```json
// package.json
{
  "scripts": {
    "test:size": "bundlesize"
  },
  "bundlesize": [
    {
      "path": "./dist/assets/index-*.js",
      "maxSize": "200 KB",
      "compression": "gzip"
    },
    {
      "path": "./dist/assets/*.css",
      "maxSize": "30 KB",
      "compression": "gzip"
    }
  ]
}
```

### 3. GitHub Actions Integration

```yaml
# .github/workflows/ci.yml
- name: Check bundle size
  run: npm run test:size
```

### 4. Lighthouse CI

```bash
npm install --save-dev @lhci/cli
```

```js
// lighthouserc.js
module.exports = {
  ci: {
    collect: {
      startServerCommand: 'npm run preview',
      url: ['http://localhost:4173'],
    },
    assert: {
      preset: 'lighthouse:recommended',
      assertions: {
        'categories:performance': ['error', { minScore: 0.9 }],
        'first-contentful-paint': ['error', { maxNumericValue: 1500 }],
        'interactive': ['error', { maxNumericValue: 3500 }],
        'total-byte-weight': ['error', { maxNumericValue: 500000 }],
      },
    },
  },
};
```

---

## Code Splitting & Lazy Loading

**Impact:** Reduces initial bundle by 40-60%, improves FCP and TTI by 1-2 seconds.

### Rule: Start with Route-Based Splitting

This is the **highest ROI optimization** (15 minutes of work, massive impact).

```tsx
// src/app/router.tsx
import { lazy, Suspense } from 'react';
import { createBrowserRouter } from 'react-router-dom';

// Lazy load route components
const Dashboard = lazy(() => import('@/features/dashboard'));
const Leads = lazy(() => import('@/features/leads'));
const Settings = lazy(() => import('@/features/settings'));

export const router = createBrowserRouter([
  {
    path: '/',
    element: (
      <Suspense fallback={<LoadingSpinner />}>
        <Dashboard />
      </Suspense>
    ),
  },
  {
    path: '/leads',
    element: (
      <Suspense fallback={<LoadingSpinner />}>
        <Leads />
      </Suspense>
    ),
  },
  {
    path: '/settings',
    element: (
      <Suspense fallback={<LoadingSpinner />}>
        <Settings />
      </Suspense>
    ),
  },
]);
```

### Component-Level Splitting

Split **large, conditional components** that aren't always needed:

```tsx
// Good candidates for splitting:
// - Modals/dialogs (only load when opened)
// - Charts/graphs (heavy libraries like recharts, chart.js)
// - Rich text editors (TipTap, Quill)
// - PDF viewers
// - Code editors (Monaco, CodeMirror)

// Example: Heavy chart component
const RevenueChart = lazy(() => import('./revenue-chart'));

export function Dashboard() {
  const [showChart, setShowChart] = useState(false);

  return (
    <div>
      <button onClick={() => setShowChart(true)}>Show Revenue Chart</button>
      {showChart && (
        <Suspense fallback={<ChartSkeleton />}>
          <RevenueChart />
        </Suspense>
      )}
    </div>
  );
}
```

### What NOT to Split

- ❌ Small components (< 10KB)
- ❌ Critical UI (header, navigation, main content)
- ❌ Components needed immediately on page load

### Meaningful Loading States

**Bad:** Generic spinner (causes layout shift)

```tsx
// ❌ WRONG
<Suspense fallback={<Spinner />}>
  <DataTable />
</Suspense>
```

**Good:** Skeleton that matches content structure (prevents CLS)

```tsx
// ✅ CORRECT
<Suspense fallback={<TableSkeleton rows={10} columns={5} />}>
  <DataTable />
</Suspense>
```

### Preloading Components

For critical lazy components, preload them before they're needed:

```tsx
// Preload on hover (for likely navigation)
import { preloadRoute } from './router';

<Link
  to="/settings"
  onMouseEnter={() => preloadRoute('/settings')}
>
  Settings
</Link>
```

---

## Image Optimization

**Impact:** Images are 50-70% of page weight. Optimization can save 300-500KB per page.

### Image Format Guidelines

| Format | When to Use | Compression |
|---|---|---|
| **WebP** | Modern browsers (95%+ support) | Best quality/size ratio |
| **AVIF** | Cutting-edge (smaller than WebP) | Even better, but less support |
| **JPEG** | Fallback for photos | Good for photos |
| **PNG** | Transparency needed | Large file size |
| **SVG** | Icons, logos, illustrations | Infinitely scalable |

### Implementation Pattern

```tsx
// Use next/image or similar for automatic optimization
import Image from 'next/image';

<Image
  src="/hero.jpg"
  alt="Hero image"
  width={1200}
  height={600}
  loading="lazy"
  placeholder="blur"
  blurDataURL="data:image/jpeg;base64,..."
/>

// Or manual with <picture> for fallbacks
<picture>
  <source srcSet="/hero.avif" type="image/avif" />
  <source srcSet="/hero.webp" type="image/webp" />
  <img src="/hero.jpg" alt="Hero image" loading="lazy" />
</picture>
```

### Image Checklist

- [ ] Use WebP/AVIF for all images
- [ ] Lazy load images below the fold
- [ ] Use responsive images (srcset for different sizes)
- [ ] Compress images (TinyPNG, Squoosh)
- [ ] Set explicit width/height (prevents CLS)
- [ ] Use CDN for image delivery

### Tools

- **Squoosh** (https://squoosh.app/) — Image compression
- **Sharp** (npm) — Server-side image processing
- **vite-plugin-image-optimizer** — Automatic optimization in build

---

## React Performance Patterns

### 1. Memoization (Use Sparingly)

**Only use when profiling shows a problem.** Premature optimization adds complexity.

```tsx
// When to use React.memo:
// - Component renders often with same props
// - Component is expensive to render (complex calculations, large lists)

const ExpensiveList = React.memo(({ items }: { items: Item[] }) => {
  return (
    <ul>
      {items.map(item => <li key={item.id}>{item.name}</li>)}
    </ul>
  );
});

// When to use useMemo:
// - Expensive calculations that depend on props/state
function DataTable({ data }: { data: Item[] }) {
  // Only recalculate when data changes
  const sortedData = useMemo(() => {
    return [...data].sort((a, b) => a.name.localeCompare(b.name));
  }, [data]);

  return <Table data={sortedData} />;
}

// When to use useCallback:
// - Passing callbacks to memoized child components
function Parent() {
  const [count, setCount] = useState(0);

  const handleClick = useCallback(() => {
    console.log('Clicked');
  }, []); // Stable reference

  return <MemoizedChild onClick={handleClick} />;
}
```

### 2. Virtual Scrolling (Large Lists)

For lists with 100+ items, use virtualization:

```tsx
import { useVirtualizer } from '@tanstack/react-virtual';

function VirtualList({ items }: { items: Item[] }) {
  const parentRef = useRef<HTMLDivElement>(null);

  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 50, // Estimated row height
  });

  return (
    <div ref={parentRef} style={{ height: '400px', overflow: 'auto' }}>
      <div
        style={{
          height: `${virtualizer.getTotalSize()}px`,
          position: 'relative',
        }}
      >
        {virtualizer.getVirtualItems().map((virtualRow) => (
          <div
            key={virtualRow.index}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              transform: `translateY(${virtualRow.start}px)`,
            }}
          >
            {items[virtualRow.index].name}
          </div>
        ))}
      </div>
    </div>
  );
}
```

### 3. Debouncing/Throttling

For search inputs and event handlers:

```tsx
import { useDebouncedValue } from '@/hooks/use-debounced-value';

function SearchInput() {
  const [search, setSearch] = useState('');
  const debouncedSearch = useDebouncedValue(search, 300); // 300ms delay

  // Only triggers when user stops typing for 300ms
  const { data } = useQuery({
    queryKey: ['search', debouncedSearch],
    queryFn: () => searchAPI(debouncedSearch),
    enabled: debouncedSearch.length > 0,
  });

  return <input value={search} onChange={(e) => setSearch(e.target.value)} />;
}

// src/hooks/use-debounced-value.ts
import { useEffect, useState } from 'react';

export function useDebouncedValue<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState(value);

  useEffect(() => {
    const handler = setTimeout(() => setDebouncedValue(value), delay);
    return () => clearTimeout(handler);
  }, [value, delay]);

  return debouncedValue;
}
```

### 4. Avoid Re-Renders

```tsx
// ❌ WRONG - Creates new object on every render
function Parent() {
  return <Child config={{ theme: 'dark' }} />; // New object reference
}

// ✅ CORRECT - Stable reference
const CONFIG = { theme: 'dark' };
function Parent() {
  return <Child config={CONFIG} />;
}

// ❌ WRONG - Inline function creates new reference
<Child onClick={() => console.log('clicked')} />

// ✅ CORRECT - useCallback for stable reference
const handleClick = useCallback(() => console.log('clicked'), []);
<MemoizedChild onClick={handleClick} />
```

### 5. Dashboard pages with heavy charts (Recharts, D3, etc.)

Report and analytics routes often mark the **entire page** as `'use client'`, which ships a large JS payload and hurts INP/LCP.

- Keep **Server Components** as the default shell: fetch aggregates on the server, pass serializable props into small **leaf** chart components that are the only `'use client'` boundaries.
- Memoize expensive transforms (`useMemo`) and consider **virtualization** for large tables paired with charts.
- On Next.js 15+, evaluate **Cache Components** / `cacheTag` / `revalidateTag` for read-mostly report data instead of refetching everything on every navigation.

---

## TanStack Query Optimization

### Stale Time & Cache Time

```tsx
// Global defaults
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes - data considered fresh
      gcTime: 1000 * 60 * 10,   // 10 minutes - cache garbage collection
      refetchOnWindowFocus: false,
      retry: 1,
    },
  },
});

// Per-query overrides
function useLeads() {
  return useQuery({
    queryKey: ['leads'],
    queryFn: fetchLeads,
    staleTime: 1000 * 60 * 1, // 1 minute - frequently changing data
  });
}
```

### Prefetching

Prefetch data before it's needed:

```tsx
function Dashboard() {
  const queryClient = useQueryClient();

  // Prefetch on hover
  const handleMouseEnter = () => {
    queryClient.prefetchQuery({
      queryKey: ['leads'],
      queryFn: fetchLeads,
    });
  };

  return (
    <Link to="/leads" onMouseEnter={handleMouseEnter}>
      View Leads
    </Link>
  );
}
```

### Pagination with keepPreviousData

Prevents loading spinner when changing pages:

```tsx
function useLeadsPaginated(page: number) {
  return useQuery({
    queryKey: ['leads', { page }],
    queryFn: () => fetchLeads(page),
    placeholderData: keepPreviousData, // Show previous data while fetching
  });
}
```

---

## Bundle Analysis

### Analyze Your Bundle

```bash
# Install bundle analyzer
npm install --save-dev rollup-plugin-visualizer

# Add to vite.config.ts
import { visualizer } from 'rollup-plugin-visualizer';

export default defineConfig({
  plugins: [
    visualizer({
      open: true,
      gzipSize: true,
      brotliSize: true,
    }),
  ],
});

# Build and open visualization
npm run build
```

### Common Large Dependencies to Watch

| Package | Size (gzip) | Alternative |
|---|---|---|
| moment.js | 71KB | date-fns (6KB), dayjs (7KB) |
| lodash | 69KB | lodash-es + tree-shaking, or native JS |
| chart.js | 60KB | recharts (smaller), or lazy load |
| material-ui | 200KB+ | shadcn/ui (zero bundle size) |

### Tree-Shaking

Import only what you need:

```tsx
// ❌ WRONG - Imports entire library
import _ from 'lodash';
_.debounce(fn, 300);

// ✅ CORRECT - Imports only debounce
import debounce from 'lodash-es/debounce';
debounce(fn, 300);

// ✅ EVEN BETTER - Use native or smaller library
import { debounce } from '@/utils/debounce'; // Custom implementation
```

---

## Monitoring & Measurement

### 1. Lighthouse CI (Automated)

Run Lighthouse on every PR:

```yaml
# .github/workflows/ci.yml
- name: Run Lighthouse CI
  run: |
    npm install -g @lhci/cli
    lhci autorun
```

### 2. Real User Monitoring (RUM)

Track actual user performance:

```tsx
// src/lib/performance.ts
import { onCLS, onFCP, onINP, onLCP, onTTFB } from 'web-vitals';

function sendToAnalytics(metric: Metric) {
  // Send to your analytics service
  console.log(metric);
  // Example: Google Analytics, Vercel Analytics, etc.
}

// Initialize in app entry
onCLS(sendToAnalytics);
onFCP(sendToAnalytics);
onINP(sendToAnalytics);
onLCP(sendToAnalytics);
onTTFB(sendToAnalytics);
```

### 3. Vercel Analytics

```bash
npm install @vercel/analytics
```

```tsx
// src/app/provider.tsx
import { Analytics } from '@vercel/analytics/react';

export function Providers({ children }: { children: ReactNode }) {
  return (
    <>
      {children}
      <Analytics />
    </>
  );
}
```

### 4. Performance Budget Dashboard

Track metrics over time:

- **Lighthouse CI** → Store results in database
- **Bundle size** → Track with bundlesize + GitHub Actions
- **Core Web Vitals** → Vercel Analytics or Google Search Console

---

## Performance Checklist

Before every production deploy:

### Bundle Size
- [ ] Initial JS bundle < 200KB (gzip)
- [ ] Total JS < 500KB (gzip)
- [ ] CSS < 30KB (gzip)
- [ ] Run `npm run test:size` — passes

### Core Web Vitals (on 3G mobile)
- [ ] LCP < 2.5s
- [ ] INP < 200ms
- [ ] CLS < 0.1
- [ ] Lighthouse Performance score > 90

### Code Splitting
- [ ] Route-based code splitting implemented
- [ ] Heavy components (charts, editors) lazy loaded
- [ ] Meaningful loading skeletons (no layout shift)

### Images
- [ ] All images optimized (WebP/AVIF)
- [ ] Images below fold lazy loaded
- [ ] Explicit width/height set (prevents CLS)

### React Optimization
- [ ] No unnecessary re-renders (checked with React DevTools)
- [ ] Large lists use virtualization (if 100+ items)
- [ ] Search inputs debounced

### TanStack Query
- [ ] Appropriate staleTime/gcTime set
- [ ] Pagination uses keepPreviousData
- [ ] Prefetching for likely navigation

---

## Performance Priorities (80/20 Rule)

Focus on these **high-impact, low-effort** optimizations first:

### Tier 1: Do These First (80% of gains)
1. ✅ **Route-based code splitting** (15 min, huge impact)
2. ✅ **Image optimization** (30 min, 300-500KB saved)
3. ✅ **Lazy load heavy components** (charts, editors) (20 min)
4. ✅ **Set performance budgets + CI enforcement** (30 min, prevents regressions)

### Tier 2: Do If Profiling Shows Issues
5. React.memo/useMemo (only if re-renders are a problem)
6. Virtual scrolling (only for lists with 100+ items)
7. Prefetching (if you have slow API calls)

### Tier 3: Diminishing Returns
8. Micro-optimizations (rarely worth it)
9. Over-memoization (adds complexity, minimal gains)

---

## Resources

### Tools
- **Lighthouse** (Chrome DevTools) — Performance audit
- **Web Vitals** (npm) — Real user metrics
- **bundlesize** (npm) — Bundle size CI checks
- **Rollup Visualizer** — Bundle analysis

### Monitoring
- **Vercel Analytics** — RUM for Vercel deployments
- **Google Search Console** — Core Web Vitals for SEO
- **PageSpeed Insights** — Google's performance tool

### Learning
- [web.dev Performance](https://web.dev/performance/)
- [React Performance Docs](https://react.dev/learn/render-and-commit)
- [TanStack Query Performance](https://tanstack.com/query/latest/docs/framework/react/guides/performance)

---

## Last Updated

April 2026 — Added dashboard/chart bundle guidance (Server Components + leaf client charts). Originally February 2026 (Core Web Vitals).
