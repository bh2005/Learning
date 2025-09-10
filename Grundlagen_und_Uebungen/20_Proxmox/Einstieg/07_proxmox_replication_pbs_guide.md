# Anleitung: Replikation und Proxmox Backup Server (OSS Edition)

## Einführung

**Replikation** in Proxmox VE ermöglicht die Übertragung von virtuellen Maschinen (VMs) und Linux Containern (LXC) zwischen Knoten eines Clusters, um Hochverfügbarkeit (HA) oder Disaster Recovery zu gewährleisten. **Proxmox Backup Server (PBS)** ist eine Open-Source-Backup-Lösung (GNU AGPLv3), die inkrementelle, deduplizierte und verschlüsselte Backups von VMs, LXC und physischen Hosts unterstützt. Die Kombination von Replikation und PBS bietet eine robuste Strategie für Datensicherheit und Wiederherstellung, insbesondere mit der 3-2-1-Backup-Regel (drei Kopien, zwei Medien, eine Off-Site). Diese Anleitung erklärt die Einrichtung, Konfiguration und Best Practices für Replikation und PBS 4.0 in Proxmox VE 9.0, optimiert für HomeLabs und Unternehmensumgebungen.

**Voraussetzungen**:
- Proxmox VE 9.0 auf mindestens 2 Knoten (3+ für HA/Quorum).
- Hardware: Mindestens 32 GB ECC-RAM, 8–16 Kerne, 2x 1 TB NVMe pro Knoten, 10 GbE Netzwerk.
- Shared Storage (z. B. Ceph, ZFS, NFS, iSCSI) für Replikation.
- Proxmox Backup Server 4.0 (dedizierter Server oder VM, vorzugsweise auf separater Hardware).
- Zugriff auf die Proxmox-Weboberfläche (`https://<IP>:8006`) und PBS-Weboberfläche (`https://<IP>:8007`).
- Grundkenntnisse in Linux, ZFS, Netzwerkkonfiguration und Virtualisierung.

**Hinweis**: Replikation erfordert ZFS als Speicher-Backend für VMs/LXC. PBS kann mit beliebigen Speichern arbeiten, empfiehlt aber ZFS für Deduplizierung.

**Quellen**: 
- Proxmox-Dokumentation: https://pve.proxmox.com/wiki/Replication, https://www.proxmox.com/en/proxmox-backup-server
- Webquellen:,,,,,,[](https://www.it-administrator.de/Proxmox-Backup-Server-4)[](https://www.proxmox.com/en/products/proxmox-backup-server/overview)[](https://www.etes.de/blog/remote-replikation-mit-proxmox-backup-server/)

## Replikation in Proxmox VE

### Konzept
Replikation in Proxmox VE synchronisiert VM- und LXC-Disk-Images zwischen Knoten eines Clusters mithilfe von ZFS-Snapshots. Sie basiert auf:
- **Initialer Transfer**: Komplettes Disk-Image wird kopiert.
- **Delta-Updates**: Nur Änderungen (Deltas) seit dem letzten Snapshot werden übertragen.
- **Planung**: Regelmäßige Replikationsjobs (z. B. stündlich, täglich).
- **Voraussetzung**: ZFS-Speicher auf allen Knoten, identische Pool-Namen, Cluster-Konfiguration.

**Vorteile**:
- Schnelle Wiederherstellung bei Knoten-Ausfall.
- Unterstützt HA (automatischer Neustart auf anderem Knoten).
- Geringe Bandbreitenanforderungen durch Delta-Updates.

**Nachteile**:
- Erfordert Cluster und ZFS.
- Keine Historie (Snapshots werden überschrieben).
- Manuelle Wiederherstellung ohne HA.

**Einsatzbereich**: HA-Umgebungen, Disaster Recovery, HomeLabs mit mehreren Knoten.

### Einrichtung der Replikation

#### Schritt 1: Cluster einrichten
1. **Cluster initialisieren** (auf Knoten 1):
   ```bash
   pvecm create mycluster
   ```
2. **Knoten hinzufügen** (auf Knoten 2 und 3):
   ```bash
   pvecm add <IP-of-node1> --link0 <IP-in-VLAN20>
   ```
3. **Cluster-Status prüfen**:
   ```bash
   pvecm status
   ```
   Stelle sicher, dass das Quorum erreicht ist (mindestens 2 Knoten, 3+ für HA).

**Tipp**: Verwende ein dediziertes 10 GbE-Netzwerk für Corosync (VLAN 20).

**Quelle**: https://pve.proxmox.com/wiki/Cluster_Manager

#### Schritt 2: ZFS-Speicher konfigurieren
1. **ZFS-Pool erstellen** (auf allen Knoten, identischer Name):
   ```bash
   zpool create -f rpool mirror /dev/nvme0n1 /dev/nvme1n1
   ```
2. **ZFS-Speicher in PVE hinzufügen**:
   - In der Weboberfläche: `Datacenter > Storage > Add > ZFS`.
   - Name: `rpool`, Pool: `rpool/data`, `Shared` aktivieren.
3. **Prüfen**:
   ```bash
   pvesm status
   ```

**Tipp**: Aktiviere Komprimierung (`zfs set compression=lz4 rpool`) für bessere Performance.

#### Schritt 3: Replikationsjob einrichten
1. **Job erstellen** (für VM 100):
   - In der Weboberfläche: `Datacenter > Replication > Add`.
   - Wähle VM 100, Zielknoten (z. B. node2), Intervall (z. B. 15 Minuten).
   - CLI-Alternative:
     ```bash
     pve-replication add 100 --target node2 --rate 100 --schedule */15
     ```
2. **Status prüfen**:
   ```bash
   pve-replication status
   ```
3. **Manuelle Replikation testen**:
   ```bash
   pve-replication run 100
   ```

**Tipp**: Plane Replikation außerhalb von Backup-Zeiten, um Storage-Last zu minimieren.

**Quelle**: https://pve.proxmox.com/wiki/Replication

#### Schritt 4: HA aktivieren (optional)
1. **HA-Gruppe erstellen**:
   - In der Weboberfläche: `Datacenter > HA > Groups > Create`.
   - Beispiel: Gruppe `ha-group1`, alle Knoten.
2. **VM für HA aktivieren**:
   ```bash
   ha-manager add vm:100 --group ha-group1
   ```
3. **Testen**:
   - Simuliere Knoten-Ausfall:
     ```bash
     systemctl poweroff
     ```
   - Prüfe, ob VM 100 auf Zielknoten startet:
     ```bash
     ha-manager status
     ```

**Tipp**: Konfiguriere Fencing (z. B. IPMI) für zuverlässige HA.

## Proxmox Backup Server (OSS Edition)

### Konzept
Proxmox Backup Server (PBS) 4.0 ist eine Open-Source-Backup-Lösung (GNU AGPLv3) für PVE, die inkrementelle, deduplizierte und verschlüsselte Backups unterstützt. Hauptmerkmale:
- **Deduplizierung**: Reduziert Speicherbedarf durch Entfernen doppelter Daten.
- **Komprimierung**: Zstandard (zstd) für platzsparende Backups.
- **Verschlüsselung**: AES-256-GCM, clientseitig, für sichere Übertragung und Speicherung.
- **Inkrementelle Backups**: Nur Änderungen seit dem letzten Backup werden gesichert.
- **Remote-Replikation**: Synchronisation von Backups zu einem entfernten PBS.

**Vorteile**:
- Platz- und bandbreiteneffizient durch Deduplizierung und Komprimierung.
- Unterstützt 3-2-1-Backup-Strategie (lokale und Off-Site-Backups).
- Einzeldatei-Wiederherstellung (außer für ZFS in VMs).
- Benutzerfreundliches Webinterface (Port 8007).

**Nachteile**:
- Deduplizierung erfordert ZFS für optimale Performance.
- Keine direkte S3-Unterstützung (in PBS 4.0 über Umwege möglich).
- Monitoring (z. B. mit Check_MK) erfordert manuelle Einrichtung.

**Einsatzbereich**: HomeLabs für kosteneffiziente Backups, Unternehmen für Enterprise-Backup-Strategien.

**Quelle**:,[](https://www.it-administrator.de/Proxmox-Backup-Server-4)[](https://www.schmidtisblog.de/proxmox-backup-server-4-0-leistungsstarke-open-source-loesung-fuer-modernstes-backup-management-1781716/)

### Einrichtung von PBS

#### Schritt 1: PBS installieren
1. **Dedicated Server** (empfohlen):
   - Lade das PBS 4.0 ISO von https://www.proxmox.com/en/downloads.
   - Installiere auf einem Server mit ZFS (z. B. 2x 1 TB NVMe, RAID 1).
2. **Alternative (HomeLab)**:
   - Installiere PBS als VM oder LXC auf einem PVE-Knoten:
     ```bash
     qm create 200 --name pbs --memory 4096 --cores 2 --net0 virtio,bridge=vmbr0 --scsi0 local-zfs:20
     ```
   - Binde eine separate SSD ein (z. B. 500 GB):
     ```bash
     qm set 200 --scsi1 /dev/nvme2n1
     ```
3. **ZFS-Pool erstellen** (auf PBS):
   ```bash
   zpool create -f pbs-pool /dev/nvme2n1
   zfs set compression=zstd pbs-pool
   ```

**Tipp**: Verwende ECC-RAM und RAID 1 für PBS, um Datenverlust zu vermeiden.

**Quelle**:,[](https://www.thomas-krenn.com/de/wiki/Proxmox_Backup_Server_Konfiguration)[](https://www.thomas-krenn.com/de/wiki/Proxmox_Backup_Server)

#### Schritt 2: Datastore einrichten
1. **Datastore erstellen** (via Webinterface, `https://<PBS-IP>:8007`):
   - `Datastore > Add Datastore`.
   - Name: `pbs-local`, Pfad: `/pbs-pool`.
   - Aktiviere Garbage Collection und Prune (z. B. behalte 7 tägliche Backups).
2. **CLI-Alternative**:
   ```bash
   proxmox-backup-manager datastore create pbs-local /pbs-pool
   proxmox-backup-manager prune pbs-local --keep-daily 7
   ```

**Tipp**: Nutze den Proxmox Prune Simulator (https://www.proxmox.com/en/downloads/item/proxmox-backup-server-prune-simulator) für optimale Retention-Einstellungen.

**Quelle**:[](https://www.thomas-krenn.com/de/wiki/Proxmox_Backup_Server_Konfiguration)

#### Schritt 3: PBS in PVE integrieren
1. **Fingerprint kopieren** (im PBS-Dashboard, `https://<PBS-IP>:8007`).
2. **PBS als Speicher hinzufügen** (in PVE, `Datacenter > Storage > Add > Proxmox Backup Server`):
   - ID: `pbs-backup`.
   - Server: `<PBS-IP>`.
   - Username: `root@pam`.
   - Datastore: `pbs-local`.
   - Fingerprint: `<PBS-Fingerprint>`.
   - CLI-Alternative:
     ```bash
     pvesm add pbs pbs-backup --server <PBS-IP> --datastore pbs-local --fingerprint <PBS-Fingerprint>
     ```
3. **Status prüfen**:
   ```bash
   pvesm status
   ```

#### Schritt 4: Backup-Job einrichten
1. **Backup-Job erstellen** (in PVE, `Datacenter > Backup > Add`):
   - Wähle VMs/LXC, Speicher: `pbs-backup`, Schedule: täglich um 04:00.
   - CLI-Alternative:
     ```bash
     pve-backup add daily-backup --storage pbs-backup --schedule "mon..sun 04:00" --all
     ```
2. **Manuelles Backup testen**:
   ```bash
   pve-backup run daily-backup
   ```
3. **Wiederherstellung testen**:
   - In PVE-Weboberfläche: `pbs-backup > Content > Restore`.
   - Einzeldatei-Wiederherstellung (für ext4/NTFS):
     - Wähle Backup, klicke auf `File Restore`.

**Tipp**: Verschlüssele Backups mit einem sicheren Schlüssel (z. B. auf USB oder in Passwort-Manager speichern).

**Quelle**:,[](https://blog.ordix.de/kein-backup-kein-mitleid-proxmox-backup-server)[](https://blog.unixa.de/re-review-proxmox-backup-server/)

## Remote-Replikation mit PBS

### Konzept
PBS unterstützt die Synchronisation von Backups zwischen einem lokalen und einem entfernten PBS (Remote-Replikation), ideal für die 3-2-1-Backup-Strategie:
- **3 Kopien**: Produktivdaten, lokales Backup, Off-Site-Backup.
- **2 Medien**: Z. B. NVMe (lokal), HDD (Off-Site).
- **1 Off-Site**: Backup auf einem PBS in einem anderen Rechenzentrum.

**Neu in PBS 4.0**:
- Unterstützung für CIFS/SMB-Mounts (z. B. NAS als Backup-Ziel).
- Automatische Sync-Jobs für wechselnde Datenspeicher.
- S3-kompatible Objektspeicher (experimentell).

**Quelle**:,[](https://www.it-administrator.de/Proxmox-Backup-Server-4)[](https://www.schmidtisblog.de/proxmox-backup-server-4-0-leistungsstarke-open-source-loesung-fuer-modernstes-backup-management-1781716/)

### Einrichtung der Remote-Replikation
1. **Zweiten PBS einrichten** (z. B. in anderem Rechenzentrum):
   - Installiere PBS 4.0 auf separatem Server.
   - Erstelle Datastore: `pbs-remote`.
2. **Sync-Job konfigurieren** (auf lokalem PBS):
   - In der Weboberfläche: `Sync Jobs > Add`.
   - Quelle: `pbs-local`, Ziel: `<Remote-PBS-IP>:pbs-remote`.
   - Schedule: Täglich um 02:00.
   - CLI-Alternative:
     ```bash
     proxmox-backup-manager sync-job create sync-to-remote --remote <Remote-PBS-IP> --remote-store pbs-remote --store pbs-local --schedule "mon..sun 02:00"
     ```
3. **Verschlüsselung prüfen**:
   - Stelle sicher, dass Daten clientseitig verschlüsselt sind (AES-256-GCM).
   ```bash
   proxmox-backup-client key create /root/backup-key
   ```
4. **Testen**:
   ```bash
   proxmox-backup-manager sync-job run sync-to-remote
   ```

**Tipp**: Nutze ein dediziertes 10 GbE-Netzwerk für Remote-Replikation (VLAN 40). Aktiviere Jumbo Frames (MTU 9000).

**Quelle**:[](https://www.etes.de/blog/remote-replikation-mit-proxmox-backup-server/)

## Best Practices

### Replikation
- **ZFS-Optimierung**: Aktiviere `lz4` oder `zstd` Komprimierung:
  ```bash
  zfs set compression=zstd rpool
  ```
- **Intervall**: Plane Replikation stündlich für HA, täglich für Disaster Recovery.
- **Speicher**: Verwende NVMe-SSDs (DWPD > 1) für ZFS-Pools.
- **Cluster**: Mindestens 3 Knoten für HA, um Quorum-Probleme zu vermeiden.
- **Monitoring**: Überwache Replikation mit Checkmk oder Prometheus:
  ```bash
  pve-replication status
  ```

### Proxmox Backup Server
- **Deduplizierung**: Verwende ZFS für maximale Effizienz. Prüfe Deduplizierungsrate:
  ```bash
  proxmox-backup-manager datastore show pbs-local
  ```
- **Retention**: Nutze Prune für automatische Bereinigung:
  ```bash
  proxmox-backup-manager prune pbs-local --keep-daily 7 --keep-weekly 4
  ```
- **Sicherheit**: Deaktiviere SSH-Passwort-Login, verwende API-Token mit eingeschränkten Rechten:
  ```bash
  proxmox-backup-manager user update backup-user --role DatastoreBackup
  ```
- **3-2-1-Strategie**: Kombiniere lokales PBS mit Remote-PBS oder CIFS/NFS (z. B. TrueNAS).
- **Monitoring**: Integriere PBS in Zabbix/Checkmk für Backup-Überwachung.

**Quelle**:,[](https://aow.de/books/dokumentation/page/backup-und-replikation-trojanersicher-fur-proxmox-ve-mit-miyagi-workflow)[](https://www.marcogriep.de/posts/proxmox-backup-server-einfuhrung-und-best-practices/)

### Kombination von Replikation und PBS
- **Strategie**: Nutze Replikation für schnelle Wiederherstellung (HA) und PBS für langfristige Backups.
- **Planung**: Vermeide Überschneidungen von Replikation und Backup-Jobs:
  - Replikation: 15-minütlich (08:00–20:00).
  - Backup: Täglich um 04:00.
- **Wiederherstellung**: Verwende PBS für historische Backups, Replikation für sofortige Failover.

## Empfehlungen für Anwendungsfälle

- **HomeLab (geringe Hardware)**:
  - **Setup**: 2 Knoten (Ryzen 7, 32 GB RAM, 2x 1 TB NVMe), PBS als VM auf separater SSD.
  - **Replikation**: Täglich zwischen Knoten, ZFS-Pool (`rpool`).
  - **PBS**: Lokales Backup auf SSD, Remote-Sync zu NAS (CIFS).
  - **Beispiel**: 5 LXC (Homeassistant, Nextcloud), 2 VMs (Ubuntu, Windows).

- **Unternehmensumgebung**:
  - **Setup**: 5 Knoten (Xeon Gold, 128 GB RAM, 6x 2 TB NVMe), dedizierter PBS-Server.
  - **Replikation**: Stündlich für HA, Ceph als Shared Storage.
  - **PBS**: Lokales Backup auf NVMe, Remote-Sync zu zweitem PBS in anderem Rechenzentrum.
  - **Beispiel**: 50 VMs (Datenbanken, Webserver), HA für kritische Dienste.

## Tipps für den Erfolg
- **Hardware**: Verwende ECC-RAM und RAID 1 für PBS, NVMe für Replikation.
- **Netzwerk**: Dediziertes 10 GbE für Replikation (VLAN 20) und PBS-Sync (VLAN 40).
- **Sicherheit**: Verschlüssele Backups und deaktiviere SSH-Passwort-Login:
  ```bash
  echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config
  systemctl restart sshd
  ```
- **Monitoring**: Überwache ZFS-Pools (`zpool status`) und PBS-Jobs (`proxmox-backup-manager task list`).
- **Testen**: Simuliere Knoten-Ausfälle und stelle Backups regelmäßig wieder her, um die Integrität zu prüfen.
- **Dokumentation**: Konsultiere https://pve.proxmox.com/wiki/Replication und https://www.proxmox.com/en/proxmox-backup-server.

## Fazit
- **Replikation**: Ideal für HA und schnelle Wiederherstellung in einem Cluster, erfordert ZFS und mindestens 2 Knoten.
- **PBS 4.0 (OSS)**: Kosteneffiziente, deduplizierte und verschlüsselte Backups, unterstützt Remote-Replikation für 3-2-1-Strategie.
- **Kombination**: Replikation für HA, PBS für langfristige Backups und Off-Site-Sicherung.

Teste die Konfiguration in einer nicht-produktiven Umgebung, um Probleme frühzeitig zu erkennen. Für HomeLabs reicht ein einfacher PBS auf einer VM mit NAS-Sync, während Unternehmen dedizierte PBS-Server und Remote-Replikation bevorzugen.

**Nächste Schritte**: Möchtest du eine detaillierte Anleitung zu ZFS-Tuning, Remote-Sync mit CIFS/S3 oder Integration mit Monitoring-Tools wie Checkmk?

**Quellen**:
- Proxmox-Dokumentation: https://pve.proxmox.com/wiki/Replication, https://www.proxmox.com/en/proxmox-backup-server
- Webquellen:,,,,,,[](https://www.it-administrator.de/Proxmox-Backup-Server-4)[](https://www.proxmox.com/en/products/proxmox-backup-server/overview)[](https://www.etes.de/blog/remote-replikation-mit-proxmox-backup-server/)