#!/usr/bin/env bash
set -euo pipefail

# === CONFIGURATION ===
# Les chemins personnels vivent hors du dépôt (voir examples/ dans le dépôt).
CONF_DIR="${BACKUP_GDRIVE_CONF_DIR:-$HOME/.config/backup-to-gdrive}"
FILTERS="$CONF_DIR/filters"

SRC1="$HOME/Documents"                            # première source
SRC2=""                                           # deuxième source, facultative
BASE_REMOTE="gdrive:_BackupsLinux"                # racine sur Drive

# Surcharges locales facultatives : SRC1, SRC2, BASE_REMOTE
[ -r "$CONF_DIR/config" ] && . "$CONF_DIR/config"

HOST="$(hostname)"                                # nom de la machine
DEST="$BASE_REMOTE/$HOST"                         # dossier principal distant

if [ ! -r "$FILTERS" ]; then
    echo "backup-to-gdrive: fichier de filtres manquant : $FILTERS" >&2
    echo "  copiez examples/backup-to-gdrive.filters du dépôt et adaptez-le." >&2
    exit 1
fi

# === SYNCHRONISATION ===

# Documents
rclone sync \
    --verbose \
    --progress \
    --transfers 4 \
    --checkers 8 \
    --copy-links \
    --fast-list \
    --filter-from "$FILTERS" \
    --exclude "*~" \
    --exclude "*.dot" \
    --exclude "*.gcda" \
    --exclude "*.gcno" \
    --exclude "*.o" \
    --exclude "*.out" \
    --exclude ".vscode*" \
    --exclude "dist/**" \
    --exclude "node_modules/**" \
    --exclude "coverage/**" \
    --exclude "package-lock.json" \
    --exclude ".git/**" \
    --exclude "*/.git/**" \
    --exclude "gsl-2.8/**" \
    --exclude "__pycache__/**" \
    --exclude "*.pyc" \
    --exclude "*.pyo" \
    --exclude "*.class" \
    --exclude "build/**" \
    --exclude "target/**" \
    --exclude ".cache/**" \
    --exclude ".idea/**" \
    --exclude "*.log" \
    --exclude "tmp/**" \
    --exclude "temp/**" \
    --exclude "temp/**" \
    --exclude "**/video/**" \
    --exclude "**/videos/**" \
    "$SRC1" \
    "$DEST/Documents"

# Deuxième source : synchronisée telle quelle, sans filtres, quand elle est
# définie dans le fichier de config. Absente, il n'y a simplement rien à faire.
if [ -n "$SRC2" ]; then
    rclone sync \
        --verbose \
        --progress \
        --transfers 4 \
        --checkers 8 \
        --copy-links \
        --fast-list \
        "$SRC2" \
        "$DEST/$(basename "$SRC2")"
fi
