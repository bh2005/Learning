# Praxisorientierte Anleitung: Einstieg in SQLite mit Python für Anfänger

## Einführung
SQLite ist eine leichtgewichtige, serverlose relationale Datenbank, die ideal für kleine Projekte, Prototypen oder Lernzwecke ist. Diese Anleitung führt Anfänger in die Nutzung von SQLite mit Python ein und konzentriert sich auf **Erstellen und Verwalten einer SQLite-Datenbank**, **Einfügen und Abfragen von Daten** sowie **Grundlegende SQL-Befehle in Python**. Eine **Spielerei** zeigt, wie du eine Klasse erstellst, die eine Aufgabenliste (To-Do-List) in SQLite verwaltet und als Markdown-Tabelle ausgibt, um eine Verbindung zu vorherigen Themen (z. B. Markdown-Ausgabe) herzustellen. Durch praktische Übungen lernst du, SQLite-Datenbanken zu erstellen, Daten zu speichern und abzufragen.

**Voraussetzungen**:
- Ein System mit Windows, macOS oder Linux (z. B. Windows 11, Ubuntu 22.04, macOS Ventura).
- Ein Terminal (PowerShell für Windows, Terminal für macOS/Linux).
- Python 3 installiert (prüfe mit `python3 --version`; installiere via `choco install python` auf Windows, `sudo apt install python3` auf Ubuntu oder `brew install python3` auf macOS).
- SQLite ist in Python integriert (`sqlite3`-Modul, keine Installation nötig).
- Grundkenntnisse in Python (Variablen, Funktionen).
- Sichere Testumgebung (z. B. `$HOME/sqlite_test` oder `~/sqlite_test`).

## Grundlegende Befehle
Hier sind die wichtigsten Konzepte und Befehle für SQLite in Python:

1. **Erstellen und Verwalten einer SQLite-Datenbank**:
   - `sqlite3.connect('database.db')`: Verbindet mit einer Datenbank (erstellt sie, falls nicht vorhanden).
   - `cursor.execute()`: Führt SQL-Befehle aus (z. B. `CREATE TABLE`).
   - `conn.commit()`: Speichert Änderungen.
   - `conn.close()`: Schließt die Verbindung.
2. **Einfügen und Abfragen von Daten**:
   - `INSERT INTO table (columns) VALUES (values)`: Fügt Daten in eine Tabelle ein.
   - `SELECT * FROM table`: Fragt Daten ab.
   - `cursor.fetchall()`: Ruft alle Ergebnisse einer Abfrage.
3. **Grundlegende SQL-Befehle**:
   - `CREATE TABLE`: Erstellt eine Tabelle.
   - `WHERE`: Filtert Daten (z. B. `WHERE age >= 18`).
   - `DELETE FROM`: Löscht Daten.
4. **Nützliche Zusatzbefehle**:
   - `python3 script.py`: Führt ein Python-Skript aus.
   - `sqlite3 database.db`: Öffnet die SQLite-CLI zum Überprüfen der Datenbank.
   - `help(sqlite3)`: Zeigt Python-Dokumentation für das `sqlite3`-Modul.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Erstellen und Verwalten einer SQLite-Datenbank
**Ziel**: Erstelle eine SQLite-Datenbank, füge eine Tabelle für Benutzer hinzu und speichere Daten.

1. **Schritt 1**: Erstelle ein Projektverzeichnis:
   ```bash
   mkdir sqlite_test
   cd sqlite_test
   ```

2. **Schritt 2**: Erstelle ein Skript zum Erstellen einer Datenbank:
   ```bash
   nano create_db.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import sqlite3

   def create_database():
       """Erstellt eine SQLite-Datenbank und eine Benutzer-Tabelle."""
       conn = sqlite3.connect("users.db")
       cursor = conn.cursor()
       cursor.execute("""
           CREATE TABLE IF NOT EXISTS users (
               id INTEGER PRIMARY KEY AUTOINCREMENT,
               name TEXT NOT NULL,
               age INTEGER,
               email TEXT
           )
       """)
       conn.commit()
       conn.close()
       print("Datenbank und Tabelle erstellt.")

   if __name__ == "__main__":
       create_database()
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   python3 create_db.py
   ```
   Die Ausgabe sollte sein:
   ```
   Datenbank und Tabelle erstellt.
   ```

4. **Schritt 4**: Überprüfe die Datenbank mit der SQLite-CLI:
   ```bash
   sqlite3 users.db
   .tables
   ```
   Die Ausgabe sollte `users` anzeigen. Verlasse die CLI mit `.exit`.

**Reflexion**: Warum ist `PRIMARY KEY AUTOINCREMENT` nützlich? Nutze `help(sqlite3)` und überlege, wie du weitere Tabellen (z. B. für Aufgaben) erstellen kannst.

### Übung 2: Einfügen und Abfragen von Daten
**Ziel**: Füge Benutzerdaten hinzu und frage volljährige Benutzer ab.

1. **Schritt 1**: Erstelle ein Skript zum Hinzufügen und Abfragen von Daten:
   ```bash
   nano manage_users.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import sqlite3

   def add_user(name, age, email):
       """Fügt einen Benutzer zur Datenbank hinzu."""
       conn = sqlite3.connect("users.db")
       cursor = conn.cursor()
       cursor.execute("INSERT INTO users (name, age, email) VALUES (?, ?, ?)", (name, age, email))
       conn.commit()
       conn.close()
       print(f"Benutzer {name} hinzugefügt.")

   def get_adults(min_age=18):
       """Fragt volljährige Benutzer ab."""
       conn = sqlite3.connect("users.db")
       cursor = conn.cursor()
       cursor.execute("SELECT name, age, email FROM users WHERE age >= ?", (min_age,))
       users = cursor.fetchall()
       conn.close()
       return users

   if __name__ == "__main__":
       # Füge Testdaten hinzu
       add_user("Anna", 25, "anna@example.com")
       add_user("Ben", 17, "ben@example.com")
       add_user("Clara", 30, "clara@example.com")
       # Frage volljährige Benutzer ab
       adults = get_adults()
       print("Volljährige Benutzer:")
       for user in adults:
           print(f"Name: {user[0]}, Alter: {user[1]}, E-Mail: {user[2]}")
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   python3 manage_users.py
   ```
   Die Ausgabe sollte so aussehen:
   ```
   Benutzer Anna hinzugefügt.
   Benutzer Ben hinzugefügt.
   Benutzer Clara hinzugefügt.
   Volljährige Benutzer:
   Name: Anna, Alter: 25, E-Mail: anna@example.com
   Name: Clara, Alter: 30, E-Mail: clara@example.com
   ```

3. **Schritt 3**: Überprüfe die Datenbank:
   ```bash
   sqlite3 users.db "SELECT * FROM users;"
   ```
   Die Ausgabe sollte die eingefügten Benutzer anzeigen:
   ```
   1|Anna|25|anna@example.com
   2|Ben|17|ben@example.com
   3|Clara|30|clara@example.com
   ```

**Reflexion**: Warum ist das `?`-Platzhalter-Syntax für SQL sicherer? Nutze die SQLite-Dokumentation (`sqlite3 -help`) und überlege, wie du Daten löschen kannst (`DELETE FROM`).

### Übung 3: Grundlegende SQL-Befehle und Spielerei
**Ziel**: Erstelle eine Klasse für eine To-Do-Liste, die Aufgaben in SQLite speichert, abfragt und als Markdown-Tabelle ausgibt.

1. **Schritt 1**: Erstelle ein Skript für eine To-Do-Liste:
   ```bash
   nano todo_manager.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import sqlite3

   class TodoManager:
       def __init__(self, db_name="todo.db"):
           self.db_name = db_name
           self.init_db()

       def init_db(self):
           """Initialisiert die Datenbank und erstellt eine Aufgaben-Tabelle."""
           conn = sqlite3.connect(self.db_name)
           cursor = conn.cursor()
           cursor.execute("""
               CREATE TABLE IF NOT EXISTS tasks (
                   id INTEGER PRIMARY KEY AUTOINCREMENT,
                   task TEXT NOT NULL,
                   completed INTEGER DEFAULT 0
               )
           """)
           conn.commit()
           conn.close()

       def add_task(self, task):
           """Fügt eine Aufgabe hinzu."""
           conn = sqlite3.connect(self.db_name)
           cursor = conn.cursor()
           cursor.execute("INSERT INTO tasks (task) VALUES (?)", (task,))
           conn.commit()
           conn.close()

       def complete_task(self, task_id):
           """Markiert eine Aufgabe als erledigt."""
           conn = sqlite3.connect(self.db_name)
           cursor = conn.cursor()
           cursor.execute("UPDATE tasks SET completed = 1 WHERE id = ?", (task_id,))
           conn.commit()
           conn.close()

       def get_tasks(self, only_pending=True):
           """Ruft Aufgaben ab (optional nur offene)."""
           conn = sqlite3.connect(self.db_name)
           cursor = conn.cursor()
           query = "SELECT id, task, completed FROM tasks"
           if only_pending:
               query += " WHERE completed = 0"
           cursor.execute(query)
           tasks = cursor.fetchall()
           conn.close()
           return tasks

       def to_markdown(self, output_file="tasks.md"):
           """Speichert Aufgaben als Markdown-Tabelle."""
           tasks = self.get_tasks(only_pending=False)
           if not tasks:
               return "Keine Aufgaben vorhanden."
           header = "| ID | Aufgabe | Status |\n|---|--------|--------|\n"
           rows = [f"| {task[0]} | {task[1]} | {'Erledigt' if task[2] else 'Offen'} |" for task in tasks]
           markdown = header + "\n".join(rows)
           with open(output_file, 'w') as f:
               f.write("# To-Do-Liste\n\n" + markdown)
           return markdown

   if __name__ == "__main__":
       todo = TodoManager()
       todo.add_task("Einkaufen gehen")
       todo.add_task("Python lernen")
       todo.complete_task(1)
       print("Alle Aufgaben:")
       for task in todo.get_tasks(only_pending=False):
           status = "Erledigt" if task[2] else "Offen"
           print(f"ID: {task[0]}, Aufgabe: {task[1]}, Status: {status}")
       print("\nMarkdown-Tabelle:")
       print(todo.to_markdown())
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   python3 todo_manager.py
   ```
   Die Ausgabe sollte so aussehen:
   ```
   Alle Aufgaben:
   ID: 1, Aufgabe: Einkaufen gehen, Status: Erledigt
   ID: 2, Aufgabe: Python lernen, Status: Offen

   Markdown-Tabelle:
   | ID | Aufgabe | Status |
   |---|--------|--------|
   | 1 | Einkaufen gehen | Erledigt |
   | 2 | Python lernen | Offen |
   ```

3. **Spielerei**: Überprüfe die Markdown-Ausgabe:
   ```bash
   cat tasks.md
   ```
   Die Datei sollte so aussehen:
   ```
   # To-Do-Liste

   | ID | Aufgabe | Status |
   |---|--------|--------|
   | 1 | Einkaufen gehen | Erledigt |
   | 2 | Python lernen | Offen |
   ```

4. **Schritt 3**: Überprüfe die Datenbank:
   ```bash
   sqlite3 todo.db "SELECT * FROM tasks;"
   ```
   Die Ausgabe sollte die Aufgaben anzeigen:
   ```
   1|Einkaufen gehen|1
   2|Python lernen|0
   ```

**Reflexion**: Wie vereinfacht die `TodoManager`-Klasse die Verwaltung von Aufgaben? Nutze `sqlite3 -help` und überlege, wie du weitere SQL-Befehle (z. B. `DELETE`) hinzufügen kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um SQLite-Grundlagen zu verinnerlichen.
- **Sicheres Testen**: Nutze Testverzeichnisse, um Datenbanken zu isolieren.
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze `help(sqlite3)` oder die SQLite-Dokumentation (https://www.sqlite.org/docs.html).
- **Effiziente Entwicklung**: Verwende `with`-Statements für Verbindungen, Platzhalter (`?`) für sichere Abfragen und Klassen für strukturierte Logik.
- **Kombiniere Tools**: Integriere SQLite mit Flask für Webanwendungen oder pandas für Analysen.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Hinzufügen von Prioritäten oder Kategorien für Aufgaben.

## Fazit
Mit diesen Übungen hast du die Grundlagen von SQLite mit Python gemeistert, einschließlich Erstellen von Datenbanken, Einfügen/Abfragen von Daten und grundlegender SQL-Nutzung. Die Spielerei zeigt, wie du eine To-Do-Liste mit SQLite und Markdown verwaltet. Vertiefe dein Wissen, indem du fortgeschrittene SQL-Konzepte (z. B. Joins, Indizes) oder Integration mit anderen Tools (z. B. Flask, pandas) ausprobierst. Wenn du ein spezifisches Thema (z. B. SQL-Abfragen oder Datenbankdesign) vertiefen möchtest, lass es mich wissen!
