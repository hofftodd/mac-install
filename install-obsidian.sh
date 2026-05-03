#!/usr/bin/env bash
set -euo pipefail

# Obsidian.
if [ -d "/Applications/Obsidian.app" ]; then
    echo "Obsidian already present at /Applications/Obsidian.app — skipping cask install."
else
    brew install --cask obsidian
fi
