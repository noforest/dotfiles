#!/usr/bin/env bash
# Compare fichier par fichier l'ancien dépôt bare (~/.dotfiles, intact) au nouveau.
#
#   ./scripts/diff-ancien-depot.sh            → résumé : quoi a changé
#   ./scripts/diff-ancien-depot.sh -v         → le diff complet
#   ./scripts/diff-ancien-depot.sh .zshrc     → le diff d'un fichier précis
set -uo pipefail

REPO="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
OLD_GIT="$HOME/.dotfiles"
OLD() { (cd "$HOME" && git --git-dir="$OLD_GIT" --work-tree="$HOME" "$@"); }

[ -d "$OLD_GIT" ] || { echo "ancien dépôt introuvable : $OLD_GIT" >&2; exit 1; }

if [ -t 1 ]; then G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; D=$'\e[2m'; N=$'\e[0m'
else G=; Y=; R=; D=; N=; fi

# Où le nouveau dépôt range-t-il un chemin relatif à $HOME ?
locate_new() {
    local rel="$1" m
    for m in "$REPO"/modules/*/; do
        [ -e "$m$rel" ] && { printf '%s\n' "$m$rel"; return 0; }
    done
    return 1
}

verbose=0; only=""
case "${1:-}" in
    -v|--verbose) verbose=1 ;;
    "") ;;
    *) only="$1" ;;
esac

same=0; changed=0; absent=0
declare -a CHANGED ABSENT

while read -r rel; do
    [ -n "$rel" ] || continue
    [ -n "$only" ] && [ "$rel" != "$only" ] && continue
    # bruit qu'on a volontairement écarté du nouveau dépôt
    case "$rel" in
        .local/share/nvim/lazy/*|.config/nvim/plugins/codediff_milestone_noah/*) continue ;;
        Suckless/*) continue ;;
    esac

    if new=$(locate_new "$rel"); then
        if OLD show "HEAD:$rel" 2>/dev/null | diff -q - "$new" >/dev/null 2>&1; then
            same=$((same+1))
        else
            changed=$((changed+1)); CHANGED+=("$rel")
            if [ "$verbose" = 1 ] || [ -n "$only" ]; then
                printf '\n%s═══ %s %s═══%s\n' "$Y" "$rel" "$Y" "$N"
                OLD show "HEAD:$rel" 2>/dev/null | diff -u - "$new" \
                    | sed '1,2d' | sed "s/^-/${R}-/;s/^+/${G}+/;s/\$/${N}/"
            fi
        fi
    else
        absent=$((absent+1)); ABSENT+=("$rel")
    fi
done < <(OLD ls-files)

[ -n "$only" ] && exit 0

printf '\n%s╔══ Comparaison ancien dépôt → nouveau ══════════════════════════╗%s\n' "$Y" "$N"
printf '\n  %s%s fichiers identiques%s\n' "$G" "$same" "$N"

printf '\n  %s%s fichiers modifiés%s :\n' "$Y" "$changed" "$N"
printf '      %s\n' "${CHANGED[@]}"
printf '      %s→ détail : ./scripts/diff-ancien-depot.sh <fichier>%s\n' "$D" "$N"

printf '\n  %s%s fichiers non repris%s (bruit écarté volontairement) :\n' "$D" "$absent" "$N"
printf '      %s\n' "${ABSENT[@]:0:12}"
[ "$absent" -gt 12 ] && printf '      %s… et %s autres%s\n' "$D" "$((absent-12))" "$N"

printf '\n  %sL'"'"'ancien dépôt n'"'"'a pas été touché : %s commits, toujours poussé sur GitHub.%s\n' \
       "$D" "$(OLD rev-list --count HEAD)" "$N"
printf '  %sPour y revenir entièrement : dotfiles checkout HEAD -- <fichier>%s\n\n' "$D" "$N"
