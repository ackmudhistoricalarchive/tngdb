#!/bin/bash
set -euo pipefail
TARGET="deploy@10.1.0.249"
SSH="ssh -o StrictHostKeyChecking=no"
rsync -a --delete --no-group --exclude='.venv' --exclude='__pycache__' --exclude='.git' \
    -e "$SSH" ./ "$TARGET":/opt/tngdb/
$SSH "$TARGET" "/opt/tngdb/.venv/bin/pip install -r /opt/tngdb/api/requirements.txt -q"
$SSH "$TARGET" "sudo systemctl restart tngdb"
echo "Deployed to tngdb"
