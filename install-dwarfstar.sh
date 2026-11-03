#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/zshrc.sh"

# DwarfStar (ds4): local inference engine by antirez for DeepSeek V4 Flash,
# GLM 5.3 Flash and Qwen3.8 Flash Next, built for Metal on Apple Silicon.
# See https://github.com/antirez/ds4
#
# There are no releases or Homebrew package, so this builds it from source
# (like install-llamacpp.sh): clone or update ~/src/ds4, then `make`. Only the
# Xcode Command Line Tools are needed (bootstrap.sh installs them).
# Re-running updates and rebuilds it.
#
# The tools load their Metal shaders and default model from the source
# folder, so ~/.local/bin gets small wrappers that run them from there:
#   ds4, ds4-server, ds4-bench, ds4-eval   run from ~/src/ds4
#   ds4-agent      loads from ~/src/ds4, works in the folder you start it in
#   ds4-download   ~/src/ds4/download_model.sh (models are large downloads)
DS4_DIR="${DS4_DIR:-$HOME/src/ds4}"

if [ "$(uname -m)" != arm64 ]; then
    echo "DwarfStar's Mac build needs Apple Silicon (Metal); this Mac is $(uname -m)." >&2
    exit 1
fi

mkdir -p "$(dirname "$DS4_DIR")"
if [ -d "$DS4_DIR/.git" ]; then
    echo "Updating existing checkout at $DS4_DIR..."
    git -C "$DS4_DIR" pull --ff-only
else
    git clone https://github.com/antirez/ds4.git "$DS4_DIR"
fi
make -C "$DS4_DIR" -j"$(sysctl -n hw.ncpu)"

BIN="$HOME/.local/bin"
mkdir -p "$BIN"
for tool in ds4 ds4-server ds4-bench ds4-eval; do
    cat > "$BIN/$tool" <<EOF
#!/bin/sh
# Installed by mac-install (install-dwarfstar.sh). Runs $tool from its source
# folder, where it finds its Metal shaders and default model.
cd "$DS4_DIR" && exec ./$tool "\$@"
EOF
    chmod +x "$BIN/$tool"
done
cat > "$BIN/ds4-agent" <<EOF
#!/bin/sh
# Installed by mac-install (install-dwarfstar.sh). Loads the model and shaders
# from the source folder, then works in the folder you started it in.
project="\$PWD"
cd "$DS4_DIR" && exec ./ds4-agent --chdir "\$project" "\$@"
EOF
cat > "$BIN/ds4-download" <<EOF
#!/bin/sh
# Installed by mac-install (install-dwarfstar.sh).
cd "$DS4_DIR" && exec ./download_model.sh "\$@"
EOF
chmod +x "$BIN/ds4-agent" "$BIN/ds4-download"

install_zshrc_snippet 10-local-bin <<'SNIPPET'
export PATH="$HOME/.local/bin:$PATH"
SNIPPET

echo
echo "DwarfStar built at $DS4_DIR ($(git -C "$DS4_DIR" log -1 --format='%h, %cs'))."
echo "Commands in ~/.local/bin: ds4, ds4-agent, ds4-server, ds4-bench, ds4-eval, ds4-download"

# Suggest a model for this Mac's memory (from the project's docs/METAL.md).
mem_gb=$(( $(sysctl -n hw.memsize) / 1073741824 ))
echo "This Mac has ${mem_gb} GB of memory."
if [ "$mem_gb" -ge 256 ]; then
    echo "  Suggested model: DeepSeek V4 Flash Q4 → ds4-download ds4f-q4"
elif [ "$mem_gb" -ge 96 ]; then
    echo "  Suggested model: DeepSeek V4 Flash Q2 → ds4-download ds4f-q2"
elif [ "$mem_gb" -ge 64 ]; then
    echo "  Suggested model: Qwen3.8 Flash Next Q2 (~42 GiB) → ds4-download qwen38-q2"
    echo "  (DeepSeek V4 Flash Q2 also runs here with --ssd-streaming, more slowly.)"
else
    echo "  DwarfStar's models need 64 GB or more, or SSD streaming (slow); see docs/METAL.md."
fi
echo "  Then: ds4 -p \"Hello\"   ·   ds4-server (http://127.0.0.1:8000)   ·   ds4-agent"
echo "Restart your shell or run: source ~/.zshrc"
