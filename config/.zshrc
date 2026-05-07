# =============================================================================
# .zshrc — devtoolkit main shell configuration
# =============================================================================
# Load order:
#   1. .zshenv (env vars, sourced for ALL zsh instances)
#   2. .zshrc  → this file → PATH → mise → compinit → tools → prompt → plugins
#
#   Rule: compinit first, then tools that add completions (zoxide, atuin, fzf),
#         then prompt (starship), then plugins (syntax-highlighting last).
# =============================================================================

# --- always start in ~/projects (override Windows inherited cwd) --------------
cd ~/projects 2>/dev/null || cd ~

# --- environment (EDITOR, VISUAL, STARSHIP_CONFIG → see .zshenv) -------------

# --- PATH -------------------------------------------------------------------
export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"
# VS Code (Windows) - symlink binaries into ~/.local/bin to avoid spaces in PATH
# Idempotent per-shell check: only runs if code symlink is missing or broken
if [[ ! -x "$HOME/.local/bin/code" ]]; then
    # Scan /mnt/c/Users/* for VS Code installation (avoids forking cmd.exe)
    for _vscode in /mnt/c/Users/*/AppData/Local/Programs/Microsoft\ VS\ Code/bin/code(N); do
        for _bin in "$_vscode:h"/*(N); do
            [[ -x "$_bin" && ! -d "$_bin" ]] && ln -sf "$_bin" "$HOME/.local/bin/${_bin:t}" 2>/dev/null
        done
    done 2>/dev/null
fi

# --- mise (polyglot version manager, cached for fast startup) ---------------
# Cache the activation script to avoid forking a subprocess on every shell start.
# Regenerates automatically when mise binary or config is updated.
_MISE_CACHE="$HOME/.cache/mise-activate.zsh"
_MISE_BIN="$HOME/.local/bin/mise"
_MISE_CFG="$HOME/.config/mise/config.toml"
if [[ ! -f "$_MISE_CACHE" ]] || \
   [[ -n "$(find "$_MISE_BIN" "$_MISE_CFG" -newer "$_MISE_CACHE" 2>/dev/null | head -1)" ]]; then
    mkdir -p "$(dirname "$_MISE_CACHE")"
    "$_MISE_BIN" activate zsh > "$_MISE_CACHE" 2>/dev/null
fi
source "$_MISE_CACHE"

# --- completion (must come before tools that add completions) ----------------
autoload -Uz compinit && compinit -C
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# --- history settings -------------------------------------------------------
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="$HOME/.zsh_history"
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY

# --- zoxide (smarter cd, adds completions after compinit) -------------------
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi

# --- atuin (shell history, must be after compinit per official docs) ---------
if command -v atuin &>/dev/null; then
    eval "$(atuin init zsh)"
fi

# --- key bindings -----------------------------------------------------------
bindkey -e                                          # emacs mode
bindkey '^ ' autosuggest-accept                     # Ctrl+Space: accept suggestion
bindkey '^[[Z' reverse-menu-complete                # Shift+Tab: reverse complete

# ===========================================================================
# ALIASES
# ===========================================================================

# --- navigation ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# --- safety ---
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias mkdir='mkdir -pv'

# --- list (eza if installed, else ls) ---
if command -v eza &>/dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first --git'
    alias la='eza -la --icons --group-directories-first --git'
    alias lt='eza --tree --level=2 --icons'
    alias lta='eza --tree --icons -a'
else
    alias ls='ls --color=auto -h'
    alias ll='ls --color=auto -lh'
    alias la='ls --color=auto -lAh'
fi

# --- git ---
alias g='git'
alias ga='git add'
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias lg='lazygit'

# --- modern replacements ---
command -v rg &>/dev/null && alias grep='rg'
alias find='fd'
alias cat='bat --paging=never'
alias top='btop'

# --- uv ---
alias uvr='uv run'
alias uva='uv add'
alias uvs='uv sync'

# --- mise ---
alias mx='mise exec'
alias mi='mise install'
alias ml='mise list'

# --- docker (if installed) ---
if command -v docker &>/dev/null; then
    alias d='docker'
    alias dc='docker compose'
    alias dps='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
    alias ld='lazydocker'
fi

# --- system ---
alias ip='ip -color'
alias ports='ss -tlnp'
alias reload='exec zsh'
alias update='sudo apt update && sudo apt upgrade -y'
alias cleanup='sudo apt autoremove -y && sudo apt autoclean'
alias du='dust'
alias df='df -h'

# ===========================================================================
# FUNCTIONS
# ===========================================================================

# Quick Python project init with uv + mise venv auto-activation
pyinit() {
    local project_name="${1:-.}"
    log() { printf '\033[1;34m[INFO]\033[0m  %s\n' "$*"; }

    if [ "$project_name" != "." ]; then
        mkdir -p "$project_name" && cd "$project_name" || return 1
    fi

    if ! grep -qF 'mise activate zsh' ~/.zshrc 2>/dev/null; then
        log "Adding mise activation to ~/.zshrc..."
        echo 'eval "$(~/.local/bin/mise activate zsh)"' >> ~/.zshrc
    fi

    if [ ! -f mise.toml ] || ! grep -q "_.python.venv" mise.toml 2>/dev/null; then
        if [ -f mise.toml ]; then
            echo -e "\n[env]\n_.python.venv = { path = \".venv\", create = true }" >> mise.toml
        else
            echo -e "[env]\n_.python.venv = { path = \".venv\", create = true }" > mise.toml
        fi
        log "mise.toml created with venv auto-activation."
    fi

    echo "✅  Done! cd back and forth to auto-activate the venv."
    echo "    Then: uv init && uv add <packages>"
}

# Make a directory and cd into it
mkcd() { mkdir -pv "$@" && cd "$@"; }

# Extract common archives
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1"   ;;
            *.tar.gz)  tar xzf "$1"   ;;
            *.tar.xz)  tar xJf "$1"   ;;
            *.bz2)     bunzip2 "$1"   ;;
            *.gz)      gunzip "$1"    ;;
            *.tar)     tar xf "$1"    ;;
            *.tbz2)    tar xjf "$1"   ;;
            *.tgz)     tar xzf "$1"   ;;
            *.zip)     unzip "$1"     ;;
            *.7z)      7z x "$1"      ;;
            *.rar)     unrar x "$1"   ;;
            *)         echo "Unknown format: $1" ;;
        esac
    else
        echo "Not a file: $1"
    fi
}

# ===========================================================================
# FZF
# ===========================================================================
if command -v fzf &>/dev/null; then
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    # fzf --zsh available since 0.48.0; falls back gracefully on older versions
    if fzf --zsh &>/dev/null 2>&1; then
        eval "$(fzf --zsh)"
    fi
fi

# ===========================================================================
# PROMPT
# ===========================================================================

# --- secrets (optional — create ~/.env_secrets with chmod 600) ---------------
# Uncomment if you store API keys separately:
[ -f ~/.env_secrets ] && source ~/.env_secrets

# --- starship prompt --------------------------------------------------------
eval "$(starship init zsh)"

# ===========================================================================
# PLUGINS (manual, no oh-my-zsh)
# ===========================================================================

# zsh-autosuggestions
if [ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
fi

# zsh-syntax-highlighting (MUST be last — official docs requirement)
if [ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# --- fastfetch (system info on shell start, uncomment to enable) --------------
# fastfetch

. "$HOME/.atuin/bin/env"

# opencode
export PATH="$HOME/.opencode/bin:$PATH"
typeset -U path                                    # deduplicate PATH (must be after all PATH mods)
path=( ${path:#*/games*} )                         # remove games dirs (WSL doesn't need them)

# --- mise internal vars cleanup (safe to unset, not needed at runtime) ------
unset __MISE_DIFF __MISE_ORIG_PATH __MISE_SESSION 2>/dev/null

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
