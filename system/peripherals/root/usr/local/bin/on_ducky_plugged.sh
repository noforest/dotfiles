#!/bin/bash
# Applies the session settings again when the Ducky keyboard is plugged in (see /etc/udev/rules.d).
. /usr/local/bin/desktop-env.sh
su "$DESKTOP_USER" -c ". \"$USER_HOME/.xinitrc\""
