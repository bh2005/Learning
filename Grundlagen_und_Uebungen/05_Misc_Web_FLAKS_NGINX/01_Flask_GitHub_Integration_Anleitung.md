# Praxisorientierte Anleitung: Integration von Flask und GitHub für Webanwendungen

## Einführung
Flask ist ein flexibles Python-Webframework, das sich hervorragend mit GitHub kombinieren lässt, um Webanwendungen zu entwickeln, zu versionieren und automatisch bereitzustellen. Diese Anleitung konzentriert sich auf die Schwerpunkte **Projektversionierung mit GitHub**, **automatisiertes Deployment mit GitHub Actions** und **kollaborative Entwicklung**, um Flask-Anwendungen effizient zu verwalten und bereitzustellen. Eine **Spielerei** zeigt, wie Flask eine Markdown-Datei aus einem GitHub-Repository lädt und anzeigt. Durch praktische Übungen lernst du, Flask mit GitHub zu integrieren, automatische Builds einzurichten und kollaborative Workflows zu nutzen.

**Voraussetzungen**:
- Ein System mit Windows, macOS oder Linux (z. B. Windows 11, Ubuntu 22.04, macOS Ventura).
- Ein Terminal (PowerShell für Windows, Terminal für macOS/Linux).
- Python 3 installiert (prüfe mit `python3 --version` oder `python --version`; installiere via `choco install python` auf Windows, `sudo apt install python3` auf Ubuntu oder `brew install python3` auf macOS).
- `pip` für Python-Pakete (prüfe mit `pip3 --version`).
- Git installiert (prüfe mit `git --version`; installiere via `choco install git`, `sudo apt install git` oder `brew install git`).
- Ein GitHub-Konto mit einem Repository.
- Grundkenntnisse in Python, Flask und Git.
- Sichere Testumgebung (z. B. `$HOME/flask_github_test` oder `~/flask_github_test`).

## Grundlegende Befehle
Hier sind die wichtigsten Befehle für die Integration von Flask und GitHub, aufgeteilt nach den Hauptthemen:

1. **Projektversionierung mit GitHub**:
   - `git init`: Initialisiert ein lokales Git-Repository.
   - `git add`: Fügt Dateien zum Staging-Bereich hinzu.
   - `git commit`: Speichert Änderungen im lokalen Repository.
   - `git push`: Lädt Änderungen in ein GitHub-Repository hoch.
   - `git clone`: Klont ein GitHub-Repository lokal.
2. **Automatisiertes Deployment mit GitHub Actions**:
   - `.github/workflows/*.yml`: Definiert CI/CD-Workflows für Flask-Anwendungen.
   - `actions/checkout`: Klont das Repository in der Pipeline.
   - `actions/setup-python`: Richtet eine Python-Umgebung ein.
3. **Kollaborative Entwicklung**:
   - `git branch`: Erstellt oder verwaltet Branches.
   - `git pull`: Synchronisiert Änderungen von GitHub.
   - `git merge`: Führt Branches zusammen.
4. **Nützliche Zusatzbefehle**:
   - `pip install flask requests`: Installiert Flask und `requests` für API-Aufrufe.
   - `python3 -m flask run`: Startet den Flask-Entwicklungsserver.
   - `curl`: Testet die Webanwendung.
   - `git log --oneline`: Zeigt die Commit-Historie.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Projektversionierung mit GitHub
**Ziel**: Erstelle eine Flask-Anwendung, versioniere sie mit Git und pushe sie zu GitHub.

1. **Schritt 1**: Erstelle ein Projektverzeichnis und eine virtuelle Umgebung:
   ```bash
   mkdir flask_github_test
   cd flask_github_test
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

3. **Schritt 3**: Installiere Flask und initialisiere ein Git-Repository:
   ```bash
   pip install flask
   git init
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
       return 'Willkommen zu meiner Flask-GitHub-Anwendung!'

   if __name__ == '__main__':
       app.run(debug=True)
   ```
   Speichere und schließe.

5. **Schritt 5**: Erstelle ein GitHub-Repository (ohne README, .gitignore oder Lizenz) und pushe die Anwendung:
   ```bash
   echo -e "*.pyc\n__pycache__/\nvenv/" > .gitignore
   git add .
   git commit -m "Initiale Flask-Anwendung"
   git remote add origin https://github.com/dein-benutzername/flask_github_test.git
   git push -u origin main
   ```
   Ersetze `dein-benutzername` durch deinen GitHub-Benutzernamen.

6. **Schritt 6**: Teste die Anwendung lokal:
   ```bash
   python3 app.py
   ```
   Öffne `http://localhost:5000` im Browser.

**Reflexion**: Wie hilft `.gitignore` bei Flask-Projekten? Nutze `git help gitignore` und überlege, welche Dateien du zusätzlich ignorieren solltest.

### Übung 2: Automatisiertes Deployment mit GitHub Actions
**Ziel**: Richte GitHub Actions ein, um die Flask-Anwendung automatisch zu testen und zu deployen (z. B. auf Heroku).

1. **Schritt 1**: Erstelle eine Anforderungsdatei für Abhängigkeiten:
   ```bash
   pip freeze > requirements.txt
   ```

2. **Schritt 2**: Erstelle eine GitHub Actions-Workflow-Datei:
   ```bash
   mkdir -p .github/workflows
   nano .github/workflows/ci.yml
   ```
   Füge folgenden Inhalt ein:
   ```yaml
   name: Flask CI
   on:
     push:
       branches: [ main ]
     pull_request:
       branches: [ main ]
   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
       - name: Checkout
         uses: actions/checkout@v5
       - name: Setup Python
         uses: actions/setup-python@v5
         with:
           python-version: '3.x'
       - name: Install Dependencies
         run: |
           python -m pip install --upgrade pip
           pip install -r requirements.txt
       - name: Test Flask App
         run: |
           python -m flask run &
           sleep 5
           curl --retry 3 http://localhost:5000
   ```
   Speichere und schließe.

3. **Schritt 3**: Committe und pushe den Workflow:
   ```bash
   git add .
   git commit -m "GitHub Actions Workflow für Flask-Tests hinzugefügt"
   git push
   ```

4. **Schritt 4**: Überprüfe den Workflow unter „Actions“ auf GitHub. Der Workflow testet, ob die Flask-App startet und auf `http://localhost:5000` antwortet.

5. **Schritt 5**: Für Deployment (z. B. auf Heroku) erweitere den Workflow. Erstelle ein Heroku-App, generiere einen API-Schlüssel und speichere ihn als GitHub Secret (`HEROKU_API_KEY`). Füge einen Deploy-Job hinzu:
   ```bash
   nano .github/workflows/ci.yml
   ```
   Ersetze den Inhalt durch:
   ```yaml
   name: Flask CI and Deploy
   on:
     push:
       branches: [ main ]
     pull_request:
       branches: [ main ]
   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
       - name: Checkout
         uses: actions/checkout@v5
       - name: Setup Python
         uses: actions/setup-python@v5
         with:
           python-version: '3.x'
       - name: Install Dependencies
         run: |
           python -m pip install --upgrade pip
           pip install -r requirements.txt
       - name: Test Flask App
         run: |
           python -m flask run &
           sleep 5
           curl --retry 3 http://localhost:5000
     deploy:
       runs-on: ubuntu-latest
       needs: test
       if: github.event_name == 'push' && github.ref == 'refs/heads/main'
       steps:
       - name: Checkout
         uses: actions/checkout@v5
       - name: Deploy to Heroku
         env:
           HEROKU_API_KEY: ${{ secrets.HEROKU_API_KEY }}
         run: |
           git remote add heroku https://git.heroku.com/your-app-name.git
           git push heroku main
   ```
   Ersetze `your-app-name` durch den Namen deiner Heroku-App. Committe und pushe:
   ```bash
   git add .github/workflows/ci.yml
   git commit -m "Heroku-Deployment zu Workflow hinzugefügt"
   git push
   ```

**Reflexion**: Warum ist das Testen vor dem Deployment wichtig? Nutze die GitHub Actions-Dokumentation und überlege, wie du Linting oder Unittests hinzufügen kannst.

### Übung 3: Kollaborative Entwicklung und Spielerei
**Ziel**: Nutze Branches und Pull Requests für die Zusammenarbeit und implementiere eine Spielerei, bei der Flask eine Markdown-Datei von GitHub lädt und anzeigt.

1. **Schritt 1**: Erstelle einen neuen Branch für eine Funktion:
   ```bash
   git checkout -b markdown-viewer
   ```

2. **Schritt 2**: Erweitere die Flask-App, um Markdown-Dateien von GitHub anzuzeigen. Installiere das `requests`-Modul:
   ```bash
   pip install requests
   pip freeze > requirements.txt
   ```

3. **Schritt 3**: Erstelle ein Template für die Markdown-Anzeige:
   ```bash
   mkdir templates
   nano templates/markdown.html
   ```
   Füge folgenden Inhalt ein:
   ```html
   <!DOCTYPE html>
   <html>
   <head>
       <title>Markdown von GitHub</title>
       <style>
           body { font-family: Arial, sans-serif; text-align: center; }
           h1 { color: #333; }
           pre { background: #f4f4f4; padding: 15px; text-align: left; }
           a { color: #007bff; text-decoration: none; }
           a:hover { text-decoration: underline; }
       </style>
   </head>
   <body>
       <h1>Markdown von GitHub</h1>
       <p>Quelle: <a href="{{ source_url }}">{{ source_url }}</a></p>
       <pre>{{ content }}</pre>
   </body>
   </html>
   ```
   Speichere und schließe.

4. **Schritt 4**: Aktualisiere `app.py` für die Markdown-Anzeige:
   ```bash
   nano app.py
   ```
   Ändere den Inhalt zu:
   ```python
   from flask import Flask, render_template
   import requests

   app = Flask(__name__)

   @app.route('/')
   def home():
       return 'Willkommen zu meiner Flask-GitHub-Anwendung!'

   @app.route('/markdown')
   def markdown():
       # Lade eine Markdown-Datei von GitHub
       repo_url = 'https://raw.githubusercontent.com/dein-benutzername/flask_github_test/main/README.md'
       response = requests.get(repo_url)
       if response.status_code == 200:
           content = response.text
       else:
           content = 'Fehler beim Laden der Markdown-Datei.'
       return render_template('markdown.html', content=content, source_url=repo_url)

   if __name__ == '__main__':
       app.run(debug=True)
   ```
   Ersetze `dein-benutzername` durch deinen GitHub-Benutzernamen. Speichere und schließe.

5. **Schritt 5**: Committe und pushe den Branch:
   ```bash
   git add .
   git commit -m "Markdown-Viewer-Funktion hinzugefügt"
   git push origin markdown-viewer
   ```

6. **Schritt 6**: Erstelle einen Pull Request auf GitHub:
   - Öffne dein Repository auf GitHub.
   - Wähle den `markdown-viewer`-Branch und erstelle einen Pull Request.
   - Merge den Pull Request in den `main`-Branch.

7. **Spielerei**: Teste die Markdown-Anzeige lokal:
   ```bash
   python3 app.py
   ```
   Öffne `http://localhost:5000/markdown` im Browser, um den Inhalt deiner `README.md` von GitHub anzuzeigen.

**Reflexion**: Wie verbessert die Integration von GitHub-Daten die Funktionalität der Flask-App? Nutze die `requests`-Dokumentation und überlege, wie du weitere GitHub-API-Endpunkte nutzen kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Flask- und GitHub-Workflows zu verinnerlichen.
- **Sicheres Testen**: Nutze virtuelle Umgebungen und Test-Branches, um Fehler zu vermeiden.
- **Fehler verstehen**: Lies Flask-Debug-Ausgaben und GitHub Actions-Logs genau.
- **Effiziente Workflows**: Verwende Branches für Features, Pull Requests für Reviews und Actions für automatisierte Tests/Deployments.
- **Sicherheitsbewusstsein**: Verwende GitHub Secrets für sensible Daten (z. B. API-Schlüssel) und vermeide den Debug-Modus in der Produktion.
- **Kombiniere Tools**: Nutze Flask mit Markdown für dynamische Inhalte, GitHub-Wikis für Dokumentation und Actions für CI/CD.

## Fazit
Mit diesen Übungen hast du gelernt, wie Flask und GitHub zusammenarbeiten, um Webanwendungen zu versionieren, automatisch zu testen und bereitzustellen sowie kollaborative Workflows zu nutzen. Die Spielerei zeigt, wie Flask Inhalte direkt von GitHub laden kann. Vertiefe dein Wissen, indem du komplexere GitHub Actions (z. B. mit Unittests), Datenbankintegration in Flask oder erweiterte GitHub-API-Nutzung ausprobierst. Wenn du ein spezifisches Thema (z. B. fortgeschrittene Actions oder API-Integration) vertiefen möchtest, lass es mich wissen!
