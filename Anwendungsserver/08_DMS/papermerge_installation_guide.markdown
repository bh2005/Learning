```markdown
# Lernprojekt: Installation von Papermerge DMS auf Debian 12

## Vorbereitung: Umgebung prüfen
1. **Proxmox VE prüfen**:
   - Melde dich an der Proxmox-Weboberfläche an: `https://192.168.30.2:8006`.
   - Stelle sicher, dass die LXC-Container für die Ubuntu-VM (`192.168.30.101`) laufen:
     ```bash
     pct list
     ```
     - Erwartete Ausgabe: Container `ubuntu` mit Status `running`.
2. **DNS in OPNsense prüfen**:
   - Öffne die OPNsense-Weboberfläche: `http://192.168.30.1`.
   - Gehe zu `Services > Unbound DNS > Overrides > Host`.
   - Füge einen Eintrag hinzu:
     - Host: `papermerge.homelab.local` → IP: `192.168.30.120`
   - Teste die DNS-Auflösung:
     ```bash
     nslookup papermerge.homelab.local 192.168.30.1
     ```
     - Erwartete Ausgabe: `192.168.30.120`.
3. **Ansible-Umgebung prüfen**:
   - Auf der Ubuntu-VM (`192.168.30.101`):
     ```bash
     ssh ubuntu@192.168.30.101
     ansible --version
     ```
   - Stelle sicher, dass SSH-Zugriff auf den Papermerge-Server möglich ist (nach Container-Erstellung):
     ```bash
     ssh root@192.168.30.120
     ```
4. **Checkmk prüfen**:
   - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
   - Melde dich an (z. B. Benutzer: `cmkadmin`, Passwort aus `elk_checkmk_integration_guide.md`).
   - Prüfe, ob die Checkmk-Site `homelab` läuft:
     ```bash
     omd status homelab
     ```
     - Erwartete Ausgabe: `running` für alle Dienste (z. B. `mkeventd`, `rrdcached`).
5. **Projektverzeichnis erstellen**:
   - Auf `192.168.30.101`:
     ```bash
     mkdir ~/papermerge-installation
     cd ~/papermerge-installation
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf OPNsense (`192.168.30.1`), TrueNAS (`192.168.30.100`) und den Papermerge-Server (`192.168.30.120`).

## Übung 1: Installation und Konfiguration von Papermerge DMS

**Ziel**: Installiere Papermerge DMS auf einem Debian 12 LXC-Container mit PostgreSQL, Nginx, Gunicorn und einem NFS-Mount von TrueNAS.

**Aufgabe**: Erstelle einen LXC-Container, installiere Papermerge mit Ansible und konfiguriere die Datenbank sowie den Dokumentenspeicher.

1. **LXC-Container für Papermerge erstellen**:
   - In Proxmox: `Create CT`:
     - Hostname: `papermerge`
     - Template: Debian 12-Standard
     - IP-Adresse: `192.168.30.120/24`
     - Gateway: `192.168.30.1`
     - DNS-Server: `192.168.30.1`
     - Speicher: 20 GB, CPU: 2 Kerne, RAM: 4 GB
     - **Wichtiger Hinweis**: Aktiviere `Nesting` und `NFS` in den Container-Optionen, um NFS-Mounts zu unterstützen.
   - Starte den Container.

2. **Ansible-Inventar erstellen**:
   - Erstelle eine Inventar-Datei:
     ```bash
     nano inventory.yml
     ```
     - Inhalt:
       ```yaml
       all:
         children:
           papermerge_servers:
             hosts:
               papermerge:
                 ansible_host: 192.168.30.120
                 ansible_user: root
                 ansible_connection: ssh
                 ansible_python_interpreter: /usr/bin/python3
           checkmk_servers:
             hosts:
               checkmk:
                 ansible_host: 192.168.30.101
                 ansible_user: ubuntu
                 ansible_connection: ssh
                 ansible_python_interpreter: /usr/bin/python3
           network_devices:
             hosts:
               opnsense:
                 ansible_host: 192.168.30.1
                 ansible_user: root
                 ansible_connection: ssh
                 ansible_network_os: freebsd
       ```

3. **Ansible-Playbook für Papermerge-Installation**:
   - Erstelle ein Playbook:
     ```bash
     nano install_papermerge.yml
     ```
     - Inhalt:
       ```yaml
       - name: Install Papermerge DMS on Debian 12
         hosts: papermerge_servers
         become: yes
         vars:
           truenas_nfs_share: "192.168.30.100:/mnt/tank/papermerge"
           papermerge_data_dir: "/var/lib/papermerge"
           postgresql_version: "15"
           papermerge_db_name: "papermerge"
           papermerge_db_user: "papermerge_user"
           papermerge_db_password: "securepassword456"
         tasks:
           - name: Update apt cache
             ansible.builtin.apt:
               update_cache: yes
           - name: Install dependencies
             ansible.builtin.apt:
               name: "{{ packages }}"
               state: present
             vars:
               packages:
                 - python3
                 - python3-pip
                 - python3-venv
                 - git
                 - nginx
                 - postgresql
                 - postgresql-contrib
                 - libpq-dev
                 - tesseract-ocr
                 - tesseract-ocr-eng
                 - tesseract-ocr-deu
                 - tesseract-ocr-fra
                 - tesseract-ocr-spa
                 - imagemagick
                 - poppler-utils
                 - pdftk
                 - nfs-common
           - name: Install Gunicorn
             ansible.builtin.pip:
               name: gunicorn
               state: present
           - name: Start and enable PostgreSQL
             ansible.builtin.service:
               name: postgresql
               state: started
               enabled: yes
           - name: Create PostgreSQL database for Papermerge
             ansible.builtin.command: >
               su - postgres -c "createdb {{ papermerge_db_name }}"
             args:
               creates: "/var/lib/postgresql/{{ postgresql_version }}/main"
           - name: Create PostgreSQL user for Papermerge
             ansible.builtin.command: >
               su - postgres -c "psql -c \"CREATE USER {{ papermerge_db_user }} WITH PASSWORD '{{ papermerge_db_password }}';\""
             args:
               creates: "/var/lib/postgresql/{{ postgresql_version }}/main"
           - name: Grant privileges to Papermerge user
             ansible.builtin.command: >
               su - postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE {{ papermerge_db_name }} TO {{ papermerge_db_user }};\""
           - name: Clone Papermerge repository
             ansible.builtin.git:
               repo: https://github.com/papermerge/papermerge-core.git
               dest: /opt/papermerge
               version: v3.5.3
           - name: Create Python virtual environment
             ansible.builtin.command: >
               python3 -m venv /opt/papermerge/.venv
             args:
               creates: /opt/papermerge/.venv
           - name: Install Papermerge dependencies
             ansible.builtin.pip:
               requirements: /opt/papermerge/requirements/base.txt
               virtualenv: /opt/papermerge/.venv
           - name: Create Papermerge data directory
             ansible.builtin.file:
               path: "{{ papermerge_data_dir }}"
               state: directory
               owner: www-data
               group: www-data
               mode: '0755'
           - name: Mount TrueNAS NFS share
             ansible.builtin.mount:
               path: "{{ papermerge_data_dir }}"
               src: "{{ truenas_nfs_share }}"
               fstype: nfs
               state: mounted
           - name: Configure Papermerge settings
             ansible.builtin.copy:
               dest: /opt/papermerge/papermerge.conf.py
               content: |
                 import os
                 DATABASES = {
                     'default': {
                         'ENGINE': 'django.db.backends.postgresql',
                         'NAME': '{{ papermerge_db_name }}',
                         'USER': '{{ papermerge_db_user }}',
                         'PASSWORD': '{{ papermerge_db_password }}',
                         'HOST': 'localhost',
                         'PORT': '5432',
                     }
                 }
                 MEDIA_ROOT = '{{ papermerge_data_dir }}'
                 BASE_URL = 'http://papermerge.homelab.local/'
               mode: '0644'
               owner: www-data
               group: www-data
           - name: Run database migrations
             ansible.builtin.command: >
               /opt/papermerge/.venv/bin/python /opt/papermerge/manage.py migrate
             environment:
               PAPERMERGE_CONFIG: /opt/papermerge/papermerge.conf.py
           - name: Create superuser
             ansible.builtin.command: >
               /opt/papermerge/.venv/bin/python /opt/papermerge/manage.py createsuperuser --noinput --username admin --email admin@homelab.local
             environment:
               DJANGO_SUPERUSER_PASSWORD: securepassword789
               PAPERMERGE_CONFIG: /opt/papermerge/papermerge.conf.py
           - name: Create Gunicorn service
             ansible.builtin.copy:
               dest: /etc/systemd/system/gunicorn.service
               content: |
                 [Unit]
                 Description=Gunicorn instance for Papermerge
                 After=network.target
                 [Service]
                 User=www-data
                 Group=www-data
                 WorkingDirectory=/opt/papermerge
                 Environment="PAPERMERGE_CONFIG=/opt/papermerge/papermerge.conf.py"
                 ExecStart=/opt/papermerge/.venv/bin/gunicorn --workers 3 --bind 127.0.0.1:8000 papermerge.wsgi:application
                 [Install]
                 WantedBy=multi-user.target
               mode: '0644'
           - name: Start and enable Gunicorn
             ansible.builtin.service:
               name: gunicorn
               state: started
               enabled: yes
           - name: Configure Nginx
             ansible.builtin.copy:
               dest: /etc/nginx/sites-available/papermerge
               content: |
                 server {
                     listen 80;
                     server_name papermerge.homelab.local;
                     location / {
                         proxy_pass http://127.0.0.1:8000;
                         proxy_set_header Host $host;
                         proxy_set_header X-Real-IP $remote_addr;
                         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                     }
                 }
               mode: '0644'
           - name: Enable Nginx site
             ansible.builtin.file:
               src: /etc/nginx/sites-available/papermerge
               dest: /etc/nginx/sites-enabled/papermerge
               state: link
           - name: Start and enable Nginx
             ansible.builtin.service:
               name: nginx
               state: started
               enabled: yes
           - name: Test Papermerge
             ansible.builtin.uri:
               url: http://192.168.30.120/
               return_content: yes
             register: papermerge_test
             ignore_errors: yes
           - name: Display Papermerge test result
             ansible.builtin.debug:
               msg: "{{ papermerge_test.status }}"
       - name: Configure OPNsense firewall for Papermerge
         hosts: network_devices
         tasks:
           - name: Add firewall rule for Papermerge (80)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.120",
                 "destination_port":"80",
                 "description":"Allow Papermerge Access"
               }'
           - name: Verify firewall rules
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Display firewall rules
             ansible.builtin.debug:
               msg: "{{ rules_list.stdout }}"
       ```
   - **Erklärung**:
     - Installiert Python, PostgreSQL, Nginx, Gunicorn und Abhängigkeiten (z. B. Tesseract für OCR).
     - Konfiguriert eine PostgreSQL-Datenbank und Benutzer für Papermerge.
     - Klont das Papermerge-Core-Repository (Version 3.5.3) und installiert Abhängigkeiten in einer virtuellen Umgebung.
     - Bindet den TrueNAS-Dokumentenspeicher (`/mnt/tank/papermerge`) über NFS ein.
     - Konfiguriert Papermerge (`papermerge.conf.py`) mit Datenbank- und Speichereinstellungen.
     - Erstellt einen Gunicorn-Dienst für die Django-Anwendung und konfiguriert Nginx als Reverse-Proxy.
     - Führt Datenbankmigrationen durch und erstellt einen Admin-Benutzer.
     - Konfiguriert die OPNsense-Firewall für Zugriff auf Papermerge (Port 80).
     - Testet die Papermerge-Weboberfläche.
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml install_papermerge.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display Papermerge test result] ****************************************
       ok: [papermerge] => {
           "msg": 200
       }
       TASK [Display firewall rules] ************************************************
       ok: [opnsense] => {
           "msg": "... Allow Papermerge Access ..."
       }
       ```
   - Prüfe Papermerge:
     - Öffne `http://papermerge.homelab.local`.
     - Melde dich an (Benutzer: `admin`, Passwort: `securepassword789`).
     - Lade ein Testdokument hoch (z. B. PDF-Datei in `/mnt/tank/papermerge`).
     - Erwartete Ausgabe: Papermerge-Weboberfläche ist zugänglich, OCR funktioniert, und Dokumente können hochgeladen/angezeigt werden.
     - **Hinweis**: Falls die Weboberfläche nicht lädt, überprüfe Nginx- und Gunicorn-Logs:
       ```bash
       ssh root@192.168.30.120 "cat /var/log/nginx/error.log"
       ssh root@192.168.30.120 "journalctl -u gunicorn"
       ```

**Erkenntnis**: Papermerge DMS kann auf Debian 12 mit PostgreSQL, Django, Gunicorn und Nginx installiert werden, wobei TrueNAS für Dokumentenspeicherung integriert wird. Ansible automatisiert den Prozess.

**Quelle**: https://docs.papermerge.io, https://github.com/ciur/papermerge[](https://github.com/ciur/papermerge)[](https://docs.papermerge.io/2.0/setup/installation/)

## Übung 2: Einrichtung eines benutzerdefinierten Checks in Checkmk

**Ziel**: Erstelle einen Checkmk-Check, um den Papermerge-Dienst und die Weboberfläche zu überwachen.

**Aufgabe**: Implementiere einen Check, der den Status des Gunicorn- und Nginx-Dienste sowie die Erreichbarkeit der Papermerge-Weboberfläche prüft.

1. **Ansible-Playbook für Checkmk-Check**:
   - Erstelle ein Playbook:
     ```bash
     nano papermerge_checkmk.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure Checkmk for Papermerge Monitoring
         hosts: checkmk_servers
         become: yes
         vars:
           checkmk_site: "homelab"
           checkmk_user: "cmkadmin"
           checkmk_password: "securepassword123"
           papermerge_host: "papermerge.homelab.local"
         tasks:
           - name: Install Checkmk agent on Papermerge server
             ansible.builtin.apt:
               name: check-mk-agent
               state: present
               update_cache: yes
             delegate_to: papermerge
           - name: Enable Checkmk agent service on Papermerge
             ansible.builtin.service:
               name: check-mk-agent
               state: started
               enabled: yes
             delegate_to: papermerge
           - name: Create Papermerge check script
             ansible.builtin.copy:
               dest: /omd/sites/{{ checkmk_site }}/local/share/check_mk/checks/papermerge_service
               content: |
                 #!/bin/bash
                 GUNICORN_STATUS=$(systemctl is-active gunicorn)
                 NGINX_STATUS=$(systemctl is-active nginx)
                 RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://192.168.30.120/)
                 if [ "$GUNICORN_STATUS" == "active" ] && [ "$NGINX_STATUS" == "active" ] && [ "$RESPONSE" == "200" ]; then
                   echo "0 Papermerge_Service - Papermerge is running and web interface is accessible"
                 else
                   echo "2 Papermerge_Service - Papermerge is not running (Gunicorn: $GUNICORN_STATUS, Nginx: $NGINX_STATUS) or web interface is not accessible (HTTP: $RESPONSE)"
                 fi
               mode: '0755'
           - name: Add Papermerge host to Checkmk
             ansible.builtin.command: >
               cmk -v -U {{ checkmk_user }}:{{ checkmk_password }} {{ checkmk_site }} add-host {{ papermerge_host }} 192.168.30.120
             args:
               creates: /omd/sites/{{ checkmk_site }}/etc/check_mk/conf.d/wato/hosts.mk
           - name: Discover services for Papermerge
             ansible.builtin.command: >
               cmk -v -U {{ checkmk_user }}:{{ checkmk_password }} {{ checkmk_site }} discover-services {{ papermerge_host }}
           - name: Activate changes in Checkmk
             ansible.builtin.command: >
               cmk -v -U {{ checkmk_user }}:{{ checkmk_password }} {{ checkmk_site }} activate
           - name: Verify Papermerge services in Checkmk
             ansible.builtin.command: >
               cmk -v -U {{ checkmk_user }}:{{ checkmk_password }} {{ checkmk_site }} list-services {{ papermerge_host }}
             register: service_list
           - name: Display Papermerge services
             ansible.builtin.debug:
               msg: "{{ service_list.stdout }}"
       - name: Configure OPNsense firewall for Checkmk
         hosts: network_devices
         tasks:
           - name: Add firewall rule for Checkmk agent (6556)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.101",
                 "destination":"192.168.30.120",
                 "destination_port":"6556",
                 "description":"Allow Checkmk to Papermerge"
               }'
           - name: Verify firewall rules
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Display firewall rules
             ansible.builtin.debug:
               msg: "{{ rules_list.stdout }}"
       ```
   - **Erklärung**:
     - Installiert den Checkmk-Agenten auf dem Papermerge-Server.
     - Erstellt einen benutzerdefinierten Check (`papermerge_service`), der die Gunicorn- und Nginx-Dienste sowie die Weboberfläche prüft.
     - Fügt Papermerge als Host in Checkmk hinzu und aktiviert den Check.
     - Konfiguriert die OPNsense-Firewall für den Checkmk-Agenten (Port 6556).
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml papermerge_checkmk.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display Papermerge services] *******************************************
       ok: [checkmk] => {
           "msg": "... Papermerge_Service ..."
       }
       TASK [Display firewall rules] ************************************************
       ok: [opnsense] => {
           "msg": "... Allow Checkmk to Papermerge ..."
       }
       ```
   - Prüfe in Checkmk:
     - Öffne `http://192.168.30.101:5000/homelab`.
     - Gehe zu `Monitor > All hosts > papermerge.homelab.local`.
     - Erwartete Ausgabe: `Papermerge_Service` zeigt Status `OK`.

**Erkenntnis**: Checkmk kann den Papermerge-Dienst effektiv überwachen, indem es die Gunicorn- und Nginx-Dienste sowie die Weboberfläche prüft.

**Quelle**: https://docs.checkmk.com/latest/en/localchecks.html

## Übung 3: Backup der Papermerge-Konfiguration und Datenbank auf TrueNAS

**Ziel**: Sichere die Papermerge-Konfiguration und Datenbank auf TrueNAS.

**Aufgabe**: Erstelle ein Ansible-Playbook für Backups und begrenze sie auf maximal fünf Versionen.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_papermerge.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup Papermerge configuration and database
         hosts: papermerge_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/papermerge-installation/backups/papermerge"
           config_backup_file: "{{ backup_dir }}/papermerge-config-backup-{{ ansible_date_time.date }}.tar.gz"
           db_backup_file: "{{ backup_dir }}/papermerge-db-backup-{{ ansible_date_time.date }}.sql.gz"
           papermerge_db_name: "papermerge"
           papermerge_db_user: "papermerge_user"
           papermerge_db_password: "securepassword456"
         tasks:
           - name: Create backup directory
             ansible.builtin.file:
               path: "{{ backup_dir }}"
               state: directory
               mode: '0755'
             delegate_to: localhost
           - name: Stop Gunicorn service
             ansible.builtin.service:
               name: gunicorn
               state: stopped
           - name: Backup Papermerge configuration
             ansible.builtin.command: >
               tar -czf /tmp/papermerge-config-backup-{{ ansible_date_time.date }}.tar.gz /opt/papermerge
             register: config_backup_result
           - name: Start Gunicorn service
             ansible.builtin.service:
               name: gunicorn
               state: started
           - name: Backup Papermerge database
             ansible.builtin.command: >
               su - postgres -c "pg_dump -U {{ papermerge_db_user }} {{ papermerge_db_name }}" | gzip > /tmp/papermerge-db-backup-{{ ansible_date_time.date }}.sql.gz
             environment:
               PGPASSWORD: "{{ papermerge_db_password }}"
             register: db_backup_result
           - name: Fetch configuration backup file
             ansible.builtin.fetch:
               src: /tmp/papermerge-config-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ config_backup_file }}"
               flat: yes
           - name: Fetch database backup file
             ansible.builtin.fetch:
               src: /tmp/papermerge-db-backup-{{ ansible_date_time.date }}.sql.gz
               dest: "{{ db_backup_file }}"
               flat: yes
           - name: Limit Papermerge configuration backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t papermerge-config-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Limit Papermerge database backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t papermerge-db-backup-*.sql.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync Papermerge backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/papermerge-installation/
             delegate_to: localhost
           - name: Display Papermerge backup status
             ansible.builtin.debug:
               msg: "Papermerge configuration backup saved to {{ config_backup_file }} and database backup to {{ db_backup_file }}; synced to TrueNAS"
       ```
   - **Erklärung**:
     - Sichert die Papermerge-Konfiguration (`/opt/papermerge`) und die Datenbank (`papermerge`).
     - Stoppt Gunicorn, um konsistente Backups zu gewährleisten.
     - Begrenzt Backups auf fünf Versionen pro Typ (Konfiguration und Datenbank).
     - Synchronisiert Backups mit TrueNAS.
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_papermerge.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display Papermerge backup status] **************************************
       ok: [papermerge] => {
           "msg": "Papermerge configuration backup saved to /home/ubuntu/papermerge-installation/backups/papermerge/papermerge-config-backup-<date>.tar.gz and database backup to /home/ubuntu/papermerge-installation/backups/papermerge/papermerge-db-backup-<date>.sql.gz; synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/papermerge-installation/
     ```
     - Erwartete Ausgabe: Maximal fünf Backups pro Typ (`papermerge-config-backup-<date>.tar.gz`, `papermerge-db-backup-<date>.sql.gz`).

2. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/papermerge-installation
       ansible-playbook -i inventory.yml backup_papermerge.yml >> backup.log 2>&1
       ```
     - Ausführbar machen:
       ```bash
       chmod +x run_backup.sh
       ```
   - Plane einen Cronjob:
     ```bash
     crontab -e
     ```
     - Füge hinzu:
       ```
       0 3 * * * /home/ubuntu/papermerge-installation/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible automatisiert die Sicherung der Papermerge-Konfiguration und Datenbank, während TrueNAS zuverlässige externe Speicherung bietet.

## Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass die Firewall-Regeln aus Übung 1 (Port 80 für Papermerge, Port 6556 für Checkmk-Agent) aktiv sind.
   - Prüfe OPNsense-Logs:
     ```bash
     ansible-playbook -i inventory.yml -m ansible.builtin.command -a "cat /var/log/system/latest.log" opnsense
     ```

2. **Erweiterung mit weiteren Checks**:
   - Erstelle einen Check für die Anzahl der Dokumente:
     ```bash
     nano /omd/sites/homelab/local/share/check_mk/checks/papermerge_documents
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       COUNT=$(find /var/lib/papermerge -type f | wc -l)
       if [ $COUNT -gt 0 ]; then
         echo "0 Papermerge_Documents documents=$COUNT Papermerge contains $COUNT documents"
       else
         echo "2 Papermerge_Documents documents=$COUNT Papermerge data directory is empty"
       fi
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /omd/sites/homelab/local/share/check_mk/checks/papermerge_documents
       ```
     - In Checkmk: `Setup > Services > Manual checks > Custom checks`, füge `Papermerge_Documents` hinzu.

## Schritt 5: Erweiterung der Übungen
1. **Erweiterte Papermerge-Konfiguration**:
   - Erstelle ein Playbook für Benutzerverwaltung:
     ```bash
     nano configure_papermerge_users.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure Papermerge users
         hosts: papermerge_servers
         become: yes
         tasks:
           - name: Add test user to Papermerge
             ansible.builtin.command: >
               /opt/papermerge/.venv/bin/python /opt/papermerge/manage.py createsuperuser --noinput --username testuser --email testuser@homelab.local
             environment:
               DJANGO_SUPERUSER_PASSWORD: testpassword123
               PAPERMERGE_CONFIG: /opt/papermerge/papermerge.conf.py
           - name: Verify user addition
             ansible.builtin.command: >
               /opt/papermerge/.venv/bin/python /opt/papermerge/manage.py shell -c "from django.contrib.auth.models import User; print(User.objects.filter(username='testuser').exists())"
             environment:
               PAPERMERGE_CONFIG: /opt/papermerge/papermerge.conf.py
             register: user_result
           - name: Display user addition result
             ansible.builtin.debug:
               msg: "{{ user_result.stdout }}"
       ```

2. **Backup-Versionierung mit Git**:
   - Initialisiere ein Git-Repository für Backups:
     ```bash
     cd ~/papermerge-installation/backups
     git init
     git add .
     git commit -m "Initial Papermerge backups"
     ```

## Best Practices für Schüler

- **Papermerge-Design**:
  - Organisiere Dokumente auf TrueNAS (`/mnt/tank/papermerge`) mit klaren Verzeichnisstrukturen.
  - Teste die Papermerge-Weboberfläche (`http://papermerge.homelab.local`) und lade Testdokumente hoch (z. B. PDFs, um OCR zu testen).
- **Sicherheit**:
  - Schränke Papermerge-Zugriff ein:
    ```bash
    ssh root@192.168.30.120 "ufw allow from 192.168.30.0/24 to any port 80 proto tcp"
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
  - Verwende HTTPS für Papermerge bei externem Zugriff:
    ```bash
    ssh root@192.168.30.120 "turnkey-letsencrypt papermerge.homelab.local"
    ```
  - Sichere PostgreSQL-Zugangsdaten:
    ```bash
    ssh root@192.168.30.120 "chmod 600 /opt/papermerge/papermerge.conf.py"
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
  - Teste Backups vor Updates (siehe https://docs.papermerge.io).
- **Fehlerbehebung**:
  - Prüfe Nginx-Logs:
    ```bash
    ssh root@192.168.30.120 "cat /var/log/nginx/error.log"
    ```
  - Prüfe Gunicorn-Logs:
    ```bash
    ssh root@192.168.30.120 "journalctl -u gunicorn"
    ```
  - Prüfe PostgreSQL-Logs:
    ```bash
    ssh root@192.168.30.120 "cat /var/log/postgresql/postgresql-15-main.log"
    ```
  - Prüfe Checkmk-Logs:
    ```bash
    cat /omd/sites/homelab/var/log/web.log
    ```
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/papermerge-installation/backup.log
    ```
  - Falls OCR fehlschlägt, überprüfe Tesseract-Installation:
    ```bash
    ssh root@192.168.30.120 "tesseract --version"
    ```

**Quellen**: https://docs.papermerge.io, https://github.com/ciur/papermerge, https://docs.checkmk.com, https://docs.ansible.com, https://docs.opnsense.org/manual[](https://github.com/ciur/papermerge)[](https://docs.papermerge.io/2.0/setup/installation/)

## Empfehlungen für Schüler

- **Setup**: Papermerge DMS, TrueNAS-Dokumentenspeicher, Checkmk-Monitoring, TrueNAS-Backups.
- **Workloads**: Dokumentenmanagement, OCR, Überwachung, Backups.
- **Integration**: Proxmox (LXC), TrueNAS (NFS), OPNsense (DNS, Netzwerk).
- **Beispiel**: Dokumentenmanagementsystem mit OCR und Volltextsuche im HomeLab.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einer kleinen Dokumentenbibliothek, teste OCR mit PDFs.
- **Übung**: Lade verschiedene Dateitypen (PDF, TIFF, JPEG) hoch und teste die Volltextsuche.
- **Fehlerbehebung**: Nutze Nginx-, Gunicorn-, PostgreSQL- und Checkmk-Logs für Debugging.
- **Lernressourcen**: https://docs.papermerge.io, https://github.com/ciur/papermerge, https://docs.checkmk.com, https://docs.ansible.com.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Schnelle Installation von Papermerge DMS mit TrueNAS-Integration und OCR-Funktionalität.
- **Skalierbarkeit**: Automatisierte Überwachung und Backup-Prozesse.
- **Lernwert**: Verständnis von Dokumentenmanagement, OCR und Monitoring in einer HomeLab-Umgebung.

**Nächste Schritte**: Möchtest du eine Anleitung zur Integration von Papermerge mit Home Assistant, Erweiterung der Checkmk-Checks (z. B. Überwachung der OCR-Leistung), oder eine andere Anpassung?

**Quellen**:
- Papermerge-Dokumentation: https://docs.papermerge.io
- Checkmk-Dokumentation: https://docs.checkmk.com
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen: https://github.com/ciur/papermerge, https://papermerge.com[](https://github.com/ciur/papermerge)[](https://docs.papermerge.io/2.0/setup/installation/)
```