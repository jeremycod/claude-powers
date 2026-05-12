# AI Development Workflow (Circuit Breaker)

A multi-agent review workflow that introduces structured validation across specialized AI roles to prevent incorrect or incomplete implementations.

> **Why this workflow?** See [WHY.md](WHY.md) for reasoning and real-world value.
> **Quick Start**: See [QUICKSTART.md](QUICKSTART.md) for practical commands and examples.

## Goal
Prevent incorrect or incomplete implementations through systematic review by specialized agents, each with distinct responsibilities.

---

# Workflow Diagram

```
AGENTS (who does the work)                ARTIFACTS (shared state)

┌──────────────┐
│   Builder    │  Designs solution or draft implementation
└──────┬───────┘
       │ writes
       ▼
                              ┌─────────────────────────────────────┐
                              │ .claude/reviews/<TICKET_ID>/        │
                              │                                     │
                              │ 00-work-dossier.md                  │
                              │ 10-builder.md                       │
                              │ 11-builder-summary.json             │
                              │ 12-builder-diff.patch               │
                              │ 13-builder-tests.txt                │
                              └─────────────────────────────────────┘
       │
       ▼
┌──────────────┐
│    Critic    │  Review logic, requirement fit, tests, edge cases
└──────┬───────┘
       │ reads requirements + artifacts
       │ writes
       ▼
                              ┌─────────────────────────────────────┐
                              │ + 20-critic.md                      │
                              └─────────────────────────────────────┘
       │
       ▼
┌──────────────┐
│ Context Chk  │  Review system-level context, hidden assumptions, integration risks
└──────┬───────┘
       │ reads requirements + critic
       │ writes
       ▼
                              ┌─────────────────────────────────────┐
                              │ + 30-context.md                     │
                              └─────────────────────────────────────┘
       │
       ▼
┌──────────────┐
│  Arbiter     │  Decide what is confirmed, what must change, and whether the work is acceptable
└──────┬───────┘
       │ reads all artifacts
       │ writes
       ▼
                              ┌─────────────────────────────────────┐
                              │ + 40-arbiter.md                     │
                              │ + 50-revision-request.md            │
                              └─────────────────────────────────────┘
       │
       ▼
┌──────────────┐
│ Builder (rev)│  Revise solution or implementation
└──────┬───────┘
       │ reads revision request
       │ updates implementation + artifacts
       ▼
                              ┌─────────────────────────────────────┐
                              │ (updates builder artifacts)         │
                              └─────────────────────────────────────┘
```

---

# Roles

## Builder
- Implements Jira ticket or problem description
- Produces code + artifacts
- Revises based on Arbiter decisions

**Skills:**
- implement-jira-ticket
- implement-from-problem
- revise-from-review

---

## Critic
- Verifies requirement fit
- Finds logic bugs, edge cases, test gaps

**Skill:**
- challenge-artifact

---

## Context Checker
- Validates system behavior
- Finds integration/runtime issues

**Skill:**
- audit-system-context

---

## Final Arbiter
- Resolves Critic + Context findings
- Produces final decision and revision request

**Skill:**
- resolve-disagreement

---

# Artifact Contract

All communication happens through:

.claude/reviews/<TICKET_ID>/

## Builder outputs
- 00-work-dossier.md
- 10-builder.md
- 11-builder-summary.json
- 12-builder-diff.patch
- 13-builder-tests.txt

## Review outputs
- 20-critic.md
- 30-context.md

## Decision outputs
- 40-arbiter.md
- 50-revision-request.md

---

# Execution Flow

1. Builder → Implement ticket
2. Critic → challenge-artifact
3. Context Checker → audit-system-context
4. Arbiter → resolve-disagreement
5. Builder → revise-from-review

---

# Loop (Optional)

Repeat:
Critic → Context → Arbiter

Until:
Decision = Accept

---

# Key Rules

- Always review branch vs main + worktree
- 50-revision-request.md is the source of truth
- No copy/paste — artifacts are shared
- Each agent runs in a separate session
- Agents do not overlap responsibilities

---

# Mental Model

Builder: implements
Critic: challenges correctness
Context: challenges system impact
Arbiter: decides truth
Builder: fixes

---

# Next Steps

- See [WHY.md](WHY.md) for reasoning behind this workflow
- See [QUICKSTART.md](QUICKSTART.md) for step-by-step command examples
- See [README.md](README.md) for complete skill reference
