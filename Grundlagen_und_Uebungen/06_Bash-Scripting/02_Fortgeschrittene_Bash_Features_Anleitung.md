# Praxisorientierte Anleitung: Fortgeschrittene Bash-Features (Arrays und reguläre Ausdrücke)

## Einführung
Fortgeschrittene Bash-Features wie **Arrays** und **reguläre Ausdrücke** ermöglichen komplexere Datenverwaltung und Textverarbeitung in Skripten. Diese Anleitung baut auf der vorherigen Bash-Scripting-Anleitung auf und konzentriert sich auf **Arrays für strukturierte Daten**, **reguläre Ausdrücke für erweiterte Suche** und **Integration mit Tools wie Redis**. Die Beispielanwendung ist eine **To-Do-Listen-Verwaltung**, die Aufgaben mit Prioritäten in einer Datei oder Redis speichert, sucht und anzeigt. Eine **Spielerei** zeigt, wie du Aufgaben als Markdown-Tabelle mit Prioritäten exportierst, um die Verbindung zu vorherigen Themen (z. B. Markdown-Ausgabe) herzustellen. Durch praktische Übungen lernst du, fortgeschrittene Bash-Techniken anzuwenden.

**Voraussetzungen**:
- Ein System mit Linux oder macOS (z. B. Ubuntu 22.04, macOS Ventura) oder Windows mit WSL2.
- Ein Terminal (z. B. Bash auf Linux/macOS, PowerShell/WSL2 auf Windows).
- Bash installiert (standardmäßig auf Linux/macOS; auf Windows via WSL2: `wsl --install`).
- Optional: Redis installiert für Übung 3 (z. B. `sudo apt install redis-server` auf Ubuntu, `brew install redis` auf macOS, oder via Docker: `docker run -d -p 6379:6379 redis`).
- Grundkenntnisse in Bash (Variablen, Schleifen, `grep`, `sed`) und Linux-Befehlen.
- Sichere Testumgebung (z. B. `$HOME/bash_advanced` oder `~/bash_advanced`).
- Ein Texteditor (z. B. `nano`, `vim` oder VS Code).

## Grundlegende Befehle
Hier sind die wichtigsten Konzepte und Befehle für fortgeschrittene Bash-Features:

1. **Arrays in Bash**:
   - `declare -a array`: Deklariert ein indiziertes Array.
   - `array=(item1 item2)`: Initialisiert ein Array.
   - `${array[@]}`: Zugriff auf alle Elemente.
   - `${array[i]}`: Zugriff auf Element an Index `i`.
   - `${#array[@]}`: Gibt die Länge des Arrays zurück.
2. **Reguläre Ausdrücke**:
   - `=~`: Prüft, ob ein String einem regulären Ausdruck entspricht.
   - `grep -E`: Verwendet erweiterte reguläre Ausdrücke für Suche.
   - `sed -E`: Verwendet reguläre Ausdrücke für Textbearbeitung.
   - Beispiele: `[0-9]+` (Zahlen), `[a-zA-Z]+` (Buchstaben).
3. **Integration mit Tools**:
   - `redis-cli`: Interagiert mit Redis-Hashes.
   - `awk`/`sed`: Verarbeitet strukturierte Daten aus Arrays.
4. **Nützliche Zusatzbefehle**:
   - `man bash`: Zeigt Bash-Dokumentation (Abschnitt zu Arrays und `=~`).
   - `help declare`: Zeigt Hilfe für Array-Deklaration.
   - `man grep`: Zeigt Optionen für reguläre Ausdrücke.
   - `redis-cli HGETALL`: Ruft Hash-Daten ab.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Arrays für strukturierte Daten
**Ziel**: Verwende Bash-Arrays, um Aufgaben mit Prioritäten in einer Datei zu speichern und anzuzeigen.

1. **Schritt 1**: Erstelle ein Projektverzeichnis:
   ```bash
   mkdir bash_advanced
   cd bash_advanced
   ```

2. **Schritt 2**: Erstelle ein Bash-Skript mit Arrays:
   ```bash
   nano todo_arrays.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash

   TODO_FILE="tasks.txt"

   # Erstelle die Datei, falls sie nicht existiert
   touch "$TODO_FILE"
   chmod 600 "$TODO_FILE"

   # Funktion zum Hinzufügen einer Aufgabe
   add_task() {
       if [ -z "$1" ] || [ -z "$2" ]; then
           echo "Fehler: Bitte Aufgabe und Priorität (1-5) angeben."
           exit 1
       fi
       if ! [[ "$2" =~ ^[1-5]$ ]]; then
           echo "Fehler: Priorität muss zwischen 1 und 5 liegen."
           exit 1
       fi
       echo "$(date '+%Y-%m-%d %H:%M:%S')|$1|$2|offen" >> "$TODO_FILE"
       echo "Aufgabe hinzugefügt: $1 (Priorität: $2)"
   }

   # Funktion zum Anzeigen aller Aufgaben mit Arrays
   list_tasks() {
       if [ ! -s "$TODO_FILE" ]; then
           echo "Keine Aufgaben vorhanden."
           return
       fi
       declare -a tasks
       mapfile -t tasks < "$TODO_FILE"
       echo "Aufgaben:"
       echo "ID | Datum | Aufgabe | Priorität | Status"
       echo "---------------------------------------"
       for i in "${!tasks[@]}"; do
           IFS='|' read -r date task priority status <<< "${tasks[i]}"
           printf "%-2s | %s | %-20s | %-9s | %s\n" "$((i + 1))" "$date" "$task" "$priority" "$status"
       done
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
           echo "Verwendung: $0 {add <Aufgabe> <Priorität> | list}"
           exit 1
           ;;
   esac
   ```
   Speichere und schließe.

3. **Schritt 3**: Mache das Skript ausführbar:
   ```bash
   chmod +x todo_arrays.sh
   ```

4. **Schritt 4**: Teste das Skript:
   - Füge Aufgaben hinzu:
     ```bash
     ./todo_arrays.sh add "Einkaufen gehen" 2
     ./todo_arrays.sh add "Python lernen" 1
     ```
   - Zeige die Aufgaben:
     ```bash
     ./todo_arrays.sh list
     ```
     Die Ausgabe sollte so aussehen:
     ```
     Aufgaben:
     ID | Datum | Aufgabe | Priorität | Status
     ---------------------------------------
     1  | 2025-09-04 13:47:00 | Einkaufen gehen      | 2         | offen
     2  | 2025-09-04 13:47:05 | Python lernen        | 1         | offen
     ```

5. **Schritt 5**: Überprüfe die Datei:
   ```bash
   cat tasks.txt
   ```

**Reflexion**: Wie vereinfachen Arrays die Verarbeitung mehrerer Aufgaben? Nutze `help declare` und überlege, wie du Arrays für komplexere Datenstrukturen nutzen kannst.

### Übung 2: Reguläre Ausdrücke für erweiterte Suche
**Ziel**: Erweitere das Skript, um Aufgaben mit regulären Ausdrücken zu suchen und zu erledigen.

1. **Schritt 1**: Erweitere das Skript mit regulären Ausdrücken:
   ```bash
   nano todo_arrays.sh
   ```
   Ersetze den Inhalt durch:
   ```bash
   #!/bin/bash

   TODO_FILE="tasks.txt"

   # Erstelle die Datei, falls sie nicht existiert
   touch "$TODO_FILE"
   chmod 600 "$TODO_FILE"

   # Funktion zum Hinzufügen einer Aufgabe
   add_task() {
       if [ -z "$1" ] || [ -z "$2" ]; then
           echo "Fehler: Bitte Aufgabe und Priorität (1-5) angeben."
           exit 1
       fi
       if ! [[ "$2" =~ ^[1-5]$ ]]; then
           echo "Fehler: Priorität muss zwischen 1 und 5 liegen."
           exit 1
       fi
       echo "$(date '+%Y-%m-%d %H:%M:%S')|$1|$2|offen" >> "$TODO_FILE"
       echo "Aufgabe hinzugefügt: $1 (Priorität: $2)"
   }

   # Funktion zum Anzeigen aller Aufgaben mit Arrays
   list_tasks() {
       if [ ! -s "$TODO_FILE" ]; then
           echo "Keine Aufgaben vorhanden."
           return
       fi
       declare -a tasks
       mapfile -t tasks < "$TODO_FILE"
       echo "Aufgaben:"
       echo "ID | Datum | Aufgabe | Priorität | Status"
       echo "---------------------------------------"
       for i in "${!tasks[@]}"; do
           IFS='|' read -r date task priority status <<< "${tasks[i]}"
           printf "%-2s | %s | %-20s | %-9s | %s\n" "$((i + 1))" "$date" "$task" "$priority" "$status"
       done
   }

   # Funktion zum Markieren einer Aufgabe als erledigt
   complete_task() {
       if [ -z "$1" ] || ! [[ "$1" =~ ^[0-9]+$ ]]; then
           echo "Fehler: Bitte eine gültige ID angeben."
           exit 1
       fi
       if [ "$1" -gt "$(wc -l < "$TODO_FILE")" ] || [ "$1" -lt 1 ]; then
           echo "Fehler: Ungültige ID."
           exit 1
       fi
       sed -i "${1}s/|offen$/|erledigt/" "$TODO_FILE"
       echo "Aufgabe $1 erledigt."
   }

   # Funktion zum Suchen nach Aufgaben mit regulären Ausdrücken
   search_tasks() {
       if [ -z "$1" ]; then
           echo "Fehler: Bitte einen Suchbegriff angeben."
           exit 1
       fi
       if [ ! -s "$TODO_FILE" ]; then
           echo "Keine Aufgaben vorhanden."
           return
       fi
       echo "Gefundene Aufgaben:"
       echo "ID | Datum | Aufgabe | Priorität | Status"
       echo "---------------------------------------"
       grep -E -i "$1" "$TODO_FILE" | awk -F'|' '{printf "%-2s | %s | %-20s | %-9s | %s\n", NR, $1, $2, $3, $4}'
   }

   # Hauptlogik
   case "$1" in
       add)
           add_task "$2" "$3"
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
           echo "Verwendung: $0 {add <Aufgabe> <Priorität> | list | complete <ID> | search <Regex>}"
           exit 1
           ;;
   esac
   ```
   Speichere und schließe.

2. **Schritt 2**: Teste das Skript:
   - Füge Aufgaben hinzu:
     ```bash
     ./todo_arrays.sh add "Einkaufen gehen" 2
     ./todo_arrays.sh add "Python lernen" 1
     ./todo_arrays.sh add "API testen" 3
     ```
   - Markiere eine Aufgabe als erledigt:
     ```bash
     ./todo_arrays.sh complete 1
     ```
   - Suche mit regulären Ausdrücken:
     ```bash
     ./todo_arrays.sh search "[a-zA-Z]+en"
     ```
     Dies findet Aufgaben wie "Einkaufen gehen" und "Python lernen". Die Ausgabe sollte so aussehen:
     ```
     Gefundene Aufgaben:
     ID | Datum | Aufgabe | Priorität | Status
     ---------------------------------------
     1  | 2025-09-04 13:47:00 | Einkaufen gehen      | 2         | erledigt
     2  | 2025-09-04 13:47:05 | Python lernen        | 1         | offen
     ```

**Reflexion**: Wie verbessern reguläre Ausdrücke die Suche? Nutze `man grep` und überlege, wie du komplexere Regex-Muster (z. B. für Datum oder Priorität) implementieren kannst.

### Übung 3: Integration mit Redis und Spielerei
**Ziel**: Integriere Redis-Hashes mit Arrays und regulären Ausdrücken und exportiere Aufgaben als Markdown.

1. **Schritt 1**: Stelle sicher, dass Redis läuft:
   ```bash
   redis-server &  # Starte Redis im Hintergrund
   redis-cli ping  # Prüfe mit "PONG"
   ```

2. **Schritt 2**: Erstelle ein Skript für Redis-Integration:
   ```bash
   nano todo_redis_advanced.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash

   LIST_KEY="tasks_list"
   REDIS_CLI="redis-cli"

   # Funktion zum Hinzufügen einer Aufgabe in Redis
   add_task_redis() {
       if [ -z "$1" ] || [ -z "$2" ]; then
           echo "Fehler: Bitte Aufgabe und Priorität (1-5) angeben."
           exit 1
       fi
       if ! [[ "$2" =~ ^[1-5]$ ]]; then
           echo "Fehler: Priorität muss zwischen 1 und 5 liegen."
           exit 1
       fi
       task_id=$($REDIS_CLI INCR task_id_counter)
       $REDIS_CLI HMSET "task:$task_id" task "$1" priority "$2" status "offen" created "$(date '+%Y-%m-%d %H:%M:%S')"
       $REDIS_CLI LPUSH "$LIST_KEY" "$task_id"
       $REDIS_CLI EXPIRE "task:$task_id" 3600
       $REDIS_CLI EXPIRE "$LIST_KEY" 3600
       echo "Aufgabe hinzugefügt: $1 (ID: $task_id, Priorität: $2)"
   }

   # Funktion zum Anzeigen aller Aufgaben mit Arrays
   list_tasks_redis() {
       task_ids=$($REDIS_CLI LRANGE "$LIST_KEY" 0 -1)
       if [ -z "$task_ids" ]; then
           echo "Keine Aufgaben vorhanden."
           return
       fi
       declare -a tasks
       id=1
       for task_id in $task_ids; do
           task_data=$($REDIS_CLI HGETALL "task:$task_id")
           task=$(echo "$task_data" | grep -A1 "^task$" | tail -n1)
           priority=$(echo "$task_data" | grep -A1 "^priority$" | tail -n1)
           status=$(echo "$task_data" | grep -A1 "^status$" | tail -n1)
           created=$(echo "$task_data" | grep -A1 "^created$" | tail -n1)
           tasks[$id]="$id|$created|$task|$priority|$status"
           ((id++))
       done
       echo "Aufgaben:"
       echo "ID | Datum | Aufgabe | Priorität | Status"
       echo "---------------------------------------"
       for task in "${tasks[@]:1}"; do
           IFS='|' read -r id created task priority status <<< "$task"
           printf "%-2s | %s | %-20s | %-9s | %s\n" "$id" "$created" "$task" "$priority" "$status"
       done
   }

   # Funktion zum Markieren einer Aufgabe als erledigt
   complete_task_redis() {
       if [ -z "$1" ] || ! [[ "$1" =~ ^[0-9]+$ ]]; then
           echo "Fehler: Bitte eine gültige ID angeben."
           exit 1
       fi
       task_ids=$($REDIS_CLI LRANGE "$LIST_KEY" 0 -1)
       task_count=$(echo "$task_ids" | wc -l)
       if [ "$1" -gt "$task_count" ] || [ "$1" -lt 1 ]; then
           echo "Fehler: Ungültige ID."
           exit 1
       fi
       index=$((task_count - $1))
       task_id=$(echo "$task_ids" | sed -n "$((index + 1))p")
       $REDIS_CLI HSET "task:$task_id" status "erledigt"
       $REDIS_CLI EXPIRE "task:$task_id" 3600
       echo "Aufgabe $task_id erledigt."
   }

   # Funktion zum Suchen nach Aufgaben mit regulären Ausdrücken
   search_tasks_redis() {
       if [ -z "$1" ]; then
           echo "Fehler: Bitte einen Suchbegriff (Regex) angeben."
           exit 1
       fi
       task_ids=$($REDIS_CLI LRANGE "$LIST_KEY" 0 -1)
       if [ -z "$task_ids" ]; then
           echo "Keine Aufgaben vorhanden."
           return
       fi
       declare -a tasks
       id=1
       echo "Gefundene Aufgaben:"
       echo "ID | Datum | Aufgabe | Priorität | Status"
       echo "---------------------------------------"
       for task_id in $task_ids; do
           task_data=$($REDIS_CLI HGETALL "task:$task_id")
           task=$(echo "$task_data" | grep -A1 "^task$" | tail -n1)
           if [[ "$task" =~ $1 ]]; then
               priority=$(echo "$task_data" | grep -A1 "^priority$" | tail -n1)
               status=$(echo "$task_data" | grep -A1 "^status$" | tail -n1)
               created=$(echo "$task_data" | grep -A1 "^created$" | tail -n1)
               printf "%-2s | %s | %-20s | %-9s | %s\n" "$id" "$created" "$task" "$priority" "$status"
           fi
           ((id++))
       done
   }

   # Funktion zum Exportieren als Markdown
   export_markdown() {
       output_file="tasks.md"
       task_ids=$($REDIS_CLI LRANGE "$LIST_KEY" 0 -1)
       if [ -z "$task_ids" ]; then
           echo "Keine Aufgaben vorhanden." > "$output_file"
           echo "Keine Aufgaben vorhanden."
           return
       fi
       echo "# To-Do-Liste" > "$output_file"
       echo "" >> "$output_file"
       echo "| ID | Datum | Aufgabe | Priorität | Status |" >> "$output_file"
       echo "|---|-------|--------|-----------|--------|" >> "$output_file"
       id=1
       for task_id in $task_ids; do
           task_data=$($REDIS_CLI HGETALL "task:$task_id")
           task=$(echo "$task_data" | grep -A1 "^task$" | tail -n1)
           priority=$(echo "$task_data" | grep -A1 "^priority$" | tail -n1)
           status=$(echo "$task_data" | grep -A1 "^status$" | tail -n1)
           created=$(echo "$task_data" | grep -A1 "^created$" | tail -n1)
           echo "| $id | $created | $task | $priority | $status |" >> "$output_file"
           ((id++))
       done
       cat "$output_file"
   }

   # Hauptlogik
   case "$1" in
       add)
           add_task_redis "$2" "$3"
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
           export_markdown
           ;;
       *)
           echo "Verwendung: $0 {add <Aufgabe> <Priorität> | list | complete <ID> | search <Regex> | export}"
           exit 1
           ;;
   esac
   ```
   Speichere und schließe.

3. **Schritt 3**: Mache das Skript ausführbar:
   ```bash
   chmod +x todo_redis_advanced.sh
   ```

4. **Schritt 4**: Teste das Skript:
   - Füge Aufgaben hinzu:
     ```bash
     ./todo_redis_advanced.sh add "Einkaufen gehen" 2
     ./todo_redis_advanced.sh add "Python lernen" 1
     ./todo_redis_advanced.sh add "API testen" 3
     ```
   - Markiere eine Aufgabe als erledigt:
     ```bash
     ./todo_redis_advanced.sh complete 1
     ```
   - Suche mit regulären Ausdrücken:
     ```bash
     ./todo_redis_advanced.sh search "[a-zA-Z]+en"
     ```
     Die Ausgabe sollte so aussehen:
     ```
     Gefundene Aufgaben:
     ID | Datum | Aufgabe | Priorität | Status
     ---------------------------------------
     1  | 2025-09-04 13:47:00 | Einkaufen gehen      | 2         | erledigt
     2  | 2025-09-04 13:47:05 | Python lernen        | 1         | offen
     ```
   - Exportiere als Markdown:
     ```bash
     ./todo_redis_advanced.sh export
     ```

5. **Spielerei**: Überprüfe die Markdown-Ausgabe:
   ```bash
   cat tasks.md
   ```
   Die Ausgabe sollte so aussehen:
   ```
   # To-Do-Liste

   | ID | Datum | Aufgabe | Priorität | Status |
   |---|-------|--------|-----------|--------|
   | 1 | 2025-09-04 13:47:00 | Einkaufen gehen | 2 | erledigt |
   | 2 | 2025-09-04 13:47:05 | Python lernen | 1 | offen |
   | 3 | 2025-09-04 13:47:10 | API testen | 3 | offen |
   ```

6. **Schritt 5**: Überprüfe die Daten in Redis:
   ```bash
   redis-cli
   LRANGE tasks_list 0 -1
   HGETALL task:1
   ```

**Reflexion**: Wie verbessern Arrays und reguläre Ausdrücke die Flexibilität des Skripts? Nutze `man bash` (Abschnitt zu `=~`) und überlege, wie du Arrays für benutzerspezifische Aufgabenlisten nutzen kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Arrays und reguläre Ausdrücke zu verinnerlichen.
- **Sicheres Testen**: Nutze Testverzeichnisse und sichere Berechtigungen (`chmod 600`).
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze `man bash`, `man grep` oder `help declare`.
- **Effiziente Entwicklung**: Verwende Arrays für strukturierte Daten, reguläre Ausdrücke für flexible Suche und Redis für schnelle Zugriffe.
- **Kombiniere Tools**: Integriere Bash-Skripte mit Flask-APIs oder GitHub Actions für Automatisierung.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Hinzufügen von Kategorien oder Sortierung nach Priorität.

## Fazit
Mit diesen Übungen hast du fortgeschrittene Bash-Features wie Arrays und reguläre Ausdrücke gemeistert und eine To-Do-Listen-Verwaltung mit Dateien und Redis erstellt. Die Spielerei zeigt, wie du Aufgaben als Markdown mit Prioritäten exportierst. Vertiefe dein Wissen, indem du weitere Bash-Features (z. B. Funktionen mit Rückgabewerten, Parametererweiterung) oder Integrationen (z. B. mit Flask-APIs oder SQLite) ausprobierst. Wenn du ein spezifisches Thema (z. B. Bash-Funktionen oder API-Integration) vertiefen möchtest, lass es mich wissen!
