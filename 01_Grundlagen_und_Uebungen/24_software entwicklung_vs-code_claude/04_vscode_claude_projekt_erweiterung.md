# Lernprojekt: Todo-App erweitern – Prioritäten, Fälligkeitsdaten und Filter

## Einführung

Dieses Modul baut direkt auf dem fertigen `todo.py`-Projekt aus Modul 3 auf. Die App bekommt drei neue Features: **Prioritäten** (hoch/mittel/niedrig), **Fälligkeitsdaten** und **Filterfunktionen** (z. B. nur offene oder nur hochpriore Aufgaben anzeigen). Der Fokus liegt dabei auf dem Umgang mit wachsender Komplexität – wie man bestehenden Code erweitert, ohne ihn zu zerbrechen, und wie Claude beim Refaktorieren hilft, ohne die Kontrolle zu übernehmen.

**Voraussetzungen**:
- Modul 3 abgeschlossen (`todo.py`, `test_todo.py`, `todos.json` vorhanden)
- `pytest` installiert
- Grundverständnis von Python-Datenstrukturen und argparse

**Ziele**:
- Bestehenden Code um neue Felder (Priorität, Fälligkeitsdatum) erweitern, ohne bestehende Funktionalität zu brechen.
- Filterlogik implementieren und mit Claude auf Edge-Cases prüfen.
- Lernen, wie man Claude für Refaktorierungsaufgaben in bestehenden Projekten einsetzt.
- Migrationsstrategie für bestehende `todos.json`-Daten entwickeln.

**Neue CLI-Befehle nach diesem Modul**:
```bash
python todo.py add "Bericht schreiben" --priority high --due 2026-04-30
python todo.py list --filter open
python todo.py list --filter high
python todo.py list --filter overdue
```

**Quellen**:
- Python datetime Dokumentation: https://docs.python.org/3/library/datetime.html
- argparse optional arguments: https://docs.python.org/3/library/argparse.html

---

## Grundlagen: Bestehenden Code erweiterbar halten

### Das Open/Closed-Prinzip in der Praxis

Beim Erweitern von Code gilt: Neues soll hinzugefügt werden können, ohne altes zu verändern. Claude kann helfen, Erweiterungspunkte zu identifizieren:

```
"Hier ist mein aktuelles todo.py. Welche Stellen im Code müssen ich ändern,
um Prioritäten und Fälligkeitsdaten hinzuzufügen? Liste die Stellen auf,
bevor du irgendetwas implementierst."
```

### Migrationsstrategie für JSON-Daten

Bestehende `todos.json`-Einträge haben kein `priority`- oder `due`-Feld. Statt alle Daten manuell anzupassen, braucht man eine Migrations- oder Kompatibilitätsstrategie.

**Drei Optionen** – welche ist sinnvoll?

| Option | Vorgehen | Risiko |
|---|---|---|
| **Hartes Migrieren** | Skript läuft einmalig, konvertiert alle alten Einträge | Datenverlust bei Fehler |
| **Lazy Migration** | Beim Laden: fehlendes Feld → Standardwert setzen | Einfach, keine Downtime |
| **Versionierung** | JSON bekommt `"version": 2`-Feld, Code prüft Version | Aufwand, aber sauber |

> ℹ️ Für ein lokales CLI-Tool ist **Lazy Migration** meist der pragmatischste Ansatz.

---

## Übungen zum Verinnerlichen

### Übung 1: Datenstruktur und Lazy Migration 🗂️

**Ziel**: Die JSON-Datenstruktur um neue Felder erweitern und sicherstellen, dass alte Daten nicht verloren gehen.

1. **Schritt 1**: Claude nach einer Einschätzung fragen:
   ```
   Meine todos.json hat aktuell folgende Struktur pro Eintrag:
   {"id": 1, "text": "...", "done": false, "created_at": "2026-04-08"}
   Ich möchte "priority" (Werte: "low", "medium", "high", Standard: "medium")
   und "due" (ISO-Datum-String oder null) hinzufügen.
   Wie implementiere ich Lazy Migration in der load_todos()-Funktion,
   sodass alte Einträge beim Laden automatisch die Standardwerte bekommen?
   ```

2. **Schritt 2**: `load_todos()` selbst anpassen – das Muster von Claude als Vorlage nutzen, aber selbst schreiben:
   ```python
   def load_todos(filepath: str) -> list[dict]:
       # ... bestehender Code ...
       # Lazy Migration: fehlende Felder mit Standardwerten auffüllen
       for todo in todos:
           todo.setdefault("priority", "medium")
           todo.setdefault("due", None)
       return todos
   ```

3. **Schritt 3**: Bestehende `todos.json` manuell prüfen – werden alte Einträge korrekt geladen?
   ```bash
   python todo.py list
   ```

4. **Schritt 4**: Tests für die Migration schreiben:
   ```python
   def test_lazy_migration_adds_missing_fields(tmp_path):
       # Alte Struktur ohne priority und due anlegen
       old_data = [{"id": 1, "text": "Alt", "done": False, "created_at": "2026-01-01"}]
       filepath = str(tmp_path / "todos.json")
       # ... Datei schreiben, load_todos aufrufen, Felder prüfen
   ```

**Reflexion**: Warum ist es gefährlich, direkt `todo["priority"]` statt `todo.get("priority", "medium")` zu schreiben? Was passiert beim Deploy auf einem System mit alten Daten?

---

### Übung 2: add-Befehl und list-Befehl erweitern ➕

**Ziel**: `--priority` und `--due` als optionale Argumente zu `add` hinzufügen und die Listenausgabe anpassen.

1. **Schritt 1**: argparse-Erweiterung planen – erst fragen, dann selbst implementieren:
   ```
   Wie füge ich zu einem bestehenden argparse-Subparser "add" zwei optionale
   Argumente hinzu: --priority (choices: low, medium, high, default: medium)
   und --due (Format: YYYY-MM-DD, optional, default: None)?
   Zeige nur die argparse-Zeilen, keinen restlichen Code.
   ```

2. **Schritt 2**: `cmd_add()` selbst anpassen, sodass `priority` und `due` gespeichert werden.

3. **Schritt 3**: `cmd_list()` anpassen – Priorität und Fälligkeitsdatum in der Ausgabe anzeigen:
   ```
   [1] Bericht schreiben [HIGH] (fällig: 2026-04-30) ✗
   [2] Kaffee kaufen [medium]                         ✓
   ```
   Claude um Hilfe beim Formatieren bitten:
   ```
   Wie kann ich Python f-strings nutzen, um die Ausgabe rechtsbündig
   ausgerichtet und farbig (ANSI-Escape-Codes) zu gestalten?
   Nur für Terminal-Ausgabe, keine externe Bibliothek.
   ```

4. **Schritt 4**: Testen:
   ```bash
   python todo.py add "Wichtige Aufgabe" --priority high --due 2026-04-15
   python todo.py add "Normale Aufgabe"
   python todo.py list
   ```

**Reflexion**: Sollte `--due` auf ein gültiges Datumsformat validiert werden? Was passiert, wenn jemand `--due gestern` eingibt?

---

### Übung 3: Filterfunktion implementieren 🔍

**Ziel**: `list --filter` implementieren, der Aufgaben nach Status, Priorität oder Fälligkeit filtert.

1. **Schritt 1**: Filterlogik mit Claude durchdenken:
   ```
   Ich möchte zu "python todo.py list" einen optionalen Parameter --filter hinzufügen.
   Mögliche Werte: open, done, high, medium, low, overdue.
   "overdue" bedeutet: due ist gesetzt, Datum liegt vor heute, done ist false.
   Schreibe eine Funktion filter_todos(todos: list[dict], filter_by: str | None) -> list[dict].
   Nutze datetime.date.today() für den Datumsvergleich.
   ```

2. **Schritt 2**: Die Funktion verstehen und in `cmd_list()` einbinden.

3. **Schritt 3**: Edge-Cases selbst testen:
   ```bash
   python todo.py list --filter open      # Nur offene Aufgaben
   python todo.py list --filter high      # Nur hochpriore
   python todo.py list --filter overdue   # Überfällige
   python todo.py list --filter done      # Erledigte
   ```
   Was passiert bei `--filter overdue` wenn keine Aufgabe ein Fälligkeitsdatum hat?

4. **Schritt 4**: Tests für alle Filter-Varianten schreiben:
   ```python
   def test_filter_overdue_returns_only_overdue_open(tmp_path):
       # Testdaten: 1 überfällig+offen, 1 überfällig+erledigt, 1 nicht fällig
       # Nur der erste sollte bei --filter overdue erscheinen
       ...
   ```

5. **Schritt 5**: Gesamten Code Claude reviewen lassen:
   ```
   Reviewe die neuen Funktionen filter_todos() und cmd_list() hinsichtlich:
   - Korrektheit des Datumsvergleichs (Zeitzone, Datumsformat-Fehler)
   - Fehlerbehandlung bei ungültigem --due-Format
   - Vollständigkeit der Filter-Logik
   ```

**Abschlussprojekt-Checkliste**:
- [ ] `add` akzeptiert `--priority` und `--due`
- [ ] Lazy Migration: alte Einträge bekommen Standardwerte
- [ ] `list` zeigt Priorität und Fälligkeitsdatum an
- [ ] `list --filter` unterstützt: open, done, high, medium, low, overdue
- [ ] Alle neuen Tests grün (`pytest test_todo.py -v`)
- [ ] Ungültiges Datumsformat bei `--due` gibt verständliche Fehlermeldung

**Reflexion**: Wie verändert sich die Komplexität des Projekts? Ab wann wäre eine Datenbank sinnvoller als JSON? (→ Modul 6)

---

## Fazit

Das Erweitern bestehenden Codes ist eine der häufigsten Entwickleraufgaben. Claude hilft dabei besonders gut als Diskussionspartner in der Planungsphase und als Reviewer danach – weniger als vollständiger Code-Generator, da er den Projektkontext nicht so tief kennt wie du.

**Nächste Schritte**:
- **Modul 5**: CI/CD-Pipeline mit GitHub Actions – automatisiert testen bei jedem Push.
- **Modul 6**: Migration zu SQLite – wenn JSON an seine Grenzen stößt.
