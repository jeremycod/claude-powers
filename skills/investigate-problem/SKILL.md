---
name: investigate-problem
description: Use when the user reports a symptom (broken endpoint, incorrect result, screenshot of wrong behavior, error description) and wants active investigation across codebase, database, logs, and observability tools to identify root causes and propose next actions.
argument-hint: [context:<name>] <symptom — endpoint, error, screenshot, description of wrong behavior>
---

# Investigate Problem

Use this skill when the user reports a live symptom and wants active investigation.

Examples of valid inputs:
- endpoint URL + "returns wrong data"
- screenshot of broken UI
- "users report intermittent 500s on /api/orders"
- error message or stack trace
- "this field shows X but should show Y"
- description of unexpected application behavior

Your job is to **actively investigate** — scan codebase, query databases, check logs and metrics, hit endpoints, consult Engram memory — then synthesize findings and present the user with ranked hypotheses and proposed next actions.

You are operating in the Builder role (investigation phase).

---

# DISTINCTION FROM `analyze-problem`

`analyze-problem` is a passive reasoner — it takes evidence the user has already collected and builds hypotheses from it.

This skill is an active investigator — it takes a symptom and goes out to gather evidence itself, then reasons about what it found.

Do NOT confuse the two. If the user has already collected evidence and wants reasoning, use `analyze-problem`. If the user has a symptom and wants you to investigate, use this skill.

---

# CONTEXT SELECTION POLICY (MANDATORY)

This skill supports an inline context selector:

`context:<name>`

Examples:
- `/investigate-problem context:orders-500 users report 500 errors on /api/orders`
- `/investigate-problem context:RUS-2458 the registration flow shows wrong status`

You MUST resolve context using this exact order:

## 1. Explicit context
If a `context:<name>` token is present in the request:
- extract `<name>`
- use review directory: `.claude/reviews/<name>/`
- treat that token as workflow metadata, not part of the problem text

## 2. Ticket-derived context
If no explicit context exists, but a clear ticket ID is present in the request:
- use that ticket ID as context
- use review directory: `.claude/reviews/<ticket>/`

## 3. Single existing review directory
If no explicit context or ticket exists, and exactly one review directory exists under `.claude/reviews/`:
- you MAY infer that directory as context

## 4. Default
If none of the above apply:
- use context: `ad-hoc`
- use review directory: `.claude/reviews/ad-hoc/`

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

Before presenting any investigation results, you MUST output:

# Builder Routing

## Phase
investigation

## Selected Skill
investigate-problem

## Context
<context name>

## Context resolution
explicit | inferred from ticket | inferred from single existing directory | defaulted to ad-hoc

## Reason
The user reported a live symptom requiring active investigation.

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

You MUST persist substantial investigation results to:
- `00-work-dossier.md`
- `10-builder.md`

---

# PROCESS

## Phase 1: Input Classification & Problem Framing

Accept any input type:
- URL / endpoint
- screenshot (read and interpret)
- error message / stack trace
- behavioral description
- logs snippet
- combination of the above

Classify the symptom:
- wrong data / incorrect result
- error response (4xx, 5xx)
- UI rendering issue
- performance degradation
- intermittent failure
- unexpected state / behavior

Restate the problem:
- what is expected
- what is actually happening
- what is the scope (which service, endpoint, feature area)

---

## Phase 2: Quick Scan (Sequential)

Perform a lightweight initial scan to orient the investigation. Each step informs the next.

### 2.1 Consult Engram memory
- Call `recall` with a description of the symptom
- Call `get_similar_errors` if the symptom involves errors
- Call `get_context_for` for the relevant service/feature area
- Note any prior incidents, known issues, or team decisions

### 2.2 Identify relevant code area
- Use Grep/Glob to find the relevant endpoint, handler, component, or service
- Use Serena (`find_symbol`, `find_declaration`) if available for precise navigation
- Identify the entry point and key files involved

### 2.3 Check recent changes
- Run `git log` on the relevant files/directories
- Look for recent commits that may have introduced the issue
- Note any relevant PRs or deployments

### 2.4 Determine which deep-dives are needed
Based on findings so far, decide which sources are relevant:
- [ ] Codebase trace (almost always yes)
- [ ] Database state check
- [ ] Logs / observability (Grafana via gcx)
- [ ] Endpoint test (hit the endpoint directly)
- [ ] Engram deep dive (more specific queries)

Not all sources apply to every problem. Skip irrelevant ones explicitly.

---

## Phase 3: Deep Investigation (Parallel where possible)

Dispatch parallel investigations into the relevant sources identified in Phase 2.

### 3.1 Codebase Trace
- Trace the call chain from entry point through business logic
- Check validation, transformations, queries, response construction
- Look for edge cases, missing null checks, incorrect conditionals
- Check configuration, feature flags, environment-specific logic
- Use Serena (`find_referencing_symbols`, `find_implementations`) for deeper navigation

### 3.2 Database Investigation
- Use database MCP tools to check:
  - Schema: `describe_table` for relevant tables
  - Data state: `execute_sql` to query relevant records
  - Sample data: `get_sample_data` for the affected entities
  - Constraints, indexes, relationships
- Look for data inconsistencies, missing records, stale state, constraint violations

### 3.3 Logs & Observability
- Use gcx tools if Grafana is available:
  - Check error rates and latency for the relevant service/endpoint
  - Look for recent anomalies in metrics
  - Search logs for related error messages
- Check application logs if accessible via filesystem

### 3.4 Endpoint Test
- If a URL/endpoint is provided and accessible:
  - Hit the endpoint and observe the actual response
  - Compare with expected behavior
  - Check headers, status codes, response body
  - Try variations (different params, auth states)

### 3.5 Engram Deep Dive
- Based on findings so far, make targeted queries:
  - `batch_recall` for multiple related topics discovered during investigation
  - Check for known architectural decisions that explain the behavior
  - Look for prior resolutions to similar issues

---

## Phase 4: Synthesis & Hypothesis Building

Compile all evidence and build hypotheses.

### 4.1 Evidence compilation
Organize by source:
- Codebase findings
- Database findings
- Log/metric findings
- Endpoint test results
- Engram/historical context

### 4.2 Separate evidence types (MANDATORY)

#### Facts
Directly observed during investigation

#### Inferences
Derived from facts

#### Assumptions
Unproven / inferred without direct evidence

### 4.3 Identify contradictions
- Signals that don't align
- Unexpected combinations
- Things that should be present but aren't

### 4.4 Build root cause hypotheses

For each hypothesis:
- Explanation: what is happening and why
- Supporting evidence: what points to this
- Conflicting evidence: what argues against it
- Confidence: `confirmed` | `likely` | `weak`
- Verification: what would prove or disprove this

Rank hypotheses by confidence.

---

## Phase 5: Present Findings & Proposed Actions (CONSULTATIVE)

Present the investigation results clearly, then offer the user a choice of next actions.

### Action menu (present ALL applicable options):

1. **Fix directly** — if root cause is clear and fix is straightforward
   → routes to `implement-from-problem`
   → state what the fix would be

2. **Create implementation ticket** — if root cause is clear but fix is non-trivial
   → routes to `draft-jira-ticket`
   → state the scope

3. **Create investigation ticket** — if hypothesis needs validation by another team/person
   → routes to `draft-jira-ticket`
   → state what needs investigation and by whom

4. **Design solution** — if the problem requires architectural consideration
   → routes to `design-solution`
   → state why design is needed

5. **Gather more evidence** — if investigation is inconclusive
   → state specifically what to check next and how
   → suggest what access/tools/people are needed

Ask the user which action to take. Do NOT proceed without user confirmation.

---

# OUTPUT FORMAT

# Investigation Results

## Problem statement
- Reported symptom:
- Expected behavior:
- Actual behavior:
- Scope:

---

## Sources investigated
- [ ] Engram memory
- [ ] Codebase (files/areas)
- [ ] Git history
- [ ] Database
- [ ] Logs / Observability
- [ ] Endpoint test
- (mark which were checked and which were skipped with reason)

---

## Evidence collected

### From codebase
- ...

### From database
- ...

### From logs / observability
- ...

### From endpoint test
- ...

### From Engram / historical context
- ...

---

## Evidence classification

### Facts
- ...

### Inferences
- ...

### Assumptions
- ...

---

## Contradictions / unresolved signals
- ...

---

## Root cause hypotheses

### Hypothesis 1 (highest confidence)
- Explanation:
- Supporting evidence:
- Conflicting evidence:
- Confidence: confirmed | likely | weak
- Verification:

### Hypothesis 2
...

---

## Proposed actions

| # | Action | Rationale | Routes to |
|---|--------|-----------|-----------|
| 1 | ... | ... | ... |
| 2 | ... | ... | ... |

**Which action would you like to take?**

---

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
- source type: symptom-investigation
- task phase: investigation
- user goal (restated symptom)
- symptom classification
- sources investigated
- key findings summary
- ranked hypotheses (brief)
- recommended next phase
- notable missing evidence

## `10-builder.md`
Must contain the full investigation artifact:
- all evidence collected (organized by source)
- all hypotheses with supporting/conflicting evidence
- proposed actions with rationale
- enough detail for downstream Critic, Context Checker, or any follow-up skill to continue without chat history

---

# INVESTIGATION RULES

You MUST:
- actively scan available sources, not just reason about user-provided text
- use the hybrid strategy: quick scan first, then targeted deep-dives
- parallelize independent investigations where possible (use Agent tool)
- explicitly state which sources were checked and which were skipped (with reason)
- separate facts from inferences from assumptions
- rank hypotheses by confidence
- present ALL applicable actions to the user
- wait for user confirmation before taking any action
- persist artifacts for downstream skill consumption

You MUST NOT:
- skip the investigation and jump to conclusions based on the symptom description alone
- assume the system is correct
- infer missing data optimistically
- take action (fix, create ticket) without presenting findings and asking the user
- conflate this skill with `analyze-problem` (this one actively gathers evidence)
- skip sources that are available and potentially relevant
- present speculation as confirmed fact

---

# CRITICAL CONSTRAINTS

- If Engram MCP tools are unavailable: note this, proceed without memory context
- If database MCP is unavailable: note this, skip DB investigation, flag as gap
- If gcx/Grafana is unavailable: note this, skip observability, flag as gap
- If Serena is unavailable: fall back to Grep/Glob for code navigation
- If an endpoint is unreachable: note this, flag as gap
- Never execute destructive queries (INSERT, UPDATE, DELETE) — read-only investigation
- Never modify code during investigation — this phase is observation only
