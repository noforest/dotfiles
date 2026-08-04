#!/bin/sh

export WALLPAPER="${WALLPAPER:-$HOME/Pictures/Wallpapers/banshee_of_inisherin.png}"

# Ne relancer que s'il n'y a pas déjà une instance
pgrep -x picom     >/dev/null || picom &
pgrep -x dunst     >/dev/null || dunst &
pgrep -f feh       >/dev/null || feh --bg-fill "$WALLPAPER" &
pgrep -x clipster  >/dev/null || clipster -d -f ~/.config/clipster/clipster.ini &

xset r rate 250 50
# xset dpms 30
export MOZ_GTK_TITLEBAR_DECORATION=none
setxkbmap -option caps:escape

# Réglages xinput propres à la machine (voir .xinitrc pour l'explication)
MACHINE_CONF="$HOME/.config/dwm/machine.d/$(hostname).sh"
[ -r "$MACHINE_CONF" ] && . "$MACHINE_CONF"

libinput-gestures-setup restart

