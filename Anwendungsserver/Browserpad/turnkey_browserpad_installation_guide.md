
# Lernprojekt: Installation von BrowserPad in einer HomeLab-Umgebung mit OPNsense DNS

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
     - Host: `browserpad`
     - Domäne: `homelab.local`
     - IP: `192.168.30.110`
     - Beschreibung: `BrowserPad Web Editor`
   - Teste den DNS-Eintrag:
     ```bash
     nslookup browserpad.homelab.local 192.168.30.1
     ```
     - Erwartete Ausgabe: `192.168.30.110`.
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
     mkdir ~/turnkey-browserpad-install
     cd ~/turnkey-browserpad-install
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Proxmox (`192.168.30.2`), OPNsense (`192.168.30.1`) und TrueNAS (`192.168.30.100`).

## Übung 1: Einrichten eines LXC-Containers mit Nginx zum Hosten von BrowserPad

**Ziel**: Installiere einen Nginx-Webserver in einem LXC-Container und hoste die BrowserPad-Dateien.

**Aufgabe**: Erstelle einen Debian-basierten LXC-Container, installiere Nginx, lade BrowserPad von GitHub herunter und konfiguriere den Webserver.

1. **Debian LXC-Vorlage herunterladen**:
   - Öffne die Proxmox-Weboberfläche.
   - Gehe zu `Storage > local > Content > Templates`.
   - Lade eine Debian 12-Vorlage herunter:
     ```bash
     pveam download local debian-12-standard_12.7-1_amd64.tar.gz
     ```
2. **LXC-Container erstellen**:
   - In Proxmox: `Create CT`:
     - Hostname: `browserpad`
     - Template: `debian-12-standard_12.7-1_amd64`
     - IP-Adresse: `192.168.30.110/24`
     - Gateway: `192.168.30.1`
     - DNS-Server: `192.168.30.1`
     - Speicher: `local-lvm` oder `local-zfs`
     - CPU: 1 Kern, RAM: 512 MB, Disk: 8 GB
   - Starte den Container:
     - In der Proxmox-Weboberfläche: `browserpad > Start`.
3. **Nginx und BrowserPad installieren**:
   - Erstelle ein Ansible-Playbook:
     ```bash
     nano install_browserpad.yml
     ```
     - Inhalt:
       ```yaml
       - name: Install Nginx and BrowserPad
         hosts: browserpad_servers
         become: yes
         vars:
           browserpad_dir: "/var/www/browserpad"
         tasks:
           - name: Update apt cache
             ansible.builtin.apt:
               update_cache: yes
           - name: Install Nginx and Git
             ansible.builtin.apt:
               name:
                 - nginx
                 - git
               state: present
           - name: Create BrowserPad directory
             ansible.builtin.file:
               path: "{{ browserpad_dir }}"
               state: directory
               mode: '0755'
           - name: Download BrowserPad from GitHub
             ansible.builtin.git:
               repo: https://github.com/GlitchLinux/BrowserPad.git
               dest: "{{ browserpad_dir }}"
               version: main
           - name: Configure Nginx for BrowserPad
             ansible.builtin.copy:
               dest: /etc/nginx/sites-available/browserpad
               content: |
                 server {
                   listen 80;
                   server_name browserpad.homelab.local;
                   root {{ browserpad_dir }};
                   index editor.html;
                   location / {
                     try_files $uri $uri/ /editor.html;
                   }
                 }
           - name: Enable Nginx site
             ansible.builtin.file:
               src: /etc/nginx/sites-available/browserpad
               dest: /etc/nginx/sites-enabled/browserpad
               state: link
           - name: Remove default Nginx site
             ansible.builtin.file:
               path: /etc/nginx/sites-enabled/default
               state: absent
           - name: Restart Nginx
             ansible.builtin.service:
               name: nginx
               state: restarted
           - name: Test BrowserPad access
             ansible.builtin.command: curl http://browserpad.homelab.local
             register: curl_result
           - name: Display BrowserPad test result
             ansible.builtin.debug:
               msg: "{{ curl_result.stdout }}"
       ```
   - Erstelle ein Inventar:
     ```bash
     nano inventory.yml
     ```
     - Inhalt:
       ```yaml
       all:
         children:
           browserpad_servers:
             hosts:
               browserpad:
                 ansible_host: 192.168.30.110
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
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml install_browserpad.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display BrowserPad test result] *******************************************
       ok: [browserpad] => {
           "msg": "<html> ... <title>BrowserPad</title> ..."
       }
       ```
   - Teste im Browser:
     - Öffne `http://browserpad.homelab.local`.
     - Erwartete Ausgabe: BrowserPad-Oberfläche mit CodeMirror-Editor.

**Erkenntnis**: BrowserPad ist ein leichtgewichtiger, clientseitiger Editor, der einfach über Nginx gehostet werden kann.[](https://github.com/GlitchLinux/BrowserPad)

**Quelle**: https://github.com/GlitchLinux/BrowserPad

## Übung 2: Konfiguration von OPNsense-DNS und Firewall-Regeln

**Ziel**: Konfiguriere OPNsense, um `browserpad.homelab.local` aufzulösen und den Zugriff auf den Nginx-Server zu erlauben.

**Aufgabe**: Erstelle ein Ansible-Playbook, um DNS- und Firewall-Einstellungen in OPNsense zu aktualisieren.

1. **Ansible-Playbook für OPNsense**:
   - Erstelle ein Playbook:
     ```bash
     nano configure_opnsense_browserpad.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure OPNsense for BrowserPad
         hosts: network_devices
         tasks:
           - name: Add DNS host override for BrowserPad
             ansible.builtin.command: >
               configctl unbound host add browserpad homelab.local 192.168.30.110 "BrowserPad Web Editor"
             register: dns_result
           - name: Add firewall rule for BrowserPad HTTP (80)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.110",
                 "destination_port":"80",
                 "description":"Allow HTTP to BrowserPad"
               }'
             register: firewall_result
           - name: Restart Unbound service
             ansible.builtin.command: configctl unbound restart
           - name: Verify firewall rules
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Test DNS resolution
             ansible.builtin.command: nslookup browserpad.homelab.local 192.168.30.1
             register: nslookup_result
           - name: Display DNS and firewall results
             ansible.builtin.debug:
               msg: "DNS: {{ nslookup_result.stdout }} | Firewall: {{ rules_list.stdout }}"
       ```
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml configure_opnsense_browserpad.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display DNS and firewall results] *****************************************
       ok: [opnsense] => {
           "msg": "DNS: ... browserpad.homelab.local 3600 IN A 192.168.30.110 ... | Firewall: ... Allow HTTP to BrowserPad ..."
       }
       ```
   - Prüfe in der OPNsense-Weboberfläche:
     - Gehe zu `Services > Unbound DNS > Overrides > Host`: Eintrag für `browserpad.homelab.local`.
     - Gehe zu `Firewall > Rules > LAN`: Regel für `192.168.30.110:80`.

**Erkenntnis**: OPNsense Unbound DNS ist ausreichend für die Namensauflösung im HomeLab, und Ansible automatisiert DNS- und Firewall-Konfigurationen.

**Quelle**: https://docs.opnsense.org/manual/unbound.html

## Übung 3: Backup der BrowserPad-Dateien auf TrueNAS

**Ziel**: Sichere die BrowserPad-Dateien und Nginx-Konfiguration auf TrueNAS.

**Aufgabe**: Erstelle ein Ansible-Playbook für Backups und begrenze sie auf maximal fünf Versionen.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_browserpad.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup BrowserPad and Nginx configuration
         hosts: browserpad_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/turnkey-browserpad-install/backups/browserpad"
           backup_file: "{{ backup_dir }}/browserpad-backup-{{ ansible_date_time.date }}.tar.gz"
         tasks:
           - name: Create backup directory
             ansible.builtin.file:
               path: "{{ backup_dir }}"
               state: directory
               mode: '0755'
             delegate_to: localhost
           - name: Stop Nginx service
             ansible.builtin.service:
               name: nginx
               state: stopped
           - name: Backup BrowserPad and Nginx configuration
             ansible.builtin.command: >
               tar -czf /tmp/browserpad-backup-{{ ansible_date_time.date }}.tar.gz /var/www/browserpad /etc/nginx
             register: backup_result
           - name: Start Nginx service
             ansible.builtin.service:
               name: nginx
               state: started
           - name: Fetch backup file
             ansible.builtin.fetch:
               src: /tmp/browserpad-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ backup_file }}"
               flat: yes
           - name: Limit backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t browserpad-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/turnkey-browserpad-install/
             delegate_to: localhost
           - name: Display backup status
             ansible.builtin.debug:
               msg: "Backup saved to {{ backup_file }} and synced to TrueNAS"
       ```
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_browserpad.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display backup status] ****************************************************
       ok: [browserpad] => {
           "msg": "Backup saved to /home/ubuntu/turnkey-browserpad-install/backups/browserpad/browserpad-backup-<date>.tar.gz and synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/turnkey-browserpad-install/
     ```
     - Erwartete Ausgabe: Maximal fünf `browserpad-backup-<date>.tar.gz`.

2. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/turnkey-browserpad-install
       ansible-playbook -i inventory.yml backup_browserpad.yml >> backup.log 2>&1
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
       0 3 * * * /home/ubuntu/turnkey-browserpad-install/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible automatisiert die Sicherung der BrowserPad-Dateien, während TrueNAS externe Speicherung bietet.

**Quelle**: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/fetch_module.html

## Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass die Firewall-Regeln aktiv sind (siehe Übung 2).
   - Prüfe OPNsense-Logs:
     ```bash
     ansible-playbook -i inventory.yml -m ansible.builtin.command -a "cat /var/log/system/latest.log" opnsense
     ```

2. **Monitoring mit Checkmk (optional)**:
   - Konfiguriere Checkmk für den BrowserPad-Server:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Füge den BrowserPad-Server als Host hinzu:
       - Hostname: `browserpad`, IP: `192.168.30.110`.
       - Speichern und `Discover services`.
     - Prüfe Services:
       - Gehe zu `Monitor > All services`.
       - Erwartete Ausgabe: Services wie `nginx`.
     - Erstelle eine benutzerdefinierte Überprüfung für BrowserPad:
       ```bash
       nano /omd/sites/homelab/local/share/check_mk/checks/browserpad
       ```
       - Inhalt:
         ```bash
         #!/bin/bash
         curl -s http://192.168.30.110 > /dev/null
         if [ $? -eq 0 ]; then
           echo "0 BrowserPad - BrowserPad is operational"
         else
           echo "2 BrowserPad - BrowserPad is not operational"
         fi
         ```
       - Ausführbar machen:
         ```bash
         chmod +x /omd/sites/homelab/local/share/check_mk/checks/browserpad
         ```
       - In Checkmk: `Setup > Services > Manual checks > Custom checks`, füge `BrowserPad` hinzu.

## Schritt 5: Erweiterung der Übungen
1. **HTTPS für BrowserPad**:
   - Erstelle ein Playbook, um Let’s Encrypt für HTTPS zu konfigurieren:
     ```bash
     nano configure_https_browserpad.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure HTTPS for BrowserPad
         hosts: browserpad_servers
         become: yes
         tasks:
           - name: Install certbot
             ansible.builtin.apt:
               name: certbot
               state: present
               update_cache: yes
           - name: Obtain Let’s Encrypt certificate
             ansible.builtin.command: >
               certbot certonly --non-interactive --agree-tos --email admin@homelab.local --webroot -w /var/www/browserpad -d browserpad.homelab.local
             register: certbot_result
           - name: Update Nginx configuration for HTTPS
             ansible.builtin.copy:
               dest: /etc/nginx/sites-available/browserpad
               content: |
                 server {
                   listen 80;
                   server_name browserpad.homelab.local;
                   return 301 https://$host$request_uri;
                 }
                 server {
                   listen 443 ssl;
                   server_name browserpad.homelab.local;
                   root /var/www/browserpad;
                   index editor.html;
                   ssl_certificate /etc/letsencrypt/live/browserpad.homelab.local/fullchain.pem;
                   ssl_certificate_key /etc/letsencrypt/live/browserpad.homelab.local/privkey.pem;
                   location / {
                     try_files $uri $uri/ /editor.html;
                   }
                 }
           - name: Restart Nginx
             ansible.builtin.service:
               name: nginx
               state: restarted
       ```
   - **Hinweis**: Für Let’s Encrypt muss `browserpad.homelab.local` öffentlich erreichbar sein (z. B. über Port-Forwarding in OPNsense). Alternativ kannst du ein selbstsigniertes Zertifikat verwenden.

2. **Backup-Versionierung mit Git**:
   - Initialisiere ein Git-Repository für Backups:
     ```bash
     cd ~/turnkey-browserpad-install/backups/browserpad
     git init
     git add .
     git commit -m "Initial BrowserPad backup"
     ```

## Best Practices für Schüler

- **BrowserPad-Design**:
  - Nutze BrowserPad für schnelle Text- und Codebearbeitung direkt im Browser.
  - Speichere Dateien lokal, da BrowserPad clientseitig arbeitet.
- **Sicherheit**:
  - Schränke Zugriff ein:
    ```bash
    ssh root@192.168.30.110 "ufw allow from 192.168.30.0/24 to any port 80"
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
  - Aktiviere HTTPS (siehe Schritt 5.1).
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe Nginx-Logs:
    ```bash
    ssh root@192.168.30.110 "cat /var/log/nginx/error.log"
    ```
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/turnkey-browserpad-install/backup.log
    ```

**Quelle**: https://github.com/GlitchLinux/BrowserPad, https://nginx.org/en/docs/

## Empfehlungen für Schüler

- **Setup**: Nginx, BrowserPad, Proxmox LXC, Ansible, TrueNAS-Backups.
- **Workloads**: BrowserPad-Hosting, DNS- und Firewall-Konfiguration, Backups.
- **Integration**: Proxmox (LXC), TrueNAS (Backups), OPNsense (DNS, Netzwerk).
- **Beispiel**: Leichtgewichtiger Code-Editor für HomeLab-Nutzer.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit der Standardkonfiguration, erweitere zu HTTPS oder Plugins.
- **Übung**: Teste BrowserPad mit verschiedenen Dateitypen (z. B. Python, Markdown).
- **Fehlerbehebung**: Nutze `ansible-playbook --check` und `curl` für Tests.
- **Lernressourcen**: https://github.com/GlitchLinux/BrowserPad, https://nginx.org/en/docs/, https://docs.ansible.com.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Schnelle Installation eines BrowserPad-Webservers mit Nginx.
- **Skalierbarkeit**: Automatisierte DNS-, Firewall- und Backup-Konfigurationen.
- **Lernwert**: Verständnis von clientseitigen Web-Editoren und HomeLab-Integration.

**Nächste Schritte**: Möchtest du eine Anleitung zur Integration von BrowserPad mit OpenLDAP für authentifizierten Zugriff, Installation von CodeMirror-Plugins, oder Monitoring mit Wazuh/Fluentd/Checkmk?

**Quellen**:
- BrowserPad GitHub: https://github.com/GlitchLinux/BrowserPad
- Nginx-Dokumentation: https://nginx.org/en/docs/
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen: https://github.com/GlitchLinux/BrowserPad[](https://github.com/GlitchLinux/BrowserPad)
```