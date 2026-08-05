#!/usr/bin/env bash
# The only two fonts that no Arch repository carries.
# Everything else comes from packages/fonts.txt.
set -euo pipefail

DEST="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
mkdir -p "$DEST"

# UnifontExMono, the fallback font st uses for exotic glyphs
# (see font2[] in suckless/st/config.h)
UNIFONTEX_URL='https://github.com/stgiga/UnifontEX/releases/latest/download/UnifontExMono.ttf'

# icons-in-terminal, the glyphs used by dwmblocks and a few scripts
ICONS_URL='https://github.com/sebastiencs/icons-in-terminal/raw/master/build/icons-in-terminal.ttf'

fetch() {  # fetch <url> <name>
    local url=$1 name=$2
    if [ -f "$DEST/$name" ]; then
        printf '  \033[2m·\033[0m %s already there\n' "$name"
        return 0
    fi
    printf '  ... downloading %s\n' "$name"
    if curl -fsSL --retry 3 -o "$DEST/$name.part" "$url"; then
        mv "$DEST/$name.part" "$DEST/$name"
        printf '  \033[32m✓\033[0m %s\n' "$name"
    else
        rm -f "$DEST/$name.part"
        printf '  \033[33m!\033[0m %s: download failed, fetch it by hand:\n     %s\n' "$name" "$url"
        return 0   # not fatal, the rest of the install carries on
    fi
}

command -v curl >/dev/null || { echo "curl required" >&2; exit 1; }

fetch "$UNIFONTEX_URL" UnifontExMono.ttf
fetch "$ICONS_URL"     icons-in-terminal.ttf

fc-cache -f "$DEST" >/dev/null 2>&1 && printf '  \033[32m✓\033[0m font cache rebuilt\n'
