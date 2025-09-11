# Anleitung: Hardware Sizing und Cluster-Konfiguration für Proxmox VE

## Einführung

Ein gut geplanter Proxmox VE Cluster ermöglicht Hochverfügbarkeit (HA), Live-Migration und Skalierbarkeit für virtuelle Maschinen (VMs) und Linux Container (LXC). Die richtige Hardware-Dimensionierung und Netzwerkkonfiguration sind entscheidend für Performance, Stabilität und Datensicherheit. Diese Anleitung behandelt **Hardware Sizing**, **Netzwerk-Trennung** (für VMs, Quorum und Management) und die Integration von **Shared Storage** (Ceph, NFS, iSCSI). Sie ist für HomeLab-Nutzer und Unternehmensumgebungen geeignet, die Proxmox VE 8.3 oder neuer einsetzen, und basiert auf der Proxmox-Dokumentation (https://pve.proxmox.com/wiki/Cluster_Manager).

**Voraussetzungen**:
- Proxmox VE 8.3 auf mindestens 3 Servern (für HA und Quorum).
- Hardware: Mindestens 32 GB RAM pro Knoten (64 GB+ für Ceph), SSDs/NVMes, 10 GbE Netzwerk.
- Zugriff auf die Proxmox-Weboberfläche (`https://<IP>:8006`) oder SSH.
- Grundkenntnisse in Linux, Netzwerkkonfiguration und Virtualisierung.
- Optional: NAS/SAN für NFS/iSCSI oder enterprise-grade SSDs für Ceph.

**Hinweis**: Die Hardware- und Netzwerkplanung hängt von der Anzahl der VMs/LXC, Workload-Typen und HA-Anforderungen ab. Diese Anleitung bietet Empfehlungen für verschiedene Szenarien.

## Hardware Sizing für Proxmox VE Cluster

### 1. CPU
- **Anforderungen**:
  - Moderne Server-CPUs (z. B. AMD EPYC, Intel Xeon Scalable) für Unternehmen; AMD Ryzen oder Intel Core i7/i9 für HomeLabs.
  - Mindestens 8–16 Kerne pro Knoten für 10–20 VMs/LXC; mehr für intensive Workloads (z. B. Datenbanken, ML).
- **Empfehlungen**:
  - Unterstützung für Virtualisierung: VT-x/AMD-V, VT-d/AMD-Vi für Passthrough.
  - Skalierung: Plane 1–2 Kerne pro VM, 0.5–1 Kern pro LXC.
  - Beispiel: AMD Ryzen 9 5900X (12 Kerne, 24 Threads) für HomeLab mit 10 VMs; EPYC 7313 (16 Kerne) für Unternehmen mit 50 VMs.
- **Ceph-spezifisch**: Mindestens 4–6 zusätzliche Kerne pro Knoten für OSDs und MONs.

### 2. RAM
- **Anforderungen**:
  - Mindestens 16 GB für HomeLabs, 32–64 GB für Unternehmen, 128 GB+ für Ceph-Cluster.
  - ZFS: 1 GB RAM pro 1 TB Speicher + 8 GB Basisbedarf.
  - Ceph: 1 GB RAM pro TB OSD-Speicher + 8 GB Basis.
- **Empfehlungen**:
  - Plane 2–4 GB RAM pro VM, 512 MB–1 GB pro LXC.
  - ECC-RAM für ZFS und Ceph, um Speicherfehler zu vermeiden.
  - Beispiel: 64 GB ECC-RAM für 10 VMs (je 4 GB) + 20 LXC (je 1 GB) + 8 GB für Host/Ceph.
- **Skalierung**: Überprovisionierung möglich, aber vermeide Swapping (Swap auf SSD).

### 3. Speicher
- **Anforderungen**:
  - SSDs/NVMes für OS und VM-Speicher; HDDs für Backups oder Ceph mit niedriger Priorität.
  - Mindestens 2x 1 TB NVMe für ZFS Mirror; 4–6x SSDs für RAID-Z2 oder Ceph OSDs.
- **Empfehlungen**:
  - Enterprise-grade SSDs (z. B. Samsung PM983, Intel D7-P5510) mit DWPD > 1 für hohe Schreibausdauer.
  - ZFS: Mindestens RAID 1 (Mirror) oder RAID-Z1 (3 Laufwerke) für Datensicherheit.
  - Ceph: 4–6 OSDs pro Knoten, separate NVMe für WAL/DB (RAID 1).
  - Beispiel: 2x 1 TB NVMe (ZFS Mirror) für HomeLab; 6x 2 TB NVMe (RAID-Z2) pro Knoten für Unternehmen.
- **Backup**: Nutze Proxmox Backup Server (PBS) mit separatem Speicher (z. B. HDDs).

### 4. Netzwerk
- **Anforderungen**:
  - Mindestens 10 GbE für Cluster-Traffic, VM- und Storage-Netzwerk; 25–40 GbE für Ceph.
  - Redundante Netzwerke (z. B. Dual-NICs mit Bonding) für HA.
- **Empfehlungen**:
  - Separate Netzwerke für:
    - **VM-Traffic**: VLAN für Gast-VMs/LXC.
    - **Quorum (Corosync)**: Dediziertes Netzwerk für Cluster-Synchronisation.
    - **Management**: Separates Netzwerk für Proxmox-Weboberfläche/SSH.
    - **Storage**: Dediziertes Netzwerk für Ceph, NFS oder iSCSI.
  - Jumbo Frames (MTU 9000) für Storage-Traffic (z. B. Ceph, iSCSI).
  - Beispiel: 2x 10 GbE NICs pro Knoten (1 für VM/Storage, 1 für Quorum/Management).

### 5. Cluster-Größe
- **Anforderungen**:
  - Mindestens 3 Knoten für HA und Quorum (Corosync benötigt Mehrheit).
  - 5–7 Knoten für Ceph-Cluster (optimale Balance zwischen Redundanz und Overhead).
- **Empfehlungen**:
  - HomeLab: 2–3 Knoten (z. B. Intel NUCs oder Mini-PCs mit Ryzen 9).
  - Unternehmen: 5+ Knoten für HA, Ceph und Lastverteilung.
  - Beispiel: 3 Knoten mit je 32 GB RAM, 16 Kerne, 2x 1 TB NVMe für HomeLab; 7 Knoten mit 128 GB RAM, 32 Kerne, 6x 2 TB NVMe für Unternehmen.

## Anleitung: Cluster-Einrichtung mit Netzwerk-Trennung und Shared Storage

### Vorbereitung
1. **Hardware prüfen**:
   - Mindestens 3 Knoten mit 32 GB ECC-RAM, 16 Kerne, 2x NVMe SSDs (1 TB), 2x 10 GbE NICs.
   - Beispiel: Dell R640 (2x Xeon Silver 4210, 64 GB RAM, 4x 1.92 TB NVMe).
2. **Netzwerk planen**:
   - VLANs: 
     - VLAN 10: VM-Traffic.
     - VLAN 20: Quorum (Corosync).
     - VLAN 30: Management.
     - VLAN 40: Storage (Ceph/NFS/iSCSI).
   - Switch: Managed Switch mit 10 GbE (z. B. MikroTik CRS317).
3. **Backup**: Konfiguriere Proxmox Backup Server (PBS) auf einem separaten Server.

### Schritt 1: Cluster erstellen
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
   Stelle sicher, dass das Quorum erreicht ist (mindestens 3 Knoten).

**Tipp**: Verwende ein dediziertes 10 GbE-Netzwerk für Corosync (VLAN 20) mit niedriger Latenz.

**Quelle**: https://pve.proxmox.com/wiki/Cluster_Manager

### Schritt 2: Netzwerk-Trennung konfigurieren
1. **Netzwerkbrücken einrichten** (auf jedem Knoten):
   - Bearbeite `/etc/network/interfaces`:
     ```bash
     auto vmbr0
     iface vmbr0 inet static
         address 192.168.30.10/24  # Management
         gateway 192.168.30.1
         bridge-ports enp0s1.30
         bridge-stp off
         bridge-fd 0
         bridge-vlan-aware yes
         bridge-vids 10,40

     auto vmbr1
     iface vmbr1 inet static
         address 192.168.20.10/24  # Quorum
         bridge-ports enp0s2
         bridge-stp off
         bridge-fd 0
     ```
   - VLAN 10 (VMs), VLAN 40 (Storage) auf `vmbr0`; VLAN 20 (Quorum) auf `vmbr1`.
2. **Netzwerk neu starten**:
   ```bash
   systemctl restart networking
   ```
3. **Switch konfigurieren**:
   - Stelle sicher, dass der Switch VLANs 10, 20, 30, 40 unterstützt und Jumbo Frames (MTU 9000) für VLAN 40 aktiviert sind.

**Tipp**: Verwende Bonding (LACP) für redundante NICs:
```bash
auto bond0
iface bond0 inet manual
    bond-slaves enp0s1 enp0s2
    bond-mode 802.3ad
    bond-miimon 100
```

### Schritt 3: Shared Storage einrichten
#### Option 1: Ceph
1. **Ceph installieren**:
   - In der Weboberfläche: `Datacenter > Ceph > Install Ceph`.
   - Installiere auf allen Knoten.
2. **Ceph-Cluster einrichten**:
   - Erstelle Monitor und Manager:
     ```bash
     pveceph mon create
     pveceph mgr create
     ```
   - Füge OSDs hinzu (z. B. 4x NVMe pro Knoten):
     ```bash
     pveceph disk init /dev/nvme0n1
     pveceph osd create /dev/nvme0n1
     ```
3. **Pool erstellen**:
   ```bash
   pveceph pool create vmdata
   ceph osd pool set vmdata size 3
   ```
4. **Speicher hinzufügen**:
   - In der Weboberfläche: `Datacenter > Storage > Add > RBD`, wähle Pool `vmdata`.
5. **Netzwerk optimieren**:
   - Dediziertes 25 GbE-Netzwerk für Ceph (VLAN 40):
     ```bash
     ceph config set mon public_network 192.168.40.0/24
     ```

**Tipp**: Verwende separate NVMe-SSDs für WAL/DB (RAID 1) und aktiviere `bluestore` für OSDs.

**Quelle**: https://pve.proxmox.com/wiki/Storage#_ceph_rados_block_device_rbd

#### Option 2: NFS
1. **NAS vorbereiten** (z. B. TrueNAS):
   - Erstelle eine NFS-Freigabe: `/mnt/tank/vmdata`.
   - Berechtigungen für Proxmox-Knoten: `192.168.40.0/24`.
2. **NFS-Speicher hinzufügen**:
   ```bash
   pvesm add nfs vmstore --server 192.168.40.100 --export /mnt/tank/vmdata --content images,iso,rootdir
   ```
3. **Jumbo Frames aktivieren**:
   ```bash
   mount -o vers=4.2,nconnect=2,mtu=9000 192.168.40.100:/mnt/tank/vmdata /mnt/pve/vmstore
   ```

**Tipp**: Verwende ZFS auf dem NAS für Snapshots und Komprimierung.

**Quelle**: https://pve.proxmox.com/wiki/Storage#_nfs_backend

#### Option 3: iSCSI
1. **SAN vorbereiten** (z. B. TrueNAS):
   - Erstelle ein iSCSI-Target mit Zvol:
     ```bash
     zfs create -V 2T tank/vmdata
     ```
2. **iSCSI-Speicher hinzufügen**:
   ```bash
   pvesm add iscsi san1 --portal 192.168.40.100 --target iqn.2025-09.com.example:vmdata
   ```
3. **ZFS oder LVM hinzufügen**:
   - ZFS over iSCSI:
     ```bash
     pvesm add zfsoniscsi zfs1 --portal 192.168.40.100 --pool tank/vmdata --blocksize 8k
     ```
   - LVM:
     ```bash
     pvesm add lvm lvm1 --vgname pve-vg --base san1
     ```
4. **Multipathing konfigurieren**:
   ```bash
   apt install multipath-tools
   multipath -ll
   ```

**Tipp**: Nutze ZFS over iSCSI für Snapshots; PBS für Backups bei LVM.

**Quelle**: https://pve.proxmox.com/wiki/Storage#_iscsi_backend

### Schritt 4: HA konfigurieren
1. **HA-Gruppen erstellen**:
   - In der Weboberfläche: `Datacenter > HA > Groups > Create`.
   - Beispiel: Gruppe `ha-group1` mit allen Knoten, Priorität auf NVMe-Knoten.
2. **VMs/LXC für HA aktivieren**:
   - Wähle VM/CT: `Edit > HA > Request State: Started`.
3. **Fencing konfigurieren** (optional):
   - Verwende Watchdog oder externe Fencing-Hardware (z. B. IPMI).
   ```bash
   apt install fence-agents
   ```

**Tipp**: Teste HA durch Herunterfahren eines Knotens:
```bash
pvecm nodes
systemctl poweroff
```

### Schritt 5: Monitoring und Backup
1. **Monitoring einrichten**:
   - Integriere Checkmk für Cluster-Überwachung:
     ```bash
     pveceph status
     zpool status
     ```
2. **Backup mit PBS**:
   - Füge PBS-Speicher hinzu:
     ```bash
     pvesm add pbs backup --server 192.168.30.200 --datastore backup
     ```
   - Plane tägliche Backups in der Weboberfläche: `Datacenter > Backup`.

## Empfehlungen für Anwendungsfälle

- **HomeLab (geringe Hardware)**:
  - **Hardware**: 3 Intel NUCs (Ryzen 7, 32 GB RAM, 2x 1 TB NVMe).
  - **Netzwerk**: 10 GbE Switch, VLANs für VM (10), Quorum (20), Management (30).
  - **Storage**: NFS (TrueNAS) oder ZFS Mirror (2x NVMe).
  - **Beispiel**: 10 LXC (z. B. Pi-hole, Nextcloud), 2 VMs (Ubuntu, Windows).

- **Unternehmensumgebung (HA, große Workloads)**:
  - **Hardware**: 5 Dell R740 (2x Xeon Gold 6230, 128 GB RAM, 6x 1.92 TB NVMe).
  - **Netzwerk**: 2x 25 GbE NICs, VLANs für VM (10), Quorum (20), Management (30), Storage (40).
  - **Storage**: Ceph (5 Knoten, 6 OSDs pro Knoten) oder iSCSI mit ZFS (TrueNAS).
  - **Beispiel**: 50 VMs (Windows/Linux), 20 LXC, HA für kritische Dienste.

- **Performance-kritische Anwendungen**:
  - **Hardware**: 3 Knoten mit NVMe (4x 2 TB, RAID-Z1), 64 GB RAM, 2x 25 GbE.
  - **Storage**: iSCSI mit ZFS oder Ceph mit separatem WAL/DB.
  - **Beispiel**: Datenbank-VMs (PostgreSQL, Oracle), GPU-Passthrough für ML.

## Tipps für den Erfolg
- **Hardware-Skalierung**: Plane 20–30% Puffer für RAM und CPU, um Spitzenlasten abzufangen.
- **Netzwerk-Redundanz**: Verwende Bonding (LACP) und redundante Switches für HA.
- **Storage-Optimierung**: Aktiviere Komprimierung (`lz4`) für ZFS/Ceph, Jumbo Frames für NFS/iSCSI.
- **Monitoring**: Nutze Checkmk oder Prometheus für Cluster- und Storage-Überwachung.
- **Dokumentation**: Konsultiere https://pve.proxmox.com/wiki/Cluster_Manager und https://pve.proxmox.com/wiki/Storage.

## Fazit
Eine sorgfältige Hardware-Dimensionierung und Netzwerk-Trennung sind entscheidend für einen stabilen Proxmox VE Cluster:
- **HomeLabs**: 3 Knoten mit 32 GB RAM, NFS oder ZFS, 10 GbE-Netzwerk.
- **Unternehmen**: 5+ Knoten mit 128 GB RAM, Ceph oder iSCSI, 25–40 GbE.
- **Shared Storage**: Ceph für HA, NFS für Einfachheit, iSCSI für Performance.

Teste die Konfiguration in einer nicht-produktiven Umgebung, um Hardware- und Netzwerkprobleme frühzeitig zu erkennen.

**Nächste Schritte**: Möchtest du eine detaillierte Anleitung zu Ceph-Tuning (z. B. CRUSH-Maps), HA-Fencing oder Integration mit Proxmox Backup Server?

**Quellen**:
- Proxmox-Dokumentation: https://pve.proxmox.com/wiki/Cluster_Manager, https://pve.proxmox.com/wiki/Storage
- Community-Diskussionen:,,,,,,