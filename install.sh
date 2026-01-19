#!/bin/bash
# ==============================================================================
# SteamOS Session Switcher - Professional Installation Script
# Target OS: Arch Linux / SteamOS-like distributions
# Optimized for: AMD GPU (Mesa/Vulkan)
# ==============================================================================
set -e

# --- GLOBAL CONFIGURATION ---
SUDOERS_FILE="/etc/sudoers.d/steamos-switcher"
HELPERS_DIR="/usr/local/bin/steamos-helpers"
SDDM_CONF_DIR="/etc/sddm.conf.d"
SDDM_WAYLAND_CONF="$SDDM_CONF_DIR/10-wayland.conf"

# --- CORE FUNCTIONS ---

# Abilita il repository multilib se necessario
enable_multilib() {
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        echo "    📦 Enabling multilib repository..."
        sudo sed -i '/^#\[multilib\]/,+1 s/^#//' /etc/pacman.conf
        sudo pacman -Sy
    else
        echo "    ✅ Multilib repository is already enabled."
    fi
}

check_and_install() {
    local PKG_LIST=("$@")
    local MISSING_PKGS=()
    for pkg in "${PKG_LIST[@]}"; do
        if ! pacman -Qi "$pkg" &> /dev/null; then MISSING_PKGS+=("$pkg"); fi
    done
    if [ ${#MISSING_PKGS[@]} -ne 0 ]; then
        echo "    📦 Installing missing dependencies: ${MISSING_PKGS[*]}..."
        sudo pacman -S --noconfirm "${MISSING_PKGS[@]}"
    fi
}

# --- INSTALLATION OVERVIEW ---
clear
echo "===================================================="
echo "      STEAMOS SESSION SWITCHER - INSTALLER         "
echo "===================================================="
echo "  This script will configure your system for a      "
echo "  seamless Gaming Mode / Desktop Mode transition.   "
echo "----------------------------------------------------"

# 1. REPOSITORY & ENVIRONMENT VALIDATION
echo "[1/7] Validating system repositories and environment..."
enable_multilib

# Definiamo i pacchetti core e le librerie 32-bit necessarie (multilib)
check_and_install steam gamescope mangohud gamemode vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader

# 2. SYSTEM STRUCTURE
echo "[2/7] Initializing system directories..."
sudo mkdir -p "$HELPERS_DIR"
sudo mkdir -p "$SDDM_CONF_DIR"
sudo mkdir -p /usr/bin/steamos-polkit-helpers

# 3. COMPONENT DEPLOYMENT
echo "[3/7] Deploying core components to $HELPERS_DIR..."
sudo cp os-session-select set-sddm-session steamos-session-launch \
        steamos-session-select steamos-update jupiter-biosupdate \
        steamos-select-branch steamos-set-timezone \
        steamos-select-session "$HELPERS_DIR/"

sudo chmod +x "$HELPERS_DIR"/*

# 4. SYSTEM INTEGRATION (SYMLINKS)
echo "[4/7] Creating global symbolic links..."
sudo ln -sf "$HELPERS_DIR/os-session-select" /usr/bin/os-session-select
sudo ln -sf "$HELPERS_DIR/steamos-update" /usr/bin/steamos-update
sudo ln -sf "$HELPERS_DIR/jupiter-biosupdate" /usr/bin/jupiter-biosupdate
sudo ln -sf "$HELPERS_DIR/steamos-select-branch" /usr/bin/steamos-select-branch
sudo ln -sf "$HELPERS_DIR/steamos-select-session" /usr/bin/steamos-select-session
sudo ln -sf "$HELPERS_DIR/steamos-set-timezone" /usr/bin/steamos-set-timezone

# 5. PRIVILEGED ACCESS CONFIGURATION (SUDOERS)
echo "[5/7] Configuring security policies (Sudoers)..."
SUDOERS_TEMP=$(mktemp)
cat <<EOF > "$SUDOERS_TEMP"
# SteamOS Switcher - Minimum required permissions for session switching
ALL ALL=(ALL) NOPASSWD: $HELPERS_DIR/set-sddm-session
ALL ALL=(ALL) NOPASSWD: $HELPERS_DIR/steamos-session-select
EOF

if visudo -cf "$SUDOERS_TEMP"; then
    sudo cp "$SUDOERS_TEMP" "$SUDOERS_FILE"
    sudo chmod 440 "$SUDOERS_FILE"
    echo "    ✅ Security policies applied successfully."
else
    echo "    ❌ ERROR: Security policy validation failed."
    exit 1
fi
rm "$SUDOERS_TEMP"

# 6. DISPLAY MANAGER CONFIGURATION (SDDM)
echo "[6/7] Applying Display Manager tweaks..."
sudo tee "$SDDM_WAYLAND_CONF" > /dev/null <<EOF
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Wayland]
CompositorCommand=kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale POSIX --inputmethod maliit
EOF

# 7. PERFORMANCE OPTIMIZATION
echo "[7/7] Applying performance capabilities..."
if command -v gamescope &> /dev/null; then
    sudo setcap 'cap_sys_admin,cap_sys_nice,cap_ipc_lock+ep' $(which gamescope)
    echo "    ✅ Gamescope capabilities optimized."
fi

echo "----------------------------------------------------"
echo "  ✅ INSTALLATION COMPLETED SUCCESSFULLY!           "
echo "  A system reboot is required to apply changes.     "
echo "----------------------------------------------------"
