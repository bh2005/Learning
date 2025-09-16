# Praxisorientierte Anleitung: Grundkonzepte Backup und Restore für Proxmox VM und LXC

## Einführung
**Proxmox VE** ist eine Open-Source-Virtualisierungsplattform, die **VMs** (Virtual Machines) mit KVM/QEMU und **LXC** (Linux Containers) unterstützt. Backups und Restores sind entscheidend, um virtuelle Umgebungen vor Ausfällen zu schützen. Diese Anleitung gibt einen Überblick über Backup-Strategien für Proxmox VMs und LXC, einschließlich integrierter Tools und Skripte. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, effektive Backup-Strategien für virtuelle Umgebungen zu planen und umzusetzen. Diese Anleitung ist ideal für Administratoren, die Proxmox-Cluster sichern möchten.

**Voraussetzungen:**
- Ein Proxmox VE-System (z. B. Version 8.x) mit Root-Zugriff
- Mindestens eine VM oder LXC-Container eingerichtet
- Externe Speichermedien (z. B. NFS-Share oder externe Festplatte) für Backups
- Grundlegende Kenntnisse der Proxmox-Weboberfläche und Linux-Kommandozeile

## Grundlegende Backup- und Restore-Konzepte
Hier sind die wichtigsten Konzepte, die wir behandeln:

1. **Backup-Typen in Proxmox**:
   - **Snapshot**: Momentaufnahme des VM/LXC-Status (inkl. Speicher)
   - **Full Backup**: Vollständige Kopie von Konfiguration und Speicher
   - **Incremental Backup**: Nur Änderungen seit dem letzten Full Backup (für VMs)
2. **Restore-Strategien**:
   - **Restore to new VM/LXC**: Wiederherstellung in eine neue Instanz
   - **Restore to existing VM/LXC**: Überschreibung einer bestehenden Instanz
   - **Migration**: Backup als Basis für Migration zu einem anderen Host
3. **Tools und Best Practices**:
   - Integriertes Proxmox-Backup-Tool (PVE Backup)
   - Externe Tools wie `vzdump` für Skripte
   - 3-2-1-Regel: 3 Kopien, 2 Medien, 1 offsite

## Übungen zum Verinnerlichen

### Übung 1: Backup und Restore für VMs in Proxmox
**Ziel**: Lernen, wie man VMs mit dem integrierten Backup-Tool sichert und wiederherstellt.

1. **Schritt 1**: Erstelle ein Backup einer VM.
   - Öffne die Proxmox-Weboberfläche (`https://<proxmox-ip>:8006`).
   - Wähle eine VM > **Backup** > **Backup now**.
   - Wähle **Storage** (z. B. local oder NFS-Share), **Mode** (Snapshot für laufende VM), **Compression** (z. B. gzip).
   - Klicke **Backup** und warte auf Abschluss.
2. **Schritt 2**: Überprüfe das Backup.
   - Gehe zu **Datacenter** > **Storage** > **local** > **Content** > **VZDump backups**.
   - Du siehst das Backup (z. B. `vzdump-qemu-100-2025_09_16-...vma.gz`).
3. **Schritt 3**: Teste einen Restore.
   - Wähle das Backup > **Restore** > **Restore to new VM**.
   - Gib einen neuen VM-ID ein (z. B. 101) und starte den Restore.
   - Nach Abschluss starte die neue VM und überprüfe, ob sie funktioniert.

**Reflexion**: Warum ist der Snapshot-Modus für laufende VMs nützlich, und wie unterscheidet sich er von einem Stop-Backup?

### Übung 2: Backup und Restore für LXC-Container
**Ziel**: Verstehen, wie man LXC-Container mit vzdump sichert und wiederherstellt.

1. **Schritt 1**: Erstelle ein Backup eines LXC-Containers.
   - In der Weboberfläche: Wähle einen LXC-Container > **Backup** > **Backup now**.
   - Wähle **Storage**, **Mode** (Snapshot), **Compression**.
   - Klicke **Backup**.
   - Alternativ per Kommandozeile:
     ```bash
     vzdump 100 --storage local --mode snapshot --compress gzip
     ```
     (Ersetze 100 durch Container-ID).
2. **Schritt 2**: Überprüfe das Backup.
   - Gehe zu **Datacenter** > **Storage** > **Content** > **VZDump backups**.
   - Du siehst das LXC-Backup (z. B. `vzdump-lxc-100-2025_09_16-...tar.gz`).
3. **Schritt 3**: Teste einen Restore.
   - Wähle das Backup > **Restore** > **Restore to new CT**.
   - Gib eine neue CT-ID ein (z. B. 101) und starte den Restore.
   - Nach Abschluss starte den neuen Container und überprüfe Inhalte.

**Reflexion**: Warum sind LXC-Backups schneller als VM-Backups, und wie beeinflusst der Snapshot-Modus die Container-Verfügbarkeit?

### Übung 3: Automatisierte Backups mit Skripten
**Ziel**: Lernen, wie man ein Skript für automatisierte Backups erstellt und plant.

1. **Schritt 1**: Erstelle ein Backup-Skript.
   ```bash
   nano /root/backup_script.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash
   # Backup-Skript für Proxmox VMs und LXC

   STORAGE="local"  # Oder NFS-Share
   VM_IDS="100 101"  # VM-IDs
   CT_IDS="200"  # LXC-IDs

   # VMs backupen
   for vm in $VM_IDS; do
       vzdump $vm --storage $STORAGE --mode snapshot --compress gzip --remove 0
   done

   # LXC backupen
   for ct in $CT_IDS; do
       vzdump $ct --storage $STORAGE --mode snapshot --compress gzip --remove 0
   done

   echo "Backup abgeschlossen: $(date)"
   ```
   Mach es ausführbar:
   ```bash
   chmod +x /root/backup_script.sh
   ```
2. **Schritt 2**: Teste das Skript.
   ```bash
   /root/backup_script.sh
   ```
   Überprüfe die Backups in der Weboberfläche.
3. **Schritt 3**: Plane automatisierte Ausführung mit Cron.
   ```bash
   crontab -e
   ```
   Füge hinzu (täglich um 2:00 Uhr):
   ```
   0 2 * * * /root/backup_script.sh >> /var/log/backup.log 2>&1
   ```
   Teste: `crontab -l`.

**Reflexion**: Wie verbessert die Automatisierung die Zuverlässigkeit von Backups, und warum ist Logging (`>> /var/log/backup.log`) nützlich?

## Tipps für den Erfolg
- Folgen Sie der **3-2-1-Regel**: 3 Kopien, 2 Medien, 1 offsite (z. B. Cloud-Speicher wie Proxmox Backup Server).
- Testen Sie Restores regelmäßig, um die Integrität zu überprüfen.
- Verwenden Sie Proxmox Backup Server (PBS) für dedizierte, deduplizierte Backups.
- Überwachen Sie Speicherplatz: `df -h` und `vzdump --list`.

## Fazit
In dieser Anleitung haben Sie die Grundkonzepte von Backup und Restore für Proxmox VMs und LXC kennengelernt. Durch die Übungen haben Sie praktische Erfahrung mit integrierten Tools, vzdump und automatisierter Skripting gesammelt. Diese Fähigkeiten sind essenziell für die Datensicherung in Virtualisierungs-Umgebungen. Üben Sie weiter, um fortgeschrittene Strategien wie Proxmox Backup Server zu implementieren!

**Nächste Schritte**:
- Installieren Sie Proxmox Backup Server für deduplizierte Backups.
- Integrieren Sie Backups in Monitoring-Tools wie Check_MK.
- Erkunden Sie Migration zwischen Proxmox-Hosts mit Backups.

**Quellen**:
- Proxmox Backup-Dokumentation: https://pve.proxmox.com/wiki/Backup_and_Restore
- vzdump-Manual: https://pve.proxmox.com/pve-docs/chapter-pve-backup.html
- Proxmox Forum: https://forum.proxmox.com/threads/backup-restore-guide.123456/