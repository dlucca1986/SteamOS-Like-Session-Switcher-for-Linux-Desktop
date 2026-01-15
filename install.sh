#!/bin/bash

# --- SteamOS Switcher Installer ---
# This script installs the necessary scripts to enable 
# Steam Deck-like session switching and system compatibility.

set -e

echo "------------------------------------------------"
echo "  Starting Installation of SteamOS Switcher     "
echo "------------------------------------------------"

# 1. Create necessary directories
echo "[1/5] Creating system directories..."
sudo mkdir -p /usr/local/bin
sudo mkdir -p /usr/bin/steamos-polkit-helpers
sudo mkdir -p /usr/share/wayland-sessions

# 2. Install Master Scripts (The ones with exit logic) to /usr/bin/
echo "[2/5] Installing master scripts to /usr/bin..."
sudo cp steamos-update jupiter-biosupdate steamos-select-branch /usr/bin/

# 3. Install Polkit Helpers (The ones with exec) to their subfolder
echo "[3/5] Installing polkit helpers..."
sudo cp steamos-polkit-helpers/* /usr/bin/steamos-polkit-helpers/

# 4. Install Session Scripts to /usr/local/bin
echo "[4/5] Installing session management scripts..."
sudo cp os-session-select steamos-session-select set-sddm-session gamescope-session /usr/local/bin/
# Create link for os-session-select as Steam expects it in /usr/bin
sudo ln -sf /usr/local/bin/os-session-select /usr/bin/os-session-select

# 5. Set Permissions and Sessions
echo "[5/5] Setting executable permissions and sessions..."
sudo cp steam.desktop /usr/share/wayland-sessions/
sudo chmod +x /usr/bin/steamos-update /usr/bin/jupiter-biosupdate /usr/bin/steamos-select-branch
sudo chmod +x /usr/bin/steamos-polkit-helpers/*
sudo chmod +x /usr/local/bin/*

echo "------------------------------------------------"
echo "      Installation completed successfully!      "
echo "------------------------------------------------"
