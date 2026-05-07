#!/usr/bin/env bash
# =============================================================================
# 06-opencode.sh — terminal AI coding agent
# =============================================================================
# Source: https://opencode.ai — official install
# =============================================================================
set -euo pipefail

log()   { printf '\033[1;34m[INFO]\033[0m  "%s"\n' "$*"; }
success(){ printf '\033[1;32m[OK]\033[0m    "%s"\n' "$*"; }

# --- install OpenCode -------------------------------------------------------
if command -v opencode &>/dev/null; then
    log "OpenCode already installed: $(opencode --version 2>/dev/null || echo 'ok')"
else
    log "Installing OpenCode via official script..."
    curl --proto '=https' --tlsv1.2 --connect-timeout 10 --max-time 60 --retry 2 --retry-delay 5 -fsSL https://opencode.ai/install | bash || {
        log "OpenCode install failed (network issue?). Install manually: https://opencode.ai"
    }
    export PATH="$HOME/.local/bin:$PATH"
fi

# --- create config dir ------------------------------------------------------
mkdir -p "$HOME/.config/opencode"
export OPENCODE_CONFIG_DIR="$HOME/.config/opencode"

success "OpenCode installed."
log "Run 'opencode auth login' to configure your AI provider keys."
