---
name: implement-from-design
description: Use when implementing a new page from Figma designs in the alphafolio_design repo. Takes the design reference and builds a V2 page alongside the existing one, re-using the same backend and following established patterns.
argument-hint: <page-name> (e.g. "portfolio-risk", "holdings", "accounts", "dashboard")
---

# implement-from-design

Build a new V2 page that **matches the design exactly** — same layout, same components, same visual structure as the design code. The existing page is only used to identify what data/API hooks to wire in.

## Design Repository Location

The design code lives in a **separate repository** (NOT inside rustfolio):

```
/Users/zoranjeremic/Sources/RustLearning/alphafolio_design/code/
```

All references to design files below use `<design-repo>` = `/Users/zoranjeremic/Sources/RustLearning/alphafolio_design`

## When to Use

The user wants to implement a redesigned page based on the Figma export in the design repo. The V2 page coexists with the current page — no replacement, no deletion of the existing implementation.

## Inputs

- **Page name** — from `$ARGUMENTS` (e.g. "portfolio-risk", "holdings", "accounts")
- **Design code** — `<design-repo>/code/src/app/BuildPage.tsx` (the Figma-generated reference)
- **Screenshots** — `<design-repo>/screenshots_new/build/*.png` (visual reference)
- **Implementation guides** — any `*_V2_*.md` files in `<design-repo>/code/` for the target page

---

## THE FUNDAMENTAL RULE

> **The design is the source of truth for what to BUILD.**
> **The existing page is only the source of truth for what DATA to fetch.**

This means:
- You are building NEW components that match the design's visual structure
- You are NOT wrapping old components in new containers
- You are NOT importing existing V1 sub-components and putting them in a new layout
- You are NOT importing existing V1 components "as-is" even if they seem complex
- You ARE writing new TSX that looks like the design code, wired to real data

If the design shows a card with 3 metrics in a specific layout, you BUILD that card from scratch using MUI components styled to match the design — you do NOT import the old component that shows those metrics and wrap it.

### Zero V1 Component Imports (ABSOLUTE RULE)

**You may NOT import ANY V1 component that renders visible UI.** No exceptions. Not even if:
- The section is complex (e.g., connected accounts, brokerage integration)
- The section has lots of business logic (rebuild the UI, reuse only the hooks/logic)
- The section "looks similar" in the design (similar ≠ same — build fresh)
- You think it would save time (the goal is design fidelity, not speed)

**What you CAN import:**
- V2 components built for previous V2 pages (these ARE part of the new design system)
- React Query hooks (data fetching logic)
- API service functions
- TypeScript types/interfaces
- Utility functions (formatCurrency, date formatters, etc.)
- Constants and enums
- Auth context/hooks

**What you CANNOT import:**
- ANY V1 component that renders visible JSX/TSX (cards, tables, sections, forms, menus, dialogs)
- ANY sub-component of a V1 page (even small ones like a status badge or action button)
- ANY component that was part of the old/current visual layout
- The old `TickerActionMenu` (use the V2 version or build new from design)

The test: if `import { X } from './SomeComponent'` would bring in a V1 component that renders visible elements — DO NOT IMPORT IT. Check if a V2 version exists first. If not, build it fresh from the design.

---

## Phase 0 — Pre-flight (MANDATORY)

### 0.1 Load Design Context (THIS IS YOUR PRIMARY REFERENCE)

1. Read `<design-repo>/code/src/app/BuildPage.tsx` — **this is what you are building**
2. Read ALL screenshots in `<design-repo>/screenshots_new/build/` — **view every PNG, this is what the result must look like**
3. Read any `*_V2_IMPLEMENTATION_GUIDE.md` or `*_V2_COMPONENT_MAPPING.md` in `<design-repo>/code/`
4. Check `<design-repo>/screenshots/<page-name>/` for page-specific screenshots
5. Study the design code's component structure, layout grid, card arrangements, typography, spacing

### 0.2 Load Existing Page — COMPLETE Data & Action Inventory (CRITICAL)

1. Identify the current page component file in `frontend/src/components/`
2. Read it fully AND all its sub-components — chase every import to find ALL:
   - React Query hooks (keys, staleTime, retry logic, enabled conditions)
   - API endpoints consumed (REST calls, WebSocket subscriptions)
   - Mutation hooks (POST/PUT/DELETE actions)
   - Auth/Guest mode branching logic
   - Data transformation logic (how API response maps to displayed values)
3. **Do NOT study the existing page's visual structure.** That is being replaced by the design.

4. **Produce a COMPLETE inventory** — this is your wiring checklist:

#### Endpoint Inventory (every single one)
```
| # | Endpoint / Hook | HTTP Method | What it provides | Used in V1 section |
|---|----------------|-------------|------------------|--------------------|
| 1 | usePortfolioHoldings() | GET /api/portfolio/:id/holdings | Holdings list | Holdings table |
| 2 | useDeletePosition() | DELETE /api/positions/:id | Remove position | Delete button |
| ... | ... | ... | ... | ... |
```

#### Action Inventory (every clickable thing)
```
| # | Action in V1 | What it does | Handler/Hook | Must wire in V2 |
|---|-------------|--------------|--------------|-----------------|
| 1 | "Connect Account" button | Opens Plaid Link | usePlaidLink() | YES |
| 2 | "Refresh" icon | Triggers re-sync | useSyncAccount() | YES |
| 3 | "Delete" icon | Removes connection | useDeleteConnection() | YES |
| ... | ... | ... | ... | ... |
```

#### Field Inventory (every displayed data point)
```
| # | Field shown in V1 | Source | Must appear in V2 |
|---|-------------------|--------|-------------------|
| 1 | Account name | connection.institutionName | YES |
| 2 | Connection status | connection.status | YES |
| 3 | Last synced date | connection.lastSyncedAt | YES |
| ... | ... | ... | ... |
```

**This inventory is your contract.** Every endpoint, action, and field in V1 MUST be wired in V2 unless you explicitly flag it as "not in design — omitted" in your final report.

### 0.3 Load Project Patterns

Read these files to understand the implementation conventions:

1. **Theme**: `frontend/src/main.tsx` — `buildTheme(mode)` function (actual theme tokens)
2. **Layout**: `frontend/src/components/Layout.tsx` — sidebar structure, page routing

### 0.4 Study Previously-Implemented V2 Pages

Search for any V2 pages that were previously implemented:
```bash
find frontend/src/components -name "*V2*" -o -name "*v2*" | sort
```

If found, read one as a pattern reference for how design code was translated into production code. Pay attention to how the design's visual structure was preserved, NOT how old components were reused.

---

## Phase 1 — Design Analysis Document

Write a design analysis document. This is NOT a "reuse plan" — it's a BUILD plan.

### Design Structure Breakdown

For each section/card/panel in the design code:
- What is the visual structure (grid, cards, tables, charts)?
- What data does it display?
- Where does that data come from in the existing API hooks?

### Data Wiring Map

| Design Element | Data Needed | API Hook Source | Transformation |
|---------------|-------------|-----------------|----------------|
| Risk Score Card | overall score, breakdown | `useRiskMetrics()` | Direct |
| Holdings Table | positions list | `usePortfolioPositions()` | Map to table rows |
| ... | ... | ... | ... |

### New Components to Build

List every component you will CREATE (not import from existing):
- `<PageName>V2.tsx` — main page
- `<PageName>V2/<SectionCard>.tsx` — section components
- Each one built to match the design's visual structure

### Component Reuse Rule: V2 YES, V1 NEVER

**Reuse V2 components** — If a component was already built for a previous V2 page (e.g., a redesigned context menu, a V2 header, a V2 data card), reuse it. These are part of the new design system.

**Never import V1 components** — Any component from the old/current pages is off-limits. Even if it "looks similar" to what the design shows.

How to identify V2 vs V1:
- V2 components live in `*V2*` directories or were created during V2 page implementations
- V1 components are everything else in `frontend/src/components/` that existed before V2 work

If no V2 version of a component exists yet (first time this element appears in a V2 page), build it fresh from the design. Once built, subsequent V2 pages should reuse it.

---

## Phase 2 — Implementation

### Ground Rules (NON-NEGOTIABLE)

1. **The design code is your blueprint.** Build components that match its structure, layout, and visual design.
2. **Do NOT wrap or import existing page sections/sub-components.** Build new components that match the design.
3. **Wire to existing API hooks for data.** Same React Query keys, same staleTime, same retry logic.
4. **No mock data.** Wire to real data or show "—" / "Unavailable".
5. **No new backend requirements** unless explicitly approved.
6. **Use the project's MUI theme tokens** — translate the design's colors to the nearest theme token.
7. **Follow the design's layout precisely** — same grid structure, card arrangement, spacing ratios.
8. **V2 coexists with current page.** Existing page remains unchanged.
9. **Match the screenshots pixel-for-pixel** (within reason of theme token mapping).

### What "Match the Design" Means

When the design shows:
- A **3-column grid of metric cards** → Build a 3-column grid of metric cards with the same spacing and proportions
- A **table with specific columns** → Build that table with those columns in that order
- A **chart with specific styling** → Build that chart with those visual properties
- A **header with specific actions** → Build that header with those actions

Do NOT:
- Import the old metric component and put it in a new Box
- Import the old table and change its container
- Import the old chart component unchanged
- Copy the old header and restyle it

### How to Translate Design Code to Production Code

The design code (`BuildPage.tsx`) uses inline styles and mock data. Translate it:

| Design Code Pattern | Production Translation |
|--------------------|-----------------------|
| `style={{ color: '#1A2B3C' }}` | `sx={{ color: 'text.primary' }}` (nearest theme token) |
| `style={{ backgroundColor: '#F5F5F5' }}` | `sx={{ bgcolor: 'background.paper' }}` |
| Hardcoded numbers `"$45,230"` | Real data from API hook: `formatCurrency(data.value)` |
| `<div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr' }}>` | `<Grid container spacing={2}><Grid item xs={4}>...` |
| Inline SVG icons | MUI Icons or project icon components |
| `font-family: 'Inter'` | Project fonts (Syne for headings, DM Sans for body) |

### Critical Component Rules

#### Ticker Context Menu — USE V2 VERSION OR BUILD FROM DESIGN

1. **Check if a V2 context menu already exists** (e.g., `TickerActionMenuV2`, or a context menu in any `*V2*` directory). If yes → reuse it.
2. **If no V2 version exists yet**, build one fresh from the design. Do NOT import the old `TickerActionMenu`. The design's menu has different items, layout, styling — build what the design shows. Wire each action to the same navigation/API calls the old menu used (read the old component for action handlers only, not UI).
3. **Once built, place it where other V2 pages can import it** (e.g., `frontend/src/components/ui/` or a shared V2 directory).

#### Charts — Use Recharts

The project uses Recharts. Translate the design's chart visual into Recharts components:
- Match the design's chart type (area, bar, line, pie)
- Match the design's color scheme (mapped to theme tokens)
- Match the design's axis labels, tooltips, legends

### File Structure

```
frontend/src/components/<PageName>V2.tsx         # Main V2 page (if small enough)
frontend/src/components/<PageName>V2/            # Directory (if page is complex)
  ├── index.tsx                                  # Main page component + exports
  ├── <SectionName>Card.tsx                      # Individual section cards
  ├── <SectionName>Table.tsx                     # Section tables
  └── ...
```

### Implementation Process

For EACH section of the design:

1. **Read the design code** for that section — understand its visual structure
2. **Look at the screenshots** — confirm what it should look like
3. **Identify what data** that section displays
4. **Find the API hook** in the existing page that provides that data
5. **Build a new component** that matches the design's layout, wired to real data
6. **Use theme tokens** for all colors, spacing, typography
7. **Handle states**: loading (skeleton matching the design layout), error, empty data ("—")

### Loading States

Build skeleton states that match the DESIGN's layout (not the old page's loading state):
- If the design shows a card with 3 metrics, the skeleton should show 3 skeleton rectangles in that card's layout
- If the design shows a table with 5 columns, the skeleton should show 5 columns of placeholder rows

### Routing & Sidebar Integration

1. **Add the V2 page** to routing config (`AuthenticatedApp.tsx` or equivalent)
2. **Replace the old sidebar entry** — the V2 page takes the original menu name and route
3. **Mark the old page as legacy** — rename its sidebar entry to `"<Page Name> (Legacy)"` and move it below the V2 entry or into a secondary/collapsed section
4. **Do NOT remove the old page** — it stays accessible for comparison and rollback, just clearly labeled as legacy

Example sidebar change:
```tsx
// BEFORE:
{ name: 'Connected Accounts', path: '/accounts', component: ConnectedAccounts }

// AFTER:
{ name: 'Connected Accounts', path: '/accounts', component: ConnectedAccountsV2 },
{ name: 'Connected Accounts (Legacy)', path: '/accounts-legacy', component: ConnectedAccounts },
```

The V2 page gets the primary route. The old page gets a `-legacy` suffix route and `(Legacy)` in its menu name.

---

## Phase 3 — Connectivity Validation (MANDATORY BEFORE VISUAL CHECK)

Go back to your Phase 0.2 inventory and validate EVERY item is wired in V2. This is a line-by-line audit.

### 3.1 Endpoint Connectivity Audit

For each endpoint in your inventory:
- [ ] Find where it's called in V2 code
- [ ] Confirm the hook is invoked with correct parameters
- [ ] Confirm the response data is rendered somewhere in the UI
- [ ] If NOT used → flag as "DISCONNECTED" with reason

### 3.2 Action Connectivity Audit

For each action/button in your inventory:
- [ ] Find the button/clickable element in V2
- [ ] Confirm it has an onClick/onSubmit handler
- [ ] Confirm the handler calls the correct mutation/navigation
- [ ] Test the action works (click it, verify the effect)
- [ ] If NOT wired → flag as "DISCONNECTED" with reason

### 3.3 Field Connectivity Audit

For each data field in your inventory:
- [ ] Find where it's rendered in V2
- [ ] Confirm it reads from the correct API response field
- [ ] Confirm it displays real data (not hardcoded, not always "—")
- [ ] If NOT displayed → flag as "DISCONNECTED" with reason

### 3.4 Connectivity Report (PRESENT TO USER)

After the audit, produce this report:

```
## Connectivity Report

### Fully Connected (X/Y endpoints, X/Y actions, X/Y fields)
✓ All wired and working

### Disconnected Items (NEEDS USER DECISION)
| Item | Type | Reason | Recommendation |
|------|------|--------|----------------|
| "Export CSV" button | Action | Not shown in design | Add anyway? Or omit? |
| lastSyncError field | Field | Design doesn't show errors inline | Show in tooltip? Or omit? |
```

**DO NOT silently omit functionality.** If something from V1 isn't wired in V2, the user must know about it and decide. Never leave a button that does nothing or a field that shows stale/empty data without reporting it.

---

## Phase 4 — Visual & Functional Verification

### Visual Comparison (CRITICAL)

1. Start the dev server (`npm run dev` from `frontend/`)
2. Navigate to the V2 page
3. Open the design screenshots side-by-side
4. **Verify layout matches**: same grid structure, same card arrangement, same proportions
5. **Verify components match**: same visual elements in same positions
6. **Verify typography matches**: headings, body text, labels in correct sizes and weights
7. **Verify spacing matches**: gaps between cards, padding inside cards, margins
8. Check both dark and light mode
9. Check responsive behavior

### Functional Check

1. Verify data loads from real API (not mocked)
2. Verify ALL buttons trigger their intended action (click each one)
3. Verify ALL data fields show real values from API
4. Verify ticker context menu (if present) opens and all actions work
5. Verify portfolio selector works (if applicable)
6. Verify auth/guest mode branching
7. Verify loading states display correctly
8. Verify error states display correctly
9. Verify no "dead" buttons (onClick does nothing or is undefined)
10. Verify no perpetually empty fields (always shows "—" when data exists)

### Anti-Pattern Check

Review the implementation and flag if ANY of these occurred:

| Anti-Pattern (FAIL if found) | What Should Have Happened |
|------------------------------|--------------------------|
| Imported an existing V1 section component | Built a new component matching the design |
| Imported a "complex" V1 component because it has business logic | Extracted hooks/logic, built new UI from design |
| Used existing component and only changed its container/wrapper | Built the visual from scratch per design |
| Used old V1 `TickerActionMenu` instead of V2 version | Use V2 context menu if it exists, or build new one from design |
| Layout doesn't match the design's grid/card structure | Match the design's arrangement exactly |
| Old page's visual hierarchy is visible in V2 | V2 should look like the design, not the old page |
| Component shows old page's layout with new background color | Complete visual rebuild per design |
| Sections arranged differently than in screenshots | Match screenshot layout precisely |
| ANY import from a V1 component file that renders visible JSX | Only import hooks, types, utils, API functions |

### Import Audit (RUN THIS BEFORE DECLARING DONE)

Search V2 files for imports from existing component files:
```bash
grep -r "import.*from.*components/" frontend/src/components/*V2* | grep -v "types\|hooks\|utils\|api\|constants\|context"
```

Every match must be justified as a non-visual import. If it imports a component that renders UI → FAIL, rebuild it.

---

## Common Mistakes (STOP AND RE-READ IF YOU'RE DOING ANY OF THESE)

| What Claude Does Wrong | What It Should Do Instead |
|----------------------|--------------------------|
| Imports `<OldRiskCard>` and puts it in a new Box | Builds a new risk card component matching the design's layout |
| Imports `<OldHoldingsTable>` and changes the container | Builds a new table matching the design's columns, row structure, and styling |
| Wraps `<OldChartComponent>` in a Paper card | Builds a new chart with Recharts matching the design's chart visual |
| Uses the old page's section components with new props | Creates new section components from scratch, following the design |
| Imports a "complex" section whole (e.g. `<ConnectedAccounts>`, `<BrokeragePanel>`) because it has lots of logic | Extracts the hooks/logic from that component, builds a NEW UI matching the design, wires the extracted logic in |
| Uses old V1 `TickerActionMenu` for the context menu | Uses the V2 context menu if it exists, or builds one from design |
| Reads the design screenshots but then implements using old components | Builds new components that LOOK LIKE the screenshots |
| Says "reusing existing component for consistency" | Consistency comes from the DESIGN, not from old code |
| Says "this component is complex, better to reuse it" | Complexity is not an excuse. Read its logic, build fresh UI from design |
| Treats the design as "inspiration" for restyling old components | Treats the design as the literal blueprint to build from |
| Imports ANY component with visible UI rendering | Only imports: hooks, types, utils, API functions, constants |

### The Litmus Test

After implementation, ask: **"If I hide the old page and only look at V2, does it look like the screenshots?"**

If V2 looks like the old page with a new coat of paint → WRONG, redo it.
If V2 looks like the screenshots/design code → CORRECT.

---

## Output

When implementation is complete, present ALL of the following to the user:

1. **Files created** — list all new files
2. **Connectivity Report** (from Phase 3.4) — the full table showing what's connected and what's not
3. **Disconnected items requiring user decision** — anything from V1 that isn't wired in V2, with clear options for the user
4. **Visual match confirmation** — "V2 layout matches design screenshots" or list specific discrepancies
5. **URL path** to access the V2 page
6. **Remaining issues** — any buttons that don't work, fields showing "—" when they shouldn't, etc.

**The connectivity report is NOT optional.** The user must see it before the task is considered complete. If there are disconnected items, WAIT for user decision before closing out.
