#!/usr/bin/env bash
# Removes everything install.sh created (config, scripts, desktop icons).
# Leaves alacritty/picom themselves installed since they're general system
# tools, not part of this project.
set -euo pipefail

"$HOME/.local/bin/cmatrix-overlay-stop" --all 2>/dev/null || true

rm -f  "$HOME/.local/bin/cmatrix-overlay"
rm -f  "$HOME/.local/bin/cmatrix-overlay-stop"
rm -f  "$HOME/.local/bin/cmatrix-overlay-setup.py"
rm -f  "$HOME/.local/bin/matrix-rain.py"
rm -rf "$HOME/.config/cmatrix-overlay"
rm -f  "$HOME/Desktop/matrix-overlay.desktop"
rm -f  "$HOME/.local/share/applications/matrix-overlay.desktop"

echo "Matrix Rain overlay uninstalled."
