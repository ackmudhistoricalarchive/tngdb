#!/bin/sh
# Install the ACK!TNG API server and configure it to autostart via systemd.
# Run as root (or via sudo).
#
# Usage: install-api-server.sh [--database-url URL] [--port PORT]
#   --database-url URL   asyncpg DSN for the acktng database.
#                        Defaults to postgres://ack:@localhost/acktng
#                        (reads password from area/db.conf if present).
#   --port PORT          TCP port to listen on (default: 8000).
#
# The script installs to /opt/tngdb and creates a dedicated 'tngapi' system
# user.  Configuration is written to /etc/tngdb-api.env (mode 640, owned by
# root:tngapi).  A systemd unit is installed and enabled.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

DATABASE_URL=
PORT=8000
INSTALL_DIR=/opt/tngdb
SERVICE_USER=tngapi
ENV_FILE=/etc/tngdb-api.env
UNIT_NAME=tngdb-api
UNIT_FILE=/etc/systemd/system/${UNIT_NAME}.service

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
while [ $# -gt 0 ]; do
    case "$1" in
        --database-url)
            DATABASE_URL="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

# Fall back to area/db.conf for the database URL if not supplied
if [ -z "$DATABASE_URL" ] && [ -f "$REPO_DIR/area/db.conf" ]; then
    . "$REPO_DIR/area/db.conf" 2>/dev/null || true
    # db.conf sets shell variables: host, port (pg), dbname, user, password, sslmode
    DB_HOST="${host:-localhost}"
    DB_PORT="${port:-5432}"
    DB_NAME="${dbname:-acktng}"
    DB_USER="${user:-ack}"
    DB_PASS="${password:-}"
    DB_SSL="${sslmode:-prefer}"
    DATABASE_URL="postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=${DB_SSL}"
fi

if [ -z "$DATABASE_URL" ]; then
    echo "WARNING: area/db.conf not found and --database-url not supplied." >&2
    echo "         Falling back to postgres://ack:@localhost/acktng (empty password)." >&2
    echo "         If the 'ack' role has a password, the service will fail to start." >&2
    echo "         Run scripts/fix-api-server-db-password.sh to correct this later." >&2
    DATABASE_URL="postgres://ack:@localhost/acktng"
fi

# ---------------------------------------------------------------------------
# System packages
# ---------------------------------------------------------------------------
apt-get update
apt-get install -y python3 python3-venv python3-pip

# ---------------------------------------------------------------------------
# Dedicated service user
# ---------------------------------------------------------------------------
if ! id "$SERVICE_USER" >/dev/null 2>&1; then
    useradd --system --create-home --shell /usr/sbin/nologin "$SERVICE_USER"
fi

# ---------------------------------------------------------------------------
# Install tree
# ---------------------------------------------------------------------------
mkdir -p "$INSTALL_DIR"

# Copy repo content (api/ package and scripts/) without overwriting .git or area/
rsync -a --exclude='.git' "$REPO_DIR/" "$INSTALL_DIR/"

# ---------------------------------------------------------------------------
# Python virtual environment + dependencies
# ---------------------------------------------------------------------------
python3 -m venv "$INSTALL_DIR/venv"
"$INSTALL_DIR/venv/bin/pip" install --quiet --upgrade pip
"$INSTALL_DIR/venv/bin/pip" install --quiet -r "$INSTALL_DIR/api/requirements.txt"

# ---------------------------------------------------------------------------
# Environment file
# ---------------------------------------------------------------------------
cat > "$ENV_FILE" <<EOF
DATABASE_URL=${DATABASE_URL}
EOF
chmod 640 "$ENV_FILE"
chown "root:$SERVICE_USER" "$ENV_FILE"

# ---------------------------------------------------------------------------
# Ownership
# ---------------------------------------------------------------------------
chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR"

# ---------------------------------------------------------------------------
# Systemd unit (patch port if non-default)
# ---------------------------------------------------------------------------
cp "$INSTALL_DIR/scripts/tngdb-api.service" "$UNIT_FILE"
if [ "$PORT" != "8000" ]; then
    sed -i "s/--port 8000/--port $PORT/" "$UNIT_FILE"
fi
# Update WorkingDirectory to match install dir
sed -i "s|WorkingDirectory=.*|WorkingDirectory=$INSTALL_DIR|" "$UNIT_FILE"

# Replace the generic 'postgresql.service' dependency with the concrete instance
# unit (e.g. postgresql@16-main.service).  The meta postgresql.service is a
# oneshot /bin/true that succeeds immediately and does NOT guarantee the real
# PostgreSQL process is running; the instance unit is Type=forking and only
# becomes active once PostgreSQL is accepting connections.
PG_VER="$(pg_lsclusters --no-header 2>/dev/null | awk 'NR==1 {print $1}')"
PG_CL="$(pg_lsclusters --no-header 2>/dev/null | awk 'NR==1 {print $2}')"
if [ -n "$PG_VER" ] && [ -n "$PG_CL" ]; then
    PG_UNIT="postgresql@${PG_VER}-${PG_CL}.service"
    sed -i "s/postgresql\.service/$PG_UNIT/g" "$UNIT_FILE"
fi

systemctl daemon-reload
systemctl enable "$UNIT_NAME"
systemctl restart "$UNIT_NAME"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "ACK!TNG API server installed and started."
echo "  install dir: $INSTALL_DIR"
echo "  env file:    $ENV_FILE"
echo "  port:        $PORT"
echo "  docs:        http://localhost:$PORT/docs"
echo ""
echo "Manage with:"
echo "  systemctl status $UNIT_NAME"
echo "  journalctl -u $UNIT_NAME -f"
