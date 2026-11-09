# ghostty on X11: what makes it slower than alacritty, and what fixes it

Measured on 2026-10-09 and 2026-10-10 on the Arch laptop (dwm, X11, picom,
1920x1080 at 60 Hz, Ryzen 5 3500U with Radeon Vega graphics), with ghostty
1.3.1, GTK 4.24.1, alacritty 0.17.0, picom 13 and tmux 3.7c.

## Conclusion

Out of the box, ghostty under X11 shows a key 40 ms later than alacritty. Two
settings bring that down to 5 to 10 ms, and both are in this repository:

- picom uses the `glx` backend (`modules/x11-dwm/.config/picom/picom.conf`),
- Mesa does not make ghostty wait for the vertical blank
  (`modules/x11-dwm/.drirc`).

On mains power ghostty then crosses a line almost as evenly as alacritty. It
still uses three to four times the CPU, and on battery it skipped cells on the
first day. That case has not been measured again with the two settings.

Decision, after a day of using both: dwm stays on alacritty. Even with the two
settings ghostty is the less smooth of the two under X11. It remains the
terminal on GNOME and Wayland.

## The symptom

Holding the right arrow in nvim to cross a long line of code. In ghostty the
cursor visibly stutters. In alacritty, same machine, same font, same tmux and
nvim, it does not.

## How it was measured

Each terminal was opened full width on the same 133 column line of Python, in
tmux and nvim with the usual config. The key was held with `xdotool keydown
Right`, so the X server repeated it at the usual 50 per second, and the row was
recorded at 120 frames per second with `ffmpeg -f x11grab`. Comparing
consecutive frames gives, for every screen update, how many cells the cursor
moved and how long after the previous update.

The delay between a key and the screen was measured apart: 40 single presses
sent through XTEST, each timed until the first pixel of the row changed.

Everything is read from what the X server displays. Nothing here measures the
panel itself.

## Key to screen

Median of 40 presses, on mains power, tmux and nvim.

| picom | ghostty | ghostty, `vblank_mode=0` | alacritty |
|---|---|---|---|
| xrender, vsync (the old config) | 67 ms | 50 ms | 27 ms |
| glx, vsync (the new config) | 39 to 45 ms | 30 to 34 ms | 25 ms |
| glx, no vsync | 47 ms | 42 ms | |
| xrender, no vsync | 52 ms | 43 ms | |
| not running | 45 ms | 32 ms | 18 ms |

`vblank_mode=0` is Mesa's switch for the swap interval. `.drirc` sets it for
the `ghostty` executable alone, so every way of starting ghostty gets it and
nothing else loses its vsync. `GDK_DEBUG=no-vsync` does nothing here: ghostty
overwrites that variable when it starts.

## Cells skipped while the key is held

A skipped cell is the cursor moving two cells in one screen update.

| | ghostty | alacritty |
|---|---|---|
| On battery, old config, about 15 runs | 3 to 24 | 0 to 2 |
| On mains, old config, 3 runs | 0 | 0 |
| On mains, new config, 9 runs | 0, 0, 0, 0, 0, 1, 2, 6, 11 | 0 |

The first day's runs were all on battery, where auto-cpufreq sets the
`powersave` governor. The CPU driver is acpi-cpufreq, for which `powersave`
means the lowest frequency, 1.4 GHz. ghostty needs 40 to 55 % of a core while
the key is held, 80 % with tmux, against 8 to 20 % for alacritty, so it is the
one that runs out of time. That link is a deduction: the governor was not
changed by hand to confirm it.

## What does not help

- The ghostty config. With `--config-default-files=false` and only the font
  set, the CPU use is the same.
- The inverted cursor (`cursor-invert-fg-bg`). Frame by frame, alacritty and
  ghostty draw the same thing: a block in the colour of the text under it.
- tmux. nvim alone in ghostty skips as many cells.
- The GTK renderer. `GSK_RENDERER=gl` changes nothing and `cairo` is worse
  (78 ms).
- ghostty's I/O backend (`--async-backend=epoll`).
- The key repeat rate. At 60 per second instead of 50 both terminals lose the
  33 ms pause that a 50 Hz repeat makes on a 60 Hz screen, but ghostty feels
  the same.

## Still open

- The battery case with the new config.
- A governor other than `powersave` on battery (`schedutil` in
  `/etc/auto-cpufreq.conf`), if ghostty still skips cells there.
- A ghostty release after 1.3.1.
