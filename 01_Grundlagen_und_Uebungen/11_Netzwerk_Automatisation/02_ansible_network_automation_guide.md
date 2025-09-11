# Lernprojekt: Netzwerk-Automatisierung mit Ansible in einer HomeLab-Umgebung

## Einführung

**Netzwerk-Automatisierung** ermöglicht die programmgesteuerte Konfiguration und Verwaltung von Netzwerkgeräten wie Routern und Switches, um manuelle Aufgaben zu minimieren und Konsistenz zu gewährleisten. Dieses Lernprojekt zeigt, wie man mit **Ansible**, einem Open-Source-Automatisierungstool, Netzwerkgeräte (z. B. OPNsense-Router) in einer HomeLab-Umgebung konfiguriert. Es orientiert sich an `network_automation_guide.md` () und nutzt die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense) für Backups und Tests. Das Projekt ist für Lernende mit Grundkenntnissen in Linux, Python, YAML und Netzwerkadministration geeignet und ist lokal, kostenlos und datenschutzfreundlich. Es umfasst drei Übungen: Einrichten von Ansible und Verbindung zu OPNsense, Automatisierung von Firewall-Regeln, und Backup von Konfigurationen auf TrueNAS.

**Voraussetzungen**:
- Ubuntu-VM auf Proxmox (IP `192.168.30.101`) mit Python 3 und `pip` installiert.
- OPNsense-Router (IP `192.168.30.1`) mit SSH-Zugriff aktiviert.
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups.
- Grundkenntnisse in Linux, SSH, YAML und Netzwerkkonfiguration (z. B. Firewall-Regeln).
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`) für OPNsense.
- Checkmk Raw Edition (Site `homelab`) installiert für optionales Monitoring (siehe `elk_checkmk_integration_guide.md`, ).

**Ziele**:
- Einrichten einer Netzwerk-Automatisierungs-Umgebung mit Ansible.
- Automatisierte Konfiguration von Firewall-Regeln auf OPNsense.
- Backup von Gerätekonfigurationen auf TrueNAS.
- Optional: Monitoring der Konfiguration mit Checkmk.

**Hinweis**: Ansible verwendet SSH für die Konfiguration von Netzwerkgeräten wie OPNsense (FreeBSD-basiert) und unterstützt Module wie `ansible.posix` für allgemeine Aufgaben.

**Quellen**:
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,,,,

## Lernprojekt: Netzwerk-Automatisierung mit Ansible

### Vorbereitung: Umgebung einrichten
1. **Ubuntu-VM prüfen**:
   - Verbinde dich mit der VM:
     ```bash
     ssh ubuntu@192.168.30.101
     ```
   - Installiere notwendige Pakete:
     ```bash
     sudo apt update
     sudo apt install -y python3-pip
     pip3 install ansible
     ```
   - Prüfe Ansible-Version:
     ```bash
     ansible --version
     ```
2. **OPNsense prüfen**:
   - Stelle sicher, dass SSH-Zugriff aktiviert ist:
     - Öffne die OPNsense-Weboberfläche: `http://192.168.30.1`.
     - Gehe zu `System > Settings > Administration`.
     - Aktiviere `Enable Secure Shell` und erlaube `root`-Zugriff.
     - Optional: Füge den öffentlichen SSH-Schlüssel (`~/.ssh/id_rsa.pub`) zu `root` hinzu:
       ```bash
       ssh-copy-id root@192.168.30.1
       ```
   - Teste die SSH-Verbindung:
     ```bash
     ssh root@192.168.30.1
     ```
3. **Projektverzeichnis erstellen**:
   ```bash
   mkdir ~/ansible-network-automation
   cd ~/ansible-network-automation
   ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf OPNsense und TrueNAS.

### Übung 1: Einrichten von Ansible und Verbindung zu OPNsense

**Ziel**: Konfiguriere Ansible und stelle eine SSH-Verbindung zu OPNsense her.

**Aufgabe**: Erstelle ein Ansible-Inventar und teste die Verbindung mit einem einfachen Befehl.

1. **Ansible-Inventar erstellen**:
   - Erstelle eine Inventar-Datei:
     ```bash
     nano inventory.yml
     ```
     - Inhalt:
       ```yaml
       all:
         hosts:
           opnsense:
             ansible_host: 192.168.30.1
             ansible_user: root
             ansible_connection: ssh
             ansible_network_os: freebsd
       ```
   - **Erklärung**:
     - `ansible_host`: IP-Adresse von OPNsense.
     - `ansible_user`: Benutzer für SSH (hier `root`).
     - `ansible_network_os`: FreeBSD für OPNsense.

2. **Ansible-Playbook für Verbindungstest**:
   - Erstelle ein Playbook:
     ```bash
     nano test_connection.yml
     ```
     - Inhalt:
       ```yaml
       - name: Test connection to OPNsense
         hosts: opnsense
         tasks:
           - name: Run uname command
             ansible.builtin.command: uname -a
             register: result
           - name: Display result
             ansible.builtin.debug:
               msg: "{{ result.stdout }}"
       ```
   - **Erklärung**:
     - `ansible.builtin.command`: Führt den Befehl `uname -a` auf OPNsense aus.
     - `debug`: Zeigt die Ausgabe an.

3. **Playbook ausführen**:
   - Teste die Verbindung:
     ```bash
     ansible-playbook -i inventory.yml test_connection.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display result] **********************************************************
       ok: [opnsense] => {
           "msg": "FreeBSD opnsense.localdomain 13.2-RELEASE-p7 FreeBSD 13.2-RELEASE-p7 ..."
       }
       ```

**Erkenntnis**: Ansible ermöglicht einfache SSH-basierte Verbindungen zu Netzwerkgeräten wie OPNsense für automatisierte Konfigurationen.

**Quelle**: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/command_module.html

### Übung 2: Automatisierung von Firewall-Regeln

**Ziel**: Automatisiere die Erstellung und Verwaltung von Firewall-Regeln auf OPNsense mit Ansible.

**Aufgabe**: Erstelle ein Playbook, um eine Firewall-Regel hinzuzufügen und zu prüfen.

1. **Ansible-Playbook für Firewall-Regeln**:
   - Erstelle ein Playbook:
     ```bash
     nano configure_firewall.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure OPNsense firewall rule
         hosts: opnsense
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
                   "destination":"192.168.30.101",
                   "destination_port":"80",
                   "description":"Allow HTTP to Ubuntu-VM"
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
       ```
   - **Erklärung**:
     - `configctl firewall rule add`: Fügt eine Firewall-Regel hinzu (JSON-Format).
     - Regel: Erlaubt TCP/80 von `192.168.30.0/24` zu `192.168.30.101` (Ubuntu-VM).

2. **Playbook ausführen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml configure_firewall.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display current rules] ****************************************************
       ok: [opnsense] => {
           "msg": "... Allow HTTP to Ubuntu-VM ..."
       }
       ```
   - Prüfe in der OPNsense-Weboberfläche:
     - Gehe zu `Firewall > Rules > LAN`.
     - Erwartete Regel: `pass`, Quelle `192.168.30.0/24`, Ziel `192.168.30.101:80`.

**Erkenntnis**: Ansible ermöglicht die Automatisierung komplexer Netzwerkkonfigurationen wie Firewall-Regeln durch Playbooks.

**Quelle**: https://docs.opnsense.org/manual/firewall.html

### Übung 3: Backup von Konfigurationen auf TrueNAS

**Ziel**: Automatisiere das Backup der OPNsense-Konfiguration und speichere es auf TrueNAS.

**Aufgabe**: Erstelle ein Playbook für Konfigurations-Backups und automatisiere es mit Cron.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_opnsense.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup OPNsense configuration
         hosts: opnsense
         vars:
           backup_dir: "/home/ubuntu/ansible-network-automation/backup-{{ ansible_date_time.date }}"
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
           - name: Save backup to file
             ansible.builtin.copy:
               content: "{{ backup_result.stdout }}"
               dest: "{{ backup_dir }}/opnsense-backup-{{ ansible_date_time.date }}.xml"
             delegate_to: localhost
           - name: Transfer backup to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/opnsense-backup-{{ ansible_date_time.date }}.xml
               root@192.168.30.100:/mnt/tank/backups/ansible-network-automation/
             delegate_to: localhost
           - name: Display backup status
             ansible.builtin.debug:
               msg: "Backup saved to {{ backup_dir }} and transferred to TrueNAS"
       ```
   - **Erklärung**:
     - `opnsense-backup`: Erstellt ein XML-Backup der OPNsense-Konfiguration.
     - `ansible.builtin.copy`: Speichert die Ausgabe lokal.
     - `rsync`: Überträgt das Backup an TrueNAS.

2. **Playbook testen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_opnsense.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display backup status] ****************************************************
       ok: [opnsense] => {
           "msg": "Backup saved to /home/ubuntu/ansible-network-automation/backup-<date> and transferred to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/ansible-network-automation/
     ```
     - Erwartete Ausgabe: `opnsense-backup-<date>.xml`.

3. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/ansible-network-automation
       ansible-playbook -i inventory.yml backup_opnsense.yml >> backup.log 2>&1
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
       0 3 * * * /home/ubuntu/ansible-network-automation/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible ermöglicht zuverlässige und wiederholbare Backups von Netzwerkkonfigurationen mit minimalem Aufwand.

**Quelle**: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/copy_module.html

### Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass SSH-Zugriff erlaubt ist:
     - Quelle: `192.168.30.0/24`
     - Ziel: `192.168.30.1`
     - Port: `22`
     - Aktion: `Allow`
   - Prüfe bestehende Firewall-Regeln:
     ```bash
     ansible-playbook -i inventory.yml -m ansible.builtin.command -a "configctl firewall list_rules" opnsense
     ```

2. **Monitoring mit Checkmk (optional)**:
   - Konfiguriere Checkmk für OPNsense:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Füge OPNsense als Host hinzu (falls nicht vorhanden):
       - Gehe zu `Setup > Hosts > Add host`.
       - Hostname: `opnsense`, IP: `192.168.30.1`.
       - Speichern und `Discover services`.
     - Prüfe:
       - Gehe zu `Monitor > All services`.
       - Erwartete Ausgabe: Services wie `CPU load`, `Memory`.

### Schritt 5: Erweiterung der Übungen
1. **Erweiterte Konfiguration**:
   - Erstelle ein Playbook für VLAN-Konfiguration:
     ```bash
     nano configure_vlan.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure VLAN on OPNsense
         hosts: opnsense
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
       ```
   - Teste mit:
     ```bash
     ansible-playbook -i inventory.yml configure_vlan.yml
     ```

2. **Validierung von Konfigurationen**:
   - Erstelle ein Playbook zur Prüfung von Firewall-Regeln:
     ```bash
     nano verify_firewall.yml
     ```
     - Inhalt:
       ```yaml
       - name: Verify OPNsense firewall rules
         hosts: opnsense
         tasks:
           - name: Check firewall rules
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Verify HTTP rule
             ansible.builtin.debug:
               msg: "HTTP rule found"
             when: "'Allow HTTP to Ubuntu-VM' in rules_list.stdout"
       ```

## Best Practices für Schüler

- **Automatisierungs-Design**:
  - Modularisiere Playbooks (separate Tasks für Konfiguration und Validierung).
  - Verwende SSH-Schlüssel statt Passwörter für sichere Verbindungen.
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
    cat ~/ansible-network-automation/backup.log
    ```
  - Prüfe OPNsense-Logs:
    ```bash
    ssh root@192.168.30.1 "cat /var/log/system/latest.log"
    ```

**Quelle**: https://docs.ansible.com, https://docs.opnsense.org

## Empfehlungen für Schüler

- **Setup**: Ansible, OPNsense, TrueNAS-Backups.
- **Workloads**: Automatisierte Firewall-Regeln und Konfigurations-Backups.
- **Integration**: Proxmox (VM), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Firewall-Regel für HTTP-Zugriff.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einfachen Playbooks, erweitere zu komplexeren Konfigurationen.
- **Übung**: Experimentiere mit VLANs oder NAT-Regeln.
- **Fehlerbehebung**: Nutze `ansible-playbook --check` für Trockenläufe.
- **Lernressourcen**: https://docs.ansible.com, https://docs.opnsense.org.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Netzwerk-Automatisierung mit Ansible und OPNsense.
- **Skalierbarkeit**: Automatisierte Konfigurationen und Backups.
- **Lernwert**: Verständnis von Ansible in einer HomeLab.

**Nächste Schritte**: Möchtest du eine Anleitung zu erweiterten Ansible-Playbooks für Multi-Device-Management, Integration mit Wazuh für Sicherheitsüberwachung, oder Log-Aggregation mit Fluentd?

**Quellen**:
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,,,,
```