# Lernprojekt: Effektives Prompting für Softwareentwicklung mit Claude

## Einführung

Die Qualität der KI-Unterstützung hängt direkt davon ab, wie gut man mit Claude kommuniziert. Ein vager Prompt liefert vage Ergebnisse – ein präziser, kontextreicher Prompt liefert genau das, was man braucht. Dieses Modul zeigt, wie man Anfragen so formuliert, dass Claude maximalen Nutzen bringt: beim Generieren von Code, beim Reviewen, beim Refaktorieren und beim Schreiben von Tests. Es behandelt außerdem typische Fallstricke und wie man Claude als iterativen Partner einsetzt statt als einmaligen Antwortgeber.

**Voraussetzungen**:
- Modul 1 abgeschlossen (Claude Code CLI eingerichtet, erste Interaktionen durchgeführt)
- Grundkenntnisse in Python oder einer anderen Programmiersprache
- VS Code mit einem geöffneten Projektverzeichnis

**Ziele**:
- Den Aufbau eines effektiven Prompts verstehen (Kontext, Aufgabe, Constraints, Format).
- Prompts iterativ verfeinern, wenn die erste Antwort nicht passt.
- Claude gezielt für Code-Review, Refaktorierung und Test-Generierung einsetzen.
- Häufige Fehler beim Prompting erkennen und vermeiden.

**Quellen**:
- Anthropic Prompt Engineering Guide: https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/overview
- VS Code Dokumentation: https://code.visualstudio.com/docs

---

## Grundlagen: Der Aufbau eines guten Prompts

### Die vier Bestandteile eines effektiven Prompts

```
[KONTEXT]    Wer bin ich, was ist das Projekt, welche Umgebung?
[AUFGABE]    Was genau soll Claude tun?
[CONSTRAINTS] Einschränkungen: Sprache, Bibliotheken, Stil, Performance
[FORMAT]     Wie soll die Antwort aussehen? (Code, Erklärung, Liste, ...)
```

**Schwacher Prompt** (zu vage):
```
Schreib mir eine Funktion für Dateien.
```

**Starker Prompt** (präzise):
```
Ich entwickle ein Python 3.12-Skript zur Logfile-Analyse auf Debian 12.
Schreibe eine Funktion read_log_lines(filepath: str, max_lines: int = 1000) -> list[str],
die eine Textdatei zeilenweise einliest, leere Zeilen überspringt und bei Datei-nicht-gefunden
eine sprechende FileNotFoundError-Message wirft.
Gib nur den Funktionscode mit Docstring zurück, kein Beispiel-Aufruf.
```

### Iteratives Prompting

Claude versteht den Gesprächskontext. Statt alles in einem Prompt zu packen, ist ein Dialog oft besser:

```
Schritt 1: "Erstelle eine Klasse UserManager für eine SQLite-Datenbank."
Schritt 2: "Ergänze eine Methode find_by_email(), die None zurückgibt wenn nicht gefunden."
Schritt 3: "Schreibe jetzt pytest-Tests für find_by_email() mit mindestens 3 Fällen."
```

---

## Übungen zum Verinnerlichen

### Übung 1: Prompt-Qualität vergleichen 🔍

**Ziel**: Den Unterschied zwischen schwachen und starken Prompts am eigenen Beispiel erleben.

1. **Schritt 1**: Sende diesen schwachen Prompt an Claude:
   ```
   Schreib mir eine Funktion die Passwörter prüft.
   ```
   Notiere, was Claude zurückgibt.

2. **Schritt 2**: Verbessere den Prompt mit allen vier Bestandteilen:
   ```
   Ich entwickle eine Python 3.12 Webanwendung mit Flask.
   Schreibe eine Funktion validate_password(password: str) -> tuple[bool, str],
   die folgende Regeln prüft:
   - Mindestlänge 10 Zeichen
   - Mindestens ein Großbuchstabe
   - Mindestens eine Zahl
   - Mindestens ein Sonderzeichen aus: !@#$%^&*
   Rückgabe: (True, "") wenn gültig, (False, "Fehlerbeschreibung") wenn ungültig.
   Keine externen Bibliotheken, nur Python-Standardbibliothek.
   ```

3. **Schritt 3**: Vergleiche beide Antworten.
   - Ist die zweite Funktion direkt verwendbar ohne Anpassungen?
   - Welche Entscheidungen musste Claude beim ersten Prompt selbst treffen?

**Reflexion**: Warum ist es wichtig, Constraints zu nennen (z. B. "keine externen Bibliotheken")? Was passiert, wenn man das weglässt?

---

### Übung 2: Code-Review mit Claude durchführen 🔎

**Ziel**: Claude als Review-Partner einsetzen und lernen, wie man gezieltes Feedback bekommt.

1. **Schritt 1**: Erstelle die Datei `data_processor.py`:
   ```python
   import json

   def process_data(filename):
       f = open(filename)
       data = json.load(f)
       results = []
       for i in range(len(data)):
           item = data[i]
           if item['status'] == 'active':
               results.append(item['name'].upper())
       f.close()
       return results

   r = process_data('users.json')
   print(r)
   ```

2. **Schritt 2**: Beantrage ein gezieltes Review:
   ```
   Reviewe data_processor.py hinsichtlich:
   1. Ressourcen-Management (Datei-Handling)
   2. Pythonic Code Style (PEP 8, idiomatische Konstrukte)
   3. Fehlerbehandlung (was passiert bei fehlender Datei oder falschem Format?)
   Zeige für jeden Punkt: Problem, Erklärung, verbesserte Version.
   ```

3. **Schritt 3**: Implementiere die Verbesserungen selbst (nicht copy-pasten) und erkläre in einem Kommentar über der Funktion, was geändert wurde.

4. **Schritt 4**: Frage Claude nach einer letzten Prüfung:
   ```
   Hier ist meine überarbeitete Version: [Code einfügen]
   Gibt es noch Verbesserungspotenzial?
   ```

**Reflexion**: Hätte ein menschlicher Code-Reviewer dieselben Punkte gefunden? Was sind die Grenzen von KI-basierten Reviews?

---

### Übung 3: Tests generieren und bewerten lassen 🧪

**Ziel**: Claude für die Test-Generierung nutzen und verstehen, wie man Testqualität bewertet.

1. **Schritt 1**: Erstelle `calculator.py`:
   ```python
   def divide(a: float, b: float) -> float:
       """Dividiert a durch b. Wirft ZeroDivisionError wenn b == 0."""
       if b == 0:
           raise ZeroDivisionError("Divisor darf nicht 0 sein.")
       return a / b

   def to_percentage(value: float, total: float) -> str:
       """Gibt den prozentualen Anteil als formatierten String zurück."""
       percent = (value / total) * 100
       return f"{percent:.1f}%"
   ```

2. **Schritt 2**: Tests anfordern – mit expliziten Anforderungen:
   ```
   Schreibe pytest-Tests für calculator.py.
   Anforderungen:
   - Mindestens 3 Testfälle pro Funktion
   - Teste Normalfall, Grenzfälle und Fehlerfälle
   - Nutze pytest.raises() für erwartete Exceptions
   - Keine Mocks nötig, alle Funktionen sind pure functions
   - Dateiname: test_calculator.py
   ```

3. **Schritt 3**: Tests ausführen:
   ```bash
   pip install pytest
   pytest test_calculator.py -v
   ```

4. **Schritt 4**: Claude fragen, welche Testfälle noch fehlen könnten:
   ```
   Welche Edge-Cases für to_percentage() hat der Test nicht abgedeckt?
   Zum Beispiel: was passiert bei total=0 oder negativen Werten?
   ```
   Ergänze die fehlenden Tests.

**Reflexion**: Sind alle generierten Tests sinnvoll? Gibt es Tests, die immer bestehen, egal ob die Funktion korrekt ist oder nicht (sogenannte "Tautologie-Tests")?

---

## Häufige Prompting-Fehler und wie man sie vermeidet

| Fehler | Beispiel | Besser |
|---|---|---|
| **Zu vage** | "Mach den Code besser" | "Refaktoriere für Lesbarkeit: sprechende Namen, max. 15 Zeilen pro Funktion" |
| **Kein Kontext** | "Wie fixe ich diesen Bug?" | "Python 3.12, Flask 3.x, Fehler tritt bei POST /api/users auf: ..." |
| **Zu viel auf einmal** | "Schreib die ganze App inkl. DB, API, Tests, Doku" | Aufgabe in Schritte aufteilen |
| **Blindes Vertrauen** | Generierter Code direkt deployen | Code verstehen, testen, reviewen |
| **Kein Format angegeben** | (Claude antwortet mit langer Erklärung + Code) | "Gib nur den Code zurück, keine Erklärung" |

---

## Fazit

Effektives Prompting ist eine erlernbare Fähigkeit. Mit den vier Bausteinen Kontext, Aufgabe, Constraints und Format sowie einem iterativen Dialog bekommt man von Claude genau die Unterstützung, die man braucht – ohne stundenlang Antworten nachzubearbeiten.

**Nächste Schritte**:
- **Modul 3**: Vollständiger Projektworkflow – ein reales Mini-Projekt von der Anforderung bis zum fertigen Code mit Claude als Pair-Programmer durchführen.
