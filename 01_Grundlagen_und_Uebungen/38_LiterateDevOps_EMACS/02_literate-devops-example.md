# Literate DevOps: Einrichten eines LXC-Containers mit Spiel und Backup

## Überblick
Dieses Dokument zeigt, wie man einen Debian LXC-Container einrichtet, das terminalbasierte Spiel `nudoku` installiert und Spielstände auf einen TrueNAS-Server sichert. Es folgt dem Literate DevOps-Ansatz: Die Dokumentation ist die primäre Quelle, und der Code ist eingebettet, um direkt ausführbar zu sein. Ziel ist es, den Prozess klar zu erklären und die Ausführung zu ermöglichen.

### Voraussetzungen
- Debian-Server mit LXC installiert.
- TrueNAS-Server (z. B. `192.168.30.100`) für Backups.
- SSH-Zugriff und `root`-Rechte.

## Schritt 1: LXC-Container einrichten
**Beschreibung**: Erstelle und starte einen Debian-Container für Spiele.  
**Code**:
```bash
# Installiere LXC (falls nicht vorhanden)
apt update && apt install -y lxc

# Erstelle und starte einen Debian Bookworm Container
lxc-create -t download -n game-container -- -d debian -r bookworm -a amd64
lxc-start -n game-container
```
**Erklärung**: Der Code installiert LXC und erstellt einen Container namens `game-container` mit Debian Bookworm. Der Container wird gestartet, um bereit für die Spielinstallation zu sein.

## Schritt 2: Spiel installieren
**Beschreibung**: Installiere `nudoku`, ein terminalbasiertes Sudoku-Spiel, im Container.  
**Code**:
```bash
# Verbinde dich mit dem Container
lxc-attach -n game-container -- bash

# Installiere nudoku
apt update && apt install -y nudoku

# Teste das Spiel
nudoku -d easy
```
**Erklärung**: Wir verbinden uns mit dem Container, aktualisieren die Paketquellen und installieren `nudoku`. Das Spiel wird mit dem einfachen Schwierigkeitsgrad gestartet, um die Funktionalität zu prüfen. Steuerung: Pfeiltasten, Zahlen 1-9, `q` zum Beenden.

## Schritt 3: Spielstände sichern
**Beschreibung**: Sichere den Spielstand von `nudoku` auf einen TrueNAS-Server.  
**Code**:
```bash
# Im Container: Erstelle Backup-Verzeichnis
mkdir -p /root/games
chmod 700 /root/games

# Kopiere Spielstand
[ -f /root/.nudoku ] && cp /root/.nudoku /root/games/nudoku.score

# Erstelle und übertrage Backup
tar -czf /tmp/nudoku-backup-$(date +%Y-%m-%d).tar.gz /root/games
scp /tmp/nudoku-backup-$(date +%Y-%m-%d).tar.gz root@192.168.30.100:/mnt/tank/backups/games/
```
**Erklärung**: Der Code erstellt ein sicheres Verzeichnis für Spielstände, kopiert den `nudoku`-Spielstand (falls vorhanden), erstellt ein komprimiertes Backup und überträgt es per SCP auf den TrueNAS-Server. Die IP `192.168.30.100` entspricht deinem HomeLab-Setup.

## Schritt 4: Backup automatisieren
**Beschreibung**: Erstelle ein Skript und automatisiere das Backup täglich mit Cron.  
**Code**:
```bash
# Im Container: Erstelle Backup-Skript
cat << 'EOF' > /usr/local/bin/nudoku_backup.sh
#!/bin/bash
trap 'echo "Backup unterbrochen"; exit 1' INT TERM
mkdir -p /root/games
[ -f /root/.nudoku ] && cp /root/.nudoku /root/games/nudoku.score
tar -czf /tmp/nudoku-backup-$(date +%Y-%m-%d).tar.gz /root/games
scp /tmp/nudoku-backup-$(date +%Y-%m-%d).tar.gz root@192.168.30.100:/mnt/tank/backups/games/
echo "Spielstände gesichert auf TrueNAS"
trap - INT TERM
EOF

# Mache Skript ausführbar
chmod +x /usr/local/bin/nudoku_backup.sh

# Füge Cron-Job hinzu
echo "0 6 * * * root /usr/local/bin/nudoku_backup.sh >> /var/log/nudoku-backup.log 2>&1" >> /etc/crontab
```
**Erklärung**: Das Skript automatisiert das Backup von `nudoku`-Spielständen. Es wird täglich um 6:00 Uhr ausgeführt und protokolliert. Der Cron-Job stellt sicher, dass Backups regelmäßig erfolgen, ohne manuelles Eingreifen.

## Reflexion
**Frage**: Wie verbessert Literate DevOps die Wartbarkeit dieses Prozesses?  
**Antwort**: Durch die Kombination von narrativer Erklärung und ausführbarem Code ist der Prozess klar dokumentiert und direkt umsetzbar. Teams verstehen den Kontext (z. B. warum `nudoku` gewählt wurde) und können den Code sofort ausführen oder anpassen.

## Tipps
- **Sicherheit**: Schütze Spielstände (`chmod 600 /root/games/*`) und sichere SCP mit SSH-Schlüsseln.
- **Fehlerbehebung**: Prüfe Logs (`tail /var/log/nudoku-backup.log`) und Container-Status (`lxc-info -n game-container`).
- **Erweiterungen**: Füge weitere Spiele hinzu (z. B. `pacman4console`) oder nutze `pandoc`, um Code zu extrahieren:
  ```bash
  pandoc literate-devops-example.md -o script.sh --extract-media=.
  chmod +x script.sh
  ./script.sh
  ```

## Nächste Schritte
- Erweitere das Dokument um weitere Spiele (z. B. `bsdgames`).
- Integriere in CI/CD, um Dokumentation zu validieren.
- Nutze Jupyter für interaktive Literate DevOps.

**Quellen**: Literate Programming Konzepte, LXC-Dokumentation, TrueNAS Docs.