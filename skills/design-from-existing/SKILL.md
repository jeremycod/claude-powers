---
name: design-from-existing
description: Use when creating a Figma-style design code for a page that hasn't been redesigned yet. Analyzes the existing page (via code and optionally Playwright screenshots), studies previously designed pages (Dashboard, Health, Portfolio Risk) as style reference, and produces new design code following the same visual language and component patterns.
argument-hint: <page-name> (e.g. "accounts", "analytics", "correlations", "downside-risk", "screener")
---

# design-from-existing

Create new Figma-quality design code for a page by studying the existing page implementation, taking screenshots if available, and following the established visual language from previously designed pages (Dashboard, Health, Portfolio Risk, Holdings).

## Design Repository Location

The design code lives in a **separate repository**:

```
/Users/zoranjeremic/Sources/RustLearning/alphafolio_design/code/
```

The rustfolio source code (the page being redesigned) is at:

```
/Users/zoranjeremic/Sources/RustLearning/rustfolio/
```

## When to Use

The user wants to create a visual redesign reference for a page that doesn't yet have design code. The output is a self-contained React component in the design project that serves as the visual reference for future V2 implementation.

---

## Phase 0 — Gather Context (MANDATORY)

### 0.1 Study the Existing Page

1. Find the current page component in `<rustfolio>/frontend/src/components/`
2. Read it fully to understand:
   - Layout structure (sections, cards, tabs, tables)
   - Data displayed (metrics, charts, tables, lists)
   - Interactive elements (buttons, selectors, menus, dialogs)
   - Sub-components used
   - API endpoints consumed (what data is available)

Where `<rustfolio>` = `/Users/zoranjeremic/Sources/RustLearning/rustfolio`

### 0.2 Take Screenshots (if available)

If the app is running or the user provides screenshots:

1. Check `<design-repo>/screenshots/<page-name>/` for existing screenshots
2. If no screenshots exist and user wants live capture, use the **playwright-cli** skill:
   ```
   playwright-cli goto http://localhost:5173
   # Navigate to the target page
   playwright-cli screenshot <design-repo>/screenshots/<page-name>/current-state.png
   ```
3. Screenshots serve as the "before" state — understanding what's there now

Where `<design-repo>` = `/Users/zoranjeremic/Sources/RustLearning/alphafolio_design`

### 0.3 Study the Established Design Language

Read these files to understand the V2 visual system that MUST be followed:

1. **`<design-repo>/code/src/app/BuildPage.tsx`** — the main Figma design output
   - Palette tokens (`D` for dark, `L` for light)
   - Shared primitives (`HCard`, `SHead`, `CTip`, `Reveal`)
   - Section structure patterns
   - Typography (font families, weights, sizes)
   - Spacing, border-radius, shadows, transitions

2. **`<design-repo>/screenshots/build/*.png`** — rendered output of existing designs
   - Visual reference for Dashboard, Health, Portfolio Risk pages
   - These are the "gold standard" to match

3. **`<design-repo>/code/src/imports/`** — reference screenshots fed to Figma
   - `Dashboard.png`, `Health.png` — existing page states
   - Other screenshots showing the current app

4. **`<design-repo>/code/src/imports/pasted_text/`** — design prompts/instructions
   - `alphafolio-figma-redesign.md` — component preservation rules
   - `figma-prototype-visual-update.md` — visual improvement guidelines
   - `dashboard-health-revamp.md` — specific page restoration instructions

### 0.4 Extract Design Tokens (from BuildPage.tsx)

The established palette:

```typescript
// Dark mode
const D = {
  appBg: "#071113", sidebar: "#081317", mainBg: "#0B1A1E",
  card: "#0F252B", cardElev: "#123139", cardNest: "#0C2026",
  border: "rgba(148,163,184,0.14)", borderHov: "rgba(20,184,166,0.32)",
  text: "#F8FAFC", textSub: "#94A3B8", textMuted: "#64748B",
  accent: "#14B8A6", accentDim: "rgba(20,184,166,0.12)",
  positive: "#22C55E", negative: "#EF4444", warning: "#F59E0B", blue: "#3B82F6",
  // ... charts, effects, tabs, warnings
};

// Light mode
const L = {
  appBg: "#F6F8FA", sidebar: "#FFFFFF", mainBg: "#F2F5F8",
  card: "#FFFFFF", cardElev: "#FAFCFF", cardNest: "#F8FAFC",
  border: "#E2E8F0", borderHov: "rgba(15,118,110,0.30)",
  text: "#0F172A", textSub: "#475569", textMuted: "#94A3B8",
  accent: "#0F766E", accentDim: "#ECFDF5",
  positive: "#16A34A", negative: "#DC2626", warning: "#D97706", blue: "#2563EB",
  // ...
};
```

### 0.5 Identify What to Preserve

From the existing page, identify components that MUST appear in the redesign:
- All data-displaying sections (metrics, charts, tables)
- All interactive controls (selectors, buttons, tabs)
- Key UX patterns (ticker menus, help dialogs, loading states)
- Guest mode considerations

---

## Phase 1 — Design Planning

Present to the user before writing code:

### Section Map

| # | Section | Current Component | Data Source | Design Treatment |
|---|---------|------------------|-------------|-----------------|
| 1 | Hero / Header | `<header area>` | portfolio context | Gradient hero card (match Dashboard hero) |
| 2 | Key Metrics | `<stat cards>` | risk/analytics hooks | V2 MetricCard grid |
| 3 | Main Chart | `<chart component>` | history endpoint | V2 ChartCard with time selector |
| 4 | Data Table | `<table section>` | positions/holdings | V2 TableCard with hover rows |
| ... | ... | ... | ... | ... |

### Design Decisions

- Hero card style: gradient / solid / minimal?
- Tab structure: keep existing tabs or reorganize?
- Ticker display: chip with TickerActionMenu (REQUIRED)
- Charts: which Recharts chart types to use?
- Warning/alert cards: use V2 warning system (red/amber/blue)
- Guest mode: placeholder cards or degraded display?

**Wait for user confirmation before proceeding.**

---

## Phase 2 — Write Design Code

### Output Location

Create the design in the design code project. The output goes into a NEW page component:

```
<design-repo>/code/src/app/<PageName>Page.tsx
```

If the page is large enough to warrant its own file (>400 lines), create it separately from `BuildPage.tsx`. Otherwise, it can be added as a new section/export in `BuildPage.tsx`.

### Design Code Structure (MUST FOLLOW)

Every page design MUST use this structure (matching BuildPage.tsx):

```tsx
import { useState, useEffect, useRef } from "react";
import { /* Recharts components */ } from "recharts";
import { /* Lucide icons */ } from "lucide-react";

// ─── Reuse shared primitives from BuildPage ─────────────────────────────────
// Import or copy: Reveal, HCard, SHead, CTip, D (dark), L (light) palettes

// ─── Page-specific mock data ─────────────────────────────────────────────────
// Mirror the SHAPE of real API data — same field names, realistic values
// This is for design visualization only

const mockMetrics = [ /* ... */ ];
const mockTableData = [ /* ... */ ];
const mockChartData = [ /* ... */ ];

// ─── PAGE COMPONENT ─────────────────────────────────────────────────────────

export default function <PageName>Page() {
  const [dark, setDark] = useState(true);
  const t = dark ? D : L;

  return (
    <div style={{ /* page wrapper with t.mainBg */ }}>
      {/* Hero Section */}
      <Reveal>
        <HCard t={t} style={{ /* gradient hero */ }}>
          {/* Page title, subtitle, status badges, key insight */}
        </HCard>
      </Reveal>

      {/* Metric Cards Grid */}
      <Reveal delay={80}>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))", gap: 16 }}>
          {/* V2-style metric cards */}
        </div>
      </Reveal>

      {/* Main Content Sections */}
      <Reveal delay={160}>
        <HCard t={t}>
          <SHead title="..." desc="..." t={t} />
          {/* Charts, tables, etc. */}
        </HCard>
      </Reveal>

      {/* ... more sections */}
    </div>
  );
}
```

### Visual Rules (NON-NEGOTIABLE)

These rules ensure the new page looks like it belongs with Dashboard/Health/Risk:

#### 1. Same Palette — Use D and L tokens

Never introduce new colors. All colors come from the established `D` (dark) and `L` (light) objects. If you need a shade that doesn't exist, derive it from existing tokens with opacity.

#### 2. Same Card Style — Use HCard primitive

All cards use `HCard` with:
- `borderRadius: 18`
- Hover: elevation change + slight translateY + border highlight
- Transition: `240ms cubic-bezier(0.22,1,0.36,1)`

#### 3. Same Typography

- **Headings**: `'Outfit', sans-serif` (700 weight, 15-20px)
- **Body**: System sans-serif (13-14px)
- **Mono**: `'JetBrains Mono', monospace` (for values, tooltips)
- **Large hero text**: 28-36px, 800 weight

#### 4. Same Section Headers — Use SHead

All sections get `<SHead title="..." desc="..." t={t} />` with optional action slot.

#### 5. Same Reveal Animations

Every section wrapped in `<Reveal delay={N}>` with staggered delays (0, 80, 160, 240...).

#### 6. Same Chart Styling

```tsx
<ResponsiveContainer width="100%" height={220}>
  <AreaChart data={data}>
    <CartesianGrid strokeDasharray="3 3" stroke={t.chartGrid} />
    <XAxis dataKey="label" stroke={t.chartTick} fontSize={11} />
    <YAxis stroke={t.chartTick} fontSize={11} />
    <Tooltip content={<CTip t={t} />} />
    <Area type="monotone" dataKey="value" stroke={t.chartLine1} fill={t.accentDim} />
  </AreaChart>
</ResponsiveContainer>
```

#### 7. Same Table Styling

- Row hover: subtle background shift
- Text: `t.text` for primary, `t.textSub` for secondary
- Borders: `t.borderSub` between rows
- Font: 13px, mono for numbers

#### 8. Same Tab Pattern

- Pill-style tabs with rounded container
- Active: `t.tabActive` background, `t.tabActiveText` text
- Inactive: transparent, `t.tabInactive` text
- Container: `t.tabBg` background, 14px border-radius

#### 9. Ticker Display Pattern

Every ticker in the design should show as an interactive chip/link that would map to `TickerActionMenu` in implementation:

```tsx
<span style={{
  fontFamily: "'JetBrains Mono', monospace",
  fontSize: 12,
  fontWeight: 600,
  color: t.accent,
  cursor: "pointer",
  padding: "3px 8px",
  borderRadius: 6,
  background: t.accentDim,
  border: `1px solid ${t.accentBorder}`,
}}>
  {ticker} ▾
</span>
```

This communicates that tickers are interactive and will use `TickerActionMenu` in V2 implementation.

#### 10. Warning/Status Cards

Match the existing warning system:
- Critical (red): `t.warnHigh` tokens
- Warning (amber): `t.warnMed` tokens
- Info (blue): `t.warnLow` tokens

---

## Phase 3 — Mock Data Strategy

### Rules for Mock Data

1. **Use realistic field names** that match the actual API response shape
2. **Use plausible values** (not round numbers, not placeholder text)
3. **Include enough rows** to show the design at scale (5-8 table rows, 12+ chart points)
4. **Mirror the TypeScript types** from the existing page's API layer
5. **Include edge cases** in mock data (negative values, zero, null-like states)

### Example: Converting Real API Shape to Mock

If the existing page uses:
```typescript
interface PositionRisk {
  ticker: string;
  weight: number;
  risk_score: number;
  volatility: number;
  // ...
}
```

The design mock should be:
```typescript
const mockPositions = [
  { ticker: "AAPL", weight: 18.4, risk_score: 42, volatility: 24.3 },
  { ticker: "MSFT", weight: 15.2, risk_score: 35, volatility: 21.8 },
  // 5-8 more...
];
```

---

## Phase 4 — Screenshots & Verification

### Build the Design

```bash
cd /Users/zoranjeremic/Sources/RustLearning/alphafolio_design/code
npm run dev
# or: npx vite --open
```

### Take Screenshots

After the design renders correctly:

1. Screenshot both dark and light mode
2. Save to `<design-repo>/screenshots/<page-name>/`
3. Name convention: `1-hero.png`, `2-metrics.png`, `3-chart.png`, etc. (or `dark.png`, `light.png`)

### Visual Comparison

Compare against the established designs:
- Does the hero card match the Dashboard/Health hero style?
- Do metric cards have the same dimensions, spacing, shadow?
- Are charts using the same grid/tick/tooltip style?
- Are tabs using the same pill pattern?
- Is the overall density/whitespace consistent?
- Does the color usage feel restrained (accent as highlight, not flood)?

---

## Phase 5 — Documentation

Create an implementation mapping document:

```
<design-repo>/code/<PAGE_NAME>_V2_COMPONENT_MAPPING.md
```

Following the same format as `PORTFOLIO_RISK_V2_COMPONENT_MAPPING.md`:

```markdown
# <Page Name> V2 — Component Mapping Document

## Ground Rules
1. Figma = visual reference only. Current page is functional source of truth.
2. V2 coexists with current page.
3. No mock data, no fake metrics, no backend changes.
4. Wrap existing sub-components, don't rewrite.
5. TickerActionMenu for all ticker interactions.

## 1. Current Page File/Data Inventory

### Main component
| File | Lines | Export |
|------|-------|--------|
| ... | ... | ... |

### Sub-components
| Component | File | Purpose |
|-----------|------|---------|
| ... | ... | ... |

### API endpoints consumed
| Endpoint | Purpose |
|----------|---------|
| ... | ... |

## 2. Design → Component Mapping

| Design Section | V2 Component | Data Source | Reuse |
|---------------|-------------|-------------|-------|
| ... | ... | ... | ... |

## 3. Implementation Notes

- <Any section-specific notes>
- <Guest mode behavior>
- <Ticker interaction points>
```

---

## Critical Rules

1. **Never diverge from established visual language** — the new page must look like it belongs on the same screen as Dashboard V2, Health V2, and Risk V2
2. **Same palette, same primitives, same animations** — consistency > novelty
3. **Preserve ALL existing page functionality** — don't simplify or remove sections; redesign visually
4. **Ticker chips are interactive** — always show the dropdown indicator (▾) to signal TickerActionMenu
5. **Mock data shape = real API shape** — implementation should be a drop-in replacement
6. **Both dark and light themes** — always implement with `const t = dark ? D : L` pattern
7. **Section stagger** — Reveal delays should increase by 80ms per section
8. **No new dependencies** — use only what's in the design project's package.json (Recharts, Lucide, Radix)
9. **Responsive grid** — use `repeat(auto-fit, minmax(Xpx, 1fr))` for card grids
10. **18px border radius** on cards, 14px on tabs, 10px on badges, 6px on chips

---

## App.tsx Integration

After creating the page component, register it in `<design-repo>/code/src/app/App.tsx` so it's accessible in the design preview. Add it as a route or tab alongside BuildPage.

---

## Output Checklist

- [ ] Page component created at `<design-repo>/code/src/app/<PageName>Page.tsx`
- [ ] Uses D/L palette tokens (no custom colors)
- [ ] Uses HCard, SHead, CTip, Reveal shared primitives
- [ ] Mock data mirrors real API type shapes
- [ ] Ticker chips show ▾ indicator (TickerActionMenu intent)
- [ ] Both dark and light mode work (toggle with `dark` state)
- [ ] Charts use Recharts with V2 chart styling
- [ ] Tabs use pill pattern with V2 tab tokens
- [ ] Warning cards use warnHigh/warnMed/warnLow tokens
- [ ] Typography uses Outfit (headings), system (body), JetBrains Mono (values)
- [ ] Screenshots saved to `<design-repo>/screenshots/<page-name>/`
- [ ] Component mapping document created
- [ ] Registered in App.tsx for preview
- [ ] Visual comparison confirms consistency with existing designed pages
