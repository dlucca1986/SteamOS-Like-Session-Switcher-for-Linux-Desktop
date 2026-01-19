#!/bin/bash
# --- SteamOS Switcher Uninstaller ---

echo "🗑️  Removing SteamOS Switcher..."

# 1. Rimoziome file e directory
sudo rm -rf /usr/bin/steamos-polkit-helpers
sudo rm -rf /usr/share/steamos-switcher
sudo rm -f /usr/share/wayland-sessions/gamescope-session.desktop # Nome del tuo file sessione

# 2. Rimozione Link Simbolici
sudo rm -f /usr/bin/os-session-select
sudo rm -f /usr/bin/steamos-update
sudo rm -f /usr/bin/jupiter-biosupdate
sudo rm -f /usr/bin/steamos-select-branch
sudo rm -f /usr/local/bin/os-session-select # Rimuovi anche l'originale se necessario

# 3. Pulizia Sudoers
sudo rm -f /etc/sudoers.d/steamos-switcher
echo "✅ Sudoers rules removed."

# 4. Pulizia Desktop Shortcut
DESKTOP_DIRS=("$HOME/Desktop" "$HOME/Scrivania" "$HOME/desktop")
for dir in "${DESKTOP_DIRS[@]}"; do
    [ -f "$dir/GameMode.desktop" ] && rm "$dir/GameMode.desktop" && echo "✅ Shortcut removed from $dir"
done

echo "✨ System cleaned successfully!"
