# Praxisorientierte Anleitung: **Dateiorganisierer mit GUI (tkinter)**

## Einführung

In diesem Projekt bauen wir eine einfache Benutzeroberfläche für deinen Dateiorganisierer. Wir ersetzen die manuelle Eingabe des Pfades in der Konsole durch ein grafisches Fenster. Das Projekt hilft dir, die grundlegenden Konzepte der GUI-Programmierung mit der Standardbibliothek `tkinter` zu verstehen.

**Nutzen**: Dein Tool wird benutzerfreundlicher und intuitiv bedienbar.

**Voraussetzungen**:

  - Dein funktionierendes **Dateiorganisierer-Skript** (aus dem vorherigen Projekt)
  - Python 3.x (mit `tkinter` bereits enthalten)
  - Grundkenntnisse in Python und deinem Skript

-----

## Grundlegende GUI-Techniken mit `tkinter`

Hier sind die wichtigsten Konzepte, die wir behandeln:

1.  **Fenster erstellen**: Das Hauptfenster (`Tk`) ist die Basis deiner Anwendung.
2.  **Widgets**: Die grafischen Bausteine (`Label`, `Button`, `Entry`) für Text, Schaltflächen und Eingabefelder.
3.  **Layout-Manager**: Methoden wie `pack()` oder `grid()`, um Widgets im Fenster anzuordnen.
4.  **Ereignis-Schleife**: `mainloop()` hält das Fenster aktiv und wartet auf Benutzereingaben.

-----

## Übungen zum Verinnerlichen

### Übung 1: Das Anwendungsfenster erstellen

**Ziel**: Ein leeres Fenster mit einem Titel anzeigen.

1.  **Schritt 1**: Importiere das `tkinter`-Modul
        ` python     import tkinter as tk      `
2.  **Schritt 2**: Erstelle das Hauptfenster
        ` python     root = tk.Tk()     root.title("Dateiorganisierer")      `
3.  **Schritt 3**: Starte die Ereignis-Schleife
        ` python     root.mainloop()      `
4.  **Schritt 4**: Führe das Skript aus und schließe das Fenster wieder.

**Reflexion**: Warum ist `root.mainloop()` notwendig? Was würde passieren, wenn du es weglässt?

-----

### Übung 2: Widgets hinzufügen

**Ziel**: Füge die nötigen Elemente für die Benutzerinteraktion hinzu.

1.  **Schritt 1**: Erstelle ein `Label` für die Anweisung
        ` python     label = tk.Label(root, text="Gib den Pfad zum Ordner ein:")     label.pack()      `
2.  **Schritt 2**: Erstelle ein `Entry`-Feld für die Pfadeingabe
        ` python     entry = tk.Entry(root, width=50)     entry.pack()      `
3.  **Schritt 3**: Füge einen `Button` hinzu, der die Aktion auslöst
        ` python     button = tk.Button(root, text="Sortieren starten")     button.pack()      `
4.  **Schritt 4**: Führe das Skript erneut aus und sieh dir die Benutzeroberfläche an.

**Reflexion**: Was bewirkt die Methode `pack()`? Was würde passieren, wenn du ein Widget nicht "packst"?

-----

### Übung 3: Die Logik verbinden

**Ziel**: Verbinde den Button mit deiner Sortierlogik.

1.  **Schritt 1**: Erstelle eine Funktion, die deine gesamte Sortierlogik enthält. Diese Funktion soll den Pfad aus dem `Entry`-Feld auslesen.
2.  **Schritt 2**: Verknüpfe diese Funktion mit dem `Button`-Widget, indem du den `command`-Parameter verwendest.
        ` python     button = tk.Button(root, text="Sortieren starten", command=deine_sortier_funktion)      `
3.  **Schritt 3**: Füge eine `Label`-Komponente hinzu, um Statusmeldungen anzuzeigen (z. B. "Sortierung abgeschlossen\!").

**Reflexion**: Wie unterscheidet sich diese "Ereignis-gesteuerte" Programmierung von der sequenziellen Ausführung deines ersten Skripts?

-----

```python
import tkinter as tk
from tkinter import messagebox
import os
import shutil

# Definition der Dateitypen und zugehörigen Zielordner
file_types = {
    'Bilder': ['.jpg', '.jpeg', '.png', '.gif'],
    'Dokumente': ['.pdf', '.docx', '.doc', '.txt'],
    'Musik': ['.mp3', '.wav', '.flac']
}

def sort_files():
    source_folder = entry.get()
    if not os.path.exists(source_folder):
        messagebox.showerror("Fehler", "Der angegebene Pfad existiert nicht!")
        return

    try:
        # Erstelle Zielordner, falls sie nicht existieren
        for folder in file_types:
            target_path = os.path.join(source_folder, folder)
            if not os.path.exists(target_path):
                os.makedirs(target_path)
        
        # Durchlaufe alle Dateien im Quellordner
        for file_name in os.listdir(source_folder):
            file_path = os.path.join(source_folder, file_name)

            if os.path.isdir(file_path):
                continue

            _, ext = os.path.splitext(file_name)

            for folder, extensions in file_types.items():
                if ext.lower() in extensions:
                    shutil.move(file_path, os.path.join(source_folder, folder, file_name))
                    break
        
        messagebox.showinfo("Erfolg", "Sortierung abgeschlossen!")

    except Exception as e:
        messagebox.showerror("Fehler", f"Ein Fehler ist aufgetreten: {e}")

# Erstelle das Hauptfenster
root = tk.Tk()
root.title("Dateiorganisierer mit GUI")
root.geometry("400x150")

# Widgets
label = tk.Label(root, text="Gib den Pfad zum Quellordner ein:")
label.pack(pady=10)

entry = tk.Entry(root, width=50)
entry.pack(pady=5)

button = tk.Button(root, text="Sortieren starten", command=sort_files)
button.pack(pady=10)

root.mainloop()
```

## Fazit

Du hast erfolgreich eine grafische Oberfläche für deinen Dateiorganisierer erstellt\! Dein Skript ist jetzt eine intuitive Anwendung, die jeder nutzen kann. Dabei hast du gelernt, wie man Fenster, Widgets und ereignisgesteuerte Logik in Python erstellt.

**Nächste Schritte**:

  - **Design-Verbesserung**: Nutze den `grid()`-Manager für ein saubereres Layout.
  - **Erweiterte Funktionen**: Füge einen "Durchsuchen"-Button hinzu, der einen Dateiauswahldialog öffnet.
  - **Fortgeschrittene GUI-Bibliotheken**: Probiere `PyQt` oder `wxPython` aus, um leistungsfähigere und professionellere Oberflächen zu erstellen.