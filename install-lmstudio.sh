#!/usr/bin/env bash
set -euo pipefail

# LM Studio. See https://lmstudio.ai/
if [ -d "/Applications/LM Studio.app" ]; then
    echo "LM Studio already present at /Applications/LM Studio.app — skipping cask install."
else
    brew install --cask lm-studio
fi

echo "LM Studio installed. Launch from Applications."
