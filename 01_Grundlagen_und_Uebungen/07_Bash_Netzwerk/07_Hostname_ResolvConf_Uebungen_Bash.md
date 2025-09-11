# Praxisorientierte Anleitung: Übungen zu /etc/hostname und /etc/resolv.conf mit Bash

## Einführung
Die Dateien **/etc/hostname** und **/etc/resolv.conf** sind zentrale Konfigurationsdateien in Linux-Systemen für die Verwaltung von Hostnamen und DNS-Auflösung. `/etc/hostname` speichert den Hostnamen des Systems, während `/etc/resolv.conf` die DNS-Server und Suchdomänen definiert. Diese Anleitung führt Anfänger durch praktische Übungen zur **Abfrage und Bearbeitung von /etc/hostname**, **Konfiguration von /etc/resolv.conf**, **Validierung der Dateien** und **Dokumentation der Änderungen**. Eine **Spielerei** zeigt, wie du die Konfigurationen in einer Markdown-Tabelle zusammenfasst, um die Verbindung zu vorherigen Themen (z. B. Markdown-Ausgabe) herzustellen. Durch diese Übungen lernst du, diese Dateien in einer Bash-Umgebung zu meistern.

**Voraussetzungen**:
- Ein System mit Linux (z. B. Ubuntu 22.04, Debian); Windows-Nutzer können WSL2 verwenden; macOS ist teilweise kompatibel (ähnliche Dateien, aber andere Pfade).
- Ein Terminal (z. B. Bash unter Linux, PowerShell mit WSL2 unter Windows).
- Netzwerktools installiert:
  - Ubuntu/Debian: `sudo apt install dnsutils` (für `dig`, `nslookup`)
  - macOS: `brew install bind` (für `dig`, `nslookup`)
- Grundkenntnisse in Bash (Befehle, Skripte) und Netzwerkkonzepten (Hostnamen, DNS).
- Sichere Testumgebung (z. B. `$HOME/config_tests` oder `~/config_tests`).
- Root-Zugriff für Konfigurationen (via `sudo`).
- Internetzugriff für DNS-Abfragen (z. B. `8.8.8.8` als DNS-Server).

## Grundlegende Befehle
Hier sind die wichtigsten Bash-Befehle für die Übungen zu `/etc/hostname` und `/etc/resolv.conf`:

1. **/etc/hostname**:
   - `cat /etc/hostname`: Zeigt den aktuellen Hostnamen.
   - `sudo hostnamectl set-hostname <name>`: Ändert den Hostnamen permanent.
   - `sudo nano /etc/hostname`: Bearbeitet die Datei direkt.
2. **/etc/resolv.conf**:
   - `cat /etc/resolv.conf`: Zeigt die DNS-Konfiguration.
   - `sudo nano /etc/resolv.conf`: Bearbeitet die DNS-Server und Suchdomänen.
   - `dig <domain>`: Testet die DNS-Auflösung mit den konfigurierten Servern.
3. **Validierung**:
   - `grep` und reguläre Ausdrücke: Prüfen den Inhalt der Dateien.
   - `hostname -f`: Überprüft den Fully Qualified Domain Name (FQDN).
4. **Dokumentation**:
   - `echo` und `>>`: Protokolliert Änderungen in einer Datei.
   - `date`: Fügt Zeitstempel hinzu.
5. **Nützliche Zusatzbefehle**:
   - `man hostnamectl`: Dokumentation für `hostnamectl`.
   - `man resolv.conf`: Dokumentation für `resolv.conf`.
   - `nslookup <domain>`: Testet die DNS-Auflösung.
   - `sudo systemctl restart systemd-resolved`: Startet den Resolver-Dienst neu (falls verwendet).

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: /etc/hostname abfragen und bearbeiten
**Ziel**: Frage den Hostnamen ab, ändere ihn temporär und permanent, und dokumentiere die Änderungen.

1. **Schritt 1**: Erstelle ein Testverzeichnis:
   ```bash
   mkdir config_tests
   cd config_tests
   ```

2. **Schritt 2**: Zeige den aktuellen Hostnamen:
   ```bash
   cat /etc/hostname
   hostname
   hostname -f
   ```
   **Beispielausgabe**:
   ```
   myhost
   myhost
   myhost.local
   ```

3. **Schritt 3**: Ändere den Hostnamen temporär:
   ```bash
   sudo hostname testhost
   hostname
   ```
   **Ausgabe**: `testhost`

4. **Schritt 4**: Ändere den Hostnamen permanent:
   ```bash
   sudo hostnamectl set-hostname testhost.local
   cat /etc/hostname
   ```
   **Ausgabe**: `testhost.local`

5. **Schritt 5**: Protokolliere die Änderungen:
   ```bash
   echo "Hostname-Abfrage und Änderung am $(date)" > config_log.txt
   echo "Alter Hostname: $(cat /etc/hostname)" >> config_log.txt
   echo "Neuer Hostname: testhost.local" >> config_log.txt
   echo "FQDN: $(hostname -f)" >> config_log.txt
   cat config_log.txt
   ```

**Reflexion**: Warum ist `/etc/hostname` für die Systemidentität wichtig? Nutze `man hostnamectl` und überlege, wie Änderungen Netzwerkdienste beeinflussen.

### Übung 2: /etc/resolv.conf konfigurieren
**Ziel**: Konfiguriere die DNS-Server in `/etc/resolv.conf` und teste die Auflösung.

1. **Schritt 1**: Zeige die aktuelle DNS-Konfiguration:
   ```bash
   cat /etc/resolv.conf
   ```
   **Beispielausgabe**:
   ```
   nameserver 8.8.8.8
   nameserver 1.1.1.1
   search mydomain.local
   ```

2. **Schritt 2**: Bearbeite `/etc/resolv.conf` (Hinweis: Bei `systemd-resolved` wird die Datei oft dynamisch generiert):
   ```bash
   sudo nano /etc/resolv.conf
   ```
   Setze z. B. folgende Konfiguration:
   ```
   nameserver 8.8.8.8
   nameserver 1.1.1.1
   search testdomain.local
   ```
   Speichere und schließe.

3. **Schritt 3**: Teste die DNS-Auflösung:
   ```bash
   dig google.com
   nslookup example.com
   ```

4. **Schritt 4**: Falls `systemd-resolved` verwendet wird, konfiguriere es:
   ```bash
   sudo systemctl restart systemd-resolved
   cat /etc/systemd/resolved.conf
   ```
   Bearbeite bei Bedarf `/etc/systemd/resolved.conf`:
   ```bash
   sudo nano /etc/systemd/resolved.conf
   ```
   Füge hinzu:
   ```
   [Resolve]
   DNS=8.8.8.8 1.1.1.1
   Domains=testdomain.local
   ```
   Starte den Dienst neu:
   ```bash
   sudo systemctl restart systemd-resolved
   ```

5. **Schritt 5**: Protokolliere die Änderungen:
   ```bash
   echo "resolv.conf geändert am $(date)" >> config_log.txt
   cat /etc/resolv.conf >> config_log.txt
   cat config_log.txt
   ```

**Reflexion**: Wie beeinflusst `/etc/resolv.conf` die DNS-Auflösung? Nutze `man resolv.conf` und überlege, wie du lokale DNS-Server hinzufügst.

### Übung 3: Validierung von /etc/hostname und /etc/resolv.conf
**Ziel**: Entwickle ein Skript, das die Inhalte der Dateien auf Korrektheit prüft.

1. **Schritt 1**: Erstelle ein Validierungsskript:
   ```bash
   nano validate_configs.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash
   # Skript zur Validierung von /etc/hostname und /etc/resolv.conf

   OUTPUT_FILE="validate_configs.txt"

   echo "Validierung von Konfigurationsdateien am $(date)" > $OUTPUT_FILE

   # Validierung von /etc/hostname
   hostname=$(cat /etc/hostname)
   if echo "$hostname" | grep -qE '^[a-zA-Z0-9-]{1,63}$'; then
       echo "Hostname ($hostname): Gültig" >> $OUTPUT_FILE
   else
       echo "Hostname ($hostname): Ungültig (Sonderzeichen oder Länge)" >> $OUTPUT_FILE
   fi

   # Validierung von /etc/resolv.conf
   if [ -f /etc/resolv.conf ]; then
       nameservers=$(grep '^nameserver' /etc/resolv.conf | awk '{print $2}')
       if [ -n "$nameservers" ]; then
           echo "resolv.conf: Gültige Nameserver gefunden: $nameservers" >> $OUTPUT_FILE
           for ns in $nameservers; do
               if ping -c 1 $ns > /dev/null 2>&1; then
                   echo "Nameserver $ns: Erreichbar" >> $OUTPUT_FILE
               else
                   echo "Nameserver $ns: Nicht erreichbar" >> $OUTPUT_FILE
               fi
           done
       else
           echo "resolv.conf: Keine Nameserver definiert" >> $OUTPUT_FILE
       fi
   else
       echo "resolv.conf: Datei nicht gefunden" >> $OUTPUT_FILE
   fi

   cat $OUTPUT_FILE
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   chmod +x validate_configs.sh
   ./validate_configs.sh
   ```
   **Beispielausgabe**:
   ```
   Validierung von Konfigurationsdateien am Fri Sep  5 11:05:00 CEST 2025
   Hostname (testhost): Gültig
   resolv.conf: Gültige Nameserver gefunden: 8.8.8.8 1.1.1.1
   Nameserver 8.8.8.8: Erreichbar
   Nameserver 1.1.1.1: Erreichbar
   ```

**Reflexion**: Warum ist die Validierung von Konfigurationsdateien wichtig? Nutze `man grep` und überlege, wie du erweiterte Prüfungen (z. B. für `search`-Domänen) implementierst.

### Übung 4: Dokumentation und Spielerei
**Ziel**: Dokumentiere die Konfigurationen von `/etc/hostname` und `/etc/resolv.conf` und erstelle eine Markdown-Tabelle.

1. **Schritt 1**: Erstelle ein Skript zur Dokumentation:
   ```bash
   nano document_configs.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash
   # Skript zur Dokumentation und Markdown-Ausgabe von Konfigurationsdateien

   OUTPUT_FILE="config_results.md"

   echo "# Konfigurationsdateien Ergebnisse" > $OUTPUT_FILE
   echo "Erstellt am: $(date)" >> $OUTPUT_FILE
   echo "" >> $OUTPUT_FILE
   echo "| Datei | Inhalt | Status | Details |" >> $OUTPUT_FILE
   echo "|-------|--------|--------|---------|" >> $OUTPUT_FILE

   # Dokumentation von /etc/hostname
   if [ -f /etc/hostname ]; then
       hostname=$(cat /etc/hostname)
       if echo "$hostname" | grep -qE '^[a-zA-Z0-9-]{1,63}$'; then
           hostname_status="Gültig"
           hostname_details="FQDN: $(hostname -f)"
       else
           hostname_status="Ungültig"
           hostname_details="Ungültiges Format"
       fi
       echo "| /etc/hostname | $hostname | $hostname_status | $hostname_details |" >> $OUTPUT_FILE
   else
       echo "| /etc/hostname | Nicht gefunden | Fehler | Datei fehlt |" >> $OUTPUT_FILE
   fi

   # Dokumentation von /etc/resolv.conf
   if [ -f /etc/resolv.conf ]; then
       nameservers=$(grep '^nameserver' /etc/resolv.conf | awk '{print $2}' | tr '\n' ' ')
       search_domain=$(grep '^search' /etc/resolv.conf | awk '{print $2}')
       if [ -n "$nameservers" ]; then
           resolv_status="Gültig"
           resolv_details="Nameserver: $nameservers, Search: ${search_domain:-Keine}"
       else
           resolv_status="Ungültig"
           resolv_details="Keine Nameserver definiert"
       fi
       echo "| /etc/resolv.conf | Nameserver: $nameservers | $resolv_status | $resolv_details |" >> $OUTPUT_FILE
   else
       echo "| /etc/resolv.conf | Nicht gefunden | Fehler | Datei fehlt |" >> $OUTPUT_FILE
   fi

   echo "Dokumentation abgeschlossen. Ergebnisse in $OUTPUT_FILE."
   cat $OUTPUT_FILE
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   chmod +x document_configs.sh
   ./document_configs.sh
   ```

3. **Spielerei**: Überprüfe die Markdown-Ausgabe:
   ```bash
   cat config_results.md
   ```
   Die Ausgabe könnte so aussehen:
   ```
   # Konfigurationsdateien Ergebnisse
   Erstellt am: Fri Sep  5 11:05:00 CEST 2025

   | Datei            | Inhalt                     | Status | Details                             |
   |------------------|----------------------------|--------|-------------------------------------|
   | /etc/hostname    | testhost                   | Gültig | FQDN: testhost.local                |
   | /etc/resolv.conf | Nameserver: 8.8.8.8 1.1.1.1 | Gültig | Nameserver: 8.8.8.8 1.1.1.1, Search: testdomain.local |
   ```

**Reflexion**: Wie hilft die Dokumentation von Konfigurationsdateien bei der Fehlersuche? Nutze `man resolv.conf` und überlege, wie du Änderungen mit Git versionierst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um `/etc/hostname` und `/etc/resolv.conf` zu verinnerlichen.
- **Sicheres Testen**: Verwende eine Testumgebung und sichere Konfigurationsdateien vor Änderungen (`sudo cp /etc/hostname /etc/hostname.bak`).
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze `man hostnamectl` oder `man resolv.conf` für Details.
- **Effiziente Entwicklung**: Nutze `hostnamectl` für sichere Hostnamen-Änderungen, Skripte für Automatisierung und `dig` für DNS-Tests.
- **Kombiniere Tools**: Integriere `ansible` für automatisierte Konfigurationen oder `nmap` für Netzwerkscans.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Hinzufügen von Tests für lokale DNS-Server oder Validierungsregeln.

## Fazit
Mit diesen Übungen hast du gelernt, `/etc/hostname` und `/etc/resolv.conf` abzufragen, zu bearbeiten, zu validieren und zu dokumentieren. Die Spielerei zeigt, wie du Konfigurationen in einer Markdown-Tabelle zusammenfasst. Vertiefe dein Wissen, indem du fortgeschrittene Themen (z. B. dynamische DNS, systemd-resolved) oder Tools wie `dnsmasq` ausprobierst. Wenn du ein spezifisches Thema (z. B. Resolver-Caching oder Konfigurationsautomatisierung) vertiefen möchtest, lass es mich wissen!
