# #!/bin/bash
#
# notification_timeout=3000
# bar_color="#eeeeee"
#
# case "$1" in
#     up)
#         wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
#         ;;
#     down)
#         wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
#         ;;
#     muted)
#         wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
#         ;;
#     *)
#         echo "Usage: $0 {up|down|muted}"
#         exit 1
#         ;;
# esac
#
# out=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
# vol=$(echo "$out" | awk '{print int($2*100)}')
# muted=$(echo "$out" | grep -o '\[MUTED\]')
#
# media=""
#
# if command -v playerctl >/dev/null 2>&1; then
#     player=$(playerctl -s status 2>/dev/null)  # active player only
#     if [ "$player" = "Playing" ]; then
#         title=$(playerctl metadata title 2>/dev/null)
#         artist=$(playerctl metadata artist 2>/dev/null)
#         media="$title"
#         [ -n "$artist" ] && media="$media — $artist"
#     fi
# fi
#
# if [ -n "$muted" ]; then
#     dunstify -t $notification_timeout -h string:x-dunst-stack-tag:volume "Muted" "$media"
# else
#     dunstify -t $notification_timeout -h string:x-dunst-stack-tag:volume -h int:value:$vol -h string:hlcolor:$bar_color "Volume: $vol%" "$media"
# fi


# ~~~~~~~~~~~ VERSION opti (sans titre-album audio) ~~~~~~~~~~~~~~

#!/bin/bash

notification_timeout=2000
bar_color="#eeeeee"

case "$1" in
    up)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
        ;;
    down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        ;;
    muted)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
    *)
        echo "Usage: $0 {up|down|muted}"
        exit 1
        ;;
esac

# Notifications
out=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
vol=$(echo "$out" | awk '{print int($2*100)}')
muted=$(echo "$out" | grep -o '\[MUTED\]')

if [ -n "$muted" ]; then
    dunstify -t $notification_timeout -h string:x-dunst-stack-tag:volume "Muted"
else
    dunstify -t $notification_timeout \
        -h string:x-dunst-stack-tag:volume \
        -h int:value:$vol \
        -h string:hlcolor:$bar_color \
        "Volume: $vol%"
fi
