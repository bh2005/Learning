## Modul 11: Monitoring und Optimierung der SDN-Umgebung mit Checkmk Raw Edition

**Lernziel**: Implementieren der Checkmk Raw Edition (kostenlos und Open Source) zur Überwachung der Leistung, Sicherheit und Stabilität Ihrer Proxmox VE SDN-Umgebung. Nach diesem Modul können Sie Netzwerkverkehr, Dienste und Ressourcen mit Checkmk überwachen, Engpässe identifizieren und die Konfiguration optimieren, um eine robuste und effiziente SDN-Infrastruktur zu gewährleisten.

**Hintergrund**:  
Eine SDN-Umgebung in Proxmox VE, die Zonen, VNets, Routing, Firewall und Load Balancing umfasst, erfordert kontinuierliche Überwachung, um Probleme wie Überlastungen, Ausfälle oder Sicherheitsverletzungen frühzeitig zu erkennen. Die Checkmk Raw Edition ist eine kostenlose, Open-Source-Lösung, die eine leistungsstarke Überwachung für Netzwerke, Server und Anwendungen bietet. Dieses Modul zeigt, wie Sie Checkmk Raw installieren, konfigurieren und nutzen, um Ihre SDN-Umgebung zu überwachen, und wie Sie basierend auf den gesammelten Daten Optimierungen vornehmen.

**Voraussetzungen**:
- Der `pve-sdn`-Dienst ist installiert und läuft (Modul 2).
- Eine EVPN-Zone (z. B. `Zone-EVPN`) mit VNets (`vnet-web`, VLAN 10, Subnetz `10.0.1.0/24`; `vnet-db`, VLAN 20, Subnetz `10.0.2.0/24`) ist konfiguriert (Modul 9).
- IP-Pools (Modul 4), Inter-VNet-Routing (Modul 5), BGP-Routen (Modul 9) und Load Balancing (Modul 10) sind eingerichtet.
- Firewall-Regeln erlauben notwendigen Verkehr (Modul 6).
- Mindestens zwei VMs in `vnet-web` (z. B. `10.0.1.101`, `10.0.1.102`) mit Webservern (z. B. Nginx) und ein Load Balancer (z. B. HAProxy mit VIP `10.0.1.200`) sind aktiv (Modul 10).
- Zugriff auf die Proxmox-GUI (`https://<Proxmox-IP>:8006`) und die Shell.
- Ein Linux-System (z. B. Ubuntu 22.04 oder 24.04) für die Checkmk-Installation, idealerweise auf einer separaten VM (z. B. `10.0.1.103` in `vnet-web`).
- Internetzugriff für den Download der Checkmk Raw Edition von `https://checkmk.com/download`.

### 11.1 Monitoring mit Checkmk Raw – Überblick
- **Was ist Checkmk Raw?**: Eine kostenlose, Open-Source-Monitoring-Lösung (GNU GPL v2), die Netzwerke, Server, Anwendungen und mehr überwacht. Sie bietet eine Weboberfläche, Agenten-basierte und agentenlose Überwachung sowie über 2.000 Plugins für umfassende Überwachung kleiner bis mittelgroßer Umgebungen.[](https://github.com/Checkmk/checkmk)[](https://checkmk.com/product/checkmk-raw)
- **Warum Checkmk Raw?**:
  - **Kostenlos**: Ideal für kleine Umgebungen oder Testsysteme.
  - **Einfache Einrichtung**: Schnelle Installation und automatische Erkennung von Hosts/Diensten.
  - **Flexibilität**: Unterstützt Proxmox, VMs, Netzwerke und Dienste wie HAProxy oder Nginx.
- **Monitoring-Komponenten**:
  - **Checkmk-Server**: Verarbeitet Metriken und stellt die Weboberfläche bereit.
  - **Checkmk-Agent**: Installiert auf überwachten VMs, um CPU, Speicher, Netzwerk usw. zu überwachen.
  - **Plugins**: Überwachen spezifische Dienste (z. B. HTTP, BGP, OVS).
  - **Proxmox-Integration**: Überwacht Proxmox-Knoten und VMs direkt.
- **Beispiel-Szenario**: Sie überwachen den HTTP-Verkehr zum Load Balancer (`10.0.1.200`), die BGP-Peering-Stabilität und die Ressourcennutzung der Webserver-VMs (`10.0.1.101`, `10.0.1.102`), um die Verfügbarkeit der Website sicherzustellen und Engpässe zu vermeiden.

### 11.2 Detaillierte Konzepte
- **Monitoring-Bereiche**:
  - **Netzwerkverkehr**: Bandbreite, Latenz, Paketverluste zwischen VNets und externen Netzwerken.
  - **Dienststatus**: Verfügbarkeit von `pve-sdn`, `frr`, `haproxy`, Webservern.
  - **Ressourcen**: CPU-, Speicher- und Speicherauslastung der VMs und des Proxmox-Hosts.
  - **Sicherheit**: Firewall-Logs für blockierte Pakete, ungewöhnlicher Verkehr.
- **Checkmk Raw Funktionen**:
  - **Automatische Erkennung**: Erkennt Hosts und Dienste (z. B. Nginx, HAProxy) automatisch.
  - **Weboberfläche**: Bietet Dashboards und Berichte für Echtzeit-Überwachung.
  - **Benachrichtigungen**: E-Mail- oder Slack-Benachrichtigungen bei Problemen.
- **Optimierung**:
  - **Load Balancer**: Anpassen des Balancing-Algorithmus basierend auf Verkehrsmetriken.
  - **Firewall**: Entfernen redundanter Regeln zur Leistungssteigerung.
  - **Ressourcen**: Skalieren von VMs oder Hinzufügen weiterer Backend-Server.

<xaiArtifact artifact_id="91f04e72-aa71-47c8-8bd2-3d338e314c55" artifact_version_id="adb1f522-4e35-436b-822a-0815ca092419" title="InstallCheckmkRaw.sh" contentType="text/x-shellscript">
#!/bin/bash
# Script to install Checkmk Raw Edition on Ubuntu 22.04/24.04

# Update system and install dependencies
sudo apt update
sudo apt install -y wget

# Download Checkmk Raw Edition (example for Ubuntu 22.04, adjust for your version)
# Replace version with the latest from https://checkmk.com/download
CHECKMK_VERSION="2.3.0p10"
wget "https://download.checkmk.com/checkmk/${CHECKMK_VERSION}/check-mk-raw-${CHECKMK_VERSION}_0.focal_amd64.deb"

# Install Checkmk
sudo dpkg -i "check-mk-raw-${CHECKMK_VERSION}_0.focal_amd64.deb"
sudo apt install -f

# Create a monitoring site (e.g., named 'mysite')
sudo omd create mysite
sudo omd start mysite

# Output access details
echo "Checkmk Web UI: http://$(hostname -I | awk '{print $1}'):mysite"
echo "Default user: cmkadmin"
echo "Password: Run 'omd config mysite' to set a new password"
</xaiArtifact>

### Praktische Übungen

#### Übung 1: Checkmk Raw installieren und konfigurieren
**Ziel**: Installieren Sie die Checkmk Raw Edition auf einer VM in `vnet-web` und richten Sie eine Monitoring-Site ein.

**Schritte**:
1. **VM für Checkmk vorbereiten**:
   - Erstellen Sie eine neue VM in `vnet-web` (z. B. `10.0.1.103`) mit Ubuntu 22.04 oder 24.04.
   - Stellen Sie sicher, dass die VM Internetzugriff hat (siehe Modul 8):
     ```bash
     ping 8.8.8.8
     ```
2. **Checkmk Raw herunterladen und installieren**:
   - Führen Sie das bereitgestellte Skript aus oder folgen Sie den Schritten manuell:
     - Download der Checkmk Raw Edition von `https://checkmk.com/download`:
       ```bash
       wget https://download.checkmk.com/checkmk/2.3.0p10/check-mk-raw-2.3.0p10_0.focal_amd64.deb
       ```
     - Installieren:
       ```bash
       sudo dpkg -i check-mk-raw-2.3.0p10_0.focal_amd64.deb
       sudo apt install -f
       ```
     - Erstellen Sie eine Monitoring-Site:
       ```bash
       sudo omd create mysite
       sudo omd start mysite
       ```
   - Greifen Sie auf die Weboberfläche zu:
     - URL: `http://10.0.1.103/mysite`
     - Benutzer: `cmkadmin`
     - Passwort: Wird bei der Erstellung angezeigt (ändern Sie es mit `omd config mysite`).
3. **Firewall-Regeln anpassen**:
   - Erlauben Sie HTTP-Zugriff (Port 80) zur Checkmk-VM:
     - In Proxmox (*Datacenter > SDN > VNets > vnet-web > Firewall*):
       - **Aktion**: `Accept`.
       - **Protokoll**: `TCP`.
       - **Ziel-Port**: `80`.
       - **Quellnetzwerk**: `0.0.0.0/0` (oder `10.0.1.0/24` für internen Zugriff).
       - **Zielnetzwerk**: `10.0.1.103/32`.
       - **Richtung**: `In`.
     - Wenden Sie die Änderungen an:
       ```bash
       pve-firewall compile
       ```
4. **Fehlerbehebung**:
   - **Download fehlschlägt**: Prüfen Sie die Internetverbindung (`ping 8.8.8.8`) und die URL (`https://checkmk.com/download`).
   - **Weboberfläche nicht erreichbar**: Überprüfen Sie den Dienststatus (`sudo omd status mysite`) und Firewall-Regeln.
   - **Abhängigkeiten fehlen**: Installieren Sie fehlende Pakete mit `sudo apt install -f`.

#### Übung 2: Hosts und Dienste in Checkmk überwachen
**Ziel**: Fügen Sie die Webserver-VMs, den Load Balancer und den Proxmox-Host zu Checkmk hinzu, um Ressourcen und Dienste zu überwachen.

**Schritte**:
1. **Checkmk-Agent auf VMs installieren**:
   - Auf jeder Webserver-VM (`10.0.1.101`, `10.0.1.102`) und der Load-Balancer-VM (falls separat):
     ```bash
     sudo apt update
     sudo apt install check-mk-agent
     ```
   - Konfigurieren Sie den Agent:
     ```bash
     sudo nano /etc/checkmk-agent/check_mk_agent
     ```
     - Setzen Sie die Checkmk-Server-IP:
       ```plaintext
       server 10.0.1.103
       ```
     - Starten Sie den Agent:
       ```bash
       sudo systemctl restart check-mk-agent
       ```
2. **Hosts in Checkmk hinzufügen**:
   - Öffnen Sie die Checkmk-Weboberfläche (`http://10.0.1.103/mysite`).
   - Gehen Sie zu *Setup > Hosts > Add host*:
     - **Hostname**: `webserver1`, **IP**: `10.0.1.101`.
     - **Hostname**: `webserver2`, **IP**: `10.0.1.102`.
     - **Hostname**: `loadbalancer`, **IP**: `10.0.1.200`.
     - **Hostname**: `pve-node1`, **IP**: IP des Proxmox-Hosts (z. B. `192.168.1.10`).
   - Aktivieren Sie die automatische Erkennung (*Service discovery*).
3. **Dienste überwachen**:
   - In *Monitoring > All hosts*:
     - Überprüfen Sie CPU-, Speicher- und Netzwerkauslastung der VMs.
     - Überwachen Sie HTTP-Dienste auf `10.0.1.200` (Load Balancer) und Nginx auf den Webservern.
   - Erstellen Sie ein Dashboard (*Views > Dashboards > Add dashboard*) für:
     - Netzwerkverkehr auf `ovsbr0`.
     - HTTP-Statuscodes des Load Balancers.
     - CPU/Speicher der VMs.
4. **Fehlerbehebung**:
   - **Agent nicht verbunden**: Prüfen Sie den Agent-Status (`sudo systemctl status check-mk-agent`) und Firewall-Regeln für TCP Port 6556.
   - **Keine Daten**: Stellen Sie sicher, dass die automatische Erkennung aktiviert ist (*Setup > Services > Discover services*).

#### Übung 3: Optimierung der SDN-Umgebung basierend auf Checkmk-Daten
**Ziel**: Analysieren Sie Monitoring-Daten und optimieren Sie die SDN-Konfiguration, um die Leistung zu verbessern.

**Schritte**:
1. **Engpässe identifizieren**:
   - In Checkmk (*Monitoring > All hosts*):
     - Suchen Sie nach VMs mit hoher CPU- oder Netzwerkauslastung (z. B. `10.0.1.101`).
     - Beispiel: Wenn `webserver1` überlastet ist, fügen Sie eine dritte VM (`10.0.1.104`) zum Load Balancer hinzu:
       ```bash
       sudo nano /etc/haproxy/haproxy.cfg
       ```
       - Fügen Sie hinzu:
         ```plaintext
         server web3 10.0.1.104:80 check
         ```
       - Starten Sie HAProxy neu:
         ```bash
         sudo systemctl restart haproxy
         ```
2. **Firewall-Regeln optimieren**:
   - Überprüfen Sie Firewall-Logs in Checkmk (*Monitoring > Event Console*) oder:
     ```bash
     journalctl -u pve-firewall
     ```
   - Entfernen Sie redundante Regeln in *Datacenter > SDN > VNets > vnet-web > Firewall*, um die Verarbeitung zu beschleunigen.
3. **Load-Balancing-Algorithmus anpassen**:
   - Basierend auf Checkmk-Metriken (z. B. ungleiche Verteilung des HTTP-Verkehrs), ändern Sie den Algorithmus in `haproxy.cfg` zu `leastconn`:
     ```plaintext
     backend webservers
         mode http
         balance leastconn
         server web1 10.0.1.101:80 check
         server web2 10.0.1.102:80 check
         server web3 10.0.1.104:80 check
     ```
   - Testen Sie die Verteilung:
     ```bash
     curl http://10.0.1.200
     ```
4. **Fehlerbehebung**:
   - **Hohe Latenz**: Prüfen Sie Netzwerkmetriken in Checkmk und skalieren Sie VM-Ressourcen (*VM > Hardware > Edit*).
   - **Firewall blockiert Verkehr**: Überprüfen Sie Logs in Checkmk oder `journalctl -u pve-firewall`.
   - **Load Balancer ineffizient**: Vergleichen Sie Metriken vor und nach der Algorithmusänderung in Checkmk.

### 11.3 Häufige Probleme und Fehlerbehebung
- **Problem: Hohe Netzwerkauslastung**:
  - **Prüfen**: Checkmk-Metriken für Netzwerkverkehr (`ovsbr0`), `iftop -i ovsbr0`.
  - **Lösung**: Skalieren Sie Backend-VMs oder optimieren Sie den Load-Balancing-Algorithmus.
- **Problem: Monitoring-Daten fehlen**:
  - **Prüfen**: Checkmk-Agent-Status (`sudo systemctl status check-mk-agent`), Firewall-Regeln für Port 6556.
  - **Lösung**: Agent neu starten, Firewall-Regeln anpassen.
- **Problem: Dienstausfälle**:
  - **Prüfen**: Checkmk-Benachrichtigungen, Dienststatus (`sudo systemctl status pve-sdn frr haproxy`), Logs (`journalctl -u <dienst>`).
  - **Lösung**: Dienste neu starten, Konfiguration prüfen.

### 11.4 Abschluss und Ausblick
- **Zusammenfassung**: Sie haben die Checkmk Raw Edition installiert, konfiguriert und genutzt, um Ihre SDN-Umgebung zu überwachen, und Optimierungen wie Load-Balancer-Anpassungen und Firewall-Bereinigung vorgenommen.
- **Empfehlung**: Experimentieren Sie mit Checkmk-Plugins (z. B. für OVS oder BGP-Monitoring) oder richten Sie Benachrichtigungen ein (*Setup > Notifications*). Testen Sie die Skalierung, indem Sie weitere VMs hinzufügen.
- **Dokumentation**: Erstellen Sie ein Monitoring-Diagramm, das die überwachten Komponenten (VMs, Load Balancer, BGP, Netzwerkverkehr) zeigt.

**Fragen zur Selbstreflexion**:
1. Welche Metriken sind für die Überwachung eines Load Balancers in Checkmk am wichtigsten?
2. Wie können Sie mit Checkmk Engpässe in Ihrer SDN-Umgebung erkennen?
3. Warum ist die Optimierung der Firewall-Regeln wichtig für die Leistung?

Falls Sie eine Visualisierung (z. B. ein Monitoring-Dashboard mit ChartJS) oder weitere Details (z. B. zu Checkmk-Plugins oder Benachrichtigungen) wünschen, lassen Sie es mich wissen!

**[Modul 12: Automatisierung mit APIs](Modul12_API.md)**   oder **[zurück zur Übersicht](00_Übersicht_SDN.md)**