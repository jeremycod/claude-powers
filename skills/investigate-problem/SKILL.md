---
name: investigate-problem
description: Use when the user reports a symptom (broken endpoint, incorrect result, screenshot of wrong behavior, error description) and wants active investigation across codebase, database, logs, and observability tools to identify root causes and propose next actions. Also handles "investigate-problem #N validated" to mark a verification entry as validated.
argument-hint: [context:<name>] <symptom — endpoint, error, screenshot, description of wrong behavior> | #<id> validated
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
- `#5 validated` — marks verification entry #5 as validated

---

# VALIDATION MODE

If the user input matches the pattern `#<id> validated` (e.g., "investigate-problem #5 validated"), this is a **validation command**, not a new investigation.

## Validation flow:
1. Read `.claude/.reviews/investigate-problem-verification.md`
2. Find the entry with the matching ID
3. Update its status from `pending` to `validated`
4. Add validation date
5. Confirm to user

## Status update format:
Change `**Status:** pending` to `**Status:** validated (YYYY-MM-DD)`

If the entry does not exist, inform the user. If it's already validated, inform the user.

After handling validation, STOP — do not proceed with the investigation flow below.

---

# VERIFICATION TRACKING

Every investigation that identifies a problem MUST append a verification entry to:

`.claude/.reviews/investigate-problem-verification.md`

This document tracks problems discovered during investigations so they can later be validated as fixed.

## When to append an entry

Append a verification entry at the END of Phase 5 (Persist Artifacts), AFTER writing `00-work-dossier.md` and `10-builder.md`, when:
- A root cause was identified (confidence: `confirmed` or `likely`)
- The investigation produced actionable findings (fix, ticket, design)

Do NOT append if:
- The investigation was inconclusive (all hypotheses are `weak`)
- The user explicitly says this is informational only

## Entry format

```markdown
---

### #<ID>

**Status:** pending
**Date:** YYYY-MM-DD
**Context:** <context name used in investigation>
**Jira:** <epic/ticket URL if created, otherwise "—">

**Problem:** <1-2 sentence description of what's wrong>

**Steps to reproduce:**
1. <step>
2. <step>
3. <step>

**Expected:** <what should happen>
**Actual:** <what happens instead>
```

## Rules for entries

- **ID**: Auto-increment integer. Read the file, find the highest existing ID, use ID+1. If file doesn't exist, start at 1.
- **Concise**: Problem description is 1-2 sentences max. Steps to reproduce are 3-5 numbered steps max.
- **Complex reproduction**: If reproducing requires more than 5 steps, complex setup, or multi-service coordination:
  - Write a separate `steps-to-reproduce-<ID>.md` in `.claude/.reviews/context/`
  - In the verification entry, replace steps with: `See [detailed steps](.reviews/context/steps-to-reproduce-<ID>.md)`
- **Jira link**: Add the epic/ticket URL when Jira tickets are created during the investigation. If tickets are created later (user picks option 2/3), update the entry at that time.
- **Status lifecycle**: `pending` → `validated` (via `#N validated` command)

## File initialization

If `.claude/.reviews/investigate-problem-verification.md` doesn't exist, create it with:

```markdown
# Investigation Verification Tracker

Problems identified during investigations, tracked for validation.

Usage: `/investigate-problem #<ID> validated` to mark as fixed.
```

Then append the first entry below.

---

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

Before presenting any investigation results, you MUST output:

# Builder Routing

## Phase
investigation

## Selected Skill
investigate-problem

## Context
<context name>

## Context resolution
explicit | inferred from worktree branch | inferred from ticket | inferred from single existing directory | defaulted to ad-hoc

## Reason
The user reported a live symptom requiring active investigation.

Do not skip this section.

---

# BUILDER FLOW INTEGRATION (MANDATORY)

This skill operates as a Builder in the standard review flow:

```
investigate-problem (Builder) → challenge-artifact (Critic) → resolve-disagreement (Arbiter) → action
```

The investigation artifact (`10-builder.md`) MUST be persisted to the review directory so that downstream review skills (`challenge-artifact`, `resolve-disagreement`, `revise-from-review`) can consume it without chat history.

After persisting artifacts, you MUST present the review option as the default next step. The user may choose to skip review and proceed directly to an action, but review is the expected path.

This is identical to how `analyze-problem` and `implement-jira-ticket` operate — they produce Builder artifacts that go through Critic/Arbiter review before any action is taken.

---

# REVIEW DIRECTORY

Use:

`.claude/reviews/<context>/`

You SHOULD read when available:
- `00-work-dossier.md`
- `10-builder.md`
- `20-critic.md`
- `30-context.md`

You MUST ALWAYS persist investigation results to:
- `00-work-dossier.md`
- `10-builder.md`

Artifact creation is UNCONDITIONAL — do not wait for the user to ask. Every investigation produces artifacts.

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
- [ ] Upstream data source validation (EODHD API via `eodhd-api` skill)
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

**IMPORTANT:** Determine which environment the issue is in, then use the correct MCP connection:
- Local: `connection="alphafolio_local"`
- Staging: `connection="alphafolio_staging"`
- Production: `connection="alphafolio_production"`

Use database MCP tools to check:
  - Schema: `describe_table` for relevant tables
  - Data state: `execute_sql` to query relevant records
  - Sample data: `get_sample_data` for the affected entities
  - Constraints, indexes, relationships
  - Pre-built templates: `list_templates` / `execute_template` for common queries (users, portfolios, risk, jobs, etc.)
- Look for data inconsistencies, missing records, stale state, constraint violations
- Compare data across environments if the issue is environment-specific

### 3.3 Logs & Observability

**IMPORTANT:** Before querying logs, determine which environment the issue is in. Then recall Engram memory for access details:
- Call `recall("investigation resources environment access")` or `get_context_for("rustfolio investigation")` to retrieve Loki/Grafana credentials and endpoints.
- The project CLAUDE.md also contains exact curl commands for each environment under "Investigation & Debugging Resources → Logs — Loki".

**How to query Loki logs (via curl in Bash tool):**
1. Identify the environment (local / staging / production)
2. Get credentials from CLAUDE.md or Engram memory
3. Build a LogQL query: `{service="alphafolio",level="error"}` or `{service="alphafolio"} |= "search_text"`
4. Set time range: `start` and `end` as epoch nanoseconds (use `$(date -v-1H +%s)000000000` for last hour)
5. Parse JSON response: `data.result[].values[]` contains `[timestamp, log_line]` pairs

**Useful LogQL patterns:**
- Errors in last hour: `{service="alphafolio",level="error"}`
- Specific endpoint: `{service="alphafolio"} |= "/api/endpoint_path"`
- Specific error message: `{service="alphafolio"} |= "error text"`
- JSON field filter: `{service="alphafolio"} | json | message =~ ".*pattern.*"`

If gcx MCP tools are also available, prefer those for dashboards and metrics. For raw log queries, curl against Loki is faster and more flexible.

### 3.4 Endpoint Test
- If a URL/endpoint is provided and accessible:
  - Hit the endpoint and observe the actual response
  - Compare with expected behavior
  - Check headers, status codes, response body
  - Try variations (different params, auth states)

### 3.5 Upstream Data Source Validation (EODHD)
- When the symptom involves incorrect financial data, missing prices, wrong fundamentals, or data freshness issues:
  - Use the `eodhd-api` skill to query the upstream EODHD API directly
  - Compare the raw API response with what the application stores/returns
  - Check if the issue is at ingestion (app didn't fetch/parse correctly) or at source (EODHD doesn't have the data)
  - Validate field mappings between EODHD response and application models
  - Check for API key validity and rate limiting issues
- This helps distinguish "our code is wrong" from "upstream data is missing/stale"

### 3.6 Engram Deep Dive
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
- Upstream data source findings (EODHD)
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

## Phase 5: Persist Artifacts & Submit for Review

After completing the investigation, you MUST:

1. Write `00-work-dossier.md` and `10-builder.md` to the review directory (see PERSISTENCE RULES below)
2. Append a verification entry to `.claude/.reviews/investigate-problem-verification.md` (see VERIFICATION TRACKING above)
3. Submit the artifact for review via the standard builder flow

The investigation artifact in `10-builder.md` is a Builder artifact. It MUST go through the same Critic → Context Checker → Arbiter review cycle as any other Builder output before action is taken.

---

## Phase 6: Present Findings & Proposed Actions (CONSULTATIVE)

Present the investigation results clearly, then offer the user a choice of next actions.

### Action menu (present ALL applicable options):

0. **Review investigation** (DEFAULT) — submit for Critic/Arbiter review before acting
   → routes to `challenge-artifact` then `resolve-disagreement`
   → ensures investigation quality before committing to an action
   → this is the default path unless user explicitly opts out

1. **Fix directly** — if root cause is confirmed and fix is straightforward
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

NOTE: Options 1-5 should only be taken AFTER the investigation has been reviewed (option 0), unless the user explicitly chooses to skip review.

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
- [ ] Upstream data source (EODHD)
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

### From upstream data source (EODHD)
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
| 0 | Review investigation (default) | Validate findings before acting | challenge-artifact → resolve-disagreement |
| 1 | ... | ... | ... |
| 2 | ... | ... | ... |

**Which action would you like to take?** (Default: 0 — submit for review)

---

## Persistence
- Context used:
- Context resolution:
- Directory used:
- Files written:
- Verification entry: #<ID> (or "skipped — inconclusive")

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
- recommended next phase (default: `challenge-artifact` for review)
- notable missing evidence

## `10-builder.md`
Must contain the full investigation artifact:
- all evidence collected (organized by source)
- all hypotheses with supporting/conflicting evidence
- proposed actions with rationale
- enough detail for downstream Critic, Context Checker, or any follow-up skill to continue without chat history

## `.claude/.reviews/investigate-problem-verification.md`
Append a verification entry (see VERIFICATION TRACKING section above) unless investigation was inconclusive. If Jira tickets are created as part of the action menu (options 2/3), update the entry's `**Jira:**` field with the epic/ticket URL before completing.

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

## NO CODE IMPLEMENTATION (NON-NEGOTIABLE)

**This skill MUST NEVER write, edit, or modify application code.** Investigation is read-only. The goal is to produce findings, hypotheses, and an implementation plan or Jira stories — NOT to fix anything.

Even if the root cause is obvious and the fix is trivial:
- Do NOT implement the fix
- Do NOT create or modify source files
- Do NOT route to `implement-from-problem` without the user's explicit written permission to make code changes
- Present findings and proposed actions, then STOP and wait for user direction

The only files this skill may write are review artifacts (`00-work-dossier.md`, `10-builder.md`) in the `.claude/reviews/` directory, the verification tracker (`.claude/.reviews/investigate-problem-verification.md`), and complex reproduction steps (`.claude/.reviews/context/steps-to-reproduce-<ID>.md`).

If the user wants code changes, they will explicitly say so. Until then, the output is analysis and planning only.

---

- If Engram MCP tools are unavailable: note this, proceed without memory context
- If database MCP is unavailable: fall back to psql via Bash (credentials in backend/.env, .env.staging, .env.production)
- If Loki/Grafana is unreachable: note this, skip observability, flag as gap. Check CLAUDE.md for curl commands.
- If EODHD API (`eodhd-api` skill) is unavailable: note this, skip upstream data validation, flag as gap
- If Serena is unavailable: fall back to Grep/Glob for code navigation
- If an endpoint is unreachable: note this, flag as gap
- Never execute destructive queries (INSERT, UPDATE, DELETE) — read-only investigation
- Never modify code during investigation — this phase is observation only
- Always check the correct environment — do not query production DB when investigating a staging issue
