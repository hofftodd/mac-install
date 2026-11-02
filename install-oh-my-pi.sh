#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/zshrc.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/versions.sh"

# Oh My Pi, an AI coding agent for the terminal — hash-anchored edits, LSP,
# Python, browser, subagents, etc. (an extension of pi). Binary: ~/.local/bin/omp.
# See https://github.com/can1357/oh-my-pi
#
# Pinned to a specific release rather than piping the installer from the
# project's main branch: the installer is fetched from the release tag and
# asked for that release's prebuilt binary, which it checks against the build
# service's sha256 before installing. update-versions.sh reports newer
# releases; bump the pin below (or set OMP_VERSION) after reviewing them.
OMP_VERSION="${OMP_VERSION:-v18.16.0}"
case "$OMP_VERSION" in v*) ;; *) OMP_VERSION="v$OMP_VERSION" ;; esac

OMP_BIN="$HOME/.local/bin/omp"
if [ -x "$OMP_BIN" ] && "$OMP_BIN" --version 2>/dev/null | grep -qF "${OMP_VERSION#v}"; then
    echo "Oh My Pi ${OMP_VERSION} is already installed at $OMP_BIN."
else
    curl -fsSL "https://raw.githubusercontent.com/can1357/oh-my-pi/${OMP_VERSION}/scripts/install.sh" \
        | sh -s -- --binary --ref "$OMP_VERSION"
fi

install_zshrc_snippet 10-local-bin <<'SNIPPET'
export PATH="$HOME/.local/bin:$PATH"
SNIPPET

echo "Oh My Pi ${OMP_VERSION} installed. Restart your shell or run: source ~/.zshrc"
echo "Then run: omp"
