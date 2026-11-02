#!/usr/bin/env bash
set -euo pipefail

# Rancher Desktop, container management and local Kubernetes (dockerd or containerd). See https://rancherdesktop.io/
if [ -d "/Applications/Rancher Desktop.app" ]; then
    echo "Rancher Desktop already present at /Applications/Rancher Desktop.app — skipping cask install."
else
    brew install --cask rancher
fi

echo "Rancher Desktop installed. Launch it from Applications to pick a container engine and Kubernetes version."
echo "Note: it provides its own docker CLI/socket; avoid running it alongside Docker Desktop or OrbStack."
