# Lernprojekt: Datenbankmigrationen mit Alembic

## Einführung

Jedes Datenbankschema verändert sich im Laufe der Zeit: Eine neue Spalte kommt hinzu, ein Index wird gebraucht, eine Tabelle wird umbenannt. Bisher haben wir das mit `CREATE TABLE IF NOT EXISTS` und manuellen Änderungen gelöst – was bei einem einzelnen Entwickler noch funktioniert, aber im Team oder beim Deployment zu Katastrophen führt. **Alembic** ist das Standard-Migrationswerkzeug für Python und SQLAlchemy: Es versioniert Schemaänderungen wie Git den Code versioniert.

**Voraussetzungen**:
- Modul 8 abgeschlossen (FastAPI-App mit `users`- und `todos`-Tabellen)
- Grundverständnis von Git (Commit-History, Branches)

**Installation**:
```bash
pip install alembic sqlalchemy
```

**Ziele**:
- Verstehen, warum manuelle Schemaänderungen in Teams scheitern.
- Alembic initialisieren und mit dem bestehenden Projekt verbinden.
- Migrationsskripte erstellen, anwenden und rückgängig machen.
- Mit Claude Migrationsskripte generieren und auf Korrektheit prüfen.
- Eine sichere Strategie für Schemaänderungen auf produktiven Systemen kennen.

**Was Alembic kann**:
```
alembic upgrade head        → Alle ausstehenden Migrationen anwenden
alembic downgrade -1        → Letzte Migration rückgängig machen
alembic revision --autogenerate  → Migration aus Modell-Änderung generieren
alembic history             → Alle Migrationen anzeigen
alembic current             → Aktueller Stand der DB
```

**Quellen**:
- Alembic Dokumentation: https://alembic.sqlalchemy.org
- SQLAlchemy Dokumentation: https://docs.sqlalchemy.org

---

## Grundlagen: Warum Migrationen?

### Das Problem ohne Alembic

```
Szenario: 3 Entwickler, eine Produktions-DB

Entwickler A:  ALTER TABLE todos ADD COLUMN tags TEXT  (lokal ausgeführt)
Entwickler B:  Weiß nichts davon, bekommt Fehler beim Deploy
Produktion:    Läuft noch mit altem Schema – App crasht

Mit Alembic:
Entwickler A:  alembic revision --autogenerate -m "add tags column"
               git commit migrations/...
Entwickler B:  git pull && alembic upgrade head  → Schema synchron
Produktion:    alembic upgrade head im Deploy-Script → automatisch aktuell
```

### Alembic vs. manuelles SQL

| Aspekt | Manuell (`ALTER TABLE`) | Alembic |
|---|---|---|
| **Nachvollziehbarkeit** | Nirgends dokumentiert | Versioniert in Git |
| **Rückgängig machen** | Manuell (fehleranfällig) | `alembic downgrade -1` |
| **Team-Synchronisation** | Jeder muss wissen was zu tun ist | `alembic upgrade head` |
| **CI/CD-Integration** | Schwierig | Direkt ins Deploy-Script |

### SQLAlchemy-Modelle als Basis

Alembic arbeitet am besten mit **SQLAlchemy ORM-Modellen**. Das bedeutet: Die Datenbankstruktur wird in Python-Klassen definiert statt in raw SQL. Alembic vergleicht Modell mit DB und generiert das diff automatisch.

```python
# models.py – statt CREATE TABLE SQL
from sqlalchemy import Column, Integer, String, Boolean, ForeignKey
from sqlalchemy.orm import DeclarativeBase

class Base(DeclarativeBase):
    pass

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True)
    username = Column(String, unique=True, nullable=False)
    password = Column(String, nullable=False)
    created_at = Column(String, nullable=False)

class Todo(Base):
    __tablename__ = "todos"
    id = Column(Integer, primary_key=True)
    text = Column(String, nullable=False)
    done = Column(Boolean, default=False)
    created_at = Column(String, nullable=False)
    priority = Column(String, default="medium")
    due = Column(String, nullable=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))
```

---

## Übungen zum Verinnerlichen

### Übung 1: Alembic initialisieren und Erstkonfiguration 🛠️

**Ziel**: Alembic im Projekt einrichten und mit der bestehenden Datenbank verbinden.

1. **Schritt 1**: Alembic initialisieren:
   ```bash
   cd ~/todo-projekt
   alembic init migrations
   ```
   Das erzeugt:
   ```
   alembic.ini           (Hauptkonfiguration)
   migrations/
   ├── env.py            (Verbindungslogik)
   ├── script.py.mako    (Vorlage für Migrationsskripte)
   └── versions/         (hier landen die Migrationsskripte)
   ```

2. **Schritt 2**: Claude helfen lassen, `alembic.ini` und `env.py` anzupassen:
   ```
   Ich habe eine SQLite-Datenbank unter "todos.db".
   Was muss ich in alembic.ini (sqlalchemy.url) und in migrations/env.py
   ändern, damit Alembic meine SQLAlchemy-Modelle aus models.py erkennt?
   Zeige nur die relevanten Zeilen, die geändert werden müssen.
   ```

3. **Schritt 3**: Anpassungen selbst eintippen:
   - In `alembic.ini`: `sqlalchemy.url = sqlite:///todos.db`
   - In `migrations/env.py`: `target_metadata` auf `Base.metadata` zeigen lassen

4. **Schritt 4**: Aktuellen Datenbankstand als Ausgangspunkt setzen.
   Da die DB bereits existiert, muss Alembic wissen, dass sie schon auf dem neuesten Stand ist:
   ```bash
   # Erste "leere" Migration erstellen (stellt Ausgangszustand dar)
   alembic revision --autogenerate -m "initial schema"
   ```
   Die generierte Datei in `migrations/versions/` öffnen und prüfen:
   - Enthält `upgrade()` und `downgrade()` die erwarteten Operationen?
   - Claude fragen: `Was bedeutet es wenn upgrade() leer ist? Ist das ein Fehler?`

5. **Schritt 5**: Migration als angewendet markieren (nicht erneut ausführen):
   ```bash
   alembic stamp head
   alembic current   # Zeigt: aktueller Revisionsstand
   ```

**Reflexion**: Warum ist `alembic stamp head` besser als `alembic upgrade head` bei einer bereits existierenden Datenbank?

---

### Übung 2: Eine Schemaänderung durchführen 🔄

**Ziel**: Eine neue Spalte hinzufügen, eine Migration generieren, anwenden und rückgängig machen.

1. **Schritt 1**: Anforderung definieren – Todos sollen ein `tags`-Feld bekommen (kommagetrennter String, optional).
   Erst den fachlichen Sinn durchdenken – Claude fragen:
   ```
   Ich möchte Todos mit Tags versehen (z. B. "arbeit,wichtig").
   Welche Vor- und Nachteile hat es, Tags als kommagetrennten String
   zu speichern statt als separate Tabelle mit Foreign Key?
   Wann wäre eine separate Tabelle sinnvoller?
   ```

2. **Schritt 2**: `models.py` anpassen – neue Spalte im Modell ergänzen:
   ```python
   class Todo(Base):
       # ... bestehende Spalten ...
       tags = Column(String, nullable=True)
   ```

3. **Schritt 3**: Migration automatisch generieren:
   ```bash
   alembic revision --autogenerate -m "add tags column to todos"
   ```
   Die generierte Datei öffnen – sie sollte etwa so aussehen:
   ```python
   def upgrade() -> None:
       op.add_column("todos", sa.Column("tags", sa.String(), nullable=True))

   def downgrade() -> None:
       op.drop_column("todos", "tags")
   ```
   Mit Claude prüfen:
   ```
   Ist dieses Alembic-Migrationsskript korrekt und vollständig?
   [Inhalt der generierten Datei einfügen]
   Was könnte bei downgrade() schiefgehen?
   ```

4. **Schritt 4**: Migration anwenden und prüfen:
   ```bash
   alembic upgrade head
   alembic current
   ```
   In Python prüfen:
   ```python
   import sqlite3
   conn = sqlite3.connect("todos.db")
   print(conn.execute("PRAGMA table_info(todos)").fetchall())
   # Spalte "tags" muss erscheinen
   ```

5. **Schritt 5**: Migration rückgängig machen und erneut anwenden:
   ```bash
   alembic downgrade -1    # tags-Spalte weg
   alembic upgrade head    # tags-Spalte wieder da
   ```
   Überprüfe nach `downgrade`, ob die Spalte wirklich fehlt.

**Reflexion**: Was passiert mit Daten in der `tags`-Spalte wenn `downgrade()` ausgeführt wird? Gibt es Fälle wo ein `downgrade` Daten unwiederbringlich löscht?

---

### Übung 3: Alembic in CI/CD und produktive Deployments integrieren 🚀

**Ziel**: Migrationen automatisiert und sicher im Deployment-Prozess ausführen.

1. **Schritt 1**: Risiken verstehen – Claude fragen:
   ```
   Welche Risiken gibt es wenn ich "alembic upgrade head" automatisch
   beim App-Start ausführe? Was kann schiefgehen wenn mehrere Instanzen
   gleichzeitig starten (z. B. in Kubernetes)?
   ```

2. **Schritt 2**: Sicheres Migrations-Pattern in `main.py` einbauen:
   ```python
   from alembic.config import Config
   from alembic import command
   from contextlib import asynccontextmanager

   @asynccontextmanager
   async def lifespan(app: FastAPI):
       # Beim Start: Migrationen ausführen
       alembic_cfg = Config("alembic.ini")
       command.upgrade(alembic_cfg, "head")
       yield
       # Beim Shutdown: (nichts nötig)

   app = FastAPI(lifespan=lifespan)
   ```

3. **Schritt 3**: CI-Pipeline erweitern – Migrationen im Test-Job prüfen:
   ```yaml
   # In ci.yml – neuer Step nach "Install dependencies":
   - name: Datenbankmigrationen prüfen
     run: |
       alembic upgrade head
       alembic check   # Schlägt fehl wenn Modell und DB-Schema nicht übereinstimmen
   ```
   Was macht `alembic check`? Claude fragen.

4. **Schritt 4**: Gefährliche Migration üben – Spalte umbenennen.
   ```
   Ich möchte die Spalte "due" in "due_date" umbenennen.
   Warum ist "alembic revision --autogenerate" dafür nicht geeignet?
   Was erzeugt Alembic stattdessen und welches Problem entsteht?
   ```
   Verstehen, dass `--autogenerate` Rename als DROP + ADD interpretiert – Datenverlust!
   Manuell eine sichere Migration schreiben:
   ```python
   def upgrade() -> None:
       # SQLite unterstützt kein direktes RENAME COLUMN vor Version 3.25
       # Sicherer Weg: neue Spalte + Daten kopieren + alte löschen
       op.add_column("todos", sa.Column("due_date", sa.String(), nullable=True))
       op.execute("UPDATE todos SET due_date = due")
       op.drop_column("todos", "due")

   def downgrade() -> None:
       op.add_column("todos", sa.Column("due", sa.String(), nullable=True))
       op.execute("UPDATE todos SET due = due_date")
       op.drop_column("todos", "due_date")
   ```

5. **Schritt 5**: `models.py`, `db.py` und `schemas.py` entsprechend anpassen – mit Claude den Überblick behalten:
   ```
   Ich habe "due" in "due_date" umbenannt. In welchen Dateien meines
   Projekts muss ich die Änderung noch nachziehen?
   Hier ist meine Projektstruktur: [Dateien auflisten]
   ```

**Abschlussprojekt-Checkliste**:
- [ ] Alembic initialisiert, `alembic.ini` und `env.py` konfiguriert
- [ ] Erster Migrationsstempel gesetzt (`alembic stamp head`)
- [ ] `tags`-Spalte per Migration hinzugefügt
- [ ] `upgrade` und `downgrade` beide getestet
- [ ] Spalten-Umbenennung ohne Datenverlust migriert
- [ ] `alembic upgrade head` im App-Lifespan
- [ ] CI-Pipeline mit `alembic check` ergänzt
- [ ] `migrations/versions/` liegt im Git-Repository

**Reflexion**: Wie unterscheidet sich Alembic vom SQL-Ansatz `CREATE TABLE IF NOT EXISTS`? In welchem Projekt würdest du auf Alembic verzichten – und wann ist es unverzichtbar?

---

## Migrations-Cheatsheet

```bash
# Initialisierung
alembic init migrations

# Neuen Stand prüfen
alembic current
alembic history --verbose

# Neue Migration (automatisch aus Modell-Diff)
alembic revision --autogenerate -m "beschreibung"

# Neue Migration (manuell, für komplexe Änderungen)
alembic revision -m "beschreibung"

# Migrationen anwenden
alembic upgrade head          # Alle ausstehenden
alembic upgrade +1            # Nur eine vorwärts

# Migrationen rückgängig machen
alembic downgrade -1          # Eine zurück
alembic downgrade base        # Alles zurück

# Bestehende DB als aktuell markieren (ohne Migration auszuführen)
alembic stamp head

# Prüfen ob Modell und DB übereinstimmen
alembic check
```

---

## Fazit

Alembic schließt den Entwicklungsworkflow: Code ist in Git versioniert, Datenbankschema ist in Alembic versioniert. Claude ist beim Generieren von Migrationsskripten und beim Erklären von SQLAlchemy-Syntax sehr hilfreich – aber bei datenzerstörenden Operationen (DROP, RENAME, Typ-Änderungen) ist manuelles Prüfen und Testen unerlässlich.

**Das vollständige Lernprojekt in der Übersicht**:
```
Modul 1–2:  Grundlagen und Prompting
Modul 3:    Todo-CLI (Python + JSON)
Modul 4:    Erweiterung (Prioritäten, Filter)
Modul 5:    CI/CD (GitHub Actions)
Modul 6:    SQLite-Migration (Repository-Pattern)
Modul 7:    REST-API (FastAPI)
Modul 8:    Mehrere Benutzer (Auth, Foreign Keys)
Modul 9:    Alembic (Schema-Versionierung)
```
