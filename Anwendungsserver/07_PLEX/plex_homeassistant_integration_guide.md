# Lernprojekt: Integration von Plex Media Server mit Home Assistant

## Vorbereitung: Umgebung prüfen
1. **Proxmox VE prüfen**:
   - Melde dich an der Proxmox-Weboberfläche an: `https://192.168.30.2:8006`.
   - Stelle sicher, dass die LXC-Container für Plex (`192.168.30.118`) und Home Assistant (`192.168.30.117`) laufen:
     ```bash
     pct list
     ```
     - Erwartete Ausgabe: Container `plex`, `homeassistant` mit Status `running`.
2. **DNS in OPNsense prüfen**:
   - Öffne die OPNsense-Weboberfläche: `http://192.168.30.1`.
   - Gehe zu `Services > Unbound DNS > Overrides > Host`.
   - Überprüfe Einträge:
     - `plex.homelab.local` → `192.168.30.118`
     - `homeassistant.homelab.local` → `192.168.30.117`
   - Teste die DNS-Auflösung:
     ```bash
     nslookup plex.homelab.local 192.168.30.1
     nslookup homeassistant.homelab.local 192.168.30.1
     ```
     - Erwartete Ausgabe: `192.168.30.118`, `192.168.30.117`.
3. **Ansible-Umgebung prüfen**:
   - Auf der Ubuntu-VM (`192.168.30.101`):
     ```bash
     ssh ubuntu@192.168.30.101
     ansible --version
     ```
   - Stelle sicher, dass SSH-Zugriff auf Plex- und Home Assistant-Server möglich ist:
     ```bash
     ssh root@192.168.30.118
     ssh root@192.168.30.117
     ```
4. **Plex und Home Assistant prüfen**:
   - Öffne Plex: `http://plex.homelab.local:32400/web`.
     - Stelle sicher, dass die Medienbibliothek (`/mnt/media`) konfiguriert ist.
   - Öffne Home Assistant: `http://homeassistant.homelab.local:8123`.
     - Melde dich an (Benutzer: `homeassistant`, Passwort: `securepassword123`).
     - Stelle sicher, dass die MQTT-Integration aktiv ist (siehe `nodered_flow_extension_homeassistant_guide.md`).
5. **Plex-Token abrufen**:
   - Melde dich bei Plex an (`https://plex.tv`).
   - Öffne `http://plex.homelab.local:32400/web` in einem Browser mit aktiver Plex-Session.
   - Öffne die Entwicklerkonsole (F12) und sende eine Anfrage (z. B. `curl http://192.168.30.118:32400`).
   - Suche in der Antwort nach `X-Plex-Token` (siehe https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/).
   - Beispiel-Token: `abc123xyz789` (ersetze durch deinen Token).
6. **Projektverzeichnis erstellen**:
   - Auf `192.168.30.101`:
     ```bash
     mkdir ~/plex-ha-integration
     cd ~/plex-ha-integration
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Plex (`192.168.30.118`), Home Assistant (`192.168.30.117`), OPNsense (`192.168.30.1`) und TrueNAS (`192.168.30.100`).

## Übung 1: Einrichtung der Plex-Integration in Home Assistant

**Ziel**: Konfiguriere die Plex-Integration in Home Assistant, um den Plex Media Server zu überwachen und zu steuern.

**Aufgabe**: Füge die Plex-Integration hinzu und teste die Erkennung von Plex-Medienwiedergabe.

1. **Ansible-Inventar erstellen**:
   - Erstelle eine Inventar-Datei:
     ```bash
     nano inventory.yml
     ```
     - Inhalt:
       ```yaml
       all:
         children:
           ha_servers:
             hosts:
               homeassistant:
                 ansible_host: 192.168.30.117
                 ansible_user: root
                 ansible_connection: ssh
                 ansible_python_interpreter: /usr/bin/python3
           plex_servers:
             hosts:
               plex:
                 ansible_host: 192.168.30.118
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

2. **Ansible-Playbook für Plex-Integration**:
   - Erstelle ein Playbook:
     ```bash
     nano configure_plex_ha.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure Plex integration in Home Assistant
         hosts: ha_servers
         become: yes
         vars:
           plex_token: "abc123xyz789"  # Ersetze durch deinen Plex-Token
           plex_server: "plex.homelab.local"
           plex_port: 32400
         tasks:
           - name: Create Plex configuration
             ansible.builtin.copy:
               dest: /usr/share/hassio/homeassistant/configuration.yaml
               content: |
                 # Existing configuration
                 mqtt:
                   broker: mosquitto.homelab.local
                   port: 1883
                   username: testuser
                   password: securepassword123
                   discovery: true
                   discovery_prefix: homeassistant
                 # Add Plex configuration
                 plex:
                   host: {{ plex_server }}
                   port: {{ plex_port }}
                   token: {{ plex_token }}
               mode: '0600'
           - name: Restart Home Assistant
             ansible.builtin.service:
               name: hassio-supervisor
               state: restarted
           - name: Test Plex integration
             ansible.builtin.uri:
               url: http://192.168.30.117:8123/api/states/media_player.plex_plex
               return_content: yes
             register: plex_test
             ignore_errors: yes
           - name: Display Plex integration test result
             ansible.builtin.debug:
               msg: "{{ plex_test.status }}"
       - name: Configure OPNsense firewall for Plex and Home Assistant
         hosts: network_devices
         tasks:
           - name: Add firewall rule for Plex (32400)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.117",
                 "destination":"192.168.30.118",
                 "destination_port":"32400",
                 "description":"Allow Home Assistant to Plex"
               }'
           - name: Verify firewall rules
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Display firewall rules
             ansible.builtin.debug:
               msg: "{{ rules_list.stdout }}"
       ```
   - **Erklärung**:
     - Fügt die Plex-Integration zur Home Assistant-Konfiguration (`configuration.yaml`) hinzu.
     - Startet Home Assistant neu, um die Änderungen zu übernehmen.
     - Testet die Plex-Integration durch Abruf des `media_player.plex_plex`-Status.
     - Konfiguriert die OPNsense-Firewall, um Home Assistant-Zugriff auf Plex (Port 32400) zu erlauben.
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml configure_plex_ha.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display Plex integration test result] ***********************************
       ok: [homeassistant] => {
           "msg": 200
       }
       TASK [Display firewall rules] ************************************************
       ok: [opnsense] => {
           "msg": "... Allow Home Assistant to Plex ..."
       }
       ```
   - Prüfe in Home Assistant:
     - Öffne `http://homeassistant.homelab.local:8123`.
     - Gehe zu `Settings > Devices & Services`.
     - Erwartete Ausgabe: Die Plex-Integration ist aktiv, und ein `media_player.plex_plex`-Entity ist sichtbar.
     - Starte eine Wiedergabe in Plex (`http://plex.homelab.local:32400/web`) und prüfe in Home Assistant unter `Developer Tools > States`, ob `media_player.plex_plex` den Status `playing` anzeigt.

**Erkenntnis**: Die Plex-Integration in Home Assistant ermöglicht die Überwachung des Wiedergabestatus und die Steuerung von Plex-Medien.

**Quelle**: https://www.home-assistant.io/integrations/plex

## Übung 2: Erstellung von Automatisierungen für die Medienwiedergabe

**Ziel**: Erstelle Automatisierungen in Home Assistant, die auf Plex-Wiedergabe oder MQTT-Sensordaten reagieren.

**Aufgabe**: Konfiguriere eine Automatisierung, die eine Benachrichtigung sendet, wenn Plex eine Wiedergabe startet, und eine weitere, die die Wiedergabe basierend auf Temperaturdaten pausiert.

1. **Ansible-Playbook für Automatisierungen**:
   - Erstelle ein Playbook:
     ```bash
     nano plex_automations.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure Plex automations in Home Assistant
         hosts: ha_servers
         become: yes
         tasks:
           - name: Create automations configuration
             ansible.builtin.copy:
               dest: /usr/share/hassio/homeassistant/automations.yaml
               content: |
                 - id: 'plex_play_notification'
                   alias: Notify on Plex Playback
                   trigger:
                     - platform: state
                       entity_id: media_player.plex_plex
                       to: 'playing'
                   action:
                     - service: notify.notify
                       data:
                         message: "Plex is playing media!"
                   mode: single
                 - id: 'plex_pause_on_high_temp'
                   alias: Pause Plex on High Temperature
                   trigger:
                     - platform: state
                       entity_id: sensor.temperature_sensor1
                       to: 'above'
                       value_template: "{{ float(states('sensor.temperature_sensor1')) > 30 }}"
                   action:
                     - service: media_player.media_pause
                       data:
                         entity_id: media_player.plex_plex
                   mode: single
               mode: '0600'
           - name: Restart Home Assistant
             ansible.builtin.service:
               name: hassio-supervisor
               state: restarted
           - name: Test notify service
             ansible.builtin.uri:
               url: http://192.168.30.117:8123/api/services/notify/notify
               method: POST
               headers:
                 Content-Type: application/json
               body: '{"message": "Test notification"}'
               return_content: yes
             register: notify_test
             ignore_errors: yes
           - name: Display notify test result
             ansible.builtin.debug:
               msg: "{{ notify_test.status }}"
       ```
   - **Erklärung**:
     - Erstellt zwei Automatisierungen:
       - `plex_play_notification`: Sendet eine Benachrichtigung, wenn Plex eine Wiedergabe startet.
       - `plex_pause_on_high_temp`: Pausiert Plex, wenn die Temperatur (von `sensor.temperature_sensor1`, MQTT-Topic `sensors/sensor1/temperature`) 30°C übersteigt.
     - Startet Home Assistant neu.
     - Testet den Benachrichtigungsdienst.
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml plex_automations.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display notify test result] ********************************************
       ok: [homeassistant] => {
           "msg": 200
       }
       ```
   - Teste die Automatisierungen:
     - Starte eine Wiedergabe in Plex (`http://plex.homelab.local:32400/web`).
     - Prüfe in Home Assistant unter `Settings > Automations & Scenes`, ob `plex_play_notification` ausgelöst wird (Benachrichtigung erscheint).
     - Sende Test-Temperaturdaten über MQTT:
       ```bash
       mosquitto_pub -h mosquitto.homelab.local -t sensors/sensor1/temperature -m "32.0"
       ```
     - Prüfe in Plex, ob die Wiedergabe pausiert wurde.
     - Erwartete Ausgabe: `media_player.plex_plex` zeigt Status `paused`.

**Erkenntnis**: Home Assistant-Automatisierungen können Plex-Medienwiedergabe basierend auf Ereignissen oder Sensordaten steuern.

**Quelle**: https://www.home-assistant.io/integrations/automation

## Übung 3: Backup der Home Assistant- und Plex-Konfigurationen auf TrueNAS

**Ziel**: Sichere die Konfigurationen von Home Assistant und Plex auf TrueNAS.

**Aufgabe**: Erstelle ein Ansible-Playbook für Backups und begrenze sie auf maximal fünf Versionen.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_plex_ha.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup Home Assistant configuration
         hosts: ha_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/plex-ha-integration/backups/ha"
           backup_file: "{{ backup_dir }}/ha-backup-{{ ansible_date_time.date }}.tar.gz"
         tasks:
           - name: Create backup directory
             ansible.builtin.file:
               path: "{{ backup_dir }}"
               state: directory
               mode: '0755'
             delegate_to: localhost
           - name: Stop Home Assistant service
             ansible.builtin.service:
               name: hassio-supervisor
               state: stopped
           - name: Backup Home Assistant configuration
             ansible.builtin.command: >
               tar -czf /tmp/ha-backup-{{ ansible_date_time.date }}.tar.gz /usr/share/hassio
             register: backup_result
           - name: Start Home Assistant service
             ansible.builtin.service:
               name: hassio-supervisor
               state: started
           - name: Fetch backup file
             ansible.builtin.fetch:
               src: /tmp/ha-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ backup_file }}"
               flat: yes
           - name: Limit Home Assistant backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t ha-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync Home Assistant backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/plex-ha-integration/
             delegate_to: localhost
           - name: Display Home Assistant backup status
             ansible.builtin.debug:
               msg: "Home Assistant backup saved to {{ backup_file }} and synced to TrueNAS"
       - name: Backup Plex configuration
         hosts: plex_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/plex-ha-integration/backups/plex"
           backup_file: "{{ backup_dir }}/plex-backup-{{ ansible_date_time.date }}.tar.gz"
         tasks:
           - name: Create backup directory
             ansible.builtin.file:
               path: "{{ backup_dir }}"
               state: directory
               mode: '0755'
             delegate_to: localhost
           - name: Stop Plex Media Server
             ansible.builtin.service:
               name: plexmediaserver
               state: stopped
           - name: Backup Plex configuration
             ansible.builtin.command: >
               tar -czf /tmp/plex-backup-{{ ansible_date_time.date }}.tar.gz /var/lib/plexmediaserver
             register: backup_result
           - name: Start Plex Media Server
             ansible.builtin.service:
               name: plexmediaserver
               state: started
           - name: Fetch backup file
             ansible.builtin.fetch:
               src: /tmp/plex-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ backup_file }}"
               flat: yes
           - name: Limit Plex backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t plex-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync Plex backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/plex-ha-integration/
             delegate_to: localhost
           - name: Display Plex backup status
             ansible.builtin.debug:
               msg: "Plex backup saved to {{ backup_file }} and synced to TrueNAS"
       ```
   - **Erklärung**:
     - Sichert Home Assistant (`/usr/share/hassio`) und Plex (`/var/lib/plexmediaserver`).
     - Stoppt Dienste, um konsistente Backups zu gewährleisten.
     - Begrenzt Backups auf fünf Versionen pro Dienst.
     - Synchronisiert Backups mit TrueNAS.
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_plex_ha.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display Home Assistant backup status] **********************************
       ok: [homeassistant] => {
           "msg": "Home Assistant backup saved to /home/ubuntu/plex-ha-integration/backups/ha/ha-backup-<date>.tar.gz and synced to TrueNAS"
       }
       TASK [Display Plex backup status] ********************************************
       ok: [plex] => {
           "msg": "Plex backup saved to /home/ubuntu/plex-ha-integration/backups/plex/plex-backup-<date>.tar.gz and synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/plex-ha-integration/
     ```
     - Erwartete Ausgabe: Maximal fünf Backups pro Dienst (`ha-backup-<date>.tar.gz`, `plex-backup-<date>.tar.gz`).

2. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/plex-ha-integration
       ansible-playbook -i inventory.yml backup_plex_ha.yml >> backup.log 2>&1
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
       0 3 * * * /home/ubuntu/plex-ha-integration/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible automatisiert die Sicherung der Home Assistant- und Plex-Konfigurationen, während TrueNAS zuverlässige externe Speicherung bietet.

## Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass die Firewall-Regeln aus Übung 1 (Port 32400 für Plex, Port 8123 für Home Assistant) aktiv sind.
   - Prüfe OPNsense-Logs:
     ```bash
     ansible-playbook -i inventory.yml -m ansible.builtin.command -a "cat /var/log/system/latest.log" opnsense
     ```

2. **Monitoring mit Checkmk (optional)**:
   - Erstelle einen Check für Plex-Wiedergabe:
     ```bash
     nano /omd/sites/homelab/local/share/check_mk/checks/plex_playback
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://192.168.30.117:8123/api/states/media_player.plex_plex)
       if [ "$RESPONSE" == "200" ]; then
         STATUS=$(curl -s http://192.168.30.117:8123/api/states/media_player.plex_plex | jq -r .state)
         if [ "$STATUS" == "playing" ]; then
           echo "0 Plex_Playback - Plex is playing media"
         else
           echo "0 Plex_Playback - Plex is not playing (state: $STATUS)"
         fi
       else
         echo "2 Plex_Playback - Unable to check Plex playback status (HTTP: $RESPONSE)"
       fi
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /omd/sites/homelab/local/share/check_mk/checks/plex_playback
       ```
     - Installiere `jq` auf dem Checkmk-Server:
       ```bash
       ssh ubuntu@192.168.30.101 "sudo apt-get install -y jq"
       ```
     - In Checkmk: `Setup > Services > Manual checks > Custom checks`, füge `Plex_Playback` hinzu.

## Schritt 5: Erweiterung der Übungen
1. **Erweiterte Automatisierungen**:
   - Erstelle ein Playbook für zusätzliche Automatisierungen:
     ```bash
     nano additional_plex_automations.yml
     ```
     - Inhalt:
       ```yaml
       - name: Add additional Plex automations
         hosts: ha_servers
         become: yes
         tasks:
           - name: Create additional automations
             ansible.builtin.copy:
               dest: /usr/share/hassio/homeassistant/automations.yaml
               content: |
                 - id: 'plex_play_notification'
                   alias: Notify on Plex Playback
                   trigger:
                     - platform: state
                       entity_id: media_player.plex_plex
                       to: 'playing'
                   action:
                     - service: notify.notify
                       data:
                         message: "Plex is playing media!"
                   mode: single
                 - id: 'plex_pause_on_high_temp'
                   alias: Pause Plex on High Temperature
                   trigger:
                     - platform: state
                       entity_id: sensor.temperature_sensor1
                       to: 'above'
                       value_template: "{{ float(states('sensor.temperature_sensor1')) > 30 }}"
                   action:
                     - service: media_player.media_pause
                       data:
                         entity_id: media_player.plex_plex
                   mode: single
                 - id: 'plex_resume_on_normal_temp'
                   alias: Resume Plex on Normal Temperature
                   trigger:
                     - platform: state
                       entity_id: sensor.temperature_sensor1
                       to: 'below'
                       value_template: "{{ float(states('sensor.temperature_sensor1')) <= 25 }}"
                   action:
                     - service: media_player.media_play
                       data:
                         entity_id: media_player.plex_plex
                   mode: single
               mode: '0600'
           - name: Restart Home Assistant
             ansible.builtin.service:
               name: hassio-supervisor
               state: restarted
       ```

2. **Backup-Versionierung mit Git**:
   - Initialisiere ein Git-Repository für Backups:
     ```bash
     cd ~/plex-ha-integration/backups
     git init
     git add .
     git commit -m "Initial Plex and Home Assistant backups"
     ```

## Best Practices für Schüler

- **Integrations-Design**:
  - Nutze die Plex-Integration für einfache Steuerung (z. B. Play/Pause) und erweitere mit komplexeren Automatisierungen.
  - Teste MQTT-Sensoren mit `mosquitto_pub`:
    ```bash
    mosquitto_pub -h mosquitto.homelab.local -t sensors/sensor1/temperature -m "32.0"
    ```
- **Sicherheit**:
  - Schränke Zugriff ein:
    ```bash
    ssh root@192.168.30.117 "ufw allow from 192.168.30.0/24 to any port 8123 proto tcp"
    ssh root@192.168.30.118 "ufw allow from 192.168.30.0/24 to any port 32400 proto tcp"
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
  - Verwende HTTPS für Plex und Home Assistant bei externem Zugriff:
    ```bash
    ssh root@192.168.30.118 "turnkey-letsencrypt plex.homelab.local"
    ssh root@192.168.30.117 "turnkey-letsencrypt homeassistant.homelab.local"
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
  - Teste Backups vor Updates (siehe https://www.home-assistant.io, https://support.plex.tv).
- **Fehlerbehebung**:
  - Prüfe Home Assistant-Logs:
    ```bash
    ssh root@192.168.30.117 "cat /usr/share/hassio/homeassistant/home-assistant.log"
    ```
  - Prüfe Plex-Logs:
    ```bash
    ssh root@192.168.30.118 "cat /var/lib/plexmediaserver/Library/Application\ Support/Plex\ Media\ Server/Logs/*.log"
    ```
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/plex-ha-integration/backup.log
    ```

**Quellen**: https://www.home-assistant.io/integrations/plex, https://support.plex.tv, https://docs.ansible.com, https://docs.opnsense.org/manual

## Empfehlungen für Schüler

- **Setup**: Plex Media Server, Home Assistant, TrueNAS-Backups.
- **Workloads**: Plex-Integration, Automatisierungen, Backups.
- **Integration**: Proxmox (LXC), TrueNAS (NFS), OPNsense (DNS, Netzwerk).
- **Beispiel**: Automatisierte Mediensteuerung basierend auf Sensordaten.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einfachen Automatisierungen, erweitere zu komplexeren Szenarien.
- **Übung**: Teste Automatisierungen mit Plex-Wiedergabe und MQTT-Sensoren.
- **Fehlerbehebung**: Nutze Home Assistant-Logs und Plex-Logs für Debugging.
- **Lernressourcen**: https://www.home-assistant.io, https://support.plex.tv, https://docs.ansible.com.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Schnelle Integration von Plex mit Home Assistant für Medienautomatisierung.
- **Skalierbarkeit**: Automatisierte Konfiguration und Backup-Prozesse.
- **Lernwert**: Verständnis von Home-Automation und Mediensteuerung.

**Nächste Schritte**: Möchtest du eine Anleitung zur Integration von Plex und Home Assistant mit Wazuh für Sicherheitsmonitoring, Erweiterung der Automatisierungen, oder eine andere Anpassung?

**Quellen**:
- Plex-Dokumentation: https://support.plex.tv
- Home Assistant-Dokumentation: https://www.home-assistant.io
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen: https://www.home-assistant.io/integrations/plex, https://support.plex.tv
```