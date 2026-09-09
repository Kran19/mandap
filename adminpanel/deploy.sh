#!/usr/bin/env bash
# ==============================================================================
# Mandap Live Server Deployment Script (Adminpanel Folder)
# Usage: ./deploy.sh [branch]
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -f "$ROOT_DIR/deploy.sh" ]; then
    exec "$ROOT_DIR/deploy.sh" "$@"
fi

echo "[ERROR] Root deploy.sh not found at $ROOT_DIR/deploy.sh"
exit 1
