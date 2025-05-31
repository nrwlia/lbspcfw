#!/usr/bin/env bash
set -euo pipefail

#
# uninstall_css_texture_fix.sh
#
# This script will:
#   1) Stop & disable the user‐systemd units (css_texture_fix.path & .service).
#   2) Remove those unit files from ~/.config/systemd/user/.
#   3) Reload the user‐systemd daemon.
#   4) Remove the “bspfix” folder that was created under your CS:S install.
#
# Usage:
#   1) Save this script somewhere (e.g. alongside your installer).
#   2) chmod +x uninstall_css_texture_fix.sh
#   3) Run: ./uninstall_css_texture_fix.sh
#

echo "[UNINSTALL] Starting CSS Texture Fix uninstallation..."

# ────────────────────────────────────────────────────────────────────────────
# 1) Detect the real CS:S folder (same logic as installer)
# ────────────────────────────────────────────────────────────────────────────
REAL_CS_DIR="$HOME/.local/share/Steam/steamapps/common/Counter-Strike Source"
if [ ! -d "$REAL_CS_DIR" ]; then
    REAL_CS_DIR="$HOME/.steam/steam/steamapps/common/Counter-Strike Source"
fi

if [ ! -d "$REAL_CS_DIR" ]; then
    echo "[WARNING] Could not find the Counter-Strike Source folder in either:"
    echo "           ~/.local/share/Steam/steamapps/common/Counter-Strike Source"
    echo "         or  ~/.steam/steam/steamapps/common/Counter-Strike Source"
    echo "[WARNING] Skipping removal of bspfix folder since the CS:S folder wasn’t found."
    REMOVE_BSPFIX=false
else
    echo "[UNINSTALL] Found CS:S directory at:"
    echo "           → \"$REAL_CS_DIR\""
    BSPFIX_DIR="$REAL_CS_DIR/bspfix"
    REMOVE_BSPFIX=true
fi

# ────────────────────────────────────────────────────────────────────────────
# 2) Define unit base name and unit file paths
# ────────────────────────────────────────────────────────────────────────────
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
UNIT_BASE_NAME="css_texture_fix"
SERVICE_UNIT_PATH="$SYSTEMD_USER_DIR/$UNIT_BASE_NAME.service"
PATH_UNIT_PATH="$SYSTEMD_USER_DIR/$UNIT_BASE_NAME.path"

# ────────────────────────────────────────────────────────────────────────────
# 3) Stop & disable the units (ignore errors if they don’t exist)
# ────────────────────────────────────────────────────────────────────────────
echo "[UNINSTALL] Stopping & disabling user‐systemd units..."
systemctl --user stop "${UNIT_BASE_NAME}.path"     > /dev/null 2>&1 || true
systemctl --user disable "${UNIT_BASE_NAME}.path"  > /dev/null 2>&1 || true
systemctl --user stop "${UNIT_BASE_NAME}.service"  > /dev/null 2>&1 || true
systemctl --user disable "${UNIT_BASE_NAME}.service" > /dev/null 2>&1 || true

# ────────────────────────────────────────────────────────────────────────────
# 4) Remove the unit files
# ────────────────────────────────────────────────────────────────────────────
echo "[UNINSTALL] Removing unit files from:"
echo "           → \"$SYSTEMD_USER_DIR\""
if [ -f "$SERVICE_UNIT_PATH" ]; then
    rm -f "$SERVICE_UNIT_PATH"
    echo "  • Removed: $(basename "$SERVICE_UNIT_PATH")"
else
    echo "  • Not found: $(basename "$SERVICE_UNIT_PATH")"
fi

if [ -f "$PATH_UNIT_PATH" ]; then
    rm -f "$PATH_UNIT_PATH"
    echo "  • Removed: $(basename "$PATH_UNIT_PATH")"
else
    echo "  • Not found: $(basename "$PATH_UNIT_PATH")"
fi

# ────────────────────────────────────────────────────────────────────────────
# 5) Reload user‐systemd daemon
# ────────────────────────────────────────────────────────────────────────────
echo "[UNINSTALL] Reloading systemd user daemon..."
systemctl --user daemon-reload

# ────────────────────────────────────────────────────────────────────────────
# 6) Remove the bspfix folder (if it exists)
# ────────────────────────────────────────────────────────────────────────────
if [ "$REMOVE_BSPFIX" = true ]; then
    if [ -d "$BSPFIX_DIR" ]; then
        echo "[UNINSTALL] Removing bspfix folder:"
        echo "           → \"$BSPFIX_DIR\""
        rm -rf "$BSPFIX_DIR"
    else
        echo "[UNINSTALL] bspfix folder not found at:"
        echo "           → \"$BSPFIX_DIR\""
    fi
fi

echo "[UNINSTALL] Completed CSS Texture Fix removal."
echo "[UNINSTALL] If you see no errors above, everything has been cleaned up."
