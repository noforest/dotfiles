#!/bin/sh
# Détermine la session graphique courante sans coder en dur ni l'utilisateur ni son $HOME.
#
# Sourcé par les scripts appelés depuis udev, acpid ou systemd — c'est-à-dire par root,
# dans un environnement où DISPLAY, XAUTHORITY et HOME ne sont pas ceux de l'utilisateur.
#
# Utilisation :
#     . /usr/local/bin/desktop-env.sh
#     # DESKTOP_USER, USER_HOME, DISPLAY et XAUTHORITY sont alors définis

# 1) l'utilisateur d'une session graphique active, 2) le propriétaire de /run/user/1000,
# 3) à défaut, l'utilisateur courant.
DESKTOP_USER="${DESKTOP_USER:-$(
    loginctl list-sessions --no-legend 2>/dev/null \
        | awk '$3 != "" && $3 != "root" {print $3; exit}'
)}"
[ -n "$DESKTOP_USER" ] || DESKTOP_USER=$(stat -c %U /run/user/1000 2>/dev/null)
[ -n "$DESKTOP_USER" ] || DESKTOP_USER=$(id -un)

USER_HOME=$(getent passwd "$DESKTOP_USER" | cut -d: -f6)
[ -n "$USER_HOME" ] || USER_HOME="/home/$DESKTOP_USER"

export DESKTOP_USER USER_HOME
export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-$USER_HOME/.Xauthority}"

# Fichier d'état du mode d'inactivité, écrit par /usr/local/bin/idle_mode et lu
# par xidlehook-start.sh. Il vit dans /run/user, donc il disparaît à la
# déconnexion : chaque démarrage repart forcément en mode « default ».
IDLE_MODE_FILE="/run/user/$(id -u "$DESKTOP_USER")/idle_mode"
export IDLE_MODE_FILE
