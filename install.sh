#!/usr/bin/env bash
# Installs the Matrix Rain desktop overlay for the current user.
#
# Copies scripts to ~/.local/bin, config to ~/.config/cmatrix-overlay,
# and adds a desktop launcher icon. Safe to re-run (overwrites its own
# files only). Interactively asks for a rain color and a toggle hotkey
# when run in a terminal; both default to sane values and can be changed
# again later without re-running this script (see README).
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/cmatrix-overlay"
APPS_DIR="$HOME/.local/share/applications"

# shellcheck source=lib/colors.sh
source "$SRC_DIR/lib/colors.sh"

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
install -m 755 "$SRC_DIR/bin/cmatrix-overlay"          "$BIN_DIR/cmatrix-overlay"
install -m 755 "$SRC_DIR/bin/cmatrix-overlay-stop"      "$BIN_DIR/cmatrix-overlay-stop"
install -m 755 "$SRC_DIR/bin/cmatrix-overlay-toggle"    "$BIN_DIR/cmatrix-overlay-toggle"
install -m 755 "$SRC_DIR/bin/cmatrix-overlay-set-color" "$BIN_DIR/cmatrix-overlay-set-color"
install -m 755 "$SRC_DIR/bin/cmatrix-overlay-setup.py"  "$BIN_DIR/cmatrix-overlay-setup.py"
install -m 755 "$SRC_DIR/bin/matrix-rain.py"            "$BIN_DIR/matrix-rain.py"

echo "Installing config to $CONFIG_DIR ..."
install -m 644 "$SRC_DIR/config/alacritty.toml.template" "$CONFIG_DIR/alacritty.toml.template"
install -m 644 "$SRC_DIR/config/picom.conf"               "$CONFIG_DIR/picom.conf"
install -m 644 "$SRC_DIR/lib/colors.sh"                   "$CONFIG_DIR/colors.sh"

echo "Installing desktop launcher ..."
sed "s|__HOME__|$HOME|g" "$SRC_DIR/desktop/matrix-overlay.desktop.template" > "$HOME/Desktop/matrix-overlay.desktop"
chmod +x "$HOME/Desktop/matrix-overlay.desktop"
sed "s|__HOME__|$HOME|g" "$SRC_DIR/desktop/matrix-overlay.desktop.template" > "$APPS_DIR/matrix-overlay.desktop"
chmod +x "$APPS_DIR/matrix-overlay.desktop"

# --- Color ------------------------------------------------------------
color_choice="green"
if [[ -t 0 ]]; then
    echo
    echo "Pick a rain color (Enter for the classic Matrix green):"
    echo "  1) green (default)   5) cyan"
    echo "  2) red                6) magenta"
    echo "  3) blue               7) white"
    echo "  4) yellow             8) custom hex code"
    read -rp "Choice [1]: " choice
    case "${choice:-1}" in
        1|"") color_choice="green" ;;
        2) color_choice="red" ;;
        3) color_choice="blue" ;;
        4) color_choice="yellow" ;;
        5) color_choice="cyan" ;;
        6) color_choice="magenta" ;;
        7) color_choice="white" ;;
        8) read -rp "Hex code (no #): " color_choice ;;
        *) echo "Unrecognized choice, using green."; color_choice="green" ;;
    esac
fi

pair=$(resolve_color "$color_choice") || { echo "Unknown color '$color_choice', falling back to green."; color_choice="green"; pair=$(resolve_color green); }
read -r normal bright <<<"$pair"
render_alacritty_config "$normal" "$bright" "$CONFIG_DIR/alacritty.toml.template" "$CONFIG_DIR/alacritty.toml"
echo "$color_choice" > "$CONFIG_DIR/color.conf"
echo "Rain color: $color_choice (#$normal, glow #$bright). Change it anytime with:"
echo "  cmatrix-overlay-set-color <green|red|blue|yellow|cyan|magenta|white|RRGGBB>"

# --- Hotkey (Openbox only, interactive only) ---------------------------
if [[ -t 0 && -f "$HOME/.config/openbox/rc.xml" ]]; then
    echo
    echo "Pick a keyboard shortcut to toggle the overlay on/off."
    echo "Openbox format: W=Super, C=Ctrl, A=Alt, S=Shift, e.g. W-m for Super+M."
    echo "Leave blank to skip."
    default_hotkey="W-m"
    while true; do
        read -rp "Shortcut [$default_hotkey]: " hotkey
        hotkey="${hotkey:-$default_hotkey}"
        if [[ "$hotkey" == "-" || -z "$hotkey" ]]; then
            echo "Skipping hotkey setup. Bind $BIN_DIR/cmatrix-overlay-toggle"
            echo "to a shortcut yourself anytime via your WM's settings."
            break
        fi
        if python3 "$SRC_DIR/lib/install_keybind.py" "$hotkey" "$BIN_DIR/cmatrix-overlay-toggle"; then
            break
        fi
        echo "Try a different combo, or leave blank to skip."
        default_hotkey=""
    done
elif [[ -t 0 ]]; then
    echo
    echo "No ~/.config/openbox/rc.xml found, so hotkey setup was skipped"
    echo "(only Openbox is supported automatically right now). Bind"
    echo "$BIN_DIR/cmatrix-overlay-toggle to a shortcut via your desktop's"
    echo "keyboard shortcut settings instead."
else
    echo
    echo "Running non-interactively, so hotkey setup was skipped. Bind"
    echo "$BIN_DIR/cmatrix-overlay-toggle to a shortcut anytime (Openbox:"
    echo "re-run install.sh from a terminal; other WMs: use its shortcut settings)."
fi

echo
echo "Done. Make sure $BIN_DIR is on your PATH."
echo
echo "Run it:"
echo "  cmatrix-overlay             # start (or double-click the Matrix Rain desktop icon)"
echo "  cmatrix-overlay-stop        # stop"
echo "  cmatrix-overlay-stop --all  # stop and also kill picom"
echo "  cmatrix-overlay-toggle      # start if stopped, stop if running"
echo "  cmatrix-overlay-set-color <name|hex>  # change the rain color anytime"
