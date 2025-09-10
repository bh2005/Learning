# Lernprojekt: Integration von TurnKey Linux ownCloud mit OpenLDAP für Authentifizierung

## Vorbereitung: Umgebung prüfen
1. **Proxmox VE prüfen**:
   - Melde dich an der Proxmox-Weboberfläche an: `https://192.168.30.2:8006`.
   - Stelle sicher, dass die LXC-Container für ownCloud (`192.168.30.111`) und OpenLDAP (`192.168.30.106`) laufen:
     ```bash
     pct list
     ```
     - Erwartete Ausgabe: Container `owncloud` und `ldap` mit Status `running`.
2. **DNS in OPNsense prüfen**:
   - Öffne die OPNsense-Weboberfläche: `http://192.168.30.1`.
   - Gehe zu `Services > Unbound DNS > Overrides > Host`.
   - Überprüfe Einträge:
     - `owncloud.homelab.local` → `192.168.30.111`
     - `ldap.homelab.local` → `192.168.30.106`
   - Teste die DNS-Auflösung:
     ```bash
     nslookup owncloud.homelab.local 192.168.30.1
     nslookup ldap.homelab.local 192.168.30.1
     ```
     - Erwartete Ausgabe: `192.168.30.111` und `192.168.30.106`.
3. **Ansible-Umgebung prüfen**:
   - Auf der Ubuntu-VM (`192.168.30.101`):
     ```bash
     ssh ubuntu@192.168.30.101
     ansible --version
     ```
   - Stelle sicher, dass SSH-Zugriff auf ownCloud und OpenLDAP möglich ist:
     ```bash
     ssh root@192.168.30.111
     ssh root@192.168.30.106
     ```
4. **Projektverzeichnis erstellen**:
   - Auf `192.168.30.101`:
     ```bash
     mkdir ~/turnkey-owncloud-openldap-integration
     cd ~/turnkey-owncloud-openldap-integration
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf ownCloud (`192.168.30.111`), OpenLDAP (`192.168.30.106`), OPNsense (`192.168.30.1`) und TrueNAS (`192.168.30.100`).

## Übung 1: Konfiguration der OpenLDAP-Integration in ownCloud

**Ziel**: Konfiguriere ownCloud, um Benutzer und Gruppen aus OpenLDAP zu authentifizieren.

**Aufgabe**: Aktiviere und konfiguriere die ownCloud-App „LDAP user and group backend“ mit Ansible.

1. **Ansible-Inventar erstellen**:
   - Erstelle eine Inventar-Datei:
     ```bash
     nano inventory.yml
     ```
     - Inhalt:
       ```yaml
       all:
         children:
           owncloud_servers:
             hosts:
               owncloud:
                 ansible_host: 192.168.30.111
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

2. **Ansible-Playbook für ownCloud-LDAP-Integration**:
   - Erstelle ein Playbook:
     ```bash
     nano configure_owncloud_ldap.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure ownCloud LDAP Integration
         hosts: owncloud_servers
         become: yes
         vars:
           owncloud_occ: "/var/www/owncloud/occ"
           ldap_host: "ldap.homelab.local"
           ldap_port: 389
           ldap_base_dn: "dc=homelab,dc=local"
           ldap_bind_dn: "cn=admin,dc=homelab,dc=local"
           ldap_bind_password: "securepassword123"
         tasks:
           - name: Enable LDAP user and group backend app
             ansible.builtin.command: >
               {{ owncloud_occ }} app:enable user_ldap
             changed_when: true
           - name: Configure LDAP server settings
             ansible.builtin.command: >
               {{ owncloud_occ }} ldap:set-config s01 ldapHost {{ ldap_host }}
             changed_when: true
           - name: Configure LDAP port
             ansible.builtin.command: >
               {{ owncloud_occ }} ldap:set-config s01 ldapPort {{ ldap_port }}
             changed_when: true
           - name: Configure LDAP base DN
             ansible.builtin.command: >
               {{ owncloud_occ }} ldap:set-config s01 ldapBase {{ ldap_base_dn }}
             changed_when: true
           - name: Configure LDAP bind DN
             ansible.builtin.command: >
               {{ owncloud_occ }} ldap:set-config s01 ldapAgentName {{ ldap_bind_dn }}
             changed_when: true
           - name: Configure LDAP bind password
             ansible.builtin.command: >
               {{ owncloud_occ }} ldap:set-config s01 ldapAgentPassword {{ ldap_bind_password }}
             changed_when: true
           - name: Configure LDAP user filter
             ansible.builtin.command: >
               {{ owncloud_occ }} ldap:set-config s01 ldapUserFilter "(objectClass=inetOrgPerson)"
             changed_when: true
           - name: Configure LDAP group filter
             ansible.builtin.command: >
               {{ owncloud_occ }} ldap:set-config s01 ldapGroupFilter "(objectClass=groupOfNames)"
             changed_when: true
           - name: Configure LDAP login filter
             ansible.builtin.command: >
               {{ owncloud_occ }} ldap:set-config s01 ldapLoginFilter "(&(objectClass=inetOrgPerson)(uid=%uid))"
             changed_when: true
           - name: Configure LDAP display name attribute
             ansible.builtin.command: >
               {{ owncloud_occ }} ldap:set-config s01 ldapUserDisplayName "cn"
             changed_when: true
           - name: Enable LDAP configuration
             ansible.builtin.command: >
               {{ owncloud_occ }} ldap:set-config s01 hasMemberOfFilterSupport "1"
             changed_when: true
           - name: Test LDAP connection
             ansible.builtin.command: >
               {{ owncloud_occ }} ldap:test-config s01
             register: ldap_test_result
           - name: Display LDAP test result
             ansible.builtin.debug:
               msg: "{{ ldap_test_result.stdout }}"
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
                 "source_net":"192.168.30.111",
                 "destination":"192.168.30.106",
                 "destination_port":"389",
                 "description":"Allow ownCloud to OpenLDAP"
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
     - Aktiviert die `user_ldap`-App in ownCloud.
     - Konfiguriert LDAP-Verbindungsparameter (Host, Port, Base DN, Bind DN, Passwort).
     - Setzt Filter für Benutzer (`inetOrgPerson`) und Gruppen (`groupOfNames`).
     - Fügt eine Firewall-Regel in OPNsense hinzu, um ownCloud (`192.168.30.111`) den Zugriff auf OpenLDAP (`192.168.30.106:389`) zu erlauben.
     - Testet die LDAP-Verbindung mit `ldap:test-config`.

3. **Playbook ausführen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml configure_owncloud_ldap.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display LDAP test result] *************************************************
       ok: [owncloud] => {
           "msg": "The configuration is valid and the connection could be established!"
       }
       TASK [Display firewall rules] ***************************************************
       ok: [opnsense] => {
           "msg": "... Allow ownCloud to OpenLDAP ..."
       }
       ```
   - Prüfe in der ownCloud-Weboberfläche:
     - Öffne `https://owncloud.homelab.local`, melde dich als Admin an.
     - Gehe zu `Settings > Admin > LDAP`.
     - Erwartete Ausgabe: Konfigurierte LDAP-Einstellungen (`ldap.homelab.local`, Port 389).
   - Prüfe in OPNsense:
     - Gehe zu `Firewall > Rules > LAN`: Regel für `192.168.30.111` zu `192.168.30.106:389`.

**Erkenntnis**: Die ownCloud-App „LDAP user and group backend“ ermöglicht eine nahtlose Integration mit OpenLDAP für zentrale Authentifizierung.

**Quelle**: https://doc.owncloud.com/server/next/admin_manual/configuration/user/user_auth_ldap.html

## Übung 2: Erstellung von LDAP-Benutzern und -Gruppen mit Ansible

**Ziel**: Erstelle LDAP-Benutzer und -Gruppen für ownCloud und teste die Authentifizierung.

**Aufgabe**: Erstelle ein Ansible-Playbook, um Benutzer und Gruppen in OpenLDAP hinzuzufügen und in ownCloud zu testen.

1. **Ansible-Playbook für LDAP-Benutzer und -Gruppen**:
   - Erstelle ein Playbook:
     ```bash
     nano create_ldap_users_groups.yml
     ```
     - Inhalt:
       ```yaml
       - name: Create LDAP users and groups for ownCloud
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
           - name: Create LDAP group for ownCloud users
             ansible.builtin.command: >
               ldapadd -x -D "{{ ldap_admin_dn }}" -w "{{ ldap_admin_password }}" -f /tmp/owncloud_users.ldif
             args:
               creates: /tmp/owncloud_users.ldif
             vars:
               ldif_content: |
                 dn: cn=owncloud_users,ou=groups,{{ ldap_base_dn }}
                 objectClass: groupOfNames
                 cn: owncloud_users
                 member: cn=testuser,ou=users,{{ ldap_base_dn }}
             delegate_to: localhost
             ansible.builtin.copy:
               dest: /tmp/owncloud_users.ldif
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
       - name: Test LDAP authentication in ownCloud
         hosts: owncloud_servers
         become: yes
         vars:
           owncloud_occ: "/var/www/owncloud/occ"
         tasks:
           - name: Check LDAP users in ownCloud
             ansible.builtin.command: >
               {{ owncloud_occ }} ldap:show-remnants
             register: ldap_users_result
           - name: Display LDAP users
             ansible.builtin.debug:
               msg: "{{ ldap_users_result.stdout }}"
       ```
   - **Erklärung**:
     - Erstellt Organizational Units (`ou=users`, `ou=groups`) in OpenLDAP.
     - Fügt eine Gruppe (`owncloud_users`) und einen Testbenutzer (`testuser`) hinzu.
     - Testet die Sichtbarkeit des Benutzers in ownCloud mit `ldap:show-remnants`.

2. **Playbook ausführen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml create_ldap_users_groups.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display LDAP users] ******************************************************
       ok: [owncloud] => {
           "msg": "... testuser ..."
       }
       ```
   - Teste die Authentifizierung in ownCloud:
     - Öffne `https://owncloud.homelab.local`.
     - Melde dich mit `testuser` und Passwort `securepassword123` an.
     - Erwartete Ausgabe: Erfolgreicher Login, Zugriff auf ownCloud-Dateien.

**Erkenntnis**: Ansible automatisiert die Erstellung von LDAP-Benutzern und -Gruppen, die in ownCloud für Authentifizierung verwendet werden.

**Quelle**: https://www.turnkeylinux.org/openldap

## Übung 3: Backup der ownCloud- und LDAP-Konfiguration auf TrueNAS

**Ziel**: Sichere die ownCloud- und OpenLDAP-Konfigurationen auf TrueNAS.

**Aufgabe**: Erstelle ein Ansible-Playbook für Backups und begrenze sie auf maximal fünf Versionen.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_owncloud_ldap.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup ownCloud configuration and data
         hosts: owncloud_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/turnkey-owncloud-openldap-integration/backups/owncloud"
           backup_file: "{{ backup_dir }}/owncloud-backup-{{ ansible_date_time.date }}.tar.gz"
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
           - name: Backup ownCloud configuration and database
             ansible.builtin.command: >
               tar -czf /tmp/owncloud-backup-{{ ansible_date_time.date }}.tar.gz /var/www/owncloud /var/lib/mysql
             register: backup_result
           - name: Start Apache service
             ansible.builtin.service:
               name: apache2
               state: started
           - name: Fetch backup file
             ansible.builtin.fetch:
               src: /tmp/owncloud-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ backup_file }}"
               flat: yes
           - name: Limit ownCloud backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t owncloud-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync ownCloud backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/turnkey-owncloud-openldap-integration/
             delegate_to: localhost
           - name: Display ownCloud backup status
             ansible.builtin.debug:
               msg: "ownCloud backup saved to {{ backup_file }} and synced to TrueNAS"
       - name: Backup OpenLDAP configuration and data
         hosts: openldap_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/turnkey-owncloud-openldap-integration/backups/openldap"
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
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/turnkey-owncloud-openldap-integration/
             delegate_to: localhost
           - name: Display OpenLDAP backup status
             ansible.builtin.debug:
               msg: "OpenLDAP backup saved to {{ backup_file }} and synced to TrueNAS"
       ```
   - **Erklärung**:
     - Sichert ownCloud (`/var/www/owncloud`, `/var/lib/mysql`) und OpenLDAP (`/etc/ldap`, `/var/lib/ldap`).
     - Stoppt Dienste (`apache2`, `slapd`), um konsistente Backups zu gewährleisten.
     - Begrenzt Backups auf fünf Versionen pro Dienst.
     - Synchronisiert Backups mit TrueNAS.

2. **Playbook testen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_owncloud_ldap.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display ownCloud backup status] *******************************************
       ok: [owncloud] => {
           "msg": "ownCloud backup saved to /home/ubuntu/turnkey-owncloud-openldap-integration/backups/owncloud/owncloud-backup-<date>.tar.gz and synced to TrueNAS"
       }
       TASK [Display OpenLDAP backup status] *******************************************
       ok: [ldap] => {
           "msg": "OpenLDAP backup saved to /home/ubuntu/turnkey-owncloud-openldap-integration/backups/openldap/openldap-backup-<date>.tar.gz and synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/turnkey-owncloud-openldap-integration/
     ```
     - Erwartete Ausgabe: Maximal fünf `owncloud-backup-<date>.tar.gz` und `openldap-backup-<date>.tar.gz`.

3. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/turnkey-owncloud-openldap-integration
       ansible-playbook -i inventory.yml backup_owncloud_ldap.yml >> backup.log 2>&1
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
       0 3 * * * /home/ubuntu/turnkey-owncloud-openldap-integration/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible automatisiert die Sicherung von ownCloud- und OpenLDAP-Daten, während TrueNAS externe Speicherung bietet.

**Quelle**: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/fetch_module.html

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
       nano /omd/sites/homelab/local/share/check_mk/checks/owncloud_ldap
       ```
       - Inhalt:
         ```bash
         #!/bin/bash
         curl -s -u testuser:securepassword123 https://192.168.30.111/status.php > /dev/null
         if [ $? -eq 0 ]; then
           echo "0 ownCloud_LDAP - LDAP authentication is operational"
         else
           echo "2 ownCloud_LDAP - LDAP authentication is not operational"
         fi
         ```
       - Ausführbar machen:
         ```bash
         chmod +x /omd/sites/homelab/local/share/check_mk/checks/owncloud_ldap
         ```
       - In Checkmk: `Setup > Services > Manual checks > Custom checks`, füge `ownCloud_LDAP` hinzu.

## Schritt 5: Erweiterung der Übungen
1. **Erweiterte LDAP-Konfiguration**:
   - Erstelle ein Playbook, um weitere Benutzer hinzuzufügen:
     ```bash
     nano add_ldap_user.yml
     ```
     - Inhalt:
       ```yaml
       - name: Add additional LDAP user for ownCloud
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
           - name: Add user to ownCloud group
             ansible.builtin.command: >
               ldapmodify -x -D "{{ ldap_admin_dn }}" -w "{{ ldap_admin_password }}" -f /tmp/add_to_group.ldif
             args:
               creates: /tmp/add_to_group.ldif
             vars:
               ldif_content: |
                 dn: cn=owncloud_users,ou=groups,{{ ldap_base_dn }}
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
     cd ~/turnkey-owncloud-openldap-integration/backups
     git init
     git add .
     git commit -m "Initial ownCloud and OpenLDAP backup"
     ```

## Best Practices für Schüler

- **ownCloud-LDAP-Design**:
  - Nutze einfache LDAP-Filter (z. B. `objectClass=inetOrgPerson`) für Benutzer.
  - Teste die LDAP-Konfiguration in der ownCloud-Weboberfläche (`Settings > Admin > LDAP`).
- **Sicherheit**:
  - Schränke LDAP-Zugriff ein:
    ```bash
    ssh root@192.168.30.111 "ufw allow from 192.168.30.111 to 192.168.30.106 port 389 proto tcp"
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
  - Verwende LDAPS (Port 636) für Produktionsumgebungen:
    ```bash
    ssh root@192.168.30.106 "turnkey-letsencrypt ldap.homelab.local"
    ```
    - Aktualisiere `ldap_port` in `configure_owncloud_ldap.yml` auf `636`.
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
  - Teste Backups vor ownCloud- oder OpenLDAP-Updates (siehe https://www.turnkeylinux.org/owncloud, https://www.turnkeylinux.org/openldap).
- **Fehlerbehebung**:
  - Prüfe ownCloud-LDAP-Logs:
    ```bash
    ssh root@192.168.30.111 "cat /var/www/owncloud/data/owncloud.log"
    ```
  - Prüfe OpenLDAP-Logs:
    ```bash
    ssh root@192.168.30.106 "cat /var/log/syslog | grep slapd"
    ```
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/turnkey-owncloud-openldap-integration/backup.log
    ```

**Quelle**: https://doc.owncloud.com/server/next/admin_manual/configuration/user/user_auth_ldap.html, https://www.turnkeylinux.org/openldap

## Empfehlungen für Schüler

- **Setup**: TurnKey ownCloud, OpenLDAP, Proxmox LXC, Ansible, TrueNAS-Backups.
- **Workloads**: LDAP-Integration, Benutzer-/Gruppenverwaltung, Backups.
- **Integration**: Proxmox (LXC), TrueNAS (Backups), OPNsense (DNS, Netzwerk).
- **Beispiel**: Zentrale Authentifizierung für ownCloud-Nutzer im HomeLab.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einem Testbenutzer, erweitere zu Gruppen und Rollen.
- **Übung**: Teste die Authentifizierung mit mehreren Benutzern und ownCloud-Clients (Desktop/Mobile).
- **Fehlerbehebung**: Nutze `ldapsearch` und `occ ldap:show-remnants` für Tests.
  ```bash
  ssh root@192.168.30.106 "ldapsearch -x -H ldap://ldap.homelab.local -D 'cn=admin,dc=homelab,dc=local' -w securepassword123 -b 'dc=homelab,dc=local' '(uid=testuser)'"
  ```
- **Lernressourcen**: https://www.turnkeylinux.org/owncloud, https://doc.owncloud.com, https://www.turnkeylinux.org/openldap, https://docs.ansible.com.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Schnelle Integration von ownCloud mit OpenLDAP für Authentifizierung.
- **Skalierbarkeit**: Automatisierte Benutzer-/Gruppenverwaltung und Backup-Konfigurationen.
- **Lernwert**: Verständnis von LDAP-Authentifizierung und HomeLab-Integration.

**Nächste Schritte**: Möchtest du eine Anleitung zur Integration anderer Dienste (z. B. Mattermost, BrowserPad) mit OpenLDAP, Installation von ownCloud-Apps, oder Monitoring mit Wazuh/Fluentd/Checkmk?

**Quellen**:
- TurnKey Linux ownCloud-Dokumentation: https://www.turnkeylinux.org/owncloud
- ownCloud LDAP-Dokumentation: https://doc.owncloud.com/server/next/admin_manual/configuration/user/user_auth_ldap.html
- TurnKey Linux OpenLDAP-Dokumentation: https://www.turnkeylinux.org/openldap
- Ansible-Dokumentation: https://docs.ansible.com
- Webquellen: https://www.turnkeylinux.org/owncloud, https://doc.owncloud.com
```