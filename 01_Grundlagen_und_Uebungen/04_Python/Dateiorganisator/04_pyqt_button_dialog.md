## Grundlegende PyQt-Techniken: Dialog und Fortschritt

Bevor wir starten, hier die neuen Bausteine, die wir benötigen:

1.  **`QFileDialog`**: Ein Standard-Dialog, der dem Nutzer eine einfache und sichere Möglichkeit bietet, ein Verzeichnis über das native Betriebssystemfenster auszuwählen.
2.  **`QProgressBar`**: Ein Widget, das den Fortschritt eines Vorgangs visuell anzeigt. Es ist entscheidend für die **User Experience** bei längeren Operationen.
3.  **`QApplication.processEvents()`**: Eine wichtige Methode, um die GUI am Leben zu erhalten. Wenn wir eine lange Schleife ausführen, wird die GUI blockiert. Dieser Befehl verarbeitet ausstehende Ereignisse (wie das Aktualisieren der Fortschrittsanzeige), ohne die Schleife zu unterbrechen.

-----

### Übungen zum Verinnerlichen

### Übung 1: Ordnerauswahl mit Dialog hinzufügen

**Ziel**: Ersetze das manuelle Eingabefeld durch einen Button und einen **`QFileDialog`**.

1.  **Schritt 1**: Ersetze in deiner `initUI`-Methode das `QLineEdit` mit einem **`QPushButton`** namens `browse_button` und einem **`QLineEdit`** zur Anzeige des Pfades. Lege die beiden Widgets in einem **`QHBoxLayout`** an, um sie nebeneinander zu platzieren.
2.  **Schritt 2**: Erstelle eine neue Methode in deiner Klasse, z.B. `browse_folder()`. Diese Methode ruft **`QFileDialog.getExistingDirectory()`** auf.
3.  **Schritt 3**: Weist den ausgewählten Pfad dem Textfeld zu.
4.  **Schritt 4**: Verbinde den **`browse_button`** mit deiner neuen Methode: `self.browse_button.clicked.connect(self.browse_folder)`.

**Reflexion**: Warum ist ein Dateiauswahldialog benutzerfreundlicher als ein einfaches Textfeld?

-----

### Übung 2: Eine Fortschrittsanzeige integrieren

**Ziel**: Zeige dem Benutzer visuell, wie viele Dateien bereits sortiert wurden.

1.  **Schritt 1**: Füge in deiner `initUI`-Methode eine **`QProgressBar`** zum Layout hinzu. Setze sie auf den Startwert `0`.
2.  **Schritt 2**: Passe deine `sort_files()`-Methode an. Zähle zunächst die Gesamtzahl der Dateien, die sortiert werden müssen.
3.  **Schritt 3**: Setze den maximalen Wert der `QProgressBar` auf diese Anzahl.
4.  **Schritt 4**: Führe die Sortierschleife aus. Innerhalb der Schleife inkrementiere den Wert der Fortschrittsanzeige und rufe `QApplication.processEvents()` auf, um die GUI zu aktualisieren.

**Reflexion**: Welchen psychologischen Effekt hat eine Fortschrittsanzeige auf den Benutzer bei einem langwierigen Prozess?

-----

```python
import sys
from PyQt6.QtWidgets import QApplication, QWidget, QVBoxLayout, QLabel, QLineEdit, QPushButton, QMessageBox, QFileDialog, QProgressBar
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
        self.setWindowTitle("Dateiorganisierer Pro")
        self.setGeometry(100, 100, 500, 200)
        self.initUI()

    def initUI(self):
        # Haupt-Layout für die gesamte Oberfläche
        main_layout = QVBoxLayout()
        
        # Widgets zur Pfadauswahl
        path_layout = QHBoxLayout()
        self.path_entry = QLineEdit()
        self.browse_button = QPushButton("Durchsuchen...")
        
        path_layout.addWidget(self.path_entry)
        path_layout.addWidget(self.browse_button)

        # Status und Fortschrittsanzeige
        self.status_label = QLabel("Bereit zum Sortieren.")
        self.progress_bar = QProgressBar(self)
        self.progress_bar.setValue(0)
        
        # Button für den Start
        self.sort_button = QPushButton("Sortieren starten")

        # Widgets zum Haupt-Layout hinzufügen
        main_layout.addLayout(path_layout)
        main_layout.addWidget(self.status_label)
        main_layout.addWidget(self.progress_bar)
        main_layout.addWidget(self.sort_button)
        
        self.setLayout(main_layout)

        # Verbindungen der Signale und Slots
        self.browse_button.clicked.connect(self.browse_folder)
        self.sort_button.clicked.connect(self.sort_files)

    def browse_folder(self):
        folder_path = QFileDialog.getExistingDirectory(self, "Wähle einen Ordner aus")
        if folder_path:
            self.path_entry.setText(folder_path)

    def sort_files(self):
        source_folder = self.path_entry.text()
        
        if not os.path.exists(source_folder):
            QMessageBox.critical(self, "Fehler", "Der angegebene Pfad existiert nicht!")
            return
            
        try:
            # Ordner-Struktur vorbereiten
            for folder in file_types:
                target_path = os.path.join(source_folder, folder)
                if not os.path.exists(target_path):
                    os.makedirs(target_path)
            
            # Alle zu sortierenden Dateien zählen
            all_files = [f for f in os.listdir(source_folder) if os.path.isfile(os.path.join(source_folder, f))]
            total_files = len(all_files)
            
            self.progress_bar.setMaximum(total_files)
            self.progress_bar.setValue(0)
            self.status_label.setText(f"Sortiere {total_files} Dateien...")
            
            # Dateien sortieren und Fortschritt aktualisieren
            for i, file_name in enumerate(all_files):
                file_path = os.path.join(source_folder, file_name)
                _, ext = os.path.splitext(file_name)

                moved = False
                for folder, extensions in file_types.items():
                    if ext.lower() in extensions:
                        shutil.move(file_path, os.path.join(source_folder, folder, file_name))
                        moved = True
                        break
                
                # Fortschritt aktualisieren
                self.progress_bar.setValue(i + 1)
                # GUI am Leben erhalten
                QApplication.processEvents()

            QMessageBox.information(self, "Erfolg", "Sortierung abgeschlossen!")
            self.status_label.setText("Bereit zum Sortieren.")
            self.progress_bar.setValue(0)
            
        except Exception as e:
            QMessageBox.critical(self, "Fehler", f"Ein Fehler ist aufgetreten: {e}")
            self.status_label.setText("Sortierung fehlgeschlagen.")
            self.progress_bar.setValue(0)

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = FileSorterApp()
    window.show()
    sys.exit(app.exec())
```

## Fazit

Mit **`QFileDialog`** und **`QProgressBar`** hast du dein Tool auf ein professionelles Niveau gehoben. Der Nutzer kann nun intuitiv einen Ordner auswählen und erhält während des Prozesses visuelles Feedback. Die Verwendung von **`QApplication.processEvents()`** ist ein entscheidender Schritt, um die Oberfläche nicht zu blockieren, was für eine gute User Experience unerlässlich ist.

**Nächste Schritte**:

  - **Separate Threading**: Bei sehr vielen Dateien kann die GUI trotzdem kurzzeitig "einfrieren". Das ist ein Zeichen dafür, dass die langwierige Operation im Haupt-Thread läuft. Die professionelle Lösung ist, den Sortiervorgang in einen separaten Thread auszulagern, um die Benutzeroberfläche jederzeit reaktionsschnell zu halten.
  - **Erweiterung**: Füge eine Konfigurationsdatei hinzu, in der der Nutzer seine eigenen Dateitypen definieren kann.