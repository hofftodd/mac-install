#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/zshrc.sh"

# Install SDKMAN! and use it to install OpenJDK, Groovy, and Gradle.
# See https://sdkman.io/

# zip/unzip ship with macOS; curl too. Nothing extra to install.

SDKMAN_PREEXISTING=0
if [ -d "$HOME/.sdkman" ]; then
    echo "SDKMAN! already installed at $HOME/.sdkman — skipping installer."
    SDKMAN_PREEXISTING=1
else
    curl -s "https://get.sdkman.io?rcupdate=false" | bash
fi

install_zshrc_snippet 20-sdkman <<'EOF'
# SDKMAN!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
EOF

export SDKMAN_DIR="$HOME/.sdkman"
# SDKMAN's shell function and its `sdk` subcommands aren't `set -u` safe;
# leave -u off for the remainder of the script.
set +u
# shellcheck disable=SC1091
source "$SDKMAN_DIR/bin/sdkman-init.sh"

export SDKMAN_AUTO_ANSWER=true

# If SDKMAN was already on disk, refresh it and its candidate metadata so we
# don't pin Java/Groovy/Gradle to stale versions.
if [ "$SDKMAN_PREEXISTING" = "1" ]; then
    echo "Updating SDKMAN! and candidate metadata..."
    sdk selfupdate force || true
    sdk update || true
fi

# Pin Java to an Eclipse Temurin build. Default is the newest Temurin SDKMAN
# currently lists; override with JAVA_VERSION (e.g. JAVA_VERSION=21.0.5-tem).
if [ -z "${JAVA_VERSION:-}" ]; then
    JAVA_VERSION="$(sdk list java 2>/dev/null \
        | awk '{ for (i=1;i<=NF;i++) if ($i ~ /-tem$/) { print $i; exit } }')"
fi
: "${JAVA_VERSION:?Could not resolve a Temurin Java identifier from 'sdk list java'}"

# `sdk current <candidate>` exits 0 even when nothing is installed, so check
# for the candidate's `current` link instead.
sdk_has() { [ -e "$SDKMAN_DIR/candidates/$1/current" ]; }

if sdk_has java; then
    echo "java already installed: $(readlink "$SDKMAN_DIR/candidates/java/current" | xargs basename)"
else
    sdk install java "$JAVA_VERSION"
fi

for candidate in groovy gradle; do
    if sdk_has "$candidate"; then
        echo "$candidate already installed: $(readlink "$SDKMAN_DIR/candidates/$candidate/current" | xargs basename)"
    else
        sdk install "$candidate"
    fi
done

echo
echo "Active versions:"
sdk current
echo
echo "Restart your shell or run: source ~/.zshrc"
