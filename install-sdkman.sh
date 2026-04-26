#!/usr/bin/env bash
set -euo pipefail

# Install SDKMAN! and use it to install OpenJDK, Groovy, and Gradle.
# See https://sdkman.io/

# zip/unzip ship with macOS; curl too. Nothing extra to install.

if [ -d "$HOME/.sdkman" ]; then
    echo "SDKMAN! already installed at $HOME/.sdkman — skipping installer."
else
    curl -s "https://get.sdkman.io?rcupdate=false" | bash
fi

if ! grep -q 'sdkman-init.sh' "$HOME/.zshrc" 2>/dev/null; then
    cat >> "$HOME/.zshrc" <<'EOF'

# SDKMAN!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
EOF
fi

export SDKMAN_DIR="$HOME/.sdkman"
set +u
# shellcheck disable=SC1091
source "$SDKMAN_DIR/bin/sdkman-init.sh"
set -u

export SDKMAN_AUTO_ANSWER=true

for candidate in java groovy gradle; do
    if sdk current "$candidate" >/dev/null 2>&1; then
        echo "$candidate already installed: $(sdk current "$candidate")"
    else
        sdk install "$candidate"
    fi
done

echo
echo "Active versions:"
sdk current
echo
echo "Restart your shell or run: source ~/.zshrc"
