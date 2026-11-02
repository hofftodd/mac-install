#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"

# UTM, virtual machines UI using QEMU. See https://mac.getutm.app/
cask_install utm "UTM.app"
