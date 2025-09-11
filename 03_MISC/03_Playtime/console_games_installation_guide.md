# Praxisorientierte Anleitung: Installation und Spielen von Konsolenspielen in einer Debian LXC-Container-Konsole

## Grundlagen terminalbasierter Spiele
Terminalbasierte Spiele sind leichtgewichtig, laufen direkt im Linux-Terminal und bieten Retro-Spaß ohne grafische Oberfläche. Sie sind ideal für LXC-Container, da sie wenig Ressourcen benötigen.

### Wichtige Konzepte
- **Spiele**:
  - **Nudoku**: Terminalbasiertes Sudoku-Spiel.
  - **Pacman4console**: Konsolenversion des klassischen Pac-Man.
  - **Moon-Buggy**: Mondfahrzeug-Spiel, bei dem Hindernisse vermieden werden.
  - **Ninvaders**: Space Invaders im Terminal.
  - **Solitaire-TUI**: Textbasierte Version von Solitär.
  - **Bastet**: Tetris-Implementierung für das Terminal.
- **Vorteile**:
  - Geringer Ressourcenverbrauch.
  - Schnelle Installation und einfache Bedienung.
  - Nostalgischer Spielspaß.
- **Sicherheitsaspekte**:
  - Minimale Sicherheitsrisiken, da keine GUI erforderlich.
  - Sichere Spielstände oder Konfigurationen.

## Vorbereitung
1. **Prüfe den LXC-Container**:
   - Verbinde dich: `ssh root@192.168.30.124`.
   - Überprüfe das System:
     ```bash
     apt update
     apt install -y nano
     ```

2. **Prüfe DNS-Eintrag**:
   - Auf OPNsense (`http://192.168.30.1`):
     - Gehe zu `Services > Unbound DNS > Overrides > Host`.
     - Prüfe: `slides.homelab.local` → `192.168.30.124`.
     - Teste: `nslookup slides.homelab.local 192.168.30.1`.

3. **Erstelle Verzeichnis für Spielstände**:
   ```bash
   mkdir -p /root/games
   chmod 700 /root/games
   ```

## Übung 1: Spiele installieren
**Ziel**: Installiere Nudoku, Pacman4console, Moon-Buggy, Ninvaders, Solitaire-TUI und Bastet.

1. **Installiere die Spiele**:
   ```bash
   apt install -y nudoku pacman4console moon-buggy ninvaders bastet
   ```
   - **Hinweis**: Solitaire-TUI ist nicht direkt in den Debian-Paketquellen verfügbar. Wir installieren stattdessen `ace-of-penguins` für ein terminalbasiertes Solitär-Spiel:
     ```bash
     apt install -y ace-of-penguins
     ```

2. **Prüfe die Installation**:
   ```bash
   nudoku --version
   pacman4console --version
   moon-buggy --version
   ninvaders --version
   bastet --version
   ```
   - Erwartete Ausgabe: Versionsinformationen der Spiele.

**Reflexion**: Warum sind terminalbasierte Spiele für LXC-Container geeignet? Überlege, wie sie den Arbeitsalltag auflockern können.

## Übung 2: Spiele spielen
**Ziel**: Starte jedes Spiel und teste die Steuerung.

1. **Nudoku (Sudoku)**:
   ```bash
   nudoku
   ```
   - **Steuerung**: Pfeiltasten zum Navigieren, Zahlen (1-9) zum Ausfüllen, `q` zum Beenden.
   - **Ziel**: Fülle das 9x9-Raster logisch mit Zahlen 1-9.
   - **Tipp**: Wähle Schwierigkeitsgrade mit `nudoku -d easy|medium|hard`.

2. **Pacman4console**:
   ```bash
   pacman4console
   ```
   - **Steuerung**: Pfeiltasten zum Bewegen, `q` zum Beenden.
   - **Ziel**: Sammle Punkte, vermeide Geister.
   - **Tipp**: Prüfe Highscores in `/root/games/pacman4console.score` (falls erstellt).

3. **Moon-Buggy**:
   ```bash
   moon-buggy
   ```
   - **Steuerung**: Leertaste zum Springen, `f` zum Schießen, `q` zum Beenden.
   - **Ziel**: Weiche Kratern aus und schieße UFOs ab.
   - **Tipp**: Achte auf die Geschwindigkeit des Buggys.

4. **Ninvaders (Space Invaders)**:
   ```bash
   ninvaders
   ```
   - **Steuerung**: Pfeiltasten zum Bewegen, Leertaste zum Schießen, `q` zum Beenden.
   - **Ziel**: Zerstöre außerirdische Schiffe.
   - **Tipp**: Bewege dich schnell, um Treffern zu entgehen.

5. **Solitaire-TUI (via Ace of Penguins)**:
   ```bash
   penguin-solitaire
   ```
   - **Steuerung**: Maus (falls verfügbar) oder Tastatureingaben (siehe `man penguin-solitaire`), `q` zum Beenden.
   - **Ziel**: Sortiere Karten nach Regeln des klassischen Solitär.
   - **Hinweis**: Falls Tastatursteuerung unklar, prüfe `man ace-of-penguins`.

6. **Bastet (Tetris)**:
   ```bash
   bastet
   ```
   - **Steuerung**: Pfeiltasten zum Bewegen, Leertaste zum Drehen, `q` zum Beenden.
   - **Ziel**: Staple Blöcke, um Reihen zu vervollständigen.
   - **Tipp**: Wähle die schwierige Version mit `bastet -e` für Herausforderungen.

**Reflexion**: Welches Spiel macht am meisten Spaß? Überlege, wie die einfache Steuerung die Zugänglichkeit erhöht.

## Übung 3: Spielstände sichern
**Ziel**: Sichere Highscores oder Konfigurationen auf TrueNAS.

1. **Erstelle Backup-Skript**:
   ```bash
   nano /usr/local/bin/games_backup.sh
   ```
   Füge hinzu:
   ```bash
   #!/bin/bash
   trap 'echo "Backup unterbrochen"; exit 1' INT TERM
   mkdir -p /root/games
   [ -f /root/.nudoku ] && cp /root/.nudoku /root/games/nudoku.score
   [ -f /var/games/pacman4console.score ] && cp /var/games/pacman4console.score /root/games/
   [ -f /var/games/moon-buggy.scores ] && cp /var/games/moon-buggy.scores /root/games/
   [ -f /var/games/ninvaders.scores ] && cp /var/games/ninvaders.scores /root/games/
   [ -f /var/games/bastet ] && cp /var/games/bastet /root/games/bastet.score
   tar -czf /tmp/games-backup-$(date +%Y-%m-%d).tar.gz /root/games
   scp /tmp/games-backup-$(date +%Y-%m-%d).tar.gz root@192.168.30.100:/mnt/tank/backups/games/
   echo "Spielstände gesichert auf TrueNAS"
   trap - INT TERM
   ```
   Ausführbar machen:
   ```bash
   chmod +x /usr/local/bin/games_backup.sh
   ```

2. **Teste das Backup**:
   ```bash
   /usr/local/bin/games_backup.sh
   ```
   - Erwartete Ausgabe: Spielstände (falls vorhanden) werden auf TrueNAS gesichert.

3. **Automatisiere mit Cron**:
   ```bash
   nano /etc/crontab
   ```
   Füge hinzu:
   ```bash
   0 6 * * * root /usr/local/bin/games_backup.sh >> /var/log/games-backup.log 2>&1
   ```
   Speichere und beende.

**Reflexion**: Warum ist das Sichern von Spielständen sinnvoll? Überlege, wie Backups bei häufigem Spielen helfen.

## Tipps für den Erfolg
- **Sicherheit**:
  - Schütze Spielstände:
    ```bash
    chmod 600 /root/games/*
    ```
  - Halte den Container aktuell: `apt upgrade`.
- **Fehlerbehebung**:
  - Prüfe Installation: `dpkg -l | grep nudoku`.
  - Prüfe Spiel-Logs: Fehler erscheinen im Terminal.
  - Prüfe Backup-Logs: `tail /var/log/games-backup.log`.
- **Backup**:
  - Überprüfe Backups:
    ```bash
    ssh root@192.168.30.100 ls /mnt/tank/backups/games/
    ```
- **Erweiterungen**:
  - Installiere weitere Spiele, z. B. `bsdgames` für Klassiker wie `worm`:
    ```bash
    apt install -y bsdgames
    worm
    ```
  - Nutze Git zur Verwaltung von Spielkonfigurationen (siehe `slides_pdf_export_template_git_guide.md`).

## Fazit
Du hast Nudoku, Pacman4console, Moon-Buggy, Ninvaders, Solitaire-TUI (via Ace of Penguins) und Bastet (Tetris) installiert, gespielt und Spielstände auf TrueNAS gesichert. Diese Spiele bieten Retro-Spaß direkt im Terminal. Wiederhole die Übungen, um Highscores zu verbessern, oder erkunde weitere terminalbasierte Spiele.

**Nächste Schritte**: Möchtest du eine Anleitung zu weiteren Spielen (z. B. `bsdgames`), Integration mit anderen HomeLab-Diensten, oder einer webbasierten Spielumgebung? Lass es mich wissen!

**Quellen**:
- https://www.tecmint.com/command-line-games-for-linux/[](https://www.tecmint.com/best-linux-terminal-console-games/)
- https://itsfoss.com/command-line-games-linux/[](https://itsfoss.com/best-command-line-games-linux/)
- https://www.howtogeek.com/10-fun-games-to-play-in-the-linux-terminal/[](https://www.howtogeek.com/791146/linux-terminal-games/)
