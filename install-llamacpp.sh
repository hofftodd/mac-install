#!/usr/bin/env bash
set -euo pipefail

# Build llama.cpp from source. See https://github.com/ggml-org/llama.cpp
# On Apple Silicon the default build uses Metal automatically; on Intel Macs
# it falls back to a CPU build. Override with BACKEND=cpu to force CPU-only.
BACKEND="${BACKEND:-metal}"
SRC_DIR="${LLAMACPP_DIR:-$HOME/src/llama.cpp}"

# Build prerequisites — git ships with Xcode CLT; the rest come from brew.
brew install cmake curl

mkdir -p "$(dirname "$SRC_DIR")"
if [ -d "$SRC_DIR/.git" ]; then
    echo "Updating existing checkout at $SRC_DIR..."
    git -C "$SRC_DIR" pull --ff-only
else
    git clone https://github.com/ggml-org/llama.cpp "$SRC_DIR"
fi

CMAKE_FLAGS=()
case "$BACKEND" in
    metal)  : ;;  # cmake auto-enables Metal on Darwin
    cpu)    CMAKE_FLAGS+=(-DGGML_METAL=OFF) ;;
    *)
        echo "Unknown BACKEND: $BACKEND" >&2
        exit 1
        ;;
esac

cmake -S "$SRC_DIR" -B "$SRC_DIR/build" "${CMAKE_FLAGS[@]}"
cmake --build "$SRC_DIR/build" --config Release -j"$(sysctl -n hw.ncpu)"

mkdir -p "$HOME/.local/bin"
for bin in llama-cli llama-server llama-quantize llama-bench; do
    if [ -f "$SRC_DIR/build/bin/$bin" ]; then
        ln -sf "$SRC_DIR/build/bin/$bin" "$HOME/.local/bin/$bin"
    fi
done

echo "llama.cpp built ($BACKEND) at $SRC_DIR/build"
echo "Binaries symlinked into ~/.local/bin (llama-cli, llama-server, ...)"
echo "Try: llama-cli --help"
