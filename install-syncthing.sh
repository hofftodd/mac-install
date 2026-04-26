#!/usr/bin/env bash
set -euo pipefail

# Syncthing. See https://docs.syncthing.net/users/autostart.html#launchd-macos
brew install syncthing

# Run as a per-user brew service so it starts at login.
brew services start syncthing

echo "Syncthing installed and enabled as a per-user service."
echo "Web UI (after first start): http://localhost:8384"
