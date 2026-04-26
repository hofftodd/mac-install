#!/usr/bin/env bash
set -euo pipefail

# HandBrake (GUI + CLI) video transcoder. See https://handbrake.fr/
brew install --cask handbrake-app
brew install handbrake

echo "HandBrake installed."
