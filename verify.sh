#!/usr/bin/env bash
# =============================================================================
# verify.sh — health check for the entire dev environment
# =============================================================================
set -euo pipefail

PASS=0
FAIL=0
SKIP=0

check() {
    local name="$1"
    local cmd="$2"
    printf "  %-30s" "$name ..."
    if bash -c "$cmd" &>/dev/null; then
        printf '\033[1;32m✓ PASS\033[0m\n'
        PASS=$((PASS + 1))
    else
        printf '\033[1;31m✗ FAIL\033[0m\n'
        FAIL=$((FAIL + 1))
    fi
}

check_opt() {
    local name="$1"
    local cmd="$2"
    printf "  %-30s" "$name ..."
    if bash -c "$cmd" &>/dev/null; then
        printf '\033[1;32m✓ PASS\033[0m\n'
        PASS=$((PASS + 1))
    else
        printf '\033[1;33m○ SKIP\033[0m (optional)\n'
        SKIP=$((SKIP + 1))
    fi
}

check_content() {
    local name="$1"
    local file="$2"
    local pattern="$3"
    printf "  %-30s" "$name ..."
    if [ -f "$file" ] && grep -qF "$pattern" "$file" 2>/dev/null; then
        printf '\033[1;32m✓ PASS\033[0m\n'
        PASS=$((PASS + 1))
    elif [ ! -f "$file" ]; then
        printf '\033[1;31m✗ FAIL\033[0m (file missing)\n'
        FAIL=$((FAIL + 1))
    else
        printf '\033[1;31m✗ FAIL\033[0m (pattern not found)\n'
        FAIL=$((FAIL + 1))
    fi
}

printf '\n'
printf '  ┌──────────────────────────────────────────────────┐\n'
printf '  │           DevToolkit Environment Verification            │\n'
printf '  └──────────────────────────────────────────────────┘\n'
printf '\n'

# --- WSL -------------------------------------------------------------------
printf '\033[1;36m[ WSL & System ]\033[0m\n'
check   "WSL detected"       "grep -qi microsoft /proc/version"
check   "Ubuntu version"     "lsb_release -ds 2>/dev/null || cat /etc/os-release 2>/dev/null | head -1"
check   "Architecture"       "uname -m"
check   "Kernel"             "uname -r"
check   "Locale"             "locale -a 2>/dev/null | grep en_US.utf8"
check   "unar"              "unar --version"

# --- Shell -----------------------------------------------------------------
printf '\n\033[1;36m[ Shell ]\033[0m\n'
check   "zsh"                "zsh --version"
check_opt "zsh is default"     "echo \$SHELL | grep -q /zsh"
check_opt "autosuggestions"  "ls ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
check_opt "syntax-highlight" "ls ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
check   "starship"           "starship --version"
check   ".zshrc linked"      "test -L ~/.zshrc && readlink ~/.zshrc | grep -q devtoolkit"
check   ".zshenv linked"     "test -L ~/.zshenv && readlink ~/.zshenv | grep -q devtoolkit"
check   "starship.toml"      "test -L ~/.config/starship.toml && readlink ~/.config/starship.toml | grep -q devtoolkit"

# --- Version Manager --------------------------------------------------------
printf '\n\033[1;36m[ Version Manager ]\033[0m\n'
check   "mise"               "$HOME/.local/bin/mise --version"
check   "mise config"        "test -f ~/.config/mise/config.toml"

# --- Python -----------------------------------------------------------------
printf '\n\033[1;36m[ Python ]\033[0m\n'
check   "uv"                 "uv --version"
check   "Python (uv)"        "uv python list 2>/dev/null | grep -q 3"
check_opt "Ruff"             "ruff --version"

# --- Dev Tools --------------------------------------------------------------
printf '\n\033[1;36m[ Dev Tools ]\033[0m\n'
check_opt "lazygit"          "lazygit --version"
check_opt "ripgrep"          "rg --version"
check_opt "fd"               "fd --version"
check_opt "fzf"              "fzf --version"
check_opt "bat"              "batcat --version || bat --version"
check_opt "delta"            "delta --version"
check_opt "difftastic"       "difft --version"
check_opt "tealdeer"         "tldr --version"
check_opt "gh"               "gh --version"

# --- Extras -----------------------------------------------------------------
printf '\n\033[1;36m[ Extras ]\033[0m\n'
check_opt "zoxide"           "zoxide --version"
check_opt "eza"              "eza --version"
check_opt "btop"             "btop --version"
check_opt "lazydocker"       "lazydocker --version"
check_opt "dust"             "dust --version"
check_opt "yazi"             "yazi --version"
check_opt "fastfetch"        "fastfetch --version"
check_opt "zellij"           "zellij --version"
check_opt "atuin"            "atuin --version"

# --- AI ---------------------------------------------------------------------
printf '\n\033[1;36m[ AI ]\033[0m\n'
check_opt "OpenCode"         "opencode --version"
check_opt "OpenCode config"  "test -d ~/.config/opencode"

# --- WSL Configs ------------------------------------------------------------
printf '\n\033[1;36m[ WSL Configs ]\033[0m\n'
check_opt "/etc/wsl.conf"          "test -f /etc/wsl.conf"
check_opt "wsl.conf: systemd"      "grep -q 'systemd=true' /etc/wsl.conf 2>/dev/null"
check_opt ".wslconfig exists"      "test -f /mnt/c/Users/*/'.wslconfig' 2>/dev/null"
check_opt ".wslconfig: mirrored"   "grep -q 'networkingMode=mirrored' /mnt/c/Users/*/'.wslconfig' 2>/dev/null"

# --- Dotfiles ---------------------------------------------------------------
printf '\n\033[1;36m[ Dotfiles ]\033[0m\n'
check   "gitconfig"          "test -f ~/.gitconfig"
check   "profile"            "test -f ~/.profile"
check_opt "gitignore_global" "test -f ~/.gitignore_global"

# --- PATH -------------------------------------------------------------------
printf '\n\033[1;36m[ PATH ]\033[0m\n'
check   ".local/bin in PATH"       "echo \$PATH | grep -qF .local/bin"

# --- Config Content -----------------------------------------------------------
printf '\n\033[1;36m[ Config Content ]\033[0m\n'
check_content "mise in .zshrc"       "$HOME/.zshrc"   'activate zsh'
check_content "starship in .zshrc"   "$HOME/.zshrc"   'eval "$(starship init zsh)"'
check_content "pyinit in .zshrc"     "$HOME/.zshrc"   'pyinit()'
check_content "mise [tools]"         "$HOME/.config/mise/config.toml"  '[tools]'
check_content "mise [settings]"      "$HOME/.config/mise/config.toml"  '[settings]'
check_content "uv mirror"            "$HOME/.config/uv/uv.toml"        'pypi.tuna.tsinghua.edu.cn'
check_content "difftastic in gitconfig" "$HOME/.gitconfig" '[difftool "difftastic"]'

# --- Version Freshness (optional, not counted) --------------------------------
printf '\n\033[1;36m[ Version Freshness ]\033[0m (vs GitHub latest)\n'

check_freshness() {
    local name="$1" installed="$2" repo="$3" strip_v="${4:-yes}"
    local latest
    printf "  %-30s" "$name ..."
    if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
        latest=$(gh api "repos/${repo}/releases/latest" --jq '.tag_name' 2>/dev/null) || true
    else
        latest=$(curl --proto '=https' --tlsv1.2 --connect-timeout 5 --max-time 10 -fsSL \
            "https://api.github.com/repos/${repo}/releases/latest" \
            | jq -r '.tag_name // empty' 2>/dev/null) || true
    fi
    if [ -z "$latest" ] || [ "$latest" = "null" ]; then
        printf '\033[1;33m○ SKIP\033[0m (API unreachable)\n'
        return
    fi
    [ "$strip_v" = "yes" ] && latest="${latest#v}"
    if [ "$installed" = "$latest" ]; then
        printf '\033[1;32m✓ %s\033[0m (current)\n' "$installed"
    else
        printf '\033[1;33m⚠ %s → %s\033[0m (update available)\n' "$installed" "$latest"
    fi
}

if command -v jq &>/dev/null; then
    check_freshness "starship"    "$(starship --version 2>/dev/null | head -1 | awk '{print $2}')"    "starship/starship"
    check_freshness "lazygit"     "$(lazygit --version 2>/dev/null | head -1 | grep -oP '(?<=, )version=\K[^,]+')" "jesseduffield/lazygit"
    check_freshness "delta"       "$(delta --version 2>/dev/null | head -1 | awk '{print $2}')"      "dandavison/delta"       "no"
    check_freshness "difftastic"  "$(difft --version 2>/dev/null | head -1 | awk '{print $2}')"      "Wilfred/difftastic"     "no"
    check_freshness "btop"        "$(btop --version 2>/dev/null | head -1 | sed 's/\x1b\[[0-9;]*m//g' | grep -oP 'version:\s*\K\S+')"       "aristocratos/btop"
    check_freshness "lazydocker"  "$(lazydocker --version 2>/dev/null | head -1 | grep -oP 'Version: \K[^ ]+')" "jesseduffield/lazydocker"
    check_freshness "dust"        "$(dust --version 2>/dev/null | head -1 | awk '{print $2}')"        "bootandy/dust"
    check_freshness "zellij"      "$(zellij --version 2>/dev/null | head -1 | awk '{print $2}')"     "zellij-org/zellij"
    check_freshness "yazi"        "$(yazi --version 2>/dev/null | head -1 | awk '{print $2}')"        "sxyazi/yazi"
    check_freshness "fastfetch"   "$(fastfetch --version 2>/dev/null | head -1 | awk '{print $2}')"  "fastfetch-cli/fastfetch" "no"
fi

# --- Summary ----------------------------------------------------------------
echo ""
echo "  ┌──────────────────────────────────────────────────┐"
printf   "  │  Results:  \033[1;32m%2d passed\033[0m  \033[1;31m%2d failed\033[0m  \033[1;33m%2d skipped\033[0m              │\n" "$PASS" "$FAIL" "$SKIP"
echo    "  └──────────────────────────────────────────────────┘"
echo ""

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
