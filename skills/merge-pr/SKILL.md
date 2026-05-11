---
name: merge-pr
description: Use when a PR is approved and ready to merge — merges the PR, transitions Jira stories to Done, and updates the parent epic status (In Progress if stories remain, In Testing if all done).
argument-hint: [<PR number or URL>] [--squash | --rebase | --merge]
---

# Merge PR

Use this skill when:
- a PR has been approved and is ready to merge
- the user wants to close out the PR and transition tickets to Done
- the parent epic needs status updates based on remaining work

This skill handles:
- merging the PR (squash/rebase/merge as appropriate)
- transitioning Jira stories covered by the PR to "Done"
- updating the parent epic:
  - "In Progress" if other stories are still incomplete
  - "In Testing" if ALL stories in the epic are now Done

---

# PROCESS

## Step 1: Identify the PR

Accept input as:
- PR number (e.g., `#42` or `42`)
- PR URL (e.g., `https://github.com/org/repo/pull/42`)
- Current branch (infer PR from branch)

If no PR is specified:
```bash
# Try to find PR for current branch
gh pr view --json number,title,state,mergeable,reviews
```

If no PR can be found, STOP and ask the user which PR to merge.

---

## Step 2: Pre-merge Checks

Verify ALL of the following:

### 2.1 PR is approved
```bash
gh pr view <number> --json reviews,reviewDecision
```

If not approved:
- warn the user
- ask for confirmation to proceed anyway
- do NOT proceed without explicit user confirmation

### 2.2 CI checks pass
```bash
gh pr checks <number>
```

If checks are failing:
- report which checks failed
- STOP and ask user how to proceed

### 2.3 No merge conflicts
```bash
gh pr view <number> --json mergeable
```

If not mergeable:
- report the conflict
- STOP — user must resolve conflicts first

### 2.4 PR is open
If PR is already merged or closed, report and STOP.

---

## Step 3: Extract Ticket Information

Before merging, extract ALL ticket IDs from:
- PR title
- PR body
- Branch name
- Commit messages in the PR
- Review artifacts in `.claude/reviews/` (if accessible)

For each ticket, determine:
- ticket ID
- parent epic (if any)
- current status

---

## Step 4: Merge the PR

Determine merge strategy:
- If `--squash` specified: squash merge
- If `--rebase` specified: rebase merge
- If `--merge` specified: regular merge
- If none specified: use repo default or squash (preferred for clean history)

```bash
gh pr merge <number> --squash  # or --rebase / --merge
```

If merge fails:
- report the error
- do NOT retry automatically
- suggest remediation

---

## Step 5: Transition Stories to Done

For EACH ticket ID identified in Step 3:

1. Verify the ticket's current status
2. If the ticket is a Story/Task/Bug and status allows transition to "Done":
   - transition to "Done"
   - add a comment: "Completed via PR #<number> — merged to <base-branch>"
3. If transition is not possible:
   - note the reason (wrong type, wrong status, permissions)
   - do not fail the overall operation

---

## Step 6: Update Parent Epic Status

For EACH unique parent epic found in Step 3:

### 6.1 Check all child stories
Query all stories/tasks under the epic and check their statuses.

### 6.2 Determine epic transition

**If ALL child stories are in "Done" status:**
- transition the epic to "In Testing"
- add comment: "All stories completed. Moving to In Testing for QA validation."

**If some child stories are still incomplete:**
- transition the epic to "In Progress" (if not already)
- add comment: "Stories completed: <list>. Remaining: <list>."

**If epic is already in correct status:**
- no transition needed
- still add a comment noting what was merged

---

## Step 7: Cleanup (Optional)

After successful merge:

```bash
# Delete remote branch (gh usually offers this)
gh pr view <number> --json headRefName
```

Ask the user:
- "Delete the remote branch `<branch>`?" (default: yes after merge)
- "Delete the local branch?" (default: yes if not current branch)

Do NOT auto-delete without asking.

---

## Step 8: Report

# PR Merged

## PR
- Number: #<number>
- Title: <title>
- Merged to: <base branch>
- Strategy: squash | rebase | merge

## Tickets Transitioned

| Ticket | Type | Previous Status | New Status | Epic |
|--------|------|-----------------|------------|------|
| ... | Story | In Progress | Done | EPIC-ID |
| ... | Task | In Review | Done | EPIC-ID |

## Epic Status Updates

| Epic | New Status | Reason |
|------|------------|--------|
| EPIC-ID | In Testing | All 5/5 stories Done |
| EPIC-ID | In Progress | 3/5 stories Done, 2 remaining |

## Cleanup
- Remote branch: deleted | kept
- Local branch: deleted | kept

## Notes
- <any warnings, skipped transitions, or issues>

---

# RULES

You MUST:
- verify PR is approved and CI passes before merging
- extract ALL ticket IDs from PR, branch, and commits
- transition stories to Done after successful merge
- check ALL child stories of each epic before determining epic status
- report the final state clearly
- ask before deleting branches

You MUST NOT:
- merge without CI passing (unless user explicitly overrides)
- merge without approval (unless user explicitly confirms)
- auto-delete branches without asking
- transition tickets if merge failed
- assume epic status without checking all child stories
- transition the epic to "Done" — only to "In Testing" or "In Progress"
- force-merge or bypass branch protection rules

---

# EPIC STATUS LOGIC

```
if ALL stories in epic are "Done":
    epic → "In Testing"
elif ANY story in epic is "Done" or "In Progress":
    epic → "In Progress" (if not already)
else:
    no change
```

The epic NEVER goes directly to "Done" via this skill — that requires QA sign-off which is a separate process.

---

# CRITICAL CONSTRAINTS

- If `gh` CLI is not available: STOP, inform user
- If Jira integration is unavailable: skip ticket transitions, report what should be done manually
- If PR has required reviewers who haven't approved: warn and ask for confirmation
- If branch protection prevents merge: report the blocking rule, do not attempt bypass
- Never force-merge or use admin override unless user explicitly requests it
- If epic has no child stories queryable: skip epic transition, note the gap
