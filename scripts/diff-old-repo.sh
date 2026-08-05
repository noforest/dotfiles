#!/usr/bin/env bash
# Compare the old bare repo (~/.dotfiles, left untouched) to this one, file by file.
#
#   ./scripts/diff-old-repo.sh            summary of what changed
#   ./scripts/diff-old-repo.sh -v         the full diff
#   ./scripts/diff-old-repo.sh .zshrc     the diff of one file
set -uo pipefail

REPO="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
OLD_GIT="$HOME/.dotfiles"
OLD() { (cd "$HOME" && git --git-dir="$OLD_GIT" --work-tree="$HOME" "$@"); }

[ -d "$OLD_GIT" ] || { echo "old repo not found: $OLD_GIT" >&2; exit 1; }

if [ -t 1 ]; then G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; D=$'\e[2m'; N=$'\e[0m'
else G=; Y=; R=; D=; N=; fi

# Where does the new repo keep a path relative to $HOME?
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
    # noise that was deliberately left out of the new repo
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
                printf '\n%s=== %s %s===%s\n' "$Y" "$rel" "$Y" "$N"
                OLD show "HEAD:$rel" 2>/dev/null | diff -u - "$new" \
                    | sed '1,2d' | sed "s/^-/${R}-/;s/^+/${G}+/;s/\$/${N}/"
            fi
        fi
    else
        absent=$((absent+1)); ABSENT+=("$rel")
    fi
done < <(OLD ls-files)

[ -n "$only" ] && exit 0

printf '\n%s=== Old repo compared to the new one ===========================%s\n' "$Y" "$N"
printf '\n  %s%s identical files%s\n' "$G" "$same" "$N"

printf '\n  %s%s modified files%s:\n' "$Y" "$changed" "$N"
printf '      %s\n' "${CHANGED[@]}"
printf '      %s-> detail: ./scripts/diff-old-repo.sh <file>%s\n' "$D" "$N"

printf '\n  %s%s files not carried over%s (noise, left out on purpose):\n' "$D" "$absent" "$N"
printf '      %s\n' "${ABSENT[@]:0:12}"
[ "$absent" -gt 12 ] && printf '      %s... and %s more%s\n' "$D" "$((absent-12))" "$N"

printf '\n  %sThe old repo was never touched: %s commits, still pushed to GitHub.%s\n' \
       "$D" "$(OLD rev-list --count HEAD)" "$N"
printf '  %sTo go back to any of it: dotfiles checkout HEAD -- <file>%s\n\n' "$D" "$N"
