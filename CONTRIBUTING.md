# Contributing to DevToolkit

Thanks for helping improve DevToolkit! This guide covers how to contribute.

## Adding a New Tool

1. Determine which phase it belongs to:
   - `00-essentials.sh` — base system packages (apt)
   - `01-zsh.sh` — shell and plugins
   - `02-mise.sh` — version managers
   - `03-uv.sh` — Python toolchain
   - `04-starship.sh` — prompt
   - `05-dev-tools.sh` — dev utilities (ripgrep, lazygit, gh, etc.)
   - `06-opencode.sh` — AI tools
   - `07-extras.sh` — quality-of-life tools (zoxide, eza, btop, etc.)

2. Add the install block to the appropriate phase script following the idempotent pattern:
   ```bash
   if command -v toolname &>/dev/null; then
       log "toolname already installed: $(toolname --version)"
   else
       log "Installing toolname..."
       # Installation command
   fi
   ```

3. Add the tool to `README.md` and `README.en.md` tool tables
4. Add a `check_opt` entry in `verify.sh`

## Coding Standards

- **Bash**: All scripts must use `set -euo pipefail`
- **ShellCheck**: Zero warnings — run `shellcheck install/*.sh bootstrap.sh verify.sh uninstall.sh`
- **Curl**: Always `--proto '=https' --tlsv1.2 --connect-timeout 10 --max-time 60 -fsSL`
- **Idempotent**: Check `command -v` before installing; safe to re-run
- **Architecture**: Auto-detect `x86_64` vs `aarch64`
- **Fallback**: GitHub API calls need hardcoded fallback version numbers

## PR Process

1. Fork the repo, create a feature branch
2. Make your changes following the coding standards above
3. Run `bash -n` on all modified scripts
4. Run `shellcheck` — zero warnings required
5. Test your changes in a real WSL environment
6. Update `CHANGELOG.md` and tool documentation
7. Submit PR against `main`

## Pre-commit Hooks

```bash
pip install pre-commit
pre-commit install
```

This runs shellcheck before every commit.
