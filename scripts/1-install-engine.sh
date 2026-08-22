#!/bin/bash
# Fetch the current stable GPTk engine (Mythic Engine) and extract to ~/Wine/gptk
set -euo pipefail
MANIFEST="https://dl.getmythic.app/engine/EngineUpdateStream.plist"
URL=$(curl -s "$MANIFEST" | grep -A2 downloadURL | grep -oE 'https?://[^<]+\.tar\.xz' | head -1)
[ -n "$URL" ] || { echo "could not read engine URL from $MANIFEST"; exit 1; }
echo "downloading $URL"
mkdir -p ~/Wine/gptk && curl -L "$URL" | tar -xJ -C ~/Wine/gptk
xattr -dr com.apple.quarantine ~/Wine/gptk 2>/dev/null || true
~/Wine/gptk/wine/bin/wine64 --version
