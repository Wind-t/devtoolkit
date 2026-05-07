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
- `lib/common.sh` — shared helpers (log, safe_curl, get_arch, github_latest_tag, require_jq)
- `config/` — configuration templates (shell, git, starship, mise, WSL)
- `install/` — per-tool install modules (8 phases, all source lib/common.sh)
- `docs/` — architecture docs (EN + ZH) and productivity guide (ZH)
- `README.md` — primary documentation (Chinese)
- `README.en.md` — English documentation
- `TROUBLESHOOTING.md` — common issues and fixes
- `LICENSE` — MIT

## Script Conventions
- All scripts must be idempotent (check `command -v` before installing)
- Use `--proto '=https' --tlsv1.2` for all curl calls
- Auto-detect architecture (x86_64/aarch64)
- GitHub API calls need fallback version numbers
- Output PASS/FAIL/SKIP for each step
