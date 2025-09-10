## Modul 8: Integration mit externen Routern

**Lernziel**: Verbinden Sie virtuelle Netzwerke (VNets) in Proxmox VE mit externen Netzwerken, wie z. B. dem Internet, durch die Konfiguration statischer Routen. Nach diesem Modul können Sie sicherstellen, dass VMs in Ihren VNets Zugang zu externen Ressourcen haben und externe Geräte (falls gewünscht) auf VMs zugreifen können, während Sie die SDN-Funktionalität beibehalten.

**Hintergrund**:  
In den bisherigen Modulen haben Sie VNets (z. B. `vnet-web`, `vnet-db`) innerhalb einer Zone (`Zone-Web`) erstellt, die intern isoliert oder durch Inter-VNet-Routing (Modul 5) verbunden sind. Um jedoch Zugriff auf externe Netzwerke wie das Internet zu ermöglichen, müssen Sie den Datenverkehr von Ihren VNets an einen physischen Router weiterleiten. Statische Routen definieren diesen Weg, indem sie unbekannten Datenverkehr (z. B. Ziel-IPs außerhalb der VNets) an ein externes Gateway leiten. Dieses Modul zeigt, wie Sie statische Routen in Proxmox SDN konfigurieren und testen, um eine Verbindung zu externen Netzwerken herzustellen.

**Voraussetzungen**:
- Der `pve-sdn`-Dienst ist installiert und läuft (Modul 2).
- Eine VLAN-Zone (z. B. `Zone-Web`) mit VNets (`vnet-web`, VLAN 10, Subnetz `10.0.1.0/24`; `vnet-db`, VLAN 20, Subnetz `10.0.2.0/24`) ist konfiguriert (Modul 3).
- IP-Pools sind eingerichtet (Modul 4).
- Inter-VNet-Routing ist aktiviert (Modul 5).
- Firewall-Regeln erlauben gewünschten Verkehr, z. B. ICMP oder TCP Port 80 (Modul 6).
- Ein physischer Router mit einer bekannten IP-Adresse (z. B. `192.168.1.1`) ist im Netzwerk verfügbar und unterstützt die VLANs Ihrer VNets (z. B. VLAN 10, 20).
- Mindestens eine VM in `vnet-web` (z. B. IP `10.0.1.101`) ist konfiguriert, idealerweise mit DHCP (Modul 4).
- Zugriff auf die Proxmox-GUI (`https://<Proxmox-IP>:8006`) und die Shell.

### 8.1 Integration mit externen Netzwerken – Überblick
- **Was ist Integration mit externen Routern?**: Dies bezieht sich auf die Weiterleitung von Datenverkehr von VNets zu einem physischen Router, der externe Netzwerke (z. B. LAN, Internet) verbindet. Statische Routen in Proxmox SDN leiten Pakete mit unbekannten Ziel-IPs (außerhalb der VNet-Subnetze) an das externe Gateway weiter.
- **Warum ist das wichtig?**: Ohne externe Konnektivität sind VMs auf interne Kommunikation beschränkt. Für Anwendungen wie Webserver, die Internetzugriff benötigen (z. B. für Updates oder API-Aufrufe), ist eine Verbindung zum externen Netzwerk essenziell.
- **Wie funktioniert es?**:
  - Ein physischer Router (z. B. `192.168.1.1`) dient als Standard-Gateway für externe Netzwerke.
  - Eine statische Route in der SDN-Zone leitet „Default“-Verkehr (`0.0.0.0/0`) an diesen Router weiter.
  - Source NAT (SNAT) kann verwendet werden, um private IPs (z. B. `10.0.1.101`) in öffentliche IPs umzuwandeln, falls erforderlich.
- **Beispiel-Szenario**: Eine VM in `vnet-web` (`10.0.1.101`) soll auf das Internet zugreifen (z. B. `ping 8.8.8.8`). Eine statische Route leitet den Verkehr über den physischen Router (`192.168.1.1`), der mit der OVS-Bridge (`ovsbr0`) verbunden ist.

### 8.2 Detaillierte Konzepte
- **Statische Route**: Eine manuell definierte Regel, die angibt, wohin Pakete mit bestimmten Ziel-IPs geleitet werden. Für Internetzugriff wird oft die „Default Route“ (`0.0.0.0/0`) verwendet, die allen Verkehr abdeckt, der nicht mit lokalen Subnetzen übereinstimmt.
- **Gateway**: Der physische Router (z. B. `192.168.1.1`) muss im gleichen Netzwerk wie die OVS-Bridge-Schnittstelle erreichbar sein. Die OVS-Bridge (`ovsbr0`) hat typischerweise eine eigene IP (z. B. `192.168.1.10`), um mit dem Router zu kommunizieren.
- **SNAT (Source NAT)**: Wandelt private VNet-IPs (z. B. `10.0.1.101`) in die öffentliche IP des Proxmox-Hosts oder Routers um, um Internetzugriff zu ermöglichen.
- **Firewall-Kompatibilität**: Firewall-Regeln (Modul 6) müssen ausgehenden Verkehr (z. B. TCP Port 80 für HTTP, ICMP für `ping`) erlauben, sonst wird der externe Zugriff blockiert.
- **VLAN-Integration**: Der physische Router und Switch müssen die VLANs (z. B. 10, 20) unterstützen, die von den VNets verwendet werden, und als Trunk-Ports konfiguriert sein.

### Praktische Übungen

#### Übung 1: Statische Route konfigurieren
**Ziel**: Erstellen Sie eine statische Route in der SDN-Zone, um den Datenverkehr von `vnet-web` an einen physischen Router weiterzuleiten.

**Schritte**:
1. **Router- und Switch-Konfiguration prüfen**:
   - Stellen Sie sicher, dass Ihr physischer Router (z. B. `192.168.1.1`) erreichbar ist:
     ```bash
     ping 192.168.1.1
     ```
     - **Erfolg**: Antworten wie `64 bytes from 192.168.1.1: icmp_seq=1 ttl=64 time=0.5 ms`.
   - Prüfen Sie, ob der physische Switch VLANs 10 und 20 unterstützt (siehe Modul 2, Übung 3). Beispiel für einen Cisco-Switch:
     ```plaintext
     interface GigabitEthernet0/1
       switchport mode trunk
       switchport trunk allowed vlan 10,20
     ```
2. **Statische Route in der GUI erstellen**:
   - Öffnen Sie die Proxmox-GUI und gehen Sie zu *Datacenter > SDN > Zones > Zone-Web > Routes*.
   - Klicken Sie auf *Erstellen*.
   - **Einstellungen**:
     - **CIDR**: `0.0.0.0/0` (Default Route, umfasst alle Ziel-IPs außerhalb der VNets).
     - **Gateway**: `192.168.1.1` (IP Ihres physischen Routers).
     - **VNet**: Wählen Sie `vnet-web` (damit die Route nur für dieses VNet gilt).
     - **SNAT** (optional): Aktivieren Sie dies, wenn private IPs (z. B. `10.0.1.0/24`) in die IP des Proxmox-Hosts umgewandelt werden sollen.
   - Klicken Sie auf *Create*.
3. **Route überprüfen**:
   - In der Shell:
     ```bash
     cat /etc/pve/sdn/zones.cfg
     ```
     - **Erwartete Ausgabe** (ergänzt um die Route):
       ```plaintext
       vlan: Zone-Web
           bridge ovsbr0
           nodes pve-node1
           route 0.0.0.0/0 192.168.1.1 vnet-web
       ```
   - Prüfen Sie die Routing-Tabelle auf dem Proxmox-Host:
     ```bash
     ip route
     ```
     - **Erwartete Ausgabe**: Eine Route wie `0.0.0.0/0 via 192.168.1.1 dev ovsbr0`.
4. **Fehlerbehebung**:
   - **Route wird nicht erstellt**: Stellen Sie sicher, dass `pve-sdn` läuft (`sudo systemctl status pve-sdn`) und die Zone korrekt konfiguriert ist.
   - **Gateway nicht erreichbar**: Prüfen Sie, ob `ovsbr0` eine IP im gleichen Subnetz wie der Router hat (z. B. `192.168.1.10/24`):
     ```bash
     ip a show ovsbr0
     ```
     - Falls keine IP gesetzt ist, konfigurieren Sie sie in der GUI (*Node > Netzwerk > ovsbr0 > Bearbeiten*).

#### Übung 2: Internetzugriff testen
**Ziel**: Testen Sie, ob eine VM in `vnet-web` auf das Internet zugreifen kann, und stellen Sie sicher, dass die Firewall-Regeln dies erlauben.

**Schritte**:
1. **Firewall-Regeln anpassen**:
   - Gehen Sie zu *Datacenter > SDN > VNets > vnet-web > Firewall*.
   - Erstellen Sie eine Regel, um ausgehenden Internetverkehr zu erlauben:
     - **Aktion**: `Accept`.
     - **Protokoll**: `ICMP` (für `ping`) oder `TCP` (für HTTP, Port 80).
     - **Richtung**: `Out`.
     - **Quellnetzwerk**: `10.0.1.0/24` (Subnetz von `vnet-web`).
     - **Zielnetzwerk**: `0.0.0.0/0` (alle externen Netzwerke).
     - **Ziel-Port** (für TCP): `80` (oder leer für ICMP).
   - Wenden Sie die Änderungen an:
     ```bash
     pve-firewall compile
     ```
2. **Internetzugriff testen**:
   - In der VM in `vnet-web` (z. B. `10.0.1.101`):
     ```bash
     ping 8.8.8.8
     ```
     - **Erfolg**: Antworten wie `64 bytes from 8.8.8.8: icmp_seq=1 ttl=117 time=20 ms`.
   - Testen Sie HTTP-Zugriff:
     ```bash
     curl http://www.google.com
     ```
     - **Erfolg**: HTML-Antwort oder HTTP-Statuscode.
3. **DNS prüfen**:
   - Stellen Sie sicher, dass die VM DNS auflöst:
     ```bash
     nslookup google.com
     ```
     - **Erwartete Ausgabe**: IP-Adressen wie `172.217.18.78`.
     - **Fehlerbehebung**: Falls DNS fehlschlägt, überprüfen Sie die DNS-Server in der VM:
       ```bash
       cat /etc/resolv.conf
       ```
       - Setzen Sie DNS-Server manuell (z. B. `8.8.8.8`) in `/etc/netplan/01-netcfg.yaml`:
         ```yaml
         network:
           version: 2
           ethernets:
             eth0:
               dhcp4: yes
               nameservers:
                 addresses: [8.8.8.8, 8.8.4.4]
         ```
       - Anwenden:
         ```bash
         sudo netplan apply
         ```
4. **Fehlerbehebung**:
   - **Ping fehlschlägt**: Prüfen Sie die Firewall-Regeln (`cat /etc/pve/firewall/vnets/vnet-web.fw`) und die Routing-Tabelle (`ip route` in der VM).
   - **Kein Internetzugriff**: Überprüfen Sie, ob der physische Router (`192.168.1.1`) erreichbar ist und NAT aktiviert ist (falls SNAT nicht in Proxmox konfiguriert ist).
   - **OVS-Probleme**: Prüfen Sie die OVS-Bridge:
     ```bash
     ovs-vsctl show
     ```
     - Stellen Sie sicher, dass `vnet-web` (VLAN 10) korrekt verbunden ist.
   - **Logs prüfen**: Aktivieren Sie Logging in der Firewall-Regel und sehen Sie in:
     ```bash
     journalctl -u pve-firewall
     ```

**Erweiterung**: Konfigurieren Sie eine statische Route für `vnet-db` (`10.0.2.0/24`) und testen Sie den Internetzugriff von einer VM in `vnet-db`. Vergleichen Sie die Ergebnisse.

### 8.3 Häufige Probleme und Fehlerbehebung
- **Problem: Kein Internetzugriff**:
  - **Prüfen**: Firewall-Regeln (`cat /etc/pve/firewall/vnets/vnet-web.fw`), Routing (`ip route`), Gateway-Erreichbarkeit (`ping 192.168.1.1`).
  - **Lösung**: Firewall-Regel für ausgehenden Verkehr hinzufügen, Route korrigieren oder SNAT aktivieren.
- **Problem: Physischer Router nicht erreichbar**:
  - **Prüfen**: IP-Konfiguration von `ovsbr0` (`ip a show ovsbr0`), VLAN-Konfiguration auf dem Switch.
  - **Lösung**: IP für `ovsbr0` setzen, Switch-Trunk-Port für VLANs 10, 20 konfigurieren.
- **Problem: DNS-Auflösung fehlschlägt**:
  - **Prüfen**: `/etc/resolv.conf` in der VM, DNS-Einstellungen im IP-Pool (`cat /etc/pve/sdn/ippools.cfg`).
  - **Lösung**: DNS-Server manuell setzen (z. B. `8.8.8.8`).

### 8.4 Vorbereitung auf die nächsten Module
- **Was kommt als Nächstes?**: In Modul 9 richten Sie dynamisches Routing mit BGP ein, um komplexere Netzwerke zu verwalten. Dies baut auf statischen Routen auf und automatisiert die Weiterleitung.
- **Empfehlung**: Testen Sie den Zugriff auf weitere externe Dienste (z. B. HTTPS mit `curl https://www.google.com`) und experimentieren Sie mit SNAT, um das Verhalten zu verstehen. Dokumentieren Sie die statischen Routen und Firewall-Regeln.
- **Dokumentation**: Erstellen Sie ein Diagramm, das zeigt, wie `vnet-web` über den physischen Router (`192.168.1.1`) mit dem Internet verbunden ist.

**Fragen zur Selbstreflexion**:
1. Warum ist eine Default Route (`0.0.0.0/0`) notwendig für Internetzugriff?
2. Wie können Sie mit `tcpdump` überprüfen, ob Pakete den physischen Router erreichen?
3. Welche Rolle spielt SNAT in diesem Szenario?

Falls Sie eine Visualisierung (z. B. ein Netzwerkdiagramm mit ChartJS) oder weitere Details (z. B. zu NAT oder Switch-Konfiguration) wünschen, lassen Sie es mich wissen!

**[Modul 9: Dynamisches Routing mit BGP](Modul09_BGP.md)**   oder **[zurück zur Übersicht](00_Übersicht_SDN.md)**