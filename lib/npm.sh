# shellcheck shell=bash
# Shared helpers for scripts that install global npm packages at a pinned
# version (install-pi.sh, install-little-coder.sh).
#
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/npm.sh"
#   require_node 22.19
#   npm_global_install some-package "$SOME_PACKAGE_VERSION"
#
# Bash 3.2 compatible (macOS /bin/bash).

# require_node <major.minor> — load nvm (install-nodejs.sh) so node/npm are
# on PATH in this non-interactive shell, then check the Node version.
require_node() {
    local min="$1"
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    # shellcheck disable=SC1091
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
        echo "Node.js/npm not found. Run install-nodejs.sh first (needs Node $min+)." >&2
        return 1
    fi
    if ! MIN="$min" node -e '
        const [a, b] = process.versions.node.split(".").map(Number);
        const [x, y] = process.env.MIN.split(".").map(Number);
        process.exit(a > x || (a === x && b >= y) ? 0 : 1)'; then
        echo "Node $(node --version) is too old: needs $min+. Try: nvm install --lts" >&2
        return 1
    fi
}

# npm_global_version <package> — the globally installed version, or empty.
npm_global_version() {
    npm ls -g --depth=0 --json 2>/dev/null | PKG="$1" node -e '
        let s = "";
        process.stdin.on("data", d => s += d).on("end", () => {
            try { process.stdout.write(((JSON.parse(s).dependencies || {})[process.env.PKG] || {}).version || ""); }
            catch (e) {}
        })' || true
}

# npm_global_install <package> <version> — install exactly that version
# globally, unless it's already installed.
npm_global_install() {
    local pkg="$1" version="$2"
    if [ "$(npm_global_version "$pkg")" = "$version" ]; then
        echo "$pkg $version is already installed."
    else
        npm install -g "$pkg@$version"
    fi
}
