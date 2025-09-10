# Praxisorientierte Anleitung: Einfache Webanwendung mit Flask und Redis für Anfänger

## Einführung
Flask ist ein leichtgewichtiges Python-Webframework, das ideal für einfache Webanwendungen ist. In Kombination mit Redis, einer schnellen In-Memory-Datenbank, kannst du Daten wie Aufgaben in einer To-Do-Liste effizient speichern, suchen und anzeigen. Diese Anleitung führt Anfänger in die Entwicklung einer Webanwendung ein, mit Fokus auf **Einrichten einer Flask-Anwendung**, **Verbindung mit Redis** und **Erstellen von Routen für CRUD-Operationen** (Create, Read, Update, Delete). Eine **Spielerei** zeigt, wie du die Aufgabenliste als Markdown-Tabelle exportierst, um eine Verbindung zu vorherigen Themen (z. B. Markdown-Ausgabe) herzustellen. Durch praktische Übungen lernst du, eine Webanwendung zu erstellen, die Daten in Redis verwaltet.

**Voraussetzungen**:
- Ein System mit Windows, macOS oder Linux (z. B. Windows 11, Ubuntu 22.04, macOS Ventura).
- Ein Terminal (PowerShell für Windows, Terminal für macOS/Linux).
- Python 3 installiert (prüfe mit `python3 --version`; installiere via `choco install python` auf Windows, `sudo apt install python3` auf Ubuntu oder `brew install python3` auf macOS).
- Flask und Redis-Bibliothek installiert (`pip install flask redis`).
- Redis installiert (z. B. `sudo apt install redis-server` auf Ubuntu, `brew install redis` auf macOS, oder via Docker: `docker run -d -p 6379:6379 redis`).
- Grundkenntnisse in Python (Funktionen, Klassen) und Redis (Schlüssel-Wert-Paare, Listen).
- Sichere Testumgebung (z. B. `$HOME/flask_redis` oder `~/flask_redis`).
- Ein Webbrowser (z. B. Chrome, Firefox).

## Grundlegende Befehle
Hier sind die wichtigsten Konzepte und Befehle für die Webanwendung:

1. **Einrichten einer Flask-Anwendung**:
   - `from flask import Flask`: Importiert Flask.
   - `app = Flask(__name__)`: Erstellt eine Flask-Anwendung.
   - `@app.route('/')`: Definiert eine Route für die URL.
   - `app.run()`: Startet den Flask-Entwicklungsserver.
2. **Verbindung mit Redis**:
   - `redis.Redis(host='localhost', port=6379)`: Verbindet mit einem Redis-Server.
   - `decode_responses=True`: Stellt sicher, dass Antworten als Strings dekodiert werden.
   - `set(key, value)`: Speichert einen Wert unter einem Schlüssel.
   - `lpush(list_key, value)`: Fügt einen Wert zu einer Liste hinzu.
   - `lrange(list_key, start, end)`: Ruft Werte aus einer Liste ab.
3. **Erstellen von Routen für CRUD-Operationen**:
   - `render_template()`: Rendert HTML-Vorlagen.
   - `request.form`: Verarbeitet Formulardaten.
   - `redirect()`: Leitet zu einer anderen Route um.
4. **Nützliche Zusatzbefehle**:
   - `python3 app.py`: Führt die Flask-Anwendung aus.
   - `redis-cli`: Öffnet die Redis-CLI zum Überprüfen der Daten.
   - `help(redis.Redis)`: Zeigt Python-Dokumentation für das `redis`-Modul.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Einrichten einer Flask-Anwendung
**Ziel**: Erstelle eine einfache Flask-Anwendung mit einer Startseite.

1. **Schritt 1**: Erstelle ein Projektverzeichnis:
   ```bash
   mkdir flask_redis
   cd flask_redis
   ```

2. **Schritt 2**: Installiere Flask und die Redis-Bibliothek:
   ```bash
   pip install flask redis
   ```

3. **Schritt 3**: Stelle sicher, dass Redis läuft:
   ```bash
   redis-server &  # Starte Redis im Hintergrund
   redis-cli ping  # Prüfe mit "PONG"
   ```

4. **Schritt 4**: Erstelle eine HTML-Vorlage für die Startseite:
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
               <td>{{ task.id }}</td>
               <td>{{ task.task }}</td>
               <td>{{ 'Erledigt' if task.completed else 'Offen' }}</td>
               <td>
                   <form method="POST" action="/complete/{{ task.id }}">
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
       <p><a href="/export">Aufgaben als Markdown exportieren</a></p>
   </body>
   </html>
   ```
   Speichere und schließe.

5. **Schritt 5**: Erstelle ein Flask-Skript für die Startseite:
   ```bash
   nano app.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from flask import Flask, render_template, request, redirect, url_for
   import redis
   import json
   import uuid

   app = Flask(__name__)

   def get_redis():
       """Verbindet mit Redis."""
       return redis.Redis(host='localhost', port=6379, decode_responses=True)

   def init_redis():
       """Initialisiert Redis mit einem Zähler für Aufgaben-IDs."""
       r = get_redis()
       if not r.exists("task_id_counter"):
           r.set("task_id_counter", 0)

   def get_tasks(query=None):
       """Ruft alle Aufgaben aus Redis ab, optional mit Suchfilter."""
       r = get_redis()
       task_ids = r.lrange("tasks_list", 0, -1)
       tasks = []
       for task_id in task_ids:
           task_data = r.get(f"task:{task_id}")
           if task_data:
               task = json.loads(task_data)
               if not query or query.lower() in task["task"].lower():
                   tasks.append({"id": task["id"], "task": task["task"], "completed": task["completed"]})
       return tasks

   def add_task(task):
       """Fügt eine neue Aufgabe hinzu."""
       r = get_redis()
       task_id = r.incr("task_id_counter")
       task_data = json.dumps({"id": task_id, "task": task, "completed": False})
       r.set(f"task:{task_id}", task_data)
       r.lpush("tasks_list", task_id)
       r.expire(f"task:{task_id}", 3600)  # Ablaufzeit von 1 Stunde
       r.expire("tasks_list", 3600)

   @app.route('/')
   def index():
       """Rendert die Startseite mit Aufgaben."""
       init_redis()  # Stelle sicher, dass der Zähler existiert
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

6. **Schritt 6**: Führe die Anwendung aus:
   ```bash
   python3 app.py
   ```
   Öffne einen Browser und gehe zu `http://localhost:5000`. Du solltest eine einfache Seite mit einem Formular und einer leeren Tabelle sehen. Füge eine Aufgabe (z. B. "Einkaufen gehen") hinzu, die in der Tabelle erscheinen sollte.

**Reflexion**: Warum ist Redis für eine schnelle Webanwendung geeignet? Nutze `help(redis.Redis)` und überlege, wie du die Startseite mit CSS verbessern kannst.

### Übung 2: Verbindung mit Redis
**Ziel**: Erweitere die Anwendung, um Aufgaben zu erledigen und zu suchen.

1. **Schritt 1**: Erweitere das Flask-Skript mit Funktionen zum Erledigen und Suchen:
   ```bash
   nano app.py
   ```
   Ersetze den Inhalt durch:
   ```python
   from flask import Flask, render_template, request, redirect, url_for
   import redis
   import json
   import uuid

   app = Flask(__name__)

   def get_redis():
       """Verbindet mit Redis."""
       return redis.Redis(host='localhost', port=6379, decode_responses=True)

   def init_redis():
       """Initialisiert Redis mit einem Zähler für Aufgaben-IDs."""
       r = get_redis()
       if not r.exists("task_id_counter"):
           r.set("task_id_counter", 0)

   def get_tasks(query=None):
       """Ruft alle Aufgaben aus Redis ab, optional mit Suchfilter."""
       r = get_redis()
       task_ids = r.lrange("tasks_list", 0, -1)
       tasks = []
       for task_id in task_ids:
           task_data = r.get(f"task:{task_id}")
           if task_data:
               task = json.loads(task_data)
               if not query or query.lower() in task["task"].lower():
                   tasks.append({"id": task["id"], "task": task["task"], "completed": task["completed"]})
       return tasks

   def add_task(task):
       """Fügt eine neue Aufgabe hinzu."""
       r = get_redis()
       task_id = r.incr("task_id_counter")
       task_data = json.dumps({"id": task_id, "task": task, "completed": False})
       r.set(f"task:{task_id}", task_data)
       r.lpush("tasks_list", task_id)
       r.expire(f"task:{task_id}", 3600)  # Ablaufzeit von 1 Stunde
       r.expire("tasks_list", 3600)

   def complete_task(task_id):
       """Markiert eine Aufgabe als erledigt."""
       r = get_redis()
       task_data = r.get(f"task:{task_id}")
       if task_data:
           task = json.loads(task_data)
           task["completed"] = True
           r.set(f"task:{task_id}", json.dumps(task))
           r.expire(f"task:{task_id}", 3600)

   @app.route('/')
   def index():
       """Rendert die Startseite mit Aufgaben."""
       init_redis()
       tasks = get_tasks()
       return render_template('index.html', tasks=tasks)

   @app.route('/add', methods=['POST'])
   def add():
       """Fügt eine neue Aufgabe hinzu."""
       task = request.form['task']
       add_task(task)
       return redirect(url_for('index'))

   @app.route('/complete/<int:task_id>', methods=['POST'])
   def complete(task_id):
       """Markiert eine Aufgabe als erledigt."""
       complete_task(task_id)
       return redirect(url_for('index'))

   @app.route('/search', methods=['GET'])
   def search():
       """Sucht nach Aufgaben."""
       query = request.args.get('query', '')
       tasks = get_tasks(query)
       return render_template('index.html', tasks=tasks)

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

3. **Schritt 3**: Überprüfe die Daten in Redis:
   ```bash
   redis-cli
   LRANGE tasks_list 0 -1
   GET task:1
   ```

**Reflexion**: Warum ist die Verwendung von JSON in Redis für strukturierte Daten nützlich? Nutze `help(redis.Redis.lrange)` und überlege, wie du Aufgaben dauerhaft speichern kannst (z. B. ohne Ablaufzeit).

### Übung 3: CRUD-Operationen und Spielerei
**Ziel**: Füge eine Funktion zum Exportieren der Aufgabenliste als Markdown hinzu.

1. **Schritt 1**: Erweitere das Skript mit einer Markdown-Exportfunktion:
   ```bash
   nano app.py
   ```
   Ersetze den Inhalt durch:
   ```python
   from flask import Flask, render_template, request, redirect, url_for
   import redis
   import json
   import uuid

   app = Flask(__name__)

   class TodoApp:
       def __init__(self, host='localhost', port=6379):
           self.r = redis.Redis(host=host, port=port, decode_responses=True)
           self.list_key = "tasks_list"
           self.init_redis()

       def init_redis(self):
           """Initialisiert Redis mit einem Zähler für Aufgaben-IDs."""
           if not self.r.exists("task_id_counter"):
               self.r.set("task_id_counter", 0)

       def add_task(self, task):
           """Fügt eine neue Aufgabe hinzu."""
           task_id = self.r.incr("task_id_counter")
           task_data = json.dumps({"id": task_id, "task": task, "completed": False})
           self.r.set(f"task:{task_id}", task_data)
           self.r.lpush(self.list_key, task_id)
           self.r.expire(f"task:{task_id}", 3600)
           self.r.expire(self.list_key, 3600)

       def complete_task(self, task_id):
           """Markiert eine Aufgabe als erledigt."""
           task_data = self.r.get(f"task:{task_id}")
           if task_data:
               task = json.loads(task_data)
               task["completed"] = True
               self.r.set(f"task:{task_id}", json.dumps(task))
               self.r.expire(f"task:{task_id}", 3600)

       def get_tasks(self, query=None):
           """Ruft Aufgaben ab, optional mit Suchfilter."""
           task_ids = self.r.lrange(self.list_key, 0, -1)
           tasks = []
           for task_id in task_ids:
               task_data = self.r.get(f"task:{task_id}")
               if task_data:
                   task = json.loads(task_data)
                   if not query or query.lower() in task["task"].lower():
                       tasks.append(task)
           return tasks

       def to_markdown(self, output_file="tasks.md"):
           """Speichert Aufgaben als Markdown-Tabelle."""
           tasks = self.get_tasks()
           if not tasks:
               return "Keine Aufgaben vorhanden."
           header = "| ID | Aufgabe | Status |\n|---|--------|--------|\n"
           rows = [f"| {task['id']} | {task['task']} | {'Erledigt' if task['completed'] else 'Offen'} |" for task in tasks]
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
   - Markiere Aufgaben als erledigt.
   - Suche nach Aufgaben (z. B. "Einkaufen").
   - Gehe zu `http://localhost:5000/export`, um die Markdown-Tabelle zu sehen.

3. **Spielerei**: Überprüfe die Markdown-Ausgabe:
   ```bash
   cat tasks.md
   ```
   Nach dem Hinzufügen von "Einkaufen gehen" (erledigt) und "Python lernen" (offen) sollte die Datei so aussehen:
   ```
   # To-Do-Liste

   | ID | Aufgabe | Status |
   |---|--------|--------|
   | 2 | Python lernen | Offen |
   | 1 | Einkaufen gehen | Erledigt |
   ```

4. **Schritt 3**: Überprüfe die Daten in Redis:
   ```bash
   redis-cli
   LRANGE tasks_list 0 -1
   GET task:1
   GET task:2
   ```

**Reflexion**: Wie vereinfacht die `TodoApp`-Klasse die Verwaltung von Aufgaben? Nutze `help(redis.Redis)` und überlege, wie du Redis-Hashes statt JSON für strukturierte Daten nutzen kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Flask und Redis zu verinnerlichen.
- **Sicheres Testen**: Nutze Testverzeichnisse und `debug=True` für Flask.
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze `help(redis)` oder die Redis-Dokumentation (https://redis.io/docs/).
- **Effiziente Entwicklung**: Verwende `decode_responses=True` für einfache String-Verarbeitung, Klassen für strukturierte Logik und Ablaufzeiten für temporäre Daten.
- **Kombiniere Tools**: Integriere Redis mit SQLite für persistente Speicherung oder Flask-RESTful für APIs.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Hinzufügen von Prioritäten oder Kategorien für Aufgaben.

## Fazit
Mit diesen Übungen hast du eine einfache Webanwendung mit Flask und Redis erstellt, die Daten speichert, sucht und anzeigt. Die Spielerei zeigt, wie du Aufgaben als Markdown exportierst. Im Vergleich zur SQLite-Version bietet Redis schnellere Zugriffe, ist aber weniger geeignet für persistente Daten. Vertiefe dein Wissen, indem du fortgeschrittene Redis-Features (z. B. Hashes, Pub/Sub) oder Flask-Features (z. B. Blueprints, WTForms) einbindest. Wenn du ein spezifisches Thema (z. B. Redis-Hashes oder API-Integration) vertiefen möchtest, lass es mich wissen!
