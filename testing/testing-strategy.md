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
- Keep full E2E suite non-blocking if needed, but maintain a small blocking smoke subset for release-critical flows

---

## Minimum Test Requirements

### Every project MUST have

1. **Env validation test** — verify app crashes on missing env vars
2. **Schema validation tests** — for every Zod schema used in forms or API
3. **Utility function tests** — for every function in `utils/`
4. **Error boundary test** — verify errors are caught, not white screen
5. **Auth-boundary smoke tests** — critical endpoints verified signed-out and signed-in

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

# Run E2E tests in headed mode (see browser)
npm run test:e2e -- --headed

# Run specific E2E test
npm run test:e2e -- login.spec.ts
```

---

## E2E Testing with Playwright

### Setup

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:5173',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:5173',
    reuseExistingServer: !process.env.CI,
  },
});
```

### E2E Test Examples

#### Critical User Flow: Login

```typescript
// e2e/auth/login.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Login Flow', () => {
  test('should login successfully with valid credentials', async ({ page }) => {
    await page.goto('/login');

    // Fill login form
    await page.getByLabel('Email').fill('user@example.com');
    await page.getByLabel('Password').fill('password123');
    await page.getByRole('button', { name: 'Sign In' }).click();

    // Wait for redirect to dashboard
    await expect(page).toHaveURL('/dashboard');

    // Verify user is logged in
    await expect(page.getByText('Welcome back')).toBeVisible();
  });

  test('should show error with invalid credentials', async ({ page }) => {
    await page.goto('/login');

    await page.getByLabel('Email').fill('wrong@example.com');
    await page.getByLabel('Password').fill('wrongpassword');
    await page.getByRole('button', { name: 'Sign In' }).click();

    // Should stay on login page
    await expect(page).toHaveURL('/login');

    // Show error message
    await expect(page.getByText(/invalid credentials/i)).toBeVisible();
  });

  test('should require email and password', async ({ page }) => {
    await page.goto('/login');

    await page.getByRole('button', { name: 'Sign In' }).click();

    // Show validation errors
    await expect(page.getByText(/email is required/i)).toBeVisible();
    await expect(page.getByText(/password is required/i)).toBeVisible();
  });

  test('should redirect to login when accessing protected route', async ({ page }) => {
    await page.goto('/dashboard');

    // Redirected to login
    await expect(page).toHaveURL(/\/login/);
  });
});
```

#### CRUD Operation: Create Lead

```typescript
// e2e/leads/create-lead.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Create Lead', () => {
  test.beforeEach(async ({ page }) => {
    // Login before each test
    await page.goto('/login');
    await page.getByLabel('Email').fill('user@example.com');
    await page.getByLabel('Password').fill('password123');
    await page.getByRole('button', { name: 'Sign In' }).click();
    await expect(page).toHaveURL('/dashboard');
  });

  test('should create new lead successfully', async ({ page }) => {
    await page.goto('/leads');

    // Click "New Lead" button
    await page.getByRole('button', { name: 'New Lead' }).click();

    // Fill form
    await page.getByLabel('Name').fill('John Doe');
    await page.getByLabel('Email').fill('john@example.com');
    await page.getByLabel('Phone').fill('+1234567890');
    await page.getByLabel('Source').selectOption('web');

    // Submit
    await page.getByRole('button', { name: 'Create Lead' }).click();

    // Wait for success message
    await expect(page.getByText(/lead created successfully/i)).toBeVisible();

    // Verify lead appears in table
    await expect(page.getByRole('cell', { name: 'John Doe' })).toBeVisible();
    await expect(page.getByRole('cell', { name: 'john@example.com' })).toBeVisible();
  });

  test('should show validation errors for invalid data', async ({ page }) => {
    await page.goto('/leads');
    await page.getByRole('button', { name: 'New Lead' }).click();

    // Try to submit with invalid email
    await page.getByLabel('Name').fill('John Doe');
    await page.getByLabel('Email').fill('not-an-email');
    await page.getByRole('button', { name: 'Create Lead' }).click();

    // Should show validation error
    await expect(page.getByText(/invalid email/i)).toBeVisible();
  });
});
```

#### Data Flow: Filter and Search

```typescript
// e2e/leads/filter-leads.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Filter Leads', () => {
  test.beforeEach(async ({ page }) => {
    // Login
    await page.goto('/login');
    await page.getByLabel('Email').fill('user@example.com');
    await page.getByLabel('Password').fill('password123');
    await page.getByRole('button', { name: 'Sign In' }).click();
    await page.goto('/leads');
  });

  test('should filter leads by status', async ({ page }) => {
    // Initial state - shows all leads
    const allRowsBefore = await page.getByRole('row').count();
    expect(allRowsBefore).toBeGreaterThan(1);

    // Apply filter
    await page.getByLabel('Status').selectOption('active');
    await page.getByRole('button', { name: 'Apply Filters' }).click();

    // Wait for table to update
    await page.waitForTimeout(500);

    // Verify only active leads shown
    const rows = page.getByRole('row');
    const activeStatusCells = rows.filter({ has: page.getByText('Active') });
    expect(await activeStatusCells.count()).toBeGreaterThan(0);
  });

  test('should search leads by name', async ({ page }) => {
    await page.getByPlaceholder('Search leads...').fill('John');
    await page.getByPlaceholder('Search leads...').press('Enter');

    // Wait for search results
    await page.waitForTimeout(500);

    // Verify results contain search term
    const firstRow = page.getByRole('row').nth(1);
    await expect(firstRow).toContainText('John');
  });

  test('should show empty state when no results', async ({ page }) => {
    await page.getByPlaceholder('Search leads...').fill('nonexistent-lead-xyz');
    await page.getByPlaceholder('Search leads...').press('Enter');

    await expect(page.getByText(/no leads found/i)).toBeVisible();
  });
});
```

#### API Integration: External Service

```typescript
// e2e/sync/hubspot-sync.spec.ts
import { test, expect } from '@playwright/test';

test.describe('HubSpot Sync', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login');
    await page.getByLabel('Email').fill('admin@example.com');
    await page.getByLabel('Password').fill('adminpass');
    await page.getByRole('button', { name: 'Sign In' }).click();
  });

  test('should trigger manual sync', async ({ page }) => {
    await page.goto('/settings/integrations');

    // Click sync button
    await page.getByRole('button', { name: 'Sync Now' }).click();

    // Show loading state
    await expect(page.getByText(/syncing.../i)).toBeVisible();

    // Wait for completion (max 30 seconds)
    await expect(page.getByText(/sync completed/i)).toBeVisible({ timeout: 30000 });

    // Verify sync stats updated
    const lastSyncElement = page.getByText(/last sync:/i);
    await expect(lastSyncElement).toBeVisible();
  });

  test('should show error if sync fails', async ({ page }) => {
    // Mock API failure (requires test API or MSW setup)
    await page.goto('/settings/integrations');

    // Trigger sync
    await page.getByRole('button', { name: 'Sync Now' }).click();

    // Should show error message (if API is down)
    // This test needs proper mocking or test environment
    // await expect(page.getByText(/sync failed/i)).toBeVisible();
  });
});
```

### E2E Test Helpers

```typescript
// e2e/helpers/auth.ts
import { Page } from '@playwright/test';

export async function login(page: Page, email: string, password: string) {
  await page.goto('/login');
  await page.getByLabel('Email').fill(email);
  await page.getByLabel('Password').fill(password);
  await page.getByRole('button', { name: 'Sign In' }).click();
  await page.waitForURL('/dashboard');
}

export async function logout(page: Page) {
  await page.getByRole('button', { name: 'User menu' }).click();
  await page.getByRole('menuitem', { name: 'Sign out' }).click();
  await page.waitForURL('/login');
}
```

```typescript
// e2e/helpers/data.ts
import { Page } from '@playwright/test';

export async function createTestLead(page: Page, data: {
  name: string;
  email: string;
  phone?: string;
}) {
  await page.goto('/leads');
  await page.getByRole('button', { name: 'New Lead' }).click();
  await page.getByLabel('Name').fill(data.name);
  await page.getByLabel('Email').fill(data.email);
  if (data.phone) await page.getByLabel('Phone').fill(data.phone);
  await page.getByRole('button', { name: 'Create Lead' }).click();
  await page.getByText(/lead created successfully/i).waitFor();
}

export async function cleanupTestData(page: Page, email: string) {
  // Delete test lead by email
  await page.goto('/leads');
  const row = page.getByRole('row').filter({ hasText: email });
  await row.getByRole('button', { name: 'Delete' }).click();
  await page.getByRole('button', { name: 'Confirm' }).click();
}
```

### E2E Test Best Practices

1. **Use data-testid sparingly** — prefer `getByRole`, `getByLabel`, `getByText`
2. **Clean up test data** — don't leave test records in database
3. **Use fixtures** for common setup (login, seed data)
4. **Test critical paths only** — max 10-15 E2E tests per project
5. **Include auth-boundary assertions** — verify signed-out failures (`401/403`) and signed-in success paths
6. **Run a blocking smoke subset in CI** for login + billing/integration core path
7. **Keep the full E2E suite non-blocking** if execution time/flakiness is high
8. **Use screenshots/videos** for debugging failures
9. **Mock external APIs** when possible to avoid rate limits

---

## Test Coverage Goals

Don't aim for 100% coverage. Aim for confidence.

- **Utils/helpers:** 90%+ coverage
- **Business logic:** 80%+ coverage
- **Components:** 60%+ coverage
- **Pages/routes:** E2E tests cover critical flows

```bash
# Generate coverage report
npm run test -- --run --coverage

# View in browser
open coverage/index.html
```
