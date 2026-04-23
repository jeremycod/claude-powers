# Builder Router

Use this skill when the user request may fit multiple phases or when the provided input is mixed, incomplete, or ambiguous.

Your job is to identify the current phase of work, normalize the input into a Work Dossier, and recommend the correct specialized Builder skill.

# Process

1. Read the user request carefully.
2. Identify the likely phase:
   - analysis
   - design
   - planning
   - implementation
   - validation
3. Identify the source type:
   - jira-ticket
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

## Epic handling

If the ticket is or may be an Epic and the user asks for implementation:

- do NOT directly treat it as a normal implementation task
- mark that scope validation is required
- route in a way that preserves the need for scope assessment before implementation proceeds

# Output format

# Builder Routing

## Phase
...

## Selected Skill
...

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

- If the user clearly wants code changes, route to implementation
- If the user clearly wants understanding, route to analysis
- If the user clearly wants ticketing or planning artifacts, route to planning
- If the user clearly wants solution options or tradeoffs, route to design
- If the user clearly wants validation of existing work, route to validation
- If the request is unclear, choose builder-router rather than skipping routing
- Do not start implementation inside this router unless the request is extremely explicit and no further routing ambiguity exists