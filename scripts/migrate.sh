#!/bin/sh
# Apply pending database migrations.
#
# Reads the current schema version from the database and applies any
# migration files in area/migrations/ that are newer.
#
# Usage: migrate.sh [--db-conf PATH]
#   --db-conf PATH   Path to db.conf connection string file.
#                    Defaults to ../area/db.conf (relative to this script's
#                    parent directory), or uses PG* environment variables.
#
# Migration files must be named NNN_description.sql where NNN is the
# schema version that migration brings the database TO.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MIGRATIONS_DIR="$SCRIPT_DIR/../area/migrations"
DB_CONF=""

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
while [ $# -gt 0 ]; do
    case "$1" in
        --db-conf)
            DB_CONF="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Resolve connection string
# ---------------------------------------------------------------------------
if [ -z "$DB_CONF" ]; then
    DEFAULT_CONF="$SCRIPT_DIR/../area/db.conf"
    if [ -f "$DEFAULT_CONF" ]; then
        DB_CONF="$DEFAULT_CONF"
    fi
fi

PSQL_ARGS=""
if [ -n "$DB_CONF" ]; then
    CONNSTR="$(cat "$DB_CONF")"
    PSQL_ARGS="\"$CONNSTR\""
fi

psql_cmd() {
    if [ -n "$DB_CONF" ]; then
        psql "$(cat "$DB_CONF")" "$@"
    else
        psql "$@"
    fi
}

# ---------------------------------------------------------------------------
# Get current schema version
# ---------------------------------------------------------------------------
CURRENT=$(psql_cmd -tAc "SELECT COALESCE(MAX(version), 0) FROM schema_version" 2>/dev/null || echo "0")
CURRENT=$(echo "$CURRENT" | tr -d '[:space:]')

echo "Current schema version: $CURRENT"

# ---------------------------------------------------------------------------
# Apply pending migrations in order
# ---------------------------------------------------------------------------
APPLIED=0

for migration in $(ls "$MIGRATIONS_DIR"/*.sql 2>/dev/null | sort); do
    filename="$(basename "$migration")"
    version="$(echo "$filename" | sed 's/^0*//' | sed 's/_.*//')"

    if [ -z "$version" ]; then
        echo "WARN: cannot parse version from $filename, skipping"
        continue
    fi

    if [ "$version" -le "$CURRENT" ]; then
        continue
    fi

    echo "Applying migration: $filename (version $version)..."
    psql_cmd -v ON_ERROR_STOP=1 -f "$migration"
    APPLIED=$((APPLIED + 1))
done

if [ "$APPLIED" -eq 0 ]; then
    echo "Database is up to date. No migrations to apply."
else
    echo "Applied $APPLIED migration(s)."
fi
