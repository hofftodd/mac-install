#!/usr/bin/env bash
set -euo pipefail

# FreeRDP, open-source Remote Desktop Protocol client. XQuartz provides the X server needed for display.
brew install --cask xquartz
brew install freerdp

echo "FreeRDP installed."
