#!/usr/bin/env bash
# Les deux seules polices qui ne sont dans aucun dépôt Arch.
# Tout le reste vient de packages/fonts.txt.
set -euo pipefail

DEST="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
mkdir -p "$DEST"

# UnifontExMono — police de repli de st pour les glyphes exotiques
# (voir font2[] dans suckless/st/config.h)
UNIFONTEX_URL='https://github.com/stgiga/UnifontEX/releases/latest/download/UnifontExMono.ttf'

# icons-in-terminal — glyphes utilisés par dwmblocks et quelques scripts
ICONS_URL='https://github.com/sebastiencs/icons-in-terminal/raw/master/build/icons-in-terminal.ttf'

fetch() {  # fetch <url> <nom>
    local url=$1 name=$2
    if [ -f "$DEST/$name" ]; then
        printf '  \033[2m·\033[0m %s déjà présente\n' "$name"
        return 0
    fi
    printf '  … téléchargement de %s\n' "$name"
    if curl -fsSL --retry 3 -o "$DEST/$name.part" "$url"; then
        mv "$DEST/$name.part" "$DEST/$name"
        printf '  \033[32m✓\033[0m %s\n' "$name"
    else
        rm -f "$DEST/$name.part"
        printf '  \033[33m!\033[0m %s : téléchargement impossible — récupère-la à la main :\n     %s\n' "$name" "$url"
        return 0   # non bloquant : le reste de l'installation continue
    fi
}

command -v curl >/dev/null || { echo "curl requis" >&2; exit 1; }

fetch "$UNIFONTEX_URL" UnifontExMono.ttf
fetch "$ICONS_URL"     icons-in-terminal.ttf

fc-cache -f "$DEST" >/dev/null 2>&1 && printf '  \033[32m✓\033[0m cache de polices reconstruit\n'
