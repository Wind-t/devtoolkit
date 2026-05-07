# 🧰 DevToolkit — WSL Dev Environment in One Command

> One command. Coffee still hot. Environment ready.
> Idempotent. Modern. China-friendly.

[![Platform](https://img.shields.io/badge/platform-WSL2%20%7C%20Ubuntu%2024.04+-blue)](https://learn.microsoft.com/en-us/windows/wsl/)
[![Shell](https://img.shields.io/badge/shell-zsh%20%2B%20starship-purple)](https://starship.rs)
[![Python](https://img.shields.io/badge/python-uv%20%2B%20ruff-yellow)](https://docs.astral.sh/uv/)
[![Version](https://img.shields.io/badge/multi--lang-mise-orange)](https://mise.jdx.dev)
[![AI](https://img.shields.io/badge/AI-OpenCode-green)](https://opencode.ai)

English | [中文](README.md)

---

## What's This?

An idempotent WSL Ubuntu development environment bootstrap script. 8 phases, run it 10 times — no errors, no duplicates. Symlinks dotfiles to `$HOME`, restart your terminal, and you're ready to code.

**Design philosophy:**

- **Fast** — Rust-native tools first (uv, mise, starship, ripgrep, fd, zoxide, eza)
- **Lean** — no oh-my-zsh bloat, on-demand plugin loading
- **Stable** — idempotent, network fallback, trap cleanup on interruption
- **China-friendly** — Aliyun apt mirror, Tsinghua PyPI mirror (skip with `SKIP_APT_MIRROR=1`)

## What's Installed

| Category | Tools | Purpose |
|----------|-------|---------|
| Shell | zsh + starship | Prompt with custom dark theme |
| Plugins | zsh-autosuggestions | Fish-style auto-completion |
| | zsh-syntax-highlighting | Real-time command highlighting |
| Version Mgmt | mise | 50+ languages (Node, Go, Rust, Java, …) |
| Python | uv | Package manager + Python installer (replaces pip/pyenv/poetry) |
| | Ruff | 10-100x faster linter + formatter |
| Git | lazygit + delta + difftastic | TUI client + syntax-highlighted diff + structural diff |
| Navigation | zoxide | Smarter cd (learns your habits) |
| Listing | eza | Modern ls with icons and git status |
| Search | ripgrep + fd + fzf | Fast file/content search |
| Viewing | bat | cat with syntax highlighting |
| Quick-ref | tealdeer | Practical command examples (tldr) |
| Monitoring | btop | Modern resource monitor (htop replacement) |
| Disk | dust | Visual disk usage (du replacement) |
| Terminal | yazi + zellij | File manager + terminal multiplexer |
| Editor | micro | Terminal text editor ($EDITOR) |
| Info | fastfetch | System info (neofetch replacement) |
| Docker | lazydocker | Docker TUI (lazygit companion) |
| AI | OpenCode | Terminal AI coding assistant |
| Other | atuin | Shell history sync |

**Shell functions:**

- `pyinit <project-name>` — one-command Python project init (uv + mise venv auto-activation)
- `mkcd <dir>` — create directory and cd into it
- `extract <archive>` — unified extraction (tar.gz/zip/7z/rar)

## Quick Start

### Prerequisites

- Windows 11 / Windows 10 2004+
- Virtualization enabled in BIOS (VT-x / AMD-V)
- Admin privileges on Windows

### Step 1 — Install WSL2

Open **PowerShell as Administrator**:

```powershell
wsl --install -d Ubuntu-24.04
```

Restart when prompted. Launch **Ubuntu 24.04** from the Start menu and complete initial setup (username, password).

### Step 2 — One-Command Deploy

```bash
git clone https://github.com/Wind-t/devtoolkit.git ~/.local/share/devtoolkit
bash ~/.local/share/devtoolkit/bootstrap.sh
```

Wait a few minutes. After seeing "Bootstrap Complete":

```bash
exec zsh
bash ~/.local/share/devtoolkit/verify.sh   # 60+ checks, should be all green
```

### Step 3 — Configure OpenCode (optional)

```bash
opencode auth login
```

## Useful Aliases

Ready after install:

```bash
# git
g / ga / gs / gc / gp / gl / gd / gco / gb
lg          → lazygit

# modern replacements
grep        → rg (ripgrep)
find        → fd
cat         → bat
top         → btop
du          → dust

# python
uvr         → uv run
uva         → uv add
uvs         → uv sync

# misc
z <dirname> → jump to directory (zoxide)
reload      → exec zsh
update      → sudo apt update && sudo apt upgrade -y
cleanup     → sudo apt autoremove -y && sudo apt autoclean
```

## Secrets Management

Store API keys / tokens in `~/.env_secrets` (auto-sourced by `.zshrc`):

```bash
touch ~/.env_secrets && chmod 600 ~/.env_secrets
# Then uncomment `source ~/.env_secrets` in .zshrc
```

## Recommended Font

Starship icons require a Nerd Font. Recommended: [Maple Mono NF CN](https://github.com/subframe7536/maple-font) — native Chinese monospace (exact 2:1 width), built-in Nerd Font icons, configurable ligatures.

## Verify Installation

```bash
bash ~/.local/share/devtoolkit/verify.sh
```

Checks 50+ items: WSL, shell, version managers, Python, dev tools, dotfiles, PATH.

## Uninstall

```bash
bash ~/.local/share/devtoolkit/uninstall.sh       # unlink dotfiles
bash ~/.local/share/devtoolkit/uninstall.sh --all # also remove ~/.local/bin
```

## Architecture

See [ARCHITECTURE.md](docs/ARCHITECTURE.md) for the layered design rationale: why Docker Desktop on Windows (not inside WSL), mise over nvm/pyenv, uv over pip/poetry, no oh-my-zsh, starship over powerlevel10k, and zoxide over autojump.

Also available in [中文](docs/ARCHITECTURE-zh.md).

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues: GitHub API rate limits, OpenCode installation failures, symlink problems, bat command not found, WSL sparse VHD warnings, networking issues.

## License

MIT © 2026 Wind_t
