# Praxisorientierte Anleitung: Integration von Bash-Skripten mit Flask-APIs und SQLite

## Einführung
Die Integration von Bash-Skripten mit Flask-APIs und SQLite ermöglicht leistungsstarke Automatisierung und Datenverwaltung in einer hybriden Umgebung. Diese Anleitung baut auf der vorherigen Anleitung zu fortgeschrittenen Bash-Features auf und konzentriert sich auf die **Integration von Bash-Skripten mit einer Flask-API** und die **Speicherung von Daten in SQLite**. Die Beispielanwendung ist eine **To-Do-Listen-Verwaltung**, die Aufgaben mit Prioritäten und Kategorien in einer SQLite-Datenbank speichert, über eine Flask-API zugänglich macht und mit Bash-Skripten als Kommandozeilen-Interface verwaltet. Eine **Spielerei** zeigt, wie du Aufgaben als Markdown-Tabelle exportierst, um die Verbindung zu vorherigen Themen (z. B. Markdown-Ausgabe) herzustellen. Durch praktische Übungen lernst du, Bash-Skripte mit Flask-APIs und SQLite zu integrieren.

**Voraussetzungen**:
- Ein System mit Linux oder macOS (z. B. Ubuntu 22.04, macOS Ventura) oder Windows mit WSL2.
- Ein Terminal (z. B. Bash auf Linux/macOS, PowerShell/WSL2 auf Windows).
- Bash installiert (standardmäßig auf Linux/macOS; auf Windows via WSL2: `wsl --install`).
- Python 3 installiert (prüfe mit `python3 --version`; installiere via `sudo apt install python3` auf Ubuntu, `brew install python3` auf macOS, oder `choco install python` auf Windows).
- SQLite installiert (prüfe mit `sqlite3 --version`; installiere via `sudo apt install sqlite3` auf Ubuntu, `brew install sqlite` auf macOS, oder `choco install sqlite` auf Windows).
- Python-Bibliotheken `flask` und `flask-restful` installiert (`pip install flask flask-restful`).
- Grundkenntnisse in Bash (Funktionen, Arrays, Parametererweiterung), Flask (Routen, APIs) und SQL (z. B. `CREATE TABLE`, `SELECT`).
- Sichere Testumgebung (z. B. `$HOME/bash_flask_sqlite` oder `~/bash_flask_sqlite`).
- Ein Texteditor (z. B. `nano`, `vim` oder VS Code).
- Ein API-Testtool (z. B. `curl` oder Postman).

## Grundlegende Befehle
Hier sind die wichtigsten Konzepte und Befehle für die Integration von Bash mit Flask-APIs und SQLite:

1. **Bash-Integration mit Flask-API**:
   - `curl`: Sendet HTTP-Anfragen an die Flask-API (z. B. `curl -X POST` für Aufgaben).
   - `jq`: Verarbeitet JSON-Antworten von der API (installiere via `sudo apt install jq` oder `brew install jq`).
   - `bash -c`: Führt Bash-Befehle innerhalb eines Skripts aus.
2. **SQLite für persistente Daten**:
   - `sqlite3 <database> "SQL-Befehl"`: Führt SQL-Befehle aus.
   - `CREATE TABLE`: Erstellt eine Tabelle für Aufgaben.
   - `INSERT`, `SELECT`, `UPDATE`: Verwaltet Daten in SQLite.
3. **Flask-API für Datenzugriff**:
   - `from flask import Flask`: Erstellt eine Flask-Anwendung.
   - `from flask_restful import Api, Resource`: Definiert API-Ressourcen.
   - `import sqlite3`: Verbindet Flask mit SQLite.
4. **Nützliche Zusatzbefehle**:
   - `man curl`: Zeigt Optionen für HTTP-Anfragen.
   - `man sqlite3`: Zeigt SQLite-Befehle.
   - `pip show flask`: Prüft Flask-Installation.
   - `man jq`: Zeigt JSON-Verarbeitung mit `jq`.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Flask-API mit SQLite für To-Do-Listen
**Ziel**: Erstelle eine Flask-API, die Aufgaben in einer SQLite-Datenbank speichert.

1. **Schritt 1**: Erstelle ein Projektverzeichnis:
   ```bash
   mkdir bash_flask_sqlite
   cd bash_flask_sqlite
   ```

2. **Schritt 2**: Installiere die erforderlichen Bibliotheken:
   ```bash
   pip install flask flask-restful
   sudo apt install jq sqlite3  # Auf Ubuntu; für macOS: brew install jq sqlite
   ```

3. **Schritt 3**: Erstelle ein Flask-Skript mit SQLite:
   ```bash
   nano app.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from flask import Flask
   from flask_restful import Api, Resource, reqparse
   import sqlite3

   app = Flask(__name__)
   api = Api(app)

   # Initialisiere SQLite-Datenbank
   def init_db():
       conn = sqlite3.connect('tasks.db')
       c = conn.cursor()
       c.execute('''
           CREATE TABLE IF NOT EXISTS tasks (
               id INTEGER PRIMARY KEY AUTOINCREMENT,
               task TEXT NOT NULL,
               priority INTEGER NOT NULL,
               status TEXT NOT NULL,
               category TEXT NOT NULL,
               created TEXT NOT NULL
           )
       ''')
       conn.commit()
       conn.close()

   class TaskAPI(Resource):
       def get(self):
           parser = reqparse.RequestParser()
           parser.add_argument('query', type=str, default='')
           args = parser.parse_args()
           conn = sqlite3.connect('tasks.db')
           c = conn.cursor()
           if args['query']:
               c.execute("SELECT * FROM tasks WHERE task LIKE ?", ('%' + args['query'] + '%',))
           else:
               c.execute("SELECT * FROM tasks")
           tasks = [{'id': row[0], 'task': row[1], 'priority': row[2], 'status': row[3], 'category': row[4], 'created': row[5]} for row in c.fetchall()]
           conn.close()
           return tasks

       def post(self):
           parser = reqparse.RequestParser()
           parser.add_argument('task', type=str, required=True, help="Task cannot be blank")
           parser.add_argument('priority', type=int, required=True, help="Priority must be provided")
           parser.add_argument('category', type=str, default='default')
           args = parser.parse_args()
           conn = sqlite3.connect('tasks.db')
           c = conn.cursor()
           c.execute("INSERT INTO tasks (task, priority, status, category, created) VALUES (?, ?, ?, ?, datetime('now'))",
                     (args['task'], args['priority'], 'offen', args['category']))
           conn.commit()
           task_id = c.lastrowid
           conn.close()
           return {'id': task_id, 'task': args['task'], 'priority': args['priority'], 'category': args['category']}, 201

       def put(self, task_id):
           conn = sqlite3.connect('tasks.db')
           c = conn.cursor()
           c.execute("UPDATE tasks SET status = 'erledigt' WHERE id = ?", (task_id,))
           updated = c.rowcount
           conn.commit()
           conn.close()
           return {'updated': bool(updated)}, 200 if updated else 404

   api.add_resource(TaskAPI, '/api/tasks', '/api/tasks/<int:task_id>')

   if __name__ == '__main__':
       init_db()
       app.run(debug=True)
   ```
   Speichere und schließe.

4. **Schritt 4**: Starte die Flask-Anwendung:
   ```bash
   python3 app.py &
   ```

5. **Schritt 5**: Teste die API mit `curl`:
   - Füge eine Aufgabe hinzu:
     ```bash
     curl -X POST -H "Content-Type: application/json" -d '{"task":"Einkaufen gehen", "priority":2, "category":"Lebensmittel"}' http://localhost:5000/api/tasks
     ```
   - Hole alle Aufgaben:
     ```bash
     curl http://localhost:5000/api/tasks
     ```
   - Markiere eine Aufgabe als erledigt (ersetze `<task_id>` mit z. B. 1):
     ```bash
     curl -X PUT http://localhost:5000/api/tasks/1
     ```

**Reflexion**: Wie erleichtert SQLite die Persistenz im Vergleich zu Dateien? Nutze `man sqlite3` und überlege, wie du die API mit Authentifizierung sichern kannst.

### Übung 2: Bash-Skript zur Interaktion mit der Flask-API
**Ziel**: Erstelle ein Bash-Skript, das die Flask-API für die To-Do-Verwaltung nutzt.

1. **Schritt 1**: Erstelle ein Bash-Skript:
   ```bash
   nano todo_api.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash

   API_URL="http://localhost:5000/api/tasks"

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
       local id="$1" created="$2" task="$3" priority="$4" status="$5" category="$6"
       printf "%-2s | %s | %-20s | %-9s | %-8s | %s\n" "$id" "${created:0:19}" "${task:0:20}" "$priority" "$status" "$category"
   }

   # Funktion zum Hinzufügen einer Aufgabe
   add_task() {
       local task="$1" priority="${2:-1}" category="${3:-default}"
       if [ -z "$task" ]; then
           echo "Fehler: Bitte eine Aufgabe angeben." >&2
           return 1
       fi
       if [ "$(validate_priority "$priority")" != "valid" ]; then
           echo "Fehler: Priorität muss zwischen 1 und 5 liegen." >&2
           return 1
       fi
       category="${category//[^a-zA-Z0-9]/_}"
       response=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"task\":\"$task\", \"priority\":$priority, \"category\":\"$category\"}" "$API_URL")
       if echo "$response" | jq -e '.id' > /dev/null; then
           echo "Aufgabe hinzugefügt: $task (Priorität: $priority, Kategorie: $category)"
           return 0
       else
           echo "Fehler: Aufgabe konnte nicht hinzugefügt werden." >&2
           return 1
       fi
   }

   # Funktion zum Anzeigen aller Aufgaben
   list_tasks() {
       response=$(curl -s "$API_URL")
       if [ -z "$response" ]; then
           echo "Keine Aufgaben vorhanden."
           return 1
       fi
       echo "Aufgaben:"
       echo "ID | Datum | Aufgabe | Priorität | Status | Kategorie"
       echo "-----------------------------------------------"
       echo "$response" | jq -r '.[] | [.id, .created, .task, .priority, .status, .category] | @tsv' | while IFS=$'\t' read -r id created task priority status category; do
           format_task "$id" "$created" "$task" "$priority" "$status" "$category"
       done
       return 0
   }

   # Funktion zum Markieren einer Aufgabe als erledigt
   complete_task() {
       local id="$1"
       if [ -z "$id" ] || ! [[ "$id" =~ ^[0-9]+$ ]]; then
           echo "Fehler: Bitte eine gültige ID angeben." >&2
           return 1
       fi
       response=$(curl -s -X PUT "$API_URL/$id")
       if echo "$response" | jq -e '.updated' > /dev/null; then
           echo "Aufgabe $id erledigt."
           return 0
       else
           echo "Fehler: Aufgabe konnte nicht erledigt werden." >&2
           return 1
       fi
   }

   # Funktion zum Suchen nach Aufgaben
   search_tasks() {
       local query="${1:-}"
       response=$(curl -s "$API_URL?query=$query")
       if [ -z "$response" ]; then
           echo "Keine Aufgaben vorhanden."
           return 1
       fi
       echo "Gefundene Aufgaben:"
       echo "ID | Datum | Aufgabe | Priorität | Status | Kategorie"
       echo "-----------------------------------------------"
       echo "$response" | jq -r '.[] | [.id, .created, .task, .priority, .status, .category] | @tsv' | while IFS=$'\t' read -r id created task priority status category; do
           format_task "$id" "$created" "$task" "$priority" "$status" "$category"
       done
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
           echo "Verwendung: $0 {add <Aufgabe> [<Priorität>] [<Kategorie>] | list | complete <ID> | search [<Suchbegriff>]}"
           exit 1
           ;;
   esac
   ```
   Speichere und schließe.

2. **Schritt 2**: Mache das Skript ausführbar:
   ```bash
   chmod +x todo_api.sh
   ```

3. **Schritt 3**: Teste das Skript (Flask-Anwendung muss laufen):
   - Füge Aufgaben hinzu:
     ```bash
     ./todo_api.sh add "Einkaufen gehen" 2 Lebensmittel
     ./todo_api.sh add "Python lernen" 1 Programmieren
     ```
   - Markiere eine Aufgabe als erledigt:
     ```bash
     ./todo_api.sh complete 1
     ```
   - Suche nach Aufgaben:
     ```bash
     ./todo_api.sh search Einkaufen
     ```
   - Zeige alle Aufgaben:
     ```bash
     ./todo_api.sh list
     ```
     Die Ausgabe sollte so aussehen:
     ```
     Aufgaben:
     ID | Datum | Aufgabe | Priorität | Status | Kategorie
     -----------------------------------------------
     1  | 2025-09-04 13:59:00 | Einkaufen gehen      | 2         | erledigt | Lebensmittel
     2  | 2025-09-04 13:59:05 | Python lernen        | 1         | offen    | Programmieren
     ```

**Reflexion**: Wie erleichtert `jq` die Verarbeitung von JSON? Nutze `man jq` und überlege, wie du das Skript um Authentifizierung für die API erweitern kannst.

### Übung 3: SQLite und Spielerei (Markdown-Export)
**Ziel**: Erweitere das Bash-Skript, um Aufgaben direkt in SQLite zu verwalten und als Markdown zu exportieren.

1. **Schritt 1**: Erstelle ein Bash-Skript für SQLite:
   ```bash
   nano todo_sqlite.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash

   DB_FILE="tasks.db"

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
       local id="$1" created="$2" task="$3" priority="$4" status="$5" category="$6"
       printf "%-2s | %s | %-20s | %-9s | %-8s | %s\n" "$id" "${created:0:19}" "${task:0:20}" "$priority" "$status" "$category"
   }

   # Funktion zum Hinzufügen einer Aufgabe
   add_task() {
       local task="$1" priority="${2:-1}" category="${3:-default}"
       if [ -z "$task" ]; then
           echo "Fehler: Bitte eine Aufgabe angeben." >&2
           return 1
       fi
       if [ "$(validate_priority "$priority")" != "valid" ]; then
           echo "Fehler: Priorität muss zwischen 1 und 5 liegen." >&2
           return 1
       fi
       category="${category//[^a-zA-Z0-9]/_}"
       sqlite3 "$DB_FILE" "INSERT INTO tasks (task, priority, status, category, created) VALUES ('$task', $priority, 'offen', '$category', datetime('now'))"
       echo "Aufgabe hinzugefügt: $task (Priorität: $priority, Kategorie: $category)"
       return 0
   }

   # Funktion zum Anzeigen aller Aufgaben
   list_tasks() {
       local tasks
       tasks=$(sqlite3 "$DB_FILE" "SELECT id, created, task, priority, status, category FROM tasks")
       if [ -z "$tasks" ]; then
           echo "Keine Aufgaben vorhanden."
           return 1
       fi
       echo "Aufgaben:"
       echo "ID | Datum | Aufgabe | Priorität | Status | Kategorie"
       echo "-----------------------------------------------"
       echo "$tasks" | while IFS='|' read -r id created task priority status category; do
           format_task "$id" "$created" "$task" "$priority" "$status" "$category"
       done
       return 0
   }

   # Funktion zum Markieren einer Aufgabe als erledigt
   complete_task() {
       local id="$1"
       if [ -z "$id" ] || ! [[ "$id" =~ ^[0-9]+$ ]]; then
           echo "Fehler: Bitte eine gültige ID angeben." >&2
           return 1
       fi
       sqlite3 "$DB_FILE" "UPDATE tasks SET status = 'erledigt' WHERE id = $id"
       if [ "$(sqlite3 "$DB_FILE" "SELECT changes()")" -eq 0 ]; then
           echo "Fehler: Aufgabe $id nicht gefunden." >&2
           return 1
       fi
       echo "Aufgabe $id erledigt."
       return 0
   }

   # Funktion zum Suchen nach Aufgaben
   search_tasks() {
       local query="${1:-}"
       local tasks
       if [ -z "$query" ]; then
           tasks=$(sqlite3 "$DB_FILE" "SELECT id, created, task, priority, status, category FROM tasks")
       else
           tasks=$(sqlite3 "$DB_FILE" "SELECT id, created, task, priority, status, category FROM tasks WHERE task LIKE '%$query%'")
       fi
       if [ -z "$tasks" ]; then
           echo "Keine Aufgaben vorhanden."
           return 1
       fi
       echo "Gefundene Aufgaben:"
       echo "ID | Datum | Aufgabe | Priorität | Status | Kategorie"
       echo "-----------------------------------------------"
       echo "$tasks" | while IFS='|' read -r id created task priority status category; do
           format_task "$id" "$created" "$task" "$priority" "$status" "$category"
       done
       return 0
   }

   # Funktion zum Exportieren als Markdown
   export_markdown() {
       local output_file="${1:-tasks.md}"
       local tasks
       tasks=$(sqlite3 "$DB_FILE" "SELECT id, created, task, priority, status, category FROM tasks")
       if [ -z "$tasks" ]; then
           echo "Keine Aufgaben vorhanden." > "$output_file"
           echo "Keine Aufgaben vorhanden."
           return 1
       fi
       echo "# To-Do-Liste" > "$output_file"
       echo "" >> "$output_file"
       echo "| ID | Datum | Aufgabe | Priorität | Status | Kategorie |" >> "$output_file"
       echo "|---|-------|--------|-----------|--------|-----------|" >> "$output_file"
       echo "$tasks" | while IFS='|' read -r id created task priority status category; do
           echo "| $id | $created | $task | $priority | $status | $category |" >> "$output_file"
       done
       cat "$output_file"
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
       export)
           export_markdown "$2"
           ;;
       *)
           echo "Verwendung: $0 {add <Aufgabe> [<Priorität>] [<Kategorie>] | list | complete <ID> | search [<Suchbegriff>] | export [<Datei>]}"
           exit 1
           ;;
   esac
   ```
   Speichere und schließe.

2. **Schritt 2**: Mache das Skript ausführbar:
   ```bash
   chmod +x todo_sqlite.sh
   ```

3. **Schritt 3**: Initialisiere die SQLite-Datenbank (wird automatisch von `app.py` erledigt, aber für das Bash-Skript separat):
   ```bash
   sqlite3 tasks.db "CREATE TABLE IF NOT EXISTS tasks (id INTEGER PRIMARY KEY AUTOINCREMENT, task TEXT NOT NULL, priority INTEGER NOT NULL, status TEXT NOT NULL, category TEXT NOT NULL, created TEXT NOT NULL)"
   ```

4. **Schritt 4**: Teste das Skript:
   - Füge Aufgaben hinzu:
     ```bash
     ./todo_sqlite.sh add "Einkaufen gehen" 2 Lebensmittel
     ./todo_sqlite.sh add "Python lernen" 1 Programmieren
     ./todo_sqlite.sh add "API testen" 3 Entwicklung
     ```
   - Markiere eine Aufgabe als erledigt:
     ```bash
     ./todo_sqlite.sh complete 1
     ```
   - Suche nach Aufgaben:
     ```bash
     ./todo_sqlite.sh search Einkaufen
     ```
   - Zeige alle Aufgaben:
     ```bash
     ./todo_sqlite.sh list
     ```
   - Exportiere als Markdown:
     ```bash
     ./todo_sqlite.sh export my_tasks.md
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
   | 1 | 2025-09-04 13:59:00 | Einkaufen gehen | 2 | erledigt | Lebensmittel |
   | 2 | 2025-09-04 13:59:05 | Python lernen | 1 | offen | Programmieren |
   | 3 | 2025-09-04 13:59:10 | API testen | 3 | offen | Entwicklung |
   ```

6. **Schritt 5**: Überprüfe die Daten in SQLite:
   ```bash
   sqlite3 tasks.db "SELECT * FROM tasks;"
   ```

**Reflexion**: Wie verbessert SQLite die Datenverwaltung gegenüber Redis? Nutze `man sqlite3` und überlege, wie du die Bash-Skripte mit weiteren API-Funktionen (z. B. Löschen) erweitern kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um die Integration von Bash, Flask und SQLite zu verinnerlichen.
- **Sicheres Testen**: Nutze Testverzeichnisse und sichere Berechtigungen (`chmod 600`).
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze `man curl`, `man sqlite3` oder `man jq`.
- **Effiziente Entwicklung**: Verwende Funktionen für modulares Bash-Scripting, `jq` für JSON-Verarbeitung und SQLite für Persistenz.
- **Kombiniere Tools**: Integriere Bash-Skripte mit GitHub Actions oder anderen APIs.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Hinzufügen von Sortierungsoptionen oder API-Authentifizierung.

## Fazit
Mit diesen Übungen hast du gelernt, Bash-Skripte mit Flask-APIs und SQLite zu integrieren, und eine To-Do-Listen-Verwaltung erstellt. Die Spielerei zeigt, wie du Aufgaben als Markdown exportierst. Im Vergleich zu früheren Redis-basierten Ansätzen bietet SQLite Persistenz, während die Flask-API flexible Zugriffe ermöglicht. Vertiefe dein Wissen, indem du weitere Integrationen (z. B. mit PostgreSQL oder JWT-Authentifizierung) oder Bash-Features (z. B. Traps) ausprobierst. Wenn du ein spezifisches Thema (z. B. Bash-Traps oder PostgreSQL-Integration) vertiefen möchtest, lass es mich wissen!
