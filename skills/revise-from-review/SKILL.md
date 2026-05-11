---
name: revise-from-review
description: Use when Builder must revise the current artifact based on Critic, Context Checker, and Final Arbiter outputs.
argument-hint: [context:<name>]
---

# Revise From Review

You are the Builder.

Your job is to revise the current artifact using the Final Arbiter’s revision request.

---

# CONTEXT SELECTION POLICY (MANDATORY)

This skill supports an inline context selector:

`context:<name>`

Examples:
- `/revise-from-review context:ad-hoc-nav-null`
- `/revise-from-review context:RUS-2458`

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

# Builder Routing

## Phase
revision

## Selected Skill
revise-from-review

## Context
<context name>

## Context resolution
explicit | inferred from worktree branch | inferred from ticket | inferred from single existing directory | defaulted to ad-hoc

## Reason
The current artifact must be revised based on prior review outputs.

---

# REVIEW DIRECTORY

Use:

`.claude/reviews/<context>/`

You MUST read when available:
- `00-work-dossier.md`
- `10-builder.md`
- `20-critic.md`
- `30-context.md`
- `40-arbiter.md`
- `50-revision-request.md`
- `12-builder-diff.patch`
- `13-builder-tests.txt`

You MUST update:
- `10-builder.md`
- `11-builder-summary.json` (if present or relevant)
- `12-builder-diff.patch` (if code changes)
- `13-builder-tests.txt` (if validation is run)

---

# PRIMARY REVISION CONTRACT

If `50-revision-request.md` exists, it is the PRIMARY revision contract.

Interpret:
- Must fix → required
- Should fix → address if clearly relevant and low-risk, or explain deferral
- Validate → test/check/note; do not blindly expand scope

If `50-revision-request.md` does not exist:
- derive from `40-arbiter.md`
- then `20-critic.md`
- then `30-context.md`

---

# REQUIRED BEHAVIOR

You must:
- identify required revision scope
- separate must-fix vs should-fix vs validate
- revise only the current artifact
- keep the work scoped

You must NOT:
- ignore confirmed issues
- expand scope into unrelated work
- silently skip required actions

---

# REVISION PLAN

Before making changes, you MUST output:

# Revision Plan

## Inputs used
- ...

## Must address now
- ...

## Should address
- ...

## Validate only
- ...

## Scope guard
What is explicitly out of scope for this pass.

---

# OUTPUT

# Revised Artifact Summary

## Context
<context name>

## Context resolution
explicit | inferred from worktree branch | inferred from ticket | inferred from single existing directory | defaulted to ad-hoc

## Findings addressed
- ...

## Changes made
- ...

## Files changed
- ...

## Tests / validation run
- ...

## Findings deferred
- ...

## Remaining uncertainty
- ...

## Recommended next step
- return to Critic
- return to Context Checker
- return to Arbiter
- accept if no further review needed

---

## Persistence
State:
- context used
- files updated

---

# PERSISTENCE

You MUST update Builder artifacts in:

`.claude/reviews/<context>/`

At minimum:
- `10-builder.md`

If relevant:
- `11-builder-summary.json`
- `12-builder-diff.patch`
- `13-builder-tests.txt`

---

# RULES

- `50-revision-request.md` is primary when present
- must-fix items may not be ignored
- should-fix items may be deferred only with explanation
- keep the revision auditable and scoped