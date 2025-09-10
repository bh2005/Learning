# Lernprojekt: Installation eines TurnKey Linux OpenLDAP-Servers als LXC-Container

## Vorbereitung: Umgebung einrichten
1. **Proxmox VE prüfen**:
   - Melde dich an der Proxmox-Weboberfläche an: `https://192.168.30.2:8006`.
   - Stelle sicher, dass LXC-Unterstützung aktiviert ist:
     ```bash
     pveam update
     pveam list
     ```
   - Prüfe verfügbare Speicherorte (z. B. `local-lvm` oder `local-zfs`).
2. **DNS in OPNsense konfigurieren**:
   - Öffne die OPNsense-Weboberfläche: `http://192.168.30.1`.
   - Gehe zu `Services > Unbound DNS > General`.
   - Aktiviere DNS-Resolver und füge einen Host-Eintrag hinzu:
     - Host: `ldap`
     - Domäne: `homelab.local`
     - IP: `192.168.30.106`
     - Beschreibung: `OpenLDAP Server`
   - Teste den DNS-Eintrag:
     ```bash
     nslookup ldap.homelab.local 192.168.30.1
     ```
     - Erwartete Ausgabe: `192.168.30.106`.
3. **Ansible-Umgebung prüfen**:
   - Auf der Ubuntu-VM (`192.168.30.101`):
     ```bash
     ssh ubuntu@192.168.30.101
     ansible --version
     ```
   - Stelle sicher, dass SSH-Zugriff auf OPNsense möglich ist:
     ```bash
     ssh root@192.168.30.1
     ```
4. **Projektverzeichnis erstellen**:
   - Auf `192.168.30.101`:
     ```bash
     mkdir ~/turnkey-openldap-install
     cd ~/turnkey-openldap-install
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Proxmox (`192.168.30.2`), OPNsense (`192.168.30.1`) und TrueNAS (`192.168.30.100`).

## Übung 1: Einrichten des LXC-Containers mit TurnKey OpenLDAP

**Ziel**: Installiere den TurnKey Linux OpenLDAP-Server als LXC-Container auf Proxmox.

**Aufgabe**: Lade die TurnKey OpenLDAP-Vorlage herunter, erstelle einen LXC-Container und konfiguriere die Basis-Einstellungen.

1. **TurnKey OpenLDAP-Vorlage herunterladen**:
   - Öffne die Proxmox-Weboberfläche.
   - Gehe zu `Storage > local > Content > Templates`.
   - Lade die neueste TurnKey OpenLDAP-Vorlage herunter:
     - URL: `http://mirror.turnkeylinux.org/turnkeylinux/images/proxmox/debian-12-turnkey-openldap_18.1-1_amd64.tar.gz`
     - Alternativ per CLI auf dem Proxmox-Host:
       ```bash
       pveam download local debian-12-turnkey-openldap_18.1-1_amd64.tar.gz
       ```
2. **LXC-Container erstellen**:
   - In Proxmox: `Create CT`:
     - Hostname: `ldap`
     - Template: `debian-12-turnkey-openldap_18.1-1_amd64`
     - IP-Adresse: `192.168.30.106/24`
     - Gateway: `192.168.30.1`
     - DNS-Server: `192.168.30.1`
     - Speicher: `local-lvm` oder `local-zfs`
     - CPU: 1 Kern, RAM: 1 GB, Disk: 10 GB
   - Starte den Container:
     - In der Proxmox-Weboberfläche: `ldap > Start`.
     - Bei der ersten Anmeldung wirst du aufgefordert, die Initialkonfiguration durchzuführen.
3. **OpenLDAP initial konfigurieren**:
   - Verbinde dich mit dem Container:
     ```bash
     ssh root@192.168.30.106
     ```
   - Führe die Ersteinrichtung durch (TurnKey Firstboot):
     - Setze das Root-Passwort.
     - Setze das OpenLDAP-Admin-Passwort (z. B. `securepassword123`).
     - Setze den LDAP-Domänennamen: `homelab.local`.
     - Installiere Sicherheitsupdates, wenn gefragt.
   - Prüfe den OpenLDAP-Dienst:
     ```bash
     systemctl status slapd
     ```
     - Erwartete Ausgabe: `active (running)`.
   - Teste die phpLDAPadmin-Oberfläche:
     ```bash
     curl https://ldap.homelab.local/phpldapadmin
     ```
     - Erwartete Ausgabe: HTML der phpLDAPadmin-Anmeldeseite.
     - Öffne im Browser: `https://192.168.30.106/phpldapadmin` (ignoriere SSL-Warnungen für selbstsignierte Zertifikate).
     - Melde dich an: `cn=admin,dc=homelab,dc=local`, Passwort: `securepassword123`.
   - Teste die LDAP-Verbindung:
     ```bash
     ldapsearch -x -H ldap://192.168.30.106 -b "dc=homelab,dc=local" -D "cn=admin,dc=homelab,dc=local" -w securepassword123
     ```
     - Erwartete Ausgabe: LDAP-Directory-Einträge (z. B. `ou=Users`, `ou=Groups`).

**Erkenntnis**: Die TurnKey OpenLDAP Appliance vereinfacht die Installation eines LDAP-Servers mit `slapd`, `phpLDAPadmin` und TLS-Unterstützung.[](https://www.turnkeylinux.org/openldap)

**Quelle**: https://www.turnkeylinux.org/openldap

## Übung 2: Konfiguration von Firewall-Regeln mit Ansible

**Ziel**: Konfiguriere Firewall-Regeln auf OPNsense, um Zugriff auf LDAP (389) und LDAPS (636) sowie phpLDAPadmin (443) zu erlauben.

**Aufgabe**: Erstelle ein Ansible-Playbook, um Firewall-Regeln für den OpenLDAP-Server zu konfigurieren.

1. **Ansible-Inventar erstellen**:
   - Erstelle eine Inventar-Datei:
     ```bash
     nano inventory.yml
     ```
     - Inhalt:
       ```yaml
       all:
         children:
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

2. **Ansible-Playbook für Firewall-Regeln**:
   - Erstelle ein Playbook:
     ```bash
     nano configure_firewall_openldap.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure OPNsense firewall for OpenLDAP
         hosts: network_devices
         tasks:
           - name: Add firewall rule for LDAP (389)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.106",
                 "destination_port":"389",
                 "description":"Allow LDAP to OpenLDAP Server"
               }'
             register: ldap_result
           - name: Add firewall rule for LDAPS (636)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.106",
                 "destination_port":"636",
                 "description":"Allow LDAPS to OpenLDAP Server"
               }'
             register: ldaps_result
           - name: Add firewall rule for phpLDAPadmin (443)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.106",
                 "destination_port":"443",
                 "description":"Allow phpLDAPadmin to OpenLDAP Server"
               }'
             register: phpldapadmin_result
           - name: Verify firewall rules
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Display firewall rules
             ansible.builtin.debug:
               msg: "{{ rules_list.stdout }}"
       ```
   - **Erklärung**:
     - Fügt Firewall-Regeln für LDAP (389), LDAPS (636) und phpLDAPadmin (443) hinzu.
     - Erlaubt Verkehr von `192.168.30.0/24` zu `192.168.30.106`.

3. **Playbook ausführen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml configure_firewall_openldap.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display firewall rules] ****************************************************
       ok: [opnsense] => {
           "msg": "... Allow LDAP to OpenLDAP Server ... Allow LDAPS to OpenLDAP Server ... Allow phpLDAPadmin to OpenLDAP Server ..."
       }
       ```
   - Prüfe in der OPNsense-Weboberfläche:
     - Gehe zu `Firewall > Rules > LAN`.
     - Erwartete Regeln: `pass` für `192.168.30.106:389`, `192.168.30.106:636`, `192.168.30.106:443`.

**Erkenntnis**: Ansible automatisiert die Firewall-Konfiguration, um sicheren Zugriff auf den OpenLDAP-Server zu gewährleisten.

**Quelle**: https://docs.opnsense.org/manual/firewall.html

## Übung 3: Backup der OpenLDAP-Daten auf TrueNAS

**Ziel**: Sichere die OpenLDAP-Konfiguration und Datenbank und versioniere sie auf TrueNAS.

**Aufgabe**: Erstelle ein Ansible-Playbook für Backups und begrenze sie auf maximal fünf Versionen.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_openldap.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup TurnKey OpenLDAP configuration and data
         hosts: ldap_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/turnkey-openldap-install/backups/ldap"
           backup_file: "{{ backup_dir }}/ldap-backup-{{ ansible_date_time.date }}.tar.gz"
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
               tar -czf /tmp/ldap-backup-{{ ansible_date_time.date }}.tar.gz /etc/ldap /var/lib/ldap
             register: backup_result
           - name: Start OpenLDAP service
             ansible.builtin.service:
               name: slapd
               state: started
           - name: Fetch backup file
             ansible.builtin.fetch:
               src: /tmp/ldap-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ backup_file }}"
               flat: yes
           - name: Limit backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t ldap-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/turnkey-openldap-install/
             delegate_to: localhost
           - name: Display backup status
             ansible.builtin.debug:
               msg: "Backup saved to {{ backup_file }} and synced to TrueNAS"
       ```
   - **Erklärung**:
     - Stoppt den `slapd`-Dienst, um konsistente Backups zu gewährleisten.
     - Sichert `/etc/ldap` (Konfiguration) und `/var/lib/ldap` (Datenbank).
     - Begrenzt Backups auf fünf durch Entfernen älterer Dateien.
     - Synchronisiert Backups mit TrueNAS.

2. **Playbook testen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_openldap.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display backup status] ****************************************************
       ok: [ldap] => {
           "msg": "Backup saved to /home/ubuntu/turnkey-openldap-install/backups/ldap/ldap-backup-<date>.tar.gz and synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/turnkey-openldap-install/
     ```
     - Erwartete Ausgabe: Maximal fünf `ldap-backup-<date>.tar.gz`.

3. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/turnkey-openldap-install
       ansible-playbook -i inventory.yml backup_openldap.yml >> backup.log 2>&1
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
       0 3 * * * /home/ubuntu/turnkey-openldap-install/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible automatisiert die Sicherung der OpenLDAP-Daten, während TrueNAS externe Speicherung bietet.

**Quelle**: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/fetch_module.html

## Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass die Firewall-Regeln aktiv sind (siehe Übung 2).
   - Prüfe OPNsense-Logs:
     ```bash
     ansible-playbook -i inventory.yml -m ansible.builtin.command -a "cat /var/log/system/latest.log" opnsense
     ```

2. **Monitoring mit Checkmk (optional)**:
   - Konfiguriere Checkmk für den OpenLDAP-Server:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Füge den OpenLDAP-Server als Host hinzu:
       - Hostname: `ldap`, IP: `192.168.30.106`.
       - Speichern und `Discover services`.
     - Prüfe Services:
       - Gehe zu `Monitor > All services`.
       - Erwartete Ausgabe: Services wie `slapd`, `Lighttpd` (für phpLDAPadmin).
     - Erstelle eine benutzerdefinierte Überprüfung für LDAP:
       ```bash
       nano /omd/sites/homelab/local/share/check_mk/checks/openldap
       ```
       - Inhalt:
         ```bash
         #!/bin/bash
         ldapsearch -x -H ldap://192.168.30.106 -b "dc=homelab,dc=local" -D "cn=admin,dc=homelab,dc=local" -w securepassword123 > /dev/null
         if [ $? -eq 0 ]; then
           echo "0 OpenLDAP - LDAP server is operational"
         else
           echo "2 OpenLDAP - LDAP server is not operational"
         fi
         ```
       - Ausführbar machen:
         ```bash
         chmod +x /omd/sites/homelab/local/share/check_mk/checks/openldap
         ```
       - In Checkmk: `Setup > Services > Manual checks > Custom checks`, füge `OpenLDAP` hinzu.

## Schritt 5: Erweiterung der Übungen
1. **Erweiterte OpenLDAP-Konfiguration**:
   - Erstelle ein Playbook, um einen LDAP-Benutzer hinzuzufügen:
     ```bash
     nano add_ldap_user.yml
     ```
     - Inhalt:
       ```yaml
       - name: Add user to OpenLDAP
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
                 userPassword: {SSHA}{{ (ldap_password | b64encode) | b64encode }}
           - name: Add user to LDAP
             ansible.builtin.command: >
               ldapadd -x -D "cn=admin,{{ ldap_domain }}" -w securepassword123 -f /tmp/add_user.ldif
             register: user_result
           - name: Display user creation status
             ansible.builtin.debug:
               msg: "{{ user_result.stdout }}"
       ```
     - **Hinweis**: Das Passwort muss korrekt gehasht werden; für Produktionsumgebungen `slappasswd` verwenden.

2. **Backup-Versionierung mit Git**:
   - Initialisiere ein Git-Repository für Backups:
     ```bash
     cd ~/turnkey-openldap-install/backups/ldap
     git init
     git add .
     git commit -m "Initial OpenLDAP backup"
     ```

## Best Practices für Schüler

- **OpenLDAP-Design**:
  - Verwende `ldaps` (Port 636) für sichere Verbindungen.
  - Nutze phpLDAPadmin für einfache Verwaltung.
- **Sicherheit**:
  - Schränke Zugriff ein:
    ```bash
    ssh root@192.168.30.106 "ufw allow from 192.168.30.0/24 to any port 389,636,443"
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe OpenLDAP-Logs:
    ```bash
    ssh root@192.168.30.106 "cat /var/log/ldap.log"
    ```
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/turnkey-openldap-install/backup.log
    ```

**Quelle**: https://www.turnkeylinux.org/openldap, https://www.openldap.org/doc/

## Empfehlungen für Schüler

- **Setup**: TurnKey OpenLDAP, Proxmox LXC, Ansible, TrueNAS-Backups.
- **Workloads**: LDAP-Installation, Firewall-Konfiguration, Backups.
- **Integration**: Proxmox (LXC), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: OpenLDAP-Server für zentrale Authentifizierung.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einer einfachen LDAP-Struktur, erweitere zu Benutzer- und Gruppenverwaltung.
- **Übung**: Experimentiere mit LDAP-Clients (z. B. `ldap-auth-config` auf Ubuntu).
- **Fehlerbehebung**: Nutze `ansible-playbook --check` und `ldapsearch`.
- **Lernressourcen**: https://www.turnkeylinux.org/openldap, https://www.openldap.org/doc/, https://docs.ansible.com.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Schnelle Installation eines OpenLDAP-Servers mit TurnKey.
- **Skalierbarkeit**: Automatisierte Firewall- und Backup-Konfigurationen.
- **Lernwert**: Verständnis von LDAP und HomeLab-Integration.

**Nächste Schritte**: Möchtest du eine Anleitung zur Integration mit Wazuh für Sicherheitsüberwachung, Log-Aggregation mit Fluentd, oder erweitertem Monitoring mit Checkmk?

**Quellen**:
- TurnKey Linux OpenLDAP-Dokumentation: https://www.turnkeylinux.org/openldap
- OpenLDAP-Dokumentation: https://www.openldap.org/doc/
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,[](https://www.turnkeylinux.org/openldap)[](https://www.turnkeylinux.org/updates/new-turnkey-openldap-version-181)[](https://releases.turnkeylinux.org/turnkey-openldap/18.0-bookworm-amd64/turnkey-openldap-18.0-bookworm-amd64.changelog)
```