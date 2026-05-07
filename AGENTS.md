# devtoolkit

A bootstrap script for setting up a complete WSL Ubuntu development environment.

## Quick Commands
- Install: `bash bootstrap.sh`
- Verify: `bash verify.sh`
- Uninstall: `bash uninstall.sh`

## Project Structure
- `bootstrap.sh` — main install script (idempotent)
- `verify.sh` — post-install verification
- `uninstall.sh` — cleanup script
- `config/` — configuration templates
- `install/` — per-tool install modules
- `docs/` — documentation

## Script Conventions
- All scripts must be idempotent (check `command -v` before installing)
- Use `--proto '=https' --tlsv1.2` for all curl calls
- Auto-detect architecture (x86_64/aarch64)
- GitHub API calls need fallback version numbers
- Output PASS/FAIL/SKIP for each step
