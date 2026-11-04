#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/chrome-app.sh"

# Gmail as a Chrome "app-mode" launcher in ~/Applications (see lib/chrome-app.sh).
install_chrome_app "Gmail" "https://mail.google.com/mail/u/0/" \
    "https://www.gstatic.com/images/branding/product/2x/gmail_2020q4_512dp.png"
