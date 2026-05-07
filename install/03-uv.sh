#!/usr/bin/env bash
# =============================================================================
# 03-uv.sh — Python toolchain: uv + Ruff
# =============================================================================
# Sources:
#   https://docs.astral.sh/uv/     — official uv docs
#   https://docs.astral.sh/ruff/   — official Ruff docs
# Design: uv replaces pip, virtualenv, pip-tools, poetry, pyenv
#         Ruff replaces Flake8, Black, isort, pylint (single tool)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# --- install uv -------------------------------------------------------------
if command -v uv &>/dev/null; then
    log "uv already installed: $(uv --version 2>/dev/null)"
else
    log "Installing uv via official standalone installer..."
    safe_curl https://astral.sh/uv/install.sh | sh || {
        log "uv install failed (network issue?). Install manually: https://docs.astral.sh/uv/"
    }
    export PATH="$HOME/.local/bin:$PATH"
fi

# --- set uv mirror (China optimization) -------------------------------------
log "Configuring uv PyPI mirror..."
mkdir -p "$HOME/.config/uv"
if [ ! -f "$HOME/.config/uv/uv.toml" ]; then
    cat > "$HOME/.config/uv/uv.toml" <<'EOF'
[[index]]
url = "https://pypi.tuna.tsinghua.edu.cn/simple"
default = true
EOF
    log "  uv.toml created with Tsinghua mirror."
else
    log "  uv.toml already exists, skipping."
fi

# --- install managed Python via uv ------------------------------------------
log "Installing Python 3.13 via uv..."
uv python install 3.13 && log "  Python 3.13 installed." || log "  Python 3.13 skipped (already installed or network error)."

# --- install Ruff (as global tool) ------------------------------------------
log "Installing Ruff via uv..."
uv tool install ruff && log "  Ruff installed." || log "  Ruff skipped (already installed or network error)."
uv tool upgrade ruff 2>/dev/null || true

success "uv + Ruff configured:"
log "  uv   : $(uv --version 2>/dev/null || echo 'restart shell')"
log "  ruff : $(ruff --version 2>/dev/null || echo 'restart shell')"
