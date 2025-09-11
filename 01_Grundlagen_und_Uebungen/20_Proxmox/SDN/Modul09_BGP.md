## Modul 9: Dynamisches Routing mit BGP

**Lernziel**: Einrichten und Verwalten von dynamischem Routing mit dem Border Gateway Protocol (BGP) in einer Proxmox VE SDN-Umgebung. Nach diesem Modul können Sie BGP verwenden, um Routen automatisch zwischen VNets und externen Netzwerken zu propagieren, was die Skalierbarkeit und Flexibilität Ihrer Netzwerkinfrastruktur erhöht, insbesondere in komplexeren Setups mit mehreren Knoten oder Clustern.

**Hintergrund**:  
Statische Routen (Modul 8) sind effektiv für einfache Netzwerke, aber in größeren Umgebungen mit vielen VNets oder dynamischen Änderungen werden sie unpraktisch, da jede Route manuell konfiguriert werden muss. BGP, ein dynamisches Routing-Protokoll, automatisiert diesen Prozess, indem es Routen zwischen Netzwerken austauscht. In Proxmox VE wird BGP oft in Kombination mit EVPN (Ethernet VPN) verwendet, um VNets über mehrere Knoten hinweg zu verbinden. Dieses Modul führt Sie durch die Einrichtung von BGP in Proxmox SDN, um automatische Routen zwischen `vnet-web`, `vnet-db` und externen Netzwerken zu ermöglichen.

**Voraussetzungen**:
- Der `pve-sdn`-Dienst ist installiert und läuft (Modul 2).
- Eine VLAN-Zone (z. B. `Zone-Web`) mit VNets (`vnet-web`, VLAN 10, Subnetz `10.0.1.0/24`; `vnet-db`, VLAN 20, Subnetz `10.0.2.0/24`) ist konfiguriert (Modul 3).
- IP-Pools sind eingerichtet (Modul 4).
- Inter-VNet-Routing ist aktiviert (Modul 5).
- Firewall-Regeln erlauben gewünschten Verkehr, z. B. ICMP oder TCP Port 80 (Modul 6).
- Statische Routen sind für externe Netzwerke konfiguriert (Modul 8).
- Ein physischer Router (z. B. `192.168.1.1`) unterstützt BGP und ist über die OVS-Bridge (`ovsbr0`) erreichbar.
- Mindestens eine VM in `vnet-web` (z. B. IP `10.0.1.101`) und eine in `vnet-db` (z. B. IP `10.0.2.101`).
- Zugriff auf die Proxmox-GUI (`https://<Proxmox-IP>:8006`) und die Shell.
- Optional: Ein BGP-fähiger Router (z. B. FRRouting oder ein kommerzieller Router wie Cisco) ist im Netzwerk vorhanden.

### 9.1 Dynamisches Routing mit BGP – Überblick
- **Was ist BGP?**: Das Border Gateway Protocol ist ein standardisiertes Protokoll (RFC 4271), das verwendet wird, um Routing-Informationen zwischen autonomen Systemen (AS) auszutauschen. In Proxmox SDN ermöglicht BGP die automatische Verteilung von Routen zwischen VNets und externen Netzwerken, ohne manuelle Konfiguration statischer Routen.
- **Warum BGP?**:
  - **Automatisierung**: Routen werden dynamisch propagiert, was Änderungen in der Netzwerkstruktur (z. B. neue VNets) automatisch berücksichtigt.
  - **Skalierbarkeit**: Geeignet für Cluster mit mehreren Proxmox-Knoten oder komplexe Netzwerke.
  - **Interoperabilität**: BGP ist ein Standardprotokoll, das mit externen Routern (z. B. im Rechenzentrum) kompatibel ist.
- **BGP in Proxmox SDN**: Proxmox nutzt FRRouting (FRR), ein Open-Source-Routing-Protokoll-Stack, um BGP zu implementieren. BGP wird in einer Zone vom Typ *EVPN* aktiviert, die VNets über Knoten hinweg verbindet.
- **Beispiel-Szenario**: Sie möchten, dass `vnet-web` (`10.0.1.0/24`) und `vnet-db` (`10.0.2.0/24`) ihre Subnetze automatisch mit einem externen BGP-fähigen Router (z. B. `192.168.1.1`) teilen, sodass externe Netzwerke die VNets erreichen können.

### 9.2 Detaillierte Konzepte
- **EVPN-Zone**: In Proxmox SDN ist BGP oft mit einer EVPN-Zone verknüpft, die Layer-2- und Layer-3-Konnektivität kombiniert. EVPN nutzt BGP, um MAC-Adressen und IP-Routen zwischen Knoten zu verteilen.
- **Autonomous System (AS)**: Jedes Netzwerk erhält eine AS-Nummer (z. B. 65001 für Proxmox, 65002 für den externen Router). BGP-Peers tauschen Routen zwischen diesen AS-Nummern aus.
- **BGP-Peering**: Proxmox (FRR) etabliert eine Verbindung mit einem externen BGP-fähigen Router. Die Peers tauschen Routen für Subnetze (z. B. `10.0.1.0/24`) aus.
- **Route Propagation**: BGP teilt die Subnetze der VNets mit dem externen Router, der diese in seine Routing-Tabelle aufnimmt und umgekehrt.
- **Firewall-Integration**: BGP-Routen beeinflussen nur die Weiterleitung, nicht die Freigabe von Verkehr. Firewall-Regeln (Modul 6) müssen weiterhin den Datenverkehr erlauben.
- **FRRouting**: Proxmox verwendet FRR, um BGP zu implementieren. Die Konfiguration erfolgt über die GUI, aber Sie können die FRR-Konfiguration in `/etc/frr/frr.conf` überprüfen.

### Praktische Übungen

#### Übung 1: BGP-fähige Zone erstellen
**Ziel**: Erstellen Sie eine EVPN-Zone mit BGP-Unterstützung und konfigurieren Sie VNets für dynamisches Routing.

**Schritte**:
1. **Voraussetzungen prüfen**:
   - Stellen Sie sicher, dass FRRouting installiert ist:
     ```bash
     dpkg -l | grep frr
     ```
     - Falls nicht installiert:
       ```bash
       sudo apt update && sudo apt install frr
       ```
   - Aktivieren Sie BGP in FRR:
     ```bash
     sudo nano /etc/frr/daemons
     ```
     - Setzen Sie `bgpd=yes` und speichern Sie.
     - Starten Sie FRR:
       ```bash
       sudo systemctl restart frr
       ```
2. **EVPN-Zone erstellen**:
   - Öffnen Sie die Proxmox-GUI und gehen Sie zu *Datacenter > SDN > Zones*.
   - Klicken Sie auf *Erstellen* > *EVPN*.
   - **Einstellungen**:
     - **Name**: `Zone-EVPN`.
     - **Nodes**: Wählen Sie Ihren Proxmox-Knoten (z. B. `pve-node1`).
     - **Bridge**: `ovsbr0` (muss *VLAN aware* sein, siehe Modul 1).
     - **AS Number**: `65001` (für Proxmox).
     - **Peers**: Geben Sie die IP des externen Routers ein (z. B. `192.168.1.1`).
   - Klicken Sie auf *Create*.
3. **VNets der Zone zuweisen**:
   - Gehen Sie zu *Datacenter > SDN > VNets*.
   - Bearbeiten Sie `vnet-web`:
     - **Zone**: Ändern Sie von `Zone-Web` zu `Zone-EVPN`.
     - Überprüfen Sie VLAN 10, Subnetz `10.0.1.0/24`, Gateway `10.0.1.1`.
   - Bearbeiten Sie `vnet-db`:
     - **Zone**: Ändern Sie zu `Zone-EVPN`.
     - Überprüfen Sie VLAN 20, Subnetz `10.0.2.0/24`, Gateway `10.0.2.1`.
4. **Überprüfen**:
   - In der Shell:
     ```bash
     cat /etc/pve/sdn/zones.cfg
     ```
     - **Erwartete Ausgabe**:
       ```plaintext
       evpn: Zone-EVPN
           bridge ovsbr0
           nodes pve-node1
           asn 65001
           peers 192.168.1.1
       ```
     ```bash
     cat /etc/pve/sdn/vnets.cfg
     ```
     - **Erwartete Ausgabe**:
       ```plaintext
       vnet: vnet-web
           zone Zone-EVPN
           tag 10
           subnet 10.0.1.0/24
           gateway 10.0.1.1
       vnet: vnet-db
           zone Zone-EVPN
           tag 20
           subnet 10.0.2.0/24
           gateway 10.0.2.1
       ```
   - Prüfen Sie die FRR-Konfiguration:
     ```bash
     cat /etc/frr/frr.conf
     ```
     - **Erwartete Ausgabe**: Enthält BGP-Konfiguration mit AS 65001 und Neighbor `192.168.1.1`.
5. **Fehlerbehebung**:
   - **Zone wird nicht erstellt**: Prüfen Sie, ob `pve-sdn` und `frr` laufen:
     ```bash
     sudo systemctl status pve-sdn frr
     ```
   - **Peers nicht erreichbar**: Testen Sie die Verbindung zum externen Router:
     ```bash
     ping 192.168.1.1
     ```

#### Übung 2: BGP-Peering testen
**Ziel**: Überprüfen Sie, ob BGP-Routen korrekt zwischen Proxmox und dem externen Router ausgetauscht werden.

**Schritte**:
1. **Externen Router konfigurieren** (falls Sie Zugriff haben, z. B. FRR oder Cisco):
   - Beispiel für FRR auf dem externen Router (`192.168.1.1`):
     ```plaintext
     router bgp 65002
       neighbor 192.168.1.10 remote-as 65001
       address-family ipv4 unicast
         network 192.168.1.0/24
       exit
     ```
     - **Hinweis**: `192.168.1.10` ist die IP der OVS-Bridge (`ovsbr0`) auf dem Proxmox-Host.
2. **BGP-Status prüfen**:
   - Auf dem Proxmox-Host:
     ```bash
     vtysh -c "show ip bgp summary"
     ```
     - **Erwartete Ausgabe**:
       ```plaintext
       Neighbor      V         AS  MsgRcvd  MsgSent  TblVer  InQ  OutQ  Up/Down  State/PfxRcd
       192.168.1.1   4      65002  10       12       0       0    0     00:05:00  1
       ```
       - Dies zeigt, dass das Peering aktiv ist und Routen ausgetauscht werden.
   - Prüfen Sie die BGP-Routen:
     ```bash
     vtysh -c "show ip bgp"
     ```
     - **Erwartete Ausgabe**: Enthält Routen wie `10.0.1.0/24` und `10.0.2.0/24` (von Proxmox) sowie externe Routen (z. B. `192.168.1.0/24` vom Router).
3. **Routing-Tabelle prüfen**:
   - Auf dem Proxmox-Host:
     ```bash
     ip route
     ```
     - **Erwartete Ausgabe**: Enthält dynamische Routen von BGP, z. B. `192.168.1.0/24 via 192.168.1.1`.
4. **Fehlerbehebung**:
   - **Peering nicht aktiv**: Prüfen Sie die FRR-Konfiguration (`/etc/frr/frr.conf`) und die Erreichbarkeit des Peers (`ping 192.168.1.1`).
   - **Routen fehlen**: Überprüfen Sie die BGP-Logs:
     ```bash
     journalctl -u frr
     ```
   - **Firewall blockiert BGP**: Stellen Sie sicher, dass TCP Port 179 (BGP) erlaubt ist:
     ```bash
     cat /etc/pve/firewall/vnets/vnet-web.fw
     ```
     - Fügen Sie ggf. eine Regel hinzu:
       ```plaintext
       IN ACCEPT -source 192.168.1.0/24 -dest 192.168.1.10 -p tcp -dport 179
       ```

#### Übung 3: Konnektivität testen
**Ziel**: Testen Sie, ob VMs in `vnet-web` und `vnet-db` externe Netzwerke über BGP-Routen erreichen können.

**Schritte**:
1. **Firewall-Regeln anpassen**:
   - In *Datacenter > SDN > VNets > vnet-web > Firewall*:
     - Erstellen Sie eine Regel für ausgehenden Verkehr:
       - **Aktion**: `Accept`.
       - **Protokoll**: `ICMP` (für `ping`) oder `TCP` (für HTTP, Port 80).
       - **Richtung**: `Out`.
       - **Quellnetzwerk**: `10.0.1.0/24`.
       - **Zielnetzwerk**: `0.0.0.0/0`.
     - Wiederholen Sie dies für `vnet-db`.
   - Wenden Sie die Änderungen an:
     ```bash
     pve-firewall compile
     ```
2. **Internetzugriff testen**:
   - In der VM in `vnet-web` (`10.0.1.101`):
     ```bash
     ping 8.8.8.8
     ```
     - **Erfolg**: Antworten wie `64 bytes from 8.8.8.8: icmp_seq=1 ttl=117 time=20 ms`.
   - Testen Sie HTTP:
     ```bash
     curl http://www.google.com
     ```
     - **Erfolg**: HTML-Antwort.
3. **Externe Erreichbarkeit testen**:
   - Vom externen Netzwerk (z. B. `192.168.1.100`) pingen Sie die VM:
     ```bash
     ping 10.0.1.101
     ```
     - **Erfolg**: Antworten, wenn BGP die Route propagiert hat und die Firewall ICMP erlaubt.
   - **Fehlerbehebung**: Falls nicht erfolgreich, prüfen Sie die BGP-Routen (`vtysh -c "show ip bgp"`) und Firewall-Regeln.
4. **Fehlerbehebung**:
   - **Kein Internetzugriff**: Prüfen Sie BGP-Status (`vtysh -c "show ip bgp summary"`), Firewall-Regeln und die Routing-Tabelle (`ip route`).
   - **Externe Netzwerke erreichen VNet nicht**: Stellen Sie sicher, dass der externe Router die Routen `10.0.1.0/24` und `10.0.2.0/24` erhalten hat.
   - **Logs prüfen**: BGP-Logs in `/var/log/frr/bgpd.log` oder `journalctl -u frr`.

### 9.3 Häufige Probleme und Fehlerbehebung
- **Problem: BGP-Peering wird nicht aufgebaut**:
  - **Prüfen**: BGP-Status (`vtysh -c "show ip bgp summary"`), Erreichbarkeit des Peers (`ping 192.168.1.1`), Firewall-Regeln für TCP Port 179.
  - **Lösung**: Korrigieren Sie die AS-Nummer oder Peer-IP, starten Sie FRR neu (`sudo systemctl restart frr`).
- **Problem: Routen werden nicht propagiert**:
  - **Prüfen**: BGP-Routen (`vtysh -c "show ip bgp"`), VNet-Konfiguration (`cat /etc/pve/sdn/vnets.cfg`).
  - **Lösung**: Stellen Sie sicher, dass die Subnetze in der EVPN-Zone korrekt sind.
- **Problem: Firewall blockiert Verkehr**:
  - **Prüfen**: Firewall-Regeln (`cat /etc/pve/firewall/vnets/vnet-web.fw`), Logs (`journalctl -u pve-firewall`).
  - **Lösung**: Regeln für ICMP oder TCP anpassen.

### 9.4 Vorbereitung auf die nächsten Module
- **Was kommt als Nächstes?**: In Modul 10 lernen Sie, SDN mit Load Balancing zu kombinieren, um den Datenverkehr effizient zu verteilen. BGP-Routen sind hierfür eine Grundlage, da sie die Erreichbarkeit sicherstellen.
- **Empfehlung**: Experimentieren Sie mit weiteren BGP-Peers (z. B. einem zweiten externen Router) und testen Sie die Ausfallsicherheit, indem Sie einen Peer deaktivieren. Dokumentieren Sie die AS-Nummern und propagierten Routen.
- **Dokumentation**: Erstellen Sie ein Diagramm, das die EVPN-Zone, VNets, BGP-Peers und propagierten Routen zeigt.

**Fragen zur Selbstreflexion**:
1. Warum ist BGP skalierbarer als statische Routen?
2. Wie können Sie mit `vtysh` überprüfen, ob eine Route erfolgreich propagiert wurde?
3. Welche Rolle spielt die Firewall bei der BGP-Integration?

Falls Sie eine Visualisierung (z. B. ein Diagramm der BGP-Routen mit ChartJS) oder weitere Details (z. B. zu EVPN-Konfiguration oder FRR-Debugging) wünschen, lassen Sie es mich wissen!

**[Modul 10: Load Balancing in SDN](Modul10_LoadBalancing.md)**   oder **[zurück zur Übersicht](00_Übersicht_SDN.md)**