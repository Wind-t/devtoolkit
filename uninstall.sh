#!/usr/bin/env bash
# =============================================================================
# uninstall.sh — remove devtoolkit-managed files
# =============================================================================
# Safe: prompts before any destructive action.
# Usage: bash uninstall.sh [--all]
#   --all   Also remove ~/.local/bin binaries (requires confirmation)
# =============================================================================
set -euo pipefail

ALL_MODE=false
[[ "${1:-}" == "--all" ]] && ALL_MODE=true

red()    { printf '\033[1;31m%s\033[0m\n' "$*"; }
green()  { printf '\033[1;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[1;33m%s\033[0m\n' "$*"; }

echo ""
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║         devtoolkit Uninstall                         ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo ""

# --- Step 1: Unlink dotfiles ------------------------------------------------
echo "Step 1: Unlinking dotfiles..."
COUNT=0
for dst in \
    "$HOME/.zshrc" \
    "$HOME/.zshenv" \
    "$HOME/.profile" \
    "$HOME/.gitconfig" \
    "$HOME/.gitignore_global" \
    "$HOME/.config/starship.toml" \
    "$HOME/.config/mise/config.toml"; do
    if [ -L "$dst" ]; then
        target=$(readlink "$dst")
        if echo "$target" | grep -q devtoolkit; then
            rm "$dst"
            green "  ✓ removed: $dst"
            COUNT=$((COUNT + 1))
        else
            yellow "  ⚠ skipping (not devtoolkit): $dst → $target"
        fi
    elif [ -f "$dst" ]; then
        yellow "  ⚠ skipping (regular file): $dst"
    fi
done
echo "  Unlinked $COUNT dotfiles."

# --- Step 2: Clean oh-my-zsh residue -----------------------------------------
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo ""
    echo "Step 2: Found ~/.oh-my-zsh (likely pre-devtoolkit residue)."
    echo "  This is NOT managed by devtoolkit but may conflict."
    read -rp "  Remove ~/.oh-my-zsh? [y/N] " yn
    if [[ "$yn" =~ ^[Yy]$ ]]; then
        rm -rf "$HOME/.oh-my-zsh"
        green "  ✓ removed ~/.oh-my-zsh"
    else
        yellow "  ⚠ kept ~/.oh-my-zsh"
    fi
fi

# --- Step 3: Remove ~/.local/bin binaries (--all only) -----------------------
if $ALL_MODE; then
    echo ""
    echo "Step 3: ~/.local/bin contains:"
    ls -1 "$HOME/.local/bin" 2>/dev/null | sed 's/^/    /' || echo "    (empty)"
    echo ""
    red "  WARNING: This will remove ALL binaries in ~/.local/bin."
    echo "  Some may have been installed outside of devtoolkit."
    read -rp "  Proceed? Type 'yes' to confirm: " yn
    if [ "$yn" = "yes" ]; then
        rm -rf "$HOME/.local/bin"/*
        green "  ✓ cleared ~/.local/bin"
    else
        yellow "  ⚠ kept ~/.local/bin"
    fi
else
    echo ""
    echo "  (use --all to also remove ~/.local/bin binaries)"
fi

# --- Step 4: Remove mise cache -----------------------------------------------
if [ -f "$HOME/.cache/mise-activate.zsh" ]; then
    rm "$HOME/.cache/mise-activate.zsh"
    green "  ✓ removed mise activation cache"
fi

# --- Done -------------------------------------------------------------------
echo ""
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║  Uninstall complete.                                 ║"
echo "  ║                                                      ║"
echo "  ║  Optional manual cleanup:                            ║"
echo "  ║    rm -rf ~/.local/share/mise   (mise installs)      ║"
echo "  ║    rm -rf ~/.local/share/uv     (uv installs)        ║"
echo "  ║    rm -rf ~/.cache              (tool caches)        ║"
echo "  ║    sudo apt remove <packages>   (apt packages)       ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo ""
