#!/usr/bin/env bash
set -euo pipefail

#
# install_css_texture_fix.sh
#
# This script will:
#   1) Verify (or create) a `bspfix` folder inside your Counter-Strike Source install.
#   2) Copy `fix_textures.sh` into that `bspfix` folder and mark it executable.
#   3) Drop two systemd‐user unit files into ~/.config/systemd/user/:
#        • css_texture_fix.service
#        • css_texture_fix.path
#      Each unit refers to paths under
#        ~/.local/share/Steam/steamapps/common/Counter-Strike\x20Source/…
#      (“\x20” tells systemd to treat that as a space).
#   4) Reloads systemd‐user, enables/starts the `.path` unit so that whenever
#      anything changes in the CS:S “maps” folder, systemd fires the `.service`
#      which runs `fix_textures.sh` with its working directory set to `bspfix`.
#
# Usage:
#   1. Place this script and your fix_textures.sh in the same folder.
#   2. chmod +x install_css_texture_fix.sh
#   3. ./install_css_texture_fix.sh
#

# ────────────────────────────────────────────────────────────────────────────
# 1) Define where your “Counter-Strike Source” folder lives (with spaces).
#    We’ll assume the default Steam location. If yours is elsewhere, edit here.
# ────────────────────────────────────────────────────────────────────────────

REAL_CS_DIR="$HOME/.local/share/Steam/steamapps/common/Counter-Strike Source"
if [ ! -d "$REAL_CS_DIR" ]; then
    REAL_CS_DIR="$HOME/.steam/steam/steamapps/common/Counter-Strike Source"
fi

if [ ! -d "$REAL_CS_DIR" ]; then
    echo "[ERROR] Could not find the Counter-Strike Source folder in either:"
    echo "         ~/.local/share/Steam/steamapps/common/Counter-Strike Source"
    echo "      or ~/.steam/steam/steamapps/common/Counter-Strike Source"
    echo "[ERROR] Please edit REAL_CS_DIR at the top of this script if yours is elsewhere."
    exit 1
fi

echo "[INFO] Found CS:S directory at:"
echo "       → \"$REAL_CS_DIR\""

# ────────────────────────────────────────────────────────────────────────────
# 2) Create (if needed) the “bspfix” folder inside CS:S
# ────────────────────────────────────────────────────────────────────────────

BSPFIX_DIR="$REAL_CS_DIR/bspfix"
echo "[INSTALL] Ensuring bspfix directory exists at:"
echo "           → \"$BSPFIX_DIR\""
mkdir -p "$BSPFIX_DIR"

# ────────────────────────────────────────────────────────────────────────────
# 3) Copy fix_textures.sh to that folder
# ────────────────────────────────────────────────────────────────────────────

if [ ! -f "./fix_textures.sh" ]; then
    echo "[ERROR] Cannot find fix_textures.sh in the current directory."
    echo "[ERROR] Make sure you run this installer from the folder containing fix_textures.sh."
    exit 1
fi

echo "[INSTALL] Copying fix_textures.sh →"
echo "           → \"$BSPFIX_DIR/\""
cp ./fix_textures.sh "$BSPFIX_DIR/"
chmod +x "$BSPFIX_DIR/fix_textures.sh"

# ────────────────────────────────────────────────────────────────────────────
# 4) Prepare systemd‐user directory
# ────────────────────────────────────────────────────────────────────────────

SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"
UNIT_BASE_NAME="css_texture_fix"   # Creates css_texture_fix.service & .path

# ────────────────────────────────────────────────────────────────────────────
# 5) Create css_texture_fix.service
# ────────────────────────────────────────────────────────────────────────────

SERVICE_UNIT="$SYSTEMD_USER_DIR/$UNIT_BASE_NAME.service"
echo "[INSTALL] Writing service unit →"
echo "           → \"$SERVICE_UNIT\""
cat > "$SERVICE_UNIT" <<EOF
[Unit]
Description=CS:S Texture Fixer (runs fix_textures.sh from bspfix)

[Service]
Type=oneshot
# We’ll launch via bash -c so we can ‘cd’ into the bspfix folder first.
ExecStart=/usr/bin/env bash -c "cd '%h/.local/share/Steam/steamapps/common/Counter-Strike\x20Source/bspfix' && ./fix_textures.sh"

[Install]
WantedBy=default.target
EOF

# ────────────────────────────────────────────────────────────────────────────
# 6) Create css_texture_fix.path
# ────────────────────────────────────────────────────────────────────────────

# The folder we want to watch (maps downloaded by CS:S):
#   ~/.local/share/Steam/steamapps/common/Counter-Strike\x20Source/cstrike/download/maps
PATH_UNIT="$SYSTEMD_USER_DIR/$UNIT_BASE_NAME.path"
echo "[INSTALL] Writing path unit →"
echo "           → \"$PATH_UNIT\""
cat > "$PATH_UNIT" <<EOF
[Unit]
Description=Watch CS:S ‘cstrike/download/maps’ for new files → trigger fix

[Path]
# Watching for any create/modify/delete in that folder:
PathModified=/home/$USER/.local/share/Steam/steamapps/common/Counter-Strike Source/cstrike/download/maps
Unit=$UNIT_BASE_NAME.service

[Install]
WantedBy=default.target
EOF

# ────────────────────────────────────────────────────────────────────────────
# 7) Reload systemd‐user, enable & start the path watcher
# ────────────────────────────────────────────────────────────────────────────

echo "[INSTALL] Reloading systemd user daemon..."
systemctl --user daemon-reload

echo "[INSTALL] Enabling & starting → \"$UNIT_BASE_NAME.path\""
systemctl --user enable --now "$UNIT_BASE_NAME.path"
echo "[INSTALL] Enabling → \"$UNIT_BASE_NAME.service\""
systemctl --user enable "$UNIT_BASE_NAME.service"

echo "[INSTALL] Installation complete."
echo "[INSTALL] systemd is now watching:"
echo "           → \"$HOME/.local/share/Steam/steamapps/common/Counter-Strike Source/cstrike/download/maps\""
echo "[INSTALL] On any change, it will run:"
echo "           → \"$BSPFIX_DIR/fix_textures.sh\""
echo "[INSTALL] Check status with:"
echo "           systemctl --user status $UNIT_BASE_NAME.path"
echo "[INSTALL] View the fixer’s output with:"
echo "           journalctl --user -u $UNIT_BASE_NAME.service -f"
