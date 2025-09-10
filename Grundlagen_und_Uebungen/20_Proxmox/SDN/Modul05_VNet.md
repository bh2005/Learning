## Modul 5: Inter-VNet-Routing

**Lernziel**: Ermöglichen der Kommunikation zwischen verschiedenen virtuellen Netzwerken (VNets) in Proxmox VE durch die Konfiguration eines virtuellen Routers. Nach diesem Modul können Sie VNets verbinden, die standardmäßig isoliert sind, und den Datenverkehr zwischen ihnen steuern, um Szenarien wie die Kommunikation zwischen einem Webserver- und einem Datenbank-VNet zu unterstützen.

**Hintergrund**:  
In Proxmox SDN sind VNets standardmäßig isoliert, was bedeutet, dass VMs in verschiedenen VNets (z. B. `vnet-web` und `vnet-db`) nicht miteinander kommunizieren können, selbst wenn sie auf demselben Host laufen. Diese Isolation ist ein Sicherheitsmerkmal, das durch VLANs und Subnetze erreicht wird. Um die Kommunikation zwischen VNets zu ermöglichen, konfigurieren wir einen virtuellen Router, der wie eine Lobby in einem Gebäude agiert und den Datenverkehr zwischen den „Wohnungen“ (VNets) weiterleitet. Dieses Modul führt Sie durch die Einrichtung und das Testen von Inter-VNet-Routing in Proxmox VE.

**Voraussetzungen**:
- Der `pve-sdn`-Dienst ist installiert und läuft (Modul 2).
- Eine VLAN-Zone (z. B. `Zone-Web`) mit mindestens zwei VNets (z. B. `vnet-web`, VLAN 10, Subnetz `10.0.1.0/24`; `vnet-db`, VLAN 20, Subnetz `10.0.2.0/24`) ist erstellt (Modul 3).
- IP-Pools für beide VNets sind konfiguriert, idealerweise mit DHCP (Modul 4).
- Mindestens zwei VMs sind erstellt: eine in `vnet-web` (z. B. IP `10.0.1.10`) und eine in `vnet-db` (z. B. IP `10.0.2.10`).
- Zugriff auf die Proxmox-GUI und die Shell.

### 5.1 Inter-VNet-Routing – Überblick
- **Was ist Inter-VNet-Routing?**: Routing ermöglicht die Weiterleitung von Datenpaketen zwischen verschiedenen VNets, die unterschiedliche Subnetze und VLANs verwenden. In Proxmox SDN wird dies durch einen virtuellen Router umgesetzt, der in der Zone konfiguriert ist.
- **Warum ist das wichtig?**: Ohne Routing sind VNets wie getrennte Inseln – VMs in `vnet-web` können nicht mit VMs in `vnet-db` kommunizieren. Dies ist problematisch für Anwendungen, bei denen z. B. ein Webserver (in `vnet-web`) auf eine Datenbank (in `vnet-db`) zugreifen muss.
- **Wie funktioniert es?**: Der virtuelle Router verwendet Routing-Tabellen, um Pakete basierend auf Ziel-IPs weiterzuleiten. Er agiert als Gateway für jedes VNet und leitet Datenverkehr zwischen Subnetzen weiter.
- **Beispiel-Szenario**: Eine VM in `vnet-web` (`10.0.1.10`) möchte mit einer VM in `vnet-db` (`10.0.2.10`) kommunizieren. Der virtuelle Router verbindet die Subnetze `10.0.1.0/24` und `10.0.2.0/24`, indem er Pakete zwischen ihnen weiterleitet.

### 5.2 Detaillierte Konzepte
- **Virtueller Router**: In Proxmox SDN wird der Router als Teil der Zone konfiguriert. Er verwendet Open vSwitch (OVS), um Datenverkehr zwischen VNets zu leiten, basierend auf IP-Adressen und VLAN-Tags.
- **Gateways**: Jedes VNet hat ein Gateway (z. B. `10.0.1.1` für `vnet-web`, `10.0.2.1` für `vnet-db`), das als Eintrittspunkt für den Datenverkehr dient. Der virtuelle Router kennt diese Gateways und leitet Pakete entsprechend weiter.
- **Routing-Tabelle**: Der Router speichert Regeln, die angeben, wie Pakete weitergeleitet werden. Beispiel:
  - Pakete für `10.0.1.0/24` → Interface für `vnet-web`.
  - Pakete für `10.0.2.0/24` → Interface für `vnet-db`.
- **VLAN-Isolation**: Selbst mit Routing bleibt die VLAN-Trennung bestehen, sodass nur explizit erlaubter Datenverkehr (durch den Router) zwischen VNets fließt.
- **Firewall-Kompatibilität**: Inter-VNet-Routing funktioniert nur, wenn die Firewall-Regeln den Datenverkehr erlauben (siehe Modul 6).

### Praktische Übungen

#### Übung 1: Zweites VNet erstellen
**Ziel**: Erstellen Sie ein zweites VNet (`vnet-db`), um die Grundlage für Inter-VNet-Routing zu schaffen, und testen Sie die Isolation.

**Schritte**:
1. **Zur Proxmox-GUI navigieren**: Öffnen Sie die Weboberfläche (`https://<Proxmox-IP>:8006`) und gehen Sie zu *Datacenter > SDN > VNets*.
2. **VNet erstellen**:
   - Klicken Sie auf *Erstellen*.
   - **Name**: Geben Sie `vnet-db` ein (für Datenbank-VMs).
   - **Zone**: Wählen Sie `Zone-Web` (aus Modul 3).
   - **VLAN ID**: Geben Sie `20` ein (eindeutig, unterschiedlich zu `vnet-web`).
   - **Subnet**: Geben Sie `10.0.2.0/24` ein (256 Adressen, z. B. `10.0.2.1` bis `10.0.2.254`).
   - **Gateway**: Geben Sie `10.0.2.1` ein (für späteres Routing).
   - **IPAM**: Wählen Sie *pve* (für automatisches IP-Management, siehe Modul 4).
   - Klicken Sie auf *Create*.
3. **IP-Pool für `vnet-db` erstellen** (optional, für DHCP):
   - Gehen Sie zu *Datacenter > SDN > IP-Pools*.
   - Klicken Sie auf *Erstellen*.
   - **Name**: `db-pool`.
   - **VNet**: Wählen Sie `vnet-db`.
   - **Subnet**: `10.0.2.100/26` (64 Adressen, `10.0.2.100` bis `10.0.2.163`).
   - **Gateway**: `10.0.2.1`.
   - **DHCP**: Aktivieren Sie die Checkbox.
   - Klicken Sie auf *Create*.
4. **Zweite VM erstellen und verbinden**:
   - Erstellen Sie eine neue VM (z. B. Ubuntu) in der Proxmox-GUI.
   - Unter *Hardware > Netzwerkgerät*:
     - **Bridge**: Wählen Sie `ovsbr0`.
     - **VLAN Tag**: Geben Sie `20` ein (oder wählen Sie `vnet-db`, falls verfügbar).
   - Konfigurieren Sie die VM für DHCP (wie in Modul 4):
     ```bash
     sudo nano /etc/netplan/01-netcfg.yaml
     ```
     - Inhalt:
       ```yaml
       network:
         version: 2
         renderer: networkd
         ethernets:
           eth0:
             dhcp4: yes
       ```
     - Anwenden:
       ```bash
       sudo netplan apply
       ```
   - Starten Sie die VM neu und prüfen Sie die IP:
     ```bash
     ip a
     ```
     - **Erwartete Ausgabe**: z. B. `10.0.2.101/26`.
5. **Isolation testen**:
   - Von der VM in `vnet-web` (z. B. `10.0.1.101`):
     ```bash
     ping 10.0.2.101
     ```
     - **Erwartete Ausgabe**: Keine Antwort („Destination Host Unreachable“), da kein Routing konfiguriert ist.
   - Dies bestätigt, dass VNets standardmäßig isoliert sind.

**Fehlerbehebung**:
- Falls das VNet nicht erstellt wird, prüfen Sie `/etc/pve/sdn/vnets.cfg` und `sudo systemctl status pve-sdn`.
- Falls die VM keine IP erhält, überprüfen Sie die DHCP-Einstellungen (`cat /etc/pve/sdn/ippools.cfg`) und die OVS-Bridge (`ovs-vsctl show`).

#### Übung 2: Inter-VNet-Routing konfigurieren
**Ziel**: Konfigurieren Sie einen virtuellen Router, um die Kommunikation zwischen `vnet-web` und `vnet-db` zu ermöglichen, und testen Sie die Konnektivität.

**Schritte**:
1. **Zur Proxmox-GUI navigieren**: Gehen Sie zu *Datacenter > SDN > Controllers* (oder *Routers*, abhängig von der Proxmox-Version).
2. **Virtuellen Router erstellen**:
   - Klicken Sie auf *Erstellen* > *Simple* (oder *EVPN* für fortgeschrittene Setups, hier nicht benötigt).
   - **Name**: Geben Sie `router-web-db` ein.
   - **Zone**: Wählen Sie `Zone-Web`.
   - **VNets**: Wählen Sie `vnet-web` und `vnet-db`.
   - **Gateways**:
     - Für `vnet-web`: `10.0.1.1`.
     - Für `vnet-db`: `10.0.2.1`.
   - **Optionale Einstellungen**:
     - **SNAT** (Source Network Address Translation): Aktivieren Sie dies, falls Sie später Internetzugriff konfigurieren (Modul 8).
     - **DNS**: Lassen Sie leer oder setzen Sie z. B. `8.8.8.8`.
   - Klicken Sie auf *Create*.
3. **Routing überprüfen**:
   - In der Shell des Proxmox-Hosts:
     ```bash
     ip route
     ```
     - **Erwartete Ausgabe**: Routen für `10.0.1.0/24` und `10.0.2.0/24` sollten über die OVS-Bridge (`ovsbr0`) geführt werden.
   - Prüfen Sie die OVS-Konfiguration:
     ```bash
     ovs-vsctl show
     ```
     - Stellen Sie sicher, dass `vnet-web` (VLAN 10) und `vnet-db` (VLAN 20) korrekt mit `ovsbr0` verbunden sind.
4. **Konnektivität testen**:
   - Von der VM in `vnet-web` (z. B. `10.0.1.101`):
     ```bash
     ping 10.0.2.101
     ```
     - **Erwartete Ausgabe**: Antworten wie `64 bytes from 10.0.2.101: icmp_seq=1 ttl=64 time=0.4 ms`.
   - Von der VM in `vnet-db` (z. B. `10.0.2.101`):
     ```bash
     ping 10.0.1.101
     ```
     - **Erfolg**: Beide VMs können sich gegenseitig erreichen.
5. **Fehlerbehebung**:
   - **Ping fehlschlägt**: Prüfen Sie die Firewall der VMs (`sudo ufw status`) und deaktivieren Sie sie vorübergehend (`sudo ufw disable`).
   - **Routing nicht aktiv**: Überprüfen Sie `/etc/pve/sdn/controllers.cfg`:
     ```bash
     cat /etc/pve/sdn/controllers.cfg
     ```
     - **Erwartete Ausgabe**:
       ```plaintext
       simple: router-web-db
           vnets vnet-web,vnet-db
           gateway 10.0.1.1,10.0.2.1
       ```
   - Stellen Sie sicher, dass `pve-sdn` läuft:
     ```bash
     sudo systemctl restart pve-sdn
     ```
   - Prüfen Sie, ob die Gateways korrekt gesetzt sind und die OVS-Bridge VLAN-Tags verarbeitet (`ovs-vsctl show`).

**Erweiterung**: Testen Sie eine Anwendung, z. B. SSH von der VM in `vnet-web` zur VM in `vnet-db`:
```bash
ssh user@10.0.2.101
```
- Falls dies fehlschlägt, prüfen Sie die Firewall-Regeln (siehe Modul 6).

### 5.3 Häufige Probleme und Fehlerbehebung
- **Problem: Keine Kommunikation zwischen VNets**:
  - Lösung: Überprüfen Sie die Router-Konfiguration (`cat /etc/pve/sdn/controllers.cfg`) und die Gateways. Stellen Sie sicher, dass die VMs die korrekten Gateways verwenden (`ip route` in der VM).
- **Problem: VLAN-Tags verhindern Routing**:
  - Lösung: Prüfen Sie, ob die OVS-Bridge *VLAN aware* ist (`ovs-vsctl show`) und der physische Switch VLAN 10 und 20 erlaubt.
- **Problem: Firewall blockiert Datenverkehr**:
  - Lösung: Deaktivieren Sie vorübergehend die Firewall in den VMs (`sudo ufw disable`) oder konfigurieren Sie Regeln (Modul 6).

### 5.4 Vorbereitung auf die nächsten Module
- **Was kommt als Nächstes?**: In Modul 6 konfigurieren Sie SDN-Firewall-Regeln, um den Datenverkehr zwischen VNets gezielt zu kontrollieren (z. B. nur SSH erlauben). Dies baut auf dem hier erstellten Routing auf.
- **Empfehlung**: Testen Sie weitere Szenarien, z. B. eine dritte VM in einem neuen VNet, und konfigurieren Sie Routing für alle drei VNets. Dokumentieren Sie die Gateways und Subnetze.
- **Dokumentation**: Erstellen Sie ein Diagramm (z. B. auf Papier oder mit draw.io), das `vnet-web`, `vnet-db`, den virtuellen Router und die VMs mit ihren IPs zeigt.

**Fragen zur Selbstreflexion**:
1. Warum ist Inter-VNet-Routing notwendig, wenn VNets standardmäßig isoliert sind?
2. Wie können Sie überprüfen, ob ein Paket korrekt vom Router zwischen `vnet-web` und `vnet-db` weitergeleitet wird?
3. Welche Rolle spielt das Gateway in jedem VNet?

Falls Sie eine Visualisierung (z. B. ein Netzwerkdiagramm mit ChartJS) oder weitere Details (z. B. zu erweiterten Routing-Optionen oder OVS-Flows) wünschen, lassen Sie es mich wissen!

**[Modul 6: SDN-Firewall und Sicherheitsregeln](Modul06_FW.md)**   oder **[zurück zur Übersicht](00_Übersicht_SDN.md)**