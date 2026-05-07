# =============================================================================
# .zshenv — environment variables (sourced for ALL zsh instances)
# =============================================================================
# WARNING: Keep PATH additions minimal here. Interactive PATH goes in .zshrc.
#          .zshenv is sourced by EVERY zsh process, including scripts.
# =============================================================================

# --- editor -----------------------------------------------------------------
# Used by git, crontab, and anything that launches $EDITOR.
export EDITOR="${EDITOR:-micro}"
export VISUAL="${VISUAL:-code}"

# --- locale -----------------------------------------------------------------
export LANG="en_US.UTF-8"
unset LC_ALL                         # no global override; let LC_* sub-vars work

# --- XDG base directories (freedesktop.org spec) ----------------------------
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# --- mise -------------------------------------------------------------------
export MISE_DATA_DIR="$HOME/.local/share/mise"

# --- OpenCode ---------------------------------------------------------------
export OPENCODE_CONFIG_DIR="$HOME/.config/opencode"

# --- uv (uncomment to set a persistent PyPI mirror) -------------------------
# export UV_INDEX_URL="https://pypi.tuna.tsinghua.edu.cn/simple"

# --- starship (config path, used by both interactive and scripted use) ------
export STARSHIP_CONFIG="$HOME/.config/starship.toml"

# --- zsh ---------------------------------------------------------------------
# Move zsh completion dump to cache directory instead of polluting $HOME
export ZSH_COMPDUMP="$HOME/.cache/zsh/zcompdump-$HOST"

# --- less (bat uses this for paging) ----------------------------------------
export LESS="-R -F -X"
export LESSHISTFILE="-"
export BAT_THEME="Dracula"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
# --- proxy (unset WSL-forwarded uppercase duplicates) -----------------------
unset HTTP_PROXY HTTPS_PROXY NO_PROXY ALL_PROXY FTP_PROXY
# Override no_proxy with standard-compliant wildcards.
# The 172.16.0.0/12 private range is split into explicit /16 blocks for maximum
# compatibility (some libcurl builds don't support CIDR wildcards like 172.*).
# Private network ranges + localhost (standard, always safe)
export no_proxy="192.168.*,172.16.*,172.17.*,172.18.*,172.19.*,172.20.*,172.21.*,172.22.*,172.23.*,172.24.*,172.25.*,172.26.*,172.27.*,172.28.*,172.29.*,172.30.*,172.31.*,10.*,127.*,*.local,localhost"
# China-specific domains (uncomment if you're in China)
# no_proxy="$no_proxy,*360buyimg.com,100ime-iat-api.xfyun.cn,*jd.com,*zhimg.com,*zhihu.com"
# MCP services (uncomment if using OpenCode MCP providers)
# no_proxy="$no_proxy,.mcp.context7.com,.mcp.grep.app,.mcp.exa.ai"
