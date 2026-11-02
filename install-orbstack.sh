#!/usr/bin/env bash
set -euo pipefail

# OrbStack, fast lightweight Docker containers and Linux machines for macOS. See https://orbstack.dev/
if [ -d "/Applications/OrbStack.app" ]; then
    echo "OrbStack already present at /Applications/OrbStack.app — skipping cask install."
else
    brew install --cask orbstack
fi

echo "OrbStack installed. Launch it from Applications to finish setup, then run: docker --version"
echo "Note: it provides its own docker CLI/socket; avoid running it alongside Docker Desktop or Rancher Desktop."
