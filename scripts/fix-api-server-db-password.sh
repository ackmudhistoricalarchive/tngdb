#!/bin/sh
# Fix the DATABASE_URL password in /etc/tngdb-api.env when the tngdb-api
# service fails with "password authentication failed for user ack".
#
# Usage: fix-api-server-db-password.sh [--password PASSWORD] [--database-url URL]
#   --password PASSWORD   New password for the 'ack' PostgreSQL role.
#                         Also updates the PostgreSQL role to match.
#                         If omitted, reads from area/db.conf (if present).
#   --database-url URL    Full asyncpg DSN (overrides --password).
#
# Run as root.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ENV_FILE=/etc/tngdb-api.env
UNIT_NAME=tngdb-api
PG_USER=ack
PG_DB=acktng

DATABASE_URL=
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
        --database-url)
            DATABASE_URL="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

# Fall back to area/db.conf
if [ -z "$DATABASE_URL" ] && [ -z "$PG_PASS" ] && [ -f "$REPO_DIR/area/db.conf" ]; then
    . "$REPO_DIR/area/db.conf" 2>/dev/null || true
    DB_HOST="${host:-localhost}"
    DB_PORT="${port:-5432}"
    DB_NAME="${dbname:-$PG_DB}"
    DB_USER="${user:-$PG_USER}"
    DB_PASS="${password:-}"
    DB_SSL="${sslmode:-prefer}"
    DATABASE_URL="postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=${DB_SSL}"
    echo "==> Loaded credentials from $REPO_DIR/area/db.conf"
fi

# Build URL from --password if no full URL supplied
if [ -z "$DATABASE_URL" ] && [ -n "$PG_PASS" ]; then
    DATABASE_URL="postgres://${PG_USER}:${PG_PASS}@localhost/${PG_DB}?sslmode=prefer"
fi

if [ -z "$DATABASE_URL" ]; then
    echo "ERROR: supply --password PASSWORD or --database-url URL, or create area/db.conf." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Optionally update the PostgreSQL role password when --password was given
# ---------------------------------------------------------------------------
if [ -n "$PG_PASS" ]; then
    echo "==> Updating PostgreSQL password for role '$PG_USER' ..."
    sudo -u postgres psql -v ON_ERROR_STOP=1 -c "ALTER ROLE ${PG_USER} PASSWORD '${PG_PASS}';"
    echo "    done."
fi

# ---------------------------------------------------------------------------
# Update the env file
# ---------------------------------------------------------------------------
if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: $ENV_FILE not found; run install-api-server.sh first." >&2
    exit 1
fi

echo "==> Updating DATABASE_URL in $ENV_FILE ..."
# Replace the DATABASE_URL line in-place; preserve any other variables.
if grep -q '^DATABASE_URL=' "$ENV_FILE"; then
    sed -i "s|^DATABASE_URL=.*|DATABASE_URL=${DATABASE_URL}|" "$ENV_FILE"
else
    echo "DATABASE_URL=${DATABASE_URL}" >> "$ENV_FILE"
fi
echo "    done."

# ---------------------------------------------------------------------------
# Restart the service
# ---------------------------------------------------------------------------
echo "==> Restarting $UNIT_NAME ..."
systemctl daemon-reload
systemctl restart "$UNIT_NAME"
sleep 2
systemctl status "$UNIT_NAME" --no-pager

echo ""
echo "Done. Check logs with: journalctl -u $UNIT_NAME -f"
