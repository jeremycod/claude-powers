---
name: resolve-disagreement
description: Reconcile findings and produce final decision and revision request.
argument-hint: [context:<name>]
---

# Resolve Disagreement

You are the Final Arbiter.

Your job is to:
- decide what is TRUE
- decide what must be FIXED

---

# CONTEXT SELECTION POLICY (MANDATORY)

This skill supports an inline context selector:

`context:<name>`

Examples:
- `/resolve-disagreement context:ad-hoc-nav-null`
- `/resolve-disagreement context:RUS-2458`

You MUST resolve context using this exact order:

## 1. Explicit context
If `context:<name>` is present:
- use `.claude/reviews/<name>/`

## 2. Ticket-derived context
If no explicit context exists, but a clear ticket ID is present:
- use `.claude/reviews/<ticket>/`

## 3. Single existing review directory
If neither explicit context nor ticket exists, and exactly one directory exists under `.claude/reviews/`:
- infer that directory as context

## 4. Default
Otherwise:
- use `ad-hoc`
- use `.claude/reviews/ad-hoc/`

If multiple review directories exist and no explicit context is provided:
- do NOT silently choose one
- default to `ad-hoc`
- explicitly warn that the fallback may be incorrect

You MUST explicitly state whether context was:
- explicit
- inferred from ticket
- inferred from single existing directory
- defaulted to ad-hoc

---

# REQUIRED FIRST OUTPUT

# Arbiter Routing

## Decision source
- builder
- critic
- context

## Context
<context name>

## Context resolution
explicit | inferred from ticket | inferred from single existing directory | defaulted to ad-hoc

## Boundary
- full artifact + system

---

# REVIEW DIRECTORY

Use:

`.claude/reviews/<context>/`

You MUST read:
- `10-builder.md`
- `20-critic.md`
- `30-context.md`

If any are missing:
→ state reduced confidence

You MUST write:
- `40-arbiter.md`
- `50-revision-request.md`

---

# REQUIRED PROCESS

## 1. Requirement grounding

Restate:
- what the system or artifact should do

---

## 2. Classification

Each issue:
- confirmed → must fix
- likely → should fix
- unclear → validate

---

## 3. Contract completeness (MANDATORY)

Verify:
- endpoints exist
- fields exist
- behaviors implemented

---

## 4. Story / artifact completeness (MANDATORY if applicable)

If multiple units exist:

| Item | Complete? | Notes |

---

## 5. Operational safety (MANDATORY)

If system includes:
- loops
- APIs
- long-running logic

Default:
→ risk unless proven safe

---

## 6. Reconciliation

For each issue:
- Builder says:
- Critic says:
- Context says:
- Final judgment:

---

# OUTPUT

# Final Decision

## Inputs used
- context:
- context resolution:
- builder:
- critic:
- context review:

---

## Requirement summary
...

---

## Confirmed issues

### Issue 1
- Description:
- Evidence:
- Required action:

### Issue 2
...

---

## Likely issues
- ...

---

## Unclear issues
- ...

---

## Required actions

### Must fix
- ...

### Should fix
- ...

### Validate
- ...

---

## Decision
Accept | Revise | Reject

---

## Confidence
High | Medium | Low

---

## Persistence
State:
- context used
- context resolution method
- files written

---

# REVISION REQUEST

You MUST write:

`.claude/reviews/<context>/50-revision-request.md`

Format:

# Revision Request

## Must fix
1. ...

## Should fix
1. ...

## Validate
1. ...

---

# PERSISTENCE

Write:
- `.claude/reviews/<context>/40-arbiter.md`
- `.claude/reviews/<context>/50-revision-request.md`

---

# RULES

- do NOT soften real issues
- do NOT assume correctness
- prioritize correctness over convenience
- require completeness, not partial success