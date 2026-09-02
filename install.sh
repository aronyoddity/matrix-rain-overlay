#!/usr/bin/env bash
# Installs the Matrix Rain desktop overlay for the current user.
#
# Copies scripts to ~/.local/bin, config to ~/.config/cmatrix-overlay,
# and adds a desktop launcher icon. Safe to re-run (overwrites its own
# files only).
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/cmatrix-overlay"
APPS_DIR="$HOME/.local/share/applications"

echo "== Matrix Rain overlay installer =="
echo

missing=()
command -v alacritty  >/dev/null 2>&1 || missing+=("alacritty")
command -v picom      >/dev/null 2>&1 || missing+=("picom")
command -v python3    >/dev/null 2>&1 || missing+=("python3")
python3 -c "import Xlib" >/dev/null 2>&1 || missing+=("python3-xlib (pip package: python-xlib)")

if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Missing dependencies:"
    for dep in "${missing[@]}"; do echo "  - $dep"; done
    echo
    echo "This overlay requires an X11 desktop (not Wayland) with the"
    echo "alacritty terminal and picom compositor installed. Install the"
    echo "missing packages above (e.g. via your distro's package manager,"
    echo "and 'pip install --user python-xlib' for python3-xlib), then"
    echo "re-run this script."
    exit 1
fi

if [[ -n "${WAYLAND_DISPLAY:-}" && -z "${DISPLAY:-}" ]]; then
    echo "Warning: this looks like a Wayland-only session. This overlay"
    echo "relies on X11/EWMH window tricks and will not work under pure"
    echo "Wayland. Continuing install anyway, in case Xwayland is available."
    echo
fi

mkdir -p "$BIN_DIR" "$CONFIG_DIR" "$APPS_DIR" "$HOME/Desktop"

echo "Installing scripts to $BIN_DIR ..."
install -m 755 "$SRC_DIR/bin/cmatrix-overlay"           "$BIN_DIR/cmatrix-overlay"
install -m 755 "$SRC_DIR/bin/cmatrix-overlay-stop"       "$BIN_DIR/cmatrix-overlay-stop"
install -m 755 "$SRC_DIR/bin/cmatrix-overlay-setup.py"   "$BIN_DIR/cmatrix-overlay-setup.py"
install -m 755 "$SRC_DIR/bin/matrix-rain.py"             "$BIN_DIR/matrix-rain.py"

echo "Installing config to $CONFIG_DIR ..."
install -m 644 "$SRC_DIR/config/alacritty.toml" "$CONFIG_DIR/alacritty.toml"
install -m 644 "$SRC_DIR/config/picom.conf"     "$CONFIG_DIR/picom.conf"

echo "Installing desktop launcher ..."
sed "s|__HOME__|$HOME|g" "$SRC_DIR/desktop/matrix-overlay.desktop.template" > "$HOME/Desktop/matrix-overlay.desktop"
chmod +x "$HOME/Desktop/matrix-overlay.desktop"
sed "s|__HOME__|$HOME|g" "$SRC_DIR/desktop/matrix-overlay.desktop.template" > "$APPS_DIR/matrix-overlay.desktop"
chmod +x "$APPS_DIR/matrix-overlay.desktop"

echo
echo "Done. Make sure $BIN_DIR is on your PATH."
echo
echo "Run it:"
echo "  cmatrix-overlay          # start (or double-click the Matrix Rain desktop icon)"
echo "  cmatrix-overlay-stop     # stop"
echo "  cmatrix-overlay-stop --all  # stop and also kill picom"
