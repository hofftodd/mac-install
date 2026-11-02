#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"

# FreeRDP, open-source Remote Desktop Protocol client. XQuartz provides the X server needed for display.
cask_install xquartz "Utilities/XQuartz.app"
brew install freerdp

echo "FreeRDP installed."
