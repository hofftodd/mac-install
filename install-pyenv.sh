#!/usr/bin/env bash
set -euo pipefail

# Install pyenv and a recent Python via pyenv. See https://github.com/pyenv/pyenv
PYTHON_VERSION="${PYTHON_VERSION:-3.14.4}"

# Build dependencies for compiling Python on macOS. See:
# https://github.com/pyenv/pyenv/wiki#suggested-build-environment
brew install pyenv openssl readline sqlite3 xz zlib tcl-tk

if ! grep -q 'PYENV_ROOT' "$HOME/.zshrc" 2>/dev/null; then
    cat >> "$HOME/.zshrc" <<'EOF'

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"
EOF
fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$(brew --prefix pyenv)/bin:$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"

if ! pyenv versions --bare | grep -qx "$PYTHON_VERSION"; then
    echo "Installing Python $PYTHON_VERSION via pyenv (this can take a few minutes)..."
    pyenv install "$PYTHON_VERSION"
fi

pyenv global "$PYTHON_VERSION"

echo "pyenv installed. Restart your shell or run: source ~/.zshrc"
echo "Active Python: $(pyenv version)"
