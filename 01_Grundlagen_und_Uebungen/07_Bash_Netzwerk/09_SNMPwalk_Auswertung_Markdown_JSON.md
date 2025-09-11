# Praxisorientierte Anleitung: Auswertung eines gespeicherten SNMPwalk (Cisco-Switch) in Markdown und JSON

## Einführung
Ein gespeicherter SNMPwalk enthält umfangreiche Informationen über ein Netzwerkgerät, wie z. B. einen Cisco-Switch, in Form von OIDs (Object Identifiers) und deren Werten. Diese Daten können mit Bash-Tools wie `grep`, `awk` und `jq` analysiert, in Markdown-Tabellen formatiert und in JSON konvertiert werden, um sie übersichtlich darzustellen oder für weitere Verarbeitung zu nutzen. Diese Anleitung führt Anfänger durch praktische Übungen zur **Vorbereitung eines gespeicherten SNMPwalk**, **Auswertung von Systeminformationen**, **Auswertung von Netzwerk-Interfaces**, **Formatierung in Markdown-Tabellen** und **Konvertierung in JSON**. Eine **Spielerei** zeigt, wie du die Ergebnisse in einem Markdown-Dokument mit eingebettetem JSON visualisierst. Die Übungen sind auf einem Debian-basierten System ausführbar und verwenden typische Cisco-OIDs (z. B. `1.3.6.1.2.1.1` für Systeminformationen, `1.3.6.1.2.1.2.2` für Interfaces).

**Voraussetzungen**:
- Ein Debian-basiertes System (z. B. Ubuntu 22.04, Debian 11); Windows-Nutzer können WSL2 verwenden; macOS ist kompatibel.
- Ein Terminal (z. B. Bash unter Linux).
- Installierte Tools:
  - `jq` für JSON-Verarbeitung: `sudo apt install jq`
  - `snmp` für Kontext (falls du den SNMPwalk selbst erstellst): `sudo apt install snmp`
- Eine gespeicherte SNMPwalk-Datei (z. B. `snmpwalk_output.txt`) mit Daten eines Cisco-Switches.
- Grundkenntnisse in Bash (Befehle, Skripte), Netzwerktechnik (SNMP, OIDs) und JSON.
- Sichere Testumgebung (z. B. `$HOME/snmp_analysis` oder `~/snmp_analysis`).
- Optional: Zugriff auf einen Cisco-Switch für Kontext (z. B. über `snmpwalk -v 2c -c public <IP> 1.3.6.1.2.1`).

## Beispiel-SNMPwalk-Datei
Für diese Übungen nehmen wir an, dass du eine Datei `snmpwalk_output.txt` hast, die durch einen Befehl wie `snmpwalk -v 2c -c public <Switch-IP> 1.3.6.1.2.1 > snmpwalk_output.txt` erstellt wurde. Ein Auszug könnte so aussehen:
```
SNMPv2-MIB::sysDescr.0 = STRING: Cisco IOS Software, C2960X Software (C2960X-UNIVERSALK9-M), Version 15.2(2)E6
SNMPv2-MIB::sysName.0 = STRING: Switch01
SNMPv2-MIB::sysUpTime.0 = Timeticks: (12345678) 1 day, 10:17:36.78
IF-MIB::ifDescr.1 = STRING: GigabitEthernet0/1
IF-MIB::ifDescr.2 = STRING: GigabitEthernet0/2
IF-MIB::ifInOctets.1 = Counter32: 123456789
IF-MIB::ifOutOctets.1 = Counter32: 987654321
IF-MIB::ifInOctets.2 = Counter32: 456789123
IF-MIB::ifOutOctets.2 = Counter32: 321654987
```

## Grundlegende Befehle
Hier sind die wichtigsten Bash-Befehle für die Auswertung eines gespeicherten SNMPwalk:

1. **Daten vorbereiten und filtern**:
   - `grep <Muster> <Datei>`: Filtert spezifische OIDs oder Werte.
   - `awk '{print $X}'`: Extrahiert Spalten aus der Ausgabe.
2. **Markdown-Tabellen erstellen**:
   - `echo "| ... | ... |"` : Erstellt Markdown-Tabellenzeilen.
3. **JSON konvertieren**:
   - `jq -R '.'`: Verarbeitet rohe Textzeilen in JSON.
   - `jq -n '[...]'`: Erstellt strukturierte JSON-Objekte.
4. **Nützliche Zusatzbefehle**:
   - `cat <Datei>`: Zeigt den Inhalt der Datei.
   - `man grep`, `man awk`, `man jq`: Dokumentation für die Tools.
   - `date`: Fügt Zeitstempel in Protokollen hinzu.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Vorbereitung der SNMPwalk-Daten
**Ziel**: Bereite die gespeicherte SNMPwalk-Datei vor und überprüfe ihren Inhalt.

1. **Schritt 1**: Erstelle ein Testverzeichnis und kopiere die SNMPwalk-Datei:
   ```bash
   mkdir snmp_analysis
   cd snmp_analysis
   # Kopiere oder erstelle die Datei (z. B. mit einem Editor oder snmpwalk)
   # Beispiel: nano snmpwalk_output.txt (füge obigen Auszug ein)
   ```

2. **Schritt 2**: Überprüfe den Inhalt der Datei:
   ```bash
   cat snmpwalk_output.txt
   ```

3. **Schritt 3**: Protokolliere die Vorbereitung:
   ```bash
   echo "SNMPwalk-Daten vorbereitet am $(date)" > analysis_log.txt
   wc -l snmpwalk_output.txt >> analysis_log.txt
   cat analysis_log.txt
   ```
   **Beispielausgabe**:
   ```
   SNMPwalk-Daten vorbereitet am Fri Sep  5 11:30:00 CEST 2025
   9 snmpwalk_output.txt
   ```

**Reflexion**: Warum ist eine strukturierte Vorbereitung der Daten wichtig? Nutze `man cat` und überlege, wie du große Dateien effizient verarbeitest.

### Übung 2: Systeminformationen auswerten
**Ziel**: Extrahiere Systeminformationen (z. B. `sysDescr`, `sysName`, `sysUpTime`) und formatierte sie in einer Markdown-Tabelle.

1. **Schritt 1**: Filtere Systeminformationen aus der SNMPwalk-Datei:
   ```bash
   grep -E "sysDescr|sysName|sysUpTime" snmpwalk_output.txt > system_info.txt
   cat system_info.txt
   ```
   **Beispielausgabe**:
   ```
   SNMPv2-MIB::sysDescr.0 = STRING: Cisco IOS Software, C2960X Software (C2960X-UNIVERSALK9-M), Version 15.2(2)E6
   SNMPv2-MIB::sysName.0 = STRING: Switch01
   SNMPv2-MIB::sysUpTime.0 = Timeticks: (12345678) 1 day, 10:17:36.78
   ```

2. **Schritt 2**: Erstelle ein Skript zur Erstellung einer Markdown-Tabelle:
   ```bash
   nano system_info_table.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash
   # Skript zur Auswertung von Systeminformationen in Markdown

   INPUT_FILE="snmpwalk_output.txt"
   OUTPUT_FILE="system_info.md"

   echo "# Systeminformationen (SNMPwalk)" > $OUTPUT_FILE
   echo "Erstellt am: $(date)" >> $OUTPUT_FILE
   echo "" >> $OUTPUT_FILE
   echo "| OID | Wert |" >> $OUTPUT_FILE
   echo "|-----|------|" >> $OUTPUT_FILE

   while IFS= read -r line; do
       oid=$(echo "$line" | awk -F' = ' '{print $1}')
       value=$(echo "$line" | awk -F' = ' '{print $2}' | sed 's/STRING: //; s/Timeticks:.*)//')
       echo "| $oid | $value |" >> $OUTPUT_FILE
   done < <(grep -E "sysDescr|sysName|sysUpTime" $INPUT_FILE)

   cat $OUTPUT_FILE
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   chmod +x system_info_table.sh
   ./system_info_table.sh
   ```
   **Beispielausgabe** (`system_info.md`):
   ```
   # Systeminformationen (SNMPwalk)
   Erstellt am: Fri Sep  5 11:30:00 CEST 2025

   | OID                    | Wert                                  |
   |------------------------|---------------------------------------|
   | SNMPv2-MIB::sysDescr.0 | Cisco IOS Software, C2960X Software...|
   | SNMPv2-MIB::sysName.0  | Switch01                              |
   | SNMPv2-MIB::sysUpTime.0| 1 day, 10:17:36.78                    |
   ```

**Reflexion**: Wie helfen Systeminformationen bei der Geräteverwaltung? Nutze `man grep` und überlege, wie du weitere OIDs (z. B. `sysContact`) einbeziehst.

### Übung 3: Netzwerk-Interfaces auswerten
**Ziel**: Extrahiere Netzwerk-Interface-Daten (z. B. `ifDescr`, `ifInOctets`, `ifOutOctets`) und formatierte sie in einer Markdown-Tabelle.

1. **Schritt 1**: Filtere Interface-Daten aus der SNMPwalk-Datei:
   ```bash
   grep -E "ifDescr|ifInOctets|ifOutOctets" snmpwalk_output.txt > interfaces.txt
   cat interfaces.txt
   ```
   **Beispielausgabe**:
   ```
   IF-MIB::ifDescr.1 = STRING: GigabitEthernet0/1
   IF-MIB::ifDescr.2 = STRING: GigabitEthernet0/2
   IF-MIB::ifInOctets.1 = Counter32: 123456789
   IF-MIB::ifOutOctets.1 = Counter32: 987654321
   IF-MIB::ifInOctets.2 = Counter32: 456789123
   IF-MIB::ifOutOctets.2 = Counter32: 321654987
   ```

2. **Schritt 2**: Erstelle ein Skript zur Erstellung einer Markdown-Tabelle für Interfaces:
   ```bash
   nano interfaces_table.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash
   # Skript zur Auswertung von Netzwerk-Interfaces in Markdown

   INPUT_FILE="snmpwalk_output.txt"
   OUTPUT_FILE="interfaces.md"

   echo "# Netzwerk-Interfaces (SNMPwalk)" > $OUTPUT_FILE
   echo "Erstellt am: $(date)" >> $OUTPUT_FILE
   echo "" >> $OUTPUT_FILE
   echo "| Interface | Eingehende Bytes | Ausgehende Bytes |" >> $OUTPUT_FILE
   echo "|-----------|------------------|------------------|" >> $OUTPUT_FILE

   interfaces=$(grep "ifDescr" $INPUT_FILE | awk -F' = ' '{print $1}' | awk -F'.' '{print $NF}')
   for index in $interfaces; do
       descr=$(grep "ifDescr.$index" $INPUT_FILE | awk -F' = ' '{print $2}' | sed 's/STRING: //')
       in_octets=$(grep "ifInOctets.$index" $INPUT_FILE | awk -F' = ' '{print $2}' | sed 's/Counter32: //')
       out_octets=$(grep "ifOutOctets.$index" $INPUT_FILE | awk -F' = ' '{print $2}' | sed 's/Counter32: //')
       echo "| $descr | $in_octets | $out_octets |" >> $OUTPUT_FILE
   done

   cat $OUTPUT_FILE
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   chmod +x interfaces_table.sh
   ./interfaces_table.sh
   ```
   **Beispielausgabe** (`interfaces.md`):
   ```
   # Netzwerk-Interfaces (SNMPwalk)
   Erstellt am: Fri Sep  5 11:30:00 CEST 2025

   | Interface          | Eingehende Bytes | Ausgehende Bytes |
   |--------------------|------------------|------------------|
   | GigabitEthernet0/1 | 123456789        | 987654321        |
   | GigabitEthernet0/2 | 456789123        | 321654987        |
   ```

**Reflexion**: Wie helfen Interface-Daten bei der Netzwerküberwachung? Nutze `man awk` und überlege, wie du Bandbreitenstatistiken berechnest.

### Übung 4: Konvertierung in JSON
**Ziel**: Konvertiere die SNMPwalk-Daten in ein JSON-Format für strukturierte Verarbeitung.

1. **Schritt 1**: Erstelle ein Skript zur JSON-Konvertierung:
   ```bash
   nano snmp_to_json.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash
   # Skript zur Konvertierung von SNMPwalk-Daten in JSON

   INPUT_FILE="snmpwalk_output.txt"
   OUTPUT_FILE="snmp_data.json"

   # Initialisiere JSON-Array
   echo "{" > $OUTPUT_FILE
   echo "  \"system\": []," >> $OUTPUT_FILE
   echo "  \"interfaces\": []" >> $OUTPUT_FILE
   echo "}" >> $OUTPUT_FILE

   # Systeminformationen
   system_json=$(grep -E "sysDescr|sysName|sysUpTime" $INPUT_FILE | while IFS= read -r line; do
       oid=$(echo "$line" | awk -F' = ' '{print $1}')
       value=$(echo "$line" | awk -F' = ' '{print $2}' | sed 's/STRING: //; s/Timeticks:.*)//; s/"/\\"/g')
       jq -n --arg oid "$oid" --arg value "$value" '{oid: $oid, value: $value}'
   done | jq -s .)

   # Interfaces
   interfaces_json=$(grep -E "ifDescr|ifInOctets|ifOutOctets" $INPUT_FILE | while IFS= read -r line; do
       oid=$(echo "$line" | awk -F' = ' '{print $1}')
       value=$(echo "$line" | awk -F' = ' '{print $2}' | sed 's/STRING: //; s/Counter32: //; s/"/\\"/g')
       jq -n --arg oid "$oid" --arg value "$value" '{oid: $oid, value: $value}'
   done | jq -s .)

   # Aktualisiere JSON-Datei
   jq --argjson sys "$system_json" --argjson ifaces "$interfaces_json" '.system = $sys | .interfaces = $ifaces' $OUTPUT_FILE > tmp.json && mv tmp.json $OUTPUT_FILE

   cat $OUTPUT_FILE | jq .
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   chmod +x snmp_to_json.sh
   ./snmp_to_json.sh
   ```
   **Beispielausgabe** (`snmp_data.json`, formatiert):
   ```json
   {
     "system": [
       {
         "oid": "SNMPv2-MIB::sysDescr.0",
         "value": "Cisco IOS Software, C2960X Software (C2960X-UNIVERSALK9-M), Version 15.2(2)E6"
       },
       {
         "oid": "SNMPv2-MIB::sysName.0",
         "value": "Switch01"
       },
       {
         "oid": "SNMPv2-MIB::sysUpTime.0",
         "value": "1 day, 10:17:36.78"
       }
     ],
     "interfaces": [
       {
         "oid": "IF-MIB::ifDescr.1",
         "value": "GigabitEthernet0/1"
       },
       {
         "oid": "IF-MIB::ifDescr.2",
         "value": "GigabitEthernet0/2"
       },
       {
         "oid": "IF-MIB::ifInOctets.1",
         "value": "123456789"
       },
       {
         "oid": "IF-MIB::ifOutOctets.1",
         "value": "987654321"
       },
       {
         "oid": "IF-MIB::ifInOctets.2",
         "value": "456789123"
       },
       {
         "oid": "IF-MIB::ifOutOctets.2",
         "value": "321654987"
       }
     ]
   }
   ```

**Reflexion**: Warum ist JSON für die Datenverarbeitung nützlich? Nutze `man jq` und überlege, wie du die JSON-Daten in eine Datenbank importierst.

### Übung 5: Spielerei – Markdown mit eingebettetem JSON
**Ziel**: Erstelle ein Markdown-Dokument, das die Ergebnisse zusammenfasst und JSON einbettet.

1. **Schritt 1**: Erstelle ein Skript für die kombinierte Ausgabe:
   ```bash
   nano snmp_summary.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash
   # Skript für kombinierte Markdown- und JSON-Ausgabe

   INPUT_FILE="snmpwalk_output.txt"
   OUTPUT_FILE="snmp_summary.md"

   echo "# SNMPwalk-Auswertung (Markdown und JSON)" > $OUTPUT_FILE
   echo "Erstellt am: $(date)" >> $OUTPUT_FILE
   echo "" >> $OUTPUT_FILE

   # Systeminformationen-Tabelle
   echo "## Systeminformationen" >> $OUTPUT_FILE
   echo "| OID | Wert |" >> $OUTPUT_FILE
   echo "|-----|------|" >> $OUTPUT_FILE
   while IFS= read -r line; do
       oid=$(echo "$line" | awk -F' = ' '{print $1}')
       value=$(echo "$line" | awk -F' = ' '{print $2}' | sed 's/STRING: //; s/Timeticks:.*)//')
       echo "| $oid | $value |" >> $OUTPUT_FILE
   done < <(grep -E "sysDescr|sysName|sysUpTime" $INPUT_FILE)

   # Interface-Tabelle
   echo "" >> $OUTPUT_FILE
   echo "## Netzwerk-Interfaces" >> $OUTPUT_FILE
   echo "| Interface | Eingehende Bytes | Ausgehende Bytes |" >> $OUTPUT_FILE
   echo "|-----------|------------------|------------------|" >> $OUTPUT_FILE
   interfaces=$(grep "ifDescr" $INPUT_FILE | awk -F' = ' '{print $1}' | awk -F'.' '{print $NF}')
   for index in $interfaces; do
       descr=$(grep "ifDescr.$index" $INPUT_FILE | awk -F' = ' '{print $2}' | sed 's/STRING: //')
       in_octets=$(grep "ifInOctets.$index" $INPUT_FILE | awk -F' = ' '{print $2}' | sed 's/Counter32: //')
       out_octets=$(grep "ifOutOctets.$index" $INPUT_FILE | awk -F' = ' '{print $2}' | sed 's/Counter32: //')
       echo "| $descr | $in_octets | $out_octets |" >> $OUTPUT_FILE
   done

   # JSON-Einbettung
   echo "" >> $OUTPUT_FILE
   echo "## JSON-Daten" >> $OUTPUT_FILE
   echo "```json" >> $OUTPUT_FILE
   cat snmp_data.json >> $OUTPUT_FILE
   echo "```" >> $OUTPUT_FILE

   echo "Auswertung abgeschlossen. Ergebnisse in $OUTPUT_FILE."
   cat $OUTPUT_FILE
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus (nach Übung 4, da es `snmp_data.json` benötigt):
   ```bash
   chmod +x snmp_summary.sh
   ./snmp_summary.sh
   ```

3. **Spielerei**: Überprüfe die Markdown-Ausgabe:
   ```bash
   cat snmp_summary.md
   ```
   **Beispielausgabe** (`snmp_summary.md`):
   ```
   # SNMPwalk-Auswertung (Markdown und JSON)
   Erstellt am: Fri Sep  5 11:30:00 CEST 2025

   ## Systeminformationen
   | OID                    | Wert                                  |
   |------------------------|---------------------------------------|
   | SNMPv2-MIB::sysDescr.0 | Cisco IOS Software, C2960X Software...|
   | SNMPv2-MIB::sysName.0  | Switch01                              |
   | SNMPv2-MIB::sysUpTime.0| 1 day, 10:17:36.78                    |

   ## Netzwerk-Interfaces
   | Interface          | Eingehende Bytes | Ausgehende Bytes |
   |--------------------|------------------|------------------|
   | GigabitEthernet0/1 | 123456789        | 987654321        |
   | GigabitEthernet0/2 | 456789123        | 321654987        |

   ## JSON-Daten
   ```json
   {
     "system": [
       {
         "oid": "SNMPv2-MIB::sysDescr.0",
         "value": "Cisco IOS Software, C2960X Software (C2960X-UNIVERSALK9-M), Version 15.2(2)E6"
       },
       {
         "oid": "SNMPv2-MIB::sysName.0",
         "value": "Switch01"
       },
       {
         "oid": "SNMPv2-MIB::sysUpTime.0",
         "value": "1 day, 10:17:36.78"
       }
     ],
     "interfaces": [
       {
         "oid": "IF-MIB::ifDescr.1",
         "value": "GigabitEthernet0/1"
       },
       {
         "oid": "IF-MIB::ifDescr.2",
         "value": "GigabitEthernet0/2"
       },
       {
         "oid": "IF-MIB::ifInOctets.1",
         "value": "123456789"
       },
       {
         "oid": "IF-MIB::ifOutOctets.1",
         "value": "987654321"
       },
       {
         "oid": "IF-MIB::ifInOctets.2",
         "value": "456789123"
       },
       {
         "oid": "IF-MIB::ifOutOctets.2",
         "value": "321654987"
       }
     ]
   }
   ```
   ```

**Reflexion**: Wie verbessert die Kombination von Markdown und JSON die Dokumentation? Nutze `man jq` und überlege, wie du die Daten in eine Web-App integrierst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um SNMP-Datenverarbeitung in Bash zu verinnerlichen.
- **Sicheres Testen**: Arbeite in einer Testumgebung und sichere Eingabedateien (`cp snmpwalk_output.txt snmpwalk_output.txt.bak`).
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze `man awk` oder `man jq` für Details.
- **Effiziente Entwicklung**: Nutze `grep` und `awk` für präzises Parsing, `jq` für JSON-Manipulation und Skripte für Automatisierung.
- **Kombiniere Tools**: Integriere `pandas` (Python) für erweiterte Analysen oder `curl` für die Weitergabe von JSON-Daten an APIs.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Hinzufügen von Diagrammen mit `mermaid` oder Datenbank-Export.

## Fazit
Mit diesen Übungen hast du gelernt, gespeicherte SNMPwalk-Daten eines Cisco-Switches vorzubereiten, Systeminformationen und Netzwerk-Interfaces auszuwerten, in Markdown-Tabellen zu formatieren und in JSON zu konvertieren. Die Spielerei zeigt, wie du die Ergebnisse in einem Markdown-Dokument mit eingebettetem JSON visualisierst. Vertiefe dein Wissen, indem du fortgeschrittene Themen (z. B. SNMPv3-Parsing, Zeitreihenanalysen) oder Tools wie `librenms` ausprobierst. Wenn du ein spezifisches Thema (z. B. Echtzeitüberwachung oder Datenvisualisierung) vertiefen möchtest, lass es mich wissen!
