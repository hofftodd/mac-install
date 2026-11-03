#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/npm.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/versions.sh"

# pi (https://pi.dev/), a minimal terminal-based coding agent, from npm.
#
# The package moved from @mariozechner/pi-coding-agent (deprecated, frozen at
# 0.73.1) to @earendil-works/pi-coding-agent. Pinned to a release like
# little-coder; update-versions.sh reports newer ones. Bump the pin below (or
# set PI_VERSION) after reviewing them.
PI_PACKAGE="@earendil-works/pi-coding-agent"
PI_OLD_PACKAGE="@mariozechner/pi-coding-agent"
PI_VERSION="${PI_VERSION:-1.5.0}"

require_node 22.19

# Both packages provide the `pi` command, so npm refuses the new one while the
# old one is installed.
if [ -n "$(npm_global_version "$PI_OLD_PACKAGE")" ]; then
    echo "Removing the deprecated $PI_OLD_PACKAGE (replaced by $PI_PACKAGE)..."
    npm uninstall -g "$PI_OLD_PACKAGE"
fi

npm_global_install "$PI_PACKAGE" "$PI_VERSION"

echo "pi $PI_VERSION installed: $(pi --version 2>/dev/null || echo 'run: pi --help')"
