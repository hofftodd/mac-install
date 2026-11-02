#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"

# Rancher Desktop, container management and local Kubernetes (dockerd or containerd). See https://rancherdesktop.io/
cask_install rancher "Rancher Desktop.app"

echo "Rancher Desktop installed. Launch it from Applications to pick a container engine and Kubernetes version."
echo "Note: it provides its own docker CLI/socket; avoid running it alongside Docker Desktop or OrbStack."
