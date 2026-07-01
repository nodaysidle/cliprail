#!/bin/bash
set -euo pipefail
# install_app.sh — install ClipRail.app to /Applications
# Kills existing, backs up previous, copies fresh, removes quarantine, verifies, launches.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_SOURCE="$PROJECT_DIR/build/ClipRail.app"
INSTALL_TARGET="/Applications/ClipRail.app"
BACKUP_DIR="/Applications/ClipRail.app.backup.$(date +%Y%m%d_%H%M%S)"

echo "========================================="
echo " ClipRail Install Script"
echo "========================================="

# --- Prerequisites ---
if [ ! -d "$APP_SOURCE" ]; then
    echo "ERROR: $APP_SOURCE not found. Run package_app.sh first."
    exit 1
fi

# --- Kill existing ---
echo "==> Killing existing ClipRail processes..."
pkill -x ClipRail 2>/dev/null || true
sleep 1

# --- Backup existing ---
if [ -d "$INSTALL_TARGET" ]; then
    echo "==> Backing up existing to $BACKUP_DIR"
    mv "$INSTALL_TARGET" "$BACKUP_DIR"
fi

# --- Copy fresh ---
echo "==> Copying fresh .app to /Applications..."
cp -R "$APP_SOURCE" "$INSTALL_TARGET"

# --- Remove quarantine ---
echo "==> Removing quarantine attribute..."
xattr -dr com.apple.quarantine "$INSTALL_TARGET" 2>/dev/null || true

# --- Verify codesign ---
echo "==> Verifying codesign..."
codesign --verify --deep --strict --verbose=2 "$INSTALL_TARGET" 2>&1 || {
    echo "WARNING: codesign verification failed. Ad-hoc signing..."
    codesign --force --deep --sign - "$INSTALL_TARGET"
    codesign --verify --deep --strict --verbose=2 "$INSTALL_TARGET" 2>&1
}

# --- Launch ---
echo "==> Launching ClipRail..."
open "$INSTALL_TARGET"

# Wait a moment for process to start
sleep 2

# --- Verify process ---
echo "==> Checking process..."
if pgrep -x ClipRail > /dev/null; then
    PID=$(pgrep -x ClipRail | head -1)
    echo "ClipRail is running (PID: $PID)"
else
    echo "WARNING: ClipRail process not found. It may be running as a background agent."
fi

echo "========================================="
echo " Install complete: $INSTALL_TARGET"
echo "========================================="
