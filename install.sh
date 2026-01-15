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

# 2. Install Master Scripts to /usr/local/bin
# These contain the core logic (exit codes, branch info, etc.)
echo "[2/5] Installing master scripts to /usr/local/bin..."
sudo cp steamos-update jupiter-biosupdate steamos-select-branch \
        os-session-select steamos-session-select set-sddm-session \
        gamescope-session /usr/local/bin/

# 3. Install Polkit Helpers to their subfolder
# These are the wrappers that call the master scripts
echo "[3/5] Installing polkit helpers to /usr/bin/steamos-polkit-helpers/..."
sudo cp steamos-polkit-helpers/steamos-update /usr/bin/steamos-polkit-helpers/
sudo cp steamos-polkit-helpers/jupiter-biosupdate /usr/bin/steamos-polkit-helpers/
sudo cp steamos-polkit-helpers/steamos-set-timezone /usr/bin/steamos-polkit-helpers/

# 4. Create symbolic links in /usr/bin
# This ensures Steam finds the scripts in the expected global path
echo "[4/5] Creating symbolic links in /usr/bin..."
sudo ln -sf /usr/local/bin/os-session-select /usr/bin/os-session-select
sudo ln -sf /usr/local/bin/steamos-update /usr/bin/steamos-update
sudo ln -sf /usr/local/bin/jupiter-biosupdate /usr/bin/jupiter-biosupdate
sudo ln -sf /usr/local/bin/steamos-select-branch /usr/bin/steamos-select-branch

# 5. Set Permissions and Wayland Sessions
echo "[5/5] Setting executable permissions and sessions..."
sudo cp steam.desktop /usr/share/wayland-sessions/
sudo chmod +x /usr/local/bin/*
sudo chmod +x /usr/bin/steamos-polkit-helpers/*

echo "------------------------------------------------"
echo "      Installation completed successfully!      "
echo "------------------------------------------------"
echo "Next step: Add the sudoers rule for passwordless switching."
echo "Check your README.md for the configuration
