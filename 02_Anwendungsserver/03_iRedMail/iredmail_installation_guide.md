# Lernprojekt: Installation von iRedMail auf einer neuen VM in einer HomeLab-Umgebung

## Einführung

**iRedMail** ist eine Open-Source-Mailserver-Lösung, die einen voll funktionsfähigen E-Mail-Server mit Postfix, Dovecot, Amavisd, ClamAV, SpamAssassin und einer Weboberfläche (Roundcube oder SOGo) bereitstellt. Dieses Lernprojekt zeigt, wie man iRedMail auf einer neuen Ubuntu-VM in einer HomeLab-Umgebung installiert, konfiguriert und in die bestehende Infrastruktur integriert. Es nutzt die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense) und baut auf Konzepten aus früheren Anleitungen auf (z. B. `ansible_multi_device_management_guide.md`, ). Das Projekt ist für Lernende mit Grundkenntnissen in Linux, Netzwerkadministration und Ansible geeignet und ist lokal, kostenlos und datenschutzfreundlich. Es umfasst drei Übungen: Einrichten der VM und Installation von iRedMail, Konfiguration von Firewall-Regeln mit Ansible, und Backup der Konfiguration auf TrueNAS.

**Voraussetzungen**:
- Proxmox VE mit einer neuen Ubuntu 22.04 VM (IP `192.168.30.103`, Hostname `mailserver`).
- OPNsense-Router (IP `192.168.30.1`) mit SSH-Zugriff aktiviert.
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups.
- Ubuntu-VM (IP `192.168.30.101`) mit Ansible installiert (siehe `ansible_multi_device_management_guide.md`).
- Grundkenntnisse in Linux, SSH, DNS, Ansible und Netzwerkkonfiguration.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`) für die neue VM und OPNsense.
- Optional: Checkmk Raw Edition (Site `homelab`) für Monitoring (siehe `elk_checkmk_integration_guide.md`, ).
- Ein DNS-Eintrag für den Mailserver (z. B. `mail.homelab.local` auf `192.168.30.103`).

**Ziele**:
- Installation und Konfiguration von iRedMail auf einer neuen Ubuntu-VM.
- Automatisierte Konfiguration von Firewall-Regeln für Mail-Dienste mit Ansible.
- Backup der iRedMail-Konfiguration auf TrueNAS.
- Optional: Monitoring mit Checkmk.

**Hinweis**: iRedMail erfordert einen voll qualifizierten Domänennamen (FQDN) und einen DNS-Eintrag. Dieses Projekt verwendet eine lokale Domäne (`homelab.local`) mit OPNsense als DNS-Server.

**Quellen**:
- iRedMail-Dokumentation: https://docs.iredmail.org
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,,,,

## Lernprojekt: iRedMail-Installation

### Vorbereitung: Umgebung einrichten
1. **Neue Ubuntu-VM erstellen**:
   - In Proxmox: Erstelle eine neue VM mit Ubuntu 22.04.
     - IP: `192.168.30.103`
     - Hostname: `mailserver`
     - Mindestens 2 GB RAM, 20 GB Speicher, 2 CPU-Kerne.
   - Installiere SSH:
     ```bash
     ssh ubuntu@192.168.30.103
     sudo apt update
     sudo apt install -y openssh-server
     sudo systemctl enable ssh
     ```
   - Füge den SSH-Schlüssel hinzu:
     ```bash
     ssh-copy-id ubuntu@192.168.30.103
     ```
   - Setze den Hostnamen:
     ```bash
     sudo hostnamectl set-hostname mailserver.homelab.local
     sudo nano /etc/hosts
     ```
     - Füge hinzu:
       ```
       192.168.30.103 mailserver.homelab.local mailserver
       ```
2. **DNS in OPNsense konfigurieren**:
   - Öffne die OPNsense-Weboberfläche: `http://192.168.30.1`.
   - Gehe zu `Services > Unbound DNS > General`.
   - Aktiviere DNS-Resolver und füge einen Host-Eintrag hinzu:
     - Host: `mailserver`
     - Domäne: `homelab.local`
     - IP: `192.168.30.103`
     - Beschreibung: `iRedMail Server`
   - Teste den DNS-Eintrag:
     ```bash
     nslookup mailserver.homelab.local 192.168.30.1
     ```
     - Erwartete Ausgabe: `192.168.30.103`.
3. **Ansible-Umgebung prüfen**:
   - Auf der Ubuntu-VM (`192.168.30.101`):
     ```bash
     ssh ubuntu@192.168.30.101
     ansible --version
     ```
   - Stelle sicher, dass SSH-Zugriff auf OPNsense und die neue VM möglich ist:
     ```bash
     ssh root@192.168.30.1
     ssh ubuntu@192.168.30.103
     ```
4. **Projektverzeichnis erstellen**:
   - Auf `192.168.30.101`:
     ```bash
     mkdir ~/iredmail-install
     cd ~/iredmail-install
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf OPNsense (`192.168.30.1`), die neue Mailserver-VM (`192.168.30.103`) und TrueNAS (`192.168.30.100`).

### Übung 1: Installation von iRedMail auf der neuen VM

**Ziel**: Installiere und konfiguriere iRedMail auf der Ubuntu-VM (`192.168.30.103`).

**Aufgabe**: Automatisiere die Installation von iRedMail mit Ansible.

1. **Ansible-Inventar erstellen**:
   - Erstelle eine Inventar-Datei:
     ```bash
     nano inventory.yml
     ```
     - Inhalt:
       ```yaml
       all:
         children:
           mail_servers:
             hosts:
               mailserver:
                 ansible_host: 192.168.30.103
                 ansible_user: ubuntu
                 ansible_connection: ssh
                 ansible_python_interpreter: /usr/bin/python3
       ```

2. **Ansible-Playbook für iRedMail-Installation**:
   - Erstelle ein Playbook:
     ```bash
     nano install_iredmail.yml
     ```
     - Inhalt:
       ```yaml
       - name: Install iRedMail on mailserver
         hosts: mail_servers
         become: yes
         vars:
           iredmail_version: "1.7.0"
           iredmail_tar: "iRedMail-{{ iredmail_version }}.tar.gz"
           iredmail_url: "https://github.com/iredmail/iRedMail/archive/{{ iredmail_version }}.tar.gz"
         tasks:
           - name: Install required packages
             ansible.builtin.apt:
               name: "{{ packages }}"
               state: present
               update_cache: yes
             vars:
               packages:
                 - wget
                 - tar
                 - bzip2
           - name: Download iRedMail
             ansible.builtin.get_url:
               url: "{{ iredmail_url }}"
               dest: "/tmp/{{ iredmail_tar }}"
               mode: '0644'
           - name: Extract iRedMail
             ansible.builtin.unarchive:
               src: "/tmp/{{ iredmail_tar }}"
               dest: /tmp
               remote_src: yes
           - name: Run iRedMail installer non-interactively
             ansible.builtin.command: >
               bash /tmp/iRedMail-{{ iredmail_version }}/install.sh
               --hostname mailserver.homelab.local
               --domain homelab.local
               --passwordfile /tmp/iredmail.passwd
             args:
               creates: /etc/iredmail-release
             environment:
               AUTO_USE_DEFAULT_MYSQL_ROOT_PASSWORD: "yes"
               AUTO_CLEANUP_REMOVE_OPENLDAP_DATA: "yes"
               AUTO_INSTALL_WITHOUT_CONFIRM: "yes"
           - name: Create password file
             ansible.builtin.copy:
               content: "admin@homelab.local:securepassword123\n"
               dest: /tmp/iredmail.passwd
               mode: '0600'
             no_log: true
           - name: Verify iRedMail installation
             ansible.builtin.command: cat /etc/iredmail-release
             register: iredmail_version
           - name: Display iRedMail version
             ansible.builtin.debug:
               msg: "{{ iredmail_version.stdout }}"
       ```
   - **Erklärung**:
     - Installiert Abhängigkeiten (`wget`, `tar`, `bzip2`).
     - Lädt iRedMail herunter und entpackt es.
     - Führt die Installation nicht-interaktiv aus mit vorgegebenem Hostnamen und Domäne.
     - Erstellt eine Passwortdatei für den Admin-Benutzer.
     - Prüft die Installation anhand von `/etc/iredmail-release`.

3. **Playbook ausführen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml install_iredmail.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display iRedMail version] ************************************************
       ok: [mailserver] => {
           "msg": "iRedMail-1.7.0"
       }
       ```
   - Prüfe die Weboberfläche:
     ```bash
     curl https://mailserver.homelab.local
     ```
     - Erwartete Ausgabe: HTML der Roundcube/SOGo-Weboberfläche.
     - Öffne im Browser: `https://192.168.30.103` (Standard-Benutzer: `admin@homelab.local`, Passwort: `securepassword123`).

**Erkenntnis**: Ansible automatisiert die iRedMail-Installation, wodurch die Einrichtung eines Mailservers vereinfacht wird.

**Quelle**: https://docs.iredmail.org/install.iredmail.on.debian.ubuntu.html

### Übung 2: Konfiguration von Firewall-Regeln mit Ansible

**Ziel**: Konfiguriere Firewall-Regeln auf OPNsense, um Mail-Dienste (SMTP, IMAP, HTTPS) zuzulassen.

**Aufgabe**: Erstelle ein Ansible-Playbook, um Firewall-Regeln für iRedMail zu konfigurieren.

1. **Ansible-Inventar erweitern**:
   - Aktualisiere `inventory.yml`:
     ```bash
     nano inventory.yml
     ```
     - Inhalt:
       ```yaml
       all:
         children:
           mail_servers:
             hosts:
               mailserver:
                 ansible_host: 192.168.30.103
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

2. **Ansible-Playbook für Firewall-Regeln**:
   - Erstelle ein Playbook:
     ```bash
     nano configure_firewall.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure OPNsense firewall for iRedMail
         hosts: network_devices
         tasks:
           - name: Add firewall rule for SMTP (25)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.103",
                 "destination_port":"25",
                 "description":"Allow SMTP to iRedMail"
               }'
             register: smtp_result
           - name: Add firewall rule for IMAP (143)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.103",
                 "destination_port":"143",
                 "description":"Allow IMAP to iRedMail"
               }'
             register: imap_result
           - name: Add firewall rule for HTTPS (443)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.103",
                 "destination_port":"443",
                 "description":"Allow HTTPS to iRedMail"
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
     - Fügt Firewall-Regeln für SMTP (25), IMAP (143) und HTTPS (443) hinzu.
     - Erlaubt Verkehr von `192.168.30.0/24` zu `192.168.30.103`.

3. **Playbook ausführen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml configure_firewall.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display firewall rules] ****************************************************
       ok: [opnsense] => {
           "msg": "... Allow SMTP to iRedMail ... Allow IMAP to iRedMail ... Allow HTTPS to iRedMail ..."
       }
       ```
   - Prüfe in der OPNsense-Weboberfläche:
     - Gehe zu `Firewall > Rules > LAN`.
     - Erwartete Regeln: `pass` für `192.168.30.103:25`, `192.168.30.103:143`, `192.168.30.103:443`.

**Erkenntnis**: Ansible ermöglicht die automatisierte Konfiguration von Firewall-Regeln, um Mail-Dienste sicher zu integrieren.

**Quelle**: https://docs.opnsense.org/manual/firewall.html

### Übung 3: Backup der iRedMail-Konfiguration auf TrueNAS

**Ziel**: Sichere die iRedMail-Konfiguration und versioniere sie auf TrueNAS.

**Aufgabe**: Erstelle ein Ansible-Playbook für Backups und begrenze sie auf maximal fünf Versionen.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_iredmail.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup iRedMail configuration
         hosts: mail_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/iredmail-install/backups/mailserver"
           backup_file: "{{ backup_dir }}/iredmail-backup-{{ ansible_date_time.date }}.tar.gz"
         tasks:
           - name: Create backup directory
             ansible.builtin.file:
               path: "{{ backup_dir }}"
               state: directory
               mode: '0755'
             delegate_to: localhost
           - name: Backup iRedMail configuration
             ansible.builtin.command: >
               tar -czf /tmp/iredmail-backup-{{ ansible_date_time.date }}.tar.gz /etc/iredmail /etc/postfix /etc/dovecot
             register: backup_result
           - name: Fetch backup file
             ansible.builtin.fetch:
               src: /tmp/iredmail-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ backup_file }}"
               flat: yes
           - name: Limit backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t iredmail-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/iredmail-install/
             delegate_to: localhost
           - name: Display backup status
             ansible.builtin.debug:
               msg: "Backup saved to {{ backup_file }} and synced to TrueNAS"
       ```
   - **Erklärung**:
     - Sichert `/etc/iredmail`, `/etc/postfix`, `/etc/dovecot` als `.tar.gz`.
     - Begrenzt Backups auf fünf durch Entfernen älterer Dateien.
     - Synchronisiert Backups mit TrueNAS.

2. **Playbook testen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_iredmail.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display backup status] ****************************************************
       ok: [mailserver] => {
           "msg": "Backup saved to /home/ubuntu/iredmail-install/backups/mailserver/iredmail-backup-<date>.tar.gz and synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/iredmail-install/
     ```
     - Erwartete Ausgabe: Maximal fünf `iredmail-backup-<date>.tar.gz`.

3. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/iredmail-install
       ansible-playbook -i inventory.yml backup_iredmail.yml >> backup.log 2>&1
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
       0 3 * * * /home/ubuntu/iredmail-install/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible automatisiert das Backup von iRedMail-Konfigurationen, während TrueNAS für externe Speicherung sorgt.

**Quelle**: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/fetch_module.html

### Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass die Firewall-Regeln aktiv sind (siehe Übung 2).
   - Prüfe OPNsense-Logs:
     ```bash
     ansible-playbook -i inventory.yml -m ansible.builtin.command -a "cat /var/log/system/latest.log" opnsense
     ```

2. **Monitoring mit Checkmk (optional)**:
   - Konfiguriere Checkmk für den Mailserver:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Füge den Mailserver als Host hinzu:
       - Hostname: `mailserver`, IP: `192.168.30.103`.
       - Speichern und `Discover services`.
     - Prüfe Services:
       - Gehe zu `Monitor > All services`.
       - Erwartete Ausgabe: Services wie `Postfix`, `Dovecot`, `Apache2`.

### Schritt 5: Erweiterung der Übungen
1. **Erweiterte iRedMail-Konfiguration**:
   - Erstelle ein Playbook für zusätzliche Benutzer:
     ```bash
     nano add_mail_user.yml
     ```
     - Inhalt:
       ```yaml
       - name: Add mail user to iRedMail
         hosts: mail_servers
         become: yes
         tasks:
           - name: Add new mail user
             ansible.builtin.command: >
               /usr/bin/vmailadmin --add-user user@homelab.local password123
             register: user_result
           - name: Display user creation status
             ansible.builtin.debug:
               msg: "{{ user_result.stdout }}"
       ```

2. **Backup-Versionierung mit Git**:
   - Initialisiere ein Git-Repository für Backups:
     ```bash
     cd ~/iredmail-install/backups/mailserver
     git init
     git add .
     git commit -m "Initial iRedMail backup"
     ```

## Best Practices für Schüler

- **Mailserver-Design**:
  - Verwende einen dedizierten FQDN und DNS-Eintrag.
  - Automatisiere mit Ansible für reproduzierbare Setups.
- **Sicherheit**:
  - Schränke Zugriff ein:
    ```bash
    sudo ufw allow from 192.168.30.0/24 to any port 22,25,143,443
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe iRedMail-Logs:
    ```bash
    ssh ubuntu@192.168.30.103 "tail -f /var/log/mail.log"
    ```
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/iredmail-install/backup.log
    ```

**Quelle**: https://docs.iredmail.org, https://docs.ansible.com, https://docs.opnsense.org

## Empfehlungen für Schüler

- **Setup**: iRedMail, Ansible, OPNsense, TrueNAS-Backups.
- **Workloads**: Mailserver-Installation, Firewall-Konfiguration, Backups.
- **Integration**: Proxmox (VM), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: iRedMail mit Roundcube und Firewall-Regeln.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einer grundlegenden Installation, erweitere zu Benutzerverwaltung und Monitoring.
- **Übung**: Experimentiere mit SOGo statt Roundcube oder SPF/DKIM-Konfiguration.
- **Fehlerbehebung**: Nutze `ansible-playbook --check` und `/var/log/mail.log`.
- **Lernressourcen**: https://docs.iredmail.org, https://docs.ansible.com, https://docs.opnsense.org.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: iRedMail-Installation mit Ansible.
- **Skalierbarkeit**: Automatisierte Firewall- und Backup-Konfigurationen.
- **Lernwert**: Verständnis von Mailservern und Netzwerkadministration.

**Nächste Schritte**: Möchtest du eine Anleitung zu Integration mit Wazuh für Sicherheitsüberwachung, Log-Aggregation mit Fluentd, oder erweitertem Monitoring mit Checkmk?

**Quellen**:
- iRedMail-Dokumentation: https://docs.iredmail.org
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,,,,
```