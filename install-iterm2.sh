#!/usr/bin/env bash
set -euo pipefail

# iTerm2, feature-rich terminal emulator for macOS. See https://iterm2.com/
if [ -d "/Applications/iTerm.app" ]; then
    echo "iTerm2 already present at /Applications/iTerm.app — skipping cask install."
else
    brew install --cask iterm2
fi

echo "iTerm2 installed."
