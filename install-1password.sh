#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"

# 1Password desktop client.
cask_install 1password "1Password.app"
