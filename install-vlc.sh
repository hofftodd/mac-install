#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"

# VLC media player.
cask_install vlc "VLC.app"

echo "VLC installed."
