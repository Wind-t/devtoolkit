#!/usr/bin/env bash
# =============================================================================
# 04-starship.sh — minimalist cross-shell prompt
# =============================================================================
# Source: https://starship.rs — official docs
# =============================================================================
set -euo pipefail

log()   { printf '\033[1;34m[INFO]\033[0m  "%s"\n' "$*"; }
success(){ printf '\033[1;32m[OK]\033[0m    "%s"\n' "$*"; }

# --- install starship -------------------------------------------------------
if command -v starship &>/dev/null; then
    log "starship already installed: $(starship --version)"
else
    log "Installing starship via official script..."
    curl --proto '=https' --tlsv1.2 --connect-timeout 10 --max-time 60 -fsSL https://starship.rs/install.sh | sh -s -- -y
    export PATH="$HOME/.local/bin:$PATH"
fi

# --- ensure config directory exists -----------------------------------------
mkdir -p "$HOME/.config"

# --- init line will be sourced in .zshrc, so no need to add here ------------

success "starship installed: $(starship --version)"
