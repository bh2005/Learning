## Modul 7: SDN Troubleshooting

**Lernziel**: Erlernen von Techniken zur Identifikation und Behebung häufiger Probleme in einer Proxmox VE SDN-Umgebung. Nach diesem Modul können Sie Netzwerk-, Firewall- und Dienstfehler analysieren und beheben, um die Stabilität und Funktionalität Ihrer virtuellen Netzwerke sicherzustellen.

**Hintergrund**:  
Software-Defined Networking (SDN) in Proxmox VE bietet leistungsstarke Funktionen, aber die Komplexität von Zonen, VNets, Routing und Firewalls kann zu Fehlern führen. Häufige Probleme umfassen falsche VLAN-Tags, blockierende Firewall-Regeln, inaktive Dienste oder fehlerhafte Routen. Dieses Modul vermittelt Ihnen systematische Ansätze zur Fehlerdiagnose und -behebung, indem Sie Proxmox-Tools, Logs und Netzwerkbefehle nutzen. Troubleshooting ist wie Detektivarbeit: Sie sammeln Hinweise (Logs, Konfigurationen) und testen Hypothesen, um die Ursache zu finden.

**Voraussetzungen**:
- Der `pve-sdn`-Dienst ist installiert und läuft (Modul 2).
- Eine VLAN-Zone (z. B. `Zone-Web`) mit VNets (`vnet-web`, VLAN 10, Subnetz `10.0.1.0/24`; `vnet-db`, VLAN 20, Subnetz `10.0.2.0/24`) ist konfiguriert (Modul 3).
- IP-Pools sind eingerichtet (Modul 4).
- Inter-VNet-Routing ist aktiviert (Modul 5).
- Firewall-Regeln sind definiert, z. B. für SSH-Zugriff (Modul 6).
- Mindestens zwei VMs sind mit `vnet-web` (z. B. IP `10.0.1.101`) und `vnet-db` (z. B. IP `10.0.2.101`) verbunden.
- Zugriff auf die Proxmox-GUI und die Shell.

### 7.1 SDN Troubleshooting – Überblick
- **Warum Troubleshooting?**: Fehler in SDN-Umgebungen können durch viele Faktoren verursacht werden: falsche Konfigurationen, inaktive Dienste, Netzwerkprobleme oder externe Hardware (z. B. Switches). Ein systematischer Ansatz spart Zeit und verhindert Frustration.
- **Häufige Fehlerquellen**:
  - **Dienste**: `pve-sdn` oder `openvswitch-switch` läuft nicht.
  - **Netzwerkkonfiguration**: Falsche VLAN-Tags, Subnetz-Konflikte oder fehlende Bridges.
  - **Routing**: Fehlerhafte oder fehlende Routen in der Routing-Tabelle.
  - **Firewall**: Blockierende Regeln, die den Datenverkehr verhindern.
  - **VM-Konfiguration**: Falsche IP-Adressen, Gateway oder DNS-Einstellungen.
  - **Externer Switch**: VLANs nicht korrekt konfiguriert oder Trunk-Ports falsch gesetzt.
- **Troubleshooting-Werkzeuge**:
  - **Proxmox-GUI**: Zeigt Konfigurationen und Status (z. B. SDN, Firewall).
  - **Shell-Befehle**: `ip`, `ping`, `ovs-vsctl`, `journalctl`, `pve-firewall`.
  - **Logs**: `/var/log/syslog`, `journalctl` für Dienst- und Firewall-Logs.
  - **Netzwerktests**: `tcpdump`, `traceroute` für Paketanalyse.

### 7.2 Detaillierte Konzepte
- **Systematischer Ansatz**:
  1. **Problem identifizieren**: Welches Symptom tritt auf? (z. B. „VMs können nicht pingen“, „SSH funktioniert nicht“).
  2. **Hypothese aufstellen**: Mögliche Ursachen (z. B. Firewall, Routing, VLANs).
  3. **Daten sammeln**: Logs, Konfigurationen und Netzwerkstatus prüfen.
  4. **Tests durchführen**: Isolierte Tests (z. B. `ping`, `tcpdump`) zur Eingrenzung der Ursache.
  5. **Lösung anwenden**: Konfiguration anpassen, Dienste neu starten, Firewall-Regeln ändern.
  6. **Überprüfen**: Testen, ob das Problem behoben ist.
- **Wichtige Befehle**:
  - `sudo systemctl status <dienst>`: Prüft den Status von Diensten wie `pve-sdn` oder `openvswitch-switch`.
  - `ovs-vsctl show`: Zeigt die OVS-Bridge-Konfiguration (z. B. `ovsbr0`, VLAN-Tags).
  - `ip route`: Zeigt die Routing-Tabelle des Hosts oder der VM.
  - `tcpdump`: Analysiert den Netzwerkverkehr auf einer Schnittstelle.
  - `journalctl`: Zeigt System- und Dienst-Logs.
- **Beispiel-Szenario**: Eine VM in `vnet-web` (`10.0.1.101`) kann nicht per SSH auf eine VM in `vnet-db` (`10.0.2.101`) zugreifen, obwohl Routing (Modul 5) und Firewall-Regeln (Modul 6) konfiguriert sind.

### Praktische Übungen

#### Übung 1: Problem simulieren und diagnostizieren
**Ziel**: Simulieren Sie ein häufiges SDN-Problem (z. B. blockierter SSH-Verkehr) und nutzen Sie Troubleshooting-Techniken, um die Ursache zu finden und zu beheben.

**Schritte**:
1. **Problem simulieren**:
   - Deaktivieren Sie die Firewall-Regel für SSH (Modul 6) in `vnet-db`:
     - Gehen Sie in der Proxmox-GUI zu *Datacenter > SDN > VNets > vnet-db > Firewall*.
     - Wählen Sie die Regel für TCP Port 22 und setzen Sie *Enable* auf *No* oder löschen Sie die Regel.
     - Alternativ: Bearbeiten Sie `/etc/pve/firewall/vnets/vnet-db.fw` und kommentieren Sie die Regel aus:
       ```plaintext
       #[RULES]
       #IN ACCEPT -source 10.0.1.0/24 -dest 10.0.2.0/24 -p tcp -dport 22 -log nolog
       ```
   - Wenden Sie die Änderungen an:
     ```bash
     pve-firewall compile
     ```
   - Testen Sie von der VM in `vnet-web` (`10.0.1.101`):
     ```bash
     ssh user@10.0.2.101
     ```
     - **Erwartete Ausgabe**: Verbindung fehlschlägt (z. B. „Connection timed out“), da die Firewall den SSH-Verkehr blockiert.
2. **Dienststatus prüfen**:
   - Überprüfen Sie, ob die SDN-Dienste laufen:
     ```bash
     sudo systemctl status pve-sdn
     ```
     - **Erwartete Ausgabe**: `active (running)`.
     - **Fehlerbehebung**: Falls nicht aktiv, starten Sie den Dienst:
       ```bash
       sudo systemctl restart pve-sdn
       ```
   - Prüfen Sie Open vSwitch:
     ```bash
     sudo systemctl status openvswitch-switch
     ```
     - **Fehlerbehebung**: Falls nicht aktiv, starten Sie:
       ```bash
       sudo systemctl restart openvswitch-switch
       ```
3. **OVS-Bridge-Konfiguration prüfen**:
   - Führen Sie aus:
     ```bash
     ovs-vsctl show
     ```
     - **Erwartete Ausgabe**:
       ```plaintext
       Bridge ovsbr0
           Port ovsbr0
               Interface ovsbr0
                   type: internal
           Port ens18
               Interface ens18
           Port vnet-web
               tag: 10
               Interface vnet-web
           Port vnet-db
               tag: 20
               Interface vnet-db
       ```
     - **Fehlerbehebung**: Stellen Sie sicher, dass `vnet-web` (VLAN 10) und `vnet-db` (VLAN 20) korrekt mit `ovsbr0` verbunden sind. Falls nicht, überprüfen Sie die VNet-Konfiguration:
       ```bash
       cat /etc/pve/sdn/vnets.cfg
       ```
4. **Routing-Tabelle prüfen**:
   - Auf dem Proxmox-Host:
     ```bash
     ip route
     ```
     - **Erwartete Ausgabe**: Routen für `10.0.1.0/24` und `10.0.2.0/24` sollten vorhanden sein, z. B. über `ovsbr0`.
     - **Fehlerbehebung**: Falls Routen fehlen, überprüfen Sie den virtuellen Router:
       ```bash
       cat /etc/pve/sdn/controllers.cfg
       ```
       - Stellen Sie sicher, dass `vnet-web` und `vnet-db` mit Gateways `10.0.1.1` und `10.0.2.1` konfiguriert sind.
5. **Firewall prüfen**:
   - Überprüfen Sie die Firewall-Regeln:
     ```bash
     cat /etc/pve/firewall/vnets/vnet-db.fw
     ```
     - **Problem erkannt**: Die SSH-Regel ist deaktiviert oder fehlt.
   - Aktivieren Sie die Regel erneut in der GUI:
     - Gehen Sie zu *Datacenter > SDN > VNets > vnet-db > Firewall*.
     - Erstellen oder aktivieren Sie die Regel:
       - **Aktion**: `Accept`.
       - **Protokoll**: `TCP`.
       - **Ziel-Port**: `22`.
       - **Quellnetzwerk**: `10.0.1.0/24`.
       - **Zielnetzwerk**: `10.0.2.0/24`.
       - **Richtung**: `In`.
   - Wenden Sie die Änderungen an:
     ```bash
     pve-firewall compile
     ```
6. **Konnektivität erneut testen**:
   - Von der VM in `vnet-web`:
     ```bash
     ssh user@10.0.2.101
     ```
     - **Erfolg**: Verbindung wird hergestellt.
   - Testen Sie ICMP (sollte weiterhin blockiert sein, wenn keine ICMP-Regel existiert):
     ```bash
     ping 10.0.2.101
     ```
     - **Erwartete Ausgabe**: Keine Antwort, da ICMP nicht erlaubt ist.

#### Übung 2: Netzwerkverkehr analysieren
**Ziel**: Verwenden Sie `tcpdump`, um den Netzwerkverkehr zu analysieren und die Ursache für blockierte Pakete zu bestätigen.

**Schritte**:
1. **tcpdump installieren** (falls nicht vorhanden):
   - Auf dem Proxmox-Host:
     ```bash
     sudo apt install tcpdump
     ```
2. **Datenverkehr aufzeichnen**:
   - Auf dem Proxmox-Host, für die OVS-Bridge:
     ```bash
     sudo tcpdump -i ovsbr0 port 22
     ```
     - **Aktion**: Versuchen Sie erneut, von `10.0.1.101` eine SSH-Verbindung zu `10.0.2.101` aufzubauen.
     - **Erwartete Ausgabe** (mit aktiver Regel):
       ```plaintext
       IP 10.0.1.101.XXXX > 10.0.2.101.22: Flags [S], seq ..., length 0
       IP 10.0.2.101.22 > 10.0.1.101.XXXX: Flags [S.], seq ..., length 0
       ```
       - Dies zeigt den SSH-Handschake (TCP Port 22).
     - **Ohne aktive Regel**: Keine oder nur einseitige Pakete (z. B. SYN ohne Antwort).
3. **ICMP-Verkehr prüfen**:
   - Führen Sie aus:
     ```bash
     sudo tcpdump -i ovsbr0 icmp
     ```
     - Versuchen Sie, von `10.0.1.101` zu pingen:
       ```bash
       ping 10.0.2.101
       ```
     - **Erwartete Ausgabe**: Keine Pakete oder nur ICMP-Requests ohne Antwort, da die Firewall ICMP blockiert.
4. **Fehlerbehebung**:
   - **Keine Pakete in tcpdump**: Prüfen Sie, ob die VM korrekt mit `vnet-web` verbunden ist (`ip a` in der VM) und ob die OVS-Bridge VLAN-Tags korrekt verarbeitet (`ovs-vsctl show`).
   - **Nur einseitiger Verkehr**: Dies weist auf Firewall-Blockierung hin. Überprüfen Sie die Firewall-Regeln (`cat /etc/pve/firewall/vnets/vnet-db.fw`).
   - **Logs prüfen**: Aktivieren Sie Logging in der Firewall-Regel (Modul 6) und sehen Sie in:
     ```bash
     journalctl -u pve-firewall
     ```

#### Übung 3: Weiteres Problem simulieren (optional)
**Ziel**: Simulieren Sie einen Dienstfehler und beheben Sie ihn.

**Schritte**:
1. **Dienst stoppen**:
   - Stoppen Sie den `pve-sdn`-Dienst:
     ```bash
     sudo systemctl stop pve-sdn
     ```
   - Testen Sie die Konnektivität:
     ```bash
     ping 10.0.2.101
     ```
     - **Erwartete Ausgabe**: Fehlschlägt, da SDN-Konfigurationen nicht aktiv sind.
2. **Diagnose**:
   - Prüfen Sie den Dienststatus:
     ```bash
     sudo systemctl status pve-sdn
     ```
     - **Ausgabe**: `inactive` oder `failed`.
   - Sehen Sie in die Logs:
     ```bash
     journalctl -u pve-sdn
     ```
3. **Behebung**:
   - Starten Sie den Dienst:
     ```bash
     sudo systemctl start pve-sdn
     ```
   - Testen Sie erneut die Konnektivität.
4. **Fehlerbehebung**:
   - Falls der Dienst nicht startet, prüfen Sie Abhängigkeiten:
     ```bash
     sudo systemctl status openvswitch-switch
     ```
   - Überprüfen Sie SDN-Konfigurationsdateien auf Syntaxfehler:
     ```bash
     cat /etc/pve/sdn/zones.cfg
     cat /etc/pve/sdn/vnets.cfg
     ```

### 7.3 Häufige Probleme und Lösungen
- **Problem: VMs können nicht kommunizieren**:
  - **Prüfen**: Firewall-Regeln (`cat /etc/pve/firewall/vnets/vnet-db.fw`), Routing (`ip route`), VLAN-Tags (`ovs-vsctl show`), VM-IPs (`ip a` in der VM).
  - **Lösung**: Firewall-Regel hinzufügen, Routing korrigieren oder VLAN-Tags anpassen.
- **Problem: SDN-Dienst startet nicht**:
  - **Prüfen**: `sudo systemctl status pve-sdn`, Logs (`journalctl -u pve-sdn`).
  - **Lösung**: Abhängigkeiten wie `openvswitch-switch` starten, Konfigurationsdateien prüfen.
- **Problem: VLAN-Tags funktionieren nicht**:
  - **Prüfen**: OVS-Konfiguration (`ovs-vsctl show`), physischer Switch (VLANs erlaubt?).
  - **Lösung**: VLANs auf dem Switch konfigurieren (z. B. Trunk-Port für VLAN 10, 20).
- **Problem: Firewall blockiert Verkehr**:
  - **Prüfen**: Firewall-Regeln, Logs (`journalctl -u pve-firewall`).
  - **Lösung**: Regel anpassen oder Logging aktivieren, um blockierte Pakete zu identifizieren.

### 7.4 Vorbereitung auf die nächsten Module
- **Was kommt als Nächstes?**: In Modul 8 verbinden Sie VNets mit externen Netzwerken (z. B. Internet) durch statische Routen. Troubleshooting-Fähigkeiten sind hier entscheidend, um Verbindungsprobleme zu lösen.
- **Empfehlung**: Simulieren Sie weitere Fehler, z. B. falsche Subnetze oder deaktivierte Dienste, und üben Sie die Diagnose mit `tcpdump` und `journalctl`. Dokumentieren Sie häufige Fehler und ihre Lösungen.
- **Dokumentation**: Erstellen Sie eine Checkliste für Troubleshooting (z. B. Dienste, Firewall, Routing, VLANs).

**Fragen zur Selbstreflexion**:
1. Welche Schritte würden Sie unternehmen, wenn eine VM keine IP-Adresse erhält?
2. Wie können Sie mit `tcpdump` bestätigen, dass ein Paket von der Firewall blockiert wird?
3. Warum ist es wichtig, Logs regelmäßig zu überprüfen, auch wenn keine Probleme offensichtlich sind?

Falls Sie eine Visualisierung (z. B. ein Flussdiagramm für Troubleshooting mit ChartJS) oder weitere Details (z. B. zu fortgeschrittenem Debugging mit `ovs-ofctl`) wünschen, lassen Sie es mich wissen!

**[Modul 8: Integration mit externen Routern](Modul08_Ext_Router.md)**   oder **[zurück zur Übersicht](00_Übersicht_SDN.md)**