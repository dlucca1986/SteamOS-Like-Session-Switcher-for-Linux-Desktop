# SteamOS-Like-Session-Switcher-for-Linux-Desktop
This project provides a set of scripts to replicate the seamless session switching experience of the Steam Deck on a standard PC. It allows you to toggle between KDE Plasma (Desktop Mode) and Steam Big Picture/Gamescope (Game Mode) using SDDM.

What's inside ?

. set-sddm-session: 
  The core logic. It writes a temporary configuration to /etc/sddm.conf.d/ to set the autologin session for the next boot and triggers a delayed restart of the Display     Manager.

. gamescope-session: 
  The Game Mode launcher. It starts Steam with -steamdeck parameters inside a Gamescope window, optimized for 1080p @ 120Hz with MangoHud and Adaptive Sync.

. steamos-session-select:
  A quick wrapper to call the system session selector and return to Plasma.

Prerequisites :

.  Operating System: Arch Linux or
