# Lernprojekt: Einrichten eines Gmail-Relay-Servers mit iRedMail in einer HomeLab-Umgebung

## Einführung

Ein **Gmail-Relay-Server** ermöglicht es, E-Mails über Googles SMTP-Server zu versenden, was die Zustellbarkeit verbessert und die Notwendigkeit einer eigenen öffentlichen Mail-Infrastruktur reduziert. Dieses Lernprojekt zeigt, wie man einen iRedMail-Mailserver in einer HomeLab-Umgebung so konfiguriert, dass er Gmail als Relay-Server verwendet. Es baut auf `iredmail_installation_guide.md` () auf und nutzt die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense). Das Projekt ist für Lernende mit Grundkenntnissen in Linux, Ansible, Postfix und Netzwerkadministration geeignet und ist lokal, kostenlos (abgesehen von einem Google-Konto) und datenschutzfreundlich. Es umfasst drei Übungen: Konfiguration von Postfix für Gmail-Relay, Automatisierung mit Ansible, und Backup der Konfiguration auf TrueNAS.

**Voraussetzungen**:
- Ubuntu-VM mit iRedMail installiert (IP `192.168.30.103`, Hostname `mailserver.homelab.local`, siehe `iredmail_installation_guide.md`).
- OPNsense-Router (IP `192.168.30.1`) mit SSH-Zugriff und DNS-Resolver.
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups.
- Ubuntu-VM (IP `192.168.30.101`) mit Ansible installiert (siehe `ansible_multi_device_management_guide.md`, ).
- Google-Konto mit aktiviertem App-Passwort (für SMTP-Relay, siehe https://myaccount.google.com/security).
- Grundkenntnisse in Linux, SSH, YAML, Ansible und Postfix-Konfiguration.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`) für die Mailserver-VM und OPNsense.
- Optional: Checkmk Raw Edition (Site `homelab`) für Monitoring (siehe `elk_checkmk_integration_guide.md`, ).

**Ziele**:
- Konfiguration von Postfix auf dem iRedMail-Server für Gmail als SMTP-Relay.
- Automatisierte Anpassung der Postfix-Konfiguration und Firewall-Regeln mit Ansible.
- Backup der Konfiguration auf TrueNAS mit Begrenzung auf fünf Versionen.

**Hinweis**: Ein App-Passwort ist erforderlich, da Google die Zwei-Faktor-Authentifizierung (2FA) für SMTP empfiehlt. Erstelle ein App-Passwort unter https://myaccount.google.com/security > "2-Step Verification" > "App passwords".

**Quellen**:
- iRedMail-Dokumentation: https://docs.iredmail.org
- Postfix-Dokumentation: http://www.postfix.org/documentation.html
- Google SMTP-Dokumentation: https://support.google.com/mail/answer/7126229
- Ansible-Dokumentation: https://docs.ansible.com
- Webquellen:,,,,,

## Lernprojekt: Einrichten eines Gmail-Relay-Servers

### Vorbereitung: Umgebung prüfen
1. **iRedMail-Server prüfen**:
   - Verbinde dich mit der Mailserver-VM:
     ```bash
     ssh ubuntu@192.168.30.103
     ```
   - Stelle sicher, dass iRedMail installiert ist:
     ```bash
     cat /etc/iredmail-release
     ```
     - Erwartete Ausgabe: `iRedMail-1.7.0` (oder ähnlich).
   - Prüfe Postfix:
     ```bash
     sudo systemctl status postfix
     ```
     - Erwartete Ausgabe: `active (running)`.
2. **Google App-Passwort erstellen**:
   - Gehe zu https://myaccount.google.com/security.
   - Aktiviere 2FA (falls nicht aktiviert).
   - Erstelle ein App-Passwort:
     - Gehe zu "App passwords" > "Select app: Mail" > "Select device: Other (Custom name)" > Name: `iRedMail`.
     - Notiere das generierte Passwort (z. B. `abcd-efgh-ijkl-mnop`).
3. **Ansible-Umgebung prüfen**:
   - Auf der Ubuntu-VM (`192.168.30.101`):
     ```bash
     ssh ubuntu@192.168.30.101
     ansible --version
     ```
   - Stelle sicher, dass SSH-Zugriff auf OPNsense und die Mailserver-VM möglich ist:
     ```bash
     ssh root@192.168.30.1
     ssh ubuntu@192.168.30.103
     ```
4. **Projektverzeichnis erstellen**:
   - Auf `192.168.30.101`:
     ```bash
     mkdir ~/gmail-relay
     cd ~/gmail-relay
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf OPNsense (`192.168.30.1`), die Mailserver-VM (`192.168.30.103`) und TrueNAS (`192.168.30.100`). Halte das Google App-Passwort bereit.

### Übung 1: Konfiguration von Postfix für Gmail-Relay

**Ziel**: Konfiguriere Postfix auf dem iRedMail-Server, um Gmail als SMTP-Relay zu verwenden.

**Aufgabe**: Erstelle ein Ansible-Playbook, um Postfix für den Gmail-Relay zu konfigurieren.

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
           network_devices:
             hosts:
               opnsense:
                 ansible_host: 192.168.30.1
                 ansible_user: root
                 ansible_connection: ssh
                 ansible_network_os: freebsd
       ```

2. **Ansible-Playbook für Postfix-Konfiguration**:
   - Erstelle ein Playbook:
     ```bash
     nano configure_gmail_relay.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure Postfix for Gmail relay
         hosts: mail_servers
         become: yes
         vars:
           gmail_user: "your.email@gmail.com"
           gmail_app_password: "abcd-efgh-ijkl-mnop"
         tasks:
           - name: Install sasl2-bin for authentication
             ansible.builtin.apt:
               name: libsasl2-modules
               state: present
               update_cache: yes
           - name: Configure Postfix main.cf
             ansible.builtin.lineinfile:
               path: /etc/postfix/main.cf
               regexp: "{{ item.regexp }}"
               line: "{{ item.line }}"
               state: present
             loop:
               - regexp: "^relayhost ="
                 line: "relayhost = [smtp.gmail.com]:587"
               - regexp: "^smtp_sasl_auth_enable ="
                 line: "smtp_sasl_auth_enable = yes"
               - regexp: "^smtp_sasl_password_maps ="
                 line: "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"
               - regexp: "^smtp_sasl_security_options ="
                 line: "smtp_sasl_security_options = noanonymous"
               - regexp: "^smtp_tls_security_level ="
                 line: "smtp_tls_security_level = may"
               - regexp: "^smtp_tls_CAfile ="
                 line: "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt"
           - name: Create sasl_passwd file
             ansible.builtin.copy:
               content: "[smtp.gmail.com]:587 {{ gmail_user }}:{{ gmail_app_password }}"
               dest: /etc/postfix/sasl_passwd
               mode: '0600'
             no_log: true
           - name: Generate sasl_passwd.db
             ansible.builtin.command: postmap /etc/postfix/sasl_passwd
             args:
               creates: /etc/postfix/sasl_passwd.db
           - name: Restart Postfix
             ansible.builtin.service:
               name: postfix
               state: restarted
           - name: Test email sending
             ansible.builtin.command: >
               echo "Test email from iRedMail" | mail -s "Test Gmail Relay" test@homelab.local
             register: mail_test
           - name: Display test email status
             ansible.builtin.debug:
               msg: "{{ mail_test.stdout }}"
       ```
   - **Erklärung**:
     - Installiert `libsasl2-modules` für SASL-Authentifizierung.
     - Konfiguriert Postfix für Gmail-Relay (`smtp.gmail.com:587`) mit TLS und SASL.
     - Erstellt `/etc/postfix/sasl_passwd` mit dem Google App-Passwort.
     - Generiert `sasl_passwd.db` mit `postmap`.
     - Testet den Relay durch Senden einer E-Mail.

3. **Playbook ausführen**:
   - Ersetze `your.email@gmail.com` und `abcd-efgh-ijkl-mnop` im Playbook mit deinem Gmail-Konto und App-Passwort.
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml configure_gmail_relay.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display test email status] ************************************************
       ok: [mailserver] => {
           "msg": ""
       }
       ```
   - Prüfe, ob die Test-E-Mail bei `test@homelab.local` ankommt:
     - Melde dich an der Roundcube-Weboberfläche an (`https://192.168.30.103`).
     - Überprüfe den Posteingang von `test@homelab.local`.

**Erkenntnis**: Ansible automatisiert die Postfix-Konfiguration für den Gmail-Relay, wodurch die E-Mail-Zustellung vereinfacht wird.

**Quelle**: https://support.google.com/mail/answer/7126229

### Übung 2: Firewall-Regeln für ausgehenden SMTP-Verkehr

**Ziel**: Konfiguriere OPNsense-Firewall-Regeln, um ausgehenden SMTP-Verkehr zu Gmail zu erlauben.

**Aufgabe**: Erstelle ein Ansible-Playbook, um die Firewall-Regeln zu aktualisieren.

1. **Ansible-Playbook für Firewall-Regeln**:
   - Erstelle ein Playbook:
     ```bash
     nano configure_firewall_gmail.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure OPNsense firewall for Gmail relay
         hosts: network_devices
         tasks:
           - name: Add firewall rule for outgoing SMTP to Gmail
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"out",
                 "protocol":"tcp",
                 "source":"192.168.30.103",
                 "destination_net":"any",
                 "destination_port":"587",
                 "description":"Allow SMTP to Gmail"
               }'
             register: smtp_result
           - name: Verify firewall rules
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Display firewall rules
             ansible.builtin.debug:
               msg: "{{ rules_list.stdout }}"
       ```
   - **Erklärung**:
     - Fügt eine Regel hinzu, die ausgehenden TCP/587-Verkehr von `192.168.30.103` erlaubt.
     - Prüft die aktiven Firewall-Regeln.

2. **Playbook ausführen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml configure_firewall_gmail.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display firewall rules] ****************************************************
       ok: [opnsense] => {
           "msg": "... Allow SMTP to Gmail ..."
       }
       ```
   - Prüfe in der OPNsense-Weboberfläche:
     - Gehe zu `Firewall > Rules > LAN`.
     - Erwartete Regel: `pass`, Quelle `192.168.30.103`, Ziel `any:587`.

**Erkenntnis**: Ansible ermöglicht die präzise Konfiguration von Firewall-Regeln für spezifische Dienste wie SMTP-Relay.

**Quelle**: https://docs.opnsense.org/manual/firewall.html

### Übung 3: Backup der Konfiguration auf TrueNAS

**Ziel**: Sichere die Postfix-Konfiguration und versioniere sie auf TrueNAS mit Begrenzung auf fünf Backups.

**Aufgabe**: Erstelle ein Ansible-Playbook für Backups und automatisiere es mit Cron.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_gmail_relay.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup iRedMail Gmail relay configuration
         hosts: mail_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/gmail-relay/backups/mailserver"
           backup_file: "{{ backup_dir }}/gmail-relay-backup-{{ ansible_date_time.date }}.tar.gz"
         tasks:
           - name: Create backup directory
             ansible.builtin.file:
               path: "{{ backup_dir }}"
               state: directory
               mode: '0755'
             delegate_to: localhost
           - name: Backup Postfix configuration
             ansible.builtin.command: >
               tar -czf /tmp/gmail-relay-backup-{{ ansible_date_time.date }}.tar.gz /etc/postfix
             register: backup_result
           - name: Fetch backup file
             ansible.builtin.fetch:
               src: /tmp/gmail-relay-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ backup_file }}"
               flat: yes
           - name: Limit backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t gmail-relay-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/gmail-relay/
             delegate_to: localhost
           - name: Display backup status
             ansible.builtin.debug:
               msg: "Backup saved to {{ backup_file }} and synced to TrueNAS"
       ```
   - **Erklärung**:
     - Sichert `/etc/postfix` als `.tar.gz`.
     - Begrenzt Backups auf fünf durch Entfernen älterer Dateien.
     - Synchronisiert Backups mit TrueNAS.

2. **Playbook testen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_gmail_relay.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display backup status] ****************************************************
       ok: [mailserver] => {
           "msg": "Backup saved to /home/ubuntu/gmail-relay/backups/mailserver/gmail-relay-backup-<date>.tar.gz and synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/gmail-relay/
     ```
     - Erwartete Ausgabe: Maximal fünf `gmail-relay-backup-<date>.tar.gz`.

3. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/gmail-relay
       ansible-playbook -i inventory.yml backup_gmail_relay.yml >> backup.log 2>&1
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
       0 3 * * * /home/ubuntu/gmail-relay/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible automatisiert Backups der Gmail-Relay-Konfiguration, während TrueNAS für externe Speicherung sorgt.

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
     - Stelle sicher, dass `mailserver` (IP `192.168.30.103`) als Host hinzugefügt ist.
     - Prüfe Services:
       - Gehe zu `Monitor > All services`.
       - Erwartete Ausgabe: Services wie `Postfix`, `SMTP`.
     - Erstelle eine benutzerdefinierte Überprüfung für SMTP:
       ```bash
       nano /omd/sites/homelab/local/share/check_mk/checks/smtp_relay
       ```
       - Inhalt:
         ```bash
         #!/bin/bash
         nc -zv smtp.gmail.com 587
         if [ $? -eq 0 ]; then
           echo "0 SMTP_Relay - Connection to smtp.gmail.com:587 successful"
         else
           echo "2 SMTP_Relay - Connection to smtp.gmail.com:587 failed"
         fi
         ```
       - Ausführbar machen:
         ```bash
         chmod +x /omd/sites/homelab/local/share/check_mk/checks/smtp_relay
         ```
       - In Checkmk: `Setup > Services > Manual checks > Custom checks`, füge `SMTP_Relay` hinzu.

### Schritt 5: Erweiterung der Übungen
1. **Erweiterte Postfix-Konfiguration**:
   - Erstelle ein Playbook für zusätzliche Relay-Einschränkungen:
     ```bash
     nano restrict_relay.yml
     ```
     - Inhalt:
       ```yaml
       - name: Restrict Gmail relay to specific domains
         hosts: mail_servers
         become: yes
         tasks:
           - name: Add sender restrictions
             ansible.builtin.lineinfile:
               path: /etc/postfix/main.cf
               line: "smtpd_sender_restrictions = permit_mynetworks, reject"
               state: present
           - name: Restart Postfix
             ansible.builtin.service:
               name: postfix
               state: restarted
       ```

2. **Backup-Versionierung mit Git**:
   - Initialisiere ein Git-Repository für Backups:
     ```bash
     cd ~/gmail-relay/backups/mailserver
     git init
     git add .
     git commit -m "Initial Gmail relay backup"
     ```

## Best Practices für Schüler

- **Relay-Design**:
  - Verwende App-Passwörter für sichere Authentifizierung.
  - Teste E-Mail-Versand vor der Produktion.
- **Sicherheit**:
  - Schränke ausgehenden SMTP-Zugriff ein:
    ```bash
    sudo ufw allow from 192.168.30.103 to any port 587
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe Postfix-Logs:
    ```bash
    ssh ubuntu@192.168.30.103 "tail -f /var/log/mail.log"
    ```
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/gmail-relay/backup.log
    ```

**Quelle**: https://docs.iredmail.org, http://www.postfix.org/documentation.html, https://docs.ansible.com

## Empfehlungen für Schüler

- **Setup**: iRedMail, Postfix, Gmail-Relay, TrueNAS-Backups.
- **Workloads**: Gmail-Relay-Konfiguration, Firewall-Regeln, Backups.
- **Integration**: Proxmox (VM), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: SMTP-Relay über Gmail mit Postfix.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einer grundlegenden Relay-Konfiguration, erweitere zu Einschränkungen oder Monitoring.
- **Übung**: Experimentiere mit SPF/DKIM für verbesserte Zustellbarkeit.
- **Fehlerbehebung**: Nutze `ansible-playbook --check` und `/var/log/mail.log`.
- **Lernressourcen**: https://docs.iredmail.org, https://support.google.com/mail/answer/7126229, https://docs.ansible.com.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Einrichtung eines Gmail-Relay-Servers mit iRedMail.
- **Skalierbarkeit**: Automatisierte Konfiguration und Backup.
- **Lernwert**: Verständnis von SMTP-Relay und Postfix-Konfiguration.

**Nächste Schritte**: Möchtest du eine Anleitung zu Integration mit Wazuh für Sicherheitsüberwachung, Log-Aggregation mit Fluentd, oder erweitertem Monitoring mit Checkmk?

**Quellen**:
- iRedMail-Dokumentation: https://docs.iredmail.org
- Postfix-Dokumentation: http://www.postfix.org/documentation.html
- Google SMTP-Dokumentation: https://support.google.com/mail/answer/7126229
- Ansible-Dokumentation: https://docs.ansible.com
- Webquellen:,,,,,
```