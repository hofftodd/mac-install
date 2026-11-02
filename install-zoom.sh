#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"

# Zoom. See https://zoom.us/download
cask_install zoom "zoom.us.app"

echo "Zoom installed."
