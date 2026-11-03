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

# Everything runs inside main(), called on the last line. When this script is
# piped in (curl ... | bash), bash reads it from the pipe as it goes; a command
# that reads its input (brew, ssh, ...) would swallow the rest of the script,
# which then shows up as stray text or silently never runs. Inside a function,
# bash has read the whole file before the first command runs.
main() {
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
        echo "  Accept the Xcode Command Line Tools dialog; this continues once they finish installing."
        # Wait for CLT to be installed before continuing.
        until xcode-select -p >/dev/null 2>&1; do sleep 5; done
    fi

    if ! command -v brew >/dev/null 2>&1; then
        # Homebrew's installer needs sudo, which only Administrator accounts have.
        # Without it, it aborts with "Insufficient permissions to install Homebrew".
        if ! id -Gn | tr ' ' '\n' | grep -qx admin; then
            echo "  This account ($(id -un)) isn't an Administrator, so it can't install Homebrew." >&2
            echo "  Either log in as an admin and run this there, or make this account an admin:" >&2
            echo "  System Settings → Users & Groups → (this user) → Allow user to administer this computer." >&2
            echo "  Then open a new terminal and re-run the bootstrap one-liner." >&2
            exit 1
        fi
        # This script is usually piped in (curl ... | bash), so its stdin is the
        # download, not the terminal. Homebrew's installer then runs
        # non-interactively, can't ask for your password, and aborts with
        # "Insufficient permissions". Give it the terminal so it can ask.
        echo "  Installing Homebrew — it will ask for your login password (for sudo)."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" < /dev/tty
    fi

    # Put brew on PATH for this shell (Apple Silicon vs Intel), and for every
    # new login shell via ~/.zprofile — the Homebrew installer only prints this
    # step, and without it /opt/homebrew/bin isn't on PATH in new terminals.
    BREW_BIN=""
    if [ -x /opt/homebrew/bin/brew ]; then
        BREW_BIN=/opt/homebrew/bin/brew
    elif [ -x /usr/local/bin/brew ]; then
        BREW_BIN=/usr/local/bin/brew
    fi
    if [ -z "$BREW_BIN" ]; then
        echo "Homebrew install didn't finish (no brew found). Re-run this script." >&2
        exit 1
    fi
    eval "$("$BREW_BIN" shellenv)"
    if ! grep -qs 'brew shellenv' "$HOME/.zprofile"; then
        {
            echo
            echo "# Homebrew (added by mac-install bootstrap.sh)"
            echo "eval \"\$($BREW_BIN shellenv)\""
        } >> "$HOME/.zprofile"
        echo "  Added Homebrew to PATH in ~/.zprofile"
    fi

    # git ships with the CLT, but make sure we have a recent one. glow is used by
    # install-master.sh to render this repo's README from inside the TUI menu.
    brew install git glow </dev/null

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
        ssh-keygen -t ed25519 -C "$SSH_KEY_COMMENT" -f "$SSH_KEY" -N "" </dev/null
    fi

    # Make sure ssh-agent is running and the key is loaded into the macOS keychain.
    if [ -z "${SSH_AUTH_SOCK:-}" ] || ! ssh-add -l >/dev/null 2>&1; then
        eval "$(ssh-agent -s)" >/dev/null
    fi
    ssh-add --apple-use-keychain "$SSH_KEY" </dev/null 2>/dev/null || ssh-add "$SSH_KEY" </dev/null 2>/dev/null || true

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
    ssh-keyscan -t ed25519 github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null </dev/null || true
    sort -u "$HOME/.ssh/known_hosts" -o "$HOME/.ssh/known_hosts" 2>/dev/null || true

    # ssh reads its input, so give it none (see main() above).
    local ssh_out
    while :; do
        # ssh -T exits 1 even on success (GitHub gives no shell), so go by its
        # message. ConnectTimeout: a blocked port 22 fails fast, not after minutes.
        ssh_out="$(ssh -T -o BatchMode=yes -o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new \
            git@github.com </dev/null 2>&1 || true)"
        case "$ssh_out" in *"successfully authenticated"*) break ;; esac
        echo "  ✗ GitHub doesn't accept this key yet. ssh said:" >&2
        printf '%s\n' "$ssh_out" | sed 's/^/      /' >&2
        case "$ssh_out" in
            *"IDENTIFICATION HAS CHANGED"*)
                echo "    → This Mac has an old saved host key for github.com. Remove it with:" >&2
                echo "        ssh-keygen -R github.com" >&2 ;;
            *"timed out"*|*"Connection refused"*|*"Could not resolve"*|*"Network is unreachable"*)
                echo "    → Couldn't reach github.com on SSH's port 22. Check the internet connection;" >&2
                echo "      some work and guest networks block port 22." >&2 ;;
            *"Permission denied"*)
                echo "    → GitHub doesn't have this key. Add it at https://github.com/settings/ssh/new" >&2
                echo "      (it's on your clipboard; key type: Authentication Key). This Mac's key is:" >&2
                echo "        $(ssh-keygen -lf "${SSH_KEY}.pub" 2>/dev/null)" >&2
                echo "      and should match one listed at https://github.com/settings/keys" >&2 ;;
            *)
                echo "    → Add the key shown above at https://github.com/settings/ssh/new" >&2
                echo "      (it's on your clipboard; key type: Authentication Key)." >&2 ;;
        esac
        read -r -p "  Press ENTER to try again, or Ctrl-C to stop..." < /dev/tty
    done
    echo "  ✓ GitHub SSH auth working."

    # ---- 5. Clone the repo ------------------------------------------------------
    echo
    echo "[5/5] Cloning ${REPO_URL} → ${CLONE_DIR}..."
    if [ -d "$CLONE_DIR/.git" ]; then
        echo "  $CLONE_DIR already exists — pulling latest."
        git -C "$CLONE_DIR" pull --ff-only </dev/null
    else
        git clone "$REPO_URL" "$CLONE_DIR" </dev/null
    fi

    echo
    echo "═══════════════════════════════════════════════════════════"
    echo "  Bootstrap complete."
    echo "═══════════════════════════════════════════════════════════"
    echo "  Next:  cd ${CLONE_DIR} && ./install-master.sh"
    echo
}

main "$@"
