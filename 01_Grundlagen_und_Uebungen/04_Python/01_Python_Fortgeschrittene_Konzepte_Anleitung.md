# Praxisorientierte Anleitung: Fortgeschrittene Python-Konzepte (Klassen, Datei-Ein-/Ausgabe, pandas)

## Einführung
Fortgeschrittene Python-Konzepte wie Klassen, Datei-Ein-/Ausgabe und externe Bibliotheken wie pandas ermöglichen komplexe Anwendungen, von objektorientierter Programmierung bis zur Datenanalyse. Diese Anleitung konzentriert sich auf **Objektorientierte Programmierung mit Klassen**, **Datei-Ein-/Ausgabe für Datenverarbeitung** und **Datenanalyse mit pandas**. Eine **Spielerei** zeigt, wie du eine Klasse erstellst, die Verzeichnisdaten analysiert und mit pandas in eine CSV-Datei schreibt, um eine Verbindung zu vorherigen Themen (z. B. Verzeichnisstruktur) herzustellen. Durch praktische Übungen lernst du, Klassen zu definieren, Dateien zu verarbeiten und Daten mit pandas zu analysieren.

**Voraussetzungen**:
- Ein System mit Windows, macOS oder Linux (z. B. Windows 11, Ubuntu 22.04, macOS Ventura).
- Ein Terminal (PowerShell für Windows, Terminal für macOS/Linux).
- Python 3 installiert (prüfe mit `python3 --version`; installiere via `choco install python` auf Windows, `sudo apt install python3` auf Ubuntu oder `brew install python3` auf macOS).
- `pip` für Python-Pakete (prüfe mit `pip3 --version`).
- pandas installiert (`pip install pandas`).
- Grundkenntnisse in Python (Variablen, Schleifen, Funktionen).
- Sichere Testumgebung (z. B. `$HOME/python_advanced_test` oder `~/python_advanced_test`).

## Grundlegende Befehle
Hier sind die wichtigsten Konzepte und Befehle, aufgeteilt nach den Hauptthemen:

1. **Objektorientierte Programmierung mit Klassen**:
   - `class`: Definiert eine Klasse (z. B. `class MyClass:`).
   - `__init__`: Konstruktor für Klasseninitialisierung.
   - `self`: Verweist auf die Instanz der Klasse.
2. **Datei-Ein-/Ausgabe**:
   - `open('file.txt', 'r')`: Öffnet eine Datei zum Lesen.
   - `open('file.txt', 'w')`: Öffnet eine Datei zum Schreiben.
   - `with`-Statement: Sichert automatische Schließung von Dateien.
3. **Datenanalyse mit pandas**:
   - `import pandas as pd`: Importiert pandas.
   - `pd.DataFrame`: Erstellt eine Datenstruktur für Tabellen.
   - `df.to_csv()`: Speichert Daten in eine CSV-Datei.
4. **Nützliche Zusatzbefehle**:
   - `python3 script.py`: Führt ein Python-Skript aus.
   - `dir()`: Zeigt Methoden eines Objekts.
   - `help()`: Zeigt Dokumentation zu Klassen oder Modulen.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Objektorientierte Programmierung mit Klassen
**Ziel**: Erstelle eine Klasse, um Benutzerdaten zu verwalten und Methoden für deren Verarbeitung zu definieren.

1. **Schritt 1**: Erstelle ein Projektverzeichnis:
   ```bash
   mkdir python_advanced_test
   cd python_advanced_test
   ```

2. **Schritt 2**: Erstelle ein Skript mit einer Benutzerklasse:
   ```bash
   nano user_manager.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   class User:
       def __init__(self, name, age, email):
           self.name = name
           self.age = age
           self.email = email

       def is_adult(self):
           return self.age >= 18

       def get_info(self):
           status = "volljährig" if self.is_adult() else "minderjährig"
           return f"{self.name} ist {self.age} Jahre alt, {status}, E-Mail: {self.email}"

   # Test der Klasse
   if __name__ == "__main__":
       users = [
           User("Anna", 25, "anna@example.com"),
           User("Ben", 17, "ben@example.com"),
           User("Clara", 30, "clara@example.com")
       ]
       for user in users:
           print(user.get_info())
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   python3 user_manager.py
   ```
   Die Ausgabe sollte so aussehen:
   ```
   Anna ist 25 Jahre alt, volljährig, E-Mail: anna@example.com
   Ben ist 17 Jahre alt, minderjährig, E-Mail: ben@example.com
   Clara ist 30 Jahre alt, volljährig, E-Mail: clara@example.com
   ```

**Reflexion**: Wie verbessern Klassen die Struktur von Code? Nutze `help(User)` und überlege, wie du Vererbung für spezialisierte Klassen (z. B. `Student`) einsetzen kannst.

### Übung 2: Datei-Ein-/Ausgabe
**Ziel**: Schreibe ein Skript, das Benutzerdaten in eine JSON-Datei speichert und liest.

1. **Schritt 1**: Erstelle ein Skript für Datei-Ein-/Ausgabe:
   ```bash
   nano user_file_io.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import json

   class User:
       def __init__(self, name, age, email):
           self.name = name
           self.age = age
           self.email = email

       def to_dict(self):
           return {"name": self.name, "age": self.age, "email": self.email}

   def save_users(users, filename="users.json"):
       """Speichert eine Liste von Usern in eine JSON-Datei."""
       with open(filename, 'w') as f:
           json.dump([user.to_dict() for user in users], f, indent=4)

   def load_users(filename="users.json"):
       """Liest User-Daten aus einer JSON-Datei."""
       try:
           with open(filename, 'r') as f:
               data = json.load(f)
               return [User(d["name"], d["age"], d["email"]) for d in data]
       except FileNotFoundError:
           return []

   if __name__ == "__main__":
       users = [
           User("Anna", 25, "anna@example.com"),
           User("Ben", 17, "ben@example.com")
       ]
       save_users(users)
       loaded_users = load_users()
       for user in loaded_users:
           print(f"Geladen: {user.name}, {user.age}, {user.email}")
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   python3 user_file_io.py
   ```
   Die Ausgabe sollte so aussehen:
   ```
   Geladen: Anna, 25, anna@example.com
   Geladen: Ben, 17, ben@example.com
   ```

3. **Schritt 3**: Überprüfe die erstellte `users.json`:
   ```bash
   cat users.json
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
           "name": "Ben",
           "age": 17,
           "email": "ben@example.com"
       }
   ]
   ```

**Reflexion**: Warum ist das `with`-Statement für Dateioperationen wichtig? Nutze `help(json)` und überlege, wie du andere Formate (z. B. CSV) nutzen kannst.

### Übung 3: Datenanalyse mit pandas und Spielerei
**Ziel**: Nutze pandas, um Verzeichnisdaten zu analysieren, in einer Klasse zu verarbeiten und in eine CSV-Datei zu schreiben.

1. **Schritt 1**: Installiere pandas:
   ```bash
   pip install pandas
   ```

2. **Schritt 2**: Erstelle einige Testdateien und -ordner:
   ```bash
   mkdir src docs
   echo "print('Hallo')" > src/main.py
   echo "Dokumentation" > docs/guide.md
   touch src/utils.py
   ```

3. **Schritt 3**: Erstelle ein Skript für die Verzeichnisanalyse:
   ```bash
   nano directory_analyzer.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import os
   import pandas as pd
   from datetime import datetime

   class DirectoryAnalyzer:
       def __init__(self, directory='.'):
           self.directory = directory
           self.data = []

       def analyze(self, ignore=['.git']):
           """Analysiert das Verzeichnis und sammelt Dateidaten."""
           for root, dirs, files in os.walk(self.directory):
               dirs[:] = [d for d in dirs if d not in ignore]
               for file in files:
                   file_path = os.path.join(root, file)
                   stats = os.stat(file_path)
                   self.data.append({
                       "file": file,
                       "path": file_path,
                       "size_bytes": stats.st_size,
                       "modified": datetime.fromtimestamp(stats.st_mtime).strftime('%Y-%m-%d %H:%M:%S')
                   })
           return self

       def to_dataframe(self):
           """Konvertiert die Daten in einen pandas DataFrame."""
           return pd.DataFrame(self.data)

       def save_to_csv(self, filename="directory_analysis.csv"):
           """Speichert die Daten in eine CSV-Datei."""
           self.to_dataframe().to_csv(filename, index=False)

   if __name__ == "__main__":
       analyzer = DirectoryAnalyzer()
       analyzer.analyze()
       df = analyzer.to_dataframe()
       print(df)
       analyzer.save_to_csv()
   ```
   Speichere und schließe.

4. **Schritt 4**: Führe das Skript aus:
   ```bash
   python3 directory_analyzer.py
   ```
   Die Ausgabe sollte eine Tabelle wie diese anzeigen (Werte variieren):
   ```
        file                    path  size_bytes            modified
   0  main.py         src/main.py         12  2025-09-04 11:00:00
   1  utils.py        src/utils.py         0  2025-09-04 11:00:00
   2  guide.md       docs/guide.md        13  2025-09-04 11:00:00
   3  user_manager.py user_manager.py       256  2025-09-04 11:00:00
   4  user_file_io.py user_file_io.py       512  2025-09-04 11:00:00
   ```

5. **Spielerei**: Erweitere die Klasse, um eine Zusammenfassung der Dateitypen zu erstellen:
   ```bash
   nano directory_analyzer.py
   ```
   Füge eine neue Methode zur Klasse `DirectoryAnalyzer` hinzu, vor `if __name__ == "__main__":`:
   ```python
       def summarize_file_types(self):
           """Erstellt eine Zusammenfassung der Dateitypen."""
           df = self.to_dataframe()
           summary = df['file'].str.extract(r'\.(\w+)$').value_counts()
           return pd.DataFrame({
               'extension': summary.index,
               'count': summary.values
           })
   ```
   Ändere den Hauptblock zu:
   ```python
   if __name__ == "__main__":
       analyzer = DirectoryAnalyzer()
       analyzer.analyze()
       df = analyzer.to_dataframe()
       print("Verzeichnisdaten:")
       print(df)
       analyzer.save_to_csv()
       summary = analyzer.summarize_file_types()
       print("\nZusammenfassung der Dateitypen:")
       print(summary)
       summary.to_csv("file_type_summary.csv", index=False)
   ```
   Speichere und schließe.

6. **Schritt 5**: Führe das Skript erneut aus:
   ```bash
   python3 directory_analyzer.py
   ```
   Die zusätzliche Ausgabe sollte so aussehen:
   ```
   Zusammenfassung der Dateitypen:
     extension  count
   0        py      3
   1        md      1
   ```

7. **Schritt 6**: Überprüfe die CSV-Dateien:
   ```bash
   cat directory_analysis.csv
   cat file_type_summary.csv
   ```

**Reflexion**: Wie erleichtert pandas die Datenanalyse? Nutze `help(pd.DataFrame)` und überlege, wie du weitere Analysen (z. B. nach Dateigröße) hinzufügen kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Klassen, Dateioperationen und pandas zu verinnerlichen.
- **Sicheres Testen**: Nutze Testverzeichnisse und virtuelle Umgebungen (`python3 -m venv venv`).
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze `help()` oder die Python-Dokumentation (https://docs.python.org/3/).
- **Effiziente Entwicklung**: Verwende Klassen für strukturierte Daten, `with` für Dateioperationen und pandas für effiziente Analysen.
- **Kombiniere Tools**: Integriere pandas mit Flask für Webanwendungen oder Git für Versionskontrolle.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Visualisierung mit `matplotlib`.

## Fazit
Mit diesen Übungen hast du fortgeschrittene Python-Konzepte wie Klassen, Datei-Ein-/Ausgabe und pandas gemeistert. Die Spielerei zeigt, wie du Verzeichnisdaten analysierst und zusammenfasst. Vertiefe dein Wissen, indem du Vererbung, fortgeschrittene pandas-Funktionen (z. B. Joins) oder andere Bibliotheken (z. B. `numpy`, `matplotlib`) ausprobierst. Wenn du ein spezifisches Thema (z. B. Vererbung oder Datenvisualisierung) vertiefen möchtest, lass es mich wissen!
