#!/bin/sh
# Fix the running tngdb-api service after install:
#   - creates the tngapi home directory (needed by asyncpg SSL cert discovery)
#   - patches ProtectHome=true -> ProtectHome=read-only in the installed unit
#   - reloads systemd and restarts the service
# Run as root.

set -e

SERVICE_USER=tngapi
UNIT_FILE=/etc/systemd/system/tngdb-api.service
UNIT_NAME=tngdb-api

echo "==> Ensuring home directory exists for $SERVICE_USER ..."
if ! id "$SERVICE_USER" >/dev/null 2>&1; then
    echo "ERROR: user '$SERVICE_USER' does not exist; run install-api-server.sh first." >&2
    exit 1
fi

HOME_DIR="$(getent passwd "$SERVICE_USER" | cut -d: -f6)"
if [ -z "$HOME_DIR" ] || [ "$HOME_DIR" = "/" ]; then
    echo "ERROR: could not determine home directory for $SERVICE_USER" >&2
    exit 1
fi

if [ ! -d "$HOME_DIR" ]; then
    mkdir -p "$HOME_DIR"
    chown "$SERVICE_USER:$SERVICE_USER" "$HOME_DIR"
    chmod 700 "$HOME_DIR"
    echo "    created $HOME_DIR"
else
    echo "    $HOME_DIR already exists"
fi

echo "==> Patching $UNIT_FILE ..."
if grep -q 'ProtectHome=true' "$UNIT_FILE"; then
    sed -i 's/ProtectHome=true/ProtectHome=read-only/' "$UNIT_FILE"
    echo "    ProtectHome=true -> ProtectHome=read-only"
elif grep -q 'ProtectHome=read-only' "$UNIT_FILE"; then
    echo "    already set to read-only, no change needed"
else
    echo "    WARNING: ProtectHome line not found in $UNIT_FILE"
fi

echo "==> Reloading systemd and restarting $UNIT_NAME ..."
systemctl daemon-reload
systemctl restart "$UNIT_NAME"
sleep 2
systemctl status "$UNIT_NAME" --no-pager

echo ""
echo "Done. Check logs with: journalctl -u $UNIT_NAME -f"
