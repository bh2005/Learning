# Praxisorientierte Anleitung: JSON-Daten mit `jq` parsen und Schnittstellengeschwindigkeit berechnen

## Einführung
Die Verarbeitung von JSON-Daten auf der Kommandozeile ist eine häufige Aufgabe in der Systemadministration, insbesondere bei der Analyse von Netzwerkdaten wie SNMPwalk-Ausgaben. Da Bash keine native JSON-Unterstützung bietet, ist `jq` ein unverzichtbares Tool zum Parsen, Filtern und Transformieren von JSON. Diese Anleitung führt Anfänger durch praktische Übungen zur **Vorbereitung von JSON-Daten**, **Parsen von Systeminformationen**, **Parsen von Netzwerk-Interfaces**, **Berechnung der Schnittstellengeschwindigkeit** und **Formatierung in Markdown-Tabellen**. Die Übungen verwenden die bereitgestellten JSON-Daten eines Cisco-Switches (SNMPwalk). Eine **Spielerei** zeigt, wie du die Ergebnisse in einem Markdown-Dokument mit eingebetteten JSON- und Geschwindigkeitsdaten visualisierst, um die Verbindung zu vorherigen Themen (z. B. Markdown-Ausgabe) herzustellen. Die Übungen sind auf einem Debian-basierten System ausführbar und für Nutzer mit grundlegenden Kenntnissen in Bash, JSON und Netzwerktechnik geeignet.

**Voraussetzungen**:
- Ein Debian-basiertes System (z. B. Ubuntu 22.04, Debian 11); Windows-Nutzer können WSL2 verwenden; macOS ist kompatibel.
- Ein Terminal (z. B. Bash unter Linux).
- Installierte Tools:
  - `jq` für JSON-Verarbeitung: `sudo apt install jq`
- Eine JSON-Datei mit SNMPwalk-Daten (z. B. `snmp_data.json`, wie oben angegeben).
- Grundkenntnisse in Bash (Befehle, Skripte), JSON und Netzwerktechnik (SNMP, OIDs).
- Sichere Testumgebung (z. B. `$HOME/json_analysis` oder `~/json_analysis`).
- Optional: `bc` für Berechnungen: `sudo apt install bc`.

## Grundlegende Befehle
Hier sind die wichtigsten Bash- und `jq`-Befehle für die JSON-Übungen:

1. **JSON-Daten vorbereiten**:
   - `cat <Datei>`: Zeigt den Inhalt der JSON-Datei.
   - `jq '.' <Datei>`: Formatiert JSON-Daten lesbar.
2. **JSON-Daten parsen**:
   - `jq '.path'` : Extrahiert Werte aus einem JSON-Pfad.
   - `jq '.[].key'` : Iteriert über Arrays und extrahiert Werte.
   - `jq 'select(condition)'` : Filtert basierend auf Bedingungen.
3. **Schnittstellengeschwindigkeit berechnen**:
   - `bc`: Führt mathematische Berechnungen durch.
   - `date`: Liefert Zeitstempel für Zeitdifferenzen.
4. **Markdown-Tabellen erstellen**:
   - `echo "| ... | ... |"` : Erstellt Markdown-Tabellenzeilen.
5. **Nützliche Zusatzbefehle**:
   - `man jq`: Dokumentation für `jq`.
   - `jq -r`: Gibt rohe Ausgabe ohne Anführungszeichen.
   - `date`: Fügt Zeitstempel in Protokollen hinzu.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: JSON-Daten vorbereiten
**Ziel**: Bereite die JSON-Datei vor und überprüfe ihren Inhalt.

1. **Schritt 1**: Erstelle ein Testverzeichnis und speichere die JSON-Daten:
   ```bash
   mkdir json_analysis
   cd json_analysis
   nano snmp_data.json
   ```
   Füge die oben angegebenen JSON-Daten ein, speichere und schließe.

2. **Schritt 2**: Überprüfe und formatiere die JSON-Datei:
   ```bash
   jq '.' snmp_data.json
   ```

3. **Schritt 3**: Protokolliere die Vorbereitung:
   ```bash
   echo "JSON-Daten vorbereitet am $(date)" > json_log.txt
   jq -r '.system[].oid' snmp_data.json >> json_log.txt
   cat json_log.txt
   ```
   **Beispielausgabe**:
   ```
   JSON-Daten vorbereitet am Fri Sep  5 11:48:00 CEST 2025
   SNMPv2-MIB::sysDescr.0
   SNMPv2-MIB::sysName.0
   SNMPv2-MIB::sysUpTime.0
   ```

**Reflexion**: Warum ist `jq` für JSON-Verarbeitung nützlich? Nutze `man jq` und überlege, wie du JSON-Daten validierst.

### Übung 2: Systeminformationen parsen
**Ziel**: Extrahiere Systeminformationen aus der JSON-Datei und formatierte sie in einer Markdown-Tabelle.

1. **Schritt 1**: Extrahiere Systeminformationen mit `jq`:
   ```bash
   jq '.system[] | {oid: .oid, value: .value}' snmp_data.json
   ```
   **Beispielausgabe**:
   ```
   {"oid":"SNMPv2-MIB::sysDescr.0","value":"Cisco IOS Software, C2960X Software (C2960X-UNIVERSALK9-M), Version 15.2(2)E6"}
   {"oid":"SNMPv2-MIB::sysName.0","value":"Switch01"}
   {"oid":"SNMPv2-MIB::sysUpTime.0","value":"1 day, 10:17:36.78"}
   ```

2. **Schritt 2**: Erstelle ein Skript für eine Markdown-Tabelle:
   ```bash
   nano system_info_table.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash
   # Skript zur Auswertung von Systeminformationen in Markdown

   INPUT_FILE="snmp_data.json"
   OUTPUT_FILE="system_info.md"

   echo "# Systeminformationen (JSON)" > $OUTPUT_FILE
   echo "Erstellt am: $(date)" >> $OUTPUT_FILE
   echo "" >> $OUTPUT_FILE
   echo "| OID | Wert |" >> $OUTPUT_FILE
   echo "|-----|------|" >> $OUTPUT_FILE

   jq -r '.system[] | "\(.oid) | \(.value)"' $INPUT_FILE >> $OUTPUT_FILE

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
   # Systeminformationen (JSON)
   Erstellt am: Fri Sep  5 11:48:00 CEST 2025

   | OID                    | Wert                                  |
   |------------------------|---------------------------------------|
   | SNMPv2-MIB::sysDescr.0 | Cisco IOS Software, C2960X Software...|
   | SNMPv2-MIB::sysName.0  | Switch01                              |
   | SNMPv2-MIB::sysUpTime.0| 1 day, 10:17:36.78                    |
   ```

**Reflexion**: Wie erleichtert `jq` das Parsen von JSON-Daten? Nutze `man jq` und überlege, wie du weitere System-OIDs einbeziehst.

### Übung 3: Netzwerk-Interfaces parsen
**Ziel**: Extrahiere Netzwerk-Interface-Daten und formatierte sie in einer Markdown-Tabelle.

1. **Schritt 1**: Extrahiere Interface-Daten mit `jq`:
   ```bash
   jq '.interfaces[] | select(.oid | contains("ifDescr") or contains("ifInOctets") or contains("ifOutOctets"))' snmp_data.json
   ```
   **Beispielausgabe**:
   ```
   {"oid":"IF-MIB::ifDescr.1","value":"GigabitEthernet0/1"}
   {"oid":"IF-MIB::ifDescr.2","value":"GigabitEthernet0/2"}
   {"oid":"IF-MIB::ifInOctets.1","value":"123456789"}
   {"oid":"IF-MIB::ifOutOctets.1","value":"987654321"}
   {"oid":"IF-MIB::ifInOctets.2","value":"456789123"}
   {"oid":"IF-MIB::ifOutOctets.2","value":"321654987"}
   ```

2. **Schritt 2**: Erstelle ein Skript für eine Markdown-Tabelle:
   ```bash
   nano interfaces_table.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash
   # Skript zur Auswertung von Netzwerk-Interfaces in Markdown

   INPUT_FILE="snmp_data.json"
   OUTPUT_FILE="interfaces.md"

   echo "# Netzwerk-Interfaces (JSON)" > $OUTPUT_FILE
   echo "Erstellt am: $(date)" >> $OUTPUT_FILE
   echo "" >> $OUTPUT_FILE
   echo "| Interface | Eingehende Bytes | Ausgehende Bytes |" >> $OUTPUT_FILE
   echo "|-----------|------------------|------------------|" >> $OUTPUT_FILE

   # Extrahiere Interface-Indizes
   indexes=$(jq -r '.interfaces[] | select(.oid | contains("ifDescr")) | .oid | capture(".*\\.(\\d+)$") | .captures[0].string' $INPUT_FILE)
   for index in $indexes; do
       descr=$(jq -r ".interfaces[] | select(.oid == \"IF-MIB::ifDescr.$index\") | .value" $INPUT_FILE)
       in_octets=$(jq -r ".interfaces[] | select(.oid == \"IF-MIB::ifInOctets.$index\") | .value" $INPUT_FILE)
       out_octets=$(jq -r ".interfaces[] | select(.oid == \"IF-MIB::ifOutOctets.$index\") | .value" $INPUT_FILE)
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
   # Netzwerk-Interfaces (JSON)
   Erstellt am: Fri Sep  5 11:48:00 CEST 2025

   | Interface          | Eingehende Bytes | Ausgehende Bytes |
   |--------------------|------------------|------------------|
   | GigabitEthernet0/1 | 123456789        | 987654321        |
   | GigabitEthernet0/2 | 456789123        | 321654987        |
   ```

**Reflexion**: Wie strukturiert `jq` die Verarbeitung von Interface-Daten? Nutze `man jq` und überlege, wie du weitere Interface-Metriken (z. B. `ifSpeed`) einbeziehst.

### Übung 4: Schnittstellengeschwindigkeit berechnen
**Ziel**: Berechne die Schnittstellengeschwindigkeit (Bytes pro Sekunde) basierend auf zwei JSON-Datensätzen mit Zeitdifferenz.

**Hinweis**: Da die bereitgestellten JSON-Daten nur einen Zeitpunkt enthalten, simulieren wir zwei Datensätze (`snmp_data_1.json` und `snmp_data_2.json`) mit einer angenommenen Zeitdifferenz von 60 Sekunden und geänderten `ifInOctets`/`ifOutOctets`-Werten.

1. **Schritt 1**: Erstelle einen zweiten JSON-Datensatz mit veränderten Werten:
   ```bash
   cp snmp_data.json snmp_data_1.json
   nano snmp_data_2.json
   ```
   Kopiere den Inhalt von `snmp_data.json` und ändere die Werte für `ifInOctets` und `ifOutOctets` (z. B. +1000000 Bytes):
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
         "value": "1 day, 10:18:36.78"
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
         "value": "124456789"
       },
       {
         "oid": "IF-MIB::ifOutOctets.1",
         "value": "988654321"
       },
       {
         "oid": "IF-MIB::ifInOctets.2",
         "value": "457789123"
       },
       {
         "oid": "IF-MIB::ifOutOctets.2",
         "value": "322654987"
       }
     ]
   }
   ```
   Speichere und schließe.

2. **Schritt 2**: Erstelle ein Skript zur Berechnung der Schnittstellengeschwindigkeit:
   ```bash
   nano interface_speed.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash
   # Skript zur Berechnung der Schnittstellengeschwindigkeit

   INPUT_FILE1="snmp_data_1.json"
   INPUT_FILE2="snmp_data_2.json"
   OUTPUT_FILE="interface_speed.md"
   TIME_DIFF=60  # Zeitdifferenz in Sekunden

   echo "# Schnittstellengeschwindigkeit (JSON)" > $OUTPUT_FILE
   echo "Erstellt am: $(date)" >> $OUTPUT_FILE
   echo "Zeitdifferenz: $TIME_DIFF Sekunden" >> $OUTPUT_FILE
   echo "" >> $OUTPUT_FILE
   echo "| Interface | Eingehende Geschwindigkeit (B/s) | Ausgehende Geschwindigkeit (B/s) |" >> $OUTPUT_FILE
   echo "|-----------|----------------------------------|----------------------------------|" >> $OUTPUT_FILE

   indexes=$(jq -r '.interfaces[] | select(.oid | contains("ifDescr")) | .oid | capture(".*\\.(\\d+)$") | .captures[0].string' $INPUT_FILE1)
   for index in $indexes; do
       descr=$(jq -r ".interfaces[] | select(.oid == \"IF-MIB::ifDescr.$index\") | .value" $INPUT_FILE1)
       in_octets1=$(jq -r ".interfaces[] | select(.oid == \"IF-MIB::ifInOctets.$index\") | .value" $INPUT_FILE1)
       out_octets1=$(jq -r ".interfaces[] | select(.oid == \"IF-MIB::ifOutOctets.$index\") | .value" $INPUT_FILE1)
       in_octets2=$(jq -r ".interfaces[] | select(.oid == \"IF-MIB::ifInOctets.$index\") | .value" $INPUT_FILE2)
       out_octets2=$(jq -r ".interfaces[] | select(.oid == \"IF-MIB::ifOutOctets.$index\") | .value" $INPUT_FILE2)

       in_speed=$(echo "($in_octets2 - $in_octets1) / $TIME_DIFF" | bc)
       out_speed=$(echo "($out_octets2 - $out_octets1) / $TIME_DIFF" | bc)

       echo "| $descr | $in_speed | $out_speed |" >> $OUTPUT_FILE
   done

   cat $OUTPUT_FILE
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   chmod +x interface_speed.sh
   ./interface_speed.sh
   ```
   **Beispielausgabe** (`interface_speed.md`):
   ```
   # Schnittstellengeschwindigkeit (JSON)
   Erstellt am: Fri Sep  5 11:48:00 CEST 2025
   Zeitdifferenz: 60 Sekunden

   | Interface          | Eingehende Geschwindigkeit (B/s) | Ausgehende Geschwindigkeit (B/s) |
   |--------------------|----------------------------------|----------------------------------|
   | GigabitEthernet0/1 | 16666                            | 16666                            |
   | GigabitEthernet0/2 | 16666                            | 16666                            |
   ```

**Reflexion**: Wie genau ist die Geschwindigkeitsberechnung? Nutze `man bc` und überlege, wie du die Zeitdifferenz dynamisch ermittelst.

### Übung 5: Spielerei – Markdown mit eingebettetem JSON und Geschwindigkeiten
**Ziel**: Erstelle ein Markdown-Dokument, das Systeminformationen, Interfaces, Geschwindigkeiten und JSON-Daten zusammenfasst.

1. **Schritt 1**: Erstelle ein Skript für die kombinierte Ausgabe:
   ```bash
   nano json_summary.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash
   # Skript für kombinierte Markdown-, JSON- und Geschwindigkeitsausgabe

   INPUT_FILE1="snmp_data_1.json"
   INPUT_FILE2="snmp_data_2.json"
   OUTPUT_FILE="json_summary.md"
   TIME_DIFF=60

   echo "# JSON-SNMP-Auswertung" > $OUTPUT_FILE
   echo "Erstellt am: $(date)" >> $OUTPUT_FILE
   echo "" >> $OUTPUT_FILE

   # Systeminformationen
   echo "## Systeminformationen" >> $OUTPUT_FILE
   echo "| OID | Wert |" >> $OUTPUT_FILE
   echo "|-----|------|" >> $OUTPUT_FILE
   jq -r '.system[] | "\(.oid) | \(.value)"' $INPUT_FILE1 >> $OUTPUT_FILE

   # Netzwerk-Interfaces und Geschwindigkeiten
   echo "" >> $OUTPUT_FILE
   echo "## Netzwerk-Interfaces und Geschwindigkeiten" >> $OUTPUT_FILE
   echo "| Interface | Eingehende Bytes | Ausgehende Bytes | Eingehende Geschwindigkeit (B/s) | Ausgehende Geschwindigkeit (B/s) |" >> $OUTPUT_FILE
   echo "|-----------|------------------|------------------|----------------------------------|----------------------------------|" >> $OUTPUT_FILE
   indexes=$(jq -r '.interfaces[] | select(.oid | contains("ifDescr")) | .oid | capture(".*\\.(\\d+)$") | .captures[0].string' $INPUT_FILE1)
   for index in $indexes; do
       descr=$(jq -r ".interfaces[] | select(.oid == \"IF-MIB::ifDescr.$index\") | .value" $INPUT_FILE1)
       in_octets1=$(jq -r ".interfaces[] | select(.oid == \"IF-MIB::ifInOctets.$index\") | .value" $INPUT_FILE1)
       out_octets1=$(jq -r ".interfaces[] | select(.oid == \"IF-MIB::ifOutOctets.$index\") | .value" $INPUT_FILE1)
       in_octets2=$(jq -r ".interfaces[] | select(.oid == \"IF-MIB::ifInOctets.$index\") | .value" $INPUT_FILE2)
       out_octets2=$(jq -r ".interfaces[] | select(.oid == \"IF-MIB::ifOutOctets.$index\") | .value" $INPUT_FILE2)
       in_speed=$(echo "($in_octets2 - $in_octets1) / $TIME_DIFF" | bc)
       out_speed=$(echo "($out_octets2 - $out_octets1) / $TIME_DIFF" | bc)
       echo "| $descr | $in_octets1 | $out_octets1 | $in_speed | $out_speed |" >> $OUTPUT_FILE
   done

   # JSON-Daten
   echo "" >> $OUTPUT_FILE
   echo "## JSON-Daten (Zweiter Datensatz)" >> $OUTPUT_FILE
   echo "```json" >> $OUTPUT_FILE
   jq '.' $INPUT_FILE2 >> $OUTPUT_FILE
   echo "```" >> $OUTPUT_FILE

   echo "Auswertung abgeschlossen. Ergebnisse in $OUTPUT_FILE."
   cat $OUTPUT_FILE
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   chmod +x json_summary.sh
   ./json_summary.sh
   ```

3. **Spielerei**: Überprüfe die Markdown-Ausgabe:
   ```bash
   cat json_summary.md
   ```
   **Beispielausgabe** (`json_summary.md`):
   ```
   # JSON-SNMP-Auswertung
   Erstellt am: Fri Sep  5 11:48:00 CEST 2025

   ## Systeminformationen
   | OID                    | Wert                                  |
   |------------------------|---------------------------------------|
   | SNMPv2-MIB::sysDescr.0 | Cisco IOS Software, C2960X Software...|
   | SNMPv2-MIB::sysName.0  | Switch01                              |
   | SNMPv2-MIB::sysUpTime.0| 1 day, 10:17:36.78                    |

   ## Netzwerk-Interfaces und Geschwindigkeiten
   | Interface          | Eingehende Bytes | Ausgehende Bytes | Eingehende Geschwindigkeit (B/s) | Ausgehende Geschwindigkeit (B/s) |
   |--------------------|------------------|------------------|----------------------------------|----------------------------------|
   | GigabitEthernet0/1 | 123456789        | 987654321        | 16666                            | 16666                            |
   | GigabitEthernet0/2 | 456789123        | 321654987        | 16666                            | 16666                            |

   ## JSON-Daten (Zweiter Datensatz)
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
         "value": "1 day, 10:18:36.78"
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
         "value": "124456789"
       },
       {
         "oid": "IF-MIB::ifOutOctets.1",
         "value": "988654321"
       },
       {
         "oid": "IF-MIB::ifInOctets.2",
         "value": "457789123"
       },
       {
         "oid": "IF-MIB::ifOutOctets.2",
         "value": "322654987"
       }
     ]
   }
   ```
   ```

**Reflexion**: Wie verbessert die Kombination von Markdown, JSON und Geschwindigkeitsdaten die Netzwerküberwachung? Nutze `man jq` und überlege, wie du die Daten in eine Web-App integrierst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um JSON-Verarbeitung mit `jq` zu verinnerlichen.
- **Sicheres Testen**: Arbeite in einer Testumgebung und sichere JSON-Dateien (`cp snmp_data.json snmp_data.json.bak`).
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze `man jq` oder `man bc` für Details.
- **Effiziente Entwicklung**: Nutze `jq -r` für rohe Ausgaben, `bc` für Berechnungen und Skripte für Automatisierung.
- **Kombiniere Tools**: Integriere `curl` für API-Uploads oder `python` mit `pandas` für erweiterte Analysen.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Visualisierung mit `mermaid` oder Export in eine Datenbank.

## Fazit
Mit diesen Übungen hast du gelernt, JSON-Daten eines SNMPwalk mit `jq` zu parsen, Systeminformationen und Netzwerk-Interfaces in Markdown-Tabellen zu formatieren und Schnittstellengeschwindigkeiten zu berechnen. Die Spielerei zeigt, wie du die Ergebnisse in einem Markdown-Dokument mit eingebetteten JSON- und Geschwindigkeitsdaten visualisierst. Vertiefe dein Wissen, indem du fortgeschrittene Themen (z. B. Echtzeit-SNMP-Abfragen, Zeitreihenanalysen) oder Tools wie `prometheus` ausprobierst. Wenn du ein spezifisches Thema (z. B. Datenvisualisierung oder API-Integration) vertiefen möchtest, lass es mich wissen!
