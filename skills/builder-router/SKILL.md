# Builder Router

Use this skill when the user request may fit multiple phases or when the provided input is mixed, incomplete, or ambiguous.

Your job is to identify the current phase of work, normalize the input into a Work Dossier, and recommend the correct specialized Builder skill.

# Process

1. Read the user request carefully.
2. Identify the likely phase:
   - investigation
   - analysis
   - design
   - planning
   - implementation
   - validation
3. Identify the source type:
   - jira-ticket
   - symptom-report
   - pasted-problem
   - bug-report
   - logs-or-errors
   - diff-or-pr
   - implementation-summary
   - mixed
4. Build the Work Dossier.
5. Select the next Builder skill.
6. Do not perform deep work beyond routing unless the request is already unambiguous and trivial.

# Special handling rules

## Jira ticket handling

If the request references a Jira ticket:

- classify whether the user wants:
  - analysis
  - planning
  - implementation
  - validation

Do NOT assume implementation just because a Jira ticket exists.

## Symptom / live-problem handling

If the request describes a live symptom (broken endpoint, wrong data, error messages, UI misbehavior, performance issue) and the user wants investigation:

- classify as phase: investigation
- classify as source type: symptom-report
- route to: `investigate-problem`

Do NOT route to `analyze-problem` when the user expects active investigation (scanning code, querying databases, checking logs). Use `analyze-problem` only when the user has already collected evidence and wants reasoning.

## Epic handling

If the ticket is or may be an Epic and the user asks for implementation:

- do NOT directly treat it as a normal implementation task
- mark that scope validation is required
- route in a way that preserves the need for scope assessment before implementation proceeds

# CONTEXT DETECTION (MANDATORY)

Before routing, determine context:

## Worktree detection
If you are in a git worktree (not the main working tree):
- Check: run `git rev-parse --git-dir` — if output contains `/worktrees/`, you are in a worktree
- Extract context from the current branch name:
  - Look for a ticket ID pattern (e.g., `feature/RUS-2458-add-auth` → `RUS-2458`)
  - Common patterns: `<prefix>/<TICKET-ID>-<description>`, `<TICKET-ID>-<description>`, `<TICKET-ID>/<description>`
- If a ticket ID is found: that IS the context — pass it to the selected skill
- When in a worktree, `context:<name>` is NOT required from the user

## Context resolution order
1. Explicit `context:<name>` in user request
2. Worktree branch name → ticket ID
3. Ticket ID mentioned in request
4. Single existing `.claude/reviews/` directory
5. Default: `ad-hoc`

Include the resolved context in the output format below.

---

# Output format

# Builder Routing

## Phase
...

## Selected Skill
...

## Context
<resolved context name>

## Context resolution
explicit | inferred from worktree branch | inferred from ticket | inferred from single existing directory | defaulted to ad-hoc

## Reason
...

# Work Dossier

## Task phase
...

## Source type
...

## User goal
...

## Inputs provided
- ...

## Known constraints
- ...

## Missing information
- ...

## Selected skill
...

## Why this skill
...

## Special notes
- ...

# Rules

- If the user reports a live symptom and wants active investigation, route to investigation (investigate-problem)
- If the user clearly wants code changes, route to implementation
- If the user clearly wants understanding of already-collected evidence, route to analysis
- If the user clearly wants ticketing or planning artifacts, route to planning
- If the user clearly wants solution options or tradeoffs, route to design
- If the user clearly wants validation of existing work, route to validation
- If the request is unclear, choose builder-router rather than skipping routing
- Do not start implementation inside this router unless the request is extremely explicit and no further routing ambiguity exists