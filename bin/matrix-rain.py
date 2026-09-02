#!/usr/bin/env python3
"""Matrix-style falling rain using real Unicode katakana glyphs.

cmatrix's -c ("Japanese characters") flag turns out to emit raw high
bytes meant for an old X11 bitmap font (mtx.pcf) rather than actual
Unicode text, so it renders as blank space in any modern UTF-8 terminal
(alacritty, qterminal, xterm with a normal font, etc). This is a
minimal replacement that draws genuine half-width/full-width katakana
(plus a sprinkling of digits, matching the movie's actual charset) so
it renders correctly anywhere.
"""
import curses
import random
import signal
import sys
import time

KATAKANA = [chr(c) for c in range(0xFF66, 0xFF9D)]  # half-width katakana
DIGITS = list("0123456789")
CHARSET = KATAKANA * 4 + DIGITS  # katakana-heavy, digits sprinkled in

def main(stdscr):
    curses.curs_set(0)
    curses.start_color()
    curses.use_default_colors()
    curses.init_pair(1, curses.COLOR_GREEN, -1)
    curses.init_pair(2, curses.COLOR_WHITE, -1)
    stdscr.nodelay(True)
    stdscr.timeout(0)

    height, width = stdscr.getmaxyx()
    drops = [random.randint(-height, 0) for _ in range(width)]
    speeds = [random.choice([1, 1, 2]) for _ in range(width)]
    ticks = [0 for _ in range(width)]
    trail_len = 18

    def resize(*_):
        nonlocal height, width, drops, speeds, ticks
        curses.endwin()
        stdscr.refresh()
        height, width = stdscr.getmaxyx()
        drops = [random.randint(-height, 0) for _ in range(width)]
        speeds = [random.choice([1, 1, 2]) for _ in range(width)]
        ticks = [0 for _ in range(width)]

    signal.signal(signal.SIGWINCH, resize)

    while True:
        ch = stdscr.getch()
        if ch != -1 and ch != curses.KEY_RESIZE:
            break

        for col in range(width):
            ticks[col] += 1
            if ticks[col] < speeds[col]:
                continue
            ticks[col] = 0

            head = drops[col]

            if 0 <= head < height:
                try:
                    stdscr.addstr(head, col, random.choice(CHARSET),
                                  curses.color_pair(2) | curses.A_BOLD)
                except curses.error:
                    pass

            fade_row = head - 1
            if 0 <= fade_row < height:
                try:
                    stdscr.addstr(fade_row, col, random.choice(CHARSET),
                                  curses.color_pair(1) | curses.A_BOLD)
                except curses.error:
                    pass

            tail_row = head - trail_len
            if 0 <= tail_row < height:
                try:
                    stdscr.addstr(tail_row, col, " ")
                except curses.error:
                    pass

            drops[col] += 1
            if drops[col] - trail_len > height:
                drops[col] = random.randint(-height // 2, 0)
                speeds[col] = random.choice([1, 1, 2])

        stdscr.refresh()
        time.sleep(0.03)


if __name__ == "__main__":
    try:
        curses.wrapper(main)
    except KeyboardInterrupt:
        sys.exit(0)
