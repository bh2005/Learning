# Praxisorientierte Anleitung: Einfaches GUI für ein Python-Big-Data-Skript mit Tkinter

## Einführung
Python-Skripte sind für die Kommandozeile optimiert, können aber mit **Tkinter**, einer standardmäßigen GUI-Bibliothek, ein einfaches grafisches User Interface (GUI) erhalten, um die Benutzerinteraktion zu verbessern. Diese Anleitung erweitert die Python-Anleitung "Funktionen und Fehlerbehandlung" und zeigt, wie du ein GUI für das Skript `summary_functions.py` erstellst, das Datenanalysen durchführt und Markdown-Berichte generiert. Das GUI ermöglicht:
- Auswahl von Aktionen (Daten laden, Fehler zählen, Benutzerereignisse abrufen, Bericht erstellen).
- Eingabe von Parametern (z. B. Dateipfad, Benutzer-ID).
- Anzeige von Ergebnissen in einem Textbereich.
- Einen Fortschrittsbalken für langlaufende Aufgaben.

Die Übungen verwenden die JSON-Datei `sample_data.json` und die Funktionen aus `summary_functions.py`. Eine **Spielerei** integriert alle Funktionen in ein Hauptfenster mit interaktiven Schaltflächen. Die Übungen sind auf einem Debian-basierten System ausführbar und für Nutzer mit grundlegenden Python-Kenntnissen geeignet.

**Voraussetzungen**:
- Ein Debian-basiertes System (z. B. Ubuntu 22.04, Debian 11); Windows-Nutzer können WSL2 mit X-Server (z. B. Xming) verwenden; macOS ist kompatibel.
- Ein Terminal (z. B. Bash unter Linux).
- Installierte Tools:
  - Python 3 und `pip`: `sudo apt install python3 python3-pip`
  - Tkinter: `sudo apt install python3-tk`
  - Die Datei `sample_data.json` aus der vorherigen Anleitung.
- Grundkenntnisse in Python (Funktionen, Fehlerbehandlung, Datei-Ein-/Ausgabe).
- Sichere Testumgebung (z. B. `$HOME/python_functions` oder `~/python_functions`).
- Optional: `pandas` für erweiterte Analysen: `pip install pandas`.

## Grundlegende Konzepte und Befehle
Hier sind die wichtigsten Python- und Tkinter-Befehle für die Übungen:

1. **Tkinter-Befehle**:
   - `tkinter.Tk()`: Erstellt das Hauptfenster.
   - `tkinter.Label()`: Zeigt Text an.
   - `tkinter.Entry()`: Erstellt ein Eingabefeld.
   - `tkinter.Button()`: Erstellt eine Schaltfläche.
   - `tkinter.Text()`: Erstellt einen Textbereich für Ergebnisse.
   - `ttk.Progressbar()`: Zeigt einen Fortschrittsbalken an.
2. **Python-Funktionen** (aus `summary_functions.py`):
   - `load_data(file_path)`: Lädt JSON-Daten.
   - `count_events(data, event_type)`: Zählt Ereignisse.
   - `get_user_events(data, user_id)`: Gibt Benutzerereignisse zurück.
   - `generate_markdown_report(data, output_file)`: Erstellt einen Markdown-Bericht.
3. **Fehlerbehandlung und Logging**:
   - `try-except`: Fängt Ausnahmen.
   - `logging`: Protokolliert Fehler und Informationen.
4. **Nützliche Zusatzbefehle**:
   - `man python3`: Dokumentation für Python.
   - `help(tkinter)`: Dokumentation für Tkinter.
   - `echo` (Bash): Fügt Zeitstempel in Protokollen hinzu.

## Beispiel-Datensatz
Wir verwenden die JSON-Datei `sample_data.json` aus der vorherigen Anleitung:
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

### Übung 1: Tkinter installieren und testen
**Ziel**: Installiere Tkinter und teste ein einfaches GUI-Fenster.

1. **Schritt 1**: Wechsle in das Testverzeichnis:
   ```bash
   cd python_functions
   ```

2. **Schritt 2**: Installiere Tkinter:
   ```bash
   sudo apt install python3-tk
   ```

3. **Schritt 3**: Teste ein einfaches Tkinter-Fenster:
   ```bash
   nano test_tkinter.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import tkinter as tk
   import logging

   logging.basicConfig(filename="gui.log", level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

   def main():
       logging.info("Starte Tkinter-Test")
       root = tk.Tk()
       root.title("Testfenster")
       tk.Label(root, text="Tkinter funktioniert!").pack(pady=10)
       tk.Button(root, text="Schließen", command=root.quit).pack(pady=10)
       root.mainloop()
       logging.info("Tkinter-Test abgeschlossen")

   if __name__ == "__main__":
       main()
   ```
   Speichere und schließe.

4. **Schritt 4**: Führe das Skript aus:
   ```bash
   python3 test_tkinter.py
   ```

5. **Schritt 5**: Protokolliere die Ergebnisse:
   ```bash
   echo "Tkinter-Test am $(date)" >> functions_log.txt
   cat gui.log >> functions_log.txt
   cat functions_log.txt
   ```
   **Beispielausgabe** (`gui.log`):
   ```
   2025-09-05 14:20:00,123 - INFO - Starte Tkinter-Test
   2025-09-05 14:20:05,456 - INFO - Tkinter-Test abgeschlossen
   ```

**Reflexion**: Wie verbessert Tkinter die Benutzerinteraktion? Nutze `help(tkinter)` und überlege, wie du weitere GUI-Elemente hinzufügst.

### Übung 2: GUI für Daten laden
**Ziel**: Erstelle ein GUI, um die Daten aus `sample_data.json` zu laden und die Ergebnisse anzuzeigen.

1. **Schritt 1**: Stelle sicher, dass `sample_data.json` existiert (siehe vorherige Anleitung).

2. **Schritt 2**: Erstelle ein Skript mit GUI für das Laden der Daten:
   ```bash
   nano gui_load_data.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import tkinter as tk
   from tkinter import filedialog, messagebox
   import json
   import logging

   logging.basicConfig(filename="gui.log", level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

   class DataFormatError(Exception):
       pass

   def load_data(file_path):
       try:
           with open(file_path, 'r') as f:
               data = json.load(f)
               if not isinstance(data, list):
                   raise DataFormatError("Daten müssen eine Liste sein.")
               logging.info(f"Daten geladen: {file_path}")
               return data
       except FileNotFoundError:
           logging.error(f"Datei {file_path} nicht gefunden.")
           raise
       except json.JSONDecodeError:
           logging.error(f"Ungültiges JSON-Format in {file_path}.")
           raise
       except DataFormatError as e:
           logging.error(f"Formatfehler: {e}")
           raise

   def main():
       def select_file():
           file_path = filedialog.askopenfilename(filetypes=[("JSON-Dateien", "*.json")])
           if file_path:
               entry_file.delete(0, tk.END)
               entry_file.insert(0, file_path)

       def load_and_display():
           file_path = entry_file.get()
           try:
               data = load_data(file_path)
               text_result.delete(1.0, tk.END)
               text_result.insert(tk.END, f"Daten erfolgreich geladen:\n{json.dumps(data, indent=2)}")
           except Exception as e:
               messagebox.showerror("Fehler", str(e))
               text_result.delete(1.0, tk.END)
               text_result.insert(tk.END, f"Fehler: {str(e)}")

       root = tk.Tk()
       root.title("Daten laden")
       tk.Label(root, text="JSON-Datei:").grid(row=0, column=0, padx=5, pady=5)
       entry_file = tk.Entry(root, width=50)
       entry_file.grid(row=0, column=1, padx=5, pady=5)
       tk.Button(root, text="Durchsuchen", command=select_file).grid(row=0, column=2, padx=5, pady=5)
       tk.Button(root, text="Laden", command=load_and_display).grid(row=1, column=0, columnspan=3, pady=10)
       text_result = tk.Text(root, height=10, width=60)
       text_result.grid(row=2, column=0, columnspan=3, padx=5, pady=5)
       root.mainloop()

   if __name__ == "__main__":
       logging.info("Starte GUI-Datenladen")
       main()
       logging.info("GUI-Datenladen abgeschlossen")
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   python3 gui_load_data.py
   ```

4. **Schritt 4**: Protokolliere die Ergebnisse:
   ```bash
   echo "GUI-Datenladen am $(date)" >> functions_log.txt
   cat gui.log >> functions_log.txt
   cat functions_log.txt
   ```
   **Beispielausgabe** (`gui.log`):
   ```
   2025-09-05 14:25:00,123 - INFO - Starte GUI-Datenladen
   2025-09-05 14:25:05,456 - INFO - Daten geladen: sample_data.json
   2025-09-05 14:25:10,789 - INFO - GUI-Datenladen abgeschlossen
   ```

**Reflexion**: Wie erleichtert ein GUI das Laden von Daten? Nutze `help(tkinter.filedialog)` und überlege, wie du weitere Eingaben (z. B. Dateitypen) hinzufügst.

### Übung 3: GUI für Fehleranalyse
**Ziel**: Erstelle ein GUI, um Fehlerereignisse zu zählen und Benutzerereignisse anzuzeigen.

1. **Schritt 1**: Erstelle ein Skript mit GUI für die Analyse:
   ```bash
   nano gui_analyze.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import tkinter as tk
   from tkinter import filedialog, messagebox
   import json
   import logging

   logging.basicConfig(filename="gui.log", level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

   class DataFormatError(Exception):
       pass

   def load_data(file_path):
       try:
           with open(file_path, 'r') as f:
               data = json.load(f)
               if not isinstance(data, list):
                   raise DataFormatError("Daten müssen eine Liste sein.")
               logging.info(f"Daten geladen: {file_path}")
               return data
       except FileNotFoundError:
           logging.error(f"Datei {file_path} nicht gefunden.")
           raise
       except json.JSONDecodeError:
           logging.error(f"Ungültiges JSON-Format in {file_path}.")
           raise
       except DataFormatError as e:
           logging.error(f"Formatfehler: {e}")
           raise

   def count_events(data, event_type=None):
       try:
           if event_type:
               return sum(1 for entry in data if entry["event"] == event_type)
           return len(data)
       except KeyError:
           logging.error("Ungültiges Datenformat (fehlender 'event'-Schlüssel).")
           raise

   def get_user_events(data, user_id):
       try:
           if not isinstance(user_id, int):
               raise ValueError("User ID muss eine Ganzzahl sein.")
           return [entry["event"] for entry in data if entry["user_id"] == user_id]
       except KeyError:
           logging.error("Ungültiges Datenformat (fehlender 'user_id'-Schlüssel).")
           raise
       except ValueError as e:
           logging.error(f"Eingabefehler: {e}")
           raise

   def main():
       def select_file():
           file_path = filedialog.askopenfilename(filetypes=[("JSON-Dateien", "*.json")])
           if file_path:
               entry_file.delete(0, tk.END)
               entry_file.insert(0, file_path)

       def analyze_data():
           file_path = entry_file.get()
           user_id = entry_user_id.get()
           try:
               data = load_data(file_path)
               total_events = count_events(data)
               error_count = count_events(data, "ERROR")
               user_id = int(user_id) if user_id else 1
               user_events = get_user_events(data, user_id)
               text_result.delete(1.0, tk.END)
               text_result.insert(tk.END, f"Gesamtereignisse: {total_events}\n")
               text_result.insert(tk.END, f"Fehlerereignisse: {error_count}\n")
               text_result.insert(tk.END, f"Ereignisse für User {user_id}: {user_events}")
               logging.info(f"Analyse: Gesamtereignisse={total_events}, Fehler={error_count}, User {user_id}={user_events}")
           except Exception as e:
               messagebox.showerror("Fehler", str(e))
               text_result.delete(1.0, tk.END)
               text_result.insert(tk.END, f"Fehler: {str(e)}")

       root = tk.Tk()
       root.title("Fehleranalyse")
       tk.Label(root, text="JSON-Datei:").grid(row=0, column=0, padx=5, pady=5)
       entry_file = tk.Entry(root, width=50)
       entry_file.grid(row=0, column=1, padx=5, pady=5)
       tk.Button(root, text="Durchsuchen", command=select_file).grid(row=0, column=2, padx=5, pady=5)
       tk.Label(root, text="User ID:").grid(row=1, column=0, padx=5, pady=5)
       entry_user_id = tk.Entry(root, width=10)
       entry_user_id.grid(row=1, column=1, sticky="w", padx=5, pady=5)
       tk.Button(root, text="Analysieren", command=analyze_data).grid(row=2, column=0, columnspan=3, pady=10)
       text_result = tk.Text(root, height=10, width=60)
       text_result.grid(row=3, column=0, columnspan=3, padx=5, pady=5)
       root.mainloop()

   if __name__ == "__main__":
       logging.info("Starte GUI-Fehleranalyse")
       main()
       logging.info("GUI-Fehleranalyse abgeschlossen")
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   python3 gui_analyze.py
   ```

3. **Schritt 3**: Protokolliere die Ergebnisse:
   ```bash
   echo "GUI-Fehleranalyse am $(date)" >> functions_log.txt
   cat gui.log >> functions_log.txt
   cat functions_log.txt
   ```
   **Beispielausgabe** (`gui.log`):
   ```
   2025-09-05 14:30:00,123 - INFO - Starte GUI-Fehleranalyse
   2025-09-05 14:30:05,456 - INFO - Daten geladen: sample_data.json
   2025-09-05 14:30:05,789 - INFO - Analyse: Gesamtereignisse=5, Fehler=1, User 1=['LOGIN', 'VIEW_PAGE']
   2025-09-05 14:30:10,012 - INFO - GUI-Fehleranalyse abgeschlossen
   ```

**Reflexion**: Wie verbessert ein GUI die Fehleranalyse? Nutze `help(tkinter)` und überlege, wie du weitere Analysen (z. B. andere Ereignistypen) hinzufügst.

### Übung 4: GUI für Markdown-Bericht
**Ziel**: Erstelle ein GUI, um einen Markdown-Bericht zu generieren und anzuzeigen.

1. **Schritt 1**: Erstelle ein Skript mit GUI für die Berichterstellung:
   ```bash
   nano gui_summary.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import tkinter as tk
   from tkinter import filedialog, messagebox
   from tkinter import ttk
   import json
   import logging
   from datetime import datetime

   logging.basicConfig(filename="gui.log", level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

   class DataFormatError(Exception):
       pass

   def load_data(file_path):
       try:
           with open(file_path, 'r') as f:
               data = json.load(f)
               if not isinstance(data, list):
                   raise DataFormatError("Daten müssen eine Liste sein.")
               logging.info(f"Daten geladen: {file_path}")
               return data
       except FileNotFoundError:
           logging.error(f"Datei {file_path} nicht gefunden.")
           raise
       except json.JSONDecodeError:
           logging.error(f"Ungültiges JSON-Format in {file_path}.")
           raise
       except DataFormatError as e:
           logging.error(f"Formatfehler: {e}")
           raise

   def count_events(data, event_type=None):
       try:
           if event_type:
               return sum(1 for entry in data if entry["event"] == event_type)
           return len(data)
       except KeyError:
           logging.error("Ungültiges Datenformat (fehlender 'event'-Schlüssel).")
           raise

   def get_user_events(data, user_id):
       try:
           if not isinstance(user_id, int):
               raise ValueError("User ID muss eine Ganzzahl sein.")
           return [entry["event"] for entry in data if entry["user_id"] == user_id]
       except KeyError:
           logging.error("Ungültiges Datenformat (fehlender 'user_id'-Schlüssel).")
           raise
       except ValueError as e:
           logging.error(f"Eingabefehler: {e}")
           raise

   def generate_markdown_report(data, output_file):
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
           return output_file
       except Exception as e:
           logging.error(f"Fehler beim Erstellen des Berichts: {e}")
           raise

   def main():
       def select_file():
           file_path = filedialog.askopenfilename(filetypes=[("JSON-Dateien", "*.json")])
           if file_path:
               entry_file.delete(0, tk.END)
               entry_file.insert(0, file_path)

       def generate_report():
           file_path = entry_file.get()
           output_file = entry_output.get()
           if not output_file:
               output_file = "analysis_report.md"
           try:
               progress["value"] = 0
               root.update()
               data = load_data(file_path)
               progress["value"] = 50
               root.update()
               generate_markdown_report(data, output_file)
               progress["value"] = 100
               root.update()
               with open(output_file, "r") as f:
                   report_content = f.read()
               text_result.delete(1.0, tk.END)
               text_result.insert(tk.END, report_content)
               messagebox.showinfo("Erfolg", f"Bericht erstellt: {output_file}")
           except Exception as e:
               messagebox.showerror("Fehler", str(e))
               text_result.delete(1.0, tk.END)
               text_result.insert(tk.END, f"Fehler: {str(e)}")
               progress["value"] = 0

       root = tk.Tk()
       root.title("Berichtserstellung")
       tk.Label(root, text="JSON-Datei:").grid(row=0, column=0, padx=5, pady=5)
       entry_file = tk.Entry(root, width=50)
       entry_file.grid(row=0, column=1, padx=5, pady=5)
       tk.Button(root, text="Durchsuchen", command=select_file).grid(row=0, column=2, padx=5, pady=5)
       tk.Label(root, text="Ausgabedatei:").grid(row=1, column=0, padx=5, pady=5)
       entry_output = tk.Entry(root, width=50)
       entry_output.insert(0, "analysis_report.md")
       entry_output.grid(row=1, column=1, padx=5, pady=5)
       tk.Button(root, text="Bericht erstellen", command=generate_report).grid(row=2, column=0, columnspan=3, pady=10)
       progress = ttk.Progressbar(root, length=300, mode="determinate")
       progress.grid(row=3, column=0, columnspan=3, pady=5)
       text_result = tk.Text(root, height=10, width=60)
       text_result.grid(row=4, column=0, columnspan=3, padx=5, pady=5)
       root.mainloop()

   if __name__ == "__main__":
       logging.info("Starte GUI-Berichtserstellung")
       main()
       logging.info("GUI-Berichtserstellung abgeschlossen")
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   python3 gui_summary.py
   ```

3. **Schritt 3**: Überprüfe den Bericht:
   ```bash
   cat analysis_report.md
   ```
   **Beispielausgabe** (`analysis_report.md`):
   ```
   # Datenanalyse-Bericht
   Erstellt am: 2025-09-05 14:35:00

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
   echo "GUI-Berichtserstellung am $(date)" >> functions_log.txt
   cat gui.log >> functions_log.txt
   cat functions_log.txt
   ```
   **Beispielausgabe** (`gui.log`):
   ```
   2025-09-05 14:35:00,123 - INFO - Starte GUI-Berichtserstellung
   2025-09-05 14:35:05,456 - INFO - Daten geladen: sample_data.json
   2025-09-05 14:35:05,789 - INFO - Markdown-Bericht erstellt: analysis_report.md
   2025-09-05 14:35:10,012 - INFO - GUI-Berichtserstellung abgeschlossen
   ```

**Reflexion**: Wie verbessert ein GUI die Berichterstellung? Nutze `help(ttk.Progressbar)` und überlege, wie du den Bericht speicherst oder versendest.

### Übung 5: Spielerei – Hauptmenü mit GUI
**Ziel**: Erstelle ein Hauptmenü, das alle Aktionen (Daten laden, Fehleranalyse, Berichtserstellung) integriert.

1. **Schritt 1**: Erstelle ein Skript mit einem GUI-Hauptmenü:
   ```bash
   nano gui_main.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import tkinter as tk
   from tkinter import filedialog, messagebox
   from tkinter import ttk
   import json
   import logging
   from datetime import datetime

   logging.basicConfig(filename="gui.log", level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

   class DataFormatError(Exception):
       pass

   def load_data(file_path):
       try:
           with open(file_path, 'r') as f:
               data = json.load(f)
               if not isinstance(data, list):
                   raise DataFormatError("Daten müssen eine Liste sein.")
               logging.info(f"Daten geladen: {file_path}")
               return data
       except FileNotFoundError:
           logging.error(f"Datei {file_path} nicht gefunden.")
           raise
       except json.JSONDecodeError:
           logging.error(f"Ungültiges JSON-Format in {file_path}.")
           raise
       except DataFormatError as e:
           logging.error(f"Formatfehler: {e}")
           raise

   def count_events(data, event_type=None):
       try:
           if event_type:
               return sum(1 for entry in data if entry["event"] == event_type)
           return len(data)
       except KeyError:
           logging.error("Ungültiges Datenformat (fehlender 'event'-Schlüssel).")
           raise

   def get_user_events(data, user_id):
       try:
           if not isinstance(user_id, int):
               raise ValueError("User ID muss eine Ganzzahl sein.")
           return [entry["event"] for entry in data if entry["user_id"] == user_id]
       except KeyError:
           logging.error("Ungültiges Datenformat (fehlender 'user_id'-Schlüssel).")
           raise
       except ValueError as e:
           logging.error(f"Eingabefehler: {e}")
           raise

   def generate_markdown_report(data, output_file):
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
           return output_file
       except Exception as e:
           logging.error(f"Fehler beim Erstellen des Berichts: {e}")
           raise

   def main():
       data = None

       def select_file():
           file_path = filedialog.askopenfilename(filetypes=[("JSON-Dateien", "*.json")])
           if file_path:
               entry_file.delete(0, tk.END)
               entry_file.insert(0, file_path)

       def load_and_display():
           nonlocal data
           file_path = entry_file.get()
           try:
               progress["value"] = 0
               root.update()
               data = load_data(file_path)
               progress["value"] = 100
               root.update()
               text_result.delete(1.0, tk.END)
               text_result.insert(tk.END, f"Daten erfolgreich geladen:\n{json.dumps(data, indent=2)}")
               messagebox.showinfo("Erfolg", "Daten geladen")
           except Exception as e:
               messagebox.showerror("Fehler", str(e))
               text_result.delete(1.0, tk.END)
               text_result.insert(tk.END, f"Fehler: {str(e)}")
               progress["value"] = 0

       def analyze_data():
           nonlocal data
           user_id = entry_user_id.get()
           if not data:
               messagebox.showerror("Fehler", "Bitte zuerst Daten laden")
               return
           try:
               progress["value"] = 0
               root.update()
               total_events = count_events(data)
               progress["value"] = 33
               root.update()
               error_count = count_events(data, "ERROR")
               progress["value"] = 66
               root.update()
               user_id = int(user_id) if user_id else 1
               user_events = get_user_events(data, user_id)
               progress["value"] = 100
               root.update()
               text_result.delete(1.0, tk.END)
               text_result.insert(tk.END, f"Gesamtereignisse: {total_events}\n")
               text_result.insert(tk.END, f"Fehlerereignisse: {error_count}\n")
               text_result.insert(tk.END, f"Ereignisse für User {user_id}: {user_events}")
               logging.info(f"Analyse: Gesamtereignisse={total_events}, Fehler={error_count}, User {user_id}={user_events}")
               messagebox.showinfo("Erfolg", "Analyse abgeschlossen")
           except Exception as e:
               messagebox.showerror("Fehler", str(e))
               text_result.delete(1.0, tk.END)
               text_result.insert(tk.END, f"Fehler: {str(e)}")
               progress["value"] = 0

       def generate_report():
           nonlocal data
           output_file = entry_output.get()
           if not output_file:
               output_file = "analysis_report.md"
           if not data:
               messagebox.showerror("Fehler", "Bitte zuerst Daten laden")
               return
           try:
               progress["value"] = 0
               root.update()
               output_file = generate_markdown_report(data, output_file)
               progress["value"] = 100
               root.update()
               with open(output_file, "r") as f:
                   report_content = f.read()
               text_result.delete(1.0, tk.END)
               text_result.insert(tk.END, report_content)
               messagebox.showinfo("Erfolg", f"Bericht erstellt: {output_file}")
           except Exception as e:
               messagebox.showerror("Fehler", str(e))
               text_result.delete(1.0, tk.END)
               text_result.insert(tk.END, f"Fehler: {str(e)}")
               progress["value"] = 0

       root = tk.Tk()
       root.title("Datenanalyse")
       tk.Label(root, text="JSON-Datei:").grid(row=0, column=0, padx=5, pady=5)
       entry_file = tk.Entry(root, width=50)
       entry_file.grid(row=0, column=1, padx=5, pady=5)
       tk.Button(root, text="Durchsuchen", command=select_file).grid(row=0, column=2, padx=5, pady=5)
       tk.Label(root, text="User ID:").grid(row=1, column=0, padx=5, pady=5)
       entry_user_id = tk.Entry(root, width=10)
       entry_user_id.grid(row=1, column=1, sticky="w", padx=5, pady=5)
       tk.Label(root, text="Ausgabedatei:").grid(row=2, column=0, padx=5, pady=5)
       entry_output = tk.Entry(root, width=50)
       entry_output.insert(0, "analysis_report.md")
       entry_output.grid(row=2, column=1, padx=5, pady=5)
       tk.Button(root, text="Daten laden", command=load_and_display).grid(row=3, column=0, pady=5)
       tk.Button(root, text="Analysieren", command=analyze_data).grid(row=3, column=1, pady=5)
       tk.Button(root, text="Bericht erstellen", command=generate_report).grid(row=3, column=2, pady=5)
       progress = ttk.Progressbar(root, length=300, mode="determinate")
       progress.grid(row=4, column=0, columnspan=3, pady=5)
       text_result = tk.Text(root, height=10, width=60)
       text_result.grid(row=5, column=0, columnspan=3, padx=5, pady=5)
       root.mainloop()

   if __name__ == "__main__":
       logging.info("Starte GUI-Hauptmenü")
       main()
       logging.info("GUI-Hauptmenü abgeschlossen")
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   python3 gui_main.py
   ```

3. **Schritt 3**: Protokolliere die Ergebnisse:
   ```bash
   echo "GUI-Hauptmenü am $(date)" >> functions_log.txt
   cat gui.log >> functions_log.txt
   cat functions_log.txt
   ```
   **Beispielausgabe** (`gui.log`, nach Ausführung aller Aktionen):
   ```
   2025-09-05 14:40:00,123 - INFO - Starte GUI-Hauptmenü
   2025-09-05 14:40:05,456 - INFO - Daten geladen: sample_data.json
   2025-09-05 14:40:10,789 - INFO - Analyse: Gesamtereignisse=5, Fehler=1, User 1=['LOGIN', 'VIEW_PAGE']
   2025-09-05 14:40:15,012 - INFO - Markdown-Bericht erstellt: analysis_report.md
   2025-09-05 14:40:20,345 - INFO - GUI-Hauptmenü abgeschlossen
   ```

**Reflexion**: Wie verbessert ein GUI-Hauptmenü die Benutzerfreundlichkeit? Nutze `help(tkinter)` und überlege, wie du weitere Funktionen (z. B. E-Mail-Versand) hinzufügst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Tkinter und GUI-Entwicklung zu verinnerlichen.
- **Sicheres Testen**: Arbeite in einer Testumgebung und sichere Dateien (`cp sample_data.json sample_data.json.bak`).
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze `help(tkinter)`, `help(logging)` oder die Python-Dokumentation.
- **Effiziente Entwicklung**: Nutze Tkinter für einfache GUIs, Funktionen für Modularität und Logging für Nachvollziehbarkeit.
- **Kombiniere Tools**: Integriere `pandas` für erweiterte Analysen oder `smtplib` für E-Mail-Versand.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Hinzufügen von Visualisierungen (via `matplotlib`) oder komplexere GUI-Elemente (z. B. Dropdown-Menüs).

## Fazit
Mit diesen Übungen hast du gelernt, ein einfaches GUI mit Tkinter für ein Python-Skript zu erstellen, das Datenanalysen durchführt und Markdown-Berichte generiert. Du hast Dialogfenster für Datenladen, Fehleranalyse und Berichterstellung implementiert und ein Hauptmenü entwickelt, das alle Aktionen integriert. Die Spielerei zeigt, wie du Benutzerinteraktionen mit GUI verbesserst. Vertiefe dein Wissen, indem du fortgeschrittene Themen (z. B. komplexe Tkinter-Formulare, Matplotlib-Integration) oder Tools wie `PyQt` oder `wxPython` ausprobierst. Wenn du ein spezifisches Thema (z. B. E-Mail-Versand oder Visualisierung) vertiefen möchtest, lass es mich wissen!
