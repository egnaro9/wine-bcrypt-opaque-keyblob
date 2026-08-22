#!/bin/bash
# Frozen launch. Use this every time; never launch Steam.exe bare.
set -euo pipefail
W=~/Wine/gptk/wine/bin
export WINEPREFIX="${WINEPREFIX:-$HOME/Wine/steam-prefix}"
PIN="http://web.archive.org/web/20250311093241if_/media.steampowered.com/client"
if pgrep -x steam_osx >/dev/null 2>&1; then
  echo "REFUSING: native macOS Steam is running (two clients cannot share the network)"; exit 1
fi
exec "$W/wine64" "$WINEPREFIX/drive_c/Program Files (x86)/Steam/Steam.exe" \
  -noverifyfiles -nobootstrapupdate -norepairfiles -overridepackageurl "$PIN" "$@"
