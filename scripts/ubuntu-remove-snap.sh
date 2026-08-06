#!/usr/bin/env bash
# Removes snapd from an Ubuntu machine and keeps it from coming back.
#
# READ THIS FIRST. On Ubuntu Desktop, `firefox` and `thunderbird` are transitional
# packages whose only job is to install the corresponding snap. Purging snapd
# therefore removes your browser. Install a real one before or right after:
#
#     # Mozilla's own apt repository, a genuine .deb, updated by apt
#     sudo install -d -m 0755 /etc/apt/keyrings
#     wget -qO- https://packages.mozilla.org/apt/repo-signing-key.gpg \
#         | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
#     echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] \
#https://packages.mozilla.org/apt mozilla main" \
#         | sudo tee /etc/apt/sources.list.d/mozilla.list
#     printf 'Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n' \
#         | sudo tee /etc/apt/preferences.d/mozilla
#     sudo apt update && sudo apt install firefox
#
# Everything here is idempotent: running it twice changes nothing the second time.
set -euo pipefail

YES=0
[ "${1:-}" = "--yes" ] && YES=1

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

step "what is installed today"
if ! command -v snap >/dev/null && ! dpkg -l snapd 2>/dev/null | grep -q '^ii'; then
    ok "snapd is already absent, nothing to do"
    exit 0
fi
snap list 2>/dev/null | tail -n +2 | awk '{printf "      %s\n", $1}' || true

if [ "$YES" -eq 0 ]; then
    printf '\n  This removes every snap above, purges snapd and blocks it in apt.\n'
    printf '  %sfirefox and thunderbird will go with it if they are snaps.%s\n' "$Y" "$N"
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
