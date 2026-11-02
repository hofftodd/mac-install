#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"

# Discord. See https://discord.com/
cask_install discord "Discord.app"
