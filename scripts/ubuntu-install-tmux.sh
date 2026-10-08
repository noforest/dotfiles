#!/usr/bin/env bash
# Builds tmux from the official release tarball, in your home.
#
# Alt+E opens yazi in a floating pane (new-pane in ~/.tmux.conf), which is tmux
# 3.7. Ubuntu 26.04 ships 3.6a, where the only floating thing is a popup, and
# no image goes through a popup: it is not a pane, so the passthrough yazi
# sends its previews with has nowhere to go. The tmux project publishes sources
# only, hence a build. The tarball is checked against a SHA256 pinned here:
# bumping the version means updating the sum below, taken from the release page.
#
# Nothing is written outside $HOME, so no sudo:
#   ~/.local/opt/tmux-<version>/   the installed tree (bin/, share/man/)
#   ~/.local/bin/tmux              a link to its bin/tmux
#
# The build needs libevent-dev, libncurses-dev, bison, pkg-config and a
# compiler, all in packages/ubuntu/shell.txt, which `dot install` installs
# before it runs this.
#
# A server that is already running keeps the old binary until it exits, and the
# new client does not talk to it reliably: `tmux kill-server` once afterwards.
#
# Source: https://github.com/tmux/tmux/releases
set -euo pipefail

VERSION="3.8"
SHA256="e79c699c7e949dccd0a4a125e17b8d1261e311b16979dbc8eb34542f3966d82e"

if [ -t 1 ]; then G=$'\e[32m'; R=$'\e[31m'; N=$'\e[0m'
else G=; R=; N=; fi
ok()  { printf '  %s✓%s %s\n' "$G" "$N" "$*"; }
die() { printf '  %s✗%s %s\n' "$R" "$N" "$*" >&2; exit 1; }

[ "$(id -u)" -ne 0 ] || die "run as your user, not root"

dest="$HOME/.local/opt/tmux-$VERSION"
link="$HOME/.local/bin/tmux"
if [ -x "$dest/bin/tmux" ] && [ "$(readlink -f "$link" 2>/dev/null)" = "$dest/bin/tmux" ]; then
    ok "tmux $VERSION already installed"
    exit 0
fi

# configure would stop on each of these in turn, one run per missing package.
missing=
command -v curl >/dev/null || missing="$missing curl"
command -v cc >/dev/null && command -v make >/dev/null || missing="$missing build-essential"
command -v pkg-config >/dev/null || missing="$missing pkg-config"
command -v bison >/dev/null || command -v yacc >/dev/null || missing="$missing bison"
if command -v pkg-config >/dev/null; then
    pkg-config --exists libevent_core || missing="$missing libevent-dev"
    pkg-config --exists ncursesw || pkg-config --exists tinfo || missing="$missing libncurses-dev"
fi
[ -z "$missing" ] || die "missing to build tmux: sudo apt-get install$missing"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
archive="tmux-$VERSION.tar.gz"
curl -fsSL "https://github.com/tmux/tmux/releases/download/$VERSION/$archive" -o "$tmp/$archive" \
    || die "download failed"
# A mismatch means the tarball is not the one this script was written for, so
# this aborts rather than warns.
echo "$SHA256  $tmp/$archive" | sha256sum -c --quiet - || die "SHA256 mismatch for $archive, nothing installed"

tar -xzf "$tmp/$archive" -C "$tmp"
# --enable-sixel as in the Ubuntu and Arch packages: without it, a sixel image
# never reaches the terminal even from a plain pane.
( cd "$tmp/tmux-$VERSION" &&
  ./configure --prefix="$dest" --enable-sixel >"$tmp/build.log" 2>&1 &&
  make -j"$(nproc)" >>"$tmp/build.log" 2>&1 ) || { tail -n 20 "$tmp/build.log" >&2; die "build failed"; }

mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
rm -rf "$dest"
make -C "$tmp/tmux-$VERSION" install >>"$tmp/build.log" 2>&1 || { tail -n 20 "$tmp/build.log" >&2; die "install failed"; }
ln -sfn "$dest/bin/tmux" "$link"
ok "tmux $VERSION installed in $dest"
ok "$link -> $dest/bin/tmux"
if tmux list-sessions >/dev/null 2>&1; then
    printf '  A tmux server is running on the old binary: tmux kill-server, then start it again.\n'
fi
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) printf '  ~/.local/bin is not on your PATH yet, .zshrc adds it.\n' ;;
esac
