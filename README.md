# mac_install

A collection of small, idempotent install scripts for setting up a fresh macOS workstation. Each script handles one tool; `install-master.sh` runs them in a sensible order. Most scripts are thin wrappers around Homebrew (`brew install` / `brew install --cask`).

## Usage

### Bootstrap (fresh machine)

On a brand-new Mac, you don't have this repo yet. Run the bootstrap one-liner — it installs the Xcode Command Line Tools and Homebrew, prompts for your git name and email, generates an SSH key, prints it for you to paste into GitHub, then clones this repo.

```bash
curl -fsSL https://raw.githubusercontent.com/hofftodd/mac_install/main/bootstrap.sh | bash
```

To run non-interactively:

```bash
curl -fsSL https://raw.githubusercontent.com/hofftodd/mac_install/main/bootstrap.sh \
  | GIT_USER_NAME="Jane Doe" GIT_USER_EMAIL="jane@example.com" bash
```

Then:

```bash
cd ~/mac_install
./install-master.sh
```

`bootstrap.sh` is **not** part of `install-master.sh` — it's the chicken-and-egg step.

### After bootstrap

Run a single script:

```bash
./install-vscode.sh
```

Or run everything in order:

```bash
./install-master.sh
```

`install-master.sh` runs every script and **continues past failures**, capturing per-script logs in a temp directory and printing a punch list at the end.

Refresh the pinned version defaults (nvm, Python, Nerd Fonts) from upstream before installing:

```bash
./update-versions.sh
```

`install-master.sh` runs this automatically as its first step.

Most scripts that pin a version expose an env var override, e.g.:

```bash
PYTHON_VERSION=3.13.0 ./install-pyenv.sh
NODE_VERSION=22       ./install-nodejs.sh
BACKEND=cpu           ./install-llamacpp.sh   # default is metal
PG_FORMULA=postgresql@17 ./install-postgres.sh
```

## What's included

### Git / GitHub
- `install-git-config.sh` — Sets `user.name`/`user.email` (prompts if not configured), modern defaults, and aliases. Auto-wires `git-delta` as the pager if installed.
- `install-gh.sh` — GitHub CLI (`gh`).

### GUI apps
- `install-chrome.sh` — Google Chrome
- `install-1password.sh` — 1Password desktop client
- `install-vscode.sh` — Visual Studio Code
- `install-cursor.sh` — Cursor AI code editor
- `install-intellij.sh` — JetBrains IntelliJ IDEA
- `install-micro.sh` — micro, modern terminal text editor
- `install-claude-code.sh` — Claude Code CLI
- `install-opencode.sh` — opencode terminal coding agent
- `install-pi.sh` — pi (pi.dev) terminal coding agent (npm; depends on Node)
- `install-obsidian.sh` — Obsidian
- `install-docker-desktop.sh` — Docker Desktop
- `install-gmail.sh`, `install-google-calendar.sh`, `install-google-contacts.sh` — Google web-app launchers (Chrome `--app=` mode wrapped in a `.app` bundle in `~/Applications`)
- `install-vlc.sh` — VLC media player
- `install-handbrake.sh` — HandBrake (GUI + CLI)

### Comms
- `install-slack.sh`, `install-discord.sh`, `install-zoom.sh`, `install-signal.sh`

### Networking / sync
- `install-tailscale.sh` — Tailscale (menu-bar app)
- `install-syncthing.sh` — Syncthing (per-user `brew services` agent)

### Databases
- `install-postgres.sh` — PostgreSQL (`postgresql@16`) + `pgcli`. Starts as a brew service, creates a database matching your username.

### Languages & runtimes
- `install-python.sh` — Python 3 from Homebrew
- `install-pyenv.sh` — pyenv + a pinned Python build
- `install-uv.sh` — uv: fast Python package/project manager
- `install-sdkman.sh` — SDKMAN! plus Java (Temurin LTS), Groovy, and Gradle
- `install-go.sh` — Go from Homebrew
- `install-nodejs.sh` — Node.js via nvm (default LTS)

### Local LLMs
- `install-ollama.sh` — Ollama (cask, includes background launchd agent)
- `install-lmstudio.sh` — LM Studio
- `install-llamacpp.sh` — llama.cpp built from source. Default backend is **Metal** on Apple Silicon; override with `BACKEND=cpu`. Symlinks binaries into `~/.local/bin`.

### Terminal / shell
- `install-modern-cli.sh` — bundle: ripgrep, fd, bat, eza, fzf, zoxide, git-delta, jq, yq, tree, htop, ncdu. Adds zoxide init to `~/.zshrc`.
- `install-starship.sh` — Starship prompt with the Gruvbox Rainbow preset.
- `install-nerd-fonts.sh` — FiraCode, JetBrainsMono, Hack, Meslo, CaskaydiaCove (Nerd Fonts) via brew casks.
- `install-btop.sh` — btop process/resource monitor

## Notes

- Scripts assume macOS with Homebrew already installed (run `bootstrap.sh` if not).
- Most language scripts append shell-init blocks to `~/.zshrc` (pyenv, sdkman, nvm, go). Open a new shell or `source ~/.zshrc` after running.
- `brew install` is a no-op when a formula is already installed, so re-running scripts is safe.
