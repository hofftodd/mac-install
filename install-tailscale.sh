#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"

# Tailscale (the macOS app, which bundles the daemon and menu-bar UI).
# See https://tailscale.com/download/mac
cask_install tailscale-app "Tailscale.app"

echo "Tailscale installed. Launch it from Applications and sign in."
