#!/bin/bash
#
# script utilisé dans /etc/acpi/events/autolock-power et lancé automatiquement
# à chaque branchement-débranchement
# slock est géré séparément par xss-lock dans .xinitrc
#

. /usr/local/bin/desktop-env.sh   # définit DESKTOP_USER, USER_HOME, DISPLAY, XAUTHORITY
export PULSE_RUNTIME_PATH=/run/user/$(id -u for)/pulse
export PULSE_SERVER=unix:${PULSE_RUNTIME_PATH}/native

# Tuer uniquement les xidlehook qui N'ONT PAS "timer 20" dans leur ligne de commande
# INDISPENSABLE: si on veut avoir un ecran noir au bout de 20s d'inactivité pendant que slock est actif
# J'en ai besoin quand je branche débranche prise, il faut supprimer l'ancien
pkill -f 'xidlehook.*timer (1200|1800)' 2>/dev/null
sleep 0.3

if acpi -a | grep -q "off-line"; then
    xidlehook --detect-sleep --not-when-audio --timer 1200 'xset dpms force off' 'xset -dpms' --timer 600 'systemctl suspend' '' &
else
    xidlehook --not-when-audio --timer 1800 'xset dpms force off' 'xset -dpms'&
fi


# exec >> /tmp/xidlehook-start.log 2>&1
# echo "=== $(date) ==="
# echo "USER: $(whoami), DISPLAY: $DISPLAY, XAUTHORITY: $XAUTHORITY"
#
# pkill -x xidlehook 2>/dev/null
# sleep 0.3
#
# if acpi -a | grep -q "off-line"; then
#     echo "Mode batterie: lancement timer 1200+600"
#     xidlehook --not-when-audio --timer 1200 'xset dpms force off' 'xset -dpms' --timer 600 'systemctl suspend' '' &
#     echo "PID xidlehook: $!"
# else
#     echo "Mode secteur: lancement timer 1800"
#     xidlehook --not-when-audio --timer 1800 'xset dpms force off' 'xset -dpms' &
#     echo "PID xidlehook: $!"
# fi
