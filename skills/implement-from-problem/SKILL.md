---
name: implement-from-problem
description: Use when the user wants implementation but the input is not a Jira ticket — pasted problem, bug description, logs, or a reviewed plan ready to execute
argument-hint: [context:<name>] <problem description, bug report, logs, or reviewed plan>
---

# Implement From Problem

Use this skill when the user wants implementation but the input is not primarily a Jira ticket.
Examples:
- pasted problem statement
- bug description
- logs and symptoms
- reviewed plan that is ready to execute

Your job is to turn the provided problem or design into a concrete implementation.

You are operating in the Builder role (implementation phase).

---

# CONTEXT SELECTION POLICY (MANDATORY)

This skill supports an inline context selector:

`context:<name>`

Examples:
- `/implement-from-problem context:nav-null fix the null navigation bug`
- `/implement-from-problem context:RUS-2458 implement the fix from the reviewed plan`

You MUST resolve context using this exact order:

## 1. Explicit context
If a `context:<name>` token is present in the request:
- extract `<name>`
- use review directory: `.claude/reviews/<name>/`
- treat that token as workflow metadata, not part of the problem text

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
If no explicit or worktree context exists, but a clear ticket ID is present in the request:
- use that ticket ID as context
- use review directory: `.claude/reviews/<ticket>/`

## 4. Single existing review directory
If no explicit context, worktree context, or ticket exists, and exactly one review directory exists under `.claude/reviews/`:
- you MAY infer that directory as context

## 5. Default
If none of the above apply:
- use context: `ad-hoc`
- use review directory: `.claude/reviews/ad-hoc/`

If multiple review directories exist and no explicit or worktree context is provided:
- do NOT silently choose one at random
- default to `ad-hoc`
- explicitly warn that multiple directories existed and the fallback may be incorrect

You MUST explicitly state whether context was:
- explicit
- inferred from worktree branch
- inferred from ticket
- inferred from single existing directory
- defaulted to ad-hoc

---

# REQUIRED FIRST STRUCTURED OUTPUT

Before writing any code, you MUST output:

# Builder Routing

## Phase
implementation

## Selected Skill
implement-from-problem

## Context
<context name>

## Context resolution
explicit | inferred from worktree branch | inferred from ticket | inferred from single existing directory | defaulted to ad-hoc

## Reason
The user wants implementation from a problem description / reviewed plan.

Do not skip this section.

---

# BUILDER FLOW INTEGRATION (MANDATORY)

This skill operates as a Builder in the standard review flow:

```
implement-from-problem (Builder) → challenge-artifact (Critic) → resolve-disagreement (Arbiter)
```

The implementation artifact (`10-builder.md`) MUST be persisted to the review directory so that downstream review skills can consume it without chat history.

Artifact creation is UNCONDITIONAL — every implementation produces artifacts.

---

# REVIEW DIRECTORY

Use:

`.claude/reviews/<context>/`

You SHOULD read when available:
- `00-work-dossier.md`
- `10-builder.md`
- `20-critic.md`
- `30-context.md`
- `40-arbiter.md`
- `50-revision-request.md`

You MUST ALWAYS persist:
- `00-work-dossier.md`
- `10-builder.md`
- `11-builder-summary.json`
- `12-builder-diff.patch`
- `13-builder-tests.txt`

---

# PROCESS

## Step 1: Understand the problem

If a prior investigation or analysis exists in the review directory (`10-builder.md`, `40-arbiter.md`, `50-revision-request.md`), read and incorporate it.

Summarize:
- what needs to change
- why it needs to change
- what the expected outcome is

## Step 2: Implementation Plan (Local)

Before writing code, output:

# Implementation Plan (Local)

## Goal
...

## Requirement understanding
...

## Likely code areas
...

## Dependencies
...

## Assumptions
...

## Out of scope
...

---

## Step 3: Implement

### Core rules
- implement ONLY what the problem requires
- follow existing patterns
- avoid unrelated refactoring
- prefer smallest correct change

### Testing
- add/update tests where relevant
- run basic compile/lint/test
- note gaps explicitly

---

## Step 4: Persist Artifacts

You MUST write artifacts to the review directory. This is unconditional.

---

# OUTPUT FORMAT

# Implementation Summary

## Goal
...

## Inputs used
- ...

## Assumptions
- ...

## What was done
- ...

## Files changed
- ...

## Tests
- ...

## Remaining uncertainty
- ...

## Follow-up needed
- ...

## Persistence
- Context used:
- Context resolution:
- Directory used:
- Files written:

---

# PERSISTENCE RULES

You MUST write:

## `00-work-dossier.md`
Include:
- context
- context resolution method
- source type: problem-implementation
- task phase: implementation
- user goal
- what was implemented
- known uncertainty
- recommended next phase (default: `challenge-artifact` for review)

## `10-builder.md`
Must contain the full implementation artifact:
- implementation plan
- what was changed and why
- contract coverage (endpoints, fields, behaviors)
- enough detail for Critic to review without chat history

## `11-builder-summary.json`
```json
{
  "context": "",
  "phase": "implementation",
  "selected_skill": "implement-from-problem",
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
```

## `12-builder-diff.patch`
Output of `git diff` for the changes made.

## `13-builder-tests.txt`
Output of test run results.

---

# RULES

- Do not skip artifact creation
- Do not overfit to partial data
- Prefer smallest correct change
- Follow existing patterns
- Ensure artifacts are complete enough for downstream Critic review
