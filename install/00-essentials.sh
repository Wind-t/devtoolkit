#!/usr/bin/env bash
# =============================================================================
# 00-essentials.sh — apt mirror + base packages
# =============================================================================
# Sources: https://learn.microsoft.com/en-us/windows/wsl/
#          https://mirrors.aliyun.com/ubuntu/
# =============================================================================
set -euo pipefail

log()   { printf '\033[1;34m[INFO]\033[0m  "%s"\n' "$*"; }
success(){ printf '\033[1;32m[OK]\033[0m    "%s"\n' "$*"; }

# --- Ubuntu apt mirror (Aliyun, for China users) ---------------------------
if [ "${SKIP_APT_MIRROR:-0}" = "1" ]; then
    log "SKIP_APT_MIRROR=1, keeping default apt sources."
else
    log "Setting apt mirror to Aliyun (set SKIP_APT_MIRROR=1 to skip)..."
    if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
        # Ubuntu 24.04+ deb822 format
        for uri in "http://archive.ubuntu.com" "https://archive.ubuntu.com" \
                   "http://security.ubuntu.com" "https://security.ubuntu.com" \
                   "http://ports.ubuntu.com" "https://ports.ubuntu.com"; do
            sudo sed -i "s|${uri}|http://mirrors.aliyun.com|g" \
                /etc/apt/sources.list.d/ubuntu.sources
        done
    elif [ -f /etc/apt/sources.list ]; then
        # Legacy format
        for uri in "http://archive.ubuntu.com" "https://archive.ubuntu.com" \
                   "http://security.ubuntu.com" "https://security.ubuntu.com" \
                   "http://ports.ubuntu.com" "https://ports.ubuntu.com"; do
            sudo sed -i "s|${uri}|http://mirrors.aliyun.com|g" \
                /etc/apt/sources.list
        done
    fi
fi

log "Updating package lists..."
sudo apt update -qq

# --- base packages ----------------------------------------------------------
log "Installing base build tools and dependencies..."
sudo apt install -y -qq \
    build-essential \
    curl \
    wget \
    git \
    unzip \
    zip \
    unar \
    jq \
    tree \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    locales \
    xdg-utils

# --- locale -----------------------------------------------------------------
log "Setting locale to en_US.UTF-8..."
sudo locale-gen en_US.UTF-8 > /dev/null 2>&1 || log "Locale en_US.UTF-8 generation failed (non-critical)."
sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 2>/dev/null || true

success "Base system packages installed."
