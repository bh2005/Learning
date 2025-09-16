# Praxisorientierte Anleitung: Disaster Recovery für RAID-Systeme auf Debian

## Einführung
Disaster Recovery (DR) für RAID-Systeme (Redundant Array of Independent Disks) umfasst Strategien und Tools, um Datenverluste und Systemausfälle bei Hardwaredefekten, Softwarefehlern oder anderen Störungen zu minimieren. RAID bietet Redundanz (z. B. RAID 1, 5, 6), aber ein DR-Plan ist entscheidend, um Datenintegrität und Verfügbarkeit zu gewährleisten. Diese Anleitung konzentriert sich auf DR-Grundlagen für Software-RAID auf Debian mit Tools wie `mdadm` sowie Backup- und Restore-Techniken. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, effektive DR-Pläne für RAID-Systeme zu erstellen und umzusetzen. Diese Anleitung ist ideal für Administratoren, die RAID-basierte Speicherlösungen schützen möchten.

**Voraussetzungen:**
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Ein Software-RAID (z. B. RAID 1, 5 oder 6) mit `mdadm` eingerichtet
- Mindestens 4 GB RAM und ausreichend Festplattenspeicher (mindestens 10 GB frei)
- Externe Speichermedien (z. B. NAS, USB-Festplatte) für Backups
- Grundlegende Kenntnisse der Linux-Kommandozeile und RAID-Konzepte

## Grundlegende Disaster Recovery-Konzepte für RAID-Systeme
Hier sind die wichtigsten Konzepte, die wir behandeln:

1. **RAID-Konzepte**:
   - **RAID-Level**: RAID 1 (Spiegelung), RAID 5 (Parität, 1 Ausfall), RAID 6 (Parität, 2 Ausfälle).
   - **mdadm**: Tool zur Verwaltung von Software-RAID in Linux.
   - **Degraded Mode**: RAID arbeitet trotz ausgefallener Festplatte(n).
2. **DR-Komponenten**:
   - **Backup**: Regelmäßige Sicherung von Daten und RAID-Metadaten.
   - **Restore**: Wiederherstellung von Daten oder RAID-Array nach Ausfall.
   - **Rebuild**: Neuaufbau des RAID nach Festplattenaustausch.
   - **RTO/RPO**: Recovery Time Objective (Zeit bis Wiederherstellung), Recovery Point Objective (Datenverlust).
3. **Best Practices**:
   - 3-2-1-Regel: 3 Kopien, 2 Medien, 1 offsite.
   - Regelmäßige Tests von Restore-Prozessen und Dokumentation.

## Übungen zum Verinnerlichen

### Übung 1: Backup eines RAID-Systems mit mdadm
**Ziel**: Lernen, wie man ein RAID-Array sichert, einschließlich Metadaten und Daten.

1. **Schritt 1**: Richte ein RAID-Array ein (falls nicht vorhanden).
   - Installiere `mdadm`:
     ```bash
     sudo apt update
     sudo apt install -y mdadm
     ```
   - Erstelle ein RAID 1 mit zwei Festplatten (z. B. `/dev/sdb`, `/dev/sdc`):
     ```bash
     sudo mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sdb /dev/sdc
     ```
   - Erstelle ein Dateisystem und mounte:
     ```bash
     sudo mkfs.ext4 /dev/md0
     sudo mkdir /mnt/raid
     sudo mount /dev/md0 /mnt/raid
     ```
   - Speichere die Konfiguration:
     ```bash
     sudo mdadm --detail --scan >> /etc/mdadm/mdadm.conf
     ```
2. **Schritt 2**: Sichere RAID-Metadaten.
   - Speichere RAID-Details:
     ```bash
     sudo mdadm --detail --scan > /media/backup/raid_metadata-$(date +%Y%m%d).conf
     sudo cp /etc/mdadm/mdadm.conf /media/backup/mdadm.conf-$(date +%Y%m%d)
     ```
3. **Schritt 3**: Sichere Daten mit rsync.
   - Erstelle ein Full Backup:
     ```bash
     sudo rsync -avh --progress /mnt/raid/ /media/backup/raid_data-$(date +%Y%m%d)
     ```
4. **Schritt 4**: Dokumentiere den DR-Plan.
   - Beispiel:
     ```
     - Backup: Täglich rsync auf NAS, wöchentlich Metadaten
     - RPO: 24 Stunden, RTO: 2 Stunden
     - Ziel: /media/backup (NAS)
     ```

**Reflexion**: Warum ist die Sicherung der RAID-Metadaten entscheidend, und wie unterstützt rsync inkrementelle Backups?

### Übung 2: Wiederherstellung eines RAID-Arrays nach Festplattenausfall
**Ziel**: Verstehen, wie man ein degradiertes RAID-Array wiederherstellt und Daten zurückspielt.

1. **Schritt 1**: Simuliere einen Festplattenausfall.
   - Markiere eine Festplatte als fehlerhaft:
     ```bash
     sudo mdadm /dev/md0 --fail /dev/sdb
     ```
   - Überprüfe den Status (degraded):
     ```bash
     cat /proc/mdstat
     ```
2. **Schritt 2**: Ersetze die ausgefallene Festplatte.
   - Entferne die fehlerhafte Festplatte:
     ```bash
     sudo mdadm /dev/md0 --remove /dev/sdb
     ```
   - Füge eine neue Festplatte hinzu (z. B. `/dev/sdd`):
     ```bash
     sudo mdadm /dev/md0 --add /dev/sdd
     ```
   - Überwache den Rebuild:
     ```bash
     watch cat /proc/mdstat
     ```
3. **Schritt 3**: Teste einen vollständigen Restore (z. B. nach Totalausfall).
   - Simuliere Totalausfall: Stoppe RAID:
     ```bash
     sudo mdadm --stop /dev/md0
     ```
   - Stelle RAID aus Metadaten wieder her:
     ```bash
     sudo mdadm --assemble /dev/md0 /dev/sdb /dev/sdc --config=/media/backup/raid_metadata-20250916.conf
     ```
   - Stelle Daten zurück:
     ```bash
     sudo mount /dev/md0 /mnt/raid
     sudo rsync -avh /media/backup/raid_data-20250916/ /mnt/raid/
     ```
   - Überprüfe Datenintegrität:
     ```bash
     ls -l /mnt/raid
     ```
4. **Schritt 4**: Dokumentiere den Restore-Prozess.
   - Beispiel:
     ```
     - Restore: mdadm --assemble, rsync für Daten
     - Test: Monatlich simulierter Ausfall
     - Verantwortlicher: Admin
     ```

**Reflexion**: Warum ist der Rebuild-Prozess zeitkritisch, und wie minimiert RAID 6 das Risiko gegenüber RAID 5?

### Übung 3: Automatisierte Backups und Offsite-Replikation
**Ziel**: Lernen, wie man automatisierte Backups für RAID-Systeme plant und Offsite-Replikation einrichtet.

1. **Schritt 1**: Erstelle ein Backup-Skript.
   ```bash
   sudo nano /root/raid_backup.sh
   ```
   Inhalt:
   ```bash
   #!/bin/bash
   # RAID-Backup-Skript
   BACKUP_DIR="/media/backup"
   DATE=$(date +%Y%m%d)
   RAID_MOUNT="/mnt/raid"

   # Sichere Metadaten
   mdadm --detail --scan > $BACKUP_DIR/raid_metadata-$DATE.conf
   cp /etc/mdadm/mdadm.conf $BACKUP_DIR/mdadm.conf-$DATE

   # Sichere Daten
   rsync -avh --delete $RAID_MOUNT/ $BACKUP_DIR/raid_data-$DATE

   echo "Backup abgeschlossen: $(date)" >> /var/log/raid_backup.log
   ```
   Mach es ausführbar:
   ```bash
   chmod +x /root/raid_backup.sh
   ```
2. **Schritt 2**: Plane das Backup mit Cron.
   ```bash
   crontab -e
   ```
   Füge hinzu (täglich um 02:00):
   ```
   0 2 * * * /root/raid_backup.sh >> /var/log/raid_backup.log 2>&1
   ```
3. **Schritt 3**: Konfiguriere Offsite-Replikation (z. B. zu AWS S3).
   - Installiere AWS CLI:
     ```bash
     sudo apt install -y awscli
     aws configure
     ```
     Gib AWS Access Key, Secret Key und Region ein (z. B. `eu-central-1`).
   - Erstelle einen S3-Bucket:
     ```bash
     aws s3 mb s3://raid-backups
     ```
   - Passe das Skript an für Offsite-Sync:
     ```bash
     sudo nano /root/raid_backup.sh
     ```
     Füge hinzu:
     ```bash
     aws s3 sync $BACKUP_DIR/ s3://raid-backups/ --delete
     ```
   - Teste das Skript:
     ```bash
     /root/raid_backup.sh
     ```
4. **Schritt 4**: Dokumentiere den DR-Plan.
   - Beispiel:
     ```
     - Backup: Täglich rsync und AWS S3
     - Offsite: S3 (eu-central-1)
     - RPO: 24 Stunden, RTO: 4 Stunden
     - Test: Vierteljährlich simulierter Festplattenausfall
     ```

**Reflexion**: Wie verbessert Offsite-Replikation die Resilienz, und warum ist Logging für die Nachverfolgbarkeit wichtig?

## Tipps für den Erfolg
- Überwachen Sie RAID-Status regelmäßig: `cat /proc/mdstat` oder `mdadm --detail /dev/md0`.
- Testen Sie Restores monatlich, um die Integrität zu gewährleisten.
- Verwenden Sie die 3-2-1-Regel: 3 Kopien, 2 Medien, 1 offsite (z. B. S3).
- Dokumentieren Sie Festplatten-IDs und Partitionen für schnellen Austausch.

## Fazit
In dieser Anleitung haben Sie die Grundlagen des Disaster Recovery für RAID-Systeme auf Debian erkundet. Durch die Übungen haben Sie praktische Erfahrung mit Backups, Restores, Rebuilds und Offsite-Replikation gesammelt. Diese Fähigkeiten sind essenziell für die Sicherung RAID-basierter Speicherlösungen. Üben Sie weiter, um DR mit Monitoring-Tools oder Cloud-DR-Lösungen zu integrieren!

**Nächste Schritte**:
- Integrieren Sie Monitoring-Tools wie Check_MK für RAID-Überwachung.
- Erkunden Sie Cloud-DR-Lösungen (z. B. Azure Site Recovery, AWS Elastic Disaster Recovery).
- Implementieren Sie Hardware-RAID für höhere Performance.

**Quellen**:
- mdadm-Dokumentation: https://manpages.debian.org/mdadm
- Debian RAID-Wiki: https://wiki.debian.org/SoftwareRAID
- AWS S3 Backup Guide: https://docs.aws.amazon.com/cli/latest/userguide/cli-services-s3.html