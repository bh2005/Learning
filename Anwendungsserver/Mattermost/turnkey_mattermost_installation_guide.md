# Lernprojekt: Installation eines TurnKey Linux Mattermost-Servers als LXC-Container

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
     - Host: `mattermost`
     - Domäne: `homelab.local`
     - IP: `192.168.30.108`
     - Beschreibung: `Mattermost Server`
   - Teste den DNS-Eintrag:
     ```bash
     nslookup mattermost.homelab.local 192.168.30.1
     ```
     - Erwartete Ausgabe: `192.168.30.108`.
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
     mkdir ~/turnkey-mattermost-install
     cd ~/turnkey-mattermost-install
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Proxmox (`192.168.30.2`), OPNsense (`192.168.30.1`) und TrueNAS (`192.168.30.100`).

## Übung 1: Einrichten des LXC-Containers mit TurnKey Mattermost

**Ziel**: Installiere den TurnKey Linux Mattermost-Server als LXC-Container auf Proxmox.

**Aufgabe**: Lade die TurnKey Mattermost-Vorlage herunter, erstelle einen LXC-Container und konfiguriere die Basis-Einstellungen.

1. **TurnKey Mattermost-Vorlage herunterladen**:
   - Öffne die Proxmox-Weboberfläche.
   - Gehe zu `Storage > local > Content > Templates`.
   - Lade die neueste TurnKey Mattermost-Vorlage herunter:
     - URL: `http://mirror.turnkeylinux.org/turnkeylinux/images/proxmox/debian-12-turnkey-mattermost_18.1-1_amd64.tar.gz`
     - Alternativ per CLI auf dem Proxmox-Host:
       ```bash
       pveam download local debian-12-turnkey-mattermost_18.1-1_amd64.tar.gz
       ```
2. **LXC-Container erstellen**:
   - In Proxmox: `Create CT`:
     - Hostname: `mattermost`
     - Template: `debian-12-turnkey-mattermost_18.1-1_amd64`
     - IP-Adresse: `192.168.30.108/24`
     - Gateway: `192.168.30.1`
     - DNS-Server: `192.168.30.1`
     - Speicher: `local-lvm` oder `local-zfs`
     - CPU: 2 Kerne, RAM: 2 GB, Disk: 20 GB
   - Starte den Container:
     - In der Proxmox-Weboberfläche: `mattermost > Start`.
     - Bei der ersten Anmeldung wirst du aufgefordert, die Initialkonfiguration durchzuführen.
3. **Mattermost initial konfigurieren**:
   - Verbinde dich mit dem Container:
     ```bash
     ssh root@192.168.30.108
     ```
   - Führe die Ersteinrichtung durch (TurnKey Firstboot):
     - Setze das Root-Passwort.
     - Setze das PostgreSQL-Root-Passwort (z. B. `securepassword123`).
     - Konfiguriere den Admin-Benutzer für Mattermost (z. B. `admin`, Passwort: `securepassword123`).
     - Installiere Sicherheitsupdates, wenn gefragt.
   - Prüfe den Mattermost-Dienst:
     ```bash
     systemctl status mattermost
     ```
     - Erwartete Ausgabe: `active (running)`.
   - Teste die Weboberfläche:
     ```bash
     curl https://mattermost.homelab.local
     ```
     - Erwartete Ausgabe: HTML der Mattermost-Anmeldeseite.
     - Öffne im Browser: `https://192.168.30.108` (ignoriere SSL-Warnungen für selbstsignierte Zertifikate).
   - Teste die Mattermost-API:
     ```bash
     curl https://192.168.30.108:8065/api/v4/system/ping
     ```
     - Erwartete Ausgabe: JSON-Antwort wie `{"status":"OK"}`.

**Erkenntnis**: Die TurnKey Mattermost Appliance vereinfacht die Installation einer Team-Kommunikationsplattform mit PostgreSQL und Nginx.

**Quelle**: https://www.turnkeylinux.org/mattermost

## Übung 2: Konfiguration von Firewall-Regeln mit Ansible

**Ziel**: Konfiguriere Firewall-Regeln auf OPNsense, um Zugriff auf Mattermost (Ports 80, 443, 8065) zu erlauben.

**Aufgabe**: Erstelle ein Ansible-Playbook, um Firewall-Regeln für den Mattermost-Server zu konfigurieren.

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
     nano configure_firewall_mattermost.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure OPNsense firewall for Mattermost
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
             register: http_result
           - name: Add firewall rule for Mattermost Admin Console and API (8065)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.108",
                 "destination_port":"8065",
                 "description":"Allow Mattermost Admin Console and API"
               }'
             register: api_result
           - name: Verify firewall rules
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Display firewall rules
             ansible.builtin.debug:
               msg: "{{ rules_list.stdout }}"
       ```
   - **Erklärung**:
     - Fügt Firewall-Regeln für HTTP/HTTPS (80, 443) und die Mattermost Admin Console/API (8065) hinzu.
     - Erlaubt Verkehr von `192.168.30.0/24` zu `192.168.30.108`.

3. **Playbook ausführen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml configure_firewall_mattermost.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display firewall rules] ****************************************************
       ok: [opnsense] => {
           "msg": "... Allow HTTP/HTTPS to Mattermost Server ... Allow Mattermost Admin Console and API ..."
       }
       ```
   - Prüfe in der OPNsense-Weboberfläche:
     - Gehe zu `Firewall > Rules > LAN`.
     - Erwartete Regeln: `pass` für `192.168.30.108:80,443` und `192.168.30.108:8065`.

**Erkenntnis**: Ansible automatisiert die Firewall-Konfiguration, um sicheren Zugriff auf den Mattermost-Server zu gewährleisten.

**Quelle**: https://docs.opnsense.org/manual/firewall.html

## Übung 3: Backup der Mattermost-Daten auf TrueNAS

**Ziel**: Sichere die Mattermost-Konfiguration und Datenbank und versioniere sie auf TrueNAS.

**Aufgabe**: Erstelle ein Ansible-Playbook für Backups und begrenze sie auf maximal fünf Versionen.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_mattermost.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup TurnKey Mattermost configuration and data
         hosts: mattermost_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/turnkey-mattermost-install/backups/mattermost"
           backup_file: "{{ backup_dir }}/mattermost-backup-{{ ansible_date_time.date }}.tar.gz"
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
           - name: Backup Mattermost configuration and database
             ansible.builtin.command: >
               tar -czf /tmp/mattermost-backup-{{ ansible_date_time.date }}.tar.gz /opt/mattermost /var/lib/postgresql
             register: backup_result
           - name: Start Mattermost service
             ansible.builtin.service:
               name: mattermost
               state: started
           - name: Fetch backup file
             ansible.builtin.fetch:
               src: /tmp/mattermost-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ backup_file }}"
               flat: yes
           - name: Limit backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t mattermost-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/turnkey-mattermost-install/
             delegate_to: localhost
           - name: Display backup status
             ansible.builtin.debug:
               msg: "Backup saved to {{ backup_file }} and synced to TrueNAS"
       ```
   - **Erklärung**:
     - Stoppt den `mattermost`-Dienst, um konsistente Backups zu gewährleisten.
     - Sichert `/opt/mattermost` (Konfiguration, Daten) und `/var/lib/postgresql` (Datenbank).
     - Begrenzt Backups auf fünf durch Entfernen älterer Dateien.
     - Synchronisiert Backups mit TrueNAS.

2. **Playbook testen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_mattermost.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display backup status] ****************************************************
       ok: [mattermost] => {
           "msg": "Backup saved to /home/ubuntu/turnkey-mattermost-install/backups/mattermost/mattermost-backup-<date>.tar.gz and synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/turnkey-mattermost-install/
     ```
     - Erwartete Ausgabe: Maximal fünf `mattermost-backup-<date>.tar.gz`.

3. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/turnkey-mattermost-install
       ansible-playbook -i inventory.yml backup_mattermost.yml >> backup.log 2>&1
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
       0 3 * * * /home/ubuntu/turnkey-mattermost-install/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible automatisiert die Sicherung der Mattermost-Daten, während TrueNAS externe Speicherung bietet.

**Quelle**: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/fetch_module.html

## Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass die Firewall-Regeln aktiv sind (siehe Übung 2).
   - Prüfe OPNsense-Logs:
     ```bash
     ansible-playbook -i inventory.yml -m ansible.builtin.command -a "cat /var/log/system/latest.log" opnsense
     ```

2. **Monitoring mit Checkmk (optional)**:
   - Konfiguriere Checkmk für den Mattermost-Server:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Füge den Mattermost-Server als Host hinzu:
       - Hostname: `mattermost`, IP: `192.168.30.108`.
       - Speichern und `Discover services`.
     - Prüfe Services:
       - Gehe zu `Monitor > All services`.
       - Erwartete Ausgabe: Services wie `mattermost`, `nginx`, `postgresql`.
     - Erstelle eine benutzerdefinierte Überprüfung für Mattermost:
       ```bash
       nano /omd/sites/homelab/local/share/check_mk/checks/mattermost
       ```
       - Inhalt:
         ```bash
         #!/bin/bash
         curl -s https://192.168.30.108:8065/api/v4/system/ping > /dev/null
         if [ $? -eq 0 ]; then
           echo "0 Mattermost - Mattermost API is operational"
         else
           echo "2 Mattermost - Mattermost API is not operational"
         fi
         ```
       - Ausführbar machen:
         ```bash
         chmod +x /omd/sites/homelab/local/share/check_mk/checks/mattermost
         ```
       - In Checkmk: `Setup > Services > Manual checks > Custom checks`, füge `Mattermost` hinzu.

## Schritt 5: Erweiterung der Übungen
1. **Erweiterte Mattermost-Konfiguration**:
   - Erstelle ein Playbook, um einen neuen Mattermost-Benutzer hinzuzufügen:
     ```bash
     nano add_mattermost_user.yml
     ```
     - Inhalt:
       ```yaml
       - name: Add user to Mattermost
         hosts: mattermost_servers
         become: yes
         vars:
           mattermost_user: "testuser"
           mattermost_password: "SecurePass123!"
           mattermost_email: "testuser@homelab.local"
         tasks:
           - name: Add Mattermost user
             ansible.builtin.command: >
               /opt/mattermost/bin/mattermost user create --username {{ mattermost_user }} --password {{ mattermost_password }} --email {{ mattermost_email }}
             register: user_result
           - name: Display user creation status
             ansible.builtin.debug:
               msg: "{{ user_result.stdout }}"
       ```
     - **Hinweis**: Dies fügt einen lokalen Benutzer hinzu. Für LDAP-Benutzer siehe `turnkey_mattermost_openldap_integration_guide.md` ().

2. **Backup-Versionierung mit Git**:
   - Initialisiere ein Git-Repository für Backups:
     ```bash
     cd ~/turnkey-mattermost-install/backups/mattermost
     git init
     git add .
     git commit -m "Initial Mattermost backup"
     ```

## Best Practices für Schüler

- **Mattermost-Design**:
  - Verwende HTTPS (Port 443) für sicheren Zugriff.
  - Nutze die API (Port 8065) für erweiterte Integrationen.
- **Sicherheit**:
  - Schränke Zugriff ein:
    ```bash
    ssh root@192.168.30.108 "ufw allow from 192.168.30.0/24 to any port 80,443,8065"
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
  - Ersetze selbstsignierte Zertifikate durch Let’s Encrypt:
    ```bash
    ssh root@192.168.30.108 "turnkey-letsencrypt mattermost.homelab.local"
    ```
    - Siehe https://www.turnkeylinux.org/mattermost für Details.
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
  - Beachte, dass Mattermost-Backups vor Updates getestet werden sollten (siehe https://www.turnkeylinux.org/mattermost).
- **Fehlerbehebung**:
  - Prüfe Mattermost-Logs:
    ```bash
    ssh root@192.168.30.108 "cat /opt/mattermost/logs/mattermost.log"
    ```
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/turnkey-mattermost-install/backup.log
    ```

**Quelle**: https://www.turnkeylinux.org/mattermost, https://docs.mattermost.com

## Empfehlungen für Schüler

- **Setup**: TurnKey Mattermost, Proxmox LXC, Ansible, TrueNAS-Backups.
- **Workloads**: Mattermost-Installation, Firewall-Konfiguration, Backups.
- **Integration**: Proxmox (LXC), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Team-Kommunikationsplattform für Zusammenarbeit.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einem einfachen Kanal, erweitere zu Plugins und Integrationen.
- **Übung**: Experimentiere mit Mattermost-Plugins (z. B. `mattermost-plugin-gitlab`).
- **Fehlerbehebung**: Nutze `ansible-playbook --check` und `curl` für API-Tests.
- **Lernressourcen**: https://www.turnkeylinux.org/mattermost, https://docs.mattermost.com, https://docs.ansible.com.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Schnelle Installation eines Mattermost-Servers mit TurnKey.
- **Skalierbarkeit**: Automatisierte Firewall- und Backup-Konfigurationen.
- **Lernwert**: Verständnis von Team-Kommunikationsplattformen und HomeLab-Integration.

**Nächste Schritte**: Möchtest du eine Anleitung zur Integration mit OpenLDAP für Authentifizierung (siehe `turnkey_mattermost_openldap_integration_guide.md`, ), Installation von Mattermost-Plugins, oder Monitoring mit Wazuh/Fluentd/Checkmk?

**Quellen**:
- TurnKey Linux Mattermost-Dokumentation: https://www.turnkeylinux.org/mattermost
- Mattermost-Dokumentation: https://docs.mattermost.com
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen: https://www.turnkeylinux.org/mattermost, https://docs.mattermost.com
```