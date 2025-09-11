## Modul 2: Lab-Setup und Vorbereitung

**Lernziel**: Aktivieren und Verifizieren der SDN-Funktionalität in Proxmox VE, um eine solide Grundlage für die nachfolgenden Module zu schaffen. Sie lernen, wie Sie die SDN-Komponenten installieren, konfigurieren und deren korrekte Funktion überprüfen. Dieses Modul stellt sicher, dass Ihre Umgebung bereit ist, um Zonen, VNets und erweiterte Netzwerkfunktionen zu implementieren.

**Hintergrund**:  
Proxmox VE ist eine leistungsstarke Virtualisierungsplattform, die standardmäßig mit einer schlanken Konfiguration geliefert wird, um Ressourcen zu sparen. Die SDN-Funktionalität (Software-Defined Networking) ist eine optionale Erweiterung, die durch das Paket `pve-sdn` aktiviert wird. Dieses Paket integriert Tools wie Open vSwitch (OVS) und ermöglicht die Steuerung virtueller Netzwerke, Router und Firewalls über die Proxmox-GUI oder CLI. Ohne korrektes Setup funktioniert SDN nicht, daher ist dieses Modul entscheidend für den Erfolg der späteren Konfigurationen.

### 2.1 SDN in Proxmox VE – Überblick
- **Was ist SDN in Proxmox?**: SDN trennt die Steuerungsebene (Control Plane, z. B. Regeln für Routing) von der Datenebene (Data Plane, tatsächlicher Datenverkehr). In Proxmox wird dies durch OVS und den `pve-sdn`-Dienst realisiert, der Funktionen wie VLANs, VNets, IPAM (IP Address Management) und virtuelle Router bereitstellt.
- **Warum ist das Setup wichtig?**: Ohne den `pve-sdn`-Dienst fehlen die GUI-Optionen für SDN (z. B. Zonen, VNets) und die zugrunde liegende Infrastruktur (z. B. OVS-Flows). Fehler im Setup führen zu Problemen wie nicht erreichbaren VMs oder falsch konfigurierten Netzwerken.
- **Voraussetzungen**:
  - Ein funktionierender Proxmox VE-Knoten (Version 7.x oder höher empfohlen, da SDN in älteren Versionen eingeschränkt ist).
  - Internetzugang für Paketinstallationen.
  - Grundlegende Netzwerkkonfiguration (z. B. eine funktionierende Bridge wie `vmbr0` oder `ovsbr0`, siehe Modul 1).
  - Root-Zugriff auf die Shell (via GUI-Console oder SSH).

### 2.2 Komponenten des SDN-Setups
- **pve-sdn**: Der Hauptdienst, der SDN-Funktionen in Proxmox integriert. Er kommuniziert mit OVS und verwaltet Zonen, VNets und IP-Pools.
- **Open vSwitch (OVS)**: Ein virtueller Switch, der die Grundlage für SDN bildet. OVS unterstützt VLANs, Flow-Regeln und SDN-Controller, im Gegensatz zu einfachen Linux-Bridges.
- **Proxmox-GUI**: Die Weboberfläche (`https://<Proxmox-IP>:8006`) bietet eine benutzerfreundliche Möglichkeit, SDN zu konfigurieren, sobald `pve-sdn` installiert ist.
- **Netzwerkvoraussetzungen**: Eine physische Netzwerkschnittstelle (z. B. `ens18`) muss verfügbar sein, um mit einer OVS-Bridge verbunden zu werden. Der physische Switch, an den der Proxmox-Server angeschlossen ist, sollte VLANs unterstützen, wenn Sie VLAN-Tagging nutzen möchten.

### Praktische Übungen

#### Übung 1: SDN-Paket installieren
**Ziel**: Installieren Sie das `pve-sdn`-Paket und stellen Sie sicher, dass der Dienst korrekt läuft.

**Hintergrund**: Das `pve-sdn`-Paket ist nicht in der Standardinstallation von Proxmox enthalten, da SDN eine optionale Funktion ist. Die Installation fügt die notwendigen Tools und GUI-Optionen hinzu. Open vSwitch wird oft automatisch als Abhängigkeit installiert, falls es noch nicht vorhanden ist.

**Schritte**:
1. **Shell öffnen**: Öffnen Sie die Shell des Proxmox-Knotens über die GUI (*Node > Shell*) oder per SSH (`ssh root@<Proxmox-IP>`).
2. **Paketquellen aktualisieren**: Führen Sie aus:
   ```bash
   sudo apt update
   ```
   - **Bedeutung**: Aktualisiert die Liste der verfügbaren Pakete, ähnlich wie ein App-Store, der nach Updates sucht. Dies stellt sicher, dass Sie die neueste Version von `pve-sdn` erhalten.
   - **Fehlerbehebung**: Falls `apt update` fehlschlägt, prüfen Sie die Internetverbindung (`ping 8.8.8.8`) oder die Paketquellen in `/etc/apt/sources.list`. Stellen Sie sicher, dass die Proxmox-Repositorys (z. B. `deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription`) korrekt konfiguriert sind.
3. **pve-sdn installieren**: Führen Sie aus:
   ```bash
   sudo apt install pve-sdn
   ```
   - **Was passiert?**: Installiert das `pve-sdn`-Paket und Abhängigkeiten wie `openvswitch-switch`. Dies kann einige Minuten dauern, je nach Internetgeschwindigkeit.
   - **Ausgabe**: Erfolgreiche Installation endet mit einer Bestätigung, z. B. "Setting up pve-sdn ...".
4. **Dienst neu starten**: Um sicherzustellen, dass der Dienst korrekt geladen wird, führen Sie aus:
   ```bash
   sudo systemctl restart pve-sdn
   ```
   - **Bedeutung**: Startet den SDN-Dienst neu, um die neuen Konfigurationen zu übernehmen.
   - **Alternative**: Falls Änderungen nicht sofort wirken, können Sie auch `pve-cluster` und `pveproxy` neu starten:
     ```bash
     sudo systemctl restart pve-cluster pveproxy
     ```
5. **Installation überprüfen**: Führen Sie aus:
   ```bash
   dpkg -l | grep pve-sdn
   ```
   - **Erwartete Ausgabe**: Zeigt die installierte Version, z. B. `ii  pve-sdn 7.0-1`.
   - **Fehlerbehebung**: Falls das Paket nicht angezeigt wird, wiederholen Sie die Installation oder prüfen Sie Logs mit `journalctl -u apt`.

**Tipp**: Notieren Sie sich die installierte Version von `pve-sdn`, da einige Funktionen (z. B. BGP-Unterstützung) von der Version abhängen.

#### Übung 2: SDN-Voraussetzungen prüfen
**Ziel**: Verifizieren Sie, dass der `pve-sdn`-Dienst läuft und die SDN-Optionen in der GUI verfügbar sind.

**Hintergrund**: Nach der Installation muss der Dienst aktiv sein, und die Proxmox-GUI sollte neue Menüpunkte unter *Datacenter > SDN* anzeigen. Diese Übung stellt sicher, dass Ihr System bereit für die Konfiguration von Zonen und VNets ist.

**Schritte**:
1. **Dienststatus prüfen**: Führen Sie in der Shell aus:
   ```bash
   sudo systemctl status pve-sdn
   ```
   - **Erwartete Ausgabe**:
     ```plaintext
     ● pve-sdn.service - Proxmox VE SDN Service
        Loaded: loaded (/lib/systemd/system/pve-sdn.service; enabled; vendor preset: enabled)
        Active: active (running) since ...
     ```
   - **Bedeutung**: `active (running)` zeigt, dass der Dienst läuft. Falls der Status `failed` oder `inactive` ist, prüfen Sie Logs mit:
     ```bash
     journalctl -u pve-sdn
     ```
   - **Häufige Fehler**: Abhängigkeiten wie OVS fehlen (`apt install openvswitch-switch`) oder Konfigurationsfehler in `/etc/pve/sdn/`.
2. **OVS-Status prüfen**: Verifizieren Sie, dass Open vSwitch korrekt läuft:
   ```bash
   sudo systemctl status openvswitch-switch
   ```
   - **Erwartete Ausgabe**: Ähnlich wie oben, `active (running)`.
   - **Zusätzlich**: Überprüfen Sie die OVS-Konfiguration mit:
     ```bash
     ovs-vsctl show
     ```
     - **Ausgabe**: Zeigt alle OVS-Bridges (z. B. `ovsbr0`) und deren Ports (z. B. `ens18`). Falls keine Bridges angezeigt werden, erstellen Sie eine wie in Modul 1 beschrieben.
3. **GUI-Check**: Melden Sie sich an der Proxmox-Weboberfläche an (`https://<Proxmox-IP>:8006`).
   - Navigieren Sie zu *Datacenter > SDN*.
   - **Erwartete Ansicht**: Ein neuer Reiter *SDN* sollte sichtbar sein, mit Unteroptionen wie *Zones*, *VNets*, *Controllers* und *IP-Pools*.
   - **Fehlerbehebung**: Falls der Reiter fehlt, starten Sie die Weboberfläche neu:
     ```bash
     sudo systemctl restart pveproxy
     ```
     oder aktualisieren Sie die GUI-Seite (F5). Stellen Sie sicher, dass Sie Root- oder Admin-Rechte haben.
4. **Netzwerkkonfiguration prüfen**: Stellen Sie sicher, dass eine OVS-Bridge (z. B. `ovsbr0`) existiert:
   - Gehen Sie zu *Node > Netzwerk*.
   - Überprüfen Sie, ob eine Bridge mit aktivierter *VLAN aware*-Option vorhanden ist (siehe Modul 1, Übung 1).
   - Testen Sie die Netzwerkkonnektivität des Hosts:
     ```bash
     ping 8.8.8.8
     ```
     - **Erfolg**: Erhalten Sie Antworten (z. B. `64 bytes from 8.8.8.8: icmp_seq=1 ttl=117 time=20 ms`).
     - **Fehler**: Prüfen Sie die Routing-Tabelle (`ip route`) und die physische Schnittstelle (`ip link`).

**Erweiterte Prüfung**: Testen Sie, ob die SDN-Konfigurationsdateien korrekt erstellt wurden:
```bash
ls /etc/pve/sdn/
```
- **Erwartete Ausgabe**: Dateien wie `zones.cfg`, `vnets.cfg` (zunächst leer, bis Sie Zonen/VNets in Modul 3 erstellen).
- Falls Ordner oder Dateien fehlen, starten Sie `pve-sdn` neu oder überprüfen Sie die Installation.

#### Übung 3: Vorbereitung der physischen Netzwerkumgebung (optional)
**Ziel**: Stellen Sie sicher, dass Ihr physischer Switch korrekt für VLANs und SDN vorbereitet ist.

**Hintergrund**: Wenn Sie VLANs in SDN nutzen, muss der physische Switch, an den Ihr Proxmox-Server angeschlossen ist, VLAN-Tagging unterstützen. Dies ist besonders wichtig für spätere Module (z. B. VLAN-Zonen).

**Schritte**:
1. **Switch-Konfiguration prüfen**:
   - Melden Sie sich an der Management-Oberfläche Ihres Switches an (z. B. via Webinterface oder CLI).
   - Stellen Sie sicher, dass der Port, an den der Proxmox-Server angeschlossen ist (z. B. Port 1 für `ens18`), als *Trunk Port* konfiguriert ist und die benötigten VLAN-IDs (z. B. 10, 20) erlaubt.
   - Beispiel für einen Cisco-Switch (CLI):
     ```plaintext
     interface GigabitEthernet0/1
       switchport mode trunk
       switchport trunk allowed vlan 10,20
     ```
2. **Testen der VLAN-Konnektivität**:
   - Erstellen Sie eine Test-VM (wie in Modul 1, Übung 2) und weisen Sie ihr ein VLAN-Tag (z. B. 10) zu.
   - Konfigurieren Sie die VM mit einer IP (z. B. `10.0.1.10/24`) und testen Sie die Konnektivität:
     ```bash
     ping 10.0.1.1
     ```
   - Falls dies fehlschlägt, prüfen Sie die Switch-Konfiguration oder OVS-Bridge (`ovs-vsctl show`).

**Tipp**: Dokumentieren Sie die Switch-Konfiguration (z. B. erlaubte VLANs, Trunk-Ports), da dies für spätere Module wichtig ist.

### 2.3 Häufige Probleme und Fehlerbehebung
- **Problem: SDN-Reiter fehlt in der GUI**:
  - Lösung: Überprüfen Sie, ob `pve-sdn` installiert ist (`dpkg -l | grep pve-sdn`). Starten Sie `pveproxy` neu (`sudo systemctl restart pveproxy`).
- **Problem: pve-sdn-Dienst startet nicht**:
  - Lösung: Prüfen Sie Logs (`journalctl -u pve-sdn`). Häufige Ursachen: Fehlende OVS-Installation oder Konflikte mit bestehenden Netzwerkkonfigurationen.
- **Problem: Keine Netzwerkkonnektivität nach Installation**:
  - Lösung: Überprüfen Sie die OVS-Bridge (`ovs-vsctl show`) und die Routing-Tabelle (`ip route`). Stellen Sie sicher, dass die physische Schnittstelle korrekt mit der Bridge verbunden ist.

### 2.4 Vorbereitung auf die nächsten Module
- **Was kommt als Nächstes?**: In Modul 3 erstellen Sie Zonen und VNets, die auf dieser Installation aufbauen. Stellen Sie sicher, dass:
  - `pve-sdn` und `openvswitch-switch` laufen.
  - Eine OVS-Bridge mit *VLAN aware* aktiviert ist.
  - Ihr physischer Switch VLANs unterstützt, falls Sie diese nutzen.
- **Empfehlung**: Erstellen Sie eine Test-VM und weisen Sie ihr eine statische IP zu (wie in Modul 1), um die Netzwerkbasis zu testen, bevor Sie mit SDN-spezifischen Konfigurationen beginnen.

**Fragen zur Selbstreflexion**:
1. Warum ist die *VLAN aware*-Option in der OVS-Bridge so wichtig für SDN?
2. Was passiert, wenn der `pve-sdn`-Dienst nicht läuft? Wie würden Sie dies bemerken?
3. Wie können Sie sicherstellen, dass Ihr physischer Switch mit der Proxmox-SDN-Umgebung kompatibel ist?

Dieses Modul stellt sicher, dass Ihre Proxmox-Umgebung SDN-fähig ist. Wenn Sie Fragen haben oder ein bestimmtes Detail vertieft werden soll (z. B. erweiterte OVS-Konfiguration oder Switch-Setup), lassen Sie es mich wissen!

**[Modul 3: Konfiguration der grundlegenden SDN-Komponenten](Modul03_Konfiguration.md)**   oder **[zurück zur Übersicht](00_Übersicht_SDN.md)**