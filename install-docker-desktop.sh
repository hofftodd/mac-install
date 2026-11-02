#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"

# Docker Desktop for macOS.
# See https://docs.docker.com/desktop/install/mac-install/
cask_install docker-desktop "Docker.app"

echo "Docker Desktop installed. Launch it from Applications, then run: docker --version"
