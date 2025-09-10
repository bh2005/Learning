# Praxisorientierte Anleitung: Einstieg in Redis mit Python für Anfänger

## Einführung
Redis ist eine schnelle, In-Memory-Schlüssel-Wert-Datenbank, die für Caching, Sitzungsverwaltung oder Echtzeit-Anwendungen ideal ist. Diese Anleitung führt Anfänger in die Nutzung von Redis mit Python ein und konzentriert sich auf **Einrichten und Verbinden mit Redis**, **Speichern und Abrufen von Schlüssel-Wert-Daten** sowie **Grundlegende Redis-Datenstrukturen (Strings, Lists, Hashes)**. Eine **Spielerei** zeigt, wie du eine Klasse erstellst, die eine Cache-Schicht für eine To-Do-Liste implementiert und die Ergebnisse als Markdown-Tabelle ausgibt, um eine Verbindung zu vorherigen Themen (z. B. Markdown-Ausgabe) herzustellen. Durch praktische Übungen lernst du, Redis zu installieren, Daten zu speichern und effizient abzufragen.

**Voraussetzungen**:
- Ein System mit Windows, macOS oder Linux (z. B. Windows 11, Ubuntu 22.04, macOS Ventura).
- Ein Terminal (PowerShell für Windows, Terminal für macOS/Linux).
- Python 3 installiert (prüfe mit `python3 --version`; installiere via `choco install python` auf Windows, `sudo apt install python3` auf Ubuntu oder `brew install python3` auf macOS).
- Redis installiert (z. B. `sudo apt install redis-server` auf Ubuntu, `brew install redis` auf macOS, oder via Docker: `docker run -d -p 6379:6379 redis`).
- Python-Bibliothek `redis` installiert (`pip install redis`).
- Grundkenntnisse in Python (Variablen, Funktionen).
- Sichere Testumgebung (z. B. `$HOME/redis_test` oder `~/redis_test`).

## Grundlegende Befehle
Hier sind die wichtigsten Konzepte und Befehle für Redis in Python:

1. **Einrichten und Verbinden mit Redis**:
   - `redis.Redis(host='localhost', port=6379)`: Verbindet mit einem Redis-Server.
   - `decode_responses=True`: Stellt sicher, dass Antworten als Strings dekodiert werden.
   - `ping()`: Prüft die Verbindung zum Redis-Server.
2. **Speichern und Abrufen von Schlüssel-Wert-Daten**:
   - `set(key, value)`: Speichert einen Wert unter einem Schlüssel.
   - `get(key)`: Ruft den Wert eines Schlüssels ab.
   - `expire(key, seconds)`: Setzt eine Ablaufzeit für einen Schlüssel.
3. **Grundlegende Redis-Datenstrukturen**:
   - **Strings**: Einfache Schlüssel-Wert-Paare (z. B. `set('user', 'Anna')`).
   - **Lists**: Listen von Werten (z. B. `lpush('tasks', 'Einkaufen')`).
   - **Hashes**: Schlüssel-Wert-Dictionaries (z. B. `hset('user:1', mapping={'name': 'Anna', 'age': 25})`).
4. **Nützliche Zusatzbefehle**:
   - `python3 script.py`: Führt ein Python-Skript aus.
   - `redis-cli`: Öffnet die Redis-CLI zum Überprüfen der Daten.
   - `help(redis.Redis)`: Zeigt Python-Dokumentation für das `redis`-Modul.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Einrichten und Verbinden mit Redis
**Ziel**: Stelle eine Verbindung zu Redis her und speichere einfache Schlüssel-Wert-Daten.

1. **Schritt 1**: Erstelle ein Projektverzeichnis:
   ```bash
   mkdir redis_test
   cd redis_test
   ```

2. **Schritt 2**: Stelle sicher, dass Redis läuft:
   ```bash
   redis-server &  # Starte Redis im Hintergrund
   redis-cli ping  # Prüfe mit "PONG"
   ```

3. **Schritt 3**: Installiere die `redis`-Bibliothek:
   ```bash
   pip install redis
   ```

4. **Schritt 4**: Erstelle ein Skript zum Verbinden und Speichern:
   ```bash
   nano redis_connect.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import redis

   def connect_and_store():
       """Verbindet mit Redis und speichert einfache Daten."""
       r = redis.Redis(host='localhost', port=6379, decode_responses=True)
       # Prüfe Verbindung
       if r.ping():
           print("Verbindung zu Redis erfolgreich!")
       # Speichere Daten
       r.set("site:name", "Meine App")
       r.set("site:version", "1.0")
       # Setze Ablaufzeit von 60 Sekunden
       r.expire("site:version", 60)
       # Rufe Daten ab
       name = r.get("site:name")
       version = r.get("site:version")
       print(f"Name: {name}, Version: {version}")
       return r

   if __name__ == "__main__":
       connect_and_store()
   ```
   Speichere und schließe.

5. **Schritt 5**: Führe das Skript aus:
   ```bash
   python3 redis_connect.py
   ```
   Die Ausgabe sollte so aussehen:
   ```
   Verbindung zu Redis erfolgreich!
   Name: Meine App, Version: 1.0
   ```

6. **Schritt 6**: Überprüfe die Daten mit `redis-cli`:
   ```bash
   redis-cli
   KEYS site:*
   GET site:name
   ```
   Die Ausgabe sollte `site:name`, `site:version` und deren Werte anzeigen.

**Reflexion**: Warum ist Redis für schnelle Datenzugriffe geeignet? Nutze `help(redis.Redis)` und überlege, wie du mehrere Schlüssel gleichzeitig abrufen kannst (`mget`).

### Übung 2: Speichern und Abrufen von Schlüssel-Wert-Daten
**Ziel**: Speichere Benutzerdaten in Redis und frage sie mit Filtern ab.

1. **Schritt 1**: Erstelle ein Skript zum Speichern und Abrufen von Benutzerdaten:
   ```bash
   nano redis_users.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import redis
   import json

   def add_user(r, name, age, email):
       """Speichert Benutzerdaten als JSON in Redis."""
       user_data = json.dumps({"name": name, "age": age, "email": email})
       r.set(f"user:{name}", user_data)
       # Setze Ablaufzeit von 300 Sekunden
       r.expire(f"user:{name}", 300)

   def get_user(r, name):
       """Ruft Benutzerdaten aus Redis ab."""
       user_data = r.get(f"user:{name}")
       return json.loads(user_data) if user_data else None

   def get_adults(r, min_age=18):
       """Ruft Benutzer ab, die volljährig sind."""
       adults = []
       for key in r.keys("user:*"):
           user = json.loads(r.get(key))
           if user["age"] >= min_age:
               adults.append(user)
       return adults

   if __name__ == "__main__":
       r = redis.Redis(host='localhost', port=6379, decode_responses=True)
       add_user(r, "Anna", 25, "anna@example.com")
       add_user(r, "Ben", 17, "ben@example.com")
       add_user(r, "Clara", 30, "clara@example.com")
       adults = get_adults(r)
       print("Volljährige Benutzer:")
       for user in adults:
           print(f"Name: {user['name']}, Alter: {user['age']}, E-Mail: {user['email']}")
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   python3 redis_users.py
   ```
   Die Ausgabe sollte so aussehen:
   ```
   Volljährige Benutzer:
   Name: Anna, Alter: 25, E-Mail: anna@example.com
   Name: Clara, Alter: 30, E-Mail: clara@example.com
   ```

3. **Schritt 3**: Überprüfe die Daten mit `redis-cli`:
   ```bash
   redis-cli
   KEYS user:*
   GET user:Anna
   ```

**Reflexion**: Warum ist JSON für die Speicherung komplexer Daten in Redis nützlich? Nutze `help(redis.Redis.keys)` und überlege, wie du Muster für `keys` optimieren kannst.

### Übung 3: Grundlegende Redis-Datenstrukturen und Spielerei
**Ziel**: Nutze Redis-Listen und Hashes, um eine To-Do-Liste zu verwalten, und erstelle eine Klasse, die Aufgaben cached und als Markdown-Tabelle ausgibt.

1. **Schritt 1**: Erstelle ein Skript für eine To-Do-Liste mit Redis:
   ```bash
   nano redis_todo.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import redis
   import json

   class TodoCache:
       def __init__(self, host='localhost', port=6379):
           self.r = redis.Redis(host=host, port=port, decode_responses=True)
           self.list_key = "todo_list"

       def add_task(self, task, priority=1):
           """Fügt eine Aufgabe als Hash und in eine Liste hinzu."""
           task_id = self.r.incr("task_id_counter")
           task_data = json.dumps({"id": task_id, "task": task, "priority": priority, "completed": False})
           self.r.hset("tasks", f"task:{task_id}", task_data)  # Speichere als Hash
           self.r.lpush(self.list_key, task_id)  # Füge ID zur Liste hinzu
           self.r.expire(f"tasks", 3600)  # Ablaufzeit für Hash (1 Stunde)
           self.r.expire(self.list_key, 3600)  # Ablaufzeit für Liste

       def complete_task(self, task_id):
           """Markiert eine Aufgabe als erledigt."""
           task_data = self.r.hget("tasks", f"task:{task_id}")
           if task_data:
               task = json.loads(task_data)
               task["completed"] = True
               self.r.hset("tasks", f"task:{task_id}", json.dumps(task))

       def get_tasks(self, only_pending=True):
           """Ruft Aufgaben ab (optional nur offene)."""
           task_ids = self.r.lrange(self.list_key, 0, -1)
           tasks = []
           for task_id in task_ids:
               task_data = self.r.hget("tasks", f"task:{task_id}")
               if task_data:
                   task = json.loads(task_data)
                   if not only_pending or not task["completed"]:
                       tasks.append(task)
           return tasks

       def to_markdown(self, output_file="todo.md"):
           """Speichert Aufgaben als Markdown-Tabelle."""
           tasks = self.get_tasks(only_pending=False)
           if not tasks:
               return "Keine Aufgaben vorhanden."
           header = "| ID | Aufgabe | Priorität | Status |\n|---|--------|-----------|--------|\n"
           rows = [f"| {task['id']} | {task['task']} | {task['priority']} | {'Erledigt' if task['completed'] else 'Offen'} |" 
                   for task in tasks]
           markdown = header + "\n".join(rows)
           with open(output_file, 'w') as f:
               f.write("# To-Do-Liste\n\n" + markdown)
           return markdown

   if __name__ == "__main__":
       todo = TodoCache()
       todo.add_task("Einkaufen gehen", 2)
       todo.add_task("Python lernen", 1)
       todo.complete_task(1)
       print("Alle Aufgaben:")
       for task in todo.get_tasks(only_pending=False):
           status = "Erledigt" if task["completed"] else "Offen"
           print(f"ID: {task['id']}, Aufgabe: {task['task']}, Priorität: {task['priority']}, Status: {status}")
       print("\nMarkdown-Tabelle:")
       print(todo.to_markdown())
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   python3 redis_todo.py
   ```
   Die Ausgabe sollte so aussehen:
   ```
   Alle Aufgaben:
   ID: 2, Aufgabe: Python lernen, Priorität: 1, Status: Offen
   ID: 1, Aufgabe: Einkaufen gehen, Priorität: 2, Status: Erledigt

   Markdown-Tabelle:
   | ID | Aufgabe | Priorität | Status |
   |---|--------|-----------|--------|
   | 2 | Python lernen | 1 | Offen |
   | 1 | Einkaufen gehen | 2 | Erledigt |
   ```

3. **Spielerei**: Überprüfe die Markdown-Ausgabe:
   ```bash
   cat todo.md
   ```
   Die Datei sollte so aussehen:
   ```
   # To-Do-Liste

   | ID | Aufgabe | Priorität | Status |
   |---|--------|-----------|--------|
   | 2 | Python lernen | 1 | Offen |
   | 1 | Einkaufen gehen | 2 | Erledigt |
   ```

4. **Schritt 3**: Überprüfe die Daten mit `redis-cli`:
   ```bash
   redis-cli
   LRANGE todo_list 0 -1
   HGETALL tasks
   ```

**Reflexion**: Wie verbessern Listen und Hashes die Organisation von Daten in Redis? Nutze `help(redis.Redis.hset)` und überlege, wie du Sets oder Sorted Sets für komplexere Datenstrukturen nutzen kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Redis-Grundlagen zu verinnerlichen.
- **Sicheres Testen**: Nutze Testverzeichnisse und stelle sicher, dass Redis läuft.
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze `help(redis)` oder die Redis-Dokumentation (https://redis.io/docs/).
- **Effiziente Entwicklung**: Verwende `decode_responses=True` für einfache String-Verarbeitung, Hashes für strukturierte Daten und Ablaufzeiten für temporäre Daten.
- **Kombiniere Tools**: Integriere Redis mit Flask für Sitzungsverwaltung oder SQLite für persistente Speicherung.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Hinzufügen von Prioritäts-Sortierung mit Sorted Sets.

## Fazit
Mit diesen Übungen hast du die Grundlagen von Redis mit Python gemeistert, einschließlich Verbindung, Schlüssel-Wert-Speicherung und Nutzung von Listen und Hashes. Die Spielerei zeigt, wie du eine To-Do-Liste mit Redis cached und in Markdown ausgibst. Vertiefe dein Wissen, indem du fortgeschrittene Redis-Konzepte (z. B. Pub/Sub, Pipelines) oder Integration mit anderen Tools (z. B. Flask, pandas) ausprobierst. Wenn du ein spezifisches Thema (z. B. Redis-Pipelines oder Cache-Strategien) vertiefen möchtest, lass es mich wissen!
