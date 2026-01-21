#!/bin/bash
# =============================================================================
# SteamMachine-DIY Installer
# Description: Configures Arch Linux to behave like SteamOS (Gaming Mode/Desktop)
# Repository: https://github.com/dlucca1986/SteamMachine-DIY
# =============================================================================

set -e

# --- Environment & Colors ---
export LANG=C
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Configuration Paths ---
HELPERS_SOURCE="/usr/local/bin/steamos-helpers"
HELPERS_LINKS="/usr/bin/steamos-polkit-helpers"
SDDM_CONF_DIR="/etc/sddm.conf.d"
SDDM_WAYLAND_CONF="$SDDM_CONF_DIR/10-wayland.conf"
SUDOERS_FILE="/etc/sudoers.d/steamos-switcher"
SESSIONS_DIR="/usr/share/wayland-sessions"
DATA_DIR="/usr/share/steamos-switcher"

# --- User Config Path ---
USER_CONFIG_DIR="$HOME/.config/steamos-diy"
USER_CONFIG_FILE="$USER_CONFIG_DIR/config"
USER_README_FILE="$USER_CONFIG_DIR/README_PARAMETERS.txt"

DEPENDENCIES=(
    steam gamescope mangohud lib32-mangohud gamemode 
    vulkan-icd-loader lib32-vulkan-icd-loader 
    vulkan-radeon lib32-vulkan-radeon
)

# --- UI Functions ---
info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()    { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- Logic Functions ---

check_multilib() {
    info "Checking multilib repository..."
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        warn "Multilib repository is disabled. Enabling..."
        sudo sed -i '/^#\[multilib\]/,+1 s/^#//' /etc/pacman.conf
        sudo pacman -Sy
        success "Multilib enabled."
    else
        success "Multilib is already enabled."
    fi
}

install_dependencies() {
    info "Verifying system dependencies..."
    local missing_pkgs=()
    for pkg in "${DEPENDENCIES[@]}"; do
        if ! pacman -Qi "$pkg" &> /dev/null; then
            missing_pkgs+=("$pkg")
        fi
    done

    if [ ${#missing_pkgs[@]} -ne 0 ]; then
        warn "Missing packages: ${missing_pkgs[*]}"
        read -p "Do you want to install them now? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo pacman -S --needed "${missing_pkgs[@]}"
        else
            error "Dependencies not met. Installation aborted."
        fi
    fi
    success "All dependencies satisfied."
}

setup_directories() {
    info "Creating system directories..."
    sudo mkdir -p "$HELPERS_SOURCE" "$SDDM_CONF_DIR" "$SESSIONS_DIR" "$DATA_DIR"
    sudo mkdir -p "$HELPERS_LINKS" # For polkit compatibility symlinks
}

setup_user_config() {
    info "Setting up user configuration in $USER_CONFIG_DIR..."
    mkdir -p "$USER_CONFIG_DIR"

    # Create README_PARAMETERS.txt
    cat << 'EOF' > "$USER_README_FILE"
===========================================================
           STEAM MACHINE DIY - PARAMETERS GUIDE
===========================================================

You can modify the 'config' file with the following values:

BASE VALUES:
- TARGET_WIDTH     : Horizontal resolution (e.g., 1920, 1280, 2560)
- TARGET_HEIGHT    : Vertical resolution (e.g., 1080, 720, 1440)
- REFRESH_RATE     : Frequency in Hz (e.g., 60, 120, 144)

TOGGLES (1 = On, 0 = Off):
- ENABLE_HDR       : Enable HDR (Requires compatible monitor)
- ENABLE_VRR       : Enable Variable Refresh Rate (FreeSync/G-Sync)
- ENABLE_MANGOAPP  : Enable the Steam performance overlay

POWER USERS:
- CUSTOM_ARGS      : Insert additional Gamescope flags within quotes.
                     Example: CUSTOM_ARGS="--upscaler fsr --fsr-sharpness 5"

-----------------------------------------------------------
NOTE: In case of a critical error, the file will be renamed 
to 'config.broken' and the system will start at 720p/60Hz 
to allow you to fix the parameters.
===========================================================
EOF

    # Create initial config only if it doesn't exist
    if [ ! -f "$USER_CONFIG_FILE" ]; then
        cat << EOF > "$USER_CONFIG_FILE"
# SteamMachine-DIY User Configuration
# Check README_PARAMETERS.txt for help

TARGET_WIDTH=1920
TARGET_HEIGHT=1080
REFRESH_RATE=60
ENABLE_HDR=0
ENABLE_VRR=0
ENABLE_MANGOAPP=1
CUSTOM_ARGS=""
EOF
        success "Default config created at $USER_CONFIG_FILE"
    else
        info "Existing config found, skipping overwrite."
    fi
}

deploy_scripts() {
    info "Deploying core binaries and helpers..."
    
    # Core Binaries
    local core_bins=(os-session-select set-sddm-session steamos-session-launch steamos-session-select)
    for bin in "${core_bins[@]}"; do
        if [ -f "$bin" ]; then
            sudo cp "$bin" /usr/local/bin/
            sudo chmod +x "/usr/local/bin/$bin"
        fi
    done
    
    # Helpers
    local helper_scripts=(jupiter-biosupdate steamos-select-branch steamos-set-timezone steamos-update steamos-select-session)
    for helper in "${helper_scripts[@]}"; do
        if [ -f "$helper" ]; then
            sudo cp "$helper" "$HELPERS_SOURCE/"
            sudo chmod +x "$HELPERS_SOURCE/$helper"
            # Compatibility Symlinks
            sudo ln -sf "$HELPERS_SOURCE/$helper" "$HELPERS_LINKS/$helper"
        fi
    done

    # Desktop Entries
    if [ -f "steamos-switcher.desktop" ]; then
        sudo cp "steamos-switcher.desktop" "$SESSIONS_DIR/"
    fi
}

configure_security() {
    info "Configuring Sudoers policies..."
    local temp_sudo=$(mktemp)
    cat <<EOF > "$temp_sudo"
# SteamMachine DIY - Session Switcher Permissions
ALL ALL=(ALL) NOPASSWD: /usr/local/bin/set-sddm-session
ALL ALL=(ALL) NOPASSWD: /usr/local/bin/steamos-session-select
EOF
    if visudo -cf "$temp_sudo"; then
        sudo cp "$temp_sudo" "$SUDOERS_FILE"
        sudo chmod 440 "$SUDOERS_FILE"
    else
        error "Sudoers validation failed."
    fi
    rm "$temp_sudo"
}

configure_sddm() {
    info "Applying SDDM Wayland tweaks..."
    sudo tee "$SDDM_WAYLAND_CONF" > /dev/null <<EOF
[General]
# Force SDDM to use Wayland to prevent conflicts with X11 sockets (e.g., :0)
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Wayland]
# Optimized for KDE Plasma 6
CompositorCommand=kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale POSIX --inputmethod maliit
EOF
}

optimize_performance() {
    info "Optimizing Gamescope performance capabilities..."
    local gpath
    gpath=$(command -v gamescope)
    if [ -x "$gpath" ]; then
        sudo setcap 'cap_sys_admin,cap_sys_nice,cap_ipc_lock+ep' "$gpath"
        success "Capabilities assigned to $gpath"
    else
        warn "Gamescope binary not found, skipping setcap."
    fi
}

setup_pacman_hook() {
    info "Setting up Pacman Hook for Gamescope capabilities..."
    sudo mkdir -p /etc/pacman.d/hooks
    sudo tee /etc/pacman.d/hooks/gamescope-capabilities.hook > /dev/null <<EOF
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = gamescope

[Action]
Description = Restoring Gamescope capabilities after update...
When = PostTransaction
Exec = /usr/bin/setcap 'cap_sys_admin,cap_sys_nice,cap_ipc_lock+ep' /usr/bin/gamescope
EOF
}

# --- Main Execution ---
clear
echo -e "${BLUE}==========================================${NC}"
echo -e "${GREEN}    SteamMachine DIY - Installer${NC}"
echo -e "${BLUE}==========================================${NC}"
echo

check_multilib
install_dependencies
setup_directories
setup_user_config
deploy_scripts
configure_security
configure_sddm
optimize_performance
setup_pacman_hook

echo
success "Installation completed successfully!"
info "User config: $USER_CONFIG_FILE"
info "Note: You might need to restart SDDM or reboot to apply all changes."
