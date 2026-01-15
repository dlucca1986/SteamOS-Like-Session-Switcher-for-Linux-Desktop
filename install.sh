#!/bin/bash

# --- SteamOS Switcher Installer ---

set -e

echo "------------------------------------------------"
echo "  Starting Installation of SteamOS Switcher     "
echo "------------------------------------------------"

# 1. Ensure system directories exist
echo "[1/5] Preparing system directories..."
sudo mkdir -p /usr/bin/steamos-polkit-helpers
sudo mkdir -p /usr/local/bin
sudo mkdir -p /usr/share/wayland-sessions

# 2. Install Master Scripts to /usr/local/bin
echo "[2/5] Installing master scripts to /usr/local/bin..."
sudo cp usr/local/bin/* /usr/local/bin/

# 3. Install Polkit Helpers to /usr/bin/steamos-polkit-helpers/
echo "[3/5] Installing polkit wrappers..."
sudo cp steamos-polkit-helpers/* /usr/bin/steamos-polkit-helpers/

# 4. Create Symbolic Links in /usr/bin
# Steam expects these specific names directly in /usr/bin
echo "[4/5] Creating system symbolic links..."
sudo ln -sf /usr/local/bin/os-session-select /usr/bin/os-session-select
sudo ln -sf /usr/local/bin/steamos-update /usr/bin/steamos-update
sudo ln -sf /usr/local/bin/jupiter-biosupdate /usr/bin/jupiter-biosupdate
sudo ln -sf /usr/local/bin/steamos-select-branch /usr/bin/steamos-select-branch

# 5. Install Session files and Set Permissions
echo "[5/5] Installing session entries and setting permissions..."
sudo cp usr/share/wayland-sessions/*.desktop /usr/share/wayland-sessions/

# Set all binaries to executable
sudo chmod +x /usr/local/bin/*
sudo chmod +x /usr/bin/steamos-polkit-helpers/*

echo "------------------------------------------------"
echo "      Installation completed successfully!      "
echo "------------------------------------------------"
echo "Check README.md to configure sudoers for "
echo "passwordless session switching."
echo "------------------------------------------------"
