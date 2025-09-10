# Praxisorientierte Anleitung: Fortgeschrittene Flask-Features mit JWT-Authentifizierung und Pagination

## Einführung
Flask ermöglicht mit **JSON Web Tokens (JWT)** eine sichere API-Authentifizierung und mit **Pagination** eine effiziente Datenverwaltung für große Datensätze. Diese Anleitung baut auf Kenntnissen in Flask, Flask-Login und REST-APIs auf und konzentriert sich auf **JWT für API-Authentifizierung**, **Pagination für effiziente Datenabfragen** und **Integration mit SQLite**. Die Webanwendung erweitert eine To-Do-Liste, bei der Benutzer sich anmelden und über eine REST-API mit JWT-Zugriff Aufgaben verwalten können, mit Unterstützung für paginierte Ergebnisse. Eine **Spielerei** zeigt, wie du paginierte Aufgaben eines Benutzers als Markdown-Tabelle exportierst, um die Verbindung zu vorherigen Themen (z. B. Markdown-Ausgabe) herzustellen. Durch praktische Übungen lernst du, sichere und skalierbare APIs zu entwickeln.

**Voraussetzungen**:
- Ein System mit Windows, macOS oder Linux (z. B. Windows 11, Ubuntu 22.04, macOS Ventura).
- Ein Terminal (PowerShell für Windows, Terminal für macOS/Linux).
- Python 3 installiert (prüfe mit `python3 --version`; installiere via `choco install python` auf Windows, `sudo apt install python3` auf Ubuntu oder `brew install python3` auf macOS).
- Flask, Flask-Login, Flask-RESTful, Flask-JWT-Extended und WTForms installiert (`pip install flask flask-login flask-restful flask-jwt-extended flask-wtf`).
- SQLite ist in Python integriert (`sqlite3`-Modul, keine Installation nötig).
- Kenntnisse in Flask (Routen, Blueprints), Flask-Login, REST-APIs, SQLite (Tabellen, Abfragen) und HTML/CSS.
- Sichere Testumgebung (z. B. `$HOME/flask_jwt_pagination` oder `~/flask_jwt_pagination`).
- Ein Webbrowser (z. B. Chrome, Firefox) und ein API-Testtool (z. B. `curl` oder Postman).

## Grundlegende Befehle
Hier sind die wichtigsten Konzepte und Befehle für die fortgeschrittenen Features:

1. **JWT-Authentifizierung mit Flask-JWT-Extended**:
   - `from flask_jwt_extended import JWTManager, jwt_required, create_access_token`: Importiert JWT-Tools.
   - `jwt.init_app(app)`: Initialisiert JWT.
   - `@jwt_required()`: Schützt API-Routen.
   - `create_access_token(identity)`: Erstellt ein JWT-Token.
2. **Pagination für REST-APIs**:
   - `LIMIT` und `OFFSET` in SQL: Begrenzt und verschiebt die abgefragten Daten.
   - `request.args.get()`: Liest Query-Parameter (z. B. `page`, `per_page`).
   - `Flask-RESTful Resource`: Verarbeitet paginierte API-Anfragen.
3. **Integration mit SQLite**:
   - `sqlite3.connect()`: Verbindet mit der Datenbank.
   - `FOREIGN KEY`: Verknüpft Benutzer mit Aufgaben.
   - `INDEX`: Beschleunigt Abfragen.
4. **Nützliche Zusatzbefehle**:
   - `python3 app.py`: Führt die Flask-Anwendung aus.
   - `sqlite3 database.db`: Öffnet die SQLite-CLI.
   - `curl -H "Authorization: Bearer <token>" http://localhost:5000/api/tasks`: Testet die API.
   - `help(flask_jwt_extended)`: Zeigt Dokumentation für JWT.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: JWT-Authentifizierung für die API
**Ziel**: Implementiere eine sichere REST-API mit JWT-Authentifizierung.

1. **Schritt 1**: Erstelle ein Projektverzeichnis:
   ```bash
   mkdir flask_jwt_pagination
   cd flask_jwt_pagination
   mkdir templates blueprints
   ```

2. **Schritt 2**: Installiere die erforderlichen Bibliotheken:
   ```bash
   pip install flask flask-login flask-restful flask-jwt-extended flask-wtf
   ```

3. **Schritt 3**: Erstelle HTML-Vorlagen (aus vorheriger Anleitung übernommen):
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

4. **Schritt 4**: Erstelle Blueprints für Authentifizierung, Aufgaben und API:
   ```bash
   nano blueprints/auth.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from flask import Blueprint, render_template, request, redirect, url_for, flash
   from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required
   from flask_wtf import FlaskForm
   from wtforms import StringField, PasswordField
   from wtforms.validators import DataRequired, Length
   from flask_jwt_extended import create_access_token
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
               access_token = create_access_token(identity=user_data['id'])
               flash(f'API-Token: {access_token}', 'info')
               return redirect(url_for('tasks.index'))
           flash('Ungültiger Benutzername oder Passwort', 'error')
       return render_template('login.html', form=form)

   @auth_bp.route('/register', methods=['GET', 'POST'])
   def register():
       form = RegisterForm()
       if form.validate_on_submit():
           conn = get_db()
           cursor = conn.cursor()
           cursor.execute("SELECT id FROM users WHERE username = ?", (form.username.data,))
           if cursor.fetchone():
               flash('Benutzername existiert bereits', 'error')
           else:
               hashed_password = hashlib.sha256(form.password.data.encode()).hexdigest()
               cursor.execute("INSERT INTO users (username, password) VALUES (?, ?)",
                             (form.username.data, hashed_password))
               conn.commit()
               conn.close()
               flash('Registrierung erfolgreich! Bitte anmelden.', 'success')
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
       page = int(request.args.get('page', 1))
       per_page = int(request.args.get('per_page', 5))
       offset = (page - 1) * per_page
       conn = get_db()
       cursor = conn.cursor()
       cursor.execute("SELECT COUNT(*) as count FROM tasks WHERE user_id = ?", (current_user.id,))
       total = cursor.fetchone()['count']
       cursor.execute("SELECT id, task, completed FROM tasks WHERE user_id = ? LIMIT ? OFFSET ?",
                     (current_user.id, per_page, offset))
       tasks = cursor.fetchall()
       conn.close()
       if not tasks:
           return "Keine Aufgaben vorhanden.<br><a href='/'>Zurück</a>"
       header = "| ID | Aufgabe | Status |\n|---|--------|--------|\n"
       rows = [f"| {task['id']} | {task['task']} | {'Erledigt' if task['completed'] else 'Offen'} |" for task in tasks]
       markdown = header + "\n".join(rows)
       with open(f"tasks_{current_user.username}.md", 'w') as f:
           f.write(f"# To-Do-Liste von {current_user.username} (Seite {page})\n\n" + markdown)
       return f"<pre>{markdown}</pre><p>Total: {total} | Page: {page}</p><br><a href='/'>Zurück</a>"
   ```
   Speichere und schließe.

   ```bash
   nano blueprints/api.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from flask import Blueprint
   from flask_restful import Api, Resource, reqparse
   from flask_jwt_extended import jwt_required, get_jwt_identity
   import sqlite3

   api_bp = Blueprint('api', __name__)
   api = Api(api_bp)

   def get_db():
       conn = sqlite3.connect("todo.db")
       conn.row_factory = sqlite3.Row
       return conn

   class TaskAPI(Resource):
       @jwt_required()
       def get(self):
           parser = reqparse.RequestParser()
           parser.add_argument('page', type=int, default=1)
           parser.add_argument('per_page', type=int, default=5)
           args = parser.parse_args()
           user_id = get_jwt_identity()
           page = args['page']
           per_page = args['per_page']
           offset = (page - 1) * per_page
           conn = get_db()
           cursor = conn.cursor()
           cursor.execute("SELECT COUNT(*) as count FROM tasks WHERE user_id = ?", (user_id,))
           total = cursor.fetchone()['count']
           cursor.execute("SELECT id, task, completed FROM tasks WHERE user_id = ? LIMIT ? OFFSET ?",
                         (user_id, per_page, offset))
           tasks = cursor.fetchall()
           conn.close()
           return {
               "tasks": [{"id": task["id"], "task": task["task"], "completed": bool(task["completed"])} for task in tasks],
               "total": total,
               "page": page,
               "per_page": per_page
           }

       @jwt_required()
       def post(self):
           parser = reqparse.RequestParser()
           parser.add_argument('task', type=str, required=True, help="Task cannot be blank")
           args = parser.parse_args()
           user_id = get_jwt_identity()
           conn = get_db()
           cursor = conn.cursor()
           cursor.execute("INSERT INTO tasks (task, user_id) VALUES (?, ?)", (args['task'], user_id))
           conn.commit()
           cursor.execute("SELECT id, task, completed FROM tasks WHERE id = last_insert_rowid()")
           task = cursor.fetchone()
           conn.close()
           return {"id": task["id"], "task": task["task"], "completed": bool(task["completed"])}, 201

   api.add_resource(TaskAPI, '/tasks')
   ```
   Speichere und schließe.

5. **Schritt 5**: Erstelle die Hauptanwendung:
   ```bash
   nano app.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from flask import Flask
   from flask_login import LoginManager, UserMixin
   from flask_restful import Api
   from flask_jwt_extended import JWTManager
   import sqlite3
   from blueprints.auth import auth_bp, User
   from blueprints.tasks import tasks_bp
   from blueprints.api import api_bp

   app = Flask(__name__)
   app.config['SECRET_KEY'] = 'your-secret-key'  # Für Flask-Login und WTForms
   app.config['JWT_SECRET_KEY'] = 'your-jwt-secret-key'  # Für JWT
   api = Api(app)
   login_manager = LoginManager()
   login_manager.init_app(app)
   login_manager.login_view = 'auth.login'
   jwt = JWTManager(app)

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
   app.register_blueprint(api_bp, url_prefix='/api')

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
   - Melde dich an. Beachte das JWT-Token in der Flash-Nachricht.
   - Füge Aufgaben hinzu und markiere sie als erledigt.
   - Exportiere Aufgaben unter `/export?page=1&per_page=2` (für Seite 1 mit 2 Aufgaben pro Seite).

7. **Schritt 7**: Teste die API mit `curl`:
   - Kopiere das JWT-Token aus der Anmeldung.
   - Hole paginierte Aufgaben:
     ```bash
     curl -H "Authorization: Bearer <your-jwt-token>" http://localhost:5000/api/tasks?page=1&per_page=2
     ```
   - Füge eine Aufgabe hinzu:
     ```bash
     curl -H "Authorization: Bearer <your-jwt-token>" -X POST -H "Content-Type: application/json" -d '{"task":"API-Test"}' http://localhost:5000/api/tasks
     ```

**Reflexion**: Wie verbessert JWT die API-Sicherheit gegenüber Basic Auth? Nutze `help(flask_jwt_extended)` und überlege, wie du Refresh-Tokens hinzufügen kannst.

### Übung 2: Pagination für REST-APIs
**Ziel**: Nutze Pagination, um Aufgaben effizient abzufragen.

1. **Schritt 1**: Die Pagination ist bereits in `api.py` (GET-Methode) und `tasks.py` (Export-Route) implementiert.

2. **Schritt 2**: Teste die Pagination:
   - Füge mehrere Aufgaben hinzu (z. B. 6 Aufgaben).
   - Gehe zu `http://localhost:5000/export?page=1&per_page=2` (zeigt die ersten 2 Aufgaben).
   - Teste die API:
     ```bash
     curl -H "Authorization: Bearer <your-jwt-token>" http://localhost:5000/api/tasks?page=2&per_page=2
     ```
     Die Ausgabe sollte die Aufgaben 3-4 und Metadaten (total, page, per_page) enthalten.

**Reflexion**: Warum ist Pagination für große Datensätze wichtig? Nutze `help(sqlite3)` und überlege, wie du die Abfrage mit `ORDER BY` optimieren kannst.

### Übung 3: Integration und Spielerei
**Ziel**: Exportiere paginierte Aufgaben als Markdown und teste die API.

1. **Schritt 1**: Die Markdown-Exportfunktion ist in `tasks.py` unter `/export` implementiert.

2. **Schritt 2**: Teste die Anwendung:
   - Registriere einen Benutzer, melde dich an und füge Aufgaben hinzu (z. B. "Einkaufen gehen", "Python lernen", "API testen").
   - Gehe zu `http://localhost:5000/export?page=1&per_page=2`.
   - Überprüfe die generierte Datei (z. B. `tasks_testuser.md`):
     ```bash
     cat tasks_testuser.md
     ```
     Die Datei sollte so aussehen (bei 3 Aufgaben, Seite 1, 2 pro Seite):
     ```
     # To-Do-Liste von testuser (Seite 1)

     | ID | Aufgabe | Status |
     |---|--------|--------|
     | 1 | Einkaufen gehen | Offen |
     | 2 | Python lernen | Offen |
     ```

3. **Schritt 3**: Überprüfe die Datenbank:
   ```bash
   sqlite3 todo.db "SELECT t.id, t.task, t.completed, u.username FROM tasks t JOIN users u ON t.user_id = u.id;"
   ```

**Reflexion**: Wie verbessert Pagination die Benutzererfahrung in der API? Nutze `help(flask_restful)` und überlege, wie du die API um Filter (z. B. nach Status) erweitern kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um JWT und Pagination zu verinnerlichen.
- **Sicheres Testen**: Nutze `debug=True` für Flask und Testverzeichnisse.
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze die Flask-Dokumentation (https://flask.palletsprojects.com/) oder JWT-Dokumentation (https://flask-jwt-extended.readthedocs.io/).
- **Effiziente Entwicklung**: Verwende separate JWT- und Flask-Login-Geheimnisse, Paginierung für große Datenmengen und Indizes für schnelle Abfragen.
- **Kombiniere Tools**: Integriere Redis für Token-Caching oder Flask-SQLAlchemy für einfachere Datenbankzugriffe.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Hinzufügen von Filtern oder einer API zum Löschen von Aufgaben.

## Fazit
Mit diesen Übungen hast du fortgeschrittene Flask-Features wie JWT-Authentifizierung und Pagination gemeistert, kombiniert mit SQLite für eine sichere und skalierbare To-Do-Liste-API. Die Spielerei zeigt, wie du paginierte Aufgaben als Markdown exportierst. Vertiefe dein Wissen, indem du weitere Features (z. B. Refresh-Tokens, API-Filter) oder andere Datenbanken (z. B. Redis, MongoDB) einbindest. Wenn du ein spezifisches Thema (z. B. API-Skalierung oder Refresh-Tokens) vertiefen möchtest, lass es mich wissen!
