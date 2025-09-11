# Lernprojekt: Backup von Netzwerkgeräten mit Ansible und Versionskontrolle in Git

## Einführung

Das Sichern von Netzwerkgerätekonfigurationen und das Verwalten dieser Backups mit einer Versionskontrolle wie **Git** ist entscheidend für die Nachverfolgbarkeit und Wiederherstellung von Konfigurationen. Dieses Lernprojekt zeigt, wie man mit **Ansible** Backups von Netzwerkgeräten (z. B. OPNsense-Router) in einer HomeLab-Umgebung erstellt, diese in einem Git-Repository versioniert und maximal fünf Backups behält. Es baut auf `ansible_multi_device_management_guide.md` () auf und nutzt die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense). Das Projekt ist für Lernende mit Grundkenntnissen in Linux, Ansible, Git und Netzwerkadministration geeignet und ist lokal, kostenlos und datenschutzfreundlich. Es umfasst drei Übungen: Einrichten eines Git-Repositorys, Automatisierung von Backups mit Ansible, und Begrenzung auf maximal fünf Backups.

**Voraussetzungen**:
- Ubuntu-VM auf Proxmox (IP `192.168.30.101`) mit Ansible installiert (siehe `ansible_multi_device_management_guide.md`).
- OPNsense-Router (IP `192.168.30.1`) mit SSH-Zugriff aktiviert.
- HomeLab mit TrueNAS (`192.168.30.100`) für zusätzliche Backups.
- Grundkenntnisse in Linux, SSH, YAML, Ansible und Git.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`) für OPNsense.
- `git` installiert auf der Ubuntu-VM.

**Ziele**:
- Einrichten eines lokalen Git-Repositorys für Netzwerkgeräte-Backups.
- Automatisierte Erstellung und Versionierung von OPNsense-Backups mit Ansible.
- Begrenzung auf maximal fünf Backups durch Skriptlogik.
- Optional: Synchronisation mit TrueNAS für externe Speicherung.

**Hinweis**: Ansible automatisiert die Backup-Erstellung, während Git die Versionskontrolle übernimmt. Die Begrenzung auf fünf Backups wird durch ein Shell-Skript umgesetzt.

**Quellen**:
- Ansible-Dokumentation: https://docs.ansible.com
- Git-Dokumentation: https://git-scm.com/doc
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,,,,

## Lernprojekt: Backup und Versionskontrolle von Netzwerkgeräten

### Vorbereitung: Umgebung einrichten
1. **Ubuntu-VM prüfen**:
   - Verbinde dich mit der VM:
     ```bash
     ssh ubuntu@192.168.30.101
     ```
   - Installiere notwendige Pakete:
     ```bash
     sudo apt update
     sudo apt install -y python3-pip git
     pip3 install ansible
     ```
   - Prüfe Ansible und Git:
     ```bash
     ansible --version
     git --version
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
3. **Projektverzeichnis und Git-Repository erstellen**:
   - Erstelle ein Verzeichnis:
     ```bash
     mkdir ~/network-backup-git
     cd ~/network-backup-git
     ```
   - Initialisiere ein Git-Repository:
     ```bash
     git init
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf OPNsense und TrueNAS.

### Übung 1: Einrichten eines Git-Repositorys für Backups

**Ziel**: Erstelle ein lokales Git-Repository für OPNsense-Backups und teste die Versionierung.

**Aufgabe**: Initialisiere ein Git-Repository und füge eine Beispielkonfiguration hinzu.

1. **Git-Repository konfigurieren**:
   - Erstelle eine Verzeichnisstruktur für Backups:
     ```bash
     mkdir -p backups/opnsense
     ```
   - Erstelle eine `.gitignore`-Datei:
     ```bash
     nano .gitignore
     ```
     - Inhalt:
       ```
       *.log
       *.tmp
       ```
   - Konfiguriere Git-Benutzer:
     ```bash
     git config --global user.name "Your Name"
     git config --global user.email "your.email@example.com"
     ```

2. **Test-Backup hinzufügen**:
   - Erstelle ein Beispiel-Backup:
     ```bash
     echo "<opnsense><test>Initial backup</test></opnsense>" > backups/opnsense/test-backup.xml
     ```
   - Füge das Backup zu Git hinzu:
     ```bash
     git add backups/opnsense/test-backup.xml
     git commit -m "Initial test backup"
     ```
   - Prüfe die Historie:
     ```bash
     git log
     ```
     - Erwartete Ausgabe:
       ```
       commit <hash> (HEAD -> master)
       Author: Your Name <your.email@example.com>
       Date:   Wed Sep 10 12:49:00 2025 +0200
           Initial test backup
       ```

**Erkenntnis**: Git ermöglicht die Versionskontrolle von Backups, um Änderungen nachzuverfolgen und ältere Konfigurationen wiederherzustellen.

**Quelle**: https://git-scm.com/doc

### Übung 2: Automatisierung von Backups mit Ansible

**Ziel**: Automatisiere die Erstellung von OPNsense-Backups und versioniere sie in Git.

**Aufgabe**: Erstelle ein Ansible-Playbook, um Backups zu erstellen und in Git zu committen.

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

2. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_opnsense.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup OPNsense configuration
         hosts: opnsense
         vars:
           backup_dir: "/home/ubuntu/network-backup-git/backups/opnsense"
           backup_file: "{{ backup_dir }}/opnsense-backup-{{ ansible_date_time.date }}.xml"
         tasks:
           - name: Create backup directory
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
               dest: "{{ backup_file }}"
             delegate_to: localhost
           - name: Add backup to Git
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && git add {{ backup_file | basename }} && git commit -m 'Backup OPNsense {{ ansible_date_time.date }}'"
             delegate_to: localhost
           - name: Display backup status
             ansible.builtin.debug:
               msg: "Backup saved to {{ backup_file }} and committed to Git"
       ```
   - **Erklärung**:
     - `opnsense-backup`: Erstellt ein XML-Backup der OPNsense-Konfiguration.
     - `ansible.builtin.copy`: Speichert das Backup lokal.
     - `git add` und `git commit`: Versioniert das Backup in Git.

3. **Playbook testen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_opnsense.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display backup status] ****************************************************
       ok: [opnsense] => {
           "msg": "Backup saved to /home/ubuntu/network-backup-git/backups/opnsense/opnsense-backup-<date>.xml and committed to Git"
       }
       ```
   - Prüfe die Git-Historie:
     ```bash
     cd backups/opnsense
     git log
     ```
     - Erwartete Ausgabe: Neuer Commit mit „Backup OPNsense <date>“.

**Erkenntnis**: Ansible automatisiert die Backup-Erstellung, während Git die Nachverfolgbarkeit sicherstellt.

**Quelle**: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/copy_module.html

### Übung 3: Begrenzung auf maximal fünf Backups und Synchronisation mit TrueNAS

**Ziel**: Begrenze die Anzahl der Backups auf fünf und sichere sie auf TrueNAS.

**Aufgabe**: Erstelle ein Skript, um alte Backups zu löschen, und ein Playbook für die TrueNAS-Synchronisation.

1. **Skript zur Begrenzung auf fünf Backups**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano limit_backups.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       BACKUP_DIR=/home/ubuntu/network-backup-git/backups/opnsense
       MAX_BACKUPS=5
       cd $BACKUP_DIR
       # Get list of backup files sorted by name (date)
       BACKUPS=$(ls -t opnsense-backup-*.xml)
       COUNT=$(echo "$BACKUPS" | wc -l)
       if [ $COUNT -gt $MAX_BACKUPS ]; then
         echo "$BACKUPS" | tail -n +$((MAX_BACKUPS + 1)) | xargs -I {} sh -c 'git rm {} && git commit -m "Remove old backup {}"'
       fi
       ```
   - Ausführbar machen:
     ```bash
     chmod +x limit_backups.sh
     ```
   - **Erklärung**:
     - `ls -t`: Sortiert Backups nach Datum (neueste zuerst).
     - `tail -n +6`: Wählt Dateien ab dem sechsten Eintrag aus.
     - `git rm`: Entfernt alte Backups aus dem Repository.

2. **Ansible-Playbook für TrueNAS-Synchronisation**:
   - Erstelle ein Playbook:
     ```bash
     nano sync_truenas.yml
     ```
     - Inhalt:
       ```yaml
       - name: Sync backups to TrueNAS
         hosts: localhost
         vars:
           backup_dir: "/home/ubuntu/network-backup-git/backups/opnsense"
         tasks:
           - name: Limit backups to 5
             ansible.builtin.command: ./limit_backups.sh
             args:
               chdir: /home/ubuntu/network-backup-git
           - name: Push to Git
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && git push origin master || true"
           - name: Sync backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/network-backup-git/
           - name: Display sync status
             ansible.builtin.debug:
               msg: "Backups synced to TrueNAS"
       ```
   - **Erklärung**:
     - `limit_backups.sh`: Entfernt Backups über die Grenze von fünf.
     - `rsync`: Synchronisiert das Backup-Verzeichnis mit TrueNAS.
     - `git push`: Optional für ein Remote-Repository (hier mit `|| true` für lokale Nutzung).

3. **Backup und Synchronisation automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup_sync.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/network-backup-git
       ansible-playbook -i inventory.yml backup_opnsense.yml >> backup.log 2>&1
       ansible-playbook -i inventory.yml sync_truenas.yml >> backup.log 2>&1
       ```
     - Ausführbar machen:
       ```bash
       chmod +x run_backup_sync.sh
       ```
   - Plane einen Cronjob:
     ```bash
     crontab -e
     ```
     - Füge hinzu:
       ```
       0 3 * * * /home/ubuntu/network-backup-git/run_backup_sync.sh
       ```
     - **Erklärung**: Führt Backup und Synchronisation täglich um 03:00 Uhr aus.

4. **Testen**:
   - Führe das Skript aus:
     ```bash
     ./run_backup_sync.sh
     ```
   - Prüfe Backups im Git-Repository:
     ```bash
     cd backups/opnsense
     ls -l
     ```
     - Erwartete Ausgabe: Maximal fünf `opnsense-backup-<date>.xml`-Dateien.
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/network-backup-git/
     ```
     - Erwartete Ausgabe: `opnsense-backup-<date>.xml` (max. fünf).

**Erkenntnis**: Die Kombination aus Ansible und Git ermöglicht automatisierte, versionierte Backups mit Begrenzung, während TrueNAS externe Sicherheit bietet.

**Quelle**: https://docs.opnsense.org/manual, https://www.rsync.org

### Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass SSH-Zugriff erlaubt ist:
     - Quelle: `192.168.30.0/24`
     - Ziel: `192.168.30.1`
     - Port: `22`
     - Aktion: `Allow`
   - Prüfe OPNsense-Logs:
     ```bash
     ansible-playbook -i inventory.yml -m ansible.builtin.command -a "cat /var/log/system/latest.log" opnsense
     ```

2. **Monitoring mit Checkmk (optional)**:
   - Konfiguriere Checkmk für OPNsense:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Füge OPNsense als Host hinzu (falls nicht vorhanden):
       - Hostname: `opnsense`, IP: `192.168.30.1`.
       - Speichern und `Discover services`.
     - Prüfe Backup-Status:
       - Erstelle eine benutzerdefinierte Überprüfung:
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
1. **Erweiterte Backup-Strategie**:
   - Füge ein Remote-Git-Repository hinzu (z. B. GitHub):
     ```bash
     git remote add origin <repository-url>
     git push -u origin master
     ```
   - Aktualisiere das Playbook `sync_truenas.yml`, um `git push` zu verwenden:
     ```yaml
     - name: Push to remote Git repository
       ansible.builtin.command: >
         bash -c "cd {{ backup_dir }} && git push origin master"
     ```

2. **Erweiterte Backup-Prüfung**:
   - Erstelle ein Playbook zur Validierung von Backups:
     ```bash
     nano verify_backup.yml
     ```
     - Inhalt:
       ```yaml
       - name: Verify OPNsense backups
         hosts: localhost
         vars:
           backup_dir: "/home/ubuntu/network-backup-git/backups/opnsense"
         tasks:
           - name: Count backups
             ansible.builtin.command: ls -1 {{ backup_dir }}/*.xml | wc -l
             register: backup_count
           - name: Check backup limit
             ansible.builtin.debug:
               msg: "{{ 'Backup count OK' if backup_count.stdout | int <= 5 else 'Too many backups' }}"
       ```

## Best Practices für Schüler

- **Backup-Design**:
  - Verwende strukturierte Verzeichnisse (`backups/opnsense`) für Klarheit.
  - Automatisiere mit Ansible und versioniere mit Git.
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
    cat ~/network-backup-git/backup.log
    ```
  - Prüfe Git-Status:
    ```bash
    cd ~/network-backup-git/backups/opnsense
    git status
    ```

**Quelle**: https://docs.ansible.com, https://git-scm.com/doc, https://docs.opnsense.org

## Empfehlungen für Schüler

- **Setup**: Ansible, Git, OPNsense, TrueNAS-Backups.
- **Workloads**: Automatisierte Backups und Versionskontrolle.
- **Integration**: Proxmox (VM), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Versionierte OPNsense-Backups mit maximal fünf Versionen.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einem Gerät, erweitere zu Multi-Device-Backups.
- **Übung**: Experimentiere mit Remote-Git-Repositories oder zusätzlichen Geräten.
- **Fehlerbehebung**: Nutze `ansible-playbook --check` und `git log`.
- **Lernressourcen**: https://docs.ansible.com, https://git-scm.com/doc, https://docs.opnsense.org.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Automatisierte Backups mit Ansible und Git.
- **Skalierbarkeit**: Begrenzung auf fünf Backups und TrueNAS-Synchronisation.
- **Lernwert**: Verständnis von Backup- und Versionskontrollstrategien.

**Nächste Schritte**: Möchtest du eine Anleitung zu Integration mit Wazuh für Sicherheitsüberwachung, Log-Aggregation mit Fluentd, oder erweitertem Monitoring mit Checkmk?

**Quellen**:
- Ansible-Dokumentation: https://docs.ansible.com
- Git-Dokumentation: https://git-scm.com/doc
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,,,,
```