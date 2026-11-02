# mac-install

A collection of small, idempotent install scripts for setting up a fresh macOS workstation. Each script handles one tool; `install-master.sh` runs them via an interactive category menu. Most scripts are thin wrappers around Homebrew (`brew install` / `brew install --cask`).

## Background

This project was vibe coded with [Claude Code](https://claude.com/claude-code) — two birds, one stone: I wanted a reproducible way to spin my development environment back up on a new machine, and I wanted to learn how to vibe code with Claude in the process.

## Usage

### Bootstrap (fresh machine)

On a brand-new Mac, you don't have this repo yet. Run the bootstrap one-liner — it installs the Xcode Command Line Tools and Homebrew (and adds Homebrew to your PATH in `~/.zprofile`), prompts for your git name and email, generates an SSH key, prints it for you to paste into GitHub, then clones this repo.

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

Every install script starts ticked except Docker Desktop, Rancher Desktop and OrbStack: each ships its own `docker` CLI and they conflict, so tick the one you want (the list lives in `DEFAULT_OFF` at the top of `install-master.sh`). The macOS settings also start unticked (see [macOS settings](#macos-settings)).

Look up the latest versions of the few tools that are pinned (nvm and the PostgreSQL major version):

```bash
./update-versions.sh
```

It saves them to `~/.mac-install/versions.env`, which the install scripts read; the repo itself isn't modified. It's optional (scripts fall back to built-in defaults) and `install-master.sh` runs it first by default. Everything else installs the latest version anyway.

Most scripts that pin a version expose an env var override, e.g.:

```bash
PYTHON_VERSION=3.13         ./install-uv.sh
NODE_VERSION=22             ./install-nodejs.sh
NVM_VERSION=v0.40.8         ./install-nodejs.sh
JAVA_VERSION=21.0.5-tem     ./install-sdkman.sh
BACKEND=cpu                 ./install-llamacpp.sh   # default is metal
PG_FORMULA=postgresql@17    ./install-postgres.sh
LITTLE_CODER_VERSION=1.20.0 ./install-little-coder.sh
OMP_VERSION=v18.16.0        ./install-oh-my-pi.sh
```

## What's included

These categories match the menu layout in `install-master.sh`.

### Setup
- `update-versions.sh` — look up the latest nvm release and PostgreSQL major version and save them to `~/.mac-install/versions.env` for the install scripts (via `lib/versions.sh`). Also reports when little-coder or Oh My Pi has a newer release than the one pinned in its script, without changing the pin. Never edits the repo.

### Git / GitHub
- `install-git-config.sh` — global git config: `user.name`/`user.email` (prompts if not set), modern defaults, aliases. Installs and sets up `micro` as the editor and `git-delta` as the pager.
- `install-gh.sh` — GitHub CLI (`gh`).

### Languages
- `install-sdkman.sh` — SDKMAN! plus Java (latest Eclipse Temurin), Groovy, and Gradle. Self-updates SDKMAN when re-run. SDKMAN needs Bash 4+, so this also installs Homebrew's `bash` (macOS only ships 3.2); your shell stays zsh.
- `install-uv.sh` — Python via [uv](https://docs.astral.sh/uv/), the only Python setup here: installs uv, the latest Python (or `PYTHON_VERSION`) as `python`/`python3` in `~/.local/bin`, and uv/uvx tab completion. Use `uv` for projects and virtualenvs, `uv tool install` for Python CLI tools, and `uv python install 3.x` for more versions. On machines set up with the old `install-pyenv.sh`, it turns off pyenv's shell hook and prints how to remove pyenv. Homebrew's own `python` may still be installed as a dependency of other formulae; that's fine, since `~/.local/bin` comes first on PATH.
- `install-go.sh` — Go from Homebrew.
- `install-rust.sh` — Rust via [rustup](https://rustup.rs/): stable toolchain (or `RUST_TOOLCHAIN`) with cargo, rustfmt, clippy and rust-analyzer. rustup manages toolchains per project — a `rust-toolchain.toml` in a repo pins its version and rustup installs it on first use. Re-running updates all toolchains. Shell setup in `~/.zshrc.d/20-rust.zsh`. If `rustup` is already installed another way (e.g. Homebrew), it uses that instead of installing a second copy.
- `install-nodejs.sh` — Node.js via nvm (default LTS).
- `install-bun.sh` — [Bun](https://bun.com/), fast JavaScript/TypeScript runtime, package manager, bundler and test runner (Homebrew; update with `brew upgrade bun`). Adds `~/.bun/bin` (global `bun add -g` commands) to PATH via `~/.zshrc.d/20-bun.zsh`. Independent of Node/nvm.

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
- `install-little-coder.sh` — little-coder, npm-based AI coding agent CLI (needs Node 22.19+). Pinned to a release (`LITTLE_CODER_VERSION`, installed with `npm install -g little-coder@<version>`) rather than piping the project's install script from its main branch.
- `install-pi.sh` — pi (pi.dev), terminal coding agent (npm; depends on Node).
- `install-oh-my-pi.sh` — Oh My Pi, AI coding agent for the terminal (hash-anchored edits, LSP, Python, browser, subagents); binary `omp` from [can1357/oh-my-pi](https://github.com/can1357/oh-my-pi). Pinned to a release (`OMP_VERSION`): the installer is fetched from that release tag and installs its prebuilt binary after checking its sha256.

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
- `install-gmail.sh` — Gmail web-app launcher (Chrome `--app=` mode wrapped in a `.app` bundle in `~/Applications`; shared helper in `lib/chrome-app.sh`, so adding another site is a two-line script).
- `install-google-calendar.sh` — Google Calendar web-app launcher (same helper as Gmail).
- `install-google-contacts.sh` — Google Contacts web-app launcher (same helper as Gmail).

### Comms
- `install-slack.sh` — Slack desktop client.
- `install-discord.sh` — Discord desktop client.
- `install-zoom.sh` — Zoom desktop client.
- `install-signal.sh` — Signal desktop client.

### Networking
- `install-tailscale.sh` — Tailscale menu-bar app.
- `install-freerdp.sh` — FreeRDP, open-source Remote Desktop Protocol client (plus XQuartz for display).
- `install-nas-tools.sh` — Samba's `smbclient` for listing and testing SMB shares. macOS already has SMB and NFS clients built in (`smbutil`, `mount_smbfs`, `showmount`, `mount_nfs`); the script prints the common commands.

### Databases
- `install-postgres.sh` — PostgreSQL plus `pgcli`, running as a brew service, with a database matching your username and `psql` & co. on PATH (`~/.zshrc.d/20-postgres.zsh`). Installs the newest major (`postgresql@18`, or what `update-versions.sh` found). If an older `postgresql@N` is already installed it keeps using that and prints the upgrade steps, since each major has its own data and they share port 5432. Force a version with `PG_FORMULA`.

### Sync / utilities
- `install-syncthing.sh` — Syncthing macOS app (start it from Applications; web UI at http://localhost:8384).
- `install-unison.sh` — Unison, two-way file synchronizer (keeps two folders in sync across machines, e.g. over SSH).
- `install-vlc.sh` — VLC media player.
- `install-handbrake.sh` — HandBrake (GUI + CLI).

### Terminal experience
- `install-modern-cli.sh` — bundle of modern CLI tools: ripgrep, fd, bat, eza, fzf, zoxide, git-delta, jq, yq, tree, htop, ncdu. Adds zoxide init and eza aliases (`ls`, `ll`, `la`, `lt`) in `~/.zshrc.d/80-modern-cli.zsh`.
- `install-nerd-fonts.sh` — FiraCode, JetBrainsMono, Hack, Meslo, CaskaydiaCove (Nerd Fonts) via brew casks.
- `install-starship.sh` — Starship prompt. Applies the Gruvbox Rainbow preset only if you don't already have `~/.config/starship.toml`.
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
- `macos-server.sh` — run the Mac as an always-on server: never sleep and keep disks awake on power (on laptops only while plugged in; battery behaviour is unchanged), restart automatically after a power failure or freeze, wake for network access, Remote Login (SSH), Screen Sharing (VNC), and don't auto-install macOS updates (which restart the machine; security responses still install). Needs your password. Tick the whole group with `A` in the menu. Also prints the manual steps that can't be scripted safely: automatic login (so apps like Ollama, Syncthing and Tailscale start after a reboot) and a stable local hostname.

## Testing

GitHub Actions (`.github/workflows/test.yml`) runs on every push, on pull requests, and weekly (to catch upstream changes such as renamed casks):

- **shellcheck + consistency** (Linux): shellcheck on every script, and `tests/check-menu.sh`, which checks that every menu item points at an executable script and every script is in the menu and this README.
- **macOS settings** (real Mac runner): `tests/macos-settings.sh` applies a sample of settings from each group for real, checks them with `defaults`/`pmset`, re-runs them (must report "already set"), checks that asking with no terminal and unknown ids change nothing, then runs the generated restore script and checks every original value came back.
- **macOS installs** (real Mac runner): `tests/installs.sh` runs a representative set of install scripts twice (the second run checks they're safe to re-run), then opens a zsh and checks the tools are on PATH, `python3` is uv's, `psql` connects, tab completion is on, PATH has no duplicates, and the checkout is still clean.

The scripts run under `/bin/bash` 3.2, as on a new Mac. The two macOS tests change system settings and install software, so they refuse to run anywhere but a CI runner. `tests/check-menu.sh` is safe to run locally. `./install-master.sh --list` prints every menu item without opening the menu.

## Notes

- Scripts assume macOS with Homebrew already installed (run `bootstrap.sh` if not). `install-master.sh` puts Homebrew on PATH for the scripts it runs even if your current shell doesn't have it, and works from any folder (e.g. `~/mac-install/install-master.sh`).
- Scripts that need shell setup (nvm, Bun, uv, rustup, SDKMAN, Go, Starship, modern-cli, and the agents that install into `~/.local/bin`) each write their own file to `~/.zshrc.d/`, e.g. `~/.zshrc.d/20-nvm.zsh`. The first one adds a small loader to `~/.zshrc` that sources every `~/.zshrc.d/*.zsh` in name order, so the number prefix sets load order. Re-running a script overwrites its file; deleting the file removes that tool's shell setup. `~/.zshrc.d/00-base.zsh` loads first: it turns on zsh tab completion (including Homebrew's completions for `gh`, `bun`, `rustup`, …), which macOS's default zsh leaves off, and keeps PATH free of duplicates. Open a new shell or `source ~/.zshrc` after running.
- Older versions of these scripts appended directly to `~/.zshrc`. Re-running a script moves its old lines out (exact matches only), backing up the original to `~/.zshrc.mac-install.bak` first. The helper lives in `lib/zshrc.sh`.
- `brew install` is a no-op when a formula is already installed, so re-running scripts is safe. Apps (casks) go through `cask_install` in `lib/brew.sh`: if the app is already in `/Applications` but wasn't installed by Homebrew (e.g. downloaded from the vendor), the script skips it instead of failing and prints how to hand it over to Homebrew (`brew install --cask --adopt <cask>`).
