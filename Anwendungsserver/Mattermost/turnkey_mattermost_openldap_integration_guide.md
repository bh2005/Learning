# Lernprojekt: Integration von TurnKey Linux Mattermost mit OpenLDAP für Authentifizierung

## Vorbereitung: Umgebung prüfen
1. **Mattermost-Server prüfen**:
   - Verbinde dich mit dem Mattermost LXC-Container:
     ```bash
     ssh root@192.168.30.108
     ```
   - Stelle sicher, dass Mattermost läuft:
     ```bash
     systemctl status mattermost
     ```
     - Erwartete Ausgabe: `active (running)`.
   - Teste die Weboberfläche:
     ```bash
     curl https://mattermost.homelab.local
     ```
     - Erwartete Ausgabe: HTML der Mattermost-Startseite oder Anmeldeseite.
   - Prüfe die Mattermost-Version:
     ```bash
     /opt/mattermost/bin/mattermost version
     ```
     - Erwartete Ausgabe: z. B. `Version: 9.0.1` (je nach Version, siehe https://www.turnkeylinux.org/mattermost).[](https://www.turnkeylinux.org/updates/mattermost)
2. **OpenLDAP-Server prüfen**:
   - Verbinde dich mit dem OpenLDAP LXC-Container:
     ```bash
     ssh root@192.168.30.106
     ```
   - Stelle sicher, dass OpenLDAP läuft:
     ```bash
     systemctl status slapd
     ```
     - Erwartete Ausgabe: `active (running)`.
   - Teste die LDAP-Verbindung:
     ```bash
     ldapsearch -x -H ldap://192.168.30.106 -b "dc=homelab,dc=local" -D "cn=admin,dc=homelab,dc=local" -w securepassword123
     ```
     - Erwartete Ausgabe: LDAP-Directory-Einträge (z. B. `ou=Users`, `ou=Groups`).
3. **Ansible-Umgebung prüfen**:
   - Auf der Ubuntu-VM (`192.168.30.101`):
     ```bash
     ssh ubuntu@192.168.30.101
     ansible --version
     ```
   - Stelle sicher, dass SSH-Zugriff auf Mattermost, OpenLDAP und OPNsense möglich ist:
     ```bash
     ssh root@192.168.30.108
     ssh root@192.168.30.106
     ssh root@192.168.30.1
     ```
4. **Projektverzeichnis erstellen**:
   - Auf `192.168.30.101`:
     ```bash
     mkdir ~/turnkey-mattermost-openldap-integration
     cd ~/turnkey-mattermost-openldap-integration
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Mattermost (`192.168.30.108`), OpenLDAP (`192.168.30.106`), OPNsense (`192.168.30.1`) und TrueNAS (`192.168.30.100`).

## Übung 1: Konfiguration von Mattermost für OpenLDAP-Authentifizierung

**Ziel**: Konfiguriere den TurnKey Mattermost-Server, um OpenLDAP als Authentifizierungs-Backend zu nutzen.

**Aufgabe**: Verwende Ansible, um die Mattermost-Konfiguration (`config.json`) für LDAP-Authentifizierung anzupassen und die Verbindung zu OpenLDAP zu testen.

1. **Ansible-Inventar erstellen**:
   - Erstelle eine Inventar-Datei:
     ```bash
     nano inventory.yml
     ```
     - Inhalt:
       ```yaml
       all:
         children:
           mattermost_servers:
             hosts:
               mattermost:
                 ansible_host: 192.168.30.108
                 ansible_user: root
                 ansible_connection: ssh
                 ansible_python_interpreter: /usr/bin/python3
           ldap_servers:
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

2. **Ansible-Playbook für Mattermost-OpenLDAP-Integration**:
   - Erstelle ein Playbook:
     ```bash
     nano configure_mattermost_openldap.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure Mattermost for OpenLDAP authentication
         hosts: mattermost_servers
         become: yes
         vars:
           ldap_server: "ldap://192.168.30.106"
           ldap_base: "dc=homelab,dc=local"
           ldap_bind_dn: "cn=admin,dc=homelab,dc=local"
           ldap_bind_password: "securepassword123"
           mattermost_config: "/opt/mattermost/config/config.json"
         tasks:
           - name: Install LDAP utilities
             ansible.builtin.apt:
               name: ldap-utils
               state: present
               update_cache: yes
           - name: Backup original Mattermost config
             ansible.builtin.copy:
               src: "{{ mattermost_config }}"
               dest: "{{ mattermost_config }}.bak"
               remote_src: yes
           - name: Configure Mattermost for LDAP authentication
             ansible.builtin.blockinfile:
               path: "{{ mattermost_config }}"
               marker: "/* {mark} LDAP Authentication Settings */"
               block: |
                 "LdapSettings": {
                   "Enable": true,
                   "LdapServer": "192.168.30.106",
                   "LdapPort": 389,
                   "ConnectionSecurity": "",
                   "BaseDN": "{{ ldap_base }}",
                   "BindId": "{{ ldap_bind_dn }}",
                   "BindPassword": "{{ ldap_bind_password }}",
                   "UserFilter": "(objectClass=posixAccount)",
                   "FirstNameAttribute": "givenName",
                   "LastNameAttribute": "sn",
                   "EmailAttribute": "mail",
                   "UsernameAttribute": "uid",
                   "IdAttribute": "uid",
                   "LoginIdAttribute": "uid",
                   "SyncIntervalMinutes": 60
                 }
           - name: Restart Mattermost service
             ansible.builtin.service:
               name: mattermost
               state: restarted
           - name: Test LDAP connection from Mattermost server
             ansible.builtin.command: >
               ldapsearch -x -H {{ ldap_server }} -b "{{ ldap_base }}" -D "{{ ldap_bind_dn }}" -w {{ ldap_bind_password }}
             register: ldap_test
           - name: Display LDAP test result
             ansible.builtin.debug:
               msg: "{{ ldap_test.stdout }}"
       ```
   - **Erklärung**:
     - Installiert `ldap-utils` für LDAP-Verbindungstests.
     - Sichert die ursprüngliche `config.json`-Datei.
     - Konfiguriert Mattermost für LDAP-Authentifizierung durch Hinzufügen von LDAP-Parametern.
     - Startet den Mattermost-Dienst neu und testet die LDAP-Verbindung.

3. **Playbook ausführen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml configure_mattermost_openldap.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display LDAP test result] *************************************************
       ok: [mattermost] => {
           "msg": "... dn: dc=homelab,dc=local ..."
       }
       ```
   - Prüfe die Mattermost-Systemkonsole:
     - Öffne `https://192.168.30.108` im Browser, melde dich als Admin an.
     - Gehe zu `System Console > Authentication > LDAP`.
     - Erwartete Ausgabe: LDAP-Einstellungen wie oben konfiguriert.
     - Teste die LDAP-Verbindung in der Systemkonsole: Klicke auf `Test Connection`.

**Erkenntnis**: Mattermost unterstützt OpenLDAP-Authentifizierung durch einfache Konfiguration in `config.json`, was eine zentrale Benutzerverwaltung ermöglicht.[](https://docs.mattermost.com/deployment-guide/server/deploy-linux.html)

**Quelle**: https://docs.mattermost.com/deployment/ldap.html

## Übung 2: Hinzufügen eines LDAP-Benutzers für Mattermost-Zugriff

**Ziel**: Füge einen Benutzer in OpenLDAP hinzu und teste den Zugriff auf Mattermost.

**Aufgabe**: Erstelle ein Ansible-Playbook, um einen Testbenutzer in OpenLDAP zu erstellen und dessen Authentifizierung in Mattermost zu verifizieren.

1. **Ansible-Playbook für Benutzererstellung**:
   - Erstelle ein Playbook:
     ```bash
     nano add_ldap_user.yml
     ```
     - Inhalt:
       ```yaml
       - name: Add LDAP user for Mattermost
         hosts: ldap_servers
         become: yes
         vars:
           ldap_user: "testuser"
           ldap_password: "SecurePass123!"
           ldap_domain: "dc=homelab,dc=local"
         tasks:
           - name: Create LDIF file for user
             ansible.builtin.copy:
               dest: /tmp/add_user.ldif
               content: |
                 dn: uid={{ ldap_user }},ou=Users,{{ ldap_domain }}
                 objectClass: top
                 objectClass: person
                 objectClass: posixAccount
                 objectClass: inetOrgPerson
                 cn: Test User
                 sn: User
                 givenName: Test
                 mail: testuser@homelab.local
                 uid: {{ ldap_user }}
                 uidNumber: 1001
                 gidNumber: 1001
                 homeDirectory: /home/{{ ldap_user }}
                 userPassword: {SSHA}{{ ldap_password | password_hash('ssha') }}
           - name: Add user to OpenLDAP
             ansible.builtin.command: >
               ldapadd -x -D "cn=admin,{{ ldap_domain }}" -w securepassword123 -f /tmp/add_user.ldif
             register: ldap_user_result
           - name: Verify user in LDAP
             ansible.builtin.command: >
               ldapsearch -x -H ldap://192.168.30.106 -b "uid={{ ldap_user }},ou=Users,{{ ldap_domain }}" -D "cn=admin,{{ ldap_domain }}" -w securepassword123
             register: ldap_verify
           - name: Display user creation status
             ansible.builtin.debug:
               msg: "{{ ldap_verify.stdout }}"
       ```
   - **Erklärung**:
     - Erstellt einen Benutzer (`testuser`) in OpenLDAP mit einem LDIF-File, inklusive `mail`-Attribut für Mattermost.
     - Verwendet `password_hash('ssha')` für sicheres Passwort-Hashing.
     - Verifiziert den Benutzer in OpenLDAP.

2. **Playbook ausführen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml add_ldap_user.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display user creation status] *************************************************
       ok: [ldap] => {
           "msg": "... uid=testuser,ou=Users,dc=homelab,dc=local ..."
       }
       ```
   - Prüfe in phpLDAPadmin:
     - Öffne `https://192.168.30.106/phpldapadmin`, melde dich an (`cn=admin,dc=homelab,dc=local`, `securepassword123`).
     - Erwartete Ausgabe: Benutzer `uid=testuser,ou=Users,dc=homelab,dc=local`.
   - Teste die Anmeldung in Mattermost:
     - Öffne `https://192.168.30.108`.
     - Melde dich mit `testuser` und `SecurePass123!` an.
     - Erwartete Ausgabe: Erfolgreicher Zugriff auf Mattermost, Benutzer wird in der Systemkonsole (`Users`) angezeigt.

**Erkenntnis**: Ein in OpenLDAP erstellter Benutzer mit den erforderlichen Attributen (z. B. `uid`, `mail`) kann sich erfolgreich in Mattermost anmelden.

**Quelle**: https://www.openldap.org/doc/admin26/slapd.d.html

## Übung 3: Backup der integrierten Umgebung auf TrueNAS

**Ziel**: Sichere die Konfigurationen und Datenbanken von Mattermost und OpenLDAP und versioniere sie auf TrueNAS.

**Aufgabe**: Erstelle ein Ansible-Playbook für Backups beider Systeme und begrenze sie auf maximal fünf Versionen.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_mattermost_openldap.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup TurnKey Mattermost and OpenLDAP
         hosts: all
         become: yes
         vars:
           backup_dir: "/home/ubuntu/turnkey-mattermost-openldap-integration/backups"
           mattermost_backup_file: "{{ backup_dir }}/mattermost-backup-{{ ansible_date_time.date }}.tar.gz"
           ldap_backup_file: "{{ backup_dir }}/ldap-backup-{{ ansible_date_time.date }}.tar.gz"
         tasks:
           - name: Create backup directory
             ansible.builtin.file:
               path: "{{ backup_dir }}"
               state: directory
               mode: '0755'
             delegate_to: localhost
           - name: Stop Mattermost service
             ansible.builtin.service:
               name: mattermost
               state: stopped
             when: inventory_hostname == 'mattermost'
           - name: Backup Mattermost configuration and database
             ansible.builtin.command: >
               tar -czf /tmp/mattermost-backup-{{ ansible_date_time.date }}.tar.gz /opt/mattermost /var/lib/postgresql
             when: inventory_hostname == 'mattermost'
           - name: Start Mattermost service
             ansible.builtin.service:
               name: mattermost
               state: started
             when: inventory_hostname == 'mattermost'
           - name: Stop OpenLDAP service
             ansible.builtin.service:
               name: slapd
               state: stopped
             when: inventory_hostname == 'ldap'
           - name: Backup OpenLDAP configuration and data
             ansible.builtin.command: >
               tar -czf /tmp/ldap-backup-{{ ansible_date_time.date }}.tar.gz /etc/ldap /var/lib/ldap
             when: inventory_hostname == 'ldap'
           - name: Start OpenLDAP service
             ansible.builtin.service:
               name: slapd
               state: started
             when: inventory_hostname == 'ldap'
           - name: Fetch Mattermost backup file
             ansible.builtin.fetch:
               src: /tmp/mattermost-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ mattermost_backup_file }}"
               flat: yes
             when: inventory_hostname == 'mattermost'
           - name: Fetch OpenLDAP backup file
             ansible.builtin.fetch:
               src: /tmp/ldap-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ ldap_backup_file }}"
               flat: yes
             when: inventory_hostname == 'ldap'
           - name: Limit Mattermost backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t mattermost-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
             when: inventory_hostname == 'mattermost'
           - name: Limit OpenLDAP backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t ldap-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
             when: inventory_hostname == 'ldap'
           - name: Sync backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/turnkey-mattermost-openldap-integration/
             delegate_to: localhost
           - name: Display backup status
             ansible.builtin.debug:
               msg: "Backups saved to {{ backup_dir }} and synced to TrueNAS"
       ```
   - **Erklärung**:
     - Stoppt die Dienste (`mattermost`, `slapd`), um konsistente Backups zu gewährleisten.
     - Sichert `/opt/mattermost`, `/var/lib/postgresql` (Mattermost) und `/etc/ldap`, `/var/lib/ldap` (OpenLDAP).
     - Begrenzt Backups auf fünf pro System durch Entfernen älterer Dateien.
     - Synchronisiert Backups mit TrueNAS.

2. **Playbook testen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_mattermost_openldap.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display backup status] ****************************************************
       ok: [mattermost] => {
           "msg": "Backups saved to /home/ubuntu/turnkey-mattermost-openldap-integration/backups and synced to TrueNAS"
       }
       ok: [ldap] => {
           "msg": "Backups saved to /home/ubuntu/turnkey-mattermost-openldap-integration/backups and synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/turnkey-mattermost-openldap-integration/
     ```
     - Erwartete Ausgabe: Maximal fünf `mattermost-backup-<date>.tar.gz` und fünf `ldap-backup-<date>.tar.gz`.

3. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/turnkey-mattermost-openldap-integration
       ansible-playbook -i inventory.yml backup_mattermost_openldap.yml >> backup.log 2>&1
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
       0 3 * * * /home/ubuntu/turnkey-mattermost-openldap-integration/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible automatisiert die Sicherung beider Systeme, während TrueNAS externe Speicherung bietet.[](https://aws.amazon.com/marketplace/pp/prodview-h24kkjdfu4xoy)

**Quelle**: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/fetch_module.html

## Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass die Firewall-Regeln für Mattermost (Ports 80, 443, 8065) und OpenLDAP (Ports 389, 636, 443) aktiv sind.
   - Erstelle ein Playbook für Firewall-Regeln:
     ```bash
     nano configure_firewall_mattermost.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure OPNsense firewall for Mattermost and OpenLDAP
         hosts: network_devices
         tasks:
           - name: Add firewall rule for Mattermost HTTP/HTTPS (80, 443)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.108",
                 "destination_port":"80,443",
                 "description":"Allow HTTP/HTTPS to Mattermost Server"
               }'
           - name: Add firewall rule for Mattermost Admin Console (8065)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.108",
                 "destination_port":"8065",
                 "description":"Allow Mattermost Admin Console"
               }'
           - name: Verify firewall rules
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Display firewall rules
             ansible.builtin.debug:
               msg: "{{ rules_list.stdout }}"
       ```
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml configure_firewall_mattermost.yml
     ```

2. **Monitoring mit Checkmk (optional)**:
   - Konfiguriere Checkmk für beide Server:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Stelle sicher, dass `mattermost` (`192.168.30.108`) und `ldap` (`192.168.30.106`) als Hosts hinzugefügt sind.
     - Prüfe Services:
       - Gehe zu `Monitor > All services`.
       - Erwartete Ausgabe: Services wie `mattermost`, `slapd`, `nginx`, `postgresql`.
     - Erstelle eine benutzerdefinierte Überprüfung für die LDAP-Integration:
       ```bash
       nano /omd/sites/homelab/local/share/check_mk/checks/mattermost_ldap
       ```
       - Inhalt:
         ```bash
         #!/bin/bash
         curl -s -u testuser:SecurePass123! https://192.168.30.108/api/v4/users/me > /dev/null
         if [ $? -eq 0 ]; then
           echo "0 Mattermost_LDAP - LDAP authentication is operational"
         else
           echo "2 Mattermost_LDAP - LDAP authentication is not operational"
         fi
         ```
       - Ausführbar machen:
         ```bash
         chmod +x /omd/sites/homelab/local/share/check_mk/checks/mattermost_ldap
         ```
       - In Checkmk: `Setup > Services > Manual checks > Custom checks`, füge `Mattermost_LDAP` hinzu.

## Schritt 5: Erweiterung der Übungen
1. **Erweiterte Benutzer- und Gruppenverwaltung**:
   - Erstelle ein Playbook, um eine LDAP-Gruppe für Mattermost-Zugriff zu erstellen:
     ```bash
     nano add_ldap_group.yml
     ```
     - Inhalt:
       ```yaml
       - name: Add LDAP group for Mattermost
         hosts: ldap_servers
         become: yes
         vars:
           ldap_group: "mattermost_users"
           ldap_domain: "dc=homelab,dc=local"
         tasks:
           - name: Create LDIF file for group
             ansible.builtin.copy:
               dest: /tmp/add_group.ldif
               content: |
                 dn: cn={{ ldap_group }},ou=Groups,{{ ldap_domain }}
                 objectClass: top
                 objectClass: posixGroup
                 cn: {{ ldap_group }}
                 gidNumber: 2001
                 memberUid: testuser
           - name: Add group to OpenLDAP
             ansible.builtin.command: >
               ldapadd -x -D "cn=admin,{{ ldap_domain }}" -w securepassword123 -f /tmp/add_group.ldif
             register: ldap_group_result
           - name: Display group creation status
             ansible.builtin.debug:
               msg: "{{ ldap_group_result.stdout }}"
       ```

2. **Backup-Versionierung mit Git**:
   - Initialisiere ein Git-Repository für Backups:
     ```bash
     cd ~/turnkey-mattermost-openldap-integration/backups
     git init
     git add .
     git commit -m "Initial Mattermost and OpenLDAP backup"
     ```

## Best Practices für Schüler

- **Integration-Design**:
  - Verwende `ldaps` (Port 636) für sichere LDAP-Verbindungen, indem du `ConnectionSecurity: TLS` in `config.json` setzt.
  - Nutze Gruppen in OpenLDAP für rollenbasierte Zugriffssteuerung in Mattermost.
- **Sicherheit**:
  - Schränke Zugriff ein:
    ```bash
    ssh root@192.168.30.108 "ufw allow from 192.168.30.0/24 to any port 80,443,8065"
    ssh root@192.168.30.106 "ufw allow from 192.168.30.0/24 to any port 389,636,443"
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
  - Ersetze selbstsignierte Zertifikate durch Let’s Encrypt:
    ```bash
    ssh root@192.168.30.108 "turnkey-letsencrypt mattermost.homelab.local"
    ```
    - Siehe https://www.turnkeylinux.org/mattermost für Details.[](https://www.turnkeylinux.org/forum/support/20160811/replacing-self-signed-mattermost-ssl-certificates)
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
  - Beachte, dass Mattermost-Backups vor Updates getestet werden sollten (siehe https://www.turnkeylinux.org/mattermost).[](https://www.turnkeylinux.org/mattermost)
- **Fehlerbehebung**:
  - Prüfe Mattermost-Logs:
    ```bash
    ssh root@192.168.30.108 "cat /opt/mattermost/logs/mattermost.log"
    ```
  - Prüfe OpenLDAP-Logs:
    ```bash
    ssh root@192.168.30.106 "cat /var/log/ldap.log"
    ```
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/turnkey-mattermost-openldap-integration/backup.log
    ```

**Quelle**: https://www.turnkeylinux.org/mattermost, https://docs.mattermost.com/deployment/ldap.html, https://www.openldap.org/doc/

## Empfehlungen für Schüler

- **Setup**: TurnKey Mattermost, OpenLDAP, Ansible, TrueNAS-Backups.
- **Workloads**: LDAP-Authentifizierung, Benutzererstellung, Backups.
- **Integration**: Proxmox (LXC), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Zentrale Authentifizierung für Team-Kommunikation.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einem einzelnen LDAP-Benutzer, erweitere zu Gruppen und Rollen.
- **Übung**: Teste die Authentifizierung mit Mattermost-Desktop- oder Mobile-Apps (siehe https://mattermost.com/download/).[](https://mattermost.com/apps/)
- **Fehlerbehebung**: Nutze `ansible-playbook --check`, `ldapsearch` und die Mattermost-Systemkonsole.
- **Lernressourcen**: https://www.turnkeylinux.org/mattermost, https://docs.mattermost.com/deployment/ldap.html, https://docs.ansible.com.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Integration von Mattermost mit OpenLDAP für zentrale Authentifizierung.
- **Skalierbarkeit**: Automatisierte Konfiguration und Backup-Prozesse.
- **Lernwert**: Verständnis von LDAP-basierter Authentifizierung und HomeLab-Integration.

**Nächste Schritte**: Möchtest du eine Anleitung zur Integration mit Wazuh für Sicherheitsüberwachung, Log-Aggregation mit Fluentd, oder erweitertem Monitoring mit Checkmk?

**Quellen**:
- TurnKey Linux Mattermost-Dokumentation: https://www.turnkeylinux.org/mattermost
- Mattermost LDAP-Dokumentation: https://docs.mattermost.com/deployment/ldap.html
- OpenLDAP-Dokumentation: https://www.openldap.org/doc/
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen: https://www.turnkeylinux.org/mattermost, https://docs.mattermost.com/deployment/ldap.html
```