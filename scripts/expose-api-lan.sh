#!/bin/sh
# Rebind the tngdb-api service to all network interfaces so it is reachable
# from the LAN (not just loopback).  Run as root (or via sudo).
#
# Usage: install-nginx-proxy.sh [--port PORT]
#   --port PORT   TCP port to listen on (default: 8000).

set -e

PORT=8000
API_SERVICE=tngdb-api
UNIT_FILE=/etc/systemd/system/${API_SERVICE}.service

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
while [ $# -gt 0 ]; do
    case "$1" in
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

# ---------------------------------------------------------------------------
# Verify the service unit exists
# ---------------------------------------------------------------------------
if [ ! -f "$UNIT_FILE" ]; then
    echo "ERROR: $UNIT_FILE not found." >&2
    echo "       Run scripts/install-api-server.sh first." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Patch host and port in the installed unit file
# ---------------------------------------------------------------------------
CURRENT_HOST="$(grep -o -- '--host [^ ]*' "$UNIT_FILE" | awk '{print $2}')"
CURRENT_PORT="$(grep -o -- '--port [0-9]*' "$UNIT_FILE" | awk '{print $2}')"

if [ "$CURRENT_HOST" != "0.0.0.0" ]; then
    sed -i "s/--host $CURRENT_HOST/--host 0.0.0.0/" "$UNIT_FILE"
    echo "Bind address: $CURRENT_HOST -> 0.0.0.0"
else
    echo "Bind address already 0.0.0.0, no change needed."
fi

if [ "$CURRENT_PORT" != "$PORT" ]; then
    sed -i "s/--port $CURRENT_PORT/--port $PORT/" "$UNIT_FILE"
    echo "Port: $CURRENT_PORT -> $PORT"
fi

systemctl daemon-reload
systemctl restart "$API_SERVICE"
sleep 1
systemctl status "$API_SERVICE" --no-pager

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "API now reachable on all interfaces, port ${PORT}."
echo "  docs: http://$(hostname -I | awk '{print $1}'):${PORT}/docs"
