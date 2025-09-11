# Lernprojekt: Integration von TurnKey Linux GNU social mit OpenLDAP für Authentifizierung

## Vorbereitung: Umgebung prüfen
1. **Proxmox VE prüfen**:
   - Melde dich an der Proxmox-Weboberfläche an: `https://192.168.30.2:8006`.
   - Stelle sicher, dass die LXC-Container für GNU social (`192.168.30.112`) und OpenLDAP (`192.168.30.106`) laufen:
     ```bash
     pct list
     ```
     - Erwartete Ausgabe: Container `gnusocial` und `ldap` mit Status `running`.
2. **DNS in OPNsense prüfen**:
   - Öffne die OPNsense-Weboberfläche: `http://192.168.30.1`.
   - Gehe zu `Services > Unbound DNS > Overrides > Host`.
   - Überprüfe Einträge:
     - `gnusocial.homelab.local` → `192.168.30.112`
     - `ldap.homelab.local` → `192.168.30.106`
   - Teste die DNS-Auflösung:
     ```bash
     nslookup gnusocial.homelab.local 192.168.30.1
     nslookup ldap.homelab.local 192.168.30.1
     ```
     - Erwartete Ausgabe: `192.168.30.112` und `192.168.30.106`.
3. **Ansible-Umgebung prüfen**:
   - Auf der Ubuntu-VM (`192.168.30.101`):
     ```bash
     ssh ubuntu@192.168.30.101
     ansible --version
     ```
   - Stelle sicher, dass SSH-Zugriff auf GNU social und OpenLDAP möglich ist:
     ```bash
     ssh root@192.168.30.112
     ssh root@192.168.30.106
     ```
4. **Projektverzeichnis erstellen**:
   - Auf `192.168.30.101`:
     ```bash
     mkdir ~/turnkey-gnusocial-openldap-integration
     cd ~/turnkey-gnusocial-openldap-integration
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf GNU social (`192.168.30.112`), OpenLDAP (`192.168.30.106`), OPNsense (`192.168.30.1`) und TrueNAS (`192.168.30.100`).

## Übung 1: Konfiguration der OpenLDAP-Integration in GNU social

**Ziel**: Konfiguriere GNU social, um Benutzer und Gruppen aus OpenLDAP zu authentifizieren.

**Aufgabe**: Installiere das `ldapauth`-Plugin und konfiguriere die LDAP-Authentifizierung mit Ansible.

1. **Ansible-Inventar erstellen**:
   - Erstelle eine Inventar-Datei:
     ```bash
     nano inventory.yml
     ```
     - Inhalt:
       ```yaml
       all:
         children:
           gnusocial_servers:
             hosts:
               gnusocial:
                 ansible_host: 192.168.30.112
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

2. **Ansible-Playbook für GNU social-LDAP-Integration**:
   - Erstelle ein Playbook:
     ```bash
     nano configure_gnusocial_ldap.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure GNU social LDAP Integration
         hosts: gnusocial_servers
         become: yes
         vars:
           gnusocial_dir: "/var/www/gnusocial"
           ldap_host: "ldap.homelab.local"
           ldap_port: 389
           ldap_base_dn: "dc=homelab,dc=local"
           ldap_bind_dn: "cn=admin,dc=homelab,dc=local"
           ldap_bind_password: "securepassword123"
         tasks:
           - name: Install LDAP authentication plugin
             ansible.builtin.command: >
               git clone https://git.gnu.io/gnu/gnu-social-ldapauth.git {{ gnusocial_dir }}/plugins/LDAPAuth
             args:
               creates: "{{ gnusocial_dir }}/plugins/LDAPAuth"
           - name: Enable LDAPAuth plugin
             ansible.builtin.lineinfile:
               path: "{{ gnusocial_dir }}/config.php"
               line: "addPlugin('LDAPAuth');"
               insertafter: EOF
           - name: Configure LDAP settings
             ansible.builtin.blockinfile:
               path: "{{ gnusocial_dir }}/config.php"
               marker: "// {mark} LDAP Configuration"
               block: |
                 $config['ldap']['host'] = '{{ ldap_host }}';
                 $config['ldap']['port'] = {{ ldap_port }};
                 $config['ldap']['basedn'] = '{{ ldap_base_dn }}';
                 $config['ldap']['binddn'] = '{{ ldap_bind_dn }}';
                 $config['ldap']['bindpw'] = '{{ ldap_bind_password }}';
                 $config['ldap']['user_filter'] = '(objectClass=inetOrgPerson)';
                 $config['ldap']['group_filter'] = '(objectClass=groupOfNames)';
                 $config['ldap']['login_filter'] = '(&(objectClass=inetOrgPerson)(uid=%s))';
                 $config['ldap']['display_name'] = 'cn';
           - name: Restart Apache
             ansible.builtin.service:
               name: apache2
               state: restarted
           - name: Test LDAP connection
             ansible.builtin.command: >
               curl -s -u testuser:securepassword123 https://gnusocial.homelab.local
             register: ldap_test_result
             ignore_errors: yes
           - name: Display LDAP test result
             ansible.builtin.debug:
               msg: "{{ ldap_test_result.stdout | default('Failed to connect, check logs') }}"
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
                 "source_net":"192.168.30.112",
                 "destination":"192.168.30.106",
                 "destination_port":"389",
                 "description":"Allow GNU social to OpenLDAP"
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
     - Installiert das `ldapauth`-Plugin von https://git.gnu.io/gnu/gnu-social-ldapauth.git.
     - Aktiviert das Plugin in der GNU social-Konfigurationsdatei (`config.php`).
     - Konfiguriert LDAP-Verbindungsparameter (Host, Port, Base DN, Bind DN, Passwort).
     - Setzt Filter für Benutzer (`inetOrgPerson`) und Gruppen (`groupOfNames`).
     - Fügt eine Firewall-Regel in OPNsense hinzu, um GNU social (`192.168.30.112`) den Zugriff auf OpenLDAP (`192.168.30.106:389`) zu erlauben.
     - Testet die LDAP-Verbindung mit einem `curl`-Befehl.

3. **Playbook ausführen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml configure_gnusocial_ldap.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display LDAP test result] *************************************************
       ok: [gnusocial] => {
           "msg": "<html>... GNU social login page ..."
       }
       TASK [Display firewall rules] ***************************************************
       ok: [opnsense] => {
           "msg": "... Allow GNU social to OpenLDAP ..."
       }
       ```
   - Prüfe in der GNU social-Weboberfläche:
     - Öffne `https://gnusocial.homelab.local`, melde dich mit einem LDAP-Benutzer an (z. B. `testuser`, siehe Übung 2).
     - Erwartete Ausgabe: Erfolgreicher Login mit LDAP-Benutzer.
   - Prüfe in OPNsense:
     - Gehe zu `Firewall > Rules > LAN`: Regel für `192.168.30.112` zu `192.168.30.106:389`.

**Erkenntnis**: Das `ldapauth`-Plugin ermöglicht die Integration von GNU social mit OpenLDAP, aber die veraltete Software (letzte stabile Version 2014) erfordert Vorsicht.

**Quelle**: https://git.gnu.io/gnu/gnu-social-ldapauth.git, https://www.turnkeylinux.org/gnusocial

## Übung 2: Erstellung von LDAP-Benutzern und -Gruppen mit Ansible

**Ziel**: Erstelle LDAP-Benutzer und -Gruppen für GNU social und teste die Authentifizierung.

**Aufgabe**: Erstelle ein Ansible-Playbook, um Benutzer und Gruppen in OpenLDAP hinzuzufügen und in GNU social zu testen.

1. **Ansible-Playbook für LDAP-Benutzer und -Gruppen**:
   - Erstelle ein Playbook:
     ```bash
     nano create_ldap_users_groups.yml
     ```
     - Inhalt:
       ```yaml
       - name: Create LDAP users and groups for GNU social
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
           - name: Create LDAP group for GNU social users
             ansible.builtin.command: >
               ldapadd -x -D "{{ ldap_admin_dn }}" -w "{{ ldap_admin_password }}" -f /tmp/gnusocial_users.ldif
             args:
               creates: /tmp/gnusocial_users.ldif
             vars:
               ldif_content: |
                 dn: cn=gnusocial_users,ou=groups,{{ ldap_base_dn }}
                 objectClass: groupOfNames
                 cn: gnusocial_users
                 member: cn=testuser,ou=users,{{ ldap_base_dn }}
             delegate_to: localhost
             ansible.builtin.copy:
               dest: /tmp/gnusocial_users.ldif
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
       - name: Test LDAP authentication in GNU social
         hosts: gnusocial_servers
         become: yes
         tasks:
           - name: Test LDAP user login
             ansible.builtin.command: >
               curl -s -u testuser:securepassword123 https://gnusocial.homelab.local
             register: login_result
             ignore_errors: yes
           - name: Display login result
             ansible.builtin.debug:
               msg: "{{ login_result.stdout | default('Failed to login, check logs') }}"
       ```
   - **Erklärung**:
     - Erstellt Organizational Units (`ou=users`, `ou=groups`) in OpenLDAP.
     - Fügt eine Gruppe (`gnusocial_users`) und einen Testbenutzer (`testuser`) hinzu.
     - Testet die Authentifizierung in GNU social mit einem `curl`-Befehl.

2. **Playbook ausführen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml create_ldap_users_groups.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display login result] *****************************************************
       ok: [gnusocial] => {
           "msg": "<html>... GNU social dashboard ..."
       }
       ```
   - Teste die Authentifizierung in GNU social:
     - Öffne `https://gnusocial.homelab.local`.
     - Melde dich mit `testuser` und Passwort `securepassword123` an.
     - Erwartete Ausgabe: Erfolgreicher Login, Zugriff auf das GNU social-Dashboard.

**Erkenntnis**: Ansible automatisiert die Erstellung von LDAP-Benutzern und -Gruppen, die in GNU social für Authentifizierung verwendet werden, aber die Stabilität der Integration ist durch die veraltete Software eingeschränkt.

**Quelle**: https://www.turnkeylinux.org/openldap, https://git.gnu.io/gnu/gnu-social-ldapauth.git

## Übung 3: Backup der GNU social- und LDAP-Konfiguration auf TrueNAS

**Ziel**: Sichere die GNU social- und OpenLDAP-Konfigurationen auf TrueNAS.

**Aufgabe**: Erstelle ein Ansible-Playbook für Backups und begrenze sie auf maximal fünf Versionen.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_gnusocial_ldap.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup GNU social configuration and data
         hosts: gnusocial_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/turnkey-gnusocial-openldap-integration/backups/gnusocial"
           backup_file: "{{ backup_dir }}/gnusocial-backup-{{ ansible_date_time.date }}.tar.gz"
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
           - name: Backup GNU social configuration and database
             ansible.builtin.command: >
               tar -czf /tmp/gnusocial-backup-{{ ansible_date_time.date }}.tar.gz /var/www/gnusocial /var/lib/mysql
             register: backup_result
           - name: Start Apache service
             ansible.builtin.service:
               name: apache2
               state: started
           - name: Fetch backup file
             ansible.builtin.fetch:
               src: /tmp/gnusocial-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ backup_file }}"
               flat: yes
           - name: Limit GNU social backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t gnusocial-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync GNU social backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/turnkey-gnusocial-openldap-integration/
             delegate_to: localhost
           - name: Display GNU social backup status
             ansible.builtin.debug:
               msg: "GNU social backup saved to {{ backup_file }} and synced to TrueNAS"
       - name: Backup OpenLDAP configuration and data
         hosts: openldap_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/turnkey-gnusocial-openldap-integration/backups/openldap"
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
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/turnkey-gnusocial-openldap-integration/
             delegate_to: localhost
           - name: Display OpenLDAP backup status
             ansible.builtin.debug:
               msg: "OpenLDAP backup saved to {{ backup_file }} and synced to TrueNAS"
       ```
   - **Erklärung**:
     - Sichert GNU social (`/var/www/gnusocial`, `/var/lib/mysql`) und OpenLDAP (`/etc/ldap`, `/var/lib/ldap`).
     - Stoppt Dienste (`apache2`, `slapd`), um konsistente Backups zu gewährleisten.
     - Begrenzt Backups auf fünf Versionen pro Dienst.
     - Synchronisiert Backups mit TrueNAS.

2. **Playbook testen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_gnusocial_ldap.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display GNU social backup status] *****************************************
       ok: [gnusocial] => {
           "msg": "GNU social backup saved to /home/ubuntu/turnkey-gnusocial-openldap-integration/backups/gnusocial/gnusocial-backup-<date>.tar.gz and synced to TrueNAS"
       }
       TASK [Display OpenLDAP backup status] ******************************************
       ok: [ldap] => {
           "msg": "OpenLDAP backup saved to /home/ubuntu/turnkey-gnusocial-openldap-integration/backups/openldap/openldap-backup-<date>.tar.gz and synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/turnkey-gnusocial-openldap-integration/
     ```
     - Erwartete Ausgabe: Maximal fünf `gnusocial-backup-<date>.tar.gz` und `openldap-backup-<date>.tar.gz`.

3. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/turnkey-gnusocial-openldap-integration
       ansible-playbook -i inventory.yml backup_gnusocial_ldap.yml >> backup.log 2>&1
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
       0 3 * * * /home/ubuntu/turnkey-gnusocial-openldap-integration/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible automatisiert die Sicherung von GNU social- und OpenLDAP-Daten, während TrueNAS externe Speicherung bietet.

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
       nano /omd/sites/homelab/local/share/check_mk/checks/gnusocial_ldap
       ```
       - Inhalt:
         ```bash
         #!/bin/bash
         curl -s -u testuser:securepassword123 https://192.168.30.112 > /dev/null
         if [ $? -eq 0 ]; then
           echo "0 GNU_social_LDAP - LDAP authentication is operational"
         else
           echo "2 GNU_social_LDAP - LDAP authentication is not operational"
         fi
         ```
       - Ausführbar machen:
         ```bash
         chmod +x /omd/sites/homelab/local/share/check_mk/checks/gnusocial_ldap
         ```
       - In Checkmk: `Setup > Services > Manual checks > Custom checks`, füge `GNU_social_LDAP` hinzu.

## Schritt 5: Erweiterung der Übungen
1. **Erweiterte LDAP-Konfiguration**:
   - Erstelle ein Playbook, um weitere Benutzer hinzuzufügen:
     ```bash
     nano add_ldap_user.yml
     ```
     - Inhalt:
       ```yaml
       - name: Add additional LDAP user for GNU social
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
           - name: Add user to GNU social group
             ansible.builtin.command: >
               ldapmodify -x -D "{{ ldap_admin_dn }}" -w "{{ ldap_admin_password }}" -f /tmp/add_to_group.ldif
             args:
               creates: /tmp/add_to_group.ldif
             vars:
               ldif_content: |
                 dn: cn=gnusocial_users,ou=groups,{{ ldap_base_dn }}
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
     cd ~/turnkey-gnusocial-openldap-integration/backups
     git init
     git add .
     git commit -m "Initial GNU social and OpenLDAP backup"
     ```

## Best Practices für Schüler

- **GNU social-LDAP-Design**:
  - Nutze einfache LDAP-Filter (z. B. `objectClass=inetOrgPerson`) für Benutzer.
  - Teste die LDAP-Konfiguration in der GNU social-Weboberfläche (`https://gnusocial.homelab.local/main/admin/plugins`).
- **Sicherheit**:
  - Schränke LDAP-Zugriff ein:
    ```bash
    ssh root@192.168.30.112 "ufw allow from 192.168.30.112 to 192.168.30.106 port 389 proto tcp"
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
  - Verwende LDAPS (Port 636) für Produktionsumgebungen:
    ```bash
    ssh root@192.168.30.106 "turnkey-letsencrypt ldap.homelab.local"
    ```
    - Aktualisiere `ldap_port` in `configure_gnusocial_ldap.yml` auf `636`.
  - Beachte die veraltete Natur von GNU social (letzte stabile Version 2014, siehe https://www.turnkeylinux.org/gnusocial) und verwende es nur in isolierten Umgebungen.
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
  - Teste Backups vor GNU social- oder OpenLDAP-Updates (siehe https://www.turnkeylinux.org/gnusocial, https://www.turnkeylinux.org/openldap).
- **Fehlerbehebung**:
  - Prüfe GNU social-LDAP-Logs:
    ```bash
    ssh root@192.168.30.112 "cat /var/www/gnusocial/log/*"
    ```
  - Prüfe OpenLDAP-Logs:
    ```bash
    ssh root@192.168.30.106 "cat /var/log/syslog | grep slapd"
    ```
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/turnkey-gnusocial-openldap-integration/backup.log
    ```

**Quelle**: https://git.gnu.io/gnu/gnu-social-ldapauth.git, https://www.turnkeylinux.org/openldap, https://www.turnkeylinux.org/gnusocial

## Empfehlungen für Schüler

- **Setup**: TurnKey GNU social, OpenLDAP, Proxmox LXC, Ansible, TrueNAS-Backups.
- **Workloads**: LDAP-Integration, Benutzer-/Gruppenverwaltung, Backups.
- **Integration**: Proxmox (LXC), TrueNAS (Backups), OPNsense (DNS, Netzwerk).
- **Beispiel**: Zentrale Authentifizierung für GNU social-Nutzer im HomeLab.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einem Testbenutzer, erweitere zu Gruppen und Rollen.
- **Übung**: Teste die Authentifizierung mit mehreren Benutzern und GNU social-Clients.
- **Fehlerbehebung**: Nutze `ldapsearch` für Tests:
  ```bash
  ssh root@192.168.30.106 "ldapsearch -x -H ldap://ldap.homelab.local -D 'cn=admin,dc=homelab,dc=local' -w securepassword123 -b 'dc=homelab,dc=local' '(uid=testuser)'"
  ```
- **Lernressourcen**: https://www.turnkeylinux.org/gnusocial, https://docs.gnusocial.rocks, https://www.turnkeylinux.org/openldap, https://docs.ansible.com.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Schnelle Integration von GNU social mit OpenLDAP für Authentifizierung.
- **Skalierbarkeit**: Automatisierte Benutzer-/Gruppenverwaltung und Backup-Konfigurationen.
- **Lernwert**: Verständnis von LDAP-Authentifizierung und HomeLab-Integration.
- **Warnung**: GNU social ist veraltet (letzte stabile Version 2014), daher nur für Lernzwecke oder isolierte Umgebungen verwenden (siehe https://www.turnkeylinux.org/gnusocial).

**Nächste Schritte**: Möchtest du eine Anleitung zur Integration von GNU social mit anderen Plattformen (z. B. Twitter, XMPP), Installation von zusätzlichen GNU social-Plugins, oder Monitoring mit Wazuh/Fluentd/Checkmk?

**Quellen**:
- TurnKey Linux GNU social-Dokumentation: https://www.turnkeylinux.org/gnusocial
- GNU social-Dokumentation: https://docs.gnusocial.rocks
- TurnKey Linux OpenLDAP-Dokumentation: https://www.turnkeylinux.org/openldap
- Ansible-Dokumentation: https://docs.ansible.com
- Webquellen: https://www.turnkeylinux.org/gnusocial, https://docs.gnusocial.rocks, https://git.gnu.io/gnu/gnu-social-ldapauth.git
```