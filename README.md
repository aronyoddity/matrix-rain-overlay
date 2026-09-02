# Matrix Rain Overlay

A fullscreen, click-through Matrix-style digital rain effect for your Linux
desktop — real Unicode katakana, transparent background, and mouse clicks
pass straight through to whatever's underneath. Your own windows can still
be brought above it (e.g. via "Always on Top" in your window manager).

![status](https://img.shields.io/badge/status-works%20for%20me-brightgreen)

![Matrix rain overlay running over a desktop, with a terminal window layered on top of it](screenshots/demo.jpg)

## Requirements

- Linux with an **X11** session (Xorg, or Xwayland — not pure Wayland; the
  overlay relies on X11/EWMH window tricks that Wayland compositors don't
  expose to clients)
- [`alacritty`](https://alacritty.org/) terminal emulator
- [`picom`](https://github.com/yshui/picom) compositor (for transparency)
- Python 3 with [`python-xlib`](https://github.com/python-xlib/python-xlib)
  (`pip install --user python-xlib`, or your distro's `python3-xlib` package)

Tested on LXQt + Openbox + picom. Should work on any X11 WM that follows
EWMH (`_NET_WM_STATE`, `_NET_WM_DESKTOP`, `_NET_CLIENT_LIST`) — i.e. most
of them (Openbox, i3, XFCE, KDE/X11, etc).

## Install

```bash
git clone https://github.com/aronyoddity/matrix-rain-overlay.git
cd matrix-rain-overlay
./install.sh
```

The installer checks for missing dependencies and tells you what to install
if anything's missing. It puts scripts in `~/.local/bin`, config in
`~/.config/cmatrix-overlay`, and adds a desktop launcher icon. Run
interactively (not piped), it also asks you to:

- **pick a rain color** — green (default), red, blue, yellow, cyan,
  magenta, white, or a custom hex code
- **pick a keyboard shortcut** to toggle the overlay on/off (Openbox
  only for now; defaults to `W-m`/Super+M, skippable)

Both can be changed again later without re-running the installer — see
below.

## Use

- Double-click the **Matrix Rain** icon on your desktop, or in your
  applications menu, or:
- `cmatrix-overlay` — start (returns immediately, runs in background)
- `cmatrix-overlay-stop` — stop
- `cmatrix-overlay-stop --all` — stop and also kill picom
- `cmatrix-overlay-toggle` — start if stopped, stop if running (what the
  hotkey from install.sh calls)
- `cmatrix-overlay-set-color <green|red|blue|yellow|cyan|magenta|white|RRGGBB>`
  — change the rain color anytime; restarts the overlay to apply if it's
  currently running. Run with no argument for the interactive picker
  (same menu install.sh shows).

## Uninstall

```bash
./uninstall.sh
```

## Resource usage

Lightweight — roughly 90–100 MB RAM total (alacritty + the rain script +
picom) and a few percent of one CPU core, safe to leave running all day.

## How it works / design notes

- **Real katakana, not cmatrix's `-c` flag**: cmatrix's built-in "Japanese
  characters" mode emits legacy high bytes meant for an old X11 bitmap font
  (`mtx.pcf`), which render as blank space in any modern UTF-8 terminal.
  `bin/matrix-rain.py` is a small custom `curses` script that draws real
  half-width katakana (U+FF66–U+FF9D) plus digits instead.
- **Click-through**: the X SHAPE extension, setting the window's *input*
  shape (not bounding shape) to an empty region. The window still renders
  normally; X just never routes pointer events to it.
- **Layering**: the overlay deliberately does *not* request
  `_NET_WM_STATE_ABOVE` and is never re-raised after launch, so it sits in
  the normal stacking layer — any window you click/focus naturally ends up
  above it and stays there. This is what makes "Always on Top" on your own
  windows actually work.
- **Fullscreen + all-desktops**: raw EWMH client messages
  (`_NET_WM_DESKTOP` = all desktops, `_NET_WM_STATE_STICKY`/
  `SKIP_TASKBAR`/`SKIP_PAGER`), plus clearing alacritty's resize-increment
  hints so the WM will actually let it fill the whole screen.
- Config is rendered from `config/alacritty.toml.template` into
  `~/.config/cmatrix-overlay/alacritty.toml` (`opacity = 0.0` — fully
  transparent background, only the falling characters are visible; raise
  this if you want a dark tint instead), plus `config/picom.conf`.
- **Color**: `matrix-rain.py` always draws with curses' `COLOR_GREEN` (body)
  and `COLOR_WHITE` (bold leading character) — "changing the color" doesn't
  touch the Python script at all, it remaps what the terminal's `green` ANSI
  slot actually renders as, via `colors.normal.green`/`colors.bright.green`
  in the rendered `alacritty.toml`. `lib/colors.sh` holds the curated
  hex pairs (and lightens an arbitrary custom hex by 45% toward white for
  the "glow" shade) shared by `install.sh` and `cmatrix-overlay-set-color`.
- **Hotkey**: `lib/install_keybind.py` does a marker-delimited text edit of
  Openbox's `rc.xml` (not a full XML re-serialize, so it can't disturb
  unrelated formatting/comments), then runs `openbox --reconfigure` to
  apply it live. `uninstall.sh` calls it with `--remove` to clean up.

## Ideas for extending this

- A rainbow/multi-color mode.
- "Wake up..." Easter egg messages typed out like the movie's intro.
- Speed/density as configurable options instead of hardcoded values.
- Hotkey support for WMs other than Openbox.
- Multi-monitor awareness (currently sizes to the primary screen at
  launch).

## Credits

This is a standalone project, not a fork — it shares no code with cmatrix
(`matrix-rain.py` is a from-scratch Python/curses reimplementation, written
because cmatrix's own Japanese-character mode doesn't render real Unicode
in modern terminals; see "How it works" above). But the idea obviously
wouldn't exist without it:

- [cmatrix](https://github.com/abishekvashok/cmatrix) — created by
  **Chris Allegretta**, currently maintained by **Abishek V Ashok**
  (GPL-3.0)
- *The Matrix* (1999) for the visual effect it's imitating in the first
  place

##Donate##
If you like my idea and wish to support my endeavours you can donate to me if you wish!

[Ko-fi](https://ko-fi.com/dreamygloom)


## License

MIT License

Copyright (c) [2026] [CMatrix-Desktop-Overlay]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
