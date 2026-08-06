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


