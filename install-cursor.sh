#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"

# Cursor, the AI code editor. See https://cursor.com/
cask_install cursor "Cursor.app"
