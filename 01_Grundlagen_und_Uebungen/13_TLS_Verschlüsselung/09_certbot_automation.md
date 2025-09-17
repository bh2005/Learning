# Praxisorientierte Anleitung: Automatisierung der Zertifikatserstellung mit Certbot auf Debian

## Einführung
Die Automatisierung der Zertifikatserstellung ist entscheidend, um TLS-Zertifikate effizient zu verwalten und Ablaufprobleme zu vermeiden. Certbot, ein Client für Let's Encrypt, ermöglicht die automatische Erstellung, Erneuerung und Installation von vertrauenswürdigen TLS-Zertifikaten für HTTPS. Diese Anleitung zeigt Ihnen, wie Sie Certbot auf einem Debian-System verwenden, um die Zertifikatserstellung und -erneuerung für einen Nginx-Webserver zu automatisieren, einschließlich Skripten für die Überprüfung und Integration mit Cron. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, TLS-Zertifikate automatisch bereitzustellen und zu erneuern, um sichere Webanwendungen ohne manuellen Aufwand zu gewährleisten. Diese Anleitung ist ideal für Administratoren und Entwickler, die wartungsarme, sichere Systeme einrichten möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Nginx installiert und konfiguriert
- Mindestens 2 GB RAM und ausreichend Festplattenspeicher (mindestens 5 GB frei)
- Ein öffentlich erreichbarer Domainname (z. B. `myserver.example.com`), der auf die Server-IP zeigt
- Grundlegende Kenntnisse der Linux-Kommandozeile und Nginx
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie VS Code)

## Grundlegende Konzepte und Befehle für Certbot
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **Certbot-Konzepte**:
   - **Let's Encrypt**: Eine kostenlose CA, die TLS-Zertifikate ausstellt
   - **ACME-Protokoll**: Automatisiertes Protokoll für Zertifikatsverwaltung
   - **Certbot**: Client für die Interaktion mit Let's Encrypt
   - **Automatische Erneuerung**: Erneuerung von Zertifikaten vor Ablauf
2. **Wichtige Certbot-Befehle**:
   - `certbot certonly`: Erstellt ein Zertifikat
   - `certbot renew`: Erneuert abgelaufene oder bald ablaufende Zertifikate
   - `certbot --nginx`: Automatisiert die Nginx-Konfiguration
3. **Wichtige Systembefehle**:
   - `crontab -e`: Plant automatische Aufgaben
   - `systemctl reload nginx`: Lädt Nginx neu
   - `certbot certificates`: Zeigt vorhandene Zertifikate

## Übungen zum Verinnerlichen

### Übung 1: Certbot installieren und initiales Zertifikat erstellen
**Ziel**: Lernen, wie man Certbot installiert und ein initiales TLS-Zertifikat für Nginx erstellt.

1. **Schritt 1**: Installiere Certbot und das Nginx-Plugin.
   ```bash
   sudo apt update
   sudo apt install -y certbot python3-certbot-nginx
   ```
2. **Schritt 2**: Stelle sicher, dass Nginx läuft und eine Basis-Konfiguration existiert.
   ```bash
   sudo systemctl start nginx
   sudo systemctl enable nginx
   sudo nano /etc/nginx/sites-available/myserver
   ```
   Füge folgenden Inhalt ein:
   ```nginx
   server {
       listen 80;
       server_name myserver.example.com;

       root /var/www/myserver/html;
       index index.html;

       location / {
           try_files $uri $uri/ /index.html;
       }
   }
   ```
   Erstelle eine Beispiel-Webseite:
   ```bash
   sudo mkdir -p /var/www/myserver/html
   echo "<h1>Willkommen auf meinem sicheren Server!</h1>" | sudo tee /var/www/myserver/html/index.html
   ```
   Aktiviere die Konfiguration:
   ```bash
   sudo ln -s /etc/nginx/sites-available/myserver /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl reload nginx
   ```
3. **Schritt 3**: Erstelle ein Zertifikat mit Certbot.
   ```bash
   sudo certbot --nginx -d myserver.example.com --email admin@example.com --agree-tos --no-eff-email
   ```
   Certbot aktualisiert automatisch die Nginx-Konfiguration für HTTPS.
4. **Schritt 4**: Überprüfe die Zertifikate.
   ```bash
   sudo certbot certificates
   ```
   Die Ausgabe zeigt das Zertifikat für `myserver.example.com`. Teste die Webseite unter `https://myserver.example.com`.

**Reflexion**: Wie vereinfacht Certbot die Zertifikatserstellung im Vergleich zu manuellen OpenSSL-Prozessen, und warum ist ein öffentlicher Domainname notwendig?

### Übung 2: Automatisches Erneuern mit Certbot und Skript
**Ziel**: Verstehen, wie man ein Bash-Skript erstellt, um Zertifikate mit Certbot zu erneuern und Nginx zu aktualisieren.

1. **Schritt 1**: Erstelle ein Skript für die Zertifikatrotation.
   ```bash
   mkdir -p ~/cert-rotation/scripts
   nano ~/cert-rotation/scripts/rotate_certbot.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash

   # Konfiguration
   DOMAIN="myserver.example.com"
   CERT_DIR="/etc/letsencrypt/live/$DOMAIN"
   BACKUP_DIR="/home/user/cert-rotation/backups"
   LOG_FILE="/var/log/cert-rotation.log"
   DATE_FORMAT=$(date +%Y%m%d%H%M%S)

   # Funktionen
   check_expiry() {
       local cert_file="$CERT_DIR/fullchain.pem"
       if [ ! -f "$cert_file" ]; then
           echo "Zertifikat $cert_file nicht gefunden." >> "$LOG_FILE"
           return 1
       fi
       local expiry_date=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)
       local expiry_epoch=$(date -d "$expiry_date" +%s)
       local current_date=$(date +%s)
       local days_left=$(( (expiry_epoch - current_date) / 86400 ))
       echo "$days_left"
   }

   renew_cert() {
       local backup_file="$BACKUP_DIR/$DOMAIN-$DATE_FORMAT.tar.gz"
       mkdir -p "$BACKUP_DIR"
       tar -czf "$backup_file" -C "$CERT_DIR" fullchain.pem privkey.pem
       echo "Backup erstellt: $backup_file" >> "$LOG_FILE"

       certbot renew --quiet --nginx
       if [ $? -eq 0 ]; then
           echo "Zertifikat erfolgreich erneuert für $DOMAIN." >> "$LOG_FILE"
       else
           echo "Fehler bei der Erneuerung des Zertifikats." >> "$LOG_FILE"
           return 1
       fi
   }

   reload_nginx() {
       nginx -t && systemctl reload nginx
       if [ $? -eq 0 ]; then
           echo "Nginx erfolgreich neu geladen." >> "$LOG_FILE"
       else
           echo "Fehler beim Neuladen von Nginx." >> "$LOG_FILE"
           return 1
       fi
   }

   # Hauptlogik
   main() {
       local days_left=$(check_expiry)
       if [ $? -ne 0 ]; then
           exit 1
       fi
       echo "Zertifikat ist noch $days_left Tage gültig." >> "$LOG_FILE"
       if [ "$days_left" -lt 30 ]; then
           echo "Zertifikat läuft in $days_left Tagen ab. Erneuerung..." >> "$LOG_FILE"
           renew_cert && reload_nginx
       fi
   }

   main
   ```
2. **Schritt 2**: Mache das Skript ausführbar und teste es.
   ```bash
   chmod +x ~/cert-rotation/scripts/rotate_certbot.sh
   sudo ~/cert-rotation/scripts/rotate_certbot.sh
   ```
   Überprüfe die Logs:
   ```bash
   tail /var/log/cert-rotation.log
   ```

**Reflexion**: Wie verbessert das Skript die Kontrolle über den Erneuerungsprozess, und warum ist das Backup von Zertifikaten wichtig?

### Übung 3: Automatisierung mit Cron und Benachrichtigungen
**Ziel**: Lernen, wie man die Rotation mit Cron automatisiert und E-Mail-Benachrichtigungen hinzufügt.

1. **Schritt 1**: Erweitere das Skript um E-Mail-Benachrichtigungen.
   ```bash
   nano ~/cert-rotation/scripts/rotate_certbot.sh
   ```
   Füge vor `main` eine Benachrichtigungsfunktion hinzu:
   ```bash
   send_notification() {
       local subject="$1"
       local message="$2"
       echo "$message" | mail -s "$subject" admin@example.com
   }
   ```
   Passe `main` an:
   ```bash
   main() {
       local days_left=$(check_expiry)
       if [ $? -ne 0 ]; then
           send_notification "Zertifikatrotation fehlgeschlagen" "Zertifikat nicht gefunden."
           exit 1
       fi
       echo "Zertifikat ist noch $days_left Tage gültig." >> "$LOG_FILE"
       if [ "$days_left" -lt 30 ]; then
           echo "Zertifikat läuft in $days_left Tagen ab. Erneuerung..." >> "$LOG_FILE"
           if renew_cert && reload_nginx; then
               send_notification "Zertifikatrotation erfolgreich" "Zertifikat für $DOMAIN erneuert."
           else
               send_notification "Zertifikatrotation fehlgeschlagen" "Fehler bei der Erneuerung oder Nginx-Reload."
           fi
       fi
   }
   ```
   Stelle sicher, dass `mail` installiert ist:
   ```bash
   sudo apt install -y mailutils
   ```
   Konfiguriere einen SMTP-Server (z. B. Postfix) oder nutze einen externen Dienst.
2. **Schritt 2**: Richte einen Cron-Job ein.
   ```bash
   sudo crontab -e
   ```
   Füge folgende Zeile hinzu (täglich um 3 Uhr):
   ```bash
   0 3 * * * /home/user/cert-rotation/scripts/rotate_certbot.sh >> /var/log/cert-rotation.log 2>&1
   ```
3. **Schritt 3**: Teste die Automatisierung.
   ```bash
   sudo crontab -l
   tail -f /var/log/cert-rotation.log
   ```
   Simuliere einen Ablauf durch Ändern von `DAYS_THRESHOLD` im Skript und überprüfe die E-Mail-Benachrichtigung.

**Reflexion**: Wie verbessert die Integration von Cron und Benachrichtigungen die Zuverlässigkeit, und welche Herausforderungen könnten bei der E-Mail-Konfiguration auftreten?

## Tipps für den Erfolg
- Überprüfe Nginx-Logs (`/var/log/nginx/error.log`) und Certbot-Logs (`/var/log/letsencrypt/`).
- Sichere private Schlüssel (`chmod 600 /etc/letsencrypt/live/myserver.example.com/privkey.pem`).
- Verwende `certbot renew --dry-run` für Testläufe ohne echte Änderungen.
- Stelle sicher, dass Port 80 für Let's Encrypt's HTTP-01-Challenge offen ist.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie die Zertifikatserstellung und -erneuerung mit Certbot auf Debian automatisieren, einschließlich Skripten, Cron-Jobs und E-Mail-Benachrichtigungen. Durch die Übungen haben Sie praktische Erfahrung mit der Einrichtung von HTTPS und der Automatisierung von Zertifikatsprozessen gesammelt. Diese Fähigkeiten sind essenziell für sichere, wartungsarme Webanwendungen. Üben Sie weiter, um Multi-Domain-Support oder Ansible-Integration zu implementieren!

**Nächste Schritte**:
- Erweitern Sie das Skript für Multi-Domain-Zertifikate.
- Integrieren Sie Certbot in Ansible für Multi-Server-Deployment.
- Erkunden Sie ACME-Client-Alternativen wie `acme.sh`.

**Quellen**:
- Certbot-Dokumentation: https://certbot.eff.org/docs/
- Let's Encrypt-Dokumentation: https://letsencrypt.org/docs/
- Nginx-Dokumentation: https://nginx.org/en/docs/
- DigitalOcean Certbot-Tutorial: https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu