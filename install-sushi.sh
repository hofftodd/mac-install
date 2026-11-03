#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"

# Sushi: local AI server for very low-bit, high-quality quantized models
# (Qwen3.8 Flash Next, GLM 5.3 Flash, MiMo, DeepSeek V4.1 Flash) on Apple
# Silicon, with OpenAI- and Anthropic-compatible APIs on 127.0.0.1:12345.
# See https://github.com/beamivalice/sushi
#
# Installed from the project's Homebrew tap (a prebuilt, checksummed binary;
# `brew upgrade` keeps it current). Includes `sushibar`, a menu bar app.
# Models are separate, large downloads: this suggests one for this Mac's
# memory but doesn't download it.

# Sushi needs Apple Silicon and macOS 26.2 or later.
if [ "$(uname -m)" != arm64 ]; then
    echo "Sushi needs an Apple Silicon Mac (M1 or later); this one is $(uname -m)." >&2
    exit 1
fi
macos="$(sw_vers -productVersion)"
major="${macos%%.*}"
minor="$(printf '%s' "$macos" | cut -d. -f2)"
if [ "$major" -lt 26 ] || { [ "$major" -eq 26 ] && [ "${minor:-0}" -lt 2 ]; }; then
    echo "Sushi needs macOS 26.2 or later; this Mac has $macos." >&2
    echo "Update in System Settings → General → Software Update, then re-run this script." >&2
    exit 1
fi

ensure_brew_on_path
brew install beamivalice/tap/sushi

echo
echo "Sushi installed: $(sushi --version 2>/dev/null || brew list --versions sushi)"

# Suggest a model pack for this Mac's memory (sizes from Sushi's own table:
# https://github.com/beamivalice/sushi/blob/main/docs/usage.md).
mem_gb=$(( $(sysctl -n hw.memsize) / 1073741824 ))
echo "This Mac has ${mem_gb} GB of memory."
if [ "$mem_gb" -ge 128 ]; then
    suggest="glm-5.3-flash  (the 2.4bpw pack; or deepseek-v4.1-flash, mimo-v2.6-flash)"
elif [ "$mem_gb" -ge 96 ]; then
    suggest="deepseek-v4.1-flash  (or qwen3.8-flash-next:4bpw, glm-5.3-flash:2bpw)"
elif [ "$mem_gb" -ge 64 ]; then
    suggest="qwen3.8-flash-next:2.75bpw"
elif [ "$mem_gb" -ge 32 ]; then
    suggest="qwen3.8-flash-next:2bpw  (streamed from the SSD below 48 GB)"
else
    suggest=""
fi
if [ -n "$suggest" ]; then
    echo "  Suggested model: $suggest"
    echo "  Download it:     sushi pull <model>        (tens of GB)"
else
    echo "  Sushi's smallest model needs 32 GB (streamed); this Mac has less."
fi
echo "  See every model and whether this Mac fits it: sushi list"
echo "  Start the server: sushi serve <model>   (see the project's docs/usage.md)"
echo "  Menu bar app:     sushibar"
