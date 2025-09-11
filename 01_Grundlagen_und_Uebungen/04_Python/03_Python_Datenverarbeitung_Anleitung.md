# Praxisorientierte Anleitung: Suchen, Filtern und Extrahieren aus JSON, CSV und Log-Dateien mit Python

## Einführung
Das Suchen, Filtern und Extrahieren von Daten aus strukturierten (JSON, CSV) und unstrukturierten (Log-Dateien) Formaten ist eine Kernaufgabe in der Datenverarbeitung. Diese Anleitung konzentriert sich auf **Suche und Filterung in JSON-Dateien**, **Verarbeitung von CSV-Dateien mit pandas** und **Parsen von Log-Dateien mit regulären Ausdrücken**. Eine **Spielerei** zeigt, wie du eine Klasse erstellst, die Daten aus allen drei Formaten verarbeitet und eine Zusammenfassung extrahiert, z. B. um Fehler aus Log-Dateien in eine CSV-Datei zu schreiben. Durch praktische Übungen lernst du, Daten effizient zu filtern, zu analysieren und zu speichern, mit Verbindungen zu vorherigen Themen wie Verzeichnisanalyse.

**Voraussetzungen**:
- Ein System mit Windows, macOS oder Linux (z. B. Windows 11, Ubuntu 22.04, macOS Ventura).
- Ein Terminal (PowerShell für Windows, Terminal für macOS/Linux).
- Python 3 installiert (prüfe mit `python3 --version`; installiere via `choco install python` auf Windows, `sudo apt install python3` auf Ubuntu oder `brew install python3` auf macOS).
- pandas installiert (`pip install pandas`).
- Grundkenntnisse in Python (Klassen, Datei-Ein-/Ausgabe, pandas).
- Sichere Testumgebung (z. B. `$HOME/data_processing_test` oder `~/data_processing_test`).

## Grundlegende Befehle
Hier sind die wichtigsten Konzepte und Befehle, aufgeteilt nach den Hauptthemen:

1. **Suche und Filterung in JSON-Dateien**:
   - `json.load()`: Liest JSON-Daten aus einer Datei.
   - List Comprehensions: Filtern von JSON-Daten (z. B. `[x for x in data if x['key'] == value]`).
   - `json.dump()`: Speichert Daten in eine JSON-Datei.
2. **Verarbeitung von CSV-Dateien mit pandas**:
   - `pd.read_csv()`: Liest eine CSV-Datei in einen DataFrame.
   - `df[df['column'] > value]`: Filtert Zeilen basierend auf Bedingungen.
   - `df.to_csv()`: Speichert einen DataFrame in eine CSV-Datei.
3. **Parsen von Log-Dateien mit regulären Ausdrücken**:
   - `import re`: Importiert das Modul für reguläre Ausdrücke.
   - `re.search()`: Findet Muster in Textzeilen.
   - `re.compile()`: Erstellt wiederverwendbare Regex-Muster.
4. **Nützliche Zusatzbefehle**:
   - `python3 script.py`: Führt ein Python-Skript aus.
   - `dir(pd.DataFrame)`: Zeigt pandas-Methoden.
   - `help(re)`: Zeigt Dokumentation zu regulären Ausdrücken.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Suche und Filterung in JSON-Dateien
**Ziel**: Filtere Benutzerdaten aus einer JSON-Datei nach Alter und speichere die Ergebnisse.

1. **Schritt 1**: Erstelle ein Projektverzeichnis:
   ```bash
   mkdir data_processing_test
   cd data_processing_test
   ```

2. **Schritt 2**: Erstelle eine JSON-Datei mit Testdaten:
   ```bash
   nano users.json
   ```
   Füge folgenden Inhalt ein:
   ```json
   [
       {"name": "Anna", "age": 25, "email": "anna@example.com"},
       {"name": "Ben", "age": 17, "email": "ben@example.com"},
       {"name": "Clara", "age": 30, "email": "clara@example.com"},
       {"name": "David", "age": 22, "email": "david@example.com"}
   ]
   ```
   Speichere und schließe.

3. **Schritt 3**: Erstelle ein Skript zum Filtern von JSON-Daten:
   ```bash
   nano filter_json.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import json

   def filter_adults(input_file="users.json", output_file="adults.json"):
       """Filtert volljährige Benutzer aus einer JSON-Datei."""
       with open(input_file, 'r') as f:
           data = json.load(f)
       adults = [user for user in data if user['age'] >= 18]
       with open(output_file, 'w') as f:
           json.dump(adults, f, indent=4)
       return adults

   if __name__ == "__main__":
       adults = filter_adults()
       print("Volljährige Benutzer:")
       for user in adults:
           print(f"{user['name']}: {user['age']} Jahre")
   ```
   Speichere und schließe.

4. **Schritt 4**: Führe das Skript aus:
   ```bash
   python3 filter_json.py
   ```
   Die Ausgabe sollte so aussehen:
   ```
   Volljährige Benutzer:
   Anna: 25 Jahre
   Clara: 30 Jahre
   David: 22 Jahre
   ```

5. **Schritt 5**: Überprüfe die Ausgabe-JSON-Datei:
   ```bash
   cat adults.json
   ```
   Die Datei sollte so aussehen:
   ```json
   [
       {
           "name": "Anna",
           "age": 25,
           "email": "anna@example.com"
       },
       {
           "name": "Clara",
           "age": 30,
           "email": "clara@example.com"
       },
       {
           "name": "David",
           "age": 22,
           "email": "david@example.com"
       }
   ]
   ```

**Reflexion**: Warum sind List Comprehensions für JSON-Filterung effizient? Nutze `help(json)` und überlege, wie du komplexere Filter (z. B. nach E-Mail-Domänen) implementieren kannst.

### Übung 2: Verarbeitung von CSV-Dateien mit pandas
**Ziel**: Filtere und analysiere Daten aus einer CSV-Datei mit pandas und speichere die Ergebnisse.

1. **Schritt 1**: Erstelle eine CSV-Datei mit Testdaten:
   ```bash
   nano data.csv
   ```
   Füge folgenden Inhalt ein:
   ```csv
   name,age,city
   Anna,25,Berlin
   Ben,17,München
   Clara,30,Hamburg
   David,22,Berlin
   ```
   Speichere und schließe.

2. **Schritt 2**: Erstelle ein Skript zum Filtern und Analysieren:
   ```bash
   nano process_csv.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import pandas as pd

   def process_csv(input_file="data.csv", output_file="filtered_data.csv"):
       """Filtert Benutzer aus Berlin und speichert sie."""
       df = pd.read_csv(input_file)
       berlin_users = df[df['city'] == 'Berlin']
       berlin_users.to_csv(output_file, index=False)
       return berlin_users

   if __name__ == "__main__":
       filtered = process_csv()
       print("Benutzer aus Berlin:")
       print(filtered)
       print("\nStatistik nach Stadt:")
       df = pd.read_csv("data.csv")
       print(df['city'].value_counts())
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   python3 process_csv.py
   ```
   Die Ausgabe sollte so aussehen:
   ```
   Benutzer aus Berlin:
       name  age   city
   0   Anna   25  Berlin
   3  David   22  Berlin

   Statistik nach Stadt:
   Berlin     2
   München    1
   Hamburg    1
   Name: city, dtype: int64
   ```

4. **Schritt 4**: Überprüfe die Ausgabe-CSV-Datei:
   ```bash
   cat filtered_data.csv
   ```
   Die Datei sollte so aussehen:
   ```csv
   name,age,city
   Anna,25,Berlin
   David,22,Berlin
   ```

**Reflexion**: Wie erleichtert pandas die Datenfilterung? Nutze `dir(pd.DataFrame)` und überlege, wie du Gruppierungen (z. B. nach Altersgruppen) hinzufügen kannst.

### Übung 3: Parsen von Log-Dateien und Spielerei
**Ziel**: Parse eine Log-Datei nach Fehlern mit regulären Ausdrücken, speichere die Ergebnisse mit pandas und erstelle eine Spielerei, die alle Formate kombiniert.

1. **Schritt 1**: Erstelle eine Test-Log-Datei:
   ```bash
   nano server.log
   ```
   Füge folgenden Inhalt ein:
   ```
   2025-09-04 10:00:01 INFO Server started
   2025-09-04 10:01:15 ERROR Failed to connect to database
   2025-09-04 10:02:30 INFO User logged in: Anna
   2025-09-04 10:03:45 ERROR Timeout in API request
   2025-09-04 10:04:00 INFO Server running
   ```
   Speichere und schließe.

2. **Schritt 2**: Erstelle ein Skript zum Parsen von Log-Dateien:
   ```bash
   nano log_parser.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import re
   import pandas as pd

   class LogParser:
       def __init__(self, log_file="server.log"):
           self.log_file = log_file
           self.errors = []

       def parse_errors(self):
           """Parst Log-Datei nach ERROR-Einträgen."""
           pattern = re.compile(r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) (ERROR) (.*)')
           with open(self.log_file, 'r') as f:
               for line in f:
                   match = pattern.search(line)
                   if match:
                       self.errors.append({
                           "timestamp": match.group(1),
                           "level": match.group(2),
                           "message": match.group(3)
                       })
           return self

       def to_dataframe(self):
           """Konvertiert Fehler in einen pandas DataFrame."""
           return pd.DataFrame(self.errors)

       def save_to_csv(self, filename="errors.csv"):
           """Speichert Fehler in eine CSV-Datei."""
           self.to_dataframe().to_csv(filename, index=False)

   if __name__ == "__main__":
       parser = LogParser()
       parser.parse_errors()
       df = parser.to_dataframe()
       print("Gefundene Fehler:")
       print(df)
       parser.save_to_csv()
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   python3 log_parser.py
   ```
   Die Ausgabe sollte so aussehen:
   ```
   Gefundene Fehler:
                 timestamp level                     message
   0  2025-09-04 10:01:15 ERROR  Failed to connect to database
   1  2025-09-04 10:03:45 ERROR         Timeout in API request
   ```

4. **Schritt 4**: Überprüfe die Ausgabe-CSV-Datei:
   ```bash
   cat errors.csv
   ```
   Die Datei sollte so aussehen:
   ```csv
   timestamp,level,message
   2025-09-04 10:01:15,ERROR,Failed to connect to database
   2025-09-04 10:03:45,ERROR,Timeout in API request
   ```

5. **Spielerei**: Erstelle eine Klasse, die JSON, CSV und Log-Daten kombiniert:
   ```bash
   nano data_combiner.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import json
   import pandas as pd
   import re

   class DataCombiner:
       def __init__(self, json_file="users.json", csv_file="data.csv", log_file="server.log"):
           self.json_file = json_file
           self.csv_file = csv_file
           self.log_file = log_file
           self.combined_data = []

       def extract_json(self, min_age=18):
           """Extrahiert volljährige Benutzer aus JSON."""
           with open(self.json_file, 'r') as f:
               data = json.load(f)
           return [{"source": "json", "name": user["name"], "age": user["age"]} 
                   for user in data if user["age"] >= min_age]

       def extract_csv(self, city="Berlin"):
           """Extrahiert Benutzer aus einer bestimmten Stadt aus CSV."""
           df = pd.read_csv(self.csv_file)
           filtered = df[df["city"] == city][["name", "age"]]
           return [{"source": "csv", "name": row["name"], "age": row["age"]} 
                   for _, row in filtered.iterrows()]

       def extract_log_errors(self):
           """Extrahiert ERROR-Einträge aus der Log-Datei."""
           pattern = re.compile(r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) (ERROR) (.*)')
           errors = []
           with open(self.log_file, 'r') as f:
               for line in f:
                   match = pattern.search(line)
                   if match:
                       errors.append({
                           "source": "log",
                           "name": None,
                           "age": None,
                           "message": match.group(3),
                           "timestamp": match.group(1)
                       })
           return errors

       def combine_and_save(self, output_file="combined_data.csv"):
           """Kombiniert Daten und speichert sie in eine CSV-Datei."""
           self.combined_data = (self.extract_json() + 
                                 self.extract_csv() + 
                                 self.extract_log_errors())
           df = pd.DataFrame(self.combined_data)
           df.to_csv(output_file, index=False)
           return df

   if __name__ == "__main__":
       combiner = DataCombiner()
       df = combiner.combine_and_save()
       print("Kombinierte Daten:")
       print(df)
   ```
   Speichere und schließe.

6. **Schritt 5**: Führe das Skript aus:
   ```bash
   python3 data_combiner.py
   ```
   Die Ausgabe sollte so aussehen (Werte variieren):
   ```
   Kombinierte Daten:
     source   name   age                    message            timestamp
   0   json   Anna  25.0                       None                 None
   1   json  Clara  30.0                       None                 None
   2   json  David  22.0                       None                 None
   3    csv   Anna  25.0                       None                 None
   4    csv  David  22.0                       None                 None
   5    log   None   NaN  Failed to connect to database  2025-09-04 10:01:15
   6    log   None   NaN         Timeout in API request  2025-09-04 10:03:45
   ```

7. **Schritt 6**: Überprüfe die Ausgabe-CSV-Datei:
   ```bash
   cat combined_data.csv
   ```

**Reflexion**: Wie vereinfacht die Kombination von JSON, CSV und Log-Daten die Analyse? Nutze `help(re)` und überlege, wie du komplexere Regex-Muster (z. B. für IP-Adressen) einsetzen kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um JSON-, CSV- und Log-Verarbeitung zu verinnerlichen.
- **Sicheres Testen**: Nutze Testverzeichnisse und virtuelle Umgebungen (`python3 -m venv venv`).
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze `help()` oder die Python-Dokumentation (https://docs.python.org/3/).
- **Effiziente Entwicklung**: Verwende Klassen für strukturierte Datenverarbeitung, pandas für Analysen und Regex für flexible Parsing.
- **Kombiniere Tools**: Integriere die Skripte in Flask für Webanwendungen oder Git für Versionskontrolle.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Visualisierung der Ergebnisse mit `matplotlib`.

## Fazit
Mit diesen Übungen hast du gelernt, wie du Daten aus JSON, CSV und Log-Dateien suchst, filterst und extrahierst. Die Spielerei zeigt, wie du Daten aus verschiedenen Quellen kombinierst und in einer einheitlichen Struktur speicherst. Vertiefe dein Wissen, indem du fortgeschrittene pandas-Funktionen (z. B. Merges), komplexe Regex-Muster oder Datenvisualisierung (z. B. mit `seaborn`) ausprobierst. Wenn du ein spezifisches Thema (z. B. Regex-Optimierung oder Visualisierung) vertiefen möchtest, lass es mich wissen!
