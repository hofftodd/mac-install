#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/zshrc.sh"

# Rust via rustup, the official toolchain manager. See https://rustup.rs/
# rustup installs and updates toolchains (stable, beta, nightly, or exact
# versions) and switches between them per project: a rust-toolchain.toml in
# a repo pins its toolchain, and rustup installs it on first use.
#
# RUST_TOOLCHAIN picks the default toolchain (default: stable).
RUST_TOOLCHAIN="${RUST_TOOLCHAIN:-stable}"

CARGO_BIN="$HOME/.cargo/bin"
OTHER_RUSTUP="$(command -v rustup 2>/dev/null || true)"

if [ -x "$CARGO_BIN/rustup" ]; then
    RUSTUP="$CARGO_BIN/rustup"
    echo "rustup already installed — updating toolchains..."
    "$RUSTUP" self update || true   # no-op if rustup came from a package manager
    "$RUSTUP" update
elif [ -n "$OTHER_RUSTUP" ]; then
    # rustup installed another way (e.g. Homebrew's rustup formula). Use it
    # rather than installing a second, competing copy.
    RUSTUP="$OTHER_RUSTUP"
    echo "Using the rustup already installed at $RUSTUP — updating toolchains..."
    "$RUSTUP" update
else
    # --no-modify-path: shell setup goes in ~/.zshrc.d instead (below).
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
        | sh -s -- -y --no-modify-path --default-toolchain "$RUST_TOOLCHAIN" --profile default
    RUSTUP="$CARGO_BIN/rustup"
fi

export PATH="$CARGO_BIN:$PATH"
"$RUSTUP" default "$RUST_TOOLCHAIN"
# The default profile includes rustc, cargo, rustfmt and clippy; add the
# language server that editors (VS Code, Zed, Helix, croft...) use.
"$RUSTUP" component add rust-analyzer

install_zshrc_snippet 20-rust <<'SNIPPET'
# Puts ~/.cargo/bin (cargo, rustc, rustup, and anything from `cargo install`) on PATH.
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
SNIPPET

echo
echo "Rust installed: $(rustc --version)"
echo "cargo: $(cargo --version)"
echo "Restart your shell or run: source ~/.zshrc"
echo "Quick reference:"
echo "  rustup update                       — update all installed toolchains"
echo "  rustup toolchain install nightly    — add another toolchain"
echo "  rustup override set nightly         — use it in the current directory"
echo "  rust-toolchain.toml                 — pin a toolchain for a project (committed with the code)"
echo "  cargo install <crate>               — CLI tools into ~/.cargo/bin"
