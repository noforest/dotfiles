#!/bin/sh
# Works out the current graphical session without hardcoding either the user or
# their $HOME.
#
# Sourced by scripts started from udev, acpid or systemd, that is by root, in an
# environment where DISPLAY, XAUTHORITY and HOME are not the user's own.
#
# Usage:
#     . /usr/local/bin/desktop-env.sh
#     # DESKTOP_USER, USER_HOME, DISPLAY and XAUTHORITY are set from here on

# 1) the user of an active graphical session, 2) the owner of /run/user/1000,
# 3) failing that, the current user.
DESKTOP_USER="${DESKTOP_USER:-$(
    loginctl list-sessions --no-legend 2>/dev/null \
        | awk '$3 != "" && $3 != "root" {print $3; exit}'
)}"
[ -n "$DESKTOP_USER" ] || DESKTOP_USER=$(stat -c %U /run/user/1000 2>/dev/null)
[ -n "$DESKTOP_USER" ] || DESKTOP_USER=$(id -un)

USER_HOME=$(getent passwd "$DESKTOP_USER" | cut -d: -f6)
[ -n "$USER_HOME" ] || USER_HOME="/home/$DESKTOP_USER"

export DESKTOP_USER USER_HOME
export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-$USER_HOME/.Xauthority}"

# State file for the idle mode, written by /usr/local/bin/idle_mode and read
# back by xidlehook-start.sh. It lives in /run/user, so it goes away on logout:
# every startup necessarily begins in "default" mode.
IDLE_MODE_FILE="/run/user/$(id -u "$DESKTOP_USER")/idle_mode"
export IDLE_MODE_FILE

# Display mode picked by hand in screen_menu, written by screen_mode and read
# back by monitor-hotplug: udev raises a DRM event whenever an output is
# switched off, and without this guard the monitor mode would overwrite the
# manual choice. In /run/user, so every session starts over on autodetection.
SCREEN_MODE_FILE="/run/user/$(id -u "$DESKTOP_USER")/screen_mode"
export SCREEN_MODE_FILE
