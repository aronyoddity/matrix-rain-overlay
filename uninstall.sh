#!/usr/bin/env bash
# Removes everything install.sh created (config, scripts, desktop icons,
# and the toggle hotkey if one was set up). Leaves alacritty/picom
# themselves installed since they're general system tools, not part of
# this project.
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$HOME/.local/bin/cmatrix-overlay-stop" --all 2>/dev/null || true

if [[ -f "$HOME/.config/openbox/rc.xml" ]]; then
    python3 "$SRC_DIR/lib/install_keybind.py" --remove || true
fi

rm -f  "$HOME/.local/bin/cmatrix-overlay"
rm -f  "$HOME/.local/bin/cmatrix-overlay-stop"
rm -f  "$HOME/.local/bin/cmatrix-overlay-toggle"
rm -f  "$HOME/.local/bin/cmatrix-overlay-set-color"
rm -f  "$HOME/.local/bin/cmatrix-overlay-setup.py"
rm -f  "$HOME/.local/bin/matrix-rain.py"
rm -rf "$HOME/.config/cmatrix-overlay"
rm -f  "$HOME/Desktop/matrix-overlay.desktop"
rm -f  "$HOME/.local/share/applications/matrix-overlay.desktop"

echo "Matrix Rain overlay uninstalled."
