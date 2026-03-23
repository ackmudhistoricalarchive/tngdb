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
SCHEMA="$SCRIPT_DIR/../../acktng/area/schema.sql"

if [ ! -f "$SCHEMA" ]; then
    echo "ERROR: cannot find acktng schema at $SCHEMA" >&2
    echo "       Make sure acktng is cloned alongside tngdb (e.g. via aicli setup.sh)." >&2
    exit 1
fi
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

sudo -u postgres dropdb --if-exists "$PG_DB"
sudo -u postgres createdb --owner="$PG_USER" "$PG_DB"

# ---------------------------------------------------------------------------
# Schema
# ---------------------------------------------------------------------------
sudo -u postgres psql -v ON_ERROR_STOP=1 -d "$PG_DB" < "$SCHEMA"

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
# ---------------------------------------------------------------------------
# Ensure the PostgreSQL instance service is enabled so it survives reboots.
# The meta postgresql.service (a oneshot /bin/true) is enabled by the apt
# postinst, but it does NOT pull in the real instance service on boot.
# We have to enable postgresql@<version>-<cluster>.service explicitly.
# ---------------------------------------------------------------------------
PG_VERSION="$(pg_lsclusters --no-header 2>/dev/null | awk 'NR==1 {print $1}')"
PG_CLUSTER_NAME="$(pg_lsclusters --no-header 2>/dev/null | awk 'NR==1 {print $2}')"
if [ -n "$PG_VERSION" ] && [ -n "$PG_CLUSTER_NAME" ]; then
    PG_INSTANCE_UNIT="postgresql@${PG_VERSION}-${PG_CLUSTER_NAME}.service"
    systemctl enable "$PG_INSTANCE_UNIT" || true
    systemctl start  "$PG_INSTANCE_UNIT" || pg_ctlcluster "$PG_VERSION" "$PG_CLUSTER_NAME" start || true
fi

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
