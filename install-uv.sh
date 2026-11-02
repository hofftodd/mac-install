#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/zshrc.sh"

# uv: Python versions, virtual environments, packages and CLI tools in one
# tool. This is the only Python setup in mac-install (no pyenv, no Homebrew
# python). See https://docs.astral.sh/uv/
#
# PYTHON_VERSION picks the Python to install as the default `python`/`python3`
# (e.g. PYTHON_VERSION=3.13). Leave it unset for the latest stable release.
PYTHON_VERSION="${PYTHON_VERSION:-}"

brew install uv

# Install Python and put python, python3 and python3.X in ~/.local/bin.
# (--default adds the unversioned python/python3 links; uv documents it as
# experimental.) Re-running is a no-op if that version is already installed.
# shellcheck disable=SC2086  # PYTHON_VERSION is empty or a single version
uv python install --default $PYTHON_VERSION

install_zshrc_snippet 10-local-bin <<'SNIPPET'
export PATH="$HOME/.local/bin:$PATH"
SNIPPET

# Tab completion for uv and uvx (only if zsh completion is set up).
install_zshrc_snippet 30-uv <<'SNIPPET'
if (( $+functions[compdef] )); then
    eval "$(uv generate-shell-completion zsh)"
    eval "$(uvx --generate-shell-completion zsh)"
fi
SNIPPET

# Machines set up by older versions of mac-install may have pyenv's shell
# hook, which would put pyenv's python ahead of uv's. Turn it off; pyenv
# itself and its Pythons are left in place for you to remove.
PYENV_LINES="$(mktemp)"
cat > "$PYENV_LINES" <<'SNIPPET'
# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"
SNIPPET
remove_legacy_zshrc_lines "$PYENV_LINES"
rm -f "$PYENV_LINES"
if [ -f "$ZSHRC_D/20-pyenv.zsh" ]; then
    rm -f "$ZSHRC_D/20-pyenv.zsh"
    echo "Removed ~/.zshrc.d/20-pyenv.zsh (pyenv's shell hook)."
fi
if command -v pyenv >/dev/null 2>&1 || [ -d "$HOME/.pyenv" ]; then
    echo
    echo "pyenv is still installed but no longer hooked into your shell. To remove it:"
    echo "  brew uninstall pyenv && rm -rf ~/.pyenv"
fi

echo
echo "uv installed: $(uv --version)"
echo "Python: $("$HOME/.local/bin/python3" --version 2>/dev/null || echo 'see: uv python list --only-installed')"
echo "Restart your shell or run: source ~/.zshrc"
echo "Quick reference:"
echo "  uv init / uv add <pkg> / uv run   — projects with a lockfile and .venv"
echo "  uv venv && uv pip install <pkg>   — plain virtual environment"
echo "  uv tool install <pkg>             — CLI tools (ruff, httpie, ...) in ~/.local/bin"
echo "  uvx <pkg>                         — run a tool once without installing it"
echo "  uv python install 3.12            — add another Python version"
