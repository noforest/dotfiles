#!/bin/bash
# Wrapper for slock that turns the screen off while locked
# For it to work: use the lock alias (= xset s activate)

. /usr/local/bin/desktop-env.sh   # sets DESKTOP_USER, USER_HOME, DISPLAY, XAUTHORITY

# Starts a temporary xidlehook that turns the screen off after 20s while locked
xidlehook --not-when-audio --timer 20 'xset dpms force off' 'xset -dpms' &
XIDLEHOOK_PID=$!

# Starts slock (blocks until unlocked)
slock

# After unlocking: kills the temporary xidlehook
kill $XIDLEHOOK_PID 2>/dev/null

# Turns the screen back on if needed
xset -dpms
# xset dpms force on
