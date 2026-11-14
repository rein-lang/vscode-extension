#!/bin/sh
# Usage: make-icon.sh <logo.svg> <repo>
# Writes images/icon.png (256 px, the Marketplace icon) and images/logo.png
# (320 px, for the README; the Marketplace rejects SVG images there).
set -eu
command -v rsvg-convert >/dev/null || { echo "rsvg-convert not found"; exit 1; }
mkdir -p "$2/images"
rsvg-convert -w 256 -h 256 "$1" -o "$2/images/icon.png"
rsvg-convert -w 320 -h 320 "$1" -o "$2/images/logo.png"
echo "$2/images/icon.png $2/images/logo.png"
