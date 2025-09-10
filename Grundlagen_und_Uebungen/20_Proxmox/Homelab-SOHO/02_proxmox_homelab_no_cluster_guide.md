# Anleitung: Proxmox VE HomeLab ohne Cluster

## Einführung

Ein Proxmox VE HomeLab ohne Cluster ist ideal für Enthusiasten, die eine flexible Virtualisierungsumgebung auf einer einzelnen Maschine einrichten möchten, ohne die Komplexität eines Clusters. Diese Anleitung beschreibt die Einrichtung von Proxmox VE 9.0 auf einem einzelnen Server mit Fokus auf Einfachheit, Kosteneffizienz und Funktionalität. Sie umfasst Hardware-Auswahl, Installation, Konfiguration von NFS als Shared Storage (z. B. über TrueNAS), Backups mit Proxmox Backup Server (PBS) 4.0 (Open Source Edition), und die Erstellung von VMs und LXC für typische HomeLab-Anwendungen (z. B. Pi-hole, Nextcloud). Die Anleitung ist für HomeLab-Nutzer mit begrenztem Budget geeignet und basiert auf der Proxmox-Dokumentation.

**Voraussetzungen**:
- Einzelner Server mit mindestens 16 GB RAM, 4–8 Kerne, 1–2 TB SSD/NVMe, 1 GbE Netzwerk.
- Optional: NAS (z. B. TrueNAS) für NFS oder externe Festplatte für Backups.
- Zugriff auf die Proxmox-Weboberfläche (`https://<IP>:8006`) und PBS-Weboberfläche (`https://<IP>:8007`).
- Grundkenntnisse in Linux, Netzwerkkonfiguration und Virtualisierung.
- ISO-Dateien (z. B. Ubuntu 22.04) und LXC-Vorlagen (via Proxmox).

**Hinweis**: Ohne Cluster gibt es keine Hochverfügbarkeit (HA) oder automatische Replikation. Backups und Redundanz werden über PBS und NFS gewährleistet.

**Quellen**:
- Proxmox-Dokumentation: https://pve.proxmox.com/wiki/Installation, https://www.proxmox.com/en/proxmox-backup-server
- Community-Diskussionen:,,,,,,

## Hardware-Auswahl

### Empfohlene Hardware
- **CPU**: AMD Ryzen 5 5600X (6 Kerne, 12 Threads) oder Intel Core i5-12400 (6 Kerne) für 5–10 VMs/LXC.
- **RAM**: 16–32 GB DDR4 (ECC bevorzugt für ZFS), z. B. 2x 16 GB.
- **Speicher**: 1–2 TB NVMe SSD (z. B. Samsung 970 EVO Plus) für OS und VMs/LXC; optional HDD für Backups.
- **Netzwerk**: 1 GbE NIC (z. B. Intel I219-V); 2.5 GbE oder 10 GbE für NAS-Performance.
- **Gehäuse**: Mini-ITX oder ATX (z. B. Fractal Design Node 804).
- **Optional**: NAS (z. B. Synology DS920+ oder TrueNAS auf separatem Gerät).

**Beispiel-Konfiguration (HomeLab)**:
- Motherboard: ASUS ROG STRIX B550-I Gaming.
- CPU: AMD Ryzen 5 5600X.
- RAM: 32 GB DDR4 (2x 16 GB).
- Speicher: 1 TB NVMe (OS/VMs), 4 TB HDD (Backups).
- Netzwerk: 2.5 GbE NIC + 1 GbE Switch (z. B. TP-Link TL-SG108E).
- Kosten: ~700–1000 € (ohne NAS).

**Tipp**: Verwende NVMe-SSDs mit hoher Schreibausdauer (DWPD > 0.5) für VMs/LXC.

## Installation von Proxmox VE

### Schritt 1: Proxmox VE 9.0 installieren
1. **ISO herunterladen**:
   - Lade die Proxmox VE 9.0 ISO von https://www.proxmox.com/en/downloads.
   - Erstelle einen bootfähigen USB-Stick (z. B. mit Rufus oder `dd`).
2. **Installation starten**:
   - Boote vom USB-Stick, wähle „Install Proxmox VE (Graphical)“.
   - Wähle die NVMe-SSD als Ziel (z. B. `/dev/nvme0n1`).
   - Dateisystem: ZFS (RAID 0 für eine SSD, Mirror für zwei SSDs):
     ```bash
     zpool create -f rpool /dev/nvme0n1
     ```
   - Netzwerk: Statische IP (z. B. `192.168.1.10/24`, Gateway `192.168.1.1`).
3. **System aktualisieren**:
   ```bash
   apt update && apt full-upgrade
   ```
4. **Zugriff prüfen**:
   - Öffne die Weboberfläche: `https://192.168.1.10:8006`.
   - Melde dich an: `root` mit dem während der Installation festgelegten Passwort.

**Tipp**: Aktiviere die Community-Repositorys für Updates ohne Subskription:
```bash
sed -i 's/enterprise.pve.proxmox.com/debian.pve.proxmox.com/' /etc/apt/sources.list.d/pve-enterprise.list
```

**Quelle**: https://pve.proxmox.com/wiki/Installation

### Schritt 2: Netzwerk konfigurieren
1. **Netzwerkbrücke einrichten**:
   - Bearbeite `/etc/network/interfaces`:
     ```bash
     auto vmbr0
     iface vmbr0 inet static
         address 192.168.1.10/24
         gateway 192.168.1.1
         bridge-ports enp0s3
         bridge-stp off
         bridge-fd 0
     ```
2. **Netzwerk neu starten**:
   ```bash
   systemctl restart networking
   ```

**Tipp**: Verwende VLANs (z. B. VLAN 10 für VMs, VLAN 20 für Storage), wenn ein Managed Switch verfügbar ist.

## Einrichtung von Shared Storage (NFS)

### Schritt 1: NAS vorbereiten (z. B. TrueNAS)
1. **NFS-Freigabe erstellen**:
   - Auf TrueNAS: Erstelle einen ZFS-Pool (`tank`) und eine Freigabe (`/mnt/tank/vmdata`).
   - Setze Berechtigungen für `192.168.1.0/24`.
2. **NFS-Speicher in PVE hinzufügen**:
   - In der Weboberfläche: `Datacenter > Storage > Add > NFS`.
   - ID: `nfs-vmstore`, Server: `192.168.1.100`, Export: `/mnt/tank/vmdata`, Inhalt: `Images, Containers, ISO`.
   - CLI-Alternative:
     ```bash
     pvesm add nfs nfs-vmstore --server 192.168.1.100 --export /mnt/tank/vmdata --content images,iso,rootdir
     ```
3. **Status prüfen**:
   ```bash
   pvesm status
   ```

**Tipp**: Aktiviere `qcow2` für Snapshots und Thin Provisioning auf NFS. Verwende NFS 4.2 mit `nconnect=2` für bessere Performance:
```bash
mount -o vers=4.2,nconnect=2 192.168.1.100:/mnt/tank/vmdata /mnt/pve/nfs-vmstore
```

**Quelle**: https://pve.proxmox.com/wiki/Storage#_nfs_backend

## Einrichtung von Proxmox Backup Server (PBS)

### Schritt 1: PBS installieren
1. **Als LXC auf Proxmox** (für HomeLabs):
   ```bash
   pveam update
   pveam download local turnkey-proxmox-backup
   pct create 100 local:vztmpl/turnkey-proxmox-backup_18.0-bookworm-amd64.tar.gz --hostname pbs --storage local-zfs --rootfs 20 --cores 2 --memory 2048 --net0 name=eth0,bridge=vmbr0,ip=192.168.1.11/24
   pct start 100
   ```
2. **Zusätzliche SSD für Backups**:
   - Binde eine HDD/SSD ein (z. B. `/dev/sdb`):
     ```bash
     pct set 100 --mp0 /dev/sdb,mp=/mnt/backup,backup=1
     ```
3. **ZFS-Pool in PBS erstellen**:
   ```bash
   pct enter 100
   zpool create -f pbs-pool /mnt/backup
   zfs set compression=zstd pbs-pool
   ```

**Alternative**: Installiere PBS auf separatem Gerät mit der PBS 4.0 ISO (https://www.proxmox.com/en/downloads).

**Tipp**: Verwende ZFS für Deduplizierung und Komprimierung.

**Quelle**: https://www.proxmox.com/en/proxmox-backup-server

### Schritt 2: PBS-Datastore einrichten
1. **Datastore erstellen** (via PBS-Webinterface, `https://192.168.1.11:8007`):
   - `Datastore > Add Datastore`.
   - Name: `pbs-local`, Pfad: `/pbs-pool`.
   - Aktiviere Prune: Behalte 7 tägliche Backups.
2. **CLI-Alternative**:
   ```bash
   proxmox-backup-manager datastore create pbs-local /pbs-pool
   proxmox-backup-manager prune pbs-local --keep-daily 7
   ```

### Schritt 3: PBS in PVE integrieren
1. **Fingerprint kopieren** (im PBS-Dashboard).
2. **PBS als Speicher hinzufügen**:
   - In der PVE-Weboberfläche: `Datacenter > Storage > Add > Proxmox Backup Server`.
   - ID: `pbs-backup`, Server: `192.168.1.11`, Datastore: `pbs-local`, Fingerprint: `<PBS-Fingerprint>`.
   - CLI-Alternative:
     ```bash
     pvesm add pbs pbs-backup --server 192.168.1.11 --datastore pbs-local --fingerprint <PBS-Fingerprint>
     ```

## Erstellung von VMs und LXC

### Schritt 1: VM erstellen (z. B. Ubuntu 22.04)
1. **ISO hochladen**:
   - Lade `ubuntu-22.04.iso` in den `local`-Speicher (Weboberfläche: `local > ISO Images > Upload`).
2. **VM erstellen**:
   - In der Weboberfläche: `Create VM`.
   - Konfiguriere:
     - Name: `ubuntu-vm`.
     - ISO: `ubuntu-22.04.iso`.
     - Disk: 20 GB, `nfs-vmstore`, `qcow2`.
     - CPU: 2 Kerne, `kvm64`.
     - RAM: 2048 MB.
     - Netzwerk: `vmbr0`, VirtIO, IP: `192.168.1.101/24`.
   - CLI-Alternative:
     ```bash
     qm create 101 --name ubuntu-vm --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0 --scsi0 nfs-vmstore:20,format=qcow2
     qm set 101 --cdrom local:iso/ubuntu-22.04.iso
     qm start 101
     ```
3. **Ubuntu installieren**:
   - Starte die VM und installiere Ubuntu über die VNC-Konsole.

**Tipp**: Verwende VirtIO-Treiber für Netzwerk und Festplatte.

### Schritt 2: LXC erstellen (z. B. Pi-hole)
1. **Vorlage herunterladen**:
   ```bash
   pveam update
   pveam download local ubuntu-22.04-standard
   ```
2. **LXC erstellen**:
   - In der Weboberfläche: `Create CT`.
   - Konfiguriere:
     - Hostname: `pihole`.
     - Template: `ubuntu-22.04-standard`.
     - Disk: 8 GB, `nfs-vmstore`.
     - CPU: 1 Kern.
     - RAM: 512 MB.
     - Netzwerk: `vmbr0`, IP: `192.168.1.102/24`.
   - CLI-Alternative:
     ```bash
     pct create 102 local:vztmpl/ubuntu-22.04-standard_amd64.tar.gz --hostname pihole --storage nfs-vmstore --rootfs 8 --cores 1 --memory 512 --net0 name=eth0,bridge=vmbr0,ip=192.168.1.102/24
     pct start 102
     ```
3. **Pi-hole installieren**:
   ```bash
   pct enter 102
   curl -sSL https://install.pi-hole.net | bash
   ```

**Tipp**: Nutze unprivilegierte Container für bessere Sicherheit.

## Backup-Konfiguration mit PBS

### Schritt 1: Backup-Job einrichten
1. **Backup-Job erstellen**:
   - In der PVE-Weboberfläche: `Datacenter > Backup > Add`.
   - Wähle VMs/LXC (101, 102), Speicher: `pbs-backup`, Schedule: Täglich um 03:00.
   - CLI-Alternative:
     ```bash
     pve-backup add daily-backup --storage pbs-backup --schedule "mon..sun 03:00" --all
     ```
2. **Manuelles Backup testen**:
   ```bash
   pve-backup run daily-backup
   ```

### Schritt 2: Wiederherstellung testen
1. **VM/LXC wiederherstellen**:
   - In der PVE-Weboberfläche: `pbs-backup > Content > Restore`.
   - Wähle Backup für VM 101 oder LXC 102, Ziel: `nfs-vmstore`.
2. **Einzeldatei-Wiederherstellung** (für ext4/NTFS):
   - In der PBS-Weboberfläche: Wähle Backup, klicke auf `File Restore`.

**Tipp**: Verschlüssele Backups für zusätzliche Sicherheit:
```bash
proxmox-backup-client key create /root/backup-key
```

## Best Practices

- **Hardware**: Verwende NVMe-SSDs für VMs/LXC, HDDs für PBS-Backups.
- **Netzwerk**: Aktiviere Jumbo Frames (MTU 9000) für NFS, wenn der Switch dies unterstützt.
- **Speicher**: Nutze ZFS auf dem PVE-Host und PBS für Komprimierung (`zstd`) und Deduplizierung.
- **Backup**: Implementiere die 3-2-1-Strategie:
  - 3 Kopien: Produktivdaten (NFS), lokales PBS, externe Festplatte/NAS.
  - 2 Medien: NVMe (PVE), HDD (PBS).
  - 1 Off-Site: Kopiere Backups auf ein NAS oder Cloud (z. B. via CIFS).
- **Monitoring**: Überwache ZFS (`zpool status`) und PBS-Status:
  ```bash
  proxmox-backup-manager task list
  ```
- **Sicherheit**: Deaktiviere SSH-Passwort-Login auf PVE und PBS:
  ```bash
  echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config
  systemctl restart sshd
  ```

## Empfehlungen für HomeLab-Anwendungen

- **Typische Workloads**:
  - **Pi-hole**: LXC mit 512 MB RAM, 8 GB Speicher, für Ad-Blocking.
  - **Nextcloud**: LXC mit 2 GB RAM, 20 GB Speicher, für Cloud-Speicher.
  - **Ubuntu-Server**: VM mit 2 GB RAM, 20 GB Speicher, für Tests.
  - **Windows 10**: VM mit 4 GB RAM, 50 GB Speicher, für Desktop-Anwendungen.
- **Setup**:
  - Hardware: Ryzen 5, 32 GB RAM, 1 TB NVMe, 4 TB HDD.
  - Speicher: NFS (TrueNAS) für VMs/LXC, PBS (LXC) für Backups.
  - Netzwerk: 1 GbE mit VLANs (optional).
- **Beispiel**:
  - 3 LXC (Pi-hole, Nextcloud, HomeAssistant).
  - 2 VMs (Ubuntu, Windows).
  - Tägliche Backups auf PBS mit 7-Tage-Retention.

## Tipps für den Erfolg
- **Speicherwahl**: Nutze NFS für Einfachheit und Snapshots; ZFS für lokale Speicherung.
- **Performance**: Verwende VirtIO für VMs und minimale LXC-Vorlagen (z. B. Alpine).
- **Backup**: Teste Wiederherstellungen regelmäßig, um Datenintegrität zu prüfen.
- **Netzwerk**: Stelle sicher, dass NAS und PVE im gleichen Subnetz sind (z. B. `192.168.1.0/24`).
- **Dokumentation**: Konsultiere https://pve.proxmox.com/wiki/Installation und https://www.proxmox.com/en/proxmox-backup-server.

## Fazit
Ein Proxmox VE HomeLab ohne Cluster ist ideal für Enthusiasten mit begrenztem Budget:
- **Hardware**: Einzelner Server mit Ryzen 5, 32 GB RAM, NVMe SSD.
- **Storage**: NFS (z. B. TrueNAS) für VMs/LXC, PBS für deduplizierte Backups.
- **Anwendungen**: LXC für leichte Dienste (Pi-hole, Nextcloud), VMs für komplexe Anwendungen (Windows).

Diese Konfiguration bietet Flexibilität und Kosteneffizienz, ohne die Komplexität eines Clusters. Für zukünftige Skalierung kannst du einen Cluster hinzufügen, um HA und Replikation zu ermöglichen.

**Nächste Schritte**: Möchtest du eine detaillierte Anleitung zu ZFS-Optimierung, Nextcloud-Setup in LXC oder Integration mit einem externen Cloud-Backup?

**Quellen**:
- Proxmox-Dokumentation: https://pve.proxmox.com/wiki/Installation, https://www.proxmox.com/en/proxmox-backup-server
- Community-Diskussionen:,,,,,,