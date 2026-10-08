#!/bin/sh

# Read the last stored directory or fallback to home
LAST_DIR=$(cat "$HOME/.last_dir" 2>/dev/null || echo "$HOME")

# Launch ghostty in the last directory
ghostty --working-directory="$LAST_DIR"
