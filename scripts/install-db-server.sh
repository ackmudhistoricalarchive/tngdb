#!/bin/sh
# Install PostgreSQL, create the ack role and acktng database, and apply
# the schema.  Run as root (or via sudo).
#
# Usage: install-db-server.sh [--password PASSWORD]
#   --password PASSWORD   Password for the 'ack' role.
#                         If omitted, a random password is generated and
#                         printed at the end of the run.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEMA="$SCRIPT_DIR/../area/schema.sql"
PG_USER=ack
PG_DB=acktng
PG_PASS=

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
while [ $# -gt 0 ]; do
    case "$1" in
        --password)
            PG_PASS="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

if [ -z "$PG_PASS" ]; then
    PG_PASS="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32)"
    GENERATED=1
fi

# ---------------------------------------------------------------------------
# Packages
# ---------------------------------------------------------------------------
apt-get update
apt-get install -y postgresql postgresql-client

# ---------------------------------------------------------------------------
# Role and database
# ---------------------------------------------------------------------------
# Run setup as the postgres superuser.
sudo -u postgres psql -v ON_ERROR_STOP=1 <<SQL
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$PG_USER') THEN
        CREATE ROLE $PG_USER LOGIN PASSWORD '$PG_PASS';
    ELSE
        ALTER ROLE $PG_USER PASSWORD '$PG_PASS';
    END IF;
END
\$\$;
SQL

sudo -u postgres createdb --owner="$PG_USER" "$PG_DB" 2>/dev/null || \
    echo "Database '$PG_DB' already exists, skipping."

# ---------------------------------------------------------------------------
# Schema
# ---------------------------------------------------------------------------
sudo -u postgres psql -v ON_ERROR_STOP=1 -d "$PG_DB" -f "$SCHEMA"

# ---------------------------------------------------------------------------
# Permissions
# ---------------------------------------------------------------------------
sudo -u postgres psql -v ON_ERROR_STOP=1 -d "$PG_DB" <<SQL
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES    IN SCHEMA public TO $PG_USER;
GRANT USAGE, UPDATE                  ON ALL SEQUENCES IN SCHEMA public TO $PG_USER;
SQL

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
if [ "${GENERATED:-0}" = "1" ]; then
    echo ""
    echo "Setup complete."
    echo "  role:     $PG_USER"
    echo "  database: $PG_DB"
    echo "  password: $PG_PASS"
    echo ""
    echo "Write this to area/db.conf (gitignored):"
    echo "  host=localhost port=5432 dbname=$PG_DB user=$PG_USER password=$PG_PASS sslmode=prefer"
fi
