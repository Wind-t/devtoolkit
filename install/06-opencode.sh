#!/usr/bin/env bash
# =============================================================================
# 06-opencode.sh — terminal AI coding agent
# =============================================================================
# Source: https://opencode.ai — official install
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# --- install OpenCode -------------------------------------------------------
if command -v opencode &>/dev/null; then
    log "OpenCode already installed: $(opencode --version 2>/dev/null || echo 'ok')"
else
    log "Installing OpenCode via official script..."
    safe_curl https://opencode.ai/install | bash || {
        log "OpenCode install failed (network issue?). Install manually: https://opencode.ai"
    }
    export PATH="$HOME/.local/bin:$PATH"
fi

# --- create config dir ------------------------------------------------------
mkdir -p "$HOME/.config/opencode"
export OPENCODE_CONFIG_DIR="$HOME/.config/opencode"

success "OpenCode installed."
log "Run 'opencode auth login' to configure your AI provider keys."
