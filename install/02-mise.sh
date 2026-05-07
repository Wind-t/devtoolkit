#!/usr/bin/env bash
# =============================================================================
# 02-mise.sh — polyglot version manager
# =============================================================================
# Source: https://mise.jdx.dev — official install docs
# Replaces: nvm, pyenv, rbenv, asdf, etc.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# --- install mise -----------------------------------------------------------
if command -v mise &>/dev/null; then
    log "mise already installed: $(mise --version)"
else
    log "Installing mise via official script..."
    safe_curl https://mise.run | sh || {
        log "mise install script failed (network issue?). Install manually: https://mise.jdx.dev"
    }

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
    # Extract bare tool name (strip @version alias)
    tool_name="${tool%%@*}"
    # mise current returns 0 even when tool is not installed (WARN + exit 0),
    # so we check mise ls output instead
    if mise ls "$tool_name" 2>/dev/null | grep -q .; then
        log "  $tool already installed."
    else
        log "  Installing $tool..."
        mise use --global "$tool"
    fi
done

# --- link config ------------------------------------------------------------
mkdir -p "$HOME/.config/mise"

success "mise configured: $(mise --version 2>/dev/null || echo 'restart shell to activate')"
