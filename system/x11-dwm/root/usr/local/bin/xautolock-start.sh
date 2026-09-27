#!/bin/bash
#
# script used in /etc/acpi/events/autolock-power, which starts it automatically on every plug and unplug
#

# pkill -x xautolock 2>/dev/null
# sleep 0.3
#
# if acpi -a | grep -q "off-line"; then
#     # Battery: (slock, thanks to xss-lock ) + screen off at 20 min, suspend at 30 min (20+10)
#     xautolock -time 20 -locker "xset dpms force off" \
#             -killtime 10 -killer "systemctl suspend" \
#             -detectsleep &
# else
#     # AC: (slock, thanks to xss-lock ) + screen off at 30 min, no suspend
#     xautolock -time 30 -locker "xset dpms force off" \
#                -detectsleep &
# fi

# pkill -x xautolock 2>/dev/null
# sleep 0.3
#
# if acpi -a | grep -q "off-line"; then
#     # Battery: (slock, thanks to xss-lock ) + screen off at 20 min, suspend at 22 min
#     xset +dpms
#     xset dpms 0 0 1200   # screen off at 20 min
#
#     xautolock -time 22 \
#         -locker "systemctl suspend" \
#         -detectsleep &
# else
#     # AC: (slock, thanks to xss-lock ) + screen off at 30 min, no suspend
#     xset +dpms
#     xset dpms 0 0 1800   # screen off at 30 min
# fi


