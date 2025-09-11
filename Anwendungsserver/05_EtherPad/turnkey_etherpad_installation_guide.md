# Lernprojekt: Installation eines TurnKey Linux Etherpad-Servers als LXC-Container

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
     - Host: `etherpad`
     - Domäne: `homelab.local`
     - IP: `192.168.30.107`
     - Beschreibung: `Etherpad Server`
   - Teste den DNS-Eintrag:
     ```bash
     nslookup etherpad.homelab.local 192.168.30.1
     ```
     - Erwartete Ausgabe: `192.168.30.107`.
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
     mkdir ~/turnkey-etherpad-install
     cd ~/turnkey-etherpad-install
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Proxmox (`192.168.30.2`), OPNsense (`192.168.30.1`) und TrueNAS (`192.168.30.100`).

## Übung 1: Einrichten des LXC-Containers mit TurnKey Etherpad

**Ziel**: Installiere den TurnKey Linux Etherpad-Server als LXC-Container auf Proxmox.

**Aufgabe**: Lade die TurnKey Etherpad-Vorlage herunter, erstelle einen LXC-Container und konfiguriere die Basis-Einstellungen.

1. **TurnKey Etherpad-Vorlage herunterladen**:
   - Öffne die Proxmox-Weboberfläche.
   - Gehe zu `Storage > local > Content > Templates`.
   - Lade die neueste TurnKey Etherpad-Vorlage herunter:
     - URL: `http://mirror.turnkeylinux.org/turnkeylinux/images/proxmox/debian-12-turnkey-etherpad_18.1-1_amd64.tar.gz`
     - Alternativ per CLI auf dem Proxmox-Host:
       ```bash
       pveam download local debian-12-turnkey-etherpad_18.1-1_amd64.tar.gz
       ```
2. **LXC-Container erstellen**:
   - In Proxmox: `Create CT`:
     - Hostname: `etherpad`
     - Template: `debian-12-turnkey-etherpad_18.1-1_amd64`
     - IP-Adresse: `192.168.30.107/24`
     - Gateway: `192.168.30.1`
     - DNS-Server: `192.168.30.1`
     - Speicher: `local-lvm` oder `local-zfs`
     - CPU: 1 Kern, RAM: 1 GB, Disk: 10 GB
   - Starte den Container:
     - In der Proxmox-Weboberfläche: `etherpad > Start`.
     - Bei der ersten Anmeldung wirst du aufgefordert, die Initialkonfiguration durchzuführen.
3. **Etherpad initial konfigurieren**:
   - Verbinde dich mit dem Container:
     ```bash
     ssh root@192.168.30.107
     ```
   - Führe die Ersteinrichtung durch (TurnKey Firstboot):
     - Setze das Root-Passwort.
     - Setze das MySQL/MariaDB-Root-Passwort (z. B. `securepassword123`).
     - Konfiguriere den Admin-Benutzer für Etherpad (z. B. `admin`, Passwort: `securepassword123`).
     - Installiere Sicherheitsupdates, wenn gefragt.
   - Prüfe den Etherpad-Dienst:
     ```bash
     systemctl status etherpad
     ```
     - Erwartete Ausgabe: `active (running)`.
   - Teste die Weboberfläche:
     ```bash
     curl https://etherpad.homelab.local
     ```
     - Erwartete Ausgabe: HTML der Etherpad-Startseite.
     - Öffne im Browser: `https://192.168.30.107` (ignoriere SSL-Warnungen für selbstsignierte Zertifikate).
   - Teste die Etherpad-API:
     ```bash
     curl http://192.168.30.107:9001/api
     ```
     - Erwartete Ausgabe: JSON-Antwort mit API-Informationen.

**Erkenntnis**: Die TurnKey Etherpad Appliance vereinfacht die Installation eines kollaborativen Texteditors mit Node.js, MySQL/MariaDB und Apache.

**Quelle**: https://www.turnkeylinux.org/etherpad

## Übung 2: Konfiguration von Firewall-Regeln mit Ansible

**Ziel**: Konfiguriere Firewall-Regeln auf OPNsense, um Zugriff auf Etherpad (Ports 80, 443) und die API (Port 9001) zu erlauben.

**Aufgabe**: Erstelle ein Ansible-Playbook, um Firewall-Regeln für den Etherpad-Server zu konfigurieren.

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
     nano configure_firewall_etherpad.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure OPNsense firewall for Etherpad
         hosts: network_devices
         tasks:
           - name: Add firewall rule for Etherpad HTTP/HTTPS (80, 443)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.107",
                 "destination_port":"80,443",
                 "description":"Allow HTTP/HTTPS to Etherpad Server"
               }'
             register: http_result
           - name: Add firewall rule for Etherpad API (9001)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.107",
                 "destination_port":"9001",
                 "description":"Allow Etherpad API"
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
     - Fügt Firewall-Regeln für HTTP/HTTPS (80, 443) und die Etherpad-API (9001) hinzu.
     - Erlaubt Verkehr von `192.168.30.0/24` zu `192.168.30.107`.

3. **Playbook ausführen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml configure_firewall_etherpad.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display firewall rules] ****************************************************
       ok: [opnsense] => {
           "msg": "... Allow HTTP/HTTPS to Etherpad Server ... Allow Etherpad API ..."
       }
       ```
   - Prüfe in der OPNsense-Weboberfläche:
     - Gehe zu `Firewall > Rules > LAN`.
     - Erwartete Regeln: `pass` für `192.168.30.107:80,443` und `192.168.30.107:9001`.

**Erkenntnis**: Ansible automatisiert die Firewall-Konfiguration, um sicheren Zugriff auf den Etherpad-Server zu gewährleisten.

**Quelle**: https://docs.opnsense.org/manual/firewall.html

## Übung 3: Backup der Etherpad-Daten auf TrueNAS

**Ziel**: Sichere die Etherpad-Konfiguration und Datenbank und versioniere sie auf TrueNAS.

**Aufgabe**: Erstelle ein Ansible-Playbook für Backups und begrenze sie auf maximal fünf Versionen.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_etherpad.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup TurnKey Etherpad configuration and data
         hosts: etherpad_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/turnkey-etherpad-install/backups/etherpad"
           backup_file: "{{ backup_dir }}/etherpad-backup-{{ ansible_date_time.date }}.tar.gz"
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
           - name: Backup Etherpad configuration and database
             ansible.builtin.command: >
               tar -czf /tmp/etherpad-backup-{{ ansible_date_time.date }}.tar.gz /etc/etherpad /var/lib/mysql
             register: backup_result
           - name: Start Etherpad service
             ansible.builtin.service:
               name: etherpad
               state: started
           - name: Fetch backup file
             ansible.builtin.fetch:
               src: /tmp/etherpad-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ backup_file }}"
               flat: yes
           - name: Limit backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t etherpad-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/turnkey-etherpad-install/
             delegate_to: localhost
           - name: Display backup status
             ansible.builtin.debug:
               msg: "Backup saved to {{ backup_file }} and synced to TrueNAS"
       ```
   - **Erklärung**:
     - Stoppt den `etherpad`-Dienst, um konsistente Backups zu gewährleisten.
     - Sichert `/etc/etherpad` (Konfiguration) und `/var/lib/mysql` (Datenbank).
     - Begrenzt Backups auf fünf durch Entfernen älterer Dateien.
     - Synchronisiert Backups mit TrueNAS.

2. **Playbook testen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_etherpad.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display backup status] ****************************************************
       ok: [etherpad] => {
           "msg": "Backup saved to /home/ubuntu/turnkey-etherpad-install/backups/etherpad/etherpad-backup-<date>.tar.gz and synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/turnkey-etherpad-install/
     ```
     - Erwartete Ausgabe: Maximal fünf `etherpad-backup-<date>.tar.gz`.

3. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/turnkey-etherpad-install
       ansible-playbook -i inventory.yml backup_etherpad.yml >> backup.log 2>&1
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
       0 3 * * * /home/ubuntu/turnkey-etherpad-install/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible automatisiert die Sicherung der Etherpad-Daten, während TrueNAS externe Speicherung bietet.

**Quelle**: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/fetch_module.html

## Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass die Firewall-Regeln aktiv sind (siehe Übung 2).
   - Prüfe OPNsense-Logs:
     ```bash
     ansible-playbook -i inventory.yml -m ansible.builtin.command -a "cat /var/log/system/latest.log" opnsense
     ```

2. **Monitoring mit Checkmk (optional)**:
   - Konfiguriere Checkmk für den Etherpad-Server:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Füge den Etherpad-Server als Host hinzu:
       - Hostname: `etherpad`, IP: `192.168.30.107`.
       - Speichern und `Discover services`.
     - Prüfe Services:
       - Gehe zu `Monitor > All services`.
       - Erwartete Ausgabe: Services wie `etherpad`, `Apache`, `MySQL`.
     - Erstelle eine benutzerdefinierte Überprüfung für Etherpad:
       ```bash
       nano /omd/sites/homelab/local/share/check_mk/checks/etherpad
       ```
       - Inhalt:
         ```bash
         #!/bin/bash
         curl -s http://192.168.30.107:9001/api > /dev/null
         if [ $? -eq 0 ]; then
           echo "0 Etherpad - Etherpad API is operational"
         else
           echo "2 Etherpad - Etherpad API is not operational"
         fi
         ```
       - Ausführbar machen:
         ```bash
         chmod +x /omd/sites/homelab/local/share/check_mk/checks/etherpad
         ```
       - In Checkmk: `Setup > Services > Manual checks > Custom checks`, füge `Etherpad` hinzu.

## Schritt 5: Erweiterung der Übungen
1. **Erweiterte Etherpad-Konfiguration**:
   - Erstelle ein Playbook, um einen neuen Etherpad-Benutzer hinzuzufügen:
     ```bash
     nano add_etherpad_user.yml
     ```
     - Inhalt:
       ```yaml
       - name: Add user to Etherpad
         hosts: etherpad_servers
         become: yes
         vars:
           etherpad_user: "testuser"
           etherpad_password: "SecurePass123!"
         tasks:
           - name: Add Etherpad user to database
             ansible.builtin.command: >
               mysql -u root -p{{ etherpad_password }} etherpad -e "INSERT INTO users (name, password) VALUES ('{{ etherpad_user }}', '{{ etherpad_password }}')"
             register: user_result
           - name: Display user creation status
             ansible.builtin.debug:
               msg: "{{ user_result.stdout }}"
       ```
     - **Hinweis**: Passe das MySQL-Passwort an die Ersteinrichtung an.

2. **Backup-Versionierung mit Git**:
   - Initialisiere ein Git-Repository für Backups:
     ```bash
     cd ~/turnkey-etherpad-install/backups/etherpad
     git init
     git add .
     git commit -m "Initial Etherpad backup"
     ```

## Best Practices für Schüler

- **Etherpad-Design**:
  - Verwende HTTPS (Port 443) für sicheren Zugriff.
  - Nutze die API für erweiterte Integrationen.
- **Sicherheit**:
  - Schränke Zugriff ein:
    ```bash
    ssh root@192.168.30.107 "ufw allow from 192.168.30.0/24 to any port 80,443,9001"
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
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/turnkey-etherpad-install/backup.log
    ```

**Quelle**: https://www.turnkeylinux.org/etherpad, https://etherpad.org/doc.html

## Empfehlungen für Schüler

- **Setup**: TurnKey Etherpad, Proxmox LXC, Ansible, TrueNAS-Backups.
- **Workloads**: Etherpad-Installation, Firewall-Konfiguration, Backups.
- **Integration**: Proxmox (LXC), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Kollaborativer Texteditor für Teamarbeit.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einem einfachen Pad, erweitere zu Benutzer- und Plugin-Verwaltung.
- **Übung**: Experimentiere mit Etherpad-Plugins (z. B. `ep_comments_page`).
- **Fehlerbehebung**: Nutze `ansible-playbook --check` und `curl` für API-Tests.
- **Lernressourcen**: https://www.turnkeylinux.org/etherpad, https://etherpad.org/doc.html, https://docs.ansible.com.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Schnelle Installation eines Etherpad-Servers mit TurnKey.
- **Skalierbarkeit**: Automatisierte Firewall- und Backup-Konfigurationen.
- **Lernwert**: Verständnis von kollaborativen Tools und HomeLab-Integration.

**Nächste Schritte**: Möchtest du eine Anleitung zur Integration mit OpenLDAP für Authentifizierung, Log-Aggregation mit Fluentd, oder erweitertem Monitoring mit Checkmk?

**Quellen**:
- TurnKey Linux Etherpad-Dokumentation: https://www.turnkeylinux.org/etherpad
- Etherpad-Dokumentation: https://etherpad.org/doc.html
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,
```