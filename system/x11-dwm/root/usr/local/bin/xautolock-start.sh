#!/bin/bash
#
# script utilisé dans /etc/acpi/events/autolock-power et lance ce dernier automatiquement à chaque branchement-débranchement
#

# pkill -x xautolock 2>/dev/null
# sleep 0.3
#
# if acpi -a | grep -q "off-line"; then
#     # Batterie : (slock, grâce à xss-lock ) + écran off à 20 min, suspend à 30 min (20+10)
#     xautolock -time 20 -locker "xset dpms force off" \
#             -killtime 10 -killer "systemctl suspend" \
#             -detectsleep &
# else
#     # Secteur : (slock, grâce à xss-lock ) + écran off à 30 min, pas de suspend
#     xautolock -time 30 -locker "xset dpms force off" \
#                -detectsleep &
# fi

# pkill -x xautolock 2>/dev/null
# sleep 0.3
#
# if acpi -a | grep -q "off-line"; then
#     # Batterie : (slock, grâce à xss-lock ) + écran off à 20 min, suspend à 22 min
#     xset +dpms
#     xset dpms 0 0 1200   # écran off à 20 min
#
#     xautolock -time 22 \
#         -locker "systemctl suspend" \
#         -detectsleep &
# else
#     # Secteur : (slock, grâce à xss-lock ) + écran off à 30 min, pas de suspend
#     xset +dpms
#     xset dpms 0 0 1800   # écran off à 30 min
# fi


