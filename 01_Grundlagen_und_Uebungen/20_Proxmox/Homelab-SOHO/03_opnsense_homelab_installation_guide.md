# Anleitung: Installation von OPNsense als Firewall für ein Proxmox VE HomeLab

## Einführung

OPNsense ist eine leistungsstarke Open-Source-Firewall und Routing-Plattform, die sich ideal für ein HomeLab eignet, um Netzwerkverkehr zu sichern, VLANs zu segmentieren und Dienste wie Proxmox VE und TrueNAS CORE zu schützen. Diese Anleitung beschreibt die Installation von OPNsense 24.7 (oder neuer) als virtuelle Maschine (VM) auf einem Proxmox VE 9.0 HomeLab ohne Cluster, die Konfiguration von VLANs (für Management, VMs, TrueNAS und Gäste), grundlegende Firewall-Regeln und die Integration mit einem TrueNAS NFS-Speicher. Sie ist für HomeLab-Nutzer mit grundlegenden Netzwerkkenntnissen geeignet und basiert auf der offiziellen OPNsense-Dokumentation und Community-Erfahrungen.

**Voraussetzungen**:
- Proxmox VE 9.0 auf einem Server mit mindestens 16 GB RAM, 4–8 Kerne, 1–2 TB SSD/NVMe, 2x 1 GbE Netzwerkkarten (NICs).
- TrueNAS CORE 13.0 (oder neuer) mit einer NFS-Freigabe (z. B. `/mnt/tank/vmdata`, IP: `192.168.1.100`).
- Managed Switch mit VLAN-Unterstützung (z. B. TP-Link TL-SG108E oder Netgear GS308T).
- OPNsense ISO (herunterladbar von https://opnsense.org/download/).
- Zugriff auf die Proxmox-Weboberfläche (`https://192.168.1.10:8006`) und ein Browser für die OPNsense-Weboberfläche (`https://192.168.1.1`).
- Grundkenntnisse in Netzwerkkonfiguration, VLANs und Firewall-Regeln.

**Netzwerkplan**:
- **VLAN 10**: VM-Traffic (z. B. Proxmox VMs/LXC, `192.168.10.0/24`).
- **VLAN 20**: Management (Proxmox, TrueNAS, OPNsense, `192.168.20.0/24`).
- **VLAN 30**: TrueNAS Storage (NFS, `192.168.30.0/24`).
- **VLAN 40**: Gäste/WLAN (z. B. IoT-Geräte, `192.168.40.0/24`).
- **WAN**: Öffentliches Netzwerk (z. B. `192.168.1.0/24`, verbunden mit dem Router).

**Hinweis**: OPNsense als VM erfordert mindestens zwei virtuelle Netzwerkkarten (WAN und LAN). Diese Anleitung setzt einen Managed Switch voraus, um VLANs zu handhaben.

**Quellen**:
- OPNsense-Dokumentation: https://docs.opnsense.org/
- Proxmox-Dokumentation: https://pve.proxmox.com/wiki/Network_Configuration
- Webquellen:,,,,,,,,,,,,,,

## Hardwareanforderungen

### Minimale Anforderungen für OPNsense-VM
- **CPU**: 2 Kerne (z. B. `kvm64` oder `host` in Proxmox).
- **RAM**: 2 GB (4 GB empfohlen für Plugins wie Suricata).
- **Speicher**: 20 GB SSD/NVMe (auf Proxmox NFS oder ZFS).
- **Netzwerk**: 2 virtuelle NICs (VirtIO, eine für WAN, eine für LAN mit VLANs).
- **Proxmox-Host**: Ryzen 5 5600X, 32 GB RAM, 1 TB NVMe, 2x 1 GbE NICs (z. B. Intel I219-V).

### Empfohlene HomeLab-Hardware (aus vorheriger Anleitung)
- **Mainboard**: ASUS PRIME B550M-A.
- **CPU**: AMD Ryzen 5 5600X (6 Kerne, 12 Threads).
- **RAM**: 32 GB DDR4 ECC.
- **Speicher**: 1 TB NVMe (Proxmox OS/VMs), 4 TB HDD (TrueNAS oder PBS).
- **Netzwerk**: 2x 1 GbE NICs (für physikalische Trennung von WAN/LAN).
- **Switch**: TP-Link TL-SG108E (8 Ports, VLAN-fähig).

**Tipp**: Verwende Intel-basierte NICs für Stabilität. Stelle sicher, dass der Switch VLAN-Tagging (802.1Q) unterstützt.

## Installation von OPNsense auf Proxmox

### Schritt 1: OPNsense ISO herunterladen
1. Lade die OPNsense ISO (Version 24.7 oder neuer) von https://opnsense.org/download/.
   - Wähle „amd64“, „DVD“ (ISO-Format).
2. Lade die ISO in Proxmox hoch:
   - In der Weboberfläche: `local > ISO Images > Upload`.
   - Wähle die Datei `OPNsense-24.7-dvd-amd64.iso`.

**Quelle**: https://docs.opnsense.org/manual/install.html

### Schritt 2: OPNsense-VM erstellen
1. **VM erstellen** (in Proxmox-Weboberfläche, `Create VM`):
   - Name: `opnsense`.
   - ISO: `OPNsense-24.7-dvd-amd64.iso`.
   - OS-Typ: `Other`.
   - Disk: 20 GB, Speicher: `nfs-vmstore` (oder `local-zfs`), Format: `qcow2`.
   - CPU: 2 Kerne, Typ: `kvm64` oder `host`.
   - RAM: 2048 MB (4096 MB für Plugins).
   - Netzwerk:
     - `Network Device 1` (WAN): `vmbr0`, VirtIO, keine VLAN-ID (direkt mit dem Router verbunden).
     - `Network Device 2` (LAN): `vmbr0`, VirtIO, VLAN Tag: `10` (für VLAN 10, VM-Traffic).
     - Optional: Füge weitere Netzwerke für VLAN 20, 30, 40 hinzu (z. B. `vmbr0.20`, `vmbr0.30`, `vmbr0.40`).
   - CLI-Alternative:
     ```bash
     qm create 100 --name opnsense --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0 --net1 virtio,bridge=vmbr0,tag=10 --scsi0 nfs-vmstore:20,format=qcow2 --ostype other
     qm set 100 --cdrom local:iso/OPNsense-24.7-dvd-amd64.iso
     ```
2. **Netzwerkbrücke konfigurieren**:
   - Bearbeite `/etc/network/interfaces` auf dem Proxmox-Host:
     ```bash
     auto vmbr0
     iface vmbr0 inet static
         address 192.168.20.10/24  # Management
         gateway 192.168.20.1
         bridge-ports enp0s3
         bridge-stp off
         bridge-fd 0
         bridge-vlan-aware yes
         bridge-vids 10,20,30,40
     ```
   - Netzwerk neu starten:
     ```bash
     systemctl restart networking
     ```

**Tipp**: Stelle sicher, dass der Switch VLAN-Tagging unterstützt und die Ports korrekt konfiguriert sind (z. B. Port für Proxmox als Trunk mit VLANs 10, 20, 30, 40).

### Schritt 3: OPNsense installieren
1. **VM starten**:
   ```bash
   qm start 100
   ```
2. **Installation über VNC** (Proxmox-Weboberfläche, `Console`):
   - Wähle „Install (Multi-user)“ und drücke `Enter`.
   - Benutzer: `installer`, Passwort: `opnsense`.
   - Wähle „Guided Installation“.
   - Ziellaufwerk: `ada0` (20 GB Disk).
   - Partitionierung: `ZFS` (Standard für OPNsense).
   - Bestätige die Installation (Daten werden gelöscht).
   - Setze ein neues `root`-Passwort (z. B. ein starkes Passwort).
   - Installation abschließen (5–10 Minuten).
   - Wähle „Reboot“ und entferne die ISO:
     ```bash
     qm set 100 --cdrom none
     ```
3. **Zugriff prüfen**:
   - Öffne die OPNsense-Weboberfläche: `https://192.168.1.1` (Standard-IP für WAN).
   - Melde dich mit `root` und dem neuen Passwort an.

**Quelle**: https://docs.opnsense.org/manual/install.html

## Grundkonfiguration von OPNsense

### Schritt 1: Netzwerkschnittstellen konfigurieren
1. **WAN-Schnittstelle**:
   - In der Weboberfläche: `Interfaces > WAN`.
   - IP-Konfiguration: DHCP (für HomeLabs, verbunden mit dem Router) oder statisch (z. B. `192.168.1.1/24`).
   - Gateway: Router-IP (z. B. `192.168.1.254`).
2. **LAN-Schnittstellen (VLANs)**:
   - Gehe zu `Interfaces > VLANs > Add`.
   - Erstelle VLANs:
     - VLAN 10: Parent Interface: `vtnet1` (LAN), Tag: `10`, Name: `VMs`.
     - VLAN 20: Parent Interface: `vtnet1`, Tag: `20`, Name: `Management`.
     - VLAN 30: Parent Interface: `vtnet1`, Tag: `30`, Name: `Storage`.
     - VLAN 40: Parent Interface: `vtnet1`, Tag: `40`, Name: `Guests`.
   - Weise Schnittstellen zu (`Interfaces > Assignments`):
     - `VMs`: `vlan0`, IP: `192.168.10.1/24`, DHCP-Server aktivieren.
     - `Management`: `vlan1`, IP: `192.168.20.1/24`, DHCP-Server aktivieren.
     - `Storage`: `vlan2`, IP: `192.168.30.1/24`, kein DHCP.
     - `Guests`: `vlan3`, IP: `192.168.40.1/24`, DHCP-Server aktivieren.
3. **DHCP-Server konfigurieren**:
   - Gehe zu `Services > DHCPv4 > [Interface]` (z. B. `VMs`).
   - Range: z. B. `192.168.10.100–192.168.10.200`.
   - Wiederhole für `Management` und `Guests`.

**Tipp**: Deaktiviere DHCP für `Storage`, da TrueNAS und Proxmox statische IPs verwenden.

### Schritt 2: Firewall-Regeln einrichten
1. **WAN-Regeln**:
   - Gehe zu `Firewall > Rules > WAN`.
   - Standardmäßig blockiert OPNsense eingehenden WAN-Traffic.
   - Optional: Erlaube Zugriff auf die Weboberfläche (für Remote-Zugriff):
     - Aktion: `Pass`, Protokoll: `TCP`, Ziel: `This Firewall`, Port: `443`.
2. **LAN-Regeln (VLANs)**:
   - Gehe zu `Firewall > Rules > VMs` (VLAN 10).
   - Regel für VM-Traffic:
     - Aktion: `Pass`, Quelle: `VMs net` (`192.168.10.0/24`), Ziel: `any`, Protokoll: `any`.
   - Gehe zu `Firewall > Rules > Management` (VLAN 20):
     - Erlaube Proxmox/TrueNAS-Zugriff:
       - Aktion: `Pass`, Quelle: `Management net` (`192.168.20.0/24`), Ziel: `any`, Protokoll: `TCP/UDP`, Ports: `8006` (Proxmox), `80,443` (TrueNAS), `22` (SSH).
   - Gehe zu `Firewall > Rules > Storage` (VLAN 30):
     - Erlaube NFS-Traffic:
       - Aktion: `Pass`, Quelle: `Storage net` (`192.168.30.0/24`), Ziel: `192.168.30.100` (TrueNAS), Protokoll: `TCP/UDP`, Ports: `2049` (NFS).
   - Gehe zu `Firewall > Rules > Guests` (VLAN 40):
     - Erlaube Internetzugriff, blockiere Zugriff auf andere VLANs:
       - Aktion: `Pass`, Quelle: `Guests net` (`192.168.40.0/24`), Ziel: `any`, Protokoll: `any`.
       - Aktion: `Block`, Quelle: `Guests net`, Ziel: `VMs net`, `Management net`, `Storage net`.
3. **NAT-Regeln** (für Internetzugriff):
   - Gehe zu `Firewall > NAT > Outbound`.
   - Modus: `Hybrid` oder `Automatic`.
   - Stelle sicher, dass NAT für VLAN 10, 20, 40 aktiviert ist (Standard).

**Tipp**: Verwende Aliases (`Firewall > Aliases`) für wiederkehrende IPs (z. B. `Proxmox: 192.168.20.10`, `TrueNAS: 192.168.30.100`).

### Schritt 3: Switch-Konfiguration
1. **VLANs einrichten** (z. B. TP-Link TL-SG108E):
   - Port 1: WAN (untagged, verbunden mit dem Router).
   - Port 2: Proxmox-Host (Trunk, VLANs 10, 20, 30, 40).
   - Port 3: TrueNAS (VLAN 20: Management, VLAN 30: Storage).
   - Port 4: Access Point (VLAN 40: Guests).
2. **Jumbo Frames aktivieren** (für NFS):
   - Setze MTU auf 9000 für VLAN 30 (Storage) auf dem Switch und in OPNsense (`Interfaces > Storage > Advanced > MTU`).

**Quelle**: https://docs.opnsense.org/manual/vlans.html

## Integration mit Proxmox und TrueNAS

### Schritt 1: Proxmox-Netzwerk anpassen
1. **Netzwerkbrücke aktualisieren**:
   - Bearbeite `/etc/network/interfaces`:
     ```bash
     auto vmbr0
     iface vmbr0 inet manual
         bridge-ports enp0s3
         bridge-stp off
         bridge-fd 0
         bridge-vlan-aware yes
         bridge-vids 10,20,30,40

     auto vmbr0.20
     iface vmbr0.20 inet static
         address 192.168.20.10/24
         gateway 192.168.20.1
     ```
   - Netzwerk neu starten:
     ```bash
     systemctl restart networking
     ```
2. **VMs/LXC anpassen**:
   - Weise bestehenden VMs/LXC VLANs zu (z. B. `tag=10` für `vmbr0`).
   - Beispiel für Pi-hole (LXC 102):
     ```bash
     pct set 102 --net0 name=eth0,bridge=vmbr0,tag=10,ip=192.168.10.102/24,gw=192.168.10.1
     ```

### Schritt 2: TrueNAS-Netzwerk anpassen
1. **Statische IPs setzen**:
   - In der TrueNAS-Weboberfläche (`https://192.168.1.100`): `Network > Interfaces > Add`.
   - Interface 1: Name: `Management`, IP: `192.168.20.100/24`, VLAN Tag: `20`.
   - Interface 2: Name: `Storage`, IP: `192.168.30.100/24`, VLAN Tag: `30`.
   - Gateway: `192.168.20.1` (OPNsense Management).
2. **NFS-Freigabe aktualisieren**:
   - Gehe zu `Sharing > Unix Shares (NFS) > Edit`.
   - Pfad: `/mnt/tank/vmdata`, Netzwerk: `192.168.30.0/24`.
3. **CLI-Alternative**:
   ```bash
   ifconfig igb0.20 192.168.20.100/24 vlan 20 vlandev igb0
   ifconfig igb0.30 192.168.30.100/24 vlan 30 vlandev igb0
   echo "/mnt/tank/vmdata 192.168.30.0/24(rw,sync,no_subtree_check)" >> /etc/exports
   service nfsd restart
   ```

### Schritt 3: NFS in Proxmox aktualisieren
1. **NFS-Speicher anpassen**:
   - In der Proxmox-Weboberfläche: `Datacenter > Storage > Edit > nfs-vmstore`.
   - Server: `192.168.30.100`, Export: `/mnt/tank/vmdata`.
   - CLI-Alternative:
     ```bash
     pvesm set nfs-vmstore --server 192.168.30.100 --export /mnt/tank/vmdata
     ```
2. **Testen**:
   ```bash
   pvesm status
   ```

## Best Practices für HomeLab

- **Netzwerksegmentierung**:
  - Verwende VLANs, um Management (`192.168.20.0/24`), Storage (`192.168.30.0/24`) und Gäste (`192.168.40.0/24`) zu trennen.
  - Blockiere Zugriff von `Guests` auf `Management` und `Storage` in OPNsense.
- **Performance**:
  - Aktiviere VirtIO für OPNsense-Netzwerkschnittstellen in Proxmox.
  - Verwende Jumbo Frames (MTU 9000) für VLAN 30 (Storage).
- **Sicherheit**:
  - Deaktiviere SSH-Passwort-Login auf OPNsense:
    - `System > Settings > Administration > SSH > Disable password login`.
  - Verwende starke Passwörter für `root` und zusätzliche Benutzer.
  - Aktiviere Zwei-Faktor-Authentifizierung (2FA):
    - `System > Access > Authentication > Add TOTP`.
- **Backup**:
  - Sichere OPNsense-Konfigurationen regelmäßig:
    - `System > Configuration > Backups > Download`.
  - Integriere OPNsense-Backups in Proxmox Backup Server (manuell via NFS).
- **Monitoring**:
  - Aktiviere Zabbix- oder Prometheus-Integration:
    - Installiere das `os-zabbix` Plugin (`System > Firmware > Plugins`).
  - Überwache Netzwerk-Traffic:
    ```bash
    netstat -i
    ```
- **Erweiterungen**:
  - Installiere Plugins wie `os-wireguard` für VPN-Zugriff:
    - `System > Firmware > Plugins > os-wireguard`.

**Quelle**: https://docs.opnsense.org/manual/plugins.html

## Empfehlungen für HomeLab-Anwendungen

- **Setup**:
  - **Proxmox**: 1 Server (Ryzen 5, 32 GB RAM, 1 TB NVMe), VLANs 10, 20, 30.
  - **TrueNAS**: 1 Server (Ryzen 3, 16 GB ECC-RAM, 2x 4 TB HDD), VLANs 20, 30.
  - **OPNsense**: VM mit 2 GB RAM, 2 Kerne, 20 GB Speicher, VLANs 10, 20, 30, 40.
  - **Workloads**: 3 LXC (Pi-hole, Nextcloud, HomeAssistant), 2 VMs (Ubuntu, Windows).
- **Netzwerk**:
  - VLAN 10: VMs/LXC (`192.168.10.0/24`, DHCP).
  - VLAN 20: Management (Proxmox: `192.168.20.10`, TrueNAS: `192.168.20.100`, OPNsense: `192.168.20.1`).
  - VLAN 30: Storage (TrueNAS: `192.168.30.100`).
  - VLAN 40: Gäste/IoT (`192.168.40.0/24`, DHCP).
- **Firewall-Regeln**:
  - Erlaube Management-Zugriff (VLAN 20) nur für Admins.
  - Erlaube NFS (VLAN 30) nur zwischen Proxmox und TrueNAS.
  - Blockiere Gäste (VLAN 40) von internen Netzwerken.

## Tipps für den Erfolg

- **Hardware**: Verwende zwei physikalische NICs (WAN, LAN) für bessere Trennung.
- **VLANs**: Teste die Switch-Konfiguration vor der OPNsense-Installation (z. B. mit `vlanctl`).
- **Sicherheit**: Aktualisiere OPNsense regelmäßig (`System > Firmware > Updates`).
- **Backup**: Exportiere OPNsense-Konfigurationen monatlich und speichere sie auf TrueNAS.
- **Dokumentation**: Konsultiere https://docs.opnsense.org/ für erweiterte Konfigurationen (z. B. VPN, IDS/IPS).

## Fazit

Die Installation von OPNsense als Firewall-VM in einem Proxmox VE HomeLab bietet:
- **Sicherheit**: VLAN-Segmentierung und strenge Firewall-Regeln schützen Proxmox und TrueNAS.
- **Flexibilität**: Unterstützt Plugins wie WireGuard, Suricata und Zabbix.
- **Integration**: Nahtlose Verbindung mit TrueNAS (NFS) und Proxmox (VMs/LXC).

Dieses Setup ist kosteneffizient und ideal für HomeLabs mit begrenzter Hardware. Für erweiterte Funktionen (z. B. IDS/IPS oder VPN) können Plugins oder zusätzliche Hardware hinzugefügt werden.

**Nächste Schritte**: Möchtest du eine detaillierte Anleitung zu OPNsense-Plugins (z. B. WireGuard, Suricata), IDS/IPS-Konfiguration oder Integration mit Proxmox Backup Server?

**Quellen**:
- OPNsense-Dokumentation: https://docs.opnsense.org/
- Proxmox-Dokumentation: https://pve.proxmox.com/wiki/Network_Configuration
- Webquellen:,,,,,,,,,,,,,,