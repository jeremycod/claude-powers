# Claude Powers

A collection of production-grade skills and agents for Claude Code that implement structured workflows for software development.

## Overview

This repository contains:
- **Skills**: Reusable workflow templates for specific development phases
- **Agents**: Specialized roles that implement multi-step review and production processes

These tools enable:
- Structured problem analysis before implementation
- Multi-phase development workflows (analysis → design → implementation)
- Agent-based review systems with Builder/Critic/Arbiter patterns
- Context-aware artifact persistence across sessions
- Active investigation of live systems (APIs, databases, logs)
- PR lifecycle management (creation and merging)

## Quick Start

**New to this workflow?**
1. Read [WHY.md](WHY.md) to understand the reasoning and real-world value
2. Read [WORKFLOW.md](WORKFLOW.md) to understand the multi-agent review pattern
3. Use [QUICKSTART.md](QUICKSTART.md) for practical command examples

**Quick example:**
```bash
# Install
ln -s /path/to/claude-powers/skills ~/.claude/skills
ln -s /path/to/claude-powers/agents ~/.claude/agents

# Use
claude
> Implement RUS-2458
```

## Installation

### Using Symlinks (Recommended)

```bash
# Clone or pull the repo
git clone <repo-url> ~/AiTools/claude-powers

# Remove existing directories (backup first if you have custom content)
rm -rf ~/.claude/skills
rm -rf ~/.claude/agents

# Create symlinks
ln -s ~/AiTools/claude-powers/skills ~/.claude/skills
ln -s ~/AiTools/claude-powers/agents ~/.claude/agents
```

### Direct Copy

```bash
cp -r skills ~/.claude/skills
cp -r agents ~/.claude/agents
```

## Skills Reference

### Analysis Phase

#### `analyze-problem`
**Use when:** You need to understand a problem, anomaly, bug, failure, or confusing behavior before proposing solutions.

**Output:** Structured root-cause analysis with:
- Problem statement and observations
- Facts vs inferences vs assumptions
- Consistency checks and contradictions
- Root cause hypotheses with confidence levels
- Recommended next phase

#### `investigate-problem`
**Use when:** The user reports a symptom (broken endpoint, incorrect result, error) and wants active investigation across codebase, database, logs, and observability tools.

**Output:** Investigation findings with:
- Symptom classification and scope assessment
- Evidence gathered from live systems
- Root causes identified with confidence levels
- Proposed next actions

### Design Phase

#### `design-solution`
**Use when:** The problem is understood and you need to propose solution approaches.

**Output:** Solution comparison with tradeoffs, options, and recommended approach.

#### `draft-implementation-plan`
**Use when:** You need a phased implementation plan rather than immediate code.

**Output:** Step-by-step plan with touched systems, dependencies, and validation checkpoints.

### Implementation Phase

#### `implement-jira-ticket`
**Use when:** You have a Jira ticket ID and want to implement it.

**Features:**
- Fetches ticket details automatically
- Validates scope (including Epic handling)
- Implements actionable work
- Persists Builder artifacts for review

#### `implement-from-problem`
**Use when:** You need implementation but don't have a Jira ticket (pasted problem, bug description, logs, or reviewed plan).

### Jira Integration

#### `draft-jira-ticket`
**Use when:** You need Jira-ready work items.

**Output:** Ticket drafts, epic breakdown, stories, tasks, subtasks, and acceptance criteria.

### Review & Revision

#### `challenge-artifact`
**Use when:** Performing adversarial review for correctness, requirement fit, and completeness.

**Features:**
- Standard Critic checks (requirements, contracts, logic, tests)
- Integrated reporting

#### `revise-from-review`
**Use when:** Builder must revise artifacts based on Critic, Context Checker, and Final Arbiter outputs.

#### `resolve-disagreement`
**Use when:** Reconciling review findings to produce final decisions and revision requests.

### PR Lifecycle

#### `create-pr`
**Use when:** Implementation is complete and you want to create a Pull Request.

**Features:**
- Pushes branch and creates PR with full summary
- Uploads review artifacts
- Transitions Jira stories to In Progress

#### `merge-pr`
**Use when:** A PR is approved and ready to merge.

**Features:**
- Merges the PR
- Transitions Jira stories to Done
- Updates parent epic status

### Routing

#### `builder-router`
**Use when:** Input is ambiguous, mixed (ticket + explanation + logs), or phase is unclear.

**Purpose:** Detects task phase, normalizes inputs, and routes to the correct Builder skill.

#### `audit-system-context`
**Use when:** System-level validation of behavior, integration, and operational safety is needed.

### Media

#### `video-toolkit`
**Use when:** Working with video files — analysis, summarization, clipping, merging, or splitting.

**Features:**
- Video analysis with FFmpeg and Whisper
- Transcription and summarization
- Editing operations (clip, merge, split)

## Agents

The multi-agent review workflow uses four specialized roles. See [WORKFLOW.md](WORKFLOW.md) for the complete pattern.

### Builder
Primary production agent that implements tickets, produces artifacts, and owns revisions.

### Critic
Adversarial reviewer that challenges artifacts for correctness, identifies gaps and edge cases.

### Context Checker
Validates artifacts against codebase conventions, existing patterns, and technical constraints.

### Final Arbiter
Reconciles review findings, decides on conflicting feedback, and produces final revision requests.

## Philosophy

These tools enforce:
- **Phase separation**: Understand before designing, design before implementing
- **Evidence-based reasoning**: Facts vs inferences vs assumptions
- **Structured artifacts**: Auditable, reusable outputs
- **Review discipline**: Build → Review → Revise cycle
- **Context preservation**: Work persists across sessions

## Requirements

- Claude Code CLI
- (Optional) Jira integration for ticket-based workflows
- (Optional) GitHub CLI (`gh`) for PR workflows

## Documentation

- [WHY.md](WHY.md) — Reasoning and real-world value of the adversarial review workflow
- [WORKFLOW.md](WORKFLOW.md) — Complete multi-agent review workflow (Circuit Breaker pattern)
- [QUICKSTART.md](QUICKSTART.md) — Practical command reference and examples

## License

MIT
