# Praxisorientierte Anleitung: Grundlagen eines Webservers mit Python und Flask

## Einführung
Flask ist ein leichtgewichtiges Python-Webframework, das ideal für die Erstellung einfacher und flexibler Webserver ist. Diese Anleitung konzentriert sich auf die Schwerpunkte **Installation und Einrichtung von Flask**, **Erstellung einer einfachen Webanwendung** und **Grundlegende Routen und Templates**, um einen funktionalen Webserver zu entwickeln. Zusätzlich beinhaltet sie eine **Spielerei**, bei der Flask den Inhalt eines Ordners ausliest und automatisch Download-Links generiert. Durch praktische Übungen lernst du, Flask zu installieren, eine Webanwendung zu erstellen, dynamische Inhalte bereitzustellen und Dateien zum Download anzubieten.

**Voraussetzungen**:
- Ein System mit Windows, macOS oder Linux (z. B. Windows 11, Ubuntu 22.04, macOS Ventura).
- Ein Terminal (PowerShell für Windows, Terminal für macOS/Linux).
- Python 3 installiert (prüfe mit `python3 --version` oder `python --version`; installiere via `choco install python` auf Windows, `sudo apt install python3` auf Ubuntu oder `brew install python3` auf macOS).
- `pip` für Python-Pakete (meist mit Python enthalten; prüfe mit `pip3 --version`).
- Grundkenntnisse in Python (z. B. Variablen, Funktionen, Dateioperationen).
- Sichere Testumgebung (z. B. `$HOME/flask_test` oder `~/flask_test`) für risikofreie Experimente.

## Grundlegende Befehle
Hier sind die wichtigsten Befehle und Konzepte für die Arbeit mit Flask, aufgeteilt nach den Hauptthemen:

1. **Installation und Einrichtung von Flask**:
   - `pip install flask`: Installiert Flask und seine Abhängigkeiten.
   - `python3 -m flask run`: Startet den Flask-Entwicklungsserver.
   - `python3 <script>.py`: Führt ein Flask-Skript direkt aus (bei gesetztem `app.run()`).
2. **Erstellung einer einfachen Webanwendung**:
   - `@app.route()`: Definiert URL-Routen für die Webanwendung.
   - `flask run --debug`: Startet den Server im Debug-Modus mit Live-Reloading.
3. **Grundlegende Routen und Templates**:
   - `render_template()`: Rendert HTML-Templates mit dynamischen Daten.
   - `Jinja2`: Template-Engine für Flask (z. B. für Schleifen, Variablen).
   - `send_from_directory()`: Ermöglicht den Download von Dateien aus einem Ordner.
   - `mkdir templates`: Erstellt ein Verzeichnis für HTML-Templates.
4. **Nützliche Zusatzbefehle**:
   - `pip list`: Zeigt installierte Python-Pakete.
   - `curl`: Testet die Erreichbarkeit der Webanwendung.
   - `python3 -m venv`: Erstellt eine virtuelle Umgebung für isolierte Projekte.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Installation und Einrichtung von Flask
**Ziel**: Installiere Flask, richte eine virtuelle Umgebung ein und starte einen einfachen Webserver.

1. **Schritt 1**: Erstelle ein Projektverzeichnis und eine virtuelle Umgebung:
   ```bash
   mkdir flask_test
   cd flask_test
   python3 -m venv venv
   ```

2. **Schritt 2**: Aktiviere die virtuelle Umgebung:
   - Auf Windows:
     ```bash
     .\venv\Scripts\activate
     ```
   - Auf Linux/macOS:
     ```bash
     source venv/bin/activate
     ```
   Überprüfe, ob die Umgebung aktiv ist (Terminal zeigt `(venv)`).

3. **Schritt 3**: Installiere Flask:
   ```bash
   pip install flask
   pip list
   ```

4. **Schritt 4**: Erstelle eine einfache Flask-Anwendung:
   ```bash
   nano app.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from flask import Flask

   app = Flask(__name__)

   @app.route('/')
   def home():
       return 'Willkommen zu meinem Flask-Webserver!'

   if __name__ == '__main__':
       app.run(debug=True)
   ```
   Speichere und schließe.

5. **Schritt 5**: Starte den Webserver:
   ```bash
   python3 app.py
   ```
   Öffne `http://localhost:5000` im Browser. Du solltest „Willkommen zu meinem Flask-Webserver!“ sehen.

**Reflexion**: Warum ist eine virtuelle Umgebung nützlich? Nutze `pip help install` und überlege, wie du Flask-Versionen verwalten kannst.

### Übung 2: Erstellung einer einfachen Webanwendung
**Ziel**: Erstelle eine Webanwendung mit mehreren Routen und dynamischen Inhalten.

1. **Schritt 1**: Erweitere `app.py` mit neuen Routen:
   ```bash
   nano app.py
   ```
   Ändere den Inhalt zu:
   ```python
   from flask import Flask

   app = Flask(__name__)

   @app.route('/')
   def home():
       return 'Willkommen zu meinem Flask-Webserver!'

   @app.route('/about')
   def about():
       return 'Dies ist die Über-Seite.'

   @app.route('/user/<name>')
   def user(name):
       return f'Hallo, {name}!'

   if __name__ == '__main__':
       app.run(debug=True)
   ```
   Speichere und schließe.

2. **Schritt 2**: Starte den Server und teste die Routen:
   ```bash
   python3 app.py
   ```
   Öffne im Browser:
   - `http://localhost:5000/` (zeigt „Willkommen zu meinem Flask-Webserver!“).
   - `http://localhost:5000/about` (zeigt „Dies ist die Über-Seite.“).
   - `http://localhost:5000/user/Anna` (zeigt „Hallo, Anna!“).

3. **Schritt 3**: Teste die Routen mit `curl`:
   ```bash
   curl http://localhost:5000/user/Anna
   ```

**Reflexion**: Wie verbessern dynamische Routen (z. B. `/user/<name>`) die Flexibilität? Überlege, wie du URL-Parameter für komplexere Anwendungen nutzen kannst.

### Übung 3: Grundlegende Routen, Templates und Spielerei
**Ziel**: Erstelle eine Webanwendung mit HTML-Templates und dynamischen Daten sowie einer Funktion, die den Inhalt eines Ordners ausliest und Download-Links generiert.

1. **Schritt 1**: Erstelle ein Verzeichnis für Templates und Dateien zum Download:
   ```bash
   mkdir templates
   mkdir files
   ```

2. **Schritt 2**: Erstelle Testdateien im `files`-Ordner:
   ```bash
   echo "Dies ist eine Testdatei" > files/test1.txt
   echo "Dies ist eine weitere Datei" > files/test2.txt
   ```

3. **Schritt 3**: Erstelle ein HTML-Template für die Dateiliste:
   ```bash
   nano templates/index.html
   ```
   Füge folgenden Inhalt ein:
   ```html
   <!DOCTYPE html>
   <html>
   <head>
       <title>Flask-Webserver</title>
       <style>
           body { font-family: Arial, sans-serif; text-align: center; }
           h1 { color: #333; }
           ul { list-style-type: none; padding: 0; }
           li { margin: 10px 0; }
           a { color: #007bff; text-decoration: none; }
           a:hover { text-decoration: underline; }
       </style>
   </head>
   <body>
       <h1>Willkommen, {{ name }}!</h1>
       <p>Das ist meine Flask-Webanwendung.</p>
       <h2>Verfügbare Dateien zum Download:</h2>
       <ul>
       {% for file in files %}
           <li><a href="{{ url_for('download_file', filename=file) }}">{{ file }}</a></li>
       {% endfor %}
       </ul>
   </body>
   </html>
   ```
   Speichere und schließe.

4. **Schritt 4**: Erweitere `app.py` für Template-Rendering und Datei-Downloads:
   ```bash
   nano app.py
   ```
   Ändere den Inhalt zu:
   ```python
   from flask import Flask, render_template, send_from_directory
   import os

   app = Flask(__name__)

   @app.route('/')
   def home():
       # Lese Dateien aus dem 'files'-Ordner
       files = os.listdir('files')
       return render_template('index.html', name='Gast', files=files)

   @app.route('/user/<name>')
   def user(name):
       # Lese Dateien aus dem 'files'-Ordner
       files = os.listdir('files')
       return render_template('index.html', name=name, files=files)

   @app.route('/download/<filename>')
   def download_file(filename):
       return send_from_directory('files', filename, as_attachment=True)

   if __name__ == '__main__':
       app.run(debug=True)
   ```
   Speichere und schließe.

5. **Schritt 5**: Starte den Server und teste die Anwendung:
   ```bash
   python3 app.py
   ```
   Öffne `http://localhost:5000/` (zeigt „Willkommen, Gast!“ und Download-Links für `test1.txt` und `test2.txt`). Klicke auf die Links, um die Dateien herunterzuladen. Teste auch `http://localhost:5000/user/Bob`.

6. **Spielerei**: Erweitere die Anwendung, um nur bestimmte Dateitypen (z. B. `.txt`) anzuzeigen:
   ```bash
   nano app.py
   ```
   Ändere die `home`- und `user`-Routen zu:
   ```python
   @app.route('/')
   def home():
       # Lese nur .txt-Dateien aus dem 'files'-Ordner
       files = [f for f in os.listdir('files') if f.endswith('.txt')]
       return render_template('index.html', name='Gast', files=files)

   @app.route('/user/<name>')
   def user(name):
       # Lese nur .txt-Dateien aus dem 'files'-Ordner
       files = [f for f in os.listdir('files') if f.endswith('.txt')]
       return render_template('index.html', name=name, files=files)
   ```
   Speichere und schließe.

7. **Schritt 6**: Erstelle eine zusätzliche Datei (z. B. eine nicht-.txt-Datei) und teste die Filterung:
   ```bash
   echo "Dies ist kein Text" > files/test.pdf
   python3 app.py
   ```
   Öffne `http://localhost:5000/` und überprüfe, ob nur `.txt`-Dateien angezeigt werden.

**Reflexion**: Wie verbessert `send_from_directory` die Sicherheit beim Datei-Download? Nutze `flask --help` und überlege, wie du den Download-Ordner dynamisch konfigurieren kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Flask und Python-Befehle zu verinnerlichen.
- **Sicheres Testen**: Nutze virtuelle Umgebungen, um Abhängigkeiten zu isolieren.
- **Fehler verstehen**: Lies Fehlermeldungen im Debug-Modus (`--debug`) und überprüfe Logs in der Konsole.
- **Effiziente Entwicklung**: Verwende `render_template` für dynamische Inhalte und strukturierte Verzeichnisse (`templates/`, `files/`).
- **Sicherheitsbewusstsein**: Vermeide den Debug-Modus in der Produktion; überprüfe Dateipfade in `send_from_directory`, um unbefugten Zugriff zu verhindern.
- **Kombiniere Tools**: Integriere Flask mit Git für Versionskontrolle oder GitHub Actions für automatisierte Deployments.

## Fazit
Mit diesen Übungen hast du die Grundlagen eines Webservers mit Python und Flask gemeistert, einschließlich Installation, Routen-Erstellung, Template-Nutzung und einer Spielerei, die Ordnerinhalte als Download-Links generiert. Vertiefe dein Wissen, indem du fortgeschrittene Features wie Flask-Formulare, Datenbankintegration (z. B. mit SQLite) oder Deployment auf Plattformen wie Heroku ausprobierst. Wenn du ein spezifisches Thema (z. B. Sicherheitsaspekte bei Downloads oder Produktions-Setup) vertiefen möchtest, lass es mich wissen!
