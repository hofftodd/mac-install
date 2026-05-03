# mac-install

A collection of small, idempotent install scripts for setting up a fresh macOS workstation. Each script handles one tool; `install-master.sh` runs them via an interactive category menu. Most scripts are thin wrappers around Homebrew (`brew install` / `brew install --cask`).

## Background

This project was vibe coded with [Claude Code](https://claude.com/claude-code) — two birds, one stone: I wanted a reproducible way to spin my development environment back up on a new machine, and I wanted to learn how to vibe code with Claude in the process.

## Usage

### Bootstrap (fresh machine)

On a brand-new Mac, you don't have this repo yet. Run the bootstrap one-liner — it installs the Xcode Command Line Tools and Homebrew, prompts for your git name and email, generates an SSH key, prints it for you to paste into GitHub, then clones this repo.

```bash
curl -fsSL https://raw.githubusercontent.com/hofftodd/mac-install/main/bootstrap.sh | bash
```

To run non-interactively:

```bash
curl -fsSL https://raw.githubusercontent.com/hofftodd/mac-install/main/bootstrap.sh \
  | GIT_USER_NAME="Jane Doe" GIT_USER_EMAIL="jane@example.com" bash
```

Then:

```bash
cd ~/mac-install
./install-master.sh
```

`bootstrap.sh` is **not** part of `install-master.sh` — it's the chicken-and-egg step.

### After bootstrap

Run a single script:

```bash
./install-vscode.sh
```

Or run the menu:

```bash
./install-master.sh
```

`install-master.sh` is a pure-bash TUI with a collapsible category tree, arrow-key navigation, and checkboxes. It runs the selected scripts and **continues past failures**, capturing per-script logs in a temp directory and printing a punch list at the end. Press `r` inside the menu to view this README without leaving it.

Refresh the pinned version defaults (nvm, Python, Nerd Fonts) from upstream before installing:

```bash
./update-versions.sh
```

`install-master.sh` runs this automatically as its first step.

Most scripts that pin a version expose an env var override, e.g.:

```bash
PYTHON_VERSION=3.13.0       ./install-pyenv.sh
NODE_VERSION=22             ./install-nodejs.sh
JAVA_VERSION=21.0.5-tem     ./install-sdkman.sh
BACKEND=cpu                 ./install-llamacpp.sh   # default is metal
PG_FORMULA=postgresql@17    ./install-postgres.sh
```

## What's included

These categories match the menu layout in `install-master.sh`.

### Setup
- `update-versions.sh` — refresh pinned tool versions (nvm, Python, Nerd Fonts) from upstream APIs and rewrite the defaults in the relevant install scripts.

### Git / GitHub
- `install-git-config.sh` — global git config: `user.name`/`user.email` (prompts if not set), modern defaults, aliases. Auto-wires `git-delta` as the pager if installed.
- `install-gh.sh` — GitHub CLI (`gh`).

### Languages
- `install-sdkman.sh` — SDKMAN! plus Java (latest Eclipse Temurin), Groovy, and Gradle. Self-updates SDKMAN when re-run.
- `install-python.sh` — Python 3 from Homebrew.
- `install-pyenv.sh` — pyenv plus a pinned Python build.
- `install-uv.sh` — uv: fast Python package/project manager.
- `install-go.sh` — Go from Homebrew.
- `install-nodejs.sh` — Node.js via nvm (default LTS).

### Local LLMs
- `install-ollama.sh` — Ollama (cask, includes background launchd agent).
- `install-lmstudio.sh` — LM Studio.
- `install-llamacpp.sh` — llama.cpp built from source. Default backend is **Metal** on Apple Silicon; override with `BACKEND=cpu`. Symlinks binaries into `~/.local/bin`.

### Editors / dev apps
- `install-vscode.sh` — Visual Studio Code.
- `install-cursor.sh` — Cursor AI code editor.
- `install-intellij.sh` — JetBrains IntelliJ IDEA.
- `install-micro.sh` — micro, modern terminal text editor.
- `install-fresh.sh` — Fresh terminal text editor (`fresh-editor` formula).
- `install-claude-code.sh` — Claude Code CLI (Anthropic).
- `install-opencode.sh` — opencode, open-source terminal coding agent.
- `install-little-coder.sh` — little-coder, npm-based AI coding agent CLI.
- `install-pi.sh` — pi (pi.dev), terminal coding agent (npm; depends on Node).
- `install-oh-my-pi.sh` — Oh My Pi, AI coding agent for the terminal (hash-anchored edits, LSP, Python, browser, subagents); binary `omp` from [can1357/oh-my-pi](https://github.com/can1357/oh-my-pi).
- `install-docker-desktop.sh` — Docker Desktop.

### Productivity
- `install-obsidian.sh` — Obsidian.
- `install-chrome.sh` — Google Chrome.
- `install-1password.sh` — 1Password desktop client.
- `install-gmail.sh` — Gmail web-app launcher (Chrome `--app=` mode wrapped in a `.app` bundle in `~/Applications`).
- `install-google-calendar.sh` — Google Calendar web-app launcher (same wrapper as Gmail).
- `install-google-contacts.sh` — Google Contacts web-app launcher (same wrapper as Gmail).

### Comms
- `install-slack.sh` — Slack desktop client.
- `install-discord.sh` — Discord desktop client.
- `install-zoom.sh` — Zoom desktop client.
- `install-signal.sh` — Signal desktop client.

### Networking
- `install-tailscale.sh` — Tailscale menu-bar app.

### Databases
- `install-postgres.sh` — PostgreSQL (`postgresql@16` by default) plus `pgcli`. Starts as a brew service and creates a database matching your username.

### Sync / utilities
- `install-syncthing.sh` — Syncthing (per-user `brew services` agent).
- `install-vlc.sh` — VLC media player.
- `install-handbrake.sh` — HandBrake (GUI + CLI).
- `install-utm.sh` — UTM, virtual-machines UI built on QEMU.

### Terminal experience
- `install-modern-cli.sh` — bundle of modern CLI tools: ripgrep, fd, bat, eza, fzf, zoxide, git-delta, jq, yq, tree, htop, ncdu. Adds zoxide init to `~/.zshrc`.
- `install-nerd-fonts.sh` — FiraCode, JetBrainsMono, Hack, Meslo, CaskaydiaCove (Nerd Fonts) via brew casks.
- `install-starship.sh` — Starship prompt with the Gruvbox Rainbow preset.
- `install-btop.sh` — btop process/resource monitor.

## Notes

- Scripts assume macOS with Homebrew already installed (run `bootstrap.sh` if not).
- Most language scripts append shell-init blocks to `~/.zshrc` (pyenv, sdkman, nvm, go). Open a new shell or `source ~/.zshrc` after running.
- `brew install` is a no-op when a formula is already installed, so re-running scripts is safe. Cask installs that detect an existing app in `/Applications` (LM Studio, Obsidian, UTM) skip cleanly instead of failing.
