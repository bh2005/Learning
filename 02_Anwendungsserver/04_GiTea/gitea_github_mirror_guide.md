# Lernprojekt: Verbinden eines lokalen Gitea-Servers mit einem externen GitHub-Repository in einer HomeLab-Umgebung

## Einführung

**Gitea** ermöglicht die Spiegelung (Mirroring) von externen Git-Repositorys, um lokale Kopien zu erstellen oder Änderungen zwischen einem lokalen Gitea-Server und einem externen Dienst wie GitHub zu synchronisieren. Dieses Lernprojekt zeigt, wie man einen lokalen Gitea-Server (in einer HomeLab-Umgebung) mit einem GitHub-Repository verbindet, um bidirektionale Synchronisation zu ermöglichen. Es baut auf `gitea_code_checkin_checkout_guide.md` () auf und nutzt die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense). Das Projekt ist für Lernende mit Grundkenntnissen in Linux, Git, Ansible und Netzwerkadministration geeignet und ist lokal, kostenlos (abgesehen von einem GitHub-Konto) und datenschutzfreundlich. Es umfasst drei Übungen: Einrichten eines gespiegelten Repositorys in Gitea, Konfiguration von Firewall-Regeln für ausgehenden GitHub-Zugriff, und Backup der Gitea-Daten auf TrueNAS.

**Voraussetzungen**:
- Gitea-Server als LXC-Container auf Proxmox VE (IP `192.168.30.104`, Hostname `gitea.homelab.local`, siehe `gitea_turnkey_lxc_installation_guide.md`).
- OPNsense-Router (IP `192.168.30.1`) mit SSH-Zugriff und DNS-Resolver.
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups.
- Ubuntu-VM (IP `192.168.30.101`) mit Ansible und Git installiert (siehe `ansible_multi_device_management_guide.md`, ).
- GitHub-Konto mit einem Repository (z. B. `username/test-repo`).
- GitHub Personal Access Token (PAT) mit `repo`-Berechtigungen (siehe https://github.com/settings/tokens).
- Grundkenntnisse in Linux, SSH, Git, YAML und Ansible.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`) auf der Ubuntu-VM für Gitea-Zugriff.
- Optional: Checkmk Raw Edition (Site `homelab`) für Monitoring (siehe `elk_checkmk_integration_guide.md`, ).
- DNS-Eintrag für Gitea (`gitea.homelab.local` auf `192.168.30.104`).

**Ziele**:
- Einrichten eines gespiegelten Repositorys in Gitea, das mit einem GitHub-Repository synchronisiert wird.
- Konfiguration von Firewall-Regeln auf OPNsense für ausgehenden GitHub-Zugriff.
- Backup der Gitea-Repository-Daten auf TrueNAS mit Begrenzung auf fünf Versionen.

**Hinweis**: Dieses Projekt verwendet HTTPS für die GitHub-Verbindung, da es einfacher einzurichten ist. SSH-Mirroring ist ebenfalls möglich, erfordert jedoch zusätzliche Schlüsselkonfiguration.

**Quellen**:
- Gitea-Dokumentation: https://docs.gitea.com
- GitHub-Dokumentation: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,,,,

## Lernprojekt: Verbinden eines lokalen Gitea-Servers mit einem GitHub-Repository

### Vorbereitung: Umgebung prüfen
1. **Gitea-Server prüfen**:
   - Verbinde dich mit dem Gitea-LXC-Container:
     ```bash
     ssh root@192.168.30.104
     ```
   - Stelle sicher, dass Gitea läuft:
     ```bash
     systemctl status gitea
     ```
     - Erwartete Ausgabe: `active (running)`.
   - Teste die Weboberfläche:
     ```bash
     curl https://gitea.homelab.local
     ```
     - Erwartete Ausgabe: HTML der Gitea-Anmeldeseite.
     - Melde dich als `admin` an (`https://192.168.30.104`, Passwort: `securepassword123`).
2. **GitHub Personal Access Token erstellen**:
   - Gehe zu https://github.com/settings/tokens.
   - Erstelle einen neuen PAT:
     - Name: `gitea-mirror`
     - Berechtigungen: `repo` (alle Unteroptionen).
     - Notiere den Token (z. B. `ghp_abcdefghijklmnopqrstuvwxyz1234567890`).
3. **Ansible- und Git-Umgebung prüfen**:
   - Auf der Ubuntu-VM (`192.168.30.101`):
     ```bash
     ssh ubuntu@192.168.30.101
     ansible --version
     git --version
     ```
   - Stelle sicher, dass SSH-Zugriff auf Gitea und OPNsense möglich ist:
     ```bash
     ssh root@192.168.30.104
     ssh root@192.168.30.1
     ```
4. **Projektverzeichnis erstellen**:
   - Auf `192.168.30.101`:
     ```bash
     mkdir ~/gitea-github-mirror
     cd ~/gitea-github-mirror
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Gitea (`192.168.30.104`), OPNsense (`192.168.30.1`) und TrueNAS (`192.168.30.100`). Halte den GitHub PAT bereit.

### Übung 1: Einrichten eines gespiegelten Repositorys in Gitea

**Ziel**: Erstelle ein gespiegeltes Repository in Gitea, das mit einem GitHub-Repository synchronisiert wird.

**Aufgabe**: Verwende Ansible, um ein Mirror-Repository zu erstellen und die Synchronisation mit GitHub zu konfigurieren.

1. **Ansible-Inventar erstellen**:
   - Erstelle eine Inventar-Datei:
     ```bash
     nano inventory.yml
     ```
     - Inhalt:
       ```yaml
       all:
         children:
           gitea_servers:
             hosts:
               gitea:
                 ansible_host: 192.168.30.104
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

2. **Ansible-Playbook für Mirror-Repository**:
   - Erstelle ein Playbook:
     ```bash
     nano setup_gitea_mirror.yml
     ```
     - Inhalt:
       ```yaml
       - name: Setup Gitea mirror for GitHub repository
         hosts: gitea_servers
         become: yes
         vars:
           gitea_user: "admin"
           gitea_password: "securepassword123"
           github_repo: "https://github.com/username/test-repo.git"
           github_token: "ghp_abcdefghijklmnopqrstuvwxyz1234567890"
           mirror_repo_name: "github-mirror-test-repo"
         tasks:
           - name: Install curl for API calls
             ansible.builtin.apt:
               name: curl
               state: present
               update_cache: yes
           - name: Create mirror repository via Gitea API
             ansible.builtin.uri:
               url: "https://gitea.homelab.local/api/v1/repos/migrate"
               method: POST
               user: "{{ gitea_user }}"
               password: "{{ gitea_password }}"
               headers:
                 Content-Type: application/json
               body_format: json
               body:
                 clone_addr: "{{ github_repo }}"
                 auth_token: "{{ github_token }}"
                 repo_name: "{{ mirror_repo_name }}"
                 mirror: true
                 private: false
                 uid: 1
                 description: "Mirror of GitHub test-repo"
                 mirror_interval: "1h"
               status_code: 201
               validate_certs: no
           - name: Trigger initial mirror sync
             ansible.builtin.uri:
               url: "https://gitea.homelab.local/api/v1/repos/{{ gitea_user }}/{{ mirror_repo_name }}/mirror-sync"
               method: POST
               user: "{{ gitea_user }}"
               password: "{{ gitea_password }}"
               headers:
                 Content-Type: application/json
               status_code: 200
               validate_certs: no
           - name: Display mirror setup status
             ansible.builtin.debug:
               msg: "Mirror repository {{ mirror_repo_name }} created and synced with {{ github_repo }}"
       ```
   - **Erklärung**:
     - Installiert `curl` für API-Aufrufe.
     - Erstellt ein Mirror-Repository mit der Gitea-API, das mit dem GitHub-Repository synchronisiert wird.
     - Setzt die Synchronisation auf stündlich (`mirror_interval: "1h"`).
     - Löst eine sofortige Synchronisation aus.

3. **Playbook ausführen**:
   - Ersetze `username/test-repo` und `ghp_abcdefghijklmnopqrstuvwxyz1234567890` im Playbook mit deinem GitHub-Repository und PAT.
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml setup_gitea_mirror.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display mirror setup status] **********************************************
       ok: [gitea] => {
           "msg": "Mirror repository github-mirror-test-repo created and synced with https://github.com/username/test-repo.git"
       }
       ```
   - Prüfe in der Gitea-Weboberfläche:
     - Öffne `https://192.168.30.104`.
     - Melde dich als `admin` an.
     - Erwartete Ausgabe: Repository `admin/github-mirror-test-repo` enthält den Inhalt des GitHub-Repositorys.

**Erkenntnis**: Gitea’s Mirroring-Funktion ermöglicht einfache Synchronisation mit GitHub, automatisiert durch Ansible.

**Quelle**: https://docs.gitea.com/next/administration/repo-mirror

### Übung 2: Konfiguration von Firewall-Regeln für GitHub-Zugriff

**Ziel**: Konfiguriere OPNsense-Firewall-Regeln, um ausgehenden HTTPS-Verkehr zu GitHub zu erlauben.

**Aufgabe**: Erstelle ein Ansible-Playbook, um Firewall-Regeln für ausgehenden GitHub-Zugriff zu konfigurieren.

1. **Ansible-Playbook für Firewall-Regeln**:
   - Erstelle ein Playbook:
     ```bash
     nano configure_firewall_github.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure OPNsense firewall for GitHub access
         hosts: network_devices
         tasks:
           - name: Add firewall rule for outgoing HTTPS to GitHub
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"out",
                 "protocol":"tcp",
                 "source":"192.168.30.104",
                 "destination_net":"any",
                 "destination_port":"443",
                 "description":"Allow HTTPS to GitHub for Gitea"
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
     - Fügt eine Regel hinzu, die ausgehenden HTTPS-Verkehr (Port 443) von `192.168.30.104` erlaubt.
     - Prüft die aktiven Firewall-Regeln.

2. **Playbook ausführen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml configure_firewall_github.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display firewall rules] ****************************************************
       ok: [opnsense] => {
           "msg": "... Allow HTTPS to GitHub for Gitea ..."
       }
       ```
   - Prüfe in der OPNsense-Weboberfläche:
     - Gehe zu `Firewall > Rules > LAN`.
     - Erwartete Regel: `pass`, Quelle `192.168.30.104`, Ziel `any:443`.

**Erkenntnis**: Ansible ermöglicht präzise Firewall-Konfigurationen für externe Dienste wie GitHub.

**Quelle**: https://docs.opnsense.org/manual/firewall.html

### Übung 3: Backup der Gitea-Repository-Daten auf TrueNAS

**Ziel**: Sichere die Gitea-Repository-Daten (inklusive Mirror) und versioniere sie auf TrueNAS.

**Aufgabe**: Erstelle ein Ansible-Playbook für Backups und begrenze sie auf maximal fünf Versionen.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_gitea_mirror.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup Gitea repositories and configuration
         hosts: gitea_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/gitea-github-mirror/backups/gitea"
           backup_file: "{{ backup_dir }}/gitea-mirror-backup-{{ ansible_date_time.date }}.tar.gz"
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
           - name: Backup Gitea repositories and configuration
             ansible.builtin.command: >
               tar -czf /tmp/gitea-mirror-backup-{{ ansible_date_time.date }}.tar.gz /home/git/gitea /var/lib/mysql
             register: backup_result
           - name: Start Gitea service
             ansible.builtin.service:
               name: gitea
               state: started
           - name: Fetch backup file
             ansible.builtin.fetch:
               src: /tmp/gitea-mirror-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ backup_file }}"
               flat: yes
           - name: Limit backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t gitea-mirror-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/gitea-github-mirror/
             delegate_to: localhost
           - name: Display backup status
             ansible.builtin.debug:
               msg: "Backup saved to {{ backup_file }} and synced to TrueNAS"
       ```
   - **Erklärung**:
     - Stoppt den Gitea-Dienst, um konsistente Backups zu gewährleisten.
     - Sichert `/home/git/gitea` (Repositorys und Konfiguration) und `/var/lib/mysql` (Datenbank).
     - Begrenzt Backups auf fünf durch Entfernen älterer Dateien.
     - Synchronisiert Backups mit TrueNAS.

2. **Playbook testen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_gitea_mirror.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display backup status] ****************************************************
       ok: [gitea] => {
           "msg": "Backup saved to /home/ubuntu/gitea-github-mirror/backups/gitea/gitea-mirror-backup-<date>.tar.gz and synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/gitea-github-mirror/
     ```
     - Erwartete Ausgabe: Maximal fünf `gitea-mirror-backup-<date>.tar.gz`.

3. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/gitea-github-mirror
       ansible-playbook -i inventory.yml backup_gitea_mirror.yml >> backup.log 2>&1
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
       0 3 * * * /home/ubuntu/gitea-github-mirror/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible automatisiert die Sicherung von Gitea-Daten, einschließlich gespiegelter Repositorys, während TrueNAS externe Speicherung bietet.

**Quelle**: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/fetch_module.html

### Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass die Firewall-Regeln aus Übung 2 aktiv sind (Port 443 für GitHub).
   - Prüfe OPNsense-Logs:
     ```bash
     ansible-playbook -i inventory.yml -m ansible.builtin.command -a "cat /var/log/system/latest.log" opnsense
     ```

2. **Monitoring mit Checkmk (optional)**:
   - Konfiguriere Checkmk für den Gitea-Server:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Stelle sicher, dass `gitea` (IP `192.168.30.104`) als Host hinzugefügt ist.
     - Prüfe Services:
       - Gehe zu `Monitor > All services`.
       - Erwartete Ausgabe: Services wie `Gitea`, `Nginx`, `MySQL`.
     - Erstelle eine benutzerdefinierte Überprüfung für Mirror-Status:
       ```bash
       nano /omd/sites/homelab/local/share/check_mk/checks/gitea_mirror
       ```
       - Inhalt:
         ```bash
         #!/bin/bash
         STATUS=$(curl -s -u admin:securepassword123 https://gitea.homelab.local/api/v1/repos/admin/github-mirror-test-repo | grep '"mirror": true')
         if [ -n "$STATUS" ]; then
           echo "0 Gitea_Mirror - Mirror repository is active"
         else
           echo "2 Gitea_Mirror - Mirror repository not found or inactive"
         fi
         ```
       - Ausführbar machen:
         ```bash
         chmod +x /omd/sites/homelab/local/share/check_mk/checks/gitea_mirror
         ```
       - In Checkmk: `Setup > Services > Manual checks > Custom checks`, füge `Gitea_Mirror` hinzu.

### Schritt 5: Erweiterung der Übungen
1. **Bidirektionale Synchronisation**:
   - Konfiguriere Push-Mirroring zu GitHub:
     ```bash
     nano configure_push_mirror.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure push mirror to GitHub
         hosts: gitea_servers
         become: yes
         vars:
           gitea_user: "admin"
           gitea_password: "securepassword123"
           github_repo: "https://github.com/username/test-repo.git"
           github_token: "ghp_abcdefghijklmnopqrstuvwxyz1234567890"
           mirror_repo_name: "github-mirror-test-repo"
         tasks:
           - name: Add push mirror to GitHub
             ansible.builtin.uri:
               url: "https://gitea.homelab.local/api/v1/repos/{{ gitea_user }}/{{ mirror_repo_name }}/push_mirrors"
               method: POST
               user: "{{ gitea_user }}"
               password: "{{ gitea_password }}"
               headers:
                 Content-Type: application/json
               body_format: json
               body:
                 remote_address: "{{ github_repo }}"
                 remote_auth_username: "username"
                 remote_auth_password: "{{ github_token }}"
                 sync_on_commit: true
               status_code: 201
               validate_certs: no
       ```

2. **Backup-Versionierung mit Git**:
   - Initialisiere ein Git-Repository für Backups:
     ```bash
     cd ~/gitea-github-mirror/backups/gitea
     git init
     git add .
     git commit -m "Initial Gitea mirror backup"
     ```

## Best Practices für Schüler

- **Mirror-Design**:
  - Verwende HTTPS mit einem GitHub PAT für einfache Authentifizierung.
  - Stelle regelmäßige Synchronisation (z. B. stündlich) ein.
- **Sicherheit**:
  - Schränke ausgehenden Zugriff ein:
    ```bash
    ssh root@192.168.30.104 "ufw allow from 192.168.30.104 to any port 443"
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
  - Speichere den GitHub PAT sicher (z. B. in Ansible Vault).
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe Gitea-Logs:
    ```bash
    ssh root@192.168.30.104 "cat /home/git/gitea/log/gitea.log"
    ```
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/gitea-github-mirror/backup.log
    ```

**Quelle**: https://docs.gitea.com, https://docs.github.com, https://docs.ansible.com

## Empfehlungen für Schüler

- **Setup**: Gitea, GitHub, Ansible, TrueNAS-Backups.
- **Workloads**: Mirror-Repository, Firewall-Konfiguration, Backups.
- **Integration**: Proxmox (LXC), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Spiegelung eines GitHub-Repositorys in Gitea.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einem Pull-Mirror, erweitere zu Push-Mirroring.
- **Übung**: Experimentiere mit unterschiedlichen Synchronisationsintervallen.
- **Fehlerbehebung**: Nutze `ansible-playbook --check` und Gitea-Logs.
- **Lernressourcen**: https://docs.gitea.com, https://docs.github.com, https://docs.opnsense.org.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Verbindung eines lokalen Gitea-Servers mit GitHub.
- **Skalierbarkeit**: Automatisierte Mirror- und Backup-Konfigurationen.
- **Lernwert**: Verständnis von Repository-Mirroring und HomeLab-Integration.

**Nächste Schritte**: Möchtest du eine Anleitung zu Integration mit Wazuh für Sicherheitsüberwachung, Log-Aggregation mit Fluentd, oder erweitertem Monitoring mit Checkmk?

**Quellen**:
- Gitea-Dokumentation: https://docs.gitea.com
- GitHub-Dokumentation: https://docs.github.com
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,,,,
```