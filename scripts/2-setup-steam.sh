#!/bin/bash
# Fresh prefix + Steam stub + pinned early-2025 client. Run once.
set -euo pipefail
W=~/Wine/gptk/wine/bin
export WINEPREFIX="${WINEPREFIX:-$HOME/Wine/steam-prefix}"
PIN="http://web.archive.org/web/20250311093241if_/media.steampowered.com/client"
SETUP="${1:?usage: 2-setup-steam.sh /path/to/SteamSetup.exe}"
"$W/wine64" wineboot -i
"$W/wine64" "$SETUP" /S; sleep 5
ST="$WINEPREFIX/drive_c/Program Files (x86)/Steam"
"$W/wine64" "$ST/Steam.exe" -forcesteamupdate -forcepackagedownload -overridepackageurl "$PIN" -exitsteam
until grep -q "Update complete\|Nothing to do" "$ST/logs/bootstrap_log.txt" 2>/dev/null; do sleep 10; done
grep -oE "/web/[0-9]+if_[^ ]*steam_client_[a-z0-9]+" "$ST/logs/bootstrap_log.txt" | tail -1 | tee /tmp/pin-check
grep -q "steam_client_win32" /tmp/pin-check || { echo "PIN FAILED: wrong manifest (see README trap note)"; exit 1; }
echo "OK: pinned win32 client installed"
