# Praxisorientierte Anleitung: Funktionen und Fehlerbehandlung in Bash-Skripten

## Einführung
Funktionen in Bash sind ein zentraler Baustein, um Skripte modular, wiederverwendbar und lesbar zu gestalten. Fehlerbehandlung ist essenziell, um robuste Skripte zu schreiben, die unerwartete Situationen (z. B. fehlende Dateien, ungültige Eingaben) graceful handhaben. Diese Anleitung führt Anfänger durch praktische Übungen zur **Definition und Nutzung von Funktionen**, **Parameterübergabe**, **Rückgabewerten mit Exit-Codes**, **Fehlerbehandlung mit Bedingungen** und **Logging**. Die Übungen verwenden die JSON-Datei `sample_data.json` aus der vorherigen Python-Anleitung (mit Log-Einträgen) und `jq` für die JSON-Verarbeitung. Eine **Spielerei** zeigt, wie du Funktionen und Fehlerbehandlung kombinierst, um Daten zu analysieren und Ergebnisse in Markdown zu dokumentieren. Die Übungen sind auf einem Debian-basierten System ausführbar und für Nutzer mit grundlegenden Kenntnissen in Bash geeignet.

**Voraussetzungen**:
- Ein Debian-basiertes System (z. B. Ubuntu 22.04, Debian 11); Windows-Nutzer können WSL2 verwenden; macOS ist kompatibel.
- Ein Terminal (z. B. Bash unter Linux).
- Installierte Tools:
  - `jq` für JSON-Verarbeitung: `sudo apt install jq`
  - Die Datei `sample_data.json` aus der vorherigen Anleitung (siehe unten).
- Grundkenntnisse in Bash (Befehle, Skripte, Bedingungen).
- Sichere Testumgebung (z. B. `$HOME/bash_functions` oder `~/bash_functions`).

## Beispiel-Datensatz
Wir verwenden die JSON-Datei `sample_data.json` aus der vorherigen Anleitung:
```json
[
    {"timestamp": 1725532080, "user_id": 1, "event": "LOGIN"},
    {"timestamp": 1725532081, "user_id": 2, "event": "ERROR"},
    {"timestamp": 1725532082, "user_id": 1, "event": "VIEW_PAGE"},
    {"timestamp": 1725532083, "user_id": 3, "event": "PURCHASE"},
    {"timestamp": 1725532084, "user_id": 2, "event": "LOGOUT"}
]
```

## Grundlegende Konzepte und Befehle
Hier sind die wichtigsten Bash-Konzepte und Befehle für die Übungen:

1. **Funktionen in Bash**:
   - `function_name() { ... }`: Definiert eine Funktion.
   - `$1`, `$2`, ...: Zugriff auf Funktionsparameter.
   - `return <code>`: Gibt einen Exit-Code zurück (0-255).
   - `echo`: Gibt Werte zurück (für Daten statt Exit-Codes).
2. **Fehlerbehandlung**:
   - `$?`: Prüft den Exit-Code des letzten Befehls.
   - `if [ condition ]; then ...; fi`: Prüft Bedingungen (z. B. Dateiexistenz).
   - `exit <code>`: Beendet das Skript mit einem Exit-Code.
3. **Logging**:
   - `echo "Nachricht" >> logfile`: Protokolliert in eine Datei.
   - `logger`: Sendet Nachrichten an das System-Log.
4. **JSON-Verarbeitung**:
   - `jq '.'`: Formatiert JSON-Daten.
   - `jq '.[] | select(.key == value)'`: Filtert JSON-Daten.
5. **Nützliche Zusatzbefehle**:
   - `man bash`: Dokumentation für Bash.
   - `man jq`: Dokumentation für `jq`.
   - `date`: Fügt Zeitstempel in Protokollen hinzu.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Vorbereitung und Datensatz prüfen
**Ziel**: Erstelle eine Testumgebung und überprüfe die JSON-Datei.

1. **Schritt 1**: Erstelle ein Testverzeichnis:
   ```bash
   mkdir bash_functions
   cd bash_functions
   ```

2. **Schritt 2**: Kopiere oder erstelle die JSON-Datei:
   ```bash
   nano sample_data.json
   ```
   Füge den obigen JSON-Inhalt ein, speichere und schließe.

3. **Schritt 3**: Installiere `jq` und überprüfe die Datei:
   ```bash
   sudo apt install jq
   jq '.' sample_data.json
   ```

4. **Schritt 4**: Protokolliere die Vorbereitung:
   ```bash
   echo "Vorbereitung abgeschlossen am $(date)" > bash_log.txt
   jq -r '.[] | .event' sample_data.json >> bash_log.txt
   cat bash_log.txt
   ```
   **Beispielausgabe**:
   ```
   Vorbereitung abgeschlossen am Fri Sep  5 13:10:00 CEST 2025
   LOGIN
   ERROR
   VIEW_PAGE
   PURCHASE
   LOGOUT
   ```

**Reflexion**: Warum ist `jq` für JSON-Verarbeitung in Bash nützlich? Nutze `man jq` und überlege, wie du andere Dateiformate prüfst.

### Übung 2: Funktionen definieren und nutzen
**Ziel**: Definiere Bash-Funktionen zur Datenanalyse und wende sie auf den Datensatz an.

1. **Schritt 1**: Erstelle ein Skript mit Funktionen:
   ```bash
   nano analyze_functions.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash

   # Funktion zum Laden der JSON-Datei
   load_data() {
       local file="$1"
       if [ -f "$file" ]; then
           jq '.' "$file" > /dev/null 2>&1
           if [ $? -eq 0 ]; then
               echo "Daten geladen: $file"
           else
               echo "Fehler: Ungültiges JSON-Format in $file"
               return 1
           fi
       else
           echo "Fehler: Datei $file nicht gefunden"
           return 1
       fi
   }

   # Funktion zum Zählen von Ereignissen
   count_events() {
       local file="$1"
       local event_type="$2"
       if [ -z "$event_type" ]; then
           jq -r '.[] | .event' "$file" | wc -l
       else
           jq -r ".[] | select(.event == \"$event_type\") | .event" "$file" | wc -l
       fi
   }

   # Funktion zum Abrufen von Ereignissen eines Benutzers
   get_user_events() {
       local file="$1"
       local user_id="$2"
       jq -r ".[] | select(.user_id == $user_id) | .event" "$file" | tr '\n' ',' | sed 's/,$//'
   }

   # Hauptprogramm
   input_file="sample_data.json"
   load_data "$input_file"
   if [ $? -eq 0 ]; then
       total_events=$(count_events "$input_file")
       error_count=$(count_events "$input_file" "ERROR")
       user_1_events=$(get_user_events "$input_file" 1)
       echo "Gesamtereignisse: $total_events"
       echo "Fehlerereignisse: $error_count"
       echo "Ereignisse für User 1: $user_1_events"
   else
       echo "Analyse abgebrochen."
   fi
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   chmod +x analyze_functions.sh
   ./analyze_functions.sh > analyze_output.txt
   ```

3. **Schritt 3**: Protokolliere die Ergebnisse:
   ```bash
   echo "Funktionenanalyse am $(date)" >> bash_log.txt
   cat analyze_output.txt >> bash_log.txt
   cat bash_log.txt
   ```
   **Beispielausgabe**:
   ```
   Daten geladen: sample_data.json
   Gesamtereignisse: 5
   Fehlerereignisse: 1
   Ereignisse für User 1: LOGIN,VIEW_PAGE
   ```

**Reflexion**: Wie verbessern Funktionen die Struktur von Bash-Skripten? Nutze `man bash` und überlege, wie du weitere Funktionen (z. B. für Zeitstempel) hinzufügst.

### Übung 3: Fehlerbehandlung mit Exit-Codes und Bedingungen
**Ziel**: Ergänze Fehlerbehandlung, um Dateizugriffe und ungültige Eingaben abzusichern.

1. **Schritt 1**: Erstelle ein Skript mit robuster Fehlerbehandlung:
   ```bash
   nano analyze_functions_safe.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash

   # Funktion zum Laden der JSON-Datei
   load_data() {
       local file="$1"
       if [ ! -f "$file" ]; then
           echo "Fehler: Datei $file nicht gefunden" >&2
           return 1
       fi
       if ! jq '.' "$file" > /dev/null 2>&1; then
           echo "Fehler: Ungültiges JSON-Format in $file" >&2
           return 1
       fi
       echo "Daten geladen: $file"
       return 0
   }

   # Funktion zum Zählen von Ereignissen
   count_events() {
       local file="$1"
       local event_type="$2"
       if [ ! -f "$file" ]; then
           echo "Fehler: Datei $file nicht gefunden" >&2
           return 1
       fi
       if [ -z "$event_type" ]; then
           jq -r '.[] | .event' "$file" | wc -l
       else
           jq -r ".[] | select(.event == \"$event_type\") | .event" "$file" | wc -l
       fi
       return 0
   }

   # Funktion zum Abrufen von Ereignissen eines Benutzers
   get_user_events() {
       local file="$1"
       local user_id="$2"
       if [ ! -f "$file" ]; then
           echo "Fehler: Datei $file nicht gefunden" >&2
           return 1
       fi
       if ! [[ "$user_id" =~ ^[0-9]+$ ]]; then
           echo "Fehler: User ID muss eine Zahl sein" >&2
           return 1
       fi
       local events
       events=$(jq -r ".[] | select(.user_id == $user_id) | .event" "$file" | tr '\n' ',' | sed 's/,$//')
       if [ -z "$events" ]; then
           echo "Keine Ereignisse für User $user_id gefunden" >&2
           return 1
       fi
       echo "$events"
       return 0
   }

   # Hauptprogramm
   input_file="sample_data.json"
   load_data "$input_file"
   if [ $? -eq 0 ]; then
       total_events=$(count_events "$input_file")
       if [ $? -eq 0 ]; then
           echo "Gesamtereignisse: $total_events"
       fi
       error_count=$(count_events "$input_file" "ERROR")
       if [ $? -eq 0 ]; then
           echo "Fehlerereignisse: $error_count"
       fi
       user_1_events=$(get_user_events "$input_file" 1)
       if [ $? -eq 0 ]; then
           echo "Ereignisse für User 1: $user_1_events"
       fi
   else
       echo "Analyse abgebrochen."
       exit 1
   fi
   ```
   Speichere und schließe.

2. **Schritt 2**: Teste die Fehlerbehandlung:
   ```bash
   mv sample_data.json sample_data.json.bak
   ./analyze_functions_safe.sh > analyze_safe_output.txt
   mv sample_data.json.bak sample_data.json
   ```

3. **Schritt 3**: Protokolliere die Ergebnisse:
   ```bash
   echo "Fehlerbehandlungsanalyse am $(date)" >> bash_log.txt
   cat analyze_safe_output.txt >> bash_log.txt
   cat bash_log.txt
   ```
   **Beispielausgabe** (bei fehlender Datei):
   ```
   Fehler: Datei sample_data.json nicht gefunden
   Analyse abgebrochen.
   ```

**Reflexion**: Wie macht Fehlerbehandlung Bash-Skripte robuster? Nutze `man bash` und überlege, wie du weitere Bedingungen prüfst.

### Übung 4: Logging und Exit-Codes
**Ziel**: Implementiere Logging und verfeinere die Fehlerbehandlung mit Exit-Codes.

1. **Schritt 1**: Erstelle ein Skript mit Logging:
   ```bash
   nano analyze_functions_logging.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash

   # Log-Datei
   LOG_FILE="analysis.log"

   # Funktion zum Logging
   log_message() {
       local level="$1"
       local message="$2"
       echo "$(date '+%Y-%m-%d %H:%M:%S') - $level - $message" >> "$LOG_FILE"
   }

   # Funktion zum Laden der JSON-Datei
   load_data() {
       local file="$1"
       if [ ! -f "$file" ]; then
           log_message "ERROR" "Datei $file nicht gefunden"
           echo "Fehler: Datei $file nicht gefunden" >&2
           return 1
       fi
       if ! jq '.' "$file" > /dev/null 2>&1; then
           log_message "ERROR" "Ungültiges JSON-Format in $file"
           echo "Fehler: Ungültiges JSON-Format in $file" >&2
           return 1
       fi
       log_message "INFO" "Daten geladen: $file"
       echo "Daten geladen: $file"
       return 0
   }

   # Funktion zum Zählen von Ereignissen
   count_events() {
       local file="$1"
       local event_type="$2"
       if [ ! -f "$file" ]; then
           log_message "ERROR" "Datei $file nicht gefunden"
           echo "Fehler: Datei $file nicht gefunden" >&2
           return 1
       fi
       local count
       if [ -z "$event_type" ]; then
           count=$(jq -r '.[] | .event' "$file" | wc -l)
       else
           count=$(jq -r ".[] | select(.event == \"$event_type\") | .event" "$file" | wc -l)
       fi
       echo "$count"
       log_message "INFO" "Ereignisse gezählt: $count (Typ: ${event_type:-Alle})"
       return 0
   }

   # Funktion zum Abrufen von Ereignissen eines Benutzers
   get_user_events() {
       local file="$1"
       local user_id="$2"
       if [ ! -f "$file" ]; then
           log_message "ERROR" "Datei $file nicht gefunden"
           echo "Fehler: Datei $file nicht gefunden" >&2
           return 1
       fi
       if ! [[ "$user_id" =~ ^[0-9]+$ ]]; then
           log_message "ERROR" "User ID muss eine Zahl sein"
           echo "Fehler: User ID muss eine Zahl sein" >&2
           return 1
       fi
       local events
       events=$(jq -r ".[] | select(.user_id == $user_id) | .event" "$file" | tr '\n' ',' | sed 's/,$//')
       if [ -z "$events" ]; then
           log_message "WARNING" "Keine Ereignisse für User $user_id gefunden"
           echo "Keine Ereignisse für User $user_id gefunden" >&2
           return 1
       fi
       echo "$events"
       log_message "INFO" "Ereignisse für User $user_id: $events"
       return 0
   }

   # Hauptprogramm
   log_message "INFO" "Starte Analyse"
   input_file="sample_data.json"
   load_data "$input_file"
   if [ $? -eq 0 ]; then
       total_events=$(count_events "$input_file")
       if [ $? -eq 0 ]; then
           echo "Gesamtereignisse: $total_events"
       fi
       error_count=$(count_events "$input_file" "ERROR")
       if [ $? -eq 0 ]; then
           echo "Fehlerereignisse: $error_count"
       fi
       user_1_events=$(get_user_events "$input_file" 1)
       if [ $? -eq 0 ]; then
           echo "Ereignisse für User 1: $user_1_events"
       fi
   else
       log_message "ERROR" "Analyse abgebrochen wegen fehlerhafter Daten"
       echo "Analyse abgebrochen."
       exit 1
   fi
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   chmod +x analyze_functions_logging.sh
   ./analyze_functions_logging.sh > analyze_logging_output.txt
   ```

3. **Schritt 3**: Überprüfe das Log:
   ```bash
   cat analysis.log
   ```

4. **Schritt 4**: Protokolliere die Ergebnisse:
   ```bash
   echo "Logging-Analyse am $(date)" >> bash_log.txt
   cat analyze_logging_output.txt >> bash_log.txt
   cat bash_log.txt
   ```

**Reflexion**: Wie verbessert Logging die Nachvollziehbarkeit in Bash? Nutze `man logger` und überlege, wie du System-Logs integrierst.

### Übung 5: Spielerei – Markdown-Bericht mit Funktionen und Fehlerbehandlung
**Ziel**: Erstelle ein Markdown-Dokument mit Analyseergebnissen, das Funktionen und Fehlerbehandlung nutzt.

1. **Schritt 1**: Erstelle ein Skript für die Markdown-Ausgabe:
   ```bash
   nano summary_functions.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash

   # Log-Datei
   LOG_FILE="analysis.log"

   # Funktion zum Logging
   log_message() {
       local level="$1"
       local message="$2"
       echo "$(date '+%Y-%m-%d %H:%M:%S') - $level - $message" >> "$LOG_FILE"
   }

   # Funktion zum Laden der JSON-Datei
   load_data() {
       local file="$1"
       if [ ! -f "$file" ]; then
           log_message "ERROR" "Datei $file nicht gefunden"
           echo "Fehler: Datei $file nicht gefunden" >&2
           return 1
       fi
       if ! jq '.' "$file" > /dev/null 2>&1; then
           log_message "ERROR" "Ungültiges JSON-Format in $file"
           echo "Fehler: Ungültiges JSON-Format in $file" >&2
           return 1
       fi
       log_message "INFO" "Daten geladen: $file"
       echo "Daten geladen: $file"
       return 0
   }

   # Funktion zum Zählen von Ereignissen
   count_events() {
       local file="$1"
       local event_type="$2"
       if [ ! -f "$file" ]; then
           log_message "ERROR" "Datei $file nicht gefunden"
           echo "Fehler: Datei $file nicht gefunden" >&2
           return 1
       fi
       local count
       if [ -z "$event_type" ]; then
           count=$(jq -r '.[] | .event' "$file" | wc -l)
       else
           count=$(jq -r ".[] | select(.event == \"$event_type\") | .event" "$file" | wc -l)
       fi
       echo "$count"
       log_message "INFO" "Ereignisse gezählt: $count (Typ: ${event_type:-Alle})"
       return 0
   }

   # Funktion zum Abrufen von Ereignissen eines Benutzers
   get_user_events() {
       local file="$1"
       local user_id="$2"
       if [ ! -f "$file" ]; then
           log_message "ERROR" "Datei $file nicht gefunden"
           echo "Fehler: Datei $file nicht gefunden" >&2
           return 1
       fi
       if ! [[ "$user_id" =~ ^[0-9]+$ ]]; then
           log_message "ERROR" "User ID muss eine Zahl sein"
           echo "Fehler: User ID muss eine Zahl sein" >&2
           return 1
       fi
       local events
       events=$(jq -r ".[] | select(.user_id == $user_id) | .event" "$file" | tr '\n' ',' | sed 's/,$//')
       if [ -z "$events" ]; then
           log_message "WARNING" "Keine Ereignisse für User $user_id gefunden"
           echo "Keine Ereignisse für User $user_id gefunden" >&2
           return 1
       fi
       echo "$events"
       log_message "INFO" "Ereignisse für User $user_id: $events"
       return 0
   }

   # Funktion zum Erstellen eines Markdown-Berichts
   generate_markdown_report() {
       local file="$1"
       local output_file="$2"
       load_data "$file"
       if [ $? -ne 0 ]; then
           log_message "ERROR" "Berichtserstellung abgebrochen wegen fehlerhafter Daten"
           echo "Fehler: Berichtserstellung abgebrochen" >&2
           return 1
       fi

       local total_events error_count user_ids user_id events
       total_events=$(count_events "$file")
       if [ $? -ne 0 ]; then
           return 1
       fi
       error_count=$(count_events "$file" "ERROR")
       if [ $? -ne 0 ]; then
           return 1
       fi

       # Erstelle Markdown-Bericht
       {
           echo "# Datenanalyse-Bericht"
           echo "Erstellt am: $(date '+%Y-%m-%d %H:%M:%S')"
           echo ""
           echo "## Analyseergebnisse"
           echo "| Metrik | Wert |"
           echo "|--------|------|"
           echo "| Gesamtereignisse | $total_events |"
           echo "| Fehlerereignisse | $error_count |"
           echo ""
           echo "## Ereignisse pro Benutzer"
           echo "| User ID | Ereignisse |"
           echo "|---------|------------|"
           user_ids=$(jq -r '.[] | .user_id' "$file" | sort -u)
           for user_id in $user_ids; do
               events=$(get_user_events "$file" "$user_id")
               if [ $? -eq 0 ]; then
                   echo "| $user_id | $events |"
               fi
           done
       } > "$output_file"

       log_message "INFO" "Markdown-Bericht erstellt: $output_file"
       echo "Bericht erstellt: $output_file"
       return 0
   }

   # Hauptprogramm
   log_message "INFO" "Starte Analyse und Berichtserstellung"
   input_file="sample_data.json"
   generate_markdown_report "$input_file" "analysis_report.md"
   if [ $? -eq 0 ]; then
       cat analysis_report.md
   else
       echo "Analyse abgebrochen."
       exit 1
   fi
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   chmod +x summary_functions.sh
   ./summary_functions.sh > summary_output.txt
   ```

3. **Schritt 3**: Überprüfe den Bericht:
   ```bash
   cat analysis_report.md
   ```
   **Beispielausgabe** (`analysis_report.md`):
   ```
   # Datenanalyse-Bericht
   Erstellt am: 2025-09-05 13:15:00

   ## Analyseergebnisse
   | Metrik | Wert |
   |--------|------|
   | Gesamtereignisse | 5 |
   | Fehlerereignisse | 1 |

   ## Ereignisse pro Benutzer
   | User ID | Ereignisse |
   |---------|------------|
   | 1 | LOGIN,VIEW_PAGE |
   | 2 | ERROR,LOGOUT |
   | 3 | PURCHASE |
   ```

4. **Schritt 4**: Protokolliere die Ergebnisse:
   ```bash
   echo "Markdown-Bericht erstellt am $(date)" >> bash_log.txt
   cat summary_output.txt >> bash_log.txt
   cat bash_log.txt
   ```

**Reflexion**: Wie verbessert die Kombination von Funktionen, Fehlerbehandlung und Markdown die Dokumentation? Nutze `man bash` und überlege, wie du Visualisierungen oder E-Mail-Versand integrierst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Bash-Funktionen und Fehlerbehandlung zu verinnerlichen.
- **Sicheres Testen**: Arbeite in einer Testumgebung und sichere Dateien (`cp sample_data.json sample_data.json.bak`).
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze `man bash` oder `man jq` für Details.
- **Effiziente Entwicklung**: Nutze Funktionen für Modularität, Exit-Codes für Fehlerbehandlung und Logging für Nachvollziehbarkeit.
- **Kombiniere Tools**: Integriere `awk` oder `sed` für erweiterte Textverarbeitung oder `mail` für E-Mail-Versand.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Hinzufügen von Visualisierungen (via `gnuplot`) oder System-Logs (`logger`).

## Fazit
Mit diesen Übungen hast du gelernt, Funktionen in Bash zu definieren und zu nutzen, Fehler mit Exit-Codes und Bedingungen zu behandeln, Logging für Nachvollziehbarkeit einzusetzen und Ergebnisse in Markdown zu dokumentieren. Die Spielerei zeigt, wie du diese Konzepte kombinierst, um einen robusten Analyse-Skript zu erstellen. Vertiefe dein Wissen, indem du fortgeschrittene Themen (z. B. Parametererweiterung, komplexe `jq`-Abfragen) oder Tools wie `gnuplot` oder `mail` ausprobierst. Wenn du ein spezifisches Thema (z. B. Visualisierung oder E-Mail-Versand) vertiefen möchtest, lass es mich wissen!
