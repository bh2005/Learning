# Lernprojekt: Upgrade von Debian 12 (Bookworm) auf Debian 13 (Trixie)

## Vorbereitung: Umgebung prüfen
1. **Proxmox VE prüfen**:
   - Melde dich an der Proxmox-Weboberfläche an: `https://192.168.30.2:8006`.
   - Stelle sicher, dass der LXC-Container für Papermerge (`192.168.30.120`) läuft:
     ```bash
     pct list
     ```
     - Erwartete Ausgabe: Container `papermerge` mit Status `running`.
2. **DNS in OPNsense prüfen**:
   - Öffne die OPNsense-Weboberfläche: `http://192.168.30.1`.
   - Gehe zu `Services > Unbound DNS > Overrides > Host`.
   - Überprüfe den Eintrag:
     - `papermerge.homelab.local` → `192.168.30.120`
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
   - Stelle sicher, dass SSH-Zugriff auf den Papermerge-Server möglich ist:
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
5. **Debian-Version prüfen**:
   - Auf dem Papermerge-Server:
     ```bash
     ssh root@192.168.30.120 "cat /etc/os-release"
     ```
     - Erwartete Ausgabe: `VERSION_CODENAME=bookworm`.
6. **Projektverzeichnis erstellen**:
   - Auf `192.168.30.101`:
     ```bash
     mkdir ~/debian-upgrade
     cd ~/debian-upgrade
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf OPNsense (`192.168.30.1`), TrueNAS (`192.168.30.100`) und den Papermerge-Server (`192.168.30.120`).

## Übung 1: Vorbereitung und Backup des Debian 12 Systems

**Ziel**: Erstelle ein vollständiges Backup des Debian 12 Systems, einschließlich Papermerge-Konfiguration, Datenbank und Dokumentenspeicher.

**Aufgabe**: Sichere die Papermerge-Konfiguration, PostgreSQL-Datenbank und den NFS-Mount auf TrueNAS.

1. **Ansible-Inventar erstellen**:
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

2. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_before_upgrade.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup Debian 12 system before upgrade
         hosts: papermerge_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/debian-upgrade/backups/papermerge"
           config_backup_file: "{{ backup_dir }}/papermerge-config-backup-{{ ansible_date_time.date }}.tar.gz"
           db_backup_file: "{{ backup_dir }}/papermerge-db-backup-{{ ansible_date_time.date }}.sql.gz"
           system_backup_file: "{{ backup_dir }}/system-backup-{{ ansible_date_time.date }}.tar.gz"
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
           - name: Stop Gunicorn and Nginx services
             ansible.builtin.service:
               name: "{{ item }}"
               state: stopped
             loop:
               - gunicorn
               - nginx
           - name: Backup Papermerge configuration
             ansible.builtin.command: >
               tar -czf /tmp/papermerge-config-backup-{{ ansible_date_time.date }}.tar.gz /opt/papermerge
             register: config_backup_result
           - name: Backup Papermerge database
             ansible.builtin.command: >
               su - postgres -c "pg_dump -U {{ papermerge_db_user }} {{ papermerge_db_name }}" | gzip > /tmp/papermerge-db-backup-{{ ansible_date_time.date }}.sql.gz
             environment:
               PGPASSWORD: "{{ papermerge_db_password }}"
             register: db_backup_result
           - name: Backup system configuration
             ansible.builtin.command: >
               tar -czf /tmp/system-backup-{{ ansible_date_time.date }}.tar.gz /etc /var/lib/postgresql
             register: system_backup_result
           - name: Start Gunicorn and Nginx services
             ansible.builtin.service:
               name: "{{ item }}"
               state: started
             loop:
               - gunicorn
               - nginx
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
           - name: Fetch system backup file
             ansible.builtin.fetch:
               src: /tmp/system-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ system_backup_file }}"
               flat: yes
           - name: Limit backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t *-backup-*.{tar.gz,sql.gz} | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/debian-upgrade/
             delegate_to: localhost
           - name: Display backup status
             ansible.builtin.debug:
               msg: "Backups saved to {{ config_backup_file }}, {{ db_backup_file }}, {{ system_backup_file }} and synced to TrueNAS"
       ```
   - **Erklärung**:
     - Sichert die Papermerge-Konfiguration (`/opt/papermerge`), die PostgreSQL-Datenbank (`papermerge`) und wichtige Systemverzeichnisse (`/etc`, `/var/lib/postgresql`).
     - Stoppt Gunicorn und Nginx, um konsistente Backups zu gewährleisten.
     - Begrenzt Backups auf fünf Versionen.
     - Synchronisiert Backups mit TrueNAS.
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_before_upgrade.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display backup status] ************************************************
       ok: [papermerge] => {
           "msg": "Backups saved to /home/ubuntu/debian-upgrade/backups/papermerge/papermerge-config-backup-<date>.tar.gz, /home/ubuntu/debian-upgrade/backups/papermerge/papermerge-db-backup-<date>.sql.gz, /home/ubuntu/debian-upgrade/backups/papermerge/system-backup-<date>.tar.gz and synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/debian-upgrade/
     ```
     - Erwartete Ausgabe: Maximal fünf Backups (`papermerge-config-backup-<date>.tar.gz`, `papermerge-db-backup-<date>.sql.gz`, `system-backup-<date>.tar.gz`).

**Erkenntnis**: Ein vollständiges Backup vor dem Upgrade schützt vor Datenverlust und ermöglicht eine Wiederherstellung bei Problemen.

**Quelle**: https://wiki.debian.org/DebianUpgrade

## Übung 2: Upgrade von Debian 12 auf Debian 13

**Ziel**: Führe das Upgrade von Debian 12 (Bookworm) auf Debian 13 (Trixie) durch und stelle sicher, dass Papermerge weiter funktioniert.

**Aufgabe**: Aktualisiere die Paketquellen, führe das Upgrade durch und überprüfe die Dienste.

1. **Ansible-Playbook für das Upgrade**:
   - Erstelle ein Playbook:
     ```bash
     nano upgrade_debian.yml
     ```
     - Inhalt:
       ```yaml
       - name: Upgrade Debian 12 to Debian 13
         hosts: papermerge_servers
         become: yes
         tasks:
           - name: Update apt cache
             ansible.builtin.apt:
               update_cache: yes
           - name: Perform full upgrade on Debian 12
             ansible.builtin.apt:
               upgrade: full
               autoremove: yes
               autoclean: yes
           - name: Backup current sources.list
             ansible.builtin.copy:
               src: /etc/apt/sources.list
               dest: /etc/apt/sources.list.bak
               remote_src: yes
           - name: Update sources.list for Debian 13 (Trixie)
             ansible.builtin.copy:
               dest: /etc/apt/sources.list
               content: |
                 deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
                 deb http://deb.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
                 deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
               mode: '0644'
           - name: Update apt cache for Debian 13
             ansible.builtin.apt:
               update_cache: yes
               cache_valid_time: 3600
           - name: Perform dist-upgrade
             ansible.builtin.apt:
               upgrade: dist
               autoremove: yes
               autoclean: yes
           - name: Check Debian version
             ansible.builtin.command: cat /etc/os-release
             register: os_release
           - name: Display Debian version
             ansible.builtin.debug:
               msg: "{{ os_release.stdout }}"
           - name: Reinstall dependencies for Papermerge
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
           - name: Ensure NFS mount is active
             ansible.builtin.mount:
               path: /var/lib/papermerge
               src: 192.168.30.100:/mnt/tank/papermerge
               fstype: nfs
               state: mounted
           - name: Reinstall Papermerge dependencies
             ansible.builtin.pip:
               requirements: /opt/papermerge/requirements/base.txt
               virtualenv: /opt/papermerge/.venv
           - name: Run database migrations
             ansible.builtin.command: >
               /opt/papermerge/.venv/bin/python /opt/papermerge/manage.py migrate
             environment:
               PAPERMERGE_CONFIG: /opt/papermerge/papermerge.conf.py
           - name: Start and enable services
             ansible.builtin.service:
               name: "{{ item }}"
               state: started
               enabled: yes
             loop:
               - postgresql
               - gunicorn
               - nginx
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
           - name: Ensure firewall rule for Papermerge (80)
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
             ignore_errors: yes
           - name: Verify firewall rules
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Display firewall rules
             ansible.builtin.debug:
               msg: "{{ rules_list.stdout }}"
       ```
   - **Erklärung**:
     - Aktualisiert Debian 12 vollständig, bevor die Paketquellen geändert werden.
     - Sichert die aktuelle `sources.list` und aktualisiert sie für Debian 13 (Trixie).
     - Führt ein `dist-upgrade` durch, um das System auf Debian 13 zu aktualisieren.
     - Installiert die für Papermerge benötigten Pakete erneut, um Kompatibilitätsprobleme (z. B. Python- oder PostgreSQL-Versionen) zu vermeiden.
     - Stellt sicher, dass der NFS-Mount aktiv ist, und führt Datenbankmigrationen durch.
     - Startet PostgreSQL, Gunicorn und Nginx und testet die Papermerge-Weboberfläche.
     - Bestätigt die OPNsense-Firewall-Regel für Papermerge (Port 80).
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml upgrade_debian.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display Debian version] ************************************************
       ok: [papermerge] => {
           "msg": "... VERSION_CODENAME=trixie ..."
       }
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
     - Lade ein Testdokument hoch (z. B. PDF-Datei in `/mnt/tank/papermerge`) und teste OCR.
     - Erwartete Ausgabe: Papermerge-Weboberfläche ist zugänglich, OCR funktioniert.
     - **Hinweis**: Falls Papermerge nach dem Upgrade nicht lädt, überprüfe die Python-Version (Papermerge benötigt Python 3.9–3.11) und aktualisiere die virtuellen Umgebung:
       ```bash
       ssh root@192.168.30.120
       rm -rf /opt/papermerge/.venv
       python3 -m venv /opt/papermerge/.venv
       /opt/papermerge/.venv/bin/pip install -r /opt/papermerge/requirements/base.txt
       ```
     - Prüfe Logs bei Problemen:
       ```bash
       ssh root@192.168.30.120 "cat /var/log/nginx/error.log"
       ssh root@192.168.30.120 "journalctl -u gunicorn"
       ssh root@192.168.30.120 "cat /var/log/postgresql/postgresql-15-main.log"
       ```

**Erkenntnis**: Das Upgrade von Debian 12 auf Debian 13 erfordert sorgfältige Vorbereitung und Überprüfung der Anwendungen (z. B. Papermerge), um Kompatibilitätsprobleme zu vermeiden.

**Quelle**: https://wiki.debian.org/DebianUpgrade, https://www.debian.org/releases/trixie/releasenotes

## Übung 3: Einrichtung eines Checkmk-Checks für das aktualisierte System

**Ziel**: Erstelle einen Checkmk-Check, um das aktualisierte Debian 13 System und Papermerge zu überwachen.

**Aufgabe**: Implementiere einen Check, der die Debian-Version, Gunicorn-, Nginx- und PostgreSQL-Dienste sowie die Papermerge-Weboberfläche prüft.

1. **Ansible-Playbook für Checkmk-Check**:
   - Erstelle ein Playbook:
     ```bash
     nano post_upgrade_checkmk.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure Checkmk for Debian 13 and Papermerge Monitoring
         hosts: checkmk_servers
         become: yes
         vars:
           checkmk_site: "homelab"
           checkmk_user: "cmkadmin"
           checkmk_password: "securepassword123"
           papermerge_host: "papermerge.homelab.local"
         tasks:
           - name: Ensure Checkmk agent is installed on Papermerge server
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
           - name: Create Debian 13 and Papermerge check script
             ansible.builtin.copy:
               dest: /omd/sites/{{ checkmk_site }}/local/share/check_mk/checks/debian13_papermerge
               content: |
                 #!/bin/bash
                 DEBIAN_VERSION=$(cat /etc/os-release | grep VERSION_CODENAME | cut -d'=' -f2)
                 GUNICORN_STATUS=$(systemctl is-active gunicorn)
                 NGINX_STATUS=$(systemctl is-active nginx)
                 POSTGRESQL_STATUS=$(systemctl is-active postgresql)
                 RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://192.168.30.120/)
                 if [ "$DEBIAN_VERSION" == "trixie" ] && [ "$GUNICORN_STATUS" == "active" ] && [ "$NGINX_STATUS" == "active" ] && [ "$POSTGRESQL_STATUS" == "active" ] && [ "$RESPONSE" == "200" ]; then
                   echo "0 Debian13_Papermerge - Debian 13 (Trixie) and Papermerge are running (Web: OK)"
                 else
                   echo "2 Debian13_Papermerge - Issue detected: Debian ($DEBIAN_VERSION), Gunicorn ($GUNICORN_STATUS), Nginx ($NGINX_STATUS), PostgreSQL ($POSTGRESQL_STATUS), Web (HTTP: $RESPONSE)"
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
           - name: Ensure firewall rule for Checkmk agent (6556)
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
             ignore_errors: yes
           - name: Verify firewall rules
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Display firewall rules
             ansible.builtin.debug:
               msg: "{{ rules_list.stdout }}"
       ```
   - **Erklärung**:
     - Installiert den Checkmk-Agenten auf dem Papermerge-Server.
     - Erstellt einen benutzerdefinierten Check (`debian13_papermerge`), der die Debian-Version, Gunicorn-, Nginx- und PostgreSQL-Dienste sowie die Papermerge-Weboberfläche prüft.
     - Fügt den Papermerge-Host in Checkmk hinzu und aktiviert den Check.
     - Bestätigt die OPNsense-Firewall-Regel für den Checkmk-Agenten (Port 6556).
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml post_upgrade_checkmk.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display Papermerge services] *******************************************
       ok: [checkmk] => {
           "msg": "... Debian13_Papermerge ..."
       }
       TASK [Display firewall rules] ************************************************
       ok: [opnsense] => {
           "msg": "... Allow Checkmk to Papermerge ..."
       }
       ```
   - Prüfe in Checkmk:
     - Öffne `http://192.168.30.101:5000/homelab`.
     - Gehe zu `Monitor > All hosts > papermerge.homelab.local`.
     - Erwartete Ausgabe: `Debian13_Papermerge` zeigt Status `OK`.

**Erkenntnis**: Checkmk kann das aktualisierte Debian 13 System und die Papermerge-Dienste effektiv überwachen.

**Quelle**: https://docs.checkmk.com/latest/en/localchecks.html

## Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass die Firewall-Regeln aus Übung 2 (Port 80 für Papermerge, Port 6556 für Checkmk-Agent) aktiv sind.
   - Prüfe OPNsense-Logs:
     ```bash
     ansible-playbook -i inventory.yml -m ansible.builtin.command -a "cat /var/log/system/latest.log" opnsense
     ```

2. **Erweiterung mit weiteren Checks**:
   - Erstelle einen Check für die PostgreSQL-Datenbankgröße:
     ```bash
     nano /omd/sites/homelab/local/share/check_mk/checks/papermerge_db_size
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       SIZE=$(su - postgres -c "psql -d papermerge -t -c 'SELECT pg_database_size('papermerge') / 1024 / 1024;'")
       if [ $SIZE -gt 0 ]; then
         echo "0 Papermerge_DB_Size size=$SIZE Papermerge database size is $SIZE MB"
       else
         echo "2 Papermerge_DB_Size size=$SIZE Papermerge database is empty or inaccessible"
       fi
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /omd/sites/homelab/local/share/check_mk/checks/papermerge_db_size
       ```
     - In Checkmk: `Setup > Services > Manual checks > Custom checks`, füge `Papermerge_DB_Size` hinzu.

## Schritt 5: Erweiterung der Übungen
1. **Automatisierung des Upgrades**:
   - Erstelle ein Shell-Skript für regelmäßige Backups vor zukünftigen Upgrades:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/debian-upgrade
       ansible-playbook -i inventory.yml backup_before_upgrade.yml >> backup.log 2>&1
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
         0 3 * * * /home/ubuntu/debian-upgrade/run_backup.sh
         ```
       - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

2. **Backup-Versionierung mit Git**:
   - Initialisiere ein Git-Repository für Backups:
     ```bash
     cd ~/debian-upgrade/backups
     git init
     git add .
     git commit -m "Initial Debian 12 backups before upgrade"
     ```

## Best Practices für Schüler

- **Upgrade-Design**:
  - Teste das Upgrade zunächst in einer Testumgebung (z. B. einem geklonten LXC-Container).
  - Prüfe die Kompatibilität von Anwendungen (z. B. Papermerge) mit Debian 13, insbesondere Python- und PostgreSQL-Versionen.
- **Sicherheit**:
  - Schränke Zugriff ein:
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
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
  - Teste Backups vor dem Upgrade:
    ```bash
    ssh root@192.168.30.120
    tar -xzf /tmp/papermerge-config-backup-<date>.tar.gz -C /tmp/test-restore
    gunzip -c /tmp/papermerge-db-backup-<date>.sql.gz | su - postgres -c "psql -d papermerge_restore"
    ```
  - Prüfe die Debian-Releasenotes für bekannte Probleme (https://www.debian.org/releases/trixie/releasenotes).
- **Fehlerbehebung**:
  - Prüfe Apt-Logs:
    ```bash
    ssh root@192.168.30.120 "cat /var/log/apt/history.log"
    ssh root@192.168.30.120 "cat /var/log/apt/term.log"
    ```
  - Prüfe System-Logs:
    ```bash
    ssh root@192.168.30.120 "journalctl -xb"
    ```
  - Prüfe Papermerge-Logs:
    ```bash
    ssh root@192.168.30.120 "cat /var/log/nginx/error.log"
    ssh root@192.168.30.120 "journalctl -u gunicorn"
    ssh root@192.168.30.120 "cat /var/log/postgresql/postgresql-15-main.log"
    ```
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/debian-upgrade/backup.log
    ```
  - Falls das Upgrade fehlschlägt, stelle das Backup wieder her:
    ```bash
    ssh root@192.168.30.120
    tar -xzf /home/ubuntu/debian-upgrade/backups/papermerge/system-backup-<date>.tar.gz -C /
    ```

**Quellen**: https://wiki.debian.org/DebianUpgrade, https://www.debian.org/releases/trixie/releasenotes, https://docs.checkmk.com, https://docs.ansible.com, https://docs.opnsense.org/manual

## Empfehlungen für Schüler

- **Setup**: Debian 13, Papermerge DMS, TrueNAS-Backups, Checkmk-Monitoring.
- **Workloads**: System-Upgrade, Backup, Überwachung.
- **Integration**: Proxmox (LXC), TrueNAS (NFS), OPNsense (DNS, Netzwerk).
- **Beispiel**: Sicheres Upgrade eines produktiven Systems mit laufendem DMS.

## Tipps für den Erfolg

- **Einfachheit**: Führe das Upgrade schrittweise durch und teste nach jedem Schritt.
- **Übung**: Teste das Backup und die Wiederherstellung in einer Testumgebung.
- **Fehlerbehebung**: Nutze System-, Apt- und Anwendungslogs für Debugging.
- **Lernressourcen**: https://wiki.debian.org/DebianUpgrade, https://www.debian.org/releases/trixie/releasenotes, https://docs.papermerge.io.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Sicheres Upgrade von Debian 12 auf Debian 13 mit Backup und Überwachung.
- **Skalierbarkeit**: Automatisierte Backup- und Monitoring-Prozesse.
- **Lernwert**: Verständnis von Linux-Systemupgrades und Anwendungskontinuität.

**Nächste Schritte**: Möchtest du eine Anleitung zur Integration von Debian 13 mit weiteren HomeLab-Diensten, Erweiterung der Checkmk-Checks, oder eine andere Anpassung?

**Quellen**:
- Debian-Dokumentation: https://www.debian.org/releases/trixie
- Checkmk-Dokumentation: https://docs.checkmk.com
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen: https://wiki.debian.org/DebianUpgrade, https://www.debian.org/releases/trixie/releasenotes
```