---
name: disk-cleanup
description: Use when the user wants to free disk space, clean orca workspaces, .claude/worktrees, build artifacts (target/, node_modules, dist), or asks what is safe to delete on this machine. Always required before removing any workspace or artifact — nothing is deleted without an explicit per-group confirmation.
---

# Disk Cleanup (orca workspaces, worktrees, build artifacts)

## Overview

Two-pass workflow: **inventory (read-only) → report → explicit confirmation → execute → verify**. The scan script finds space; the user decides; you execute with the tool that matches each item class. Regenerable build artifacts inside *active* workspaces are usually the biggest win — deleting whole workspaces is the last resort, not the default.

## Iron Rules

- **Nothing is deleted until the user explicitly approves the plan** — not "clean up" as a request, not a vague yes. Present the plan, ask per group (A/B/C/D).
- **Never `rm -rf` a directory that is or was a git worktree.** Orca-managed → `orca worktree rm`; plain git worktree → `git worktree remove`. Raw rm desyncs Orca's registry and leaves stale git metadata.
- **Never delete the workspace hosting the current session** (or any workspace with a live session). The current session's cwd defines one protected path; the scan finds the rest.
- **Never delete git-tracked files** (e.g. committed design PNGs). Section D marks them `TRACKED(do-not-delete)`.
- **Never add `--force` past a failed worktree removal.** A dirty-worktree failure means uncommitted work exists → go back to the user.
- Never touch `~/orca/workspaces/.orca-*` (Orca bookkeeping).

## Workflow

### 1. Scan (read-only)

```bash
~/.claude/skills/disk-cleanup/scripts/disk-cleanup-scan.sh          # default roots
~/.claude/skills/disk-cleanup/scripts/disk-cleanup-scan.sh ~/extra/root   # custom roots
```

Takes 1–3 min (du of big trees). Warn the user it's running. The script NEVER deletes anything — it is safe to run any time.

### 2. Report + reclaim estimate

Present four groups with sizes:
- **A Workspaces** — `KEEP(...)` shows the exact reason (active session / dirty / unpushed / recent); `DELETE-SAFE` means: no live session, clean tree, fully pushed/pushed-equivalent, >7 days quiet.
- **B Build artifacts** — regenerable (`target/`, `node_modules`, `.next`...). Pruning these inside *kept* workspaces reclaims space without losing work. Mention rebuild cost (e.g. a 100GB+ cargo target recompiles everything).
- **C Stale residue** — dirs git no longer registers (leftovers after a prior removal). Plain `rm -rf` is allowed *here only*, after confirmation.
- **D Large media** — `TRACKED(do-not-delete)` rows are off-limits; only untracked/gitignored rows are candidates.

Estimate = Σ(DELETE-SAFE workspaces) + Σ(prunable artifacts of KEPT workspaces). Never double-count artifacts inside a to-be-deleted workspace.

### 3. Confirm

Use AskUserQuestion with one option per group (plus "nothing — report only"). A "yes" covers exactly the groups shown; any path added later needs fresh confirmation. Deleting a workspace's git branch too (when Orca offers it) must be stated in the plan.

### 4. Execute — correct tool per class

| Item class | Command |
|---|---|
| Orca-managed workspace (`~/orca/workspaces/**`) | `orca worktree rm --worktree path:<path>` (deregisters Orca + git; refuses unprovable-merge branches — report, don't override) |
| Plain git worktree | `git worktree remove <path>`; then `git worktree prune` |
| Stale residue (Section C) | `rm -rf <dir>` after confirmation, then `git worktree prune` |
| Rust/sbt artifacts | `cargo clean --manifest-path <dir>/Cargo.toml` or `rm -rf <target dir>` |
| node_modules | `rm -rf <dir>` (restore: `npm install`) |
| Untracked media | `rm <file>` after confirmation |

Run deletions one item at a time; if any command fails, stop and report — do not escalate flags.

### 5. Verify

Re-run the scan (or `du -sh` on touched parents), report actual space freed vs. the estimate, and note anything skipped and why.

## Common Mistakes

| Mistake | Reality |
|---|---|
| "`clean up` = permission to delete" | It's a request for a report + plan. Confirm per group. |
| "Nothing looks stale, so nothing can be freed" | Active workspaces often hide 100GB+ of regenerable `target/` — check Section B first. |
| "`git worktree remove` failed, just rm -rf" | Failure = uncommitted/unregistered state. Surface it; never force silently. |
| "That big PNG is junk" | Section D says TRACKED → it's part of the repo. Skip. |
| "Empty leftover dir, harmless to rm" | Only if unregistered (Section C) — registered worktrees go through `orca worktree rm` / `git worktree remove`. |
| "The scan is slow, I'll skip du and eyeball" | No sizes = no informed consent. Run the scan. |

## Red Flags — STOP

- About to `rm -rf` a **workspace root** (a git worktree) → wrong tool; use `orca worktree rm` / `git worktree remove`. (`rm -rf` is correct *inside* a kept workspace, and only for regenerable artifacts: `node_modules`, `dist`, test output. For `target/`, prefer `cargo clean`/`sbt clean`.)
- About to delete the cwd workspace or a `KEEP(...)` row → forbidden without the user overriding the specific row.
- About to proceed with only "sounds good" / "don't ask me" from the user → not explicit confirmation; show the plan first.
