# Praxisorientierte Anleitung: Einstieg in Datenbanken mit Python (SQLite, Redis, MongoDB)

## Einführung
Datenbanken sind essenziell für die Speicherung und Verwaltung von Daten in Anwendungen. Diese Anleitung führt in **SQLite** (eine relationale Datenbank), **Redis** (eine In-Memory-Schlüssel-Wert-Datenbank) und **MongoDB** (eine dokumentenbasierte NoSQL-Datenbank) ein. Die Schwerpunkte sind **Grundlagen von SQLite für relationale Daten**, **Redis für schnelle Schlüssel-Wert-Speicherung** und **MongoDB für dokumentenbasierte NoSQL-Daten**. Eine **Spielerei** zeigt, wie du eine Klasse erstellst, die Benutzerdaten zwischen SQLite und MongoDB synchronisiert, um eine Verbindung zu vorherigen Themen (z. B. Datenverarbeitung) herzustellen. Durch praktische Übungen lernst du, Datenbanken einzurichten, zu nutzen und zu integrieren.

**Voraussetzungen**:
- Ein System mit Windows, macOS oder Linux (z. B. Windows 11, Ubuntu 22.04, macOS Ventura).
- Ein Terminal (PowerShell für Windows, Terminal für macOS/Linux).
- Python 3 installiert (prüfe mit `python3 --version`; installiere via `choco install python` auf Windows, `sudo apt install python3` auf Ubuntu oder `brew install python3` auf macOS).
- Bibliotheken: `pip install redis pymongo` (SQLite ist in Python integriert).
- Redis installiert (z. B. `sudo apt install redis-server` auf Ubuntu, `brew install redis` auf macOS).
- MongoDB installiert (z. B. via Docker: `docker run -d -p 27017:27017 mongo`, oder lokal: `sudo apt install mongodb` auf Ubuntu).
- Grundkenntnisse in Python (Klassen, Datei-Ein-/Ausgabe).
- Sichere Testumgebung (z. B. `$HOME/db_test` oder `~/db_test`).

## Grundlegende Befehle
Hier sind die wichtigsten Konzepte und Befehle, aufgeteilt nach den Hauptthemen:

1. **Grundlagen von SQLite**:
   - `sqlite3.connect()`: Verbindet mit einer SQLite-Datenbank.
   - `cursor.execute()`: Führt SQL-Befehle aus (z. B. `CREATE TABLE`, `INSERT`).
   - `cursor.fetchall()`: Ruft Abfrageergebnisse ab.
2. **Redis für Schlüssel-Wert-Speicherung**:
   - `redis.Redis()`: Verbindet mit einem Redis-Server.
   - `set(key, value)`: Speichert einen Wert.
   - `get(key)`: Ruft einen Wert ab.
3. **MongoDB für NoSQL-Daten**:
   - `pymongo.MongoClient()`: Verbindet mit einem MongoDB-Server.
   - `db.collection.insert_one()`: Fügt ein Dokument hinzu.
   - `db.collection.find()`: Findet Dokumente in einer Sammlung.
4. **Nützliche Zusatzbefehle**:
   - `python3 script.py`: Führt ein Python-Skript aus.
   - `redis-cli`: Interagiert mit Redis im Terminal.
   - `mongo`: Startet die MongoDB-Shell.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Grundlagen von SQLite
**Ziel**: Erstelle eine SQLite-Datenbank, füge Benutzerdaten hinzu und frage sie ab.

1. **Schritt 1**: Erstelle ein Projektverzeichnis:
   ```bash
   mkdir db_test
   cd db_test
   ```

2. **Schritt 2**: Erstelle ein Skript für SQLite:
   ```bash
   nano sqlite_users.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import sqlite3

   def init_db():
       """Initialisiert die SQLite-Datenbank und erstellt eine Tabelle."""
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

   def add_user(name, age, email):
       """Fügt einen Benutzer hinzu."""
       conn = sqlite3.connect("users.db")
       cursor = conn.cursor()
       cursor.execute("INSERT INTO users (name, age, email) VALUES (?, ?, ?)", (name, age, email))
       conn.commit()
       conn.close()

   def get_users(min_age=0):
       """Ruft Benutzer ab, die älter als min_age sind."""
       conn = sqlite3.connect("users.db")
       cursor = conn.cursor()
       cursor.execute("SELECT name, age, email FROM users WHERE age >= ?", (min_age,))
       users = cursor.fetchall()
       conn.close()
       return users

   if __name__ == "__main__":
       init_db()
       add_user("Anna", 25, "anna@example.com")
       add_user("Ben", 17, "ben@example.com")
       add_user("Clara", 30, "clara@example.com")
       users = get_users(min_age=18)
       print("Volljährige Benutzer:")
       for user in users:
           print(f"Name: {user[0]}, Alter: {user[1]}, E-Mail: {user[2]}")
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   python3 sqlite_users.py
   ```
   Die Ausgabe sollte so aussehen:
   ```
   Volljährige Benutzer:
   Name: Anna, Alter: 25, E-Mail: anna@example.com
   Name: Clara, Alter: 30, E-Mail: clara@example.com
   ```

4. **Schritt 4**: Überprüfe die SQLite-Datenbank:
   ```bash
   sqlite3 users.db "SELECT * FROM users;"
   ```
   Die Ausgabe sollte die eingefügten Benutzer anzeigen.

**Reflexion**: Warum ist SQLite für kleine Anwendungen geeignet? Nutze `help(sqlite3)` und überlege, wie du Indizes für schnellere Abfragen einrichten kannst.

### Übung 2: Redis für schnelle Schlüssel-Wert-Speicherung
**Ziel**: Speichere und rufe Benutzerdaten in Redis ab, z. B. für schnelle Cache-Operationen.

1. **Schritt 1**: Stelle sicher, dass Redis läuft:
   ```bash
   redis-server  # Starte Redis im Hintergrund
   redis-cli ping  # Prüfe mit "PONG"
   ```

2. **Schritt 2**: Erstelle ein Skript für Redis:
   ```bash
   nano redis_users.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import redis
   import json

   def add_user_to_redis(name, age, email, redis_client=None):
       """Speichert Benutzerdaten in Redis."""
       if redis_client is None:
           redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)
       user_data = json.dumps({"name": name, "age": age, "email": email})
       redis_client.set(f"user:{name}", user_data)

   def get_user_from_redis(name, redis_client=None):
       """Ruft Benutzerdaten aus Redis ab."""
       if redis_client is None:
           redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)
       user_data = redis_client.get(f"user:{name}")
       return json.loads(user_data) if user_data else None

   if __name__ == "__main__":
       r = redis.Redis(host='localhost', port=6379, decode_responses=True)
       add_user_to_redis("Anna", 25, "anna@example.com", r)
       add_user_to_redis("Ben", 17, "ben@example.com", r)
       user = get_user_from_redis("Anna", r)
       print("Benutzer aus Redis:", user)
   ```
   Speichere und schließe.

3. **Schritt 3**: Installiere die `redis`-Bibliothek:
   ```bash
   pip install redis
   ```

4. **Schritt 4**: Führe das Skript aus:
   ```bash
   python3 redis_users.py
   ```
   Die Ausgabe sollte so aussehen:
   ```
   Benutzer aus Redis: {'name': 'Anna', 'age': 25, 'email': 'anna@example.com'}
   ```

5. **Schritt 5**: Überprüfe Redis mit `redis-cli`:
   ```bash
   redis-cli
   KEYS user:*
   GET user:Anna
   ```

**Reflexion**: Warum ist Redis für Caching geeignet? Nutze `help(redis.Redis)` und überlege, wie du Ablaufzeiten (`expire`) für Cache-Einträge setzen kannst.

### Übung 3: MongoDB für NoSQL-Daten und Spielerei
**Ziel**: Speichere und frage dokumentenbasierte Daten in MongoDB ab und synchronisiere Daten zwischen SQLite und MongoDB.

1. **Schritt 1**: Stelle sicher, dass MongoDB läuft:
   ```bash
   docker run -d -p 27017:27017 mongo  # Oder lokal: sudo systemctl start mongodb
   ```

2. **Schritt 2**: Installiere `pymongo`:
   ```bash
   pip install pymongo
   ```

3. **Schritt 3**: Erstelle ein Skript für MongoDB und Synchronisation:
   ```bash
   nano mongodb_sync.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import sqlite3
   from pymongo import MongoClient
   import json

   class DatabaseSync:
       def __init__(self, sqlite_db="users.db", mongo_uri="mongodb://localhost:27017", mongo_db="testdb"):
           self.sqlite_conn = sqlite3.connect(sqlite_db)
           self.mongo_client = MongoClient(mongo_uri)
           self.mongo_db = self.mongo_client[mongo_db]
           self.collection = self.mongo_db.users

       def add_to_sqlite(self, name, age, email):
           """Fügt Benutzer zu SQLite hinzu."""
           cursor = self.sqlite_conn.cursor()
           cursor.execute("INSERT INTO users (name, age, email) VALUES (?, ?, ?)", (name, age, email))
           self.sqlite_conn.commit()

       def add_to_mongo(self, name, age, email):
           """Fügt Benutzer zu MongoDB hinzu."""
           user = {"name": name, "age": age, "email": email}
           self.collection.insert_one(user)

       def sync_sqlite_to_mongo(self):
           """Synchronisiert Benutzer von SQLite nach MongoDB."""
           cursor = self.sqlite_conn.cursor()
           cursor.execute("SELECT name, age, email FROM users")
           users = cursor.fetchall()
           for user in users:
               self.collection.update_one(
                   {"name": user[0]},
                   {"$set": {"name": user[0], "age": user[1], "email": user[2]}},
                   upsert=True
               )
           return self.collection.count_documents({})

       def get_mongo_users(self, min_age=0):
           """Ruft Benutzer aus MongoDB ab."""
           return list(self.collection.find({"age": {"$gte": min_age}}))

       def __del__(self):
           """Schließt Verbindungen."""
           self.sqlite_conn.close()
           self.mongo_client.close()

   if __name__ == "__main__":
       # Initialisiere SQLite-Datenbank
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

       # Synchronisiere Daten
       sync = DatabaseSync()
       sync.add_to_sqlite("Anna", 25, "anna@example.com")
       sync.add_to_sqlite("Ben", 17, "ben@example.com")
       count = sync.sync_sqlite_to_mongo()
       print(f"Synchronisierte Benutzer: {count}")
       users = sync.get_mongo_users(min_age=18)
       print("Volljährige Benutzer in MongoDB:")
       for user in users:
           print(f"Name: {user['name']}, Alter: {user['age']}, E-Mail: {user['email']}")
   ```
   Speichere und schließe.

4. **Schritt 4**: Führe das Skript aus:
   ```bash
   python3 mongodb_sync.py
   ```
   Die Ausgabe sollte so aussehen:
   ```
   Synchronisierte Benutzer: 2
   Volljährige Benutzer in MongoDB:
   Name: Anna, Alter: 25, E-Mail: anna@example.com
   ```

5. **Spielerei**: Erweitere die Klasse, um eine Markdown-Zusammenfassung der synchronisierten Daten zu erstellen:
   ```bash
   nano mongodb_sync.py
   ```
   Füge eine neue Methode zur `DatabaseSync`-Klasse hinzu, vor `def __del__(self):`:
   ```python
       def to_markdown(self, output_file="sync_summary.md"):
           """Erstellt eine Markdown-Tabelle der MongoDB-Daten."""
           users = self.get_mongo_users()
           if not users:
               return "Keine Daten vorhanden."
           header = "| Name | Alter | E-Mail |\n|------|-------|-------|\n"
           rows = [f"| {user['name']} | {user['age']} | {user['email']} |" for user in users]
           markdown = header + "\n".join(rows)
           with open(output_file, 'w') as f:
               f.write("# Synchronisierte Benutzer\n\n" + markdown)
           return markdown
   ```
   Ändere den Hauptblock zu:
   ```python
   if __name__ == "__main__":
       # Initialisiere SQLite-Datenbank
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

       # Synchronisiere Daten
       sync = DatabaseSync()
       sync.add_to_sqlite("Anna", 25, "anna@example.com")
       sync.add_to_sqlite("Ben", 17, "ben@example.com")
       count = sync.sync_sqlite_to_mongo()
       print(f"Synchronisierte Benutzer: {count}")
       users = sync.get_mongo_users(min_age=18)
       print("Volljährige Benutzer in MongoDB:")
       for user in users:
           print(f"Name: {user['name']}, Alter: {user['age']}, E-Mail: {user['email']}")
       print("\nMarkdown-Zusammenfassung:")
       print(sync.to_markdown())
   ```
   Speichere und schließe.

6. **Schritt 5**: Führe das Skript erneut aus:
   ```bash
   python3 mongodb_sync.py
   ```
   Die Ausgabe enthält die Markdown-Tabelle, und `sync_summary.md` wird erstellt:
   ```
   Synchronisierte Benutzer: 2
   Volljährige Benutzer in MongoDB:
   Name: Anna, Alter: 25, E-Mail: anna@example.com

   Markdown-Zusammenfassung:
   | Name | Alter | E-Mail |
   |------|-------|-------|
   | Anna | 25 | anna@example.com |
   ```

**Reflexion**: Wie erleichtert die Synchronisation zwischen SQLite und MongoDB die Datenverwaltung? Nutze `help(pymongo.MongoClient)` und überlege, wie du Indizes in MongoDB für schnellere Abfragen einrichten kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um SQLite, Redis und MongoDB zu verinnerlichen.
- **Sicheres Testen**: Nutze Testverzeichnisse und virtuelle Umgebungen (`python3 -m venv venv`).
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze `help()` oder die Dokumentation (z. B. https://www.mongodb.com/docs/, https://redis.io/docs/).
- **Effiziente Entwicklung**: Verwende `with`-Statements für SQLite, Connection-Pooling für Redis und MongoDB, und Klassen für strukturierte Logik.
- **Kombiniere Tools**: Integriere Datenbanken mit Flask für Webanwendungen oder pandas für Analysen.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Synchronisation mit Redis oder Visualisierung der Daten.

## Fazit
Mit diesen Übungen hast du einen Einstieg in SQLite, Redis und MongoDB geschafft und gelernt, wie du relationale, In-Memory- und NoSQL-Datenbanken in Python nutzt. Die Spielerei zeigt, wie du Daten zwischen Datenbanken synchronisierst und in Markdown ausgibst. Vertiefe dein Wissen, indem du fortgeschrittene Datenbankkonzepte (z. B. SQL-Joins, Redis-Pipelines, MongoDB-Aggregationen) oder Integration mit anderen Tools (z. B. Flask, pandas) ausprobierst. Wenn du ein spezifisches Thema (z. B. MongoDB-Aggregationen oder Redis-Caching) vertiefen möchtest, lass es mich wissen!
