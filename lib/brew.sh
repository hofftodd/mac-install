# shellcheck shell=bash
# Shared Homebrew helpers for install scripts.
#
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"
#   cask_install google-chrome "Google Chrome.app"
#
# Bash 3.2 compatible (macOS /bin/bash).

# ensure_brew_on_path — make `brew` usable in this process even if the shell
# that started us doesn't have Homebrew on PATH yet.
ensure_brew_on_path() {
    command -v brew >/dev/null 2>&1 && return 0
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
}

# cask_install <cask> [<App name>.app | <path relative to /Applications>]
# Installs a Homebrew cask, unless it's already there:
#   - installed by Homebrew: nothing to do (`brew upgrade` keeps it current);
#   - the app already exists in /Applications or ~/Applications but wasn't
#     installed by Homebrew (e.g. downloaded from the vendor): skip instead of
#     failing, and say how to hand it over to Homebrew.
cask_install() {
    local cask="$1" app="${2:-}" dir
    if brew list --cask "$cask" >/dev/null 2>&1; then
        echo "$cask is already installed by Homebrew."
        return 0
    fi
    if [ -n "$app" ]; then
        for dir in /Applications "$HOME/Applications"; do
            if [ -e "$dir/$app" ]; then
                echo "$app is already installed at $dir/$app (not by Homebrew) — skipping."
                echo "  To let Homebrew manage and update it: brew install --cask --adopt $cask"
                echo "  (if that refuses because the versions differ: brew install --cask --force $cask)"
                return 0
            fi
        done
    fi
    brew install --cask "$cask"
}
