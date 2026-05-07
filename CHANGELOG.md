# Changelog

## v1.0.0 (2026-05-08)

### Added
- Initial public release
- 8-phase idempotent WSL Ubuntu dev environment bootstrap
- 26 tools: zsh, starship, mise, uv, ruff, lazygit, delta, difftastic, ripgrep, fd, fzf, bat, tealdeer, gh, micro, zoxide, eza, btop, lazydocker, dust, yazi, zellij, fastfetch, atuin, OpenCode
- Shell functions: `pyinit`, `mkcd`, `extract`
- 60+ item verification suite (`verify.sh`)
- Bilingual README (中文 + English) with language switcher
- WSL config templates: `.wslconfig` (mirrored networking, DNS tunneling, firewall, sparse VHD) and `wsl.conf`
- China-friendly: Aliyun apt mirror, Tsinghua PyPI mirror
- MIT License

### Fixed
- ShellCheck zero warnings across all 11 scripts
- `curl | sh` patterns hardened with `--retry` and fallback URLs
- micro editor properly installed (was missing from base packages)
- Starship palette naming aligned with actual colors
- `.zshenv` no_proxy comments corrected
- Dead bun runtime code removed from `.zshrc`
- `verify.sh` starship.toml symlink path corrected
