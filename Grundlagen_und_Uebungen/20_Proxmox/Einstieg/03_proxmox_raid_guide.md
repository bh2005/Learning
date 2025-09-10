# Anleitung: RAID in Proxmox VE

## Einführung

RAID (Redundant Array of Independent Disks) ist eine Technologie zur Verbesserung der Datensicherheit und Performance durch die Kombination mehrerer Festplatten. In Proxmox Virtual Environment (PVE) wird RAID häufig mit Dateisystemen wie ZFS oder Hardware-RAID-Controllern verwendet, um virtuelle Maschinen (VMs), Container (LXC) und Shared Storage zuverlässig zu betreiben. Diese Anleitung bietet eine Übersicht über RAID-Typen, deren Vor- und Nachteile, und praktische Schritte zur Einrichtung von RAID in Proxmox, insbesondere für ZFS und Hardware-RAID. Sie basiert auf der Proxmox-Dokumentation (https://pve.proxmox.com/wiki/Storage) und ist für HomeLab-Nutzer sowie Unternehmensumgebungen mit Proxmox VE 8.3 geeignet.

**Voraussetzungen**:
- Proxmox VE auf einem Server mit mindestens 16 GB RAM (32 GB+ für ZFS empfohlen).
- Mindestens zwei SSDs oder HDDs für RAID (NVMe bevorzugt für Performance).
- Optional: Hardware-RAID-Controller (z. B. LSI/Broadcom, Dell PERC) für Hardware-RAID.
- Zugriff auf die Proxmox-Weboberfläche (`https://<IP>:8006`) oder SSH.
- Grundkenntnisse in Linux, ZFS und Speicherverwaltung.

**Hinweis**: Die Wahl des RAID-Typs hängt von den Anforderungen an Redundanz, Performance und Speicherplatz ab. ZFS-RAID ist in Proxmox besonders beliebt aufgrund seiner Integration und Funktionen wie Snapshots.

## Übersicht der RAID-Typen

RAID gibt es in verschiedenen Leveln, die unterschiedliche Kombinationen von Redundanz, Performance und Kapazität bieten. Die gängigsten für Proxmox sind:

### RAID 0 (Striping)
- **Beschreibung**: Daten werden über mehrere Laufwerke verteilt (gestreift), ohne Redundanz.
- **Vorteile**:
  - Maximale Performance (Lese- und Schreibgeschwindigkeit skaliert mit Anzahl der Laufwerke).
  - Nutzt gesamten Speicherplatz (kein Overhead).
- **Nachteile**:
  - Keine Redundanz: Ausfall eines Laufwerks führt zu vollständigem Datenverlust.
  - Nicht für kritische Daten geeignet.
- **Einsatzbereich**: Testumgebungen oder Cache-Layer (z. B. ZFS L2ARC), wo Performance wichtiger als Datensicherheit ist.

### RAID 1 (Mirroring)
- **Beschreibung**: Daten werden auf zwei oder mehr Laufwerke gespiegelt (identische Kopien).
- **Vorteile**:
  - Hohe Redundanz: Bis zu n-1 Laufwerke können ausfallen (bei n Kopien).
  - Gute Lese-Performance (Daten können von allen Spiegeln gelesen werden).
- **Nachteile**:
  - Schreib-Performance ähnlich wie ein einzelnes Laufwerk.
  - Hoher Speicher-Overhead: Nur 50% der Kapazität nutzbar (bei 2 Spiegeln).
- **Einsatzbereich**: HomeLabs, kleine Unternehmen mit Fokus auf Datensicherheit.

### RAID 5 (Parity)
- **Beschreibung**: Daten und Paritätsinformationen werden über mindestens drei Laufwerke verteilt. Ein Laufwerk kann ausfallen.
- **Vorteile**:
  - Gute Balance zwischen Redundanz und Speicher: n-1 Laufwerke nutzbar.
  - Gute Lese-Performance.
- **Nachteile**:
  - Schreib-Performance langsamer durch Paritätsberechnung.
  - Wiederherstellung (Rebuild) nach Ausfall kann lange dauern und SSDs belasten.
  - Nur ein Laufwerk kann ausfallen.
- **Einsatzbereich**: Mittlere Umgebungen mit moderatem Budget, wo Speicherplatz wichtig ist.

### RAID 6 (Double Parity)
- **Beschreibung**: Ähnlich wie RAID 5, aber mit zwei Paritätsblöcken (mindestens vier Laufwerke). Zwei Laufwerke können ausfallen.
- **Vorteile**:
  - Höhere Redundanz als RAID 5: Zwei Laufwerke können ausfallen.
  - Gute Speicher-Effizienz: n-2 Laufwerke nutzbar.
- **Nachteile**:
  - Noch höherer Schreib-Overhead als RAID 5.
  - Längere Rebuild-Zeiten, besonders bei großen HDDs.
- **Einsatzbereich**: Unternehmensumgebungen mit hohen Datensicherheitsanforderungen.

### RAID-Z (ZFS-spezifisch)
- **Beschreibung**: ZFS-equivalent zu RAID 5 (RAID-Z1), RAID 6 (RAID-Z2) oder RAID 7 (RAID-Z3), mit integrierter Datenintegrität und Selbstheilung.
- **Vorteile**:
  - Bitrot-Schutz durch Checksumming.
  - Snapshots, Komprimierung und Replikation nativ in ZFS.
  - Selbstheilung bei erkannten Datenfehlern.
- **Nachteile**:
  - Hoher RAM-Bedarf (mindestens 16 GB, besser 32 GB+).
  - Komplexe Konfiguration und Wartung (z. B. Scrubbing).
  - RAID-Z-Pools sind schwer erweiterbar ohne zusätzliche VDevs.
- **Einsatzbereich**: Proxmox-Setups mit Fokus auf Datensicherheit und fortgeschrittene Funktionen.

### RAID 10 (1+0)
- **Beschreibung**: Kombination aus RAID 1 (Mirroring) und RAID 0 (Striping), mindestens vier Laufwerke.
- **Vorteile**:
  - Hohe Performance (Lese- und Schreibgeschwindigkeit).
  - Hohe Redundanz: Bis zu 50% der Laufwerke können ausfallen (je nach Konfiguration).
- **Nachteile**:
  - Hoher Speicher-Overhead: Nur 50% der Kapazität nutzbar.
  - Höhere Kosten durch mehr Laufwerke.
- **Einsatzbereich**: Performance-kritische Umgebungen mit hohen Datensicherheitsanforderungen.

## Vergleichstabelle

| **RAID-Typ** | **Min. Laufwerke** | **Redundanz** | **Kapazität** | **Performance** | **Einsatzbereich** |
|--------------|--------------------|---------------|---------------|-----------------|---------------------|
| **RAID 0**   | 2                  | Keine         | 100%          | Sehr hoch       | Testumgebungen      |
| **RAID 1**   | 2                  | 1 Ausfall     | 50%           | Mittel (Lesen hoch) | HomeLabs, kleine Setups |
| **RAID 5**   | 3                  | 1 Ausfall     | n-1           | Mittel          | Mittlere Setups     |
| **RAID 6**   | 4                  | 2 Ausfälle    | n-2           | Mittel          | Unternehmen         |
| **RAID-Z1**  | 3                  | 1 Ausfall     | n-1           | Mittel          | ZFS, Datensicherheit |
| **RAID-Z2**  | 4                  | 2 Ausfälle    | n-2           | Mittel          | ZFS, Unternehmen    |
| **RAID 10**  | 4                  | Bis zu 50%    | 50%           | Hoch            | Performance-kritisch |

## Anleitung: Einrichtung von RAID in Proxmox

### Vorbereitung
1. **Hardware prüfen**:
   - Mindestens 2–4 SSDs/NVMes (enterprise-grade, z. B. Samsung PM983) für RAID.
   - ECC-RAM für ZFS (mindestens 16 GB, besser 32 GB+).
   - Optional: Hardware-RAID-Controller mit Battery Backup Unit (BBU) für Schreib-Cache.
2. **Backup erstellen**: Stelle sicher, dass alle Daten gesichert sind, bevor du RAID konfigurierst.
3. **Netzwerk**: Verwende 10 GbE oder schneller für Cluster- und Storage-Traffic.
4. **Proxmox aktualisieren**:
   ```bash
   apt update && apt full-upgrade
   ```

### Einrichtung von ZFS-RAID (RAID-Z1 oder Mirror)
1. **Proxmox-Installer mit ZFS**:
   - Boote von der Proxmox ISO und wähle „Install Proxmox VE (Graphical)“.
   - Unter „Advanced Options“ wähle ZFS und den gewünschten RAID-Typ:
     - **Mirror** (RAID 1): 2 Laufwerke.
     - **RAID-Z1**: Mindestens 3 Laufwerke.
     - Beispiel für RAID-Z1 mit 3 SSDs:
       ```bash
       zpool create -f pve raidz1 /dev/nvme0n1 /dev/nvme1n1 /dev/nvme2n1
       ```
2. **ZFS-Dataset für VMs erstellen**:
   - Nach der Installation:
     ```bash
     zfs create pve/vmdata
     zfs set mountpoint=/vmdata pve/vmdata
     zfs set compression=lz4 pve/vmdata
     ```
3. **Speicher in Proxmox hinzufügen**:
   - In der Weboberfläche: `Datacenter > Storage > Add > ZFS`.
   - Wähle den Pool `pve` oder Dataset `pve/vmdata`.
4. **Wartung einrichten**:
   - Automatisiertes Scrubbing (wöchentlich):
     ```bash
     echo "zpool scrub pve" > /etc/cron.weekly/zfs-scrub
     chmod +x /etc/cron.weekly/zfs-scrub
     ```
   - Überprüfe den Pool-Status:
     ```bash
     zpool status pve
     ```

**Tipp**: Verwende SSDs mit hoher Schreibausdauer (z. B. DWPD > 1) und aktiviere Komprimierung (`lz4`) für bessere Speichernutzung.

**Quelle**: https://pve.proxmox.com/wiki/ZFS_on_Linux

### Einrichtung von Hardware-RAID (z. B. RAID 5)
1. **RAID-Controller konfigurieren**:
   - Greife auf das RAID-Controller-BIOS zu (z. B. bei Dell PERC via F2 beim Booten).
   - Erstelle ein RAID-Array (z. B. RAID 5 mit 3+ SSDs):
     - Wähle Laufwerke, RAID-Level und Cache-Einstellungen (Write-Back mit BBU empfohlen).
   - Beispiel mit `megacli` (für LSI/Broadcom-Controller):
     ```bash
     megacli -CfgLdAdd -r5 '[252:0,252:1,252:2]' -a0
     ```
2. **Proxmox installieren**:
   - Boote von der Proxmox ISO und wähle ext4 oder LVM als Dateisystem.
   - Der RAID-Controller präsentiert das Array als ein einziges Laufwerk (`/dev/sda`).
3. **Speicher hinzufügen**:
   - In der Weboberfläche: `Datacenter > Storage > Add > Directory` für ext4 oder `LVM-Thin` für Thin Provisioning.
4. **Überwachung einrichten**:
   - Installiere Tools zur Überwachung (z. B. `megacli` oder `perccli`):
     ```bash
     apt install megacli
     megacli -LDInfo -Lall -aAll
     ```
   - Integriere RAID-Status in Proxmox-Monitoring (z. B. mit Checkmk).

**Tipp**: Aktiviere Write-Back-Cache nur mit BBU, um Datenverlust bei Stromausfall zu vermeiden.

**Quelle**: https://pve.proxmox.com/wiki/Hardware

### Einrichtung von RAID für Ceph
1. **Ceph-Vorbereitung**:
   - Stelle sicher, dass jeder Knoten mindestens 2–4 SSDs/NVMes für OSDs hat.
   - Vermeide RAID für Ceph-OSDs; Ceph verwaltet Redundanz selbst (Replikation oder Erasure Coding).
2. **OSDs hinzufügen**:
   - Initialisiere OSDs ohne RAID:
     ```bash
     pveceph disk init /dev/nvme0n1
     pveceph osd create /dev/nvme0n1
     ```
3. **Replikation einstellen**:
   - Setze die Replikationsgröße auf 3:
     ```bash
     ceph osd pool set vmdata size 3
     ```
4. **RAID für Cache (optional)**:
   - Verwende RAID 0 oder 1 für Journal/Write-Ahead-Log (WAL) SSDs:
     ```bash
     zpool create -f ceph-wal mirror /dev/sdb /dev/sdc
     pveceph osd create /dev/nvme0n1 --wal-device /dev/zvol/ceph-wal
     ```

**Tipp**: Verwende separate NVMe-SSDs für WAL/DB, um die Ceph-Performance zu steigern.

**Quelle**: https://pve.proxmox.com/wiki/Storage#_ceph_rados_block_device_rbd

## Empfehlungen für Anwendungsfälle

- **HomeLab (geringe Hardware, einfache Bedürfnisse)**:
  - **Empfehlung**: RAID 1 (ZFS Mirror).
  - **Begründung**: Einfache Einrichtung, gute Redundanz, Snapshots für Backups.
  - **Beispiel**: 2x 1 TB NVMe für ZFS Mirror, Proxmox Backup Server für Backups.

- **HomeLab mit Fokus auf Performance**:
  - **Empfehlung**: RAID 10 (Hardware-RAID).
  - **Begründung**: Hohe Lese- und Schreibgeschwindigkeit, Redundanz für bis zu 50% Ausfälle.
  - **Beispiel**: 4x 500 GB SSDs mit LSI-Controller, ext4 für einfache Verwaltung.

- **Unternehmensumgebung (HA, große Workloads)**:
  - **Empfehlung**: RAID-Z2 (ZFS) oder RAID 6 (Hardware).
  - **Begründung**: Schutz gegen zwei Laufwerksausfälle, Bitrot-Schutz (ZFS), Skalierbarkeit.
  - **Beispiel**: 6x 2 TB NVMe in RAID-Z2 für VM-Speicher, 40 GbE Netzwerk.

- **Ceph-Cluster**:
  - **Empfehlung**: Kein RAID für OSDs, RAID 1 für WAL/DB.
  - **Begründung**: Ceph übernimmt Redundanz; RAID für Cache verbessert Performance.
  - **Beispiel**: 5 Knoten mit 4 OSDs (NVMe) pro Knoten, 2x SSD für WAL/DB in RAID 1.

## Tipps für den Erfolg
- **Backups**: Implementiere immer ein Backup-Konzept (z. B. Proxmox Backup Server), da RAID kein Ersatz für Backups ist.
- **Monitoring**: Überwache RAID-Status mit Tools wie `zpool status` (ZFS) oder `megacli` (Hardware-RAID).
- **Hardware**: Verwende enterprise-grade SSDs mit hoher Schreibausdauer (DWPD > 1) und ECC-RAM für ZFS.
- **Rebuild-Zeiten**: Plane längere Rebuild-Zeiten bei RAID 5/6 oder RAID-Z1/Z2 ein, besonders bei großen HDDs.
- **Dokumentation**: Konsultiere https://pve.proxmox.com/wiki/Storage für Details zu RAID-Integration.

## Fazit
- **RAID 1/ZFS Mirror**: Ideal für HomeLabs mit Fokus auf Datensicherheit und einfache Einrichtung.
- **RAID 5/6 oder RAID-Z1/Z2**: Geeignet für Unternehmen mit Balance zwischen Redundanz und Speicher.
- **RAID 10**: Beste Wahl für Performance-kritische Anwendungen.
- **Ceph ohne RAID**: Optimal für hyperkonvergente Cluster, mit RAID nur für Cache-Layer.

Die Wahl des RAID-Typs hängt von deinen Prioritäten ab: Redundanz (RAID 1, RAID-Z2), Performance (RAID 10, RAID 0) oder Speicher-Effizienz (RAID 5, RAID-Z1). Teste die Konfiguration in einer nicht-produktiven Umgebung, bevor du sie einsetzt.

**Nächste Schritte**: Möchtest du eine detaillierte Anleitung zur Optimierung von ZFS-RAID (z. B. SLOG, L2ARC) oder zur Integration von Hardware-RAID mit Proxmox Backup Server?

**Quellen**:
- Proxmox-Dokumentation: https://pve.proxmox.com/wiki/Storage
- ZFS-Dokumentation: https://pve.proxmox.com/wiki/ZFS_on_Linux
- Community-Diskussionen:,,,,