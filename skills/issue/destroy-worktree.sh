#!/usr/bin/env bash
set -euo pipefail

# Destroy a full-stack worktree (back + front) and clean up database.
# Usage: destroy-worktree.sh <branch-name>

BRANCH="${1:?Usage: destroy-worktree.sh <branch-name>}"
ROOT="/home/ubuntu/projects"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

BACK_MASTER="$ROOT/back/master"
FRONT_MASTER="$ROOT/front/master"

# ===== Step A — Kill ng serve =====
echo "===== Step A: Stop ng serve ====="
NG_PID=$(pgrep -f "ng serve.*${BRANCH}" || true)
if [ -n "$NG_PID" ]; then
  kill "$NG_PID" 2>/dev/null || true
  echo "Killed ng serve PID $NG_PID"
else
  echo "No ng serve process found for $BRANCH"
fi

# ===== Step B — Clean front worktree =====
echo ""
echo "===== Step B: Clean front worktree ====="
FRONT_WT="$ROOT/front/$BRANCH"
if [ -d "$FRONT_WT" ]; then
  cd "$FRONT_MASTER"
  just wt-clean "$FRONT_WT" 2>&1 || echo "Warning: front wt-clean failed, continuing"
else
  echo "Front worktree not found at $FRONT_WT, skipping"
fi

# ===== Step C — Clean back worktree =====
echo ""
echo "===== Step C: Clean back worktree ====="
BACK_WT="$ROOT/back/$BRANCH"
if [ -d "$BACK_WT" ]; then
  cd "$BACK_MASTER"
  just wt-clean "$BACK_WT" 2>&1 || echo "Warning: back wt-clean failed, continuing"
else
  echo "Back worktree not found at $BACK_WT, skipping"
fi

# ===== Step D — Drop database =====
echo ""
echo "===== Step D: Drop database ====="
"$SCRIPT_DIR/clone-db.sh" "$BRANCH" --drop

echo ""
echo "============================="
echo "Worktree $BRANCH destroyed."
echo "============================="
