#!/usr/bin/env python3
"""Launch alacritty+matrix-rain as a fullscreen, all-desktops, fully
click-through overlay that sits in the normal stacking layer (not above
everything) so your real windows can layer on top of it. Click-through is
done via the X Shape extension (empty input region) -- the window is still
drawn, but every mouse event falls through to whatever is beneath it.
Keyboard focus is explicitly restored to whatever was focused before
launch, so typing still goes to your real desktop.
"""
import os
import subprocess
import sys
import time

from Xlib import X, display, Xutil, protocol
from Xlib.ext import shape

HOME = os.path.expanduser("~")
CONFIG_DIR = os.path.join(HOME, ".config", "cmatrix-overlay")
BIN_DIR = os.path.dirname(os.path.abspath(__file__))
WM_CLASS_NAME = "CmatrixOverlay"


def send_to_all_desktops(disp, root, win):
    # 0xFFFFFFFF is the EWMH magic value meaning "all desktops" for
    # _NET_WM_DESKTOP -- this is the real "show on every workspace"
    # mechanism; _NET_WM_STATE_STICKY alone is not enough on openbox.
    net_wm_desktop = disp.intern_atom("_NET_WM_DESKTOP")
    data = (32, [0xFFFFFFFF, 1, 0, 0, 0])
    ev = protocol.event.ClientMessage(window=win, client_type=net_wm_desktop, data=data)
    mask = X.SubstructureRedirectMask | X.SubstructureNotifyMask
    root.send_event(ev, event_mask=mask)


def send_wm_state(disp, root, win, atom_names, action=1):
    net_wm_state = disp.intern_atom("_NET_WM_STATE")
    for name in atom_names:
        atom = disp.intern_atom(name)
        data = (32, [action, atom, 0, 1, 0])
        ev = protocol.event.ClientMessage(window=win, client_type=net_wm_state, data=data)
        mask = X.SubstructureRedirectMask | X.SubstructureNotifyMask
        root.send_event(ev, event_mask=mask)


def find_window(disp, root, timeout=10.0):
    net_client_list = disp.intern_atom("_NET_CLIENT_LIST")
    deadline = time.time() + timeout
    while time.time() < deadline:
        prop = root.get_full_property(net_client_list, X.AnyPropertyType)
        if prop:
            for wid in prop.value:
                try:
                    win = disp.create_resource_object("window", wid)
                    cls = win.get_wm_class()
                except Exception:
                    continue
                if cls and WM_CLASS_NAME in cls:
                    return win
        time.sleep(0.15)
    return None


def main():
    disp = display.Display()
    screen = disp.screen()
    root = screen.root
    width = screen.width_in_pixels
    height = screen.height_in_pixels

    # Remember what currently has keyboard focus so we can hand it right back.
    prev_focus = disp.get_input_focus().focus

    env_note = f"Launching cmatrix overlay at {width}x{height}..."
    print(env_note)

    subprocess.Popen(
        [
            "alacritty",
            "--class", WM_CLASS_NAME,
            "--config-file", f"{CONFIG_DIR}/alacritty.toml",
            "-e", "python3", os.path.join(BIN_DIR, "matrix-rain.py"),
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )

    win = find_window(disp, root)
    if win is None:
        print("Could not find the overlay window after launch; aborting.", file=sys.stderr)
        sys.exit(1)

    # Ask the WM to hide it from taskbar/pager and pin it to every virtual
    # desktop. Deliberately NOT using _NET_WM_STATE_ABOVE (or FULLSCREEN):
    # we want this window to sit in the normal stacking layer, so any real
    # window you click on or mark "Always on top" naturally ends up above
    # it -- and stays there, since nothing here ever re-raises the overlay.
    send_wm_state(
        disp, root, win,
        [
            "_NET_WM_STATE_STICKY",
            "_NET_WM_STATE_SKIP_TASKBAR",
            "_NET_WM_STATE_SKIP_PAGER",
        ],
    )
    send_to_all_desktops(disp, root, win)

    # Best-effort: tell the WM this window doesn't want keyboard input at all.
    try:
        win.set_wm_hints(flags=Xutil.InputHint, input=0)
    except Exception:
        pass

    disp.sync()
    time.sleep(0.3)  # let the WM apply the state changes first

    # Alacritty's terminal grid comes with resize-increment hints (it only
    # wants to be resized in whole character-cell steps), which makes the WM
    # round a resize-to-fullscreen request down, leaving it stuck at its
    # small starting size. Clear those hints, then force exact full-screen
    # geometry and raise it to the top of its stacking layer.
    try:
        win.set_wm_normal_hints(flags=0)
    except Exception:
        pass
    win.configure(x=0, y=0, width=width, height=height, border_width=0)
    win.raise_window()
    disp.sync()
    time.sleep(0.2)  # give cmatrix a moment to see the resize and redraw

    # Make it fully click-through: empty input shape means every mouse event
    # (clicks, scroll, hover) passes straight through to the window below.
    win.shape_rectangles(shape.SO.Set, shape.SK.Input, X.Unsorted, 0, 0, [])

    # Hand keyboard focus back to whatever you were using before. openbox
    # reacts to this by re-raising that window (focus-follows-raise), which
    # would bury our overlay again -- so we raise ours once more right after.
    if prev_focus and prev_focus != X.NONE:
        try:
            prev_focus.set_input_focus(X.RevertToParent, X.CurrentTime)
        except Exception:
            pass
    disp.sync()
    time.sleep(0.15)
    win.raise_window()
    disp.sync()

    print("Overlay is live and click-through. Run cmatrix-overlay-stop to end it.")


if __name__ == "__main__":
    main()
