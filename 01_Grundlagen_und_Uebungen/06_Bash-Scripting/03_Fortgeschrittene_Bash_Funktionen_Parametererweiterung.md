# Praxisorientierte Anleitung: Fortgeschrittene Bash-Features (Funktionen mit Rückgabewerten und Parametererweiterung)

## Einführung
Fortgeschrittene Bash-Features wie **Funktionen mit Rückgabewerten** und **Parametererweiterung** ermöglichen modularen, flexiblen und robusten Code. Diese Anleitung baut auf der vorherigen Anleitung zu Arrays und regulären Ausdrücken auf und konzentriert sich auf **Funktionen mit Rückgabewerten für strukturierte Logik**, **Parametererweiterung für flexible Datenverarbeitung** und **Integration mit Redis**. Die Beispielanwendung ist eine **To-Do-Listen-Verwaltung**, die Aufgaben mit Prioritäten und Kategorien in einer Datei oder Redis speichert, sucht und anzeigt. Eine **Spielerei** zeigt, wie du Aufgaben als Markdown-Tabelle mit Prioritäten und Kategorien exportierst, um die Verbindung zu vorherigen Themen (z. B. Markdown-Ausgabe) herzustellen. Durch praktische Übungen lernst du, fortgeschrittene Bash-Techniken anzuwenden.

**Voraussetzungen**:
- Ein System mit Linux oder macOS (z. B. Ubuntu 22.04, macOS Ventura) oder Windows mit WSL2.
- Ein Terminal (z. B. Bash auf Linux/macOS, PowerShell/WSL2 auf Windows).
- Bash installiert (standardmäßig auf Linux/macOS; auf Windows via WSL2: `wsl --install`).
- Optional: Redis installiert für Übung 3 (z. B. `sudo apt install redis-server` auf Ubuntu, `brew install redis` auf macOS, oder via Docker: `docker run -d -p 6379:6379 redis`).
- Grundkenntnisse in Bash (Arrays, reguläre Ausdrücke, `grep`, `sed`) und Linux-Befehlen.
- Sichere Testumgebung (z. B. `$HOME/bash_functions` oder `~/bash_functions`).
- Ein Texteditor (z. B. `nano`, `vim` oder VS Code).

## Grundlegende Befehle
Hier sind die wichtigsten Konzepte und Befehle für Funktionen mit Rückgabewerten und Parametererweiterung:

1. **Funktionen mit Rückgabewerten**:
   - `return <n>`: Setzt den Exit-Code einer Funktion (0-255, 0 = Erfolg).
   - `echo` in Funktionen: Gibt Werte zurück, die mit `$(funktion)` erfasst werden.
   - `local`: Definiert lokale Variablen in Funktionen.
2. **Parametererweiterung**:
   - `${var:-default}`: Gibt Standardwert, wenn `var` nicht gesetzt ist.
   - `${var//pattern/replacement}`: Ersetzt alle Vorkommen eines Musters.
   - `${var#pattern}`: Entfernt das kürzeste Muster von vorne.
   - `${var##pattern}`: Entfernt das längste Muster von vorne.
   - `${var:offset:length}`: Extrahiert Teilstrings.
3. **Integration mit Tools**:
   - `redis-cli`: Interagiert mit Redis-Hashes.
   - `awk`/`sed`: Verarbeitet Daten mit Parametererweiterung.
4. **Nützliche Zusatzbefehle**:
   - `man bash`: Zeigt Bash-Dokumentation (Abschnitte zu Funktionen und Parametererweiterung).
   - `help return`: Zeigt Hilfe für Rückgabewerte.
   - `man redis-cli`: Zeigt Redis-Befehle.
   - `set -e`: Beendet Skript bei Fehlern.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Funktionen mit Rückgabewerten
**Ziel**: Verwende Funktionen mit Rückgabewerten, um Aufgaben in einer Datei zu verwalten.

1. **Schritt 1**: Erstelle ein Projektverzeichnis:
   ```bash
   mkdir bash_functions
   cd bash_functions
   ```

2. **Schritt 2**: Erstelle ein Bash-Skript mit Funktionen:
   ```bash
   nano todo_functions.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash

   TODO_FILE="tasks.txt"

   # Erstelle die Datei, falls sie nicht existiert
   touch "$TODO_FILE"
   chmod 600 "$TODO_FILE"

   # Funktion zum Validieren der Priorität
   validate_priority() {
       local priority="$1"
       if [[ "$priority" =~ ^[1-5]$ ]]; then
           echo "valid"
           return 0
       else
           echo "invalid"
           return 1
       fi
   }

   # Funktion zum Formatieren einer Aufgabe
   format_task() {
       local id="$1" date="$2" task="$3" priority="$4" status="$5"
       printf "%-2s | %s | %-20s | %-9s | %s\n" "$id" "$date" "${task:0:20}" "$priority" "$status"
   }

   # Funktion zum Hinzufügen einer Aufgabe
   add_task() {
       local task="$1" priority="${2:-1}" # Standardpriorität 1
       if [ -z "$task" ]; then
           echo "Fehler: Bitte eine Aufgabe angeben." >&2
           return 1
       fi
       if [ "$(validate_priority "$priority")" != "valid" ]; then
           echo "Fehler: Priorität muss zwischen 1 und 5 liegen." >&2
           return 1
       fi
       echo "$(date '+%Y-%m-%d %H:%M:%S')|$task|$priority|offen" >> "$TODO_FILE"
       echo "Aufgabe hinzugefügt: $task (Priorität: $priority)"
       return 0
   }

   # Funktion zum Anzeigen aller Aufgaben
   list_tasks() {
       if [ ! -s "$TODO_FILE" ]; then
           echo "Keine Aufgaben vorhanden."
           return 1
       fi
       echo "Aufgaben:"
       echo "ID | Datum | Aufgabe | Priorität | Status"
       echo "---------------------------------------"
       local i=1
       while IFS='|' read -r date task priority status; do
           format_task "$i" "$date" "$task" "$priority" "$status"
           ((i++))
       done < "$TODO_FILE"
       return 0
   }

   # Hauptlogik
   case "$1" in
       add)
           add_task "$2" "$3"
           ;;
       list)
           list_tasks
           ;;
       *)
           echo "Verwendung: $0 {add <Aufgabe> [<Priorität>] | list}"
           exit 1
           ;;
   esac
   ```
   Speichere und schließe.

3. **Schritt 3**: Mache das Skript ausführbar:
   ```bash
   chmod +x todo_functions.sh
   ```

4. **Schritt 4**: Teste das Skript:
   - Füge Aufgaben hinzu:
     ```bash
     ./todo_functions.sh add "Einkaufen gehen" 2
     ./todo_functions.sh add "Python lernen"
     ```
   - Zeige die Aufgaben:
     ```bash
     ./todo_functions.sh list
     ```
     Die Ausgabe sollte so aussehen:
     ```
     Aufgaben:
     ID | Datum | Aufgabe | Priorität | Status
     ---------------------------------------
     1  | 2025-09-04 13:53:00 | Einkaufen gehen      | 2         | offen
     2  | 2025-09-04 13:53:05 | Python lernen        | 1         | offen
     ```

5. **Schritt 5**: Überprüfe die Datei:
   ```bash
   cat tasks.txt
   ```

**Reflexion**: Wie verbessern Rückgabewerte die Fehlersuche? Nutze `help return` und überlege, wie du Funktionen für komplexere Validierungen nutzen kannst.

### Übung 2: Parametererweiterung für flexible Datenverarbeitung
**Ziel**: Erweitere das Skript mit Parametererweiterung für Suche und Erledigen.

1. **Schritt 1**: Erweitere das Skript:
   ```bash
   nano todo_functions.sh
   ```
   Ersetze den Inhalt durch:
   ```bash
   #!/bin/bash

   TODO_FILE="tasks.txt"

   # Erstelle die Datei, falls sie nicht existiert
   touch "$TODO_FILE"
   chmod 600 "$TODO_FILE"

   # Funktion zum Validieren der Priorität
   validate_priority() {
       local priority="$1"
       if [[ "$priority" =~ ^[1-5]$ ]]; then
           echo "valid"
           return 0
       else
           echo "invalid"
           return 1
       fi
   }

   # Funktion zum Validieren der Kategorie
   validate_category() {
       local category="${1:-default}" # Standardkategorie
       category="${category//[^a-zA-Z0-9]/_}" # Ersetze ungültige Zeichen
       echo "$category"
       return 0
   }

   # Funktion zum Formatieren einer Aufgabe
   format_task() {
       local id="$1" date="$2" task="$3" priority="$4" status="$5" category="$6"
       printf "%-2s | %s | %-20s | %-9s | %-8s | %s\n" "$id" "$date" "${task:0:20}" "$priority" "$status" "$category"
   }

   # Funktion zum Hinzufügen einer Aufgabe
   add_task() {
       local task="$1" priority="${2:-1}" category="$3"
       if [ -z "$task" ]; then
           echo "Fehler: Bitte eine Aufgabe angeben." >&2
           return 1
       fi
       if [ "$(validate_priority "$priority")" != "valid" ]; then
           echo "Fehler: Priorität muss zwischen 1 und 5 liegen." >&2
           return 1
       fi
       category=$(validate_category "$category")
       echo "$(date '+%Y-%m-%d %H:%M:%S')|$task|$priority|offen|$category" >> "$TODO_FILE"
       echo "Aufgabe hinzugefügt: $task (Priorität: $priority, Kategorie: $category)"
       return 0
   }

   # Funktion zum Anzeigen aller Aufgaben
   list_tasks() {
       if [ ! -s "$TODO_FILE" ]; then
           echo "Keine Aufgaben vorhanden."
           return 1
       fi
       echo "Aufgaben:"
       echo "ID | Datum | Aufgabe | Priorität | Status | Kategorie"
       echo "-----------------------------------------------"
       local i=1
       while IFS='|' read -r date task priority status category; do
           format_task "$i" "$date" "$task" "$priority" "$status" "$category"
           ((i++))
       done < "$TODO_FILE"
       return 0
   }

   # Funktion zum Markieren einer Aufgabe als erledigt
   complete_task() {
       local id="$1"
       if [ -z "$id" ] || ! [[ "$id" =~ ^[0-9]+$ ]]; then
           echo "Fehler: Bitte eine gültige ID angeben." >&2
           return 1
       fi
       if [ "$id" -gt "$(wc -l < "$TODO_FILE")" ] || [ "$id" -lt 1 ]; then
           echo "Fehler: Ungültige ID." >&2
           return 1
       fi
       sed -i "${id}s/|offen|/|erledigt|/" "$TODO_FILE"
       echo "Aufgabe $id erledigt."
       return 0
   }

   # Funktion zum Suchen nach Aufgaben
   search_tasks() {
       local query="${1:-.*}" # Standard: alle Aufgaben
       if [ ! -s "$TODO_FILE" ]; then
           echo "Keine Aufgaben vorhanden."
           return 1
       fi
       echo "Gefundene Aufgaben:"
       echo "ID | Datum | Aufgabe | Priorität | Status | Kategorie"
       echo "-----------------------------------------------"
       local i=1
       while IFS='|' read -r date task priority status category; do
           if [[ "$task" =~ $query ]]; then
               format_task "$i" "$date" "$task" "$priority" "$status" "$category"
           fi
           ((i++))
       done < "$TODO_FILE"
       return 0
   }

   # Hauptlogik
   case "$1" in
       add)
           add_task "$2" "$3" "$4"
           ;;
       list)
           list_tasks
           ;;
       complete)
           complete_task "$2"
           ;;
       search)
           search_tasks "$2"
           ;;
       *)
           echo "Verwendung: $0 {add <Aufgabe> [<Priorität>] [<Kategorie>] | list | complete <ID> | search [<Regex>]}"
           exit 1
           ;;
   esac
   ```
   Speichere und schließe.

2. **Schritt 2**: Teste das Skript:
   - Füge Aufgaben hinzu:
     ```bash
     ./todo_functions.sh add "Einkaufen gehen" 2 Lebensmittel
     ./todo_functions.sh add "Python lernen" 1 Programmieren
     ```
   - Markiere eine Aufgabe als erledigt:
     ```bash
     ./todo_functions.sh complete 1
     ```
   - Suche mit regulären Ausdrücken:
     ```bash
     ./todo_functions.sh search "[a-zA-Z]+en"
     ```
     Die Ausgabe sollte so aussehen:
     ```
     Gefundene Aufgaben:
     ID | Datum | Aufgabe | Priorität | Status | Kategorie
     -----------------------------------------------
     1  | 2025-09-04 13:53:00 | Einkaufen gehen      | 2         | erledigt | Lebensmittel
     2  | 2025-09-04 13:53:05 | Python lernen        | 1         | offen    | Programmieren
     ```

**Reflexion**: Wie erleichtert Parametererweiterung die Datenverarbeitung? Nutze `man bash` (Abschnitt zu Parametererweiterung) und überlege, wie du Kategorien für Filterung nutzen kannst.

### Übung 3: Integration mit Redis und Spielerei
**Ziel**: Integriere Redis-Hashes mit Funktionen und Parametererweiterung und exportiere Aufgaben als Markdown.

1. **Schritt 1**: Stelle sicher, dass Redis läuft:
   ```bash
   redis-server &  # Starte Redis im Hintergrund
   redis-cli ping  # Prüfe mit "PONG"
   ```

2. **Schritt 2**: Erstelle ein Skript für Redis-Integration:
   ```bash
   nano todo_redis_functions.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash

   LIST_KEY="tasks_list"
   REDIS_CLI="redis-cli"

   # Funktion zum Validieren der Priorität
   validate_priority() {
       local priority="$1"
       if [[ "$priority" =~ ^[1-5]$ ]]; then
           echo "valid"
           return 0
       else
           echo "invalid"
           return 1
       fi
   }

   # Funktion zum Validieren der Kategorie
   validate_category() {
       local category="${1:-default}" # Standardkategorie
       category="${category//[^a-zA-Z0-9]/_}" # Ersetze ungültige Zeichen
       echo "$category"
       return 0
   }

   # Funktion zum Formatieren einer Aufgabe
   format_task() {
       local id="$1" created="$2" task="$3" priority="$4" status="$5" category="$6"
       printf "%-2s | %s | %-20s | %-9s | %-8s | %s\n" "$id" "$created" "${task:0:20}" "$priority" "$status" "$category"
   }

   # Funktion zum Hinzufügen einer Aufgabe in Redis
   add_task_redis() {
       local task="$1" priority="${2:-1}" category="$3"
       if [ -z "$task" ]; then
           echo "Fehler: Bitte eine Aufgabe angeben." >&2
           return 1
       fi
       if [ "$(validate_priority "$priority")" != "valid" ]; then
           echo "Fehler: Priorität muss zwischen 1 und 5 liegen." >&2
           return 1
       fi
       category=$(validate_category "$category")
       task_id=$($REDIS_CLI INCR task_id_counter)
       $REDIS_CLI HMSET "task:$task_id" task "$task" priority "$priority" status "offen" created "$(date '+%Y-%m-%d %H:%M:%S')" category "$category"
       $REDIS_CLI LPUSH "$LIST_KEY" "$task_id"
       $REDIS_CLI EXPIRE "task:$task_id" 3600
       $REDIS_CLI EXPIRE "$LIST_KEY" 3600
       echo "Aufgabe hinzugefügt: $task (ID: $task_id, Priorität: $priority, Kategorie: $category)"
       return 0
   }

   # Funktion zum Anzeigen aller Aufgaben
   list_tasks_redis() {
       task_ids=$($REDIS_CLI LRANGE "$LIST_KEY" 0 -1)
       if [ -z "$task_ids" ]; then
           echo "Keine Aufgaben vorhanden."
           return 1
       fi
       echo "Aufgaben:"
       echo "ID | Datum | Aufgabe | Priorität | Status | Kategorie"
       echo "-----------------------------------------------"
       local id=1
       for task_id in $task_ids; do
           task_data=$($REDIS_CLI HGETALL "task:$task_id")
           task=$(echo "$task_data" | grep -A1 "^task$" | tail -n1)
           priority=$(echo "$task_data" | grep -A1 "^priority$" | tail -n1)
           status=$(echo "$task_data" | grep -A1 "^status$" | tail -n1)
           created=$(echo "$task_data" | grep -A1 "^created$" | tail -n1)
           category=$(echo "$task_data" | grep -A1 "^category$" | tail -n1)
           format_task "$id" "$created" "$task" "$priority" "$status" "$category"
           ((id++))
       done
       return 0
   }

   # Funktion zum Markieren einer Aufgabe als erledigt
   complete_task_redis() {
       local id="$1"
       if [ -z "$id" ] || ! [[ "$id" =~ ^[0-9]+$ ]]; then
           echo "Fehler: Bitte eine gültige ID angeben." >&2
           return 1
       fi
       task_ids=$($REDIS_CLI LRANGE "$LIST_KEY" 0 -1)
       task_count=$(echo "$task_ids" | wc -l)
       if [ "$id" -gt "$task_count" ] || [ "$id" -lt 1 ]; then
           echo "Fehler: Ungültige ID." >&2
           return 1
       fi
       index=$((task_count - id))
       task_id=$(echo "$task_ids" | sed -n "$((index + 1))p")
       $REDIS_CLI HSET "task:$task_id" status "erledigt"
       $REDIS_CLI EXPIRE "task:$task_id" 3600
       echo "Aufgabe $task_id erledigt."
       return 0
   }

   # Funktion zum Suchen nach Aufgaben
   search_tasks_redis() {
       local query="${1:-.*}"
       task_ids=$($REDIS_CLI LRANGE "$LIST_KEY" 0 -1)
       if [ -z "$task_ids" ]; then
           echo "Keine Aufgaben vorhanden."
           return 1
       fi
       echo "Gefundene Aufgaben:"
       echo "ID | Datum | Aufgabe | Priorität | Status | Kategorie"
       echo "-----------------------------------------------"
       local id=1
       for task_id in $task_ids; do
           task_data=$($REDIS_CLI HGETALL "task:$task_id")
           task=$(echo "$task_data" | grep -A1 "^task$" | tail -n1)
           if [[ "$task" =~ $query ]]; then
               priority=$(echo "$task_data" | grep -A1 "^priority$" | tail -n1)
               status=$(echo "$task_data" | grep -A1 "^status$" | tail -n1)
               created=$(echo "$task_data" | grep -A1 "^created$" | tail -n1)
               category=$(echo "$task_data" | grep -A1 "^category$" | tail -n1)
               format_task "$id" "$created" "$task" "$priority" "$status" "$category"
           fi
           ((id++))
       done
       return 0
   }

   # Funktion zum Exportieren als Markdown
   export_markdown() {
       local output_file="${1:-tasks.md}"
       task_ids=$($REDIS_CLI LRANGE "$LIST_KEY" 0 -1)
       if [ -z "$task_ids" ]; then
           echo "Keine Aufgaben vorhanden." > "$output_file"
           echo "Keine Aufgaben vorhanden."
           return 1
       fi
       echo "# To-Do-Liste" > "$output_file"
       echo "" >> "$output_file"
       echo "| ID | Datum | Aufgabe | Priorität | Status | Kategorie |" >> "$output_file"
       echo "|---|-------|--------|-----------|--------|-----------|" >> "$output_file"
       local id=1
       for task_id in $task_ids; do
           task_data=$($REDIS_CLI HGETALL "task:$task_id")
           task=$(echo "$task_data" | grep -A1 "^task$" | tail -n1)
           priority=$(echo "$task_data" | grep -A1 "^priority$" | tail -n1)
           status=$(echo "$task_data" | grep -A1 "^status$" | tail -n1)
           created=$(echo "$task_data" | grep -A1 "^created$" | tail -n1)
           category=$(echo "$task_data" | grep -A1 "^category$" | tail -n1)
           echo "| $id | $created | $task | $priority | $status | $category |" >> "$output_file"
           ((id++))
       done
       cat "$output_file"
       return 0
   }

   # Hauptlogik
   case "$1" in
       add)
           add_task_redis "$2" "$3" "$4"
           ;;
       list)
           list_tasks_redis
           ;;
       complete)
           complete_task_redis "$2"
           ;;
       search)
           search_tasks_redis "$2"
           ;;
       export)
           export_markdown "$2"
           ;;
       *)
           echo "Verwendung: $0 {add <Aufgabe> [<Priorität>] [<Kategorie>] | list | complete <ID> | search [<Regex>] | export [<Datei>]}"
           exit 1
           ;;
   esac
   ```
   Speichere und schließe.

3. **Schritt 3**: Mache das Skript ausführbar:
   ```bash
   chmod +x todo_redis_functions.sh
   ```

4. **Schritt 4**: Teste das Skript:
   - Füge Aufgaben hinzu:
     ```bash
     ./todo_redis_functions.sh add "Einkaufen gehen" 2 Lebensmittel
     ./todo_redis_functions.sh add "Python lernen" 1 Programmieren
     ./todo_redis_functions.sh add "API testen" 3 Entwicklung
     ```
   - Markiere eine Aufgabe als erledigt:
     ```bash
     ./todo_redis_functions.sh complete 1
     ```
   - Suche mit regulären Ausdrücken:
     ```bash
     ./todo_redis_functions.sh search "[a-zA-Z]+en"
     ```
     Die Ausgabe sollte so aussehen:
     ```
     Gefundene Aufgaben:
     ID | Datum | Aufgabe | Priorität | Status | Kategorie
     -----------------------------------------------
     1  | 2025-09-04 13:53:00 | Einkaufen gehen      | 2         | erledigt | Lebensmittel
     2  | 2025-09-04 13:53:05 | Python lernen        | 1         | offen    | Programmieren
     ```
   - Exportiere als Markdown:
     ```bash
     ./todo_redis_functions.sh export my_tasks.md
     ```

5. **Spielerei**: Überprüfe die Markdown-Ausgabe:
   ```bash
   cat my_tasks.md
   ```
   Die Ausgabe sollte so aussehen:
   ```
   # To-Do-Liste

   | ID | Datum | Aufgabe | Priorität | Status | Kategorie |
   |---|-------|--------|-----------|--------|-----------|
   | 1 | 2025-09-04 13:53:00 | Einkaufen gehen | 2 | erledigt | Lebensmittel |
   | 2 | 2025-09-04 13:53:05 | Python lernen | 1 | offen | Programmieren |
   | 3 | 2025-09-04 13:53:10 | API testen | 3 | offen | Entwicklung |
   ```

6. **Schritt 5**: Überprüfe die Daten in Redis:
   ```bash
   redis-cli
   LRANGE tasks_list 0 -1
   HGETALL task:1
   ```

**Reflexion**: Wie verbessern Funktionen mit Rückgabewerten und Parametererweiterung die Wartbarkeit? Nutze `man bash` (Abschnitte zu Funktionen und Parametererweiterung) und überlege, wie du Parametererweiterung für Datenbereinigung nutzen kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Funktionen und Parametererweiterung zu verinnerlichen.
- **Sicheres Testen**: Nutze Testverzeichnisse und sichere Berechtigungen (`chmod 600`).
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze `man bash` oder `help return`.
- **Effiziente Entwicklung**: Verwende Funktionen für modulare Logik, Parametererweiterung für flexible Eingaben und Redis für schnelle Datenverwaltung.
- **Kombiniere Tools**: Integriere Bash-Skripte mit Flask-APIs oder GitHub Actions.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Hinzufügen von Sortierungsoptionen oder Löschfunktionen.

## Fazit
Mit diesen Übungen hast du fortgeschrittene Bash-Features wie Funktionen mit Rückgabewerten und Parametererweiterung gemeistert und eine To-Do-Listen-Verwaltung mit Dateien und Redis erstellt. Die Spielerei zeigt, wie du Aufgaben mit Prioritäten und Kategorien als Markdown exportierst. Vertiefe dein Wissen, indem du weitere Bash-Features (z. B. Traps, Coprocesses) oder Integrationen (z. B. mit Flask-APIs oder SQLite) ausprobierst. Wenn du ein spezifisches Thema (z. B. Bash-Traps oder API-Integration) vertiefen möchtest, lass es mich wissen!
