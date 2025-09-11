# Praxisorientierte Anleitung: Flask-Webanwendung mit Redis-Hashes, API-Integration und Sidebar

## Einführung
Diese Anleitung erweitert die vorherige To-Do-Listen-Webanwendung (UUID: 2c3a5f4d-0c1e-4f89-8e2b-5c0f3f2d2e12) um eine **Sidebar** in der Benutzeroberfläche, die Navigation und eine Übersicht der Aufgaben oder API-Funktionen bietet. Die Anwendung verwendet **Flask** für das Webframework, **Redis-Hashes** für strukturierte Daten und **Flask-RESTful** für eine REST-API. Die Sidebar enthält Links zu den Hauptfunktionen (Hinzufügen, Suchen, Exportieren) und zeigt eine kompakte Aufgabenübersicht. Die Schwerpunkte sind **Einrichten einer Flask-Anwendung mit Sidebar**, **Verwaltung von Aufgaben mit Redis-Hashes** und **Integration einer REST-API**. Eine **Spielerei** zeigt, wie du Aufgaben als Markdown-Tabelle exportierst, mit einer Sidebar, die die Benutzerfreundlichkeit verbessert. Die Übungen sind für Nutzer mit grundlegenden Flask- und Redis-Kenntnissen geeignet.

**Voraussetzungen**:
- Ein System mit Windows, macOS oder Linux (z. B. Windows 11, Ubuntu 22.04, macOS Ventura).
- Ein Terminal (PowerShell für Windows, Terminal für macOS/Linux).
- Python 3 installiert (prüfe mit `python3 --version`; installiere via `choco install python` auf Windows, `sudo apt install python3` auf Ubuntu oder `brew install python3` auf macOS).
- Flask, Flask-RESTful und Redis-Bibliothek installiert (`pip install flask flask-restful redis`).
- Redis installiert (z. B. `sudo apt install redis-server` auf Ubuntu, `brew install redis` auf macOS, oder via Docker: `docker run -d -p 6379:6379 redis`).
- Grundkenntnisse in Python (Klassen, Funktionen), Flask (Routen, Vorlagen), Redis (Hashes, Listen) und HTML/CSS.
- Sichere Testumgebung (z. B. `$HOME/flask_redis_sidebar` oder `~/flask_redis_sidebar`).
- Ein Webbrowser (z. B. Chrome, Firefox) und ein API-Testtool (z. B. `curl` oder Postman).

**Hinweis zur Sidebar**: Die Sidebar wird als festes HTML-Element auf der linken Seite der Benutzeroberfläche implementiert, mit CSS für Responsivität und einer Übersicht der letzten Aufgaben. Sie enthält Links zu den Hauptfunktionen und API-Dokumentation.

## Grundlegende Befehle
Hier sind die wichtigsten Konzepte und Befehle für die Webanwendung:

1. **Einrichten einer Flask-Anwendung mit Sidebar**:
   - `from flask import Flask, render_template`: Importiert Flask und Vorlagen-Rendering.
   - `app = Flask(__name__)`: Erstellt eine Flask-Anwendung.
   - `@app.route('/')`: Definiert Routen für die Webanwendung.
   - CSS (`position: fixed`, `width`): Stylt die Sidebar.
2. **Verwaltung von Aufgaben mit Redis-Hashes**:
   - `redis.Redis(host='localhost', port=6379, decode_responses=True)`: Verbindet mit Redis.
   - `hset(key, field, value)`: Speichert Daten in einem Hash.
   - `hgetall(key)`: Ruft alle Felder eines Hashs ab.
   - `lpush(list_key, value)`: Fügt Task-IDs zu einer Liste hinzu.
3. **Integration einer REST-API**:
   - `from flask_restful import Api, Resource`: Importiert API-Tools.
   - `api.add_resource()`: Fügt API-Ressourcen hinzu (z. B. für GET/POST).
   - `reqparse.RequestParser()`: Validiert API-Eingaben.
4. **Nützliche Zusatzbefehle**:
   - `python3 app.py`: Führt die Flask-Anwendung aus.
   - `redis-cli`: Öffnet die Redis-CLI zum Überprüfen von Hashes.
   - `curl http://localhost:5000/api/tasks`: Testet die API.
   - `help(redis.Redis.hset)`: Zeigt Dokumentation für Hash-Befehle.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Einrichten einer Flask-Anwendung mit Sidebar
**Ziel**: Erstelle eine Flask-Anwendung mit einer Sidebar für Navigation und Aufgabenübersicht.

1. **Schritt 1**: Erstelle ein Projektverzeichnis:
   ```bash
   mkdir flask_redis_sidebar
   cd flask_redis_sidebar
   mkdir templates
   ```

2. **Schritt 2**: Installiere die erforderlichen Bibliotheken:
   ```bash
   pip install flask flask-restful redis
   ```

3. **Schritt 3**: Stelle sicher, dass Redis läuft:
   ```bash
   redis-server &  # Starte Redis im Hintergrund
   redis-cli ping  # Prüfe mit "PONG"
   ```

4. **Schritt 4**: Erstelle eine HTML-Vorlage mit Sidebar:
   ```bash
   nano templates/base.html
   ```
   Füge folgenden Inhalt ein:
   ```html
   <!DOCTYPE html>
   <html>
   <head>
       <title>To-Do-Liste</title>
       <style>
           body { font-family: Arial, sans-serif; margin: 0; padding: 0; display: flex; }
           .sidebar {
               width: 250px;
               position: fixed;
               top: 0;
               left: 0;
               height: 100%;
               background-color: #f2f2f2;
               padding: 20px;
               border-right: 1px solid #ddd;
           }
           .sidebar h2 { font-size: 1.2em; }
           .sidebar ul { list-style: none; padding: 0; }
           .sidebar li { margin: 10px 0; }
           .sidebar a { text-decoration: none; color: #333; }
           .sidebar a:hover { color: #007bff; }
           .content { margin-left: 270px; padding: 20px; width: 100%; }
           table { border-collapse: collapse; width: 100%; }
           th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
           th { background-color: #f2f2f2; }
           form { margin-bottom: 20px; }
           @media (max-width: 768px) {
               .sidebar { width: 200px; }
               .content { margin-left: 220px; }
           }
       </style>
   </head>
   <body>
       <div class="sidebar">
           <h2>To-Do Navigation</h2>
           <ul>
               <li><a href="{{ url_for('index') }}">Startseite</a></li>
               <li><a href="{{ url_for('export') }}">Exportieren</a></li>
               <li><a href="#api-docs">API-Dokumentation</a></li>
           </ul>
           <h2>Letzte Aufgaben</h2>
           <ul>
               {% for task in recent_tasks %}
               <li>{{ task.task }} ({{ 'Erledigt' if task.completed == 'True' else 'Offen' }})</li>
               {% endfor %}
           </ul>
       </div>
       <div class="content">
           {% block content %}{% endblock %}
       </div>
   </body>
   </html>
   ```
   Speichere und schließe.

   ```bash
   nano templates/index.html
   ```
   Füge folgenden Inhalt ein:
   ```html
   {% extends "base.html" %}
   {% block content %}
       <h1>To-Do-Liste</h1>
       <form method="POST" action="{{ url_for('add') }}">
           <input type="text" name="task" placeholder="Neue Aufgabe" required>
           <input type="number" name="priority" placeholder="Priorität (1-5)" min="1" max="5" required>
           <input type="submit" value="Hinzufügen">
       </form>
       <h2>Aufgaben</h2>
       <table>
           <tr>
               <th>ID</th>
               <th>Aufgabe</th>
               <th>Priorität</th>
               <th>Status</th>
               <th>Aktion</th>
           </tr>
           {% for task in tasks %}
           <tr>
               <td>{{ task.id }}</td>
               <td>{{ task.task }}</td>
               <td>{{ task.priority }}</td>
               <td>{{ 'Erledigt' if task.completed == 'True' else 'Offen' }}</td>
               <td>
                   <form method="POST" action="{{ url_for('complete', task_id=task.id) }}">
                       <input type="submit" value="Erledigen">
                   </form>
               </td>
           </tr>
           {% endfor %}
       </table>
       <h2>Aufgaben suchen</h2>
       <form method="GET" action="{{ url_for('search') }}">
           <input type="text" name="query" placeholder="Aufgabe suchen">
           <input type="submit" value="Suchen">
       </form>
   {% endblock %}
   ```
   Speichere und schließe.

5. **Schritt 5**: Erstelle das Flask-Skript mit Redis-Hashes und API:
   ```bash
   nano app.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from flask import Flask, render_template, request, redirect, url_for
   from flask_restful import Api, Resource, reqparse
   import redis
   import json

   app = Flask(__name__)
   api = Api(app)

   class TodoApp:
       def __init__(self, host='localhost', port=6379):
           self.r = redis.Redis(host=host, port=port, decode_responses=True)
           self.list_key = "tasks_list"
           self.init_redis()

       def init_redis(self):
           """Initialisiert Redis mit einem Zähler für Aufgaben-IDs."""
           if not self.r.exists("task_id_counter"):
               self.r.set("task_id_counter", 0)

       def add_task(self, task, priority):
           """Fügt eine Aufgabe hinzu (atomar)."""
           pipe = self.r.pipeline()
           task_id = pipe.incr("task_id_counter")
           pipe.hmset(f"task:{task_id.execute()[0]}", {
               "task": task,
               "priority": priority,
               "completed": False
           })
           pipe.lpush(self.list_key, task_id.execute()[0])
           pipe.expire(f"task:{task_id.execute()[0]}", 3600)
           pipe.expire(self.list_key, 3600)
           pipe.execute()

       def complete_task(self, task_id):
           """Markiert eine Aufgabe als erledigt."""
           pipe = self.r.pipeline()
           pipe.hset(f"task:{task_id}", "completed", True)
           pipe.expire(f"task:{task_id}", 3600)
           pipe.execute()

       def get_tasks(self, query=None):
           """Ruft Aufgaben ab, optional mit Suchfilter."""
           task_ids = self.r.lrange(self.list_key, 0, -1)
           pipe = self.r.pipeline()
           for task_id in task_ids:
               pipe.hgetall(f"task:{task_id}")
           tasks = pipe.execute()
           filtered_tasks = [
               {"id": task_ids[i], **tasks[i]}
               for i in range(len(tasks)) if tasks[i] and (not query or query.lower() in tasks[i]["task"].lower())
           ]
           return filtered_tasks

       def get_recent_tasks(self, limit=3):
           """Ruft die letzten 'limit' Aufgaben ab."""
           task_ids = self.r.lrange(self.list_key, 0, limit - 1)
           pipe = self.r.pipeline()
           for task_id in task_ids:
               pipe.hgetall(f"task:{task_id}")
           tasks = pipe.execute()
           return [{"id": task_ids[i], **tasks[i]} for i in range(len(tasks)) if tasks[i]]

       def to_markdown(self, output_file="tasks.md"):
           """Speichert Aufgaben als Markdown-Tabelle."""
           tasks = self.get_tasks()
           if not tasks:
               return "Keine Aufgaben vorhanden."
           header = "| ID | Aufgabe | Priorität | Status |\n|---|--------|-----------|--------|\n"
           rows = [
               f"| {task['id']} | {task['task']} | {task['priority']} | {'Erledigt' if task['completed'] == 'True' else 'Offen'} |"
               for task in tasks
           ]
           markdown = header + "\n".join(rows)
           with open(output_file, 'w') as f:
               f.write("# To-Do-Liste\n\n" + markdown)
           return markdown

   todo = TodoApp()

   @app.route('/')
   def index():
       """Rendert die Startseite mit Aufgaben."""
       tasks = todo.get_tasks()
       recent_tasks = todo.get_recent_tasks()
       return render_template('index.html', tasks=tasks, recent_tasks=recent_tasks)

   @app.route('/add', methods=['POST'])
   def add():
       """Fügt eine neue Aufgabe hinzu."""
       task = request.form['task']
       priority = int(request.form['priority'])
       todo.add_task(task, priority)
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
       recent_tasks = todo.get_recent_tasks()
       return render_template('index.html', tasks=tasks, recent_tasks=recent_tasks)

   @app.route('/export', methods=['GET'])
   def export():
       """Exportiert Aufgaben als Markdown."""
       markdown = todo.to_markdown()
       recent_tasks = todo.get_recent_tasks()
       return render_template('index.html', tasks=todo.get_tasks(), recent_tasks=recent_tasks, markdown=markdown)

   class TaskAPI(Resource):
       def get(self):
           parser = reqparse.RequestParser()
           parser.add_argument('query', type=str, default='')
           args = parser.parse_args()
           tasks = todo.get_tasks(args['query'])
           return [{"id": task["id"], "task": task["task"], "priority": int(task["priority"]), "completed": task["completed"] == 'True'} for task in tasks]

       def post(self):
           parser = reqparse.RequestParser()
           parser.add_argument('task', type=str, required=True, help="Task cannot be blank")
           parser.add_argument('priority', type=int, required=True, help="Priority must be provided")
           args = parser.parse_args()
           todo.add_task(args['task'], args['priority'])
           return {"message": "Task added", "task": args['task'], "priority": args['priority']}, 201

   api.add_resource(TaskAPI, '/api/tasks')

   if __name__ == '__main__':
       app.run(debug=True)
   ```
   Speichere und schließe.

6. **Schritt 6**: Führe die Anwendung aus:
   ```bash
   python3 app.py
   ```
   Gehe zu `http://localhost:5000`:
   - Die Sidebar sollte links sichtbar sein mit Links zu "Startseite", "Exportieren" und "API-Dokumentation" sowie den letzten drei Aufgaben.
   - Füge Aufgaben hinzu (z. B. "Einkaufen gehen", Priorität 2).
   - Markiere Aufgaben als erledigt.
   - Suche nach Aufgaben (z. B. "Einkaufen").
   - Gehe zu `http://localhost:5000/export`, um die Markdown-Tabelle zu sehen.

7. **Schritt 7**: Teste die API:
   - Füge eine Aufgabe hinzu:
     ```bash
     curl -X POST -H "Content-Type: application/json" -d '{"task":"API-Test", "priority":3}' http://localhost:5000/api/tasks
     ```
   - Hole Aufgaben ab:
     ```bash
     curl http://localhost:5000/api/tasks
     ```

**Reflexion**: Wie verbessert die Sidebar die Benutzerfreundlichkeit? Nutze `help(flask.render_template)` und überlege, wie du die Sidebar mit JavaScript für dynamische Updates erweitern kannst.

### Übung 2: Verwaltung von Aufgaben mit Redis-Hashes
**Ziel**: Nutze Redis-Hashes für strukturierte Aufgaben mit Prioritäten.

1. **Schritt 1**: Die Verwaltung von Aufgaben ist bereits in der `TodoApp`-Klasse in `app.py` implementiert, mit Hashes für `task`, `priority` und `completed`.

2. **Schritt 2**: Überprüfe die Daten in Redis:
   ```bash
   redis-cli
   LRANGE tasks_list 0 -1
   HGETALL task:1
   ```
   Nach dem Hinzufügen von "Einkaufen gehen" (Priorität 2, erledigt) sollte die Ausgabe so aussehen:
   ```
   1) "1"
   1) "task"      2) "Einkaufen gehen"
   3) "priority"  4) "2"
   5) "completed" 6) "True"
   ```

**Reflexion**: Warum sind Redis-Hashes für strukturierte Daten wie Aufgaben geeignet? Nutze `help(redis.Redis.hgetall)` und überlege, wie du atomare Operationen mit `pipeline()` weiter optimieren kannst.

### Übung 3: API-Integration und Spielerei
**Ziel**: Integriere die REST-API und exportiere Aufgaben als Markdown.

1. **Schritt 1**: Die API ist bereits in `app.py` unter `/api/tasks` implementiert.

2. **Schritt 2**: Teste die Anwendung:
   - Füge mehrere Aufgaben hinzu (z. B. "Einkaufen gehen", Priorität 2; "Python lernen", Priorität 1).
   - Überprüfe die Sidebar, die die letzten drei Aufgaben anzeigt.
   - Gehe zu `http://localhost:5000/export`, um die Markdown-Tabelle zu sehen.
   - Überprüfe die generierte Datei:
     ```bash
     cat tasks.md
     ```
     Die Datei sollte so aussehen:
     ```
     # To-Do-Liste

     | ID | Aufgabe | Priorität | Status |
     |---|--------|-----------|--------|
     | 2 | Python lernen | 1 | Offen |
     | 1 | Einkaufen gehen | 2 | Erledigt |
     ```

3. **Schritt 3**: Teste die API erneut:
   - Hole Aufgaben mit Suche:
     ```bash
     curl http://localhost:5000/api/tasks?query=Einkaufen
     ```

**Reflexion**: Wie erleichtert die API die Interaktion mit der Anwendung? Nutze `help(flask_restful)` und überlege, wie du die API mit JWT-Authentifizierung sichern kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Sidebar-Design, Redis-Hashes und API-Integration zu verinnerlichen.
- **Sicheres Testen**: Nutze `debug=True` für Flask und Testverzeichnisse.
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze die Flask-Dokumentation (https://flask.palletsprojects.com/) oder Redis-Dokumentation (https://redis.io/docs/).
- **Effiziente Entwicklung**: Verwende Hashes für strukturierte Daten, Pipelines für atomare Operationen und CSS für responsive Sidebars.
- **Kombiniere Tools**: Integriere Redis mit SQLite für Persistenz oder Flask-Login für Authentifizierung.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Hinzufügen von Kategorien oder dynamischen Sidebar-Updates mit JavaScript.

## Fazit
Mit diesen Übungen hast du eine Flask-Webanwendung mit einer Sidebar, Redis-Hashes und API-Integration erstellt. Die Sidebar verbessert die Navigation und zeigt eine Aufgabenübersicht, während die API den Datenzugriff ermöglicht. Die Spielerei zeigt, wie du Aufgaben als Markdown exportierst. Vertiefe dein Wissen, indem du fortgeschrittene Features (z. B. JWT-Authentifizierung, Pagination) oder andere Redis-Datenstrukturen (z. B. Sorted Sets) einbindest. Wenn du ein spezifisches Thema (z. B. dynamische Sidebar-Updates oder API-Sicherheit) vertiefen möchtest, lass es mich wissen!
