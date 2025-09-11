```markdown
# Lernprojekt: Installation von OpenDocMan auf Debian 12

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
     - Host: `opendocman.homelab.local` → IP: `192.168.30.119`
   - Teste die DNS-Auflösung:
     ```bash
     nslookup opendocman.homelab.local 192.168.30.1
     ```
     - Erwartete Ausgabe: `192.168.30.119`.
3. **Ansible-Umgebung prüfen**:
   - Auf der Ubuntu-VM (`192.168.30.101`):
     ```bash
     ssh ubuntu@192.168.30.101
     ansible --version
     ```
   - Stelle sicher, dass SSH-Zugriff auf den OpenDocMan-Server möglich ist (nach Container-Erstellung):
     ```bash
     ssh root@192.168.30.119
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
     mkdir ~/opendocman-installation
     cd ~/opendocman-installation
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf OPNsense (`192.168.30.1`), TrueNAS (`192.168.30.100`) und den OpenDocMan-Server (`192.168.30.119`).

## Übung 1: Installation und Konfiguration von OpenDocMan

**Ziel**: Installiere OpenDocMan auf einem Debian 12 LXC-Container mit Apache, PHP, MySQL und einem NFS-Mount von TrueNAS.

**Aufgabe**: Erstelle einen LXC-Container, installiere OpenDocMan mit Ansible und konfiguriere die Datenbank sowie den Datenordner.

1. **LXC-Container für OpenDocMan erstellen**:
   - In Proxmox: `Create CT`:
     - Hostname: `opendocman`
     - Template: Debian 12-Standard
     - IP-Adresse: `192.168.30.119/24`
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
           opendocman_servers:
             hosts:
               opendocman:
                 ansible_host: 192.168.30.119
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

3. **Ansible-Playbook für OpenDocMan-Installation**:
   - Erstelle ein Playbook:
     ```bash
     nano install_opendocman.yml
     ```
     - Inhalt:
       ```yaml
       - name: Install OpenDocMan on Debian 12
         hosts: opendocman_servers
         become: yes
         vars:
           truenas_nfs_share: "192.168.30.100:/mnt/tank/opendocman"
           opendocman_data_dir: "/var/www/html/opendocman/data"
           mysql_root_password: "securepassword123"
           opendocman_db_name: "opendocman"
           opendocman_db_user: "opendocman_user"
           opendocman_db_password: "securepassword456"
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
                 - apache2
                 - php
                 - php-mysql
                 - php-gd
                 - php-mbstring
                 - mysql-server
                 - mysql-client
                 - nfs-common
                 - curl
           - name: Start and enable Apache
             ansible.builtin.service:
               name: apache2
               state: started
               enabled: yes
           - name: Start and enable MySQL
             ansible.builtin.service:
               name: mysql
               state: started
               enabled: yes
           - name: Secure MySQL installation
             ansible.builtin.command: >
               mysql_secure_installation --use-default
             environment:
               MYSQL_ROOT_PASSWORD: "{{ mysql_root_password }}"
             changed_when: false
           - name: Create MySQL database for OpenDocMan
             ansible.builtin.mysql_db:
               name: "{{ opendocman_db_name }}"
               state: present
               login_user: root
               login_password: "{{ mysql_root_password }}"
           - name: Create MySQL user for OpenDocMan
             ansible.builtin.mysql_user:
               name: "{{ opendocman_db_user }}"
               password: "{{ opendocman_db_password }}"
               priv: "{{ opendocman_db_name }}.*:ALL"
               state: present
               login_user: root
               login_password: "{{ mysql_root_password }}"
           - name: Download OpenDocMan
             ansible.builtin.get_url:
               url: https://github.com/opendocman/opendocman/archive/refs/tags/v1.4.4.tar.gz
               dest: /tmp/opendocman-1.4.4.tar.gz
               mode: '0644'
           - name: Extract OpenDocMan
             ansible.builtin.unarchive:
               src: /tmp/opendocman-1.4.4.tar.gz
               dest: /var/www/html
               remote_src: yes
               creates: /var/www/html/opendocman-1.4.4
           - name: Rename OpenDocMan directory
             ansible.builtin.command: >
               mv /var/www/html/opendocman-1.4.4 /var/www/html/opendocman
             args:
               creates: /var/www/html/opendocman
           - name: Set permissions for OpenDocMan
             ansible.builtin.file:
               path: /var/www/html/opendocman
               owner: www-data
               group: www-data
               mode: '0755'
               recurse: yes
           - name: Create OpenDocMan data directory
             ansible.builtin.file:
               path: "{{ opendocman_data_dir }}"
               state: directory
               owner: www-data
               group: www-data
               mode: '0755'
           - name: Mount TrueNAS NFS share
             ansible.builtin.mount:
               path: "{{ opendocman_data_dir }}"
               src: "{{ truenas_nfs_share }}"
               fstype: nfs
               state: mounted
           - name: Configure OpenDocMan
             ansible.builtin.copy:
               dest: /var/www/html/opendocman/config.php
               content: |
                 <?php
                 $GLOBALS['CONFIG']['db_hostname'] = 'localhost';
                 $GLOBALS['CONFIG']['db_name'] = '{{ opendocman_db_name }}';
                 $GLOBALS['CONFIG']['db_user'] = '{{ opendocman_db_user }}';
                 $GLOBALS['CONFIG']['db_pass'] = '{{ opendocman_db_password }}';
                 $GLOBALS['CONFIG']['dataDir'] = '{{ opendocman_data_dir }}/';
                 $GLOBALS['CONFIG']['base_url'] = 'http://opendocman.homelab.local/';
                 ?>
               mode: '0644'
               owner: www-data
               group: www-data
           - name: Test OpenDocMan
             ansible.builtin.uri:
               url: http://192.168.30.119/
               return_content: yes
             register: opendocman_test
             ignore_errors: yes
           - name: Display OpenDocMan test result
             ansible.builtin.debug:
               msg: "{{ opendocman_test.status }}"
       - name: Configure OPNsense firewall for OpenDocMan
         hosts: network_devices
         tasks:
           - name: Add firewall rule for OpenDocMan (80)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.119",
                 "destination_port":"80",
                 "description":"Allow OpenDocMan Access"
               }'
           - name: Verify firewall rules
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Display firewall rules
             ansible.builtin.debug:
               msg: "{{ rules_list.stdout }}"
       ```
   - **Erklärung**:
     - Installiert Apache, PHP, MySQL und benötigte PHP-Module.
     - Sichert MySQL und erstellt eine Datenbank und einen Benutzer für OpenDocMan.
     - Lädt OpenDocMan (Version 1.4.4) herunter, entpackt es nach `/var/www/html/opendocman` und setzt Berechtigungen.
     - Bindet den TrueNAS-Datenordner (`/mnt/tank/opendocman`) über NFS ein.
     - Konfiguriert `config.php` für OpenDocMan mit Datenbank- und Datenordner-Einstellungen.
     - Konfiguriert die OPNsense-Firewall für Zugriff auf OpenDocMan (Port 80).
     - Testet die OpenDocMan-Weboberfläche.
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml install_opendocman.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display OpenDocMan test result] ****************************************
       ok: [opendocman] => {
           "msg": 200
       }
       TASK [Display firewall rules] ************************************************
       ok: [opnsense] => {
           "msg": "... Allow OpenDocMan Access ..."
       }
       ```
   - Prüfe OpenDocMan:
     - Öffne `http://opendocman.homelab.local`.
     - Folge dem Installationsassistenten (falls erforderlich, siehe Hinweis unten).
     - Erstelle einen Admin-Benutzer (z. B. Benutzer: `admin`, Passwort: `securepassword789`).
     - Lade ein Testdokument hoch (z. B. PDF-Datei in `/mnt/tank/opendocman`).
     - Erwartete Ausgabe: OpenDocMan-Weboberfläche ist zugänglich, und Dokumente können hochgeladen/angezeigt werden.
     - **Hinweis**: Falls die Installation bei „Let’s Go“ hängen bleibt (siehe,), überprüfe die PHP-Version (erforderlich: PHP 7.4 oder niedriger) und Apache-Logs:[](https://github.com/opendocman/opendocman/issues/334)[](https://community.spiceworks.com/t/any-opendocman-experts-in-the-house/931225)
       ```bash
       ssh root@192.168.30.119 "cat /var/log/apache2/error.log"
       ```
       Falls nötig, installiere PHP 7.4:
       ```bash
       ssh root@192.168.30.119 "apt-get install -y php7.4 php7.4-mysql php7.4-gd php7.4-mbstring"
       ```

**Erkenntnis**: OpenDocMan kann auf Debian 12 mit Apache, PHP und MySQL installiert werden, wobei TrueNAS für Dokumentenspeicherung integriert wird. Ansible automatisiert den Prozess.

**Quelle**:,,, https://www.opendocman.com[](https://wiki.opendocman.com/getting_started_with_opendocman.html)[](https://github.com/opendocman/opendocman)[](https://www.opendocman.com/)

## Übung 2: Einrichtung eines benutzerdefinierten Checks in Checkmk

**Ziel**: Erstelle einen Checkmk-Check, um den OpenDocMan-Dienst und die Weboberfläche zu überwachen.

**Aufgabe**: Implementiere einen Check, der den Status des Apache-Dienstes und die Erreichbarkeit der OpenDocMan-Weboberfläche prüft.

1. **Ansible-Playbook für Checkmk-Check**:
   - Erstelle ein Playbook:
     ```bash
     nano opendocman_checkmk.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure Checkmk for OpenDocMan Monitoring
         hosts: checkmk_servers
         become: yes
         vars:
           checkmk_site: "homelab"
           checkmk_user: "cmkadmin"
           checkmk_password: "securepassword123"
           opendocman_host: "opendocman.homelab.local"
         tasks:
           - name: Install Checkmk agent on OpenDocMan server
             ansible.builtin.apt:
               name: check-mk-agent
               state: present
               update_cache: yes
             delegate_to: opendocman
           - name: Enable Checkmk agent service on OpenDocMan
             ansible.builtin.service:
               name: check-mk-agent
               state: started
               enabled: yes
             delegate_to: opendocman
           - name: Create OpenDocMan check script
             ansible.builtin.copy:
               dest: /omd/sites/{{ checkmk_site }}/local/share/check_mk/checks/opendocman_service
               content: |
                 #!/bin/bash
                 APACHE_STATUS=$(systemctl is-active apache2)
                 RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://192.168.30.119/)
                 if [ "$APACHE_STATUS" == "active" ] && [ "$RESPONSE" == "200" ]; then
                   echo "0 OpenDocMan_Service - OpenDocMan is running and web interface is accessible"
                 else
                   echo "2 OpenDocMan_Service - OpenDocMan is not running (Apache status: $APACHE_STATUS) or web interface is not accessible (HTTP: $RESPONSE)"
                 fi
               mode: '0755'
           - name: Add OpenDocMan host to Checkmk
             ansible.builtin.command: >
               cmk -v -U {{ checkmk_user }}:{{ checkmk_password }} {{ checkmk_site }} add-host {{ opendocman_host }} 192.168.30.119
             args:
               creates: /omd/sites/{{ checkmk_site }}/etc/check_mk/conf.d/wato/hosts.mk
           - name: Discover services for OpenDocMan
             ansible.builtin.command: >
               cmk -v -U {{ checkmk_user }}:{{ checkmk_password }} {{ checkmk_site }} discover-services {{ opendocman_host }}
           - name: Activate changes in Checkmk
             ansible.builtin.command: >
               cmk -v -U {{ checkmk_user }}:{{ checkmk_password }} {{ checkmk_site }} activate
           - name: Verify OpenDocMan services in Checkmk
             ansible.builtin.command: >
               cmk -v -U {{ checkmk_user }}:{{ checkmk_password }} {{ checkmk_site }} list-services {{ opendocman_host }}
             register: service_list
           - name: Display OpenDocMan services
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
                 "destination":"192.168.30.119",
                 "destination_port":"6556",
                 "description":"Allow Checkmk to OpenDocMan"
               }'
           - name: Verify firewall rules
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Display firewall rules
             ansible.builtin.debug:
               msg: "{{ rules_list.stdout }}"
       ```
   - **Erklärung**:
     - Installiert den Checkmk-Agenten auf dem OpenDocMan-Server.
     - Erstellt einen benutzerdefinierten Check (`opendocman_service`), der den Apache-Dienst und die Weboberfläche prüft.
     - Fügt OpenDocMan als Host in Checkmk hinzu und aktiviert den Check.
     - Konfiguriert die OPNsense-Firewall für den Checkmk-Agenten (Port 6556).
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml opendocman_checkmk.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display OpenDocMan services] *******************************************
       ok: [checkmk] => {
           "msg": "... OpenDocMan_Service ..."
       }
       TASK [Display firewall rules] ************************************************
       ok: [opnsense] => {
           "msg": "... Allow Checkmk to OpenDocMan ..."
       }
       ```
   - Prüfe in Checkmk:
     - Öffne `http://192.168.30.101:5000/homelab`.
     - Gehe zu `Monitor > All hosts > opendocman.homelab.local`.
     - Erwartete Ausgabe: `OpenDocMan_Service` zeigt Status `OK`.

**Erkenntnis**: Checkmk kann den OpenDocMan-Dienst effektiv überwachen, indem es den Apache-Dienst und die Weboberfläche prüft.

**Quelle**: https://docs.checkmk.com/latest/en/localchecks.html

## Übung 3: Backup der OpenDocMan-Konfiguration und Datenbank auf TrueNAS

**Ziel**: Sichere die OpenDocMan-Konfiguration und Datenbank auf TrueNAS.

**Aufgabe**: Erstelle ein Ansible-Playbook für Backups und begrenze sie auf maximal fünf Versionen.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_opendocman.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup OpenDocMan configuration and database
         hosts: opendocman_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/opendocman-installation/backups/opendocman"
           config_backup_file: "{{ backup_dir }}/opendocman-config-backup-{{ ansible_date_time.date }}.tar.gz"
           db_backup_file: "{{ backup_dir }}/opendocman-db-backup-{{ ansible_date_time.date }}.sql.gz"
           mysql_root_password: "securepassword123"
           opendocman_db_name: "opendocman"
         tasks:
           - name: Create backup directory
             ansible.builtin.file:
               path: "{{ backup_dir }}"
               state: directory
               mode: '0755'
             delegate_to: localhost
           - name: Stop Apache service
             ansible.builtin.service:
               name: apache2
               state: stopped
           - name: Backup OpenDocMan configuration
             ansible.builtin.command: >
               tar -czf /tmp/opendocman-config-backup-{{ ansible_date_time.date }}.tar.gz /var/www/html/opendocman
             register: config_backup_result
           - name: Start Apache service
             ansible.builtin.service:
               name: apache2
               state: started
           - name: Backup OpenDocMan database
             ansible.builtin.command: >
               mysqldump -u root -p{{ mysql_root_password }} {{ opendocman_db_name }} | gzip > /tmp/opendocman-db-backup-{{ ansible_date_time.date }}.sql.gz
             register: db_backup_result
           - name: Fetch configuration backup file
             ansible.builtin.fetch:
               src: /tmp/opendocman-config-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ config_backup_file }}"
               flat: yes
           - name: Fetch database backup file
             ansible.builtin.fetch:
               src: /tmp/opendocman-db-backup-{{ ansible_date_time.date }}.sql.gz
               dest: "{{ db_backup_file }}"
               flat: yes
           - name: Limit OpenDocMan configuration backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t opendocman-config-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Limit OpenDocMan database backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t opendocman-db-backup-*.sql.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync OpenDocMan backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/opendocman-installation/
             delegate_to: localhost
           - name: Display OpenDocMan backup status
             ansible.builtin.debug:
               msg: "OpenDocMan configuration backup saved to {{ config_backup_file }} and database backup to {{ db_backup_file }}; synced to TrueNAS"
       ```
   - **Erklärung**:
     - Sichert die OpenDocMan-Konfiguration (`/var/www/html/opendocman`) und die Datenbank (`opendocman`).
     - Stoppt Apache, um konsistente Backups zu gewährleisten.
     - Begrenzt Backups auf fünf Versionen pro Typ (Konfiguration und Datenbank).
     - Synchronisiert Backups mit TrueNAS.
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_opendocman.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display OpenDocMan backup status] **************************************
       ok: [opendocman] => {
           "msg": "OpenDocMan configuration backup saved to /home/ubuntu/opendocman-installation/backups/opendocman/opendocman-config-backup-<date>.tar.gz and database backup to /home/ubuntu/opendocman-installation/backups/opendocman/opendocman-db-backup-<date>.sql.gz; synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/opendocman-installation/
     ```
     - Erwartete Ausgabe: Maximal fünf Backups pro Typ (`opendocman-config-backup-<date>.tar.gz`, `opendocman-db-backup-<date>.sql.gz`).

2. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/opendocman-installation
       ansible-playbook -i inventory.yml backup_opendocman.yml >> backup.log 2>&1
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
       0 3 * * * /home/ubuntu/opendocman-installation/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible automatisiert die Sicherung der OpenDocMan-Konfiguration und Datenbank, während TrueNAS zuverlässige externe Speicherung bietet.

## Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass die Firewall-Regeln aus Übung 1 (Port 80 für OpenDocMan, Port 6556 für Checkmk-Agent) aktiv sind.
   - Prüfe OPNsense-Logs:
     ```bash
     ansible-playbook -i inventory.yml -m ansible.builtin.command -a "cat /var/log/system/latest.log" opnsense
     ```

2. **Erweiterung mit weiteren Checks**:
   - Erstelle einen Check für die Anzahl der Dokumente:
     ```bash
     nano /omd/sites/homelab/local/share/check_mk/checks/opendocman_documents
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       COUNT=$(find /var/www/html/opendocman/data -type f | wc -l)
       if [ $COUNT -gt 0 ]; then
         echo "0 OpenDocMan_Documents documents=$COUNT OpenDocMan contains $COUNT documents"
       else
         echo "2 OpenDocMan_Documents documents=$COUNT OpenDocMan data directory is empty"
       fi
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /omd/sites/homelab/local/share/check_mk/checks/opendocman_documents
       ```
     - In Checkmk: `Setup > Services > Manual checks > Custom checks`, füge `OpenDocMan_Documents` hinzu.

## Schritt 5: Erweiterung der Übungen
1. **Erweiterte OpenDocMan-Konfiguration**:
   - Erstelle ein Playbook für Benutzerverwaltung:
     ```bash
     nano configure_opendocman_users.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure OpenDocMan users
         hosts: opendocman_servers
         become: yes
         vars:
           mysql_root_password: "securepassword123"
           opendocman_db_name: "opendocman"
         tasks:
           - name: Add test user to OpenDocMan
             ansible.builtin.mysql_query:
               login_user: root
               login_password: "{{ mysql_root_password }}"
               db: "{{ opendocman_db_name }}"
               query: >
                 INSERT INTO user (username, password, first_name, last_name, email, department, admin)
                 VALUES ('testuser', MD5('testpassword123'), 'Test', 'User', 'testuser@homelab.local', 1, 0)
               single_transaction: yes
           - name: Verify user addition
             ansible.builtin.mysql_query:
               login_user: root
               login_password: "{{ mysql_root_password }}"
               db: "{{ opendocman_db_name }}"
               query: SELECT username FROM user WHERE username = 'testuser'
               register: user_result
           - name: Display user addition result
             ansible.builtin.debug:
               msg: "{{ user_result.query_result }}"
       ```

2. **Backup-Versionierung mit Git**:
   - Initialisiere ein Git-Repository für Backups:
     ```bash
     cd ~/opendocman-installation/backups
     git init
     git add .
     git commit -m "Initial OpenDocMan backups"
     ```

## Best Practices für Schüler

- **OpenDocMan-Design**:
  - Organisiere Dokumente auf TrueNAS (`/mnt/tank/opendocman`) mit klaren Verzeichnisstrukturen.
  - Teste die OpenDocMan-Weboberfläche (`http://opendocman.homelab.local`) und lade Testdokumente hoch.
- **Sicherheit**:
  - Schränke OpenDocMan-Zugriff ein:
    ```bash
    ssh root@192.168.30.119 "ufw allow from 192.168.30.0/24 to any port 80 proto tcp"
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
  - Verwende HTTPS für OpenDocMan bei externem Zugriff:
    ```bash
    ssh root@192.168.30.119 "turnkey-letsencrypt opendocman.homelab.local"
    ```
  - Sichere MySQL-Zugangsdaten:
    ```bash
    ssh root@192.168.30.119 "chmod 600 /var/www/html/opendocman/config.php"
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
  - Teste Backups vor Updates (siehe https://www.opendocman.com).
- **Fehlerbehebung**:
  - Prüfe Apache-Logs:
    ```bash
    ssh root@192.168.30.119 "cat /var/log/apache2/error.log"
    ```
  - Prüfe MySQL-Logs:
    ```bash
    ssh root@192.168.30.119 "cat /var/log/mysql/error.log"
    ```
  - Prüfe Checkmk-Logs:
    ```bash
    cat /omd/sites/homelab/var/log/web.log
    ```
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/opendocman-installation/backup.log
    ```
  - Falls die Installation bei „Let’s Go“ hängen bleibt (siehe,), überprüfe PHP-Module und `open_basedir`-Einstellungen:[](https://github.com/opendocman/opendocman/issues/334)[](https://community.spiceworks.com/t/any-opendocman-experts-in-the-house/931225)
    ```bash
    ssh root@192.168.30.119 "php -m"
    ssh root@192.168.30.119 "cat /etc/php/*/apache2/php.ini | grep open_basedir"
    ```

**Quellen**:,,, https://www.opendocman.com, https://docs.checkmk.com, https://docs.ansible.com, https://docs.opnsense.org/manual[](https://wiki.opendocman.com/getting_started_with_opendocman.html)[](https://github.com/opendocman/opendocman)[](https://www.opendocman.com/)

## Empfehlungen für Schüler

- **Setup**: OpenDocMan, TrueNAS-Datenspeicher, Checkmk-Monitoring, TrueNAS-Backups.
- **Workloads**: Dokumentenmanagement, Überwachung, Backups.
- **Integration**: Proxmox (LXC), TrueNAS (NFS), OPNsense (DNS, Netzwerk).
- **Beispiel**: Dokumentenmanagementsystem mit Überwachung im HomeLab.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einer kleinen Dokumentenbibliothek, erweitere nach Bedarf.
- **Übung**: Teste das Hochladen und Abrufen von Dokumenten in OpenDocMan.
- **Fehlerbehebung**: Nutze Apache-, MySQL- und Checkmk-Logs für Debugging.
- **Lernressourcen**: https://www.opendocman.com, https://docs.checkmk.com, https://docs.ansible.com.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Schnelle Installation von OpenDocMan mit TrueNAS-Integration.
- **Skalierbarkeit**: Automatisierte Überwachung und Backup-Prozesse.
- **Lernwert**: Verständnis von Dokumentenmanagement und Monitoring in einer HomeLab-Umgebung.

**Nächste Schritte**: Möchtest du eine Anleitung zur Integration von OpenDocMan mit Home Assistant, Erweiterung der Checkmk-Checks, oder eine andere Anpassung?

**Quellen**:
- OpenDocMan-Dokumentation: https://www.opendocman.com
- Checkmk-Dokumentation: https://docs.checkmk.com
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,,,[](https://wiki.opendocman.com/getting_started_with_opendocman.html)[](https://www.opendocman.com/enterprise-document-management-system-installation/)[](https://github.com/opendocman/opendocman)
```