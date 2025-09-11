# Lernprojekt: Installation eines Plex Media Servers auf Debian 12

## Vorbereitung: Umgebung prüfen
1. **Proxmox VE prüfen**:
   - Melde dich an der Proxmox-Weboberfläche an: `https://192.168.30.2:8006`.
   - Stelle sicher, dass die LXC-Container für die Ubuntu-VM (`192.168.30.101`) laufen:
     ```bash
     pct list
     ```
     - Erwartete Ausgabe: Container `ubuntu` mit Status `running`.
2. **DNS in OPNsense prüfen**:
   - Öffne die OPNsense-Weboberfläche: `http://192.168.30.1`.
   - Gehe zu `Services > Unbound DNS > Overrides > Host`.
   - Füge einen Eintrag hinzu:
     - Host: `plex.homelab.local` → IP: `192.168.30.118`
   - Teste die DNS-Auflösung:
     ```bash
     nslookup plex.homelab.local 192.168.30.1
     ```
     - Erwartete Ausgabe: `192.168.30.118`.
3. **Ansible-Umgebung prüfen**:
   - Auf der Ubuntu-VM (`192.168.30.101`):
     ```bash
     ssh ubuntu@192.168.30.101
     ansible --version
     ```
   - Stelle sicher, dass SSH-Zugriff auf den Plex-Server möglich ist (nach Container-Erstellung):
     ```bash
     ssh root@192.168.30.118
     ```
4. **Checkmk prüfen**:
   - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
   - Melde dich an (z. B. Benutzer: `cmkadmin`, Passwort aus `elk_checkmk_integration_guide.md`).
   - Prüfe, ob die Checkmk-Site `homelab` läuft:
     ```bash
     omd status homelab
     ```
     - Erwartete Ausgabe: `running` für alle Dienste (z. B. `mkeventd`, `rrdcached`).
5. **Projektverzeichnis erstellen**:
   - Auf `192.168.30.101`:
     ```bash
     mkdir ~/plex-installation
     cd ~/plex-installation
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf OPNsense (`192.168.30.1`), TrueNAS (`192.168.30.100`) und den Plex-Server (`192.168.30.118`).

## Übung 1: Installation und Konfiguration des Plex Media Servers

**Ziel**: Installiere Plex Media Server auf einem Debian 12 LXC-Container und binde Mediendateien von TrueNAS ein.

**Aufgabe**: Erstelle einen LXC-Container, installiere Plex mit Ansible und konfiguriere den Zugriff auf TrueNAS-Medien.

1. **LXC-Container für Plex erstellen**:
   - In Proxmox: `Create CT`:
     - Hostname: `plex`
     - Template: Debian 12-Standard
     - IP-Adresse: `192.168.30.118/24`
     - Gateway: `192.168.30.1`
     - DNS-Server: `192.168.30.1`
     - Speicher: 20 GB, CPU: 2 Kerne, RAM: 4 GB
     - **Wichtiger Hinweis**: Aktiviere `Nesting` und `NFS` in den Container-Optionen, um NFS-Mounts zu unterstützen.
   - Starte den Container.

2. **Ansible-Inventar erstellen**:
   - Erstelle eine Inventar-Datei:
     ```bash
     nano inventory.yml
     ```
     - Inhalt:
       ```yaml
       all:
         children:
           plex_servers:
             hosts:
               plex:
                 ansible_host: 192.168.30.118
                 ansible_user: root
                 ansible_connection: ssh
                 ansible_python_interpreter: /usr/bin/python3
           checkmk_servers:
             hosts:
               checkmk:
                 ansible_host: 192.168.30.101
                 ansible_user: ubuntu
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

3. **Ansible-Playbook für Plex-Installation**:
   - Erstelle ein Playbook:
     ```bash
     nano install_plex.yml
     ```
     - Inhalt:
       ```yaml
       - name: Install Plex Media Server
         hosts: plex_servers
         become: yes
         vars:
           truenas_nfs_share: "192.168.30.100:/mnt/tank/media"
           plex_media_dir: "/mnt/media"
         tasks:
           - name: Update apt cache
             ansible.builtin.apt:
               update_cache: yes
           - name: Install dependencies
             ansible.builtin.apt:
               name: "{{ packages }}"
               state: present
             vars:
               packages:
                 - curl
                 - apt-transport-https
                 - nfs-common
           - name: Add Plex repository key
             ansible.builtin.apt_key:
               url: https://downloads.plex.tv/plex-keys/PlexSign.key
               state: present
           - name: Add Plex repository
             ansible.builtin.apt_repository:
               repo: deb https://downloads.plex.tv/repo/deb public main
               state: present
               filename: plexmediaserver
           - name: Install Plex Media Server
             ansible.builtin.apt:
               name: plexmediaserver
               state: present
               update_cache: yes
           - name: Create media directory
             ansible.builtin.file:
               path: "{{ plex_media_dir }}"
               state: directory
               mode: '0755'
           - name: Mount TrueNAS NFS share
             ansible.builtin.mount:
               path: "{{ plex_media_dir }}"
               src: "{{ truenas_nfs_share }}"
               fstype: nfs
               state: mounted
           - name: Start Plex Media Server
             ansible.builtin.service:
               name: plexmediaserver
               state: started
               enabled: yes
           - name: Test Plex Media Server
             ansible.builtin.uri:
               url: http://192.168.30.118:32400/web
               return_content: yes
             register: plex_test
             ignore_errors: yes
           - name: Display Plex test result
             ansible.builtin.debug:
               msg: "{{ plex_test.status }}"
       - name: Configure OPNsense firewall for Plex
         hosts: network_devices
         tasks:
           - name: Add firewall rule for Plex (32400)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.118",
                 "destination_port":"32400",
                 "description":"Allow Plex Media Server"
               }'
           - name: Verify firewall rules
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Display firewall rules
             ansible.builtin.debug:
               msg: "{{ rules_list.stdout }}"
       ```
   - **Erklärung**:
     - Installiert Plex Media Server auf Debian 12.
     - Bindet die TrueNAS-Medienfreigabe (`/mnt/tank/media`) über NFS ein.
     - Konfiguriert die OPNsense-Firewall, um Zugriff auf Plex (Port 32400) zu erlauben.
     - Testet die Plex-Weboberfläche.
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml install_plex.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display Plex test result] ***********************************************
       ok: [plex] => {
           "msg": 200
       }
       TASK [Display firewall rules] *************************************************
       ok: [opnsense] => {
           "msg": "... Allow Plex Media Server ..."
       }
       ```
   - Prüfe Plex:
     - Öffne `http://plex.homelab.local:32400/web`.
     - Melde dich an (erfordert ein Plex-Konto, erstelle eines unter https://www.plex.tv).
     - Füge die Medienbibliothek hinzu: `Settings > Libraries > Add Library > /mnt/media`.
     - Erwartete Ausgabe: Medien aus `/mnt/tank/media` werden in Plex angezeigt.

**Erkenntnis**: Plex Media Server kann einfach auf Debian 12 installiert und mit TrueNAS-Medien integriert werden, während Ansible die Konfiguration automatisiert.

**Quelle**: https://support.plex.tv/articles/200288586-installation

## Übung 2: Einrichtung eines benutzerdefinierten Checks in Checkmk

**Ziel**: Erstelle einen Checkmk-Check, um den Plex Media Server-Dienst zu überwachen.

**Aufgabe**: Implementiere einen Check, der den Status des Plex-Dienstes und die Erreichbarkeit der Weboberfläche prüft.

1. **Ansible-Playbook für Checkmk-Check**:
   - Erstelle ein Playbook:
     ```bash
     nano plex_checkmk.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure Checkmk for Plex Monitoring
         hosts: checkmk_servers
         become: yes
         vars:
           checkmk_site: "homelab"
           checkmk_user: "cmkadmin"
           checkmk_password: "securepassword123"
           plex_host: "plex.homelab.local"
         tasks:
           - name: Install Checkmk agent on Plex server
             ansible.builtin.apt:
               name: check-mk-agent
               state: present
               update_cache: yes
             delegate_to: plex
           - name: Enable Checkmk agent service on Plex
             ansible.builtin.service:
               name: check-mk-agent
               state: started
               enabled: yes
             delegate_to: plex
           - name: Create Plex check script
             ansible.builtin.copy:
               dest: /omd/sites/{{ checkmk_site }}/local/share/check_mk/checks/plex_service
               content: |
                 #!/bin/bash
                 STATUS=$(systemctl is-active plexmediaserver)
                 RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://192.168.30.118:32400/web)
                 if [ "$STATUS" == "active" ] && [ "$RESPONSE" == "200" ]; then
                   echo "0 Plex_Service - Plex Media Server is running and web interface is accessible"
                 else
                   echo "2 Plex_Service - Plex Media Server is not running (status: $STATUS) or web interface is not accessible (HTTP: $RESPONSE)"
                 fi
               mode: '0755'
           - name: Add Plex host to Checkmk
             ansible.builtin.command: >
               cmk -v -U {{ checkmk_user }}:{{ checkmk_password }} {{ checkmk_site }} add-host {{ plex_host }} 192.168.30.118
             args:
               creates: /omd/sites/{{ checkmk_site }}/etc/check_mk/conf.d/wato/hosts.mk
           - name: Discover services for Plex
             ansible.builtin.command: >
               cmk -v -U {{ checkmk_user }}:{{ checkmk_password }} {{ checkmk_site }} discover-services {{ plex_host }}
           - name: Activate changes in Checkmk
             ansible.builtin.command: >
               cmk -v -U {{ checkmk_user }}:{{ checkmk_password }} {{ checkmk_site }} activate
           - name: Verify Plex services in Checkmk
             ansible.builtin.command: >
               cmk -v -U {{ checkmk_user }}:{{ checkmk_password }} {{ checkmk_site }} list-services {{ plex_host }}
             register: service_list
           - name: Display Plex services
             ansible.builtin.debug:
               msg: "{{ service_list.stdout }}"
       - name: Configure OPNsense firewall for Checkmk
         hosts: network_devices
         tasks:
           - name: Add firewall rule for Checkmk agent (6556)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.101",
                 "destination":"192.168.30.118",
                 "destination_port":"6556",
                 "description":"Allow Checkmk to Plex"
               }'
           - name: Verify firewall rules
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Display firewall rules
             ansible.builtin.debug:
               msg: "{{ rules_list.stdout }}"
       ```
   - **Erklärung**:
     - Installiert den Checkmk-Agenten auf dem Plex-Server.
     - Erstellt einen benutzerdefinierten Check (`plex_service`), der den Dienststatus und die Weboberfläche prüft.
     - Fügt Plex als Host in Checkmk hinzu und aktiviert den Check.
     - Konfiguriert die OPNsense-Firewall für den Checkmk-Agenten (Port 6556).
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml plex_checkmk.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display Plex services] ************************************************
       ok: [checkmk] => {
           "msg": "... Plex_Service ..."
       }
       TASK [Display firewall rules] ***********************************************
       ok: [opnsense] => {
           "msg": "... Allow Checkmk to Plex ..."
       }
       ```
   - Prüfe in Checkmk:
     - Öffne `http://192.168.30.101:5000/homelab`.
     - Gehe zu `Monitor > All hosts > plex.homelab.local`.
     - Erwartete Ausgabe: `Plex_Service` zeigt Status `OK`.

**Erkenntnis**: Checkmk kann den Plex-Dienst effektiv überwachen, indem es den Dienststatus und die Weboberfläche prüft.

**Quelle**: https://docs.checkmk.com/latest/en/localchecks.html

## Übung 3: Backup der Plex-Konfiguration auf TrueNAS

**Ziel**: Sichere die Plex-Konfiguration auf TrueNAS.

**Aufgabe**: Erstelle ein Ansible-Playbook für Backups und begrenze sie auf maximal fünf Versionen.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_plex.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup Plex configuration
         hosts: plex_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/plex-installation/backups/plex"
           backup_file: "{{ backup_dir }}/plex-backup-{{ ansible_date_time.date }}.tar.gz"
         tasks:
           - name: Create backup directory
             ansible.builtin.file:
               path: "{{ backup_dir }}"
               state: directory
               mode: '0755'
             delegate_to: localhost
           - name: Stop Plex Media Server
             ansible.builtin.service:
               name: plexmediaserver
               state: stopped
           - name: Backup Plex configuration
             ansible.builtin.command: >
               tar -czf /tmp/plex-backup-{{ ansible_date_time.date }}.tar.gz /var/lib/plexmediaserver
             register: backup_result
           - name: Start Plex Media Server
             ansible.builtin.service:
               name: plexmediaserver
               state: started
           - name: Fetch backup file
             ansible.builtin.fetch:
               src: /tmp/plex-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ backup_file }}"
               flat: yes
           - name: Limit Plex backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t plex-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync Plex backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/plex-installation/
             delegate_to: localhost
           - name: Display Plex backup status
             ansible.builtin.debug:
               msg: "Plex backup saved to {{ backup_file }} and synced to TrueNAS"
       ```
   - **Erklärung**:
     - Sichert die Plex-Konfiguration (`/var/lib/plexmediaserver`).
     - Stoppt den Plex-Dienst, um konsistente Backups zu gewährleisten.
     - Begrenzt Backups auf fünf Versionen.
     - Synchronisiert Backups mit TrueNAS.
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_plex.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display Plex backup status] ********************************************
       ok: [plex] => {
           "msg": "Plex backup saved to /home/ubuntu/plex-installation/backups/plex/plex-backup-<date>.tar.gz and synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/plex-installation/
     ```
     - Erwartete Ausgabe: Maximal fünf `plex-backup-<date>.tar.gz`.

2. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/plex-installation
       ansible-playbook -i inventory.yml backup_plex.yml >> backup.log 2>&1
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
       0 3 * * * /home/ubuntu/plex-installation/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible automatisiert die Sicherung der Plex-Konfiguration, während TrueNAS zuverlässige externe Speicherung bietet.

## Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass die Firewall-Regeln aus Übung 1 (Port 32400 für Plex, Port 6556 für Checkmk-Agent) aktiv sind.
   - Prüfe OPNsense-Logs:
     ```bash
     ansible-playbook -i inventory.yml -m ansible.builtin.command -a "cat /var/log/system/latest.log" opnsense
     ```

2. **Erweiterung mit weiteren Checks**:
   - Erstelle einen Check für die Plex-Medienbibliothek:
     ```bash
     nano /omd/sites/homelab/local/share/check_mk/checks/plex_library
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       COUNT=$(find /mnt/media -type f | wc -l)
       if [ $COUNT -gt 0 ]; then
         echo "0 Plex_Library files=$COUNT Plex library contains $COUNT files"
       else
         echo "2 Plex_Library files=$COUNT Plex library is empty"
       fi
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /omd/sites/homelab/local/share/check_mk/checks/plex_library
       ```
     - In Checkmk: `Setup > Services > Manual checks > Custom checks`, füge `Plex_Library` hinzu.

## Schritt 5: Erweiterung der Übungen
1. **Erweiterte Plex-Konfiguration**:
   - Erstelle ein Playbook für Plex-Benutzerverwaltung:
     ```bash
     nano configure_plex_users.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure Plex users
         hosts: plex_servers
         become: yes
         vars:
           plex_token: "your_plex_token"  # Erhalte den Token von https://plex.tv/api
         tasks:
           - name: Add test user to Plex
             ansible.builtin.uri:
               url: https://plex.tv/api/v2/users
               method: POST
               headers:
                 X-Plex-Token: "{{ plex_token }}"
               body_format: json
               body: |
                 {
                   "email": "testuser@homelab.local",
                   "username": "testuser",
                   "password": "securepassword123"
                 }
               status_code: 201
             register: user_result
             ignore_errors: yes
           - name: Display user creation result
             ansible.builtin.debug:
               msg: "{{ user_result.status }}"
       ```

2. **Backup-Versionierung mit Git**:
   - Initialisiere ein Git-Repository für Backups:
     ```bash
     cd ~/plex-installation/backups
     git init
     git add .
     git commit -m "Initial Plex backups"
     ```

## Best Practices für Schüler

- **Plex-Design**:
  - Organisiere Mediendateien auf TrueNAS (`/mnt/tank/media`) mit klaren Verzeichnisstrukturen (z. B. `/mnt/tank/media/Movies`, `/mnt/tank/media/Music`).
  - Teste die Plex-Weboberfläche (`http://plex.homelab.local:32400/web`) und die Medienwiedergabe.
- **Sicherheit**:
  - Schränke Plex-Zugriff ein:
    ```bash
    ssh root@192.168.30.118 "ufw allow from 192.168.30.0/24 to any port 32400 proto tcp"
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
  - Verwende HTTPS für Plex bei externem Zugriff:
    ```bash
    ssh root@192.168.30.118 "turnkey-letsencrypt plex.homelab.local"
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
  - Teste Backups vor Updates (siehe https://support.plex.tv).
- **Fehlerbehebung**:
  - Prüfe Plex-Logs:
    ```bash
    ssh root@192.168.30.118 "cat /var/lib/plexmediaserver/Library/Application\ Support/Plex\ Media\ Server/Logs/*.log"
    ```
  - Prüfe Checkmk-Logs:
    ```bash
    cat /omd/sites/homelab/var/log/web.log
    ```
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/plex-installation/backup.log
    ```

**Quellen**: https://support.plex.tv, https://docs.checkmk.com, https://docs.ansible.com, https://docs.opnsense.org/manual

## Empfehlungen für Schüler

- **Setup**: Plex Media Server, TrueNAS-Medien, Checkmk-Monitoring, TrueNAS-Backups.
- **Workloads**: Plex-Installation, Überwachung, Backups.
- **Integration**: Proxmox (LXC), TrueNAS (NFS), OPNsense (DNS, Netzwerk).
- **Beispiel**: Medien-Streaming-Server mit Überwachung im HomeLab.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einer kleinen Medienbibliothek, erweitere nach Bedarf.
- **Übung**: Teste die Wiedergabe auf verschiedenen Geräten (z. B. Browser, Plex-App).
- **Fehlerbehebung**: Nutze Plex-Logs und Checkmk-Dashboards.
- **Lernressourcen**: https://www.plex.tv, https://docs.checkmk.com, https://docs.ansible.com.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Schnelle Installation von Plex mit TrueNAS-Integration.
- **Skalierbarkeit**: Automatisierte Überwachung und Backup-Prozesse.
- **Lernwert**: Verständnis von Medien-Streaming und Monitoring in einer HomeLab-Umgebung.

**Nächste Schritte**: Möchtest du eine Anleitung zur Integration von Plex mit Home Assistant, Erweiterung der Checkmk-Checks, oder eine andere Anpassung?

**Quellen**:
- Plex-Dokumentation: https://support.plex.tv
- Checkmk-Dokumentation: https://docs.checkmk.com
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen: https://www.plex.tv, https://docs.checkmk.com
```