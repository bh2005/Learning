# Praxisorientierte Anleitung: Funktionen und Fehlerbehandlung in Python-Skripten

## Einführung
Funktionen in Python sind ein zentraler Baustein, um Code modular, wiederverwendbar und lesbar zu gestalten. Fehlerbehandlung ist essenziell, um robuste Skripte zu schreiben, die unerwartete Situationen (z. B. ungültige Eingaben, fehlende Dateien) graceful handhaben. Diese Anleitung führt Anfänger durch praktische Übungen zur **Definition und Nutzung von Funktionen**, **Parameterübergabe**, **Rückgabewerten**, **Fehlerbehandlung mit try-except**, **benutzerdefinierten Ausnahmen** und **Logging**. Die Übungen verwenden einen simulierten Datensatz (JSON-Format, ähnlich den vorherigen Big-Data-Übungen) für praktische Beispiele. Eine **Spielerei** zeigt, wie du Funktionen und Fehlerbehandlung kombinierst, um Daten zu analysieren und Ergebnisse in Markdown zu dokumentieren. Die Übungen sind auf einem Debian-basierten System ausführbar und für Nutzer mit grundlegenden Kenntnissen in Python geeignet.

**Voraussetzungen**:
- Ein Debian-basiertes System (z. B. Ubuntu 22.04, Debian 11); Windows-Nutzer können WSL2 verwenden; macOS ist kompatibel.
- Ein Terminal (z. B. Bash unter Linux).
- Installierte Tools:
  - Python 3 und `pip`: `sudo apt install python3 python3-pip`
  - Optional: `pandas` für Datenanalyse: `pip install pandas`
- Grundkenntnisse in Python (Variablen, Schleifen, Datei-Ein-/Ausgabe).
- Sichere Testumgebung (z. B. `$HOME/python_functions` oder `~/python_functions`).

## Grundlegende Konzepte und Befehle
Hier sind die wichtigsten Python-Konzepte und Befehle für die Übungen:

1. **Funktionen in Python**:
   - `def function_name(parameters)`: Definiert eine Funktion.
   - `return value`: Gibt einen Wert zurück.
   - `*args`, `**kwargs`: Ermöglicht flexible Parameterübergabe.
2. **Fehlerbehandlung**:
   - `try-except`: Fängt und behandelt Ausnahmen.
   - `raise Exception`: Löst eine benutzerdefinierte Ausnahme aus.
   - `logging`: Protokolliert Fehler und Informationen.
3. **Dateioperationen**:
   - `open(<Datei>, 'r')`: Liest eine Datei.
   - `json.load()`: Lädt JSON-Daten.
4. **Nützliche Zusatzbefehle**:
   - `man python3`: Dokumentation für Python.
   - `pip install pandas`: Installiert Pandas für Datenanalyse.
   - `echo` (Bash): Fügt Zeitstempel in Protokollen hinzu.

## Beispiel-Datensatz
Für die Übungen erstellen wir eine kleine JSON-Datei `sample_data.json` mit Log-Einträgen, ähnlich den vorherigen Big-Data-Übungen:
```json
[
    {"timestamp": 1725532080, "user_id": 1, "event": "LOGIN"},
    {"timestamp": 1725532081, "user_id": 2, "event": "ERROR"},
    {"timestamp": 1725532082, "user_id": 1, "event": "VIEW_PAGE"},
    {"timestamp": 1725532083, "user_id": 3, "event": "PURCHASE"},
    {"timestamp": 1725532084, "user_id": 2, "event": "LOGOUT"}
]
```

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Vorbereitung und Datensatz erstellen
**Ziel**: Erstelle eine Testumgebung und eine JSON-Datei mit simulierten Daten.

1. **Schritt 1**: Erstelle ein Testverzeichnis:
   ```bash
   mkdir python_functions
   cd python_functions
   ```

2. **Schritt 2**: Erstelle ein Skript zur Datengenerierung:
   ```bash
   nano generate_data.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import json

   data = [
       {"timestamp": 1725532080, "user_id": 1, "event": "LOGIN"},
       {"timestamp": 1725532081, "user_id": 2, "event": "ERROR"},
       {"timestamp": 1725532082, "user_id": 1, "event": "VIEW_PAGE"},
       {"timestamp": 1725532083, "user_id": 3, "event": "PURCHASE"},
       {"timestamp": 1725532084, "user_id": 2, "event": "LOGOUT"}
   ]

   with open("sample_data.json", "w") as f:
       json.dump(data, f, indent=4)

   print("Datensatz erstellt: sample_data.json")
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   python3 generate_data.py
   ```

4. **Schritt 4**: Überprüfe die Datei:
   ```bash
   cat sample_data.json
   ```

5. **Schritt 5**: Protokolliere die Erstellung:
   ```bash
   echo "Datensatz erstellt am $(date)" > functions_log.txt
   ls -lh sample_data.json >> functions_log.txt
   cat functions_log.txt
   ```

**Reflexion**: Warum ist ein simulierter Datensatz für Übungen nützlich? Nutze `man cat` und überlege, wie du größere Datensätze erstellst.

### Übung 2: Funktionen definieren und nutzen
**Ziel**: Definiere Funktionen zur Datenanalyse und wende sie auf den Datensatz an.

1. **Schritt 1**: Erstelle ein Skript mit Funktionen zur Analyse:
   ```bash
   nano analyze_functions.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import json

   def load_data(file_path):
       """Läd JSON-Daten aus einer Datei."""
       with open(file_path, 'r') as f:
           return json.load(f)

   def count_events(data, event_type=None):
       """Zählt Ereignisse, optional gefiltert nach Typ."""
       if event_type:
           return sum(1 for entry in data if entry["event"] == event_type)
       return len(data)

   def get_user_events(data, user_id):
       """Gibt Ereignisse für einen bestimmten Benutzer zurück."""
       return [entry["event"] for entry in data if entry["user_id"] == user_id]

   # Hauptprogramm
   if __name__ == "__main__":
       data = load_data("sample_data.json")
       total_events = count_events(data)
       error_count = count_events(data, "ERROR")
       user_1_events = get_user_events(data, 1)

       print(f"Gesamtereignisse: {total_events}")
       print(f"Fehlerereignisse: {error_count}")
       print(f"Ereignisse für User 1: {user_1_events}")
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   python3 analyze_functions.py > analyze_output.txt
   ```

3. **Schritt 3**: Protokolliere die Ergebnisse:
   ```bash
   echo "Funktionenanalyse am $(date)" >> functions_log.txt
   cat analyze_output.txt >> functions_log.txt
   cat functions_log.txt
   ```
   **Beispielausgabe**:
   ```
   Gesamtereignisse: 5
   Fehlerereignisse: 1
   Ereignisse für User 1: ['LOGIN', 'VIEW_PAGE']
   ```

**Reflexion**: Wie verbessern Funktionen die Lesbarkeit und Wiederverwendbarkeit? Nutze die Python-Dokumentation (`help`) und überlege, wie du weitere Funktionen (z. B. für Zeitstempel) hinzufügst.

### Übung 3: Fehlerbehandlung mit try-except
**Ziel**: Ergänze Fehlerbehandlung, um Dateizugriffe und ungültige Eingaben abzusichern.

1. **Schritt 1**: Aktualisiere das Skript mit Fehlerbehandlung:
   ```bash
   nano analyze_functions_safe.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import json

   def load_data(file_path):
       """Läd JSON-Daten aus einer Datei mit Fehlerbehandlung."""
       try:
           with open(file_path, 'r') as f:
               return json.load(f)
       except FileNotFoundError:
           print(f"Fehler: Datei {file_path} nicht gefunden.")
           return []
       except json.JSONDecodeError:
           print(f"Fehler: Ungültiges JSON-Format in {file_path}.")
           return []

   def count_events(data, event_type=None):
       """Zählt Ereignisse, optional gefiltert nach Typ."""
       try:
           if not isinstance(data, list):
               raise ValueError("Daten müssen eine Liste sein.")
           if event_type:
               return sum(1 for entry in data if entry["event"] == event_type)
           return len(data)
       except KeyError:
           print("Fehler: Ungültiges Datenformat (fehlender 'event'-Schlüssel).")
           return 0

   def get_user_events(data, user_id):
       """Gibt Ereignisse für einen bestimmten Benutzer zurück."""
       try:
           if not isinstance(user_id, int):
               raise ValueError("User ID muss eine Ganzzahl sein.")
           return [entry["event"] for entry in data if entry["user_id"] == user_id]
       except KeyError:
           print("Fehler: Ungültiges Datenformat (fehlender 'user_id'-Schlüssel).")
           return []

   # Hauptprogramm
   if __name__ == "__main__":
       data = load_data("sample_data.json")
       if data:
           total_events = count_events(data)
           error_count = count_events(data, "ERROR")
           user_1_events = get_user_events(data, 1)
           print(f"Gesamtereignisse: {total_events}")
           print(f"Fehlerereignisse: {error_count}")
           print(f"Ereignisse für User 1: {user_1_events}")
       else:
           print("Analyse abgebrochen wegen fehlerhafter Daten.")
   ```
   Speichere und schließe.

2. **Schritt 2**: Teste die Fehlerbehandlung:
   ```bash
   mv sample_data.json sample_data.json.bak
   python3 analyze_functions_safe.py > analyze_safe_output.txt
   mv sample_data.json.bak sample_data.json
   ```

3. **Schritt 3**: Protokolliere die Ergebnisse:
   ```bash
   echo "Fehlerbehandlungsanalyse am $(date)" >> functions_log.txt
   cat analyze_safe_output.txt >> functions_log.txt
   cat functions_log.txt
   ```
   **Beispielausgabe** (bei fehlender Datei):
   ```
   Fehler: Datei sample_data.json nicht gefunden.
   Analyse abgebrochen wegen fehlerhafter Daten.
   ```

**Reflexion**: Wie macht Fehlerbehandlung Skripte robuster? Nutze die Python-Dokumentation (`help(Exception)`) und überlege, wie du weitere Ausnahmen behandelst.

### Übung 4: Benutzerdefinierte Ausnahmen und Logging
**Ziel**: Implementiere benutzerdefinierte Ausnahmen und protokolliere Fehler mit `logging`.

1. **Schritt 1**: Erstelle ein Skript mit benutzerdefinierten Ausnahmen und Logging:
   ```bash
   nano analyze_functions_logging.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import json
   import logging

   # Konfiguriere Logging
   logging.basicConfig(
       filename="analysis.log",
       level=logging.INFO,
       format="%(asctime)s - %(levelname)s - %(message)s"
   )

   class DataFormatError(Exception):
       """Benutzerdefinierte Ausnahme für ungültige Datenformate."""
       pass

   def load_data(file_path):
       """Läd JSON-Daten aus einer Datei mit Fehlerbehandlung."""
       try:
           with open(file_path, 'r') as f:
               data = json.load(f)
               if not isinstance(data, list):
                   raise DataFormatError("Daten müssen eine Liste sein.")
               return data
       except FileNotFoundError:
           logging.error(f"Datei {file_path} nicht gefunden.")
           return []
       except json.JSONDecodeError:
           logging.error(f"Ungültiges JSON-Format in {file_path}.")
           return []
       except DataFormatError as e:
           logging.error(f"Formatfehler: {e}")
           return []

   def count_events(data, event_type=None):
       """Zählt Ereignisse, optional gefiltert nach Typ."""
       try:
           if event_type:
               return sum(1 for entry in data if entry["event"] == event_type)
           return len(data)
       except KeyError:
           logging.error("Ungültiges Datenformat (fehlender 'event'-Schlüssel).")
           return 0

   def get_user_events(data, user_id):
       """Gibt Ereignisse für einen bestimmten Benutzer zurück."""
       try:
           if not isinstance(user_id, int):
               raise ValueError("User ID muss eine Ganzzahl sein.")
           return [entry["event"] for entry in data if entry["user_id"] == user_id]
       except KeyError:
           logging.error("Ungültiges Datenformat (fehlender 'user_id'-Schlüssel).")
           return []
       except ValueError as e:
           logging.error(f"Eingabefehler: {e}")
           return []

   # Hauptprogramm
   if __name__ == "__main__":
       logging.info("Starte Analyse.")
       data = load_data("sample_data.json")
       if data:
           total_events = count_events(data)
           error_count = count_events(data, "ERROR")
           user_1_events = get_user_events(data, 1)
           logging.info(f"Gesamtereignisse: {total_events}")
           logging.info(f"Fehlerereignisse: {error_count}")
           logging.info(f"Ereignisse für User 1: {user_1_events}")
           print(f"Gesamtereignisse: {total_events}")
           print(f"Fehlerereignisse: {error_count}")
           print(f"Ereignisse für User 1: {user_1_events}")
       else:
           logging.warning("Analyse abgebrochen wegen fehlerhafter Daten.")
           print("Analyse abgebrochen.")
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   python3 analyze_functions_logging.py > analyze_logging_output.txt
   ```

3. **Schritt 3**: Überprüfe das Log:
   ```bash
   cat analysis.log
   ```

4. **Schritt 4**: Protokolliere die Ergebnisse:
   ```bash
   echo "Logging-Analyse am $(date)" >> functions_log.txt
   cat analyze_logging_output.txt >> functions_log.txt
   cat functions_log.txt
   ```

**Reflexion**: Wie verbessert Logging die Nachvollziehbarkeit? Nutze die Python-Dokumentation (`help(logging)`) und überlege, wie du Log-Level anpasst.

### Übung 5: Spielerei – Markdown-Bericht mit Funktionen und Fehlerbehandlung
**Ziel**: Erstelle ein Markdown-Dokument mit Analyseergebnissen, das Funktionen und Fehlerbehandlung nutzt.

1. **Schritt 1**: Erstelle ein Skript für die Markdown-Ausgabe:
   ```bash
   nano summary_functions.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import json
   import logging
   from datetime import datetime

   # Konfiguriere Logging
   logging.basicConfig(
       filename="analysis.log",
       level=logging.INFO,
       format="%(asctime)s - %(levelname)s - %(message)s"
   )

   class DataFormatError(Exception):
       """Benutzerdefinierte Ausnahme für ungültige Datenformate."""
       pass

   def load_data(file_path):
       """Läd JSON-Daten aus einer Datei mit Fehlerbehandlung."""
       try:
           with open(file_path, 'r') as f:
               data = json.load(f)
               if not isinstance(data, list):
                   raise DataFormatError("Daten müssen eine Liste sein.")
               return data
       except FileNotFoundError:
           logging.error(f"Datei {file_path} nicht gefunden.")
           return []
       except json.JSONDecodeError:
           logging.error(f"Ungültiges JSON-Format in {file_path}.")
           return []
       except DataFormatError as e:
           logging.error(f"Formatfehler: {e}")
           return []

   def count_events(data, event_type=None):
       """Zählt Ereignisse, optional gefiltert nach Typ."""
       try:
           if event_type:
               return sum(1 for entry in data if entry["event"] == event_type)
           return len(data)
       except KeyError:
           logging.error("Ungültiges Datenformat (fehlender 'event'-Schlüssel).")
           return 0

   def get_user_events(data, user_id):
       """Gibt Ereignisse für einen bestimmten Benutzer zurück."""
       try:
           if not isinstance(user_id, int):
               raise ValueError("User ID muss eine Ganzzahl sein.")
           return [entry["event"] for entry in data if entry["user_id"] == user_id]
       except KeyError:
           logging.error("Ungültiges Datenformat (fehlender 'user_id'-Schlüssel).")
           return []
       except ValueError as e:
           logging.error(f"Eingabefehler: {e}")
           return []

   def generate_markdown_report(data, output_file):
       """Erstellt einen Markdown-Bericht mit Analyseergebnissen."""
       try:
           total_events = count_events(data)
           error_count = count_events(data, "ERROR")
           user_ids = set(entry["user_id"] for entry in data)
           user_event_summary = {uid: get_user_events(data, uid) for uid in user_ids}

           with open(output_file, "w") as f:
               f.write("# Datenanalyse-Bericht\n")
               f.write(f"Erstellt am: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
               f.write("## Analyseergebnisse\n")
               f.write("| Metrik | Wert |\n")
               f.write("|--------|------|\n")
               f.write(f"| Gesamtereignisse | {total_events} |\n")
               f.write(f"| Fehlerereignisse | {error_count} |\n")
               f.write("\n## Ereignisse pro Benutzer\n")
               f.write("| User ID | Ereignisse |\n")
               f.write("|---------|------------|\n")
               for uid, events in user_event_summary.items():
                   f.write(f"| {uid} | {', '.join(events)} |\n")

           logging.info(f"Markdown-Bericht erstellt: {output_file}")
       except Exception as e:
           logging.error(f"Fehler beim Erstellen des Berichts: {e}")
           print(f"Fehler beim Erstellen des Berichts: {e}")

   # Hauptprogramm
   if __name__ == "__main__":
       logging.info("Starte Analyse und Berichtserstellung.")
       data = load_data("sample_data.json")
       if data:
           generate_markdown_report(data, "analysis_report.md")
           print("Bericht erstellt: analysis_report.md")
       else:
           logging.warning("Analyse abgebrochen wegen fehlerhafter Daten.")
           print("Analyse abgebrochen.")
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   python3 summary_functions.py
   ```

3. **Schritt 3**: Überprüfe den Bericht:
   ```bash
   cat analysis_report.md
   ```
   **Beispielausgabe** (`analysis_report.md`):
   ```
   # Datenanalyse-Bericht
   Erstellt am: 2025-09-05 13:05:00

   ## Analyseergebnisse
   | Metrik | Wert |
   |--------|------|
   | Gesamtereignisse | 5 |
   | Fehlerereignisse | 1 |

   ## Ereignisse pro Benutzer
   | User ID | Ereignisse |
   |---------|------------|
   | 1 | LOGIN, VIEW_PAGE |
   | 2 | ERROR, LOGOUT |
   | 3 | PURCHASE |
   ```

4. **Schritt 4**: Protokolliere die Ergebnisse:
   ```bash
   echo "Markdown-Bericht erstellt am $(date)" >> functions_log.txt
   cat analysis_report.md >> functions_log.txt
   cat functions_log.txt
   ```

**Reflexion**: Wie verbessert die Kombination von Funktionen, Fehlerbehandlung und Markdown die Dokumentation? Nutze die Python-Dokumentation und überlege, wie du Visualisierungen hinzufügst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Funktionen und Fehlerbehandlung zu verinnerlichen.
- **Sicheres Testen**: Arbeite in einer Testumgebung und sichere Dateien (`cp sample_data.json sample_data.json.bak`).
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze die Python-Dokumentation (`help(Exception)`, `help(logging)`).
- **Effiziente Entwicklung**: Nutze Funktionen für Modularität, `try-except` für Robustheit und `logging` für Nachvollziehbarkeit.
- **Kombiniere Tools**: Integriere `pandas` für erweiterte Analysen oder `matplotlib` für Visualisierungen.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Hinzufügen von Visualisierungen oder E-Mail-Versand.

## Fazit
Mit diesen Übungen hast du gelernt, Funktionen in Python zu definieren und zu nutzen, Fehler mit `try-except` und benutzerdefinierten Ausnahmen zu behandeln, Logging für Nachvollziehbarkeit einzusetzen und Ergebnisse in Markdown zu dokumentieren. Die Spielerei zeigt, wie du diese Konzepte kombinierst, um einen robusten Analyse-Skript zu erstellen. Vertiefe dein Wissen, indem du fortgeschrittene Themen (z. B. dekorierte Funktionen, fortgeschrittene Logging-Formate) oder Tools wie `pandas` oder `matplotlib` ausprobierst. Wenn du ein spezifisches Thema (z. B. Visualisierung oder Datenbank-Integration) vertiefen möchtest, lass es mich wissen!
