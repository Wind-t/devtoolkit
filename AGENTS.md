# devtoolkit

A bootstrap script for setting up a complete WSL Ubuntu development environment.

## Quick Commands
- Install: `bash bootstrap.sh`
- Verify: `bash verify.sh`
- Uninstall: `bash uninstall.sh`

## Project Structure
- `bootstrap.sh` — main install script (idempotent, with pre-flight dep checks)
- `verify.sh` — post-install verification (65+ checks)
- `uninstall.sh` — cleanup script
- `config/` — configuration templates (shell, git, starship, mise, WSL)
- `install/` — per-tool install modules (8 phases)
- `docs/` — architecture docs (EN + ZH) and productivity guide (ZH)
- `.github/workflows/ci.yml` — CI: bash syntax + ShellCheck + Docker integration
- `.pre-commit-config.yaml` — pre-commit shellcheck hook
- `README.md` — primary documentation (Chinese)
- `README.en.md` — English documentation
- `CONTRIBUTING.md` — coding standards and PR process
- `CHANGELOG.md` — version history
- `TROUBLESHOOTING.md` — common issues and fixes
- `LICENSE` — MIT

## v2 (branch `v2`)
- Adds `lib/common.sh` — shared helpers (log, safe_curl, get_arch, etc.)
- All install scripts source `lib/common.sh` instead of duplicating helpers
- Adds `SKIP_WSL_CHECK`, `SKIP_ROOT_CHECK`, `SKIP_SUDO_CHECK` for CI/Docker

## Script Conventions
- All scripts must be idempotent (check `command -v` before installing)
- Use `--proto '=https' --tlsv1.2` for all curl calls (or `safe_curl` wrapper in v2)
- Auto-detect architecture (x86_64/aarch64)
- GitHub API calls need fallback version numbers
- Output PASS/FAIL/SKIP for each step
- ShellCheck `--severity=warning` must pass with zero warnings
