#!/bin/sh

# Read the last stored directory or fallback to home
LAST_DIR=$(cat "$HOME/.last_dir" 2>/dev/null || echo "$HOME")

# Launch alacritty in the last directory
alacritty --working-directory "$LAST_DIR"
