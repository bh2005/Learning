# Praxisorientierte Anleitung: **Dateiorganisierer mit GUI (PyQt)**

## Einführung

In diesem Projekt erstellen wir die gleiche grafische Benutzeroberfläche wie zuvor, aber mit der leistungsstarken **`PyQt`**-Bibliothek. Du wirst lernen, wie professionelle Desktop-Anwendungen mit einem **klassenbasierten, objektorientierten Ansatz** entwickelt werden.

**Hinweis**: `PyQt` ist nicht Teil der Standardbibliothek. Du musst es zuerst installieren.

**Voraussetzungen**:

  - Python 3.x
  - Installation von `PyQt6`: `pip install PyQt6`
  - Dein funktionierendes Dateiorganisierer-Skript

-----

## Grundlegende GUI-Techniken mit `PyQt`

Hier sind die wichtigsten Konzepte, die wir behandeln:

1.  **Installation**: `pip install PyQt6` ist der erste Schritt.
2.  **Klassenbasiert**: Eine Anwendung ist eine Klasse, die von einem **`QWidget`** oder **`QMainWindow`** erbt.
3.  **Widgets**: Bausteine mit dem `Q`-Präfix (`QLabel`, `QLineEdit`, `QPushButton`).
4.  **Layout-Manager**: Manager wie **`QVBoxLayout`** oder `QHBoxLayout`, die Widgets automatisch anordnen.
5.  **Signale und Slots**: Das Konzept, das Widgets und Funktionen miteinander verbindet (`.clicked.connect()`).

-----

## Übungen zum Verinnerlichen

### Übung 1: Das Anwendungsfenster als Klasse erstellen

**Ziel**: Ein leeres Fenster erstellen und anzeigen.

1.  **Schritt 1**: Importiere die notwendigen Module
    ```python
    import sys
    from PyQt6.QtWidgets import QApplication, QWidget
    ```
2.  **Schritt 2**: Erstelle eine Klasse für deine Hauptanwendung
    ```python
    class FileSorterApp(QWidget):
        def __init__(self):
            super().__init__()
            self.setWindowTitle("Dateiorganisierer mit PyQt")
            self.setGeometry(100, 100, 400, 150)
    ```
3.  **Schritt 3**: Erstelle die Hauptanwendung und zeige das Fenster an
    ```python
    app = QApplication(sys.argv)
    window = FileSorterApp()
    window.show()
    sys.exit(app.exec())
    ```

**Reflexion**: Was ist der Vorteil, das Fenster in eine eigene Klasse zu packen? Was ist die Aufgabe von `QApplication`?

-----

### Übung 2: Widgets und Layout hinzufügen

**Ziel**: Füge die nötigen Elemente in einem Layout an.

1.  **Schritt 1**: Importiere weitere Widgets und den Layout-Manager
    ```python
    from PyQt6.QtWidgets import QApplication, QWidget, QVBoxLayout, QLabel, QLineEdit, QPushButton
    ```
2.  **Schritt 2**: Erstelle eine `initUI`-Methode in deiner `FileSorterApp`-Klasse, um die Widgets zu erstellen. Rufe diese Methode im `__init__`-Konstruktor auf.
    ```python
    def initUI(self):
        # Layout und Widgets erstellen
        layout = QVBoxLayout()
        self.label = QLabel("Gib den Pfad zum Quellordner ein:")
        self.entry = QLineEdit()
        self.button = QPushButton("Sortieren starten")
        
        layout.addWidget(self.label)
        layout.addWidget(self.entry)
        layout.addWidget(self.button)
        
        self.setLayout(layout)
    ```

**Reflexion**: Was ist der Unterschied zwischen der `pack()`-Methode in `tkinter` und einem `QVBoxLayout` in `PyQt`?

-----

### Übung 3: Logik mit Slots verbinden

**Ziel**: Verbinde den Button mit deiner Sortierlogik.

1.  **Schritt 1**: Erstelle eine Methode (einen sogenannten **Slot**) in deiner Klasse, die deine gesamte Sortierlogik enthält. Greife auf das Textfeld mit `self.entry.text()` zu.
2.  **Schritt 2**: Verbinde das `clicked`-Signal des Buttons mit deiner Methode.
    ```python
    self.button.clicked.connect(self.sort_files)
    ```
3.  **Schritt 3**: Zeige Statusmeldungen mit **`QMessageBox`** an.

**Reflexion**: Wie unterscheidet sich das **Signal-und-Slot**-Konzept von der direkten Funktionszuweisung bei `tkinter`?

-----

```python
import sys
from PyQt6.QtWidgets import QApplication, QWidget, QVBoxLayout, QLabel, QLineEdit, QPushButton, QMessageBox
import os
import shutil

# Definition der Dateitypen und zugehörigen Zielordner
file_types = {
    'Bilder': ['.jpg', '.jpeg', '.png', '.gif'],
    'Dokumente': ['.pdf', '.docx', '.doc', '.txt'],
    'Musik': ['.mp3', '.wav', '.flac']
}

class FileSorterApp(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Dateiorganisierer mit PyQt")
        self.setGeometry(100, 100, 400, 150)
        self.initUI()

    def initUI(self):
        layout = QVBoxLayout()
        
        self.label = QLabel("Gib den Pfad zum Quellordner ein:")
        self.entry = QLineEdit()
        self.button = QPushButton("Sortieren starten")
        
        layout.addWidget(self.label)
        layout.addWidget(self.entry)
        layout.addWidget(self.button)
        
        self.setLayout(layout)
        
        # Verbindung des Buttons mit der Sortierfunktion
        self.button.clicked.connect(self.sort_files)

    def sort_files(self):
        source_folder = self.entry.text()
        
        if not os.path.exists(source_folder):
            QMessageBox.critical(self, "Fehler", "Der angegebene Pfad existiert nicht!")
            return
            
        try:
            for folder in file_types:
                target_path = os.path.join(source_folder, folder)
                if not os.path.exists(target_path):
                    os.makedirs(target_path)
            
            for file_name in os.listdir(source_folder):
                file_path = os.path.join(source_folder, file_name)

                if os.path.isdir(file_path):
                    continue

                _, ext = os.path.splitext(file_name)

                for folder, extensions in file_types.items():
                    if ext.lower() in extensions:
                        shutil.move(file_path, os.path.join(source_folder, folder, file_name))
                        break
            
            QMessageBox.information(self, "Erfolg", "Sortierung abgeschlossen!")
            
        except Exception as e:
            QMessageBox.critical(self, "Fehler", f"Ein Fehler ist aufgetreten: {e}")

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = FileSorterApp()
    window.show()
    sys.exit(app.exec())

```

## Fazit

Du hast nun eine vollwertige Desktop-Anwendung mit `PyQt` erstellt, die professioneller aussieht und robuster ist als die `tkinter`-Version. Du hast gelernt, wie man objektorientiert in der GUI-Programmierung arbeitet und die mächtigen **`Signals`** und **`Slots`** von `PyQt` nutzt.

**Nächste Schritte**:

  - **Professioneller Dialog**: Ersetze das Eingabefeld durch einen **`QPushButton`**, der einen **`QFileDialog`** öffnet, um einen Ordner auszuwählen.
  - **Benutzer-Feedback**: Füge eine Fortschrittsanzeige hinzu, die den Status des Sortiervorgangs anzeigt.
  - **Multi-Threading**: Führe den Sortiervorgang in einem separaten Thread aus, damit das Hauptfenster nicht blockiert wird.