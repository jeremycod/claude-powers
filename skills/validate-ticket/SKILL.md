---
name: validate-ticket
description: Use when the user provides one or more Jira epic/story IDs and wants a testable summary of completed work — generates UI test steps for manual validation and automatically verifies backend concerns (endpoints, DB state, logs). Supports multiple tickets for cross-epic validation.
argument-hint: <TICKET-ID> [<TICKET-ID-2> ...]
---

# Validate Ticket

Use this skill when:
- the user provides one or more Jira ticket IDs (epics or stories)
- the user wants to understand what was built and how to test it in the UI
- the goal is validation/QA, not implementation

If no Jira ticket ID is provided, STOP and ask for one.

---

# INPUT PARSING

The user may provide:
- Single ticket: `/validate-ticket RUS-3893`
- Multiple tickets: `/validate-ticket RUS-3893 RUS-3900 RUS-3910`
- Comma-separated: `/validate-ticket RUS-3893, RUS-3900, RUS-3910`

Parse ALL ticket IDs from the input. Treat each as a separate epic/story to fetch and validate.

---

# CONTEXT RESOLUTION (MANDATORY)

When **single ticket** is provided:
- Context = that ticket ID
- Review directory: `.claude/reviews/<TICKET-ID>/`

When **multiple tickets** are provided:
- Context = the FIRST ticket ID (used for directory naming)
- Review directory: `.claude/reviews/<FIRST-TICKET-ID>/`
- The validation report covers ALL provided tickets as a unified test plan
- The report header lists all ticket IDs covered

Example: `/validate-ticket RUS-3893 RUS-3900 RUS-3910` → `.claude/reviews/RUS-3893/`

Create the directory if it does not exist.

---

# REFERENCE LABELING SYSTEM

All output sections MUST use a two-axis reference system so the user can refer to specific items without repeating context:

**Letters (A, B, C...)** = Feature areas / UI test scenarios
**Numbers (1, 2, 3...)** = Backend verification checks
**Concerns use C1, C2, C3...**

Examples of user referencing:
- "A looks good" → Feature A passes
- "Retest 3" → Re-run backend check 3
- "C2 is acceptable" → Concern C2 can be ignored

### How to assign labels

- Assign letters sequentially to each UI test feature section (A, B, C, D...)
- Assign numbers sequentially to each backend verification check (1, 2, 3, 4...)
- Assign C-prefixed numbers to each concern row (C1, C2, C3...)

Labels MUST appear prominently in headers and table rows. Format:

```
## [A] Feature: CSV Import → Price Provisioning
## [B] Feature: 503 "Setting Up" Message
```

```
### [1] RUS-3895: Post-import provisioning pipeline
### [2] RUS-3896: 503 error response
```

```
| C1 | Low | Field name deviation... |
| C2 | Medium | Readiness table not implemented... |
```

---

# PROCESS

## Step 0: Environment Setup (Worktree Detection)

Before fetching tickets, determine if you are in a worktree:

```bash
git rev-parse --git-dir
```

If the output contains `/worktrees/`, you ARE in a worktree.

### If in a worktree:

You MUST start the backend and frontend services yourself using the `run-from-worktree` pattern:

1. Identify the main checkout path via `git worktree list` (first entry)
2. Copy `backend/.env` from the main checkout if not already present
3. Start backend (`cd backend && cargo run`) in background
4. Start frontend (`cd frontend && npm run dev`) in background
5. Wait for both services to be ready before proceeding to backend verification (Step 5)

This ensures you can hit endpoints and verify UI behavior against the worktree code.

### If on main branch (not a worktree):

Do NOT start services. Assume the user will start them manually or they are already running.
If backend verification (Step 5) requires a running service and it's unreachable, mark those checks as SKIPPED with a note: "Service not running — start backend/frontend manually or use `/validate-ticket` from a worktree."

---

## Step 1: Fetch Tickets

For EACH provided ticket ID, retrieve using available Jira/Atlassian tools:

- ticket ID, summary, type (Epic / Story / Task)
- description
- acceptance criteria
- status

If a ticket is an Epic or has children, fetch ALL child tickets.

When multiple tickets are provided, fetch them all and merge their children into a single unified list for Steps 2–5. Track which parent epic each child belongs to (used in the report for grouping).

---

## Step 2: Identify Completed Work

Filter to only DONE / completed tickets (or the status equivalent in the project's workflow).

Build a summary table. When multiple epics are provided, group by parent epic:

```
### Epic: RUS-3893 — CSV Import Pipeline

| Ticket | Summary | Status | Has AC? |
|--------|---------|--------|---------|
| RUS-3895 | ... | Done | yes |
| RUS-3896 | ... | Done | yes |

### Epic: RUS-3900 — Risk Dashboard Enhancements

| Ticket | Summary | Status | Has AC? |
|--------|---------|--------|---------|
| RUS-3901 | ... | Done | yes |
```

For a single ticket, use a flat table without epic grouping.

If NO tickets are completed across ANY of the provided epics → STOP and report that there is nothing to validate yet.

---

## Step 3: For Each Completed Ticket — Analyze What Was Built

For each completed ticket:

1. Read the acceptance criteria
2. Read linked PRs or commits (if available via Jira or GitHub)
3. Identify the feature area (what part of the UI or system is affected)
4. Classify each acceptance criterion as:
   - **UI-testable** — user can verify directly in the browser
   - **Backend-verifiable** — requires API call, DB query, or log check
   - **Code-only** — structural/refactoring, not user-visible

---

## Step 4: Generate UI Test Steps

For each UI-testable criterion, produce step-by-step instructions that a human tester can follow.

**Each feature section gets a letter label: [A], [B], [C]...**

### Format per feature:

```
## [A] Feature: <Feature Name>
Source: <TICKET-ID> — <Summary>

### Prerequisites
- <any setup needed: logged in as X, data exists, etc.>

### Steps
1. Navigate to <URL or page>
2. <specific action>
3. <specific action>
4. ...

### Expected Result
- <what the user should see>
- <specific UI elements, messages, or behaviors>

### Edge Cases to Check
- <boundary condition>
- <error state>
```

Rules for UI test steps:
- Be SPECIFIC — name exact pages, buttons, fields
- Include the URL path if known
- Describe expected visual feedback (toasts, redirects, state changes)
- Group related steps into logical scenarios
- Order from happy path → edge cases

---

## Step 5: Automatically Verify Backend Concerns

For each backend-verifiable criterion, YOU (Claude) must verify it directly. Do NOT ask the user to do these.

**Each backend check gets a number label: [1], [2], [3]...**

### What to verify automatically:

**API endpoints:**
- Hit the endpoint (curl/fetch) and confirm expected response shape
- Check status codes
- Verify required fields exist in response

**Database state:**
- Query the database to confirm expected records/schema exist
- Verify data integrity constraints
- Check that migrations ran correctly

**Logs / observability:**
- Check application logs for expected entries
- Verify no error-level logs for the feature
- Check that events are being emitted if applicable

**Configuration:**
- Verify environment variables or feature flags are set
- Check that services are properly configured

### Output format for backend verification:

```
## Backend Verification Results

### [1] <TICKET-ID>: <what was checked>
- Status: PASS / FAIL / SKIPPED
- Method: <what you did — curl, SQL query, log check>
- Evidence: <response snippet, query result, or log line>
- Notes: <any concerns or follow-ups>

### [2] <TICKET-ID>: <what was checked>
...
```

If you CANNOT verify something (no DB access, no running service, credentials missing):
- Mark it as SKIPPED
- Explain what would need to be checked and how
- Provide the exact command/query the user could run

---

## Step 6: Produce Final Validation Report

Combine everything into a structured report:

```
# Validation Report: <FIRST-TICKET-ID> — <Title>

## Scope
- Tickets validated: <TICKET-ID-1>, <TICKET-ID-2>, ... (list all)
- Total completed stories: N
- UI test scenarios: N (labeled A–X)
- Backend checks: N passed / N failed / N skipped (labeled 1–X)

## Completed Tickets
<table from Step 2, grouped by epic if multiple>

## UI Test Plan
<all UI test steps from Step 4, each with [A], [B], [C]... labels>
<when multiple epics: group features by epic, but labels are global/sequential>

## Backend Verification Results
<all backend results from Step 5, each with [1], [2], [3]... labels>

## Not Yet Testable
<tickets that are still in progress or have unclear AC>

## Concerns / Notes
| Ref | Severity | Description |
|-----|----------|-------------|
| C1  | Low/Med/High | ... |
| C2  | ... | ... |
```

When multiple epics are provided, the UI Test Plan may group features under epic headings for readability, but the reference labels (A, B, C...) remain globally sequential — never restart at A for a second epic.

---

## Step 7: Persist Validation Artifact

After producing the report, persist it to the review directory:

`.claude/reviews/<TICKET-ID>/50-validation-report.md`

The file MUST contain:
- the full validation report from Step 6
- a reference key at the top explaining the labeling system

### Reference key format (prepend to artifact):

```
# Reference Key
- [A], [B], [C]... = UI test scenarios
- [1], [2], [3]... = Backend verification checks
- C1, C2, C3... = Concerns/notes
- Use these labels to discuss specific items (e.g., "A passed", "retest 3", "C2 is acceptable")
```

If the review directory already has other artifacts (from implementation), this validation report complements them — do not overwrite existing files.

---

# USER OBSERVATIONS (Post-Report Testing Phase)

After the validation report is delivered, the user will test the UI and report problems one at a time. This section defines how to handle those reports.

**CRITICAL: During collection, ONLY store. Do NOT investigate, analyze, or classify. Just record and confirm.**

## How observations arrive

The user will send messages like:
- "A doesn't work — the button is missing" (references a UI scenario label)
- "When I click import nothing happens" (freeform description)
- A screenshot (pasted inline or file path) with a comment
- "3 fails — I get a 500 instead of 503"

Each message = one observation. The user may send several across the conversation.

## What to do for EACH observation

### 1. Save screenshot (if provided)

If the user pasted a screenshot inline, immediately capture it:

```bash
mkdir -p .claude/reviews/<TICKET-ID>/observations/O<N>
pngpaste .claude/reviews/<TICKET-ID>/observations/O<N>/screenshot-1.png
```

If the user provided a file path:
```bash
cp <path> .claude/reviews/<TICKET-ID>/observations/O<N>/screenshot-1.png
```

If `pngpaste` is not installed, inform the user: "Screenshot couldn't be saved — install with `brew install pngpaste`, or provide a file path."

### 2. Append to observations artifact

Append a structured entry to:

`.claude/reviews/<TICKET-ID>/51-observations.md`

Create the file on first observation with a header:

```markdown
# Observations — <TICKET-ID>

Reference: These are user-reported issues found during validation testing.
Labels: O1, O2, O3... Use these to reference specific observations.
Status: collecting (run "investigate observations" when done)

---
```

Each entry uses the format:

```markdown
### O<N>: <Short title>
- **Ref:** [label] (or "new" if not in original report)
- **Reported:** <user's description, verbatim or summarized>
- **Screenshot:** `observations/O<N>/screenshot-1.png` or "none"
- **Status:** open
```

That's it. No classification, no investigation, no analysis. Just store the raw report.

Labels: O1, O2, O3... (sequential, never reused in the session).

### 3. Confirm briefly

Reply with ONLY:
```
O<N> recorded. (<total> total)
```

Do NOT add commentary, classification, or suggestions. The user is in testing flow — don't interrupt.

---

## When user triggers investigation

The user MUST explicitly trigger processing. Typical triggers:
- "investigate observations"
- "investigate all"
- "process observations"
- "analyze problems"
- "what's going on with all of these"

**Do NOT investigate until explicitly asked.** Even if you think you see the problem, wait.

### Investigation process

#### 1. Read the full observations file

Load `.claude/reviews/<TICKET-ID>/51-observations.md`

#### 2. Classify each observation

For each observation:
- **Type:** UI issue / Backend issue / Data issue / Unclear
- **Severity:** Critical / High / Medium / Low
- Map to validation report reference label if applicable

#### 3. Deep investigate each observation

**Phase 1: Locate code**
- Identify relevant files (grep, glob, follow call chain)
- Check recent commits touching that area

**Phase 2: Verify**
- Hit endpoints if applicable
- Query DB if data-related
- Read logs if available
- Re-read screenshots for visual evidence

**Phase 3: Root cause**
- Determine root cause (or top hypotheses with confidence)
- Note if multiple observations share a cause

#### 4. Produce investigation summary

Append to the observations file AND output to user:

```markdown
---

## Investigation Summary

| Ref | Title | Type | Severity | Root Cause | Confidence | Suggested Fix |
|-----|-------|------|----------|-----------|------------|---------------|
| O1  | ...   | ...  | ...      | ...       | confirmed/likely/weak | ... |
| O2  | ...   | ...  | ...      | ...       | ...        | ... |

### Grouped Issues
- O1 + O3: <shared root cause explanation>
- O2: <independent issue>

### Recommended Next Steps
1. <highest priority action>
2. <next action>
3. ...
```

#### 5. Update observation statuses

Update each observation's status in `51-observations.md`:
- **confirmed** — issue verified, fix identified
- **explained** — not a bug (expected behavior, user misunderstanding, or environment issue)
- **resolved** — if you were able to fix it during investigation

#### 6. Route to next action

After presenting the summary, offer:

| Action | Routes to |
|--------|-----------|
| Create tickets for confirmed issues | `draft-jira-ticket` |
| Fix directly (if trivial) | `implement-from-problem` |
| Design a solution (if complex) | `design-solution` |
| Continue collecting observations | stay in validate-ticket |

Wait for user choice. Do NOT proceed without confirmation.

---

# RULES

You MUST:
- only include COMPLETED tickets in the validation plan
- write UI steps specific enough that someone unfamiliar with the system could follow them
- attempt backend verification yourself before asking the user
- clearly distinguish what YOU verified vs what the user needs to test manually
- report any discrepancies between AC and actual implementation
- use the reference labeling system consistently ([A], [B], [1], [2], C1, C2)
- persist the validation artifact to `.claude/reviews/<TICKET-ID>/50-validation-report.md`
- record EVERY user-reported observation to `51-observations.md` immediately
- keep observation labels (O1, O2...) sequential and stable
- wait for explicit user trigger before investigating observations

You MUST NOT:
- include in-progress or todo tickets in the test plan
- write vague steps like "verify it works" — be specific
- ask the user to run API calls or DB queries that you can run yourself
- assume features work without evidence
- skip acceptance criteria even if they seem trivial
- use unlabeled sections — every feature, check, and concern gets a reference label
- silently drop observations — every user report gets an O-label and is persisted
- reuse or renumber O-labels within a session
- investigate, classify, or analyze observations during collection — ONLY store
- add commentary or suggestions when recording an observation

---

# CRITICAL CONSTRAINTS

- If Jira/Atlassian tools are unavailable: STOP, inform user
- If a ticket has no acceptance criteria: note this explicitly and infer testable behavior from the description and any linked PRs
- If you cannot access the running application: produce the UI test plan but mark backend verification as SKIPPED with instructions
- If the database MCP is available: USE IT for verification queries
- If the application is running locally: hit endpoints directly for verification
