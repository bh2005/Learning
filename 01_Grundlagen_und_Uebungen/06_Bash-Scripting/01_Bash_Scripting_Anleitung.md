# Praxisorientierte Anleitung: Bash-Scripting für Anfänger

## Einführung
Bash (Bourne Again Shell) ist eine leistungsstarke Skriptsprache für die Automatisierung von Aufgaben in Linux/Unix-Umgebungen. Diese Anleitung führt Anfänger in Bash-Scripting ein, mit Fokus auf **Grundlagen von Bash-Skripten**, **Automatisierung von Aufgaben** und **Integration mit Tools wie Redis oder Flask**. Die Beispielanwendung ist eine **To-Do-Listen-Verwaltung**, die Aufgaben in einer Datei oder optional in Redis speichert, sucht und anzeigt. Eine **Spielerei** zeigt, wie du Aufgaben als Markdown-Tabelle exportierst, um die Verbindung zu vorherigen Themen (z. B. Markdown-Ausgabe) herzustellen. Durch praktische Übungen lernst du, einfache Bash-Skripte zu schreiben und Systemaufgaben zu automatisieren.

**Voraussetzungen**:
- Ein System mit Linux oder macOS (z. B. Ubuntu 22.04, macOS Ventura) oder Windows mit WSL2 (Windows Subsystem for Linux).
- Ein Terminal (z. B. Bash auf Linux/macOS, PowerShell/WSL2 auf Windows).
- Bash installiert (standardmäßig auf Linux/macOS; auf Windows via WSL2: `wsl --install`).
- Optional: Redis installiert für Übung 3 (z. B. `sudo apt install redis-server` auf Ubuntu, `brew install redis` auf macOS, oder via Docker: `docker run -d -p 6379:6379 redis`).
- Grundkenntnisse in Linux-Befehlen (z. B. `ls`, `cat`, `grep`) und Dateibearbeitung.
- Sichere Testumgebung (z. B. `$HOME/bash_todo` oder `~/bash_todo`).
- Ein Texteditor (z. B. `nano`, `vim` oder VS Code).

## Grundlegende Befehle
Hier sind die wichtigsten Konzepte und Befehle für Bash-Scripting:

1. **Grundlagen von Bash-Skripten**:
   - `#!/bin/bash`: Shebang-Zeile, um Bash als Interpreter anzugeben.
   - `chmod +x script.sh`: Macht ein Skript ausführbar.
   - `./script.sh`: Führt ein Skript aus.
   - `echo`: Gibt Text oder Variablen aus.
   - `$1`, `$2`, ...: Zugriff auf Skript-Argumente.
2. **Automatisierung von Aufgaben**:
   - `read`: Liest Benutzereingaben.
   - `if`, `for`, `while`: Steuern Programmfluss.
   - `grep`: Sucht in Dateien oder Ausgaben.
   - `>>`: Hängt an eine Datei an.
3. **Integration mit Tools**:
   - `redis-cli`: Interagiert mit Redis über die Kommandozeile.
   - `curl`: Testet APIs (z. B. eine Flask-API).
4. **Nützliche Zusatzbefehle**:
   - `man bash`: Zeigt die Bash-Dokumentation.
   - `help <command>`: Zeigt Hilfe für eingebaute Bash-Befehle (z. B. `help echo`).
   - `chmod 600 file`: Setzt sichere Dateiberechtigungen.
   - `cat file`: Zeigt Dateiinhalt an.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Grundlagen von Bash-Skripten
**Ziel**: Erstelle ein Bash-Skript, um Aufgaben in einer Datei zu speichern und anzuzeigen.

1. **Schritt 1**: Erstelle ein Projektverzeichnis:
   ```bash
   mkdir bash_todo
   cd bash_todo
   ```

2. **Schritt 2**: Erstelle ein Bash-Skript zum Hinzufügen und Anzeigen von Aufgaben:
   ```bash
   nano todo.sh
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
       if [ -z "$1" ]; then
           echo "Fehler: Bitte eine Aufgabe angeben."
           exit 1
       fi
       echo "$(date '+%Y-%m-%d %H:%M:%S')|$1|offen" >> "$TODO_FILE"
       echo "Aufgabe hinzugefügt: $1"
   }

   # Funktion zum Anzeigen aller Aufgaben
   list_tasks() {
       if [ ! -s "$TODO_FILE" ]; then
           echo "Keine Aufgaben vorhanden."
           return
       fi
       echo "Aufgaben:"
       echo "ID | Datum | Aufgabe | Status"
       echo "--------------------------------"
       awk -F'|' '{printf "%-2s | %s | %-20s | %s\n", NR, $1, $2, $3}' "$TODO_FILE"
   }

   # Hauptlogik
   case "$1" in
       add)
           shift
           add_task "$*"
           ;;
       list)
           list_tasks
           ;;
       *)
           echo "Verwendung: $0 {add <Aufgabe> | list}"
           exit 1
           ;;
   esac
   ```
   Speichere und schließe.

3. **Schritt 3**: Mache das Skript ausführbar:
   ```bash
   chmod +x todo.sh
   ```

4. **Schritt 4**: Teste das Skript:
   - Füge eine Aufgabe hinzu:
     ```bash
     ./todo.sh add "Einkaufen gehen"
     ```
   - Zeige die Aufgaben an:
     ```bash
     ./todo.sh list
     ```
     Die Ausgabe sollte so aussehen:
     ```
     Aufgaben:
     ID | Datum | Aufgabe | Status
     --------------------------------
     1  | 2025-09-04 13:42:00 | Einkaufen gehen      | offen
     ```

5. **Schritt 5**: Überprüfe die Datei:
   ```bash
   cat tasks.txt
   ```

**Reflexion**: Warum ist `awk` nützlich für die Formatierung? Nutze `man awk` und überlege, wie du das Skript um eine "Erledigen"-Funktion erweitern kannst.

### Übung 2: Automatisierung von Aufgaben
**Ziel**: Erweitere das Skript, um Aufgaben zu erledigen und zu suchen.

1. **Schritt 1**: Erweitere das Skript mit Funktionen zum Erledigen und Suchen:
   ```bash
   nano todo.sh
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
       if [ -z "$1" ]; then
           echo "Fehler: Bitte eine Aufgabe angeben."
           exit 1
       fi
       echo "$(date '+%Y-%m-%d %H:%M:%S')|$1|offen" >> "$TODO_FILE"
       echo "Aufgabe hinzugefügt: $1"
   }

   # Funktion zum Anzeigen aller Aufgaben
   list_tasks() {
       if [ ! -s "$TODO_FILE" ]; then
           echo "Keine Aufgaben vorhanden."
           return
       fi
       echo "Aufgaben:"
       echo "ID | Datum | Aufgabe | Status"
       echo "--------------------------------"
       awk -F'|' '{printf "%-2s | %s | %-20s | %s\n", NR, $1, $2, $3}' "$TODO_FILE"
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

   # Funktion zum Suchen nach Aufgaben
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
       echo "ID | Datum | Aufgabe | Status"
       echo "--------------------------------"
       grep -i "$1" "$TODO_FILE" | awk -F'|' '{printf "%-2s | %s | %-20s | %s\n", NR, $1, $2, $3}'
   }

   # Hauptlogik
   case "$1" in
       add)
           shift
           add_task "$*"
           ;;
       list)
           list_tasks
           ;;
       complete)
           complete_task "$2"
           ;;
       search)
           shift
           search_tasks "$*"
           ;;
       *)
           echo "Verwendung: $0 {add <Aufgabe> | list | complete <ID> | search <Begriff>}"
           exit 1
           ;;
   esac
   ```
   Speichere und schließe.

2. **Schritt 2**: Teste das Skript:
   - Füge Aufgaben hinzu:
     ```bash
     ./todo.sh add "Einkaufen gehen"
     ./todo.sh add "Python lernen"
     ```
   - Markiere eine Aufgabe als erledigt:
     ```bash
     ./todo.sh complete 1
     ```
   - Suche nach Aufgaben:
     ```bash
     ./todo.sh search Einkaufen
     ```
   - Zeige alle Aufgaben:
     ```bash
     ./todo.sh list
     ```

**Reflexion**: Wie erleichtert `sed` die Bearbeitung von Dateien? Nutze `man sed` und überlege, wie du das Skript um Prioritäten erweitern kannst.

### Übung 3: Integration mit Tools und Spielerei
**Ziel**: Integriere Redis für die Aufgabenverwaltung und exportiere Aufgaben als Markdown.

1. **Schritt 1**: Stelle sicher, dass Redis installiert ist:
   ```bash
   redis-server &  # Starte Redis im Hintergrund
   redis-cli ping  # Prüfe mit "PONG"
   ```

2. **Schritt 2**: Erstelle ein neues Skript für Redis-Integration:
   ```bash
   nano todo_redis.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash

   LIST_KEY="tasks_list"
   REDIS_CLI="redis-cli"

   # Funktion zum Hinzufügen einer Aufgabe in Redis
   add_task_redis() {
       if [ -z "$1" ]; then
           echo "Fehler: Bitte eine Aufgabe angeben."
           exit 1
       fi
       task_id=$($REDIS_CLI INCR task_id_counter)
       $REDIS_CLI HMSET "task:$task_id" task "$1" status "offen" created "$(date '+%Y-%m-%d %H:%M:%S')"
       $REDIS_CLI LPUSH "$LIST_KEY" "$task_id"
       $REDIS_CLI EXPIRE "task:$task_id" 3600
       $REDIS_CLI EXPIRE "$LIST_KEY" 3600
       echo "Aufgabe hinzugefügt: $1 (ID: $task_id)"
   }

   # Funktion zum Anzeigen aller Aufgaben
   list_tasks_redis() {
       task_ids=$($REDIS_CLI LRANGE "$LIST_KEY" 0 -1)
       if [ -z "$task_ids" ]; then
           echo "Keine Aufgaben vorhanden."
           return
       fi
       echo "Aufgaben:"
       echo "ID | Datum | Aufgabe | Status"
       echo "--------------------------------"
       id=1
       for task_id in $task_ids; do
           task_data=$($REDIS_CLI HGETALL "task:$task_id")
           task=$(echo "$task_data" | grep -A1 "task" | tail -n1)
           status=$(echo "$task_data" | grep -A1 "status" | tail -n1)
           created=$(echo "$task_data" | grep -A1 "created" | tail -n1)
           printf "%-2s | %s | %-20s | %s\n" "$id" "$created" "$task" "$status"
           ((id++))
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
       # Berechne die Redis-Index-ID (umgekehrte Reihenfolge wegen LPUSH)
       index=$((task_count - $1))
       task_id=$(echo "$task_ids" | sed -n "$((index + 1))p")
       $REDIS_CLI HSET "task:$task_id" status "erledigt"
       $REDIS_CLI EXPIRE "task:$task_id" 3600
       echo "Aufgabe $task_id erledigt."
   }

   # Funktion zum Suchen nach Aufgaben
   search_tasks_redis() {
       if [ -z "$1" ]; then
           echo "Fehler: Bitte einen Suchbegriff angeben."
           exit 1
       fi
       task_ids=$($REDIS_CLI LRANGE "$LIST_KEY" 0 -1)
       if [ -z "$task_ids" ]; then
           echo "Keine Aufgaben vorhanden."
           return
       fi
       echo "Gefundene Aufgaben:"
       echo "ID | Datum | Aufgabe | Status"
       echo "--------------------------------"
       id=1
       for task_id in $task_ids; do
           task_data=$($REDIS_CLI HGETALL "task:$task_id")
           task=$(echo "$task_data" | grep -A1 "task" | tail -n1)
           if echo "$task" | grep -qi "$1"; then
               status=$(echo "$task_data" | grep -A1 "status" | tail -n1)
               created=$(echo "$task_data" | grep -A1 "created" | tail -n1)
               printf "%-2s | %s | %-20s | %s\n" "$id" "$created" "$task" "$status"
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
       echo "| ID | Datum | Aufgabe | Status |" >> "$output_file"
       echo "|---|-------|--------|--------|" >> "$output_file"
       id=1
       for task_id in $task_ids; do
           task_data=$($REDIS_CLI HGETALL "task:$task_id")
           task=$(echo "$task_data" | grep -A1 "task" | tail -n1)
           status=$(echo "$task_data" | grep -A1 "status" | tail -n1)
           created=$(echo "$task_data" | grep -A1 "created" | tail -n1)
           echo "| $id | $created | $task | $status |" >> "$output_file"
           ((id++))
       done
       cat "$output_file"
   }

   # Hauptlogik
   case "$1" in
       add)
           shift
           add_task_redis "$*"
           ;;
       list)
           list_tasks_redis
           ;;
       complete)
           complete_task_redis "$2"
           ;;
       search)
           shift
           search_tasks_redis "$*"
           ;;
       export)
           export_markdown
           ;;
       *)
           echo "Verwendung: $0 {add <Aufgabe> | list | complete <ID> | search <Begriff> | export}"
           exit 1
           ;;
   esac
   ```
   Speichere und schließe.

3. **Schritt 3**: Mache das Skript ausführbar:
   ```bash
   chmod +x todo_redis.sh
   ```

4. **Schritt 4**: Teste das Skript:
   - Füge Aufgaben hinzu:
     ```bash
     ./todo_redis.sh add "Einkaufen gehen"
     ./todo_redis.sh add "Python lernen"
     ```
   - Markiere eine Aufgabe als erledigt:
     ```bash
     ./todo_redis.sh complete 1
     ```
   - Suche nach Aufgaben:
     ```bash
     ./todo_redis.sh search Einkaufen
     ```
   - Zeige alle Aufgaben:
     ```bash
     ./todo_redis.sh list
     ```
   - Exportiere als Markdown:
     ```bash
     ./todo_redis.sh export
     ```

5. **Spielerei**: Überprüfe die Markdown-Ausgabe:
   ```bash
   cat tasks.md
   ```
   Die Ausgabe sollte so aussehen:
   ```
   # To-Do-Liste

   | ID | Datum | Aufgabe | Status |
   |---|-------|--------|--------|
   | 1 | 2025-09-04 13:42:00 | Einkaufen gehen | erledigt |
   | 2 | 2025-09-04 13:42:05 | Python lernen | offen |
   ```

6. **Schritt 5**: Überprüfe die Daten in Redis:
   ```bash
   redis-cli
   LRANGE tasks_list 0 -1
   HGETALL task:1
   ```

**Reflexion**: Wie erleichtert Redis die Datenverwaltung im Vergleich zur Datei? Nutze `man redis-cli` und überlege, wie du das Skript mit einer Flask-API integrieren kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Bash-Scripting zu verinnerlichen.
- **Sicheres Testen**: Nutze Testverzeichnisse und sichere Berechtigungen (`chmod 600`).
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze `man bash` oder `help <command>`.
- **Effiziente Entwicklung**: Verwende Funktionen für modulares Scripting, `awk`/`sed` für Textverarbeitung und Redis für schnelle Daten.
- **Kombiniere Tools**: Integriere Bash-Skripte mit Flask-APIs oder GitHub Actions für Automatisierung.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Hinzufügen von Prioritäten oder einer Löschfunktion.

## Fazit
Mit diesen Übungen hast du die Grundlagen von Bash-Scripting gelernt und eine To-Do-Listen-Verwaltung mit Dateien und Redis erstellt. Die Spielerei zeigt, wie du Aufgaben als Markdown exportierst. Im Vergleich zur Flask-Redis-Anwendung bieten Bash-Skripte eine einfache, aber leistungsstarke Möglichkeit zur Automatisierung. Vertiefe dein Wissen, indem du fortgeschrittene Bash-Features (z. B. Arrays, reguläre Ausdrücke) oder Integrationen (z. B. mit Flask-APIs) ausprobierst. Wenn du ein spezifisches Thema (z. B. Bash-Arrays oder API-Integration) vertiefen möchtest, lass es mich wissen!
