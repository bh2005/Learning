# Praxisorientierte Anleitung: Netzwerkübungen mit Bash (Subnetting, IP-Adressierung, Ping-Test)

## Einführung
Netzwerkadministration ist eine Schlüsselkompetenz für Systemadministratoren, und Bash bietet leistungsstarke Werkzeuge, um Netzwerkaufgaben wie Subnetting, IP-Adressierung und Ping-Tests zu bewältigen. Diese Anleitung führt Anfänger durch praktische Übungen zu **Subnetting**, **IP-Adressierung** und **Ping-Tests** mit Bash-Befehlen. Die Übungen konzentrieren sich auf das Berechnen von Subnetzen, das Zuweisen von IP-Adressen und das Testen der Netzwerkkonnektivität. Eine **Spielerei** zeigt, wie du die Ergebnisse in einer Markdown-Tabelle zusammenfasst, um die Verbindung zu vorherigen Themen (z. B. Markdown-Ausgabe) herzustellen. Durch diese Übungen lernst du, grundlegende Netzwerkaufgaben in Bash zu meistern.

**Voraussetzungen**:
- Ein System mit Linux (z. B. Ubuntu 22.04, Debian) oder macOS; Windows-Nutzer können WSL2 (Windows Subsystem for Linux) verwenden.
- Ein Terminal (z. B. Bash unter Linux/macOS, PowerShell mit WSL2 unter Windows).
- Netzwerktools installiert (z. B. `ipcalc` für Subnetting, `ping` für Konnektivitätstests):
  - Ubuntu/Debian: `sudo apt install ipcalc iputils-ping`
  - macOS: `brew install ipcalc` (`ping` ist vorinstalliert)
- Grundkenntnisse in Bash (Befehle, Skripte) und Netzwerkkonzepten (IP-Adressen, Subnetze).
- Sichere Testumgebung (z. B. `$HOME/network_tests` oder `~/network_tests`).
- Zugriff auf ein lokales Netzwerk mit Geräten oder öffentliche IP-Adressen (z. B. `8.8.8.8`) zum Testen.

## Grundlegende Befehle
Hier sind die wichtigsten Bash-Befehle für die Netzwerkübungen:

1. **Subnetting**:
   - `ipcalc <Netzwerkadresse>/<CIDR>`: Berechnet Subnetzdetails (z. B. Netzwerkadresse, Broadcast, Hostbereich).
   - `bc`: Führt mathematische Berechnungen durch (z. B. Anzahl der Hosts).
2. **IP-Adressierung**:
   - `ip addr show`: Zeigt die IP-Adressen des Systems.
   - `sudo ip addr add <IP>/<CIDR> dev <Interface>`: Weist eine IP-Adresse zu.
   - `echo` und `>>`: Dokumentiert Zuweisungen in einer Datei.
3. **Ping-Test**:
   - `ping -c <Anzahl> <IP>`: Sendet ICMP-Pakete an eine IP-Adresse.
   - `grep` und `awk`: Analysiert die Ausgabe von `ping`.
4. **Nützliche Zusatzbefehle**:
   - `man ipcalc`: Zeigt die Dokumentation für `ipcalc`.
   - `man ping`: Zeigt die Dokumentation für `ping`.
   - `whoami`: Prüft den aktuellen Benutzer (wichtig für `sudo`).
   - `date`: Fügt Zeitstempel in Protokollen hinzu.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Subnetting
**Ziel**: Berechne die Subnetze für das Netzwerk `192.168.1.0/24` und bestimme die Anzahl der Hosts pro Subnetz.

1. **Schritt 1**: Erstelle ein Testverzeichnis:
   ```bash
   mkdir network_tests
   cd network_tests
   ```

2. **Schritt 2**: Installiere `ipcalc`:
   ```bash
   sudo apt install ipcalc  # Ubuntu/Debian
   # oder: brew install ipcalc  # macOS
   ```

3. **Schritt 3**: Berechne Subnetze für `192.168.1.0/24` mit einer neuen Subnetzmaske von `/26` (4 Subnetze):
   ```bash
   ipcalc 192.168.1.0/24 -s 64
   ```
   **Erklärung**: `-s 64` teilt das Netzwerk in Subnetze mit jeweils 64 Adressen (entspricht `/26`, da 2^(32-26) = 64).

   Die Ausgabe zeigt z. B.:
   ```
   Address:   192.168.1.0
   Netmask:   255.255.255.0 = 24
   Network:   192.168.1.0/24
   HostMin:   192.168.1.1
   HostMax:   192.168.1.254
   Broadcast: 192.168.1.255
   Hosts/Net: 254

   Subnets:
   1. Address:   192.168.1.0
      Netmask:   255.255.255.192 = 26
      Network:   192.168.1.0/26
      HostMin:   192.168.1.1
      HostMax:   192.168.1.62
      Broadcast: 192.168.1.63
      Hosts/Net: 62

   2. Address:   192.168.1.64
      ...
   ```

4. **Schritt 4**: Berechne die Anzahl der Hosts pro Subnetz manuell:
   ```bash
   echo "2^(32-26)-2" | bc
   ```
   **Ausgabe**: `62` (64 Adressen minus Netzwerk- und Broadcast-Adresse).

5. **Schritt 5**: Speichere die Ergebnisse in einer Datei:
   ```bash
   ipcalc 192.168.1.0/24 -s 64 > subnets.txt
   echo "Hosts pro Subnetz: $((2**(32-26)-2))" >> subnets.txt
   cat subnets.txt
   ```

**Reflexion**: Warum ist Subnetting für Netzwerkorganisation wichtig? Nutze `man ipcalc` und überlege, wie du Subnetze für andere Netzwerke (z. B. `10.0.0.0/16`) berechnen kannst.

### Übung 2: IP-Adressierung
**Ziel**: Weise IP-Adressen manuell an Geräte in einem kleinen Netzwerk zu und dokumentiere die Zuweisungen.

1. **Schritt 1**: Erstelle ein Skript zur Dokumentation der IP-Zuweisungen:
   ```bash
   nano assign_ips.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash
   # Skript zur Dokumentation von IP-Zuweisungen in einem Netzwerk

   OUTPUT_FILE="ip_assignments.txt"
   echo "IP-Zuweisungen für Netzwerk 192.168.1.0/26" > $OUTPUT_FILE
   echo "Erstellt am: $(date)" >> $OUTPUT_FILE
   echo "----------------------------------------" >> $OUTPUT_FILE

   # Beispielgeräte
   devices=("Router" "Server" "Workstation1" "Workstation2")
   ip_base="192.168.1"
   start_ip=1

   for device in "${devices[@]}"; do
       ip="$ip_base.$start_ip/26"
       echo "Zuweisung: $device -> $ip" >> $OUTPUT_FILE
       # Simuliere Zuweisung (entferne Kommentar für echte Zuweisung, benötigt sudo)
       # sudo ip addr add $ip dev eth0
       ((start_ip++))
   done

   echo "Zuweisungen abgeschlossen. Ergebnisse in $OUTPUT_FILE."
   cat $OUTPUT_FILE
   ```
   Speichere und schließe.

2. **Schritt 2**: Mache das Skript ausführbar und führe es aus:
   ```bash
   chmod +x assign_ips.sh
   ./assign_ips.sh
   ```

3. **Schritt 3**: Überprüfe die Ausgabe:
   ```bash
   cat ip_assignments.txt
   ```
   Die Ausgabe sollte so aussehen:
   ```
   IP-Zuweisungen für Netzwerk 192.168.1.0/26
   Erstellt am: Fri Sep  5 10:36:00 CEST 2025
   ----------------------------------------
   Zuweisung: Router -> 192.168.1.1/26
   Zuweisung: Server -> 192.168.1.2/26
   Zuweisung: Workstation1 -> 192.168.1.3/26
   Zuweisung: Workstation2 -> 192.168.1.4/26
   ```

**Reflexion**: Warum ist eine strukturierte IP-Zuweisung wichtig? Nutze `man ip` und überlege, wie du dynamische Zuweisungen mit DHCP kombinieren kannst.

### Übung 3: Ping-Test und Spielerei
**Ziel**: Führe Ping-Tests zu IP-Adressen durch, analysiere die Ergebnisse und erstelle eine Markdown-Tabelle.

1. **Schritt 1**: Erstelle ein Skript für Ping-Tests:
   ```bash
   nano ping_test.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash
   # Skript für Ping-Tests und Markdown-Ausgabe

   OUTPUT_FILE="ping_results.md"
   echo "# Ping-Test Ergebnisse" > $OUTPUT_FILE
   echo "Erstellt am: $(date)" >> $OUTPUT_FILE
   echo "" >> $OUTPUT_FILE
   echo "| IP-Adresse | Status | Durchschnittliche Latenz (ms) | Paketverlust (%) |" >> $OUTPUT_FILE
   echo "|------------|--------|------------------------------|-------------------|" >> $OUTPUT_FILE

   # Test-IPs (lokal und öffentlich)
   ips=("192.168.1.1" "8.8.8.8" "1.1.1.1")

   for ip in "${ips[@]}"; do
       echo "Teste $ip..."
       # Führe Ping-Test durch (4 Pakete)
       ping_result=$(ping -c 4 $ip 2>/dev/null)
       if [ $? -eq 0 ]; then
           status="Erreichbar"
           # Extrahiere Latenz und Paketverlust
           latency=$(echo "$ping_result" | grep 'rtt min/avg/max' | awk -F'/' '{print $5}')
           packet_loss=$(echo "$ping_result" | grep 'packet loss' | awk '{print $6}')
       else
           status="Nicht erreichbar"
           latency="N/A"
           packet_loss="100%"
       fi
       echo "| $ip | $status | $latency | $packet_loss |" >> $OUTPUT_FILE
   done

   echo "Ping-Tests abgeschlossen. Ergebnisse in $OUTPUT_FILE."
   cat $OUTPUT_FILE
   ```
   Speichere und schließe.

2. **Schritt 2**: Mache das Skript ausführbar und führe es aus:
   ```bash
   chmod +x ping_test.sh
   ./ping_test.sh
   ```

3. **Spielerei**: Überprüfe die Markdown-Ausgabe:
   ```bash
   cat ping_results.md
   ```
   Die Ausgabe könnte so aussehen (abhängig von deinem Netzwerk):
   ```
   # Ping-Test Ergebnisse
   Erstellt am: Fri Sep  5 10:36:00 CEST 2025

   | IP-Adresse   | Status        | Durchschnittliche Latenz (ms) | Paketverlust (%) |
   |--------------|---------------|------------------------------|-------------------|
   | 192.168.1.1  | Erreichbar    | 0.123                | 0%                |
   | 8.8.8.8      | Erreichbar    | 20.456               | 0%                |
   | 1.1.1.1      | Erreichbar    | 18.789               | 0%                |
   ```

4. **Schritt 3**: Analysiere die Ergebnisse:
   ```bash
   grep "Nicht erreichbar" ping_results.md
   ```
   Wenn keine Ausgabe erscheint, sind alle IPs erreichbar. Andernfalls überprüfe die Netzwerkkonfiguration (z. B. Firewall, Router).

**Reflexion**: Wie helfen Ping-Tests bei der Fehlersuche im Netzwerk? Nutze `man ping` und überlege, wie du die Ergebnisse mit `jq` oder `awk` weiter analysieren kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Netzwerkkonzepte in Bash zu verinnerlichen.
- **Sicheres Testen**: Verwende eine Testumgebung und vermeide Änderungen an produktiven Netzwerken.
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze `man ipcalc` oder `man ping` für Details.
- **Effiziente Entwicklung**: Nutze Skripte für wiederholbare Aufgaben, `ipcalc` für Subnetting und `grep`/`awk` für Analysen.
- **Kombiniere Tools**: Integriere `nmap` für Netzwerkscans oder `curl` für API-Tests in Netzwerken.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Hinzufügen von Zeitstempeln oder automatischen Berichten.

## Fazit
Mit diesen Übungen hast du gelernt, Subnetting mit `ipcalc` durchzuführen, IP-Adressen zuzuweisen und Ping-Tests in Bash zu analysieren. Die Spielerei zeigt, wie du Ergebnisse in einer Markdown-Tabelle zusammenfasst. Vertiefe dein Wissen, indem du fortgeschrittene Netzwerktools (z. B. `nmap`, `tcpdump`) oder Skripte für automatisierte Netzwerküberwachung einbindest. Wenn du ein spezifisches Thema (z. B. Netzwerkscans oder Firewall-Konfiguration) vertiefen möchtest, lass es mich wissen!
