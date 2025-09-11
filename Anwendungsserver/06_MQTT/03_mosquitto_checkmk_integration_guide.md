# Lernprojekt: Integration von Mosquitto als MQTT-Broker mit Checkmk-Monitoring

## Vorbereitung: Umgebung prüfen
1. **Proxmox VE prüfen**:
   - Melde dich an der Proxmox-Weboberfläche an: `https://192.168.30.2:8006`.
   - Stelle sicher, dass die LXC-Container für Mosquitto (`192.168.30.113`), Node-RED (`192.168.30.114`), InfluxDB (`192.168.30.115`) und Grafana (`192.168.30.116`) laufen:
     ```bash
     pct list
     ```
     - Erwartete Ausgabe: Container `mosquitto`, `nodered`, `influxdb`, `grafana` mit Status `running`.
2. **DNS in OPNsense prüfen**:
   - Öffne die OPNsense-Weboberfläche: `http://192.168.30.1`.
   - Gehe zu `Services > Unbound DNS > Overrides > Host`.
   - Überprüfe Einträge:
     - `mosquitto.homelab.local` → `192.168.30.113`
     - `checkmk.homelab.local` → `192.168.30.101`
   - Teste die DNS-Auflösung:
     ```bash
     nslookup mosquitto.homelab.local 192.168.30.1
     nslookup checkmk.homelab.local 192.168.30.1
     ```
     - Erwartete Ausgabe: `192.168.30.113`, `192.168.30.101`.
3. **Ansible-Umgebung prüfen**:
   - Auf der Ubuntu-VM (`192.168.30.101`):
     ```bash
     ssh ubuntu@192.168.30.101
     ansible --version
     ```
   - Stelle sicher, dass SSH-Zugriff auf Mosquitto-Server möglich ist:
     ```bash
     ssh root@192.168.30.113
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
     mkdir ~/mosquitto-checkmk-integration
     cd ~/mosquitto-checkmk-integration
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Mosquitto (`192.168.30.113`), OPNsense (`192.168.30.1`) und TrueNAS (`192.168.30.100`).

## Übung 1: Konfiguration von Checkmk für die Überwachung von Mosquitto

**Ziel**: Konfiguriere Checkmk, um den Mosquitto-Broker und seine grundlegenden Dienste zu überwachen.

**Aufgabe**: Füge Mosquitto als Host in Checkmk hinzu und aktiviere grundlegende Überwachungen (z. B. CPU, Speicher, Dienststatus).

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

2. **Ansible-Playbook für Checkmk-Konfiguration**:
   - Erstelle ein Playbook:
     ```bash
     nano configure_checkmk_mosquitto.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure Checkmk for Mosquitto Monitoring
         hosts: checkmk_servers
         become: yes
         vars:
           checkmk_site: "homelab"
           checkmk_user: "cmkadmin"
           checkmk_password: "securepassword123"
           mosquitto_host: "mosquitto.homelab.local"
         tasks:
           - name: Install Checkmk agent on Mosquitto
             ansible.builtin.apt:
               name: check-mk-agent
               state: present
               update_cache: yes
             delegate_to: mosquitto
           - name: Enable Checkmk agent service on Mosquitto
             ansible.builtin.service:
               name: check-mk-agent
               state: started
               enabled: yes
             delegate_to: mosquitto
           - name: Add Mosquitto host to Checkmk
             ansible.builtin.command: >
               cmk -v -U {{ checkmk_user }}:{{ checkmk_password }} {{ checkmk_site }} add-host {{ mosquitto_host }} 192.168.30.113
             args:
               creates: /omd/sites/{{ checkmk_site }}/etc/check_mk/conf.d/wato/hosts.mk
           - name: Discover services for Mosquitto
             ansible.builtin.command: >
               cmk -v -U {{ checkmk_user }}:{{ checkmk_password }} {{ checkmk_site }} discover-services {{ mosquitto_host }}
           - name: Activate changes in Checkmk
             ansible.builtin.command: >
               cmk -v -U {{ checkmk_user }}:{{ checkmk_password }} {{ checkmk_site }} activate
           - name: Verify Mosquitto services in Checkmk
             ansible.builtin.command: >
               cmk -v -U {{ checkmk_user }}:{{ checkmk_password }} {{ checkmk_site }} list-services {{ mosquitto_host }}
             register: service_list
           - name: Display Mosquitto services
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
                 "destination":"192.168.30.113",
                 "destination_port":"6556",
                 "description":"Allow Checkmk to Mosquitto"
               }'
           - name: Verify firewall rules
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Display firewall rules
             ansible.builtin.debug:
               msg: "{{ rules_list.stdout }}"
       ```
   - **Erklärung**:
     - Installiert den Checkmk-Agenten auf dem Mosquitto-Server (`192.168.30.113`).
     - Fügt Mosquitto als Host in Checkmk hinzu und entdeckt Dienste (z. B. CPU, Speicher, Mosquitto-Dienst).
     - Konfiguriert die OPNsense-Firewall, um Checkmk-Zugriff auf den Agenten (Port 6556) zu erlauben.
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml configure_checkmk_mosquitto.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display Mosquitto services] ***********************************************
       ok: [checkmk] => {
           "msg": "... CPU utilization, Memory, Mosquitto Service ..."
       }
       TASK [Display firewall rules] ***************************************************
       ok: [opnsense] => {
           "msg": "... Allow Checkmk to Mosquitto ..."
       }
       ```
   - Prüfe in Checkmk:
     - Öffne `http://192.168.30.101:5000/homelab`.
     - Gehe zu `Monitor > All hosts > mosquitto.homelab.local`.
     - Erwartete Ausgabe: Dienste wie `CPU utilization`, `Memory`, `Mosquitto Service` sind sichtbar.

**Erkenntnis**: Checkmk kann Mosquitto als Host überwachen und grundlegende Metriken wie CPU, Speicher und Dienststatus bereitstellen.

**Quelle**: https://docs.checkmk.com/latest/en/monitoring_basics.html

## Übung 2: Benutzerdefinierter Check für MQTT-Topics

**Ziel**: Erstelle einen benutzerdefinierten Checkmk-Check, um MQTT-Topic-Daten (z. B. Temperatur) zu überwachen.

**Aufgabe**: Implementiere einen Check, der MQTT-Daten von `sensors/#` überwacht und Schwellenwerte für Temperaturdaten prüft.

1. **Ansible-Playbook für benutzerdefinierten MQTT-Check**:
   - Erstelle ein Playbook:
     ```bash
     nano mqtt_topic_check.yml
     ```
     - Inhalt:
       ```yaml
       - name: Create custom MQTT topic check for Checkmk
         hosts: checkmk_servers
         become: yes
         vars:
           checkmk_site: "homelab"
         tasks:
           - name: Install mosquitto-clients on Checkmk server
             ansible.builtin.apt:
               name: mosquitto-clients
               state: present
               update_cache: yes
           - name: Create MQTT topic check script
             ansible.builtin.copy:
               dest: /omd/sites/{{ checkmk_site }}/local/share/check_mk/checks/mqtt_temperature
               content: |
                 #!/bin/bash
                 TEMP=$(mosquitto_sub -h mosquitto.homelab.local -t sensors/sensor1/temperature -C 1 -W 5 2>/dev/null)
                 if [ -z "$TEMP" ]; then
                   echo "2 MQTT_Temperature - No data received from MQTT topic sensors/sensor1/temperature"
                   exit 2
                 fi
                 TEMP_INT=$(echo $TEMP | cut -d'.' -f1)
                 if [ $TEMP_INT -gt 30 ]; then
                   echo "2 MQTT_Temperature temperature=$TEMP;25;30 Temperature ($TEMP°C) above critical threshold (30°C)"
                 elif [ $TEMP_INT -gt 25 ]; then
                   echo "1 MQTT_Temperature temperature=$TEMP;25;30 Temperature ($TEMP°C) above warning threshold (25°C)"
                 else
                   echo "0 MQTT_Temperature temperature=$TEMP;25;30 Temperature ($TEMP°C) within normal range"
                 fi
               mode: '0755'
           - name: Discover services for Mosquitto
             ansible.builtin.command: >
               cmk -v -U {{ checkmk_user }}:{{ checkmk_password }} {{ checkmk_site }} discover-services {{ mosquitto_host }}
           - name: Activate changes in Checkmk
             ansible.builtin.command: >
               cmk -v -U {{ checkmk_user }}:{{ checkmk_password }} {{ checkmk_site }} activate
           - name: Verify MQTT temperature check
             ansible.builtin.command: >
               cmk -v -U {{ checkmk_user }}:{{ checkmk_password }} {{ checkmk_site }} list-services {{ mosquitto_host }}
             register: service_list
           - name: Display services
             ansible.builtin.debug:
               msg: "{{ service_list.stdout }}"
       ```
   - **Erklärung**:
     - Installiert `mosquitto-clients` auf dem Checkmk-Server, um MQTT-Daten zu abonnieren.
     - Erstellt ein Skript `/omd/sites/homelab/local/share/check_mk/checks/mqtt_temperature`, das Temperaturdaten von `sensors/sensor1/temperature` prüft und Schwellenwerte (Warnung: 25°C, Kritisch: 30°C) anwendet.
     - Entdeckt und aktiviert den neuen Check in Checkmk.
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml mqtt_topic_check.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display services] ****************************************************
       ok: [checkmk] => {
           "msg": "... MQTT_Temperature ..."
       }
       ```
   - Teste den Check:
     - Sende Testdaten:
       ```bash
       mosquitto_pub -h mosquitto.homelab.local -t sensors/sensor1/temperature -m "28.5"
       ```
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Gehe zu `Monitor > All services > MQTT_Temperature`.
     - Erwartete Ausgabe: Status `WARNING` (Temperatur 28.5°C über Warnschwelle 25°C).

**Erkenntnis**: Benutzerdefinierte Checks in Checkmk ermöglichen die Überwachung spezifischer MQTT-Topic-Daten mit flexiblen Schwellenwerten.

**Quelle**: https://docs.checkmk.com/latest/en/localchecks.html

## Übung 3: Backup der Systemkonfigurationen auf TrueNAS

**Ziel**: Sichere die Konfigurationen von Mosquitto und Checkmk auf TrueNAS.

**Aufgabe**: Erstelle ein Ansible-Playbook für Backups und begrenze sie auf maximal fünf Versionen.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_mosquitto_checkmk.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup Mosquitto configuration
         hosts: mqtt_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/mosquitto-checkmk-integration/backups/mosquitto"
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
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/mosquitto-checkmk-integration/
             delegate_to: localhost
           - name: Display Mosquitto backup status
             ansible.builtin.debug:
               msg: "Mosquitto backup saved to {{ backup_file }} and synced to TrueNAS"
       - name: Backup Checkmk configuration
         hosts: checkmk_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/mosquitto-checkmk-integration/backups/checkmk"
           backup_file: "{{ backup_dir }}/checkmk-backup-{{ ansible_date_time.date }}.tar.gz"
         tasks:
           - name: Create backup directory
             ansible.builtin.file:
               path: "{{ backup_dir }}"
               state: directory
               mode: '0755'
             delegate_to: localhost
           - name: Stop Checkmk site
             ansible.builtin.command: >
               omd stop homelab
           - name: Backup Checkmk configuration
             ansible.builtin.command: >
               tar -czf /tmp/checkmk-backup-{{ ansible_date_time.date }}.tar.gz /omd/sites/homelab
             register: backup_result
           - name: Start Checkmk site
             ansible.builtin.command: >
               omd start homelab
           - name: Fetch backup file
             ansible.builtin.fetch:
               src: /tmp/checkmk-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ backup_file }}"
               flat: yes
           - name: Limit Checkmk backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t checkmk-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync Checkmk backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/mosquitto-checkmk-integration/
             delegate_to: localhost
           - name: Display Checkmk backup status
             ansible.builtin.debug:
               msg: "Checkmk backup saved to {{ backup_file }} and synced to TrueNAS"
       ```
   - **Erklärung**:
     - Sichert Mosquitto (`/etc/mosquitto`) und Checkmk (`/omd/sites/homelab`).
     - Stoppt Dienste (`mosquitto`, `homelab`), um konsistente Backups zu gewährleisten.
     - Begrenzt Backups auf fünf Versionen pro Dienst.
     - Synchronisiert Backups mit TrueNAS.
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_mosquitto_checkmk.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display Mosquitto backup status] ******************************************
       ok: [mosquitto] => {
           "msg": "Mosquitto backup saved to /home/ubuntu/mosquitto-checkmk-integration/backups/mosquitto/mosquitto-backup-<date>.tar.gz and synced to TrueNAS"
       }
       TASK [Display Checkmk backup status] ********************************************
       ok: [checkmk] => {
           "msg": "Checkmk backup saved to /home/ubuntu/mosquitto-checkmk-integration/backups/checkmk/checkmk-backup-<date>.tar.gz and synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/mosquitto-checkmk-integration/
     ```
     - Erwartete Ausgabe: Maximal fünf Backups pro Dienst (`mosquitto-backup-<date>.tar.gz`, `checkmk-backup-<date>.tar.gz`).

2. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/mosquitto-checkmk-integration
       ansible-playbook -i inventory.yml backup_mosquitto_checkmk.yml >> backup.log 2>&1
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
       0 3 * * * /home/ubuntu/mosquitto-checkmk-integration/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible automatisiert die Sicherung der Mosquitto- und Checkmk-Konfigurationen, während TrueNAS zuverlässige externe Speicherung bietet.

## Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass die Firewall-Regeln aus Übung 1 (Port 6556 für Checkmk-Agent, Port 1883 für MQTT) aktiv sind.
   - Prüfe OPNsense-Logs:
     ```bash
     ansible-playbook -i inventory.yml -m ansible.builtin.command -a "cat /var/log/system/latest.log" opnsense
     ```

2. **Erweiterung mit weiteren Checks**:
   - Erstelle einen Check für MQTT-Verbindungen:
     ```bash
     nano /omd/sites/homelab/local/share/check_mk/checks/mqtt_connections
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       CONNECTIONS=$(mosquitto_sub -h mosquitto.homelab.local -t '$SYS/broker/clients/connected' -C 1 -W 5 2>/dev/null)
       if [ -z "$CONNECTIONS" ]; then
         echo "2 MQTT_Connections - No connection data received"
         exit 2
       fi
       if [ $CONNECTIONS -gt 10 ]; then
         echo "1 MQTT_Connections connections=$CONNECTIONS;10;20 Too many MQTT connections ($CONNECTIONS)"
       else
         echo "0 MQTT_Connections connections=$CONNECTIONS;10;20 MQTT connections ($CONNECTIONS) within normal range"
       fi
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /omd/sites/homelab/local/share/check_mk/checks/mqtt_connections
       ```
     - In Checkmk: `Setup > Services > Manual checks > Custom checks`, füge `MQTT_Connections` hinzu.

## Schritt 5: Erweiterung der Übungen
1. **Erweiterte Checkmk-Checks**:
   - Erstelle ein Playbook für zusätzliche MQTT-Checks:
     ```bash
     nano add_mqtt_check.yml
     ```
     - Inhalt:
       ```yaml
       - name: Add additional MQTT check
         hosts: checkmk_servers
         become: yes
         vars:
           checkmk_site: "homelab"
         tasks:
           - name: Create MQTT humidity check script
             ansible.builtin.copy:
               dest: /omd/sites/{{ checkmk_site }}/local/share/check_mk/checks/mqtt_humidity
               content: |
                 #!/bin/bash
                 HUMIDITY=$(mosquitto_sub -h mosquitto.homelab.local -t sensors/sensor1/humidity -C 1 -W 5 2>/dev/null)
                 if [ -z "$HUMIDITY" ]; then
                   echo "2 MQTT_Humidity - No data received from MQTT topic sensors/sensor1/humidity"
                   exit 2
                 fi
                 HUMIDITY_INT=$(echo $HUMIDITY | cut -d'.' -f1)
                 if [ $HUMIDITY_INT -gt 80 ]; then
                   echo "2 MQTT_Humidity humidity=$HUMIDITY;70;80 Humidity ($HUMIDITY%) above critical threshold (80%)"
                 elif [ $HUMIDITY_INT -gt 70 ]; then
                   echo "1 MQTT_Humidity humidity=$HUMIDITY;70;80 Humidity ($HUMIDITY%) above warning threshold (70%)"
                 else
                   echo "0 MQTT_Humidity humidity=$HUMIDITY;70;80 Humidity ($HUMIDITY%) within normal range"
                 fi
               mode: '0755'
           - name: Discover services
             ansible.builtin.command: >
               cmk -v -U {{ checkmk_user }}:{{ checkmk_password }} {{ checkmk_site }} discover-services {{ mosquitto_host }}
           - name: Activate changes
             ansible.builtin.command: >
               cmk -v -U {{ checkmk_user }}:{{ checkmk_password }} {{ checkmk_site }} activate
       ```

2. **Backup-Versionierung mit Git**:
   - Initialisiere ein Git-Repository für Backups:
     ```bash
     cd ~/mosquitto-checkmk-integration/backups
     git init
     git add .
     git commit -m "Initial Mosquitto and Checkmk backups"
     ```

## Best Practices für Schüler

- **Monitoring-Design**:
  - Nutze Checkmk für grundlegende Überwachungen (CPU, Speicher) und benutzerdefinierte Checks für MQTT-spezifische Metriken.
  - Teste MQTT-Topics mit `mosquitto_pub` und `mosquitto_sub`:
    ```bash
    mosquitto_pub -h mosquitto.homelab.local -t sensors/sensor1/temperature -m "28.5"
    ```
- **Sicherheit**:
  - Schränke Checkmk-Agent-Zugriff ein:
    ```bash
    ssh root@192.168.30.113 "ufw allow from 192.168.30.101 to any port 6556 proto tcp"
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
  - Teste Backups vor Updates (siehe https://mosquitto.org, https://docs.checkmk.com).
- **Fehlerbehebung**:
  - Prüfe Mosquitto-Logs:
    ```bash
    ssh root@192.168.30.113 "cat /var/log/mosquitto/mosquitto.log"
    ```
  - Prüfe Checkmk-Logs:
    ```bash
    cat /omd/sites/homelab/var/log/web.log
    ```
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/mosquitto-checkmk-integration/backup.log
    ```

**Quellen**: https://mosquitto.org, https://docs.checkmk.com, https://docs.ansible.com, https://docs.opnsense.org/manual

## Empfehlungen für Schüler

- **Setup**: Mosquitto, Checkmk, TrueNAS-Backups.
- **Workloads**: MQTT-Monitoring, benutzerdefinierte Checks, Backups.
- **Integration**: Proxmox (LXC), TrueNAS (Backups), OPNsense (DNS, Netzwerk).
- **Beispiel**: Überwachung von MQTT-Broker und Sensordaten im HomeLab.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit grundlegenden Checks, erweitere zu komplexeren MQTT-Metriken.
- **Übung**: Teste mit MQTT Explorer (`mosquitto.homelab.local:1883`) und Checkmk-Dashboards.
- **Fehlerbehebung**: Nutze Checkmk-Logs und `mosquitto_sub` für Debugging.
- **Lernressourcen**: https://mosquitto.org, https://docs.checkmk.com, https://docs.ansible.com.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Schnelle Integration von Mosquitto mit Checkmk für Monitoring.
- **Skalierbarkeit**: Automatisierte Checks und Backup-Prozesse.
- **Lernwert**: Verständnis von MQTT-Überwachung und Checkmk-Checks.

**Nächste Schritte**: Möchtest du eine Anleitung zur Integration von Mosquitto mit Wazuh oder Fluentd, Erweiterung der Checks für weitere MQTT-Topics, oder eine Kombination mit Home Assistant?

**Quellen**:
- Mosquitto-Dokumentation: https://mosquitto.org
- Checkmk-Dokumentation: https://docs.checkmk.com
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen: https://mosquitto.org, https://docs.checkmk.com
```