# Praxisorientierte Anleitung: Erweiterung des Ansible-Playbooks für Zertifikatrotation mit Zwischenzertifikaten auf Debian

## Einführung
Zwischenzertifikate (Intermediate Certificates) sind ein wesentlicher Bestandteil der TLS-Vertrauenskette, insbesondere in Szenarien mit Proxies oder Firewalls, die Zwischen-CAs verwenden. Die Automatisierung der Zertifikatrotation für Zwischenzertifikate erfordert die Verwaltung von Root-CA, Zwischen-CA und Serverzertifikaten sowie deren Integration in Nginx. Diese Anleitung erweitert das Ansible-Playbook aus der vorherigen Anleitung, um Zertifikatrotation mit Zwischenzertifikaten (aus der Anleitung "Integration von TLS-Zertifikaten mit Zwischenzertifikaten") auf mehreren Debian-Servern zu automatisieren. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, komplexe Vertrauensketten in einer Multi-Server-Umgebung zu verwalten und zu rotieren. Diese Anleitung ist ideal für Administratoren, die skalierbare, sichere Systeme mit Zwischenzertifikaten einrichten möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) als Steuerknoten mit Root- oder Sudo-Zugriff
- Mindestens zwei Debian-Server als Zielknoten mit Nginx und OpenSSL installiert
- Root- und Zwischen-CA-Zertifikate verfügbar (z. B. in `~/ca`: `root/ca.crt`, `intermediate/intermediate.crt`, `intermediate/myserver.key`, `intermediate/myserver-bundle.crt`)
- Ansible installiert auf dem Steuerknoten
- SSH-Zugriff mit schlüsselbasierter Authentifizierung zu den Zielservern
- Mindestens 2 GB RAM und ausreichend Festplattenspeicher (mindestens 5 GB frei)
- Grundlegende Kenntnisse der Linux-Kommandozeile, Ansible, OpenSSL und Kryptographie
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie VS Code)

## Grundlegende Konzepte und Befehle
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **Zertifikatrotation mit Zwischenzertifikaten**:
   - **Vertrauenskette**: Kombination aus Serverzertifikat, Zwischenzertifikat und Root-Zertifikat
   - **Ablaufüberprüfung**: Prüfung der Gültigkeit von Server- und Zwischenzertifikaten
   - **Zertifikaterneuerung**: Generierung und Signierung neuer Zertifikate mit OpenSSL
   - **Nginx-Integration**: Aktualisierung der Vertrauenskette in Nginx
2. **Ansible-Konzepte**:
   - **Playbook**: YAML-Datei für automatisierte Aufgaben
   - **Templates**: Dynamische Konfigurationsdateien für OpenSSL und Nginx
   - **Inventory**: Liste der Zielserver
3. **Wichtige Befehle**:
   - `ansible-playbook`: Führt Playbooks aus
   - `openssl x509 -enddate`: Prüft Ablaufdaten
   - `openssl ca`: Signiert Zertifikate mit der Zwischen-CA

## Übungen zum Verinnerlichen

### Übung 1: Ansible-Umgebung vorbereiten und Zwischen-CA einrichten
**Ziel**: Vorbereitung der Ansible-Umgebung und Verteilung der Zwischen-CA-Struktur auf Zielserver.

1. **Schritt 1**: Stelle sicher, dass Ansible installiert ist und SSH-Zugriff funktioniert (siehe vorherige Anleitung).
   ```bash
   ansible -i inventory.yml all -m ping
   ```
2. **Schritt 2**: Erstelle die Verzeichnisstruktur für Ansible und CA-Dateien.
   ```bash
   mkdir -p ~/ansible-cert-rotation/templates
   mkdir -p ~/ansible-cert-rotation/files/ca/{root,intermediate/certs}
   cd ~/ansible-cert-rotation
   ```
3. **Schritt 3**: Kopiere bestehende CA-Dateien (aus vorheriger Anleitung).
   ```bash
   cp ~/ca/root/ca.{key,crt} files/ca/root/
   cp ~/ca/intermediate/{intermediate.key,intermediate.crt,openssl.cnf} files/ca/intermediate/
   touch files/ca/intermediate/index.txt
   echo 1000 > files/ca/intermediate/serial
   ```
4. **Schritt 4**: Erstelle eine OpenSSL-Konfigurationsvorlage für SAN.
   ```bash
   nano templates/openssl-san.cnf.j2
   ```
   Füge folgenden Inhalt ein:
   ```ini
   [req]
   distinguished_name = req_distinguished_name
   req_extensions = v3_req
   prompt = no

   [req_distinguished_name]
   C = DE
   O = MyOrg
   CN = {{ domain }}

   [v3_req]
   keyUsage = keyEncipherment, dataEncipherment
   extendedKeyUsage = serverAuth
   subjectAltName = @alt_names

   [alt_names]
   DNS.1 = {{ domain }}
   DNS.2 = localhost
   IP.1 = 127.0.0.1
   ```
5. **Schritt 5**: Aktualisiere die Inventory-Datei mit Variablen.
   ```bash
   nano inventory.yml
   ```
   Füge folgenden Inhalt ein:
   ```yaml
   all:
     hosts:
       server1:
         ansible_host: 192.168.1.101
         ansible_user: user
         domain: myserver.local
       server2:
         ansible_host: 192.168.1.102
         ansible_user: user
         domain: myserver.local
   ```
   Passe IP-Adressen, Benutzernamen und `domain` an.

**Reflexion**: Warum ist die zentrale Verwaltung von CA-Dateien mit Ansible vorteilhaft, und wie hilft die Templating-Funktion bei der Skalierung?

### Übung 2: Ansible-Playbook für Rotation mit Zwischenzertifikaten erstellen
**Ziel**: Erstellen eines Playbooks, das Zwischenzertifikate verteilt, Serverzertifikate rotiert und Nginx aktualisiert.

1. **Schritt 1**: Erstelle das Rotationsskript für Zwischenzertifikate.
   ```bash
   nano scripts/rotate_intermediate_cert.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash

   # Konfiguration
   DOMAIN="$1"
   CERT_DIR="/etc/nginx/ssl"
   BACKUP_DIR="/home/user/cert-rotation/backups"
   CA_DIR="/home/user/ca"
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
       tar -czf "$backup_file" -C "$CERT_DIR" "$DOMAIN.crt" "$DOMAIN.key" "$DOMAIN-bundle.crt"
       echo "Backup erstellt: $backup_file"

       # Neue CSR erstellen
       openssl req -new -key "$CERT_DIR/$DOMAIN.key" -out "$CA_DIR/intermediate/$DOMAIN.csr" \
           -config "$CA_DIR/intermediate/openssl-san.cnf"
       # Signieren mit Zwischen-CA
       openssl ca -config "$CA_DIR/intermediate/openssl.cnf" -extensions v3_req \
           -in "$CA_DIR/intermediate/$DOMAIN.csr" -out "$CERT_DIR/$DOMAIN.crt" -batch
       # Zertifikatbündel erstellen
       cat "$CERT_DIR/$DOMAIN.crt" "$CA_DIR/intermediate/intermediate.crt" > "$CERT_DIR/$DOMAIN-bundle.crt"
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
   nano cert_rotation_intermediate.yml
   ```
   Füge folgenden Inhalt ein:
   ```yaml
   - name: Automatische Zertifikatrotation mit Zwischenzertifikaten
     hosts: all
     become: yes
     vars:
       ca_dir: /home/user/ca
       cert_dir: /etc/nginx/ssl
       backup_dir: /home/user/cert-rotation/backups
     tasks:
       - name: Erstelle Verzeichnisse für CA, Zertifikate und Backups
         file:
           path: "{{ item }}"
           state: directory
           mode: '0700'
         loop:
           - "{{ ca_dir }}/root"
           - "{{ ca_dir }}/intermediate/certs"
           - "{{ cert_dir }}"
           - "{{ backup_dir }}"
           - /home/user/cert-rotation/scripts

       - name: Kopiere Root- und Zwischen-CA-Dateien
         copy:
           src: "{{ item.src }}"
           dest: "{{ item.dest }}"
           mode: "{{ item.mode }}"
         loop:
           - { src: files/ca/root/ca.key, dest: "{{ ca_dir }}/root/ca.key", mode: '0600' }
           - { src: files/ca/root/ca.crt, dest: "{{ ca_dir }}/root/ca.crt", mode: '0644' }
           - { src: files/ca/intermediate/intermediate.key, dest: "{{ ca_dir }}/intermediate/intermediate.key", mode: '0600' }
           - { src: files/ca/intermediate/intermediate.crt, dest: "{{ ca_dir }}/intermediate/intermediate.crt", mode: '0644' }
           - { src: files/ca/intermediate/openssl.cnf, dest: "{{ ca_dir }}/intermediate/openssl.cnf", mode: '0644' }
           - { src: files/ca/intermediate/index.txt, dest: "{{ ca_dir }}/intermediate/index.txt", mode: '0644' }
           - { src: files/ca/intermediate/serial, dest: "{{ ca_dir }}/intermediate/serial", mode: '0644' }

       - name: Erstelle OpenSSL-SAN-Konfiguration
         template:
           src: templates/openssl-san.cnf.j2
           dest: "{{ ca_dir }}/intermediate/openssl-san.cnf"
           mode: '0644'

       - name: Erstelle Server-Schlüssel
         command: openssl genrsa -out "{{ cert_dir }}/{{ domain }}.key" 2048
         args:
           creates: "{{ cert_dir }}/{{ domain }}.key"

       - name: Kopiere Rotationsskript
         copy:
           src: scripts/rotate_intermediate_cert.sh
           dest: /home/user/cert-rotation/scripts/rotate_intermediate_cert.sh
           mode: '0700'

       - name: Führe Rotationsskript aus
         command: /home/user/cert-rotation/scripts/rotate_intermediate_cert.sh {{ domain }}
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
           job: "/home/user/cert-rotation/scripts/rotate_intermediate_cert.sh {{ domain }} >> /var/log/cert-rotation.log 2>&1"
   ```
3. **Schritt 3**: Führe das Playbook aus.
   ```bash
   ansible-playbook -i inventory.yml cert_rotation_intermediate.yml
   ```
   Überprüfe `/var/log/cert-rotation.log` auf den Zielservern.

**Reflexion**: Wie vereinfacht Ansible die Verwaltung von Zwischenzertifikaten in Multi-Server-Szenarien, und warum ist die zentrale CA-Verwaltung sicherer?

### Übung 3: Nginx-Konfiguration für Zwischenzertifikate anpassen
**Ziel**: Erweitern des Playbooks, um die Nginx-Konfiguration mit Zwischenzertifikaten zu aktualisieren.

1. **Schritt 1**: Erstelle eine Nginx-Konfigurationsvorlage.
   ```bash
   nano templates/nginx.conf.j2
   ```
   Füge folgenden Inhalt ein:
   ```nginx
   server {
       listen 80;
       server_name {{ domain }};
       return 301 https://$server_name$request_uri;
   }

   server {
       listen 443 ssl;
       server_name {{ domain }};

       ssl_certificate {{ cert_dir }}/{{ domain }}-bundle.crt;
       ssl_certificate_key {{ cert_dir }}/{{ domain }}.key;
       ssl_trusted_certificate {{ ca_dir }}/root/ca.crt;

       ssl_protocols TLSv1.2 TLSv1.3;
       ssl_prefer_server_ciphers on;
       ssl_ciphers EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH;

       root /var/www/{{ domain }}/html;
       index index.html;

       location / {
           try_files $uri $uri/ /index.html;
       }
   }
   ```
2. **Schritt 2**: Erweitere das Playbook um die Nginx-Konfiguration.
   ```bash
   nano cert_rotation_intermediate.yml
   ```
   Füge vor dem Cron-Task folgende Aufgaben hinzu:
   ```yaml
       - name: Erstelle Web-Verzeichnis
         file:
           path: /var/www/{{ domain }}/html
           state: directory
           mode: '0755'

       - name: Erstelle Beispiel-Webseite
         copy:
           content: "<h1>Sicherer Server mit Zwischenzertifikat</h1>"
           dest: /var/www/{{ domain }}/html/index.html
           mode: '0644'

       - name: Konfiguriere Nginx
         template:
           src: templates/nginx.conf.j2
           dest: /etc/nginx/sites-available/{{ domain }}
           mode: '0644'
         notify: Reload Nginx

       - name: Aktiviere Nginx-Konfiguration
         file:
           src: /etc/nginx/sites-available/{{ domain }}
           dest: /etc/nginx/sites-enabled/{{ domain }}
           state: link
         notify: Reload Nginx
     handlers:
       - name: Reload Nginx
         systemd:
           name: nginx
           state: reloaded
   ```
3. **Schritt 3**: Führe das Playbook aus und teste.
   ```bash
   ansible-playbook -i inventory.yml cert_rotation_intermediate.yml
   ```
   Öffne `https://myserver.local` auf den Zielservern (nach Import von `ca.crt` in den Browser).

**Reflexion**: Wie verbessert die Integration der Nginx-Konfiguration die Konsistenz, und warum ist der Einsatz von Handlern in Ansible nützlich?

## Tipps für den Erfolg
- Überprüfe Ansible-Logs (`ansible-playbook -v`) und Server-Logs (`/var/log/cert-rotation.log`).
- Sichere CA-Schlüssel (`chmod 600 files/ca/root/ca.key`).
- Verwende `openssl s_client -connect myserver.local:443 -CAfile files/ca/root/ca.crt` für TLS-Debugging.
- Teste in einer Staging-Umgebung, bevor du in Produktion gehst.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie ein Ansible-Playbook für die Zertifikatrotation mit Zwischenzertifikaten erweitern, einschließlich CA-Verteilung, Zertifikaterneuerung und Nginx-Konfiguration. Durch die Übungen haben Sie praktische Erfahrung mit Ansible-Templates, Playbooks und Vertrauensketten gesammelt. Diese Fähigkeiten sind essenziell für skalierbare, sichere Multi-Server-Systeme. Üben Sie weiter, um Erweiterungen wie Benachrichtigungen oder Ansible Vault zu implementieren!

**Nächste Schritte**:
- Integrieren Sie E-Mail-Benachrichtigungen bei Rotationsfehlern.
- Verwenden Sie Ansible Vault für sichere Verwaltung von CA-Schlüsseln.
- Erkunden Sie Let's Encrypt für echte Zwischenzertifikate.

**Quellen**:
- Ansible-Dokumentation: https://docs.ansible.com/ansible/latest/
- OpenSSL-Dokumentation: https://www.openssl.org/docs/
- Nginx-Dokumentation: https://nginx.org/en/docs/
- DigitalOcean Ansible-Tutorial: https://www.digitalocean.com/community/tutorials/how-to-use-ansible-to-automate-initial-server-setup-on-ubuntu