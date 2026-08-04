#!/bin/bash

notification_timeout=3000
bar_color="#eeeeee"

case "$1" in
    up)
        brightnessctl set +10% > /dev/null
        ;;
    down)
        brightnessctl set 10%- > /dev/null
        ;;
    *)
        echo "Usage: $0 {up|down}"
        exit 1
        ;;
esac

brightness=$(brightnessctl g)
max=$(brightnessctl m)
percent=$(( brightness * 100 / max ))

dunstify -t $notification_timeout \
    -h string:x-dunst-stack-tag:brightness \
    -h int:value:$percent \
    -h string:hlcolor:$bar_color \
    "Luminosité: $percent%"
