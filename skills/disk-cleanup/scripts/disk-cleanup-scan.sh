#!/usr/bin/env bash
# disk-cleanup-scan.sh — READ-ONLY inventory of reclaimable disk space.
#
# Scans orca workspaces, .claude/worktrees (registered git worktrees AND stale
# residue), regenerable build artifacts (target/, node_modules, .next, dist...),
# and large media files. NEVER deletes or modifies anything.
#
# Usage: disk-cleanup-scan.sh [extra-search-root ...]
# Default roots: ~/orca/workspaces ~/Sources ~/AiTools
#
# Output sections:
#   A. Workspaces        — whole-dir keep/delete decisions
#   B. Build artifacts   — regenerable, prunable inside kept workspaces
#   C. Stale residue     — dirs that LOOK like worktrees but git no longer knows them
#   D. Large media       — images >5MB, classified tracked-in-git vs untracked
# Exit code is always 0 unless usage is wrong. Sizing may take 1-3 min on big trees.

# NOTE: no `set -e/-u` — macOS ships bash 3.2 (empty array expansion errors
# under -u) and many probes legitimately fail; every failure is handled inline.

HUMAN() { awk -v k="$1" 'BEGIN{split("KB MB GB TB",u," ");s=k;i=1;while(s>=1024&&i<4){s/=1024;i++}printf (s<10?"%.1f %s":"%.0f %s"),s,u[i]}'; }

ORCA_BIN="$(command -v orca 2>/dev/null)"
ROOTS=("$HOME/orca/workspaces" "$HOME/Sources" "$HOME/AiTools")
[ $# -gt 0 ] && ROOTS=("$@")

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
WT_LIST="$TMP/worktrees.txt"      # one candidate workspace path per line
ART_LIST="$TMP/artifacts.txt"     # one build-artifact dir per line
IMG_LIST="$TMP/images.txt"        # one image file per line
DUSIZES="$TMP/du.txt"             # "<KB> <path>" per line
CWD_LIST="$TMP/cwds.txt"          # every live process cwd
touch "$WT_LIST" "$ART_LIST" "$IMG_LIST" "$DUSIZES" "$CWD_LIST"

echo "Scanning roots: ${ROOTS[*]}" >&2
echo "df overview:" >&2; df -h / 2>/dev/null | tail -1 >&2

# ---------------------------------------------------------------- discovery
# 1) Orca-managed worktrees (authoritative: orca's own registry)
if [ -n "$ORCA_BIN" ]; then
  "$ORCA_BIN" worktree list 2>/dev/null | while IFS= read -r line; do
    case "$line" in
      *::/*) p="${line#*::}"; p="${p%%[[:space:]]*}"; [ -d "$p" ] && echo "$p" ;;
    esac
  done >> "$WT_LIST"
fi

# 2) Filesystem worktrees: orca layout ~/orca/workspaces/<repo>/<id>
for repo in "$HOME/orca/workspaces"/*/; do
  [ -d "$repo" ] || continue
  case "$repo" in */.orca*) continue ;; esac
  for wt in "$repo"*/; do
    [ -d "$wt" ] && echo "${wt%/}" >> "$WT_LIST"
  done
done

# 3) .claude/worktrees children under every search root
for root in "${ROOTS[@]}"; do
  [ -d "$root" ] || continue
  find "$root" -maxdepth 5 -type d -path '*/.claude/worktrees' 2>/dev/null | while IFS= read -r wdir; do
    for child in "$wdir"/*/; do [ -d "$child" ] && echo "${child%/}" >> "$WT_LIST"; done
  done
done
sort -u "$WT_LIST" -o "$WT_LIST"

# ---------------------------------------------------------------- live sessions
# Single lsof sweep of every process cwd (user-owned only, no sudo needed).
lsof -w -d cwd -Fn 2>/dev/null | awk '/^n/{print substr($0,2)}' | sort -u > "$CWD_LIST"

# Orca live-agent counts: "repo branch host=local live:N ..." followed by the path line.
orca_live_for() { # $1=path -> echo N (or "")
  [ -n "$ORCA_BIN" ] || return 0
  local live="" path
  "$ORCA_BIN" worktree ps 2>/dev/null | while IFS= read -r line; do
    case "$line" in
      *live:*) live="$(echo "$line" | sed -n 's/.*live:\([0-9]*\).*/\1/p')" ;;
      /*) [ "$line" = "$1" ] && [ -n "$live" ] && { echo "$live"; exit 0; } ;;
    esac
  done
  return 0
}

proc_inside() { # $1=path -> nonempty if any live process cwd is $1 or below
  awk -v p="$1" 'index($0,p)==1' "$CWD_LIST" | head -1
}

# ---------------------------------------------------------------- git classification
git_flags() { # $1=workspace path -> echoes "REG|RESIDUE  dirty  unpushed  lastcommit_age_days"
  local p="$1"
  if [ ! -e "$p/.git" ]; then echo "RESIDUE - - -"; return 0; fi
  local common
  common="$(git -C "$p" rev-parse --git-common-dir 2>/dev/null)" || { echo "RESIDUE - - -"; return 0; }
  local reg="REG"
  git -C "$p" worktree list --porcelain 2>/dev/null | grep -qx "worktree $p" || reg="UNREGISTERED"
  local dirty unpushed age
  dirty="$(git -C "$p" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  local up
  up="$(git -C "$p" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)"
  if [ -n "$up" ]; then
    unpushed="$(git -C "$p" rev-list --count "$up..HEAD" 2>/dev/null || echo '?')"
  else
    unpushed="$(git -C "$p" rev-list --count origin/main..HEAD 2>/dev/null || echo '?')"
  fi
  age="$(git -C "$p" log -1 --format=%ct 2>/dev/null)"
  if [ -n "$age" ]; then age=$(( ( $(date +%s) - age ) / 86400 )); else age="?"; fi
  echo "$reg $dirty $unpushed $age"
}

recent_activity() { # $1=path -> prints a sample file if modified in last 7 days (outside build dirs)
  find "$1" \( -path '*/node_modules' -o -path '*/target' -o -path '*/.git' -o -path '*/.astro' \
              -o -path '*/.next' -o -path '*/dist' -o -path '*/build' \) -prune \
           -o -type f -mtime -7 -print -quit 2>/dev/null
}

# ---------------------------------------------------------------- artifact sweep
echo "Sweeping build artifacts (pruned traversal)..." >&2
for root in "${ROOTS[@]}"; do
  [ -d "$root" ] || continue
  # Prune python venvs/site-packages FIRST: a package literally named "build"
  # lives there and must never be reported as build output.
  find "$root" -maxdepth 7 \
     \( \( -name .venv -o -name venv -o -name site-packages -o -name .git \) -prune \) -o \
     \( -type d \( -name node_modules -o -name target -o -name .next -o -name .turbo -o -name dist \
        -o -name build -o -name coverage -o -name test-results -o -name playwright-report \
        -o -name pw-reports \) -prune -print \) 2>/dev/null >> "$ART_LIST"
done
sort -u "$ART_LIST" -o "$ART_LIST"

# ---------------------------------------------------------------- media sweep
echo "Sweeping large media (>5MB images)..." >&2
for root in "${ROOTS[@]}"; do
  [ -d "$root" ] || continue
  find "$root" \( -path '*/node_modules' -o -path '*/target' -o -path '*/.git' \
                 -o -path '*/.astro' -o -path '*/.next' -o -path '*/dist' -o -path '*/build' \) -prune \
              -o -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \
                           -o -iname '*.gif' -o -iname '*.webp' \) -size +5M -print 2>/dev/null
done | head -50 >> "$IMG_LIST"

# ---------------------------------------------------------------- sizing (parallel)
echo "Measuring sizes (this is the slow part, a couple of minutes on big trees)..." >&2
{ cat "$WT_LIST" "$ART_LIST"; while IFS= read -r f; do printf '%s\n' "$(dirname "$f")"; done < "$IMG_LIST"; } \
  | sort -u > "$TMP/tomeasure.txt"
if [ -s "$TMP/tomeasure.txt" ]; then
  xargs -P 4 -n 1 du -sk < "$TMP/tomeasure.txt" 2>/dev/null >> "$DUSIZES"
fi
size_of() { awk -v p="$1" '$2==p{print $1; exit}' "$DUSIZES"; }

# ---------------------------------------------------------------- report
HR; echo "A. WORKSPACES (whole-dir keep/delete decisions)"; HR
printf '%-72s %9s %-9s %-6s %-6s %-9s %-5s %s\n' PATH SIZE ACTIVE GIT DIRTY UNPUSHED AGE VERDICT
while IFS= read -r wt; do
  case "$wt" in */.orca*) continue ;; esac
  s="$(size_of "$wt")"; [ -z "$s" ] && s=0
  flags="$(git_flags "$wt")"; set -- $flags
  reg="$1"; dirty="$2"; unpushed="$3"; age="$4"
  live="$(orca_live_for "$wt")"; [ -z "$live" ] && live=0
  proc="$(proc_inside "$wt")"
  recent="$(recent_activity "$wt")"
  # verdict: any active signal or unpushed/dirty work => KEEP. Numeric guards:
  # placeholders ("-", "?") must not satisfy the != "0" checks below.
  if [ "$reg" = "RESIDUE" ] || [ "$reg" = "UNREGISTERED" ]; then v="RESIDUE(see C)"
  elif [ "${live:-0}" -gt 0 ] 2>/dev/null || [ -n "$proc" ]; then v="KEEP(active session)"
  elif [ "$dirty" -gt 0 ] 2>/dev/null; then v="KEEP(dirty x$dirty)"
  elif [ "$unpushed" -gt 0 ] 2>/dev/null; then v="KEEP(unpushed x$unpushed)"
  elif [ "$age" != "?" ] && [ "$age" -le 7 ] 2>/dev/null; then v="KEEP(recent)"
  else v="DELETE-SAFE"; fi
  printf '%-72s %9s %-9s %-6s %-6s %-9s %-5s %s\n' \
    "$wt" "$(HUMAN "$s")" "$([ "$live" -gt 0 ] 2>/dev/null && echo "orca:$live" || { [ -n "$proc" ] && echo "procs" || echo "-"; })" \
    "$reg" "$dirty" "$unpushed" "$age" "$v"
done < "$WT_LIST"

HR; echo "B. BUILD ARTIFACTS (regenerable — prune inside kept workspaces)"; HR
printf '%-90s %9s %s\n' PATH SIZE KIND
while IFS= read -r a; do
  case "$a" in
    */node_modules)  k="npm (npm install to restore)" ;;
    */target)        k="rust/sbt (cargo clean / sbt clean)" ;;
    */.next|*/.turbo|*/dist|*/build) k="frontend build" ;;
    *)               k="test/build output" ;;
  esac
  s="$(size_of "$a")"; [ -z "$s" ] && s=0
  printf '%-90s %9s %s\n' "$a" "$(HUMAN "$s")" "$k"
done < "$ART_LIST"

HR; echo "C. STALE RESIDUE (unregistered — git already forgot these)"; HR
found_residue=0
while IFS= read -r wt; do
  f="$(git_flags "$wt" | cut -d' ' -f1)"
  { [ "$f" = "RESIDUE" ] || [ "$f" = "UNREGISTERED" ]; } && { echo "$wt"; found_residue=1; }
done < "$WT_LIST"
[ "$found_residue" = "0" ] && echo "(none)"

HR; echo "D. LARGE MEDIA >5MB (tracked files must NOT be deleted)"; HR
if [ -s "$IMG_LIST" ]; then
  printf '%-90s %9s %s\n' PATH SIZE GIT
  while IFS= read -r img; do
    d="$(dirname "$img")"; rel="${img#"$d"/}"
    tracked="untracked"
    if git -C "$d" rev-parse --git-dir >/dev/null 2>&1; then
      if git -C "$d" ls-files --error-unmatch "$rel" >/dev/null 2>&1; then tracked="TRACKED(do-not-delete)"
      elif git -C "$d" check-ignore -q "$rel" 2>/dev/null; then tracked="gitignored"; fi
    fi
    kb="$(du -sk "$img" 2>/dev/null | awk '{print $1}')"; [ -z "$kb" ] && kb=0
    printf '%-90s %9s %s\n' "$img" "$(HUMAN "$kb")" "$tracked"
  done < "$IMG_LIST"
else
  echo "(none)"
fi

HR
echo "Scan complete. Nothing was modified. Compute reclaim estimate in the report:"
echo "  DELETE-SAFE workspaces + prunable artifacts of KEPT workspaces (do not double-count)."
exit 0
