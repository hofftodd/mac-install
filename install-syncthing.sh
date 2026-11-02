#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"

# Syncthing macOS GUI app. See https://syncthing.net/
cask_install syncthing-app "Syncthing.app"

echo "Syncthing installed."
echo "Launch Syncthing.app to start the service; web UI: http://localhost:8384"
