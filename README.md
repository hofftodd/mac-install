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

Every script starts ticked except Docker Desktop, Rancher Desktop and OrbStack: each ships its own `docker` CLI and they conflict, so tick the one you want (the list lives in `DEFAULT_OFF` at the top of `install-master.sh`).

Refresh the pinned version defaults (nvm, Nerd Fonts) from upstream before installing:

```bash
./update-versions.sh
```

`install-master.sh` runs this automatically as its first step.

Most scripts that pin a version expose an env var override, e.g.:

```bash
PYTHON_VERSION=3.13         ./install-uv.sh
NODE_VERSION=22             ./install-nodejs.sh
JAVA_VERSION=21.0.5-tem     ./install-sdkman.sh
BACKEND=cpu                 ./install-llamacpp.sh   # default is metal
PG_FORMULA=postgresql@17    ./install-postgres.sh
```

## What's included

These categories match the menu layout in `install-master.sh`.

### Setup
- `update-versions.sh` — refresh pinned tool versions (nvm, Nerd Fonts) from upstream APIs and rewrite the defaults in the relevant install scripts.

### Git / GitHub
- `install-git-config.sh` — global git config: `user.name`/`user.email` (prompts if not set), modern defaults, aliases. Auto-wires `git-delta` as the pager if installed.
- `install-gh.sh` — GitHub CLI (`gh`).

### Languages
- `install-sdkman.sh` — SDKMAN! plus Java (latest Eclipse Temurin), Groovy, and Gradle. Self-updates SDKMAN when re-run.
- `install-uv.sh` — Python via [uv](https://docs.astral.sh/uv/), the only Python setup here: installs uv, the latest Python (or `PYTHON_VERSION`) as `python`/`python3` in `~/.local/bin`, and uv/uvx tab completion. Use `uv` for projects and virtualenvs, `uv tool install` for Python CLI tools, and `uv python install 3.x` for more versions. On machines set up with the old `install-pyenv.sh`, it turns off pyenv's shell hook and prints how to remove pyenv. Homebrew's own `python` may still be installed as a dependency of other formulae; that's fine, since `~/.local/bin` comes first on PATH.
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
- `install-croft.sh` — croft, VSCode-style terminal text editor (from the `vitali87/croft` Homebrew tap).
- `install-claude-code.sh` — Claude Code CLI (Anthropic).
- `install-opencode.sh` — opencode, open-source terminal coding agent.
- `install-little-coder.sh` — little-coder, npm-based AI coding agent CLI.
- `install-pi.sh` — pi (pi.dev), terminal coding agent (npm; depends on Node).
- `install-oh-my-pi.sh` — Oh My Pi, AI coding agent for the terminal (hash-anchored edits, LSP, Python, browser, subagents); binary `omp` from [can1357/oh-my-pi](https://github.com/can1357/oh-my-pi).

### VMs and virtualization
- `install-docker-desktop.sh` — Docker Desktop.
- `install-rancher-desktop.sh` — Rancher Desktop, containers plus local Kubernetes (`rancher` cask).
- `install-orbstack.sh` — OrbStack, lightweight Docker and Linux VMs for macOS.
- `install-lima.sh` — Lima, Linux VMs on macOS (containerd/nerdctl included). Doesn't create a VM; run `limactl start` afterward.
- `install-utm.sh` — UTM, virtual-machines UI built on QEMU.

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
- `install-freerdp.sh` — FreeRDP, open-source Remote Desktop Protocol client (plus XQuartz for display).

### Databases
- `install-postgres.sh` — PostgreSQL (`postgresql@16` by default) plus `pgcli`. Starts as a brew service and creates a database matching your username.

### Sync / utilities
- `install-syncthing.sh` — Syncthing (per-user `brew services` agent).
- `install-vlc.sh` — VLC media player.
- `install-handbrake.sh` — HandBrake (GUI + CLI).

### Terminal experience
- `install-modern-cli.sh` — bundle of modern CLI tools: ripgrep, fd, bat, eza, fzf, zoxide, git-delta, jq, yq, tree, htop, ncdu. Adds zoxide init and eza aliases (`ls`, `ll`, `la`, `lt`) in `~/.zshrc.d/80-modern-cli.zsh`.
- `install-nerd-fonts.sh` — FiraCode, JetBrainsMono, Hack, Meslo, CaskaydiaCove (Nerd Fonts) via brew casks.
- `install-starship.sh` — Starship prompt with the Gruvbox Rainbow preset.
- `install-btop.sh` — btop process/resource monitor.
- `install-ghostty.sh` — Ghostty, fast GPU-accelerated native terminal emulator.
- `install-iterm2.sh` — iTerm2, feature-rich terminal emulator for macOS.

### macOS settings
These change macOS settings rather than installing software. In `install-master.sh` each group is a collapsed category (`macOS: Dock`, `macOS: Finder`, …) and **each setting is its own checkbox**, labelled with the value it sets. They all start unticked: tick the ones you want and they're applied without further prompts. Settings that already have that value are left alone.

The scripts also work on their own:
- `./macos-dock.sh` — asks about each setting in turn, showing the current and new value (default is no).
- `./macos-dock.sh tilesize no-recents` — applies just those settings, without asking.
- `./macos-dock.sh --list` — lists the setting ids and labels.

Before a setting is changed for the first time, its original value is saved to `~/.mac-install/restore-macos-defaults.sh`; run that to undo everything. The shared helper is `lib/macos-defaults.sh`.

- `macos-keyboard.sh` — fast key repeat and short repeat delay, key repeat instead of the accent picker, and smart quotes, smart dashes, auto-capitalisation, auto-correct and double-space period turned off. Key repeat needs a logout.
- `macos-finder.sh` — show file extensions, hidden files, path bar and status bar; list view; folders first; search the current folder; no extension-change warning; no `.DS_Store` files on network or USB drives. Restarts Finder.
- `macos-dock.sh` — auto-hide with no delay, 48 px icons, no recent apps, Spaces in a fixed order. Restarts the Dock.
- `macos-screenshots.sh` — save to `~/Screenshots` (override with `SCREENSHOT_DIR`), PNG, no window shadow.
- `macos-trackpad.sh` — tap to click; three-finger drag (moves the three-finger swipes to four fingers). Needs a logout.
- `macos-security.sh` — Touch ID for `sudo` via `/etc/pam.d/sudo_local` (survives macOS updates), and require the password immediately after sleep or screen saver (via `sysadminctl`). Both ask for your password.
- `macos-misc.sh` — expanded Save and Print dialogs; Time Machine stops offering new disks; Photos doesn't open when a phone or camera is connected.

## Notes

- Scripts assume macOS with Homebrew already installed (run `bootstrap.sh` if not).
- Scripts that need shell setup (nvm, uv, SDKMAN, Go, Starship, modern-cli, and the agents that install into `~/.local/bin`) each write their own file to `~/.zshrc.d/`, e.g. `~/.zshrc.d/20-nvm.zsh`. The first one adds a small loader to `~/.zshrc` that sources every `~/.zshrc.d/*.zsh` in name order, so the number prefix sets load order. Re-running a script overwrites its file; deleting the file removes that tool's shell setup. Open a new shell or `source ~/.zshrc` after running.
- Older versions of these scripts appended directly to `~/.zshrc`. Re-running a script moves its old lines out (exact matches only), backing up the original to `~/.zshrc.mac-install.bak` first. The helper lives in `lib/zshrc.sh`.
- `brew install` is a no-op when a formula is already installed, so re-running scripts is safe. Cask installs that detect an existing app in `/Applications` (LM Studio, Obsidian, UTM, Ghostty, iTerm2, Rancher Desktop, OrbStack) skip cleanly instead of failing.
