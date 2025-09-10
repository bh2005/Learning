# Praxisorientierte Anleitung: Fortgeschrittene Datenverarbeitung mit Python (Regex-Optimierung und Visualisierung)

## Einführung
Fortgeschrittene Techniken in der Datenverarbeitung wie optimierte reguläre Ausdrücke (Regex) und Visualisierung ermöglichen effiziente Analysen und intuitive Darstellungen von Daten aus JSON, CSV und Log-Dateien. Diese Anleitung baut auf der grundlegenden Version auf und konzentriert sich auf **optimierte Regex für Log-Parsing**, **Datenvisualisierung mit matplotlib** und **Integration in Klassen und pandas**. Eine **Spielerei** zeigt, wie du eine Klasse erstellst, die Log-Daten mit optimierten Regex parsed, die Ergebnisse visualisiert (z. B. ein Balkendiagramm der Fehlerhäufigkeit) und in eine CSV-Datei speichert. Durch praktische Übungen lernst du, Regex zu optimieren, Daten zu visualisieren und komplexe Workflows zu automatisieren.

**Voraussetzungen**:
- Ein System mit Windows, macOS oder Linux (z. B. Windows 11, Ubuntu 22.04, macOS Ventura).
- Ein Terminal (PowerShell für Windows, Terminal für macOS/Linux).
- Python 3 installiert (prüfe mit `python3 --version`; installiere via `choco install python` auf Windows, `sudo apt install python3` auf Ubuntu oder `brew install python3` auf macOS).
- pandas und matplotlib installiert (`pip install pandas matplotlib`).
- Grundkenntnisse in Python (Regex, pandas, Klassen).
- Sichere Testumgebung (z. B. `$HOME/advanced_data_test` oder `~/advanced_data_test`).

## Grundlegende Befehle
Hier sind die wichtigsten Konzepte und Befehle, aufgeteilt nach den Hauptthemen:

1. **Optimierte Regex für Log-Parsing**:
   - `re.compile()`: Kompiliert Regex für schnellere Ausführung.
   - `re.finditer()`: Findet alle Treffer in Text und optimiert das Parsing.
   - `re.VERBOSE`: Ermöglicht lesbare Regex mit Kommentaren.
2. **Datenvisualisierung mit matplotlib**:
   - `import matplotlib.pyplot as plt`: Importiert die Bibliothek.
   - `plt.bar()`: Erstellt Balkendiagramme.
   - `plt.savefig()`: Speichert Diagramme als Bilddatei.
3. **Integration in Klassen und pandas**:
   - `pd.DataFrame`: Erstellt DataFrames für Visualisierungsdaten.
   - `class`: Definiert eine Klasse für das Parsen und Visualisieren.
   - `df.plot()`: Integrierte Visualisierung mit pandas.
4. **Nützliche Zusatzbefehle**:
   - `python3 script.py`: Führt ein Python-Skript aus.
   - `dir(re)`: Zeigt Regex-Methoden.
   - `help(plt.bar)`: Zeigt Dokumentation zu Visualisierungsfunktionen.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Optimierte Regex für Log-Parsing
**Ziel**: Optimierte Regex nutzen, um Log-Dateien nach Fehlern zu parsen und die Performance zu verbessern.

1. **Schritt 1**: Erstelle ein Projektverzeichnis:
   ```bash
   mkdir advanced_data_test
   cd advanced_data_test
   ```

2. **Schritt 2**: Erstelle eine erweiterte Log-Datei:
   ```bash
   nano advanced.log
   ```
   Füge folgenden Inhalt ein:
   ```
   2025-09-04 10:00:01 INFO Server started
   2025-09-04 10:01:15 ERROR Failed to connect to database (code: 500)
   2025-09-04 10:02:30 INFO User logged in: Anna
   2025-09-04 10:03:45 ERROR Timeout in API request (code: 408)
   2025-09-04 10:04:00 INFO Server running
   2025-09-04 10:05:22 ERROR Invalid user input (code: 400)
   2025-09-04 10:06:10 INFO Backup completed
   2025-09-04 10:07:35 ERROR Disk space low (code: 507)
   ```
   Speichere und schließe.

3. **Schritt 3**: Erstelle ein Skript mit optimiertem Regex-Parsing:
   ```bash
   nano optimized_log_parser.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import re
   import time

   def parse_logs_optimized(log_file="advanced.log"):
       """Parst Log-Datei mit optimiertem Regex."""
       pattern = re.compile(r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) (ERROR) (.*?)( \((code: \d+)\))?')
       errors = []
       start_time = time.time()
       with open(log_file, 'r') as f:
           for line in f:
               match = pattern.search(line)
               if match:
                   errors.append({
                       "timestamp": match.group(1),
                       "level": match.group(2),
                       "message": match.group(3),
                       "code": match.group(5) if match.group(5) else None
                   })
       end_time = time.time()
       print(f"Parsing-Zeit: {end_time - start_time} Sekunden")
       return errors

   if __name__ == "__main__":
       errors = parse_logs_optimized()
       print("Gefundene Fehler:")
       for error in errors:
           print(f"{error['timestamp']} - {error['message']} (Code: {error['code']})")
   ```
   Speichere und schließe.

4. **Schritt 4**: Führe das Skript aus:
   ```bash
   python3 optimized_log_parser.py
   ```
   Die Ausgabe sollte so aussehen (Zeit variiert):
   ```
   Parsing-Zeit: 0.000123 Sekunden
   Gefundene Fehler:
   2025-09-04 10:01:15 - Failed to connect to database (Code: 500)
   2025-09-04 10:03:45 - Timeout in API request (Code: 408)
   2025-09-04 10:05:22 - Invalid user input (Code: 400)
   2025-09-04 10:07:35 - Disk space low (Code: 507)
   ```

**Reflexion**: Wie verbessert `re.compile()` die Performance? Nutze `help(re.compile)` und überlege, wie du Regex für spezifische Muster (z. B. IPs) optimieren kannst.

### Übung 2: Datenvisualisierung mit matplotlib
**Ziel**: Visualisiere gefilterte Daten aus einer CSV-Datei mit matplotlib.

1. **Schritt 1**: Erstelle eine CSV-Datei mit Testdaten:
   ```bash
   nano sales_data.csv
   ```
   Füge folgenden Inhalt ein:
   ```csv
   month,sales
   Jan,120
   Feb,150
   Mar,130
   Apr,170
   May,200
   Jun,180
   ```
   Speichere und schließe.

2. **Schritt 2**: Erstelle ein Skript zur Visualisierung:
   ```bash
   nano visualize_data.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import pandas as pd
   import matplotlib.pyplot as plt

   def visualize_sales(input_file="sales_data.csv", output_image="sales_chart.png"):
       """Visualisiert Verkaufsdaten aus einer CSV-Datei."""
       df = pd.read_csv(input_file)
       df.plot(kind='bar', x='month', y='sales', color='skyblue')
       plt.title('Monatliche Verkaufszahlen')
       plt.xlabel('Monat')
       plt.ylabel('Verkäufe')
       plt.grid(axis='y')
       plt.savefig(output_image)
       plt.show()

   if __name__ == "__main__":
       visualize_sales()
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   python3 visualize_data.py
   ```
   Es öffnet sich ein Diagrammfenster, und eine Datei `sales_chart.png` wird gespeichert.

4. **Schritt 4**: Überprüfe die Bilddatei (z. B. mit einem Bildbetrachter):
   - Das Balkendiagramm zeigt die Verkaufszahlen pro Monat.

**Reflexion**: Wie hilft Visualisierung bei der Dateninterpretation? Nutze `help(plt.bar)` und überlege, wie du Linien- oder Tortendiagramme hinzufügen kannst.

### Übung 3: Integration in Klassen und pandas mit Spielerei
**Ziel**: Erstelle eine Klasse, die Daten aus JSON, CSV und Log-Dateien kombiniert, Regex optimiert, visualisiert und in einer CSV speichert.

1. **Schritt 1**: Erstelle Testdateien (JSON und CSV aus vorherigen Übungen, Log aus Übung 1).

2. **Schritt 2**: Erstelle ein Skript für die integrierte Datenverarbeitung:
   ```bash
   nano advanced_data_processor.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import json
   import re
   import pandas as pd
   import matplotlib.pyplot as plt

   class AdvancedDataProcessor:
       def __init__(self, json_file="users.json", csv_file="data.csv", log_file="advanced.log"):
           self.json_file = json_file
           self.csv_file = csv_file
           self.log_file = log_file
           self.data = pd.DataFrame()

       def extract_json(self, min_age=18):
           """Extrahiert volljährige Benutzer aus JSON."""
           with open(self.json_file, 'r') as f:
               json_data = json.load(f)
           filtered = [user for user in json_data if user['age'] >= min_age]
           return pd.DataFrame(filtered, columns=['name', 'age', 'email']).assign(source='json')

       def extract_csv(self, city="Berlin"):
           """Extrahiert Benutzer aus einer bestimmten Stadt aus CSV."""
           df = pd.read_csv(self.csv_file)
           filtered = df[df['city'] == city][['name', 'age', 'city']]
           return filtered.assign(source='csv')

       def extract_log_errors(self):
           """Parst Log-Datei mit optimiertem Regex."""
           pattern = re.compile(
               r'(?P<timestamp>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) '
               r'(?P<level>ERROR) '
               r'(?P<message>.*?)'
               r'( \((?P<code>code: \d+)\))?$',
               re.VERBOSE
           )
           errors = []
           with open(self.log_file, 'r') as f:
               for line in f:
                   match = pattern.match(line)
                   if match:
                       errors.append({
                           'timestamp': match.group('timestamp'),
                           'level': match.group('level'),
                           'message': match.group('message'),
                           'code': match.group('code') if match.group('code') else None,
                           'source': 'log'
                       })
           return pd.DataFrame(errors)

       def combine_data(self):
           """Kombiniert Daten aus allen Quellen."""
           json_df = self.extract_json()
           csv_df = self.extract_csv()
           log_df = self.extract_log_errors()
           # Passe Spalten an für den Merge
           csv_df = csv_df.rename(columns={'city': 'additional'})
           log_df = log_df.rename(columns={'message': 'name', 'code': 'age'})
           log_df['age'] = pd.to_numeric(log_df['age'].str.extract(r'(\d+)', expand=False), errors='coerce')
           self.data = pd.concat([json_df, csv_df, log_df], ignore_index=True, sort=False)
           return self.data

       def visualize_errors(self, output_image="error_chart.png"):
           """Visualisiert die Häufigkeit von Fehlercodes."""
           df = self.extract_log_errors()
           if not df.empty:
               df['code'] = df['code'].fillna('Unknown')
               df['code'].value_counts().plot(kind='bar', color='red')
               plt.title('Häufigkeit von Fehlercodes')
               plt.xlabel('Fehlercode')
               plt.ylabel('Anzahl')
               plt.grid(axis='y')
               plt.savefig(output_image)
               plt.show()

       def save_combined(self, filename="combined_advanced.csv"):
           """Speichert kombinierte Daten in eine CSV-Datei."""
           self.data.to_csv(filename, index=False)

   if __name__ == "__main__":
       processor = AdvancedDataProcessor()
       processor.combine_data()
       processor.visualize_errors()
       processor.save_combined()
       print("Kombinierte Daten:")
       print(processor.data)
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   python3 advanced_data_processor.py
   ```
   Es öffnet sich ein Diagrammfenster mit der Fehlercode-Häufigkeit, und eine Datei `error_chart.png` wird gespeichert. Die Ausgabe sollte die kombinierten Daten anzeigen, und `combined_advanced.csv` wird erstellt.

**Reflexion**: Wie optimiert `re.VERBOSE` die Lesbarkeit von Regex? Nutze `help(matplotlib.pyplot)` und überlege, wie du interaktive Visualisierungen (z. B. mit Plotly) einsetzen kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Regex-Optimierung und Visualisierung zu verinnerlichen.
- **Sicheres Testen**: Nutze Testverzeichnisse und virtuelle Umgebungen (`python3 -m venv venv`).
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze `help()` oder die Python-Dokumentation (https://docs.python.org/3/).
- **Effiziente Entwicklung**: Verwende kompilierte Regex für Performance, matplotlib für schnelle Visualisierungen und Klassen für modulare Code-Struktur.
- **Kombiniere Tools**: Integriere die Skripte in Flask für Webanwendungen oder GitHub Actions für automatisierte Analysen.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Visualisierung von Zeitreihen aus Logs.

## Fazit
Mit diesen Übungen hast du fortgeschrittene Python-Techniken für Regex-Optimierung und Visualisierung gemeistert, integriert in Klassen und pandas. Die Spielerei zeigt, wie du Daten aus verschiedenen Quellen kombinierst und visualisierst. Vertiefe dein Wissen, indem du Regex-Debugging-Tools, fortgeschrittene matplotlib-Features (z. B. Subplots) oder Bibliotheken wie `seaborn` ausprobierst. Wenn du ein spezifisches Thema (z. B. Regex-Performance oder interaktive Plots) vertiefen möchtest, lass es mich wissen!
