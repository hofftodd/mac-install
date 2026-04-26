#!/usr/bin/env bash
set -euo pipefail

# uv, the fast Python package & project manager. See https://docs.astral.sh/uv/
brew install uv

echo "uv installed: $(uv --version)"
