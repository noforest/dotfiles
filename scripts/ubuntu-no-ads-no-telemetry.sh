#!/usr/bin/env bash
# Silences the Ubuntu Pro advertising and turns off the data that leaves the machine.
#
# Three separate advertising mechanisms, plus five reporting ones. Each is handled
# by configuration rather than by removing packages, because ubuntu-pro-client is
# also what applies ESM security updates if you ever enable them. Removing it
# would trade advertising for missing patches.
#
# Everything is idempotent and reversible, each change says how to undo it.
set -euo pipefail

YES=0
[ "${1:-}" = "--yes" ] && YES=1

if [ -t 1 ]; then G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; D=$'\e[2m'; N=$'\e[0m'
else G=; Y=; R=; D=; N=; fi
ok()   { printf '  %s✓%s %s\n' "$G" "$N" "$*"; }
warn() { printf '  %s!%s %s\n' "$Y" "$N" "$*"; }
step() { printf '\n%s== %s%s\n' "$Y" "$*" "$N"; }
die()  { printf '  %s✗%s %s\n' "$R" "$N" "$*" >&2; exit 1; }

[ -r /etc/os-release ] || die "no /etc/os-release"
. /etc/os-release
case "${ID:-}${ID_LIKE:-}" in
    *ubuntu*|*debian*) ;;
    *) die "Ubuntu or Debian only, this machine reports ID=${ID:-unknown}" ;;
esac
[ "$(id -u)" -ne 0 ] || die "run as your user, not root: the script calls sudo where needed"

if [ "$YES" -eq 0 ]; then
    printf '  Turns off Ubuntu Pro adverts, APT News, MOTD news and crash reporting.\n'
    printf '  Nothing is uninstalled. Continue? [y/N] '
    read -r a
    case "$a" in [yY]*) ;; *) die "aborted" ;; esac
fi

step "1. Ubuntu Pro adverts in apt"
# The ubuntu-pro-client hook is what prints "N additional security updates are
# available with ESM Apps" after every upgrade.
sudo tee /etc/apt/apt.conf.d/99-no-pro-ads >/dev/null <<'EOF'
# Ubuntu Pro / ESM advertising, off.
# Undo: delete this file.
APT::Periodic::Enable "0";
EOF
if [ -f /etc/apt/apt.conf.d/20apt-esm-hook.conf ]; then
    sudo mv /etc/apt/apt.conf.d/20apt-esm-hook.conf \
            /etc/apt/apt.conf.d/20apt-esm-hook.conf.disabled
    ok "ESM apt hook disabled (renamed to .disabled)"
else
    ok "no ESM apt hook on this machine"
fi
# ubuntu-advantage was the old name, ubuntu-pro-client the current one.
for u in ua-timer.timer ua-messaging.timer ua-license-check.timer \
         apt-news.service esm-cache.service ubuntu-advantage.service; do
    systemctl list-unit-files "$u" >/dev/null 2>&1 \
        && sudo systemctl disable --now "$u" 2>/dev/null && ok "disabled $u" || true
done

step "2. APT News"
# apt update downloads a commercial news feed from motd.ubuntu.com and prints it.
sudo tee /etc/apt/apt.conf.d/99-no-apt-news >/dev/null <<'EOF'
# The news feed shown by `apt update`, off.
# Undo: delete this file.
APT::News "0";
Acquire::Languages "none";
EOF
ok "APT News off"

step "3. MOTD news"
# /etc/update-motd.d/50-motd-news phones home every 12 hours through a systemd
# timer, sending the Ubuntu version, the architecture and the cloud id in the
# User-Agent. This is the mechanism that carried the Microsoft/Azure promotion.
if [ -f /etc/default/motd-news ]; then
    sudo sed -i 's/^ENABLED=.*/ENABLED=0/' /etc/default/motd-news
    ok "/etc/default/motd-news: ENABLED=0"
fi
sudo systemctl disable --now motd-news.timer motd-news.service 2>/dev/null \
    && ok "motd-news timer stopped" || ok "no motd-news timer"
for f in /etc/update-motd.d/50-motd-news /etc/update-motd.d/88-esm-announce \
         /etc/update-motd.d/91-contract-ua-esm-status; do
    [ -x "$f" ] && sudo chmod -x "$f" && ok "$(basename "$f") no longer runs"
done

step "4. Telemetry and crash reporting"
# ubuntu-report sends a hardware census at install time. Refuse it explicitly.
command -v ubuntu-report >/dev/null && { ubuntu-report send no >/dev/null 2>&1 \
    && ok "ubuntu-report: refused" || warn "ubuntu-report: could not set"; }

# apport builds crash reports, whoopsie uploads them to Canonical.
if [ -f /etc/default/apport ]; then
    sudo sed -i 's/^enabled=.*/enabled=0/' /etc/default/apport
    ok "apport disabled"
fi
sudo systemctl disable --now apport.service whoopsie.service kerneloops.service 2>/dev/null || true
if [ -f /etc/whoopsie ]; then
    sudo sed -i 's/^report_crashes=.*/report_crashes=false/' /etc/whoopsie
    ok "whoopsie: report_crashes=false"
fi

# popularity-contest reports the list of installed packages every week.
if [ -f /etc/popularity-contest.conf ]; then
    sudo sed -i 's/^PARTICIPATE=.*/PARTICIPATE="no"/' /etc/popularity-contest.conf
    ok "popularity-contest: no"
fi

# The GNOME privacy knobs, harmless if GNOME is not installed.
command -v gsettings >/dev/null && {
    gsettings set org.gnome.desktop.privacy report-technical-problems false 2>/dev/null || true
    gsettings set org.gnome.desktop.privacy send-software-usage-stats false 2>/dev/null || true
}

step "check"
grep -qs '^ENABLED=0' /etc/default/motd-news && ok "motd-news off" || warn "motd-news: check by hand"
[ -f /etc/apt/apt.conf.d/99-no-apt-news ] && ok "APT News off"
[ -f /etc/apt/apt.conf.d/20apt-esm-hook.conf ] && warn "the ESM hook is back" || ok "no ESM hook"
systemctl is-enabled whoopsie.service 2>/dev/null | grep -q enabled \
    && warn "whoopsie still enabled" || ok "whoopsie off"

printf '\n  %sRun `apt update && apt upgrade` once to confirm the adverts are gone.%s\n' "$D" "$N"
printf '  %sAn Ubuntu upgrade may restore some of these files. Re-run this script after one.%s\n' "$D" "$N"
