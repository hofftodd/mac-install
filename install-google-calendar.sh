#!/usr/bin/env bash
set -euo pipefail

# Install Google Calendar as a Chrome "app-mode" launcher.

CHROME_APP="/Applications/Google Chrome.app"
if [ ! -d "$CHROME_APP" ]; then
    echo "Google Chrome not found at $CHROME_APP. Install it first (./install-chrome.sh)." >&2
    exit 1
fi

NAME="Google Calendar"
URL="https://calendar.google.com/"
APP_DIR="$HOME/Applications"
APP_PATH="$APP_DIR/${NAME}.app"

mkdir -p "$APP_DIR"
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"

cat > "$APP_PATH/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>GoogleCalendar</string>
    <key>CFBundleIdentifier</key><string>net.hoffmannet.GoogleCalendar</string>
    <key>CFBundleName</key><string>${NAME}</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
</dict>
</plist>
EOF

cat > "$APP_PATH/Contents/MacOS/GoogleCalendar" <<EOF
#!/usr/bin/env bash
exec "${CHROME_APP}/Contents/MacOS/Google Chrome" --app="${URL}"
EOF
chmod +x "$APP_PATH/Contents/MacOS/GoogleCalendar"

echo "Google Calendar launcher installed at $APP_PATH"
