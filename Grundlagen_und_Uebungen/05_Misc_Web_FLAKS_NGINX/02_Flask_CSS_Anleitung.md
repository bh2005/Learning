# Praxisorientierte Anleitung: CSS mit Flask und optional NGINX

## Einführung
CSS (Cascading Style Sheets) ist essenziell, um Webanwendungen visuell ansprechend und benutzerfreundlich zu gestalten. Diese Anleitung kombiniert **Flask**, ein leichtgewichtiges Python-Webframework, mit CSS, um stilvolle Webanwendungen zu erstellen, und zeigt optional, wie **NGINX** als Webserver für die Produktionsumgebung genutzt werden kann. Die Schwerpunkte sind **Grundlagen von CSS in Flask**, **Erstellung einer stilisierten Webanwendung** und **Bereitstellung mit NGINX**. Eine **Spielerei** demonstriert die Verwendung von CSS Media Queries für ein responsives Design, das auf verschiedenen Geräten funktioniert. Durch praktische Übungen lernst du, CSS in Flask zu integrieren, eine ansprechende Benutzeroberfläche zu gestalten und die Anwendung bereitzustellen.

**Voraussetzungen**:
- Ein System mit Windows, macOS oder Linux (z. B. Windows 11, Ubuntu 22.04, macOS Ventura).
- Ein Terminal (PowerShell für Windows, Terminal für macOS/Linux).
- Python 3 installiert (prüfe mit `python3 --version` oder `python --version`; installiere via `choco install python` auf Windows, `sudo apt install python3` auf Ubuntu oder `brew install python3` auf macOS).
- `pip` für Python-Pakete (prüfe mit `pip3 --version`).
- Optional: NGINX für Produktionsumgebung (installiere via `sudo apt install nginx` auf Ubuntu oder `brew install nginx` auf macOS).
- Grundkenntnisse in Python, HTML und Git.
- Sichere Testumgebung (z. B. `$HOME/flask_css_test` oder `~/flask_css_test`).

## Grundlegende Befehle
Hier sind die wichtigsten Befehle und Konzepte, aufgeteilt nach den Hauptthemen:

1. **Grundlagen von CSS in Flask**:
   - `flask run`: Startet den Flask-Entwicklungsserver.
   - `static/style.css`: Standardpfad für CSS-Dateien in Flask.
   - `url_for('static', filename='style.css')`: Generiert sichere URLs für statische Dateien.
2. **Erstellung einer stilisierten Webanwendung**:
   - `@app.route()`: Definiert Routen für die Webanwendung.
   - `render_template()`: Rendert HTML-Templates mit CSS.
   - `mkdir static templates`: Erstellt Verzeichnisse für CSS und HTML.
3. **Bereitstellung mit NGINX**:
   - `gunicorn`: WSGI-Server für Flask in Produktion.
   - `nginx -t`: Testet NGINX-Konfigurationen.
   - `systemctl reload nginx`: Lädt NGINX-Konfiguration neu.
4. **Nützliche Zusatzbefehle**:
   - `python3 -m venv`: Erstellt eine virtuelle Umgebung.
   - `curl`: Testet die Webanwendung.
   - `git push`: Lädt Änderungen in ein GitHub-Repository.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Grundlagen von CSS in Flask
**Ziel**: Erstelle eine einfache Flask-Anwendung mit einer CSS-Datei für grundlegendes Styling.

1. **Schritt 1**: Erstelle ein Projektverzeichnis und eine virtuelle Umgebung:
   ```bash
   mkdir flask_css_test
   cd flask_css_test
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

3. **Schritt 3**: Installiere Flask und erstelle Verzeichnisse:
   ```bash
   pip install flask
   mkdir static templates
   ```

4. **Schritt 4**: Erstelle eine CSS-Datei:
   ```bash
   nano static/style.css
   ```
   Füge folgenden Inhalt ein:
   ```css
   body {
       font-family: Arial, sans-serif;
       margin: 0;
       padding: 20px;
       background-color: #f0f0f0;
   }
   h1 {
       color: #333;
       text-align: center;
   }
   .container {
       max-width: 800px;
       margin: 0 auto;
       background: white;
       padding: 20px;
       border-radius: 8px;
       box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
   }
   ```
   Speichere und schließe.

5. **Schritt 5**: Erstelle ein HTML-Template:
   ```bash
   nano templates/index.html
   ```
   Füge folgenden Inhalt ein:
   ```html
   <!DOCTYPE html>
   <html>
   <head>
       <title>Flask mit CSS</title>
       <link rel="stylesheet" href="{{ url_for('static', filename='style.css') }}">
   </head>
   <body>
       <div class="container">
           <h1>Willkommen zu meiner Flask-Anwendung!</h1>
           <p>Diese Seite verwendet CSS für ein modernes Design.</p>
       </div>
   </body>
   </html>
   ```
   Speichere und schließe.

6. **Schritt 6**: Erstelle die Flask-Anwendung:
   ```bash
   nano app.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from flask import Flask, render_template

   app = Flask(__name__)

   @app.route('/')
   def home():
       return render_template('index.html')

   if __name__ == '__main__':
       app.run(debug=True)
   ```
   Speichere und schließe.

7. **Schritt 7**: Starte den Server und teste die Anwendung:
   ```bash
   python3 app.py
   ```
   Öffne `http://localhost:5000` im Browser. Du solltest eine gestylte Seite mit zentriertem Titel und einem Container sehen.

**Reflexion**: Wie verbessert CSS die Benutzererfahrung? Nutze `flask --help` und überlege, wie du weitere statische Dateien (z. B. Bilder) einbinden kannst.

### Übung 2: Erstellung einer stilisierten Webanwendung
**Ziel**: Erweitere die Anwendung mit dynamischen Routen und einem responsiven Design.

1. **Schritt 1**: Erweitere die CSS-Datei für ein Navigationsmenü und responsives Design:
   ```bash
   nano static/style.css
   ```
   Ersetze den Inhalt durch:
   ```css
   body {
       font-family: Arial, sans-serif;
       margin: 0;
       padding: 20px;
       background-color: #f0f0f0;
   }
   h1 {
       color: #333;
       text-align: center;
   }
   .container {
       max-width: 800px;
       margin: 0 auto;
       background: white;
       padding: 20px;
       border-radius: 8px;
       box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
   }
   nav {
       background: #007bff;
       padding: 10px;
       border-radius: 5px;
       margin-bottom: 20px;
   }
   nav a {
       color: white;
       text-decoration: none;
       margin: 0 15px;
       font-weight: bold;
   }
   nav a:hover {
       text-decoration: underline;
   }
   @media (max-width: 600px) {
       nav {
           display: flex;
           flex-direction: column;
           align-items: center;
       }
       nav a {
           margin: 5px 0;
       }
   }
   ```
   Speichere und schließe.

2. **Schritt 2**: Erstelle ein Basis-Template für Wiederverwendbarkeit:
   ```bash
   nano templates/base.html
   ```
   Füge folgenden Inhalt ein:
   ```html
   <!DOCTYPE html>
   <html>
   <head>
       <title>{% block title %}{% endblock %}</title>
       <link rel="stylesheet" href="{{ url_for('static', filename='style.css') }}">
   </head>
   <body>
       <nav>
           <a href="{{ url_for('home') }}">Home</a>
           <a href="{{ url_for('about') }}">Über</a>
           <a href="{{ url_for('user', name='Gast') }}">Benutzer</a>
       </nav>
       <div class="container">
           {% block content %}{% endblock %}
       </div>
   </body>
   </html>
   ```
   Speichere und schließe.

3. **Schritt 3**: Aktualisiere das Home-Template:
   ```bash
   nano templates/index.html
   ```
   Ersetze den Inhalt durch:
   ```html
   {% extends 'base.html' %}
   {% block title %}Home{% endblock %}
   {% block content %}
       <h1>Willkommen zu meiner Flask-Anwendung!</h1>
       <p>Diese Seite verwendet CSS für ein modernes Design.</p>
   {% endblock %}
   ```
   Speichere und schließe.

4. **Schritt 4**: Erstelle ein Template für die Über-Seite:
   ```bash
   nano templates/about.html
   ```
   Füge folgenden Inhalt ein:
   ```html
   {% extends 'base.html' %}
   {% block title %}Über{% endblock %}
   {% block content %}
       <h1>Über diese Anwendung</h1>
       <p>Entwickelt mit Flask und CSS für ein ansprechendes Design.</p>
   {% endblock %}
   ```
   Speichere und schließe.

5. **Schritt 5**: Erstelle ein Template für die Benutzer-Seite:
   ```bash
   nano templates/user.html
   ```
   Füge folgenden Inhalt ein:
   ```html
   {% extends 'base.html' %}
   {% block title %}Benutzer{% endblock %}
   {% block content %}
       <h1>Hallo, {{ name }}!</h1>
       <p>Willkommen auf deiner persönlichen Seite.</p>
   {% endblock %}
   ```
   Speichere und schließe.

6. **Schritt 6**: Erweitere die Flask-Anwendung:
   ```bash
   nano app.py
   ```
   Ersetze den Inhalt durch:
   ```python
   from flask import Flask, render_template

   app = Flask(__name__)

   @app.route('/')
   def home():
       return render_template('index.html')

   @app.route('/about')
   def about():
       return render_template('about.html')

   @app.route('/user/<name>')
   def user(name):
       return render_template('user.html', name=name)

   if __name__ == '__main__':
       app.run(debug=True)
   ```
   Speichere und schließe.

7. **Schritt 7**: Starte den Server und teste die Anwendung:
   ```bash
   python3 app.py
   ```
   Öffne `http://localhost:5000`, `http://localhost:5000/about` und `http://localhost:5000/user/Anna` im Browser. Verkleinere das Browserfenster, um das responsive Navigationsmenü zu testen.

**Reflexion**: Wie verbessern CSS Media Queries die Zugänglichkeit? Nutze die Flask-Dokumentation und überlege, wie du weitere CSS-Features (z. B. Flexbox) einbinden kannst.

### Übung 3: Bereitstellung mit NGINX und Spielerei
**Ziel**: Stelle die Flask-Anwendung mit NGINX bereit und füge eine Spielerei hinzu, die ein responsives Grid-Layout mit CSS implementiert.

1. **Schritt 1**: Installiere Gunicorn für die Produktionsumgebung:
   ```bash
   pip install gunicorn
   pip freeze > requirements.txt
   ```

2. **Schritt 2**: Teste die Anwendung mit Gunicorn:
   ```bash
   gunicorn --bind 0.0.0.0:8000 app:app
   ```
   Öffne `http://localhost:8000`. Beende Gunicorn mit `Ctrl+C`.

3. **Schritt 3**: Installiere NGINX (auf Ubuntu/Debian):
   ```bash
   sudo apt update
   sudo apt install nginx -y
   ```

4. **Schritt 4**: Konfiguriere NGINX als Reverse Proxy:
   ```bash
   sudo nano /etc/nginx/sites-available/flask_css
   ```
   Füge folgenden Inhalt ein:
   ```
   server {
       listen 80;
       server_name flask_css.local;

       location / {
           proxy_pass http://127.0.0.1:8000;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }

       location /static {
           alias /path/to/flask_css_test/static;
       }
   }
   ```
   Ersetze `/path/to/flask_css_test/static` durch den absoluten Pfad zu deinem `static`-Ordner (z. B. `/home/user/flask_css_test/static`). Speichere und schließe.

5. **Schritt 5**: Aktiviere die NGINX-Konfiguration:
   ```bash
   sudo ln -s /etc/nginx/sites-available/flask_css /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl reload nginx
   ```

6. **Schritt 6**: Füge `flask_css.local` zur `/etc/hosts`-Datei hinzu:
   ```bash
   sudo nano /etc/hosts
   ```
   Füge hinzu:
   ```
   127.0.0.1 flask_css.local
   ```

7. **Schritt 7**: Starte Gunicorn im Hintergrund:
   ```bash
   gunicorn --bind 0.0.0.0:8000 app:app --daemon
   ```
   Öffne `http://flask_css.local` im Browser. Beende Gunicorn nach dem Test:
   ```bash
   pkill gunicorn
   ```

8. **Spielerei**: Füge ein responsives Grid-Layout hinzu:
   ```bash
   nano static/style.css
   ```
   Füge am Ende hinzu:
   ```css
   .grid-container {
       display: grid;
       grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
       gap: 20px;
       margin-top: 20px;
   }
   .grid-item {
       background: #e7f3ff;
       padding: 15px;
       border-radius: 5px;
       text-align: center;
   }
   ```
   Speichere und schließe.

9. **Schritt 8**: Erweitere `templates/index.html` für das Grid:
   ```bash
   nano templates/index.html
   ```
   Ersetze den `<div class="container">`-Inhalt durch:
   ```html
   <div class="container">
       <h1>Willkommen zu meiner Flask-Anwendung!</h1>
       <p>Diese Seite verwendet CSS für ein modernes Design.</p>
       <div class="grid-container">
           <div class="grid-item">Element 1</div>
           <div class="grid-item">Element 2</div>
           <div class="grid-item">Element 3</div>
           <div class="grid-item">Element 4</div>
       </div>
   </div>
   ```
   Speichere und schließe.

10. **Schritt 9**: Teste die Anwendung lokal:
    ```bash
    python3 app.py
    ```
    Öffne `http://localhost:5000` und verkleinere das Browserfenster, um das responsive Grid zu sehen.

**Reflexion**: Wie verbessert ein CSS-Grid die Darstellung von Inhalten? Nutze die NGINX-Dokumentation und überlege, wie du HTTPS mit Let’s Encrypt einrichten kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um CSS und Flask-Workflows zu verinnerlichen.
- **Sicheres Testen**: Nutze virtuelle Umgebungen und lokale Tests, um Fehler zu vermeiden.
- **Fehler verstehen**: Lies Flask-Debug-Ausgaben oder NGINX-Logs (`/var/log/nginx/error.log`) genau.
- **Effiziente Workflows**: Verwende `static/` für CSS-Dateien, `base.html` für wiederverwendbare Templates und NGINX für skalierbare Bereitstellung.
- **Sicherheitsbewusstsein**: Vermeide den Debug-Modus in der Produktion und sichere NGINX mit einer Firewall (z. B. `ufw`).
- **Kombiniere Tools**: Integriere Flask mit GitHub für Versionskontrolle oder GitHub Actions für automatisierte Tests.

## Fazit
Mit diesen Übungen hast du gelernt, wie du CSS mit Flask kombinierst, um stilvolle Webanwendungen zu erstellen, und optional NGINX für die Produktionsumgebung nutzt. Die Spielerei zeigt, wie du ein responsives Grid-Layout implementierst. Vertiefe dein Wissen, indem du fortgeschrittene CSS-Features (z. B. Animations, SCSS) oder NGINX-Optimierungen (z. B. Caching, Load Balancing) ausprobierst. Wenn du ein spezifisches Thema (z. B. CSS-Animationen oder NGINX-Skalierung) vertiefen möchtest, lass es mich wissen!
