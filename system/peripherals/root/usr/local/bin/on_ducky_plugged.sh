#!/bin/bash
# Relance les réglages de session quand le clavier Ducky est branché (voir /etc/udev/rules.d).
. /usr/local/bin/desktop-env.sh
su "$DESKTOP_USER" -c ". \"$USER_HOME/.xinitrc\""
