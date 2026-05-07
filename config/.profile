# =============================================================================
# .profile — login shell fallback (bash / sh compatibility)
# =============================================================================
# This runs for POSIX login shells. If you use zsh, .zshrc is the main config.
# .profile is kept minimal as a safety net.
# =============================================================================

# --- PATH -------------------------------------------------------------------
export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"

# --- mise (for bash users) --------------------------------------------------
if [ -x "$HOME/.local/bin/mise" ]; then
    eval "$($HOME/.local/bin/mise activate bash)"
fi

# --- starship (for bash users) ----------------------------------------------
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# --- source .zshenv if running zsh (but NOT .zshrc — that's interactive) ---
if [ -n "${ZSH_VERSION:-}" ] && [ -f "$HOME/.zshenv" ]; then
    . "$HOME/.zshenv"
fi

[ -f "$HOME/.atuin/bin/env" ] && . "$HOME/.atuin/bin/env"
