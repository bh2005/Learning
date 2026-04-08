# Lernprojekt: Softwareentwicklung mit VS Code und Claude – Einstieg und Grundlagen

## Einführung

**Claude** (von Anthropic) ist ein KI-Assistent, der Entwickler beim Schreiben, Erklären, Debuggen und Refaktorieren von Code unterstützt. In Kombination mit **Visual Studio Code** entsteht eine leistungsstarke Entwicklungsumgebung, in der KI-Unterstützung direkt in den Arbeitsfluss integriert ist. Dieses Modul führt in die Grundlagen dieser Zusammenarbeit ein: Wie funktioniert Claude als Coding-Partner? Welche Aufgaben übernimmt er besonders gut? Und wie kommuniziert man effektiv mit ihm?

**Voraussetzungen**:
- Visual Studio Code installiert (aktuelle Version, [code.visualstudio.com](https://code.visualstudio.com/))
- Ein Anthropic-Konto oder Zugang zu Claude (z. B. über [claude.ai](https://claude.ai) oder Claude Code CLI)
- Grundkenntnisse in mindestens einer Programmiersprache (z. B. Python, JavaScript)
- Grundkenntnisse der Linux/Mac/Windows-Kommandozeile

**Ziele**:
- Verstehen, wie Claude als KI-Coding-Assistent funktioniert und wo seine Stärken liegen.
- Claude Code CLI in VS Code einrichten und erste Interaktionen durchführen.
- Den Unterschied zwischen Chat-basierter und kontextbasierter KI-Unterstützung kennenlernen.
- Grundlegende Aufgaben wie Code erklären, generieren und debuggen mit Claude durchführen.

**Hinweis**: Claude ist kein Ersatz für eigenes Verständnis, sondern ein Werkzeug, das Lernprozesse beschleunigt und repetitive Aufgaben automatisiert. Das kritische Überprüfen von KI-generierten Vorschlägen bleibt immer Aufgabe des Entwicklers.

**Quellen**:
- Anthropic Dokumentation: https://docs.anthropic.com
- Claude Code CLI: https://claude.ai/code
- VS Code Dokumentation: https://code.visualstudio.com/docs

---

## Grundlagen: Claude als Coding-Partner

### Was kann Claude in der Softwareentwicklung?

Claude unterstützt in allen Phasen des Entwicklungsprozesses:

| Aufgabe | Beschreibung |
|---|---|
| **Code generieren** | Funktionen, Klassen, Skripte auf Basis einer Beschreibung erstellen |
| **Code erklären** | Bestehenden Code Zeile für Zeile oder konzeptuell erläutern |
| **Debuggen** | Fehlermeldungen analysieren und Lösungen vorschlagen |
| **Refaktorieren** | Code lesbarer, effizienter oder testbarer umstrukturieren |
| **Tests schreiben** | Unit-Tests und Integrationstests für vorhandenen Code erstellen |
| **Dokumentation** | Docstrings, README-Dateien und Kommentare generieren |
| **Code reviewen** | Probleme, Sicherheitslücken und Verbesserungspotenzial identifizieren |

### Claude Code CLI – Überblick

**Claude Code** ist ein CLI-Tool (Command Line Interface), das Claude direkt im Terminal und in VS Code verfügbar macht. Es versteht den Kontext des gesamten Projekts (nicht nur einzelner Dateien) und kann Dateien lesen, bearbeiten und ausführen.

```bash
# Installation (Node.js >= 18 erforderlich)
npm install -g @anthropic-ai/claude-code

# Starten im Projektverzeichnis
claude
```

> ℹ️ **Claude Code vs. claude.ai**: Claude Code (CLI) hat direkten Zugriff auf das Dateisystem und Projektkontext. claude.ai (Webinterface) ist besser für isolierte Fragen ohne Projektbezug geeignet.

---

## Übungen zum Verinnerlichen

### Übung 1: Claude Code CLI einrichten und erste Interaktion 🔧

**Ziel**: Claude Code installieren, mit VS Code verbinden und eine erste Aufgabe stellen.

1. **Schritt 1**: Node.js prüfen und Claude Code installieren.
   ```bash
   node --version   # Muss >= 18.0.0 sein
   npm install -g @anthropic-ai/claude-code
   claude --version
   ```

2. **Schritt 2**: Ein Testprojekt anlegen und Claude starten.
   ```bash
   mkdir ~/claude-übung && cd ~/claude-übung
   echo "# Testprojekt" > README.md
   claude
   ```

3. **Schritt 3**: Claude eine einfache Aufgabe stellen.
   Tippe im Claude-Prompt:
   ```
   Erstelle eine Python-Datei hello.py, die "Hallo, Welt!" ausgibt und schreibe einen Kommentar dazu.
   ```
   Claude liest den Projektkontext, schlägt die Datei vor und erstellt sie nach Bestätigung.

4. **Schritt 4**: Die erstellte Datei in VS Code öffnen und prüfen.
   ```bash
   code hello.py
   python hello.py
   ```

**Reflexion**: Was hat Claude eigenständig entschieden (z. B. Dateiname, Kommentar-Stil)? Wo hättest du andere Entscheidungen getroffen?

---

### Übung 2: Bestehenden Code erklären lassen 📖

**Ziel**: Lernen, wie man Claude nutzt, um unbekannten Code schnell zu verstehen.

1. **Schritt 1**: Eine Python-Datei mit unbekanntem Code anlegen.
   Erstelle `mystery.py` mit folgendem Inhalt:
   ```python
   def flatten(lst):
       result = []
       for item in lst:
           if isinstance(item, list):
               result.extend(flatten(item))
           else:
               result.append(item)
       return result

   print(flatten([1, [2, [3, 4], 5], [6, 7]]))
   ```

2. **Schritt 2**: Claude um eine Erklärung bitten.
   Im Claude-Prompt (oder claude.ai):
   ```
   Erkläre mir die Funktion in mystery.py Schritt für Schritt.
   Was ist das Konzept dahinter und wie heißt es?
   ```

3. **Schritt 3**: Tiefer nachfragen.
   ```
   Welche Eingaben würden zu einem Fehler führen?
   Wie könnte man die Funktion mit einem Typ-Hint versehen?
   ```

4. **Schritt 4**: Das Erklärte selbst zusammenfassen – ohne Claude – in einem Kommentar über der Funktion.

**Reflexion**: Hat Claudes Erklärung etwas enthalten, das du nicht erwartet hättest? Wo war die Erklärung zu ausführlich oder zu knapp?

---

### Übung 3: Eine Fehlermeldung debuggen 🐛

**Ziel**: Claude als Debugging-Partner einsetzen und verstehen, wie man Fehlerkontext effektiv übermittelt.

1. **Schritt 1**: Eine Datei mit einem bewussten Fehler erstellen (`buggy.py`):
   ```python
   def berechne_durchschnitt(zahlen):
       summe = sum(zahlen)
       return summe / len(zahlen)

   daten = [10, 20, 30]
   print(berechne_durchschnitt(daten))
   print(berechne_durchschnitt([]))   # Dieser Aufruf verursacht einen Fehler
   ```

2. **Schritt 2**: Die Datei ausführen und den Fehler notieren.
   ```bash
   python buggy.py
   ```
   Erwartete Ausgabe:
   ```
   ZeroDivisionError: division by zero
   ```

3. **Schritt 3**: Fehler und Kontext an Claude übergeben.
   ```
   Ich bekomme folgenden Fehler in buggy.py:
   ZeroDivisionError: division by zero
   Wie kann ich die Funktion absichern, ohne ihr Verhalten für normale Eingaben zu ändern?
   ```

4. **Schritt 4**: Claudes Vorschlag verstehen, dann selbst implementieren (nicht copy-pasten) und testen.

**Reflexion**: Hat Claude die beste Lösung vorgeschlagen? Gibt es Alternativen (z. B. Exception werfen statt 0 zurückgeben)? Was wäre in einem Produktionssystem sinnvoller?

---

## Fazit

Claude in VS Code ist ein vielseitiger Assistent, der in alle Phasen der Softwareentwicklung eingreift. Der Schlüssel zur effektiven Nutzung liegt in klaren, kontextreichen Anfragen und dem kritischen Hinterfragen der Antworten.

**Nächste Schritte**:
- **Modul 2**: Effektives Prompting für Entwicklungsaufgaben – wie formuliere ich Anfragen präzise?
- **Modul 3**: Vollständiger Projektworkflow – ein echtes Mini-Projekt mit Claude als Pair-Programmer umsetzen.
