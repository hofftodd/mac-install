#!/usr/bin/env bash
set -euo pipefail

# Syncthing macOS GUI app. See https://syncthing.net/
if [ -d "/Applications/Syncthing.app" ]; then
    echo "Syncthing already present at /Applications/Syncthing.app — skipping cask install."
else
    brew install --cask syncthing-app
fi

echo "Syncthing installed."
echo "Launch Syncthing.app to start the service; web UI: http://localhost:8384"
