# Übersicht und Anleitung: Shared Storage für Proxmox VE (Ceph, NFS, iSCSI)

## Einführung

Shared Storage ist in Proxmox Virtual Environment (PVE) entscheidend für Hochverfügbarkeit (HA) und Live-Migration von virtuellen Maschinen (VMs) ohne Ausfallzeiten. Im Gegensatz zu lokalem Speicher ermöglicht Shared Storage, dass alle Cluster-Knoten direkten Zugriff auf VM-Disk-Images haben. Diese Anleitung vergleicht die drei gängigen Shared-Storage-Optionen für Proxmox – **Ceph**, **NFS** und **iSCSI** – und bietet praktische Anleitungen zur Einrichtung. Sie basiert auf der Proxmox-Dokumentation (https://pve.proxmox.com/wiki/Storage) und Community-Diskussionen. Die Anleitung ist für HomeLab-Nutzer und Unternehmensumgebungen geeignet, die Proxmox VE 8.3 oder neuer verwenden.

**Voraussetzungen**:
- Proxmox VE Cluster mit mindestens 3 Knoten (für HA und Ceph empfohlen).
- Netzwerk mit mindestens 10 GbE (25 GbE oder höher für Ceph bevorzugt).
- Hardware: Mindestens 32 GB RAM pro Knoten für Ceph, 16 GB für NFS/iSCSI; SSDs für Performance.
- Zugriff auf die Proxmox-Weboberfläche (`https://<IP>:8006`) oder SSH.
- Optional: TrueNAS, Synology oder andere NAS/SAN für NFS/iSCSI.

**Hinweis**: Die Wahl des Shared Storage hängt von Performance, Skalierbarkeit, Budget und Datensicherheitsanforderungen ab.

## Übersicht der Shared-Storage-Optionen

### 1. Ceph
**Beschreibung**: Ceph ist ein verteiltes Speichersystem, das in Proxmox nativ integriert ist. Es bietet Block-, Datei- und Objektspeicher (RBD, CephFS) und unterstützt Thin Provisioning, Snapshots und Replikation. Ceph speichert Daten über mehrere Knoten, ideal für hyperkonvergente Infrastrukturen (HCI).

**Vorteile**:
- **Hochverfügbarkeit**: Daten werden über Knoten repliziert (z. B. 3 Kopien), keine Single Point of Failure (SPoF).
- **Skalierbarkeit**: Einfaches Hinzufügen von OSDs (Object Storage Daemons) oder Knoten.
- **Snapshots und Thin Provisioning**: Unterstützt effiziente Snapshots und platzsparende Speicherzuweisung.
- **Integration**: Nahtlos in Proxmox integriert, verwaltbar über die Weboberfläche.
- **Selbstheilung**: Automatische Erkennung und Wiederherstellung von Datenfehlern.

**Nachteile**:
- **Hoher Ressourcenbedarf**: Benötigt viel RAM (1 GB pro TB + 8 GB Basis) und CPU, besonders bei kleinen Clustern.
- **Komplexität**: Erfordert Planung (z. B. Netzwerk, OSDs) und Wartungskenntnisse.
- **Performance**: Kann bei kleinen Clustern (z. B. 3 Knoten) oder bei random I/O langsamer sein als iSCSI.
- **Netzwerkabhängigkeit**: Erfordert stabiles, schnelles Netzwerk (mindestens 10 GbE, besser 40 GbE).

**Einsatzbereich**: Unternehmensumgebungen, hyperkonvergente Setups mit mindestens 5 Knoten, hohe Anforderungen an HA und Skalierbarkeit.

**Quelle**: https://pve.proxmox.com/wiki/Storage,[](https://readyspace.com/proxmox-ceph-vs-zfs/)

### 2. NFS
**Beschreibung**: NFS (Network File System) ist ein dateibasiertes Protokoll, das VM-Images (z. B. im `qcow2`-Format) auf einem NAS wie TrueNAS oder Synology speichert. Proxmox unterstützt NFS für VMs, LXC, ISOs und Backups.

**Vorteile**:
- **Einfachheit**: Schnelle Einrichtung, ideal für bestehende NAS-Systeme.
- **Snapshots**: Unterstützt Snapshots mit `qcow2`-Format.
- **Thin Provisioning**: Effiziente Speichernutzung mit `qcow2`.
- **Flexibilität**: Kann ISOs, Backups und Container speichern, im Gegensatz zu blockbasierten Systemen.
- **Geringerer Overhead**: Weniger RAM- und CPU-Bedarf als Ceph.

**Nachteile**:
- **Performance**: Höhere Latenz als iSCSI oder Ceph, besonders bei intensiven Workloads.
- **Netzwerkabhängigkeit**: Empfindlich gegenüber Netzwerkunterbrechungen, kann zu stale Mounts führen.
- **Single Point of Failure**: NAS ohne Dual-Controller ist ein Risiko für HA.
- **Keine Selbstheilung**: Keine automatische Datenreparatur wie bei ZFS oder Ceph.

**Einsatzbereich**: HomeLabs, kleine bis mittlere Umgebungen mit bestehendem NAS, moderate I/O-Anforderungen.

**Quelle**: https://pve.proxmox.com/wiki/Storage,,[](https://www.reddit.com/r/Proxmox/comments/1fsc81e/still_need_ceph_when_using_iscsi_shared_storage/)[](https://www.reddit.com/r/Proxmox/comments/10japnq/shared_storage_with_thin_provisioning/)

### 3. iSCSI
**Beschreibung**: iSCSI bietet blockbasierten Zugriff auf Speicher (z. B. über ein SAN wie TrueNAS). Proxmox unterstützt iSCSI direkt oder mit LVM/ZFS on top, wobei ZFS over iSCSI Snapshots ermöglicht.

**Vorteile**:
- **Performance**: Niedrige Latenz, ideal für I/O-intensive Workloads (z. B. Datenbanken).
- **Einfache Integration**: Funktioniert mit bestehenden SANs (z. B. Dell PowerVault, TrueNAS).
- **Multipathing**: Unterstützt redundante Netzwerkpfade für höhere Verfügbarkeit.
- **Flexibilität**: Kann mit LVM (keine Snapshots) oder ZFS (Snapshots) kombiniert werden.

**Nachteile**:
- **Keine Snapshots (LVM)**: LVM über iSCSI unterstützt keine VM-Snapshots, nur Backups via Proxmox Backup Server (PBS).
- **Komplexität**: Multipathing und SAN-Konfiguration erfordern Know-how.
- **Single Point of Failure**: Ohne Dual-Controller-SAN besteht ein Ausfallrisiko.
- **Kein Thin Provisioning (LVM)**: LVM verwendet Thick Provisioning, was Speicher ineffizient nutzen kann.

**Einsatzbereich**: Unternehmensumgebungen mit bestehendem SAN, hohe Performance-Anforderungen, weniger Fokus auf Snapshots.

**Quelle**: https://pve.proxmox.com/wiki/Storage,,[](https://forum.proxmox.com/threads/proxmox-vs-esxi-storage-performance-tuning-iscsi.157346/)[](https://pve.proxmox.com/pve-docs/chapter-pvesm.html)

## Vergleichstabelle

| **Kriterium**            | **Ceph**              | **NFS**               | **iSCSI**             |
|--------------------------|-----------------------|-----------------------|-----------------------|
| **Typ**                  | Verteiltes Block/Datei/Objekt | Dateibasiert         | Blockbasiert          |
| **Hochverfügbarkeit**    | Hoch (Replikation)    | Mittel (NAS-abhängig) | Mittel (SAN-abhängig) |
| **Snapshots**            | Ja (RBD)              | Ja (`qcow2`)          | Ja (ZFS), Nein (LVM)  |
| **Thin Provisioning**    | Ja                    | Ja (`qcow2`)          | Nein (LVM), Ja (ZFS)  |
| **Performance**          | Mittel bis Hoch       | Mittel                | Hoch                  |
| **RAM-Bedarf**           | Hoch (32 GB+ pro Knoten) | Gering (8–16 GB)   | Gering (8–16 GB)      |
| **Netzwerk**             | 10–40 GbE erforderlich | 10 GbE empfohlen    | 10–25 GbE empfohlen   |
| **Komplexität**          | Hoch                  | Niedrig               | Mittel                |
| **Einsatzbereich**       | HCI, große Cluster    | HomeLab, NAS          | SAN, Performance       |

## Anleitung: Einrichtung von Shared Storage in Proxmox

### Vorbereitung
1. **Cluster einrichten**:
   - Erstelle einen Proxmox-Cluster mit mindestens 3 Knoten:
     ```bash
     pvecm create mycluster
     ```
   - Füge Knoten hinzu:
     ```bash
     pvecm add <IP-of-first-node>
     ```
2. **Netzwerk prüfen**:
   - Stelle sicher, dass ein schnelles Netzwerk (mindestens 10 GbE) verfügbar ist.
   - Konfiguriere separate Netzwerke für Cluster-Traffic und Storage (z. B. VLANs).
3. **Backup planen**: Nutze Proxmox Backup Server (PBS) für inkrementelle Backups, besonders bei iSCSI ohne Snapshots.

### Einrichtung von Ceph
1. **Ceph installieren**:
   - In der Weboberfläche: `Datacenter > Ceph > Install Ceph`.
   - Wähle alle Cluster-Knoten aus, installiere Ceph-Pakete.
2. **Ceph-Cluster initialisieren**:
   - Erstelle einen Monitor auf jedem Knoten:
     ```bash
     pveceph mon create
     ```
   - Erstelle einen Manager:
     ```bash
     pveceph mgr create
     ```
3. **OSDs hinzufügen**:
   - Füge SSDs/NVMes pro Knoten als OSDs hinzu (mindestens 3 Knoten, 3–5 OSDs pro Knoten):
     ```bash
     pveceph disk init /dev/nvme0n1
     pveceph osd create /dev/nvme0n1
     ```
4. **Pool erstellen**:
   - Erstelle einen RBD-Pool für VMs:
     ```bash
     pveceph pool create vmdata
     ```
5. **Speicher in Proxmox hinzufügen**:
   - Gehe zu `Datacenter > Storage > Add > RBD`, wähle den Pool `vmdata`.
6. **Replikation einstellen**:
   - Stelle sicher, dass die Replikationsgröße auf 3 gesetzt ist (Standard):
     ```bash
     ceph osd pool set vmdata size 3
     ```

**Tipp**: Verwende enterprise-grade SSDs (z. B. Samsung PM983) und mindestens 40 GbE für optimale Performance. Plane 1 GB RAM pro TB Speicher.

**Quelle**: https://pve.proxmox.com/wiki/Storage#_ceph_rados_block_device_rbd,[](https://readyspace.com/proxmox-ceph-vs-zfs/)

### Einrichtung von NFS
1. **NAS vorbereiten** (z. B. TrueNAS):
   - Erstelle eine NFS-Freigabe auf dem NAS (z. B. `/mnt/tank/vmdata`).
   - Stelle sicher, dass Proxmox-Knoten Zugriff haben (NFS-Berechtigungen).
2. **NFS-Speicher hinzufügen**:
   - In der Weboberfläche: `Datacenter > Storage > Add > NFS`.
   - Gib die NAS-IP, Export-Pfad (z. B. `/mnt/tank/vmdata`) und Inhalt (`Images, Containers, ISO`) ein.
   - Beispiel CLI-Befehl:
     ```bash
     pvesm add nfs vmstore --server 192.168.1.100 --export /mnt/tank/vmdata --content images,iso,rootdir
     ```
3. **Snapshots aktivieren**:
   - Stelle sicher, dass VMs `qcow2`-Format verwenden (Standard für NFS).
   - Erstelle Snapshots in der Weboberfläche: `VM > Snapshots > Create`.

**Tipp**: Verwende NFS 4.2 mit `nconnect=2` für bessere Performance:
```bash
mount -o vers=4.2,nconnect=2 192.168.1.100:/mnt/tank/vmdata /mnt/pve/vmstore
```

**Quelle**: https://pve.proxmox.com/wiki/Storage#_nfs_backend,,[](https://www.reddit.com/r/Proxmox/comments/1fsc81e/still_need_ceph_when_using_iscsi_shared_storage/)[](https://www.virtualizationhowto.com/2025/08/5-storage-projects-to-supercharge-your-home-lab-this-weekend/)

### Einrichtung von iSCSI
1. **SAN vorbereiten** (z. B. TrueNAS):
   - Erstelle eine iSCSI-Target mit einem ZFS-Zvol (für Snapshots) oder LVM-Volume.
   - Beispiel ZFS-Zvol auf TrueNAS:
     ```bash
     zfs create -V 1T tank/vmdata
     ```
2. **iSCSI in Proxmox hinzufügen**:
   - Gehe zu `Datacenter > Storage > Add > iSCSI`.
   - Gib die Portal-IP (z. B. `192.168.1.100`) und Target ein.
   - Beispiel CLI-Befehl:
     ```bash
     pvesm add iscsi san1 --portal 192.168.1.100 --target iqn.2025-09.com.example:vmdata
     ```
3. **ZFS oder LVM hinzufügen**:
   - Für Snapshots: Füge ZFS over iSCSI hinzu:
     ```bash
     pvesm add zfsoniscsi zfs1 --portal 192.168.1.100 --pool tank/vmdata --blocksize 8k
     ```
   - Für LVM: Füge LVM über iSCSI hinzu:
     ```bash
     pvesm add lvm lvm1 --vgname pve-vg --base san1
     ```
4. **Multipathing aktivieren** (optional):
   - Konfiguriere Multipath auf Proxmox-Knoten:
     ```bash
     apt install multipath-tools
     multipath -ll
     ```
   - Bearbeite `/etc/multipath.conf` für optimale Einstellungen.

**Tipp**: Verwende ZFS over iSCSI für Snapshots oder Proxmox Backup Server für inkrementelle Backups bei LVM.

**Quelle**: https://pve.proxmox.com/wiki/Storage#_iscsi_backend,,[](https://forum.proxmox.com/threads/proxmox-vs-esxi-storage-performance-tuning-iscsi.157346/)[](https://pve.proxmox.com/pve-docs/chapter-pvesm.html)

## Empfehlungen für Anwendungsfälle

- **HomeLab (kleine Cluster, begrenztes Budget)**:
  - **Empfehlung**: NFS.
  - **Begründung**: Einfache Einrichtung, Unterstützung für Snapshots und Thin Provisioning, ideal für bestehende NAS-Lösungen wie TrueNAS.
  - **Beispiel**: TrueNAS Scale mit 10 GbE, NFS-Freigabe für 5–10 VMs.

- **Unternehmensumgebung (HA, große Workloads)**:
  - **Empfehlung**: Ceph oder iSCSI mit ZFS.
  - **Begründung**: Ceph bietet Skalierbarkeit und HA, iSCSI mit ZFS kombiniert hohe Performance mit Snapshots.
  - **Beispiel**: 5-Knoten-Ceph-Cluster mit NVMe SSDs oder TrueNAS mit ZFS over iSCSI und 25 GbE.

- **Performance-kritische Anwendungen**:
  - **Empfehlung**: iSCSI mit LVM oder ZFS.
  - **Begründung**: Niedrige Latenz, ideal für Datenbanken oder I/O-intensive VMs.
  - **Beispiel**: SAN mit Dual-Controller, iSCSI mit Multipathing für 20+ VMs.

- **Experimentelle Setups**:
  - **Empfehlung**: Ceph.
  - **Begründung**: Lernmöglichkeiten durch hyperkonvergente Architektur, aber Vorsicht bei kleinen Clustern (Performance-Einbußen).

## Tipps für den Erfolg
- **Netzwerkoptimierung**: Verwende Jumbo Frames (MTU 9000) für iSCSI und NFS, 40 GbE für Ceph.
- **Redundanz**: Vermeide SPoF durch Dual-Controller-SANs oder mindestens 5 Ceph-Knoten.
- **Backups**: Nutze Proxmox Backup Server (PBS) für effiziente Backups, besonders bei iSCSI ohne Snapshots.
- **Wartung**: Führe regelmäßige Ceph-Scans (`ceph health`) oder ZFS-Scrubs durch.
- **Testumgebung**: Baue ein Test-Cluster (z. B. mit Intel NUCs) zur Evaluierung.

## Fazit
- **Ceph**: Ideal für hyperkonvergente Cluster mit hoher Skalierbarkeit und HA, aber ressourcenintensiv.
- **NFS**: Einfach und flexibel für HomeLabs oder kleinere Umgebungen, jedoch netzwerkabhängig.
- **iSCSI**: Beste Performance für blockbasierte Workloads, aber eingeschränkte Snapshot-Unterstützung mit LVM.

Für HomeLabs ist NFS oft die beste Wahl wegen der Einfachheit und Flexibilität. In Unternehmensumgebungen mit hohen Anforderungen an HA und Performance sind Ceph oder iSCSI (mit ZFS) vorzuziehen. Teste die Konfiguration in einer nicht-produktiven Umgebung, bevor du sie einsetzt.