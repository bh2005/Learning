# Lernprojekt: Installation von TurnKey Linux GNU social in einer HomeLab-Umgebung

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
     - Host: `gnusocial`
     - Domäne: `homelab.local`
     - IP: `192.168.30.112`
     - Beschreibung: `GNU social Microblogging Server`
   - Teste den DNS-Eintrag:
     ```bash
     nslookup gnusocial.homelab.local 192.168.30.1
     ```
     - Erwartete Ausgabe: `192.168.30.112`.
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
     mkdir ~/turnkey-gnusocial-install
     cd ~/turnkey-gnusocial-install
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Proxmox (`192.168.30.2`), OPNsense (`192.168.30.1`) und TrueNAS (`192.168.30.100`).

## Übung 1: Einrichten des LXC-Containers mit TurnKey GNU social

**Ziel**: Installiere den TurnKey GNU social-Server als LXC-Container auf Proxmox.

**Aufgabe**: Lade die TurnKey GNU social-Vorlage herunter, erstelle einen LXC-Container und konfiguriere die Basis-Einstellungen.

1. **TurnKey GNU social-Vorlage herunterladen**:
   - Öffne die Proxmox-Weboberfläche.
   - Gehe zu `Storage > local > Content > Templates`.
   - Lade die neueste TurnKey GNU social-Vorlage herunter (Version 17.1, basierend auf Debian Bullseye):
     - URL: `http://mirror.turnkeylinux.org/turnkeylinux/images/proxmox/debian-11-turnkey-gnusocial_17.1-1_amd64.tar.gz`
     - Alternativ per CLI auf dem Proxmox-Host:
       ```bash
       pveam download local debian-11-turnkey-gnusocial_17.1-1_amd64.tar.gz
       ```
       - Quelle:[](https://mirror.servercomplete.com/turnkeylinux/metadata/turnkey-gnusocial/17.1-bullseye-amd64/)
2. **LXC-Container erstellen**:
   - In Proxmox: `Create CT`:
     - Hostname: `gnusocial`
     - Template: `debian-11-turnkey-gnusocial_17.1-1_amd64`
     - IP-Adresse: `192.168.30.112/24`
     - Gateway: `192.168.30.1`
     - DNS-Server: `192.168.30.1`
     - Speicher: `local-lvm` oder `local-zfs`
     - CPU: 2 Kerne, RAM: 2 GB, Disk: 20 GB
   - Starte den Container:
     - In der Proxmox-Weboberfläche: `gnusocial > Start`.
     - Bei der ersten Anmeldung wirst du aufgefordert, die Initialkonfiguration durchzuführen.
3. **GNU social initial konfigurieren**:
   - Verbinde dich mit dem Container:
     ```bash
     ssh root@192.168.30.112
     ```
   - Führe die Ersteinrichtung durch (TurnKey Firstboot):
     - Setze das Root-Passwort.
     - Setze das MariaDB-Root-Passwort (z. B. `securepassword123`).
     - Setze den GNU social-Admin-Benutzer (z. B. `admin`, Passwort: `securepassword123`, E-Mail: `admin@homelab.local`).
     - Gib die Domäne an: `gnusocial.homelab.local`.
     - Installiere Sicherheitsupdates, wenn gefragt.
   - Prüfe den Apache-Dienst:
     ```bash
     systemctl status apache2
     ```
     - Erwartete Ausgabe: `active (running)`.
   - Teste die Weboberfläche:
     ```bash
     curl https://gnusocial.homelab.local
     ```
     - Erwartete Ausgabe: HTML der GNU social-Anmeldeseite.
     - Öffne im Browser: `https://192.168.30.112` (ignoriere SSL-Warnungen für selbstsignierte Zertifikate).
   - Teste die Adminer-Oberfläche:
     ```bash
     curl https://192.168.30.112:12322
     ```
     - Erwartete Ausgabe: HTML der Adminer-Anmeldeseite.
     - Öffne im Browser: `https://192.168.30.112:12322`.

**Erkenntnis**: Die TurnKey GNU social Appliance vereinfacht die Installation einer Mikroblogging-Plattform mit Apache und MariaDB, aber die veraltete Software erfordert Vorsicht (letzte stabile Version 2014, siehe).[](https://github.com/turnkeylinux/tracker/issues/1567)

**Quelle**: https://www.turnkeylinux.org/gnusocial,[](https://www.turnkeylinux.org/gnusocial)

## Übung 2: Konfiguration von OPNsense-DNS und Firewall-Regeln

**Ziel**: Konfiguriere OPNsense, um `gnusocial.homelab.local` aufzulösen und den Zugriff auf den GNU social-Server zu erlauben.

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
           gnusocial_servers:
             hosts:
               gnusocial:
                 ansible_host: 192.168.30.112
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
     nano configure_opnsense_gnusocial.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure OPNsense for GNU social
         hosts: network_devices
         tasks:
           - name: Add DNS host override for GNU social
             ansible.builtin.command: >
               configctl unbound host add gnusocial homelab.local 192.168.30.112 "GNU social Microblogging Server"
             register: dns_result
           - name: Add firewall rule for GNU social HTTP/HTTPS (80, 443)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.112",
                 "destination_port":"80,443",
                 "description":"Allow HTTP/HTTPS to GNU social"
               }'
             register: firewall_http_result
           - name: Add firewall rule for Adminer (12322)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.112",
                 "destination_port":"12322",
                 "description":"Allow Adminer to GNU social"
               }'
             register: firewall_adminer_result
           - name: Restart Unbound service
             ansible.builtin.command: configctl unbound restart
           - name: Verify firewall rules
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Test DNS resolution
             ansible.builtin.command: nslookup gnusocial.homelab.local 192.168.30.1
             register: nslookup_result
           - name: Display DNS and firewall results
             ansible.builtin.debug:
               msg: "DNS: {{ nslookup_result.stdout }} | Firewall: {{ rules_list.stdout }}"
       ```
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml configure_opnsense_gnusocial.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display DNS and firewall results] *****************************************
       ok: [opnsense] => {
           "msg": "DNS: ... gnusocial.homelab.local 3600 IN A 192.168.30.112 ... | Firewall: ... Allow HTTP/HTTPS to GNU social ... Allow Adminer to GNU social ..."
       }
       ```
   - Prüfe in der OPNsense-Weboberfläche:
     - Gehe zu `Services > Unbound DNS > Overrides > Host`: Eintrag für `gnusocial.homelab.local`.
     - Gehe zu `Firewall > Rules > LAN`: Regeln für `192.168.30.112:80,443` und `192.168.30.112:12322`.

**Erkenntnis**: OPNsense Unbound DNS ist ausreichend für die Namensauflösung im HomeLab, und Ansible automatisiert DNS- und Firewall-Konfigurationen.

**Quelle**: https://docs.opnsense.org/manual/unbound.html

## Übung 3: Backup der GNU social-Daten auf TrueNAS

**Ziel**: Sichere die GNU social-Konfiguration und Datenbank auf TrueNAS.

**Aufgabe**: Erstelle ein Ansible-Playbook für Backups und begrenze sie auf maximal fünf Versionen.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_gnusocial.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup TurnKey GNU social configuration and data
         hosts: gnusocial_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/turnkey-gnusocial-install/backups/gnusocial"
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
           - name: Limit backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t gnusocial-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/turnkey-gnusocial-install/
             delegate_to: localhost
           - name: Display backup status
             ansible.builtin.debug:
               msg: "Backup saved to {{ backup_file }} and synced to TrueNAS"
       ```
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_gnusocial.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display backup status] ****************************************************
       ok: [gnusocial] => {
           "msg": "Backup saved to /home/ubuntu/turnkey-gnusocial-install/backups/gnusocial/gnusocial-backup-<date>.tar.gz and synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/turnkey-gnusocial-install/
     ```
     - Erwartete Ausgabe: Maximal fünf `gnusocial-backup-<date>.tar.gz`.

2. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/turnkey-gnusocial-install
       ansible-playbook -i inventory.yml backup_gnusocial.yml >> backup.log 2>&1
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
       0 3 * * * /home/ubuntu/turnkey-gnusocial-install/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible automatisiert die Sicherung der GNU social-Daten, während TrueNAS externe Speicherung bietet.

**Quelle**: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/fetch_module.html

## Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass die Firewall-Regeln aktiv sind (siehe Übung 2).
   - Prüfe OPNsense-Logs:
     ```bash
     ansible-playbook -i inventory.yml -m ansible.builtin.command -a "cat /var/log/system/latest.log" opnsense
     ```

2. **Monitoring mit Checkmk (optional)**:
   - Konfiguriere Checkmk für den GNU social-Server:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Füge den GNU social-Server als Host hinzu:
       - Hostname: `gnusocial`, IP: `192.168.30.112`.
       - Speichern und `Discover services`.
     - Prüfe Services:
       - Gehe zu `Monitor > All services`.
       - Erwartete Ausgabe: Services wie `apache2`, `mysql`.
     - Erstelle eine benutzerdefinierte Überprüfung für GNU social:
       ```bash
       nano /omd/sites/homelab/local/share/check_mk/checks/gnusocial
       ```
       - Inhalt:
         ```bash
         #!/bin/bash
         curl -s https://192.168.30.112 > /dev/null
         if [ $? -eq 0 ]; then
           echo "0 GNU_social - GNU social is operational"
         else
           echo "2 GNU_social - GNU social is not operational"
         fi
         ```
       - Ausführbar machen:
         ```bash
         chmod +x /omd/sites/homelab/local/share/check_mk/checks/gnusocial
         ```
       - In Checkmk: `Setup > Services > Manual checks > Custom checks`, füge `GNU_social` hinzu.

## Schritt 5: Erweiterung der Übungen
1. **HTTPS mit Let’s Encrypt**:
   - Erstelle ein Playbook, um Let’s Encrypt für HTTPS zu konfigurieren:
     ```bash
     nano configure_https_gnusocial.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure HTTPS for GNU social
         hosts: gnusocial_servers
         become: yes
         tasks:
           - name: Install certbot
             ansible.builtin.apt:
               name: certbot
               state: present
               update_cache: yes
           - name: Obtain Let’s Encrypt certificate
             ansible.builtin.command: >
               certbot certonly --non-interactive --agree-tos --email admin@homelab.local --webroot -w /var/www/gnusocial -d gnusocial.homelab.local
             register: certbot_result
           - name: Update Apache configuration for HTTPS
             ansible.builtin.blockinfile:
               path: /etc/apache2/sites-available/gnusocial.conf
               marker: "# {mark} HTTPS Configuration"
               block: |
                 <VirtualHost *:443>
                   ServerName gnusocial.homelab.local
                   DocumentRoot /var/www/gnusocial
                   SSLEngine on
                   SSLCertificateFile /etc/letsencrypt/live/gnusocial.homelab.local/fullchain.pem
                   SSLCertificateKeyFile /etc/letsencrypt/live/gnusocial.homelab.local/privkey.pem
                   <Directory /var/www/gnusocial>
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
                   ServerName gnusocial.homelab.local
                   Redirect permanent / https://gnusocial.homelab.local/
                 </VirtualHost>
           - name: Restart Apache
             ansible.builtin.service:
               name: apache2
               state: restarted
       ```
   - **Hinweis**: Für Let’s Encrypt muss `gnusocial.homelab.local` öffentlich erreichbar sein (z. B. über Port-Forwarding in OPNsense). Alternativ kannst du das selbstsignierte Zertifikat verwenden (siehe).[](https://www.turnkeylinux.org/gnusocial)

2. **Backup-Versionierung mit Git**:
   - Initialisiere ein Git-Repository für Backups:
     ```bash
     cd ~/turnkey-gnusocial-install/backups/gnusocial
     git init
     git add .
     git commit -m "Initial GNU social backup"
     ```

## Best Practices für Schüler

- **GNU social-Design**:
  - Nutze GNU social für Mikroblogging und Integration mit anderen Plattformen (z. B. Twitter, XMPP).
  - Konfiguriere Benutzer und Gruppen in der GNU social-Weboberfläche (`https://gnusocial.homelab.local`).
- **Sicherheit**:
  - Schränke Zugriff ein:
    ```bash
    ssh root@192.168.30.112 "ufw allow from 192.168.30.0/24 to any port 80,443,12322"
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
  - Aktiviere HTTPS (siehe Schritt 5.1) oder verwende `turnkey-letsencrypt`:
    ```bash
    ssh root@192.168.30.112 "turnkey-letsencrypt gnusocial.homelab.local"
    ```
    - Siehe https://www.turnkeylinux.org/gnusocial für Details.
  - Überwache Sicherheitsupdates manuell, da GNU social veraltet ist (letzte stabile Version 2014, siehe).[](https://github.com/turnkeylinux/tracker/issues/1567)
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
  - Teste Backups vor GNU social-Updates (siehe https://www.turnkeylinux.org/gnusocial).
- **Fehlerbehebung**:
  - Prüfe GNU social-Logs:
    ```bash
    ssh root@192.168.30.112 "cat /var/www/gnusocial/log/*"
    ```
  - Prüfe Apache-Logs:
    ```bash
    ssh root@192.168.30.112 "cat /var/log/apache2/error.log"
    ```
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/turnkey-gnusocial-install/backup.log
    ```

**Quelle**: https://www.turnkeylinux.org/gnusocial, https://docs.gnusocial.rocks,,[](https://www.turnkeylinux.org/gnusocial)[](https://github.com/turnkeylinux-apps/gnusocial)

## Empfehlungen für Schüler

- **Setup**: TurnKey GNU social, Proxmox LXC, Ansible, TrueNAS-Backups.
- **Workloads**: GNU social-Installation, DNS- und Firewall-Konfiguration, Backups.
- **Integration**: Proxmox (LXC), TrueNAS (Backups), OPNsense (DNS, Netzwerk).
- **Beispiel**: Mikroblogging-Plattform für HomeLab-Nutzer.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einem einzelnen Benutzer, erweitere zu Gruppen und Integrationen.
- **Übung**: Teste GNU social mit Posts und Integrationen (z. B. Twitter, XMPP).
- **Fehlerbehebung**: Nutze `ansible-playbook --check` und `curl` für Tests.
- **Lernressourcen**: https://www.turnkeylinux.org/gnusocial, https://docs.gnusocial.rocks, https://docs.ansible.com.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Schnelle Installation eines GNU social-Servers mit TurnKey.
- **Skalierbarkeit**: Automatisierte DNS-, Firewall- und Backup-Konfigurationen.
- **Lernwert**: Verständnis von Mikroblogging und HomeLab-Integration.
- **Warnung**: GNU social ist veraltet (letzte stabile Version 2014), daher nur für Lernzwecke oder isolierte Umgebungen verwenden (siehe).[](https://github.com/turnkeylinux/tracker/issues/1567)

**Nächste Schritte**: Möchtest du eine Anleitung zur Integration von GNU social mit OpenLDAP für Authentifizierung (ähnlich `turnkey_owncloud_openldap_integration_guide.md`, ), Integration mit anderen Plattformen (z. B. Twitter), oder Monitoring mit Wazuh/Fluentd/Checkmk?

**Quellen**:
- TurnKey Linux GNU social-Dokumentation: https://www.turnkeylinux.org/gnusocial
- GNU social-Dokumentation: https://docs.gnusocial.rocks
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen: https://www.turnkeylinux.org/gnusocial, https://docs.gnusocial.rocks,,,[](https://www.turnkeylinux.org/gnusocial)[](https://github.com/turnkeylinux-apps/gnusocial)[](https://github.com/turnkeylinux/tracker/issues/1567)
```