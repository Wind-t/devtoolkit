#!/usr/bin/env bash
# =============================================================================
# lib/common.sh — shared helpers for all devtoolkit scripts
# =============================================================================
# Source this file from any install script or bootstrap.sh:
#   SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
#   source "$SCRIPT_DIR/../lib/common.sh"    # from install/
#   source "$SCRIPT_DIR/lib/common.sh"       # from bootstrap.sh
# =============================================================================

# --- logging ----------------------------------------------------------------
log()     { printf '\033[1;34m[INFO]\033[0m  "%s"\n' "$*"; }
success() { printf '\033[1;32m[OK]\033[0m    "%s"\n' "$*"; }
warn()    { printf '\033[1;33m[WARN]\033[0m  "%s"\n' "$*"; }
fail()    { printf '\033[1;31m[FAIL]\033[0m  "%s"\n' "$*"; exit 1; }

section() {
    printf '\n\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n'
    printf '\033[1;36m  %s\033[0m\n' "$*"
    printf '\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n'
}

# --- system checks ----------------------------------------------------------
is_wsl() { grep -qi microsoft /proc/version 2>/dev/null; }

get_arch() {
    case "$(uname -m)" in
        x86_64)  echo "x86_64" ;;
        aarch64) echo "arm64" ;;
        *)       echo "unknown" ;;
    esac
}

# --- network ----------------------------------------------------------------
# Standard curl wrapper with security defaults and retry
safe_curl() {
    curl --proto '=https' --tlsv1.2 --connect-timeout 10 --max-time 60 \
         --retry 2 --retry-delay 5 -fsSL "$@"
}

# Fetch latest GitHub release tag with fallback
github_latest_tag() {
    local repo="$1" fallback="${2:-}"
    local tag
    tag=$(safe_curl --max-time 15 "https://api.github.com/repos/${repo}/releases/latest" \
        2>/dev/null | jq -r '.tag_name // empty' 2>/dev/null) || true
    if [ -n "$tag" ] && [ "$tag" != "null" ]; then
        echo "$tag"
    elif [ -n "$fallback" ]; then
        echo "$fallback"
    fi
}

# --- dependency guard -------------------------------------------------------
require_jq() {
    if ! command -v jq &>/dev/null; then
        echo "[ERROR] jq is required but not installed. Run 00-essentials.sh first." >&2
        exit 1
    fi
}
