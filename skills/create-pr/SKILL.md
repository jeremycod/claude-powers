---
name: create-pr
description: Use when implementation is complete and the user wants to create a Pull Request — pushes branch, creates PR with full summary of all changes, uploads review artifacts, and transitions Jira stories to In Progress.
argument-hint: [context:<name>] [--base <branch>] [--draft]
---

# Create PR

Use this skill when:
- implementation is complete and tested
- the user wants to create a Pull Request
- you need to push the branch and open a PR with a comprehensive summary

This skill handles:
- pushing the branch to remote
- creating a PR with a full summary of all changes
- uploading review artifacts (from `.claude/reviews/`) to the PR description
- listing all tickets covered
- transitioning Jira stories to "In Progress"

---

# CONTEXT SELECTION POLICY (MANDATORY)

This skill supports an inline context selector:

`context:<name>`

Examples:
- `/create-pr context:RUS-2458`
- `/create-pr context:orders-500 --base develop`

You MUST resolve context using this exact order:

## 1. Explicit context
If a `context:<name>` token is present in the request:
- extract `<name>`
- use review directory: `.claude/reviews/<name>/`

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
If no explicit or worktree context exists, but a clear ticket ID is present (from branch name or review directory):
- use that ticket ID as context
- use review directory: `.claude/reviews/<ticket>/`

## 4. Single existing review directory
If none of the above apply, and exactly one review directory exists under `.claude/reviews/`:
- infer that directory as context

## 5. Default
If none of the above apply:
- use context: `ad-hoc`
- use review directory: `.claude/reviews/ad-hoc/`

---

# PROCESS

## Step 1: Pre-flight Checks

Before creating the PR, verify:

1. **Tests pass** — run the project test suite
2. **No uncommitted changes** — all work is committed
3. **Branch is not main/master** — cannot create PR from default branch
4. **Remote is reachable** — `git remote -v` works

If any check fails, STOP and report the issue.

---

## Step 2: Gather Information

Collect ALL of the following:

### 2.1 Git state
```bash
git log --oneline $(git merge-base HEAD main)..HEAD
git diff --stat $(git merge-base HEAD main)..HEAD
```

### 2.2 Review artifacts
Read from `.claude/reviews/<context>/`:
- `00-work-dossier.md` — scope, goals, constraints
- `10-builder.md` — full implementation details
- `11-builder-summary.json` — structured summary
- `20-critic.md` — review findings (if exists)
- `40-arbiter.md` — final decisions (if exists)

### 2.3 Ticket references
Extract ticket IDs from:
- branch name (e.g., `feature/RUS-2458-...`)
- review directory name
- commit messages
- work dossier content

### 2.4 Files changed
```bash
git diff --stat $(git merge-base HEAD main)..HEAD
```

---

## Step 3: Build PR Description

The PR description MUST include ALL of the following sections:

```markdown
## Summary
<2-5 bullet points describing what this PR does and why>

## Tickets
<list of all Jira tickets covered, with links if URL pattern is known>
- [TICKET-ID] Summary of what was done for this ticket

## Changes
<organized list of changes by area>

### <Area 1>
- change description
- change description

### <Area 2>
- change description

## Implementation Details
<relevant technical details from 10-builder.md>
- key decisions made
- approach taken
- notable patterns used

## Contract Coverage
<from 11-builder-summary.json if available>
- endpoints affected
- behaviors modified
- fields added/changed

## Known Limitations / Uncertainty
<from work dossier or builder artifact>
- what is not yet covered
- what needs follow-up

## Test Plan
- [ ] <specific verification steps>
- [ ] <edge cases to check>
- [ ] <regression checks>

## Review Artifacts
<summary of what review was done>
- Builder artifact: <present/absent>
- Critic review: <present/absent, summary of findings>
- Arbiter decision: <present/absent, verdict>
```

---

## Step 4: Push Branch and Create PR

```bash
# Push branch with upstream tracking
git push -u origin <branch-name>

# Create PR using gh CLI
gh pr create --title "<title>" --body "<body>"
```

### PR Title Rules
- Under 70 characters
- Format: `[TICKET-ID] Short description of change`
- If no ticket: descriptive summary of the change
- Use imperative mood ("Add", "Fix", "Update", not "Added", "Fixed")

### Draft PR
If `--draft` flag is specified or tests are incomplete:
```bash
gh pr create --draft --title "..." --body "..."
```

---

## Step 5: Upload Artifacts as PR Comments

After creating the PR, upload key artifacts as comments for reviewers:

```bash
# Upload builder summary if it exists
gh pr comment <PR-NUMBER> --body "$(cat <<'EOF'
## Builder Artifact Summary

<content from 10-builder.md, condensed to key sections>
EOF
)"
```

Only upload if artifacts contain substantial content. Do not upload empty templates.

---

## Step 6: Transition Jira Tickets to In Progress

For EACH ticket ID identified in Step 2.3:

1. Verify the ticket exists and its current status
2. If status allows transition to "In Progress":
   - transition the ticket
   - add a comment with the PR URL
3. If transition is not possible (wrong status, permissions):
   - note this in the output
   - do not fail the overall operation

Use available Jira integration (API, CLI, or MCP tools) to perform transitions.
If no Jira integration is available, output the list of tickets that SHOULD be transitioned and ask the user to do it manually.

---

## Step 7: Report

Output a clear summary:

# PR Created

## PR
- URL: <PR URL>
- Title: <title>
- Base: <base branch>
- Status: ready | draft

## Tickets
| Ticket | Status | Transitioned? |
|--------|--------|---------------|
| ... | ... | yes/no/skipped |

## Artifacts uploaded
- <list of what was attached to PR>

## Next steps
- <what the user should do next: request review, wait for CI, etc.>

---

# RULES

You MUST:
- run tests before creating the PR
- include ALL tickets found in artifacts, commits, and branch name
- write a comprehensive PR description (not a one-liner)
- include implementation details from review artifacts
- attempt to transition tickets to In Progress
- report the PR URL when done

You MUST NOT:
- create a PR with failing tests (unless user explicitly requests `--draft`)
- skip the artifact summary in the PR body
- force-push or rewrite history
- transition tickets if unsure about the correct target status
- create a PR from main/master branch
- omit ticket references that are clearly related to this work

---

# CRITICAL CONSTRAINTS

- If `gh` CLI is not available: STOP, inform user they need to install GitHub CLI
- If no remote is configured: STOP, inform user
- If branch has no commits ahead of base: STOP, nothing to PR
- If Jira integration is unavailable: skip transitions, report what should be done manually
- Never include secrets, credentials, or .env content in PR descriptions
