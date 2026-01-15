# 🎮 SteamOS Switcher for Linux

### "Bringing the SteamOS Experience to Every Handheld"

## 🌟 Il Progetto
Ciao! Sono [Il Tuo Nome/Username]. Ho creato questo progetto per colmare il vuoto tra le distribuzioni Linux standard e l'interfaccia di Steam Deck. 

Spesso, installando Steam su PC o dispositivi handheld (come ROG Ally o Legion Go), ci si scontra con l'impossibilità di tornare al Desktop correttamente o con errori fastidiosi nei menu di sistema. Questo set di script nasce dalla mia passione per il gaming su Linux e dalla voglia di rendere l'esperienza "Game Mode" fluida e professionale per tutti.

## ✨ Caratteristiche
* **Seamless Switch:** Abilita il tasto "Passa al Desktop" direttamente dall'interfaccia Steam.
* **Update Fix:** Gestisce i segnali di aggiornamento di sistema (Exit Code 7) per evitare loop infiniti.
* **Handheld Optimized:** Configurato per emulare il comportamento dei polkit-helpers di SteamOS (Jupiter).
* **Safe & Clean:** Utilizza una struttura professionale in `/usr/local/bin` per non sporcare i file di sistema originali.

## 🚀 Installazione Rapida
Apri il terminale e digita:
```bash
git clone [https://github.com/tuo-username/steamos-switcher.git](https://github.com/tuo-username/steamos-switcher.git)
cd steamos-switcher
chmod +x install.sh
sudo ./install.sh
