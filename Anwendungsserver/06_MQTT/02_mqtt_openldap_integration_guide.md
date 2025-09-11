# Lernprojekt: Integration eines MQTT-Systems mit OpenLDAP für Authentifizierung

## Vorbereitung: Umgebung prüfen
1. **Proxmox VE prüfen**:
   - Melde dich an der Proxmox-Weboberfläche an: `https://192.168.30.2:8006`.
   - Stelle sicher, dass die LXC-Container für Mosquitto (`192.168.30.113`), Node-RED (`192.168.30.114`), InfluxDB (`192.168.30.115`), Grafana (`192.168.30.116`) und OpenLDAP (`192.168.30.106`) laufen:
     ```bash
     pct list
     ```
     - Erwartete Ausgabe: Container `mosquitto`, `nodered`, `influxdb`, `grafana`, `ldap` mit Status `running`.
2. **DNS in OPNsense prüfen**:
   - Öffne die OPNsense-Weboberfläche: `http://192.168.30.1`.
   - Gehe zu `Services > Unbound DNS > Overrides > Host`.
   - Überprüfe Einträge:
     - `mosquitto.homelab.local` → `192.168.30.113`
     - `nodered.homelab.local` → `192.168.30.114`
     - `influxdb.homelab.local` → `192.168.30.115`
     - `grafana.homelab.local` → `192.168.30.116`
     - `ldap.homelab.local` → `192.168.30.106`
   - Teste die DNS-Auflösung:
     ```bash
     nslookup mosquitto.homelab.local 192.168.30.1
     nslookup nodered.homelab.local 192.168.30.1
     nslookup influxdb.homelab.local 192.168.30.1
     nslookup grafana.homelab.local 192.168.30.1
     nslookup ldap.homelab.local 192.168.30.1
     ```
     - Erwartete Ausgabe: `192.168.30.113`, `192.168.30.114`, `192.168.30.115`, `192.168.30.116`, `192.168.30.106`.
3. **Ansible-Umgebung prüfen**:
   - Auf der Ubuntu-VM (`192.168.30.101`):
     ```bash
     ssh ubuntu@192.168.30.101
     ansible --version
     ```
   - Stelle sicher, dass SSH-Zugriff auf alle Server möglich ist:
     ```bash
     ssh root@192.168.30.113
     ssh root@192.168.30.114
     ssh root@192.168.30.106
     ```
4. **Projektverzeichnis erstellen**:
   - Auf `192.168.30.101`:
     ```bash
     mkdir ~/mqtt-openldap-integration
     cd ~/mqtt-openldap-integration
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Mosquitto (`192.168.30.113`), Node-RED (`192.168.30.114`), InfluxDB (`192.168.30.115`), Grafana (`192.168.30.116`), OpenLDAP (`192.168.30.106`), OPNsense (`192.168.30.1`) und TrueNAS (`192.168.30.100`).

## Übung 1: Konfiguration der OpenLDAP-Integration für Mosquitto und Node-RED

**Ziel**: Konfiguriere Mosquitto und Node-RED, um Benutzer aus OpenLDAP zu authentifizieren.

**Aufgabe**: Installiere das `mosquitto-auth-plug`-Plugin für Mosquitto und das `node-red-contrib-ldap-auth`-Plugin für Node-RED, und konfiguriere die LDAP-Authentifizierung mit Ansible.

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
           openldap_servers:
             hosts:
               ldap:
                 ansible_host: 192.168.30.106
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

2. **Ansible-Playbook für Mosquitto und Node-RED LDAP-Integration**:
   - Erstelle ein Playbook:
     ```bash
     nano configure_mqtt_nodered_ldap.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure Mosquitto LDAP Integration
         hosts: mqtt_servers
         become: yes
         vars:
           ldap_host: "ldap.homelab.local"
           ldap_port: 389
           ldap_base_dn: "dc=homelab,dc=local"
           ldap_bind_dn: "cn=admin,dc=homelab,dc=local"
           ldap_bind_password: "securepassword123"
         tasks:
           - name: Install build dependencies for mosquitto-auth-plug
             ansible.builtin.apt:
               name: "{{ packages }}"
               state: present
               update_cache: yes
             vars:
               packages:
                 - git
                 - build-essential
                 - libmosquitto-dev
                 - libldap2-dev
                 - libssl-dev
           - name: Clone mosquitto-auth-plug repository
             ansible.builtin.git:
               repo: https://github.com/jpmens/mosquitto-auth-plug.git
               dest: /root/mosquitto-auth-plug
               version: master
           - name: Build mosquitto-auth-plug
             ansible.builtin.command: make -C /root/mosquitto-auth-plug
             args:
               creates: /root/mosquitto-auth-plug/auth-plug.so
           - name: Copy auth-plug.so to Mosquitto plugins
             ansible.builtin.copy:
               src: /root/mosquitto-auth-plug/auth-plug.so
               dest: /usr/lib/mosquitto/auth-plug.so
               mode: '0644'
           - name: Create Mosquitto auth configuration
             ansible.builtin.copy:
               dest: /etc/mosquitto/conf.d/auth.conf
               content: |
                 auth_plugin /usr/lib/mosquitto/auth-plug.so
                 auth_opt_backends ldap
                 auth_opt_ldap_host {{ ldap_host }}
                 auth_opt_ldap_port {{ ldap_port }}
                 auth_opt_ldap_binddn {{ ldap_bind_dn }}
                 auth_opt_ldap_bindpw {{ ldap_bind_password }}
                 auth_opt_ldap_basedn {{ ldap_base_dn }}
                 auth_opt_ldap_username_attr uid
                 auth_opt_ldap_filter (objectClass=inetOrgPerson)
                 allow_anonymous false
           - name: Restart Mosquitto
             ansible.builtin.service:
               name: mosquitto
               state: restarted
           - name: Test LDAP authentication with Mosquitto
             ansible.builtin.command: >
               mosquitto_sub -h mosquitto.homelab.local -t sensors/test -u testuser -P securepassword123 -C 1 -W 5
             register: mqtt_test_result
             ignore_errors: yes
           - name: Display Mosquitto LDAP test result
             ansible.builtin.debug:
               msg: "{{ mqtt_test_result.stdout | default('Failed to connect, check logs') }}"
       - name: Configure Node-RED LDAP Integration
         hosts: nodered_servers
         become: yes
         vars:
           ldap_host: "ldap.homelab.local"
           ldap_port: 389
           ldap_base_dn: "dc=homelab,dc=local"
           ldap_bind_dn: "cn=admin,dc=homelab,dc=local"
           ldap_bind_password: "securepassword123"
         tasks:
           - name: Install node-red-contrib-ldap-auth
             ansible.builtin.command: npm install -g node-red-contrib-ldap-auth
             args:
               creates: /usr/lib/node_modules/node-red-contrib-ldap-auth
           - name: Configure Node-RED LDAP settings
             ansible.builtin.copy:
               dest: /root/.node-red/settings.js
               content: |
                 module.exports = {
                   adminAuth: {
                     type: "ldap",
                     ldap: {
                       uri: "ldap://{{ ldap_host }}:{{ ldap_port }}",
                       base: "{{ ldap_base_dn }}",
                       bindDn: "{{ ldap_bind_dn }}",
                       bindCredentials: "{{ ldap_bind_password }}",
                       searchBase: "ou=users,{{ ldap_base_dn }}",
                       searchFilter: "(uid={{username}})",
                       attribute: "uid"
                     },
                     default: {
                       role: "read"
                     }
                   }
                 }
           - name: Restart Node-RED
             ansible.builtin.service:
               name: nodered
               state: restarted
           - name: Test Node-RED LDAP authentication
             ansible.builtin.command: >
               curl -s -u testuser:securepassword123 http://nodered.homelab.local:1880
             register: nodered_test_result
             ignore_errors: yes
           - name: Display Node-RED LDAP test result
             ansible.builtin.debug:
               msg: "{{ nodered_test_result.stdout | default('Failed to connect, check logs') }}"
       - name: Configure OPNsense firewall for LDAP
         hosts: network_devices
         tasks:
           - name: Add firewall rule for LDAP (389)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.113,192.168.30.114",
                 "destination":"192.168.30.106",
                 "destination_port":"389",
                 "description":"Allow Mosquitto and Node-RED to OpenLDAP"
               }'
             register: firewall_result
           - name: Verify firewall rules
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Display firewall rules
             ansible.builtin.debug:
               msg: "{{ rules_list.stdout }}"
       ```
   - **Erklärung**:
     - Installiert das `mosquitto-auth-plug`-Plugin für Mosquitto und konfiguriert LDAP-Authentifizierung.
     - Installiert das `node-red-contrib-ldap-auth`-Plugin für Node-RED und konfiguriert LDAP in `settings.js`.
     - Fügt eine Firewall-Regel in OPNsense hinzu, um Mosquitto (`192.168.30.113`) und Node-RED (`192.168.30.114`) den Zugriff auf OpenLDAP (`192.168.30.106:389`) zu erlauben.
     - Testet die LDAP-Authentifizierung für beide Dienste.

3. **Playbook ausführen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml configure_mqtt_nodered_ldap.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display Mosquitto LDAP test result] ***************************************
       ok: [mosquitto] => {
           "msg": ""
       }
       TASK [Display Node-RED LDAP test result] ****************************************
       ok: [nodered] => {
           "msg": "<html>... Node-RED login page ..."
       }
       TASK [Display firewall rules] ***************************************************
       ok: [opnsense] => {
           "msg": "... Allow Mosquitto and Node-RED to OpenLDAP ..."
       }
       ```
   - Prüfe Mosquitto:
     ```bash
     mosquitto_sub -h mosquitto.homelab.local -t sensors/test -u testuser -P securepassword123 -C 1 -W 5
     ```
     - Erwartete Ausgabe: Erfolgreiche Verbindung (leere Ausgabe, da kein Fehler).
   - Prüfe Node-RED:
     - Öffne `http://nodered.homelab.local:1880`, melde dich mit `testuser` und Passwort `securepassword123` an.
     - Erwartete Ausgabe: Zugriff auf die Node-RED-Oberfläche.
   - Prüfe in OPNsense:
     - Gehe zu `Firewall > Rules > LAN`: Regel für `192.168.30.113,192.168.30.114` zu `192.168.30.106:389`.

**Erkenntnis**: Mosquitto und Node-RED können mit OpenLDAP für zentrale Authentifizierung integriert werden, wobei Ansible die Konfiguration vereinfacht.

**Quelle**: https://github.com/jpmens/mosquitto-auth-plug, https://flows.nodered.org/node/node-red-contrib-ldap-auth

## Übung 2: Erstellung von LDAP-Benutzern und -Gruppen mit Ansible

**Ziel**: Erstelle LDAP-Benutzer und -Gruppen für Mosquitto und Node-RED und teste die Authentifizierung.

**Aufgabe**: Erstelle ein Ansible-Playbook, um Benutzer und Gruppen in OpenLDAP hinzuzufügen und in Mosquitto/Node-RED zu testen.

1. **Ansible-Playbook für LDAP-Benutzer und -Gruppen**:
   - Erstelle ein Playbook:
     ```bash
     nano create_ldap_users_groups.yml
     ```
     - Inhalt:
       ```yaml
       - name: Create LDAP users and groups for MQTT and Node-RED
         hosts: openldap_servers
         become: yes
         vars:
           ldap_base_dn: "dc=homelab,dc=local"
           ldap_admin_dn: "cn=admin,dc=homelab,dc=local"
           ldap_admin_password: "securepassword123"
         tasks:
           - name: Create LDAP organizational unit for users
             ansible.builtin.command: >
               ldapadd -x -D "{{ ldap_admin_dn }}" -w "{{ ldap_admin_password }}" -f /tmp/users_ou.ldif
             args:
               creates: /tmp/users_ou.ldif
             vars:
               ldif_content: |
                 dn: ou=users,{{ ldap_base_dn }}
                 objectClass: organizationalUnit
                 ou: users
             delegate_to: localhost
             ansible.builtin.copy:
               dest: /tmp/users_ou.ldif
               content: "{{ ldif_content }}"
           - name: Create LDAP organizational unit for groups
             ansible.builtin.command: >
               ldapadd -x -D "{{ ldap_admin_dn }}" -w "{{ ldap_admin_password }}" -f /tmp/groups_ou.ldif
             args:
               creates: /tmp/groups_ou.ldif
             vars:
               ldif_content: |
                 dn: ou=groups,{{ ldap_base_dn }}
                 objectClass: organizationalUnit
                 ou: groups
             delegate_to: localhost
             ansible.builtin.copy:
               dest: /tmp/groups_ou.ldif
               content: "{{ ldif_content }}"
           - name: Create LDAP group for MQTT and Node-RED users
             ansible.builtin.command: >
               ldapadd -x -D "{{ ldap_admin_dn }}" -w "{{ ldap_admin_password }}" -f /tmp/mqtt_users.ldif
             args:
               creates: /tmp/mqtt_users.ldif
             vars:
               ldif_content: |
                 dn: cn=mqtt_users,ou=groups,{{ ldap_base_dn }}
                 objectClass: groupOfNames
                 cn: mqtt_users
                 member: cn=testuser,ou=users,{{ ldap_base_dn }}
             delegate_to: localhost
             ansible.builtin.copy:
               dest: /tmp/mqtt_users.ldif
               content: "{{ ldif_content }}"
           - name: Create LDAP test user
             ansible.builtin.command: >
               ldapadd -x -D "{{ ldap_admin_dn }}" -w "{{ ldap_admin_password }}" -f /tmp/testuser.ldif
             args:
               creates: /tmp/testuser.ldif
             vars:
               ldif_content: |
                 dn: cn=testuser,ou=users,{{ ldap_base_dn }}
                 objectClass: inetOrgPerson
                 cn: testuser
                 sn: User
                 uid: testuser
                 userPassword: {SSHA}securepassword123
                 mail: testuser@homelab.local
             delegate_to: localhost
             ansible.builtin.copy:
               dest: /tmp/testuser.ldif
               content: "{{ ldif_content }}"
       - name: Test LDAP authentication in Mosquitto
         hosts: mqtt_servers
         become: yes
         tasks:
           - name: Test LDAP user login
             ansible.builtin.command: >
               mosquitto_sub -h mosquitto.homelab.local -t sensors/test -u testuser -P securepassword123 -C 1 -W 5
             register: mqtt_test_result
             ignore_errors: yes
           - name: Display Mosquitto login result
             ansible.builtin.debug:
               msg: "{{ mqtt_test_result.stdout | default('Failed to login, check logs') }}"
       - name: Test LDAP authentication in Node-RED
         hosts: nodered_servers
         become: yes
         tasks:
           - name: Test LDAP user login
             ansible.builtin.command: >
               curl -s -u testuser:securepassword123 http://nodered.homelab.local:1880
             register: nodered_test_result
             ignore_errors: yes
           - name: Display Node-RED login result
             ansible.builtin.debug:
               msg: "{{ nodered_test_result.stdout | default('Failed to login, check logs') }}"
       ```
   - **Erklärung**:
     - Erstellt Organizational Units (`ou=users`, `ou=groups`) in OpenLDAP.
     - Fügt eine Gruppe (`mqtt_users`) und einen Testbenutzer (`testuser`) hinzu.
     - Testet die Authentifizierung in Mosquitto und Node-RED.

2. **Playbook ausführen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml create_ldap_users_groups.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display Mosquitto login result] *******************************************
       ok: [mosquitto] => {
           "msg": ""
       }
       TASK [Display Node-RED login result] ********************************************
       ok: [nodered] => {
           "msg": "<html>... Node-RED dashboard ..."
       }
       ```
   - Teste die Authentifizierung:
     - Mosquitto:
       ```bash
       mosquitto_sub -h mosquitto.homelab.local -t sensors/test -u testuser -P securepassword123 -C 1 -W 5
       ```
       - Erwartete Ausgabe: Erfolgreiche Verbindung (leere Ausgabe).
     - Node-RED:
       - Öffne `http://nodered.homelab.local:1880`, melde dich mit `testuser` und Passwort `securepassword123` an.
       - Erwartete Ausgabe: Zugriff auf die Node-RED-Oberfläche.

**Erkenntnis**: Ansible automatisiert die Erstellung von LDAP-Benutzern und -Gruppen, die für Mosquitto und Node-RED Authentifizierung verwendet werden.

**Quelle**: https://www.turnkeylinux.org/openldap, https://github.com/jpmens/mosquitto-auth-plug

## Übung 3: Backup der Systemkonfigurationen auf TrueNAS

**Ziel**: Sichere die Konfigurationen von Mosquitto, Node-RED, InfluxDB, Grafana und OpenLDAP auf TrueNAS.

**Aufgabe**: Erstelle ein Ansible-Playbook für Backups und begrenze sie auf maximal fünf Versionen.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_mqtt_openldap.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup Mosquitto configuration
         hosts: mqtt_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/mqtt-openldap-integration/backups/mosquitto"
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
               tar -czf /tmp/mosquitto-backup-{{ ansible_date_time.date }}.tar.gz /etc/mosquitto /usr/lib/mosquitto
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
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/mqtt-openldap-integration/
             delegate_to: localhost
           - name: Display Mosquitto backup status
             ansible.builtin.debug:
               msg: "Mosquitto backup saved to {{ backup_file }} and synced to TrueNAS"
       - name: Backup Node-RED configuration
         hosts: nodered_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/mqtt-openldap-integration/backups/nodered"
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
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/mqtt-openldap-integration/
             delegate_to: localhost
           - name: Display Node-RED backup status
             ansible.builtin.debug:
               msg: "Node-RED backup saved to {{ backup_file }} and synced to TrueNAS"
       - name: Backup OpenLDAP configuration and data
         hosts: openldap_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/mqtt-openldap-integration/backups/openldap"
           backup_file: "{{ backup_dir }}/openldap-backup-{{ ansible_date_time.date }}.tar.gz"
         tasks:
           - name: Create backup directory
             ansible.builtin.file:
               path: "{{ backup_dir }}"
               state: directory
               mode: '0755'
             delegate_to: localhost
           - name: Stop OpenLDAP service
             ansible.builtin.service:
               name: slapd
               state: stopped
           - name: Backup OpenLDAP configuration and data
             ansible.builtin.command: >
               tar -czf /tmp/openldap-backup-{{ ansible_date_time.date }}.tar.gz /etc/ldap /var/lib/ldap
             register: backup_result
           - name: Start OpenLDAP service
             ansible.builtin.service:
               name: slapd
               state: started
           - name: Fetch backup file
             ansible.builtin.fetch:
               src: /tmp/openldap-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ backup_file }}"
               flat: yes
           - name: Limit OpenLDAP backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t openldap-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync OpenLDAP backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/mqtt-openldap-integration/
             delegate_to: localhost
           - name: Display OpenLDAP backup status
             ansible.builtin.debug:
               msg: "OpenLDAP backup saved to {{ backup_file }} and synced to TrueNAS"
       ```
   - **Erklärung**:
     - Sichert Mosquitto (`/etc/mosquitto`, `/usr/lib/mosquitto`), Node-RED (`/root/.node-red`) und OpenLDAP (`/etc/ldap`, `/var/lib/ldap`).
     - Stoppt Dienste (`mosquitto`, `nodered`, `slapd`), um konsistente Backups zu gewährleisten.
     - Begrenzt Backups auf fünf Versionen pro Dienst.
     - Synchronisiert Backups mit TrueNAS.

2. **Playbook testen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_mqtt_openldap.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display Mosquitto backup status] ******************************************
       ok: [mosquitto] => {
           "msg": "Mosquitto backup saved to /home/ubuntu/mqtt-openldap-integration/backups/mosquitto/mosquitto-backup-<date>.tar.gz and synced to TrueNAS"
       }
       TASK [Display Node-RED backup status] *******************************************
       ok: [nodered] => {
           "msg": "Node-RED backup saved to /home/ubuntu/mqtt-openldap-integration/backups/nodered/nodered-backup-<date>.tar.gz and synced to TrueNAS"
       }
       TASK [Display OpenLDAP backup status] *******************************************
       ok: [ldap] => {
           "msg": "OpenLDAP backup saved to /home/ubuntu/mqtt-openldap-integration/backups/openldap/openldap-backup-<date>.tar.gz and synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/mqtt-openldap-integration/
     ```
     - Erwartete Ausgabe: Maximal fünf Backups pro Dienst (`mosquitto-backup-<date>.tar.gz`, `nodered-backup-<date>.tar.gz`, `openldap-backup-<date>.tar.gz`).

3. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/mqtt-openldap-integration
       ansible-playbook -i inventory.yml backup_mqtt_openldap.yml >> backup.log 2>&1
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
       0 3 * * * /home/ubuntu/mqtt-openldap-integration/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible automatisiert die Sicherung der MQTT- und OpenLDAP-Konfigurationen, während TrueNAS externe Speicherung bietet.

## Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass die Firewall-Regeln aktiv sind (siehe Übung 1).
   - Prüfe OPNsense-Logs:
     ```bash
     ansible-playbook -i inventory.yml -m ansible.builtin.command -a "cat /var/log/system/latest.log" opnsense
     ```

2. **Monitoring mit Checkmk (optional)**:
   - Konfiguriere Checkmk für die LDAP-Integration:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Füge eine benutzerdefinierte Überprüfung für die LDAP-Integration hinzu:
       ```bash
       nano /omd/sites/homelab/local/share/check_mk/checks/mqtt_ldap
       ```
       - Inhalt:
         ```bash
         #!/bin/bash
         mosquitto_sub -h mosquitto.homelab.local -t sensors/test -u testuser -P securepassword123 -C 1 -W 5 > /dev/null
         if [ $? -eq 0 ]; then
           echo "0 MQTT_LDAP - MQTT LDAP authentication is operational"
         else
           echo "2 MQTT_LDAP - MQTT LDAP authentication is not operational"
         fi
         ```
       - Ausführbar machen:
         ```bash
         chmod +x /omd/sites/homelab/local/share/check_mk/checks/mqtt_ldap
         ```
       - In Checkmk: `Setup > Services > Manual checks > Custom checks`, füge `MQTT_LDAP` hinzu.

## Schritt 5: Erweiterung der Übungen
1. **Erweiterte LDAP-Konfiguration**:
   - Erstelle ein Playbook, um weitere Benutzer hinzuzufügen:
     ```bash
     nano add_ldap_user.yml
     ```
     - Inhalt:
       ```yaml
       - name: Add additional LDAP user for MQTT and Node-RED
         hosts: openldap_servers
         become: yes
         vars:
           ldap_base_dn: "dc=homelab,dc=local"
           ldap_admin_dn: "cn=admin,dc=homelab,dc=local"
           ldap_admin_password: "securepassword123"
           new_user: "newuser"
           new_user_password: "SecurePass123!"
           new_user_email: "newuser@homelab.local"
         tasks:
           - name: Create new LDAP user
             ansible.builtin.command: >
               ldapadd -x -D "{{ ldap_admin_dn }}" -w "{{ ldap_admin_password }}" -f /tmp/newuser.ldif
             args:
               creates: /tmp/newuser.ldif
             vars:
               ldif_content: |
                 dn: cn={{ new_user }},ou=users,{{ ldap_base_dn }}
                 objectClass: inetOrgPerson
                 cn: {{ new_user }}
                 sn: User
                 uid: {{ new_user }}
                 userPassword: {SSHA}{{ new_user_password }}
                 mail: {{ new_user_email }}
             delegate_to: localhost
             ansible.builtin.copy:
               dest: /tmp/newuser.ldif
               content: "{{ ldif_content }}"
           - name: Add user to MQTT group
             ansible.builtin.command: >
               ldapmodify -x -D "{{ ldap_admin_dn }}" -w "{{ ldap_admin_password }}" -f /tmp/add_to_group.ldif
             args:
               creates: /tmp/add_to_group.ldif
             vars:
               ldif_content: |
                 dn: cn=mqtt_users,ou=groups,{{ ldap_base_dn }}
                 changetype: modify
                 add: member
                 member: cn={{ new_user }},ou=users,{{ ldap_base_dn }}
             delegate_to: localhost
             ansible.builtin.copy:
               dest: /tmp/add_to_group.ldif
               content: "{{ ldif_content }}"
       ```

2. **Backup-Versionierung mit Git**:
   - Initialisiere ein Git-Repository für Backups:
     ```bash
     cd ~/mqtt-openldap-integration/backups
     git init
     git add .
     git commit -m "Initial MQTT and OpenLDAP backup"
     ```

## Best Practices für Schüler

- **MQTT-LDAP-Design**:
  - Nutze einfache LDAP-Filter (z. B. `objectClass=inetOrgPerson`) für Benutzer.
  - Teste die LDAP-Konfiguration mit MQTT Explorer (`mosquitto.homelab.local:1883`) und der Node-RED-Weboberfläche (`http://nodered.homelab.local:1880`).
- **Sicherheit**:
  - Schränke LDAP-Zugriff ein:
    ```bash
    ssh root@192.168.30.113 "ufw allow from 192.168.30.113 to 192.168.30.106 port 389 proto tcp"
    ssh root@192.168.30.114 "ufw allow from 192.168.30.114 to 192.168.30.106 port 389 proto tcp"
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
  - Verwende LDAPS (Port 636) für Produktionsumgebungen:
    ```bash
    ssh root@192.168.30.106 "turnkey-letsencrypt ldap.homelab.local"
    ```
    - Aktualisiere `ldap_port` in `configure_mqtt_nodered_ldap.yml` auf `636`.
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
  - Teste Backups vor Updates (siehe https://mosquitto.org, https://nodered.org/docs, https://www.turnkeylinux.org/openldap).
- **Fehlerbehebung**:
  - Prüfe Mosquitto-Logs:
    ```bash
    ssh root@192.168.30.113 "cat /var/log/mosquitto/mosquitto.log"
    ```
  - Prüfe Node-RED-Logs:
    ```bash
    ssh root@192.168.30.114 "cat /root/.node-red/.log"
    ```
  - Prüfe OpenLDAP-Logs:
    ```bash
    ssh root@192.168.30.106 "cat /var/log/syslog | grep slapd"
    ```
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/mqtt-openldap-integration/backup.log
    ```

**Quellen**: https://mosquitto.org, https://nodered.org/docs, https://www.turnkeylinux.org/openldap, https://github.com/jpmens/mosquitto-auth-plug, https://flows.nodered.org/node/node-red-contrib-ldap-auth

## Empfehlungen für Schüler

- **Setup**: Mosquitto, Node-RED, OpenLDAP, Proxmox LXC, Ansible, TrueNAS-Backups.
- **Workloads**: LDAP-Integration, Benutzer-/Gruppenverwaltung, Backups.
- **Integration**: Proxmox (LXC), TrueNAS (Backups), OPNsense (DNS, Netzwerk).
- **Beispiel**: Zentrale Authentifizierung für MQTT-Clients und Node-RED-Nutzer im HomeLab.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einem Testbenutzer, erweitere zu Gruppen und Rollen.
- **Übung**: Teste die Authentifizierung mit MQTT Explorer (`mosquitto.homelab.local:1883`) und Node-RED (`http://nodered.homelab.local:1880`).
- **Fehlerbehebung**: Nutze `ldapsearch` für Tests:
  ```bash
  ssh root@192.168.30.106 "ldapsearch -x -H ldap://ldap.homelab.local -D 'cn=admin,dc=homelab,dc=local' -w securepassword123 -b 'dc=homelab,dc=local' '(uid=testuser)'"
  ```
- **Lernressourcen**: https://mosquitto.org, https://nodered.org/docs, https://www.turnkeylinux.org/openldap, https://docs.ansible.com.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Schnelle Integration von Mosquitto und Node-RED mit OpenLDAP für Authentifizierung.
- **Skalierbarkeit**: Automatisierte Benutzer-/Gruppenverwaltung und Backup-Konfigurationen.
- **Lernwert**: Verständnis von LDAP-Authentifizierung in MQTT-Systemen.

**Nächste Schritte**: Möchtest du eine Anleitung zur Erweiterung des Node-RED-Flows, Integration mit weiteren Diensten (z. B. Home Assistant), oder Monitoring mit Wazuh/Fluentd/Checkmk?

**Quellen**:
- Mosquitto-Dokumentation: https://mosquitto.org
- Node-RED-Dokumentation: https://nodered.org/docs
- OpenLDAP-Dokumentation: https://www.turnkeylinux.org/openldap
- Ansible-Dokumentation: https://docs.ansible.com
- Mosquitto Auth Plugin: https://github.com/jpmens/mosquitto-auth-plug
- Node-RED LDAP Auth: https://flows.nodered.org/node/node-red-contrib-ldap-auth
- Webquellen: https://mosquitto.org, https://nodered.org/docs, https://www.turnkeylinux.org/openldap
```