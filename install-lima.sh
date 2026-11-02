#!/usr/bin/env bash
set -euo pipefail

# Lima, Linux virtual machines on macOS (with containerd/nerdctl). See https://lima-vm.io/
brew install lima

echo "Lima installed: $(limactl --version)"
echo "Create and start the default VM with: limactl start"
echo "Then open a shell in it with: lima"
