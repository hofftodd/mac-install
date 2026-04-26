#!/usr/bin/env bash
set -euo pipefail

# Docker Desktop for macOS.
# See https://docs.docker.com/desktop/install/mac-install/
brew install --cask docker-desktop

echo "Docker Desktop installed. Launch it from Applications, then run: docker --version"
