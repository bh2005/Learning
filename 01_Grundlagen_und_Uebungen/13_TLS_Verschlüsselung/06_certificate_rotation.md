# Praxisorientierte Anleitung: Zertifikatrotation mit automatisierten Skripten auf Debian

## Einführung
Zertifikatrotation ist der Prozess des regelmäßigen Erneuerns von TLS-Zertifikaten, um Ablaufdaten zu vermeiden und die Sicherheit zu gewährleisten. Automatisierte Skripte können dies überprüfen, neue Zertifikate generieren und den Webserver (z. B. Nginx) ohne Downtime neu laden. Diese Anleitung zeigt Ihnen, wie Sie mit OpenSSL und Bash-Skripten auf einem Debian-System eine Zertifikatrotation implementieren, einschließlich der Überprüfung von Ablaufdaten, Erneuerung und Integration mit Nginx. Wir verwenden selbstsignierte Zertifikate als Beispiel, das auf Let's Encrypt erweitert werden kann. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, Zertifikate automatisch zu rotieren und Server sicher zu aktualisieren. Diese Anleitung ist ideal für Administratoren, die wartungsarme, sichere Systeme einrichten möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- OpenSSL und Nginx installiert (z. B. aus vorherigen Anleitungen)
- TLS-Zertifikate verfügbar (z. B. in `~/tls-certs`: `myserver.crt`, `myserver.key`)
- Bash und Cron für Automatisierung
- Mindestens 2 GB RAM und ausreichend Festplattenspeicher (mindestens 5 GB frei)
- Grundlegende Kenntnisse der Linux-Kommandozeile und Skripting
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie VS Code)

## Grundlegende Konzepte und Befehle für Zertifikatrotation
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **Zertifikatrotation-Konzepte**:
   - **Ablaufüberprüfung**: Prüfung der Gültigkeitsdauer mit OpenSSL
   - **Automatisierung**: Bash-Skripte mit Cron-Jobs für periodische Ausführung
   - **Nginx-Integration**: Reload des Servers nach Zertifikatupdate ohne Downtime
   - **Backup**: Sichere Speicherung alter Zertifikate
2. **Wichtige OpenSSL-Befehle**:
   - `openssl x509 -enddate`: Prüft das Ablaufdatum eines Zertifikats
   - `openssl req -x509`: Generiert neue selbstsignierte Zertifikate
3. **Wichtige Systembefehle**:
   - `crontab -e`: Plant Cron-Jobs
   - `systemctl reload nginx`: Lädt Nginx neu
   - `date`: Vergleicht Datum mit Ablaufdatum

## Übungen zum Verinnerlichen

### Übung 1: Skript für Zertifikatablaufüberprüfung und Erneuerung erstellen
**Ziel**: Lernen, wie man ein Bash-Skript schreibt, das Zertifikate überprüft und bei Bedarf erneuert.

1. **Schritt 1**: Erstelle ein Verzeichnis für Skripte und Zertifikate.
   ```bash
   mkdir -p ~/cert-rotation/scripts
   mkdir -p ~/cert-rotation/certs
   mkdir -p ~/cert-rotation/backups
   cd ~/cert-rotation
   ```
2. **Schritt 2**: Erstelle das Bash-Skript `rotate_cert.sh`.
   ```bash
   nano scripts/rotate_cert.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash

   # Konfiguration
   DOMAIN="myserver.local"
   CERT_DIR="/etc/nginx/ssl"
   BACKUP_DIR="$HOME/cert-rotation/backups"
   DAYS_THRESHOLD=30  # Erneuern, wenn weniger als 30 Tage gültig
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
       # Backup erstellen
       tar -czf "$backup_file" -C "$CERT_DIR" "$DOMAIN.crt" "$DOMAIN.key"
       echo "Backup erstellt: $backup_file"

       # Neues Zertifikat generieren (selbstsigniert als Beispiel)
       cd "$CERT_DIR"
       openssl req -x509 -newkey rsa:2048 -nodes -days 365 -keyout "$DOMAIN.key" \
           -out "$DOMAIN.crt" -subj "/C=DE/ST=State/L=City/O=MyOrg/CN=$DOMAIN"

       echo "Zertifikat erneuert für $DOMAIN."
   }

   reload_nginx() {
       sudo nginx -t && sudo systemctl reload nginx
       if [ $? -eq 0 ]; then
           echo "Nginx erfolgreich neu geladen."
       else
           echo "Fehler beim Neuladen von Nginx."
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
3. **Schritt 3**: Mache das Skript ausführbar und teste es.
   ```bash
   chmod +x scripts/rotate_cert.sh
   ./scripts/rotate_cert.sh
   ```
   Die Ausgabe zeigt die verbleibenden Tage und erneuert bei Bedarf das Zertifikat.

**Reflexion**: Warum ist die Ablaufüberprüfung entscheidend, und wie verhindert das Backup Downtime bei Fehlern?

### Übung 2: Skript für Let's Encrypt-Integration erweitern
**Ziel**: Verstehen, wie man das Skript für Let's Encrypt erweitert, um echte Zertifikate zu rotieren.

1. **Schritt 1**: Installiere Certbot für Let's Encrypt.
   ```bash
   sudo apt update
   sudo apt install -y certbot python3-certbot-nginx
   ```
2. **Schritt 2**: Erweitere das Skript um Let's Encrypt-Renewal.
   ```bash
   nano scripts/rotate_cert.sh
   ```
   Ersetze die `renew_cert`-Funktion durch:
   ```bash
   renew_cert() {
       local domain="$DOMAIN"
       local backup_file="$BACKUP_DIR/$domain-$DATE_FORMAT.tar.gz"
       # Backup erstellen
       tar -czf "$backup_file" -C "$CERT_DIR" "$domain.crt" "$domain.key"
       echo "Backup erstellt: $backup_file"

       # Let's Encrypt erneuern
       sudo certbot renew --cert-name "$domain" --quiet --nginx
       if [ $? -eq 0 ]; then
           echo "Let's Encrypt-Zertifikat erneuert."
       else
           echo "Fehler bei der Erneuerung mit Let's Encrypt."
           return 1
       fi
   }
   ```
3. **Schritt 3**: Teste die Erweiterung (zuerst manuell ein Zertifikat holen).
   ```bash
   sudo certbot certonly --nginx -d myserver.local --email admin@example.com --agree-tos --no-eff-email
   ./scripts/rotate_cert.sh
   ```
   Das Skript erneuert nun mit Certbot, wenn nötig.

**Reflexion**: Wie verbessert Let's Encrypt die Automatisierung, und welche Vorteile bietet es gegenüber selbstsignierten Zertifikaten?

### Übung 3: Cron-Job für automatisierte Rotation einrichten
**Ziel**: Lernen, wie man das Skript mit Cron plant, um wöchentliche Rotation zu automatisieren.

1. **Schritt 1**: Bearbeite die Crontab.
   ```bash
   crontab -e
   ```
   Füge folgende Zeile hinzu (wöchentlich montags um 3 Uhr):
   ```bash
   0 3 * * 1 /home/user/cert-rotation/scripts/rotate_cert.sh >> /var/log/cert-rotation.log 2>&1
   ```
2. **Schritt 2**: Überprüfe die Crontab und teste.
   ```bash
   crontab -l
   ```
   Um zu testen, führe das Skript manuell aus oder passe den Cron auf Minuten um (z. B. `* * * * *` für minütlich, nur für Tests!).
3. **Schritt 3**: Überprüfe Logs nach Ausführung.
   ```bash
   tail -f /var/log/cert-rotation.log
   ```

**Reflexion**: Wie gewährleistet Cron die Automatisierung, und warum ist Logging für die Überwachung entscheidend?

## Tipps für den Erfolg
- Überprüfe Nginx-Logs (`/var/log/nginx/error.log`) nach Reload-Fehlern.
- Sichere Skripte und Zertifikate (`chmod 700 scripts/rotate_cert.sh`).
- Verwende `openssl x509 -checkend 2592000 -noout -in /etc/nginx/ssl/myserver.crt` für Tage-Überprüfung (30 Tage = 2592000 Sekunden).
- Teste in einer Staging-Umgebung, bevor du in Produktion gehst.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Zertifikatrotation mit Bash-Skripten auf Debian automatisieren, einschließlich Ablaufüberprüfung, Erneuerung mit OpenSSL oder Let's Encrypt und Nginx-Reload. Durch die Übungen haben Sie praktische Erfahrung mit Skripting und Cron-Jobs gesammelt. Diese Fähigkeiten sind essenziell für wartungsarme, sichere Systeme. Üben Sie weiter, um Erweiterungen wie Benachrichtigungen oder Multi-Domain-Support zu implementieren!

**Nächste Schritte**:
- Erweitern Sie das Skript für E-Mail-Benachrichtigungen bei Fehlern.
- Integrieren Sie es in Ansible für Multi-Server-Deployment.
- Erkunden Sie ACME-Protokoll für vollständige Automatisierung.

**Quellen**:
- OpenSSL-Dokumentation: https://www.openssl.org/docs/
- Certbot-Dokumentation: https://certbot.eff.org/docs/
- Nginx-Dokumentation: https://nginx.org/en/docs/
- DigitalOcean Certbot-Tutorial: https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu