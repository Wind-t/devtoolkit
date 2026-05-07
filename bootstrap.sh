#!/usr/bin/env bash
# =============================================================================
# devtoolkit bootstrap.sh — WSL Development Environment Setup
# =============================================================================
# Idempotent: safe to run multiple times.
# Usage: bash bootstrap.sh
# =============================================================================

set -euo pipefail

DRY_RUN="${DRY_RUN:-0}"

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$DOTFILES_DIR/install"
CONFIG_DIR="$DOTFILES_DIR/config"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# --- shared helpers ---------------------------------------------------------
source "$DOTFILES_DIR/lib/common.sh"

run_phase() {
    local name="$1" script="$2"
    section "$name"
    if [ "$DRY_RUN" = "1" ]; then
        log "[DRY RUN] Would run: $(basename "$script")"
    else
        if [ ! -f "$script" ]; then
            warn "Install script not found: $script"
            return
        fi
        bash "$script" || log "Warning: Phase '$name' failed (script: $script), continuing..."
    fi
}

# --- preflight --------------------------------------------------------------
section "Preflight Checks"

if ! grep -qi microsoft /proc/version 2>/dev/null; then
    fail "This script must be run inside WSL."
fi

if [ "$(whoami)" = "root" ]; then
    fail "Do not run as root. Run as your normal user."
fi

if ! sudo -n true 2>/dev/null; then
    if ! tty -s 2>/dev/null; then
        fail "Running in non-interactive mode and no valid sudo ticket.
  Workarounds:
    - Run in a real terminal
    - Pre-authenticate: run 'sudo -v' in another terminal first
    - CI/CD: echo '\$SUDO_PASSWORD' | sudo -S -v before running this script
    - Dev: add '$(whoami) ALL=(ALL) NOPASSWD:ALL' to /etc/sudoers.d/devtoolkit"
    fi
    log "sudo access required. You may be prompted for your password."
    sudo -v || fail "sudo authentication failed."
fi
log "sudo access confirmed."

# Pre-flight dependency check — verify required binaries exist before any phase
section "Preflight — Dependency Check"
declare -A REQUIRED_BINS=(
    [curl]="sudo apt install -y curl"
    [git]="sudo apt install -y git"
    [jq]="sudo apt install -y jq"
    [tar]="sudo apt install -y tar"
    [unzip]="sudo apt install -y unzip"
)
DEPS_FAILED=0
for bin in "${!REQUIRED_BINS[@]}"; do
    if command -v "$bin" &>/dev/null; then
        log "  ✓ $bin"
    else
        warn "  ✗ $bin — install with: ${REQUIRED_BINS[$bin]}"
        DEPS_FAILED=$((DEPS_FAILED + 1))
    fi
done
if [ "$DEPS_FAILED" -gt 0 ]; then
    fail "$DEPS_FAILED required tool(s) missing. Install them and re-run."
fi
success "All required tools available."

# Check disk space (warn if < 2GB available in $HOME)
AVAIL_KB=$(df -k --output=avail "$HOME" 2>/dev/null | tail -1)
if [ -n "$AVAIL_KB" ] && [ "$AVAIL_KB" -lt 2097152 ]; then
    warn "Low disk space: $((AVAIL_KB / 1024))MB available in $HOME. Installations may fail."
fi

# Background sudo keepalive to prevent timeout during long installs
(while true; do sudo -n true 2>/dev/null || sudo -v 2>/dev/null || true; sleep 60; done) &
keepalive_pid=$!
trap 'kill $keepalive_pid 2>/dev/null' EXIT INT TERM HUP

if [ ! -d "$INSTALL_DIR" ]; then
    fail "Install scripts directory not found: $INSTALL_DIR"
fi
if [ ! -d "$CONFIG_DIR" ]; then
    fail "Config directory not found: $CONFIG_DIR"
fi

log "Dotfiles directory: $DOTFILES_DIR"
log "Timestamp: $TIMESTAMP"
log "User: $(whoami)"
log "Home: $HOME"

# --- run install scripts ----------------------------------------------------
run_phase "Phase 1 — Base System"                         "$INSTALL_DIR/00-essentials.sh"
run_phase "Phase 2 — Shell & CLI"                         "$INSTALL_DIR/01-zsh.sh"
run_phase "Phase 3 — Polyglot Version Manager (mise)"     "$INSTALL_DIR/02-mise.sh"
run_phase "Phase 4 — Python Toolchain (uv + Ruff)"        "$INSTALL_DIR/03-uv.sh"
run_phase "Phase 5 — Starship Prompt"                     "$INSTALL_DIR/04-starship.sh"
run_phase "Phase 6 — Dev Tools (gh, lazygit, ripgrep...)" "$INSTALL_DIR/05-dev-tools.sh"
run_phase "Phase 7 — Terminal AI (OpenCode)"              "$INSTALL_DIR/06-opencode.sh"
run_phase "Phase 8 — Extras (zoxide, eza, btop...)"       "$INSTALL_DIR/07-extras.sh"

# --- link dotfiles ----------------------------------------------------------
section "Linking Dotfiles"

link_file() {
    local src="$1"
    local dst="$2"
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
            log "Already linked: $dst"
            return
        fi
        log "Backing up existing: $dst → ${dst}.bak.$(date +%s)"
        mv "$dst" "${dst}.bak.$(date +%s)"
    fi
    if [ ! -f "$src" ]; then
        warn "Source file missing, skipping: $src"
        return
    fi
    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    success "Linked: $dst → $src"
}

link_file "$CONFIG_DIR/.zshrc"        "$HOME/.zshrc"
link_file "$CONFIG_DIR/.zshenv"       "$HOME/.zshenv"
link_file "$CONFIG_DIR/.profile"      "$HOME/.profile"
link_file "$CONFIG_DIR/.gitconfig"    "$HOME/.gitconfig"
link_file "$CONFIG_DIR/starship.toml" "$HOME/.config/starship.toml"
link_file "$CONFIG_DIR/mise.config.toml" "$HOME/.config/mise/config.toml"
link_file "$CONFIG_DIR/.gitignore_global" "$HOME/.gitignore_global"

# --- final ------------------------------------------------------------------
section "Bootstrap Complete"

echo ""
echo "  ┌───────────────────────────────────────────────────────────────┐"
echo "  │                                                               │"
echo "  │   All done! Next steps:                                       │"
echo "  │                                                               │"
echo "  │   1. Restart your terminal or run: exec zsh                   │"
echo "  │   2. Verify installation: bash $DOTFILES_DIR/verify.sh        │"
echo "  │   3. Set up OpenCode: opencode auth login                     │"
echo "  │   4. Copy config/.wslconfig.ref → %UserProfile%\\.wslconfig    │"
echo "  │   5. Copy config/wsl.conf.ref   → /etc/wsl.conf (sudo)         │"
echo "  │                                                               │"
echo "  │   Optional:                                                   │"
echo "  │   - Docker Desktop: install on Windows side for containers    │"
echo "  │   - Secrets: create ~/.env_secrets (chmod 600) for API keys   │"
echo "  │   - Font: Maple Mono NF CN for icon rendering               │"
echo "  │                                                               │"
echo "  │   Quick dev commands:                                         │"
echo "  │     pyinit myproject   → bootstrap a Python project           │"
echo "  │     lg                 → lazygit TUI                          │"
echo "  │     opencode           → AI coding agent                      │"
echo "  │     z <dirname>        → jump to directory (zoxide)           │"
echo "  │                                                               │"
echo "  └───────────────────────────────────────────────────────────────┘"
echo ""
