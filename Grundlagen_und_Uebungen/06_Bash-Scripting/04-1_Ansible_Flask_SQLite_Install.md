# Praxisorientierte Anleitung: Automatisierte Installation von Flask und SQLite auf Debian Localhost mit Ansible

## Einführung
Diese Anleitung zeigt, wie du mit Ansible die Installation und Konfiguration einer Flask-Anwendung mit SQLite auf einem Debian-basierten localhost automatisierst. Sie baut auf der vorherigen Anleitung zur Integration von Bash-Skripten mit Flask-APIs und SQLite auf und verwendet die dort beschriebene To-Do-Listen-Anwendung. Das Ansible-Playbook installiert Python, SQLite, Flask und Flask-RESTful, richtet die SQLite-Datenbank ein, kopiert die Flask-Anwendung (`app.py`) und startet sie im Hintergrund. Eine Spielerei generiert einen Markdown-Bericht über den Installationsstatus, um die Verbindung zu vorherigen Themen (z. B. Markdown-Ausgabe) herzustellen. Die Übungen sind für Nutzer mit grundlegenden Kenntnissen in Ansible und Linux-Systemadministration gedacht.

**Voraussetzungen**:
- Ein Debian-basiertes System (z. B. Debian 11/12 oder Ubuntu 22.04) als localhost.
- Ein Terminal (z. B. Bash).
- Root- oder sudo-Berechtigungen auf dem localhost.
- Ansible installiert (prüfe mit `ansible --version`; installiere via `sudo apt install ansible` oder `pip install ansible`).
- SSH-Zugang zum localhost (für Ansible; standardmäßig für localhost eingerichtet).
- Python 3 verfügbar (prüfe mit `python3 --version`).
- Sichere Testumgebung (z. B. `$HOME/flask_sqlite_install` oder `~/flask_sqlite_install`).
- Ein Texteditor (z. B. `nano`, `vim` oder VS Code).
- Grundkenntnisse in Ansible (Playbooks, Module), Flask (Routen, APIs) und SQLite (z. B. `CREATE TABLE`).

**Hinweis**: Diese Anleitung verwendet `localhost` als Ziel, daher ist kein separates SSH-Setup erforderlich. Für Remote-Hosts wären SSH-Schlüssel (`ssh-keygen`, `ssh-copy-id`) notwendig.

## Grundlegende Befehle
Hier sind die wichtigsten Ansible-Module und Befehle für die Installation und Konfiguration:
1. **Ansible-Module**:
   - `ansible.builtin.apt`: Verwaltet Pakete auf Debian-Systemen.
   - `ansible.builtin.pip`: Installiert Python-Bibliotheken.
   - `ansible.builtin.copy`: Kopiert Dateien (z. B. `app.py`).
   - `ansible.builtin.command`: Führt Befehle aus (z. B. SQLite-Initialisierung, Flask-Start).
   - `ansible.builtin.template`: Erstellt Dateien aus Vorlagen (z. B. Markdown-Bericht).
2. **Nützliche Zusatzbefehle**:
   - `ansible-playbook playbook.yml`: Führt ein Playbook aus.
   - `ansible localhost -m ping`: Testet die Verbindung zum localhost.
   - `man ansible`: Zeigt Ansible-Dokumentation.
   - `ansible-doc apt`: Zeigt Dokumentation für das `apt`-Modul (ähnlich für `pip`, `copy`, `command`).
   - `curl`: Testet die Flask-API (z. B. `curl http://localhost:5000/api/tasks`).

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Ansible Playbook für Flask und SQLite Installation
**Ziel**: Erstelle ein Ansible-Playbook, das Python, SQLite, Flask, Flask-RESTful installiert, die SQLite-Datenbank einrichtet, die Flask-Anwendung bereitstellt und startet, und einen Markdown-Bericht generiert.

1. **Schritt 1**: Erstelle ein Projektverzeichnis:
   ```bash
   mkdir flask_sqlite_install
   cd flask_sqlite_install
   ```

2. **Schritt 2**: Erstelle ein Inventar für localhost:
   ```bash
   nano inventory.yml
   ```
   Füge folgenden Inhalt ein:
   ```yaml
   all:
     hosts:
       localhost:
         ansible_connection: local
         ansible_python_interpreter: /usr/bin/python3
   ```
   Speichere und schließe.

3. **Schritt 3**: Erstelle die Flask-Anwendung (`app.py`) lokal:
   ```bash
   nano app.py
   ```
   Füge den Inhalt aus der vorherigen Anleitung ein (To-Do-Listen-API):
   ```python
   from flask import Flask
   from flask_restful import Api, Resource, reqparse
   import sqlite3

   app = Flask(__name__)
   api = Api(app)

   def init_db():
       conn = sqlite3.connect('tasks.db')
       c = conn.cursor()
       c.execute('''
           CREATE TABLE IF NOT EXISTS tasks (
               id INTEGER PRIMARY KEY AUTOINCREMENT,
               task TEXT NOT NULL,
               priority INTEGER NOT NULL,
               status TEXT NOT NULL,
               category TEXT NOT NULL,
               created TEXT NOT NULL
           )
       ''')
       conn.commit()
       conn.close()

   class TaskAPI(Resource):
       def get(self):
           parser = reqparse.RequestParser()
           parser.add_argument('query', type=str, default='')
           args = parser.parse_args()
           conn = sqlite3.connect('tasks.db')
           c = conn.cursor()
           if args['query']:
               c.execute("SELECT * FROM tasks WHERE task LIKE ?", ('%' + args['query'] + '%',))
           else:
               c.execute("SELECT * FROM tasks")
           tasks = [{'id': row[0], 'task': row[1], 'priority': row[2], 'status': row[3], 'category': row[4], 'created': row[5]} for row in c.fetchall()]
           conn.close()
           return tasks

       def post(self):
           parser = reqparse.RequestParser()
           parser.add_argument('task', type=str, required=True, help="Task cannot be blank")
           parser.add_argument('priority', type=int, required=True, help="Priority must be provided")
           parser.add_argument('category', type=str, default='default')
           args = parser.parse_args()
           conn = sqlite3.connect('tasks.db')
           c = conn.cursor()
           c.execute("INSERT INTO tasks (task, priority, status, category, created) VALUES (?, ?, ?, ?, datetime('now'))",
                     (args['task'], args['priority'], 'offen', args['category']))
           conn.commit()
           task_id = c.lastrowid
           conn.close()
           return {'id': task_id, 'task': args['task'], 'priority': args['priority'], 'category': args['category']}, 201

       def put(self, task_id):
           conn = sqlite3.connect('tasks.db')
           c = conn.cursor()
           c.execute("UPDATE tasks SET status = 'erledigt' WHERE id = ?", (task_id,))
           updated = c.rowcount
           conn.commit()
           conn.close()
           return {'updated': bool(updated)}, 200 if updated else 404

   api.add_resource(TaskAPI, '/api/tasks', '/api/tasks/<int:task_id>')

   if __name__ == '__main__':
       init_db()
       app.run(debug=True)
   ```
   Speichere und schließe.

4. **Schritt 4**: Erstelle das Ansible-Playbook:
   ```bash
   nano install_flask_sqlite.yml
   ```
   Füge folgenden Inhalt ein:
   ```yaml
   ---
   - name: Install and Configure Flask and SQLite on Debian Localhost
     hosts: localhost
     become: true
     vars:
       app_dir: "/opt/flask_todo"
       app_file: "{{ app_dir }}/app.py"
       db_file: "{{ app_dir }}/tasks.db"
       report_file: "/tmp/flask_install_report_{{ ansible_date_time.iso8601_basic }}.md"
     tasks:
       - name: Install system packages (Python, SQLite, curl, jq)
         ansible.builtin.apt:
           name:
             - python3
             - python3-pip
             - sqlite3
             - curl
             - jq
           state: present
           update_cache: yes
         register: apt_result

       - name: Install Flask and Flask-RESTful via pip
         ansible.builtin.pip:
           name:
             - flask
             - flask-restful
           state: present
           executable: pip3
         register: pip_result

       - name: Create application directory
         ansible.builtin.file:
           path: "{{ app_dir }}"
           state: directory
           mode: '0755'
         register: dir_result

       - name: Copy Flask application (app.py)
         ansible.builtin.copy:
           src: app.py
           dest: "{{ app_file }}"
           mode: '0644'
         register: copy_result

       - name: Initialize SQLite database
         ansible.builtin.command:
           cmd: sqlite3 {{ db_file }} "CREATE TABLE IF NOT EXISTS tasks (id INTEGER PRIMARY KEY AUTOINCREMENT, task TEXT NOT NULL, priority INTEGER NOT NULL, status TEXT NOT NULL, category TEXT NOT NULL, created TEXT NOT NULL)"
           creates: "{{ db_file }}"
         register: db_result

       - name: Check if Flask app is already running
         ansible.builtin.shell: ps aux | grep '[p]ython3.*app.py' || true
         register: flask_status
         changed_when: false

       - name: Start Flask application in background
         ansible.builtin.command:
           cmd: nohup python3 {{ app_file }} &
           chdir: "{{ app_dir }}"
         when: flask_status.stdout == ""
         register: flask_start_result

       - name: Wait for Flask to be available
         ansible.builtin.wait_for:
           host: localhost
           port: 5000
           state: started
           timeout: 30
         register: flask_port_result

       - name: Test Flask API
         ansible.builtin.uri:
           url: http://localhost:5000/api/tasks
           method: GET
           status_code: 200
         register: api_test_result

       - name: Create installation report
         ansible.builtin.template:
           src: report_template.j2
           dest: "{{ report_file }}"
           mode: '0644'

   - name: Create report template
     hosts: localhost
     tasks:
       - name: Create report template file
         ansible.builtin.copy:
           content: |
             # Flask and SQLite Installation Report
             Generated on: {{ ansible_date_time.iso8601 }}

             | Task | Status | Changed |
             |------|--------|---------|
             | Install system packages | {{ apt_result.state | default('failed') }} | {{ apt_result.changed | string | capitalize }} |
             | Install Flask and Flask-RESTful | {{ pip_result.state | default('failed') }} | {{ pip_result.changed | string | capitalize }} |
             | Create application directory | {{ dir_result.state | default('failed') }} | {{ dir_result.changed | string | capitalize }} |
             | Copy Flask application | {{ copy_result.state | default('failed') }} | {{ copy_result.changed | string | capitalize }} |
             | Initialize SQLite database | {{ db_result.state | default('failed') }} | {{ db_result.changed | string | capitalize }} |
             | Start Flask application | {{ flask_start_result.state | default('skipped') }} | {{ flask_start_result.changed | default(false) | string | capitalize }} |
             | Flask API test | {{ api_test_result.state | default('failed') }} | {{ api_test_result.status | default(0) == 200 | string | capitalize }} |
           dest: report_template.j2
           mode: '0644'
   ```
   Speichere und schließe.

5. **Schritt 5**: Führe das Playbook aus:
   ```bash
   ansible-playbook -i inventory.yml install_flask_sqlite.yml
   ```

6. **Schritt 6**: Überprüfe den Installationsbericht:
   ```bash
   cat /tmp/flask_install_report_*.md
   ```
   Die Ausgabe sollte so aussehen:
   ```
   # Flask and SQLite Installation Report
   Generated on: 20250904T141200Z

   | Task | Status | Changed |
   |------|--------|---------|
   | Install system packages | ok | True |
   | Install Flask and Flask-RESTful | ok | True |
   | Create application directory | ok | True |
   | Copy Flask application | ok | True |
   | Initialize SQLite database | ok | True |
   | Start Flask application | ok | True |
   | Flask API test | ok | True |
   ```

7. **Schritt 7**: Teste die Flask-API:
   ```bash
   curl http://localhost:5000/api/tasks
   ```
   Füge eine Aufgabe hinzu:
   ```bash
   curl -X POST -H "Content-Type: application/json" -d '{"task":"Einkaufen gehen", "priority":2, "category":"Lebensmittel"}' http://localhost:5000/api/tasks
   ```
   Überprüfe die Datenbank:
   ```bash
   sqlite3 /opt/flask_todo/tasks.db "SELECT * FROM tasks;"
   ```

**Reflexion**: Wie vereinfacht Ansible die Installation im Vergleich zu manuellen Schritten? Nutze `ansible-doc apt`, `ansible-doc pip` und überlege, wie du das Playbook für eine produktionsreife Umgebung (z. B. mit Gunicorn und Nginx) anpassen kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übung, um Ansible-Module wie `apt`, `pip` und `uri` zu verinnerlichen.
- **Sicheres Testen**: Nutze Testverzeichnisse und überprüfe Dateiberechtigungen (`chmod 644` für `app.py`, `600` für `tasks.db`).
- **Fehler verstehen**: Lies Ansible-Fehlermeldungen genau und nutze `ansible-doc` für Moduldetails.
- **Effiziente Entwicklung**: Verwende `when`-Bedingungen und `register`, um Playbooks flexibel und wiederverwendbar zu gestalten.
- **Kombiniere Tools**: Integriere Ansible mit `curl` oder `jq` für API-Tests oder mit CI/CD-Pipelines.
- **Experimentiere**: Erweitere das Playbook, z. B. durch Hinzufügen eines `supervisor`-Dienstes für Flask oder eines Nginx-Reverse-Proxys.

## Fazit
Mit dieser Übung hast du gelernt, Ansible zur automatisierten Installation und Konfiguration einer Flask-Anwendung mit SQLite auf einem Debian localhost zu nutzen. Das Playbook installiert Abhängigkeiten, richtet die Datenbank ein, kopiert die Anwendung, startet sie und generiert einen Markdown-Bericht, der den Installationsstatus dokumentiert. Im Vergleich zu manuellen Installationen reduziert Ansible den Aufwand und erhöht die Reproduzierbarkeit. Vertiefe dein Wissen, indem du das Playbook für Remote-Server, produktionsreife Setups (z. B. mit Gunicorn/Nginx) oder zusätzliche API-Tests erweiterst. Wenn du ein spezifisches Thema (z. B. Ansible-Rollen oder Sicherheitskonfigurationen) vertiefen möchtest, lass es mich wissen!

**Quellen**:
- Ansible Community Documentation: Installation und Module (`apt`, `pip`, `copy`)[](https://cloudinfrastructureservices.co.uk/how-to-install-ansible-on-debian-11-server/)
- Flask Documentation: Installation und API-Entwicklung[](https://flask.palletsprojects.com/en/stable/installation/)
- DigitalOcean: Flask mit SQLite integrieren[](https://www.digitalocean.com/community/tutorials/how-to-use-an-sqlite-database-in-a-flask-application)[](https://www.digitalocean.com/community/tutorials/how-to-use-flask-sqlalchemy-to-interact-with-databases-in-a-flask-application)
- Stack Overflow: Flask mit SQLite einrichten[](https://stackoverflow.com/questions/70855824/how-to-get-sqlite-working-in-my-flask-application)
