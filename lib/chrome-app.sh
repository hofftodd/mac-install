# shellcheck shell=bash
# Shared helper for Chrome "app-mode" launchers (Gmail, Google Calendar, ...).
#
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/chrome-app.sh"
#   install_chrome_app "Gmail" "https://mail.google.com/mail/u/0/" "<icon png url>"
#
# Wraps Chrome's --app flag in a small .app bundle in ~/Applications, so the
# site opens in its own window and shows up in Spotlight, Launchpad and the
# Dock like a regular app. Re-running replaces the bundle.
#
# Bash 3.2 compatible (macOS /bin/bash).

CHROME_APP="${CHROME_APP:-/Applications/Google Chrome.app}"

# _chrome_app_icns <png url> <out .icns>
# Downloads a square PNG (ideally 1024x1024) and converts it to an .icns with
# sips + iconutil. Returns non-zero (and leaves no output) on any failure.
_chrome_app_icns() {
    local url="$1" out="$2" tmp src size
    tmp="$(mktemp -d)" || return 1
    src="$tmp/src.png"
    if ! curl -fsSL "$url" -o "$src" </dev/null \
        || ! sips -g pixelWidth "$src" >/dev/null 2>&1; then
        rm -rf "$tmp"
        return 1
    fi
    mkdir "$tmp/AppIcon.iconset"
    for size in 16 32 128 256 512; do
        sips -z "$size" "$size" "$src" --out "$tmp/AppIcon.iconset/icon_${size}x${size}.png" >/dev/null 2>&1 || { rm -rf "$tmp"; return 1; }
        sips -z $((size * 2)) $((size * 2)) "$src" --out "$tmp/AppIcon.iconset/icon_${size}x${size}@2x.png" >/dev/null 2>&1 || { rm -rf "$tmp"; return 1; }
    done
    iconutil -c icns "$tmp/AppIcon.iconset" -o "$out" || { rm -rf "$tmp"; return 1; }
    rm -rf "$tmp"
}

# install_chrome_app <name> <url> [icon_png_url]
# The bundle is ~/Applications/<name>.app; its executable and bundle id use
# the name without spaces (e.g. "Google Calendar" → GoogleCalendar). Without
# an icon (or if it can't be fetched) macOS shows the generic app icon.
install_chrome_app() {
    local name="$1" url="$2" icon_url="${3:-}" exe app_path icon_key=""
    if [ -z "$name" ] || [ -z "$url" ]; then
        echo "install_chrome_app: usage: install_chrome_app <name> <url> [icon_png_url]" >&2
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
    mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"

    if [ -n "$icon_url" ]; then
        if _chrome_app_icns "$icon_url" "$app_path/Contents/Resources/AppIcon.icns"; then
            icon_key="<key>CFBundleIconFile</key><string>AppIcon</string>"
        else
            echo "  Warning: couldn't fetch the icon for $name; it will use the generic app icon." >&2
        fi
    fi

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
    ${icon_key}
</dict>
</plist>
PLIST

    cat > "$app_path/Contents/MacOS/$exe" <<LAUNCHER
#!/usr/bin/env bash
exec "${CHROME_APP}/Contents/MacOS/Google Chrome" --app="${url}"
LAUNCHER
    chmod +x "$app_path/Contents/MacOS/$exe"

    # Re-register so Finder, the Dock and Launchpad pick up the new icon
    # instead of a cached generic one.
    touch "$app_path"
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$app_path" >/dev/null 2>&1 || true

    echo "$name launcher installed at $app_path"
}
