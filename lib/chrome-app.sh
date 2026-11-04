# shellcheck shell=bash
# Shared helper for Google web apps installed through Chrome (Gmail, Google
# Calendar, ...).
#
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/chrome-app.sh"
#   install_chrome_app "Gmail" "https://mail.google.com/mail/u/0/"
#
# Uses Chrome's own "Install page as app", which creates a real app in
# ~/Applications/Chrome Apps.localized/ with its own icon and Dock tile, and
# shares your normal Chrome profile (no extra sign-in). Chrome has no
# supported CLI for that, so this opens the page and tells you what to click.
#
# (An earlier version built a .app that ran `Google Chrome --app=<url>`. When
# Chrome was already running, Chrome took over the window and the launcher
# exited, so the window landed under Chrome's Dock icon. Those launchers are
# removed here.)
#
# Bash 3.2 compatible (macOS /bin/bash).

CHROME_APP="${CHROME_APP:-/Applications/Google Chrome.app}"
CHROME_APPS_DIR="${CHROME_APPS_DIR:-$HOME/Applications/Chrome Apps.localized}"

# install_chrome_app <name> <url>
# <name> is the app name Chrome gives the installed app (from the site's
# manifest), used to tell whether it's already installed.
install_chrome_app() {
    local name="$1" url="$2" legacy id
    if [ -z "$name" ] || [ -z "$url" ]; then
        echo "install_chrome_app: usage: install_chrome_app <name> <url>" >&2
        return 1
    fi
    if [ ! -d "$CHROME_APP" ]; then
        echo "Google Chrome not found at $CHROME_APP. Install it first (./install-chrome.sh)." >&2
        return 1
    fi

    # Remove the old --app launcher this repo used to create, but only if it
    # is ours (our bundle id prefix), never an app of the same name.
    legacy="$HOME/Applications/$name.app"
    if [ -d "$legacy" ]; then
        id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$legacy/Contents/Info.plist" 2>/dev/null || true)"
        case "$id" in
            net.hoffmannet.*)
                rm -rf "${legacy:?}"
                echo "  Removed old launcher $legacy"
                ;;
        esac
    fi

    if [ -d "$CHROME_APPS_DIR/$name.app" ]; then
        echo "$name is already installed as a Chrome app ($CHROME_APPS_DIR/$name.app)."
        return 0
    fi

    if [ -n "${CI:-}" ]; then
        echo "$name: not installed (CI: skipping opening Chrome; install it from $url)."
        return 0
    fi
    open -a "$CHROME_APP" "$url"
    echo "Opened $name in Chrome. To install it as an app with its own Dock icon:"
    echo "  Chrome menu (⋮) → Cast, save, and share → Install page as app… → Install"
    echo "  (or click the install icon at the right end of the address bar)"
}
