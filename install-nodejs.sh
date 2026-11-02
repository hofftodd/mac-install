#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/zshrc.sh"

# Install Node.js via nvm (Node Version Manager).
# See https://github.com/nvm-sh/nvm
NVM_VERSION="${NVM_VERSION:-v0.40.4}"
NODE_VERSION="${NODE_VERSION:---lts}"   # e.g. "22", "20.18.0", or "--lts"

export PROFILE=/dev/null
curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
unset PROFILE

install_zshrc_snippet 20-nvm <<'EOF'
# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF

export NVM_DIR="$HOME/.nvm"
\. "$NVM_DIR/nvm.sh"

nvm install "$NODE_VERSION"
# `nvm alias default` doesn't accept `--lts`; translate it to `lts/*`.
if [ "$NODE_VERSION" = "--lts" ]; then
    nvm alias default 'lts/*'
else
    nvm alias default "$NODE_VERSION"
fi
nvm use default

echo "Node installed: $(node --version)"
echo "npm: $(npm --version)"
echo "Restart your shell or run: source ~/.zshrc"
