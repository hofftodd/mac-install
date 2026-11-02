# shellcheck shell=bash
# Shared helper for Chrome "app-mode" launchers (Gmail, Google Calendar, ...).
#
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/chrome-app.sh"
#   install_chrome_app "Gmail" "https://mail.google.com/mail/u/0/"
#
# Wraps Chrome's --app flag in a small .app bundle in ~/Applications, so the
# site opens in its own window and shows up in Spotlight, Launchpad and the
# Dock like a regular app. Re-running replaces the bundle.
#
# Bash 3.2 compatible (macOS /bin/bash).

CHROME_APP="${CHROME_APP:-/Applications/Google Chrome.app}"

# install_chrome_app <name> <url>
# The bundle is ~/Applications/<name>.app; its executable and bundle id use
# the name without spaces (e.g. "Google Calendar" → GoogleCalendar).
install_chrome_app() {
    local name="$1" url="$2" exe app_path
    if [ -z "$name" ] || [ -z "$url" ]; then
        echo "install_chrome_app: usage: install_chrome_app <name> <url>" >&2
        return 1
    fi
    if [ ! -d "$CHROME_APP" ]; then
        echo "Google Chrome not found at $CHROME_APP. Install it first (./install-chrome.sh)." >&2
        return 1
    fi

    exe="$(printf '%s' "$name" | tr -d ' ')"
    app_path="$HOME/Applications/$name.app"

    mkdir -p "$HOME/Applications"
    rm -rf "${app_path:?}"
    mkdir -p "$app_path/Contents/MacOS"

    cat > "$app_path/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>${exe}</string>
    <key>CFBundleIdentifier</key><string>net.hoffmannet.${exe}</string>
    <key>CFBundleName</key><string>${name}</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
</dict>
</plist>
PLIST

    cat > "$app_path/Contents/MacOS/$exe" <<LAUNCHER
#!/usr/bin/env bash
exec "${CHROME_APP}/Contents/MacOS/Google Chrome" --app="${url}"
LAUNCHER
    chmod +x "$app_path/Contents/MacOS/$exe"

    echo "$name launcher installed at $app_path"
}
