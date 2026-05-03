#!/usr/bin/env bash
set -euo pipefail

# Bootstrap a fresh macOS machine: install Xcode CLT + Homebrew, configure git
# identity, generate an SSH key (if needed), wait for you to add it to GitHub,
# then clone the mac-install repo. After this finishes you can run
# ./install-master.sh inside the cloned repo.
#
# This script is intentionally NOT part of install-master.sh — it's the
# chicken-and-egg "how do I even get the install scripts onto the machine"
# step. To run on a fresh box:
#
#   curl -fsSL https://raw.githubusercontent.com/hofftodd/mac-install/main/bootstrap.sh | bash
#
# Override defaults via env vars (otherwise you'll be prompted):
#   GIT_USER_NAME, GIT_USER_EMAIL, SSH_KEY, SSH_KEY_COMMENT, REPO_URL, CLONE_DIR

GIT_USER_NAME="${GIT_USER_NAME:-}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519}"
REPO_URL="${REPO_URL:-git@github.com:hofftodd/mac-install.git}"
CLONE_DIR="${CLONE_DIR:-$HOME/mac-install}"

echo "═══════════════════════════════════════════════════════════"
echo "  macOS workstation bootstrap"
echo "═══════════════════════════════════════════════════════════"

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

SSH_KEY_COMMENT="${SSH_KEY_COMMENT:-$GIT_USER_EMAIL}"

echo
echo "  Git user:  ${GIT_USER_NAME} <${GIT_USER_EMAIL}>"
echo "  SSH key:   ${SSH_KEY}"
echo "  Repo:      ${REPO_URL}"
echo "  Clone to:  ${CLONE_DIR}"
echo

# ---- 1. Install Xcode CLT + Homebrew ----------------------------------------
echo "[1/5] Installing Xcode Command Line Tools and Homebrew..."
if ! xcode-select -p >/dev/null 2>&1; then
    xcode-select --install || true
    echo "  Accept the Xcode CLT install dialog, then re-run this script when it finishes."
    # Wait for CLT to be installed before continuing.
    until xcode-select -p >/dev/null 2>&1; do sleep 5; done
fi

if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Put brew on PATH for this shell (Apple Silicon vs Intel).
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# git ships with the CLT, but make sure we have a recent one.
brew install git

# ---- 2. Configure git identity + sensible defaults --------------------------
echo
echo "[2/5] Configuring git..."
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global push.autoSetupRemote true
git config --global fetch.prune true
git config --global rebase.autoStash true
git config --global rerere.enabled true
git config --global merge.conflictStyle zdiff3

# ---- 3. Generate SSH key (if missing) ---------------------------------------
echo
echo "[3/5] SSH key..."
if [ -f "$SSH_KEY" ]; then
    echo "  Existing key found at $SSH_KEY — reusing."
else
    mkdir -p "$(dirname "$SSH_KEY")"
    chmod 700 "$(dirname "$SSH_KEY")"
    ssh-keygen -t ed25519 -C "$SSH_KEY_COMMENT" -f "$SSH_KEY" -N ""
fi

# Make sure ssh-agent is running and the key is loaded into the macOS keychain.
if [ -z "${SSH_AUTH_SOCK:-}" ] || ! ssh-add -l >/dev/null 2>&1; then
    eval "$(ssh-agent -s)" >/dev/null
fi
ssh-add --apple-use-keychain "$SSH_KEY" 2>/dev/null || ssh-add "$SSH_KEY" 2>/dev/null || true

# ---- 4. Pause for user to register the key with GitHub ----------------------
echo
echo "═══════════════════════════════════════════════════════════"
echo "  ADD THIS PUBLIC KEY TO GITHUB"
echo "═══════════════════════════════════════════════════════════"
cat "${SSH_KEY}.pub"
echo "═══════════════════════════════════════════════════════════"
echo
echo "  → Open: https://github.com/settings/ssh/new"
echo "  → Paste the line above and save."
echo

# Copy to clipboard for convenience (macOS pbcopy).
if command -v pbcopy >/dev/null 2>&1; then
    pbcopy < "${SSH_KEY}.pub"
    echo "  (Public key copied to clipboard.)"
    echo
fi

read -r -p "Press ENTER once you've added the key to GitHub..." < /dev/tty

echo
echo "[4/5] Verifying SSH access to GitHub..."
ssh-keyscan -t ed25519 github.com 2>/dev/null >> "$HOME/.ssh/known_hosts" 2>/dev/null || true
sort -u "$HOME/.ssh/known_hosts" -o "$HOME/.ssh/known_hosts" 2>/dev/null || true

if ssh -T -o BatchMode=yes -o StrictHostKeyChecking=accept-new git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "  ✓ GitHub SSH auth working."
else
    echo "  ✗ Could not authenticate to GitHub via SSH." >&2
    echo "    Confirm the key was added at https://github.com/settings/keys" >&2
    echo "    then re-run this script." >&2
    exit 1
fi

# ---- 5. Clone the repo ------------------------------------------------------
echo
echo "[5/5] Cloning ${REPO_URL} → ${CLONE_DIR}..."
if [ -d "$CLONE_DIR/.git" ]; then
    echo "  $CLONE_DIR already exists — pulling latest."
    git -C "$CLONE_DIR" pull --ff-only
else
    git clone "$REPO_URL" "$CLONE_DIR"
fi

echo
echo "═══════════════════════════════════════════════════════════"
echo "  Bootstrap complete."
echo "═══════════════════════════════════════════════════════════"
echo "  Next:  cd ${CLONE_DIR} && ./install-master.sh"
echo
