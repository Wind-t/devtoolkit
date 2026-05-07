#!/usr/bin/env bash
# =============================================================================
# 01-zsh.sh — zsh + plugins (no oh-my-zsh)
# =============================================================================
# Sources:
#   https://github.com/zsh-users/zsh-autosuggestions
#   https://github.com/zsh-users/zsh-syntax-highlighting
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# --- install zsh ------------------------------------------------------------
log "Installing zsh..."
sudo apt install -y -qq zsh > /dev/null 2>&1

# Set zsh as default shell (idempotent)
if [ "$SHELL" != "$(command -v zsh)" ]; then
    log "Setting zsh as default shell..."
    # Use chsh with stdin closed to avoid blocking on password prompt
    # Falls back to manual instruction if non-interactive
    if sudo chsh -s "$(command -v zsh)" "$(whoami)" </dev/null; then
        success "zsh set as default shell."
    else
        log "Could not change default shell (non-interactive session?)."
        log "Run manually: chsh -s $(command -v zsh)"
    fi
fi

# --- install plugins (manual clone, no oh-my-zsh) ---------------------------
log "Installing zsh plugins..."

ZSH_PLUGIN_DIR="$HOME/.zsh"

# zsh-autosuggestions
if [ ! -d "$ZSH_PLUGIN_DIR/zsh-autosuggestions" ]; then
    if timeout 120 git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git \
        "$ZSH_PLUGIN_DIR/zsh-autosuggestions" 2>/dev/null; then
        success "zsh-autosuggestions installed."
    else
        log "zsh-autosuggestions clone failed (network issue?)."
    fi
else
    log "zsh-autosuggestions already present, updating..."
    timeout 30 git -C "$ZSH_PLUGIN_DIR/zsh-autosuggestions" pull --ff-only 2>/dev/null || true
fi

# zsh-syntax-highlighting
if [ ! -d "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting" ]; then
    if timeout 120 git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting" 2>/dev/null; then
        success "zsh-syntax-highlighting installed."
    else
        log "zsh-syntax-highlighting clone failed (network issue?)."
    fi
else
    log "zsh-syntax-highlighting already present, updating..."
    timeout 30 git -C "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting" pull --ff-only 2>/dev/null || true
fi

success "zsh + plugins configured."
