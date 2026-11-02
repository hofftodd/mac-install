#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"

# LM Studio. See https://lmstudio.ai/
cask_install lm-studio "LM Studio.app"

echo "LM Studio installed. Launch from Applications."
