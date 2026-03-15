#!/usr/bin/env bash
# clone-db.sh - Clone the Sytex MySQL database for a worktree branch
#
# Usage:
#   ./clone-db.sh <branch_name>           # Create copy
#   ./clone-db.sh <branch_name> --drop    # Drop copy
#
# Environment variables (optional, have defaults):
#   MYSQL_CONTAINER  - MySQL container name (default: master-mysql-1)
#   MYSQL_USER       - MySQL user (default: root)
#   MYSQL_PASS       - MySQL password (default: e8m9ElV3jWOUMzN)
#   SOURCE_DB        - Source database name (default: sytex_telesoluciones)

set -euo pipefail

# --- Config ---
MYSQL_CONTAINER="${MYSQL_CONTAINER:-master-mysql-1}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASS="${MYSQL_PASS:-e8m9ElV3jWOUMzN}"
SOURCE_DB="${SOURCE_DB:-sytex_telesoluciones}"

# --- Validation ---
if [ -z "${1:-}" ]; then
  echo "Usage: $0 <branch_name> [--drop]"
  exit 1
fi

# Sanitize branch name: feature/login-fix -> feature_login_fix
BRANCH="$1"
DB_SUFFIX=$(echo "$BRANCH" | sed 's/[^a-zA-Z0-9]/_/g' | tr '[:upper:]' '[:lower:]')
TARGET_DB="sytex_${DB_SUFFIX}"

MYSQL_CMD="docker exec -i $MYSQL_CONTAINER mysql -u$MYSQL_USER -p$MYSQL_PASS"

# --- Drop ---
if [ "${2:-}" = "--drop" ]; then
  echo "Dropping database $TARGET_DB..."
  $MYSQL_CMD -e "DROP DATABASE IF EXISTS $TARGET_DB;" 2>/dev/null
  echo "Done."
  exit 0
fi

# --- Check if already exists ---
EXISTS=$($MYSQL_CMD -N -e "SELECT COUNT(*) FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='$TARGET_DB';" 2>/dev/null)
if [ "$EXISTS" -gt 0 ]; then
  echo "Database $TARGET_DB already exists. Use --drop first to recreate."
  exit 1
fi

# --- Create and clone ---
echo "Creating database $TARGET_DB from $SOURCE_DB..."
$MYSQL_CMD -e "CREATE DATABASE $TARGET_DB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null

echo "Copying data (~1min for 1.2GB)..."
docker exec $MYSQL_CONTAINER bash -c \
  "mysqldump -u$MYSQL_USER -p$MYSQL_PASS --single-transaction --routines --triggers $SOURCE_DB \
  | sed 's/utf8mb3_unicode_ci/utf8mb4_unicode_ci/g; s/CHARSET=utf8mb3/CHARSET=utf8mb4/g; s/CHARACTER SET utf8mb3/CHARACTER SET utf8mb4/g' \
  | mysql -u$MYSQL_USER -p$MYSQL_PASS $TARGET_DB"

echo "Done. Database $TARGET_DB created."
