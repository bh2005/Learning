## Modul 1: Grundlagen von TCP/IP, Routing und VLANs

**Lernziel**: Auffrischen und Vertiefen der grundlegenden Netzwerkkonzepte, die die Basis für Software-Defined Networking (SDN) in Proxmox VE bilden. Nach diesem Modul verstehen Sie nicht nur die theoretischen Grundlagen, sondern können diese auch in der Praxis anwenden, um Netzwerke effizient zu konfigurieren und zu troubleshooten.

**Hintergrund**:  
Proxmox VE basiert auf einer virtualisierten Umgebung, in der Netzwerkkonzepte wie TCP/IP, Routing und VLANs eine zentrale Rolle spielen. SDN erweitert diese Grundlagen, indem es die Netzwerksteuerung von der Hardware entkoppelt und softwarebasiert macht. Lassen Sie uns die Konzepte Schritt für Schritt detaillieren.

### 1.1 TCP/IP – Das Fundament des Internets
TCP/IP ist ein Protokollstapel, der die Kommunikation in Netzwerken ermöglicht. Es basiert lose auf dem OSI-Modell (Open Systems Interconnection), das Netzwerke in 7 Schichten unterteilt:

- **Schicht 1: Physisch** (z. B. Kabel, Switches) – Übertragung von Bits.
- **Schicht 2: Data Link** (z. B. Ethernet, MAC-Adressen) – Lokale Adressierung und Fehlerkorrektur.
- **Schicht 3: Network** (IP) – Globale Adressierung und Routing.
- **Schicht 4: Transport** (TCP/UDP) – Zuverlässige oder schnelle Datenübertragung.
- **Schicht 5-7: Session, Presentation, Application** (z. B. HTTP, SSH) – Anwendungslogik.

**IP (Internet Protocol)**:  
- **Funktion**: IP dient als Adresssystem für Geräte im Netzwerk, ähnlich wie Hausadressen in einer Stadt. Es sorgt dafür, dass Datenpakete (Packets) von der Quelle zum Ziel gelangen.
- **IPv4 vs. IPv6**: IPv4 verwendet 32-Bit-Adressen (z. B. 192.168.1.10), was ca. 4 Milliarden Adressen ergibt. Aufgrund der Adressknappheit gibt es IPv6 mit 128-Bit-Adressen (z. B. 2001:db8::1). In Proxmox wird meist IPv4 verwendet, aber IPv6-Unterstützung ist integriert.
- **Subnetting**: Teilt Netzwerke in kleinere Segmente auf. Die Notation `/24` (z. B. 192.168.1.0/24) bedeutet eine Subnetzmaske von 255.255.255.0, was 256 Adressen (minus Broadcast und Network) erlaubt. Warum? Um Kollisionen zu vermeiden und Bandbreite effizient zu nutzen.
- **TCP vs. UDP**: TCP (Transmission Control Protocol) ist verbindungsorientiert und zuverlässig (z. B. für Webseiten, mit Handshake und Fehlerkorrektur). UDP (User Datagram Protocol) ist verbindungslos und schnell (z. B. für Streaming, ohne Garantie auf Vollständigkeit).

In SDN-Kontext: IP-Adressen werden dynamisch zugewiesen (z. B. via IPAM in späteren Modulen), und Proxmox nutzt IP für die Kommunikation zwischen VMs und dem Host.

### 1.2 Routing – Die Navigation der Datenpakete
**Funktion**: Routing leitet Datenpakete durch Netzwerke, ähnlich wie ein Navigationssystem Wege findet. Router analysieren die Ziel-IP und wählen den besten Pfad basierend auf Routing-Tabellen.
- **Statisches Routing**: Manuell konfigurierte Routen (z. B. "Alle Pakete nach 10.0.0.0/8 gehen über Gateway 192.168.1.1"). Einfach, aber unflexibel für große Netzwerke.
- **Dynamisches Routing**: Protokolle wie OSPF, BGP (später in Modul 9) lernen Routen automatisch. In Proxmox SDN werden virtuelle Router für Inter-VNet-Kommunikation verwendet.
- **Routing-Tabelle**: Enthält Einträge wie Zielnetz, Gateway und Metrik (Kosten). Befehl: `ip route show` zeigt dies an.
- **Hintergrund in SDN**: In Proxmox ermöglicht Routing die Isolation und Verbindung von virtuellen Netzwerken (VNets). Ohne Routing sind VNets wie getrennte Inseln – Routing baut Brücken.

### 1.3 VLANs – Virtuelle Trennung physischer Netzwerke
**Funktion**: VLANs (Virtual Local Area Networks) teilen ein physisches Netzwerk in logische Segmente auf, wie virtuelle "Fahrspuren" auf einer Autobahn. Basierend auf IEEE 802.1Q-Standard.
- **Vorteile**: Sicherheit (z. B. Abteilung von Gast- und Admin-Netzwerken), Effizienz (weniger Broadcast-Verkehr) und Skalierbarkeit.
- **Konfiguration**: Jede VLAN hat eine ID (1-4094). Pakete werden mit einem VLAN-Tag markiert (4 Bytes im Ethernet-Frame).
  - **Access Ports**: Für Endgeräte, die nur einer VLAN angehören (untagged).
  - **Trunk Ports**: Für Switches/Router, die mehrere VLANs transportieren (tagged).
- **In Proxmox SDN**: VLANs werden mit OVS (Open vSwitch) integriert. Die "VLAN aware"-Option erlaubt es, Tags zu handhaben, was für SDN essenziell ist, um VNets zu isolieren.

**Vergleich: Linux Bridge vs. OVS Bridge** (warum OVS für SDN mächtiger ist):

| Aspekt              | Linux Bridge (Standard in Proxmox) | OVS Bridge (für SDN empfohlen) |
|---------------------|------------------------------------|--------------------------------|
| **Funktionalität** | Einfacher virtueller Switch, unterstützt grundlegende Bridging. | Erweiterter Switch mit Flow-basierten Regeln, SDN-Controller-Integration. |
| **VLAN-Unterstützung** | Basis-VLANs möglich, aber manuell. | VLAN-aware-Modus für dynamische Tags, ideal für SDN-Zonen. |
| **Performance**    | Gut für kleine Setups.            | Besser skalierbar, unterstützt OpenFlow für programmierbare Netzwerke. |
| **SDN-Integration**| Begrenzt, keine native SDN.       | Kern für Proxmox SDN, ermöglicht VNets, IPAM und Routing. |
| **Beispielnutzung**| Einfache VM-Netzwerke.            | Komplexe SDN-Umgebungen mit VLANs und Firewalls. |

**Netzwerkdiagramm (textbasiert)**:  
Stellen Sie sich vor:  
- Physischer Host (Proxmox) mit NIC `ens18`.  
- OVS Bridge `ovsbr0` (VLAN-aware) verbindet `ens18`.  
- VM1 in VLAN 10 (Web) mit IP 10.0.1.10.  
- VM2 in VLAN 20 (DB) mit IP 10.0.2.10.  
Pfeile zeigen: VM1 → ovsbr0 → ens18 (tagged) → externer Switch.

### Praktische Übungen

#### Übung 1: Erstellen einer OVS Bridge (detailliert)
**Definition**: Eine OVS (Open vSwitch) Bridge fungiert als virtueller Switch, der VMs mit dem physischen Netzwerk verbindet. Im Gegensatz zu einer Linux Bridge unterstützt OVS fortschrittliche Features wie Flow-Matching und SDN-Controller.

**Voraussetzungen**: Stellen Sie sicher, dass OVS installiert ist (`apt install openvswitch-switch`). Identifizieren Sie Ihre physische Schnittstelle mit `ip link show` (z. B. `ens18`).

**Schritte**:
1. **In der Proxmox-GUI navigieren**: Gehen Sie zum Knoten > *Netzwerk*.
2. **Bridge erstellen**: Klicken Sie auf *Erstellen* > *OVS Bridge*.
   - **Name**: Geben Sie `ovsbr0` ein (beliebig, aber konsistent).
   - **Ports**: Fügen Sie die physische Schnittstelle hinzu, z. B. `ens18`. Dies bindet die Bridge an die Hardware.
   - **VLAN aware**: Aktivieren Sie diese Option! Sie ermöglicht das Handhaben von VLAN-Tags, was für SDN-Zonen und VNets entscheidend ist. Ohne dies funktionieren VLANs nicht dynamisch.
   - **Optionale Einstellungen**: MTU auf 1500 lassen (Standard), oder anpassen, wenn Jumbo Frames benötigt werden.
3. **Anwenden**: Klicken Sie auf *Anwenden* – der Host rebootet möglicherweise das Netzwerk (kurze Unterbrechung möglich).
4. **Überprüfen**: In der Shell: `ovs-vsctl show`. Ausgabe sollte `ovsbr0` mit Port `ens18` zeigen. Testen Sie mit `ip a` – die Bridge sollte UP sein.

**Troubleshooting**: Wenn die Bridge nicht erscheint, prüfen Sie Logs mit `journalctl -u pve-network`. Häufiger Fehler: Falsche Schnittstellennamen oder Konflikte mit bestehenden Bridges.

#### Übung 2: Manuelle Netzwerkkonfiguration auf einer VM (erweitert)
**Ziel**: Lernen Sie, wie IP-Konfiguration in einer VM funktioniert und wie sie mit der Bridge interagiert.

**Voraussetzungen**: Eine OVS Bridge wie `ovsbr0` existiert. Installieren Sie eine Linux-VM (z. B. Ubuntu) in Proxmox.

**Schritte**:
1. **VM erstellen**: In der Proxmox-GUI > *Erstellen* > *Virtuelle Maschine*.
   - Wählen Sie ein OS-Image (z. B. Ubuntu ISO).
   - Unter *Netzwerk*: Modell `VirtIO` (für beste Performance), Bridge `ovsbr0`.
   - Starten Sie die VM und installieren Sie das OS.
2. **In der VM-Shell zugreifen**: Öffnen Sie die Konsole in Proxmox oder SSH.
3. **Netzwerkdatei bearbeiten**: Verwenden Sie `sudo nano /etc/netplan/01-netcfg.yaml` (für moderne Ubuntu; bei älteren: `/etc/network/interfaces`).
   - Beispiel für statische IP (Netplan-Format):
     ```yaml
     network:
       version: 2
       renderer: networkd
       ethernets:
         eth0:
           dhcp4: no
           addresses: [192.168.1.15/24]
           gateway4: 192.168.1.1
           nameservers:
             addresses: [8.8.8.8, 8.8.4.4]
     ```
     - Erklärung: `dhcp4: no` deaktiviert DHCP. `addresses` setzt IP und Subnetz. `gateway4` ist der Router für externe Netze. DNS für Namensauflösung.
4. **Änderungen anwenden**: `sudo netplan apply` (oder `sudo systemctl restart networking` für interfaces-Datei).
5. **Konnektivität testen**:
   - `ip a`: Zeigt die IP an (sollte 192.168.1.15 sein).
   - `ping 192.168.1.1`: Testet Gateway.
   - `ping google.com`: Testet Internet (DNS + Routing).
   - `traceroute 8.8.8.8`: Zeigt den Routing-Pfad.

**Variation**: Konfigurieren Sie DHCP in der VM (`dhcp4: yes`) und beobachten Sie, wie der Router IPs zuweist. Testen Sie VLANs, indem Sie in der Bridge-Config einen VLAN-Tag setzen (z. B. via GUI: Netzwerkgerät > VLAN Tag 10).

**Häufige Fehler**: Falsche Subnetzmaske führt zu "Network unreachable". Überprüfen Sie mit `ip route` die Routing-Tabelle.

Dieses Modul legt die Grundlage für die folgenden – experimentieren Sie, um die Konzepte zu verinnerlichen! Falls Fragen aufkommen, notieren Sie sie für Modul 11.

**[Modul 2: Lab-Setup und Vorbereitung](Modul02_Setup.md)**   oder **[zurück zur Übersicht](00_Übersicht_SDN.md)**