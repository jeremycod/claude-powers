---
name: run-from-worktree
description: Use when working in a git worktree and needing to run the frontend and backend dev servers locally. Handles copying .env from the main checkout and launching both services.
---

# Run From Worktree

Run the project's frontend (React) and backend (Rust) dev servers from the current git worktree.

Worktrees don't include untracked files like `.env`, so you must copy environment config from the main checkout before running.

---

## Steps

### 1. Identify the main checkout path

The main checkout is the original working tree (not a worktree). Determine it:

```bash
git worktree list
```

The first entry (without `[branch]` suffix or marked as `(bare)`) is the main checkout. Extract that path — referred to as `$MAIN_CHECKOUT` below.

If you are NOT currently in a worktree (i.e., the current directory IS the main checkout), skip the .env copy step.

### 2. Copy backend .env

```bash
cp "$MAIN_CHECKOUT/backend/.env" ./backend/.env
```

Only copy if `./backend/.env` does not already exist or the user requests a refresh. Never overwrite without confirming.

### 3. Start backend (Rust)

```bash
cd backend && cargo run
```

Run in background or in a separate terminal. The backend must be running before the frontend can connect to its API.

### 4. Start frontend (React)

```bash
cd frontend && npm run dev
```

---

## Quick Reference

| Component | Directory | Command | Env needed |
|-----------|-----------|---------|------------|
| Backend | `backend/` | `cargo run` | `backend/.env` (copy from main checkout) |
| Frontend | `frontend/` | `npm run dev` | None |

## Common Issues

- **Backend fails to start**: Check that `backend/.env` exists and has valid values. Compare with main checkout.
- **Frontend can't reach API**: Ensure the backend is running and listening before starting frontend. Check the API URL in frontend config matches the backend port from `.env`.
- **Permission denied on .env copy**: The main checkout path may have changed. Re-run `git worktree list` to confirm.
- **Cargo build errors in worktree**: Run `cargo build` first to check for compilation issues separate from runtime config.
