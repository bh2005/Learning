# Lernprojekt: Rollback von Netzwerkgerätekonfigurationen mit Ansible und Git

## Einführung

Ein **Rollback** ermöglicht es, eine ältere Version der Konfiguration eines Netzwerkgeräts wiederherzustellen, um Fehler oder unerwünschte Änderungen rückgängig zu machen. Dieses Lernprojekt zeigt, wie man mit **Ansible** und **Git** einen Rollback der OPNsense-Konfiguration in einer HomeLab-Umgebung durchführt, basierend auf einem versionierten Backup-Repository. Es baut auf `network_device_backup_git_guide.md` () auf und nutzt die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense). Das Projekt ist für Lernende mit Grundkenntnissen in Linux, Ansible, Git und Netzwerkadministration geeignet und ist lokal, kostenlos und datenschutzfreundlich. Es umfasst drei Übungen: Auswahl einer älteren Backup-Version aus Git, Rollback der OPNsense-Konfiguration mit Ansible, und Validierung sowie Backup des Rollback-Prozesses auf TrueNAS.

**Voraussetzungen**:
- Ubuntu-VM auf Proxmox (IP `192.168.30.101`) mit Ansible und Git installiert (siehe `network_device_backup_git_guide.md`).
- OPNsense-Router (IP `192.168.30.1`) mit SSH-Zugriff aktiviert.
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups.
- Git-Repository mit OPNsense-Backups (max. 5 Versionen) im Verzeichnis `~/network-backup-git/backups/opnsense`.
- Grundkenntnisse in Linux, SSH, YAML, Ansible und Git.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`) für OPNsense.
- Optional: Checkmk Raw Edition (Site `homelab`) installiert für Monitoring (siehe `elk_checkmk_integration_guide.md`, ).

**Ziele**:
- Auswahl und Prüfung einer älteren Konfigurationsversion aus dem Git-Repository.
- Automatisierter Rollback der OPNsense-Konfiguration mit Ansible.
- Validierung des Rollbacks und Backup der neuen Konfiguration auf TrueNAS.

**Hinweis**: Der Rollback-Prozess verwendet Git, um eine ältere Konfiguration auszuwählen, und Ansible, um diese auf OPNsense anzuwenden. Vor dem Rollback wird die aktuelle Konfiguration gesichert.

**Quellen**:
- Ansible-Dokumentation: https://docs.ansible.com
- Git-Dokumentation: https://git-scm.com/doc
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,,,,

## Lernprojekt: Rollback von Netzwerkgerätekonfigurationen

### Vorbereitung: Umgebung prüfen
1. **Ubuntu-VM prüfen**:
   - Verbinde dich mit der VM:
     ```bash
     ssh ubuntu@192.168.30.101
     ```
   - Stelle sicher, dass Ansible und Git installiert sind:
     ```bash
     sudo apt update
     sudo apt install -y python3-pip git
     pip3 install ansible
     ansible --version
     git --version
     ```
   - Prüfe das Git-Repository:
     ```bash
     cd ~/network-backup-git
     git status
     ```
     - Erwartete Ausgabe: Verzeichnis `backups/opnsense` mit maximal fünf `opnsense-backup-<date>.xml`-Dateien.
2. **OPNsense prüfen**:
   - Stelle sicher, dass SSH-Zugriff aktiviert ist:
     - Öffne die OPNsense-Weboberfläche: `http://192.168.30.1`.
     - Gehe zu `System > Settings > Administration`.
     - Aktiviere `Enable Secure Shell` und erlaube `root`-Zugriff.
     - Stelle sicher, dass der SSH-Schlüssel vorhanden ist:
       ```bash
       ssh-copy-id root@192.168.30.1
       ```
   - Teste SSH:
     ```bash
     ssh root@192.168.30.1
     ```
3. **Projektverzeichnis prüfen**:
   - Stelle sicher, dass das Verzeichnis `~/network-backup-git` existiert und das Git-Repository initialisiert ist:
     ```bash
     cd ~/network-backup-git
     ls backups/opnsense
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf OPNsense (`192.168.30.1`) und TrueNAS (`192.168.30.100`).

### Übung 1: Auswahl einer älteren Backup-Version aus Git

**Ziel**: Identifiziere und prüfe eine ältere Konfigurationsversion im Git-Repository.

**Aufgabe**: Liste die verfügbaren Backups auf und wähle eine Version für den Rollback aus.

1. **Git-Historie prüfen**:
   - Wechsle in das Backup-Verzeichnis:
     ```bash
     cd ~/network-backup-git/backups/opnsense
     ```
   - Zeige die Commit-Historie an:
     ```bash
     git log --oneline
     ```
     - Erwartete Ausgabe (Beispiel):
       ```
       abc1234 Backup OPNsense 2025-09-10
       def5678 Backup OPNsense 2025-09-09
       ghi9012 Backup OPNsense 2025-09-08
       jkl3456 Backup OPNsense 2025-09-07
       mno7890 Backup OPNsense 2025-09-06
       ```
2. **Backup-Version auswählen**:
   - Wähle z. B. das Backup vom 2025-09-08 (Commit-Hash `ghi9012`):
     ```bash
     git show ghi9012:opnsense-backup-2025-09-08.xml
     ```
     - Erwartete Ausgabe: XML-Inhalt der Konfiguration (z. B. Firewall-Regeln, Schnittstellen).
   - Speichere die gewählte Version lokal:
     ```bash
     git show ghi9012:opnsense-backup-2025-09-08.xml > rollback-candidate.xml
     ```
3. **Backup-Inhalt prüfen**:
   - Überprüfe die Datei:
     ```bash
     cat rollback-candidate.xml
     ```
     - Stelle sicher, dass die Konfiguration gültig ist (z. B. enthält `<opnsense>`-XML-Struktur).

**Erkenntnis**: Git ermöglicht die einfache Auswahl und Prüfung älterer Konfigurationen für einen Rollback.

**Quelle**: https://git-scm.com/docs/git-show

### Übung 2: Rollback der OPNsense-Konfiguration mit Ansible

**Ziel**: Stelle die gewählte Backup-Version auf OPNsense wieder her.

**Aufgabe**: Erstelle ein Ansible-Playbook, um die aktuelle Konfiguration zu sichern und den Rollback durchzuführen.

1. **Ansible-Inventar prüfen**:
   - Stelle sicher, dass das Inventar existiert:
     ```bash
     cat ~/network-backup-git/inventory.yml
     ```
     - Inhalt (wie in `network_device_backup_git_guide.md`):
       ```yaml
       all:
         hosts:
           opnsense:
             ansible_host: 192.168.30.1
             ansible_user: root
             ansible_connection: ssh
             ansible_network_os: freebsd
       ```

2. **Ansible-Playbook für Rollback**:
   - Erstelle ein Playbook:
     ```bash
     cd ~/network-backup-git
     nano rollback_opnsense.yml
     ```
     - Inhalt:
       ```yaml
       - name: Rollback OPNsense configuration
         hosts: opnsense
         vars:
           backup_dir: "/home/ubuntu/network-backup-git/backups/opnsense"
           rollback_file: "/home/ubuntu/network-backup-git/backups/opnsense/rollback-candidate.xml"
           current_backup: "{{ backup_dir }}/opnsense-backup-{{ ansible_date_time.date }}-before-rollback.xml"
         tasks:
           - name: Create backup directory
             ansible.builtin.file:
               path: "{{ backup_dir }}"
               state: directory
               mode: '0755'
             delegate_to: localhost
           - name: Backup current OPNsense configuration
             ansible.builtin.command: opnsense-backup
             register: current_config
           - name: Save current configuration
             ansible.builtin.copy:
               content: "{{ current_config.stdout }}"
               dest: "{{ current_backup }}"
             delegate_to: localhost
           - name: Add current backup to Git
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && git add {{ current_backup | basename }} && git commit -m 'Backup before rollback {{ ansible_date_time.date }}'"
             delegate_to: localhost
           - name: Restore selected backup
             ansible.builtin.command: >
               opnsense-backup --restore {{ rollback_file }}
             register: restore_result
           - name: Display restore status
             ansible.builtin.debug:
               msg: "{{ restore_result.stdout }}"
       ```
   - **Erklärung**:
     - `opnsense-backup`: Sichert die aktuelle Konfiguration vor dem Rollback.
     - `opnsense-backup --restore`: Stellt die gewählte Konfiguration (`rollback-candidate.xml`) wieder her.
     - `git commit`: Versioniert die aktuelle Konfiguration vor dem Rollback.

3. **Playbook ausführen**:
   - Führe den Rollback aus:
     ```bash
     ansible-playbook -i inventory.yml rollback_opnsense.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display restore status] ****************************************************
       ok: [opnsense] => {
           "msg": "Configuration restored successfully"
       }
       ```
   - Prüfe in der OPNsense-Weboberfläche:
     - Gehe zu `System > Configuration > Backups`.
     - Stelle sicher, dass die Konfiguration vom 2025-09-08 (z. B. Firewall-Regeln) aktiv ist.

**Erkenntnis**: Ansible automatisiert den Rollback-Prozess, während ein Backup der aktuellen Konfiguration die Sicherheit erhöht.

**Quelle**: https://docs.opnsense.org/manual/backups.html

### Übung 3: Validierung und Backup auf TrueNAS

**Ziel**: Validiere den Rollback und sichere die neue Konfiguration auf TrueNAS.

**Aufgabe**: Erstelle ein Playbook zur Validierung der Konfiguration und zur Synchronisation mit TrueNAS, mit Begrenzung auf fünf Backups.

1. **Ansible-Playbook für Validierung und Synchronisation**:
   - Erstelle ein Playbook:
     ```bash
     nano validate_sync_truenas.yml
     ```
     - Inhalt:
       ```yaml
       - name: Validate and sync OPNsense configuration
         hosts: localhost
         vars:
           backup_dir: "/home/ubuntu/network-backup-git/backups/opnsense"
         tasks:
           - name: Limit backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t opnsense-backup-*.xml | tail -n +6 | xargs -I {} sh -c 'git rm {} && git commit -m \"Remove old backup {}}\" || true'"
           - name: Validate OPNsense configuration
             ansible.builtin.command: >
               ssh root@192.168.30.1 "configctl system validate"
             register: validate_result
           - name: Display validation status
             ansible.builtin.debug:
               msg: "{{ validate_result.stdout }}"
           - name: Sync backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/network-backup-git/
           - name: Display sync status
             ansible.builtin.debug:
               msg: "Backups synced to TrueNAS"
       ```
   - **Erklärung**:
     - `ls -t | tail -n +6`: Entfernt Backups über die Grenze von fünf.
     - `configctl system validate`: Prüft die Integrität der OPNsense-Konfiguration.
     - `rsync`: Synchronisiert das Backup-Verzeichnis mit TrueNAS.

2. **Playbook testen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml validate_sync_truenas.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display validation status] ************************************************
       ok: [localhost] => {
           "msg": "Configuration is valid"
       }
       TASK [Display sync status] ******************************************************
       ok: [localhost] => {
           "msg": "Backups synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/network-backup-git/
     ```
     - Erwartete Ausgabe: Maximal fünf `opnsense-backup-<date>.xml`-Dateien.

3. **Automatisierung mit Cron**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_rollback_sync.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/network-backup-git
       ansible-playbook -i inventory.yml validate_sync_truenas.yml >> rollback.log 2>&1
       ```
     - Ausführbar machen:
       ```bash
       chmod +x run_rollback_sync.sh
       ```
   - Plane einen Cronjob (für regelmäßige Validierung/Sync):
     ```bash
     crontab -e
     ```
     - Füge hinzu:
       ```
       0 4 * * * /home/ubuntu/network-backup-git/run_rollback_sync.sh
       ```
     - **Erklärung**: Führt Validierung und Synchronisation täglich um 04:00 Uhr aus.

**Erkenntnis**: Die Validierung stellt die Integrität der Konfiguration sicher, während TrueNAS-Backups zusätzliche Redundanz bieten.

**Quelle**: https://docs.ansible.com, https://www.rsync.org

### Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass SSH-Zugriff erlaubt ist:
     - Quelle: `192.168.30.0/24`
     - Ziel: `192.168.30.1`
     - Port: `22`
     - Aktion: `Allow`
   - Prüfe OPNsense-Logs nach dem Rollback:
     ```bash
     ansible-playbook -i inventory.yml -m ansible.builtin.command -a "cat /var/log/system/latest.log" opnsense
     ```

2. **Monitoring mit Checkmk (optional)**:
   - Konfiguriere Checkmk für OPNsense:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Füge OPNsense als Host hinzu (falls nicht vorhanden):
       - Hostname: `opnsense`, IP: `192.168.30.1`.
       - Speichern und `Discover services`.
     - Erstelle eine benutzerdefinierte Überprüfung für Backup-Zahlen:
       ```bash
       nano /omd/sites/homelab/local/share/check_mk/checks/backup_count
       ```
       - Inhalt:
         ```bash
         #!/bin/bash
         COUNT=$(ls -1 /home/ubuntu/network-backup-git/backups/opnsense/*.xml | wc -l)
         if [ $COUNT -le 5 ]; then
           echo "0 Backup_Count - $COUNT backups found, within limit"
         else
           echo "2 Backup_Count - $COUNT backups found, exceeds limit of 5"
         fi
         ```
       - Ausführbar machen:
         ```bash
         chmod +x /omd/sites/homelab/local/share/check_mk/checks/backup_count
         ```
       - In Checkmk: `Setup > Services > Manual checks > Custom checks`, füge `Backup_Count` hinzu.

### Schritt 5: Erweiterung der Übungen
1. **Erweiterte Rollback-Strategie**:
   - Erstelle ein Playbook zur Auswahl eines Rollbacks basierend auf einem Datum:
     ```bash
     nano select_rollback.yml
     ```
     - Inhalt:
       ```yaml
       - name: Select rollback version by date
         hosts: localhost
         vars:
           backup_dir: "/home/ubuntu/network-backup-git/backups/opnsense"
           target_date: "2025-09-08"
         tasks:
           - name: Find backup for target date
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && git show $(git log --oneline | grep {{ target_date }} | awk '{print $1}'):opnsense-backup-{{ target_date }}.xml"
             register: rollback_file
           - name: Save rollback candidate
             ansible.builtin.copy:
               content: "{{ rollback_file.stdout }}"
               dest: "{{ backup_dir }}/rollback-candidate.xml"
       ```

2. **Rollback-Validierung**:
   - Erstelle ein Playbook zur detaillierten Validierung:
     ```bash
     nano validate_rollback.yml
     ```
     - Inhalt:
       ```yaml
       - name: Validate rollback configuration
         hosts: opnsense
         tasks:
           - name: Check firewall rules after rollback
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Verify HTTP rule
             ansible.builtin.debug:
               msg: "HTTP rule restored"
             when: "'Allow HTTP' in rules_list.stdout"
       ```

## Best Practices für Schüler

- **Rollback-Design**:
  - Sichere immer die aktuelle Konfiguration vor einem Rollback.
  - Validiere die Konfiguration nach dem Rollback.
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
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, Git), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/network-backup-git/rollback.log
    ```
  - Prüfe Git-Historie:
    ```bash
    cd ~/network-backup-git/backups/opnsense
    git log --oneline
    ```

**Quelle**: https://docs.ansible.com, https://git-scm.com/doc, https://docs.opnsense.org

## Empfehlungen für Schüler

- **Setup**: Ansible, Git, OPNsense, TrueNAS-Backups.
- **Workloads**: Rollback von Konfigurationen und Validierung.
- **Integration**: Proxmox (VM), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Rollback zu einer OPNsense-Konfiguration vom 2025-09-08.

## Tipps für den Erfolg

- **Einfachheit**: Teste Rollbacks in einer Testumgebung, bevor du sie in Produktion anwendest.
- **Übung**: Experimentiere mit verschiedenen Backup-Daten für Rollbacks.
- **Fehlerbehebung**: Nutze `ansible-playbook --check` und `git diff`.
- **Lernressourcen**: https://docs.ansible.com, https://git-scm.com/doc, https://docs.opnsense.org.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Rollback von Netzwerkkonfigurationen mit Ansible und Git.
- **Skalierbarkeit**: Automatisierte Wiederherstellung und Validierung.
- **Lernwert**: Verständnis von Rollback-Strategien und Versionskontrolle.

**Nächste Schritte**: Möchtest du eine Anleitung zu Integration mit Wazuh für Sicherheitsüberwachung, Log-Aggregation mit Fluentd, oder erweitertem Monitoring mit Checkmk?

**Quellen**:
- Ansible-Dokumentation: https://docs.ansible.com
- Git-Dokumentation: https://git-scm.com/doc
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,,,,
```