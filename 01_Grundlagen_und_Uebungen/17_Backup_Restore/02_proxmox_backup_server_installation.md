# Praxisorientierte Anleitung: Einstieg in Proxmox Backup Server für deduplizierte Backups auf Debian

## Einführung
**Proxmox Backup Server (PBS)** ist ein Open-Source-Tool für deduplizierte, inkrementelle Backups, das nahtlos mit Proxmox VE integriert wird. Es reduziert Speicherbedarf durch Deduplizierung (Entfernen redundanter Daten) und ermöglicht schnelle Backups/Restores für VMs, LXC und Hosts. Diese Anleitung führt Sie in die Installation und Konfiguration von PBS auf einem Debian-System ein und zeigt, wie Sie deduplizierte Backups für Proxmox VE einrichten. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, effiziente Backup-Strategien für virtuelle Umgebungen umzusetzen. Diese Anleitung ist ideal für Administratoren, die deduplizierte Backups in Proxmox implementieren möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Proxmox VE installiert (z. B. auf einem separaten Host, wie in vorherigen Anleitungen)
- Mindestens 8 GB RAM und dedizierter Speicher (mindestens 500 GB SSD für deduplizierte Backups)
- Netzwerkverbindung zwischen PBS und Proxmox VE
- Grundlegende Kenntnisse der Linux-Kommandozeile und Proxmox
- Ein Texteditor (z. B. `nano`, `vim`)

## Grundlegende Proxmox Backup Server-Konzepte und Befehle
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **PBS-Komponenten**:
   - **Deduplizierung**: Reduziert Speicher durch Entfernen duplizierter Blöcke
   - **Incremental Backups**: Nur geänderte Daten sichern
   - **Prune**: Automatische Löschung alter Backups nach Policy
   - **Sync**: Replikation zwischen PBS-Servern
2. **Wichtige Konfigurationsdateien**:
   - `/etc/proxmox-backup/`: Hauptverzeichnis für PBS-Konfigurationen
   - `/etc/proxmox-backup/proxmox-backup.cfg`: Globale Einstellungen
3. **Wichtige Befehle**:
   - `proxmox-backup-server start`: Startet PBS
   - `proxmox-backup-client`: Client-Tool für Backups von Proxmox VE
   - `pxar`: Tool für deduplizierte Backups
   - `proxmox-backup-manager`: Manager für Datastores und Pruning

## Übungen zum Verinnerlichen

### Übung 1: Proxmox Backup Server installieren
**Ziel**: Lernen, wie man PBS auf einem Debian-System installiert und initialisiert.

1. **Schritt 1**: Füge das Proxmox-Repository hinzu und installiere PBS.
   ```bash
   sudo apt update
   sudo apt install -y gnupg
   wget https://enterprise.proxmox.com/debian/proxmox-release-bullseye.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bullseye.gpg
   echo "deb https://enterprise.proxmox.com/debian/pbs bullseye pbs-no-subscription" | sudo tee /etc/apt/sources.list.d/pbs.list
   sudo apt update
   sudo apt install -y proxmox-backup-server
   ```
2. **Schritt 2**: Starte und aktiviere PBS-Dienste.
   ```bash
   sudo systemctl start proxmox-backup.service
   sudo systemctl enable proxmox-backup.service
   sudo systemctl start proxmox-backup-proxy.service
   sudo systemctl enable proxmox-backup-proxy.service
   ```
3. **Schritt 3**: Überprüfe den Status.
   ```bash
   sudo systemctl status proxmox-backup
   sudo systemctl status proxmox-backup-proxy
   ```
4. **Schritt 4**: Öffne die Weboberfläche und erstelle einen Admin-Benutzer.
   - Öffne `https://<pbs-ip>:8007` (akzeptiere das Self-Signed-Zertifikat).
   - Melde dich an (default: root@pam, System-Passwort).
   - Erstelle einen neuen Benutzer: **Administration** > **User** > **Add**.

**Reflexion**: Warum ist Deduplizierung für Backups effizient, und wie unterscheidet sich PBS von traditionellen Backup-Tools?

### Übung 2: Datastore konfigurieren und Backup von Proxmox VE einrichten
**Ziel**: Verstehen, wie man einen Datastore erstellt und PBS mit Proxmox VE verbindet.

1. **Schritt 1**: Erstelle einen Datastore auf PBS.
   - In der Weboberfläche: **Datastore** > **Add**.
   - Name: `backup-store`, Pfad: `/backup` (z. B. mounten Sie ein dediziertes Laufwerk: `sudo mkdir /backup`).
   - Klicke **Create**.
2. **Schritt 2**: Installiere den Proxmox Backup Client auf dem Proxmox VE-Host.
   ```bash
   sudo apt update
   sudo apt install -y proxmox-backup-client
   ```
3. **Schritt 3**: Konfiguriere den PBS-Remote auf Proxmox VE.
   - In Proxmox-Weboberfläche: **Datacenter** > **Storage** > **Add** > **Proxmox Backup Server**.
   - ID: `pbs-remote`, Server: `<pbs-ip>`, Datastore: `backup-store`, Username: `root@pam`, Password: PBS-Passwort.
   - Klicke **Add**.
4. **Schritt 4**: Erstelle ein Backup einer VM/LXC auf PBS.
   - Wähle eine VM/LXC > **Backup** > **Backup now** > Storage: `pbs-remote`, Mode: Snapshot.
   - Klicke **Backup**.

**Reflexion**: Wie reduziert Deduplizierung den Speicherbedarf, und warum ist die Remote-Integration sicher (z. B. mit Zertifikaten)?

### Übung 3: Restore und Pruning testen
**Ziel**: Lernen, wie man Backups wiederherstellt und alte Backups automatisch löscht.

1. **Schritt 1**: Teste einen Restore von PBS.
   - In Proxmox-Weboberfläche: **Datacenter** > **Storage** > **pbs-remote** > **Content**.
   - Wähle ein Backup > **Restore** > **Restore to new VM/CT**.
   - Gib eine neue ID ein und starte den Restore.
2. **Schritt 2**: Konfiguriere Pruning auf PBS.
   - In PBS-Weboberfläche: **Datastore** > **backup-store** > **Prune & GC** > **Add**.
   - Name: `daily-prune`, Keep last: 7, Keep daily: 30, Keep monthly: 12.
   - Schedule: Daily (z. B. 02:00).
   - Klicke **Create**.
3. **Schritt 3**: Teste Garbage Collection.
   ```bash
   proxmox-backup-manager garbage-collection start --store backup-store
   ```
   Überprüfe den Status: **Datastore** > **Statistics**.

**Reflexion**: Warum ist Pruning für die Speicherverwaltung wichtig, und wie funktioniert Garbage Collection in PBS?

## Tipps für den Erfolg
- Verwenden Sie dedizierte Hardware für PBS (z. B. SSD für Chunk-Store).
- Testen Sie Restores regelmäßig, um die Integrität zu überprüfen.
- Konfigurieren Sie Zertifikate für sichere Verbindungen (z. B. Let's Encrypt).
- Für Offsite: Replizieren Sie Datastores mit `pxar` oder Sync-Jobs.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Proxmox Backup Server auf Debian installieren, konfigurieren und mit Proxmox VE für deduplizierte Backups integrieren. Durch die Übungen haben Sie praktische Erfahrung mit Datastores, Backups, Restores und Pruning gesammelt. Diese Fähigkeiten sind essenziell für effiziente Backup-Strategien in virtualisierten Umgebungen. Üben Sie weiter, um Sync zwischen PBS-Servern oder Integration mit anderen Tools zu meistern!

**Nächste Schritte**:
- Integrieren Sie PBS mit externen Speichern (z. B. S3 für Offsite).
- Erkunden Sie Proxmox Backup Client für Host-Backups.
- Lernen Sie fortgeschrittene Features wie Encryption oder Multi-Tenancy.

**Quellen**:
- Proxmox Backup Server-Dokumentation: https://pbs.proxmox.com/docs/
- Proxmox VE Integration: https://pve.proxmox.com/wiki/Proxmox_Backup_Server
- Community Forum: https://forum.proxmox.com/forums/proxmox-backup-server.68/