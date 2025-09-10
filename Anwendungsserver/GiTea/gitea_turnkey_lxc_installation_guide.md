# Lernprojekt: Installation von Gitea mit TurnKey Linux als LXC-Container

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
     - Host: `gitea`
     - Domäne: `homelab.local`
     - IP: `192.168.30.104`
     - Beschreibung: `Gitea Server`
   - Teste den DNS-Eintrag:
     ```bash
     nslookup gitea.homelab.local 192.168.30.1
     ```
     - Erwartete Ausgabe: `192.168.30.104`.
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
     mkdir ~/gitea-install
     cd ~/gitea-install
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Proxmox (`192.168.30.2`), OPNsense (`192.168.30.1`) und TrueNAS (`192.168.30.100`).

## Übung 1: Einrichten des LXC-Containers mit TurnKey Gitea

**Ziel**: Installiere Gitea mit dem TurnKey Linux Appliance als LXC-Container auf Proxmox.

**Aufgabe**: Lade die TurnKey Gitea-Vorlage herunter, erstelle einen LXC-Container und konfiguriere die Basis-Einstellungen.

1. **TurnKey Gitea-Vorlage herunterladen**:
   - Öffne die Proxmox-Weboberfläche.
   - Gehe zu `Storage > local > Content > Templates`.
   - Lade die neueste TurnKey Gitea-Vorlage herunter:
     - URL: `http://mirror.turnkeylinux.org/turnkeylinux/images/proxmox/debian-11-turnkey-gitea_18.0-1_amd64.tar.gz`[](https://www.turnkeylinux.org/gitea)
     - Alternativ per CLI auf dem Proxmox-Host:
       ```bash
       pveam download local debian-11-turnkey-gitea_18.0-1_amd64.tar.gz
       ```
2. **LXC-Container erstellen**:
   - In Proxmox: `Create CT`:
     - Hostname: `gitea`
     - Template: `debian-11-turnkey-gitea_18.0-1_amd64`
     - IP-Adresse: `192.168.30.104/24`
     - Gateway: `192.168.30.1`
     - DNS-Server: `192.168.30.1`
     - Speicher: `local-lvm` oder `local-zfs`
     - CPU: 1 Kern, RAM: 1 GB, Disk: 10 GB
   - Starte den Container:
     - In der Proxmox-Weboberfläche: `gitea > Start`.
     - Bei der ersten Anmeldung wirst du aufgefordert, das Root-Passwort zu ändern.
3. **Gitea initial konfigurieren**:
   - Verbinde dich mit dem Container:
     ```bash
     ssh root@192.168.30.104
     ```
   - Führe die Ersteinrichtung durch (TurnKey Firstboot):
     - Setze das Root-Passwort.
     - Setze den Gitea-Admin-Benutzer (z. B. `admin`, Passwort: `securepassword123`, E-Mail: `admin@homelab.local`).
     - Setze den Domänennamen: `gitea.homelab.local`.
   - Prüfe den Gitea-Dienst:
     ```bash
     systemctl status gitea
     ```
     - Erwartete Ausgabe: `active (running)`.
   - Teste die Weboberfläche:
     ```bash
     curl https://gitea.homelab.local
     ```
     - Erwartete Ausgabe: HTML der Gitea-Anmeldeseite.
     - Öffne im Browser: `https://192.168.30.104` (ignoriere SSL-Warnungen für selbstsignierte Zertifikate).

**Erkenntnis**: Die TurnKey Gitea Appliance vereinfacht die Installation durch vorgefertigte Konfigurationen mit MySQL, Nginx und Postfix.[](https://www.turnkeylinux.org/gitea)

**Quelle**: https://www.turnkeylinux.org/gitea

## Übung 2: Konfiguration von Firewall-Regeln mit Ansible

**Ziel**: Konfiguriere Firewall-Regeln auf OPNsense, um Zugriff auf Gitea (HTTP/HTTPS) zu erlauben.

**Aufgabe**: Erstelle ein Ansible-Playbook, um Firewall-Regeln für Gitea zu konfigurieren.

1. **Ansible-Inventar erstellen**:
   - Erstelle eine Inventar-Datei:
     ```bash
     nano inventory.yml
     ```
     - Inhalt:
       ```yaml
       all:
         children:
           network_devices:
             hosts:
               opnsense:
                 ansible_host: 192.168.30.1
                 ansible_user: root
                 ansible_connection: ssh
                 ansible_network_os: freebsd
           gitea_servers:
             hosts:
               gitea:
                 ansible_host: 192.168.30.104
                 ansible_user: root
                 ansible_connection: ssh
                 ansible_python_interpreter: /usr/bin/python3
       ```

2. **Ansible-Playbook für Firewall-Regeln**:
   - Erstelle ein Playbook:
     ```bash
     nano configure_firewall_gitea.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure OPNsense firewall for Gitea
         hosts: network_devices
         tasks:
           - name: Add firewall rule for HTTP (80)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.104",
                 "destination_port":"80",
                 "description":"Allow HTTP to Gitea"
               }'
             register: http_result
           - name: Add firewall rule for HTTPS (443)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.104",
                 "destination_port":"443",
                 "description":"Allow HTTPS to Gitea"
               }'
             register: https_result
           - name: Verify firewall rules
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Display firewall rules
             ansible.builtin.debug:
               msg: "{{ rules_list.stdout }}"
       ```
   - **Erklärung**:
     - Fügt Firewall-Regeln für HTTP (80) und HTTPS (443) hinzu.
     - Erlaubt Verkehr von `192.168.30.0/24` zu `192.168.30.104`.

3. **Playbook ausführen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml configure_firewall_gitea.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display firewall rules] ****************************************************
       ok: [opnsense] => {
           "msg": "... Allow HTTP to Gitea ... Allow HTTPS to Gitea ..."
       }
       ```
   - Prüfe in der OPNsense-Weboberfläche:
     - Gehe zu `Firewall > Rules > LAN`.
     - Erwartete Regeln: `pass` für `192.168.30.104:80` und `192.168.30.104:443`.

**Erkenntnis**: Ansible automatisiert die Firewall-Konfiguration, um sicheren Zugriff auf Gitea zu gewährleisten.

**Quelle**: https://docs.opnsense.org/manual/firewall.html

## Übung 3: Backup der Gitea-Daten auf TrueNAS

**Ziel**: Sichere die Gitea-Daten (Repositorys, Datenbank) und versioniere sie auf TrueNAS.

**Aufgabe**: Erstelle ein Ansible-Playbook für Backups und begrenze sie auf maximal fünf Versionen.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_gitea.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup Gitea configuration and data
         hosts: gitea_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/gitea-install/backups/gitea"
           backup_file: "{{ backup_dir }}/gitea-backup-{{ ansible_date_time.date }}.tar.gz"
         tasks:
           - name: Create backup directory
             ansible.builtin.file:
               path: "{{ backup_dir }}"
               state: directory
               mode: '0755'
             delegate_to: localhost
           - name: Stop Gitea service
             ansible.builtin.service:
               name: gitea
               state: stopped
           - name: Backup Gitea data and configuration
             ansible.builtin.command: >
               tar -czf /tmp/gitea-backup-{{ ansible_date_time.date }}.tar.gz /home/git/gitea /var/lib/mysql
             register: backup_result
           - name: Start Gitea service
             ansible.builtin.service:
               name: gitea
               state: started
           - name: Fetch backup file
             ansible.builtin.fetch:
               src: /tmp/gitea-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ backup_file }}"
               flat: yes
           - name: Limit backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t gitea-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/gitea-install/
             delegate_to: localhost
           - name: Display backup status
             ansible.builtin.debug:
               msg: "Backup saved to {{ backup_file }} and synced to TrueNAS"
       ```
   - **Erklärung**:
     - Stoppt den Gitea-Dienst, um konsistente Backups zu gewährleisten.
     - Sichert `/home/git/gitea` (Gitea-Konfiguration) und `/var/lib/mysql` (MySQL-Datenbank).
     - Begrenzt Backups auf fünf durch Entfernen älterer Dateien.
     - Synchronisiert Backups mit TrueNAS.

2. **Playbook testen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_gitea.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display backup status] ****************************************************
       ok: [gitea] => {
           "msg": "Backup saved to /home/ubuntu/gitea-install/backups/gitea/gitea-backup-<date>.tar.gz and synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/gitea-install/
     ```
     - Erwartete Ausgabe: Maximal fünf `gitea-backup-<date>.tar.gz`.

3. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/gitea-install
       ansible-playbook -i inventory.yml backup_gitea.yml >> backup.log 2>&1
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
       0 3 * * * /home/ubuntu/gitea-install/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible automatisiert die Sicherung von Gitea-Daten, während TrueNAS externe Speicherung bietet.

**Quelle**: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/fetch_module.html

## Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass die Firewall-Regeln aktiv sind (siehe Übung 2).
   - Prüfe OPNsense-Logs:
     ```bash
     ansible-playbook -i inventory.yml -m ansible.builtin.command -a "cat /var/log/system/latest.log" opnsense
     ```

2. **Monitoring mit Checkmk (optional)**:
   - Konfiguriere Checkmk für den Gitea-Server:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Füge den Gitea-Server als Host hinzu:
       - Hostname: `gitea`, IP: `192.168.30.104`.
       - Speichern und `Discover services`.
     - Prüfe Services:
       - Gehe zu `Monitor > All services`.
       - Erwartete Ausgabe: Services wie `Gitea`, `Nginx`, `MySQL`.

## Schritt 5: Erweiterung der Übungen
1. **Erweiterte Gitea-Konfiguration**:
   - Erstelle ein Playbook für die Aktivierung von Gitea Actions (CI/CD):
     ```bash
     nano enable_gitea_actions.yml
     ```
     - Inhalt:
       ```yaml
       - name: Enable Gitea Actions
         hosts: gitea_servers
         become: yes
         tasks:
           - name: Enable Gitea Actions in config
             ansible.builtin.lineinfile:
               path: /home/git/gitea/custom/conf/app.ini
               regexp: "^ENABLED ="
               line: "ENABLED = true"
               insertafter: "[actions]"
           - name: Restart Gitea
             ansible.builtin.service:
               name: gitea
               state: restarted
       ```

2. **Backup-Versionierung mit Git**:
   - Initialisiere ein Git-Repository für Backups:
     ```bash
     cd ~/gitea-install/backups/gitea
     git init
     git add .
     git commit -m "Initial Gitea backup"
     ```

## Best Practices für Schüler

- **Gitea-Design**:
  - Verwende die TurnKey Appliance für eine schnelle Einrichtung.
  - Konfiguriere einen dedizierten DNS-Eintrag (z. B. `gitea.homelab.local`).
- **Sicherheit**:
  - Schränke Zugriff ein:
    ```bash
    ssh root@192.168.30.104 "ufw allow from 192.168.30.0/24 to any port 22,80,443"
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe Gitea-Logs:
    ```bash
    ssh root@192.168.30.104 "cat /home/git/gitea/log/gitea.log"
    ```
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/gitea-install/backup.log
    ```

**Quelle**: https://www.turnkeylinux.org/gitea, https://docs.gitea.com, https://docs.ansible.com

## Empfehlungen für Schüler

- **Setup**: TurnKey Gitea, Proxmox LXC, Ansible, TrueNAS-Backups.
- **Workloads**: Gitea-Installation, Firewall-Konfiguration, Backups.
- **Integration**: Proxmox (LXC), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Gitea mit MySQL und Nginx für Git-Repositorys.

## Tipps für den Erfolg

- **Einfachheit**: Nutze die TurnKey Appliance für eine schnelle Installation.
- **Übung**: Experimentiere mit Gitea Actions oder SSH-Zugriff für Repositorys.
- **Fehlerbehebung**: Nutze `ansible-playbook --check` und `journalctl -u gitea`.
- **Lernressourcen**: https://www.turnkeylinux.org/gitea, https://docs.gitea.com, https://docs.opnsense.org.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Schnelle Gitea-Installation mit TurnKey LXC.
- **Skalierbarkeit**: Automatisierte Firewall- und Backup-Konfigurationen.
- **Lernwert**: Verständnis von Git-Servern und HomeLab-Integration.

**Nächste Schritte**: Möchtest du eine Anleitung zu Integration mit Wazuh für Sicherheitsüberwachung, Log-Aggregation mit Fluentd, oder erweitertem Monitoring mit Checkmk?

**Quellen**:
- TurnKey Linux Gitea-Dokumentation: https://www.turnkeylinux.org/gitea[](https://www.turnkeylinux.org/gitea)
- Gitea-Dokumentation: https://docs.gitea.com
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,,,,
```