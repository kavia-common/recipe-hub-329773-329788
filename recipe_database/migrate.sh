#!/bin/bash
set -euo pipefail

# Recipe Hub - Migration/Seed runner
#
# Contract:
# - Inputs:
#   - db_connection.txt must exist and contain a "psql postgresql://..." command
#   - Optional arg1: "up" (default) | "seed"
# - Outputs:
#   - Applies schema migrations tracked in schema_migrations table
#   - Optionally applies seed data (idempotent)
# - Errors:
#   - Exits non-zero on any psql error
# - Side effects:
#   - Creates/updates tables in the target DB
#   - Inserts rows into schema_migrations
#
# Usage:
#   ./migrate.sh up
#   ./migrate.sh seed

MODE="${1:-up}"

if [ ! -f "db_connection.txt" ]; then
  echo "ERROR: db_connection.txt not found. Run ./startup.sh first."
  exit 1
fi

PSQL_CMD="$(cat db_connection.txt)"

# Ensure we can call psql in a consistent way: db_connection.txt contains something like
#   psql postgresql://user:pass@host:port/db
# We always append flags and -c/-f to it.
psql_exec() {
  # $1: SQL command
  ${PSQL_CMD} -v ON_ERROR_STOP=1 -q -c "$1"
}

psql_file() {
  # $1: file path
  ${PSQL_CMD} -v ON_ERROR_STOP=1 -q -f "$1"
}

ensure_migrations_table() {
  # Create schema_migrations table if not present (also loads extension if needed later)
  # This is duplicated defensively because the migration table itself is needed for tracking.
  psql_exec "CREATE EXTENSION IF NOT EXISTS citext;"
  psql_exec "CREATE TABLE IF NOT EXISTS schema_migrations (version TEXT PRIMARY KEY, applied_at TIMESTAMPTZ NOT NULL DEFAULT now());"
}

apply_migration_if_needed() {
  # $1: version (e.g., 001_init)
  # $2: path to sql file
  local version="$1"
  local file_path="$2"

  local already_applied
  already_applied="$(${PSQL_CMD} -t -A -q -v ON_ERROR_STOP=1 -c "SELECT 1 FROM schema_migrations WHERE version='${version}' LIMIT 1;")"

  if [ "${already_applied}" = "1" ]; then
    echo "✓ Migration already applied: ${version}"
    return 0
  fi

  echo "Applying migration: ${version} (${file_path})"
  psql_file "${file_path}"
  psql_exec "INSERT INTO schema_migrations(version) VALUES ('${version}');"
  echo "✓ Migration applied: ${version}"
}

run_up() {
  ensure_migrations_table

  # NOTE: Keep versions in order.
  apply_migration_if_needed "001_init" "schema/001_init.sql"
}

run_seed() {
  ensure_migrations_table
  echo "Applying seed data (idempotent): schema/seed.sql"
  psql_file "schema/seed.sql"
  echo "✓ Seed applied"
}

case "${MODE}" in
  up)
    run_up
    ;;
  seed)
    run_up
    run_seed
    ;;
  *)
    echo "ERROR: unknown mode '${MODE}'. Use: up | seed"
    exit 1
    ;;
esac
