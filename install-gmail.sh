#!/usr/bin/env bash
set -euo pipefail

# Install Gmail as a Chrome "app-mode" launcher.
# On macOS we wrap Chrome's --app flag in a small .app bundle so it shows up
# in Spotlight / Launchpad with its own dock icon.

CHROME_APP="/Applications/Google Chrome.app"
if [ ! -d "$CHROME_APP" ]; then
    echo "Google Chrome not found at $CHROME_APP. Install it first (./install-chrome.sh)." >&2
    exit 1
fi

NAME="Gmail"
URL="https://mail.google.com/mail/u/0/"
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
    <key>CFBundleExecutable</key><string>${NAME}</string>
    <key>CFBundleIdentifier</key><string>net.hoffmannet.${NAME}</string>
    <key>CFBundleName</key><string>${NAME}</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
</dict>
</plist>
EOF

cat > "$APP_PATH/Contents/MacOS/${NAME}" <<EOF
#!/usr/bin/env bash
exec "${CHROME_APP}/Contents/MacOS/Google Chrome" --app="${URL}"
EOF
chmod +x "$APP_PATH/Contents/MacOS/${NAME}"

echo "Gmail launcher installed at $APP_PATH"
