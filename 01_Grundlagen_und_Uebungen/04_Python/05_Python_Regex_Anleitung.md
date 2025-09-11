# Praxisorientierte Anleitung: Reguläre Ausdrücke (Regex) in Python – Grundlagen und Fortgeschrittene Konzepte

## Einführung
Reguläre Ausdrücke (Regex) sind ein mächtiges Werkzeug zur Mustererkennung und Textverarbeitung in Python. Diese Anleitung deckt **Grundlegende Regex-Muster und -Methoden**, **Anwendung in realen Szenarien (z. B. Log-Parsing)** und **fortgeschrittene Optimierungen (z. B. Performance, benannte Gruppen, Lookaheads)** ab. Eine **Spielerei** zeigt, wie du eine Klasse erstellst, die Log-Dateien mit optimierten Regex parsed und die Ergebnisse in eine Markdown-Tabelle umwandelt, um eine Verbindung zu vorherigen Themen (z. B. Verzeichnisstruktur) herzustellen. Durch praktische Übungen lernst du, Regex zu schreiben, anzuwenden und zu optimieren, sowohl für einfache als auch komplexe Szenarien.

**Voraussetzungen**:
- Ein System mit Windows, macOS oder Linux (z. B. Windows 11, Ubuntu 22.04, macOS Ventura).
- Ein Terminal (PowerShell für Windows, Terminal für macOS/Linux).
- Python 3 installiert (prüfe mit `python3 --version`; installiere via `choco install python` auf Windows, `sudo apt install python3` auf Ubuntu oder `brew install python3` auf macOS).
- Grundkenntnisse in Python (Variablen, Schleifen, Datei-Ein-/Ausgabe).
- Sichere Testumgebung (z. B. `$HOME/regex_test` oder `~/regex_test`).

## Grundlegende Befehle
Hier sind die wichtigsten Regex-Konzepte und Python-Befehle, aufgeteilt nach den Hauptthemen:

1. **Grundlegende Regex-Muster und -Methoden**:
   - `import re`: Importiert das Regex-Modul.
   - `re.search(pattern, string)`: Findet das erste Vorkommen eines Musters.
   - `re.findall(pattern, string)`: Findet alle Vorkommen eines Musters.
   - `re.match(pattern, string)`: Prüft, ob ein Muster am Anfang des Strings passt.
   - Grundlegende Muster:
     - `.`: Beliebiger Charakter (außer Zeilenumbruch).
     - `\d`: Ziffer (0-9).
     - `\w`: Wortzeichen (a-z, A-Z, 0-9, _).
     - `*`: 0 oder mehr Vorkommen.
     - `+`: 1 oder mehr Vorkommen.
     - `?`: 0 oder 1 Vorkommen.
2. **Anwendung in realen Szenarien (Log-Parsing)**:
   - `re.compile()`: Kompiliert Regex für bessere Performance.
   - `re.split()`: Teilt Strings basierend auf einem Muster.
   - `re.sub()`: Ersetzt gefundene Muster durch Text.
3. **Fortgeschrittene Optimierungen**:
   - `re.VERBOSE`: Ermöglicht lesbare Regex mit Kommentaren.
   - `(?<name>...)`: Benannte Gruppen für klareres Parsing.
   - `(?=...)`, `(?!...)`: Positive/negative Lookaheads für komplexe Bedingungen.
4. **Nützliche Zusatzbefehle**:
   - `python3 script.py`: Führt ein Python-Skript aus.
   - `dir(re)`: Zeigt Regex-Methoden.
   - `help(re.search)`: Zeigt Dokumentation zu Regex-Funktionen.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Grundlegende Regex-Muster und -Methoden
**Ziel**: Erstelle ein Skript, das grundlegende Regex-Muster verwendet, um E-Mails und URLs aus Text zu extrahieren.

1. **Schritt 1**: Erstelle ein Projektverzeichnis:
   ```bash
   mkdir regex_test
   cd regex_test
   ```

2. **Schritt 2**: Erstelle eine Textdatei mit Testdaten:
   ```bash
   nano sample.txt
   ```
   Füge folgenden Inhalt ein:
   ```
   Kontaktieren Sie uns unter anna@example.com oder besuchen Sie https://example.com.
   Weitere Infos bei ben@example.org und http://test-site.de.
   Fehlerhafte E-Mail: invalid.email@com
   ```
   Speichere und schließe.

3. **Schritt 3**: Erstelle ein Skript zum Extrahieren von E-Mails und URLs:
   ```bash
   nano extract_basic.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import re

   def extract_emails_and_urls(file_path="sample.txt"):
       """Extrahiert E-Mails und URLs aus einer Textdatei."""
       email_pattern = r'\b[\w.-]+@[\w.-]+\.\w+\b'  # Grundlegendes E-Mail-Muster
       url_pattern = r'https?://[\w.-]+\.\w+'       # Grundlegendes URL-Muster
       emails = []
       urls = []
       with open(file_path, 'r') as f:
           text = f.read()
           emails = re.findall(email_pattern, text)
           urls = re.findall(url_pattern, text)
       return emails, urls

   if __name__ == "__main__":
       emails, urls = extract_emails_and_urls()
       print("Gefundene E-Mails:", emails)
       print("Gefundene URLs:", urls)
   ```
   Speichere und schließe.

4. **Schritt 4**: Führe das Skript aus:
   ```bash
   python3 extract_basic.py
   ```
   Die Ausgabe sollte so aussehen:
   ```
   Gefundene E-Mails: ['anna@example.com', 'ben@example.org']
   Gefundene URLs: ['https://example.com', 'http://test-site.de']
   ```

**Reflexion**: Warum filtert das E-Mail-Muster `invalid.email@com` heraus? Nutze `help(re.findall)` und überlege, wie du das Muster für komplexere E-Mails (z. B. mit Subdomains) verbessern kannst.

### Übung 2: Anwendung in realen Szenarien (Log-Parsing)
**Ziel**: Parse eine Log-Datei mit Regex, um Fehler und Warnungen zu extrahieren.

1. **Schritt 1**: Erstelle eine Log-Datei:
   ```bash
   nano server.log
   ```
   Füge folgenden Inhalt ein:
   ```
   2025-09-04 10:00:01 INFO Server started
   2025-09-04 10:01:15 ERROR Failed to connect to database
   2025-09-04 10:02:30 WARNING Low memory detected
   2025-09-04 10:03:45 ERROR Timeout in API request
   2025-09-04 10:04:00 INFO Server running
   ```
   Speichere und schließe.

2. **Schritt 2**: Erstelle ein Skript zum Parsen der Log-Datei:
   ```bash
   nano log_parser.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import re

   def parse_log(file_path="server.log"):
       """Parst Log-Datei nach ERROR- und WARNING-Einträgen."""
       pattern = re.compile(r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) (ERROR|WARNING) (.*)')
       results = []
       with open(file_path, 'r') as f:
           for line in f:
               match = pattern.search(line)
               if match:
                   results.append({
                       "timestamp": match.group(1),
                       "level": match.group(2),
                       "message": match.group(3)
                   })
       return results

   if __name__ == "__main__":
       logs = parse_log()
       print("Gefundene Log-Einträge:")
       for log in logs:
           print(f"{log['timestamp']} [{log['level']}]: {log['message']}")
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   python3 log_parser.py
   ```
   Die Ausgabe sollte so aussehen:
   ```
   Gefundene Log-Einträge:
   2025-09-04 10:01:15 [ERROR]: Failed to connect to database
   2025-09-04 10:02:30 [WARNING]: Low memory detected
   2025-09-04 10:03:45 [ERROR]: Timeout in API request
   ```

**Reflexion**: Wie verbessert `re.compile()` die Lesbarkeit und Wiederverwendbarkeit? Nutze `help(re.search)` und überlege, wie du `re.sub()` für Log-Bereinigung einsetzen kannst.

### Übung 3: Fortgeschrittene Optimierungen und Spielerei
**Ziel**: Nutze fortgeschrittene Regex-Techniken (z. B. benannte Gruppen, Lookaheads) und erstelle eine Klasse, die Log-Daten parsed und in eine Markdown-Tabelle umwandelt.

1. **Schritt 1**: Erweitere die Log-Datei:
   ```bash
   nano server.log
   ```
   Ersetze den Inhalt durch:
   ```
   2025-09-04 10:00:01 INFO Server started
   2025-09-04 10:01:15 ERROR Failed to connect to database (code: 500)
   2025-09-04 10:02:30 WARNING Low memory detected (code: 301)
   2025-09-04 10:03:45 ERROR Timeout in API request (code: 408)
   2025-09-04 10:04:00 INFO Server running
   2025-09-04 10:05:22 ERROR Invalid user input (code: 400)
   ```
   Speichere und schließe.

2. **Schritt 2**: Erstelle ein Skript mit einer Klasse für optimiertes Parsing:
   ```bash
   nano advanced_log_parser.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import re

   class AdvancedLogParser:
       def __init__(self, log_file="server.log"):
           self.log_file = log_file
           self.pattern = re.compile(
               r"""
               (?P<timestamp>\d{4}-\d{2}-\d{2}\ \d{2}:\d{2}:\d{2})\  # Datum und Uhrzeit
               (?P<level>ERROR|WARNING)\                        # Log-Level
               (?P<message>.*?)\                                # Nachricht
               (?:\ \(code:\ (?P<code>\d+)\))?$                 # Optionaler Code
               """,
               re.VERBOSE
           )
           self.results = []

       def parse(self):
           """Parst Log-Datei mit optimiertem Regex."""
           with open(self.log_file, 'r') as f:
               for line in f:
                   match = self.pattern.match(line)
                   if match and match.group('level') in ['ERROR', 'WARNING']:
                       self.results.append({
                           "timestamp": match.group('timestamp'),
                           "level": match.group('level'),
                           "message": match.group('message'),
                           "code": match.group('code') if match.group('code') else 'N/A'
                       })
           return self.results

       def to_markdown(self, output_file="log_summary.md"):
           """Speichert Ergebnisse als Markdown-Tabelle."""
           if not self.results:
               return "Keine Daten vorhanden."
           header = "| Timestamp | Level | Message | Code |\n|----------|-------|---------|------|\n"
           rows = [f"| {r['timestamp']} | {r['level']} | {r['message']} | {r['code']} |" 
                   for r in self.results]
           markdown = header + "\n".join(rows)
           with open(output_file, 'w') as f:
               f.write("# Log-Zusammenfassung\n\n" + markdown)
           return markdown

   if __name__ == "__main__":
       parser = AdvancedLogParser()
       parser.parse()
       print("Gefundene Log-Einträge:")
       for result in parser.results:
           print(f"{result['timestamp']} [{result['level']}]: {result['message']} (Code: {result['code']})")
       print("\nMarkdown-Tabelle:")
       print(parser.to_markdown())
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   python3 advanced_log_parser.py
   ```
   Die Ausgabe sollte so aussehen:
   ```
   Gefundene Log-Einträge:
   2025-09-04 10:01:15 [ERROR]: Failed to connect to database (Code: 500)
   2025-09-04 10:02:30 [WARNING]: Low memory detected (Code: 301)
   2025-09-04 10:03:45 [ERROR]: Timeout in API request (Code: 408)
   2025-09-04 10:05:22 [ERROR]: Invalid user input (Code: 400)

   Markdown-Tabelle:
   | Timestamp | Level | Message | Code |
   |----------|-------|---------|------|
   | 2025-09-04 10:01:15 | ERROR | Failed to connect to database | 500 |
   | 2025-09-04 10:02:30 | WARNING | Low memory detected | 301 |
   | 2025-09-04 10:03:45 | ERROR | Timeout in API request | 408 |
   | 2025-09-04 10:05:22 | ERROR | Invalid user input | 400 |
   ```

4. **Spielerei**: Erweitere die Klasse mit einem Lookahead, um nur Fehler mit bestimmten Codes zu filtern:
   ```bash
   nano advanced_log_parser.py
   ```
   Ändere die `pattern`-Definition in der `AdvancedLogParser`-Klasse zu:
   ```python
           self.pattern = re.compile(
               r"""
               (?P<timestamp>\d{4}-\d{2}-\d{2}\ \d{2}:\d{2}:\d{2})\  # Datum und Uhrzeit
               (?P<level>ERROR|WARNING)\                        # Log-Level
               (?P<message>.*?)\                                # Nachricht
               (?=\ \(code:\ (?:500|408)\))                     # Lookahead für Code 500 oder 408
               \ \(code:\ (?P<code>\d+)\)$                      # Code
               """,
               re.VERBOSE
           )
   ```
   Speichere und schließe.

5. **Schritt 4**: Führe das Skript erneut aus:
   ```bash
   python3 advanced_log_parser.py
   ```
   Die Ausgabe sollte nur Fehler mit den Codes 500 und 408 anzeigen:
   ```
   Gefundene Log-Einträge:
   2025-09-04 10:01:15 [ERROR]: Failed to connect to database (Code: 500)
   2025-09-04 10:03:45 [ERROR]: Timeout in API request (Code: 408)

   Markdown-Tabelle:
   | Timestamp | Level | Message | Code |
   |----------|-------|---------|------|
   | 2025-09-04 10:01:15 | ERROR | Failed to connect to database | 500 |
   | 2025-09-04 10:03:45 | ERROR | Timeout in API request | 408 |
   ```

**Reflexion**: Wie verbessern benannte Gruppen und Lookaheads die Regex-Lesbarkeit und Präzision? Nutze `help(re.compile)` und überlege, wie du negative Lookaheads für komplexere Filter einsetzen kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Regex-Muster und Methoden zu verinnerlichen.
- **Sicheres Testen**: Nutze Testverzeichnisse und kleine Datensätze, um Regex zu debuggen.
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze `help(re)` oder die Python-Dokumentation (https://docs.python.org/3/library/re.html).
- **Effiziente Entwicklung**: Verwende `re.VERBOSE` für lesbare Regex, `re.compile()` für Performance und Klassen für strukturierte Logik.
- **Kombiniere Tools**: Integriere Regex mit pandas für Datenanalyse oder Flask für Webanwendungen.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Parsing von IP-Adressen oder Integration mit Visualisierung.

## Fazit
Mit diesen Übungen hast du sowohl grundlegende als auch fortgeschrittene Regex-Techniken in Python gemeistert, einschließlich Mustererkennung, Log-Parsing und Optimierungen wie benannte Gruppen und Lookaheads. Die Spielerei zeigt, wie du Log-Daten in eine Markdown-Tabelle umwandelst. Vertiefe dein Wissen, indem du fortgeschrittene Regex-Features (z. B. Backreferences, non-greedy Matching) oder Integration mit anderen Tools (z. B. `pandas`, `matplotlib`) ausprobierst. Wenn du ein spezifisches Thema (z. B. Regex-Performance oder Visualisierung der Ergebnisse) vertiefen möchtest, lass es mich wissen!
