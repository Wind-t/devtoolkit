#!/usr/bin/env bash
# =============================================================================
# 04-starship.sh — minimalist cross-shell prompt
# =============================================================================
# Source: https://starship.rs — official docs
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# --- install starship -------------------------------------------------------
if command -v starship &>/dev/null; then
    log "starship already installed: $(starship --version)"
else
    log "Installing starship via official script..."
    safe_curl https://starship.rs/install.sh | sh -s -- -y || {
        log "starship install failed (network issue?). Install manually: https://starship.rs"
    }
    export PATH="$HOME/.local/bin:$PATH"
fi

# --- ensure config directory exists -----------------------------------------
mkdir -p "$HOME/.config"

if command -v starship &>/dev/null; then
    success "starship installed: $(starship --version)"
else
    warn "starship NOT installed. Run manually: curl -fsSL https://starship.rs/install.sh | sh"
fi
