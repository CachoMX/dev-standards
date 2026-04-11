# Accessibility Standards (a11y)

**Last updated:** February 2026

## Overview

Every project must meet **WCAG 2.1 Level AA** compliance standards as a minimum. Accessibility is not optional — it's a legal requirement (ADA, EAA) and ensures your app is usable by everyone, including users with disabilities.

**Key Statistics:**
- 1 in 4 adults in the US has a disability
- Automated tools catch only 57% of accessibility issues
- Manual testing with screen readers is essential

---

## WCAG 2.1 Principles (POUR)

All accessibility requirements stem from these four principles:

| Principle | What It Means |
|---|---|
| **Perceivable** | Content must be noticeable to users (they can see or hear it) |
| **Operable** | Users can navigate and interact with all functionality |
| **Understandable** | Information and UI operation is clear and predictable |
| **Robust** | Content works with current and future assistive technologies |

---

## Level AA Requirements Checklist

### 1. Perceivable

#### Text Alternatives (1.1)
- [ ] All images have meaningful `alt` text
- [ ] Decorative images use `alt=""` or `aria-hidden="true"`
- [ ] Icons have accessible labels (aria-label or sr-only text)

```tsx
// ✅ CORRECT
<img src="logo.png" alt="Company Name" />
<img src="decorative.png" alt="" aria-hidden="true" />
<button aria-label="Close dialog">
  <X className="h-4 w-4" />
</button>

// ❌ WRONG
<img src="logo.png" /> // Missing alt
<img src="decorative.png" alt="decorative image" /> // Unnecessary description
<button><X /></button> // No label
```

#### Color Contrast (1.4.3)
- [ ] Normal text: minimum **4.5:1** contrast ratio
- [ ] Large text (18pt+ or 14pt+ bold): minimum **3:1** contrast ratio
- [ ] UI components and graphics: minimum **3:1** contrast ratio
- [ ] Never rely on color alone to convey information

**Tools:**
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [Contrast Checker Chrome Extension](https://chromewebstore.google.com/detail/contrast-checker)

```css
/* ✅ CORRECT - High contrast */
:root {
  --color-text-primary: #111827;     /* 16:1 on white */
  --color-text-secondary: #4b5563;   /* 7:1 on white */
}

/* ❌ WRONG - Low contrast */
:root {
  --color-text-light: #9ca3af;       /* 2.5:1 on white - fails AA */
}
```

#### Resizable Text (1.4.4)
- [ ] Text can be resized up to 200% without loss of content or functionality
- [ ] Use relative units (`rem`, `em`) not fixed pixels
- [ ] Test zoom at 200% in browser

```css
/* ✅ CORRECT */
font-size: 1rem;
padding: 0.5rem 1rem;

/* ❌ WRONG */
font-size: 14px;
padding: 8px 16px;
```

#### Images of Text (1.4.5)
- [ ] Avoid images of text — use real text styled with CSS
- [ ] Exception: logos

---

### 2. Operable

#### Keyboard Accessible (2.1)
- [ ] All functionality available via keyboard (no mouse required)
- [ ] No keyboard traps (users can navigate away from any element)
- [ ] Focus order is logical and follows visual flow
- [ ] Tab navigation works correctly

**Keyboard Testing Checklist:**
- `Tab` — moves forward through interactive elements
- `Shift + Tab` — moves backward
- `Enter` or `Space` — activates buttons/links
- `Arrow keys` — navigate within components (menus, tabs, radio groups)
- `Esc` — closes modals/dialogs

```tsx
// ✅ CORRECT - Button is keyboard accessible
<button onClick={handleClick}>Submit</button>

// ❌ WRONG - Div is not keyboard accessible by default
<div onClick={handleClick}>Submit</div>

// ✅ ACCEPTABLE - Div with proper keyboard support
<div
  role="button"
  tabIndex={0}
  onClick={handleClick}
  onKeyDown={(e) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      handleClick();
    }
  }}
>
  Submit
</div>
```

#### Focus Visible (2.4.7)
- [ ] Keyboard focus indicator is clearly visible
- [ ] Don't remove focus outlines with `outline: none` without replacement

```css
/* ❌ WRONG - Removes focus indicator */
button:focus {
  outline: none;
}

/* ✅ CORRECT - Custom focus indicator */
button:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}
```

#### Skip Links (2.4.1)
- [ ] Provide "Skip to main content" link at top of page
- [ ] Visible on keyboard focus

```tsx
// src/components/layouts/skip-link.tsx
export function SkipLink() {
  return (
    <a
      href="#main-content"
      className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:px-4 focus:py-2 focus:bg-white focus:text-black focus:border-2"
    >
      Skip to main content
    </a>
  );
}

// Usage in app layout
export function Layout({ children }: { children: React.ReactNode }) {
  return (
    <>
      <SkipLink />
      <Header />
      <main id="main-content">{children}</main>
    </>
  );
}
```

#### Page Titles (2.4.2)
- [ ] Every page has a unique, descriptive `<title>`
- [ ] Format: `Page Name - Site Name`

```tsx
// Use React Helmet or similar
import { Helmet } from 'react-helmet-async';

export function LeadsPage() {
  return (
    <>
      <Helmet>
        <title>Leads Dashboard - CRM App</title>
      </Helmet>
      {/* Page content */}
    </>
  );
}
```

#### Link Purpose (2.4.4)
- [ ] Link text describes destination — avoid "click here" or "read more"
- [ ] Links are distinguishable from regular text (not just by color)

```tsx
// ❌ WRONG
<a href="/docs">Click here</a> to read the documentation.

// ✅ CORRECT
Read the <a href="/docs">documentation</a> for more details.
```

---

### 3. Understandable

#### Language of Page (3.1.1)
- [ ] HTML `lang` attribute set correctly

```html
<html lang="en">
```

#### Consistent Navigation (3.2.3)
- [ ] Navigation menus appear in same location across pages
- [ ] Navigation order is consistent

#### Error Identification (3.3.1)
- [ ] Form errors are clearly identified and described
- [ ] Error messages appear in text (not just red borders)

```tsx
// ✅ CORRECT - Clear error message
<div>
  <label htmlFor="email">Email</label>
  <input
    id="email"
    type="email"
    aria-invalid={!!error}
    aria-describedby={error ? 'email-error' : undefined}
  />
  {error && (
    <span id="email-error" role="alert" className="text-red-600">
      {error}
    </span>
  )}
</div>
```

#### Labels or Instructions (3.3.2)
- [ ] All form inputs have labels
- [ ] Required fields are clearly marked

```tsx
// ✅ CORRECT
<label htmlFor="name">
  Name <span aria-label="required">*</span>
</label>
<input id="name" type="text" required aria-required="true" />

// ❌ WRONG
<input placeholder="Name" /> // Placeholder is not a label
```

---

### 4. Robust

#### Parsing (4.1.1)
- [ ] Use valid HTML (no duplicate IDs, properly nested tags)
- [ ] Use semantic HTML elements

```tsx
// ✅ CORRECT - Semantic HTML
<header>
  <nav>
    <ul>
      <li><a href="/">Home</a></li>
    </ul>
  </nav>
</header>

// ❌ WRONG - Divs for everything
<div className="header">
  <div className="nav">
    <div onClick={...}>Home</div>
  </div>
</div>
```

#### Name, Role, Value (4.1.2)
- [ ] All UI components have accessible names
- [ ] Custom components use ARIA roles/states correctly

---

## React-Specific Patterns

### Semantic HTML

Always use semantic HTML elements before adding ARIA:

```tsx
// ✅ BEST - Semantic HTML (no ARIA needed)
<button onClick={handleClick}>Submit</button>
<nav><ul><li><a href="/about">About</a></li></ul></nav>

// ❌ AVOID - Div with ARIA (more code, more errors)
<div role="button" tabIndex={0} onClick={handleClick} onKeyDown={...}>
  Submit
</div>
```

### Focus Management

**Modal/Dialog Pattern:**

```tsx
import { useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';

export function Dialog({ isOpen, onClose, children }: DialogProps) {
  const dialogRef = useRef<HTMLDivElement>(null);
  const previousFocusRef = useRef<HTMLElement | null>(null);

  useEffect(() => {
    if (isOpen) {
      // Store current focus
      previousFocusRef.current = document.activeElement as HTMLElement;

      // Focus first focusable element in dialog
      const firstFocusable = dialogRef.current?.querySelector(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
      ) as HTMLElement;
      firstFocusable?.focus();

      // Trap focus
      const handleKeyDown = (e: KeyboardEvent) => {
        if (e.key === 'Escape') {
          onClose();
        }
      };
      document.addEventListener('keydown', handleKeyDown);

      return () => {
        document.removeEventListener('keydown', handleKeyDown);
        // Restore focus on close
        previousFocusRef.current?.focus();
      };
    }
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return createPortal(
    <div
      className="fixed inset-0 bg-black/50 flex items-center justify-center"
      onClick={onClose}
      role="dialog"
      aria-modal="true"
      aria-labelledby="dialog-title"
    >
      <div
        ref={dialogRef}
        className="bg-white p-6 rounded"
        onClick={(e) => e.stopPropagation()}
      >
        {children}
      </div>
    </div>,
    document.body
  );
}
```

### Live Regions (Announcements)

For dynamic content changes that should be announced to screen readers:

```tsx
// src/components/ui/live-region.tsx
export function LiveRegion({ message, priority = 'polite' }: {
  message: string;
  priority?: 'polite' | 'assertive';
}) {
  return (
    <div
      role="status"
      aria-live={priority}
      aria-atomic="true"
      className="sr-only"
    >
      {message}
    </div>
  );
}

// Usage - announce when data loads
function DataTable() {
  const { data, isLoading } = useQuery(...);

  return (
    <>
      {isLoading && <LiveRegion message="Loading data..." />}
      {data && <LiveRegion message={`Loaded ${data.length} items`} />}
      <table>...</table>
    </>
  );
}
```

### ARIA Patterns for Common Components

#### Tabs

```tsx
export function Tabs({ tabs }: { tabs: Array<{ id: string; label: string; content: ReactNode }> }) {
  const [activeTab, setActiveTab] = useState(tabs[0].id);

  return (
    <div>
      <div role="tablist" aria-label="Main tabs">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            role="tab"
            id={`tab-${tab.id}`}
            aria-selected={activeTab === tab.id}
            aria-controls={`panel-${tab.id}`}
            tabIndex={activeTab === tab.id ? 0 : -1}
            onClick={() => setActiveTab(tab.id)}
          >
            {tab.label}
          </button>
        ))}
      </div>
      {tabs.map((tab) => (
        <div
          key={tab.id}
          role="tabpanel"
          id={`panel-${tab.id}`}
          aria-labelledby={`tab-${tab.id}`}
          hidden={activeTab !== tab.id}
        >
          {tab.content}
        </div>
      ))}
    </div>
  );
}
```

#### Dropdown/Combobox

```tsx
export function Combobox({ options, value, onChange }: ComboboxProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [search, setSearch] = useState('');

  return (
    <div role="combobox" aria-expanded={isOpen} aria-haspopup="listbox">
      <input
        type="text"
        value={search}
        onChange={(e) => setSearch(e.target.value)}
        onFocus={() => setIsOpen(true)}
        aria-autocomplete="list"
        aria-controls="combobox-listbox"
      />
      {isOpen && (
        <ul id="combobox-listbox" role="listbox">
          {options
            .filter(opt => opt.label.toLowerCase().includes(search.toLowerCase()))
            .map((opt) => (
              <li
                key={opt.value}
                role="option"
                aria-selected={value === opt.value}
                onClick={() => {
                  onChange(opt.value);
                  setIsOpen(false);
                }}
              >
                {opt.label}
              </li>
            ))}
        </ul>
      )}
    </div>
  );
}
```

---

## Screen Reader Testing

### Required Screen Readers

Test with at least these combinations:

| OS | Screen Reader | Browser |
|---|---|---|
| Windows | **NVDA** (free) | Chrome/Firefox |
| Windows | JAWS | Chrome/Edge |
| macOS | **VoiceOver** | Safari |
| iOS | VoiceOver | Safari |
| Android | TalkBack | Chrome |

**Minimum:** NVDA (Windows) + VoiceOver (macOS)

### Testing Checklist

For each major feature/component:

- [ ] Navigate entire page with keyboard only (no mouse)
- [ ] Navigate with screen reader enabled
- [ ] Verify all content is announced correctly
- [ ] Verify all interactive elements are reachable
- [ ] Verify ARIA labels/roles are correct
- [ ] Verify form errors are announced
- [ ] Verify dynamic content changes are announced

### Quick VoiceOver Commands (macOS)

```
Cmd + F5          — Enable/disable VoiceOver
VO + Right Arrow  — Next item (VO = Ctrl + Option)
VO + Left Arrow   — Previous item
VO + Space        — Activate item
VO + U            — Rotor (navigate by headings, links, etc.)
```

### Quick NVDA Commands (Windows)

```
Ctrl + Alt + N    — Start NVDA
Insert + Down     — Next item
Insert + Up       — Previous item
Enter             — Activate item
Insert + F7       — Elements list
```

---

## Automated Testing Tools

### ESLint Plugin

```bash
npm install --save-dev eslint-plugin-jsx-a11y
```

```js
// .eslintrc.cjs
module.exports = {
  extends: [
    'plugin:jsx-a11y/recommended',
  ],
  rules: {
    'jsx-a11y/anchor-is-valid': 'error',
    'jsx-a11y/img-redundant-alt': 'error',
    'jsx-a11y/no-autofocus': 'warn',
  },
};
```

### React Testing Library

```tsx
import { render, screen } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

it('should have no accessibility violations', async () => {
  const { container } = render(<MyComponent />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});

it('should have accessible label', () => {
  render(<Button>Submit</Button>);
  expect(screen.getByRole('button', { name: 'Submit' })).toBeInTheDocument();
});
```

### Browser Extensions

- **axe DevTools** (Chrome/Firefox) — Automated accessibility testing
- **WAVE** — Visual feedback about accessibility issues
- **Lighthouse** (Chrome DevTools) — Accessibility score + audit

---

## Common Mistakes & Fixes

### 1. Missing Form Labels

```tsx
// ❌ WRONG
<input placeholder="Email" />

// ✅ CORRECT
<label htmlFor="email">Email</label>
<input id="email" type="email" />

// ✅ ALSO CORRECT - Visually hidden label
<label htmlFor="search" className="sr-only">Search</label>
<input id="search" placeholder="Search..." />
```

### 2. Non-Semantic Buttons

```tsx
// ❌ WRONG
<div onClick={handleClick}>Click me</div>

// ✅ CORRECT
<button onClick={handleClick}>Click me</button>
```

### 3. Icon-Only Buttons

```tsx
// ❌ WRONG
<button><X /></button>

// ✅ CORRECT
<button aria-label="Close">
  <X />
</button>

// ✅ ALSO CORRECT
<button>
  <X aria-hidden="true" />
  <span className="sr-only">Close</span>
</button>
```

### 4. Low Color Contrast

```tsx
// ❌ WRONG
<p className="text-gray-400">Secondary text</p> // 2.5:1 on white

// ✅ CORRECT
<p className="text-gray-600">Secondary text</p> // 5.9:1 on white
```

### 5. Keyboard Traps

```tsx
// ❌ WRONG - Modal doesn't trap focus
function Modal({ children }: { children: ReactNode }) {
  return <div className="modal">{children}</div>;
}

// ✅ CORRECT - Use focus trap library or implement manually
import { FocusTrap } from '@headlessui/react';

function Modal({ children }: { children: ReactNode }) {
  return (
    <FocusTrap>
      <div className="modal">{children}</div>
    </FocusTrap>
  );
}
```

---

## Accessibility Review Checklist

Before deploying any feature:

### Basic Checks
- [ ] All images have alt text
- [ ] Color contrast passes AA (4.5:1 for text)
- [ ] Forms have labels
- [ ] Buttons/links have meaningful text
- [ ] Page has proper heading hierarchy (h1, h2, h3)

### Keyboard Testing
- [ ] Tab through entire page — all interactive elements reachable
- [ ] No keyboard traps
- [ ] Focus indicators visible
- [ ] Enter/Space activates buttons

### Screen Reader Testing
- [ ] Navigate with NVDA or VoiceOver
- [ ] All content is announced
- [ ] ARIA labels are correct
- [ ] Form errors are announced

### Automated Testing
- [ ] `eslint-plugin-jsx-a11y` shows no errors
- [ ] Lighthouse accessibility score > 90
- [ ] axe DevTools shows no violations

---

## Resources

### Official Documentation
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [WAI-ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)
- [React Accessibility Docs](https://react.dev/learn/accessibility)

### Testing Tools
- [WAVE Browser Extension](https://wave.webaim.org/extension/)
- [axe DevTools](https://www.deque.com/axe/devtools/)
- [NVDA Screen Reader (Free)](https://www.nvaccess.org/)

### Tutorials
- [WebAIM Keyboard Testing](https://webaim.org/articles/keyboard/)
- [A11y Project Checklist](https://www.a11yproject.com/checklist/)

---

## Last Updated

February 2026 — Based on WCAG 2.1 Level AA standards and 2025 React accessibility best practices.
