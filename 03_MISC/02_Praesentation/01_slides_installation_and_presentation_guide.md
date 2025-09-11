# Praxisorientierte Anleitung: Installation von Slides in einer Debian LXC-Container-Konsole und Erstellung einer Präsentation

## Grundlagen von Slides
**Slides** ist eine Open-Source-Software, die Markdown-Dateien in interaktive Präsentationen im Terminal umwandelt. Sie ist leichtgewichtig, ideal für technische Präsentationen und läuft ohne Browser.

### Wichtige Konzepte
- **Markdown**: Ein einfaches Textformat für strukturierte Inhalte (z. B. Überschriften, Listen, Codeblöcke).
- **Slides**: Rendert Markdown-Dateien mit Folien (getrennt durch `---`) im Terminal.
- **Einsatzmöglichkeiten**:
  - Technische Präsentationen (z. B. HomeLab-Dokumentation).
  - Schulungen oder Demos ohne komplexe GUI.
- **Vorteile**:
  - Minimalistischer Ressourcenverbrauch, ideal für LXC-Container.
  - Einfache Erstellung und Bearbeitung mit Markdown.
- **Sicherheitsaspekte**:
  - Sichere Backups der Präsentationen.
  - Schütze sensible Daten in Markdown-Dateien.

## Vorbereitung
1. **Erstelle einen Debian LXC-Container in Proxmox**:
   - Öffne: `https://192.168.30.2:8006`.
   - Gehe zu `Datacenter > Node > Create LXC`.
   - Konfiguriere:
     - Template: `debian-13-standard`
     - Hostname: `slides`
     - IP-Adresse: `192.168.30.124/24`
     - Gateway: `192.168.30.1`
     - DNS-Server: `192.168.30.1`
     - Speicher: 10 GB
     - CPU: 1, RAM: 1024 MB
   - Starte den Container:
     ```bash
     pct start <CTID>  # Ersetze <CTID> durch die Container-ID (z. B. 101)
     ```

2. **DNS-Eintrag in OPNsense hinzufügen**:
   - Öffne: `http://192.168.30.1`.
   - Gehe zu `Services > Unbound DNS > Overrides > Host`.
   - Füge hinzu: `slides.homelab.local` → `192.168.30.124`.
   - Teste:
     ```bash
     nslookup slides.homelab.local 192.168.30.1
     ```
     - Erwartete Ausgabe: `192.168.30.124`.

3. **Verbinde dich mit dem Container**:
   ```bash
   ssh root@192.168.30.124
   ```

4. **Aktualisiere das System und installiere Grundpakete**:
   ```bash
   apt update
   apt install -y nano curl
   ```

## Übung 1: Slides installieren
**Ziel**: Installiere Slides im Debian LXC-Container.

1. **Installiere Node.js** (erforderlich für Slides):
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
   apt install -y nodejs
   ```

2. **Installiere Slides**:
   ```bash
   npm install -g @maaslalani/slides
   ```

3. **Prüfe die Installation**:
   ```bash
   slides --version
   ```
   - Erwartete Ausgabe: Zeigt die installierte Version von Slides (z. B. `0.9.0`).

**Reflexion**: Warum ist Slides für einen LXC-Container geeignet? Überlege, wie Markdown die Erstellung von Präsentationen vereinfacht.

## Übung 2: Präsentation erstellen
**Ziel**: Erstelle eine Markdown-Präsentation über die HomeLab-PKI.

1. **Erstelle ein Verzeichnis für die Präsentation**:
   ```bash
   mkdir -p /root/presentations
   cd /root/presentations
   ```

2. **Erstelle die Präsentationsdatei**:
   ```bash
   nano pki_presentation.md
   ```
   Füge hinzu:
   ```markdown
   # HomeLab PKI Präsentation

   ## Willkommen
   - Überblick über die Public Key Infrastructure (PKI)
   - Einrichtung in der HomeLab-Umgebung
   - Erstellt von: HomeLab Team

   ---

   ## Was ist eine PKI?
   - **Definition**: System zur Verwaltung digitaler Zertifikate
   - **Komponenten**:
     - Root CA
     - Intermediate CA
     - Zertifikate und CRLs
   - **Einsatz**: VPNs, Webserver, E-Mail-Sicherheit

   ---

   ## Einrichtung in der HomeLab
   - **Server**: Debian 13 VM (`pki.homelab.local`, `192.168.30.123`)
   - **Tools**: OpenSSL
   - **Struktur**:
     ```bash
     /root/ca/
     ├── root/
     │   ├── certs/
     │   ├── private/
     │   └── ...
     ├── intermediate/
     │   ├── certs/
     │   ├── private/
     │   └── ...
     ```

   ---

   ## Beispiel: Zertifikat für Webserver
   - **Schritte**:
     1. Generiere Schlüssel: `openssl genrsa`
     2. Erstelle CSR: `openssl req`
     3. Signiere mit Intermediate CA: `openssl ca`
   - **Nutzung**: HTTPS für `webserver.homelab.local`

   ---

   ## Fazit
   - **Vorteile**:
     - Sichere Kommunikation
     - Flexible Zertifikatsverwaltung
   - **Nächste Schritte**:
     - Integration in OPNsense
     - Erstellung von SAN-Zertifikaten
   - Fragen?

   ---
   ```
   Speichere (Ctrl+O, Enter) und beende (Ctrl+X).

3. **Teste die Präsentation**:
   ```bash
   slides pki_presentation.md
   ```
   - Erwartete Ausgabe: Terminal zeigt die Präsentation; navigiere mit Pfeiltasten oder `q` zum Beenden.

**Reflexion**: Wie erleichtert Markdown die Erstellung von Präsentationen? Überlege, wie Slides in Schulungen oder Demos eingesetzt werden kann.

## Übung 3: Präsentation sichern
**Ziel**: Sichere die Präsentation auf TrueNAS.

1. **Erstelle Backup-Skript**:
   ```bash
   nano /usr/local/bin/slides_backup.sh
   ```
   Füge hinzu:
   ```bash
   #!/bin/bash
   trap 'echo "Backup unterbrochen"; exit 1' INT TERM
   tar -czf /tmp/slides-backup-$(date +%Y-%m-%d).tar.gz /root/presentations
   scp /tmp/slides-backup-$(date +%Y-%m-%d).tar.gz root@192.168.30.100:/mnt/tank/backups/slides/
   echo "Präsentationen gesichert auf TrueNAS"
   trap - INT TERM
   ```
   Ausführbar machen:
   ```bash
   chmod +x /usr/local/bin/slides_backup.sh
   ```

2. **Teste das Backup**:
   ```bash
   /usr/local/bin/slides_backup.sh
   ```
   - Erwartete Ausgabe: Präsentationen werden auf TrueNAS gesichert.

3. **Automatisiere mit Cron**:
   ```bash
   nano /etc/crontab
   ```
   Füge hinzu:
   ```bash
   0 5 * * * root /usr/local/bin/slides_backup.sh >> /var/log/slides-backup.log 2>&1
   ```
   Speichere und beende.

**Reflexion**: Wie schützt das Backup die Präsentationen? Überlege, wie regelmäßige Backups die Wiederherstellung erleichtern.

## Tipps für den Erfolg
- **Sicherheit**:
  - Schütze sensible Daten in Präsentationen (z. B. Passwörter entfernen).
  - Sichere den Container:
    ```bash
    chmod 700 /root/presentations
    ```
- **Fehlerbehebung**:
  - Prüfe Node.js: `node --version`.
  - Prüfe Slides: `slides --version`.
  - Prüfe Backup-Logs: `tail /var/log/slides-backup.log`.
- **Backup**:
  - Überprüfe Backups:
    ```bash
    ssh root@192.168.30.100 ls /mnt/tank/backups/slides/
    ```
- **Erweiterungen**:
  - Füge Bilder oder Codeblöcke zur Präsentation hinzu (Markdown-Syntax).
  - Verwende eine webbasierte Alternative wie **Reveal.js** für Browser-Präsentationen.
  - Exportiere die Präsentation als PDF (z. B. mit `pandoc` und LaTeX):
    ```bash
    apt install -y pandoc texlive
    pandoc -t beamer pki_presentation.md -o pki_presentation.pdf
    ```

## Fazit
Du hast Slides in einem Debian LXC-Container installiert, eine Präsentation über die HomeLab-PKI erstellt und Backups auf TrueNAS automatisiert. Die Präsentation kann im Terminal angezeigt oder für Schulungen verwendet werden. Wiederhole die Übungen, um weitere Präsentationen zu erstellen, oder erweitere die Funktionalität mit anderen Tools.

**Nächste Schritte**: Möchtest du eine Anleitung zur Erstellung von Präsentationen mit Reveal.js, Export als PDF, oder Integration mit anderen HomeLab-Diensten (z. B. Papermerge für Dokumentenverwaltung)?

**Quellen**:
- Slides-Dokumentation: https://github.com/maaslalani/slides
- Node.js-Installation: https://nodejs.org/en/download/package-manager
- Markdown-Guide: https://www.markdownguide.org/