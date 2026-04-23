---
name: analyze-problem
description: Use when the user wants to understand a problem, anomaly, bug, failure, or confusing behavior — before any solution or fix is proposed.
argument-hint: [context:<name>] <problem description>
---

# Analyze Problem

Use this skill when the user wants to understand a problem, anomaly, bug, failure, or confusing behavior.

Your job is to produce a high-quality, auditable analysis artifact:
a structured root-cause hypothesis set grounded in evidence.

You are operating in the Builder role (analysis phase).

---

# CONTEXT SELECTION POLICY (MANDATORY)

This skill supports an inline context selector:

`context:<name>`

Examples:
- `/analyze-problem context:ad-hoc-nav-null investigate why nav is null`
- `/analyze-problem context:RUS-2458 analyze why support_status stays unsupported`

You MUST resolve context using this exact order:

## 1. Explicit context
If a `context:<name>` token is present in the request:
- extract `<name>`
- use review directory:
  `.claude/reviews/<name>/`
- treat that token as workflow metadata, not part of the problem text

## 2. Ticket-derived context
If no explicit context exists, but a clear ticket ID is present in the request:
- use that ticket ID as context
- use review directory:
  `.claude/reviews/<ticket>/`

## 3. Single existing review directory
If no explicit context or ticket exists, and exactly one review directory exists under:
- `.claude/reviews/`

then you MAY infer that directory as context.

## 4. Default
If none of the above apply:
- use context:
  `ad-hoc`
- use review directory:
  `.claude/reviews/ad-hoc/`

If multiple review directories exist and no explicit context is provided:
- do NOT silently choose one at random
- default to `ad-hoc`
- explicitly warn that multiple directories existed and the fallback may be incorrect

You MUST explicitly state whether context was:
- explicit
- inferred from ticket
- inferred from single existing directory
- defaulted to ad-hoc

---

# REQUIRED FIRST STRUCTURED OUTPUT

Before presenting any conclusions or analysis sections, you MUST output:

# Builder Routing

## Phase
analysis

## Selected Skill
analyze-problem

## Context
<context name>

## Context resolution
explicit | inferred from ticket | inferred from single existing directory | defaulted to ad-hoc

## Reason
The request is asking for problem understanding, root-cause analysis, or explanation before any solution.

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

You MUST persist substantial analysis to:
- `00-work-dossier.md`
- `10-builder.md`

Substantial analysis means the output includes any of:
- multiple observations
- hypotheses
- system reasoning
- a recommended next step

---

# GOALS

- reconstruct what the problem actually is
- distinguish observations from explanations
- identify plausible root causes
- identify what evidence supports each cause
- identify what is still unproven
- identify contradictions and unresolved signals
- determine what is blocked and why
- recommend the correct next phase

---

# PROCESS

## 1. Restate the problem precisely

Clarify:
- what is expected
- what is actually happening
- what is unclear

---

## 2. Extract observations (STRICT)

Extract only directly observable data from:
- user input
- API responses
- logs
- code
- database state
- system behavior
- tickets or artifacts

---

## 3. Separate evidence types (MANDATORY)

You MUST separate:

### Facts
Directly observed

### Inferences
Derived from facts

### Assumptions
Unproven / inferred without direct evidence

---

## 4. Validate internal consistency (MANDATORY)

You MUST:
- identify contradictions
- identify mismatched signals
- identify unexpected combinations

Do NOT resolve contradictions by assumption.

---

## 5. Detect gating conditions (MANDATORY)

Check for:
- status fields
- filters
- eligibility conditions
- background jobs
- required transitions
- dependent processes

Explain what is blocked and why.

---

## 6. Handle incomplete or truncated input (CRITICAL)

If input is:
- truncated
- missing fields
- partially visible
- ambiguous

You MUST:
- treat unknown fields as UNKNOWN
- avoid optimistic assumptions
- explicitly list unknown but load-bearing data

You MUST NOT:
- infer healthy state from partial evidence
- draw structural conclusions that depend on missing data without labeling them as hypotheses

---

## 7. Build root cause hypotheses

For each hypothesis:
- explanation
- supporting evidence
- conflicting evidence
- confidence level

Confidence must be one of:
- confirmed
- likely
- weak

---

## 8. System-level reasoning

Explain:
- why the system behaves this way
- what downstream processes are blocked
- what conditions were not satisfied

---

## 9. Identify missing evidence

List what would confirm or reject hypotheses.

---

## 10. Recommend next step

One of:
- design-solution
- implement-from-problem
- draft-jira-ticket
- draft-implementation-plan
- gather-more-evidence

---

# CRITICAL ANALYSIS RULES

You MUST:
- explicitly distinguish facts vs inferences vs assumptions
- identify contradictions clearly
- treat missing data as UNKNOWN, not “likely”
- analyze gating conditions
- explain system behavior, not just describe it
- downgrade confidence when evidence is incomplete

You MUST NOT:
- jump to implementation
- assume system is correct
- infer missing fields optimistically
- present speculation as fact
- conclude “healthy” without full evidence

If a conclusion depends on missing data:
→ move it to hypothesis or missing evidence

---

# OUTPUT FORMAT

# Problem Analysis

## Problem statement
...

---

## Observations
- ...

---

## Facts vs inference

### Facts
- ...

### Inferences
- ...

### Assumptions
- ...

---

## Consistency checks

### Contradictions / unresolved signals
- ...

### Unknown but load-bearing fields
- ...

---

## Root cause hypotheses

### Hypothesis 1
- Explanation:
- Supporting evidence:
- Conflicting evidence:
- Confidence: confirmed | likely | weak

### Hypothesis 2
...

---

## System-level explanation

Explain:
- gating conditions
- blocked flows
- why system produced this outcome

---

## Missing evidence
- ...

---

## Recommended next step
...

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

## `00-work-dossier.md`
Include:
- context
- context resolution method
- source type
- task phase
- user goal
- notable missing evidence
- recommended next phase

## `10-builder.md`
Must contain the full analysis artifact.

---

# RULES

- Do not jump to a fix
- Do not overfit to partial data
- Prefer uncertainty over incorrect clarity
- Prefer explicit reasoning over implicit assumptions
- Ensure the output is auditable and reusable by Critic and Context Checker