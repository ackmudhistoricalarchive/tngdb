#!/bin/sh
# Apply the acktng canonical schema to the database.
#
# Uses acktng/area/schema.sql which is idempotent (CREATE TABLE IF NOT
# EXISTS throughout), so it is safe to run against an existing database.
#
# Usage: migrate.sh [--db-conf PATH]
#   --db-conf PATH   Path to db.conf connection string file.
#                    If omitted, uses PG* environment variables.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEMA="$SCRIPT_DIR/../../acktng/area/schema.sql"

if [ ! -f "$SCHEMA" ]; then
    echo "ERROR: cannot find acktng schema at $SCHEMA" >&2
    echo "       Make sure acktng is cloned alongside tngdb (e.g. via aicli setup.sh)." >&2
    exit 1
fi

DB_CONF=""

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

psql_cmd() {
    if [ -n "$DB_CONF" ]; then
        psql "$(cat "$DB_CONF")" "$@"
    else
        psql "$@"
    fi
}

echo "Applying acktng schema: $SCHEMA"
psql_cmd -v ON_ERROR_STOP=1 -f "$SCHEMA"
echo "Schema applied successfully."
