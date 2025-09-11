# Lernprojekt: Installation von TurnKey Linux ownCloud in einer HomeLab-Umgebung

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
   - Aktiviere DNS-Resolver (falls nicht bereits aktiv).
   - Füge einen Host-Eintrag hinzu:
     - Host: `owncloud`
     - Domäne: `homelab.local`
     - IP: `192.168.30.111`
     - Beschreibung: `ownCloud File Server`
   - Teste den DNS-Eintrag:
     ```bash
     nslookup owncloud.homelab.local 192.168.30.1
     ```
     - Erwartete Ausgabe: `192.168.30.111`.
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
     mkdir ~/turnkey-owncloud-install
     cd ~/turnkey-owncloud-install
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Proxmox (`192.168.30.2`), OPNsense (`192.168.30.1`) und TrueNAS (`192.168.30.100`).

## Übung 1: Einrichten des LXC-Containers mit TurnKey ownCloud

**Ziel**: Installiere den TurnKey Linux ownCloud-Server als LXC-Container auf Proxmox.

**Aufgabe**: Lade die TurnKey ownCloud-Vorlage herunter, erstelle einen LXC-Container und konfiguriere die Basis-Einstellungen.

1. **TurnKey ownCloud-Vorlage herunterladen**:
   - Öffne die Proxmox-Weboberfläche.
   - Gehe zu `Storage > local > Content > Templates`.
   - Lade die neueste TurnKey ownCloud-Vorlage herunter:
     - URL: `http://mirror.turnkeylinux.org/turnkeylinux/images/proxmox/debian-12-turnkey-owncloud_18.0-1_amd64.tar.gz`
     - Alternativ per CLI auf dem Proxmox-Host:
       ```bash
       pveam download local debian-12-turnkey-owncloud_18.0-1_amd64.tar.gz
       ```
2. **LXC-Container erstellen**:
   - In Proxmox: `Create CT`:
     - Hostname: `owncloud`
     - Template: `debian-12-turnkey-owncloud_18.0-1_amd64`
     - IP-Adresse: `192.168.30.111/24`
     - Gateway: `192.168.30.1`
     - DNS-Server: `192.168.30.1`
     - Speicher: `local-lvm` oder `local-zfs`
     - CPU: 2 Kerne, RAM: 2 GB, Disk: 20 GB
   - Starte den Container:
     - In der Proxmox-Weboberfläche: `owncloud > Start`.
     - Bei der ersten Anmeldung wirst du aufgefordert, die Initialkonfiguration durchzuführen.
3. **ownCloud initial konfigurieren**:
   - Verbinde dich mit dem Container:
     ```bash
     ssh root@192.168.30.111
     ```
   - Führe die Ersteinrichtung durch (TurnKey Firstboot):
     - Setze das Root-Passwort.
     - Setze das MariaDB-Root-Passwort (z. B. `securepassword123`).
     - Konfiguriere den ownCloud-Admin-Benutzer (z. B. `admin`, Passwort: `securepassword123`).
     - Installiere Sicherheitsupdates, wenn gefragt.
   - Prüfe den Apache-Dienst:
     ```bash
     systemctl status apache2
     ```
     - Erwartete Ausgabe: `active (running)`.
   - Teste die Weboberfläche:
     ```bash
     curl https://owncloud.homelab.local
     ```
     - Erwartete Ausgabe: HTML der ownCloud-Anmeldeseite.
     - Öffne im Browser: `https://192.168.30.111` (ignoriere SSL-Warnungen für selbstsignierte Zertifikate).
   - Teste die Webmin-Oberfläche:
     ```bash
     curl https://192.168.30.111:12322
     ```
     - Erwartete Ausgabe: HTML der Webmin-Anmeldeseite.
     - Öffne im Browser: `https://192.168.30.111:12322`.

**Erkenntnis**: Die TurnKey ownCloud Appliance vereinfacht die Installation einer Dateisynchronisierungsplattform mit Apache und MariaDB.

**Quelle**: https://www.turnkeylinux.org/owncloud

## Übung 2: Konfiguration von OPNsense-DNS und Firewall-Regeln

**Ziel**: Konfiguriere OPNsense, um `owncloud.homelab.local` aufzulösen und den Zugriff auf den ownCloud-Server zu erlauben.

**Aufgabe**: Erstelle ein Ansible-Playbook, um DNS- und Firewall-Einstellungen in OPNsense zu aktualisieren.

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
           network_devices:
             hosts:
               opnsense:
                 ansible_host: 192.168.30.1
                 ansible_user: root
                 ansible_connection: ssh
                 ansible_network_os: freebsd
       ```

2. **Ansible-Playbook für OPNsense**:
   - Erstelle ein Playbook:
     ```bash
     nano configure_opnsense_owncloud.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure OPNsense for ownCloud
         hosts: network_devices
         tasks:
           - name: Add DNS host override for ownCloud
             ansible.builtin.command: >
               configctl unbound host add owncloud homelab.local 192.168.30.111 "ownCloud File Server"
             register: dns_result
           - name: Add firewall rule for ownCloud HTTP/HTTPS (80, 443)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.111",
                 "destination_port":"80,443",
                 "description":"Allow HTTP/HTTPS to ownCloud"
               }'
             register: firewall_http_result
           - name: Add firewall rule for Webmin (12322)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.111",
                 "destination_port":"12322",
                 "description":"Allow Webmin to ownCloud"
               }'
             register: firewall_webmin_result
           - name: Restart Unbound service
             ansible.builtin.command: configctl unbound restart
           - name: Verify firewall rules
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Test DNS resolution
             ansible.builtin.command: nslookup owncloud.homelab.local 192.168.30.1
             register: nslookup_result
           - name: Display DNS and firewall results
             ansible.builtin.debug:
               msg: "DNS: {{ nslookup_result.stdout }} | Firewall: {{ rules_list.stdout }}"
       ```
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml configure_opnsense_owncloud.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display DNS and firewall results] *****************************************
       ok: [opnsense] => {
           "msg": "DNS: ... owncloud.homelab.local 3600 IN A 192.168.30.111 ... | Firewall: ... Allow HTTP/HTTPS to ownCloud ... Allow Webmin to ownCloud ..."
       }
       ```
   - Prüfe in der OPNsense-Weboberfläche:
     - Gehe zu `Services > Unbound DNS > Overrides > Host`: Eintrag für `owncloud.homelab.local`.
     - Gehe zu `Firewall > Rules > LAN`: Regeln für `192.168.30.111:80,443` und `192.168.30.111:12322`.

**Erkenntnis**: OPNsense Unbound DNS ist ausreichend für die Namensauflösung im HomeLab, und Ansible automatisiert DNS- und Firewall-Konfigurationen.

**Quelle**: https://docs.opnsense.org/manual/unbound.html

## Übung 3: Backup der ownCloud-Daten auf TrueNAS

**Ziel**: Sichere die ownCloud-Konfiguration und Datenbank auf TrueNAS.

**Aufgabe**: Erstelle ein Ansible-Playbook für Backups und begrenze sie auf maximal fünf Versionen.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_owncloud.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup TurnKey ownCloud configuration and data
         hosts: owncloud_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/turnkey-owncloud-install/backups/owncloud"
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
           - name: Limit backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t owncloud-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/turnkey-owncloud-install/
             delegate_to: localhost
           - name: Display backup status
             ansible.builtin.debug:
               msg: "Backup saved to {{ backup_file }} and synced to TrueNAS"
       ```
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_owncloud.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display backup status] ****************************************************
       ok: [owncloud] => {
           "msg": "Backup saved to /home/ubuntu/turnkey-owncloud-install/backups/owncloud/owncloud-backup-<date>.tar.gz and synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/turnkey-owncloud-install/
     ```
     - Erwartete Ausgabe: Maximal fünf `owncloud-backup-<date>.tar.gz`.

2. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/turnkey-owncloud-install
       ansible-playbook -i inventory.yml backup_owncloud.yml >> backup.log 2>&1
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
       0 3 * * * /home/ubuntu/turnkey-owncloud-install/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible automatisiert die Sicherung der ownCloud-Daten, während TrueNAS externe Speicherung bietet.

**Quelle**: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/fetch_module.html

## Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass die Firewall-Regeln aktiv sind (siehe Übung 2).
   - Prüfe OPNsense-Logs:
     ```bash
     ansible-playbook -i inventory.yml -m ansible.builtin.command -a "cat /var/log/system/latest.log" opnsense
     ```

2. **Monitoring mit Checkmk (optional)**:
   - Konfiguriere Checkmk für den ownCloud-Server:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Füge den ownCloud-Server als Host hinzu:
       - Hostname: `owncloud`, IP: `192.168.30.111`.
       - Speichern und `Discover services`.
     - Prüfe Services:
       - Gehe zu `Monitor > All services`.
       - Erwartete Ausgabe: Services wie `apache2`, `mysql`.
     - Erstelle eine benutzerdefinierte Überprüfung für ownCloud:
       ```bash
       nano /omd/sites/homelab/local/share/check_mk/checks/owncloud
       ```
       - Inhalt:
         ```bash
         #!/bin/bash
         curl -s https://192.168.30.111/status.php > /dev/null
         if [ $? -eq 0 ]; then
           echo "0 ownCloud - ownCloud is operational"
         else
           echo "2 ownCloud - ownCloud is not operational"
         fi
         ```
       - Ausführbar machen:
         ```bash
         chmod +x /omd/sites/homelab/local/share/check_mk/checks/owncloud
         ```
       - In Checkmk: `Setup > Services > Manual checks > Custom checks`, füge `ownCloud` hinzu.

## Schritt 5: Erweiterung der Übungen
1. **HTTPS mit Let’s Encrypt**:
   - Erstelle ein Playbook, um Let’s Encrypt für HTTPS zu konfigurieren:
     ```bash
     nano configure_https_owncloud.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure HTTPS for ownCloud
         hosts: owncloud_servers
         become: yes
         tasks:
           - name: Install certbot
             ansible.builtin.apt:
               name: certbot
               state: present
               update_cache: yes
           - name: Obtain Let’s Encrypt certificate
             ansible.builtin.command: >
               certbot certonly --non-interactive --agree-tos --email admin@homelab.local --webroot -w /var/www/owncloud -d owncloud.homelab.local
             register: certbot_result
           - name: Update Apache configuration for HTTPS
             ansible.builtin.blockinfile:
               path: /etc/apache2/sites-available/owncloud.conf
               marker: "# {mark} HTTPS Configuration"
               block: |
                 <VirtualHost *:443>
                   ServerName owncloud.homelab.local
                   DocumentRoot /var/www/owncloud
                   SSLEngine on
                   SSLCertificateFile /etc/letsencrypt/live/owncloud.homelab.local/fullchain.pem
                   SSLCertificateKeyFile /etc/letsencrypt/live/owncloud.homelab.local/privkey.pem
                   <Directory /var/www/owncloud>
                     Options +FollowSymlinks
                     AllowOverride All
                     Require all granted
                   </Directory>
                 </VirtualHost>
           - name: Enable Apache SSL module
             ansible.builtin.command: a2enmod ssl
           - name: Redirect HTTP to HTTPS
             ansible.builtin.blockinfile:
               path: /etc/apache2/sites-available/000-default.conf
               marker: "# {mark} HTTP Redirect"
               block: |
                 <VirtualHost *:80>
                   ServerName owncloud.homelab.local
                   Redirect permanent / https://owncloud.homelab.local/
                 </VirtualHost>
           - name: Restart Apache
             ansible.builtin.service:
               name: apache2
               state: restarted
       ```
   - **Hinweis**: Für Let’s Encrypt muss `owncloud.homelab.local` öffentlich erreichbar sein (z. B. über Port-Forwarding in OPNsense). Alternativ kannst du das selbstsignierte Zertifikat verwenden.

2. **Backup-Versionierung mit Git**:
   - Initialisiere ein Git-Repository für Backups:
     ```bash
     cd ~/turnkey-owncloud-install/backups/owncloud
     git init
     git add .
     git commit -m "Initial ownCloud backup"
     ```

## Best Practices für Schüler

- **ownCloud-Design**:
  - Nutze ownCloud für Dateisynchronisierung und Zusammenarbeit im HomeLab.
  - Konfiguriere Benutzer und Gruppen in der ownCloud-Weboberfläche (`https://192.168.30.111`).
- **Sicherheit**:
  - Schränke Zugriff ein:
    ```bash
    ssh root@192.168.30.111 "ufw allow from 192.168.30.0/24 to any port 80,443,12322"
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
  - Aktiviere HTTPS (siehe Schritt 5.1) oder verwende `turnkey-letsencrypt`:
    ```bash
    ssh root@192.168.30.111 "turnkey-letsencrypt owncloud.homelab.local"
    ```
    - Siehe https://www.turnkeylinux.org/owncloud für Details.
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
  - Teste Backups vor ownCloud-Updates (siehe https://www.turnkeylinux.org/owncloud).
- **Fehlerbehebung**:
  - Prüfe ownCloud-Logs:
    ```bash
    ssh root@192.168.30.111 "cat /var/www/owncloud/data/owncloud.log"
    ```
  - Prüfe Apache-Logs:
    ```bash
    ssh root@192.168.30.111 "cat /var/log/apache2/error.log"
    ```
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/turnkey-owncloud-install/backup.log
    ```

**Quelle**: https://www.turnkeylinux.org/owncloud, https://doc.owncloud.com

## Empfehlungen für Schüler

- **Setup**: TurnKey ownCloud, Proxmox LXC, Ansible, TrueNAS-Backups.
- **Workloads**: ownCloud-Installation, DNS- und Firewall-Konfiguration, Backups.
- **Integration**: Proxmox (LXC), TrueNAS (Backups), OPNsense (DNS, Netzwerk).
- **Beispiel**: Dateisynchronisierungsplattform für HomeLab-Nutzer.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einem einzelnen Benutzer, erweitere zu Gruppen und Apps.
- **Übung**: Teste ownCloud-Desktop- oder Mobile-Clients (siehe https://owncloud.com/download/).
- **Fehlerbehebung**: Nutze `ansible-playbook --check` und `curl` für Tests.
- **Lernressourcen**: https://www.turnkeylinux.org/owncloud, https://doc.owncloud.com, https://docs.ansible.com.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Schnelle Installation eines ownCloud-Servers mit TurnKey.
- **Skalierbarkeit**: Automatisierte DNS-, Firewall- und Backup-Konfigurationen.
- **Lernwert**: Verständnis von Dateisynchronisierung und HomeLab-Integration.

**Nächste Schritte**: Möchtest du eine Anleitung zur Integration von ownCloud mit OpenLDAP für Authentifizierung (ähnlich `turnkey_mattermost_openldap_integration_guide.md`, ), Installation von ownCloud-Apps, oder Monitoring mit Wazuh/Fluentd/Checkmk?

**Quellen**:
- TurnKey Linux ownCloud-Dokumentation: https://www.turnkeylinux.org/owncloud
- ownCloud-Dokumentation: https://doc.owncloud.com
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen: https://www.turnkeylinux.org/owncloud, https://doc.owncloud.com
```