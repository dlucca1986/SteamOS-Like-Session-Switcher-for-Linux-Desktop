#!/bin/bash
# =============================================================================
# SteamMachine-DIY Uninstaller
# Description: Completely removes the SteamOS-like environment.
# Repository: https://github.com/dlucca1986/SteamMachine-DIY
# =============================================================================

set -e

# --- Environment & Colors ---
export LANG=C
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Configuration Paths ---
HELPERS_SOURCE="/usr/local/bin/steamos-helpers"
HELPERS_LINKS="/usr/bin/steamos-polkit-helpers"
SDDM_CONF_DIR="/etc/sddm.conf.d"
SDDM_WAYLAND_CONF="$SDDM_CONF_DIR/10-wayland.conf"
SUDOERS_FILE="/etc/sudoers.d/steamos-switcher"
AUTOLOGIN_CONF="$SDDM_CONF_DIR/zz-steamos-autologin.conf"
SESSIONS_DIR="/usr/share/wayland-sessions"
DATA_DIR="/usr/share/steamos-switcher"
PACMAN_HOOK="/etc/pacman.d/hooks/gamescope-capabilities.hook"

# --- User Config Path ---
USER_CONFIG_DIR="$HOME/.config/steamos-diy"
LOG_FILE="/tmp/steamos-diy.log"

# --- UI Functions ---
info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- Logic Functions ---

remove_scripts() {
    info "Removing core binaries and helper scripts..."
    
    # Core Binaries
    local core_bins=(os-session-select set-sddm-session steamos-session-launch steamos-session-select)
    for bin in "${core_bins[@]}"; do
        if [ -f "/usr/local/bin/$bin" ]; then
            sudo rm -f "/usr/local/bin/$bin"
            info "Removed /usr/local/bin/$bin"
        fi
    done

    # Helpers and Symlinks
    # Removing compatibility symlinks directory
    if [ -d "$HELPERS_LINKS" ]; then
        sudo rm -rf "$HELPERS_LINKS"
        info "Removed compatibility symlinks directory ($HELPERS_LINKS)."
    fi

    # Removing helper source directory
    if [ -d "$HELPERS_SOURCE" ]; then
        sudo rm -rf "$HELPERS_SOURCE"
        info "Removed helper source directory ($HELPERS_SOURCE)."
    fi

    # Desktop Entries & Data
    # Cleanup of session entry and data directory
    if [ -f "$SESSIONS_DIR/steamos-switcher.desktop" ]; then
        sudo rm -f "$SESSIONS_DIR/steamos-switcher.desktop"
        info "Removed SDDM session entry."
    fi

    if [ -d "$DATA_DIR" ]; then
        sudo rm -rf "$DATA_DIR"
        info "Removed data directory $DATA_DIR"
    fi

    # Remove the user desktop shortcut if present
    if [ -f "$HOME/Desktop/GameMode.desktop" ]; then
        rm -f "$HOME/Desktop/GameMode.desktop"
        info "Removed Desktop shortcut."
    fi
}

remove_user_configs() {
    info "Checking for user-specific configurations..."
    
    if [ -d "$USER_CONFIG_DIR" ]; then
        warn "Found user config directory: $USER_CONFIG_DIR"
        read -p "Do you want to delete your custom settings (resolution, HDR, etc.)? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$USER_CONFIG_DIR"
            success "User configurations removed."
        else
            info "User configurations preserved."
        fi
    fi

    if [ -f "$LOG_FILE" ]; then
        rm -f "$LOG_FILE"
        info "Cleaned session logs from /tmp"
    fi
}

remove_security_configs() {
    info "Reverting security policies..."
    if [ -f "$SUDOERS_FILE" ]; then
        sudo rm -f "$SUDOERS_FILE"
        success "Sudoers policy removed."
    fi
}

remove_sddm_configs() {
    info "Reverting SDDM configurations..."
    
    if [ -f "$SDDM_WAYLAND_CONF" ]; then
        sudo rm -f "$SDDM_WAYLAND_CONF"
        success "SDDM Wayland tweaks removed."
    fi

    if [ -f "$AUTOLOGIN_CONF" ]; then
        sudo rm -f "$AUTOLOGIN_CONF"
        success "Autologin overrides removed."
    fi
    
    # SDDM State cleanup (restoring Plasma as default session)
    if [ -f "/var/lib/sddm/state.conf" ]; then
        info "Resetting SDDM last session state..."
        sudo sed -i 's/Session=.*/Session=plasma/' /var/lib/sddm/state.conf 2>/dev/null || true
    fi
}

revert_performance_tweaks() {
    info "Reverting Gamescope performance tweaks..."
    
    # 1. Remove Pacman Hook
    if [ -f "$PACMAN_HOOK" ]; then
        sudo rm -f "$PACMAN_HOOK"
        info "Removed Gamescope Pacman hook."
    fi

    # 2. Remove File Capabilities from binary
    local gpath
    gpath=$(command -v gamescope)
    if [ -x "$gpath" ]; then
        if command -v getcap >/dev/null && getcap "$gpath" | grep -q 'cap_'; then
            sudo setcap -r "$gpath"
            success "Capabilities removed from $gpath"
        fi
    fi
}

# --- Main Execution ---
clear
echo -e "${BLUE}==========================================${NC}"
echo -e "${RED}    SteamMachine DIY - Uninstaller${NC}"
echo -e "${BLUE}==========================================${NC}"
echo
warn "This action will completely remove the SteamOS session logic."
read -p "Are you sure you want to proceed? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Uninstallation aborted."
    exit 0
fi

remove_scripts
remove_user_configs
remove_security_configs
remove_sddm_configs
revert_performance_tweaks

echo
success "Uninstallation completed successfully!"
info "KDE Plasma and SDDM have been restored to default behavior."
info "A system reboot is recommended to ensure all changes take effect."
