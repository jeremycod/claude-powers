---
name: create-tickets-from-design
description: Analyze Figma designs in the alphafolio_design repo and create Jira stories for implementing a V2 page. Uses RUS-4103 child stories as format reference. Asks user whether to create a new epic or add to existing.
argument-hint: <page-name> (e.g. "portfolio-risk", "holdings", "accounts", "dashboard", "analytics")
---

# create-tickets-from-design

Analyze Figma design code and create structured Jira stories for implementing a V2 page redesign, following the same format and granularity as the stories under RUS-4103.

## Design Repository Location

The design code lives in a **separate repository** (NOT inside rustfolio):

```
/Users/zoranjeremic/Sources/RustLearning/alphafolio_design/code/
```

All references to design files below use `<design-repo>` = `/Users/zoranjeremic/Sources/RustLearning/alphafolio_design`

## When to Use

The user wants to plan the implementation of a page redesign from Figma, broken into Jira stories with proper acceptance criteria, before writing any code.

---

## Phase 0 — Design Analysis (MANDATORY)

### 0.1 Load Design Reference

1. Read `<design-repo>/code/src/app/BuildPage.tsx` — the full Figma-generated visual reference
2. View screenshots in `<design-repo>/screenshots/build/*.png`
3. Read any `*_V2_IMPLEMENTATION_GUIDE.md` or `*_V2_COMPONENT_MAPPING.md` in `<design-repo>/code/`
4. Read any `*_V2_DISCOVERY.md` if it exists for the target
5. Check page-specific subdirectories (e.g., `<design-repo>/screenshots/<page-name>/`)

### 0.2 Load Existing Page

1. Find the current page component in `frontend/src/components/`
2. Read it to understand:
   - All React Query hooks and API endpoints consumed
   - Sub-components imported
   - Auth vs Guest mode logic
   - Data types and state management
   - Action buttons and mutations

### 0.3 Load Reference Stories

Fetch stories under RUS-4103 to match format:
```
JQL: parent = RUS-4103 ORDER BY key ASC
```

Study:
- Story title format: concise, descriptive, includes scope hint
- Description structure: Phase header → file/component target → Requirements list → Acceptance Criteria checklist
- Granularity: one story = one logical deliverable (a component, a section, a tab)
- Dependencies: stories within same PR batch are independent; cross-PR dependencies noted

---

## Phase 1 — Discovery Output

Present to the user:

### Section Inventory

Break the design into implementable sections:

| # | Design Section | Existing Component(s) | Reuse Strategy | Complexity |
|---|---------------|----------------------|----------------|-----------|
| 1 | Page shell + hero | (new V2 wrapper) | Wrap existing data | Low |
| 2 | Overview tab / main section | `<existing>` | Wrap + restyle | Medium |
| 3 | Detail section / sub-tab | `<existing sub-component>` | Direct import | Low |
| ... | ... | ... | ... | ... |

### API Endpoint Map

| Endpoint | Current Page Uses | V2 Will Use | Notes |
|----------|------------------|-------------|-------|
| `getPortfolioRisk(id, days, bench)` | Yes | Yes (same) | Auth only |
| `getGuestPortfolioRisk(id)` | Yes | Yes (same) | Guest mode |
| ... | ... | ... | ... |

### Key Decisions (carry forward from RUS-4103 epic)

- TickerActionMenu for all ticker interactions (NOT a new menu)
- No mock data — real API data or "—" / placeholder
- No backend changes unless explicitly approved
- V2 tokens from existing `v2/tokens.ts` (if already created) or project theme
- Guest mode: degraded/partial data with styled placeholders
- Animation: IntersectionObserver + CSS transitions (no framer-motion)
- Wrap existing sub-components, don't rewrite

---

## Phase 2 — User Decision: Epic Placement

**ASK THE USER** before creating any tickets:

> I've analyzed the design for `<page-name>` and identified **N stories** across **M PR batches**.
>
> Where should these stories go?
>
> 1. **Add to existing epic RUS-4103** (Dashboard V2 + Health V2 Visual Redesign) — as additional PR phases
> 2. **Create a new epic** — with its own scope and description
> 3. **Add to a different epic** — specify which one
>
> Also: should I check if any V2 foundation stories (tokens, shared components) already exist, or assume they're done?

**Wait for user response.** Do NOT proceed without confirmation.

---

## Phase 3 — Story Generation

### Story Format (match RUS-4103 children exactly)

Each story follows this template:

```markdown
## Phase N — <PR Batch Description>

<Component/file target and what it does>

### Requirements

* <Specific requirement 1>
* <Specific requirement 2>
* <File paths where code will live>
* <Data source: which hook/endpoint provides the data>
* <Reuse note: "Wraps existing `<ComponentName>`" or "New V2 component">

### Key Rules

* TickerActionMenu for all ticker interactions
* No mock data — use real API data or show "—" / "Unavailable"
* Use V2 tokens from `useV2Tokens()` hook
* <Any page-specific rules>

### Acceptance Criteria

* [ ] <Criterion 1 — specific, verifiable>
* [ ] <Criterion 2>
* [ ] <Criterion 3>
* [ ] Component renders with real data from `<hookName>`
* [ ] Dark mode + light mode both work via V2 tokens
* [ ] Guest mode: <specific behavior>
* [ ] No TypeScript errors (`npx tsc --noEmit` on the new file)
```

### PR Batching Strategy

Group stories into logical PR batches (same pattern as RUS-4103):

| PR | Stories | Goal |
|----|---------|------|
| PR 1 — Shell + Route | 2-3 stories | Page route, shell, hero/header |
| PR 2 — Main Content | 3-5 stories | Primary sections, data display |
| PR 3 — Depth/Polish | 2-4 stories | Secondary tabs, interactions, guest mode, responsive |

Rules for batching:
- Each PR should be independently shippable
- Shell/route first (unblocks other work)
- Most complex sections get their own story
- Guest mode + responsive + accessibility = final polish PR
- Max 5-6 stories per PR

### Story Granularity Rules

- **One story = one component OR one logical section** (not an entire tab with 5 sub-sections)
- **Hero/header** = separate story
- **Each tab** = separate story (if tabs exist)
- **Table with complex behavior** = separate story
- **Chart section** = separate story
- **Guest mode adaptation** (if complex) = separate story
- **Action buttons + modals** = separate story (if they involve mutations)
- **Never combine** unrelated sections into one story

### Title Format

Match the RUS-4103 pattern:
- `V2 <Component/Section Name> (<key detail>)`
- Examples:
  - `V2 Analytics Hero Card (performance summary + portfolio selector)`
  - `V2 Risk Overview Tab (score bar, stat cards, contribution table)`
  - `V2 Holdings Table (grouped by ticker, TickerActionMenu integration)`
  - `V2 Guest Mode Adaptation (placeholders + degraded states)`

---

## Phase 4 — Ticket Creation

### Epic (if creating new)

Create with:
- **Type**: Epic
- **Summary**: `<Page Name> V2 Visual Redesign`
- **Description**: Follow RUS-4103 format:
  - Overview section
  - Architecture section (styling, components, routing)
  - Key Decisions table
  - Implementation Constraints list
  - PR Batching Strategy table
  - Story Count summary
  - Design Artifacts links

### Stories

Create each story with:
- **Type**: Story
- **Parent**: The chosen epic
- **Summary**: Title from generation step
- **Description**: Full markdown from template above
- **Priority**: Medium (unless user specifies otherwise)
- **Labels**: (match existing epic labels if any)

### After Creation

Present summary:

```
## Created: N stories under <EPIC-KEY>

| PR Batch | Stories | Goal |
|----------|---------|------|
| PR 1 | RUS-XXXX, RUS-YYYY | Shell + hero |
| PR 2 | RUS-XXXX, RUS-YYYY, RUS-ZZZZ | Main content |
| PR 3 | RUS-XXXX, RUS-YYYY | Polish + guest |

Total: N stories, M PRs estimated.
Ready to implement with `/implement-from-design <page-name>`
```

---

## Common Mistakes to Avoid in Tickets

| Mistake | Correct |
|---------|---------|
| Writing "implement ticker dropdown" | Write "integrate TickerActionMenu component" |
| Accepting criteria says "renders mock data" | AC must say "renders from `usePortfolioRisk()` hook" |
| Story covers entire page in one ticket | Split into hero + tabs + table + actions |
| No mention of guest mode | Every story must state guest behavior |
| No file path specified | Always specify target file: `frontend/src/components/<Page>V2/<Section>.tsx` |
| Backend requirement snuck in | Explicitly state "No backend changes" in each story |
| Referencing Figma component library | Reference existing project components only |
| Missing dark/light mode criterion | Every visual story needs "Dark + light mode via V2 tokens" AC |

---

## Design Source Locations

| Resource | Path |
|----------|------|
| Design repo root | `/Users/zoranjeremic/Sources/RustLearning/alphafolio_design/` |
| Figma code (main) | `<design-repo>/code/src/app/BuildPage.tsx` |
| Screenshots | `<design-repo>/screenshots/build/*.png` |
| Page-specific screenshots | `<design-repo>/screenshots/<page>/` |
| Implementation guides | `<design-repo>/code/*_V2_*.md` |
| Existing V2 components | `frontend/src/components/v2/` (if already created) |
| Project theme | `frontend/src/main.tsx` → `buildTheme(mode)` |
| TickerActionMenu | `frontend/src/components/TickerActionMenu.tsx` |

---

## Jira Configuration

- **Cloud ID**: `f59f6f68-e075-422c-98c2-a68875b1bf32`
- **Project Key**: `RUS`
- **Issue Type (Epic)**: Epic
- **Issue Type (Story)**: Story
- **Reference Epic**: RUS-4103
- **Content Format**: `markdown`
