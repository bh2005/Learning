# Praxisorientierte Anleitung: Python Basics für Anfänger

## Einführung
Python ist eine vielseitige und anfängerfreundliche Programmiersprache, die für Webanwendungen, Datenanalyse und Automatisierung verwendet wird. Diese Anleitung konzentriert sich auf die Schwerpunkte **Variablen und Datentypen**, **Kontrollstrukturen und Schleifen** sowie **Funktionen und Module**, um die Grundlagen zu vermitteln. Eine **Spielerei** zeigt, wie du ein Python-Skript schreibst, das eine Verzeichnisstruktur analysiert und in eine Markdown-Datei ausgibt, um eine Verbindung zu vorherigen Themen (z. B. `README.md`) herzustellen. Durch praktische Übungen lernst du, Python-Skripte zu schreiben, grundlegende Logik zu implementieren und Dateien zu verarbeiten.

**Voraussetzungen**:
- Ein System mit Windows, macOS oder Linux (z. B. Windows 11, Ubuntu 22.04, macOS Ventura).
- Ein Terminal (PowerShell für Windows, Terminal für macOS/Linux).
- Python 3 installiert (prüfe mit `python3 --version` oder `python --version`; installiere via `choco install python` auf Windows, `sudo apt install python3` auf Ubuntu oder `brew install python3` auf macOS).
- Ein Texteditor (z. B. VS Code, `nano` oder Notepad).
- Sichere Testumgebung (z. B. `$HOME/python_basics_test` oder `~/python_basics_test`).
- Keine Vorkenntnisse erforderlich, aber Grundverständnis für Computer hilfreich.

## Grundlegende Befehle
Hier sind die wichtigsten Python-Konzepte und Befehle, aufgeteilt nach den Hauptthemen:

1. **Variablen und Datentypen**:
   - `int`, `float`, `str`, `bool`, `list`, `dict`: Grundlegende Datentypen.
   - `=` : Weist Werte Variablen zu (z. B. `x = 5`).
   - `type()`: Prüft den Datentyp einer Variable.
   - `print()`: Gibt Werte in der Konsole aus.
2. **Kontrollstrukturen und Schleifen**:
   - `if`, `elif`, `else`: Bedingte Anweisungen.
   - `for x in range(n)`: Schleife über einen Bereich.
   - `while`: Schleife mit Bedingung.
3. **Funktionen und Module**:
   - `def`: Definiert eine Funktion (z. B. `def my_func():`).
   - `import`: Importiert Module (z. B. `import os`).
   - `return`: Gibt Werte aus einer Funktion zurück.
4. **Nützliche Zusatzbefehle**:
   - `python3 script.py`: Führt ein Python-Skript aus.
   - `dir()`: Zeigt verfügbare Methoden eines Objekts.
   - `help()`: Zeigt Dokumentation zu Modulen oder Funktionen.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Variablen und Datentypen
**Ziel**: Erstelle ein Python-Skript, das mit verschiedenen Datentypen arbeitet und sie ausgibt.

1. **Schritt 1**: Erstelle ein Projektverzeichnis:
   ```bash
   mkdir python_basics_test
   cd python_basics_test
   ```

2. **Schritt 2**: Erstelle ein Skript für Variablen:
   ```bash
   nano variables.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   # Variablen und Datentypen
   name = "Anna"  # String
   age = 25       # Integer
   height = 1.75  # Float
   is_student = True  # Boolean
   hobbies = ["Lesen", "Sport", "Kochen"]  # Liste
   info = {"name": name, "age": age}  # Dictionary

   # Ausgabe der Variablen und Typen
   print(f"Name: {name}, Typ: {type(name)}")
   print(f"Alter: {age}, Typ: {type(age)}")
   print(f"Größe: {height}, Typ: {type(height)}")
   print(f"Student: {is_student}, Typ: {type(is_student)}")
   print(f"Hobbies: {hobbies}, Typ: {type(hobbies)}")
   print(f"Info: {info}, Typ: {type(info)}")
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   python3 variables.py
   ```
   Die Ausgabe sollte so aussehen:
   ```
   Name: Anna, Typ: <class 'str'>
   Alter: 25, Typ: <class 'int'>
   Größe: 1.75, Typ: <class 'float'>
   Student: True, Typ: <class 'bool'>
   Hobbies: ['Lesen', 'Sport', 'Kochen'], Typ: <class 'list'>
   Info: {'name': 'Anna', 'age': 25}, Typ: <class 'dict'>
   ```

**Reflexion**: Warum ist es wichtig, Datentypen zu verstehen? Nutze `help(type)` und überlege, wie du Listen oder Dictionaries für komplexere Daten verwenden kannst.

### Übung 2: Kontrollstrukturen und Schleifen
**Ziel**: Schreibe ein Skript, das Bedingungen und Schleifen nutzt, um Benutzerdaten zu verarbeiten.

1. **Schritt 1**: Erstelle ein Skript für Kontrollstrukturen:
   ```bash
   nano conditions_loops.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   # Benutzerdaten
   users = [
       {"name": "Anna", "age": 25},
       {"name": "Ben", "age": 17},
       {"name": "Clara", "age": 30}
   ]

   # Schleife und Bedingungen
   for user in users:
       name = user["name"]
       age = user["age"]
       if age >= 18:
           status = "volljährig"
       else:
           status = "minderjährig"
       print(f"{name} ist {age} Jahre alt und {status}.")
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   python3 conditions_loops.py
   ```
   Die Ausgabe sollte so aussehen:
   ```
   Anna ist 25 Jahre alt und volljährig.
   Ben ist 17 Jahre alt und minderjährig.
   Clara ist 30 Jahre alt und volljährig.
   ```

3. **Schritt 3**: Erweitere das Skript mit einer `while`-Schleife:
   ```bash
   nano conditions_loops.py
   ```
   Füge am Ende hinzu:
   ```python
   # While-Schleife für eine Zählung
   count = 0
   while count < len(users):
       print(f"Benutzer {count + 1}: {users[count]['name']}")
       count += 1
   ```
   Speichere und schließe.

4. **Schritt 4**: Führe das Skript erneut aus:
   ```bash
   python3 conditions_loops.py
   ```
   Die zusätzliche Ausgabe sollte sein:
   ```
   Benutzer 1: Anna
   Benutzer 2: Ben
   Benutzer 3: Clara
   ```

**Reflexion**: Wie helfen Schleifen bei der Verarbeitung von Datenlisten? Nutze `help('for')` und überlege, wie du Schleifen für größere Datensätze optimieren kannst.

### Übung 3: Funktionen und Module mit Spielerei
**Ziel**: Erstelle Funktionen und nutze das `os`-Modul, um eine Verzeichnisstruktur zu analysieren und in eine Markdown-Datei auszugeben.

1. **Schritt 1**: Erstelle einige Testdateien und -ordner:
   ```bash
   mkdir src docs
   echo "print('Hallo')" > src/main.py
   echo "Dokumentation" > docs/guide.md
   ```

2. **Schritt 2**: Erstelle ein Skript für die Verzeichnisstruktur:
   ```bash
   nano tree_generator.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import os

   def generate_tree(directory='.', ignore=['.git']):
       """Generiert eine Verzeichnisstruktur als String."""
       tree = ['## Verzeichnisstruktur\n```tree']
       for root, dirs, files in os.walk(directory):
           dirs[:] = [d for d in dirs if d not in ignore]
           level = root.replace(directory, '').count(os.sep)
           indent = '  ' * level
           tree.append(f'{indent}{os.path.basename(root)}/')
           for file in sorted(files):
               tree.append(f'{indent}  {file}')
       tree.append('```')
       return '\n'.join(tree)

   def save_to_markdown(filename='README.md'):
       """Speichert die Verzeichnisstruktur in eine Markdown-Datei."""
       with open(filename, 'w') as f:
           f.write('# Mein Projekt\n\n')
           f.write(generate_tree())

   if __name__ == '__main__':
       save_to_markdown()
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   python3 tree_generator.py
   cat README.md
   ```
   Die `README.md` sollte so aussehen:
   ```
   # Mein Projekt

   ## Verzeichnisstruktur
   ```tree
   ./
     docs/
       guide.md
     src/
       main.py
     conditions_loops.py
     tree_generator.py
     variables.py
   ```
   ```

4. **Spielerei**: Erweitere das Skript, um nur `.py`-Dateien anzuzeigen:
   ```bash
   nano tree_generator.py
   ```
   Ändere die `generate_tree`-Funktion zu:
   ```python
   def generate_tree(directory='.', ignore=['.git'], file_extension='.py'):
       """Generiert eine Verzeichnisstruktur mit bestimmten Dateitypen."""
       tree = ['## Verzeichnisstruktur (nur Python-Dateien)\n```tree']
       for root, dirs, files in os.walk(directory):
           dirs[:] = [d for d in dirs if d not in ignore]
           level = root.replace(directory, '').count(os.sep)
           indent = '  ' * level
           tree.append(f'{indent}{os.path.basename(root)}/')
           for file in sorted(f for f in files if f.endswith(file_extension)):
               tree.append(f'{indent}  {file}')
       tree.append('```')
       return '\n'.join(tree)
   ```
   Speichere und schließe.

5. **Schritt 4**: Führe das Skript erneut aus:
   ```bash
   python3 tree_generator.py
   cat README.md
   ```
   Die `README.md` sollte nun nur `.py`-Dateien anzeigen:
   ```
   # Mein Projekt

   ## Verzeichnisstruktur (nur Python-Dateien)
   ```tree
   ./
     src/
       main.py
     conditions_loops.py
     tree_generator.py
     variables.py
   ```
   ```

**Reflexion**: Wie machen Funktionen und Module den Code wiederverwendbar? Nutze `help(os)` und überlege, wie du weitere Module (z. B. `pathlib`) einbinden kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Python-Grundlagen zu verinnerlichen.
- **Sicheres Testen**: Nutze Testverzeichnisse, um Fehler zu vermeiden.
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze `help()` oder die Python-Dokumentation (https://docs.python.org/3/).
- **Effiziente Entwicklung**: Verwende klare Variablennamen, kommentiere deinen Code und organisiere Skripte in Funktionen.
- **Kombiniere Tools**: Integriere Python mit Git für Versionskontrolle oder VS Code für produktives Coding (`code .`).
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Filterung nach anderen Dateitypen oder Einbindung in Flask.

## Fazit
Mit diesen Übungen hast du die Grundlagen von Python gemeistert, einschließlich Variablen, Kontrollstrukturen, Schleifen, Funktionen und Modulen. Die Spielerei zeigt, wie du Python für praktische Aufgaben wie die Verzeichnisanalyse nutzen kannst. Vertiefe dein Wissen, indem du fortgeschrittene Konzepte wie Klassen, Datei-Ein-/Ausgabe oder externe Bibliotheken (z. B. `pandas`) ausprobierst. Wenn du ein spezifisches Thema (z. B. Datei-Ein-/Ausgabe oder Python-Module) vertiefen möchtest, lass es mich wissen!
