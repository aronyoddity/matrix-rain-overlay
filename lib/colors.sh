#!/usr/bin/env bash
# Shared color palette + config renderer for the Matrix rain overlay.
# Sourced by install.sh and cmatrix-overlay-set-color -- not meant to be
# run directly.

# Hand-tuned "vivid rain / glowing lead character" hex pairs for the named
# colors cmatrix-overlay-set-color accepts.
color_pair_for_name() {
    case "$1" in
        green)   echo "00ff41 66ff9c" ;;
        red)     echo "ff1a1a ff8080" ;;
        blue)    echo "1a75ff 99c2ff" ;;
        yellow)  echo "ffe135 fff5a0" ;;
        cyan)    echo "00e5ff 99faff" ;;
        magenta) echo "ff33cc ff99ee" ;;
        white)   echo "e6e6e6 ffffff" ;;
        *) return 1 ;;
    esac
}

# Blends a 6-digit hex color toward white by pct% (0-100). Used to derive a
# "glow" shade for the bold/leading characters from an arbitrary custom hex
# that isn't one of the curated named pairs above.
lighten_hex() {
    local hex="${1#\#}" pct="$2"
    local r=$((16#${hex:0:2})) g=$((16#${hex:2:2})) b=$((16#${hex:4:2}))
    r=$(( r + (255 - r) * pct / 100 ))
    g=$(( g + (255 - g) * pct / 100 ))
    b=$(( b + (255 - b) * pct / 100 ))
    printf '%02x%02x%02x' "$r" "$g" "$b"
}

# Prints "<normal_hex> <bright_hex>" for a named color or a raw 6-digit hex
# code (with or without a leading #). Returns non-zero if input matches
# neither.
resolve_color() {
    local input="$1" pair hex
    if pair=$(color_pair_for_name "$input"); then
        echo "$pair"
        return 0
    fi
    hex="${input#\#}"
    if [[ "$hex" =~ ^[0-9a-fA-F]{6}$ ]]; then
        echo "$hex $(lighten_hex "$hex" 45)"
        return 0
    fi
    return 1
}

render_alacritty_config() {
    local normal="$1" bright="$2" template="$3" dest="$4"
    sed -e "s/__NORMAL_HEX__/$normal/g" -e "s/__BRIGHT_HEX__/$bright/g" \
        "$template" > "$dest"
}
