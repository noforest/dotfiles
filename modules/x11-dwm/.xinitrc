#!/bin/sh

# Pour que clipster fonctionne
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

# HACK: faire <gf> dans nvim pour ouvrir le fichier sous le curseur
# *****************************************************
# autres dossiers & fichiers importants:
# - /etc/udev/rules.d/* (ex: 95-monitor-hotplug.rules)
# - /etc/X11/xorg.conf.d/*
# - /etc/ly/config.ini
# - /etc/systemd/logind.conf
# - /etc/systemd/system/*
# - /etc/acpi/events/*
# - /usr/local/bin/*
#
# ==> tous ces fichiers sont désormais versionnés dans system/ du dépôt dotfiles,
#     et déployés par `dot system-apply`.
# *****************************************************

exec >"$HOME/.xinitrc.log" 2>&1
# ly stocke le fichier d'autorité dans /run/user/<uid>/lyxauth : on le recopie vers
# ~/.Xauthority, que plusieurs scripts lisent. Les autres gestionnaires de session
# (GDM, LightDM, SDDM) exportent XAUTHORITY eux-mêmes et n'ont rien à recopier —
# d'où le test, sans lequel `set -e` ferait échouer la session sur une machine sans ly.
if [ -r "/run/user/$(id -u)/lyxauth" ]; then
    cp "/run/user/$(id -u)/lyxauth" ~/.Xauthority
fi
# Donne DISPLAY et XAUTHORITY au gestionnaire systemd utilisateur.
# ly + .xinitrc ne démarrent pas la session via systemd : sans cet import, les
# services activés à la demande (xdg-desktop-portal-gtk, xfconfd…) échouent sur
# « cannot open display » et thunar ou flameshot restent bloqués.
systemctl --user import-environment DISPLAY XAUTHORITY 2>/dev/null

picom -b &
dunst &
playerctld daemon &
# feh --bg-fill ~/Pictures/from_twitter/IMG_7741.JPG &
# feh --bg-fill Pictures/Wallpapers/a_ski_lift_with_a_chair_in_the_air.jpg &
# feh --bg-fill ~/Pictures/Wallpapers/purple_mountain.JPG &

export WALLPAPER="${WALLPAPER:-$HOME/Pictures/Wallpapers/banshee_of_inisherin.png}"
[ -f "$WALLPAPER" ] && feh --bg-fill "$WALLPAPER" &

numlockx &
xset r rate 250 50 &

clipster -d -f ~/.config/clipster/clipster.ini &
export MOZ_GTK_TITLEBAR_DECORATION=none

# Réglages propres à la machine : identifiants xinput, écrans, périphériques.
# Ces noms ("ELAN2204:00 04F3:3109 Touchpad"…) n'existent que sur un portable donné,
# d'où un fichier par machine. Sur un nouveau PC : créer le sien, sinon rien n'est chargé.
MACHINE_CONF="$HOME/.config/dwm/machine.d/$(hostname).sh"
[ -r "$MACHINE_CONF" ] && . "$MACHINE_CONF"

libinput-gestures-setup restart &
dwmblocks &


# IMPORTANT: ouvre en arrière plan solaar: permet d'éviter que le logibolt
# envoie des signaux USB au contrôleur usb XHC0 PENDANT que je suis en suspend
# impliquant le réveil involontaire de l'ordi (situation: quand je ferme le capot, etc...)
solaar -w hide &  

xset -dpms        # désactive DPMS natif (évite HDMI disconnected)
xset s off        # désactive le screensaver X (sinon au bout de 10min slock s'active tt seul)
export SESSION_ID=$(loginctl list-sessions --no-legend | awk '$4 != "-" {print $1}' | head -1)
xss-lock --session="$SESSION_ID" -- /usr/local/bin/slock-wrapper.sh &   # NOTE: Permet de remettre l'écran noir au bout de x secondes quand slock actif
                                                                        # du coup quand je fais slock dans le terminal: il n'y a
                                                                        # plus de wrapper (reste donc tout le temps actif ou du moins pendant 
                                                                        # le temps restant du script xidlehook-start.sh) 
                                                                        # ==> il faut que je fasse la commande lock (qui est un alias de xset s activate) 
                                                                        # pour activer xss-lock et donc le wrapper de slock

# NOTE: et est utilisé dans: /etc/acpi/events/autolock-power (acpid détecte
# branchement et débranchement)
/usr/local/bin/xidlehook-start.sh & 

exec dwm
