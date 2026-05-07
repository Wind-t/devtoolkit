#!/usr/bin/env bash
# =============================================================================
# 05-dev-tools.sh — lazygit, ripgrep, fd, fzf, bat, difftastic, tealdeer, gh
# =============================================================================
# Sources:
#   https://github.com/jesseduffield/lazygit
#   https://github.com/BurntSushi/ripgrep
#   https://github.com/sharkdp/fd
#   https://github.com/junegunn/fzf
#   https://github.com/sharkdp/bat
# =============================================================================
set -euo pipefail

log()   { printf '\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
success(){ printf '\033[1;32m[OK]\033[0m    %s\n' "$*"; }

# --- dependency guard --------------------------------------------------------
if ! command -v jq &>/dev/null; then
    echo "[ERROR] jq is required but not installed. Run 00-essentials.sh first." >&2
    exit 1
fi

ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  LAZYGIT_ARCH="x86_64" ;;
    aarch64) LAZYGIT_ARCH="arm64" ;;
    *)       echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Fetch version for logging (URL uses /latest/download/ so version is non-critical)
LAZYGIT_VERSION=$(curl --proto '=https' --tlsv1.2 --connect-timeout 10 --max-time 30 -fsSL \
    "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
    | jq -r '.tag_name // empty' | sed 's/^v//') || LAZYGIT_VERSION="0.61.1"

# --- ripgrep, fd, bat -------------------------------------------------------
log "Installing ripgrep, fd, bat, fzf..."
sudo apt install -y -qq ripgrep fd-find bat fzf || log "  Some apt packages may have failed (see above for details)."

# Create `fd` alias (Ubuntu packages it as `fdfind`)
if ! command -v fd &>/dev/null && command -v fdfind &>/dev/null; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi

# --- lazygit ----------------------------------------------------------------
if command -v lazygit &>/dev/null; then
    log "lazygit already installed: $(lazygit --version | head -1)"
else
    log "Installing lazygit v${LAZYGIT_VERSION} (${LAZYGIT_ARCH})..."
    TMPDIR=$(mktemp -d -t lazygit-XXXX)
    trap 'rm -rf "${TMPDIR:-}" 2>/dev/null' EXIT INT TERM
    curl --proto '=https' --tlsv1.2 --connect-timeout 10 --max-time 120 -fsSLo "$TMPDIR/lazygit.tar.gz" \
        "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz"
    tar xf "$TMPDIR/lazygit.tar.gz" -C "$TMPDIR" lazygit
    mkdir -p "$HOME/.local/bin"
    install "$TMPDIR/lazygit" "$HOME/.local/bin/lazygit"
    trap - EXIT INT TERM
    rm -rf "$TMPDIR"
fi

success "Dev tools installed."

# --- difftastic (structural diff) -------------------------------------------
# Not in Ubuntu apt — use prebuilt GitHub release binary
if command -v difft &>/dev/null; then
    log "difftastic already installed: $(difft --version | head -1)"
else
    DIFFT_VERSION=$(curl --proto '=https' --tlsv1.2 --connect-timeout 10 --max-time 30 -fsSL \
        https://api.github.com/repos/Wilfred/difftastic/releases/latest \
        | jq -r '.tag_name // empty' | sed 's/^v//') || DIFFT_VERSION="0.69.0"
    log "Installing difftastic v${DIFFT_VERSION}..."
    case "$(uname -m)" in
        x86_64)  DIFF_ARCH="x86_64-unknown-linux-gnu" ;;
        aarch64) DIFF_ARCH="aarch64-unknown-linux-gnu" ;;
        *)       log "Unsupported arch for difftastic, falling back to x86_64"; DIFF_ARCH="x86_64-unknown-linux-gnu" ;;
    esac
    TMPDIR=$(mktemp -d -t difft-XXXX)
    trap 'rm -rf "${TMPDIR:-}" 2>/dev/null' EXIT INT TERM
    if curl --proto '=https' --tlsv1.2 --connect-timeout 10 --max-time 120 -fsSLo "$TMPDIR/difft.tar.gz" \
        "https://github.com/Wilfred/difftastic/releases/latest/download/difft-${DIFF_ARCH}.tar.gz"; then
        tar xf "$TMPDIR/difft.tar.gz" -C "$TMPDIR"
        mkdir -p "$HOME/.local/bin"
        install "$TMPDIR/difft" "$HOME/.local/bin/difft"
        trap - EXIT INT TERM
        rm -rf "$TMPDIR"
    else
        log "  difftastic download failed (network issue)."
        trap - EXIT INT TERM
        rm -rf "$TMPDIR"
    fi
fi

# --- tealdeer (tldr client) --------------------------------------------------
if command -v tldr &>/dev/null; then
    log "tealdeer already installed: $(tldr --version 2>/dev/null || echo 'ok')"
else
    log "Installing tealdeer..."
    case "$(uname -m)" in
        x86_64)  TLDR_ARCH="x86_64" ;;
        aarch64) TLDR_ARCH="aarch64" ;;
        *)       log "Unsupported arch for tealdeer, falling back to x86_64"; TLDR_ARCH="x86_64" ;;
    esac
    curl --proto '=https' --tlsv1.2 --connect-timeout 10 --max-time 120 -fsSLo "$HOME/.local/bin/tldr" \
        "https://github.com/tealdeer-rs/tealdeer/releases/latest/download/tealdeer-linux-${TLDR_ARCH}-musl" \
        && chmod +x "$HOME/.local/bin/tldr" \
        || log "tealdeer install failed; install manually: https://github.com/tealdeer-rs/tealdeer"
fi
tldr --update 2>/dev/null || true


# --- gh (GitHub CLI) ----------------------------------------------------------
if command -v gh &>/dev/null; then
    log "GitHub CLI already installed: $(gh --version | head -1)"
else
    log "Installing GitHub CLI..."
    sudo apt install -y -qq gh || log "gh install failed; install manually: https://github.com/cli/cli"
fi

success "Extended dev tools installed."
