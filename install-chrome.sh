#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"

# Browse the web with the most popular browser. See https://www.google.com/chrome/
cask_install google-chrome "Google Chrome.app"
