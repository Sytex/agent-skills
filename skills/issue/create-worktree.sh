#!/usr/bin/env bash
set -euo pipefail

# Create a full-stack worktree (back + front) with running services.
# Usage: create-worktree.sh <branch-name>

BRANCH="${1:?Usage: create-worktree.sh <branch-name>}"
ROOT="/home/ubuntu/projects"
DEV_DOMAIN="kadmos.sytex.io"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

BACK_MASTER="$ROOT/back/master"
FRONT_MASTER="$ROOT/front/master"

# ===== Step A — Frontend worktree =====
echo "===== Step A: Frontend worktree ====="
cd "$FRONT_MASTER"
git fetch origin master 2>&1
just wt-new "$BRANCH" 2>&1

# ===== Step B — Backend worktree (manual, NOT wt-new) =====
# wt-new would run containers before we can patch the compose override,
# causing the proxy to crash due to missing SSL certs.
echo ""
echo "===== Step B: Backend worktree ====="
cd "$BACK_MASTER"
git fetch origin master 2>&1

# B.1 Create git worktree
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  echo "Branch exists locally, reusing"
  git worktree add "../$BRANCH" "$BRANCH" 2>&1
else
  git worktree add -b "$BRANCH" "../$BRANCH" master 2>&1
fi

# B.2 Ensure master shared services are up
echo "--- Ensuring master services ---"
just run 2>&1

# B.3 Bootstrap (generates compose.worktree.override.yaml)
echo "--- Bootstrapping worktree ---"
WT_ALLOW_UV_SYNC_FAILURE=1 UV_CACHE_DIR="../$BRANCH/.uv-cache" \
  just --justfile "$BACK_MASTER/Justfile" --working-directory "$ROOT/back/$BRANCH" \
  wt-bootstrap "$BACK_MASTER" "0" "0" "0" 2>&1

# ===== Step C — Clone database =====
echo ""
echo "===== Step C: Clone database ====="
"$SCRIPT_DIR/clone-db.sh" "$BRANCH"

# Sanitize branch name the same way clone-db.sh does
DB_SUFFIX=$(echo "$BRANCH" | sed 's/[^a-zA-Z0-9]/_/g' | tr '[:upper:]' '[:lower:]')
TARGET_DB="sytex_${DB_SUFFIX}"

# ===== Step D — Patch compose override (before starting containers) =====
echo ""
echo "===== Step D: Patch compose override ====="
cd "$ROOT"

FRONT_PORT=$("$FRONT_MASTER/bin/wt-ports.sh" "$BRANCH")
read -r BACK_HTTP BACK_HTTPS < <("$BACK_MASTER/bin/wt-ports.sh" "$BRANCH")

# D.1 Proxy SSL: point volumes to master's certs
sed -i "/^      - \"${BACK_HTTPS}:443\"/a\\
    volumes: !override\\
      - ${BACK_MASTER}/local-proxy.conf:/etc/nginx/conf.d/default.conf\\
      - ${BACK_MASTER}/sytex.io.crt:/etc/nginx/certs/sytex.io.crt\\
      - ${BACK_MASTER}/sytex.io.key:/etc/nginx/certs/sytex.io.key" "./back/$BRANCH/compose.worktree.override.yaml"

# D.2 SYTEX_ANGULAR_FRONT_URL → frontend worktree (with trailing slash)
grep -q 'SYTEX_ANGULAR_FRONT_URL' "./back/$BRANCH/compose.worktree.override.yaml" || \
  sed -i '/ALFRED_SERVICE_URL/a\
      SYTEX_ANGULAR_FRONT_URL: https://'"${DEV_DOMAIN}"':'"${FRONT_PORT}"'/' "./back/$BRANCH/compose.worktree.override.yaml"

# D.3 SYTEX_DATABASE_NAME → worktree's own database
grep -q 'SYTEX_DATABASE_NAME' "./back/$BRANCH/compose.worktree.override.yaml" || \
  sed -i '/SYTEX_DATABASE_HOST/a\
      SYTEX_DATABASE_NAME: '"${TARGET_DB}"'' "./back/$BRANCH/compose.worktree.override.yaml"

# D.4 Patch frontend apiUrl to point to backend worktree
if [ -f "./front/$BRANCH/src/environments/environment.ts" ]; then
  sed -i "s|apiUrl: '.*'|apiUrl: 'https://${DEV_DOMAIN}:${BACK_HTTPS}'|" \
    "./front/$BRANCH/src/environments/environment.ts"
fi

# ===== Step E — Start services =====
echo ""
echo "===== Step E: Start services ====="

# E.1 Backend containers
echo "--- Starting backend ---"
cd "$ROOT/back/$BRANCH"
just run "0" 2>&1

# E.2 ng serve
echo "--- Starting ng serve ---"
cd "$ROOT/front/$BRANCH"
FRONT_PORT=$("$FRONT_MASTER/bin/wt-ports.sh" "$(basename "$PWD")")
nohup npx ng serve --host 0.0.0.0 --port "${FRONT_PORT}" --no-hmr > "/tmp/ng-serve-${BRANCH}.log" 2>&1 &
echo "ng serve PID: $!"

echo ""
echo "============================="
echo "Backend:  https://${DEV_DOMAIN}:${BACK_HTTPS}"
echo "Frontend: https://${DEV_DOMAIN}:${FRONT_PORT}"
echo "Database: ${TARGET_DB}"
echo "ng serve log: /tmp/ng-serve-${BRANCH}.log"
echo "============================="
