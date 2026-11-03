#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/npm.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/versions.sh"

# little-coder, an AI coding agent CLI published on npm.
# See https://github.com/itayinbarr/little-coder
#
# Pinned to a specific release rather than piping the project's install.sh
# from its main branch: that script only checks the Node version and runs
# `npm install -g little-coder` (whatever is newest), so we do the same steps
# here with an exact version. update-versions.sh reports newer releases;
# bump the pin below (or set LITTLE_CODER_VERSION) after reviewing them.
LITTLE_CODER_VERSION="${LITTLE_CODER_VERSION:-1.20.0}"

require_node 22.19
npm_global_install little-coder "$LITTLE_CODER_VERSION"

echo "little-coder $LITTLE_CODER_VERSION installed (in Node $(node --version)'s global packages)."
echo "Then run: little-coder --list-models"
