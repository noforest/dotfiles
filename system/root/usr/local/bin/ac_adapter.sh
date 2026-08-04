#!/bin/sh


if acpi -a | grep -q "off-line"; then
    if ! pgrep -x xautolock >/dev/null; then
        xautolock -time 35 -locker "systemctl suspend" -detectsleep &
        # xautolock -time 1 -locker "systemctl suspend" -detectsleep &
    fi
else
    pkill -x xautolock
fi
