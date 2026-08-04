#!/bin/bash

export DISPLAY=:0
export XAUTHORITY=/run/user/1000/lyxauth
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus"

# Log pour débogage
echo "$(date): applying keyboard options" >> /tmp/udev-keyboard.log

/usr/bin/setxkbmap fr -option caps:escape
/usr/bin/xset r rate 250 50
