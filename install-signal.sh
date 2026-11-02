#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"

# Signal Desktop. See https://signal.org/download/macos/
cask_install signal "Signal.app"

echo "Signal Desktop installed."
