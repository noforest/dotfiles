#!/usr/bin/env bash
# Installs Firefox as a real .deb from Mozilla's own APT repository.
#
# Ubuntu ships `firefox` as a transitional package whose only job is to install
# the snap. This follows Mozilla's official instructions, including the deb822
# `.sources` format that Debian Trixie and Ubuntu Resolute (26.04) and newer
# expect, and the pin that keeps apt from falling back to the Ubuntu package.
#
# Source: https://support.mozilla.org/kb/install-firefox-linux
set -euo pipefail

if [ -t 1 ]; then G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; D=$'\e[2m'; N=$'\e[0m'
else G=; Y=; R=; D=; N=; fi
ok()   { printf '  %s✓%s %s\n' "$G" "$N" "$*"; }
step() { printf '\n%s== %s%s\n' "$Y" "$*" "$N"; }
die()  { printf '  %s✗%s %s\n' "$R" "$N" "$*" >&2; exit 1; }

[ -r /etc/os-release ] || die "no /etc/os-release"
. /etc/os-release
case "${ID:-}${ID_LIKE:-}" in *ubuntu*|*debian*) ;; *) die "Ubuntu or Debian only" ;; esac
[ "$(id -u)" -ne 0 ] || die "run as your user, not root"
command -v wget >/dev/null || die "wget missing: sudo apt-get install wget"

LANGPACK="${1:-}"   # optional, e.g. fr

step "1. keyring directory"
sudo install -d -m 0755 /etc/apt/keyrings
ok "/etc/apt/keyrings"

step "2. Mozilla signing key"
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- \
    | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
ok "key imported"

step "3. fingerprint check"
# Must be 35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3. A mismatch means the key was
# tampered with in transit, so this aborts rather than warns.
FPR=$(gpg -n -q --import --import-options import-show \
        /etc/apt/keyrings/packages.mozilla.org.asc 2>/dev/null \
      | awk '/pub/{getline; gsub(/^ +| +$/,""); print; exit}')
if [ "$FPR" = "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3" ]; then
    ok "fingerprint matches ($FPR)"
else
    sudo rm -f /etc/apt/keyrings/packages.mozilla.org.asc
    die "fingerprint mismatch: got '$FPR'. Key removed, nothing installed."
fi

step "4. repository"
# Ubuntu 26.04 (resolute) and newer want deb822. Older releases use a one line
# entry in a .list file.
case "${VERSION_ID:-}" in
    24.*|22.*|20.*)
        echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" \
            | sudo tee /etc/apt/sources.list.d/mozilla.list > /dev/null
        ok "/etc/apt/sources.list.d/mozilla.list (one line format)" ;;
    *)
        sudo tee /etc/apt/sources.list.d/mozilla.sources > /dev/null <<'EOF'
Types: deb
URIs: https://packages.mozilla.org/apt
Suites: mozilla
Components: main
Signed-By: /etc/apt/keyrings/packages.mozilla.org.asc
EOF
        ok "/etc/apt/sources.list.d/mozilla.sources (deb822)" ;;
esac

step "5. priority over the Ubuntu package"
sudo tee /etc/apt/preferences.d/mozilla > /dev/null <<'EOF'
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF
ok "pinned at 1000"

step "6. install"
sudo apt-get update
sudo apt-get install -y firefox
[ -n "$LANGPACK" ] && sudo apt-get install -y "firefox-l10n-$LANGPACK" \
    && ok "language pack firefox-l10n-$LANGPACK"

step "check"
apt-cache policy firefox | sed 's/^/      /' | head -4
printf '\n  %sIf the candidate comes from packages.mozilla.org, you have the real deb.%s\n' "$D" "$N"
printf '  %sLanguage packs: %s./scripts/ubuntu-install-firefox-deb.sh fr%s, list them with `apt-cache search firefox-l10n`.%s\n' "$D" "$G" "$D" "$N"
