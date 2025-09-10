## Modul 10: Load Balancing in SDN

**Lernziel**: Einrichten und Verwalten von Load Balancing in einer Proxmox VE SDN-Umgebung, um den Datenverkehr effizient auf mehrere virtuelle Maschinen (VMs) zu verteilen. Nach diesem Modul können Sie einen virtuellen Load Balancer konfigurieren, der den Datenverkehr (z. B. HTTP-Anfragen) an mehrere VMs in einem VNet weiterleitet, um die Verfügbarkeit und Skalierbarkeit von Diensten wie Webservern zu verbessern.

**Hintergrund**:  
In großen Netzwerken ist es oft notwendig, den Datenverkehr gleichmäßig auf mehrere Server zu verteilen, um Überlastungen zu vermeiden und die Ausfallsicherheit zu erhöhen. Ein Load Balancer agiert wie ein Verkehrsleiter, der eingehende Anfragen an mehrere Backend-VMs weiterleitet. In Proxmox VE SDN wird Load Balancing durch Integration mit Tools wie HAProxy oder durch SDN-spezifische Mechanismen realisiert. Dieses Modul zeigt, wie Sie einen Load Balancer einrichten, um HTTP-Verkehr an mehrere VMs in `vnet-web` zu verteilen, während Sie die in den vorherigen Modulen konfigurierte Infrastruktur (z. B. BGP-Routen, Firewall) nutzen.

**Voraussetzungen**:
- Der `pve-sdn`-Dienst ist installiert und läuft (Modul 2).
- Eine EVPN-Zone (z. B. `Zone-EVPN`) mit VNets (`vnet-web`, VLAN 10, Subnetz `10.0.1.0/24`; `vnet-db`, VLAN 20, Subnetz `10.0.2.0/24`) ist konfiguriert (Modul 9).
- IP-Pools sind eingerichtet (Modul 4).
- Inter-VNet-Routing (Modul 5) und BGP-Routen (Modul 9) sind aktiviert.
- Firewall-Regeln erlauben HTTP-Verkehr (TCP Port 80) (Modul 6).
- Mindestens zwei VMs in `vnet-web` (z. B. IP `10.0.1.101` und `10.0.1.102`) mit installiertem Webserver (z. B. Apache oder Nginx).
- Ein physischer Router (z. B. `192.168.1.1`) mit BGP-Peering ist erreichbar (Modul 9).
- Zugriff auf die Proxmox-GUI (`https://<Proxmox-IP>:8006`) und die Shell.
- Optional: HAProxy ist auf dem Proxmox-Host oder einer separaten VM installiert.

### 10.1 Load Balancing in Proxmox SDN – Überblick
- **Was ist Load Balancing?**: Ein Load Balancer verteilt eingehende Netzwerkanfragen (z. B. HTTP, TCP) an mehrere Backend-Server, um die Last zu verteilen und die Verfügbarkeit zu erhöhen. In Proxmox SDN kann dies durch externe Tools wie HAProxy oder durch zukünftige SDN-native Load-Balancing-Funktionen (je nach Proxmox-Version) realisiert werden.
- **Warum Load Balancing?**:
  - **Skalierbarkeit**: Mehrere VMs können denselben Dienst (z. B. Webserver) bereitstellen, um mehr Anfragen zu bewältigen.
  - **Ausfallsicherheit**: Wenn eine VM ausfällt, leitet der Load Balancer den Verkehr an andere VMs weiter.
  - **Effizienz**: Optimale Nutzung der Ressourcen durch gleichmäßige Verteilung.
- **Wie funktioniert es?**:
  - Ein Load Balancer erhält Anfragen über eine virtuelle IP (VIP), z. B. `10.0.1.200`.
  - Er verteilt diese Anfragen an Backend-VMs (z. B. `10.0.1.101`, `10.0.1.102`) basierend auf einem Algorithmus (z. B. Round-Robin).
  - BGP (Modul 9) kann die VIP nach außen propagieren, sodass externe Netzwerke sie erreichen.
- **Beispiel-Szenario**: Zwei Webserver-VMs in `vnet-web` (`10.0.1.101`, `10.0.1.102`) hosten eine Website. Ein Load Balancer verteilt HTTP-Anfragen (Port 80) von externen Clients oder anderen VNets an diese VMs.

### 10.2 Detaillierte Konzepte
- **HAProxy**: Ein weit verbreitetes Open-Source-Tool für Load Balancing, das in Proxmox-Umgebungen verwendet wird. Es unterstützt TCP- und HTTP-basiertes Balancing und kann auf dem Proxmox-Host oder einer separaten VM installiert werden.
- **Virtuelle IP (VIP)**: Eine IP-Adresse, die Clients verwenden, um auf den Load Balancer zuzugreifen. Sie ist nicht an eine spezifische VM gebunden, sondern wird vom Load Balancer verwaltet.
- **Backend-Server**: Die VMs, die den eigentlichen Dienst (z. B. Webserver) bereitstellen. Der Load Balancer verteilt Anfragen an diese Server.
- **Balancing-Algorithmen**:
  - **Round-Robin**: Anfragen werden gleichmäßig an alle Backend-Server verteilt.
  - **Least Connections**: Anfragen gehen an den Server mit den wenigsten aktiven Verbindungen.
  - **Source**: Anfragen von derselben Client-IP gehen an denselben Server (für Sitzungspersistenz).
- **Firewall-Integration**: Firewall-Regeln (Modul 6) müssen den Verkehr zur VIP (z. B. TCP Port 80) erlauben.
- **BGP-Integration**: BGP (Modul 9) kann die VIP an externe Netzwerke propagieren, um den Load Balancer von außerhalb erreichbar zu machen.

### Praktische Übungen

#### Übung 1: Webserver-VMs vorbereiten
**Ziel**: Bereiten Sie zwei VMs in `vnet-web` mit Webservern vor, die als Backend für den Load Balancer dienen.

**Schritte**:
1. **VMs prüfen**:
   - Stellen Sie sicher, dass zwei VMs in `vnet-web` existieren (z. B. `10.0.1.101`, `10.0.1.102`), wie in Modul 4 konfiguriert (DHCP oder statische IPs).
   - Verbinden Sie beide mit `vnet-web` (VLAN 10, OVS-Bridge `ovsbr0`).
2. **Webserver installieren**:
   - In jeder VM (z. B. Ubuntu):
     ```bash
     sudo apt update && sudo apt install nginx
     ```
   - Erstellen Sie eine einfache Testseite, um die VMs zu unterscheiden:
     - Auf VM1 (`10.0.1.101`):
       ```bash
       echo "Webserver 1" | sudo tee /var/www/html/index.html
       ```
     - Auf VM2 (`10.0.1.102`):
       ```bash
       echo "Webserver 2" | sudo tee /var/www/html/index.html
       ```
   - Starten Sie Nginx:
     ```bash
     sudo systemctl restart nginx
     ```
3. **Webserver testen**:
   - Von einer anderen VM (z. B. in `vnet-db`, `10.0.2.101`):
     ```bash
     curl http://10.0.1.101
     ```
     - **Erwartete Ausgabe**: `Webserver 1`.
     ```bash
     curl http://10.0.1.102
     ```
     - **Erwartete Ausgabe**: `Webserver 2`.
4. **Fehlerbehebung**:
   - **Nginx nicht erreichbar**: Prüfen Sie, ob der Dienst läuft (`sudo systemctl status nginx`) und ob die Firewall HTTP erlaubt:
     ```bash
     sudo ufw allow 80
     ```
   - **Netzwerkprobleme**: Überprüfen Sie die VNet-Zuweisung (`ip a` in der VM) und Firewall-Regeln in Proxmox (*Datacenter > SDN > VNets > vnet-web > Firewall*).

#### Übung 2: HAProxy als Load Balancer einrichten
**Ziel**: Installieren und konfigurieren Sie HAProxy auf dem Proxmox-Host oder einer separaten VM, um HTTP-Verkehr an die beiden Webserver-VMs zu verteilen.

**Schritte**:
1. **HAProxy installieren**:
   - Auf dem Proxmox-Host (oder einer separaten VM in `vnet-web` mit IP z. B. `10.0.1.200`):
     ```bash
     sudo apt update && sudo apt install haproxy
     ```
2. **HAProxy konfigurieren**:
   - Bearbeiten Sie die HAProxy-Konfigurationsdatei:
     ```bash
     sudo nano /etc/haproxy/haproxy.cfg
     ```
   - Fügen Sie am Ende Folgendes hinzu:
     ```plaintext
     frontend http-in
         bind 10.0.1.200:80
         mode http
         default_backend webservers

     backend webservers
         mode http
         balance roundrobin
         server web1 10.0.1.101:80 check
         server web2 10.0.1.102:80 check
     ```
     - **Erklärung**:
       - `bind 10.0.1.200:80`: Die VIP, an die Clients Anfragen senden.
       - `balance roundrobin`: Verteilt Anfragen abwechselnd an die Backend-Server.
       - `server web1/web2`: Die IPs der Webserver-VMs mit Gesundheitsprüfung (`check`).
3. **VIP konfigurieren**:
   - Fügen Sie die VIP (`10.0.1.200`) zur OVS-Bridge oder einer VM-Schnittstelle hinzu:
     - Auf dem Proxmox-Host:
       ```bash
       sudo ip addr add 10.0.1.200/24 dev ovsbr0
       ```
     - Falls HAProxy auf einer VM läuft, setzen Sie die IP in der VM (`/etc/netplan/01-netcfg.yaml`).
4. **HAProxy starten**:
   - ```bash
     sudo systemctl restart haproxy
     ```
   - Prüfen Sie den Status:
     ```bash
     sudo systemctl status haproxy
     ```
     - **Erwartete Ausgabe**: `active (running)`.
5. **Fehlerbehebung**:
   - **HAProxy startet nicht**: Prüfen Sie die Konfiguration:
     ```bash
     haproxy -c -f /etc/haproxy/haproxy.cfg
     ```
   - **VIP nicht erreichbar**: Überprüfen Sie die IP-Zuweisung (`ip a show ovsbr0`) und Firewall-Regeln.

#### Übung 3: Load Balancer testen
**Ziel**: Testen Sie den Load Balancer, indem Sie HTTP-Anfragen an die VIP senden, und überprüfen Sie die BGP-Integration für externe Erreichbarkeit.

**Schritte**:
1. **Firewall-Regeln anpassen**:
   - In *Datacenter > SDN > VNets > vnet-web > Firewall*:
     - Erstellen Sie eine Regel, um HTTP-Verkehr zur VIP zu erlauben:
       - **Aktion**: `Accept`.
       - **Protokoll**: `TCP`.
       - **Ziel-Port**: `80`.
       - **Quellnetzwerk**: `0.0.0.0/0` (oder `10.0.2.0/24` für Tests von `vnet-db`).
       - **Zielnetzwerk**: `10.0.1.200/32` (VIP).
       - **Richtung**: `In`.
     - Wenden Sie die Änderungen an:
       ```bash
       pve-firewall compile
       ```
2. **Load Balancer testen**:
   - Von einer VM in `vnet-db` (`10.0.2.101`):
     ```bash
     curl http://10.0.1.200
     ```
     - **Erwartete Ausgabe**: Abwechselnd `Webserver 1` oder `Webserver 2` (wegen Round-Robin).
   - Wiederholen Sie den Befehl mehrfach, um die Verteilung zu sehen.
3. **Externe Erreichbarkeit testen**:
   - Stellen Sie sicher, dass BGP die VIP propagiert (Modul 9):
     ```bash
     vtysh -c "show ip bgp"
     ```
     - **Erwartete Ausgabe**: Enthält `10.0.1.200/32`.
   - Vom externen Netzwerk (z. B. `192.168.1.100`):
     ```bash
     curl http://10.0.1.200
     ```
     - **Erfolg**: Antwort von einem der Webserver.
4. **Fehlerbehebung**:
   - **VIP nicht erreichbar**: Prüfen Sie die HAProxy-Konfiguration, die VIP-Zuweisung (`ip a`) und Firewall-Regeln.
   - **Verkehr wird nicht verteilt**: Überprüfen Sie den HAProxy-Status (`sudo systemctl status haproxy`) und die Gesundheitsprüfung (`check` in `haproxy.cfg`).
   - **Externe Netzwerke erreichen VIP nicht**: Prüfen Sie BGP-Routen (`vtysh -c "show ip bgp"`) und die externe Router-Konfiguration.

### 10.3 Häufige Probleme und Fehlerbehebung
- **Problem: Load Balancer antwortet nicht**:
  - **Prüfen**: HAProxy-Status (`sudo systemctl status haproxy`), VIP (`ip a`), Firewall-Regeln (`cat /etc/pve/firewall/vnets/vnet-web.fw`).
  - **Lösung**: HAProxy-Konfiguration korrigieren, VIP neu zuweisen, Firewall-Regeln anpassen.
- **Problem: Verkehr wird nur an eine VM geleitet**:
  - **Prüfen**: HAProxy-Backend-Status (`haproxy -c -f /etc/haproxy/haproxy.cfg`), Webserver-Status (`sudo systemctl status nginx`).
  - **Lösung**: Stellen Sie sicher, dass beide VMs erreichbar sind und die Gesundheitsprüfung besteht.
- **Problem: Externe Zugriffe fehlschlagen**:
  - **Prüfen**: BGP-Routen (`vtysh -c "show ip bgp"`), externe Firewall-Regeln.
  - **Lösung**: VIP-Route in BGP propagieren, externe Firewall anpassen.

### 10.4 Abschluss und Ausblick
- **Zusammenfassung**: Sie haben gelernt, einen Load Balancer mit HAProxy einzurichten, um HTTP-Verkehr an mehrere VMs in `vnet-web` zu verteilen, und die Integration mit BGP für externe Erreichbarkeit getestet.
- **Empfehlung**: Experimentieren Sie mit anderen Algorithmen (z. B. `leastconn` in HAProxy) oder fügen Sie weitere VMs hinzu. Testen Sie die Ausfallsicherheit, indem Sie einen Webserver abschalten (`sudo systemctl stop nginx`).
- **Dokumentation**: Erstellen Sie ein Diagramm, das den Load Balancer, die VIP, Backend-VMs und BGP-Routen zeigt.

**Fragen zur Selbstreflexion**:
1. Warum ist ein Load Balancer für skalierbare Dienste notwendig?
2. Wie können Sie mit `tcpdump` überprüfen, ob der Load Balancer Anfragen korrekt verteilt?
3. Welche Vorteile bietet die Integration von BGP mit Load Balancing?

Falls Sie eine Visualisierung (z. B. ein Diagramm des Load-Balancing-Flusses mit ChartJS) oder weitere Details (z. B. zu HAProxy-Statistiken oder fortgeschrittenen Algorithmen) wünschen, lassen Sie es mich wissen!

**[Modul 11: Monitoring und Optimierung der SDN-Umgebung mit Checkmk Raw Edition](Modul11_Monitoring.md)**   oder **[zurück zur Übersicht](00_Übersicht_SDN.md)**