# Lernprojekt: Integration von TurnKey Linux Etherpad mit OpenLDAP für Authentifizierung

## Vorbereitung: Umgebung prüfen
1. **Etherpad-Server prüfen**:
   - Verbinde dich mit dem Etherpad LXC-Container:
     ```bash
     ssh root@192.168.30.107
     ```
   - Stelle sicher, dass Etherpad läuft:
     ```bash
     systemctl status etherpad
     ```
     - Erwartete Ausgabe: `active (running)`.
   - Teste die Weboberfläche:
     ```bash
     curl https://etherpad.homelab.local
     ```
     - Erwartete Ausgabe: HTML der Etherpad-Startseite.
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
   - Stelle sicher, dass SSH-Zugriff auf Etherpad, OpenLDAP und OPNsense möglich ist:
     ```bash
     ssh root@192.168.30.107
     ssh root@192.168.30.106
     ssh root@192.168.30.1
     ```
4. **Projektverzeichnis erstellen**:
   - Auf `192.168.30.101`:
     ```bash
     mkdir ~/turnkey-etherpad-openldap-integration
     cd ~/turnkey-etherpad-openldap-integration
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Etherpad (`192.168.30.107`), OpenLDAP (`192.168.30.106`), OPNsense (`192.168.30.1`) und TrueNAS (`192.168.30.100`).

## Übung 1: Konfiguration von Etherpad für OpenLDAP-Authentifizierung

**Ziel**: Konfiguriere den TurnKey Etherpad-Server, um OpenLDAP als Authentifizierungs-Backend zu nutzen.

**Aufgabe**: Verwende Ansible, um das `ep_ldap`-Plugin zu installieren und die Etherpad-Konfiguration (`settings.json`) für LDAP-Authentifizierung anzupassen.

1. **Ansible-Inventar erstellen**:
   - Erstelle eine Inventar-Datei:
     ```bash
     nano inventory.yml
     ```
     - Inhalt:
       ```yaml
       all:
         children:
           etherpad_servers:
             hosts:
               etherpad:
                 ansible_host: 192.168.30.107
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

2. **Ansible-Playbook für Etherpad-OpenLDAP-Integration**:
   - Erstelle ein Playbook:
     ```bash
     nano configure_etherpad_openldap.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure Etherpad for OpenLDAP authentication
         hosts: etherpad_servers
         become: yes
         vars:
           ldap_server: "ldap://192.168.30.106"
           ldap_base: "dc=homelab,dc=local"
           ldap_bind_dn: "cn=admin,dc=homelab,dc=local"
           ldap_bind_password: "securepassword123"
           etherpad_config: "/etc/etherpad/settings.json"
         tasks:
           - name: Install Node.js and npm
             ansible.builtin.apt:
               name: "{{ item }}"
               state: present
               update_cache: yes
             loop:
               - nodejs
               - npm
           - name: Install ep_ldap plugin
             ansible.builtin.command: >
               npm install ep_ldap --prefix /usr/share/etherpad
             args:
               creates: /usr/share/etherpad/node_modules/ep_ldap
           - name: Backup original Etherpad settings
             ansible.builtin.copy:
               src: "{{ etherpad_config }}"
               dest: "{{ etherpad_config }}.bak"
               remote_src: yes
           - name: Configure Etherpad for LDAP authentication
             ansible.builtin.blockinfile:
               path: "{{ etherpad_config }}"
               marker: "// {mark} LDAP Authentication Settings"
               block: |
                 "users": {
                   "ldap": {
                     "url": "{{ ldap_server }}",
                     "base": "{{ ldap_base }}",
                     "bindDN": "{{ ldap_bind_dn }}",
                     "bindPW": "{{ ldap_bind_password }}",
                     "filter": "(objectClass=posixAccount)",
                     "usernameField": "uid"
                   }
                 },
                 "authentication": {
                   "method": "ldap"
                 }
           - name: Restart Etherpad service
             ansible.builtin.service:
               name: etherpad
               state: restarted
           - name: Test LDAP connection
             ansible.builtin.command: >
               ldapsearch -x -H {{ ldap_server }} -b "{{ ldap_base }}" -D "{{ ldap_bind_dn }}" -w {{ ldap_bind_password }}
             register: ldap_test
             delegate_to: 192.168.30.107
           - name: Display LDAP test result
             ansible.builtin.debug:
               msg: "{{ ldap_test.stdout }}"
       ```
   - **Erklärung**:
     - Installiert `nodejs` und `npm` für die Plugin-Installation.
     - Installiert das `ep_ldap`-Plugin für Etherpad.
     - Sichert die ursprüngliche `settings.json`-Datei.
     - Konfiguriert Etherpad für LDAP-Authentifizierung durch Hinzufügen von LDAP-Parametern.
     - Startet den Etherpad-Dienst neu und testet die LDAP-Verbindung.

3. **Playbook ausführen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml configure_etherpad_openldap.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display LDAP test result] *************************************************
       ok: [etherpad] => {
           "msg": "... dn: dc=homelab,dc=local ..."
       }
       ```
   - Prüfe die Etherpad-Weboberfläche:
     - Öffne `https://192.168.30.107` im Browser.
     - Versuche, dich mit einem LDAP-Benutzer anzumelden (wird in Übung 2 erstellt).
     - Erwartete Ausgabe: Anmeldeaufforderung, die LDAP-Benutzer akzeptiert.

**Erkenntnis**: Das `ep_ldap`-Plugin ermöglicht die Integration von Etherpad mit OpenLDAP für zentrale Authentifizierung.

**Quelle**: https://www.npmjs.com/package/ep_ldap

## Übung 2: Hinzufügen eines LDAP-Benutzers für Etherpad-Zugriff

**Ziel**: Füge einen Benutzer in OpenLDAP hinzu und teste den Zugriff auf Etherpad.

**Aufgabe**: Erstelle ein Ansible-Playbook, um einen Testbenutzer in OpenLDAP zu erstellen und dessen Authentifizierung in Etherpad zu verifizieren.

1. **Ansible-Playbook für Benutzererstellung**:
   - Erstelle ein Playbook:
     ```bash
     nano add_ldap_user.yml
     ```
     - Inhalt:
       ```yaml
       - name: Add LDAP user for Etherpad
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
                 uid: {{ ldap_user }}
                 uidNumber: 1001
                 gidNumber: 1001
                 homeDirectory: /home/{{ ldap_user }}
                 userPassword: {SSHA}{{ lookup('password', '/tmp/passwd chars=ascii_letters,digits length=32') | password_hash('ssha') }}
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
     - Erstellt einen Benutzer (`testuser`) in OpenLDAP mit einem LDIF-File.
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
   - Teste die Anmeldung in Etherpad:
     - Öffne `https://192.168.30.107`.
     - Melde dich mit `testuser` und `SecurePass123!` an.
     - Erwartete Ausgabe: Erfolgreicher Zugriff auf Etherpad.

**Erkenntnis**: Ein in OpenLDAP erstellter Benutzer kann sich erfolgreich in Etherpad anmelden, wenn das `ep_ldap`-Plugin korrekt konfiguriert ist.

**Quelle**: https://www.openldap.org/doc/admin26/slapd.d.html

## Übung 3: Backup der integrierten Umgebung auf TrueNAS

**Ziel**: Sichere die Konfigurationen und Datenbanken von Etherpad und OpenLDAP und versioniere sie auf TrueNAS.

**Aufgabe**: Erstelle ein Ansible-Playbook für Backups beider Systeme und begrenze sie auf maximal fünf Versionen.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_etherpad_openldap.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup TurnKey Etherpad and OpenLDAP
         hosts: all
         become: yes
         vars:
           backup_dir: "/home/ubuntu/turnkey-etherpad-openldap-integration/backups"
           etherpad_backup_file: "{{ backup_dir }}/etherpad-backup-{{ ansible_date_time.date }}.tar.gz"
           ldap_backup_file: "{{ backup_dir }}/ldap-backup-{{ ansible_date_time.date }}.tar.gz"
         tasks:
           - name: Create backup directory
             ansible.builtin.file:
               path: "{{ backup_dir }}"
               state: directory
               mode: '0755'
             delegate_to: localhost
           - name: Stop Etherpad service
             ansible.builtin.service:
               name: etherpad
               state: stopped
             when: inventory_hostname == 'etherpad'
           - name: Backup Etherpad configuration and database
             ansible.builtin.command: >
               tar -czf /tmp/etherpad-backup-{{ ansible_date_time.date }}.tar.gz /etc/etherpad /var/lib/mysql
             when: inventory_hostname == 'etherpad'
           - name: Start Etherpad service
             ansible.builtin.service:
               name: etherpad
               state: started
             when: inventory_hostname == 'etherpad'
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
           - name: Fetch Etherpad backup file
             ansible.builtin.fetch:
               src: /tmp/etherpad-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ etherpad_backup_file }}"
               flat: yes
             when: inventory_hostname == 'etherpad'
           - name: Fetch OpenLDAP backup file
             ansible.builtin.fetch:
               src: /tmp/ldap-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ ldap_backup_file }}"
               flat: yes
             when: inventory_hostname == 'ldap'
           - name: Limit Etherpad backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t etherpad-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
             when: inventory_hostname == 'etherpad'
           - name: Limit OpenLDAP backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t ldap-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
             when: inventory_hostname == 'ldap'
           - name: Sync backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/turnkey-etherpad-openldap-integration/
             delegate_to: localhost
           - name: Display backup status
             ansible.builtin.debug:
               msg: "Backups saved to {{ backup_dir }} and synced to TrueNAS"
       ```
   - **Erklärung**:
     - Stoppt die Dienste (`etherpad`, `slapd`), um konsistente Backups zu gewährleisten.
     - Sichert `/etc/etherpad`, `/var/lib/mysql` (Etherpad) und `/etc/ldap`, `/var/lib/ldap` (OpenLDAP).
     - Begrenzt Backups auf fünf pro System durch Entfernen älterer Dateien.
     - Synchronisiert Backups mit TrueNAS.

2. **Playbook testen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_etherpad_openldap.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display backup status] ****************************************************
       ok: [etherpad] => {
           "msg": "Backups saved to /home/ubuntu/turnkey-etherpad-openldap-integration/backups and synced to TrueNAS"
       }
       ok: [ldap] => {
           "msg": "Backups saved to /home/ubuntu/turnkey-etherpad-openldap-integration/backups and synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/turnkey-etherpad-openldap-integration/
     ```
     - Erwartete Ausgabe: Maximal fünf `etherpad-backup-<date>.tar.gz` und fünf `ldap-backup-<date>.tar.gz`.

3. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/turnkey-etherpad-openldap-integration
       ansible-playbook -i inventory.yml backup_etherpad_openldap.yml >> backup.log 2>&1
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
       0 3 * * * /home/ubuntu/turnkey-etherpad-openldap-integration/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible automatisiert die Sicherung beider Systeme, während TrueNAS externe Speicherung bietet.

**Quelle**: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/fetch_module.html

## Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass die Firewall-Regeln aus den vorherigen Anleitungen aktiv sind (Ports 80, 443, 9001 für Etherpad; 389, 636, 443 für OpenLDAP).
   - Prüfe OPNsense-Logs:
     ```bash
     ansible-playbook -i inventory.yml -m ansible.builtin.command -a "cat /var/log/system/latest.log" opnsense
     ```

2. **Monitoring mit Checkmk (optional)**:
   - Konfiguriere Checkmk für beide Server:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Stelle sicher, dass `etherpad` (`192.168.30.107`) und `ldap` (`192.168.30.106`) als Hosts hinzugefügt sind.
     - Prüfe Services:
       - Gehe zu `Monitor > All services`.
       - Erwartete Ausgabe: Services wie `etherpad`, `slapd`, `Apache`, `Lighttpd`.
     - Erstelle eine benutzerdefinierte Überprüfung für die LDAP-Integration:
       ```bash
       nano /omd/sites/homelab/local/share/check_mk/checks/etherpad_ldap
       ```
       - Inhalt:
         ```bash
         #!/bin/bash
         curl -s -u testuser:SecurePass123! https://192.168.30.107 > /dev/null
         if [ $? -eq 0 ]; then
           echo "0 Etherpad_LDAP - LDAP authentication is operational"
         else
           echo "2 Etherpad_LDAP - LDAP authentication is not operational"
         fi
         ```
       - Ausführbar machen:
         ```bash
         chmod +x /omd/sites/homelab/local/share/check_mk/checks/etherpad_ldap
         ```
       - In Checkmk: `Setup > Services > Manual checks > Custom checks`, füge `Etherpad_LDAP` hinzu.

## Schritt 5: Erweiterung der Übungen
1. **Erweiterte Benutzer- und Gruppenverwaltung**:
   - Erstelle ein Playbook, um eine LDAP-Gruppe für Etherpad-Zugriff zu erstellen:
     ```bash
     nano add_ldap_group.yml
     ```
     - Inhalt:
       ```yaml
       - name: Add LDAP group for Etherpad
         hosts: ldap_servers
         become: yes
         vars:
           ldap_group: "etherpad_users"
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
     cd ~/turnkey-etherpad-openldap-integration/backups
     git init
     git add .
     git commit -m "Initial Etherpad and OpenLDAP backup"
     ```

## Best Practices für Schüler

- **Integration-Design**:
  - Verwende `ldaps` (Port 636) für sichere LDAP-Verbindungen.
  - Nutze Gruppen in OpenLDAP für rollenbasierte Zugriffssteuerung.
- **Sicherheit**:
  - Schränke Zugriff ein:
    ```bash
    ssh root@192.168.30.107 "ufw allow from 192.168.30.0/24 to any port 80,443,9001"
    ssh root@192.168.30.106 "ufw allow from 192.168.30.0/24 to any port 389,636,443"
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe Etherpad-Logs:
    ```bash
    ssh root@192.168.30.107 "cat /var/log/etherpad.log"
    ```
  - Prüfe OpenLDAP-Logs:
    ```bash
    ssh root@192.168.30.106 "cat /var/log/ldap.log"
    ```
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/turnkey-etherpad-openldap-integration/backup.log
    ```

**Quelle**: https://www.turnkeylinux.org/etherpad, https://www.turnkeylinux.org/openldap, https://www.npmjs.com/package/ep_ldap

## Empfehlungen für Schüler

- **Setup**: TurnKey Etherpad, OpenLDAP, Ansible, TrueNAS-Backups.
- **Workloads**: LDAP-Authentifizierung, Benutzererstellung, Backups.
- **Integration**: Proxmox (LXC), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Zentrale Authentifizierung für kollaborative Textbearbeitung.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einem einzelnen LDAP-Benutzer, erweitere zu Gruppen und Rollen.
- **Übung**: Teste die Authentifizierung mit verschiedenen LDAP-Clients.
- **Fehlerbehebung**: Nutze `ansible-playbook --check`, `ldapsearch` und Etherpad-Logs.
- **Lernressourcen**: https://www.turnkeylinux.org/etherpad, https://www.openldap.org/doc/, https://docs.ansible.com.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Integration von Etherpad mit OpenLDAP für zentrale Authentifizierung.
- **Skalierbarkeit**: Automatisierte Konfiguration und Backup-Prozesse.
- **Lernwert**: Verständnis von LDAP-basierter Authentifizierung und HomeLab-Integration.

**Nächste Schritte**: Möchtest du eine Anleitung zur Integration mit Wazuh für Sicherheitsüberwachung, Log-Aggregation mit Fluentd, oder erweitertem Monitoring mit Checkmk?

**Quellen**:
- TurnKey Linux Etherpad-Dokumentation: https://www.turnkeylinux.org/etherpad
- TurnKey Linux OpenLDAP-Dokumentation: https://www.turnkeylinux.org/openldap
- Etherpad-Plugin `ep_ldap`: https://www.npmjs.com/package/ep_ldap
- OpenLDAP-Dokumentation: https://www.openldap.org/doc/
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,,
```