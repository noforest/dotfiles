#!/bin/sh
# Réglages matériels du portable « archlinux ».
# Sourcé par ~/.xinitrc via machine.d/$(hostname).sh.
#
# Sur une nouvelle machine : copier ce fichier sous le nom du nouvel hostname,
# puis remplacer les identifiants ci-dessous par ceux de `xinput list`.

# Pavé tactile : réduit le pas de défilement (défaut trop rapide)
xinput --set-prop "ELAN2204:00 04F3:3109 Touchpad" \
       "libinput Scrolling Pixel Distance" 30 2>/dev/null &

# Clavier/souris Logitech K400 Plus : défilement naturel
xinput --set-prop "pointer:Logitech K400 Plus" \
       "libinput Natural Scrolling Enabled" 1 2>/dev/null &
