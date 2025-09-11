# Lernprojekt: Monitoring eines MQTT-Systems mit Mosquitto, Node-RED, InfluxDB, Grafana und MQTT Explorer

## Vorbereitung: Umgebung prüfen
1. **Proxmox VE prüfen**:
   - Melde dich an der Proxmox-Weboberfläche an: `https://192.168.30.2:8006`.
   - Stelle sicher, dass LXC-Unterstützung aktiviert ist:
     ```bash
     pveam update
     pveam list
     ```
2. **DNS in OPNsense prüfen**:
   - Öffne die OPNsense-Weboberfläche: `http://192.168.30.1`.
   - Gehe zu `Services > Unbound DNS > Overrides > Host`.
   - Überprüfe Einträge:
     - `mosquitto.homelab.local` → `192.168.30.113`
     - `nodered.homelab.local` → `192.168.30.114`
     - `influxdb.homelab.local` → `192.168.30.115`
     - `grafana.homelab.local` → `192.168.30.116`
   - Teste die DNS-Auflösung:
     ```bash
     nslookup mosquitto.homelab.local 192.168.30.1
     nslookup nodered.homelab.local 192.168.30.1
     nslookup influxdb.homelab.local 192.168.30.1
     nslookup grafana.homelab.local 192.168.30.1
     ```
     - Erwartete Ausgabe: `192.168.30.113`, `192.168.30.114`, `192.168.30.115`, `192.168.30.116`.
3. **Ansible-Umgebung prüfen**:
   - Auf der Ubuntu-VM (`192.168.30.101`):
     ```bash
     ssh ubuntu@192.168.30.101
     ansible --version
     ```
4. **Projektverzeichnis erstellen**:
   - Auf `192.168.30.101`:
     ```bash
     mkdir ~/mqtt-monitoring
     cd ~/mqtt-monitoring
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Proxmox (`192.168.30.2`), OPNsense (`192.168.30.1`) und TrueNAS (`192.168.30.100`).

## Übung 1: Einrichten der MQTT-Umgebung

**Ziel**: Installiere und konfiguriere Mosquitto, Node-RED, InfluxDB und Grafana als LXC-Container auf Proxmox.

**Aufgabe**: Erstelle LXC-Container für alle Komponenten und konfiguriere sie mit Ansible.

1. **Ansible-Inventar erstellen**:
   - Erstelle eine Inventar-Datei:
     ```bash
     nano inventory.yml
     ```
     - Inhalt:
       ```yaml
       all:
         children:
           mqtt_servers:
             hosts:
               mosquitto:
                 ansible_host: 192.168.30.113
                 ansible_user: root
                 ansible_connection: ssh
                 ansible_python_interpreter: /usr/bin/python3
           nodered_servers:
             hosts:
               nodered:
                 ansible_host: 192.168.30.114
                 ansible_user: root
                 ansible_connection: ssh
                 ansible_python_interpreter: /usr/bin/python3
           influxdb_servers:
             hosts:
               influxdb:
                 ansible_host: 192.168.30.115
                 ansible_user: root
                 ansible_connection: ssh
                 ansible_python_interpreter: /usr/bin/python3
           grafana_servers:
             hosts:
               grafana:
                 ansible_host: 192.168.30.116
                 ansible_user: root
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

2. **LXC-Container in Proxmox erstellen**:
   - In der Proxmox-Weboberfläche (`https://192.168.30.2:8006`):
     - Erstelle vier LXC-Container mit der Debian 11-Vorlage:
       - **Mosquitto**: Hostname `mosquitto`, IP `192.168.30.113/24`, Gateway/DNS `192.168.30.1`, 1 CPU, 1 GB RAM, 10 GB Disk.
       - **Node-RED**: Hostname `nodered`, IP `192.168.30.114/24`, Gateway/DNS `192.168.30.1`, 2 CPUs, 2 GB RAM, 20 GB Disk.
       - **InfluxDB**: Hostname `influxdb`, IP `192.168.30.115/24`, Gateway/DNS `192.168.30.1`, 2 CPUs, 2 GB RAM, 20 GB Disk.
       - **Grafana**: Hostname `grafana`, IP `192.168.30.116/24`, Gateway/DNS `192.168.30.1`, 2 CPUs, 2 GB RAM, 20 GB Disk.
     - Starte alle Container.

3. **Ansible-Playbook für die Installation**:
   - Erstelle ein Playbook:
     ```bash
     nano setup_mqtt_monitoring.yml
     ```
     - Inhalt:
       ```yaml
       - name: Install Mosquitto MQTT Broker
         hosts: mqtt_servers
         become: yes
         tasks:
           - name: Install Mosquitto
             ansible.builtin.apt:
               name: mosquitto
               state: present
               update_cache: yes
           - name: Enable Mosquitto service
             ansible.builtin.service:
               name: mosquitto
               state: started
               enabled: yes
           - name: Configure Mosquitto to allow anonymous access
             ansible.builtin.lineinfile:
               path: /etc/mosquitto/mosquitto.conf
               line: "allow_anonymous true"
               insertafter: EOF
           - name: Restart Mosquitto
             ansible.builtin.service:
               name: mosquitto
               state: restarted
       - name: Install Node-RED
         hosts: nodered_servers
         become: yes
         tasks:
           - name: Install Node-RED
             ansible.builtin.shell: bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/setup.sh)
             args:
               creates: /usr/bin/node-red
           - name: Enable Node-RED service
             ansible.builtin.service:
               name: nodered
               state: started
               enabled: yes
           - name: Install node-red-contrib-influxdb
             ansible.builtin.command: npm install -g node-red-contrib-influxdb
             args:
               creates: /usr/lib/node_modules/node-red-contrib-influxdb
       - name: Install InfluxDB
         hosts: influxdb_servers
         become: yes
         vars:
           influxdb_admin_user: "admin"
           influxdb_admin_password: "securepassword123"
           influxdb_database: "sensors"
         tasks:
           - name: Add InfluxDB repository key
             ansible.builtin.apt_key:
               url: https://repos.influxdata.com/influxdata-archive_compat.key
               state: present
           - name: Add InfluxDB repository
             ansible.builtin.apt_repository:
               repo: deb https://repos.influxdata.com/debian bullseye stable
               state: present
           - name: Install InfluxDB
             ansible.builtin.apt:
               name: influxdb
               state: present
               update_cache: yes
           - name: Enable InfluxDB service
             ansible.builtin.service:
               name: influxdb
               state: started
               enabled: yes
           - name: Create InfluxDB admin user
             ansible.builtin.command: influx -execute "CREATE USER {{ influxdb_admin_user }} WITH PASSWORD '{{ influxdb_admin_password }}' WITH ALL PRIVILEGES"
             args:
               creates: /var/lib/influxdb/.influxdb_initialized
           - name: Create InfluxDB database
             ansible.builtin.command: influx -execute "CREATE DATABASE {{ influxdb_database }}"
             args:
               creates: /var/lib/influxdb/.sensors_created
       - name: Install Grafana
         hosts: grafana_servers
         become: yes
         vars:
           grafana_admin_user: "admin"
           grafana_admin_password: "securepassword123"
         tasks:
           - name: Add Grafana repository key
             ansible.builtin.apt_key:
               url: https://packages.grafana.com/gpg.key
               state: present
           - name: Add Grafana repository
             ansible.builtin.apt_repository:
               repo: deb https://packages.grafana.com/oss/deb stable main
               state: present
           - name: Install Grafana
             ansible.builtin.apt:
               name: grafana
               state: present
               update_cache: yes
           - name: Enable Grafana service
             ansible.builtin.service:
               name: grafana-server
               state: started
               enabled: yes
           - name: Set Grafana admin password
             ansible.builtin.command: grafana-cli admin reset-admin-password {{ grafana_admin_password }}
             args:
               creates: /var/lib/grafana/.password_reset
       - name: Configure OPNsense firewall
         hosts: network_devices
         tasks:
           - name: Add firewall rule for Mosquitto (1883)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.113",
                 "destination_port":"1883",
                 "description":"Allow MQTT to Mosquitto"
               }'
           - name: Add firewall rule for Node-RED (1880)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.114",
                 "destination_port":"1880",
                 "description":"Allow Node-RED"
               }'
           - name: Add firewall rule for InfluxDB (8086)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.114",
                 "destination":"192.168.30.115",
                 "destination_port":"8086",
                 "description":"Allow Node-RED to InfluxDB"
               }'
           - name: Add firewall rule for Grafana (3000)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.116",
                 "destination_port":"3000",
                 "description":"Allow Grafana"
               }'
           - name: Restart Unbound service
             ansible.builtin.command: configctl unbound restart
           - name: Verify firewall rules
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Display firewall rules
             ansible.builtin.debug:
               msg: "{{ rules_list.stdout }}"
       ```
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml setup_mqtt_monitoring.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display firewall rules] ***************************************************
       ok: [opnsense] => {
           "msg": "... Allow MQTT to Mosquitto ... Allow Node-RED ... Allow Node-RED to InfluxDB ... Allow Grafana ..."
       }
       ```
   - Prüfe die Dienste:
     - Mosquitto: `ssh root@192.168.30.113 systemctl status mosquitto`
     - Node-RED: `curl http://nodered.homelab.local:1880`
     - InfluxDB: `curl http://influxdb.homelab.local:8086/ping`
     - Grafana: `curl http://grafana.homelab.local:3000`

**Erkenntnis**: Ansible automatisiert die Installation von Mosquitto, Node-RED, InfluxDB und Grafana, während OPNsense die Netzwerksicherheit gewährleistet.,[](https://github.com/aktnk/mqtt-node_red-influxdb-grafana)[](https://gist.github.com/Paraphraser/c9db25d131dd4c09848ffb353b69038f)

## Übung 2: Erstellung eines Node-RED-Flows für MQTT-Datenverarbeitung

**Ziel**: Erstelle einen Node-RED-Flow, um MQTT-Daten zu empfangen, in InfluxDB zu speichern und in Grafana zu visualisieren.

**Aufgabe**: Konfiguriere Node-RED, um MQTT-Daten (z. B. Temperatur, Luftfeuchtigkeit) zu verarbeiten, und richte Grafana für die Visualisierung ein.

1. **Node-RED-Flow erstellen**:
   - Öffne die Node-RED-Weboberfläche: `http://nodered.homelab.local:1880`.
   - Erstelle einen neuen Flow:
     - Füge einen **MQTT In** Node hinzu:
       - Server: `mosquitto.homelab.local:1883`
       - Topic: `sensors/#`
       - Name: `MQTT Sensor Input`
     - Füge einen **Function** Node hinzu (um JSON-Daten zu parsen):
       - Name: `Parse Sensor Data`
       - Code:
         ```javascript
         if (msg.topic.includes("temperature")) {
             msg.payload = {
                 measurement: "temperature",
                 fields: { value: parseFloat(msg.payload) },
                 tags: { sensor: msg.topic.split("/")[1] }
             };
         } else if (msg.topic.includes("humidity")) {
             msg.payload = {
                 measurement: "humidity",
                 fields: { value: parseFloat(msg.payload) },
                 tags: { sensor: msg.topic.split("/")[1] }
             };
         }
         return msg;
         ```
     - Füge einen **InfluxDB Out** Node hinzu:
       - Server: `influxdb.homelab.local:8086`
       - Database: `sensors`
       - Name: `Store in InfluxDB`
     - Verbinde die Nodes: `MQTT In` → `Function` → `InfluxDB Out`.
   - Deploy den Flow.

2. **Testdaten senden**:
   - Auf der Ubuntu-VM:
     ```bash
     mosquitto_pub -h mosquitto.homelab.local -t sensors/sensor1/temperature -m "23.5"
     mosquitto_pub -h mosquitto.homelab.local -t sensors/sensor1/humidity -m "60"
     ```
   - Prüfe in Node-RED (Debug-Tab), ob die Daten empfangen werden.

3. **Grafana konfigurieren**:
   - Öffne die Grafana-Weboberfläche: `http://grafana.homelab.local:3000`.
   - Melde dich an (Benutzer: `admin`, Passwort: `securepassword123`).
   - Füge eine InfluxDB-Datenquelle hinzu:
     - URL: `http://influxdb.homelab.local:8086`
     - Database: `sensors`
     - Benutzer: `admin`, Passwort: `securepassword123`
   - Erstelle ein Dashboard:
     - Füge ein Panel hinzu (z. B. Zeitreihen-Diagramm).
     - Query: `SELECT mean("value") FROM "temperature" WHERE time >= now() - 1h GROUP BY time(10s), "sensor"`
     - Visualisierung: Zeitreihen, Titel: `Sensor Temperature`.
   - Speichere das Dashboard.

4. **Ansible-Playbook für Node-RED-Flow**:
   - Erstelle ein Playbook, um den Flow zu exportieren:
     ```bash
     nano export_nodered_flow.yml
     ```
     - Inhalt:
       ```yaml
       - name: Export Node-RED Flow
         hosts: nodered_servers
         become: yes
         tasks:
           - name: Export Node-RED flows
             ansible.builtin.command: node-red-admin flows get > /root/flows.json
             args:
               creates: /root/flows.json
           - name: Fetch Node-RED flows
             ansible.builtin.fetch:
               src: /root/flows.json
               dest: /home/ubuntu/mqtt-monitoring/flows.json
               flat: yes
       ```
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml export_nodered_flow.yml
     ```

**Erkenntnis**: Node-RED ermöglicht die einfache Verarbeitung von MQTT-Daten und deren Speicherung in InfluxDB, während Grafana flexible Visualisierungen bietet.,,[](https://github.com/aktnk/mqtt-node_red-influxdb-grafana)[](https://discourse.nodered.org/t/parse-and-plot-mqtt-data-on-a-chart/29457)[](https://gist.github.com/Paraphraser/c9db25d131dd4c09848ffb353b69038f)

## Übung 3: Backup der Systemkonfigurationen auf TrueNAS

**Ziel**: Sichere die Konfigurationen von Mosquitto, Node-RED, InfluxDB und Grafana auf TrueNAS.

**Aufgabe**: Erstelle ein Ansible-Playbook für Backups und begrenze sie auf maximal fünf Versionen.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_mqtt_monitoring.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup Mosquitto configuration
         hosts: mqtt_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/mqtt-monitoring/backups/mosquitto"
           backup_file: "{{ backup_dir }}/mosquitto-backup-{{ ansible_date_time.date }}.tar.gz"
         tasks:
           - name: Create backup directory
             ansible.builtin.file:
               path: "{{ backup_dir }}"
               state: directory
               mode: '0755'
             delegate_to: localhost
           - name: Stop Mosquitto service
             ansible.builtin.service:
               name: mosquitto
               state: stopped
           - name: Backup Mosquitto configuration
             ansible.builtin.command: >
               tar -czf /tmp/mosquitto-backup-{{ ansible_date_time.date }}.tar.gz /etc/mosquitto
             register: backup_result
           - name: Start Mosquitto service
             ansible.builtin.service:
               name: mosquitto
               state: started
           - name: Fetch backup file
             ansible.builtin.fetch:
               src: /tmp/mosquitto-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ backup_file }}"
               flat: yes
           - name: Limit Mosquitto backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t mosquitto-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync Mosquitto backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/mqtt-monitoring/
             delegate_to: localhost
           - name: Display Mosquitto backup status
             ansible.builtin.debug:
               msg: "Mosquitto backup saved to {{ backup_file }} and synced to TrueNAS"
       - name: Backup Node-RED configuration
         hosts: nodered_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/mqtt-monitoring/backups/nodered"
           backup_file: "{{ backup_dir }}/nodered-backup-{{ ansible_date_time.date }}.tar.gz"
         tasks:
           - name: Create backup directory
             ansible.builtin.file:
               path: "{{ backup_dir }}"
               state: directory
               mode: '0755'
             delegate_to: localhost
           - name: Stop Node-RED service
             ansible.builtin.service:
               name: nodered
               state: stopped
           - name: Backup Node-RED configuration
             ansible.builtin.command: >
               tar -czf /tmp/nodered-backup-{{ ansible_date_time.date }}.tar.gz /root/.node-red
             register: backup_result
           - name: Start Node-RED service
             ansible.builtin.service:
               name: nodered
               state: started
           - name: Fetch backup file
             ansible.builtin.fetch:
               src: /tmp/nodered-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ backup_file }}"
               flat: yes
           - name: Limit Node-RED backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t nodered-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync Node-RED backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/mqtt-monitoring/
             delegate_to: localhost
           - name: Display Node-RED backup status
             ansible.builtin.debug:
               msg: "Node-RED backup saved to {{ backup_file }} and synced to TrueNAS"
       - name: Backup InfluxDB configuration and data
         hosts: influxdb_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/mqtt-monitoring/backups/influxdb"
           backup_file: "{{ backup_dir }}/influxdb-backup-{{ ansible_date_time.date }}.tar.gz"
         tasks:
           - name: Create backup directory
             ansible.builtin.file:
               path: "{{ backup_dir }}"
               state: directory
               mode: '0755'
             delegate_to: localhost
           - name: Stop InfluxDB service
             ansible.builtin.service:
               name: influxdb
               state: stopped
           - name: Backup InfluxDB configuration and data
             ansible.builtin.command: >
               tar -czf /tmp/influxdb-backup-{{ ansible_date_time.date }}.tar.gz /var/lib/influxdb
             register: backup_result
           - name: Start InfluxDB service
             ansible.builtin.service:
               name: influxdb
               state: started
           - name: Fetch backup file
             ansible.builtin.fetch:
               src: /tmp/influxdb-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ backup_file }}"
               flat: yes
           - name: Limit InfluxDB backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t influxdb-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync InfluxDB backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/mqtt-monitoring/
             delegate_to: localhost
           - name: Display InfluxDB backup status
             ansible.builtin.debug:
               msg: "InfluxDB backup saved to {{ backup_file }} and synced to TrueNAS"
       - name: Backup Grafana configuration
         hosts: grafana_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/mqtt-monitoring/backups/grafana"
           backup_file: "{{ backup_dir }}/grafana-backup-{{ ansible_date_time.date }}.tar.gz"
         tasks:
           - name: Create backup directory
             ansible.builtin.file:
               path: "{{ backup_dir }}"
               state: directory
               mode: '0755'
             delegate_to: localhost
           - name: Stop Grafana service
             ansible.builtin.service:
               name: grafana-server
               state: stopped
           - name: Backup Grafana configuration
             ansible.builtin.command: >
               tar -czf /tmp/grafana-backup-{{ ansible_date_time.date }}.tar.gz /var/lib/grafana
             register: backup_result
           - name: Start Grafana service
             ansible.builtin.service:
               name: grafana-server
               state: started
           - name: Fetch backup file
             ansible.builtin.fetch:
               src: /tmp/grafana-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ backup_file }}"
               flat: yes
           - name: Limit Grafana backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t grafana-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync Grafana backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/mqtt-monitoring/
             delegate_to: localhost
           - name: Display Grafana backup status
             ansible.builtin.debug:
               msg: "Grafana backup saved to {{ backup_file }} and synced to TrueNAS"
       ```
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_mqtt_monitoring.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display Mosquitto backup status] ******************************************
       ok: [mosquitto] => {
           "msg": "Mosquitto backup saved to /home/ubuntu/mqtt-monitoring/backups/mosquitto/mosquitto-backup-<date>.tar.gz and synced to TrueNAS"
       }
       TASK [Display Node-RED backup status] *******************************************
       ok: [nodered] => {
           "msg": "Node-RED backup saved to /home/ubuntu/mqtt-monitoring/backups/nodered/nodered-backup-<date>.tar.gz and synced to TrueNAS"
       }
       TASK [Display InfluxDB backup status] *******************************************
       ok: [influxdb] => {
           "msg": "InfluxDB backup saved to /home/ubuntu/mqtt-monitoring/backups/influxdb/influxdb-backup-<date>.tar.gz and synced to TrueNAS"
       }
       TASK [Display Grafana backup status] ********************************************
       ok: [grafana] => {
           "msg": "Grafana backup saved to /home/ubuntu/mqtt-monitoring/backups/grafana/grafana-backup-<date>.tar.gz and synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/mqtt-monitoring/
     ```
     - Erwartete Ausgabe: Maximal fünf Backups pro Dienst (`mosquitto-backup-<date>.tar.gz`, `nodered-backup-<date>.tar.gz`, etc.).

2. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/mqtt-monitoring
       ansible-playbook -i inventory.yml backup_mqtt_monitoring.yml >> backup.log 2>&1
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
       0 3 * * * /home/ubuntu/mqtt-monitoring/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible automatisiert die Sicherung der MQTT-Systemkomponenten, während TrueNAS zuverlässige externe Speicherung bietet.

## Empfehlung: MQTT Explorer

**Ziel**: Verwende MQTT Explorer, um Einblicke in die MQTT-Topic-Struktur zu erhalten.

**Aufgabe**: Installiere MQTT Explorer auf einem lokalen Rechner und analysiere die MQTT-Daten.

1. **MQTT Explorer installieren**:
   - Lade MQTT Explorer von https://mqtt-explorer.com herunter (verfügbar für Windows, macOS, Linux).
   - Installiere es auf deinem lokalen Rechner (z. B. Ubuntu-Desktop):
     ```bash
     sudo snap install mqtt-explorer
     ```
2. **MQTT Explorer konfigurieren**:
   - Starte MQTT Explorer.
   - Füge eine Verbindung hinzu:
     - Host: `mosquitto.homelab.local`
     - Port: `1883`
     - Name: `HomeLab MQTT`
   - Verbinde dich und inspiziere die Topics (z. B. `sensors/#`).
   - Sende Testdaten:
     - Publish auf `sensors/sensor1/temperature` mit Wert `24.0`.
     - Publish auf `sensors/sensor1/humidity` mit Wert `65`.
   - Überprüfe, ob die Daten in Node-RED, InfluxDB und Grafana ankommen.

**Erkenntnis**: MQTT Explorer ist ein nützliches Tool, um die MQTT-Topic-Struktur zu visualisieren und Debugging zu erleichtern.[](https://discourse.nodered.org/t/mqtt-as-a-debugging-aid/94344)

## Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass die Firewall-Regeln aktiv sind (siehe Übung 1).
   - Prüfe OPNsense-Logs:
     ```bash
     ansible-playbook -i inventory.yml -m ansible.builtin.command -a "cat /var/log/system/latest.log" opnsense
     ```

2. **Monitoring mit Checkmk (optional)**:
   - Konfiguriere Checkmk für das MQTT-System:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Füge Hosts hinzu: `mosquitto`, `nodered`, `influxdb`, `grafana`.
     - Erstelle eine benutzerdefinierte Überprüfung für MQTT:
       ```bash
       nano /omd/sites/homelab/local/share/check_mk/checks/mqtt_monitoring
       ```
       - Inhalt:
         ```bash
         #!/bin/bash
         mosquitto_sub -h mosquitto.homelab.local -t sensors/test -C 1 -W 5 > /dev/null
         if [ $? -eq 0 ]; then
           echo "0 MQTT_Monitoring - MQTT broker is operational"
         else
           echo "2 MQTT_Monitoring - MQTT broker is not operational"
         fi
         ```
       - Ausführbar machen:
         ```bash
         chmod +x /omd/sites/homelab/local/share/check_mk/checks/mqtt_monitoring
         ```
       - In Checkmk: `Setup > Services > Manual checks > Custom checks`, füge `MQTT_Monitoring` hinzu.

## Schritt 5: Erweiterung der Übungen
1. **Erweiterte Node-RED-Flows**:
   - Erstelle ein Playbook, um Node-RED-Flows zu importieren:
     ```bash
     nano import_nodered_flow.yml
     ```
     - Inhalt:
       ```yaml
       - name: Import Node-RED Flow
         hosts: nodered_servers
         become: yes
         tasks:
           - name: Copy Node-RED flow
             ansible.builtin.copy:
               src: /home/ubuntu/mqtt-monitoring/flows.json
               dest: /root/flows.json
           - name: Import Node-RED flow
             ansible.builtin.command: node-red-admin flows set /root/flows.json
       ```

2. **Backup-Versionierung mit Git**:
   - Initialisiere ein Git-Repository für Backups:
     ```bash
     cd ~/mqtt-monitoring/backups
     git init
     git add .
     git commit -m "Initial MQTT monitoring backups"
     ```

## Best Practices für Schüler

- **MQTT-Design**:
  - Nutze hierarchische Topics (z. B. `sensors/<sensor_id>/temperature`).
  - Verwende `mosquitto_pub` und MQTT Explorer für Tests.[](https://discourse.nodered.org/t/mqtt-as-a-debugging-aid/94344)
- **Sicherheit**:
  - Schränke MQTT-Zugriff ein:
    ```bash
    ssh root@192.168.30.113 "ufw allow from 192.168.30.0/24 to any port 1883"
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
  - Verwende MQTT über TLS (Port 8883) für Produktionsumgebungen:
    ```bash
    ssh root@192.168.30.113 "mosquitto -c /etc/mosquitto/conf.d/tls.conf"
    ```
    - Erstelle ein TLS-Zertifikat mit `turnkey-letsencrypt`.
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
  - Teste Backups vor Updates (siehe https://mosquitto.org, https://nodered.org/docs).
- **Fehlerbehebung**:
  - Prüfe Mosquitto-Logs:
    ```bash
    ssh root@192.168.30.113 "cat /var/log/mosquitto/mosquitto.log"
    ```
  - Prüfe Node-RED-Logs:
    ```bash
    ssh root@192.168.30.114 "cat /root/.node-red/.log"
    ```
  - Prüfe InfluxDB-Logs:
    ```bash
    ssh root@192.168.30.115 "cat /var/log/influxdb/influxd.log"
    ```
  - Prüfe Grafana-Logs:
    ```bash
    ssh root@192.168.30.116 "cat /var/log/grafana/grafana.log"
    ```

**Quellen**: https://mosquitto.org, https://nodered.org/docs, https://docs.influxdata.com, https://grafana.com/docs, https://mqtt-explorer.com,,,[](https://github.com/aktnk/mqtt-node_red-influxdb-grafana)[](https://gist.github.com/Paraphraser/c9db25d131dd4c09848ffb353b69038f)[](https://discourse.nodered.org/t/mqtt-as-a-debugging-aid/94344)

## Empfehlungen für Schüler

- **Setup**: Mosquitto, Node-RED, InfluxDB, Grafana, MQTT Explorer.
- **Workloads**: MQTT-Datenverarbeitung, Zeitreihen-Speicherung, Visualisierung.
- **Integration**: Proxmox (LXC), TrueNAS (Backups), OPNsense (DNS, Netzwerk).
- **Beispiel**: Überwachung von Sensordaten im HomeLab.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einem einfachen Topic (z. B. `sensors/test`).
- **Übung**: Teste mit MQTT Explorer und füge weitere Sensoren hinzu.
- **Fehlerbehebung**: Nutze MQTT Explorer und Node-RED-Debug-Nodes.
- **Lernressourcen**: https://mosquitto.org, https://nodered.org/docs, https://docs.influxdata.com, https://grafana.com/docs, https://mqtt-explorer.com.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Schnelle Einrichtung eines MQTT-Monitoring-Systems.
- **Skalierbarkeit**: Automatisierte Installation, Datenverarbeitung und Backups.
- **Lernwert**: Verständnis von MQTT, Zeitreihen-Datenbanken und Visualisierung.

**Nächste Schritte**: Möchtest du eine Anleitung zur Integration des MQTT-Systems mit OpenLDAP für Authentifizierung, Erweiterung des Node-RED-Flows, oder Monitoring mit Wazuh/Fluentd/Checkmk?

**Quellen**:
- Mosquitto-Dokumentation: https://mosquitto.org
- Node-RED-Dokumentation: https://nodered.org/docs
- InfluxDB-Dokumentation: https://docs.influxdata.com
- Grafana-Dokumentation: https://grafana.com/docs
- MQTT Explorer: https://mqtt-explorer.com
- Webquellen:,,,,,[](https://github.com/aktnk/mqtt-node_red-influxdb-grafana)[](https://docs.arduino.cc/tutorials/portenta-x8/datalogging-iot/)[](http://www.steves-internet-guide.com/monitoring-mqtt-brokers/)
```