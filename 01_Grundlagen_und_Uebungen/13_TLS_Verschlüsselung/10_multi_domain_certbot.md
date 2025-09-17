# Praxisorientierte Anleitung: Erweiterung des Skripts für Multi-Domain-Zertifikate mit Certbot auf Debian

## Einführung
Multi-Domain-Zertifikate (SAN-Zertifikate) ermöglichen die Absicherung mehrerer Domains oder Subdomains mit einem einzigen TLS-Zertifikat, was effizient und kostensparend ist. Certbot unterstützt die Erstellung solcher Zertifikate und ihre automatische Erneuerung. Diese Anleitung erweitert das Zertifikatrotationsskript aus der vorherigen Anleitung, um Multi-Domain-Zertifikate zu handhaben, einschließlich der Konfiguration für mehrere Domains, der Erneuerung und der Integration mit Nginx. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, Multi-Domain-TLS-Zertifikate automatisch zu verwalten und zu rotieren. Diese Anleitung ist ideal für Administratoren, die mehrere Domains mit einem Zertifikat sichern möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Certbot und Nginx installiert (z. B. aus der vorherigen Certbot-Anleitung)
- Mindestens 2 GB RAM und ausreichend Festplattenspeicher (mindestens 5 GB frei)
- Öffentlich erreichbare Domainnamen (z. B. `example.com`, `sub.example.com`), die auf die Server-IP zeigen
- Grundlegende Kenntnisse der Linux-Kommandozeile, Certbot und Nginx
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie VS Code)

## Grundlegende Konzepte und Befehle für Multi-Domain-Zertifikate
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **Multi-Domain-Konzepte**:
   - **SAN (Subject Alternative Name)**: Erweitert Zertifikate um mehrere Domains
   - **Certbot mit SAN**: Unterstützt mehrere `-d` Parameter für Domains
   - **Automatische Erneuerung**: Certbot erneuert alle SAN-Domains gleichzeitig
2. **Wichtige Certbot-Befehle**:
   - `certbot certonly --nginx -d domain1 -d domain2`: Erstellt ein Multi-Domain-Zertifikat
   - `certbot certificates`: Zeigt alle Zertifikate und SANs
3. **Wichtige Systembefehle**:
   - `crontab -e`: Plant Erneuerungen
   - `systemctl reload nginx`: Lädt Nginx neu

## Übungen zum Verinnerlichen

### Übung 1: Multi-Domain-Zertifikat mit Certbot erstellen
**Ziel**: Lernen, wie man ein SAN-Zertifikat für mehrere Domains mit Certbot erstellt.

1. **Schritt 1**: Stelle sicher, dass Nginx läuft und die Domains in `/etc/hosts` oder DNS konfiguriert sind.
   ```bash
   sudo nano /etc/hosts
   ```
   Füge hinzu (für lokale Tests):
   ```
   127.0.0.1 example.com sub.example.com
   ```
2. **Schritt 2**: Erstelle ein Multi-Domain-Zertifikat.
   ```bash
   sudo certbot --nginx -d example.com -d sub.example.com --email admin@example.com --agree-tos --no-eff-email
   ```
   Certbot konfiguriert Nginx automatisch für beide Domains.
3. **Schritt 3**: Überprüfe das Zertifikat.
   ```bash
   sudo certbot certificates
   ```
   Die Ausgabe zeigt das Zertifikat mit SANs: `example.com, sub.example.com`.
4. **Schritt 4**: Teste die Domains.
   Öffne `https://example.com` und `https://sub.example.com` im Browser. Beide sollten das gleiche Zertifikat verwenden.

**Reflexion**: Wie vereinfacht Certbot die Erstellung von SAN-Zertifikaten, und warum ist dies für Wildcard-Domains oder Subdomains nützlich?

### Übung 2: Das Rotationsskript für Multi-Domain erweitern
**Ziel**: Verstehen, wie man das Skript aus der vorherigen Anleitung erweitert, um Multi-Domain-Zertifikate zu handhaben.

1. **Schritt 1**: Erstelle oder erweitere das Skript.
   ```bash
   mkdir -p ~/cert-rotation/scripts
   nano ~/cert-rotation/scripts/rotate_certbot_multi.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash

   # Konfiguration
   DOMAINS=("example.com" "sub.example.com")  # Multi-Domain-Array
   CERT_NAME="multi-domain-cert"  # Name für das Zertifikat
   CERT_DIR="/etc/letsencrypt/live/$CERT_NAME"
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
       local backup_file="$BACKUP_DIR/$CERT_NAME-$DATE_FORMAT.tar.gz"
       mkdir -p "$BACKUP_DIR"
       tar -czf "$backup_file" -C "$CERT_DIR" fullchain.pem privkey.pem
       echo "Backup erstellt: $backup_file" >> "$LOG_FILE"

       # Multi-Domain erneuern
       certbot renew --cert-name "$CERT_NAME" --quiet --nginx
       if [ $? -eq 0 ]; then
           echo "Multi-Domain-Zertifikat erneuert für ${DOMAINS[*]}." >> "$LOG_FILE"
       else
           echo "Fehler bei der Erneuerung des Multi-Domain-Zertifikats." >> "$LOG_FILE"
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
       echo "Multi-Domain-Zertifikat ist noch $days_left Tage gültig." >> "$LOG_FILE"
       if [ "$days_left" -lt 30 ]; then
           echo "Zertifikat läuft in $days_left Tagen ab. Erneuerung..." >> "$LOG_FILE"
           renew_cert && reload_nginx
       fi
   }

   main
   ```
2. **Schritt 2**: Mache das Skript ausführbar und teste es.
   ```bash
   chmod +x ~/cert-rotation/scripts/rotate_certbot_multi.sh
   sudo ~/cert-rotation/scripts/rotate_certbot_multi.sh
   ```
   Überprüfe die Logs:
   ```bash
   tail /var/log/cert-rotation.log
   ```

**Reflexion**: Wie handhabt das Skript Multi-Domain-Zertifikate effizient, und warum ist ein gemeinsamer Cert-Name für SANs wichtig?

### Übung 3: Cron-Job für Multi-Domain-Automatisierung einrichten
**Ziel**: Lernen, wie man die Rotation mit Cron automatisiert und E-Mail-Benachrichtigungen hinzufügt.

1. **Schritt 1**: Erweitere das Skript um E-Mail-Benachrichtigungen.
   ```bash
   nano ~/cert-rotation/scripts/rotate_certbot_multi.sh
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
           send_notification "Multi-Domain-Zertifikatrotation fehlgeschlagen" "Zertifikat nicht gefunden."
           exit 1
       fi
       echo "Multi-Domain-Zertifikat ist noch $days_left Tage gültig." >> "$LOG_FILE"
       if [ "$days_left" -lt 30 ]; then
           echo "Zertifikat läuft in $days_left Tagen ab. Erneuerung..." >> "$LOG_FILE"
           if renew_cert && reload_nginx; then
               send_notification "Multi-Domain-Zertifikatrotation erfolgreich" "Zertifikat für ${DOMAINS[*]} erneuert."
           else
               send_notification "Multi-Domain-Zertifikatrotation fehlgeschlagen" "Fehler bei der Erneuerung oder Nginx-Reload."
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
   0 3 * * * /home/user/cert-rotation/scripts/rotate_certbot_multi.sh >> /var/log/cert-rotation.log 2>&1
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
- Sichere private Schlüssel (`chmod 600 /etc/letsencrypt/live/multi-domain-cert/privkey.pem`).
- Verwende `certbot renew --dry-run` für Testläufe ohne echte Änderungen.
- Stelle sicher, dass Port 80 für Let's Encrypt's HTTP-01-Challenge offen ist.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie das Zertifikatrotationsskript für Multi-Domain-Zertifikate mit Certbot erweitern, einschließlich SAN-Konfiguration, Erneuerung und Automatisierung mit Cron. Durch die Übungen haben Sie praktische Erfahrung mit der Einrichtung von HTTPS für mehrere Domains und der Automatisierung von Zertifikatsprozessen gesammelt. Diese Fähigkeiten sind essenziell für sichere, skalierbare Webanwendungen. Üben Sie weiter, um Multi-Server-Support oder Integration mit Ansible zu implementieren!

**Nächste Schritte**:
- Erweitern Sie das Skript für Wildcard-Zertifikate (`*.example.com`).
- Integrieren Sie Certbot in Ansible für Multi-Server-Deployment.
- Erkunden Sie ACME-Client-Alternativen wie `acme.sh`.

**Quellen**:
- Certbot-Dokumentation: https://certbot.eff.org/docs/
- Let's Encrypt-Dokumentation: https://letsencrypt.org/docs/
- Nginx-Dokumentation: https://nginx.org/en/docs/
- DigitalOcean Certbot-Tutorial: https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu