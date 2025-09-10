# Lernprojekt: Ein- und Auschecken von Code in Gitea in einer HomeLab-Umgebung

## Einführung

**Gitea** ist ein leichtgewichtiger, selbst gehosteter Git-Dienst, der das Verwalten von Code-Repositorys ermöglicht. Dieses Lernprojekt zeigt, wie man Code in ein Gitea-Repository eincheckt (push) und auscheckt (clone/pull) in einer HomeLab-Umgebung. Es baut auf `gitea_turnkey_lxc_installation_guide.md` () auf und nutzt die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense). Das Projekt ist für Lernende mit Grundkenntnissen in Linux, Git, Ansible und Netzwerkadministration geeignet und ist lokal, kostenlos und datenschutzfreundlich. Es umfasst drei Übungen: Einrichten eines Gitea-Repositorys und Benutzerzugriffs, Einchecken und Auschecken von Code mit Git, und Automatisierung von Backups der Repository-Daten auf TrueNAS.

**Voraussetzungen**:
- Gitea-Server als LXC-Container auf Proxmox VE (IP `192.168.30.104`, Hostname `gitea.homelab.local`, siehe `gitea_turnkey_lxc_installation_guide.md`).
- OPNsense-Router (IP `192.168.30.1`) mit SSH-Zugriff und DNS-Resolver.
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups.
- Ubuntu-VM (IP `192.168.30.101`) mit Ansible und Git installiert (siehe `ansible_multi_device_management_guide.md`, ).
- Grundkenntnisse in Linux, SSH, Git, YAML und Ansible.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`) auf der Ubuntu-VM für Gitea-Zugriff.
- Optional: Checkmk Raw Edition (Site `homelab`) für Monitoring (siehe `elk_checkmk_integration_guide.md`, ).
- DNS-Eintrag für Gitea (`gitea.homelab.local` auf `192.168.30.104`).

**Ziele**:
- Einrichten eines Gitea-Repositorys und Konfiguration des Benutzerzugriffs über SSH.
- Einchecken (push) und Auschecken (clone/pull) von Code mit Git.
- Automatisierte Sicherung der Gitea-Repository-Daten auf TrueNAS mit Begrenzung auf fünf Backups.

**Hinweis**: Dieses Projekt verwendet SSH für den Git-Zugriff, da es sicherer ist als HTTP für lokale HomeLab-Umgebungen. HTTPS kann optional konfiguriert werden, erfordert jedoch ein gültiges SSL-Zertifikat.

**Quellen**:
- Gitea-Dokumentation: https://docs.gitea.com
- Git-Dokumentation: https://git-scm.com/doc
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,,,,

## Lernprojekt: Ein- und Auschecken von Code in Gitea

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
     - Öffne im Browser: `https://192.168.30.104` (Admin: `admin`, Passwort: `securepassword123`, siehe `gitea_turnkey_lxc_installation_guide.md`).
2. **Ansible- und Git-Umgebung prüfen**:
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
3. **Projektverzeichnis erstellen**:
   - Auf `192.168.30.101`:
     ```bash
     mkdir ~/gitea-code
     cd ~/gitea-code
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Gitea (`192.168.30.104`), OPNsense (`192.168.30.1`) und TrueNAS (`192.168.30.100`). Halte dein SSH-Schlüsselpaar bereit.

### Übung 1: Einrichten eines Gitea-Repositorys und Benutzerzugriffs

**Ziel**: Erstelle ein Gitea-Repository und konfiguriere SSH-Zugriff für Benutzer.

**Aufgabe**: Erstelle ein Repository und füge einen Benutzer mit SSH-Schlüssel hinzu, automatisiert mit Ansible.

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

2. **Ansible-Playbook für Repository und Benutzer**:
   - Erstelle ein Playbook:
     ```bash
     nano setup_gitea_repo.yml
     ```
     - Inhalt:
       ```yaml
       - name: Setup Gitea repository and user
         hosts: gitea_servers
         become: yes
         vars:
           gitea_user: "testuser"
           gitea_email: "testuser@homelab.local"
           gitea_password: "securepassword123"
           ssh_key: "{{ lookup('file', '~/.ssh/id_rsa.pub') }}"
           repo_name: "test-repo"
         tasks:
           - name: Install curl for API calls
             ansible.builtin.apt:
               name: curl
               state: present
               update_cache: yes
           - name: Create Gitea user via API
             ansible.builtin.uri:
               url: "https://gitea.homelab.local/api/v1/admin/users"
               method: POST
               user: admin
               password: "{{ gitea_password }}"
               headers:
                 Content-Type: application/json
               body_format: json
               body:
                 username: "{{ gitea_user }}"
                 email: "{{ gitea_email }}"
                 password: "{{ gitea_password }}"
                 must_change_password: false
               status_code: 201
               validate_certs: no
           - name: Add SSH key for user
             ansible.builtin.uri:
               url: "https://gitea.homelab.local/api/v1/users/{{ gitea_user }}/keys"
               method: POST
               user: admin
               password: "{{ gitea_password }}"
               headers:
                 Content-Type: application/json
               body_format: json
               body:
                 title: "ansible-generated-key"
                 key: "{{ ssh_key }}"
               status_code: 201
               validate_certs: no
           - name: Create repository
             ansible.builtin.uri:
               url: "https://gitea.homelab.local/api/v1/user/repos"
               method: POST
               user: "{{ gitea_user }}"
               password: "{{ gitea_password }}"
               headers:
                 Content-Type: application/json
               body_format: json
               body:
                 name: "{{ repo_name }}"
                 private: false
               status_code: 201
               validate_certs: no
           - name: Display repository details
             ansible.builtin.debug:
               msg: "Repository {{ repo_name }} created for {{ gitea_user }}"
       ```
   - **Erklärung**:
     - Installiert `curl` für API-Aufrufe.
     - Erstellt einen Benutzer (`testuser`) über die Gitea-API.
     - Fügt den öffentlichen SSH-Schlüssel hinzu.
     - Erstellt ein öffentliches Repository (`test-repo`).

3. **Playbook ausführen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml setup_gitea_repo.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display repository details] ***********************************************
       ok: [gitea] => {
           "msg": "Repository test-repo created for testuser"
       }
       ```
   - Prüfe in der Gitea-Weboberfläche:
     - Öffne `https://192.168.30.104`.
     - Melde dich als `testuser` an (Passwort: `securepassword123`).
     - Erwartete Ausgabe: Repository `test-repo` ist sichtbar.

**Erkenntnis**: Ansible automatisiert die Erstellung von Benutzern und Repositorys in Gitea, wodurch der Verwaltungsaufwand reduziert wird.

**Quelle**: https://docs.gitea.com/next/administration/api-usage

### Übung 2: Einchecken und Auschecken von Code mit Git

**Ziel**: Checke Code in das Gitea-Repository ein (push) und checke ihn aus (clone/pull).

**Aufgabe**: Erstelle ein Beispielprojekt, checke es ein, klone es und aktualisiere es.

1. **SSH-Zugriff konfigurieren**:
   - Auf der Ubuntu-VM (`192.168.30.101`):
     - Stelle sicher, dass der SSH-Schlüssel vorhanden ist:
       ```bash
       ls ~/.ssh/id_rsa.pub
       ```
     - Prüfe SSH-Zugriff auf Gitea:
       ```bash
       ssh -T git@gitea.homelab.local
       ```
       - Erwartete Ausgabe: `Hi testuser! You've successfully authenticated...`.

2. **Code einchecken (Push)**:
   - Erstelle ein Beispielprojekt:
     ```bash
     mkdir ~/test-project
     cd ~/test-project
     echo "# Test Project" > README.md
     git init
     git add README.md
     git commit -m "Initial commit"
     ```
   - Füge das Gitea-Repository hinzu:
     ```bash
     git remote add origin git@gitea.homelab.local:testuser/test-repo.git
     git push -u origin main
     ```
     - Erwartete Ausgabe:
       ```
       Enumerating objects: 3, done.
       ...
       To gitea.homelab.local:testuser/test-repo.git
        * [new branch]      main -> main
       ```
   - Prüfe in der Gitea-Weboberfläche (`https://192.168.30.104`):
     - Repository `testuser/test-repo` enthält `README.md`.

3. **Code auschecken (Clone/Pull)**:
   - Klonen des Repositorys auf eine andere Maschine (z. B. lokal auf `192.168.30.101`):
     ```bash
     cd ~
     git clone git@gitea.homelab.local:testuser/test-repo.git test-repo-cloned
     cd test-repo-cloned
     ls
     ```
     - Erwartete Ausgabe: `README.md`.
   - Ändere die Datei und aktualisiere:
     ```bash
     echo "Updated content" >> README.md
     git add README.md
     git commit -m "Update README"
     git push origin main
     ```
   - Ziehe Änderungen in das ursprüngliche Projekt:
     ```bash
     cd ~/test-project
     git pull origin main
     cat README.md
     ```
     - Erwartete Ausgabe:
       ```
       # Test Project
       Updated content
       ```

**Erkenntnis**: Gitea ermöglicht einfaches Ein- und Auschecken von Code über SSH, ähnlich wie GitHub, aber lokal kontrolliert.

**Quelle**: https://git-scm.com/docs/git-push

### Übung 3: Backup der Gitea-Repository-Daten auf TrueNAS

**Ziel**: Sichere die Gitea-Repository-Daten und versioniere sie auf TrueNAS.

**Aufgabe**: Erstelle ein Ansible-Playbook für Backups und begrenze sie auf maximal fünf Versionen.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_gitea_repos.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup Gitea repositories and configuration
         hosts: gitea_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/gitea-code/backups/gitea"
           backup_file: "{{ backup_dir }}/gitea-repos-backup-{{ ansible_date_time.date }}.tar.gz"
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
               tar -czf /tmp/gitea-repos-backup-{{ ansible_date_time.date }}.tar.gz /home/git/gitea /var/lib/mysql
             register: backup_result
           - name: Start Gitea service
             ansible.builtin.service:
               name: gitea
               state: started
           - name: Fetch backup file
             ansible.builtin.fetch:
               src: /tmp/gitea-repos-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ backup_file }}"
               flat: yes
           - name: Limit backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t gitea-repos-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/gitea-code/
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
     ansible-playbook -i inventory.yml backup_gitea_repos.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display backup status] ****************************************************
       ok: [gitea] => {
           "msg": "Backup saved to /home/ubuntu/gitea-code/backups/gitea/gitea-repos-backup-<date>.tar.gz and synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/gitea-code/
     ```
     - Erwartete Ausgabe: Maximal fünf `gitea-repos-backup-<date>.tar.gz`.

3. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/gitea-code
       ansible-playbook -i inventory.yml backup_gitea_repos.yml >> backup.log 2>&1
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
       0 3 * * * /home/ubuntu/gitea-code/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible automatisiert die Sicherung von Gitea-Repositorys, während TrueNAS externe Speicherung bietet.

**Quelle**: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/fetch_module.html

## Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass die Firewall-Regeln aus `gitea_turnkey_lxc_installation_guide.md` aktiv sind (Ports 80, 443).
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
     - Erstelle eine benutzerdefinierte Überprüfung für Repositorys:
       ```bash
       nano /omd/sites/homelab/local/share/check_mk/checks/gitea_repos
       ```
       - Inhalt:
         ```bash
         #!/bin/bash
         COUNT=$(ssh root@192.168.30.104 "ls -1 /home/git/gitea-repos | wc -l")
         if [ $COUNT -gt 0 ]; then
           echo "0 Gitea_Repos - $COUNT repositories found"
         else
           echo "1 Gitea_Repos - No repositories found"
         fi
         ```
       - Ausführbar machen:
         ```bash
         chmod +x /omd/sites/homelab/local/share/check_mk/checks/gitea_repos
         ```
       - In Checkmk: `Setup > Services > Manual checks > Custom checks`, füge `Gitea_Repos` hinzu.

## Schritt 5: Erweiterung der Übungen
1. **Erweiterter Git-Zugriff**:
   - Konfiguriere HTTPS-Zugriff für Gitea:
     ```bash
     nano configure_gitea_https.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure Gitea for HTTPS access
         hosts: gitea_servers
         become: yes
         tasks:
           - name: Update Gitea configuration for HTTPS
             ansible.builtin.lineinfile:
               path: /home/git/gitea/custom/conf/app.ini
               regexp: "^ROOT_URL ="
               line: "ROOT_URL = https://gitea.homelab.local/"
               insertafter: "[server]"
           - name: Restart Gitea
             ansible.builtin.service:
               name: gitea
               state: restarted
       ```

2. **Automatisierte Repository-Verwaltung**:
   - Erstelle ein Playbook zum Löschen alter Repositorys:
     ```bash
     nano clean_old_repos.yml
     ```
     - Inhalt:
       ```yaml
       - name: Clean old Gitea repositories
         hosts: gitea_servers
         become: yes
         vars:
           gitea_user: "admin"
           gitea_password: "securepassword123"
         tasks:
           - name: Delete inactive repositories
             ansible.builtin.uri:
               url: "https://gitea.homelab.local/api/v1/repos/{{ gitea_user }}/old-repo"
               method: DELETE
               user: "{{ gitea_user }}"
               password: "{{ gitea_password }}"
               status_code: 204
               validate_certs: no
       ```

## Best Practices für Schüler

- **Gitea-Design**:
  - Verwende SSH für sicheren Git-Zugriff.
  - Automatisiere Benutzer- und Repository-Verwaltung mit Ansible.
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
    cat ~/gitea-code/backup.log
    ```

**Quelle**: https://docs.gitea.com, https://git-scm.com/doc, https://docs.ansible.com

## Empfehlungen für Schüler

- **Setup**: Gitea, Ansible, Git, TrueNAS-Backups.
- **Workloads**: Repository-Verwaltung, Code ein-/auschecken, Backups.
- **Integration**: Proxmox (LXC), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Ein-/Auschecken eines Testprojekts in Gitea.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einem einfachen Repository, erweitere zu mehreren Benutzern.
- **Übung**: Experimentiere mit Gitea Actions oder Team-Berechtigungen.
- **Fehlerbehebung**: Nutze `git log` und `ansible-playbook --check`.
- **Lernressourcen**: https://docs.gitea.com, https://git-scm.com/doc, https://docs.opnsense.org.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Ein- und Auschecken von Code in Gitea mit Git.
- **Skalierbarkeit**: Automatisierte Repository-Verwaltung und Backups.
- **Lernwert**: Verständnis von Git-Workflows und HomeLab-Integration.

**Nächste Schritte**: Möchtest du eine Anleitung zu Integration mit Wazuh für Sicherheitsüberwachung, Log-Aggregation mit Fluentd, oder erweitertem Monitoring mit Checkmk?

**Quellen**:
- Gitea-Dokumentation: https://docs.gitea.com
- Git-Dokumentation: https://git-scm.com/doc
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,,,,
```