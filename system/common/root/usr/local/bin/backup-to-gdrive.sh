#!/usr/bin/env bash
set -euo pipefail

# === CONFIGURATION ===
# Personal paths live outside the repository (see examples/ in the repository).
CONF_DIR="${BACKUP_GDRIVE_CONF_DIR:-$HOME/.config/backup-to-gdrive}"
FILTERS="$CONF_DIR/filters"

SRC1="$HOME/Documents"                            # first source
SRC2=""                                           # second source, optional
BASE_REMOTE="gdrive:_BackupsLinux"                # root on Drive

# Optional local overrides: SRC1, SRC2, BASE_REMOTE
[ -r "$CONF_DIR/config" ] && . "$CONF_DIR/config"

HOST="$(hostname)"                                # machine name
DEST="$BASE_REMOTE/$HOST"                         # main remote folder

if [ ! -r "$FILTERS" ]; then
    echo "backup-to-gdrive: missing filters file: $FILTERS" >&2
    echo "  copy examples/backup-to-gdrive.filters from the repository and adapt it." >&2
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

# Second source: synced as is, without filters, when it is
# set in the config file. When it is missing, there is simply nothing to do.
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
