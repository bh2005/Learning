# Praxisorientierte Anleitung: Grundlagen des Disaster Recovery für Windows, Debian und Proxmox VE

## Einführung
**Disaster Recovery (DR)** umfasst Prozesse, Richtlinien und Tools, um kritische IT-Systeme nach einem Ausfall (z. B. Hardwaredefekt, Cyberangriff, Naturkatastrophe) wiederherzustellen. Diese Anleitung gibt einen Überblick über die Grundlagen des Disaster Recovery für **Windows**, **Debian** (Linux) und **Proxmox VE**, einschließlich Backup-Strategien, Wiederherstellungspläne und Tools. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, einen effektiven DR-Plan zu erstellen und umzusetzen. Diese Anleitung ist ideal für Administratoren, die ihre Systeme vor schwerwiegenden Störungen schützen möchten.

**Voraussetzungen:**
- Ein Windows-, Debian- oder Proxmox VE-System mit Administratorrechten
- Grundlegende Kenntnisse der Kommandozeile (CMD/PowerShell für Windows, Bash für Debian, Proxmox-Weboberfläche)
- Zugriff auf externe Speichermedien (z. B. NAS, Cloud) für Backups
- Netzwerkverbindung für Offsite-Backups und Replikation

## Grundlegende Disaster Recovery-Konzepte
Hier sind die wichtigsten Konzepte, die wir behandeln:

1. **Disaster Recovery-Konzepte**:
   - **RTO (Recovery Time Objective)**: Zeit bis zur Wiederherstellung eines Systems.
   - **RPO (Recovery Point Objective)**: Maximal akzeptabler Datenverlust (Zeitraum zwischen Backups).
   - **Backup-Typen**: Vollständig, inkrementell, differentiell.
   - **Replikation**: Echtzeitkopien auf einem sekundären Standort.
2. **DR-Strategien**:
   - **Bare-Metal Restore**: Wiederherstellung eines gesamten Systems.
   - **Failover**: Umschalten auf ein Standby-System.
   - **Testing**: Regelmäßige Simulation von Ausfällen.
3. **Best Practices**:
   - 3-2-1-Regel: 3 Kopien, 2 Medien, 1 offsite.
   - Dokumentation des DR-Plans und regelmäßige Tests.

## Übungen zum Verinnerlichen

### Übung 1: Disaster Recovery für Windows
**Ziel**: Lernen, wie man einen DR-Plan mit Windows Server Backup für Bare-Metal-Restore erstellt.

1. **Schritt 1**: Installiere und konfiguriere Windows Server Backup.
   - Auf Windows Server: Öffne **Server-Manager** > **Add Roles and Features** > Installiere **Windows Server Backup**.
   - Öffne **Windows Server Backup** > **Backup Schedule Wizard**.
   - Wähle **Full server (recommended)** > Ziel: externe Festplatte oder NAS.
   - Plane tägliche Backups (z. B. 01:00 Uhr).
2. **Schritt 2**: Teste einen Bare-Metal-Restore.
   - Erstelle ein Boot-Medium: **Windows Server Backup** > **Recovery** > **Create a system repair disc**.
   - Simuliere einen Ausfall: Starte von der Wiederherstellungs-CD/USB.
   - Wähle **System Image Recovery** > Wähle das Backup > Folge dem Assistenten.
3. **Schritt 3**: Dokumentiere den DR-Plan.
   - Erstelle eine Checkliste: Backup-Zeitplan, Speicherorte, Restore-Schritte, Verantwortliche.
   - Beispiel:
     ```
     - Backup: Täglich 01:00, NAS (\\nas\backup)
     - RPO: 24 Stunden, RTO: 4 Stunden
     - Restore: Boot von USB, System Image Recovery
     ```

**Reflexion**: Warum ist ein Bare-Metal-Restore für DR entscheidend, und wie beeinflussen RTO und RPO die Planung?

### Übung 2: Disaster Recovery für Debian (Linux)
**Ziel**: Verstehen, wie man Debian mit rsync und Clonezilla für DR sichert.

1. **Schritt 1**: Erstelle ein Full Backup mit rsync.
   ```bash
   sudo apt update
   sudo apt install -y rsync
   rsync -aAXv --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*"} / /media/backup/full-$(date +%Y%m%d)
   ```
   - `-aAX`: Bewahrt Dateiattribute, ACLs und Extended Attributes.
   - `--exclude`: Ignoriert temporäre Systemverzeichnisse.
2. **Schritt 2**: Verwende Clonezilla für ein System-Image.
   - Lade Clonezilla Live ISO herunter (https://clonezilla.org).
   - Erstelle einen bootfähigen USB-Stick:
     ```bash
     sudo dd if=clonezilla-live.iso of=/dev/sdX bs=4M status=progress
     ```
   - Boote von Clonezilla USB > Wähle **device-image** > Ziel: externe Festplatte > Erstelle Image von `/`.
3. **Schritt 3**: Teste einen Restore mit Clonezilla.
   - Boote erneut von Clonezilla USB.
   - Wähle **device-image** > **Restore disk** > Wähle Image > Ziel: Systemdisk.
   - Überprüfe die Wiederherstellung: Starte das System.
4. **Schritt 4**: Dokumentiere den DR-Plan.
   - Beispiel:
     ```
     - Backup: Wöchentlich Full mit rsync, monatlich Image mit Clonezilla
     - RPO: 1 Woche, RTO: 2 Stunden
     - Restore: Clonezilla für Bare-Metal, rsync für Dateien
     ```

**Reflexion**: Wie unterstützt Clonezilla komplexe DR-Szenarien, und warum ist rsync für inkrementelle Updates nützlich?

### Übung 3: Disaster Recovery für Proxmox VE
**Ziel**: Lernen, wie man Proxmox VE mit Proxmox Backup Server (PBS) für DR sichert.

1. **Schritt 1**: Konfiguriere PBS für Proxmox VE (siehe vorherige Anleitung).
   - Stelle sicher, dass PBS installiert ist und ein Datastore (z. B. `backup-store`) konfiguriert ist.
   - In Proxmox VE: **Datacenter** > **Storage** > **Add** > **Proxmox Backup Server**.
2. **Schritt 2**: Erstelle regelmäßige Backups für VMs und LXC.
   - In Proxmox-Weboberfläche: Wähle VM/LXC > **Backup** > **Schedule** > Storage: `pbs-remote`, Mode: Snapshot, Daily 02:00.
   - Überprüfe Backups: **Datacenter** > **Storage** > **pbs-remote** > **Content**.
3. **Schritt 3**: Teste einen Restore nach simuliertem Ausfall.
   - Simuliere einen Host-Ausfall: Lösche eine VM (z. B. ID 100).
   - In Proxmox-Weboberfläche: **pbs-remote** > Wähle Backup > **Restore** > Neue VM-ID (z. B. 101).
   - Starte die VM und überprüfe die Funktionalität.
4. **Schritt 4**: Plane Offsite-Replikation.
   - Installiere einen zweiten PBS-Server (z. B. an einem anderen Standort).
   - Konfiguriere Sync: **PBS-Weboberfläche** > **Datastore** > **Sync Jobs** > **Add**.
   - Beispiel: Sync `backup-store` von PBS1 zu PBS2, täglich.
5. **Schritt 5**: Dokumentiere den DR-Plan.
   - Beispiel:
     ```
     - Backup: Täglich 02:00 auf PBS, Sync zu Offsite-PBS
     - RPO: 24 Stunden, RTO: 1 Stunde pro VM
     - Restore: PBS-Weboberfläche, Bare-Metal mit Proxmox ISO
     ```

**Reflexion**: Wie unterstützt PBS die Minimierung von RPO, und warum ist Offsite-Replikation für DR entscheidend?

## Tipps für den Erfolg
- Testen Sie DR-Pläne vierteljährlich durch simulierte Ausfälle.
- Verwenden Sie die 3-2-1-Regel: 3 Kopien, 2 Medien, 1 offsite (z. B. Cloud oder zweiter PBS).
- Dokumentieren Sie Netzwerk- und Zugangsdaten für Notfälle.
- Automatisieren Sie Backups mit Cron (Debian) oder Task Scheduler (Windows).

## Fazit
In dieser Anleitung haben Sie die Grundlagen des Disaster Recovery für Windows, Debian und Proxmox VE kennengelernt. Durch die Übungen haben Sie praktische Erfahrung mit Backups, Restores und DR-Planung gesammelt. Diese Fähigkeiten sind essenziell, um Systeme vor katastrophalen Ausfällen zu schützen. Üben Sie weiter, um fortgeschrittene DR-Strategien wie Multi-Site-Replikation zu meistern!

**Nächste Schritte**:
- Erkunden Sie Cloud-DR-Lösungen (z. B. Azure Site Recovery, AWS Elastic Disaster Recovery).
- Integrieren Sie Monitoring-Tools (z. B. Check_MK) für Backup-Überwachung.
- Testen Sie Multi-Site-DR-Szenarien mit Proxmox Cluster.

**Quellen**:
- Microsoft Docs (Windows DR): https://docs.microsoft.com/en-us/windows-server/administration/windows-server-backup
- Debian Backup Guide: https://wiki.debian.org/BackupAndRecovery
- Proxmox Backup Server: https://pbs.proxmox.com/docs/