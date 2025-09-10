## Modul 4: Automatisches IP-Management (IPAM)

**Lernziel**: Automatisieren der IP-Adressvergabe für virtuelle Maschinen (VMs) und Container in Proxmox VE mithilfe des integrierten IP Address Management (IPAM)-Systems. Nach diesem Modul können Sie IP-Pools erstellen, DHCP aktivieren und die automatische Zuweisung von IP-Adressen an VMs testen, um die Verwaltung von Netzwerken zu vereinfachen und Fehler bei der manuellen Konfiguration zu vermeiden.

**Hintergrund**:  
IPAM (IP Address Management) ist ein zentraler Bestandteil von SDN, da es die manuelle Zuweisung von IP-Adressen ersetzt und Konflikte (z. B. doppelte IPs) verhindert. In Proxmox VE integriert das IPAM-System die automatische Verwaltung von IP-Adressen innerhalb von VNets, indem es DHCP (Dynamic Host Configuration Protocol) oder feste Zuweisungen nutzt. IPAM ist wie ein Postmeister, der sicherstellt, dass jede VM eine eindeutige Adresse erhält, ohne dass Sie diese manuell einstellen müssen. Dies ist besonders nützlich in großen Umgebungen mit vielen VMs oder dynamischen Deployments.

**Voraussetzungen**:
- Der `pve-sdn`-Dienst ist installiert und läuft (Modul 2).
- Eine VLAN-Zone (z. B. `Zone-Web`) und ein VNet (z. B. `vnet-web`, VLAN 10, Subnetz `10.0.1.0/24`) sind erstellt (Modul 3).
- Eine OVS-Bridge (z. B. `ovsbr0`) mit *VLAN aware* ist konfiguriert (Modul 1).
- Eine Test-VM ist verfügbar und mit `vnet-web` verbunden (Modul 3).
- Zugriff auf die Proxmox-GUI und die Shell.

### 4.1 IPAM in Proxmox VE – Überblick
- **Was ist IPAM?**: IPAM verwaltet IP-Adressen innerhalb eines Subnetzes und weist sie VMs oder Containern zu, entweder statisch (feste Zuweisung) oder dynamisch (via DHCP). In Proxmox ist IPAM in den `pve-sdn`-Dienst integriert und nutzt die internen Datenbanken, um Adressen zu verfolgen.
- **Vorteile**:
  - **Automatisierung**: Keine manuelle Konfiguration von IPs in jeder VM.
  - **Konfliktvermeidung**: Verhindert doppelte IP-Adressen.
  - **Skalierbarkeit**: Vereinfacht die Verwaltung in großen Netzwerken.
- **Komponenten**:
  - **IP-Pool**: Ein Bereich von IP-Adressen innerhalb eines Subnetzes, der VMs zugewiesen werden kann.
  - **DHCP**: Automatische Zuweisung von IPs aus dem Pool an VMs, die auf DHCP konfiguriert sind.
  - **Gateway**: Der Router (z. B. `10.0.1.1`) für den Datenverkehr außerhalb des VNet.
- **In Proxmox**: IPAM wird über die GUI unter *Datacenter > SDN > IP-Pools* verwaltet. Es ist mit VNets und Zonen verknüpft und verwendet OVS, um den Datenverkehr korrekt zu handhaben.

### 4.2 Detaillierte Konzepte
- **IP-Pool**: Ein definierter Adressbereich (z. B. `10.0.1.100` bis `10.0.1.150`) innerhalb eines Subnetzes (z. B. `10.0.1.0/24`). Sie können mehrere Pools pro VNet erstellen, z. B. für unterschiedliche VM-Gruppen (Webserver, Datenbanken).
- **DHCP in SDN**: Proxmox IPAM kann als DHCP-Server agieren, der VMs automatisch IPs, Subnetzmasken, Gateways und DNS-Server zuweist. Dies erfordert, dass die VM auf DHCP eingestellt ist (z. B. `dhcp4: yes` in Netplan).
- **Statische Zuweisung**: Alternativ können Sie IPs manuell aus dem Pool zuweisen, was nützlich ist, wenn VMs feste Adressen benötigen (z. B. für Server mit öffentlichen Diensten).
- **Beispiel-Szenario**: In `vnet-web` (Subnetz `10.0.1.0/24`) erstellen Sie einen IP-Pool von `10.0.1.100/26` (64 Adressen). VMs, die diesem VNet zugewiesen sind, erhalten automatisch eine IP aus diesem Bereich, z. B. `10.0.1.101`.

### Praktische Übungen

#### Übung 1: IP-Pool erstellen
**Ziel**: Erstellen Sie einen IP-Pool für `vnet-web`, aktivieren Sie DHCP und konfigurieren Sie das Gateway.

**Schritte**:
1. **Zur Proxmox-GUI navigieren**: Öffnen Sie die Weboberfläche (`https://<Proxmox-IP>:8006`) und gehen Sie zu *Datacenter > SDN > IP-Pools*.
2. **IP-Pool erstellen**:
   - Klicken Sie auf *Erstellen*.
   - **Name**: Geben Sie `web-pool` ein (beliebig, aber beschreibend).
   - **VNet**: Wählen Sie `vnet-web` (aus Modul 3).
   - **Subnet**: Geben Sie `10.0.1.100/26` ein.
     - **Erklärung**: `/26` entspricht 64 Adressen (`10.0.1.100` bis `10.0.1.163`). Dies ist ein Teilbereich des VNet-Subnetzes `10.0.1.0/24`.
   - **Gateway**: Geben Sie `10.0.1.1` ein (muss mit dem VNet-Gateway übereinstimmen, falls definiert).
   - **DHCP**: Aktivieren Sie die Checkbox *DHCP* (ermöglicht automatische IP-Zuweisung).
   - **Optionale Einstellungen**:
     - **DNS-Server**: Geben Sie z. B. `8.8.8.8` ein (Google DNS), falls Sie keine internen DNS-Server haben.
     - **Range**: Lassen Sie leer, um den gesamten `/26`-Bereich zu nutzen, oder schränken Sie ihn ein (z. B. `10.0.1.100-10.0.1.120`).
   - Klicken Sie auf *Create*.
3. **Überprüfen**:
   - In der GUI sollte `web-pool` unter *IP-Pools* erscheinen.
   - In der Shell:
     ```bash
     cat /etc/pve/sdn/ippools.cfg
     ```
     - **Erwartete Ausgabe**:
       ```plaintext
       ippool: web-pool
           subnet 10.0.1.100/26
           gateway 10.0.1.1
           dhcp 1
           vnet vnet-web
       ```
   - Prüfen Sie, ob IPAM korrekt geladen ist:
     ```bash
     sudo systemctl status pve-sdn
     ```
     - Stellen Sie sicher, dass der Dienst `active (running)` ist.
4. **Fehlerbehebung**:
   - **Pool wird nicht erstellt**: Überprüfen Sie, ob `vnet-web` existiert (`cat /etc/pve/sdn/vnets.cfg`) und ob das Subnetz korrekt ist (keine Überschneidungen mit anderen Pools).
   - **DHCP funktioniert nicht**: Stellen Sie sicher, dass `pve-sdn` läuft und die OVS-Bridge (`ovsbr0`) korrekt konfiguriert ist (`ovs-vsctl show`).

**Tipp**: Erstellen Sie einen zweiten Pool (z. B. `db-pool` für `vnet-db`, Subnetz `10.0.2.100/26`) für spätere Tests mit mehreren VNets.

#### Übung 2: Automatisches IP-Management testen
**Ziel**: Konfigurieren Sie eine VM für DHCP und überprüfen Sie, ob sie automatisch eine IP aus dem `web-pool` erhält.

**Voraussetzungen**: Eine VM ist mit `vnet-web` verbunden (VLAN 10, siehe Modul 3, Übung 3).

**Schritte**:
1. **VM-Netzwerk auf DHCP einstellen**:
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
             dhcp4: yes
       ```
     - **Erklärung**: `dhcp4: yes` weist die VM an, eine IP vom DHCP-Server (Proxmox IPAM) anzufordern.
   - Speichern und anwenden:
     ```bash
     sudo netplan apply
     ```
2. **VM neu starten**:
   - Starten Sie die VM neu, damit die DHCP-Anfrage gesendet wird:
     ```bash
     sudo reboot
     ```
3. **IP-Adresse prüfen**:
   - Nach dem Neustart, in der VM-Shell:
     ```bash
     ip a
     ```
     - **Erwartete Ausgabe**: `eth0` hat eine IP aus dem Pool, z. B. `10.0.1.101/26`, mit Gateway `10.0.1.1`.
   - Überprüfen Sie die DHCP-Zuweisung:
     ```bash
     cat /var/lib/dhcp/dhclient.leases
     ```
     - Dies zeigt die zugewiesene IP, den Gateway und die Lease-Zeit.
4. **Konnektivität testen**:
   - Testen Sie das Gateway:
     ```bash
     ping 10.0.1.1
     ```
     - **Erfolg**: Antworten wie `64 bytes from 10.0.1.1: icmp_seq=1 ttl=64 time=0.3 ms`.
   - Testen Sie externe Konnektivität (falls Routing konfiguriert ist):
     ```bash
     ping 8.8.8.8
     ```
   - Überprüfen Sie DNS:
     ```bash
     nslookup google.com
     ```
     - **Erfolg**: DNS-Server (z. B. `8.8.8.8`) löst Namen auf.
5. **IPAM in der GUI überprüfen**:
   - Gehen Sie zu *Datacenter > SDN > IP-Pools > web-pool*.
   - Unter *Used IPs* sollte die zugewiesene IP (z. B. `10.0.1.101`) für die VM angezeigt werden.
6. **Fehlerbehebung**:
   - **Keine IP zugewiesen**: Stellen Sie sicher, dass DHCP im Pool aktiviert ist (`cat /etc/pve/sdn/ippools.cfg`). Prüfen Sie OVS (`ovs-vsctl show`) und den `pve-sdn`-Dienst.
   - **Falsche IP**: Überprüfen Sie, ob das Subnetz des Pools mit dem VNet übereinstimmt (`10.0.1.0/24`).
   - **Keine Konnektivität**: Prüfen Sie die Firewall der VM (`sudo ufw status`) oder die OVS-Bridge-Konfiguration.

**Erweiterung**: Weisen Sie einer zweiten VM im selben VNet (`vnet-web`) eine IP zu und überprüfen Sie, ob IPAM eine andere Adresse aus dem Pool vergibt (z. B. `10.0.1.102`). Testen Sie die Kommunikation zwischen den VMs:
```bash
ping 10.0.1.102
```

### 4.3 Häufige Probleme und Fehlerbehebung
- **Problem: DHCP funktioniert nicht**:
  - Lösung: Überprüfen Sie, ob der Pool DHCP aktiviert hat (`dhcp 1` in `ippools.cfg`). Stellen Sie sicher, dass die VM auf DHCP eingestellt ist und `pve-sdn` läuft.
- **Problem: IP-Konflikte**:
  - Lösung: Prüfen Sie, ob andere Pools oder manuelle IPs das gleiche Subnetz verwenden. Verwenden Sie `ip a` in allen VMs, um doppelte Adressen zu finden.
- **Problem: Gateway nicht erreichbar**:
  - Lösung: Stellen Sie sicher, dass das Gateway (`10.0.1.1`) in der Pool-Konfiguration korrekt ist und die OVS-Bridge VLAN-Tags korrekt verarbeitet (`ovs-vsctl show`).

### 4.4 Vorbereitung auf die nächsten Module
- **Was kommt als Nächstes?**: In Modul 5 konfigurieren Sie Inter-VNet-Routing, um die Kommunikation zwischen VNets (z. B. `vnet-web` und `vnet-db`) zu ermöglichen. IPAM wird dabei helfen, IPs in beiden Netzwerken konsistent zu verwalten.
- **Empfehlung**: Erstellen Sie einen zweiten IP-Pool für ein anderes VNet (z. B. `vnet-db`, Subnetz `10.0.2.100/26`) und testen Sie DHCP mit einer zweiten VM. Dokumentieren Sie die zugewiesenen IPs, um Konflikte zu vermeiden.
- **Dokumentation**: Notieren Sie die Pool-Konfigurationen (Subnetz, Gateway, DHCP-Einstellungen) und die zugewiesenen IPs für jede VM.

**Fragen zur Selbstreflexion**:
1. Warum ist IPAM effizienter als manuelle IP-Zuweisung in großen Netzwerken?
2. Was passiert, wenn zwei VMs versuchen, dieselbe IP aus einem Pool zu erhalten?
3. Wie können Sie sicherstellen, dass der DHCP-Server in Proxmox korrekt mit dem VNet kommuniziert?

Falls Sie eine Visualisierung (z. B. ein Diagramm der IP-Pool-Zuweisungen) oder weitere Details (z. B. zu statischen IP-Zuweisungen oder erweiterten DHCP-Optionen) wünschen, lassen Sie es mich wissen!

**[Modul 5: Inter-VNet-Routing](Modul05_VNet.md)**   oder **[zurück zur Übersicht](00_Übersicht_SDN.md)**