#!/bin/bash
# ==============================================================================
# SteamOS Switcher - Professional Installer (Full AMD Optimized)
# ==============================================================================
set -e

# --- CONFIGURATION ---
SUDOERS_FILE="/etc/sudoers.d/steamos-switcher"
SDDM_CONF_DIR="/etc/sddm.conf.d"
SDDM_WAYLAND_CONF="$SDDM_CONF_DIR/10-wayland.conf"

# --- FUNCTIONS ---

# Function to check and install packages
check_and_install() {
    local PKG_LIST=("$@")
    local MISSING_PKGS=()

    for pkg in "${PKG_LIST[@]}"; do
        if ! pacman -Qi "$pkg" &> /dev/null; then
            MISSING_PKGS+=("$pkg")
        fi
    done

    if [ ${#MISSING_PKGS[@]} -eq 0 ]; then
        echo "    ✅ Check OK: ${PKG_LIST[*]}"
    else
        echo "    ⚠️ Missing packages: ${MISSING_PKGS[*]}"
        read -p "    Do you want to install them now? [Y/n]: " choice
        choice=${choice:-Y}
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            sudo pacman -S --noconfirm "${MISSING_PKGS[@]}"
        else
            echo "    ❌ Installation aborted. These packages are required."
            exit 1
        fi
    fi
}

# --- WELCOME ---
clear
echo "------------------------------------------------"
echo "    Welcome to SteamOS Switcher Installer! 🚀   "
echo "      Optimized for Full AMD Builds             "
echo "------------------------------------------------"

# 1. HARDWARE COMPATIBILITY CHECK
echo "[1/8] Verifying Hardware Compatibility..."
GPU_INFO=$(lspci | grep -i 'vga\|display' | grep -i 'AMD\|Radeon' || true)

if [ -n "$GPU_INFO" ]; then
    echo "    ✅ AMD GPU detected: $GPU_INFO"
else
    echo "    ------------------------------------------------"
    echo "    ⚠️  WARNING: No AMD GPU detected!"
    echo "    This project is engineered for AMD (Mesa/RADV)."
    echo "    ------------------------------------------------"
    read -p "    Do you want to proceed anyway? [y/N]: " gpu_choice
    gpu_choice=${gpu_choice:-N}
    if [[ ! "$gpu_choice" =~ ^[Yy]$ ]]; then
        echo "    ❌ Installation aborted by user."
        exit 1
    fi
fi

# 2. PREREQUISITES CHECK
echo "[2/8] Checking Software Prerequisites..."
check_and_install steam gamescope mangohud lib32-mangohud gamemode vulkan-icd-loader lib32-vulkan-icd-loader vulkan-radeon lib32-vulkan-radeon

# 3. PREPARING DIRECTORIES
echo "[3/8] Preparing system directories..."
sudo mkdir -p /usr/bin/steamos-polkit-helpers
sudo mkdir -p /usr/local/bin
sudo mkdir -p /usr/share/wayland-sessions
sudo mkdir -p /usr/share/steamos-switcher
sudo mkdir -p "$SDDM_CONF_DIR"

# 4. INSTALLING FILES
echo "[4/8] Installing system files from usr/..."
if [ -d "usr" ]; then
    sudo cp -r usr/* /usr/
    echo "    ✅ Files copied to /usr/"
else
    echo "    ❌ Error: 'usr' directory not found!"
    exit 1
fi

# 5. SDDM WAYLAND CONFIGURATION
echo "[5/8] Configuring SDDM for Wayland..."
# Creazione del file 10-wayland.conf come richiesto
sudo tee "$SDDM_WAYLAND_CONF" > /dev/null <<EOF
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Wayland]
CompositorCommand=kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale POSIX --inputmethod maliit
EOF
echo "    ✅ SDDM Wayland config created at $SDDM_WAYLAND_CONF"

# 6. SYMBOLIC LINKS
echo "[6/8] Creating system symbolic links..."
sudo ln -sf /usr/local/bin/os-session-select /usr/bin/os-session-select
sudo ln -sf /usr/local/bin/steamos-update /usr/bin/steamos-update
sudo ln -sf /usr/local/bin/jupiter-biosupdate /usr/bin/jupiter-biosupdate
sudo ln -sf /usr/local/bin/steamos-select-branch /usr/bin/steamos-select-branch

# 7. SUDOERS AUTOMATION (SAFE METHOD)
echo "[7/8] Configuring Sudoers for seamless switching..."
# Definiamo il contenuto con i permessi corretti
SUDOERS_TEMP=$(mktemp)
cat <<EOF > "$SUDOERS_TEMP"
# SteamOS Switcher Permissions
%wheel ALL=(ALL) NOPASSWD: /usr/local/bin/set-sddm-session
%wheel ALL=(ALL) NOPASSWD: /usr/local/bin/os-session-select
EOF

# Validazione sintassi prima dell'installazione
if visudo -cf "$SUDOERS_TEMP"; then
    sudo cp "$SUDOERS_TEMP" "$SUDOERS_FILE"
    sudo chmod 440 "$SUDOERS_FILE"
    echo "    ✅ Sudoers rule installed safely."
else
    echo "    ❌ Error: Sudoers syntax validation failed!"
    exit 1
fi
rm "$SUDOERS_TEMP"

# 8. SHORTCUTS & PERMISSIONS
echo "[8/8] Finalizing shortcuts and permissions..."
sudo chmod +x /usr/local/bin/*
sudo chmod +x /usr/bin/steamos-polkit-helpers/*

# Gamescope Capabilities per performance
sudo setcap 'cap_sys_admin,cap_sys_nice,cap_ipc_lock+ep' $(which gamescope)
echo "    ✅ Gamescope capabilities set."

echo "------------------------------------------------"
echo "    🎉 Installation completed successfully!     "
echo "    Please reboot to apply SDDM Wayland changes."
echo "------------------------------------------------"
