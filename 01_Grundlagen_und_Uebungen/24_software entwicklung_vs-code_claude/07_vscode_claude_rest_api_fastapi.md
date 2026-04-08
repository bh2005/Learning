# Lernprojekt: Repository-Pattern auf eine REST-API übertragen (FastAPI)

## Einführung

Die Todo-App aus den vorherigen Modulen ist bisher eine lokale CLI. In diesem Modul wird sie in eine **REST-API** mit **FastAPI** umgewandelt – der moderne Python-Standard für Web-APIs. Der entscheidende Vorteil: Das `TodoRepository` aus Modul 6 bleibt vollständig unverändert. Die Datenbankschicht weiß nichts davon, dass sie jetzt über HTTP angesprochen wird. Dieses Trennungsprinzip ist das Herzstück sauber strukturierter Software.

**Voraussetzungen**:
- Modul 6 abgeschlossen (`db.py` mit `TodoRepository`, `todos.db`)
- Grundverständnis von HTTP (GET, POST, PUT, DELETE, Statuscodes)
- Python 3.12, pip

**Installation**:
```bash
pip install fastapi uvicorn[standard]
```

**Ziele**:
- Verstehen, wie FastAPI funktioniert (Routing, Pydantic-Modelle, automatische Doku).
- Das bestehende `TodoRepository` als Service-Schicht in eine API einbetten.
- REST-konforme Endpunkte mit korrekten HTTP-Methoden und Statuscodes implementieren.
- Mit Claude API-Endpunkte generieren, hinterfragen und testen.
- Automatisch generierte API-Dokumentation (Swagger UI) nutzen.

**API-Endpunkte nach diesem Modul**:
```
GET    /todos              → Alle Todos (optional: ?filter=open)
POST   /todos              → Neues Todo erstellen
GET    /todos/{id}         → Einzelnes Todo abrufen
PUT    /todos/{id}/done    → Todo als erledigt markieren
DELETE /todos/{id}         → Todo löschen
```

**Quellen**:
- FastAPI Dokumentation: https://fastapi.tiangolo.com
- Pydantic Dokumentation: https://docs.pydantic.dev
- HTTP Status Codes: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status

---

## Grundlagen: REST und FastAPI

### REST-Prinzipien im Überblick

```
Ressource: /todos
┌─────────┬──────────────────┬──────────────────────────────┐
│ Methode │ Endpunkt         │ Bedeutung                    │
├─────────┼──────────────────┼──────────────────────────────┤
│ GET     │ /todos           │ Liste aller Todos            │
│ POST    │ /todos           │ Neues Todo anlegen           │
│ GET     │ /todos/1         │ Todo mit ID 1 abrufen        │
│ PUT     │ /todos/1/done    │ Todo 1 als erledigt markieren│
│ DELETE  │ /todos/1         │ Todo 1 löschen               │
└─────────┴──────────────────┴──────────────────────────────┘
```

### FastAPI – Was es besonders macht

- **Automatische Swagger UI**: `http://localhost:8000/docs` – fertig, ohne Konfiguration
- **Pydantic-Validierung**: Request-Body wird automatisch validiert und typisiert
- **Async-fähig**: Unterstützt `async def` für nicht-blockierende Operationen
- **Typ-Annotationen**: Python-Typen werden direkt für API-Schema genutzt

### Projektstruktur nach diesem Modul

```
todo-projekt/
├── db.py           (unverändert aus Modul 6)
├── main.py         (FastAPI-App – neu)
├── schemas.py      (Pydantic-Modelle – neu)
├── todo.py         (CLI – bleibt erhalten)
├── test_todo.py    (bestehende Tests)
├── test_api.py     (neue API-Tests – neu)
└── todos.db
```

---

## Übungen zum Verinnerlichen

### Übung 1: FastAPI-Grundstruktur und ersten Endpunkt erstellen 🚀

**Ziel**: FastAPI einrichten, Pydantic-Schemas definieren und den ersten Endpunkt implementieren.

1. **Schritt 1**: Pydantic-Schemas mit Claude entwerfen.
   ```
   Ich habe ein Todo mit den Feldern: id (int), text (str), done (bool),
   created_at (str), priority (str: low/medium/high), due (str | None).
   
   Erstelle Pydantic v2 Schemas für FastAPI:
   - TodoCreate: Was der Client beim POST sendet (text, priority, due)
   - TodoResponse: Was die API zurückgibt (alle Felder)
   Nutze Field() für Validierung (text nicht leer, priority als Literal).
   Erkläre den Unterschied zwischen den beiden Schemas.
   ```

2. **Schritt 2**: `schemas.py` anlegen – Schemas selbst schreiben, Claudes Vorlage als Leitfaden:
   ```python
   from pydantic import BaseModel, Field
   from typing import Literal

   class TodoCreate(BaseModel):
       text: str = Field(..., min_length=1, max_length=200)
       priority: Literal["low", "medium", "high"] = "medium"
       due: str | None = None

   class TodoResponse(BaseModel):
       id: int
       text: str
       done: bool
       created_at: str
       priority: str
       due: str | None
   ```

3. **Schritt 3**: `main.py` mit dem ersten Endpunkt erstellen:
   ```python
   from fastapi import FastAPI
   from db import TodoRepository
   from schemas import TodoCreate, TodoResponse

   app = FastAPI(title="Todo API", version="1.0.0")
   repo = TodoRepository("todos.db")

   @app.get("/todos", response_model=list[TodoResponse])
   def get_todos(filter: str | None = None):
       return repo.get_all(filter_by=filter)
   ```

4. **Schritt 4**: Server starten und Swagger UI öffnen:
   ```bash
   uvicorn main:app --reload
   # Browser: http://localhost:8000/docs
   ```
   Teste den `GET /todos`-Endpunkt direkt in der Swagger UI.

**Reflexion**: Was passiert, wenn `repo.get_all()` ein dict zurückgibt, das nicht dem `TodoResponse`-Schema entspricht? Wie hilft FastAPI beim Finden solcher Fehler?

---

### Übung 2: Alle CRUD-Endpunkte implementieren 🔨

**Ziel**: POST, GET by ID, PUT und DELETE implementieren – mit korrekten HTTP-Statuscodes.

1. **Schritt 1**: Claude nach Best Practices für Statuscodes fragen:
   ```
   Welche HTTP-Statuscodes sind korrekt für:
   - POST /todos (Erfolg)?
   - GET /todos/99 wenn ID nicht existiert?
   - DELETE /todos/1 (Erfolg)?
   - PUT /todos/99/done wenn ID nicht existiert?
   ```

2. **Schritt 2**: `POST /todos` selbst implementieren:
   ```python
   from fastapi import HTTPException
   import http

   @app.post("/todos", response_model=TodoResponse, status_code=201)
   def create_todo(todo: TodoCreate):
       return repo.add(todo.text, todo.priority, todo.due)
   ```

3. **Schritt 3**: `GET /todos/{todo_id}`, `PUT /todos/{todo_id}/done` und `DELETE /todos/{todo_id}` selbst implementieren.
   Für alle drei: Was tust du, wenn die ID nicht existiert?
   ```python
   # Hilfsfunktion – nur einmal schreiben:
   def get_or_404(todo_id: int) -> dict:
       todo = repo.get_by_id(todo_id)   # Diese Methode in db.py ergänzen!
       if todo is None:
           raise HTTPException(status_code=404, detail=f"Todo {todo_id} nicht gefunden")
       return todo
   ```
   Claude fragen: `Muss ich get_by_id() im Repository ergänzen oder kann ich get_all() filtern? Was ist effizienter?`

4. **Schritt 4**: Alle Endpunkte in der Swagger UI testen:
   - Todo erstellen (POST)
   - Alle auflisten (GET)
   - Einzelnes abrufen (GET by ID)
   - Als erledigt markieren (PUT)
   - Löschen (DELETE)
   - Ungültige ID testen – kommt 404?

**Reflexion**: Warum ist `HTTPException(status_code=404)` besser als einfach `None` zurückzugeben? Was würde ein Client-Entwickler bei `None` denken?

---

### Übung 3: API-Tests und CI-Integration 🧪

**Ziel**: Die API mit `TestClient` von FastAPI testen und in die bestehende CI-Pipeline einbinden.

1. **Schritt 1**: FastAPI-Testmuster von Claude erklären lassen:
   ```
   Wie teste ich FastAPI-Endpunkte mit TestClient?
   Zeige ein Beispiel für POST /todos und GET /todos/{id}.
   Wie stelle ich sicher, dass jeder Test eine frische (leere) Datenbank nutzt?
   ```

2. **Schritt 2**: `test_api.py` anlegen – Tests selbst schreiben:
   ```python
   from fastapi.testclient import TestClient
   import pytest
   from main import app, repo

   @pytest.fixture(autouse=True)
   def clean_db():
       # Vor jedem Test: Datenbank leeren
       # Wie? Claude fragen: "Wie leere ich alle Einträge zwischen Tests
       # wenn ich eine :memory: DB nicht nutzen kann?"
       yield

   client = TestClient(app)

   def test_create_todo_returns_201():
       response = client.post("/todos", json={"text": "Test"})
       assert response.status_code == 201
       assert response.json()["text"] == "Test"

   def test_get_nonexistent_todo_returns_404():
       response = client.get("/todos/9999")
       assert response.status_code == 404
   ```

3. **Schritt 3**: Mindestens 8 Tests schreiben – alle Endpunkte abdecken inkl. Fehlerfälle.
   Claude um Hilfe beim Finden weiterer Testfälle bitten:
   ```
   Hier sind meine bisherigen API-Tests [einfügen].
   Welche wichtigen Fälle fehlen noch?
   ```

4. **Schritt 4**: CI-Pipeline aus Modul 5 erweitern – `test_api.py` wird automatisch mitgetestet:
   ```yaml
   # In ci.yml – fastapi und httpx zu requirements.txt hinzufügen
   ```
   ```bash
   echo "fastapi>=0.115" >> requirements.txt
   echo "httpx>=0.27" >> requirements.txt   # TestClient-Abhängigkeit
   ```
   Push → Pipeline grün?

**Abschlussprojekt-Checkliste**:
- [ ] `schemas.py` mit `TodoCreate` und `TodoResponse`
- [ ] `main.py` mit allen 5 Endpunkten
- [ ] Korrekte HTTP-Statuscodes (201 für POST, 404 für nicht gefundene IDs)
- [ ] `get_by_id()` im Repository ergänzt
- [ ] Swagger UI unter `http://localhost:8000/docs` funktionsfähig
- [ ] `test_api.py` mit mindestens 8 Tests, alle grün
- [ ] CI-Pipeline läuft weiterhin grün

**Reflexion**: Was hat sich durch das Repository-Pattern bewährt? Musste `db.py` für die API-Migration verändert werden?

---

## Fazit

FastAPI und das Repository-Pattern ergänzen sich ideal: FastAPI übernimmt HTTP-Routing und Validierung, das Repository die Datenbanklogik. Claude ist beim Generieren von Boilerplate-Code (Schemas, Endpunkt-Gerüste) sehr hilfreich – die Kernlogik und das Verständnis der Architektur bleiben aber beim Entwickler.

**Nächste Schritte**:
- **Modul 8**: Mehrere Benutzer – User-Tabelle, Authentifizierung, Foreign Keys.
- **Modul 9**: Alembic – Datenbankschema sauber versionieren und migrieren.
