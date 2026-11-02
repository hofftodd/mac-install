#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"

# OrbStack, fast lightweight Docker containers and Linux machines for macOS. See https://orbstack.dev/
cask_install orbstack "OrbStack.app"

echo "OrbStack installed. Launch it from Applications to finish setup, then run: docker --version"
echo "Note: it provides its own docker CLI/socket; avoid running it alongside Docker Desktop or Rancher Desktop."
