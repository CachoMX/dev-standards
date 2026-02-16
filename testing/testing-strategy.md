# Testing Strategy

## Philosophy

Test what matters, not everything. Focus on code that handles money, data, or user trust. A small number of good tests beats 100% coverage with shallow tests.

---

## Testing Pyramid

```
        ┌─────────┐
        │   E2E   │  Few — critical user journeys only
        ├─────────┤
        │ Integr. │  Some — API calls, data flows, multi-component
        ├─────────┤
        │  Unit   │  Many — utils, hooks, business logic
        └─────────┘
```

### What to Test at Each Level

**Unit Tests (Vitest)**
- Utility functions (formatCurrency, parseDate, calculateMER)
- Zod schemas (valid input passes, invalid input fails)
- Custom hooks (data transformations, state logic)
- Pure business logic (lead scoring, deal calculations)

**Integration Tests (Vitest + React Testing Library)**
- Form submission flow (fill → validate → submit → success/error)
- Data fetching components (loading → data → render correctly)
- Filter/search interactions (apply filter → list updates)
- Auth flow (login → redirect → show protected content)

**E2E Tests (Playwright)**
- Only critical paths: login, create lead, complete deal, generate report
- Maximum 10-15 E2E tests per project
- Run in CI but not blocking (can be slow)

---

## Minimum Test Requirements

### Every project MUST have

1. **Env validation test** — verify app crashes on missing env vars
2. **Schema validation tests** — for every Zod schema used in forms or API
3. **Utility function tests** — for every function in `utils/`
4. **Error boundary test** — verify errors are caught, not white screen

### Features that MUST have tests

- Anything involving money (calculations, display, transactions)
- Anything involving data mutations (create, update, delete)
- Anything involving permissions/auth logic
- Complex business logic (scoring, filtering, reporting)

### Features that DON'T need tests

- Static UI components with no logic
- Simple wrappers around third-party components
- One-off scripts or migrations
- Prototype/demo features

---

## Test Structure

### File Location

Tests live next to the code they test:

```
src/
  features/
    leads/
      components/
        lead-table.tsx
        lead-table.test.tsx        ← component test
      hooks/
        use-leads.ts
        use-leads.test.ts          ← hook test
      utils/
        lead-scoring.ts
        lead-scoring.test.ts       ← unit test
  utils/
    format-currency.ts
    format-currency.test.ts        ← unit test
```

### Test File Pattern

```typescript
import { describe, it, expect, vi } from 'vitest';

describe('featureName', () => {
  describe('functionOrComponent', () => {
    it('should handle the happy path', () => {
      // Arrange
      const input = { ... };

      // Act
      const result = myFunction(input);

      // Assert
      expect(result).toEqual(expected);
    });

    it('should handle edge case: empty input', () => {
      expect(myFunction([])).toEqual([]);
    });

    it('should handle edge case: null values', () => {
      expect(myFunction(null)).toEqual(defaultValue);
    });

    it('should throw on invalid input', () => {
      expect(() => myFunction('garbage')).toThrow();
    });
  });
});
```

### Naming Conventions

```typescript
// Good — describes behavior
it('should calculate MER as revenue divided by total ad spend')
it('should return empty array when no leads match filter')
it('should show error toast when API call fails')
it('should redirect to login when session expires')

// Bad — describes implementation
it('should call the function')
it('should work')
it('test 1')
it('should set state to true')
```

---

## Testing Patterns

### Mocking API Calls

```typescript
import { vi } from 'vitest';
import { supabase } from '@/lib/supabase';

// Mock the module
vi.mock('@/lib/supabase', () => ({
  supabase: {
    from: vi.fn(() => ({
      select: vi.fn(() => ({
        eq: vi.fn(() => ({
          data: mockLeads,
          error: null,
        })),
      })),
    })),
  },
}));

// Or use MSW for more realistic API mocking
import { setupServer } from 'msw/node';
import { http, HttpResponse } from 'msw';

const server = setupServer(
  http.get('/api/leads', () => {
    return HttpResponse.json({ data: mockLeads });
  }),
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

### Testing Hooks

```typescript
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

function createWrapper() {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  return ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  );
}

it('should fetch and return leads', async () => {
  const { result } = renderHook(() => useLeads(), {
    wrapper: createWrapper(),
  });

  await waitFor(() => expect(result.current.isSuccess).toBe(true));
  expect(result.current.data).toHaveLength(3);
});
```

### Testing Components

```typescript
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

it('should submit lead form with valid data', async () => {
  const onSubmit = vi.fn();
  render(<LeadForm onSubmit={onSubmit} />);

  await userEvent.type(screen.getByLabelText('Name'), 'John Doe');
  await userEvent.type(screen.getByLabelText('Email'), 'john@example.com');
  await userEvent.click(screen.getByRole('button', { name: /submit/i }));

  await waitFor(() => {
    expect(onSubmit).toHaveBeenCalledWith({
      name: 'John Doe',
      email: 'john@example.com',
    });
  });
});

it('should show validation error for invalid email', async () => {
  render(<LeadForm onSubmit={vi.fn()} />);

  await userEvent.type(screen.getByLabelText('Email'), 'not-an-email');
  await userEvent.click(screen.getByRole('button', { name: /submit/i }));

  expect(screen.getByText(/invalid email/i)).toBeInTheDocument();
});
```

### Testing Error States

```typescript
it('should show error message when API fails', async () => {
  // Override handler to return error
  server.use(
    http.get('/api/leads', () => {
      return HttpResponse.json(
        { error: 'Internal Server Error' },
        { status: 500 },
      );
    }),
  );

  render(<LeadsList />);

  await waitFor(() => {
    expect(screen.getByText(/failed to load leads/i)).toBeInTheDocument();
  });
  expect(screen.queryByRole('table')).not.toBeInTheDocument();
});
```

---

## Vitest Configuration

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    include: ['src/**/*.test.{ts,tsx}'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html'],
      include: ['src/**/*.{ts,tsx}'],
      exclude: [
        'src/**/*.test.{ts,tsx}',
        'src/**/*.d.ts',
        'src/test/**',
        'src/types/**',
      ],
    },
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
```

```typescript
// src/test/setup.ts
import '@testing-library/jest-dom/vitest';

// Global test utilities
beforeEach(() => {
  vi.clearAllMocks();
});
```

---

## Running Tests

```bash
# Run all tests once
npm run test -- --run

# Run tests in watch mode (during development)
npm run test

# Run specific test file
npm run test -- lead-scoring

# Run with coverage
npm run test -- --run --coverage

# Run E2E tests
npm run test:e2e
```
