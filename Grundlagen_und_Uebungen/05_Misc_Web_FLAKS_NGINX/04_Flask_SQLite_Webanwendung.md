# Praxisorientierte Anleitung: Einfache Webanwendung mit Flask und SQLite für Anfänger

## Einführung
Flask ist ein leichtgewichtiges Python-Webframework, das ideal für einfache Webanwendungen ist. In Kombination mit SQLite kannst du Daten wie Aufgaben in einer To-Do-Liste speichern, suchen und anzeigen. Diese Anleitung führt Anfänger in die Entwicklung einer Webanwendung ein, mit Fokus auf **Einrichten einer Flask-Anwendung**, **Verbindung mit SQLite** und **Erstellen von Routen für CRUD-Operationen** (Create, Read, Update, Delete). Eine **Spielerei** zeigt, wie du die Aufgabenliste als Markdown-Tabelle exportierst, um eine Verbindung zu vorherigen Themen (z. B. Markdown-Ausgabe) herzustellen. Durch praktische Übungen lernst du, eine Webanwendung zu erstellen, die Daten in einer SQLite-Datenbank verwaltet.

**Voraussetzungen**:
- Ein System mit Windows, macOS oder Linux (z. B. Windows 11, Ubuntu 22.04, macOS Ventura).
- Ein Terminal (PowerShell für Windows, Terminal für macOS/Linux).
- Python 3 installiert (prüfe mit `python3 --version`; installiere via `choco install python` auf Windows, `sudo apt install python3` auf Ubuntu oder `brew install python3` auf macOS).
- Flask installiert (`pip install flask`).
- SQLite ist in Python integriert (`sqlite3`-Modul, keine Installation nötig).
- Grundkenntnisse in Python (Funktionen, Klassen) und SQLite (Tabellen, Abfragen).
- Sichere Testumgebung (z. B. `$HOME/flask_todo` oder `~/flask_todo`).
- Ein Webbrowser (z. B. Chrome, Firefox).

## Grundlegende Befehle
Hier sind die wichtigsten Konzepte und Befehle für die Webanwendung:

1. **Einrichten einer Flask-Anwendung**:
   - `from flask import Flask`: Importiert Flask.
   - `app = Flask(__name__)`: Erstellt eine Flask-Anwendung.
   - `@app.route('/')`: Definiert eine Route für die URL.
   - `app.run()`: Startet den Flask-Entwicklungsserver.
2. **Verbindung mit SQLite**:
   - `sqlite3.connect('database.db')`: Verbindet mit einer SQLite-Datenbank.
   - `cursor.execute()`: Führt SQL-Befehle aus (z. B. `INSERT`, `SELECT`).
   - `conn.commit()`: Speichert Änderungen.
3. **Erstellen von Routen für CRUD-Operationen**:
   - `render_template()`: Rendert HTML-Vorlagen.
   - `request.form`: Verarbeitet Formulardaten.
   - `redirect()`: Leitet zu einer anderen Route um.
4. **Nützliche Zusatzbefehle**:
   - `python3 app.py`: Führt die Flask-Anwendung aus.
   - `sqlite3 database.db`: Öffnet die SQLite-CLI zum Überprüfen der Datenbank.
   - `help(flask)`: Zeigt Python-Dokumentation für Flask.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Einrichten einer Flask-Anwendung
**Ziel**: Erstelle eine einfache Flask-Anwendung mit einer Startseite.

1. **Schritt 1**: Erstelle ein Projektverzeichnis:
   ```bash
   mkdir flask_todo
   cd flask_todo
   ```

2. **Schritt 2**: Installiere Flask:
   ```bash
   pip install flask
   ```

3. **Schritt 3**: Erstelle eine HTML-Vorlage für die Startseite:
   ```bash
   mkdir templates
   nano templates/index.html
   ```
   Füge folgenden Inhalt ein:
   ```html
   <!DOCTYPE html>
   <html>
   <head>
       <title>To-Do-Liste</title>
       <style>
           body { font-family: Arial, sans-serif; margin: 20px; }
           table { border-collapse: collapse; width: 100%; }
           th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
           th { background-color: #f2f2f2; }
           form { margin-bottom: 20px; }
       </style>
   </head>
   <body>
       <h1>To-Do-Liste</h1>
       <form method="POST" action="/add">
           <input type="text" name="task" placeholder="Neue Aufgabe" required>
           <input type="submit" value="Hinzufügen">
       </form>
       <h2>Aufgaben</h2>
       <table>
           <tr>
               <th>ID</th>
               <th>Aufgabe</th>
               <th>Status</th>
               <th>Aktion</th>
           </tr>
           {% for task in tasks %}
           <tr>
               <td>{{ task[0] }}</td>
               <td>{{ task[1] }}</td>
               <td>{{ 'Erledigt' if task[2] else 'Offen' }}</td>
               <td>
                   <form method="POST" action="/complete/{{ task[0] }}">
                       <input type="submit" value="Erledigen">
                   </form>
               </td>
           </tr>
           {% endfor %}
       </table>
       <h2>Aufgaben suchen</h2>
       <form method="GET" action="/search">
           <input type="text" name="query" placeholder="Aufgabe suchen">
           <input type="submit" value="Suchen">
       </form>
   </body>
   </html>
   ```
   Speichere und schließe.

4. **Schritt 4**: Erstelle ein Flask-Skript für die Startseite:
   ```bash
   nano app.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from flask import Flask, render_template

   app = Flask(__name__)

   @app.route('/')
   def index():
       """Rendert die Startseite."""
       return render_template('index.html', tasks=[])

   if __name__ == '__main__':
       app.run(debug=True)
   ```
   Speichere und schließe.

5. **Schritt 5**: Führe die Anwendung aus:
   ```bash
   python3 app.py
   ```
   Öffne einen Browser und gehe zu `http://localhost:5000`. Du solltest eine einfache Seite mit einem Formular und einer leeren Tabelle sehen.

**Reflexion**: Warum ist Flask für kleine Webanwendungen geeignet? Nutze `help(flask.Flask)` und überlege, wie du die Seite mit CSS verbessern kannst.

### Übung 2: Verbindung mit SQLite
**Ziel**: Verbinde die Flask-Anwendung mit SQLite, um Aufgaben zu speichern und anzuzeigen.

1. **Schritt 1**: Erstelle ein Skript mit SQLite-Integration:
   ```bash
   nano app.py
   ```
   Ersetze den Inhalt durch:
   ```python
   from flask import Flask, render_template, request, redirect, url_for
   import sqlite3

   app = Flask(__name__)

   def init_db():
       """Initialisiert die SQLite-Datenbank."""
       conn = sqlite3.connect("todo.db")
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

   def get_tasks():
       """Ruft alle Aufgaben aus der Datenbank ab."""
       conn = sqlite3.connect("todo.db")
       cursor = conn.cursor()
       cursor.execute("SELECT id, task, completed FROM tasks")
       tasks = cursor.fetchall()
       conn.close()
       return tasks

   def add_task(task):
       """Fügt eine neue Aufgabe hinzu."""
       conn = sqlite3.connect("todo.db")
       cursor = conn.cursor()
       cursor.execute("INSERT INTO tasks (task) VALUES (?)", (task,))
       conn.commit()
       conn.close()

   @app.route('/')
   def index():
       """Rendert die Startseite mit Aufgaben."""
       init_db()  # Stelle sicher, dass die Datenbank existiert
       tasks = get_tasks()
       return render_template('index.html', tasks=tasks)

   @app.route('/add', methods=['POST'])
   def add():
       """Fügt eine neue Aufgabe hinzu."""
       task = request.form['task']
       add_task(task)
       return redirect(url_for('index'))

   if __name__ == '__main__':
       app.run(debug=True)
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe die Anwendung aus:
   ```bash
   python3 app.py
   ```
   Gehe zu `http://localhost:5000`, gib eine Aufgabe (z. B. "Einkaufen gehen") ins Formular ein und klicke auf "Hinzufügen". Die Aufgabe sollte in der Tabelle erscheinen.

3. **Schritt 3**: Überprüfe die Datenbank:
   ```bash
   sqlite3 todo.db "SELECT * FROM tasks;"
   ```

**Reflexion**: Warum ist `conn.commit()` für Datenbankänderungen wichtig? Nutze `help(sqlite3)` und überlege, wie du die Datenbankverbindung in einer Klasse organisieren kannst.

### Übung 3: Routen für CRUD-Operationen und Spielerei
**Ziel**: Erweitere die Anwendung mit Routen zum Erledigen und Suchen von Aufgaben und füge eine Funktion zum Exportieren als Markdown hinzu.

1. **Schritt 1**: Erweitere das Skript mit vollständigen CRUD-Operationen:
   ```bash
   nano app.py
   ```
   Ersetze den Inhalt durch:
   ```python
   from flask import Flask, render_template, request, redirect, url_for
   import sqlite3

   app = Flask(__name__)

   class TodoApp:
       def __init__(self, db_name="todo.db"):
           self.db_name = db_name
           self.init_db()

       def init_db(self):
           """Initialisiert die SQLite-Datenbank."""
           with sqlite3.connect(self.db_name) as conn:
               cursor = conn.cursor()
               cursor.execute("""
                   CREATE TABLE IF NOT EXISTS tasks (
                       id INTEGER PRIMARY KEY AUTOINCREMENT,
                       task TEXT NOT NULL,
                       completed INTEGER DEFAULT 0
                   )
               """)
               conn.commit()

       def add_task(self, task):
           """Fügt eine neue Aufgabe hinzu."""
           with sqlite3.connect(self.db_name) as conn:
               cursor = conn.cursor()
               cursor.execute("INSERT INTO tasks (task) VALUES (?)", (task,))
               conn.commit()

       def complete_task(self, task_id):
           """Markiert eine Aufgabe als erledigt."""
           with sqlite3.connect(self.db_name) as conn:
               cursor = conn.cursor()
               cursor.execute("UPDATE tasks SET completed = 1 WHERE id = ?", (task_id,))
               conn.commit()

       def get_tasks(self, query=None):
           """Ruft Aufgaben ab, optional mit Suchfilter."""
           with sqlite3.connect(self.db_name) as conn:
               cursor = conn.cursor()
               if query:
                   cursor.execute("SELECT id, task, completed FROM tasks WHERE task LIKE ?", (f'%{query}%',))
               else:
                   cursor.execute("SELECT id, task, completed FROM tasks")
               tasks = cursor.fetchall()
           return tasks

       def to_markdown(self, output_file="tasks.md"):
           """Speichert Aufgaben als Markdown-Tabelle."""
           tasks = self.get_tasks()
           if not tasks:
               return "Keine Aufgaben vorhanden."
           header = "| ID | Aufgabe | Status |\n|---|--------|--------|\n"
           rows = [f"| {task[0]} | {task[1]} | {'Erledigt' if task[2] else 'Offen'} |" for task in tasks]
           markdown = header + "\n".join(rows)
           with open(output_file, 'w') as f:
               f.write("# To-Do-Liste\n\n" + markdown)
           return markdown

   todo = TodoApp()

   @app.route('/')
   def index():
       """Rendert die Startseite mit Aufgaben."""
       tasks = todo.get_tasks()
       return render_template('index.html', tasks=tasks)

   @app.route('/add', methods=['POST'])
   def add():
       """Fügt eine neue Aufgabe hinzu."""
       task = request.form['task']
       todo.add_task(task)
       return redirect(url_for('index'))

   @app.route('/complete/<int:task_id>', methods=['POST'])
   def complete(task_id):
       """Markiert eine Aufgabe als erledigt."""
       todo.complete_task(task_id)
       return redirect(url_for('index'))

   @app.route('/search', methods=['GET'])
   def search():
       """Sucht nach Aufgaben."""
       query = request.args.get('query', '')
       tasks = todo.get_tasks(query)
       return render_template('index.html', tasks=tasks)

   @app.route('/export', methods=['GET'])
   def export():
       """Exportiert Aufgaben als Markdown."""
       markdown = todo.to_markdown()
       return "<pre>" + markdown + "</pre><br><a href='/'>Zurück</a>"

   if __name__ == '__main__':
       app.run(debug=True)
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe die Anwendung aus:
   ```bash
   python3 app.py
   ```
   Gehe zu `http://localhost:5000`:
   - Füge Aufgaben hinzu (z. B. "Einkaufen gehen", "Python lernen").
   - Markiere Aufgaben als erledigt mit dem Button "Erledigen".
   - Suche nach Aufgaben (z. B. gib "Einkaufen" ein).
   - Gehe zu `http://localhost:5000/export`, um die Markdown-Tabelle zu sehen.

3. **Spielerei**: Überprüfe die Markdown-Ausgabe:
   ```bash
   cat tasks.md
   ```
   Nach dem Hinzufügen von "Einkaufen gehen" und "Python lernen" (wobei die erste Aufgabe erledigt ist) sollte die Datei so aussehen:
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

**Reflexion**: Wie vereinfacht Flask die Erstellung von Webanwendungen? Nutze `help(flask.render_template)` und überlege, wie du die Oberfläche mit Bootstrap oder zusätzlichen Funktionen (z. B. Löschen) verbessern kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Flask und SQLite zu verinnerlichen.
- **Sicheres Testen**: Nutze Testverzeichnisse und `debug=True` für Flask.
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze `help(flask)` oder die Flask-Dokumentation (https://flask.palletsprojects.com/).
- **Effiziente Entwicklung**: Verwende `with`-Statements für SQLite, Klassen für strukturierte Logik und Vorlagen für sauberes HTML.
- **Kombiniere Tools**: Integriere Flask mit Redis für Caching oder pandas für Datenanalysen.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Hinzufügen von Aufgabenprioritäten oder einem Lösch-Button.

## Fazit
Mit diesen Übungen hast du eine einfache Webanwendung mit Flask und SQLite erstellt, die Daten speichert, sucht und anzeigt. Die Spielerei zeigt, wie du Aufgaben als Markdown exportierst. Vertiefe dein Wissen, indem du fortgeschrittene Flask-Features (z. B. Blueprints, Formularvalidierung) oder andere Datenbanken (z. B. Redis, MongoDB) einbindest. Wenn du ein spezifisches Thema (z. B. Formularvalidierung oder Styling) vertiefen möchtest, lass es mich wissen!
