#!/bin/sh
TMPFILE=$(mktemp /tmp/screenshot-XXXXXX.png)

# capture
maim -s "$TMPFILE"

# édition
swappy -f "$TMPFILE"

# copier dans le presse-papiers comme image
xclip -selection clipboard -t image/png -i "$TMPFILE"

# nettoyage
rm -f "$TMPFILE"
