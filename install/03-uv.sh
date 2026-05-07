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

log()   { printf '\033[1;34m[INFO]\033[0m  "%s"\n' "$*"; }
success(){ printf '\033[1;32m[OK]\033[0m    "%s"\n' "$*"; }

# --- install uv -------------------------------------------------------------
if command -v uv &>/dev/null; then
    log "uv already installed: $(uv --version 2>/dev/null)"
else
    log "Installing uv via official standalone installer..."
    curl --proto '=https' --tlsv1.2 --connect-timeout 10 --max-time 60 -LsSf https://astral.sh/uv/install.sh | sh
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
