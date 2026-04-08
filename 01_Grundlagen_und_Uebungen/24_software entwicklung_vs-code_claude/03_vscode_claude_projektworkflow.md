# Lernprojekt: Vollständiger Projektworkflow mit Claude als Pair-Programmer

## Einführung

Dieses Modul verbindet alle bisherigen Grundlagen in einem realen Mini-Projekt: einer **einfachen Aufgabenverwaltungs-CLI** (Todo-App) in Python. Das Projekt wird vollständig mit Claude als Pair-Programmer entwickelt – von der Anforderungsanalyse über Implementierung und Tests bis hin zur Dokumentation. Dabei liegt der Fokus auf dem **Workflow**: Wann greift man auf Claude zurück, wann arbeitet man selbst, und wie behält man die Kontrolle über das eigene Projekt?

**Voraussetzungen**:
- Modul 1 und 2 abgeschlossen
- Python 3.12 installiert
- Claude Code CLI eingerichtet und lauffähig
- VS Code mit Python-Erweiterung
- `pytest` installiert (`pip install pytest`)

**Ziele**:
- Einen vollständigen Entwicklungs-Workflow mit Claude von Anfang bis Ende durchlaufen.
- Claude für verschiedene Phasen (Design, Implementierung, Testing, Dokumentation) nutzen.
- Verstehen, wie man KI-Unterstützung sinnvoll dosiert – wann sie hilft und wann sie bremst.
- Ein funktionsfähiges, getestetes und dokumentiertes Python-Projekt abliefern.

**Projektziel**: Eine CLI-Anwendung `todo.py`, die Aufgaben in einer JSON-Datei speichert und folgende Befehle unterstützt:
```bash
python todo.py add "Einkaufen gehen"
python todo.py list
python todo.py done 1
python todo.py delete 1
```

**Quellen**:
- Python argparse Dokumentation: https://docs.python.org/3/library/argparse.html
- pytest Dokumentation: https://docs.pytest.org

---

## Grundlagen: Der KI-unterstützte Entwicklungsworkflow

### Phasen und Claude-Einsatz

```
Phase 1: Anforderungen & Design
  → Claude: Architektur diskutieren, Datenstruktur vorschlagen lassen
  → Selbst: Entscheidungen treffen und verstehen

Phase 2: Implementierung
  → Claude: Boilerplate generieren, Muster zeigen
  → Selbst: Kernlogik schreiben und verstehen

Phase 3: Testing
  → Claude: Test-Cases vorschlagen, Edge-Cases finden
  → Selbst: Tests schreiben und ausführen

Phase 4: Dokumentation & Review
  → Claude: Docstrings, README-Entwurf
  → Selbst: Review und finaler Schliff
```

> ℹ️ **Pair-Programming-Prinzip**: Claude übernimmt nie die Verantwortung für das Projekt. Er ist ein Diskussionspartner, kein Entwickler. Jede Zeile, die ins Projekt kommt, muss vom Entwickler verstanden und bewusst akzeptiert werden.

---

## Übungen zum Verinnerlichen

### Übung 1: Anforderungen analysieren und Datenstruktur entwerfen 📐

**Ziel**: Claude als Design-Partner nutzen, um die Projektstruktur durchzudenken, bevor Code geschrieben wird.

1. **Schritt 1**: Projektverzeichnis anlegen.
   ```bash
   mkdir ~/todo-projekt && cd ~/todo-projekt
   code .
   ```

2. **Schritt 2**: Anforderungen mit Claude diskutieren.
   Stelle folgenden Prompt:
   ```
   Ich möchte eine Todo-CLI in Python 3.12 entwickeln.
   Befehle: add, list, done, delete.
   Daten werden in einer JSON-Datei gespeichert (todos.json).
   Schlage mir eine geeignete JSON-Datenstruktur vor und erkläre,
   welche Felder jede Aufgabe haben sollte. Berücksichtige:
   - Eindeutige ID für done/delete per Nummer
   - Status (offen/erledigt)
   - Erstellungsdatum
   Gib nur die Datenstruktur als Beispiel-JSON zurück, keinen Code.
   ```

3. **Schritt 3**: Die vorgeschlagene Struktur bewerten.
   - Brauchst du alle Felder?
   - Fehlt etwas?
   - Triff eine bewusste Entscheidung und notiere sie in `DESIGN.md`:
     ```markdown
     # Design-Entscheidungen
     - Datenformat: JSON, Datei: todos.json
     - Felder pro Aufgabe: id, text, done, created_at
     - IDs: fortlaufende Ganzzahlen ab 1
     ```

4. **Schritt 4**: Frage Claude nach möglichen Problemen:
   ```
   Was sind potenzielle Probleme mit fortlaufenden Integer-IDs in einer JSON-Datei,
   wenn Aufgaben gelöscht werden?
   ```
   Entscheide, ob du die IDs neu vergibst oder behältst (und warum).

**Reflexion**: Hätte man diese Designfragen auch ohne Claude klären können? Welchen Mehrwert hat der Dialog gegenüber einfach loszuschreiben?

---

### Übung 2: Kernimplementierung mit Claude als Pair-Programmer 💻

**Ziel**: Die Todo-App iterativ implementieren – Claude generiert Strukturen, du schreibst die Logik.

1. **Schritt 1**: Lass Claude das Grundgerüst generieren:
   ```
   Erstelle das Grundgerüst für todo.py (Python 3.12) mit argparse.
   Befehle: add (Argument: text), list, done (Argument: id als int), delete (Argument: id als int).
   Keine Implementierung der Befehle – nur die argparse-Struktur mit einer
   main()-Funktion und leeren Handler-Funktionen (pass).
   ```

2. **Schritt 2**: Implementiere selbst die Datei-Hilfsfunktionen:
   ```python
   # Diese Funktionen selbst schreiben (nicht von Claude):
   def load_todos(filepath: str) -> list[dict]:
       ...

   def save_todos(filepath: str, todos: list[dict]) -> None:
       ...
   ```
   Frage Claude nur, wenn du bei einem konkreten Problem feststeckst (z. B. `json.JSONDecodeError` abfangen).

3. **Schritt 3**: Implementiere `cmd_add()` selbst und nutze Claude für Feedback:
   ```
   Hier ist meine cmd_add()-Implementierung: [Code einfügen]
   Prüfe auf: korrekte ID-Vergabe, fehlende Fehlerbehandlung, Pythonic Style.
   ```

4. **Schritt 4**: Implementiere `cmd_list()`, `cmd_done()`, `cmd_delete()` selbst.
   Für jede Funktion: erst schreiben, dann manuell testen:
   ```bash
   python todo.py add "Ersten Kaffee trinken"
   python todo.py add "Modul 3 abschließen"
   python todo.py list
   python todo.py done 1
   python todo.py list
   python todo.py delete 2
   ```

5. **Schritt 5**: Den fertigen Code Claude reviewen lassen:
   ```
   Reviewe todo.py auf: Fehlerbehandlung, Code-Qualität, Edge-Cases
   (z. B. done/delete mit ungültiger ID, leere Todo-Liste).
   ```

**Reflexion**: Wo war Claudes Unterstützung am hilfreichsten? Wo hat eigenständiges Schreiben das Verständnis vertieft?

---

### Übung 3: Tests schreiben und Dokumentation erstellen 📋

**Ziel**: Das Projekt mit Tests absichern und eine verständliche Dokumentation erstellen.

1. **Schritt 1**: Testfälle mit Claude planen:
   ```
   Welche pytest-Testfälle sollte ich für todo.py schreiben?
   Fokus auf: load_todos, save_todos, cmd_add, cmd_done, cmd_delete.
   Liste nur die Testfall-Beschreibungen auf, keinen Code.
   ```

2. **Schritt 2**: Testdatei anlegen und Tests selbst schreiben (`test_todo.py`).
   Nutze `tmp_path` von pytest für temporäre Dateien:
   ```python
   def test_add_creates_todo(tmp_path):
       filepath = str(tmp_path / "todos.json")
       # ... Test selbst implementieren
   ```
   Frage Claude nur für spezifische pytest-Syntax-Fragen.

3. **Schritt 3**: Tests ausführen und Fehler beheben:
   ```bash
   pytest test_todo.py -v
   ```
   Bei Fehlern: Fehlermeldung + relevanten Code-Ausschnitt an Claude übergeben.

4. **Schritt 4**: Docstrings generieren lassen:
   ```
   Schreibe Google-Style Docstrings für alle Funktionen in todo.py.
   Gib den vollständigen Code mit Docstrings zurück.
   ```
   Überprüfe jeden Docstring: Stimmt die Beschreibung mit dem tatsächlichen Verhalten überein?

5. **Schritt 5**: README erstellen lassen und anpassen:
   ```
   Erstelle eine README.md für mein todo.py-Projekt.
   Enthalten sein soll: Kurzbeschreibung, Voraussetzungen, Installation,
   Verwendung mit Beispielen für alle 4 Befehle, Hinweis auf Tests.
   Markdown-Format, keine Badges oder Logos.
   ```
   Lies die generierte README durch und korrigiere alles, was nicht korrekt oder zu ausführlich ist.

**Abschlussprojekt-Checkliste**:
- [ ] `todo.py` mit allen 4 Befehlen funktionsfähig
- [ ] `todos.json` wird korrekt erstellt und aktualisiert
- [ ] Fehlerbehandlung bei ungültigen IDs vorhanden
- [ ] `test_todo.py` mit mindestens 6 Tests, alle grün
- [ ] Alle Funktionen haben Docstrings
- [ ] `README.md` vorhanden und korrekt
- [ ] `DESIGN.md` mit Entscheidungen dokumentiert

**Reflexion**: Wie lange hätte das Projekt ohne Claude gedauert? Wo hat KI-Unterstützung Zeit gespart? Wo hat sie eher abgelenkt oder zu Überprüfungsaufwand geführt?

---

## Zusammenfassung: Der Workflow im Überblick

```
Anforderungen          → Claude als Sparringspartner für Designfragen
Boilerplate/Struktur   → Claude generiert, du verstehst und bestätigst
Kernlogik              → Selbst schreiben, Claude bei Blockaden fragen
Review                 → Claude als zweite Meinung
Tests                  → Claude schlägt Fälle vor, du implementierst
Dokumentation          → Claude generiert Entwurf, du korrigierst
```

**Goldene Regeln**:
1. Verstehe jede Zeile, die ins Projekt kommt – egal ob von dir oder Claude.
2. Teste immer selbst, verlasse dich nie blind auf KI-generierte Tests.
3. Claude ist besser bei Struktur und Boilerplate als bei domänenspezifischer Logik.
4. Nutze Claude iterativ im Dialog, nicht als Einmal-Generator.

**Nächste Schritte**:
- Das Projekt erweitern: Prioritäten, Fälligkeitsdaten, Filterfunktionen
- CI/CD-Pipeline mit GitHub Actions einrichten (Claude kann das Workflow-YAML generieren)
- Das Projekt auf eine Datenbank (SQLite) umstellen und Claude die Migration begleiten lassen
