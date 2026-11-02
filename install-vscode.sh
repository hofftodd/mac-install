#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"

# Visual Studio Code.
cask_install visual-studio-code "Visual Studio Code.app"
