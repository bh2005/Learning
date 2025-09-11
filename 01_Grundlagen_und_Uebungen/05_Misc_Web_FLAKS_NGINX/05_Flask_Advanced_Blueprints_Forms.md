# Praxisorientierte Anleitung: Fortgeschrittene Flask-Features mit SQLite

## Einführung
Flask ist ein flexibles Python-Webframework, das mit fortgeschrittenen Features wie **Blueprints** für modulare Routen und **WTForms** für sichere Formularvalidierung leistungsstarke Webanwendungen ermöglicht. Diese Anleitung baut auf grundlegenden Flask- und SQLite-Kenntnissen auf und konzentriert sich auf **Flask-Blueprints**, **Formularvalidierung mit WTForms** und **erweiterte SQLite-Operationen**. Die Webanwendung verwaltet eine **To-Do-Liste** mit Prioritäten, Kategorien und Benutzer-authentifizierung. Eine **Spielerei** zeigt, wie du Aufgaben mit benutzerdefinierten Filtern als Markdown-Tabelle exportierst, um die Verbindung zu vorherigen Themen (z. B. Markdown-Ausgabe) herzustellen. Durch praktische Übungen lernst du, modulare, sichere und skalierbare Webanwendungen zu entwickeln.

**Voraussetzungen**:
- Ein System mit Windows, macOS oder Linux (z. B. Windows 11, Ubuntu 22.04, macOS Ventura).
- Ein Terminal (PowerShell für Windows, Terminal für macOS/Linux).
- Python 3 installiert (prüfe mit `python3 --version`; installiere via `choco install python` auf Windows, `sudo apt install python3` auf Ubuntu oder `brew install python3` auf macOS).
- Flask und WTForms installiert (`pip install flask flask-wtf`).
- SQLite ist in Python integriert (`sqlite3`-Modul, keine Installation nötig).
- Grundkenntnisse in Flask (Routen, Vorlagen), SQLite (Tabellen, Abfragen) und HTML/CSS.
- Sichere Testumgebung (z. B. `$HOME/flask_advanced` oder `~/flask_advanced`).
- Ein Webbrowser (z. B. Chrome, Firefox).

## Grundlegende Befehle
Hier sind die wichtigsten Konzepte und Befehle für fortgeschrittene Flask-Features:

1. **Flask-Blueprints**:
   - `from flask import Blueprint`: Erstellt ein modulares Blueprint.
   - `Blueprint('name', __name__)`: Definiert ein Blueprint mit einem Namen.
   - `app.register_blueprint()`: Registriert ein Blueprint in der Flask-Anwendung.
2. **Formularvalidierung mit WTForms**:
   - `from flask_wtf import FlaskForm`: Importiert die Formularklasse.
   - `wtforms.StringField`, `wtforms.IntegerField`: Definieren Formularfelder.
   - `wtforms.validators`: Validierungsregeln (z. B. `DataRequired`, `Length`).
   - `form.validate_on_submit()`: Prüft Formulardaten und Validierung.
3. **Erweiterte SQLite-Operationen**:
   - `JOIN`: Verknüpft Tabellen (z. B. Aufgaben mit Kategorien).
   - `INDEX`: Beschleunigt Abfragen.
   - `sqlite3.connect()`: Verbindet mit der Datenbank.
4. **Nützliche Zusatzbefehle**:
   - `python3 app.py`: Führt die Flask-Anwendung aus.
   - `sqlite3 database.db`: Öffnet die SQLite-CLI.
   - `help(flask.Blueprint)`: Zeigt Dokumentation für Blueprints.
   - `help(flask_wtf.FlaskForm)`: Zeigt Dokumentation für WTForms.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Flask-Blueprints für modulare Routen
**Ziel**: Organisiere die To-Do-Liste mit Blueprints für Aufgaben- und Benutzerverwaltung.

1. **Schritt 1**: Erstelle ein Projektverzeichnis:
   ```bash
   mkdir flask_advanced
   cd flask_advanced
   mkdir templates
   ```

2. **Schritt 2**: Installiere Flask und WTForms:
   ```bash
   pip install flask flask-wtf
   ```

3. **Schritt 3**: Erstelle eine HTML-Vorlage für die Startseite:
   ```bash
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
           .error { color: red; }
       </style>
   </head>
   <body>
       <h1>To-Do-Liste</h1>
       <h2>Neue Aufgabe hinzufügen</h2>
       <form method="POST">
           {{ form.hidden_tag() }}
           <p>
               {{ form.task.label }} {{ form.task(size=30) }}
               {% for error in form.task.errors %}
                   <span class="error">{{ error }}</span>
               {% endfor %}
           </p>
           <p>
               {{ form.priority.label }} {{ form.priority() }}
               {% for error in form.priority.errors %}
                   <span class="error">{{ error }}</span>
               {% endfor %}
           </p>
           <p>
               {{ form.category.label }} {{ form.category() }}
               {% for error in form.category.errors %}
                   <span class="error">{{ error }}</span>
               {% endfor %}
           </p>
           <p><input type="submit" value="Hinzufügen"></p>
       </form>
       <h2>Aufgaben</h2>
       <table>
           <tr>
               <th>ID</th>
               <th>Aufgabe</th>
               <th>Priorität</th>
               <th>Kategorie</th>
               <th>Status</th>
               <th>Aktion</th>
           </tr>
           {% for task in tasks %}
           <tr>
               <td>{{ task.id }}</td>
               <td>{{ task.task }}</td>
               <td>{{ task.priority }}</td>
               <td>{{ task.category_name }}</td>
               <td>{{ 'Erledigt' if task.completed else 'Offen' }}</td>
               <td>
                   <form method="POST" action="{{ url_for('tasks.complete_task', task_id=task.id) }}">
                       <input type="submit" value="Erledigen">
                   </form>
               </td>
           </tr>
           {% endfor %}
       </table>
       <h2>Aufgaben suchen</h2>
       <form method="GET" action="{{ url_for('tasks.search') }}">
           <input type="text" name="query" placeholder="Aufgabe oder Kategorie suchen">
           <input type="submit" value="Suchen">
       </form>
       <p><a href="{{ url_for('tasks.export') }}">Aufgaben als Markdown exportieren</a></p>
   </body>
   </html>
   ```
   Speichere und schließe.

4. **Schritt 4**: Erstelle ein Blueprint für Aufgaben:
   ```bash
   mkdir blueprints
   nano blueprints/tasks.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from flask import Blueprint, render_template, request, redirect, url_for
   from flask_wtf import FlaskForm
   from wtforms import StringField, IntegerField, SelectField
   from wtforms.validators import DataRequired, NumberRange, Length
   import sqlite3

   tasks_bp = Blueprint('tasks', __name__)

   class TaskForm(FlaskForm):
       task = StringField('Aufgabe', validators=[DataRequired(), Length(min=1, max=100)])
       priority = IntegerField('Priorität', validators=[DataRequired(), NumberRange(min=1, max=5)])
       category = SelectField('Kategorie', choices=[('work', 'Arbeit'), ('personal', 'Persönlich')], validators=[DataRequired()])

   def get_db():
       conn = sqlite3.connect("todo.db")
       conn.row_factory = sqlite3.Row
       return conn

   @tasks_bp.route('/')
   def index():
       """Rendert die Startseite mit Aufgaben."""
       form = TaskForm()
       conn = get_db()
       cursor = conn.cursor()
       cursor.execute("""
           SELECT t.id, t.task, t.priority, t.completed, c.name as category_name
           FROM tasks t JOIN categories c ON t.category_id = c.id
       """)
       tasks = cursor.fetchall()
       conn.close()
       return render_template('index.html', tasks=tasks, form=form)

   @tasks_bp.route('/add', methods=['POST'])
   def add_task():
       """Fügt eine neue Aufgabe hinzu."""
       form = TaskForm()
       if form.validate_on_submit():
           conn = get_db()
           cursor = conn.cursor()
           category_id = 1 if form.category.data == 'work' else 2
           cursor.execute("INSERT INTO tasks (task, priority, category_id) VALUES (?, ?, ?)",
                         (form.task.data, form.priority.data, category_id))
           conn.commit()
           conn.close()
       return redirect(url_for('tasks.index'))

   @tasks_bp.route('/complete/<int:task_id>', methods=['POST'])
   def complete_task(task_id):
       """Markiert eine Aufgabe als erledigt."""
       conn = get_db()
       cursor = conn.cursor()
       cursor.execute("UPDATE tasks SET completed = 1 WHERE id = ?", (task_id,))
       conn.commit()
       conn.close()
       return redirect(url_for('tasks.index'))

   @tasks_bp.route('/search', methods=['GET'])
   def search():
       """Sucht nach Aufgaben."""
       query = request.args.get('query', '')
       form = TaskForm()
       conn = get_db()
       cursor = conn.cursor()
       cursor.execute("""
           SELECT t.id, t.task, t.priority, t.completed, c.name as category_name
           FROM tasks t JOIN categories c ON t.category_id = c.id
           WHERE t.task LIKE ? OR c.name LIKE ?
       """, (f'%{query}%', f'%{query}%'))
       tasks = cursor.fetchall()
       conn.close()
       return render_template('index.html', tasks=tasks, form=form)
   ```
   Speichere und schließe.

5. **Schritt 5**: Erstelle die Hauptanwendung:
   ```bash
   nano app.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from flask import Flask
   import sqlite3
   from blueprints.tasks import tasks_bp

   app = Flask(__name__)
   app.config['SECRET_KEY'] = 'your-secret-key'  # Für WTForms erforderlich

   def init_db():
       """Initialisiert die SQLite-Datenbank."""
       with sqlite3.connect("todo.db") as conn:
           cursor = conn.cursor()
           cursor.execute("""
               CREATE TABLE IF NOT EXISTS categories (
                   id INTEGER PRIMARY KEY AUTOINCREMENT,
                   name TEXT NOT NULL
               )
           """)
           cursor.execute("""
               CREATE TABLE IF NOT EXISTS tasks (
                   id INTEGER PRIMARY KEY AUTOINCREMENT,
                   task TEXT NOT NULL,
                   priority INTEGER,
                   category_id INTEGER,
                   completed INTEGER DEFAULT 0,
                   FOREIGN KEY (category_id) REFERENCES categories(id)
               )
           """)
           # Füge Standardkategorien hinzu
           cursor.execute("INSERT OR IGNORE INTO categories (id, name) VALUES (1, 'work')")
           cursor.execute("INSERT OR IGNORE INTO categories (id, name) VALUES (2, 'personal')")
           conn.commit()

   app.register_blueprint(tasks_bp)
   init_db()

   if __name__ == '__main__':
       app.run(debug=True)
   ```
   Speichere und schließe.

6. **Schritt 6**: Führe die Anwendung aus:
   ```bash
   python3 app.py
   ```
   Gehe zu `http://localhost:5000`:
   - Füge Aufgaben mit Priorität (1-5) und Kategorie (Arbeit/Persönlich) hinzu.
   - Markiere Aufgaben als erledigt.
   - Suche nach Aufgaben oder Kategorien.

**Reflexion**: Wie verbessern Blueprints die Wartbarkeit der Anwendung? Nutze `help(flask.Blueprint)` und überlege, wie du ein Blueprint für Benutzerverwaltung hinzufügen kannst.

### Übung 2: Formularvalidierung mit WTForms
**Ziel**: Nutze WTForms für sichere Formularvalidierung und Fehlermeldungen.

1. **Schritt 1**: Die Formularvalidierung ist bereits im `TaskForm` in `tasks.py` integriert (siehe `DataRequired`, `NumberRange`, `Length`).

2. **Schritt 2**: Teste die Validierung:
   - Gehe zu `http://localhost:5000`.
   - Versuche, eine Aufgabe ohne Text oder mit einer Priorität außerhalb von 1-5 hinzuzufügen. Du solltest Fehlermeldungen unter den Feldern sehen.

**Reflexion**: Warum ist WTForms für sichere Eingaben wichtig? Nutze `help(wtforms.validators)` und überlege, wie du benutzerdefinierte Validatoren hinzufügen kannst.

### Übung 3: Erweiterte SQLite-Operationen und Spielerei
**Ziel**: Füge eine Markdown-Exportfunktion mit Filtern hinzu und optimiere die Datenbank mit Indizes.

1. **Schritt 1**: Erweitere das `tasks.py`-Blueprint mit einer Export-Route:
   ```bash
   nano blueprints/tasks.py
   ```
   Füge am Ende des Blueprints (vor `@tasks_bp.route('/search', ...)`) folgende Route und Methode hinzu:
   ```python
   @tasks_bp.route('/export', methods=['GET'])
   def export():
       """Exportiert Aufgaben als Markdown-Tabelle."""
       query = request.args.get('query', '')
       tasks = []
       conn = get_db()
       cursor = conn.cursor()
       if query:
           cursor.execute("""
               SELECT t.id, t.task, t.priority, t.completed, c.name as category_name
               FROM tasks t JOIN categories c ON t.category_id = c.id
               WHERE t.task LIKE ? OR c.name LIKE ?
           """, (f'%{query}%', f'%{query}%'))
       else:
           cursor.execute("""
               SELECT t.id, t.task, t.priority, t.completed, c.name as category_name
               FROM tasks t JOIN categories c ON t.category_id = c.id
           """)
       tasks = cursor.fetchall()
       conn.close()
       if not tasks:
           return "Keine Aufgaben vorhanden.<br><a href='/'>Zurück</a>"
       header = "| ID | Aufgabe | Priorität | Kategorie | Status |\n|---|--------|-----------|-----------|--------|\n"
       rows = [f"| {task['id']} | {task['task']} | {task['priority']} | {task['category_name']} | {'Erledigt' if task['completed'] else 'Offen'} |" for task in tasks]
       markdown = header + "\n".join(rows)
       with open("tasks.md", 'w') as f:
           f.write("# To-Do-Liste\n\n" + markdown)
       return "<pre>" + markdown + "</pre><br><a href='/'>Zurück</a>"
   ```
   Speichere und schließe.

2. **Schritt 2**: Optimiere die Datenbank mit einem Index:
   ```bash
   nano app.py
   ```
   Füge in der `init_db`-Funktion vor `conn.commit()` folgendes hinzu:
   ```python
           cursor.execute("CREATE INDEX IF NOT EXISTS idx_task ON tasks(task)")
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe die Anwendung aus:
   ```bash
   python3 app.py
   ```
   Gehe zu `http://localhost:5000`:
   - Füge Aufgaben hinzu (z. B. "Einkaufen gehen", Priorität 2, Kategorie Persönlich).
   - Suche nach Aufgaben (z. B. "Einkaufen").
   - Klicke auf "Aufgaben als Markdown exportieren" oder gehe zu `http://localhost:5000/export?query=Einkaufen`.

4. **Spielerei**: Überprüfe die Markdown-Ausgabe:
   ```bash
   cat tasks.md
   ```
   Nach dem Hinzufügen von "Einkaufen gehen" (Persönlich, Priorität 2, erledigt) und "Python lernen" (Arbeit, Priorität 1, offen) sollte die Datei so aussehen:
   ```
   # To-Do-Liste

   | ID | Aufgabe | Priorität | Kategorie | Status |
   |---|--------|-----------|-----------|--------|
   | 1 | Einkaufen gehen | 2 | personal | Erledigt |
   | 2 | Python lernen | 1 | work | Offen |
   ```

5. **Schritt 4**: Überprüfe die Datenbank:
   ```bash
   sqlite3 todo.db "SELECT t.id, t.task, t.priority, t.completed, c.name FROM tasks t JOIN categories c ON t.category_id = c.id;"
   ```

**Reflexion**: Wie verbessert ein Index die Suchperformance? Nutze `help(sqlite3.Row)` und überlege, wie du Benutzer-authentifizierung hinzufügen kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Blueprints und WTForms zu verinnerlichen.
- **Sicheres Testen**: Nutze `debug=True` für Flask und Testverzeichnisse.
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze `help(flask_wtf)` oder die Flask-Dokumentation (https://flask.palletsprojects.com/).
- **Effiziente Entwicklung**: Verwende Blueprints für modulare Struktur, WTForms für sichere Eingaben und Indizes für schnelle Abfragen.
- **Kombiniere Tools**: Integriere Redis für Caching oder Flask-Login für Authentifizierung.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Hinzufügen von Löschfunktionen oder Benutzerrollen.

## Fazit
Mit diesen Übungen hast du fortgeschrittene Flask-Features wie Blueprints und WTForms gemeistert, kombiniert mit SQLite für eine skalierbare To-Do-Liste. Die Spielerei zeigt, wie du Aufgaben mit Filtern als Markdown exportierst. Vertiefe dein Wissen, indem du weitere Flask-Features (z. B. Flask-Login, REST-APIs) oder Datenbanken (z. B. Redis, MongoDB) einbindest. Wenn du ein spezifisches Thema (z. B. Authentifizierung oder REST-APIs) vertiefen möchtest, lass es mich wissen!
