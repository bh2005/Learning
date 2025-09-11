# Lernprojekt: Multi-Device-Management mit Ansible in einer HomeLab-Umgebung

## Einführung

**Multi-Device-Management** mit Ansible ermöglicht die gleichzeitige Konfiguration und Verwaltung mehrerer Netzwerkgeräte, um Effizienz und Konsistenz in einer Netzwerkumgebung zu gewährleisten. Dieses Lernprojekt zeigt, wie man mit **Ansible** mehrere Geräte (z. B. OPNsense-Router und Ubuntu-Server) in einer HomeLab-Umgebung konfiguriert und überwacht. Es baut auf `ansible_network_automation_guide.md` () auf und nutzt die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense) für Backups und Tests. Das Projekt ist für Lernende mit Grundkenntnissen in Linux, YAML, Ansible und Netzwerkadministration geeignet und ist lokal, kostenlos und datenschutzfreundlich. Es umfasst drei Übungen: Einrichten eines Multi-Device-Inventars, Automatisierung von Firewall-Regeln und Systemkonfigurationen, und Backup von Konfigurationen auf TrueNAS.

**Voraussetzungen**:
- Ubuntu-VM auf Proxmox (IP `192.168.30.101`) mit Ansible installiert (siehe `ansible_network_automation_guide.md`).
- OPNsense-Router (IP `192.168.30.1`) mit SSH-Zugriff aktiviert.
- Zusätzlicher Ubuntu-Server (IP `192.168.30.102`) für Multi-Device-Management.
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups.
- Grundkenntnisse in Linux, SSH, YAML und Netzwerkkonfiguration.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`) für OPNsense und Ubuntu-Server.
- Optional: Checkmk Raw Edition (Site `homelab`) installiert für Monitoring (siehe `elk_checkmk_integration_guide.md`, ).

**Ziele**:
- Einrichten eines Ansible-Inventars für mehrere Geräte (OPNsense und Ubuntu-Server).
- Automatisierte Konfiguration von Firewall-Regeln (OPNsense) und Software-Installationen (Ubuntu-Server).
- Backup von Konfigurationen auf TrueNAS.
- Optional: Monitoring mit Checkmk.

**Hinweis**: Ansible nutzt SSH für die Kommunikation mit Netzwerkgeräten (z. B. OPNsense, FreeBSD-basiert) und Servern (z. B. Ubuntu), wobei Playbooks für deklarative Konfigurationen sorgen.

**Quellen**:
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,,,,

## Lernprojekt: Multi-Device-Management mit Ansible

### Vorbereitung: Umgebung einrichten
1. **Ubuntu-VM (Control Node) prüfen**:
   - Verbinde dich mit der VM:
     ```bash
     ssh ubuntu@192.168.30.101
     ```
   - Stelle sicher, dass Ansible installiert ist:
     ```bash
     sudo apt update
     sudo apt install -y python3-pip
     pip3 install ansible
     ansible --version
     ```
2. **OPNsense prüfen**:
   - Stelle sicher, dass SSH-Zugriff aktiviert ist:
     - Öffne die OPNsense-Weboberfläche: `http://192.168.30.1`.
     - Gehe zu `System > Settings > Administration`.
     - Aktiviere `Enable Secure Shell` und erlaube `root`-Zugriff.
     - Füge den öffentlichen SSH-Schlüssel hinzu:
       ```bash
       ssh-copy-id root@192.168.30.1
       ```
   - Teste SSH:
     ```bash
     ssh root@192.168.30.1
     ```
3. **Ubuntu-Server (IP `192.168.30.102`) einrichten**:
   - Erstelle eine neue VM in Proxmox mit Ubuntu 22.04, IP `192.168.30.102`.
   - Aktiviere SSH:
     ```bash
     ssh ubuntu@192.168.30.102
     sudo apt update
     sudo apt install -y openssh-server
     sudo systemctl enable ssh
     ```
   - Füge den SSH-Schlüssel hinzu:
     ```bash
     ssh-copy-id ubuntu@192.168.30.102
     ```
4. **Projektverzeichnis erstellen**:
   - Auf der Ubuntu-VM (`192.168.30.101`):
     ```bash
     mkdir ~/ansible-multi-device
     cd ~/ansible-multi-device
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf OPNsense (`192.168.30.1`), Ubuntu-Server (`192.168.30.102`) und TrueNAS (`192.168.30.100`).

### Übung 1: Einrichten eines Multi-Device-Inventars und Verbindungstest

**Ziel**: Erstelle ein Ansible-Inventar für mehrere Geräte und teste die Verbindung.

**Aufgabe**: Konfiguriere ein Inventar für OPNsense und Ubuntu-Server und führe einen Testbefehl aus.

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
           servers:
             hosts:
               ubuntu_server:
                 ansible_host: 192.168.30.102
                 ansible_user: ubuntu
                 ansible_connection: ssh
                 ansible_python_interpreter: /usr/bin/python3
       ```
   - **Erklärung**:
     - `network_devices`: Gruppe für OPNsense (FreeBSD-basiert).
     - `servers`: Gruppe für Ubuntu-Server.
     - `ansible_python_interpreter`: Stellt sicher, dass Python 3 auf dem Ubuntu-Server verwendet wird.

2. **Ansible-Playbook für Verbindungstest**:
   - Erstelle ein Playbook:
     ```bash
     nano test_connection.yml
     ```
     - Inhalt:
       ```yaml
       - name: Test connection to all devices
         hosts: all
         tasks:
           - name: Run system info command
             ansible.builtin.command: uname -a
             register: result
           - name: Display result
             ansible.builtin.debug:
               msg: "{{ result.stdout }}"
       ```
   - **Erklärung**:
     - `hosts: all`: Ziel ist alle Geräte im Inventar.
     - `ansible.builtin.command`: Führt `uname -a` auf jedem Gerät aus.

3. **Playbook ausführen**:
   - Teste die Verbindung:
     ```bash
     ansible-playbook -i inventory.yml test_connection.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display result] ****************************************************
       ok: [opnsense] => {
           "msg": "FreeBSD opnsense.localdomain 13.2-RELEASE-p7 FreeBSD 13.2-RELEASE-p7 ..."
       }
       ok: [ubuntu_server] => {
           "msg": "Linux ubuntu-server 5.15.0-73-generic ..."
       }
       ```

**Erkenntnis**: Ansible ermöglicht die gleichzeitige Verwaltung mehrerer Geräte durch ein einheitliches Inventar und Playbooks.

**Quelle**: https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html

### Übung 2: Automatisierung von Firewall-Regeln und Software-Installationen

**Ziel**: Automatisiere Firewall-Regeln auf OPNsense und Software-Installationen auf dem Ubuntu-Server.

**Aufgabe**: Erstelle ein Playbook, um eine Firewall-Regel auf OPNsense und eine Software (z. B. Apache2) auf dem Ubuntu-Server zu konfigurieren.

1. **Ansible-Playbook für Multi-Device-Konfiguration**:
   - Erstelle ein Playbook:
     ```bash
     nano configure_multi_device.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure OPNsense firewall rule
         hosts: network_devices
         tasks:
           - name: Add firewall rule to allow HTTP
             ansible.builtin.command:
               cmd: >
                 configctl firewall rule add '{
                   "action":"pass",
                   "interface":"lan",
                   "direction":"in",
                   "protocol":"tcp",
                   "source_net":"192.168.30.0/24",
                   "destination":"192.168.30.102",
                   "destination_port":"80",
                   "description":"Allow HTTP to Ubuntu-Server"
                 }'
             register: firewall_result
           - name: Display firewall rule output
             ansible.builtin.debug:
               msg: "{{ firewall_result.stdout }}"
           - name: Verify firewall rules
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Display current rules
             ansible.builtin.debug:
               msg: "{{ rules_list.stdout }}"

       - name: Configure Ubuntu-Server with Apache2
         hosts: servers
         tasks:
           - name: Install Apache2
             ansible.builtin.apt:
               name: apache2
               state: present
               update_cache: yes
             become: yes
           - name: Ensure Apache2 is running
             ansible.builtin.service:
               name: apache2
               state: started
               enabled: yes
             become: yes
           - name: Verify Apache2 installation
             ansible.builtin.uri:
               url: http://192.168.30.102
               return_content: yes
             register: apache_result
           - name: Display Apache2 status
             ansible.builtin.debug:
               msg: "Apache2 is running, content: {{ apache_result.content | truncate(100) }}"
       ```
   - **Erklärung**:
     - Für OPNsense: Fügt eine Firewall-Regel hinzu, die HTTP-Verkehr (Port 80) zu `192.168.30.102` erlaubt.
     - Für Ubuntu-Server: Installiert Apache2, startet den Dienst und prüft die Erreichbarkeit.

2. **Playbook ausführen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml configure_multi_device.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display current rules] *********************************************
       ok: [opnsense] => {
           "msg": "... Allow HTTP to Ubuntu-Server ..."
       }
       TASK [Display Apache2 status] ********************************************
       ok: [ubuntu_server] => {
           "msg": "Apache2 is running, content: <!DOCTYPE html><html><head><title>Apache2 Ubuntu Default Page..."
       }
       ```
   - Prüfe in der OPNsense-Weboberfläche:
     - Gehe zu `Firewall > Rules > LAN`.
     - Erwartete Regel: `pass`, Quelle `192.168.30.0/24`, Ziel `192.168.30.102:80`.
   - Prüfe auf dem Ubuntu-Server:
     ```bash
     curl http://192.168.30.102
     ```
     - Erwartete Ausgabe: HTML der Apache2-Standardseite.

**Erkenntnis**: Ansible ermöglicht die gleichzeitige Konfiguration heterogener Geräte (Netzwerkgeräte und Server) in einem einzigen Playbook.

**Quelle**: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_module.html

### Übung 3: Backup von Konfigurationen auf TrueNAS

**Ziel**: Automatisiere das Backup von OPNsense- und Ubuntu-Server-Konfigurationen und speichere sie auf TrueNAS.

**Aufgabe**: Erstelle ein Playbook für Multi-Device-Backups und automatisiere es mit Cron.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_multi_device.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup OPNsense configuration
         hosts: network_devices
         vars:
           backup_dir: "/home/ubuntu/ansible-multi-device/backup-{{ ansible_date_time.date }}"
         tasks:
           - name: Create local backup directory
             ansible.builtin.file:
               path: "{{ backup_dir }}"
               state: directory
               mode: '0755'
             delegate_to: localhost
           - name: Backup OPNsense configuration
             ansible.builtin.command: opnsense-backup
             register: backup_result
           - name: Save OPNsense backup to file
             ansible.builtin.copy:
               content: "{{ backup_result.stdout }}"
               dest: "{{ backup_dir }}/opnsense-backup-{{ ansible_date_time.date }}.xml"
             delegate_to: localhost

       - name: Backup Ubuntu-Server configuration
         hosts: servers
         vars:
           backup_dir: "/home/ubuntu/ansible-multi-device/backup-{{ ansible_date_time.date }}"
         tasks:
           - name: Backup /etc directory
             ansible.builtin.command: tar -czf /tmp/etc-backup-{{ ansible_date_time.date }}.tar.gz /etc
             register: etc_backup
           - name: Fetch backup file
             ansible.builtin.fetch:
               src: /tmp/etc-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ backup_dir }}/ubuntu-server-etc-backup-{{ ansible_date_time.date }}.tar.gz"
               flat: yes

       - name: Transfer backups to TrueNAS
         hosts: localhost
         vars:
           backup_dir: "/home/ubuntu/ansible-multi-device/backup-{{ ansible_date_time.date }}"
         tasks:
           - name: Transfer backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/ansible-multi-device/
           - name: Display backup status
             ansible.builtin.debug:
               msg: "Backups transferred to TrueNAS"
       ```
   - **Erklärung**:
     - Für OPNsense: Sichert die Konfiguration mit `opnsense-backup`.
     - Für Ubuntu-Server: Sichert das `/etc`-Verzeichnis als `.tar.gz`.
     - `rsync`: Überträgt Backups an TrueNAS.

2. **Playbook testen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_multi_device.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display backup status] ****************************************************
       ok: [localhost] => {
           "msg": "Backups transferred to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/ansible-multi-device/
     ```
     - Erwartete Ausgabe: `opnsense-backup-<date>.xml`, `ubuntu-server-etc-backup-<date>.tar.gz`.

3. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/ansible-multi-device
       ansible-playbook -i inventory.yml backup_multi_device.yml >> backup.log 2>&1
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
       0 3 * * * /home/ubuntu/ansible-multi-device/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible ermöglicht skalierbare Backups für mehrere Geräte mit einem einzigen Playbook.

**Quelle**: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/fetch_module.html

### Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass SSH-Zugriff erlaubt ist:
     - Quelle: `192.168.30.0/24`
     - Ziel: `192.168.30.1`, `192.168.30.102`
     - Port: `22`
     - Aktion: `Allow`
   - Prüfe Firewall-Regeln:
     ```bash
     ansible-playbook -i inventory.yml -m ansible.builtin.command -a "configctl firewall list_rules" opnsense
     ```

2. **Monitoring mit Checkmk (optional)**:
   - Konfiguriere Checkmk für OPNsense und Ubuntu-Server:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Füge Hosts hinzu (falls nicht vorhanden):
       - Hostname: `opnsense`, IP: `192.168.30.1`.
       - Hostname: `ubuntu-server`, IP: `192.168.30.102`.
       - Speichern und `Discover services`.
     - Prüfe:
       - Gehe zu `Monitor > All services`.
       - Erwartete Ausgabe: Services wie `CPU load`, `Memory`, `Apache2`.

### Schritt 5: Erweiterung der Übungen
1. **Erweiterte Konfiguration**:
   - Erstelle ein Playbook für VLAN-Konfiguration und Software-Updates:
     ```bash
     nano configure_advanced.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure VLAN on OPNsense
         hosts: network_devices
         tasks:
           - name: Add VLAN
             ansible.builtin.command: >
               configctl interface vlan create '{
                 "interface":"lan",
                 "vlan_id":"10",
                 "description":"VLAN10"
               }'
             register: vlan_result
           - name: Display VLAN output
             ansible.builtin.debug:
               msg: "{{ vlan_result.stdout }}"

       - name: Update software on Ubuntu-Server
         hosts: servers
         tasks:
           - name: Update all packages
             ansible.builtin.apt:
               upgrade: dist
               update_cache: yes
             become: yes
       ```

2. **Validierung von Konfigurationen**:
   - Erstelle ein Playbook zur Prüfung von Konfigurationen:
     ```bash
     nano verify_config.yml
     ```
     - Inhalt:
       ```yaml
       - name: Verify OPNsense firewall rules
         hosts: network_devices
         tasks:
           - name: Check firewall rules
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Verify HTTP rule
             ansible.builtin.debug:
               msg: "HTTP rule found"
             when: "'Allow HTTP to Ubuntu-Server' in rules_list.stdout"

       - name: Verify Apache2 on Ubuntu-Server
         hosts: servers
         tasks:
           - name: Check Apache2 service
             ansible.builtin.service:
               name: apache2
               state: started
             register: apache_status
             become: yes
           - name: Display Apache2 status
             ansible.builtin.debug:
               msg: "Apache2 is {{ apache_status.state }}"
       ```

## Best Practices für Schüler

- **Automatisierungs-Design**:
  - Organisiere Geräte in Gruppen (`network_devices`, `servers`) für skalierbare Playbooks.
  - Verwende SSH-Schlüssel statt Passwörter.
- **Sicherheit**:
  - Schränke SSH-Zugriff ein:
    ```bash
    sudo ufw allow from 192.168.30.0/24 to any port 22
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/ansible-multi-device/backup.log
    ```
  - Prüfe OPNsense-Logs:
    ```bash
    ssh root@192.168.30.1 "cat /var/log/system/latest.log"
    ```
  - Prüfe Ubuntu-Server-Logs:
    ```bash
    ssh ubuntu@192.168.30.102 "cat /var/log/syslog"
    ```

**Quelle**: https://docs.ansible.com, https://docs.opnsense.org

## Empfehlungen für Schüler

- **Setup**: Ansible, OPNsense, Ubuntu-Server, TrueNAS-Backups.
- **Workloads**: Automatisierte Firewall-Regeln, Software-Installationen, Backups.
- **Integration**: Proxmox (VM), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Firewall-Regel für HTTP und Apache2-Installation.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einfachen Playbooks für einzelne Geräte, erweitere zu Multi-Device-Management.
- **Übung**: Experimentiere mit weiteren Konfigurationen wie VLANs oder Docker-Installationen.
- **Fehlerbehebung**: Nutze `ansible-playbook --check` für Trockenläufe und `ansible --verbose` für detaillierte Logs.
- **Lernressourcen**: https://docs.ansible.com, https://docs.opnsense.org.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Multi-Device-Management mit Ansible.
- **Skalierbarkeit**: Automatisierte Konfigurationen für Netzwerkgeräte und Server.
- **Lernwert**: Verständnis von Ansible für heterogene Umgebungen.

**Nächste Schritte**: Möchtest du eine Anleitung zu Integration mit Wazuh für Sicherheitsüberwachung, Log-Aggregation mit Fluentd, oder erweiterten Netzwerk-Monitoring mit Checkmk?

**Quellen**:
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,,,,
```