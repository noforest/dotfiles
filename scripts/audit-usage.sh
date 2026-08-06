#!/usr/bin/env bash
# What does this machine really use?
#
# Two signals, because neither one is enough on its own:
#   - atuin history: reliable for anything typed in a terminal
#   - mtime of ~/.config, ~/.cache, ~/.local/share: the only clue for graphical
#     apps, which are started from dmenu and never reach the shell history
#
# IMPORTANT LIMIT: "no trace" does not mean "useless". Services (ly, pipewire,
# grub) and libraries are never launched by hand. This script sorts, you decide.
#
# ARCH ONLY: the package half is built on `pacman -Qqe` and `pacman -Ql`, which
# maps a package to the binaries it ships. apt has no direct equivalent, and this
# is an occasional audit tool, not a link in the bootstrap chain.
set -uo pipefail

command -v pacman >/dev/null || {
    echo "audit-usage.sh: Arch only (needs pacman -Ql to map packages to binaries)" >&2
    exit 1
}

REPO="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
DB="$HOME/.local/share/atuin/history.db"
NOW=$(date +%s)
MODE="${1:-packages}"

if [ -t 1 ]; then G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; D=$'\e[2m'; B=$'\e[34m'; N=$'\e[0m'
else G=; Y=; R=; D=; B=; N=; fi

# Packages nobody ever invokes by hand, and without which nothing works.
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

# Aliases hide real usage. With `alias du="dust -r"`, the name `dust` never
# appears as such in the history. So we build a map of binary to the aliases
# that launch it.
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

usage_of() {  # usage_of <binary-name...> -> "run_count|last_timestamp"
    local where="" b a
    for b in "$@"; do
        # the binary itself, plus every alias pointing at it
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
    printf '%s=== PACKAGES =========================================================%s\n' "$B" "$N"
    local pkg bins runs ts d newest m best
    local -a never stale live
    for pkg in $(pacman -Qqe); do
        [[ "$pkg" =~ $INFRA ]] && continue
        mapfile -t bins < <(pacman -Ql "$pkg" 2>/dev/null \
            | awk '$2 ~ /^\/usr\/bin\/[^\/]+$/ {n=split($2,a,"/"); print a[n]}' | sort -u)
        [ "${#bins[@]}" -eq 0 ] && continue          # pure library, no judgement
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
        elif [ "$d" -gt 180 ]; then stale+=("$(printf '%s (%sx, %sd)' "$pkg" "$runs" "$d")")
        else live+=("$pkg"); fi
    done
    printf '\n %sNO TRACE AT ALL%s, %s packages\n' "$R" "$N" "${#never[@]}"
    printf '   %s\n' "$(printf '%s ' "${never[@]}" | fold -s -w 68 | sed '2,$s/^/   /')"
    printf '\n %sUNUSED FOR MORE THAN 6 MONTHS%s, %s packages\n' "$Y" "$N" "${#stale[@]}"
    printf '   %s\n' "$(printf '%s, ' "${stale[@]}" | fold -s -w 68 | sed '2,$s/^/   /')"
    printf '\n %sACTIVE%s, %s packages\n' "$G" "$N" "${#live[@]}"
    printf '\n %sInfrastructure is left out of the analysis%s (services, fonts,\n' "$D" "$N"
    printf ' %slibraries: never invoked by hand, so "no trace" means nothing there).%s\n' "$D" "$N"
}

audit_scripts() {
    printf '\n%s=== SCRIPTS IN /usr/local/bin ========================================%s\n' "$B" "$N"
    local s n refs runs ts d
    for s in "$REPO"/system/root/usr/local/bin/*; do
        n=$(basename "$s")
        refs=$(grep -rl --exclude-dir=.git -F "$n" \
               "$REPO/suckless" "$REPO/modules" "$REPO/system/root/etc" \
               "$REPO/system/root/usr" 2>/dev/null | grep -cv "usr/local/bin/$n\$")
        IFS='|' read -r runs ts < <(usage_of "$n")
        d=$(days_since "${ts:0:10}")
        if   [ "$refs" -gt 0 ]; then printf '  %s✓%s %-40s called by %s file(s)\n' "$G" "$N" "$n" "$refs"
        elif [ "$runs" -eq 0 ]; then printf '  %s✗%s %-40s orphan, never run\n' "$R" "$N" "$n"
        elif [ "$d" -gt 180 ]; then printf '  %s?%s %-40s %sx, last run %s days ago\n' "$Y" "$N" "$n" "$runs" "$d"
        else printf '  %s✓%s %-40s %sx, run by hand\n' "$G" "$N" "$n" "$runs"; fi
    done
}

command -v sqlite3 >/dev/null || { echo "sqlite3 required (pacman -S sqlite)"; exit 1; }
[ -f "$DB" ] || echo "  ! no atuin database, only disk mtime will be used"

case "$MODE" in
    packages) audit_packages ;;
    scripts)  audit_scripts ;;
    *)        audit_packages; audit_scripts ;;
esac
