# Praxisorientierte Anleitung: **Dateiorganisierer mit Python**

## Einführung
In diesem Mini-Projekt erstellen wir ein einfaches Python-Tool, das Dateien in einem Ordner automatisch nach Typen (z. B. Bilder, Dokumente, Musik) sortiert und in entsprechende Unterordner verschiebt. Das Projekt hilft dir, grundlegende Python-Konzepte wie Schleifen, Bedingungen, Funktionen, Dateiverarbeitung und Fehlerbehandlung praktisch anzuwenden.

**Nutzen**: Du lernst, wie man mit dem Dateisystem arbeitet und ein nützliches Tool für den Alltag entwickelt.

**Voraussetzungen**:
- Python 3.x installiert
- Zugriff auf ein Testverzeichnis mit verschiedenen Dateitypen
- Grundkenntnisse in Python (Variablen, Schleifen, Funktionen, Module)

---

## Grundlegende Techniken

Hier sind die wichtigsten Konzepte, die wir behandeln:

1. **Dateiverarbeitung**:
   - `os.listdir()`: Listet Dateien in einem Verzeichnis auf
   - `os.path.splitext()`: Trennt Dateinamen und Endung
   - `os.rename()`: Verschiebt oder benennt Dateien um

2. **Fehlerbehandlung**:
   - `try/except`: Fängt Fehler ab, z. B. bei fehlenden Zugriffsrechten

3. **Datenstrukturen**:
   - Dictionaries zur Zuordnung von Dateitypen zu Ordnern

---

## Übungen zum Verinnerlichen

### Übung 1: Ordnerstruktur vorbereiten
**Ziel**: Erstelle die Zielordner für verschiedene Dateitypen

1. **Schritt 1**: Definiere die Dateitypen und Zielordner
   ```python
   file_types = {
       'Bilder': ['.jpg', '.png', '.gif'],
       'Dokumente': ['.pdf', '.docx', '.txt'],
       'Musik': ['.mp3', '.wav']
   }
   ```
2. **Schritt 2**: Erstelle die Ordner, falls sie nicht existieren
   ```python
   import os

   for folder in file_types:
       if not os.path.exists(folder):
           os.mkdir(folder)
   ```
3. **Schritt 3**: Teste die Ordnererstellung mit einem Beispielverzeichnis

**Reflexion**: Warum ist es sinnvoll, die Existenz eines Ordners vor dem Erstellen zu prüfen?

---

### Übung 2: Dateien sortieren
**Ziel**: Verschiebe Dateien in die passenden Ordner

1. **Schritt 1**: Liste alle Dateien im Quellordner auf
   ```python
   files = os.listdir('Testordner')
   ```
2. **Schritt 2**: Bestimme den Dateityp und Zielordner
   ```python
   for file in files:
       ext = os.path.splitext(file)[1]
       for folder, extensions in file_types.items():
           if ext in extensions:
               os.rename(f'Testordner/{file}', f'{folder}/{file}')
   ```
3. **Schritt 3**: Füge Fehlerbehandlung hinzu
   ```python
   try:
       os.rename(...)
   except Exception as e:
       print(f'Fehler beim Verschieben: {e}')
   ```

**Reflexion**: Welche Probleme könnten beim Verschieben auftreten?

---

### Übung 3: Erweiterung mit Benutzerinteraktion
**Ziel**: Erlaube dem Benutzer, den Quellordner selbst zu wählen

1. **Schritt 1**: Nutze `input()` zur Abfrage des Pfads
   ```python
   source = input("Gib den Pfad zum Quellordner ein: ")
   ```
2. **Schritt 2**: Validierung des Pfads
   ```python
   if not os.path.exists(source):
       print("Pfad existiert nicht.")
   ```
3. **Schritt 3**: Integriere die Sortierlogik

**Reflexion**: Wie kann man das Tool benutzerfreundlicher gestalten?

---

```python
import os
import shutil

# Definierter Quellordner (bitte anpassen)
source_folder = "Pfad/zum/Quellordner"

# Definition der Dateitypen und zugehörigen Zielordner
file_types = {
    'Bilder': ['.jpg', '.jpeg', '.png', '.gif'],
    'Dokumente': ['.pdf', '.docx', '.doc', '.txt'],
    'Musik': ['.mp3', '.wav', '.flac']
}

# Erstelle Zielordner, falls sie nicht existieren
for folder in file_types:
    target_path = os.path.join(source_folder, folder)
    if not os.path.exists(target_path):
        os.makedirs(target_path)

# Durchlaufe alle Dateien im Quellordner
for file_name in os.listdir(source_folder):
    file_path = os.path.join(source_folder, file_name)

    # Überspringe Ordner
    if os.path.isdir(file_path):
        continue

    # Bestimme Dateiendung
    _, ext = os.path.splitext(file_name)

    # Suche passenden Zielordner
    moved = False
    for folder, extensions in file_types.items():
        if ext.lower() in extensions:
            target_path = os.path.join(source_folder, folder, file_name)
            try:
                shutil.move(file_path, target_path)
                print(f"Verschoben: {file_name} → {folder}")
            except Exception as e:
                print(f"Fehler beim Verschieben von {file_name}: {e}")
            moved = True
            break

    if not moved:
        print(f"Keine Kategorie für: {file_name}")
```

## Tipps für den Erfolg
- Teste mit einem kleinen Satz an Dateien
- Nutze `print()` zur Kontrolle der Zwischenschritte
- Kommentiere deinen Code für bessere Lesbarkeit

---

## Fazit
Du hast ein praktisches Tool entwickelt, das dein Dateisystem organisiert. Dabei hast du wichtige Python-Konzepte wie Dateiverarbeitung, Fehlerbehandlung und Benutzerinteraktion angewendet.

**Nächste Schritte**:
- Erweiterung um weitere Dateitypen
- GUI mit `tkinter` oder `PyQt`
- Automatisierung mit Zeitintervallen (`schedule` oder `cron`)

**Quellen**:
- Python os-Modul Dokumentation
- Python shutil-Modul

---
