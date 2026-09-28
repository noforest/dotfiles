#!/bin/sh

# For clipster to work
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

# HACK: press <gf> in nvim to open the file under the cursor
# *****************************************************
# other important folders & files:
# - /etc/udev/rules.d/* (e.g. 95-monitor-hotplug.rules)
# - /etc/X11/xorg.conf.d/*
# - /etc/ly/config.ini
# - /etc/systemd/logind.conf
# - /etc/systemd/system/*
# - /etc/acpi/events/*
# - /usr/local/bin/*
# - /usr/share/X11/xkb/symbols/inet
#
# ==> all these files are now versioned in system/ of the dotfiles repository,
#     and deployed by `dot system-apply`.
# *****************************************************

exec >"$HOME/.xinitrc.log" 2>&1
# ly stores the authority file in /run/user/<uid>/lyxauth: it is copied to
# ~/.Xauthority, which several scripts read. The other session managers
# (GDM, LightDM, SDDM) export XAUTHORITY themselves and have nothing to copy,
# hence the test, without which `set -e` would fail the session on a machine without ly.
if [ -r "/run/user/$(id -u)/lyxauth" ]; then
    cp "/run/user/$(id -u)/lyxauth" ~/.Xauthority
fi
# Hands DISPLAY and XAUTHORITY to the systemd user manager.
# ly + .xinitrc do not start the session through systemd: without this import, the
# services activated on demand (xdg-desktop-portal-gtk, xfconfd…) fail with
# "cannot open display" and thunar or flameshot hang.
systemctl --user import-environment DISPLAY XAUTHORITY 2>/dev/null

picom -b &
dunst &
playerctld daemon &
# feh --bg-fill ~/Pictures/from_twitter/IMG_7741.JPG &
# feh --bg-fill Pictures/Wallpapers/a_ski_lift_with_a_chair_in_the_air.jpg &
# feh --bg-fill ~/Pictures/Wallpapers/purple_mountain.JPG &

export WALLPAPER="${WALLPAPER:-$HOME/Pictures/Wallpapers/banshee_of_inisherin.png}"
[ -f "$WALLPAPER" ] && feh --bg-fill "$WALLPAPER" &

numlockx &
xset r rate 250 50 &

clipster -d -f ~/.config/clipster/clipster.ini &
export MOZ_GTK_TITLEBAR_DECORATION=none

# Machine-specific settings: xinput ids, screens, devices.
# These names ("ELAN2204:00 04F3:3109 Touchpad"…) only exist on a given laptop,
# hence one file per machine. On a new PC: create its own, otherwise nothing is loaded.
MACHINE_CONF="$HOME/.config/dwm/machine.d/$(hostname).sh"
[ -r "$MACHINE_CONF" ] && . "$MACHINE_CONF"

libinput-gestures-setup restart &
dwmblocks &
vap-internet-watch &
# dwmblocks reads the volume once at startup, before PipeWire is up, and then
# only when a volume key signals it: refresh the block as soon as wpctl answers.
( for _ in $(seq 30); do
      wpctl get-volume @DEFAULT_AUDIO_SINK@ >/dev/null 2>&1 && break
      sleep 1
  done
  pkill -RTMIN+10 -x dwmblocks ) &


# IMPORTANT: starts solaar in the background: keeps the logibolt receiver from
# sending USB signals to the XHC0 usb controller WHILE I am suspended,
# which woke the computer up unintentionally (situation: when I close the lid, etc...)
solaar -w hide &

# LocalSend's own "Autostart after login" writes to ~/.config/autostart,
# which nothing reads under dwm. Starts straight into the tray.
localsend --hidden &

xset -dpms        # disables native DPMS (avoids HDMI disconnected)
xset s off        # disables the X screensaver (otherwise slock starts on its own after 10min)
export SESSION_ID=$(loginctl list-sessions --no-legend | awk '$4 != "-" {print $1}' | head -1)
xss-lock --session="$SESSION_ID" -- /usr/local/bin/slock-wrapper.sh &   # NOTE: turns the screen black again after x seconds while slock is active
                                                                        # so when I run slock in the terminal: there is
                                                                        # no wrapper any more (so it stays on all the time, or at least for 
                                                                        # the remaining time of the xidlehook-start.sh script) 
                                                                        # ==> I have to run the lock command (an alias of xset s activate) 
                                                                        # to trigger xss-lock and therefore the slock wrapper

# NOTE: also used in: /etc/acpi/events/autolock-power (acpid detects
# plugging and unplugging)
/usr/local/bin/xidlehook-start.sh & 

exec dwm
