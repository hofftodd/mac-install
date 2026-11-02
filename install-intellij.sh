#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"

# JetBrains IntelliJ IDEA Ultimate.
cask_install intellij-idea "IntelliJ IDEA.app"
