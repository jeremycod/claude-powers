---
name: implement-jira-ticket
description: Use when the user has provided a Jira ticket ID and explicitly wants implementation — fetches ticket, validates scope, implements actionable work, and persists Builder artifacts for downstream review.
---

# Implement Jira Ticket

Use this skill ONLY when:
- the user explicitly wants implementation
- a Jira ticket ID is provided

If no Jira ticket ID is provided, STOP and state that a ticket ID is required.

---

# REQUIRED FIRST OUTPUT

You MUST begin your visible response with:

# Builder Routing

## Phase
implementation

## Selected Skill
implement-jira-ticket

## Reason
The user explicitly requested implementation of a Jira ticket.

Do not skip this section.

---

# REVIEW DIRECTORY (MANDATORY WHEN TICKET ID IS KNOWN)

If a Jira ticket ID is known, you MUST use this review directory inside the CURRENT WORKTREE:

.claude/reviews/<TICKET_ID>/

Example:
.claude/reviews/RUS-2458/

You MUST create it if it does not exist.

You MUST persist these files there before finishing:

- 00-work-dossier.md
- 10-builder.md
- 11-builder-summary.json
- 12-builder-diff.patch
- 13-builder-tests.txt

---

# PROCESS

## Step 1: Fetch and classify the ticket

Retrieve and internalize:

- ticket ID
- summary
- type (Epic / Story / Task / Bug / Sub-task)
- description
- acceptance criteria
- technical notes
- parent / epic context
- labels / components
- priority
- current Jira status

If the ticket type is unclear, say so explicitly.

---

## Step 2: Scope validation (MANDATORY)

### If the ticket is an Epic OR has child issues

You MUST:

1. Fetch ALL child tickets

2. Build a structured table:

| Story | Summary | Fetched? | AC Clear? |
|------|--------|----------|-----------|

3. For EACH child story:
- extract acceptance criteria
- determine if independently implementable
- identify dependencies

4. Decide execution strategy:

- implement ONE story
- implement a small set of tightly related stories
- STOP and recommend planning

### HARD RULES

- You MUST NOT claim “implemented” without verifying each story’s acceptance criteria
- You MUST NOT treat “Epic description” as sufficient requirement definition
- You MUST NOT silently skip child stories

---

### If the ticket is a Story with subtasks

You MUST:

- fetch all subtasks
- list them
- determine execution order or grouping

If unclear:
→ STOP and recommend planning

---

### If the ticket is Task / Bug / Sub-task

Proceed after understanding requirements.

---

## Step 3: Understand before coding (MANDATORY)

Before writing code, you MUST output:

# Implementation Plan (Local)

## Goal
...

## Requirement understanding
Summarize what the system must do.

## Acceptance criteria
- list explicitly

## Contract expectations (MANDATORY)

Identify expected:

- endpoints (if applicable)
- response fields
- DB writes/reads
- state transitions
- side effects (jobs, logs, etc.)

## Likely code areas
...

## Dependencies
...

## Out of scope
...

## Known uncertainty
...

---

## Step 4: Clarification gate

If ANY of the following are true:

- acceptance criteria are unclear
- required behavior is ambiguous
- dependencies are unknown
- requirements conflict
- scope is too large

→ STOP
→ ask questions or recommend planning

Otherwise:
→ proceed

---

## Step 5: Implement

### Core rules

- implement ONLY what the ticket requires
- follow existing patterns
- avoid unrelated refactoring
- prefer smallest correct change

---

### CONTRACT COMPLETENESS (MANDATORY)

Ensure implementation includes:

- required endpoints exist
- required fields are returned
- required DB writes happen
- required state transitions occur

---

### FAILURE SAFETY (MANDATORY)

Ensure:

- no silent partial success
- no inconsistent state on failure
- error paths are handled explicitly

---

### QUERY / SQL VALIDATION (MANDATORY)

For any new or modified query:

- selected fields exist in schema
- aliases match usage
- field names match consuming code
- no obvious runtime mismatch

---

### TESTING

- add/update tests where relevant
- run basic compile/lint/test
- note gaps explicitly if not covered

---

## Step 6: Persist Builder artifacts

### 00-work-dossier.md

Must contain:
- ticket ID
- summary
- phase
- constraints
- selected skill
- scope decision
- known uncertainty

---

### 10-builder.md (FULL ARTIFACT)

MUST include:

- Builder Routing
- Scope Summary (Epic/Story)
- Implementation Plan
- Implementation Summary
- Contract coverage
- Known uncertainty

This must be detailed enough for downstream agents without chat history.

---

### 11-builder-summary.json

```json
{
  "ticket": "",
  "phase": "implementation",
  "selected_skill": "implement-jira-ticket",
  "branch": "",
  "base_branch": "main",
  "files_changed": [],
  "tests_run": [],
  "contract_coverage": {
    "endpoints": [],
    "fields": [],
    "behaviors": []
  },
  "known_uncertainties": []
}