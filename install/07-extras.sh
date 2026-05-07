#!/usr/bin/env bash
# =============================================================================
# 07-extras.sh — quality-of-life dev tools
# =============================================================================
# zoxide  → smarter cd (autojump/z replacement)
# eza     → modern ls with icons, git status, tree
# btop    → modern resource monitor (htop replacement)
# delta   → syntax-highlighting git diff pager
# lazydocker → Docker TUI (companion to lazygit)
# dust    → visual disk usage (du replacement)
# yazi    → terminal file manager
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# --- dependency guard --------------------------------------------------------
require_jq

# --- zoxide -----------------------------------------------------------------
if command -v zoxide &>/dev/null; then
    log "zoxide already installed: $(zoxide --version)"
else
    log "Installing zoxide..."
    # Try apt first (some distributions have it)
    if sudo apt install -y -qq zoxide 2>/dev/null; then
        log "  zoxide installed via apt."
    elif command -v cargo &>/dev/null; then
        log "  Installing zoxide via cargo..."
        cargo install zoxide 2>/dev/null && log "  zoxide installed via cargo." || log "  zoxide cargo install failed."
    else
        # Fallback to official script (may hit rate limit)
        safe_curl https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash || log "  zoxide install failed. Install manually: https://github.com/ajeetdsouza/zoxide"
    fi
    export PATH="$HOME/.local/bin:$PATH"
fi

# --- eza --------------------------------------------------------------------
if command -v eza &>/dev/null; then
    log "eza already installed: $(eza --version | head -1)"
else
    log "Installing eza..."
    # Ubuntu 24.04+ has eza in apt
    sudo apt install -y -qq eza || {
        # Fallback: cargo install
        if command -v cargo &>/dev/null; then
            log "Installing eza via cargo (compiling from source, please wait)..."
            cargo install eza 2>/dev/null || log "eza cargo install failed."
        else
            log "Skipping eza — no cargo available. Install Rust first: mise use --global rust@latest"
        fi
    }
fi

# --- btop (modern resource monitor, replaces htop) --------------------------
if command -v btop &>/dev/null; then
    log "btop already installed: $(btop --version 2>/dev/null || echo 'ok')"
else
    log "Installing btop..."
    BTOP_VERSION=$(github_latest_tag "aristocratos/btop" "v1.4.7" | sed 's/^v//')
    case "$(uname -m)" in
        x86_64)  BTOP_ARCH="x86_64-unknown-linux-musl" ;;
        aarch64) BTOP_ARCH="aarch64-unknown-linux-musl" ;;
        *)       BTOP_ARCH="x86_64-unknown-linux-musl" ;;
    esac
    TMPDIR=$(mktemp -d -t btop-XXXX)
    trap 'rm -rf "${TMPDIR:-}" 2>/dev/null' EXIT INT TERM
    if safe_curl --max-time 120 -o "$TMPDIR/btop.tar.gz" \
        "https://github.com/aristocratos/btop/releases/download/v${BTOP_VERSION}/btop-${BTOP_ARCH}.tar.gz" && \
        tar xzf "$TMPDIR/btop.tar.gz" -C "$TMPDIR"; then
        mkdir -p "$HOME/.local/bin" "$HOME/.config/btop/themes"
        install "$TMPDIR/btop/bin/btop" "$HOME/.local/bin/btop"
        cp -r "$TMPDIR/btop/themes/"* "$HOME/.config/btop/themes/" 2>/dev/null || true
        log "  btop v${BTOP_VERSION} installed from GitHub."
    else
        log "  GitHub install failed, falling back to apt..."
        sudo apt install -y -qq btop || log "btop install failed."
    fi
    trap - EXIT INT TERM
    rm -rf "$TMPDIR"
fi

# --- git-delta --------------------------------------------------------------
if command -v delta &>/dev/null; then
    log "delta already installed: $(delta --version | head -1)"
else
    log "Installing git-delta..."
    DELTA_TAG=$(github_latest_tag "dandavison/delta" "0.19.2")
    DELTA_VERSION="${DELTA_TAG#v}"
    case "$(uname -m)" in
        x86_64)  DELTA_ARCH="amd64" ;;
        aarch64) DELTA_ARCH="arm64" ;;
        *)       DELTA_ARCH="amd64" ;;
    esac
    TMPDEB=$(mktemp -t delta-XXXX.deb)
    if safe_curl --max-time 120 -o "$TMPDEB" \
        "https://github.com/dandavison/delta/releases/download/${DELTA_TAG}/git-delta_${DELTA_VERSION}_${DELTA_ARCH}.deb" \
        && sudo dpkg -i "$TMPDEB" 2>/dev/null \
        && sudo apt-get install -f -y -qq 2>/dev/null; then
        log "  delta ${DELTA_VERSION} installed from GitHub."
    else
        log "  GitHub install failed, falling back to apt..."
        sudo apt install -y -qq git-delta || log "delta install failed; install manually: https://github.com/dandavison/delta"
    fi
    rm -f "$TMPDEB"
fi

# --- lazydocker --------------------------------------------------------------
if command -v lazydocker &>/dev/null; then
    log "lazydocker already installed: $(lazydocker --version | head -1)"
else
    log "Installing lazydocker..."
    LAZYDOCKER_VERSION=$(github_latest_tag "jesseduffield/lazydocker" "v0.25.2" | sed 's/^v//')
    case "$(uname -m)" in
        x86_64)  LD_ARCH="x86_64" ;;
        aarch64) LD_ARCH="arm64" ;;
        *)       log "Unsupported arch for lazydocker, falling back to x86_64"; LD_ARCH="x86_64" ;;
    esac
    TMPDIR=$(mktemp -d -t lazydocker-XXXX)
    trap 'rm -rf "${TMPDIR:-}" 2>/dev/null' EXIT INT TERM
    if safe_curl --max-time 120 -o "$TMPDIR/lazydocker.tar.gz" \
        "https://github.com/jesseduffield/lazydocker/releases/download/v${LAZYDOCKER_VERSION}/lazydocker_${LAZYDOCKER_VERSION}_Linux_${LD_ARCH}.tar.gz" && \
        tar xf "$TMPDIR/lazydocker.tar.gz" -C "$TMPDIR" lazydocker; then
        mkdir -p "$HOME/.local/bin"
        install "$TMPDIR/lazydocker" "$HOME/.local/bin/lazydocker"
        log "  lazydocker v${LAZYDOCKER_VERSION} installed."
    else
        log "  lazydocker download or extraction failed."
    fi
    trap - EXIT INT TERM
    rm -rf "$TMPDIR"
fi

# --- dust (visual disk usage) ------------------------------------------------
# GitHub release first, cargo as fallback
if command -v dust &>/dev/null; then
    log "dust already installed: $(dust --version 2>/dev/null || echo 'ok')"
else
    log "Installing dust..."
    DUST_VERSION=$(github_latest_tag "bootandy/dust" "v1.2.4" | sed 's/^v//')
    case "$(uname -m)" in
        x86_64)  DUST_ARCH="x86_64-unknown-linux-musl" ;;
        aarch64) DUST_ARCH="aarch64-unknown-linux-musl" ;;
        *)       log "Unsupported arch for dust, falling back to x86_64"; DUST_ARCH="x86_64-unknown-linux-musl" ;;
    esac
    TMPDIR=$(mktemp -d -t dust-XXXX)
    safe_curl --max-time 120 -o "$TMPDIR/dust.tar.gz" \
        "https://github.com/bootandy/dust/releases/download/v${DUST_VERSION}/dust-v${DUST_VERSION}-${DUST_ARCH}.tar.gz" \
        && {
            tar xzf "$TMPDIR/dust.tar.gz" -C "$TMPDIR"
            mkdir -p "$HOME/.local/bin"
            install "$TMPDIR"/dust-*/dust "$HOME/.local/bin/dust"
            rm -rf "$TMPDIR"
        } || {
            rm -rf "$TMPDIR"
            # Fallback: cargo
            cargo install du-dust 2>/dev/null || log "dust install failed; install manually: https://github.com/bootandy/dust"
        }
fi

# --- yazi (terminal file manager) --------------------------------------------
if command -v yazi &>/dev/null; then
    log "yazi already installed: $(yazi --version | head -1)"
else
    log "Installing yazi..."
    case "$(uname -m)" in
        x86_64)  YAZI_ARCH="x86_64-unknown-linux-musl" ;;
        aarch64) YAZI_ARCH="aarch64-unknown-linux-musl" ;;
        *)       log "Unsupported arch for yazi, falling back to x86_64"; YAZI_ARCH="x86_64-unknown-linux-musl" ;;
    esac
    TMPDIR=$(mktemp -d -t yazi-XXXX)
    trap 'rm -rf "${TMPDIR:-}" 2>/dev/null' EXIT INT TERM
    safe_curl --max-time 120 -o "$TMPDIR/yazi.zip" \
        "https://github.com/sxyazi/yazi/releases/latest/download/yazi-${YAZI_ARCH}.zip"
    if unzip -qo "$TMPDIR/yazi.zip" -d "$TMPDIR" 2>/dev/null; then
        mkdir -p "$HOME/.local/bin"
        install "$TMPDIR"/yazi-*/yazi "$HOME/.local/bin/yazi"
        install "$TMPDIR"/yazi-*/ya "$HOME/.local/bin/ya"
        log "  yazi installed."
    else
        log "  yazi install failed; install manually: https://github.com/sxyazi/yazi"
    fi
    trap - EXIT INT TERM
    rm -rf "$TMPDIR"
fi


# --- fastfetch (C rewrite of neofetch, 10x faster) ---------------------------
if command -v fastfetch &>/dev/null; then
    log "fastfetch already installed: $(fastfetch --version 2>/dev/null || echo 'ok')"
else
    log "Installing fastfetch..."
    case "$(uname -m)" in
        x86_64)  FF_ARCH="amd64" ;;
        aarch64) FF_ARCH="aarch64" ;;
        *)       log "Unsupported arch for fastfetch, falling back to amd64"; FF_ARCH="amd64" ;;
    esac
    TMPDIR=$(mktemp -d -t fastfetch-XXXX)
    trap 'rm -rf "${TMPDIR:-}" 2>/dev/null' EXIT INT TERM
    safe_curl --max-time 120 -o "$TMPDIR/fastfetch.tar.gz" \
        "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-${FF_ARCH}.tar.gz"
    tar xzf "$TMPDIR/fastfetch.tar.gz" -C "$TMPDIR"
    mkdir -p "$HOME/.local/bin"
    install "$TMPDIR"/fastfetch-*/usr/bin/fastfetch "$HOME/.local/bin/fastfetch"
    trap - EXIT INT TERM
    rm -rf "$TMPDIR"
fi

# --- zellij (modern terminal multiplexer) ------------------------------------
if command -v zellij &>/dev/null; then
    log "zellij already installed: $(zellij --version 2>/dev/null || echo 'ok')"
else
    log "Installing zellij..."
    case "$(uname -m)" in
        x86_64)  ZELLIJ_ARCH="x86_64-unknown-linux-musl" ;;
        aarch64) ZELLIJ_ARCH="aarch64-unknown-linux-musl" ;;
        *)       log "Unsupported arch for zellij, falling back to x86_64"; ZELLIJ_ARCH="x86_64-unknown-linux-musl" ;;
    esac
    TMPDIR=$(mktemp -d -t zellij-XXXX)
    trap 'rm -rf "${TMPDIR:-}" 2>/dev/null' EXIT INT TERM
    safe_curl --max-time 120 -o "$TMPDIR/zellij.tar.gz" \
        "https://github.com/zellij-org/zellij/releases/latest/download/zellij-${ZELLIJ_ARCH}.tar.gz"
    tar xzf "$TMPDIR/zellij.tar.gz" -C "$TMPDIR"
    mkdir -p "$HOME/.local/bin"
    install "$TMPDIR/zellij" "$HOME/.local/bin/zellij"
    trap - EXIT INT TERM
    rm -rf "$TMPDIR"
fi

# --- atuin (shell history sync & fuzzy search) -------------------------------
if command -v atuin &>/dev/null; then
    log "atuin already installed: $(atuin --version 2>/dev/null || echo 'ok')"
else
    log "Installing atuin..."
    safe_curl https://setup.atuin.sh | bash || {
        log "atuin install failed (network issue?). Install manually: https://atuin.sh"
    }
    export PATH="$HOME/.local/bin:$PATH"
    # atuin installer may put binary in ~/.atuin/bin, symlink to standard path
    if [ -f "$HOME/.atuin/bin/atuin" ] && [ ! -f "$HOME/.local/bin/atuin" ]; then
        ln -sf "$HOME/.atuin/bin/atuin" "$HOME/.local/bin/atuin"
    fi
fi

success "Extras installed."
