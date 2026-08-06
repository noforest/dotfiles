#!/bin/bash
# Wrapper pour slock qui gère l'extinction d'écran pendant le lock
# Pour qu'il fonctionne: utiliser l'alias lock (= xset s activate)

. /usr/local/bin/desktop-env.sh   # définit DESKTOP_USER, USER_HOME, DISPLAY, XAUTHORITY

# Lance un xidlehook temporaire qui éteint l'écran après 20s pendant le lock
xidlehook --not-when-audio --timer 20 'xset dpms force off' 'xset -dpms' &
XIDLEHOOK_PID=$!

# Lance slock (bloquant jusqu'au déverrouillage)
slock

# Après déverrouillage : tue le xidlehook temporaire
kill $XIDLEHOOK_PID 2>/dev/null

# Réactive l'écran si nécessaire
xset -dpms
# xset dpms force on
