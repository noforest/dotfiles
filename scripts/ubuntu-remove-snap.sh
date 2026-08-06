#!/usr/bin/env bash
# Removes snapd from an Ubuntu machine and keeps it from coming back.
#
# READ THIS FIRST. Removing snapd removes every application installed as a snap,
# and on Ubuntu Desktop that includes your browser: `firefox` and `thunderbird`
# are transitional packages whose only job is to install the corresponding snap.
#
# So the script starts by listing what you are about to lose, with a suggested
# replacement for each one it recognises, and stops there unless you confirm.
# Run it with --list to see that inventory and do nothing else.
#
# For Firefox, ./scripts/ubuntu-install-firefox-deb.sh installs the real .deb
# from Mozilla's own repository, following their official instructions.
#
# Everything here is idempotent: running it twice changes nothing the second time.
set -euo pipefail

YES=0; LIST_ONLY=0
case "${1:-}" in
    --yes)  YES=1 ;;
    --list) LIST_ONLY=1 ;;
esac

# Known non-snap replacements. Anything not listed here is reported as "look for
# a deb, a PPA, an AppImage or a flatpak" rather than guessed at.
replacement_for() {
    case "$1" in
        firefox)            echo "./scripts/ubuntu-install-firefox-deb.sh (real deb from Mozilla)" ;;
        thunderbird)        echo "apt install thunderbird from the Mozilla repository, same method as firefox" ;;
        chromium)           echo "apt install chromium from the Debian repository, or use firefox" ;;
        code)               echo "Microsoft apt repository, packages.microsoft.com" ;;
        spotify)            echo "Spotify apt repository, repository.spotify.com" ;;
        discord)            echo "the .deb from discord.com/download" ;;
        obsidian)           echo "the .deb from obsidian.md/download" ;;
        bitwarden)          echo "the .deb from bitwarden.com/download" ;;
        slack|zoom-client)  echo "the vendor .deb" ;;
        snap-store|gnome-*|gtk-common-themes|firmware-updater|snapd-desktop-integration|desktop-security-center|prompting-client)
                            echo "part of the Ubuntu desktop plumbing, nothing to replace on a dwm session" ;;
        core|core[0-9]*|bare)
                            echo "snap runtime, disappears with snapd" ;;
        *)                  echo "" ;;
    esac
}

if [ -t 1 ]; then R=$'\e[31m'; G=$'\e[32m'; Y=$'\e[33m'; D=$'\e[2m'; N=$'\e[0m'
else R=; G=; Y=; D=; N=; fi
ok()   { printf '  %s✓%s %s\n' "$G" "$N" "$*"; }
warn() { printf '  %s!%s %s\n' "$Y" "$N" "$*"; }
step() { printf '\n%s== %s%s\n' "$Y" "$*" "$N"; }
die()  { printf '  %s✗%s %s\n' "$R" "$N" "$*" >&2; exit 1; }

# Guard: this only makes sense where snapd is a distribution choice.
[ -r /etc/os-release ] || die "no /etc/os-release, not a Linux distribution I know"
. /etc/os-release
case "${ID:-}${ID_LIKE:-}" in
    *ubuntu*|*debian*) ;;
    *) die "Ubuntu or Debian only, this machine reports ID=${ID:-unknown}" ;;
esac
[ "$(id -u)" -ne 0 ] || die "run as your user, not root: the script calls sudo where needed"

step "what you are about to lose"
if ! command -v snap >/dev/null && ! dpkg -l snapd 2>/dev/null | grep -q '^ii'; then
    ok "snapd is already absent, nothing to do"
    exit 0
fi

n_unknown=0
printf '  %-28s %-10s %s\n' "SNAP" "VERSION" "REPLACEMENT"
printf '  %s\n' "$(printf '%.0s-' $(seq 1 72))"
while read -r name version _; do
    [ -n "$name" ] || continue
    [ "$name" = "Name" ] && continue
    rep=$(replacement_for "$name")
    if [ -z "$rep" ]; then
        rep="${Y}no known deb, look for a PPA, an AppImage or a flatpak${N}"
        n_unknown=$((n_unknown + 1))
    fi
    printf '  %-28s %-10s %b\n' "$name" "${version:0:10}" "$rep"
done < <(snap list 2>/dev/null | tail -n +2)

if [ "$n_unknown" -gt 0 ]; then
    printf '\n'
    warn "$n_unknown snap(s) above have no replacement listed in this script."
    warn "Install what you need from another source BEFORE continuing, or you"
    warn "will be without them until you do."
fi

if [ "$LIST_ONLY" -eq 1 ]; then
    printf '\n  %s--list: nothing was removed.%s\n' "$D" "$N"
    exit 0
fi

if [ "$YES" -eq 0 ]; then
    printf '\n  This removes every snap above, purges snapd and blocks it in apt.\n'
    printf '  %sYour browser goes with it if it is a snap.%s\n' "$Y" "$N"
    printf '  %sRe-run with --list to review the table without touching anything.%s\n' "$D" "$N"
    printf '  Continue? [y/N] '
    read -r a
    case "$a" in [yY]*) ;; *) die "aborted" ;; esac
fi

step "removing the snaps"
# Order matters. Snaps that others depend on refuse to go first, and the base
# snaps (core*, snapd, bare) must be last. Two passes are enough in practice.
for pass in 1 2; do
    while read -r name _; do
        [ -n "$name" ] || continue
        case "$name" in Name|core*|bare|snapd) continue ;; esac
        sudo snap remove --purge "$name" 2>/dev/null && ok "removed $name" || true
    done < <(snap list 2>/dev/null | tail -n +2)
done
for name in $(snap list 2>/dev/null | tail -n +2 | awk '{print $1}'); do
    sudo snap remove --purge "$name" 2>/dev/null && ok "removed $name" || true
done

step "stopping the services"
sudo systemctl disable --now snapd.service snapd.socket snapd.seeded.service 2>/dev/null || true
sudo systemctl disable --now snapd.apparmor.service 2>/dev/null || true
ok "snapd units stopped and disabled"

step "purging the package"
sudo apt-get purge -y snapd
sudo apt-get autoremove -y --purge
ok "snapd purged"

step "removing what it leaves behind"
# /var/lib/snapd holds the downloaded snaps, several hundred megabytes.
sudo rm -rf /var/cache/snapd /var/lib/snapd /snap /root/snap
rm -rf "$HOME/snap"
ok "state directories removed"

step "blocking reinstallation"
# A pin at -10 makes apt refuse snapd even as a dependency, so a package that
# recommends it installs without pulling it back in.
sudo tee /etc/apt/preferences.d/no-snap.pref >/dev/null <<'EOF'
# Keeps snapd out, including as a dependency of something else.
# Remove this file if you ever want snaps back.
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF
ok "/etc/apt/preferences.d/no-snap.pref written"

step "check"
command -v snap >/dev/null && warn "the snap command is still in PATH, open a new shell" || ok "the snap command is gone"
dpkg -l snapd 2>/dev/null | grep -q '^ii' && warn "snapd is still installed" || ok "snapd is not installed"
apt-cache policy snapd 2>/dev/null | grep -q 'Candidate: (none)\|-10' && ok "apt refuses snapd" || warn "check the apt pin"

printf '\n  %sDone. If you have not installed a real firefox yet, see the header of this script.%s\n' "$D" "$N"
