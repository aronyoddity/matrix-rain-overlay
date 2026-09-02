#!/usr/bin/env python3
"""Adds or removes (--remove) an Openbox keybind that runs a command.

Used by install.sh/uninstall.sh to wire up a hotkey for
cmatrix-overlay-toggle. This does a text-based, marker-delimited edit of
rc.xml rather than parsing/re-serializing the XML, so it never disturbs the
rest of the user's config (comments, formatting, unrelated keybinds) --
it only ever touches the block between its own markers.
"""
import re
import subprocess
import sys
from pathlib import Path

MARKER_BEGIN = "    <!-- BEGIN cmatrix-overlay-toggle keybind (managed by install.sh) -->"
MARKER_END = "    <!-- END cmatrix-overlay-toggle keybind -->"
BLOCK_RE = re.compile(re.escape(MARKER_BEGIN) + r".*?" + re.escape(MARKER_END) + r"\n?", re.DOTALL)


def load_rc():
    rc_path = Path.home() / ".config" / "openbox" / "rc.xml"
    if not rc_path.exists():
        print(f"{rc_path} not found -- not an Openbox session?", file=sys.stderr)
        sys.exit(1)
    return rc_path, rc_path.read_text()


def backup(rc_path, original_text):
    backup_path = rc_path.with_suffix(rc_path.suffix + ".bak")
    if not backup_path.exists():
        backup_path.write_text(original_text)


def reconfigure():
    subprocess.run(["openbox", "--reconfigure"], check=False)


def main():
    rc_path, text = load_rc()
    original_text = text

    if sys.argv[1:2] == ["--remove"]:
        new_text = BLOCK_RE.sub("", text)
        if new_text != text:
            rc_path.write_text(new_text)
            reconfigure()
            print("Removed the cmatrix-overlay-toggle keybind.")
        return

    if len(sys.argv) != 3:
        print("usage: install_keybind.py <key-combo> <command>", file=sys.stderr)
        print("       install_keybind.py --remove", file=sys.stderr)
        sys.exit(2)

    key, command = sys.argv[1], sys.argv[2]
    text = BLOCK_RE.sub("", text)

    if re.search(rf'key="{re.escape(key)}"', text):
        print(f"'{key}' is already bound to something else in rc.xml.", file=sys.stderr)
        sys.exit(1)

    if "</keyboard>" not in text:
        print("Could not find </keyboard> in rc.xml; skipping keybind install.", file=sys.stderr)
        sys.exit(1)

    block = (
        f"{MARKER_BEGIN}\n"
        f'    <keybind key="{key}">\n'
        f'      <action name="Execute">\n'
        f"        <command>{command}</command>\n"
        f"      </action>\n"
        f"    </keybind>\n"
        f"{MARKER_END}\n"
    )
    # Match (and replace) any leading whitespace on the </keyboard> line too,
    # so re-running this doesn't leave accumulating stray indentation.
    text = re.sub(r"[ \t]*</keyboard>", lambda _m: block + "  </keyboard>", text, count=1)

    backup(rc_path, original_text)
    rc_path.write_text(text)
    reconfigure()
    print(f"Bound {key} to toggle the overlay (backup saved to {rc_path}.bak).")


if __name__ == "__main__":
    main()
