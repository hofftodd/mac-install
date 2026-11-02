#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"

# Slack. See https://slack.com/downloads/mac
cask_install slack "Slack.app"

echo "Slack installed."
