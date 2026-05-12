# Quick Start — Command Guide

Practical examples for using the multi-agent review workflow.

> **Why use this?** See [WHY.md](WHY.md) for reasoning and real-world value.
> **New to this?** Read [WORKFLOW.md](WORKFLOW.md) first to understand the architecture and agent roles.

## Precondition

Make sure you are inside the correct worktree:

```bash
cd .claude/worktrees/<your-worktree>
```

All agents must run in the same worktree.

## Quick Command Reference

```
/analyze-problem
/investigate-problem
/implement-jira-ticket RUS-2458
/challenge-artifact
/audit-system-context
/resolve-disagreement
/revise-from-review
/create-pr
/merge-pr
```

---

# Full Workflow (Step-by-step)

## 1. Builder — Implementation

Start a new session:

```bash
claude
```

Run:

```text
Implement RUS-2458
```

### Output

.claude/reviews/RUS-2458/
- 00-work-dossier.md
- 10-builder.md
- 11-builder-summary.json
- 12-builder-diff.patch
- 13-builder-tests.txt

---

## 2. Critic — Code Review

Start a new session:

```bash
claude
```

Run:

```text
Use challenge-artifact to review the current implementation of RUS-2458 in this worktree.
```

### Output

.claude/reviews/RUS-2458/
- 20-critic.md

---

## 3. Context Checker — System Review

Start a new session:

```bash
claude
```

Run:

```text
Use audit-system-context to review the current implementation of RUS-2458 in this worktree.
```

### Output

.claude/reviews/RUS-2458/
- 30-context.md

---

## 4. Final Arbiter — Decision

Start a new session:

```bash
claude
```

Run:

```text
Use resolve-disagreement for RUS-2458 based on the current Builder, Critic, and Context outputs in this worktree.
```

### Output

.claude/reviews/RUS-2458/
- 40-arbiter.md
- 50-revision-request.md

---

## 5. Builder — Revision

Start a new session:

```bash
claude
```

Run:

```text
Use revise-from-review to revise the current implementation of RUS-2458.
```

### Output (updated)

.claude/reviews/RUS-2458/
- 10-builder.md
- 11-builder-summary.json
- 12-builder-diff.patch
- 13-builder-tests.txt

---

# Optional Validation Loop

Re-run:

```text
Use challenge-artifact to review the current implementation of RUS-2458 in this worktree.
Use audit-system-context to review the current implementation of RUS-2458 in this worktree.
Use resolve-disagreement for RUS-2458 based on the current outputs.
```

Repeat until:

Decision = Accept

---

# PR Lifecycle

Once the Arbiter accepts:

```text
Use create-pr to push and open a pull request for RUS-2458.
```

After approval:

```text
Use merge-pr to merge the approved PR for RUS-2458.
```

---

# Fast Path (Optional)

```text
Critic → Builder revise
```

Use only when changes are small and obvious.

---

# Key Rules

- Use a new Claude session for each role
- Stay in the same worktree
- Do not copy/paste between agents
- Use shared artifacts
- Treat 50-revision-request.md as source of truth

---

# One-line Summary

Implement → Review → Validate → Decide → Revise → Ship

---

# Learn More

- See [WHY.md](WHY.md) for reasoning behind this workflow and when to use it
- See [WORKFLOW.md](WORKFLOW.md) for detailed architecture and agent responsibilities
- See [README.md](README.md) for complete skill catalog and philosophy
