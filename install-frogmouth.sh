#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/zshrc.sh"

# Frogmouth, Markdown browser for the terminal (local files, URLs and GitHub
# READMEs). It's a Python app, not in Homebrew, so it's installed with
# `uv tool` into ~/.local/bin. See https://github.com/Textualize/frogmouth
if ! command -v uv >/dev/null 2>&1; then
    echo "uv not found — run install-uv.sh, then re-run this script." >&2
    exit 1
fi

# Frogmouth 0.9.x pins an old httpx/httpcore that crashes on start under
# Python 3.14+ ('typing.Union' object has no attribute '__module__'), so it
# gets its own Python instead of the default one. Override with
# FROGMOUTH_PYTHON=3.x once a newer frogmouth release fixes that.
FROGMOUTH_PYTHON="${FROGMOUTH_PYTHON:-3.13}"

# Re-running is a no-op if it's already installed on that Python (uv
# reinstalls it if it's on a different one); `uv tool upgrade --all`
# (update.sh) keeps it current.
uv tool install --python "$FROGMOUTH_PYTHON" frogmouth

install_zshrc_snippet 10-local-bin <<'SNIPPET'
export PATH="$HOME/.local/bin:$PATH"
SNIPPET

echo "frogmouth installed in $HOME/.local/bin. Try: frogmouth README.md"
