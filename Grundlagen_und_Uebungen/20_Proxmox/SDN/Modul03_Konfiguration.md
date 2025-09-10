## Modul 3: Konfiguration der grundlegenden SDN-Komponenten

**Lernziel**: Verstehen und praktisch umsetzen der grundlegenden SDN-Komponenten in Proxmox VE, insbesondere die Erstellung und Verwaltung von Zonen und VNets (virtuelle Netzwerke). Nach diesem Modul können Sie virtuelle Netzwerke logisch trennen, VLANs zuweisen und VMs in diese Netzwerke integrieren, um eine skalierbare und sichere Netzwerkumgebung aufzubauen.

**Hintergrund**:  
In Proxmox SDN sind **Zonen** und **VNets** die Kernbausteine für die Organisation virtueller Netzwerke. Eine **Zone** ist wie ein Gebäude, das mehrere virtuelle Netzwerke (VNets) beherbergt, die jeweils durch VLAN-IDs und Subnetze definiert sind. VNets sind wie Wohnungen in diesem Gebäude, die spezifische Netzwerke für VMs oder Container bereitstellen. Dieses Modul führt Sie Schritt für Schritt durch die Erstellung und Zuweisung dieser Komponenten, um eine logisch getrennte Netzwerkumgebung aufzubauen.

### 3.1 SDN-Komponenten in Proxmox VE
- **Zonen**: Eine Zone definiert einen Bereich für virtuelle Netzwerke. Sie bestimmt, wie VNets mit der physischen Infrastruktur (z. B. OVS-Bridge) verbunden sind und welche SDN-Technologie verwendet wird (z. B. VLAN, VXLAN oder BGP). In diesem Modul konzentrieren wir uns auf VLAN-Zonen, da diese am häufigsten für grundlegende SDN-Setups verwendet werden.
- **VNets**: Ein virtuelles Netzwerk innerhalb einer Zone, das durch eine VLAN-ID und ein Subnetz definiert ist. VNets isolieren den Datenverkehr und ermöglichen die Zuweisung von VMs zu spezifischen Netzwerken.
- **OVS-Bridge**: Die Brücke (z. B. `ovsbr0`, erstellt in Modul 1) verbindet VNets mit der physischen Netzwerkschnittstelle und handhabt VLAN-Tags.
- **Warum ist das wichtig?**: Durch Zonen und VNets können Sie Netzwerke logisch trennen (z. B. ein Netzwerk für Webserver, ein anderes für Datenbanken), ohne zusätzliche physische Hardware. Dies erhöht Sicherheit, Skalierbarkeit und Effizienz.

**Voraussetzungen**:
- Der `pve-sdn`-Dienst ist installiert und läuft (siehe Modul 2).
- Eine OVS-Bridge (z. B. `ovsbr0`) mit aktivierter *VLAN aware*-Option existiert.
- Zugriff auf die Proxmox-GUI und die Shell.
- Optional: Ein physischer Switch, der VLAN-Tagging unterstützt, falls externe Netzwerke verwendet werden.

### 3.2 Detaillierte Konzepte
- **VLAN-Zone**: Eine Zone vom Typ VLAN verwendet VLAN-Tagging, um Netzwerke zu trennen. Sie ist mit einer OVS-Bridge verknüpft und definiert die physische Schnittstelle, über die der Datenverkehr läuft.
- **VNet**: Jedes VNet in einer Zone hat eine eindeutige VLAN-ID (1-4094) und ein Subnetz (z. B. `10.0.1.0/24`). VMs, die einem VNet zugewiesen sind, kommunizieren nur innerhalb dieses Netzwerks, es sei denn, Routing ist konfiguriert (Modul 5).
- **VLAN-Tagging in OVS**: Wenn *VLAN aware* aktiviert ist, fügt OVS automatisch Tags zu Datenpaketen hinzu, die über die Bridge gesendet werden. Dies ermöglicht die Kommunikation mit externen Switches, die VLANs unterstützen.
- **Beispiel-Szenario**: Stellen Sie sich vor, Sie betreiben einen Webserver (VNet mit VLAN 10, Subnetz `10.0.1.0/24`) und eine Datenbank (VNet mit VLAN 20, Subnetz `10.0.2.0/24`). Beide sind in einer Zone (`Zone-Web`), die mit `ovsbr0` verbunden ist. Die VMs in diesen VNets sind isoliert, bis Sie Routing oder Firewall-Regeln konfigurieren.

### Praktische Übungen

#### Übung 1: VLAN-Zone erstellen
**Ziel**: Erstellen Sie eine VLAN-Zone in Proxmox, die als Container für VNets dient und mit einer OVS-Bridge verbunden ist.

**Schritte**:
1. **Zur Proxmox-GUI navigieren**: Öffnen Sie die Weboberfläche (`https://<Proxmox-IP>:8006`) und gehen Sie zu *Datacenter > SDN > Zones*.
2. **Zone erstellen**:
   - Klicken Sie auf *Erstellen* > *VLAN*.
   - **Name**: Geben Sie `Zone-Web` ein (beliebig, aber beschreibend, z. B. für Webserver).
   - **Bridge**: Wählen Sie die OVS-Bridge, z. B. `ovsbr0` (muss *VLAN aware* sein, siehe Modul 1).
   - **Nodes**: Wählen Sie den Proxmox-Knoten aus, auf dem die Zone aktiv sein soll (z. B. `pve-node1`). In einem Cluster können mehrere Knoten ausgewählt werden.
   - **Optionale Einstellungen**:
     - **DNS Zone Prefix**: Lassen Sie leer, es sei denn, Sie konfigurieren später DNS (Modul 4).
     - **IPAM**: Lassen Sie auf *None* oder wählen Sie *pve* (für automatisches IP-Management, Modul 4).
   - Klicken Sie auf *Create*.
3. **Überprüfen**:
   - In der GUI sollte `Zone-Web` unter *Zones* angezeigt werden.
   - In der Shell: Prüfen Sie die SDN-Konfigurationsdatei:
     ```bash
     cat /etc/pve/sdn/zones.cfg
     ```
     - **Erwartete Ausgabe**:
       ```plaintext
       vlan: Zone-Web
           bridge ovsbr0
           nodes pve-node1
       ```
4. **Fehlerbehebung**:
   - Falls die Zone nicht erstellt wird, überprüfen Sie, ob `pve-sdn` läuft:
     ```bash
     sudo systemctl status pve-sdn
     ```
   - Stellen Sie sicher, dass `ovsbr0` existiert und korrekt konfiguriert ist:
     ```bash
     ovs-vsctl show
     ```
   - Falls die GUI nicht aktualisiert, starten Sie `pveproxy` neu:
     ```bash
     sudo systemctl restart pveproxy
     ```

**Tipp**: Dokumentieren Sie den Namen der Zone (`Zone-Web`) und die zugewiesene Bridge, da diese in den nächsten Übungen verwendet werden.

#### Übung 2: VNet erstellen
**Ziel**: Erstellen Sie ein virtuelles Netzwerk (VNet) innerhalb der Zone, das durch eine VLAN-ID und ein Subnetz definiert ist.

**Schritte**:
1. **Zur SDN-Sektion navigieren**: Gehen Sie zu *Datacenter > SDN > VNets*.
2. **VNet erstellen**:
   - Klicken Sie auf *Erstellen*.
   - **Name**: Geben Sie `vnet-web` ein (z. B. für Webserver).
   - **Zone**: Wählen Sie `Zone-Web` (aus Übung 1).
   - **VLAN ID**: Geben Sie `10` ein (muss zwischen 1 und 4094 liegen, einzigartig pro Zone).
   - **Subnet**: Geben Sie `10.0.1.0/24` ein (entspricht 256 Adressen, z. B. `10.0.1.1` bis `10.0.1.254`).
   - **Gateway** (optional): Geben Sie `10.0.1.1` ein, falls Sie später Routing konfigurieren möchten.
   - **Optionale Einstellungen**:
     - **Tag**: Wird automatisch aus VLAN-ID übernommen (10).
     - **IPAM**: Lassen Sie auf *pve* oder leer, falls Sie manuelle IPs verwenden.
   - Klicken Sie auf *Create*.
3. **Überprüfen**:
   - In der GUI sollte `vnet-web` unter *VNets* erscheinen.
   - In der Shell:
     ```bash
     cat /etc/pve/sdn/vnets.cfg
     ```
     - **Erwartete Ausgabe**:
       ```plaintext
       vnet: vnet-web
           zone Zone-Web
           tag 10
           ipam pve
           subnet 10.0.1.0/24
           gateway 10.0.1.1
       ```
   - Prüfen Sie OVS:
     ```bash
     ovs-vsctl show
     ```
     - Die Ausgabe sollte zeigen, dass `ovsbr0` VLAN-Tags verarbeitet.
4. **Fehlerbehebung**:
   - Falls das VNet nicht erscheint, prüfen Sie, ob die Zone korrekt ist und `pve-sdn` läuft.
   - Falls VLAN-Tags nicht funktionieren, stellen Sie sicher, dass der physische Switch VLAN 10 erlaubt (siehe Modul 2, Übung 3).

**Tipp**: Erstellen Sie ein zweites VNet (z. B. `vnet-db`, VLAN 20, Subnetz `10.0.2.0/24`) für spätere Übungen zu Inter-VNet-Routing (Modul 5).

#### Übung 3: VM dem VNet zuweisen
**Ziel**: Verbinden Sie eine VM mit dem erstellten VNet und testen Sie die Netzwerkkonnektivität.

**Voraussetzungen**: Eine VM (z. B. Ubuntu) ist erstellt, wie in Modul 1 beschrieben. Die VM sollte mit der OVS-Bridge `ovsbr0` verbunden sein.

**Schritte**:
1. **VM auswählen**: Gehen Sie in der Proxmox-GUI zu Ihrer VM (z. B. `VM 100`).
2. **Netzwerkgerät bearbeiten**:
   - Gehen Sie zu *Hardware* > *Netzwerkgerät (net0)* > *Bearbeiten*.
   - **Bridge**: Wählen Sie `ovsbr0` (falls nicht bereits gesetzt).
   - **VLAN Tag**: Geben Sie `10` ein (passend zu `vnet-web`).
   - Alternativ: Wählen Sie `vnet-web` direkt aus, wenn die GUI dies unterstützt (ab Proxmox 7.3+).
   - **Modell**: Lassen Sie `VirtIO` für beste Performance.
   - Klicken Sie auf *OK* und dann auf *Anwenden*.
3. **IP-Adresse konfigurieren**:
   - Starten Sie die VM und öffnen Sie die Shell (über GUI-Konsole oder SSH).
   - Bearbeiten Sie die Netzwerkkonfiguration, z. B. für Ubuntu mit Netplan:
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
             dhcp4: no
             addresses: [10.0.1.10/24]
             gateway4: 10.0.1.1
             nameservers:
               addresses: [8.8.8.8, 8.8.4.4]
       ```
   - Speichern und anwenden:
     ```bash
     sudo netplan apply
     ```
4. **Konnektivität testen**:
   - Überprüfen Sie die IP:
     ```bash
     ip a
     ```
     - **Erwartete Ausgabe**: `eth0` hat die Adresse `10.0.1.10/24`.
   - Testen Sie das Gateway:
     ```bash
     ping 10.0.1.1
     ```
     - **Erfolg**: Antworten wie `64 bytes from 10.0.1.1: icmp_seq=1 ttl=64 time=0.2 ms`.
   - Testen Sie externe Konnektivität (falls Routing konfiguriert ist):
     ```bash
     ping 8.8.8.8
     ```
5. **Fehlerbehebung**:
   - **Keine IP**: Überprüfen Sie die Netplan-Konfiguration oder ob `vnet-web` korrekt zugewiesen ist.
   - **Kein Ping**: Prüfen Sie die OVS-Bridge (`ovs-vsctl show`) und ob VLAN 10 auf dem physischen Switch erlaubt ist.
   - **Firewall-Probleme**: Deaktivieren Sie vorübergehend die VM-Firewall (`sudo ufw disable`) für Tests.

**Erweiterung**: Erstellen Sie eine zweite VM und weisen Sie sie einem anderen VNet zu (z. B. `vnet-db`, VLAN 20, IP `10.0.2.10`). Versuchen Sie, von `vnet-web` zu `vnet-db` zu pingen – dies sollte fehlschlagen, da kein Routing konfiguriert ist (wird in Modul 5 behandelt).

### 3.3 Häufige Probleme und Fehlerbehebung
- **Problem: VNet wird nicht erstellt**:
  - Lösung: Überprüfen Sie, ob die Zone existiert und `pve-sdn` läuft (`sudo systemctl status pve-sdn`). Prüfen Sie `/etc/pve/sdn/vnets.cfg`.
- **Problem: VM hat keine Konnektivität**:
  - Lösung: Überprüfen Sie die VLAN-ID im Netzwerkgerät der VM, die OVS-Bridge-Konfiguration (`ovs-vsctl show`) und die Switch-Konfiguration (VLAN erlaubt?).
- **Problem: Konflikte zwischen VNets**:
  - Lösung: Stellen Sie sicher, dass VLAN-IDs eindeutig sind und Subnetze sich nicht überschneiden (z. B. `10.0.1.0/24` vs. `10.0.2.0/24`).

### 3.4 Vorbereitung auf die nächsten Module
- **Was kommt als Nächstes?**: In Modul 4 konfigurieren Sie IPAM, um IP-Adressen automatisch zuzuweisen. In Modul 5 richten Sie Inter-VNet-Routing ein, um die Kommunikation zwischen `vnet-web` und `vnet-db` zu ermöglichen.
- **Empfehlung**: Experimentieren Sie mit mehreren VNets (z. B. `vnet-web`, `vnet-db`, `vnet-mgmt`) und VMs, um die Isolation zu testen. Notieren Sie die VLAN-IDs und Subnetze für spätere Module.
- **Dokumentation**: Erstellen Sie ein einfaches Diagramm (z. B. auf Papier oder mit Tools wie draw.io), das Ihre Zone (`Zone-Web`), VNets (`vnet-web`, `vnet-db`) und VMs mit IPs zeigt.

**Fragen zur Selbstreflexion**:
1. Warum ist die Trennung von VNets durch VLAN-IDs sicherer als ein einziges Netzwerk?
2. Wie können Sie überprüfen, ob ein Datenpaket korrekt mit VLAN 10 getaggt ist?
3. Was passiert, wenn zwei VNets dieselbe VLAN-ID verwenden?

Falls Sie eine Visualisierung (z. B. ein Netzwerkdiagramm mit ChartJS) oder weitere Details zu einem Aspekt (z. B. OVS-Flow-Regeln) wünschen, lassen Sie es mich wissen!

**[Modul 4: Automatisches IP-Management (IPAM)](Modul04_IPAM.md)**   oder **[zurück zur Übersicht](00_Übersicht_SDN.md)**