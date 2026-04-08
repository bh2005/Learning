# Lernprojekt: Migration von JSON zu SQLite mit Claude

## Einführung

Ab einem bestimmten Punkt stößt eine JSON-Datei als Datenspeicher an ihre Grenzen: gleichzeitige Schreibzugriffe, komplexe Abfragen, Performance bei vielen Einträgen. Eine **SQLite-Datenbank** ist der natürliche nächste Schritt für eine lokale Anwendung – sie ist serverlos, in Python eingebaut und deutlich mächtiger als JSON. Dieses Modul begleitet die Migration von `todos.json` zu einer SQLite-Datenbank mit Claudes Unterstützung – aber mit vollem Verständnis jeder Änderung.

**Voraussetzungen**:
- Modul 3–5 abgeschlossen (todo.py mit Prioritäten, Fälligkeitsdaten, Tests, CI-Pipeline)
- Grundverständnis von SQL (SELECT, INSERT, UPDATE, DELETE)
- Python `sqlite3`-Modul (in Python-Standardbibliothek enthalten, keine Installation nötig)

**Ziele**:
- Verstehen, wann und warum eine Migration von JSON zu SQLite sinnvoll ist.
- Mit Claude eine Datenbankschicht entwerfen und implementieren.
- Eine Migrationsstrategie für bestehende Daten entwickeln.
- Das Repository-Pattern als Abstraktionsschicht kennenlernen.
- Alle bestehenden Tests weiterhin grün halten (Regression vermeiden).

**Vor und nach der Migration**:
```
Vorher:                          Nachher:
todo.py                          todo.py
  → load_todos(filepath)    →      → TodoRepository.get_all()
  → save_todos(filepath)    →      → TodoRepository.add()
  → todos.json              →      → todos.db (SQLite)
```

**Quellen**:
- Python sqlite3 Dokumentation: https://docs.python.org/3/library/sqlite3.html
- SQLite Dokumentation: https://www.sqlite.org/docs.html

---

## Grundlagen: JSON vs. SQLite – Wann wechseln?

### Vergleich

| Kriterium | JSON-Datei | SQLite |
|---|---|---|
| **Setup** | Keine Installation | In Python eingebaut |
| **Abfragen** | Immer alles laden + Python filtern | SQL: `WHERE`, `ORDER BY`, `LIKE` |
| **Performance** | Langsam bei > 1.000 Einträgen | Gut bis Millionen von Einträgen |
| **Gleichzeitiger Zugriff** | Keine Unterstützung | Begrenzt (Lesen parallel, Schreiben seriell) |
| **Transaktionen** | Nicht vorhanden | Vollständig (ACID) |
| **Lesbarkeit** | Direkt mit Texteditor | Braucht SQLite-Browser oder CLI |

### Das Repository-Pattern

Statt `load_todos()` und `save_todos()` direkt aufzurufen, kapselt ein **Repository** alle Datenbankoperationen. Der Rest der App (`cmd_add`, `cmd_list`, etc.) merkt nichts vom Wechsel:

```python
class TodoRepository:
    def __init__(self, db_path: str): ...
    def get_all(self, filter_by=None) -> list[dict]: ...
    def add(self, text, priority, due) -> dict: ...
    def mark_done(self, todo_id: int) -> bool: ...
    def delete(self, todo_id: int) -> bool: ...
```

> ℹ️ **Warum das Pattern?** Wenn morgen statt SQLite eine andere Datenbank genutzt wird, ändert sich nur das Repository – nicht die CLI-Logik.

---

## Übungen zum Verinnerlichen

### Übung 1: Datenbankschema entwerfen und anlegen 🗄️

**Ziel**: Das Datenbankschema mit Claude diskutieren und die Initialisierungslogik implementieren.

1. **Schritt 1**: Schema mit Claude durchdenken:
   ```
   Ich migriere folgende JSON-Struktur zu SQLite:
   {"id": 1, "text": "...", "done": false, "created_at": "2026-04-08",
    "priority": "medium", "due": null}
   
   Schlage mir ein SQLite-CREATE TABLE Statement vor. Berücksichtige:
   - Welcher Python-Typ wird für "done" (bool) gespeichert?
   - Wie speichere ich Datumswerte (TEXT vs. INTEGER)?
   - Soll "id" AUTOINCREMENT haben?
   Erkläre die Vor- und Nachteile der Entscheidungen.
   ```

2. **Schritt 2**: Datei `db.py` anlegen und `TodoRepository.__init__()` implementieren:
   ```python
   import sqlite3

   class TodoRepository:
       def __init__(self, db_path: str = "todos.db"):
           self.db_path = db_path
           self._init_db()

       def _init_db(self):
           # CREATE TABLE IF NOT EXISTS ...
           # Selbst implementieren basierend auf Schritt 1
           pass
   ```

3. **Schritt 3**: In der Python-Shell testen:
   ```python
   from db import TodoRepository
   repo = TodoRepository("test.db")
   # Existiert die Tabelle?
   import sqlite3
   conn = sqlite3.connect("test.db")
   print(conn.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall())
   ```

4. **Schritt 4**: Claude nach möglichen Problemen fragen:
   ```
   Was passiert wenn _init_db() aufgerufen wird aber die Datenbank
   bereits existiert und die Tabelle schon vorhanden ist?
   Wie stelle ich sicher, dass die Funktion idempotent ist?
   ```

**Reflexion**: Warum nutzt man `CREATE TABLE IF NOT EXISTS` statt erst zu prüfen ob die Tabelle existiert?

---

### Übung 2: Repository-Methoden implementieren 🔧

**Ziel**: Alle CRUD-Operationen im Repository implementieren und verstehen.

1. **Schritt 1**: `add()`-Methode – erst verstehen, dann schreiben:
   ```
   Wie füge ich einen neuen Eintrag in SQLite ein und bekomme die
   automatisch vergebene ID zurück? Zeige nur das SQL-Pattern und
   wie cursor.lastrowid funktioniert.
   ```
   Dann selbst implementieren:
   ```python
   def add(self, text: str, priority: str = "medium", due: str | None = None) -> dict:
       with sqlite3.connect(self.db_path) as conn:
           cursor = conn.execute(
               "INSERT INTO todos (text, done, created_at, priority, due) VALUES (?,?,?,?,?)",
               (text, False, ..., priority, due)
           )
           # Eintrag zurückgeben (nicht einfach dict bauen – aus DB lesen!)
           ...
   ```

2. **Schritt 2**: `get_all()` mit optionalem Filter implementieren.
   Claude nach dem SQL-Pattern fragen:
   ```
   Wie baue ich in Python sqlite3 eine SQL-Abfrage mit einem optionalen
   WHERE-Clause auf? Ich möchte nach "done", "priority" oder "overdue"
   filtern können, ohne SQL-Injection-Risiko (kein String-Concatenation).
   ```

3. **Schritt 3**: `mark_done()` und `delete()` selbst implementieren – beide geben `bool` zurück (True = Eintrag gefunden und geändert, False = ID nicht vorhanden). Wie prüfst du das?
   ```python
   # Hinweis: cursor.rowcount gibt an, wie viele Zeilen betroffen waren
   ```

4. **Schritt 4**: Alle Methoden manuell in der Python-Shell testen:
   ```python
   repo = TodoRepository(":memory:")  # In-Memory DB für Tests
   todo = repo.add("Test", priority="high")
   print(repo.get_all())
   repo.mark_done(todo["id"])
   print(repo.get_all())
   repo.delete(todo["id"])
   print(repo.get_all())  # Muss leer sein
   ```

**Reflexion**: Was bedeutet `":memory:"` als Datenbankpfad? Warum ist das für Tests ideal?

---

### Übung 3: todo.py migrieren und alte Daten übertragen 🚚

**Ziel**: `todo.py` auf das Repository umstellen und bestehende JSON-Daten migrieren.

1. **Schritt 1**: `todo.py` refaktorieren – `load_todos`/`save_todos` durch Repository ersetzen.
   Vorher:
   ```python
   def cmd_add(args):
       todos = load_todos("todos.json")
       todos.append(...)
       save_todos("todos.json", todos)
   ```
   Nachher:
   ```python
   def cmd_add(args, repo: TodoRepository):
       repo.add(args.text, args.priority, args.due)
   ```
   Claude kann helfen, die Signatur der `main()`-Funktion anzupassen:
   ```
   Wie übergebe ich das TodoRepository-Objekt an alle cmd_*-Funktionen,
   ohne es als globale Variable zu nutzen? Zeige das Muster für main().
   ```

2. **Schritt 2**: Migrationsskript für bestehende Daten erstellen (`migrate.py`):
   ```
   Schreibe ein einmalig auszuführendes Migrationsskript migrate.py, das:
   1. todos.json liest (falls vorhanden)
   2. TodoRepository initialisiert
   3. Alle Einträge aus JSON in die SQLite-DB überträgt
   4. Am Ende meldet: "X Einträge migriert."
   5. Nicht abstürzt wenn todos.json nicht existiert oder leer ist.
   ```
   Das Skript verstehen und selbst anpassen – dann ausführen:
   ```bash
   python migrate.py
   ```

3. **Schritt 3**: Alle bestehenden Tests anpassen.
   Die Tests nutzen noch `tmp_path` mit JSON-Dateien. Jetzt müssen sie `TodoRepository(":memory:")` nutzen:
   ```python
   # Vorher:
   def test_add_creates_todo(tmp_path):
       filepath = str(tmp_path / "todos.json")
       ...

   # Nachher:
   def test_add_creates_todo():
       repo = TodoRepository(":memory:")
       todo = repo.add("Test")
       assert todo["text"] == "Test"
       assert todo["done"] == False
   ```
   Claude kann beim systematischen Umbau helfen:
   ```
   Hier sind meine alten Tests [einfügen]. Hilf mir, sie auf das
   Repository-Pattern umzustellen. Zeige jeden Test einzeln.
   ```

4. **Schritt 4**: Alle Tests ausführen – müssen grün sein:
   ```bash
   pytest test_todo.py -v
   ```

5. **Schritt 5**: End-to-End manuell testen:
   ```bash
   python todo.py add "SQLite funktioniert!" --priority high
   python todo.py list
   python todo.py done 1
   python todo.py list --filter done
   ```

**Abschlussprojekt-Checkliste**:
- [ ] `db.py` mit `TodoRepository` und allen CRUD-Methoden
- [ ] `todo.py` nutzt `TodoRepository` statt `load_todos`/`save_todos`
- [ ] `migrate.py` überträgt JSON-Daten in SQLite
- [ ] `todos.db` wird korrekt angelegt
- [ ] Alle Tests in `test_todo.py` grün
- [ ] `":memory:"`-Datenbank in Tests verwendet
- [ ] CI-Pipeline (Modul 5) läuft weiterhin grün

**Reflexion**: Was wäre der nächste sinnvolle Schritt nach SQLite? Wann würde man eine echte Client-Server-Datenbank (PostgreSQL, MySQL) brauchen?

---

## Vergleich: Vorher / Nachher

```
Vorher (JSON):                    Nachher (SQLite):
─────────────────────────         ─────────────────────────
todos.json          (Daten)       todos.db            (Daten)
todo.py             (Logik)       todo.py             (Logik, schlank)
  load_todos()                    db.py               (Repository)
  save_todos()                      TodoRepository
  filter_todos()                      get_all()
                                      add()
                                      mark_done()
                                      delete()
```

---

## Fazit

Die Migration zu SQLite zeigt ein grundlegendes Entwicklungsprinzip: Abstraktion durch das Repository-Pattern. Die CLI-Logik weiß nicht, ob dahinter JSON, SQLite oder eine Remote-API steckt. Claude war bei dieser Migration besonders nützlich als Erklärer von SQL-Patterns und beim systematischen Umbau der Tests – aber das Verständnis jeder Entscheidung blieb beim Entwickler.

**Ausblick**:
- Das Repository-Pattern auf eine REST-API übertragen (Flask/FastAPI)
- Mehrere Benutzer unterstützen (User-Tabelle, Foreign Keys)
- Alembic für Datenbankmigrationen nutzen (wenn das Schema sich weiterentwickelt)
