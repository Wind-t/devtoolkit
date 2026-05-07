# Architecture Design — WSL Development Environment

## 1. Layer Model

```
┌─────────────────────────────────────────────────────────┐
│                  Windows 11 (Host OS)                    │
│                                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │              Docker Desktop (Windows)             │   │
│  │  ┌──────────────┐  ┌──────────────────────────┐  │   │
│  │  │ docker cli   │  │  docker-desktop (WSL VM) │  │   │
│  │  └──────┬───────┘  └──────────────────────────┘  │   │
│  └─────────┼────────────────────────────────────────┘   │
│            │ unix:///var/run/docker.sock                │
│  ┌─────────┼────────────────────────────────────────┐   │
│  │         ▼                     WSL 2 VM             │   │
│  │  ┌──────────────────────────────────────────┐     │   │
│  │  │        Ubuntu 24.04 (dev distro)          │     │   │
│  │  │                                           │     │   │
│  │  │  ┌ Shell Layer ──────────────────────┐   │     │   │
│  │  │  │ zsh + starship + plugins           │   │     │   │
│  │  │  │ zoxide (smart jumper)              │   │     │   │
│  │  │  │ eza (modern ls)                    │   │     │   │
│  │  │  └────────────────────────────────────┘   │     │   │
│  │  │                                           │     │   │
│  │  │  ┌ Version Layer ────────────────────┐   │     │   │
│  │  │  │ mise (node, go, rust, java, ...)   │   │     │   │
│  │  │  └────────────────────────────────────┘   │     │   │
│  │  │                                           │     │   │
│  │  │  ┌ Python Layer ─────────────────────┐   │     │   │
│  │  │  │ uv (pkg mgr) + Ruff (lint/fmt)    │   │     │   │
│  │  │  │ pyinit() → project bootstrap       │   │     │   │
│  │  │  └────────────────────────────────────┘   │     │   │
│  │  │                                           │     │   │
│  │  │  ┌ Tool Layer ───────────────────────┐   │     │   │
│  │  │  │ lazygit, ripgrep, fd, fzf, bat    │   │     │   │
│  │  │  │ delta (git diff), btop (monitor)   │   │     │   │
│  │  │  └────────────────────────────────────┘   │     │   │
│  │  │                                           │     │   │
│  │  │  ┌ AI Layer ─────────────────────────┐   │     │   │
│  │  │  │ OpenCode (terminal AI agent)       │   │     │   │
│  │  │  └────────────────────────────────────┘   │     │   │
│  │  └───────────────────────────────────────────┘     │   │
│  └────────────────────────────────────────────────────┘   │
│                                                         │
│  ┌ VS Code (Windows) ────────────┐                      │
│  │  Remote - WSL extension        │                      │
│  │  Remote - Containers extension │                      │
│  └────────────────────────────────┘                      │
└─────────────────────────────────────────────────────────┘
```

## 2. Why This Architecture?

### Docker: Desktop on Windows, NOT engine in WSL

**Correct approach:** Docker Desktop installs on Windows. It creates a dedicated `docker-desktop` WSL distro (kernel-level VM) and exposes `docker.sock` to your dev distro via WSL Integration setting.

**Why NOT `apt install docker-ce` inside WSL:**
- WSL 2 is already a managed VM; nesting Docker inside it creates double-cgroup overhead.
- systemd in WSL doesn't manage containerd/runC as reliably as Docker Desktop.
- Docker Desktop provides the GUI, automatic updates, and `docker compose` consistently.

### mise over nvm/pyenv/asdf

- **One tool, 50+ languages** — not 5 different version managers.
- Written in Rust — fast, single binary.
- Compatible with `.tool-versions`, `.node-version`, `.ruby-version` (legacy).
- Built-in direnv replacement (per-project env vars).

### uv over pip/virtualenv/poetry

- Rust-based, 10-100x faster than pip.
- Single binary replaces pip, pip-tools, virtualenv, pyenv, poetry, pipx.
- Can install and manage Python versions itself (`uv python install 3.12`).
- Zero-config lockfile (`uv lock`).

### No oh-my-zsh

- oh-my-zsh is ~100+ plugins, most unused. Slow shell startup.
- We only need 2 plugins: autosuggestions + syntax-highlighting.
- Manual git-clone gives us full control over load order and version.

### Starship over Powerlevel10k

- Written in Rust — instant prompt.
- Cross-shell (works in bash, zsh, fish, PowerShell).
- TOML config — clean, version-controllable.
- No zsh-specific framework dependency.

### zoxide over autojump/z.lua

- Rust implementation — faster.
- Cross-shell support.
- Smarter ranking algorithm (frecency = frequency + recency).
- Zero-config: just start using `z <dirname>`.

### eza over exa (unmaintained) / plain ls

- `exa` is abandoned; eza is the community fork actively maintained.
- Icons, git status, tree view, color-coded permissions.
- Ships in Ubuntu 24.04 apt repos.

## 3. Environment Variable Strategy

| Variable | Purpose | Location | Why Here? |
|----------|---------|----------|-----------|
| `EDITOR` | Default editor for git, crontab, etc. | `.zshenv` | needed by non-interactive shells too |
| `VISUAL` | Same as EDITOR | `.zshenv` | POSIX convention |
| `OPENCODE_CONFIG_DIR` | OpenCode config path | `.zshenv` | needed by both CLI and TUI |
| `STARSHIP_CONFIG` | starship.toml path | `.zshenv` | needed by scripted use too |
| `MISE_DATA_DIR` | mise install location | `.zshenv` | needed by mise activate |
| `BAT_THEME` | bat syntax highlighting theme | `.zshenv` | global default |
| `PATH` (extended) | `~/.local/bin` priority | `.zshrc` | interactive use; `.profile` handles login shells |
| `FZF_DEFAULT_OPTS` | fzf appearance | `.zshrc` | interactive only |
| `UV_INDEX_URL` | PyPI mirror | `.zshenv` (optional) | affects all uv invocations |

**Rule:** Put env vars in `.zshenv` when they are needed by non-interactive zsh scripts. Put them in `.zshrc` when they are only needed interactively. Put them in `.profile` as a bash fallback.

## 4. File System Best Practices

```
/mnt/c/Users/you/           ← DON'T put projects here (cross-fs I/O is 5-10x slower)
~/projects/                 ← DO put projects here (native ext4 on virtual disk)
```

WSL 2 uses ext4 inside the VM disk. Accessing Windows files via `/mnt/c` goes through the 9P protocol layer — every I/O call crosses the VM boundary. For git operations, `npm install`, or anything with many small files, performance tanks.

**Recommendation:** Keep all source code under `~/projects/`. Only use `/mnt/c` for one-off file transfers.

## 5. Performance Optimizations

### `.wslconfig` tuning
- **memory**: Limit to 50-60% of physical RAM so Windows doesn't swap.
- **autoMemoryReclaim=gradual**: WSL returns unused memory to Windows without needing shutdown.
- **networkingMode=mirrored**: WSL shares Windows IP — localhost works directly.
- **sparseVhd=true**: Shrinks the WSL virtual disk as files are deleted.

### Linux-side tuning
- **apt mirror**: Aliyun/Tsinghua for China users reduces `apt update` from minutes to seconds.
- **uv mirror**: PyPI mirror for fast Python package downloads.
- **WSL `wsl.conf`**: `appendWindowsPath=true` lets you launch Windows tools from WSL; set `false` for cleaner PATH isolation.

## 6. Shell Functions Design

| Function | Purpose | Example |
|----------|---------|---------|
| `pyinit [name]` | Bootstrap Python project with uv + mise venv auto-activation | `pyinit myapp` |
| `mkcd <dir>` | Create directory and cd into it | `mkcd ~/projects/foo` |
| `extract <file>` | Unified archive extraction (tar.gz/zip/7z/rar) | `extract archive.tar.gz` |

## 7. Why This Stack?

| Problem | Old Solution | New Solution | Why Better |
|---------|-------------|-------------|------------|
| Python package mgmt | pip + virtualenv + pyenv | uv | 10-100x faster, single binary, includes Python installer |
| Multi-language versions | nvm, pyenv, rbenv, sdkman | mise | One tool, 50+ langs, direnv built-in |
| Shell framework | oh-my-zsh | manual plugins | Faster startup, less bloat, explicit control |
| Prompt | powerlevel10k | starship | Rust, cross-shell, simpler config |
| Directory jumping | autojump/z.lua | zoxide | Rust, cross-shell, frecency ranking |
| File listing | exa (unmaintained) | eza | Active fork, icons, git, tree |
| Linting | Flake8 + Black + isort | Ruff | Single tool, 10-100x faster |
| Git GUI | GitKraken / SourceTree | lazygit | Terminal-native, no Electron bloat |
| Git diff | plain git diff | delta | Syntax highlighting, line numbers, side-by-side |
| Code AI | Copilot (in-editor only) | OpenCode | Terminal agent, multi-model, multi-provider |
| Docker | docker-ce in WSL | Docker Desktop + WSL Integration | Proper VM management, GUI, auto-updates |
| System monitor | htop | btop | Modern UI, GPU stats, theme support |
| Disk usage | du | dust | Visual tree output, intuitive at a glance |
| Terminal font | JetBrainsMono Nerd Font | Maple Mono NF CN | Native CJK monospace (exact 2:1 width), built-in Nerd Font icons |

## 8. Script Execution Flow

```
bootstrap.sh
  │
  ├─ Phase 1: 00-essentials.sh    apt mirrors + base packages + locale
  ├─ Phase 2: 01-zsh.sh           zsh + plugins (manual clone, no oh-my-zsh)
  ├─ Phase 3: 02-mise.sh          polyglot version manager + node/go runtimes
  ├─ Phase 4: 03-uv.sh            uv + Ruff + PyPI mirror
  ├─ Phase 5: 04-starship.sh      cross-shell prompt
  ├─ Phase 6: 05-dev-tools.sh     lazygit, ripgrep, fd, fzf, bat, difftastic, tealdeer, gh
  ├─ Phase 7: 06-opencode.sh      terminal AI coding agent
  ├─ Phase 8: 07-extras.sh        zoxide, eza, btop, delta, lazydocker, dust, yazi, etc.
  │
  └─ Linking:                     symlink config/ dotfiles into $HOME
```

Each Phase script runs independently. Dependencies between phases are protected by `command -v` guards and explicit dependency checks. A failure in one phase does not block subsequent phases (unless a critical dependency is missing).

## 9. Error Handling Design

The project uses a **three-layer defense** strategy:

| Layer | Mechanism | Covers |
|-------|-----------|--------|
| Outer | `set -euo pipefail` + `trap EXIT INT TERM` | Script-level abnormal exit, temp file cleanup |
| Middle | `command -v` guards + `curl -f` + `jq // empty` | Network failures, API rate limits, idempotent skip |
| Inner | `|| { fallback }` + hardcoded fallback versions | Final safety net when GitHub API is completely unreachable |

**Trap cleanup**: Every code block that creates a temporary directory has a paired `trap` set/clear, ensuring no garbage is left behind on Ctrl+C or `set -e` exit.

**Idempotency**: The entire bootstrap can be run ten times on the same machine — each pass checks what's already installed and only fills in what's missing.

---

> For more detailed design decisions and troubleshooting, see [README.md](../README.md).
