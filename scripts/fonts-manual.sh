#!/usr/bin/env bash
# The fonts no repository carries: two for st and dwmblocks (dwm profiles only), and the Nerd Fonts where the
# distribution does not package them (Ubuntu). Everything else comes from
# packages/<distro>/fonts.txt.
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

# fetch_nerd <archive> <family>: a Nerd Fonts release, skipped when the family is
# already installed, by the package manager on Arch for instance
NERD_URL='https://github.com/ryanoasis/nerd-fonts/releases/latest/download'
fetch_nerd() {
    local archive=$1 family=$2
    # grep without -q: an early exit would kill fc-list and pipefail would
    # report the font missing
    if fc-list : family | grep -iF "$family" >/dev/null; then
        printf '  \033[2m·\033[0m %s already there\n' "$family"
        return 0
    fi
    printf '  ... downloading %s\n' "$family"
    mkdir -p "$DEST/$archive"
    if curl -fsSL --retry 3 "$NERD_URL/$archive.tar.xz" | tar -xJ -C "$DEST/$archive"; then
        printf '  \033[32m✓\033[0m %s\n' "$family"
    else
        rm -rf "${DEST:?}/$archive"
        printf '  \033[33m!\033[0m %s: download failed, fetch it by hand:\n     %s\n' "$family" "$NERD_URL/$archive.tar.xz"
    fi
}

command -v curl >/dev/null || { echo "curl required" >&2; exit 1; }

if [ "${SUCKLESS_FONTS:-1}" = 1 ]; then
    fetch "$UNIFONTEX_URL" UnifontExMono.ttf
    fetch "$ICONS_URL"     icons-in-terminal.ttf
fi
# The fallback .config/fontconfig/fonts.conf appends to every family, so the
# icons render in any font without replacing it
fetch_nerd NerdFontsSymbolsOnly "Symbols Nerd Font Mono"

fc-cache -f "$DEST" >/dev/null 2>&1 && printf '  \033[32m✓\033[0m font cache rebuilt\n'
