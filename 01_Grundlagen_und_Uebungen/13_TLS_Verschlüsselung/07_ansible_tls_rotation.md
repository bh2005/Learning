# Praxisorientierte Anleitung: Integration von Zertifikatrotation in Ansible für Multi-Server-Deployment auf Debian

## Einführung
Ansible ist ein Open-Source-Automatisierungstool, das die Konfiguration und Verwaltung mehrerer Server vereinfacht. Durch die Integration der Zertifikatrotation in Ansible können Sie TLS-Zertifikate auf mehreren Debian-Servern zentral verwalten, Ablaufdaten überwachen, Zertifikate erneuern und Nginx ohne Downtime neu laden. Diese Anleitung zeigt Ihnen, wie Sie die Zertifikatrotation aus der vorherigen Anleitung (mit OpenSSL oder Let's Encrypt) in ein Ansible-Playbook integrieren, um sie auf mehrere Server anzuwenden. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, Zertifikatrotation für Multi-Server-Umgebungen zu automatisieren. Diese Anleitung ist ideal für Administratoren, die skalierbare, sichere Systeme verwalten möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) als Steuerknoten mit Root- oder Sudo-Zugriff
- Mindestens zwei Debian-Server als Zielknoten mit Nginx und OpenSSL installiert
- TLS-Zertifikate verfügbar (z. B. in `~/tls-certs`: `myserver.crt`, `myserver.key`)
- Ansible installiert auf dem Steuerknoten
- SSH-Zugriff mit schlüsselbasierter Authentifizierung zu den Zielservern
- Mindestens 2 GB RAM und ausreichend Festplattenspeicher (mindestens 5 GB frei)
- Grundlegende Kenntnisse der Linux-Kommandozeile, Ansible und Skripting
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie VS Code)

## Grundlegende Konzepte und Befehle für Ansible und Zertifikatrotation
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **Ansible-Konzepte**:
   - **Playbook**: YAML-Datei, die Aufgaben für mehrere Server definiert
   - **Inventory**: Liste der Zielserver
   - **Modules**: Ansible-Bausteine wie `copy`, `script`, `cron` für Aufgaben
   - **Idempotenz**: Ansible stellt sicher, dass Änderungen nur bei Bedarf angewendet werden
2. **Zertifikatrotation-Konzepte**:
   - **Ablaufüberprüfung**: Prüfung der Gültigkeitsdauer mit OpenSSL
   - **Zertifikaterneuerung**: Erstellung neuer Zertifikate mit OpenSSL oder Let's Encrypt
   - **Nginx-Reload**: Neuladen der Konfiguration ohne Downtime
3. **Wichtige Ansible-Befehle**:
   - `ansible-playbook`: Führt Playbooks aus
   - `ansible-inventory`: Zeigt die Inventory-Konfiguration
   - `ansible -m ping`: Testet die Verbindung zu Zielservern

## Übungen zum Verinnerlichen

### Übung 1: Ansible einrichten und Zielserver konfigurieren
**Ziel**: Lernen, wie man Ansible installiert, eine Inventory-Datei erstellt und SSH-Zugriff zu Zielservern einrichtet.

1. **Schritt 1**: Installiere Ansible auf dem Steuerknoten.
   ```bash
   sudo apt update
   sudo apt install -y ansible
   ansible --version
   ```
2. **Schritt 2**: Richte SSH-Schlüssel für passwortlosen Zugriff ein.
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
   ssh-copy-id user@server1
   ssh-copy-id user@server2
   ```
   Ersetze `user@server1` und `user@server2` durch die Benutzer und IP-Adressen deiner Zielserver (z. B. `user@192.168.1.101`).
3. **Schritt 3**: Erstelle eine Ansible-Inventory-Datei.
   ```bash
   mkdir -p ~/ansible-cert-rotation
   cd ~/ansible-cert-rotation
   nano inventory.yml
   ```
   Füge folgenden Inhalt ein:
   ```yaml
   all:
     hosts:
       server1:
         ansible_host: 192.168.1.101
         ansible_user: user
       server2:
         ansible_host: 192.168.1.102
         ansible_user: user
   ```
   Passe die IP-Adressen und Benutzernamen an.
4. **Schritt 4**: Teste die Verbindung zu den Zielservern.
   ```bash
   ansible -i inventory.yml all -m ping
   ```
   Die Ausgabe sollte `pong` für jeden Server anzeigen.

**Reflexion**: Warum ist schlüsselbasierte SSH-Authentifizierung für Ansible wichtig, und wie vereinfacht die Inventory-Datei die Verwaltung mehrerer Server?

### Übung 2: Ansible-Playbook für Zertifikatrotation erstellen
**Ziel**: Verstehen, wie man ein Playbook erstellt, das das Rotationsskript verteilt und ausführt.

1. **Schritt 1**: Erstelle das Rotationsskript (aus der vorherigen Anleitung).
   ```bash
   nano scripts/rotate_cert.sh
   ```
   Füge folgenden Inhalt ein (angepasst für Ansible):
   ```bash
   #!/bin/bash

   # Konfiguration
   DOMAIN="myserver.local"
   CERT_DIR="/etc/nginx/ssl"
   BACKUP_DIR="/home/user/cert-rotation/backups"
   DAYS_THRESHOLD=30
   CURRENT_DATE=$(date +%s)
   DATE_FORMAT=$(date +%Y%m%d%H%M%S)

   # Funktionen
   check_expiry() {
       local cert_file="$CERT_DIR/$DOMAIN.crt"
       if [ ! -f "$cert_file" ]; then
           echo "Zertifikat $cert_file nicht gefunden."
           return 1
       fi
       local expiry_date=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)
       local expiry_epoch=$(date -d "$expiry_date" +%s)
       local days_left=$(( (expiry_epoch - CURRENT_DATE) / 86400 ))
       echo "$days_left"
   }

   renew_cert() {
       local backup_file="$BACKUP_DIR/$DOMAIN-$DATE_FORMAT.tar.gz"
       mkdir -p "$BACKUP_DIR"
       tar -czf "$backup_file" -C "$CERT_DIR" "$DOMAIN.crt" "$DOMAIN.key"
       echo "Backup erstellt: $backup_file"

       # Neues Zertifikat generieren (selbstsigniert)
       cd "$CERT_DIR"
       openssl req -x509 -newkey rsa:2048 -nodes -days 365 -keyout "$DOMAIN.key" \
           -out "$DOMAIN.crt" -subj "/C=DE/ST=State/L=City/O=MyOrg/CN=$DOMAIN"
       echo "Zertifikat erneuert für $DOMAIN."
   }

   reload_nginx() {
       nginx -t && systemctl reload nginx
       if [ $? -eq 0 ]; then
           echo "Nginx erfolgreich neu geladen."
       else
           echo "Fehler beim Neuladen von Nginx."
           return 1
       fi
   }

   # Hauptlogik
   main() {
       local days_left=$(check_expiry)
       if [ $? -ne 0 ]; then
           exit 1
       fi
       if [ "$days_left" -lt "$DAYS_THRESHOLD" ]; then
           echo "Zertifikat läuft in $days_left Tagen ab. Erneuerung..."
           renew_cert
           reload_nginx
       else
           echo "Zertifikat ist noch $days_left Tage gültig."
       fi
   }

   main
   ```
2. **Schritt 2**: Erstelle das Ansible-Playbook.
   ```bash
   nano cert_rotation.yml
   ```
   Füge folgenden Inhalt ein:
   ```yaml
   - name: Automatische Zertifikatrotation auf Zielservern
     hosts: all
     become: yes
     tasks:
       - name: Erstelle Verzeichnisse für Zertifikate und Backups
         file:
           path: "{{ item }}"
           state: directory
           mode: '0700'
         loop:
           - /etc/nginx/ssl
           - /home/user/cert-rotation/backups
           - /home/user/cert-rotation/scripts

       - name: Kopiere Rotationsskript
         copy:
           src: scripts/rotate_cert.sh
           dest: /home/user/cert-rotation/scripts/rotate_cert.sh
           mode: '0700'

       - name: Führe Rotationsskript aus
         command: /home/user/cert-rotation/scripts/rotate_cert.sh
         register: rotation_result
         changed_when: "'Zertifikat erneuert' in rotation_result.stdout"

       - name: Stelle sicher, dass Nginx läuft
         systemd:
           name: nginx
           state: started
           enabled: yes

       - name: Füge Cron-Job für wöchentliche Rotation hinzu
         cron:
           name: "Zertifikatrotation"
           minute: "0"
           hour: "3"
           day: "*"
           weekday: "1"
           job: "/home/user/cert-rotation/scripts/rotate_cert.sh >> /var/log/cert-rotation.log 2>&1"
   ```
3. **Schritt 3**: Führe das Playbook aus.
   ```bash
   ansible-playbook -i inventory.yml cert_rotation.yml
   ```
   Überprüfe die Ausgabe für erfolgreiche Ausführung.

**Reflexion**: Wie vereinfacht Ansible die Verwaltung von Zertifikaten auf mehreren Servern, und warum ist Idempotenz wichtig?

### Übung 3: Let's Encrypt für Multi-Server-Deployment integrieren
**Ziel**: Erweitern des Playbooks für Let's Encrypt, um echte Zertifikate auf mehreren Servern zu rotieren.

1. **Schritt 1**: Aktualisiere das Rotationsskript für Let's Encrypt.
   ```bash
   nano scripts/rotate_cert.sh
   ```
   Ersetze die `renew_cert`-Funktion durch:
   ```bash
   renew_cert() {
       local domain="$DOMAIN"
       local backup_file="$BACKUP_DIR/$domain-$DATE_FORMAT.tar.gz"
       mkdir -p "$BACKUP_DIR"
       tar -czf "$backup_file" -C "$CERT_DIR" "$domain.crt" "$domain.key"
       echo "Backup erstellt: $backup_file"

       certbot renew --cert-name "$domain" --quiet --nginx
       if [ $? -eq 0 ]; then
           echo "Let's Encrypt-Zertifikat erneuert."
       else
           echo "Fehler bei der Erneuerung mit Let's Encrypt."
           return 1
       fi
   }
   ```
2. **Schritt 2**: Aktualisiere das Playbook für Let's Encrypt.
   ```bash
   nano cert_rotation.yml
   ```
   Ersetze den Inhalt durch:
   ```yaml
   - name: Automatische Zertifikatrotation mit Let's Encrypt
     hosts: all
     become: yes
     tasks:
       - name: Installiere Certbot
         apt:
           name: "{{ item }}"
           state: present
         loop:
           - certbot
           - python3-certbot-nginx

       - name: Erstelle Verzeichnisse für Zertifikate und Backups
         file:
           path: "{{ item }}"
           state: directory
           mode: '0700'
         loop:
           - /etc/nginx/ssl
           - /home/user/cert-rotation/backups
           - /home/user/cert-rotation/scripts

       - name: Kopiere Rotationsskript
         copy:
           src: scripts/rotate_cert.sh
           dest: /home/user/cert-rotation/scripts/rotate_cert.sh
           mode: '0700'

       - name: Stelle sicher, dass ein Zertifikat existiert
         command: certbot certonly --nginx -d myserver.local --email admin@example.com --agree-tos --no-eff-email --non-interactive
         args:
           creates: /etc/letsencrypt/live/myserver.local/fullchain.pem
         register: certbot_init

       - name: Führe Rotationsskript aus
         command: /home/user/cert-rotation/scripts/rotate_cert.sh
         register: rotation_result
         changed_when: "'Zertifikat erneuert' in rotation_result.stdout"

       - name: Füge Cron-Job für wöchentliche Rotation hinzu
         cron:
           name: "Zertifikatrotation"
           minute: "0"
           hour: "3"
           day: "*"
           weekday: "1"
           job: "/home/user/cert-rotation/scripts/rotate_cert.sh >> /var/log/cert-rotation.log 2>&1"
   ```
3. **Schritt 3**: Führe das Playbook aus.
   ```bash
   ansible-playbook -i inventory.yml cert_rotation.yml
   ```
   Überprüfe `/var/log/cert-rotation.log` auf den Zielservern.

**Reflexion**: Wie erleichtert Ansible die Skalierung von Let's Encrypt-Zertifikaten, und welche Herausforderungen könnten bei Multi-Server-Umgebungen auftreten?

## Tipps für den Erfolg
- Überprüfe Ansible-Logs (`ansible-playbook -v`) und Server-Logs (`/var/log/cert-rotation.log`).
- Sichere SSH-Schlüssel und Skripte (`chmod 600 ~/.ssh/id_rsa`).
- Verwende `ansible -m ping` vor Playbook-Ausführung, um Konnektivität zu prüfen.
- Teste in einer Staging-Umgebung, bevor du in Produktion gehst.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Zertifikatrotation mit Ansible für Multi-Server-Deployment auf Debian automatisieren, einschließlich OpenSSL und Let's Encrypt. Durch die Übungen haben Sie praktische Erfahrung mit Playbooks, Inventories und Cron-Jobs gesammelt. Diese Fähigkeiten sind essenziell für skalierbare, sichere Systeme. Üben Sie weiter, um Erweiterungen wie Benachrichtigungen oder Fehlerbehandlung zu implementieren!

**Nächste Schritte**:
- Integrieren Sie E-Mail-Benachrichtigungen für Fehler mit Ansible.
- Erweitern Sie das Playbook für Zwischenzertifikate (aus vorheriger Anleitung).
- Verwenden Sie Ansible Vault für sichere Verwaltung von Geheimnissen.

**Quellen**:
- Ansible-Dokumentation: https://docs.ansible.com/ansible/latest/
- Certbot-Dokumentation: https://certbot.eff.org/docs/
- Nginx-Dokumentation: https://nginx.org/en/docs/
- DigitalOcean Ansible-Tutorial: https://www.digitalocean.com/community/tutorials/how-to-use-ansible-to-automate-initial-server-setup-on-ubuntu