## Modul 6: SDN-Firewall und Sicherheitsregeln

**Lernziel**: Erlernen der Konfiguration und Verwaltung von SDN-Firewall-Regeln in Proxmox VE, um den Datenverkehr zwischen virtuellen Netzwerken (VNets) gezielt zu steuern und die Sicherheit der Netzwerkumgebung zu gewährleisten. Nach diesem Modul können Sie Firewall-Regeln erstellen, testen und anpassen, um spezifische Kommunikation (z. B. SSH oder Datenbankzugriff) zwischen VNets zuzulassen oder zu blockieren, während unerwünschter Datenverkehr verhindert wird.

**Hintergrund**:  
Die SDN-Firewall in Proxmox VE ermöglicht eine präzise Kontrolle des Datenverkehrs auf Netzwerkebene, indem sie Pakete basierend auf Kriterien wie Protokoll, Port, Quell- oder Ziel-IP filtert. Sie fungiert wie ein Sicherheitsfilter, der entscheidet, welche Datenpakete zwischen VNets (z. B. `vnet-web` und `vnet-db`) oder zu externen Netzwerken zugelassen werden. Ohne Firewall-Regeln erlaubt Inter-VNet-Routing (Modul 5) uneingeschränkten Datenverkehr, was ein Sicherheitsrisiko darstellt. Dieses Modul zeigt, wie Sie Firewall-Regeln einrichten, um z. B. nur SSH-Verkehr zuzulassen, und wie Sie die Konnektivität testen, um sicherzustellen, dass die Regeln korrekt funktionieren.

**Voraussetzungen**:
- Der `pve-sdn`-Dienst ist installiert und aktiv (Modul 2).
- Eine VLAN-Zone (z. B. `Zone-Web`) mit zwei VNets (`vnet-web`, VLAN 10, Subnetz `10.0.1.0/24`; `vnet-db`, VLAN 20, Subnetz `10.0.2.0/24`) ist erstellt (Modul 3).
- IP-Pools sind für beide VNets konfiguriert, idealerweise mit DHCP (Modul 4).
- Inter-VNet-Routing ist eingerichtet, sodass VMs in `vnet-web` (z. B. IP `10.0.1.101`) und `vnet-db` (z. B. IP `10.0.2.101`) sich pingen können (Modul 5).
- Mindestens zwei VMs sind erstellt und mit den VNets verbunden.
- SSH ist auf der VM in `vnet-db` installiert (`sudo apt install openssh-server`).
- Zugriff auf die Proxmox-GUI (`https://<Proxmox-IP>:8006`) und die Shell.

### 6.1 SDN-Firewall in Proxmox VE – Überblick
- **Was ist die SDN-Firewall?**: Die Firewall in Proxmox SDN arbeitet auf Netzwerkebene und nutzt Open vSwitch (OVS) sowie iptables/ebtables, um Datenpakete basierend auf definierten Regeln zu filtern. Sie wird über die Proxmox-GUI unter *Datacenter > SDN > VNets > Firewall* konfiguriert.
- **Warum ist sie wichtig?**: Ohne Firewall-Regeln erlaubt das Inter-VNet-Routing (Modul 5) jeglichen Datenverkehr zwischen VNets, was Sicherheitsrisiken birgt (z. B. unbefugter Zugriff). Die Firewall ermöglicht es, nur notwendigen Verkehr zuzulassen (z. B. TCP Port 22 für SSH) und alles andere zu blockieren.
- **Ebenen der Firewall**:
  - **Datacenter-Ebene**: Globale Regeln, die für alle Knoten gelten.
  - **Zone/VNet-Ebene**: Regeln für spezifische VNets (z. B. `vnet-db`), was für SDN typisch ist.
  - **VM-Ebene**: Regeln für einzelne VMs (weniger relevant für SDN, aber möglich).
- **Regelstruktur**:
  - **Aktion**: `Accept` (zulassen), `Drop` (verwerfen ohne Rückmeldung), `Reject` (ablehnen mit Rückmeldung).
  - **Protokoll**: z. B. TCP, UDP, ICMP.
  - **Quell-/Ziel-IP**: Einzelne IPs oder Subnetze (z. B. `10.0.1.0/24`).
  - **Port**: Zielport (z. B. 22 für SSH, 3306 für MySQL).
  - **Richtung**: `In` (eingehend), `Out` (ausgehend) oder `In/Out` (beide).
- **Beispiel-Szenario**: Sie möchten, dass eine VM in `vnet-web` (`10.0.1.101`) per SSH auf eine VM in `vnet-db` (`10.0.2.101`) zugreifen kann, aber anderer Verkehr (z. B. ICMP für `ping`) blockiert wird.

### 6.2 Detaillierte Konzepte
- **Firewall-Verarbeitung**: Regeln werden in der Reihenfolge ihrer Definition geprüft. Die erste zutreffende Regel bestimmt die Aktion. Ohne explizite Regeln gilt die Standardrichtlinie (oft `Drop`, wenn die Firewall aktiviert ist).
- **VNet-Firewall**: Regeln auf VNet-Ebene (z. B. für `vnet-db`) steuern den gesamten ein- und ausgehenden Datenverkehr eines VNets. Dies ist effizienter als VM-spezifische Regeln.
- **Default-Verhalten**: Nach Aktivierung der Firewall wird standardmäßig alles blockiert, was nicht explizit erlaubt ist (implizite `Drop`-Regel). Dies erfordert präzise Regeln, um notwendigen Verkehr zuzulassen.
- **ICMP und Troubleshooting**: ICMP (z. B. für `ping`) wird oft separat gefiltert. Wenn Sie `ping` für Tests verwenden, müssen Sie explizite ICMP-Regeln erstellen.
- **Logging**: Regeln können so konfiguriert werden, dass sie blockierte oder erlaubte Pakete protokollieren, was beim Debugging hilfreich ist.
- **Interaktion mit Inter-VNet-Routing**: Die Firewall wirkt nach dem Routing (Modul 5). Selbst wenn Routing konfiguriert ist, blockiert die Firewall den Verkehr, wenn keine passende Regel existiert.

### Praktische Übungen

#### Übung 1: Firewall-Regel erstellen
**Ziel**: Erstellen Sie eine Firewall-Regel, die SSH-Verkehr (TCP, Port 22) von `vnet-web` (`10.0.1.0/24`) nach `vnet-db` (`10.0.2.0/24`) erlaubt, während anderer Verkehr blockiert wird.

**Schritte**:
1. **Firewall für VNet aktivieren**:
   - Öffnen Sie die Proxmox-GUI und gehen Sie zu *Datacenter > SDN > VNets > vnet-db*.
   - Wählen Sie den Reiter *Firewall* und klicken Sie auf *Optionen*.
   - Setzen Sie *Enable Firewall* auf *Yes* und klicken Sie auf *OK*.
   - **Hinweis**: Dies aktiviert die Firewall für `vnet-db`, sodass nur explizit erlaubter Verkehr durchgelassen wird. Ohne aktive Firewall-Regeln wird alles blockiert.
2. **Firewall-Regel erstellen**:
   - In *Datacenter > SDN > VNets > vnet-db > Firewall*, klicken Sie auf *Erstellen*.
   - **Regel-Einstellungen**:
     - **Aktion**: `Accept`.
     - **Protokoll**: `TCP`.
     - **Ziel-Port**: `22` (für SSH).
     - **Quellnetzwerk**: `10.0.1.0/24` (Subnetz von `vnet-web`).
     - **Zielnetzwerk**: `10.0.2.0/24` (Subnetz von `vnet-db`).
     - **Richtung**: `In` (Eingehender Verkehr zu `vnet-db`).
     - **Enable**: Aktiviert (Checkbox gesetzt).
     - **Log**: `nolog` (oder `log` für Debugging, um Verkehr zu protokollieren).
     - **Kommentar** (optional): „Erlaube SSH von vnet-web zu vnet-db“.
   - Klicken Sie auf *Create*.
3. **Regel überprüfen**:
   - In der GUI sollte die Regel unter *vnet-db > Firewall* sichtbar sein.
   - In der Shell:
     ```bash
     cat /etc/pve/firewall/vnets/vnet-db.fw
     ```
     - **Erwartete Ausgabe**:
       ```plaintext
       [RULES]
       IN ACCEPT -source 10.0.1.0/24 -dest 10.0.2.0/24 -p tcp -dport 22 -log nolog
       ```
   - Prüfen Sie den Firewall-Status:
     ```bash
     pve-firewall status
     ```
     - **Erwartete Ausgabe**: `Status: enabled/running`.
4. **Fehlerbehebung**:
   - **Regel nicht erstellt**: Stellen Sie sicher, dass die Firewall für `vnet-db` aktiviert ist und `pve-sdn` läuft (`sudo systemctl status pve-sdn`).
   - **Regel wirkt nicht**: Überprüfen Sie die Reihenfolge der Regeln (GUI zeigt die Liste). Regeln werden von oben nach unten verarbeitet.
   - **Firewall blockiert alles**: Ohne explizite `Accept`-Regeln blockiert die aktivierte Firewall allen Verkehr. Fügen Sie ggf. eine temporäre Regel hinzu, um ICMP (für `ping`) zu testen:
     ```plaintext
     IN ACCEPT -source 10.0.1.0/24 -dest 10.0.2.0/24 -p icmp
     ```

#### Übung 2: Konnektivität testen
**Ziel**: Testen Sie die Firewall-Regel, indem Sie SSH von der VM in `vnet-web` zur VM in `vnet-db` ausführen und überprüfen, ob anderer Verkehr (z. B. ICMP) blockiert wird.

**Schritte**:
1. **Vorbereitung der VMs**:
   - Stellen Sie sicher, dass die VM in `vnet-db` (z. B. `10.0.2.101`) einen SSH-Server installiert hat:
     ```bash
     sudo apt update && sudo apt install openssh-server
     ```
   - Überprüfen Sie, ob der SSH-Dienst läuft:
     ```bash
     sudo systemctl status ssh
     ```
     - **Erwartete Ausgabe**: `active (running)`.
2. **SSH-Verbindung testen**:
   - Von der VM in `vnet-web` (z. B. `10.0.1.101`):
     ```bash
     ssh user@10.0.2.101
     ```
     - **Erfolg**: Sie werden zur Eingabe eines Passworts aufgefordert oder verbinden sich, wenn SSH-Schlüssel konfiguriert sind.
     - **Fehler**: Falls die Verbindung fehlschlägt, prüfen Sie:
       - Ist die Firewall-Regel korrekt? (`cat /etc/pve/firewall/vnets/vnet-db.fw`)
       - Ist der SSH-Dienst aktiv? (`sudo systemctl status ssh` auf der Ziel-VM)
       - Ist die VM-Firewall aktiv? Deaktivieren Sie sie vorübergehend:
         ```bash
         sudo ufw disable
         ```
3. **Anderen Verkehr testen**:
   - Von der VM in `vnet-web`:
     ```bash
     ping 10.0.2.101
     ```
     - **Erwartete Ausgabe**: Keine Antwort („Destination Host Unreachable“), da ICMP nicht erlaubt ist.
   - Dies bestätigt, dass die Firewall nur SSH (TCP Port 22) zulässt und anderen Verkehr blockiert.
4. **Logging aktivieren (optional)**:
   - Bearbeiten Sie die Regel in der GUI (*vnet-db > Firewall > Regel auswählen > Bearbeiten*).
   - Setzen Sie *Log* auf `log` und wenden Sie die Änderungen an.
   - Testen Sie erneut den SSH-Verkehr und prüfen Sie die Logs:
     ```bash
     journalctl -u pve-firewall
     ```
     - **Erwartete Ausgabe**: Zeigt akzeptierte Pakete für TCP Port 22 von `10.0.1.101` nach `10.0.2.101`.
5. **Fehlerbehebung**:
   - **SSH fehlschlägt**: Überprüfen Sie die Firewall-Regel (Quell-/Ziel-IP, Port, Protokoll). Stellen Sie sicher, dass die Richtung `In` ist und die Ziel-VM SSH erlaubt.
   - **Ping funktioniert unerwartet**: Eine andere Regel (z. B. auf Datacenter-Ebene) könnte ICMP erlauben. Prüfen Sie *Datacenter > Firewall* oder deaktivieren Sie andere Regeln temporär.
   - **Keine Logs**: Stellen Sie sicher, dass Logging aktiviert ist und `pve-firewall` läuft.

**Erweiterung**: Erstellen Sie eine zusätzliche Regel, um ICMP (für `ping`) von `vnet-web` nach `vnet-db` zu erlauben:
- In *vnet-db > Firewall*:
  - **Aktion**: `Accept`.
  - **Protokoll**: `ICMP`.
  - **Quellnetzwerk**: `10.0.1.0/24`.
  - **Zielnetzwerk**: `10.0.2.0/24`.
  - **Richtung**: `In`.
- Testen Sie erneut:
  ```bash
  ping 10.0.2.101
  ```
  - **Erfolg**: Antworten wie `64 bytes from 10.0.2.101: icmp_seq=1 ttl=64 time=0.4 ms`.

### 6.3 Häufige Probleme und Fehlerbehebung
- **Problem: Firewall blockiert alles**:
  - Lösung: Stellen Sie sicher, dass die Firewall-Regel korrekt definiert ist (richtige Quell-/Ziel-IP, Port, Protokoll). Prüfen Sie die Standardrichtlinie (`Drop`) und fügen Sie explizite `Accept`-Regeln hinzu.
- **Problem: SSH funktioniert nicht trotz Regel**:
  - Lösung: Überprüfen Sie, ob der SSH-Dienst auf der Ziel-VM läuft (`sudo systemctl status ssh`). Deaktivieren Sie die VM-interne Firewall (`sudo ufw disable`) für Tests.
- **Problem: Unerwarteter Verkehr wird zugelassen**:
  - Lösung: Prüfen Sie alle Firewall-Regeln auf VNet- und Datacenter-Ebene. Regeln auf höherer Ebene (Datacenter) können VNet-Regeln überschreiben.
- **Problem: Keine Logs sichtbar**:
  - Lösung: Aktivieren Sie Logging in der Regel und prüfen Sie `journalctl -u pve-firewall`. Stellen Sie sicher, dass `pve-firewall` läuft.

### 6.4 Vorbereitung auf die nächsten Module
- **Was kommt als Nächstes?**: In Modul 7 lernen Sie Troubleshooting-Techniken für SDN, um Fehler wie blockierte Pakete oder falsche Firewall-Regeln zu identifizieren. Modul 8 verbindet VNets mit externen Netzwerken (z. B. Internet).
- **Empfehlung**: Experimentieren Sie mit weiteren Firewall-Regeln, z. B. um HTTP-Verkehr (TCP Port 80) oder MySQL-Verkehr (TCP Port 3306) zwischen VNets zu erlauben. Testen Sie die Auswirkungen von `Drop`-Regeln, um unerwünschten Verkehr gezielt zu blockieren.
- **Dokumentation**: Notieren Sie die Firewall-Regeln (z. B. Protokoll, Port, Quell-/Ziel-IP) und erstellen Sie ein Diagramm, das zeigt, welcher Verkehr zwischen `vnet-web` und `vnet-db` erlaubt/blockiert ist.

**Fragen zur Selbstreflexion**:
1. Warum ist es wichtig, die Firewall auf VNet-Ebene statt nur auf VM-Ebene zu konfigurieren?
2. Wie können Sie überprüfen, ob ein Paket von der Firewall blockiert wird?
3. Was passiert, wenn Sie die Richtung einer Regel von `In` auf `Out` ändern?

Falls Sie eine Visualisierung (z. B. ein Diagramm der Firewall-Regeln mit ChartJS) oder weitere Details (z. B. zu Logging oder komplexeren Regeln) wünschen, lassen Sie es mich wissen!

**[Modul 7: SDN Troubleshooting](Modul07_Troubleshooting.md)**   oder **[zurück zur Übersicht](00_Übersicht_SDN.md)**