# Lernprojekt: Mehrere Benutzer – User-Tabelle, Authentifizierung und Foreign Keys

## Einführung

Bisher kennt die Todo-API keine Benutzer – jeder sieht alle Todos. In diesem Modul wird eine **User-Tabelle** mit **Foreign Keys** eingeführt: Jedes Todo gehört einem Benutzer. Dazu kommt eine einfache **JWT-Authentifizierung**, damit nur eingeloggte Benutzer auf ihre eigenen Todos zugreifen können. Dieses Modul verbindet Datenbankmodellierung, relationale Konzepte und API-Sicherheit – alles typische Herausforderungen realer Webanwendungen.

**Voraussetzungen**:
- Modul 7 abgeschlossen (FastAPI-API mit `TodoRepository`, alle Endpunkte funktionsfähig)
- Grundverständnis von SQL-Joins und Foreign Keys
- Grundverständnis von HTTP-Headern (Authorization: Bearer)

**Installation**:
```bash
pip install python-jose[cryptography] passlib[bcrypt]
```

**Ziele**:
- Relationales Datenbankmodell mit Foreign Keys in SQLite verstehen und implementieren.
- Passwort-Hashing mit `passlib` (bcrypt) korrekt anwenden.
- JWT-Tokens ausstellen und in FastAPI prüfen.
- Endpunkte absichern: Jeder Benutzer sieht nur seine eigenen Todos.
- Mit Claude Sicherheitsaspekte durchdenken und typische Fehler vermeiden.

**Neue Endpunkte nach diesem Modul**:
```
POST   /auth/register      → Neuen Benutzer registrieren
POST   /auth/login         → Token abrufen
GET    /todos              → Nur eigene Todos (Token erforderlich)
POST   /todos              → Todo für eingeloggten User erstellen
```

**Quellen**:
- FastAPI Security: https://fastapi.tiangolo.com/tutorial/security/
- python-jose: https://python-jose.readthedocs.io
- passlib: https://passlib.readthedocs.io

---

## Grundlagen: Relationales Modell und Authentifizierung

### Datenbankmodell mit Foreign Key

```
users                          todos
─────────────────────          ──────────────────────────────
id        INTEGER PK           id        INTEGER PK
username  TEXT UNIQUE          text      TEXT
password  TEXT (hashed!)       done      INTEGER
created_at TEXT                created_at TEXT
                               priority  TEXT
                               due       TEXT
                               user_id   INTEGER FK → users.id
```

**Beziehung**: Ein User hat viele Todos (`1:n`). Der Foreign Key `user_id` in `todos` stellt diese Verbindung her.

### JWT-Authentifizierungsablauf

```
1. POST /auth/login  {username, password}
   → Server prüft Passwort-Hash
   → Server erstellt JWT-Token (enthält user_id, Ablaufzeit)
   → Client bekommt Token

2. GET /todos
   Authorization: Bearer <token>
   → Server dekodiert Token → user_id
   → Nur Todos mit dieser user_id werden zurückgegeben
```

> ⚠️ **Sicherheitshinweis**: Passwörter werden **niemals** im Klartext gespeichert. Immer hashen mit `passlib` (bcrypt). Ein gestohlener JWT-Token gibt Zugriff auf alle Daten des Nutzers – kurze Ablaufzeiten (z. B. 30 Minuten) begrenzen den Schaden.

---

## Übungen zum Verinnerlichen

### Übung 1: Datenbankmodell erweitern und UserRepository erstellen 🗄️

**Ziel**: Die Datenbank um eine `users`-Tabelle mit Foreign-Key-Beziehung zu `todos` erweitern.

1. **Schritt 1**: Relationales Schema mit Claude durchdenken:
   ```
   Ich möchte in SQLite eine users-Tabelle hinzufügen und todos mit
   einem Foreign Key user_id verknüpfen.
   
   Erkläre mir:
   1. Wie aktiviere ich Foreign-Key-Enforcement in SQLite (es ist standardmäßig aus)?
   2. Was passiert mit bestehenden todos-Einträgen wenn ich user_id NOT NULL mache?
   3. Soll user_id ON DELETE CASCADE oder ON DELETE SET NULL sein?
   ```

2. **Schritt 2**: `db.py` erweitern – `_init_db()` um Users-Tabelle und Foreign Key ergänzen:
   ```python
   def _init_db(self):
       with sqlite3.connect(self.db_path) as conn:
           conn.execute("PRAGMA foreign_keys = ON")
           conn.execute("""
               CREATE TABLE IF NOT EXISTS users (
                   id INTEGER PRIMARY KEY AUTOINCREMENT,
                   username TEXT UNIQUE NOT NULL,
                   password TEXT NOT NULL,
                   created_at TEXT NOT NULL
               )
           """)
           conn.execute("""
               CREATE TABLE IF NOT EXISTS todos (
                   -- bestehende Spalten ...
                   user_id INTEGER,
                   FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
               )
           """)
   ```

3. **Schritt 3**: `UserRepository`-Klasse in `db.py` ergänzen (oder neue Datei `user_db.py`):
   Claude fragen:
   ```
   Welche Methoden braucht ein UserRepository für Authentifizierung?
   Liste nur die Methodensignaturen auf, keinen Code.
   ```
   Dann selbst implementieren: `create_user()`, `get_by_username()`.

4. **Schritt 4**: Foreign-Key-Verhalten testen:
   ```python
   repo = TodoRepository(":memory:")
   user_repo = UserRepository(":memory:")  # Gleiche Verbindung!
   # Hinweis: Wie teile ich eine :memory:-Verbindung zwischen zwei Repositories?
   # Claude fragen: "Was ist das Problem mit zwei separaten :memory: SQLite-Verbindungen?"
   ```

**Reflexion**: Warum muss `PRAGMA foreign_keys = ON` bei **jeder Verbindung** gesetzt werden und gilt nicht dauerhaft? Was ist der historische Grund?

---

### Übung 2: Passwort-Hashing und JWT-Token implementieren 🔐

**Ziel**: Sichere Passwortspeicherung und Token-Ausstellung implementieren – und verstehen warum.

1. **Schritt 1**: Passwort-Hashing mit Claude erklären lassen:
   ```
   Erkläre mir den Unterschied zwischen:
   - Passwort im Klartext speichern
   - Passwort mit MD5/SHA256 hashen
   - Passwort mit bcrypt hashen
   Warum ist bcrypt trotz Langsamkeit die bessere Wahl?
   ```

2. **Schritt 2**: Sicherheitsmodul `auth.py` erstellen:
   ```python
   from passlib.context import CryptContext
   from jose import JWTError, jwt
   from datetime import datetime, timedelta

   SECRET_KEY = "ERSETZE-MICH-DURCH-EINEN-ECHTEN-SECRET"  # In Produktion: aus Umgebungsvariable!
   ALGORITHM = "HS256"
   TOKEN_EXPIRE_MINUTES = 30

   pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

   def hash_password(password: str) -> str:
       return pwd_context.hash(password)

   def verify_password(plain: str, hashed: str) -> bool:
       return pwd_context.verify(plain, hashed)

   def create_token(user_id: int) -> str:
       # Selbst implementieren: payload mit user_id und exp (Ablaufzeit)
       ...

   def decode_token(token: str) -> int:
       # Selbst implementieren: token dekodieren, user_id zurückgeben
       # HTTPException 401 wenn Token ungültig oder abgelaufen
       ...
   ```

3. **Schritt 3**: Claude nach dem `decode_token`-Muster fragen:
   ```
   Wie implementiere ich decode_token() mit python-jose so, dass:
   - JWTError in HTTPException(401) umgewandelt wird
   - Ein abgelaufener Token ebenfalls 401 ergibt
   - Die Funktion die user_id als int zurückgibt
   ```

4. **Schritt 4**: `auth.py` manuell testen:
   ```python
   from auth import hash_password, verify_password, create_token, decode_token
   hashed = hash_password("meinPasswort123")
   print(verify_password("meinPasswort123", hashed))   # True
   print(verify_password("falsches", hashed))           # False
   token = create_token(42)
   print(decode_token(token))                           # 42
   ```

**Reflexion**: Wo sollte `SECRET_KEY` in einem echten Projekt gespeichert werden? Was ist der Unterschied zwischen einer `.env`-Datei und einer Umgebungsvariable?

---

### Übung 3: Endpunkte absichern und User-Isolation testen 🛡️

**Ziel**: Register/Login-Endpunkte implementieren und alle Todo-Endpunkte mit Authentifizierung absichern.

1. **Schritt 1**: Auth-Endpunkte in `main.py` hinzufügen:
   ```python
   from auth import hash_password, verify_password, create_token, decode_token

   @app.post("/auth/register", status_code=201)
   def register(username: str, password: str):
       # Existiert der Username schon? → 400
       # Passwort hashen, User anlegen
       # Token zurückgeben (direkt einloggen nach Registrierung)
       ...

   @app.post("/auth/login")
   def login(username: str, password: str):
       # User suchen → 401 wenn nicht gefunden
       # Passwort prüfen → 401 wenn falsch
       # Token zurückgeben
       ...
   ```

2. **Schritt 2**: FastAPI-Dependency für Authentifizierung erstellen:
   ```
   Erkläre mir das Dependency-Injection-Konzept in FastAPI.
   Wie erstelle ich eine Funktion get_current_user(), die:
   - Den Authorization-Header ausliest
   - Den Token dekodiert
   - Den User aus der DB lädt
   - Als Dependency in Endpunkten verwendet werden kann?
   ```
   Implementierung (Vorlage von Claude, selbst eintippen):
   ```python
   from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

   security = HTTPBearer()

   def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
       token = credentials.credentials
       user_id = decode_token(token)
       # User aus DB laden, zurückgeben
       ...
   ```

3. **Schritt 3**: Alle Todo-Endpunkte mit `Depends(get_current_user)` absichern:
   ```python
   @app.get("/todos", response_model=list[TodoResponse])
   def get_todos(filter: str | None = None, current_user: dict = Depends(get_current_user)):
       return repo.get_all(filter_by=filter, user_id=current_user["id"])
   ```
   `get_all()` im Repository muss `user_id` als Parameter akzeptieren – anpassen.

4. **Schritt 4**: User-Isolation testen – das Wichtigste:
   ```python
   def test_user_cannot_see_other_users_todos():
       # User A registrieren und Todo anlegen
       client.post("/auth/register", json={"username": "alice", "password": "pass1"})
       token_a = client.post("/auth/login", json={"username": "alice", "password": "pass1"}).json()["token"]
       client.post("/todos", json={"text": "Alices Todo"}, headers={"Authorization": f"Bearer {token_a}"})

       # User B registrieren
       client.post("/auth/register", json={"username": "bob", "password": "pass2"})
       token_b = client.post("/auth/login", json={"username": "bob", "password": "pass2"}).json()["token"]

       # User B darf Alices Todos nicht sehen
       response = client.get("/todos", headers={"Authorization": f"Bearer {token_b}"})
       assert response.json() == []
   ```

5. **Schritt 5**: Sicherheits-Review mit Claude:
   ```
   Reviewe meinen Auth-Code in auth.py und main.py auf:
   1. Werden Passwörter irgendwo geloggt oder im Klartext zurückgegeben?
   2. Sind alle Todo-Endpunkte wirklich abgesichert?
   3. Kann User B das Todo von User A löschen wenn er die ID errät?
   ```

**Abschlussprojekt-Checkliste**:
- [ ] `users`-Tabelle mit Foreign Key zu `todos`
- [ ] `PRAGMA foreign_keys = ON` bei jeder Verbindung gesetzt
- [ ] Passwörter mit bcrypt gehasht (niemals Klartext)
- [ ] JWT-Token mit Ablaufzeit
- [ ] `POST /auth/register` und `POST /auth/login` funktionsfähig
- [ ] Alle Todo-Endpunkte erfordern gültigen Token
- [ ] User-Isolation getestet: User B sieht keine Todos von User A
- [ ] CI-Pipeline weiterhin grün

**Reflexion**: Welche Sicherheitslücken hat diese Implementierung noch? (Denke an: Rate Limiting, HTTPS, Token-Invalidierung bei Logout, Brute-Force-Schutz)

---

## Fazit

Mit User-Tabelle, Foreign Keys und JWT-Authentifizierung ist die Todo-App zu einer mehrschichtigen Webanwendung gewachsen. Claude war besonders wertvoll beim Erklären von Sicherheitskonzepten und beim Identifizieren von Lücken im Security-Review. Aber: Sicherheitskritischer Code erfordert immer eigene Verifikation – KI-generierter Auth-Code muss genauso gründlich geprüft werden wie selbst geschriebener.

**Nächste Schritte**:
- **Modul 9**: Alembic – Datenbankschema sauber versionieren, damit Schemaänderungen ohne Datenverlust deployed werden können.
