#!/usr/bin/env bash
# Installs neovim from the official release archive, in your home.
#
# The nvim config needs neovim 0.12 (nvim-treesitter calls vim.list.unique, which
# 0.11 does not have, and no parser gets installed without it). Ubuntu 26.04
# ships 0.11.6. The archive is the one the neovim project publishes on GitHub,
# checked against a SHA256 pinned here: bumping the version means updating the
# two sums below, taken from the release page.
#
# Nothing is written outside $HOME, so no sudo:
#   ~/.local/opt/nvim-<version>/   the unpacked archive
#   ~/.local/bin/nvim              a link to its bin/nvim
#
# Source: https://github.com/neovim/neovim/releases
set -euo pipefail

VERSION="0.12.5"
SHA256_x86_64="bce0f56eda1f1b1db6eee8f4133d7a38813ea07933837dd1777411ca384c6875"
SHA256_arm64="1aa5ca085249580ae0f91eb14f27ec0919773ff2d99a163d03f3d6c21ac29725"

if [ -t 1 ]; then G=$'\e[32m'; R=$'\e[31m'; N=$'\e[0m'
else G=; R=; N=; fi
ok()  { printf '  %s✓%s %s\n' "$G" "$N" "$*"; }
die() { printf '  %s✗%s %s\n' "$R" "$N" "$*" >&2; exit 1; }

[ "$(id -u)" -ne 0 ] || die "run as your user, not root"
case "$(uname -m)" in
    x86_64)        arch=x86_64; sum=$SHA256_x86_64 ;;
    aarch64|arm64) arch=arm64;  sum=$SHA256_arm64 ;;
    *) die "no official neovim archive for $(uname -m)" ;;
esac

dest="$HOME/.local/opt/nvim-$VERSION"
link="$HOME/.local/bin/nvim"
if [ -x "$dest/bin/nvim" ] && [ "$(readlink -f "$link" 2>/dev/null)" = "$dest/bin/nvim" ]; then
    ok "neovim $VERSION already installed"
    exit 0
fi
command -v curl >/dev/null || die "curl missing: sudo apt-get install curl"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
archive="nvim-linux-$arch.tar.gz"
curl -fsSL "https://github.com/neovim/neovim/releases/download/v$VERSION/$archive" -o "$tmp/$archive" \
    || die "download failed"
# A mismatch means the archive is not the one this script was written for, so
# this aborts rather than warns.
echo "$sum  $tmp/$archive" | sha256sum -c --quiet - || die "SHA256 mismatch for $archive, nothing installed"

mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
rm -rf "$dest"
tar -xzf "$tmp/$archive" -C "$tmp"
mv "$tmp/nvim-linux-$arch" "$dest"
ln -sfn "$dest/bin/nvim" "$link"
ok "neovim $VERSION installed in $dest"
ok "$link -> $dest/bin/nvim"
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) printf '  ~/.local/bin is not on your PATH yet, .zshrc adds it.\n' ;;
esac
