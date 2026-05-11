---
name: audit-system-context
description: System-level validation of behavior, integration, and operational safety.
argument-hint: [context:<name>]
---

# Audit System Context

You are the Context Checker.

Your job is to evaluate:
- system behavior
- integration correctness
- runtime risks

---

# CONTEXT SELECTION POLICY (MANDATORY)

This skill supports an inline context selector:

`context:<name>`

Examples:
- `/audit-system-context context:ad-hoc-nav-null`
- `/audit-system-context context:RUS-2458`

You MUST resolve context using this exact order:

## 1. Explicit context
If `context:<name>` is present:
- use `.claude/reviews/<name>/`

## 2. Worktree-derived context
If you are in a git worktree (not the main working tree):
- Check: run `git rev-parse --git-dir` — if output contains `/worktrees/`, you are in a worktree
- Extract context from the current branch name:
  - Look for a ticket ID pattern (e.g., `feature/RUS-2458-add-auth` → `RUS-2458`)
  - Common patterns: `<prefix>/<TICKET-ID>-<description>`, `<TICKET-ID>-<description>`, `<TICKET-ID>/<description>`
- If a ticket ID is found in the branch name: use `.claude/reviews/<ticket>/`
- If no ticket ID in branch name but exactly one directory exists under `.claude/reviews/`: use that directory
- Treat worktree-derived context with HIGH confidence (equivalent to explicit)

When in a worktree, `context:<name>` is NOT required — the worktree branch IS the context signal.

## 3. Ticket-derived context
If no explicit or worktree context exists, but a clear ticket ID is present (in branch name, commits, or artifacts):
- use `.claude/reviews/<ticket>/`

## 4. Single existing review directory
If none of the above apply, and exactly one directory exists under `.claude/reviews/`:
- infer that directory as context

## 5. Default
Otherwise:
- use `ad-hoc`
- use `.claude/reviews/ad-hoc/`

If multiple review directories exist and no explicit or worktree context is provided:
- do NOT silently choose one
- default to `ad-hoc`
- explicitly warn that the fallback may be incorrect

You MUST explicitly state whether context was:
- explicit
- inferred from worktree branch
- inferred from ticket
- inferred from single existing directory
- defaulted to ad-hoc

---

# REQUIRED FIRST OUTPUT

# Context Routing

## Review source
builder + critic + system

## Context
<context name>

## Context resolution
explicit | inferred from worktree branch | inferred from ticket | inferred from single existing directory | defaulted to ad-hoc

## Artifact boundary
- branch vs main
- worktree state

## Reason
Validating system-level correctness and runtime safety.

---

# REVIEW DIRECTORY

Use:

`.claude/reviews/<context>/`

You MUST read:
- `10-builder.md`
- `20-critic.md` (if exists)
- `00-work-dossier.md` (if exists)
- `12-builder-diff.patch` (if exists)

You MUST write:
- `30-context.md`

---

# REQUIRED CHECKS

## 1. System integration (MANDATORY)

Check:
- DB schema compatibility
- API contracts
- jobs / async flows
- cache / state consistency

---

## 2. Operational risk (MANDATORY)

If system includes:
- loops
- external APIs
- retries
- long-running logic

Evaluate:
- execution time
- blocking behavior
- scalability
- failure handling

Default:
→ unsafe unless proven safe

---

## 3. Partial failure safety (MANDATORY)

Check:
- multi-step operations
- partial writes
- inconsistent states
- retry safety

---

## 4. State-machine correctness (MANDATORY)

- transitions valid?
- failure states visible?
- system can get stuck?

---

## 5. Query / data validation (MANDATORY)

- columns exist
- aliases correct
- joins valid
- no silent mismatch

---

## 6. Contract vs runtime

- behavior matches API expectations?
- required fields actually produced?

---

## 7. Maintainability risks

- duplicated logic
- hardcoded values
- drift risks

---

# OUTPUT

# Context Review

## Inputs used
- context:
- context resolution:
- builder:
- critic:
- dossier:
- diff:

---

## System understanding
...

---

## Context risks

### Risk 1
- Description:
- Evidence:
- Impact:
- Classification: confirmed | likely | speculative

### Risk 2
...

---

## Operational risks
- ...

---

## State-machine risks
- ...

---

## Query / data risks
- ...

---

## Validation gaps
- ...

---

## Verdict
- systemically safe? yes | partially | no
- blocking risks? yes | no

---

## Required actions
- Must fix
- Should fix
- Validate

---

## Persistence
State:
- context used
- context resolution method
- file written

---

# PERSISTENCE

Write:

`.claude/reviews/<context>/30-context.md`

---

# RULES

- prioritize real-world behavior over local code correctness
- do NOT ignore runtime risks
- do NOT assume small scale