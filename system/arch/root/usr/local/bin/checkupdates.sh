#!/bin/bash

ICON=""
CACHE="/tmp/dwm-updates-count"

case $BUTTON in
    1)
        alacritty -e sudo pacman -Syu
        echo "$(checkupdates | wc -l)" > "$CACHE"
        pkill -RTMIN+2 dwmblocks
        exit
        ;;
esac

if [[ -f $CACHE && $(find "$CACHE" -mmin -30) ]]; then
    echo " $ICON $(cat $CACHE)⠀ "
else
    if [ -f $CACHE ]; then
        echo " $ICON $(cat $CACHE)  "
    else
        echo " $ICON ... "
    fi
    (
        COUNT=$(checkupdates | wc -l)
        echo "$COUNT" > "$CACHE"
        pkill -RTMIN+2 dwmblocks
        ) &
fi
