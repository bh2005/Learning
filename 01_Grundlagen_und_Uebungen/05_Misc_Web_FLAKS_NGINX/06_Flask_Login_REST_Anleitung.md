# Praxisorientierte Anleitung: Fortgeschrittene Flask-Features mit Flask-Login und REST-APIs

## Einführung
Flask bietet mit **Flask-Login** eine robuste Lösung für Benutzer-Authentifizierung und mit **Flask-RESTful** eine einfache Möglichkeit, REST-APIs zu erstellen. Diese Anleitung baut auf grundlegenden Flask- und SQLite-Kenntnissen auf und konzentriert sich auf **Flask-Login für sichere Authentifizierung**, **REST-API-Entwicklung mit Flask-RESTful** und **Integration mit SQLite**. Die Webanwendung verwaltet eine **To-Do-Liste**, bei der Benutzer sich anmelden müssen, um Aufgaben zu erstellen, anzuzeigen oder über eine API abzufragen. Eine **Spielerei** zeigt, wie du die Aufgaben eines Benutzers als Markdown-Tabelle exportierst, um die Verbindung zu vorherigen Themen (z. B. Markdown-Ausgabe) herzustellen. Durch praktische Übungen lernst du, sichere und skalierbare Webanwendungen mit APIs zu entwickeln.

**Voraussetzungen**:
- Ein System mit Windows, macOS oder Linux (z. B. Windows 11, Ubuntu 22.04, macOS Ventura).
- Ein Terminal (PowerShell für Windows, Terminal für macOS/Linux).
- Python 3 installiert (prüfe mit `python3 --version`; installiere via `choco install python` auf Windows, `sudo apt install python3` auf Ubuntu oder `brew install python3` auf macOS).
- Flask, Flask-Login, Flask-RESTful und WTForms installiert (`pip install flask flask-login flask-restful flask-wtf`).
- SQLite ist in Python integriert (`sqlite3`-Modul, keine Installation nötig).
- Grundkenntnisse in Flask (Routen, Blueprints), SQLite (Tabellen, Abfragen) und HTML/CSS.
- Sichere Testumgebung (z. B. `$HOME/flask_login_rest` oder `~/flask_login_rest`).
- Ein Webbrowser (z. B. Chrome, Firefox) und ein API-Testtool (z. B. `curl` oder Postman).

## Grundlegende Befehle
Hier sind die wichtigsten Konzepte und Befehle für fortgeschrittene Flask-Features:

1. **Flask-Login für Authentifizierung**:
   - `from flask_login import LoginManager, UserMixin`: Importiert Authentifizierungs-Tools.
   - `login_manager.init_app(app)`: Initialisiert Flask-Login.
   - `@login_required`: Schützt Routen vor unbefugtem Zugriff.
   - `login_user(user)`: Meldet einen Benutzer an.
   - `logout_user()`: Meldet einen Benutzer ab.
2. **REST-API-Entwicklung mit Flask-RESTful**:
   - `from flask_restful import Api, Resource`: Importiert API-Tools.
   - `Api(app)`: Initialisiert die REST-API.
   - `api.add_resource()`: Fügt eine API-Ressource hinzu (z. B. für GET/POST).
3. **Integration mit SQLite**:
   - `sqlite3.connect()`: Verbindet mit der Datenbank.
   - `FOREIGN KEY`: Verknüpft Benutzer mit Aufgaben.
   - `INDEX`: Beschleunigt Abfragen.
4. **Nützliche Zusatzbefehle**:
   - `python3 app.py`: Führt die Flask-Anwendung aus.
   - `sqlite3 database.db`: Öffnet die SQLite-CLI.
   - `curl http://localhost:5000/api/tasks`: Testet die API.
   - `help(flask_login)`: Zeigt Dokumentation für Flask-Login.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Flask-Login für Benutzer-Authentifizierung
**Ziel**: Implementiere eine Anmeldung mit Flask-Login und schütze die To-Do-Liste.

1. **Schritt 1**: Erstelle ein Projektverzeichnis:
   ```bash
   mkdir flask_login_rest
   cd flask_login_rest
   mkdir templates
   ```

2. **Schritt 2**: Installiere die erforderlichen Bibliotheken:
   ```bash
   pip install flask flask-login flask-restful flask-wtf
   ```

3. **Schritt 3**: Erstelle HTML-Vorlagen:
   ```bash
   nano templates/login.html
   ```
   Füge folgenden Inhalt ein:
   ```html
   <!DOCTYPE html>
   <html>
   <head>
       <title>Anmeldung</title>
       <style>
           body { font-family: Arial, sans-serif; margin: 20px; }
           .error { color: red; }
       </style>
   </head>
   <body>
       <h1>Anmeldung</h1>
       <form method="POST">
           {{ form.hidden_tag() }}
           <p>
               {{ form.username.label }} {{ form.username(size=20) }}
               {% for error in form.username.errors %}
                   <span class="error">{{ error }}</span>
               {% endfor %}
           </p>
           <p>
               {{ form.password.label }} {{ form.password(size=20) }}
               {% for error in form.password.errors %}
                   <span class="error">{{ error }}</span>
               {% endfor %}
           </p>
           <p><input type="submit" value="Anmelden"></p>
       </form>
       <p><a href="{{ url_for('auth.register') }}">Registrieren</a></p>
   </body>
   </html>
   ```
   Speichere und schließe.

   ```bash
   nano templates/register.html
   ```
   Füge folgenden Inhalt ein:
   ```html
   <!DOCTYPE html>
   <html>
   <head>
       <title>Registrierung</title>
       <style>
           body { font-family: Arial, sans-serif; margin: 20px; }
           .error { color: red; }
       </style>
   </head>
   <body>
       <h1>Registrierung</h1>
       <form method="POST">
           {{ form.hidden_tag() }}
           <p>
               {{ form.username.label }} {{ form.username(size=20) }}
               {% for error in form.username.errors %}
                   <span class="error">{{ error }}</span>
               {% endfor %}
           </p>
           <p>
               {{ form.password.label }} {{ form.password(size=20) }}
               {% for error in form.password.errors %}
                   <span class="error">{{ error }}</span>
               {% endfor %}
           </p>
           <p><input type="submit" value="Registrieren"></p>
       </form>
       <p><a href="{{ url_for('auth.login') }}">Zur Anmeldung</a></p>
   </body>
   </html>
   ```

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
       <h1>To-Do-Liste von {{ current_user.username }}</h1>
       <p><a href="{{ url_for('auth.logout') }}">Abmelden</a></p>
       <h2>Neue Aufgabe hinzufügen</h2>
       <form method="POST" action="{{ url_for('tasks.add_task') }}">
           {{ form.hidden_tag() }}
           <p>
               {{ form.task.label }} {{ form.task(size=30) }}
               {% for error in form.task.errors %}
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
               <th>Status</th>
               <th>Aktion</th>
           </tr>
           {% for task in tasks %}
           <tr>
               <td>{{ task.id }}</td>
               <td>{{ task.task }}</td>
               <td>{{ 'Erledigt' if task.completed else 'Offen' }}</td>
               <td>
                   <form method="POST" action="{{ url_for('tasks.complete_task', task_id=task.id) }}">
                       <input type="submit" value="Erledigen">
                   </form>
               </td>
           </tr>
           {% endfor %}
       </table>
       <p><a href="{{ url_for('tasks.export') }}">Aufgaben als Markdown exportieren</a></p>
   </body>
   </html>
   ```
   Speichere und schließe.

4. **Schritt 4**: Erstelle Blueprints für Authentifizierung und Aufgaben:
   ```bash
   mkdir blueprints
   nano blueprints/auth.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from flask import Blueprint, render_template, request, redirect, url_for, flash
   from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required
   from flask_wtf import FlaskForm
   from wtforms import StringField, PasswordField
   from wtforms.validators import DataRequired, Length
   import sqlite3
   import hashlib

   auth_bp = Blueprint('auth', __name__)

   class User(UserMixin):
       def __init__(self, id, username):
           self.id = id
           self.username = username

   class LoginForm(FlaskForm):
       username = StringField('Benutzername', validators=[DataRequired(), Length(min=3, max=20)])
       password = PasswordField('Passwort', validators=[DataRequired(), Length(min=6)])

   class RegisterForm(FlaskForm):
       username = StringField('Benutzername', validators=[DataRequired(), Length(min=3, max=20)])
       password = PasswordField('Passwort', validators=[DataRequired(), Length(min=6)])

   def get_db():
       conn = sqlite3.connect("todo.db")
       conn.row_factory = sqlite3.Row
       return conn

   @auth_bp.route('/login', methods=['GET', 'POST'])
   def login():
       form = LoginForm()
       if form.validate_on_submit():
           conn = get_db()
           cursor = conn.cursor()
           hashed_password = hashlib.sha256(form.password.data.encode()).hexdigest()
           cursor.execute("SELECT id, username FROM users WHERE username = ? AND password = ?",
                         (form.username.data, hashed_password))
           user_data = cursor.fetchone()
           conn.close()
           if user_data:
               user = User(user_data['id'], user_data['username'])
               login_user(user)
               return redirect(url_for('tasks.index'))
           flash('Ungültiger Benutzername oder Passwort')
       return render_template('login.html', form=form)

   @auth_bp.route('/register', methods=['GET', 'POST'])
   def register():
       form = RegisterForm()
       if form.validate_on_submit():
           conn = get_db()
           cursor = conn.cursor()
           cursor.execute("SELECT id FROM users WHERE username = ?", (form.username.data,))
           if cursor.fetchone():
               flash('Benutzername existiert bereits')
           else:
               hashed_password = hashlib.sha256(form.password.data.encode()).hexdigest()
               cursor.execute("INSERT INTO users (username, password) VALUES (?, ?)",
                             (form.username.data, hashed_password))
               conn.commit()
               conn.close()
               return redirect(url_for('auth.login'))
       return render_template('register.html', form=form)

   @auth_bp.route('/logout')
   @login_required
   def logout():
       logout_user()
       return redirect(url_for('auth.login'))
   ```
   Speichere und schließe.

   ```bash
   nano blueprints/tasks.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from flask import Blueprint, render_template, request, redirect, url_for
   from flask_login import login_required, current_user
   from flask_wtf import FlaskForm
   from wtforms import StringField
   from wtforms.validators import DataRequired, Length
   import sqlite3

   tasks_bp = Blueprint('tasks', __name__)

   class TaskForm(FlaskForm):
       task = StringField('Aufgabe', validators=[DataRequired(), Length(min=1, max=100)])

   def get_db():
       conn = sqlite3.connect("todo.db")
       conn.row_factory = sqlite3.Row
       return conn

   @tasks_bp.route('/')
   @login_required
   def index():
       form = TaskForm()
       conn = get_db()
       cursor = conn.cursor()
       cursor.execute("SELECT id, task, completed FROM tasks WHERE user_id = ?", (current_user.id,))
       tasks = cursor.fetchall()
       conn.close()
       return render_template('index.html', tasks=tasks, form=form)

   @tasks_bp.route('/add', methods=['POST'])
   @login_required
   def add_task():
       form = TaskForm()
       if form.validate_on_submit():
           conn = get_db()
           cursor = conn.cursor()
           cursor.execute("INSERT INTO tasks (task, user_id) VALUES (?, ?)",
                         (form.task.data, current_user.id))
           conn.commit()
           conn.close()
       return redirect(url_for('tasks.index'))

   @tasks_bp.route('/complete/<int:task_id>', methods=['POST'])
   @login_required
   def complete_task(task_id):
       conn = get_db()
       cursor = conn.cursor()
       cursor.execute("UPDATE tasks SET completed = 1 WHERE id = ? AND user_id = ?",
                     (task_id, current_user.id))
       conn.commit()
       conn.close()
       return redirect(url_for('tasks.index'))

   @tasks_bp.route('/export', methods=['GET'])
   @login_required
   def export():
       conn = get_db()
       cursor = conn.cursor()
       cursor.execute("SELECT id, task, completed FROM tasks WHERE user_id = ?", (current_user.id,))
       tasks = cursor.fetchall()
       conn.close()
       if not tasks:
           return "Keine Aufgaben vorhanden.<br><a href='/'>Zurück</a>"
       header = "| ID | Aufgabe | Status |\n|---|--------|--------|\n"
       rows = [f"| {task['id']} | {task['task']} | {'Erledigt' if task['completed'] else 'Offen'} |" for task in tasks]
       markdown = header + "\n".join(rows)
       with open(f"tasks_{current_user.username}.md", 'w') as f:
           f.write(f"# To-Do-Liste von {current_user.username}\n\n" + markdown)
       return "<pre>" + markdown + "</pre><br><a href='/'>Zurück</a>"
   ```
   Speichere und schließe.

5. **Schritt 5**: Erstelle die Hauptanwendung:
   ```bash
   nano app.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from flask import Flask
   from flask_login import LoginManager
   from flask_restful import Api, Resource
   import sqlite3
   from blueprints.auth import auth_bp, User
   from blueprints.tasks import tasks_bp

   app = Flask(__name__)
   app.config['SECRET_KEY'] = 'your-secret-key'  # Für Flask-Login und WTForms erforderlich
   api = Api(app)
   login_manager = LoginManager()
   login_manager.init_app(app)
   login_manager.login_view = 'auth.login'

   def init_db():
       with sqlite3.connect("todo.db") as conn:
           cursor = conn.cursor()
           cursor.execute("""
               CREATE TABLE IF NOT EXISTS users (
                   id INTEGER PRIMARY KEY AUTOINCREMENT,
                   username TEXT NOT NULL UNIQUE,
                   password TEXT NOT NULL
               )
           """)
           cursor.execute("""
               CREATE TABLE IF NOT EXISTS tasks (
                   id INTEGER PRIMARY KEY AUTOINCREMENT,
                   task TEXT NOT NULL,
                   user_id INTEGER,
                   completed INTEGER DEFAULT 0,
                   FOREIGN KEY (user_id) REFERENCES users(id)
               )
           """)
           cursor.execute("CREATE INDEX IF NOT EXISTS idx_task ON tasks(task)")
           conn.commit()

   @login_manager.user_loader
   def load_user(user_id):
       conn = sqlite3.connect("todo.db")
       cursor = conn.cursor()
       cursor.execute("SELECT id, username FROM users WHERE id = ?", (user_id,))
       user_data = cursor.fetchone()
       conn.close()
       if user_data:
           return User(user_data[0], user_data[1])
       return None

   app.register_blueprint(auth_bp, url_prefix='/auth')
   app.register_blueprint(tasks_bp)

   if __name__ == '__main__':
       init_db()
       app.run(debug=True)
   ```
   Speichere und schließe.

6. **Schritt 6**: Führe die Anwendung aus:
   ```bash
   python3 app.py
   ```
   Gehe zu `http://localhost:5000/auth/register`:
   - Registriere einen Benutzer (z. B. Benutzername: "testuser", Passwort: "test123456").
   - Melde dich an und füge Aufgaben hinzu.
   - Markiere Aufgaben als erledigt und exportiere sie als Markdown unter `/export`.
   - Melde dich ab unter `/auth/logout`.

**Reflexion**: Wie schützt Flask-Login sensible Routen? Nutze `help(flask_login)` und überlege, wie du Passwort-Hashing mit `bcrypt` statt `hashlib` verbessern kannst.

### Übung 2: REST-API-Entwicklung mit Flask-RESTful
**Ziel**: Implementiere eine REST-API, um Aufgaben zu verwalten.

1. **Schritt 1**: Erstelle ein API-Modul:
   ```bash
   nano blueprints/api.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from flask import Blueprint
   from flask_restful import Api, Resource, reqparse
   from flask_login import login_required, current_user
   import sqlite3

   api_bp = Blueprint('api', __name__)
   api = Api(api_bp)

   def get_db():
       conn = sqlite3.connect("todo.db")
       conn.row_factory = sqlite3.Row
       return conn

   class TaskAPI(Resource):
       decorators = [login_required]

       def get(self):
           conn = get_db()
           cursor = conn.cursor()
           cursor.execute("SELECT id, task, completed FROM tasks WHERE user_id = ?", (current_user.id,))
           tasks = cursor.fetchall()
           conn.close()
           return [{"id": task["id"], "task": task["task"], "completed": bool(task["completed"])} for task in tasks]

       def post(self):
           parser = reqparse.RequestParser()
           parser.add_argument('task', type=str, required=True, help="Task cannot be blank")
           args = parser.parse_args()
           conn = get_db()
           cursor = conn.cursor()
           cursor.execute("INSERT INTO tasks (task, user_id) VALUES (?, ?)", (args['task'], current_user.id))
           conn.commit()
           cursor.execute("SELECT id, task, completed FROM tasks WHERE id = last_insert_rowid()")
           task = cursor.fetchone()
           conn.close()
           return {"id": task["id"], "task": task["task"], "completed": bool(task["completed"])}, 201

   api.add_resource(TaskAPI, '/tasks')
   ```
   Speichere und schließe.

2. **Schritt 2**: Registriere das API-Blueprint in `app.py`:
   ```bash
   nano app.py
   ```
   Füge vor `if __name__ == '__main__':` folgendes hinzu:
   ```python
   from blueprints.api import api_bp
   app.register_blueprint(api_bp, url_prefix='/api')
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe die Anwendung aus:
   ```bash
   python3 app.py
   ```
   Teste die API mit `curl`:
   - Melde dich im Browser an (`http://localhost:5000/auth/login`).
   - Hole Aufgaben:
     ```bash
     curl -u testuser:test123456 http://localhost:5000/api/tasks
     ```
   - Füge eine Aufgabe hinzu:
     ```bash
     curl -u testuser:test123456 -X POST -H "Content-Type: application/json" -d '{"task":"API-Test"}' http://localhost:5000/api/tasks
     ```

**Reflexion**: Wie erleichtert Flask-RESTful die API-Entwicklung? Nutze `help(flask_restful)` und überlege, wie du PUT/DELETE-Methoden hinzufügen kannst.

### Übung 3: Integration und Spielerei
**Ziel**: Exportiere benutzerspezifische Aufgaben als Markdown und teste die API.

1. **Schritt 1**: Die Markdown-Exportfunktion ist bereits in `tasks.py` unter `/export` implementiert.

2. **Schritt 2**: Teste die Anwendung:
   - Registriere einen Benutzer, melde dich an und füge Aufgaben hinzu.
   - Gehe zu `http://localhost:5000/export`, um die Markdown-Tabelle zu sehen.
   - Überprüfe die generierte Datei (z. B. `tasks_testuser.md`):
     ```bash
     cat tasks_testuser.md
     ```
     Nach dem Hinzufügen von "Einkaufen gehen" (erledigt) und "Python lernen" (offen) sollte die Datei so aussehen:
     ```
     # To-Do-Liste von testuser

     | ID | Aufgabe | Status |
     |---|--------|--------|
     | 1 | Einkaufen gehen | Erledigt |
     | 2 | Python lernen | Offen |
     ```

3. **Schritt 3**: Überprüfe die Datenbank:
   ```bash
   sqlite3 todo.db "SELECT t.id, t.task, t.completed, u.username FROM tasks t JOIN users u ON t.user_id = u.id;"
   ```

**Reflexion**: Wie verbessert die Benutzer-Authentifizierung die Datensicherheit? Nutze `help(sqlite3.Row)` und überlege, wie du die API mit Token-Authentifizierung erweitern kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Flask-Login und Flask-RESTful zu verinnerlichen.
- **Sicheres Testen**: Nutze `debug=True` für Flask und Testverzeichnisse.
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze die Flask-Dokumentation (https://flask.palletsprojects.com/).
- **Effiziente Entwicklung**: Verwende Blueprints für Modularität, WTForms für sichere Eingaben und Indizes für schnelle Abfragen.
- **Kombiniere Tools**: Integriere Redis für Caching oder Flask-JWT für API-Authentifizierung.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Hinzufügen von Kategorien oder API-Filter.

## Fazit
Mit diesen Übungen hast du fortgeschrittene Flask-Features wie Flask-Login und REST-APIs mit Flask-RESTful gemeistert, kombiniert mit SQLite für eine sichere To-Do-Liste. Die Spielerei zeigt, wie du benutzerspezifische Aufgaben als Markdown exportierst. Vertiefe dein Wissen, indem du weitere Features (z. B. Token-Authentifizierung, Pagination) oder andere Datenbanken (z. B. Redis, MongoDB) einbindest. Wenn du ein spezifisches Thema (z. B. API-Sicherheit oder Skalierung) vertiefen möchtest, lass es mich wissen!
