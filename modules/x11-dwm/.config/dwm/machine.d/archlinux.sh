#!/bin/sh
# Hardware settings of the "archlinux" laptop.
# Sourced by ~/.xinitrc through machine.d/$(hostname).sh.
#
# On a new machine: copy this file under the new hostname,
# then replace the ids below with those from `xinput list`.

# Touchpad: lowers the scroll step (the default is too fast)
xinput --set-prop "ELAN2204:00 04F3:3109 Touchpad" \
       "libinput Scrolling Pixel Distance" 30 2>/dev/null &

# Logitech K400 Plus keyboard/mouse: natural scrolling
xinput --set-prop "pointer:Logitech K400 Plus" \
       "libinput Natural Scrolling Enabled" 1 2>/dev/null &

# HDMI: since kernel 7.3, amdgpu's automatic choice sends limited range RGB
# (16-235) or YUV at 1080p, and black shows as dark grey on the monitor.
# Force full range RGB. The property sticks to the port across replugs.
xrandr --output HDMI-A-0 --set "Broadcast RGB" Full \
       --set "color format" RGB 2>/dev/null &
