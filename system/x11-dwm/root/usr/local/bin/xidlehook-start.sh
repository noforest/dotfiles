#!/bin/bash
#
# script used in /etc/acpi/events/autolock-power and started automatically
# on every plug and unplug
# slock is handled separately by xss-lock in .xinitrc
#

. /usr/local/bin/desktop-env.sh   # sets DESKTOP_USER, USER_HOME, DISPLAY, XAUTHORITY
export PULSE_RUNTIME_PATH=/run/user/$(id -u "$DESKTOP_USER")/pulse
export PULSE_SERVER=unix:${PULSE_RUNTIME_PATH}/native

# Caffeine mode (see /usr/local/bin/idle_mode): nothing may turn the screen off
# or suspend. acpid calls this script again on every plug, hence this safeguard.
[ "$(cat "$IDLE_MODE_FILE" 2>/dev/null)" = caffeine ] && exit 0

# Kill only the xidlehook instances that DO NOT have "timer 20" in their command line
# ESSENTIAL: for the screen to go black after 20s of inactivity while slock is active
# I need it when I plug or unplug the charger, the old one has to be removed

pkill -f 'xidlehook.*timer (1200|1800)' 2>/dev/null
sleep 0.3

if acpi -a | grep -q "off-line"; then
    xidlehook --detect-sleep --not-when-audio --timer 1200 'xset dpms force off' 'xset -dpms' --timer 300 'systemctl suspend' '' &
else
    xidlehook --not-when-audio --timer 1800 'xset dpms force off' 'xset -dpms'&
fi

# # NOTE: temporaire
#
# pkill -f 'xidlehook.*timer (30|60|1200|1800)' 2>/dev/null
# sleep 0.3
#
# if acpi -a | grep -q "off-line"; then
#     xidlehook --detect-sleep --not-when-audio --timer 30 'xset dpms force off' 'xset -dpms' --timer 40 'systemctl suspend' '' &
# else
#     xidlehook --not-when-audio --timer 30 'xset dpms force off' 'xset -dpms'&
# fi


