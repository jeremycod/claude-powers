---
name: design-solution
description: Use when the problem is understood and the next task is to propose how to solve it — tradeoffs, options comparison, and recommended approach.
argument-hint: [context:<name>] <problem or design prompt>
---

# Design Solution

Use this skill when the problem is understood enough that the next task is to propose how to solve it.

Your job is to produce a high-quality, auditable solution proposal with tradeoffs, risks, and a recommended approach.

You are operating in the Builder role (design phase).

---

# CONTEXT SELECTION POLICY (MANDATORY)

This skill supports an inline context selector:

`context:<name>`

Examples:
- `/design-solution context:ad-hoc-nav-null propose how to fix the null NAV pipeline`
- `/design-solution context:RUS-2458 propose the safest registration strategy`

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

Before presenting any design conclusions, you MUST output:

# Builder Routing

## Phase
design

## Selected Skill
design-solution

## Context
<context name>

## Context resolution
explicit | inferred from ticket | inferred from single existing directory | defaulted to ad-hoc

## Reason
The problem appears sufficiently understood and the next task is to propose how to solve it.

Do not skip this section.

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

You MUST persist substantial design work to:
- `10-builder.md`

You SHOULD update:
- `00-work-dossier.md`

Substantial design work means the output includes any of:
- target behavior definition
- multiple options
- tradeoff analysis
- recommended approach
- implementation implications

---

# GOALS

- define the target behavior
- propose one or more solution options
- compare them
- recommend the best fit
- identify implementation implications
- identify operational and system impact
- identify migration / rollout concerns
- distinguish decisions from open questions

---

# PROCESS

## 1. Summarize the problem being solved

Clarify:
- what is broken, missing, or unclear
- what target outcome is desired
- what constraints are already known

If the problem is still too unclear for design:
→ say so explicitly
→ recommend `gather-more-evidence` or `analyze-problem`

---

## 2. Define success conditions (MANDATORY)

Define what success looks like in concrete terms.

Include where relevant:
- user-visible behavior
- backend/API behavior
- state transitions
- data correctness
- operational behavior
- validation expectations

Do NOT keep success conditions vague.

---

## 3. Identify constraints and assumptions

Separate clearly:

### Constraints
Known limits, requirements, invariants, compatibility needs

### Assumptions
Things believed true but not yet proven

If a recommendation depends on an assumption:
→ call that out explicitly

---

## 4. Propose solution options

You SHOULD propose at least two options when meaningful.

Each option must be materially distinct, not a trivial variation.

For each option, assess:

- correctness
- complexity
- risk
- blast radius
- compatibility with existing patterns
- operational implications
- migration / rollout implications
- observability / debuggability

If only one realistic option exists:
→ say why alternatives are not viable

---

## 5. Compare options directly (MANDATORY)

Do not just list pros/cons independently.

You MUST compare options on the dimensions that matter most for this problem, such as:
- correctness
- implementation effort
- production safety
- reversibility
- maintainability
- user impact
- system coupling

---

## 6. Recommend one option

State clearly:
- which option is preferred
- why it is preferred
- what tradeoffs are accepted

If the recommendation is conditional:
→ state the condition explicitly

---

## 7. Describe implementation implications

Without writing code unless asked, explain:
- what areas would need to change
- what data / API / UI / job / workflow implications exist
- whether rollout should be incremental
- whether migration or backfill is needed
- whether new tests / monitoring would be needed

---

## 8. Identify open questions

List:
- unresolved decisions
- missing evidence
- product questions
- validation needed before implementation

Do NOT hide uncertainty.

---

## 9. Recommend next step

One of:
- `draft-jira-ticket`
- `draft-implementation-plan`
- `implement-from-problem`
- `gather-more-evidence`

---

# CRITICAL DESIGN RULES

You MUST:

- define target behavior clearly
- separate constraints from assumptions
- compare options, not just enumerate them
- call out system impact and blast radius
- call out migration / rollout implications when relevant
- prefer the smallest correct solution that fits the system
- explicitly identify what could go wrong operationally

You MUST NOT:

- jump straight into code unless explicitly asked
- pretend uncertainty does not exist
- recommend a solution without explaining tradeoffs
- overfit to a local fix if the problem is systemic
- assume implementation details are trivial

If the best option depends on missing evidence:
→ say so
→ recommend validation before implementation

---

# OUTPUT FORMAT

# Solution Design

## Problem summary
...

---

## Context
- context:
- context resolution:
- artifacts used:

---

## Success conditions
- ...

---

## Constraints
- ...

---

## Assumptions
- ...

---

## Options considered

### Option 1
- Approach:
- Pros:
- Cons:
- Risks:
- Blast radius:
- Compatibility with existing patterns:
- Operational implications:
- Migration / rollout implications:

### Option 2
- Approach:
- Pros:
- Cons:
- Risks:
- Blast radius:
- Compatibility with existing patterns:
- Operational implications:
- Migration / rollout implications:

### Option 3
...

---

## Comparison summary
- correctness:
- complexity:
- risk:
- reversibility:
- maintainability:
- system impact:

---

## Recommended approach
...

---

## Why this is preferred
...

---

## Implementation implications
- ...

---

## Open questions
- ...

---

## Recommended next step
One of:
- draft-jira-ticket
- draft-implementation-plan
- implement-from-problem
- gather-more-evidence

---

## Persistence
State:
- context used
- context resolution method
- directory used
- files written

---

# PERSISTENCE RULES

You MUST write:

## `10-builder.md`
Must contain the full design artifact.

You SHOULD update:

## `00-work-dossier.md`
Include or update:
- context
- context resolution method
- task phase = design
- user goal
- constraints
- notable open questions
- recommended next phase

---

# RULES

- Do not write code unless explicitly asked
- Prefer the smallest correct approach that fits the system
- Call out uncertainty and system impact
- Ensure the output is auditable and reusable by later Critic / Context / Arbiter steps