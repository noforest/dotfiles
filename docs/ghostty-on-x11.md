# ghostty on X11: why dwm stays on alacritty

Measured on 2026-10-09 on the Arch laptop (dwm, X11, picom, 1920x1080 at 60 Hz,
Radeon Vega integrated graphics), with ghostty 1.3.1, GTK 4.24.1, alacritty
0.17.0, picom 13 and tmux 3.7c.

## Conclusion

Under X11, ghostty moves the cursor less smoothly than alacritty and answers a
key later. No setting found here fixes it, so dwm opens alacritty. ghostty stays
the terminal on GNOME and Wayland, where the cursor looks smooth. That part was
not measured.

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

## Results

| | alacritty | ghostty |
|---|---|---|
| Cells skipped while crossing the line (the cursor moves two at once) | 0 to 2 | 8 to 19 |
| Key to screen, median | 34 ms | 52 to 60 ms |
| Key to screen, worst | 45 ms | 82 ms |
| CPU of the terminal while the key is held, nvim alone | 20 % of a core | 50 % |

With tmux in between, ghostty reaches 80 % of a core. Its two busy threads are
the renderer (about 29 %) and the GTK main thread (about 16 %).

## What was ruled out

Each line is a run of the same recording.

- The ghostty config. With `--config-default-files=false` and only the font
  set, the CPU use is the same. The skipped cells could not be counted in that
  run.
- The inverted cursor (`cursor-invert-fg-bg`). Frame by frame, alacritty and
  ghostty draw the same thing: a block in the colour of the text under it.
- tmux. nvim alone in ghostty skips as many cells.
- picom. Stopping it changes nothing on the full width line.
- Vertical sync. Neither `vblank_mode=0` nor `GDK_DEBUG=no-vsync` helps.
- The GTK renderer (`GSK_RENDERER=gl`) and ghostty's I/O backend
  (`--async-backend=epoll`).
- The key repeat rate. At 60 per second instead of 50 both terminals lose the
  33 ms pause that a 50 Hz repeat makes on a 60 Hz screen, but ghostty still
  feels the same.
- The hardware. alacritty keeps up on the same machine.

## A guess at the cause

Not verified. On Wayland the compositor tells GTK when each frame is shown, so
GTK paints in step with the screen. On X11 that signal needs a compositing
window manager that speaks the frame synchronisation protocol, which neither
dwm nor picom does. GTK then paces itself on a timer, drifts against the real
refresh and regularly misses a frame. ghostty also draws on its own thread and
hands the result to the GTK thread, one more step than alacritty has.

## When to look again

After a ghostty or GTK release that changes rendering on X11, or if dwm is
replaced by a Wayland compositor. The test takes a few minutes to redo: hold
the right arrow across a long line in both terminals and compare.
