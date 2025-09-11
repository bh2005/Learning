# Lernprojekt: Integration von TurnKey Linux Domain Controller und OpenLDAP

## Vorbereitung: Umgebung prüfen
1. **Domain Controller prüfen**:
   - Verbinde dich mit dem Domain Controller LXC-Container:
     ```bash
     ssh root@192.168.30.105
     ```
   - Stelle sicher, dass Samba läuft:
     ```bash
     systemctl status samba-ad-dc
     ```
     - Erwartete Ausgabe: `active (running)`.
   - Teste die AD-Funktionalität:
     ```bash
     samba-tool domain info 192.168.30.105
     ```
     - Erwartete Ausgabe: Informationen wie `Domain: HOMELAB`.
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
     - Erwartete Ausgabe: LDAP-Directory-Einträge.
3. **Ansible-Umgebung prüfen**:
   - Auf der Ubuntu-VM (`192.168.30.101`):
     ```bash
     ssh ubuntu@192.168.30.101
     ansible --version
     ```
   - Stelle sicher, dass SSH-Zugriff auf DC, OpenLDAP und OPNsense möglich ist:
     ```bash
     ssh root@192.168.30.105
     ssh root@192.168.30.106
     ssh root@192.168.30.1
     ```
4. **Projektverzeichnis erstellen**:
   - Auf `192.168.30.101`:
     ```bash
     mkdir ~/turnkey-dc-openldap-integration
     cd ~/turnkey-dc-openldap-integration
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf DC (`192.168.30.105`), OpenLDAP (`192.168.30.106`), OPNsense (`192.168.30.1`) und TrueNAS (`192.168.30.100`).

## Übung 1: Konfiguration des Domain Controllers für OpenLDAP

**Ziel**: Konfiguriere den TurnKey Domain Controller, um OpenLDAP als Authentifizierungs-Backend zu nutzen.

**Aufgabe**: Verwende Ansible, um den Samba-DC so zu konfigurieren, dass er OpenLDAP-Daten abfragt, und füge einen Testbenutzer hinzu.

1. **Ansible-Inventar erstellen**:
   - Erstelle eine Inventar-Datei:
     ```bash
     nano inventory.yml
     ```
     - Inhalt:
       ```yaml
       all:
         children:
           dc_servers:
             hosts:
               dc:
                 ansible_host: 192.168.30.105
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

2. **Ansible-Playbook für Samba-OpenLDAP-Integration**:
   - Erstelle ein Playbook:
     ```bash
     nano configure_samba_openldap.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure Samba to use OpenLDAP as backend
         hosts: dc_servers
         become: yes
         vars:
           ldap_server: "ldap://192.168.30.106"
           ldap_base: "dc=homelab,dc=local"
           ldap_admin_dn: "cn=admin,dc=homelab,dc=local"
           ldap_admin_password: "securepassword123"
         tasks:
           - name: Install LDAP utilities on Domain Controller
             ansible.builtin.apt:
               name: "{{ item }}"
               state: present
               update_cache: yes
             loop:
               - ldap-utils
               - sssd
               - sssd-ldap
           - name: Configure SSSD for LDAP
             ansible.builtin.copy:
               dest: /etc/sssd/sssd.conf
               content: |
                 [sssd]
                 config_file_version = 2
                 services = nss, pam
                 domains = homelab.local
                 [domain/homelab.local]
                 id_provider = ldap
                 auth_provider = ldap
                 ldap_uri = {{ ldap_server }}
                 ldap_search_base = {{ ldap_base }}
                 ldap_user_search_base = ou=Users,{{ ldap_base }}
                 ldap_group_search_base = ou=Groups,{{ ldap_base }}
                 ldap_default_bind_dn = {{ ldap_admin_dn }}
                 ldap_default_authtok = {{ ldap_admin_password }}
                 cache_credentials = true
                 enumerate = true
               mode: '0600'
           - name: Enable and start SSSD service
             ansible.builtin.service:
               name: sssd
               state: started
               enabled: yes
           - name: Configure Samba to use SSSD
             ansible.builtin.lineinfile:
               path: /etc/samba/smb.conf
               regexp: "^passdb backend ="
               line: "passdb backend = ldapsam:{{ ldap_server }}"
               insertafter: "[global]"
           - name: Add LDAP admin credentials to Samba
             ansible.builtin.lineinfile:
               path: /etc/samba/smb.conf
               regexp: "^ldap admin dn ="
               line: "ldap admin dn = {{ ldap_admin_dn }}"
               insertafter: "[global]"
           - name: Set LDAP admin password in Samba
             ansible.builtin.command: >
               smbpasswd -W {{ ldap_admin_password }}
             changed_when: false
           - name: Restart Samba service
             ansible.builtin.service:
               name: samba-ad-dc
               state: restarted
           - name: Test LDAP connection from Samba
             ansible.builtin.command: >
               ldapsearch -x -H {{ ldap_server }} -b "{{ ldap_base }}" -D "{{ ldap_admin_dn }}" -w {{ ldap_admin_password }}
             register: ldap_test
           - name: Display LDAP test result
             ansible.builtin.debug:
               msg: "{{ ldap_test.stdout }}"
       ```
   - **Erklärung**:
     - Installiert `ldap-utils`, `sssd` und `sssd-ldap` auf dem Domain Controller.
     - Konfiguriert SSSD (System Security Services Daemon) für die Verbindung zu OpenLDAP.
     - Passt die Samba-Konfiguration (`smb.conf`) an, um OpenLDAP als `ldapsam`-Backend zu nutzen.
     - Testet die LDAP-Verbindung.

3. **Playbook ausführen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml configure_samba_openldap.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display LDAP test result] *************************************************
       ok: [dc] => {
           "msg": "... dn: dc=homelab,dc=local ..."
       }
       ```
   - Prüfe die Samba-AD-Verbindung:
     ```bash
     ssh root@192.168.30.105 "samba-tool user list"
     ```
     - Erwartete Ausgabe: Liste der AD-Benutzer (zunächst nur Standardbenutzer wie `Administrator`).

**Erkenntnis**: Samba kann OpenLDAP als Authentifizierungs-Backend nutzen, indem SSSD und `ldapsam` konfiguriert werden.

**Quelle**: https://wiki.samba.org/index.php/OpenLDAP_as_a_Samba_Backend

## Übung 2: Synchronisation von Benutzern zwischen OpenLDAP und Samba-AD

**Ziel**: Synchronisiere Benutzer von OpenLDAP nach Samba-AD, um eine einheitliche Benutzerverwaltung zu ermöglichen.

**Aufgabe**: Erstelle ein Ansible-Playbook, um einen Testbenutzer in OpenLDAP zu erstellen und nach Samba-AD zu synchronisieren.

1. **Ansible-Playbook für Benutzer-Synchronisation**:
   - Erstelle ein Playbook:
     ```bash
     nano sync_users_openldap_samba.yml
     ```
     - Inhalt:
       ```yaml
       - name: Add user to OpenLDAP and sync to Samba
         hosts: all
         become: yes
         vars:
           ldap_user: "testuser"
           ldap_password: "SecurePass123!"
           ldap_domain: "dc=homelab,dc=local"
           samba_domain: "HOMELAB"
         tasks:
           - name: Create LDIF file for OpenLDAP user
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
                 userPassword: {CRYPT}{{ lookup('password', '/tmp/passwd chars=ascii_letters,digits length=32') }}
             delegate_to: 192.168.30.106
           - name: Add user to OpenLDAP
             ansible.builtin.command: >
               ldapadd -x -D "cn=admin,{{ ldap_domain }}" -w securepassword123 -f /tmp/add_user.ldif
             register: ldap_user_result
             delegate_to: 192.168.30.106
           - name: Export OpenLDAP user to LDIF
             ansible.builtin.command: >
               ldapsearch -x -H ldap://192.168.30.106 -b "uid={{ ldap_user }},ou=Users,{{ ldap_domain }}" -D "cn=admin,{{ ldap_domain }}" -w securepassword123 > /tmp/user_export.ldif
             delegate_to: 192.168.30.106
           - name: Copy LDIF to Samba server
             ansible.builtin.copy:
               src: /tmp/user_export.ldif
               dest: /tmp/user_export.ldif
             delegate_to: 192.168.30.105
           - name: Convert LDIF for Samba compatibility
             ansible.builtin.shell: >
               sed 's/uid=/sAMAccountName=/g' /tmp/user_export.ldif > /tmp/user_samba.ldif
             delegate_to: 192.168.30.105
           - name: Add user to Samba AD
             ansible.builtin.command: >
               samba-tool user create {{ ldap_user }} {{ ldap_password }} --given-name=Test --surname=User
             delegate_to: 192.168.30.105
           - name: Verify user in Samba
             ansible.builtin.command: >
               samba-tool user list
             register: samba_user_list
             delegate_to: 192.168.30.105
           - name: Display user sync status
             ansible.builtin.debug:
               msg: "{{ samba_user_list.stdout }}"
       ```
   - **Erklärung**:
     - Erstellt einen Benutzer (`testuser`) in OpenLDAP mit einem LDIF-File.
     - Exportiert den Benutzer aus OpenLDAP und kopiert ihn zum Samba-DC.
     - Konvertiert das LDIF für Samba-Kompatibilität (rudimentäre Anpassung von `uid` zu `sAMAccountName`).
     - Fügt den Benutzer zu Samba-AD hinzu.
     - Verifiziert die Benutzerliste in Samba.

2. **Playbook ausführen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml sync_users_openldap_samba.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display user sync status] *************************************************
       ok: [dc] => {
           "msg": "... testuser ..."
       }
       ```
   - Prüfe in phpLDAPadmin:
     - Öffne `https://192.168.30.106/phpldapadmin`, melde dich an (`cn=admin,dc=homelab,dc=local`, `securepassword123`).
     - Erwartete Ausgabe: Benutzer `uid=testuser,ou=Users,dc=homelab,dc=local`.
   - Prüfe in Samba:
     ```bash
     ssh root@192.168.30.105 "samba-tool user list"
     ```
     - Erwartete Ausgabe: `testuser` in der Liste.

**Erkenntnis**: Benutzer können von OpenLDAP zu Samba-AD synchronisiert werden, aber die Kompatibilität erfordert Anpassungen (z. B. Attribut-Mapping).

**Quelle**: https://www.openldap.org/doc/admin26/slapd.d.html

## Übung 3: Backup der integrierten Umgebung auf TrueNAS

**Ziel**: Sichere die Konfigurationen und Datenbanken von OpenLDAP und Samba-AD und versioniere sie auf TrueNAS.

**Aufgabe**: Erstelle ein Ansible-Playbook für Backups beider Systeme und begrenze sie auf maximal fünf Versionen.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_dc_openldap.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup TurnKey Domain Controller and OpenLDAP
         hosts: all
         become: yes
         vars:
           backup_dir: "/home/ubuntu/turnkey-dc-openldap-integration/backups"
           dc_backup_file: "{{ backup_dir }}/dc-backup-{{ ansible_date_time.date }}.tar.gz"
           ldap_backup_file: "{{ backup_dir }}/ldap-backup-{{ ansible_date_time.date }}.tar.gz"
         tasks:
           - name: Create backup directory
             ansible.builtin.file:
               path: "{{ backup_dir }}"
               state: directory
               mode: '0755'
             delegate_to: localhost
           - name: Stop Samba service
             ansible.builtin.service:
               name: samba-ad-dc
               state: stopped
             when: inventory_hostname == 'dc'
           - name: Backup Samba configuration and AD database
             ansible.builtin.command: >
               tar -czf /tmp/dc-backup-{{ ansible_date_time.date }}.tar.gz /etc/samba /var/lib/samba
             when: inventory_hostname == 'dc'
           - name: Start Samba service
             ansible.builtin.service:
               name: samba-ad-dc
               state: started
             when: inventory_hostname == 'dc'
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
           - name: Fetch Samba backup file
             ansible.builtin.fetch:
               src: /tmp/dc-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ dc_backup_file }}"
               flat: yes
             when: inventory_hostname == 'dc'
           - name: Fetch OpenLDAP backup file
             ansible.builtin.fetch:
               src: /tmp/ldap-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ ldap_backup_file }}"
               flat: yes
             when: inventory_hostname == 'ldap'
           - name: Limit Samba backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t dc-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
             when: inventory_hostname == 'dc'
           - name: Limit OpenLDAP backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t ldap-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
             when: inventory_hostname == 'ldap'
           - name: Sync backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/turnkey-dc-openldap-integration/
             delegate_to: localhost
           - name: Display backup status
             ansible.builtin.debug:
               msg: "Backups saved to {{ backup_dir }} and synced to TrueNAS"
       ```
   - **Erklärung**:
     - Stoppt die Dienste (`samba-ad-dc`, `slapd`), um konsistente Backups zu gewährleisten.
     - Sichert `/etc/samba`, `/var/lib/samba` (Samba-AD) und `/etc/ldap`, `/var/lib/ldap` (OpenLDAP).
     - Begrenzt Backups auf fünf pro System durch Entfernen älterer Dateien.
     - Synchronisiert Backups mit TrueNAS.

2. **Playbook testen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_dc_openldap.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display backup status] ****************************************************
       ok: [dc] => {
           "msg": "Backups saved to /home/ubuntu/turnkey-dc-openldap-integration/backups and synced to TrueNAS"
       }
       ok: [ldap] => {
           "msg": "Backups saved to /home/ubuntu/turnkey-dc-openldap-integration/backups and synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/turnkey-dc-openldap-integration/
     ```
     - Erwartete Ausgabe: Maximal fünf `dc-backup-<date>.tar.gz` und fünf `ldap-backup-<date>.tar.gz`.

3. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/turnkey-dc-openldap-integration
       ansible-playbook -i inventory.yml backup_dc_openldap.yml >> backup.log 2>&1
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
       0 3 * * * /home/ubuntu/turnkey-dc-openldap-integration/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible automatisiert die Sicherung beider Systeme, während TrueNAS externe Speicherung bietet.

**Quelle**: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/fetch_module.html

## Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass die Firewall-Regeln aus den vorherigen Anleitungen aktiv sind (Ports 137-139, 445, 12321 für DC; 389, 636, 443 für OpenLDAP).
   - Prüfe OPNsense-Logs:
     ```bash
     ansible-playbook -i inventory.yml -m ansible.builtin.command -a "cat /var/log/system/latest.log" opnsense
     ```

2. **Monitoring mit Checkmk (optional)**:
   - Konfiguriere Checkmk für beide Server:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Stelle sicher, dass `dc` (`192.168.30.105`) und `ldap` (`192.168.30.106`) als Hosts hinzugefügt sind.
     - Prüfe Services:
       - Gehe zu `Monitor > All services`.
       - Erwartete Ausgabe: Services wie `samba-ad-dc`, `slapd`, `Webmin`, `Lighttpd`.
     - Erstelle eine benutzerdefinierte Überprüfung für die Integration:
       ```bash
       nano /omd/sites/homelab/local/share/check_mk/checks/dc_ldap_integration
       ```
       - Inhalt:
         ```bash
         #!/bin/bash
         samba-tool user list | grep testuser > /dev/null
         if [ $? -eq 0 ]; then
           echo "0 DC_LDAP_Integration - User synchronization is operational"
         else
           echo "2 DC_LDAP_Integration - User synchronization is not operational"
         fi
         ```
       - Ausführbar machen:
         ```bash
         chmod +x /omd/sites/homelab/local/share/check_mk/checks/dc_ldap_integration
         ```
       - In Checkmk: `Setup > Services > Manual checks > Custom checks`, füge `DC_LDAP_Integration` hinzu.

## Schritt 5: Erweiterung der Übungen
1. **Erweiterte Benutzer-Synchronisation**:
   - Erstelle ein Skript für bidirektionale Synchronisation:
     ```bash
     nano sync_bidirectional.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       # Export from Samba to LDIF
       ssh root@192.168.30.105 "samba-tool user list" | while read user; do
         ssh root@192.168.30.106 "ldapsearch -x -H ldap://192.168.30.106 -b 'uid=$user,ou=Users,dc=homelab,dc=local' -D 'cn=admin,dc=homelab,dc=local' -w securepassword123 || echo 'User $user not found'"
       done
       ```
     - Ausführbar machen:
       ```bash
       chmod +x sync_bidirectional.sh
       ```

2. **Backup-Versionierung mit Git**:
   - Initialisiere ein Git-Repository für Backups:
     ```bash
     cd ~/turnkey-dc-openldap-integration/backups
     git init
     git add .
     git commit -m "Initial DC and OpenLDAP backup"
     ```

## Best Practices für Schüler

- **Integration-Design**:
  - Verwende SSSD für eine robuste Samba-OpenLDAP-Verbindung.
  - Halte die LDAP-Struktur (`ou=Users`, `ou=Groups`) konsistent.
- **Sicherheit**:
  - Schränke Zugriff ein:
    ```bash
    ssh root@192.168.30.105 "ufw allow from 192.168.30.0/24 to any port 137-139,445,12321"
    ssh root@192.168.30.106 "ufw allow from 192.168.30.0/24 to any port 389,636,443"
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe Samba-Logs:
    ```bash
    ssh root@192.168.30.105 "cat /var/log/samba/log.samba"
    ```
  - Prüfe OpenLDAP-Logs:
    ```bash
    ssh root@192.168.30.106 "cat /var/log/ldap.log"
    ```
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/turnkey-dc-openldap-integration/backup.log
    ```

**Quelle**: https://wiki.samba.org, https://www.openldap.org/doc/, https://docs.ansible.com

## Empfehlungen für Schüler

- **Setup**: TurnKey Domain Controller, OpenLDAP, Ansible, TrueNAS-Backups.
- **Workloads**: Integration, Benutzer-Synchronisation, Backups.
- **Integration**: Proxmox (LXC), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Hybride AD-LDAP-Umgebung für Authentifizierung.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einer einfachen Benutzer-Synchronisation, erweitere zu Gruppen und Policies.
- **Übung**: Teste die Authentifizierung mit einem LDAP-Client (z. B. `ldap-auth-config`) und Windows-Client.
- **Fehlerbehebung**: Nutze `ansible-playbook --check`, `ldapsearch` und `samba-tool`.
- **Lernressourcen**: https://www.turnkeylinux.org/domain-controller, https://www.turnkeylinux.org/openldap, https://wiki.samba.org.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Integration von Samba-AD und OpenLDAP in einer HomeLab.
- **Skalierbarkeit**: Automatisierte Synchronisation und Backup-Konfigurationen.
- **Lernwert**: Verständnis von hybriden Verzeichnisdiensten und HomeLab-Integration.

**Nächste Schritte**: Möchtest du eine Anleitung zur Integration mit Wazuh für Sicherheitsüberwachung, Log-Aggregation mit Fluentd, oder erweitertem Monitoring mit Checkmk?

**Quellen**:
- TurnKey Linux Domain Controller-Dokumentation: https://www.turnkeylinux.org/domain-controller
- TurnKey Linux OpenLDAP-Dokumentation: https://www.turnkeylinux.org/openldap
- Samba-Dokumentation: https://wiki.samba.org
- OpenLDAP-Dokumentation: https://www.openldap.org/doc/
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,
```