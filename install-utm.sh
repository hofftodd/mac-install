#!/usr/bin/env bash
set -euo pipefail

# UTM, virtual machines UI using QEMU. See https://mac.getutm.app/
if [ -d "/Applications/UTM.app" ]; then
    echo "UTM already present at /Applications/UTM.app — skipping cask install."
else
    brew install --cask utm
fi
