#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"

# HandBrake (GUI + CLI) video transcoder. See https://handbrake.fr/
cask_install handbrake-app "HandBrake.app"
brew install handbrake

echo "HandBrake installed."
