#!/usr/bin/env bash
set -euo pipefail

# Configure global git settings: user identity + sensible defaults.
# Override via env vars: GIT_USER_NAME, GIT_USER_EMAIL — otherwise we use
# whatever is already in `git config --global`, or prompt if nothing is set.
GIT_USER_NAME="${GIT_USER_NAME:-$(git config --global --get user.name 2>/dev/null || true)}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-$(git config --global --get user.email 2>/dev/null || true)}"

if [ -z "$GIT_USER_NAME" ]; then
    read -r -p "Git user name (e.g. 'Jane Doe'): " GIT_USER_NAME < /dev/tty
fi
if [ -z "$GIT_USER_EMAIL" ]; then
    read -r -p "Git user email (e.g. 'jane@example.com'): " GIT_USER_EMAIL < /dev/tty
fi
if [ -z "$GIT_USER_NAME" ] || [ -z "$GIT_USER_EMAIL" ]; then
    echo "Name and email are required." >&2
    exit 1
fi

git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"

git config --global core.editor "micro"

git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global push.autoSetupRemote true
git config --global push.default simple
git config --global fetch.prune true
git config --global rebase.autoStash true
git config --global rerere.enabled true
git config --global diff.colorMoved zebra
git config --global merge.conflictStyle zdiff3

# Use git-delta as the pager if it's installed (from install-modern-cli.sh).
if command -v delta >/dev/null 2>&1; then
    git config --global core.pager 'delta'
    git config --global interactive.diffFilter 'delta --color-only'
    git config --global delta.navigate true
    git config --global delta.line-numbers true
    git config --global merge.conflictstyle zdiff3
fi

git config --global alias.st 'status -sb'
git config --global alias.co 'checkout'
git config --global alias.br 'branch'
git config --global alias.lg "log --graph --pretty=format:'%C(yellow)%h%Creset %C(cyan)%an%Creset %s %C(green)(%cr)%Creset%C(auto)%d%Creset' --abbrev-commit"
git config --global alias.last 'log -1 HEAD'
git config --global alias.unstage 'reset HEAD --'

echo "Git configured for: ${GIT_USER_NAME} <${GIT_USER_EMAIL}>"
echo "Review with: git config --global --list"
