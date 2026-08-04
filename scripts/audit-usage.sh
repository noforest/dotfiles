#!/usr/bin/env bash
# Qu'est-ce qui sert vraiment sur cette machine ?
#
# Deux signaux, parce qu'aucun ne suffit seul :
#   - historique atuin : fiable pour tout ce qui se tape dans un terminal
#   - mtime de ~/.config, ~/.cache, ~/.local/share : seul indice pour les applis
#     graphiques, lancées via dmenu et donc absentes de l'historique du shell
#
# LIMITE IMPORTANTE : « aucune trace » ne veut pas dire « inutile ». Les services
# (ly, pipewire, grub) et les bibliothèques ne se lancent jamais à la main.
# Ce script trie ; c'est toi qui décides.
set -uo pipefail

REPO="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
DB="$HOME/.local/share/atuin/history.db"
NOW=$(date +%s)
MODE="${1:-packages}"

if [ -t 1 ]; then G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; D=$'\e[2m'; B=$'\e[34m'; N=$'\e[0m'
else G=; Y=; R=; D=; B=; N=; fi

# Paquets qui ne s'invoquent jamais à la main mais sans lesquels rien ne marche.
INFRA='^(base|base-devel|linux|linux-firmware|grub|efibootmgr|os-prober|ly|lightdm.*|
xorg-server.*|xorg-xauth|xorg-iceauth|xorg-mkfontscale|xorg-font.*|xorg-bdftopcf|
xorg-setxkbmap|xorg-xkbcomp|xorg-xsetroot|xorg-xhost|xorg-xrdb|xorg-xmodmap|
xf86-video-.*|pipewire.*|wireplumber|sof-firmware|alsa-utils|networkmanager|
openresolv|power-profiles-daemon|acpid?|acpilight|fprintd|bluez.*|
noto-fonts.*|ttf-.*|powerline-fonts|papirus-icon-theme|
glibc-debug|openmp|gobject-introspection|gtksourceview3|sdl2_.*|
libdvdcss|gvfs.*|tumbler|exo|garcon|xfconf|xdg-desktop-portal.*|
python-(pip|pipx)|perl-file-mimeinfo|pacman-contrib|reflector|plocate|
cpio|dosfstools|exfatprogs|mtools|7zip|zip|unzip|unrar|man-pages|
texlive-.*|tesseract-data-.*|vim-runtime|vim-spell-fr|xss-lock|numlockx|
jdk.*-openjdk|virtualbox-guest-iso|inotify-tools|keychain)$'
INFRA=$(printf '%s' "$INFRA" | tr -d '\n')

# Les alias masquent l'usage réel : `alias du="dust -r"` fait que `dust` n'apparaît
# jamais tel quel dans l'historique. On construit binaire → alias qui le lancent.
declare -A ALIAS_OF
_load_aliases() {
    local zshrc="$REPO/modules/shell/.zshrc" line name target bin
    [ -r "$zshrc" ] || return 0
    while IFS= read -r line; do
        name=$(sed -E 's/^[[:space:]]*alias[[:space:]]+([A-Za-z0-9_.-]+)=.*/\1/' <<< "$line")
        target=$(sed -E 's/^[[:space:]]*alias[[:space:]]+[A-Za-z0-9_.-]+=//; s/^["'"'"']//; s/["'"'"']$//' <<< "$line")
        bin=${target%% *}; bin=${bin##*/}
        [ -n "$bin" ] && [ "$bin" != "$name" ] && ALIAS_OF[$bin]="${ALIAS_OF[$bin]:-} $name"
    done < <(grep -E '^[[:space:]]*alias[[:space:]]+[A-Za-z0-9_.-]+=' "$zshrc")
}
_load_aliases

usage_of() {  # usage_of <nom-de-binaire...> → "nb_lancements|dernier_ts"
    local where="" b a
    for b in "$@"; do
        # le binaire, plus tout alias qui pointe dessus
        for a in "$b" ${ALIAS_OF[$b]:-}; do
            a=${a//\'/\'\'}
            where="$where OR command LIKE '$a %' OR command = '$a' OR command LIKE '% $a %'"
        done
    done
    where=${where# OR }
    [ -n "$where" ] && [ -f "$DB" ] || { echo "0|0"; return; }
    sqlite3 "$DB" "SELECT COUNT(*), COALESCE(MAX(timestamp),0) FROM history WHERE $where" 2>/dev/null || echo "0|0"
}

days_since() { [ "$1" = "0" ] && { echo 99999; return; }; echo $(( (NOW - $1) / 86400 )); }

audit_packages() {
    printf '%s╔══ PAQUETS ══════════════════════════════════════════════════════════╗%s\n' "$B" "$N"
    local pkg bins runs ts d newest m best
    local -a never stale live
    for pkg in $(pacman -Qqe); do
        [[ "$pkg" =~ $INFRA ]] && continue
        mapfile -t bins < <(pacman -Ql "$pkg" 2>/dev/null \
            | awk '$2 ~ /^\/usr\/bin\/[^\/]+$/ {n=split($2,a,"/"); print a[n]}' | sort -u)
        [ "${#bins[@]}" -eq 0 ] && continue          # bibliothèque pure : on ne juge pas
        IFS='|' read -r runs ts < <(usage_of "${bins[@]}")
        d=$(days_since "${ts:0:10}")
        newest=0
        for dir in "$HOME/.config/$pkg" "$HOME/.cache/$pkg" "$HOME/.local/share/$pkg"; do
            [ -e "$dir" ] || continue
            m=$(find "$dir" -printf '%T@\n' 2>/dev/null | sort -rn | head -1); m=${m%%.*}
            [ -n "$m" ] && [ "$m" -gt "$newest" ] 2>/dev/null && newest=$m
        done
        [ "$newest" != "0" ] && { local dd=$(days_since "$newest"); [ "$dd" -lt "$d" ] && d=$dd; }
        if   [ "$runs" -eq 0 ] && [ "$d" -ge 99999 ]; then never+=("$pkg")
        elif [ "$d" -gt 180 ]; then stale+=("$(printf '%s (%s×, %sj)' "$pkg" "$runs" "$d")")
        else live+=("$pkg"); fi
    done
    printf '\n %sJAMAIS AUCUNE TRACE%s — %s paquets\n' "$R" "$N" "${#never[@]}"
    printf '   %s\n' "$(printf '%s ' "${never[@]}" | fold -s -w 68 | sed '2,$s/^/   /')"
    printf '\n %sPLUS UTILISÉS DEPUIS > 6 MOIS%s — %s paquets\n' "$Y" "$N" "${#stale[@]}"
    printf '   %s\n' "$(printf '%s, ' "${stale[@]}" | fold -s -w 68 | sed '2,$s/^/   /')"
    printf '\n %sACTIFS%s — %s paquets\n' "$G" "$N" "${#live[@]}"
    printf '\n %sInfrastructure exclue de l'"'"'analyse%s (services, polices, bibliothèques :\n' "$D" "$N"
    printf ' %sne s'"'"'invoquent jamais à la main, donc « aucune trace » n'"'"'y signifie rien).%s\n' "$D" "$N"
}

audit_scripts() {
    printf '\n%s╔══ SCRIPTS /usr/local/bin ═══════════════════════════════════════════╗%s\n' "$B" "$N"
    local s n refs runs ts d
    for s in "$REPO"/system/root/usr/local/bin/*; do
        n=$(basename "$s")
        refs=$(grep -rl --exclude-dir=.git -F "$n" \
               "$REPO/suckless" "$REPO/modules" "$REPO/system/root/etc" \
               "$REPO/system/root/usr" 2>/dev/null | grep -cv "usr/local/bin/$n\$")
        IFS='|' read -r runs ts < <(usage_of "$n")
        d=$(days_since "${ts:0:10}")
        if   [ "$refs" -gt 0 ]; then printf '  %s✓%s %-40s appelé par %s fichier(s)\n' "$G" "$N" "$n" "$refs"
        elif [ "$runs" -eq 0 ]; then printf '  %s✗%s %-40s orphelin, jamais lancé\n' "$R" "$N" "$n"
        elif [ "$d" -gt 180 ]; then printf '  %s?%s %-40s %s× — dernier il y a %s jours\n' "$Y" "$N" "$n" "$runs" "$d"
        else printf '  %s✓%s %-40s %s× — lancé à la main\n' "$G" "$N" "$n" "$runs"; fi
    done
}

command -v sqlite3 >/dev/null || { echo "sqlite3 requis (pacman -S sqlite)"; exit 1; }
[ -f "$DB" ] || echo "  ! base atuin absente : seul le mtime disque sera utilisé"

case "$MODE" in
    packages) audit_packages ;;
    scripts)  audit_scripts ;;
    *)        audit_packages; audit_scripts ;;
esac
