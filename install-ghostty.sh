#!/usr/bin/env bash
set -euo pipefail

# Ghostty, fast GPU-accelerated native terminal emulator. See https://ghostty.org/
if [ -d "/Applications/Ghostty.app" ]; then
    echo "Ghostty already present at /Applications/Ghostty.app — skipping cask install."
else
    brew install --cask ghostty
fi

echo "Ghostty installed."
echo "Config file: ~/.config/ghostty/config (run 'ghostty +show-config --default --docs' for options)"
