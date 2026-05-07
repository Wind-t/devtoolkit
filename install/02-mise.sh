#!/usr/bin/env bash
# =============================================================================
# 02-mise.sh — polyglot version manager
# =============================================================================
# Source: https://mise.jdx.dev — official install docs
# Replaces: nvm, pyenv, rbenv, asdf, etc.
# =============================================================================
set -euo pipefail

log()   { printf '\033[1;34m[INFO]\033[0m  "%s"\n' "$*"; }
success(){ printf '\033[1;32m[OK]\033[0m    "%s"\n' "$*"; }

# --- install mise -----------------------------------------------------------
if command -v mise &>/dev/null; then
    log "mise already installed: $(mise --version)"
else
    log "Installing mise via official script..."
    curl --proto '=https' --tlsv1.2 --connect-timeout 10 --max-time 60 -fsSL https://mise.run | sh

    # Ensure mise binary is available immediately
    export PATH="$HOME/.local/bin:$PATH"
fi

log "Updating mise..."
mise self-update -y 2>/dev/null || log "  mise self-update skipped (network issue?)."

# --- activate in current shell ----------------------------------------------
if [ -x "$HOME/.local/bin/mise" ]; then
    eval "$(~/.local/bin/mise activate zsh)" 2>/dev/null || true
fi

# --- install common runtimes (adjust to your needs) -------------------------
log "Installing common runtimes via mise..."

for tool in node@lts go@latest; do
    # Extract bare tool name (strip @version alias for mise current check)
    tool_name="${tool%%@*}"
    if mise current "$tool_name" &>/dev/null; then
        log "  $tool already installed."
    else
        log "  Installing $tool..."
        mise use --global "$tool"
    fi
done

# --- link config ------------------------------------------------------------
mkdir -p "$HOME/.config/mise"

success "mise configured: $(mise --version 2>/dev/null || echo 'restart shell to activate')"
