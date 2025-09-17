# Praxisorientierte Anleitung: Erkunden des ACME-Protokolls für vollständige Automatisierung auf Debian

## Einführung
Das ACME-Protokoll (Automated Certificate Management Environment) ist ein standardisiertes Netzwerkprotokoll (RFC 8555), das die automatisierte Ausstellung, Erneuerung und Verwaltung von TLS-Zertifikaten ermöglicht. Es wurde vom Internet Security Research Group (ISRG) für Let's Encrypt entwickelt und wird von Clients wie Certbot oder acme.sh implementiert. ACME ermöglicht vollständige Automatisierung durch Challenges (z. B. HTTP-01 oder DNS-01), die Domainbesitz validieren, ohne manuelle Intervention. Diese Anleitung erkundet das ACME-Protokoll auf einem Debian-System, zeigt die Integration mit Certbot für die Automatisierung von Zertifikaten in Nginx und erweitert das Rotationsskript aus vorherigen Anleitungen. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, ACME für wartungsarme HTTPS-Infrastrukturen zu nutzen. Diese Anleitung ist ideal für Administratoren und Entwickler, die skalierbare Zertifikatsverwaltung implementieren möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Nginx installiert und konfiguriert (z. B. aus vorherigen Anleitungen)
- Python 3 und pip installiert
- Ein öffentlich erreichbarer Domainname (z. B. `example.com`), der auf die Server-IP zeigt
- Mindestens 2 GB RAM und ausreichend Festplattenspeicher (mindestens 5 GB frei)
- Grundlegende Kenntnisse der Linux-Kommandozeile, Certbot und Nginx
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie VS Code)

## Grundlegende ACME-Protokoll-Konzepte und Befehle
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **ACME-Protokoll-Konzepte**:
   - **ACME v2**: Aktuelle Version (RFC 8555), unterstützt Wildcard-Zertifikate (z. B. `*.example.com`)
   - **Challenges**: Validierungsmethoden wie HTTP-01 (Datei auf Server platzieren) oder DNS-01 (TXT-Record setzen)
   - **Clients**: Certbot (Python-basiert, integriert mit Nginx) oder acme.sh (Shell-basiert, leichtgewichtig)
   - **Automatisierung**: Erneuerung alle 60–90 Tage, mit Hooks für Server-Reload
2. **Wichtige Certbot-Befehle**:
   - `certbot certonly --standalone`: Erstellt Zertifikate ohne Server-Integration
   - `certbot renew --dry-run`: Testet Erneuerung ohne Änderungen
   - `certbot --nginx`: Automatisiert Nginx-Konfiguration
3. **Wichtige Systembefehle**:
   - `crontab -e`: Plant Erneuerungen
   - `systemctl reload nginx`: Lädt Nginx neu

## Übungen zum Verinnerlichen

### Übung 1: ACME mit Certbot für Wildcard-Zertifikate einrichten
**Ziel**: Lernen, wie man ACME mit Certbot für Wildcard-Zertifikate (ACME v2) nutzt, die mehrere Subdomains abdecken.

1. **Schritt 1**: Installiere Certbot (falls nicht bereits vorhanden).
   ```bash
   sudo apt update
   sudo apt install -y certbot python3-certbot-nginx
   ```
2. **Schritt 2**: Erstelle ein Wildcard-Zertifikat mit DNS-01-Challenge (benötigt DNS-API-Zugriff, z. B. für Cloudflare).
   ```bash
   sudo certbot certonly --manual --preferred-challenges dns -d "*.example.com" -d example.com --email admin@example.com --agree-tos --no-eff-email
   ```
   - Folge den Anweisungen: Füge einen TXT-Record in deinen DNS-Provider hinzu (z. B. `_acme-challenge.example.com`).
   - Warte auf DNS-Propagation und drücke Enter.
3. **Schritt 3**: Überprüfe das Zertifikat.
   ```bash
   sudo certbot certificates
   ```
   Die Ausgabe zeigt das Wildcard-Zertifikat mit SANs: `example.com, *.example.com`.
4. **Schritt 4**: Teste das Zertifikat.
   Öffne `https://sub.example.com` (nach DNS-Konfiguration). Das Zertifikat deckt alle Subdomains ab.

**Reflexion**: Warum ist DNS-01 für Wildcard-Zertifikate notwendig, und wie ermöglicht ACME v2 diese Erweiterung?

### Übung 2: Das Rotationsskript für ACME-Automatisierung erweitern
**Ziel**: Verstehen, wie man das Skript aus der vorherigen Anleitung erweitert, um ACME-Challenges und Hooks zu handhaben.

1. **Schritt 1**: Erweitere das Skript um ACME-spezifische Hooks.
   ```bash
   nano ~/cert-rotation/scripts/rotate_acme.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash

   # Konfiguration
   DOMAIN="example.com"
   CERT_NAME="wildcard-$DOMAIN"
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
       tar -czf "$backup_file" -C "$CERT_DIR" fullchain.pem privkey.pem chain.pem
       echo "Backup erstellt: $backup_file" >> "$LOG_FILE"

       # ACME-Erneuerung mit Hooks
       certbot renew --cert-name "$CERT_NAME" --quiet --post-hook "systemctl reload nginx"
       if [ $? -eq 0 ]; then
           echo "ACME-Zertifikat erneuert für $DOMAIN." >> "$LOG_FILE"
       else
           echo "Fehler bei der ACME-Erneuerung." >> "$LOG_FILE"
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
       echo "ACME-Zertifikat ist noch $days_left Tage gültig." >> "$LOG_FILE"
       if [ "$days_left" -lt 30 ]; then
           echo "Zertifikat läuft in $days_left Tagen ab. Erneuerung..." >> "$LOG_FILE"
           renew_cert && reload_nginx
       fi
   }

   main
   ```
2. **Schritt 2**: Mache das Skript ausführbar und teste es.
   ```bash
   chmod +x ~/cert-rotation/scripts/rotate_acme.sh
   sudo ~/cert-rotation/scripts/rotate_acme.sh
   ```
   Überprüfe die Logs:
   ```bash
   tail /var/log/cert-rotation.log
   ```

**Reflexion**: Wie handhabt das Skript ACME-Hooks, und warum ist der `--post-hook` nützlich für Server-Updates?

### Übung 3: ACME-Automatisierung mit acme.sh als Alternative
**Ziel**: Lernen, wie man acme.sh als leichtgewichtigen ACME-Client einsetzt, um die Automatisierung zu erweitern.

1. **Schritt 1**: Installiere acme.sh.
   ```bash
   curl https://get.acme.sh | sh
   source ~/.bashrc
   ```
2. **Schritt 2**: Erstelle ein Wildcard-Zertifikat mit acme.sh (DNS-01).
   ```bash
   acme.sh --issue -d "*.example.com" -d example.com --dns dns_cf -keylength 2048
   ```
   - Ersetze `dns_cf` durch deinen DNS-Provider (z. B. `dns_cf` für Cloudflare). Konfiguriere API-Schlüssel in `~/.acme.sh/account.conf`.
3. **Schritt 3**: Installiere das Zertifikat in Nginx.
   ```bash
   acme.sh --install-cert -d example.com \
       --cert-file /etc/nginx/ssl/fullchain.pem \
       --key-file /etc/nginx/ssl/privkey.pem \
       --fullchain-file /etc/nginx/ssl/fullchain.pem \
       --reloadcmd "systemctl reload nginx"
   ```
4. **Schritt 4**: Automatisiere die Erneuerung mit Cron.
   ```bash
   crontab -e
   ```
   Füge hinzu (täglich um 3 Uhr):
   ```bash
   0 3 * * * /root/.acme.sh/acme.sh --cron --home /root/.acme.sh > /dev/null
   ```
5. **Schritt 5**: Teste die Erneuerung.
   ```bash
   acme.sh --renew -d example.com
   ```

**Reflexion**: Wie unterscheidet sich acme.sh von Certbot, und warum ist es für Shell-Skripte geeignet?

## Tipps für den Erfolg
- Überprüfe Certbot-Logs (`/var/log/letsencrypt/`) und acme.sh-Logs (`~/.acme.sh/acme.sh.log`).
- Stelle sicher, dass Port 80/443 für Challenges offen ist.
- Verwende `--test-cert` für Tests mit der Staging-Umgebung von Let's Encrypt.
- Backup Zertifikate regelmäßig (`/etc/letsencrypt/`).

## Fazit
In dieser Anleitung haben Sie das ACME-Protokoll erkundet und Certbot sowie acme.sh für die vollständige Automatisierung von Zertifikaten verwendet. Durch die Übungen haben Sie praktische Erfahrung mit Wildcard-Zertifikaten, DNS-Challenges und Cron-Integration gesammelt. Diese Fähigkeiten sind essenziell für skalierbare HTTPS-Infrastrukturen. Üben Sie weiter, um Multi-Server-Support oder Integration mit Ansible zu implementieren!

**Nächste Schritte**:
- Erweitern Sie für Wildcard-Zertifikate in Multi-Server-Umgebungen.
- Integrieren Sie ACME in CI/CD-Pipelines.
- Erkunden Sie andere ACME-Clients wie lego.

**Quellen**:
- ACME-Protokoll (RFC 8555): https://datatracker.ietf.org/doc/html/rfc8555
- Certbot-Dokumentation: https://certbot.eff.org/docs/
- acme.sh-Dokumentation: https://github.com/acmesh-official/acme.sh
- Let's Encrypt-Dokumentation: https://letsencrypt.org/docs/

</xaiArtifact># Praxisorientierte Anleitung: Erkundung des ACME-Protokolls für vollständige Automatisierung auf Debian

## Einführung
Das ACME-Protokoll (Automated Certificate Management Environment) ist ein standardisiertes Protokoll der IETF (RFC 8555), das automatisierte Interaktionen zwischen Zertifizierungsstellen (CAs) und Servern für die Ausstellung, Validierung und Erneuerung von TLS-Zertifikaten ermöglicht. Es wird von Diensten wie Let's Encrypt genutzt, um kostenlose, vertrauenswürdige Zertifikate ohne manuelle Intervention zu erzeugen. ACME unterstützt Challenges (z. B. HTTP-01 für Domainvalidierung) und ermöglicht vollständige Automatisierung durch Clients wie Certbot. Diese Anleitung erkundet das ACME-Protokoll, erklärt seine Funktionsweise und zeigt, wie Sie es mit Certbot und Skripten auf einem Debian-System für die vollständige Automatisierung von Zertifikatserstellung und -erneuerung implementieren. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, ACME für sichere, wartungsarme HTTPS-Setups zu nutzen. Diese Anleitung ist ideal für Administratoren und Entwickler, die automatisierte Zertifikatsverwaltung erkunden möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Nginx installiert und konfiguriert (z. B. aus vorherigen Anleitungen)
- Mindestens 2 GB RAM und ausreichend Festplattenspeicher (mindestens 5 GB frei)
- Ein öffentlich erreichbarer Domainname (z. B. `myserver.example.com`), der auf die Server-IP zeigt
- Grundlegende Kenntnisse der Linux-Kommandozeile, Nginx und Skripting
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie VS Code)

## Grundlegende ACME-Konzepte und Befehle
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **ACME-Konzepte**:
   - **Account**: Registriert einen Benutzer bei der CA (z. B. Let's Encrypt)
   - **Key Pair**: Jede ACME-Interaktion verwendet ein Schlüsselpaar für Authentifizierung
   - **Order**: Fordert ein Zertifikat für Domains an
   - **Authorization**: Validierung der Domainkontrolle durch Challenges (HTTP-01, DNS-01)
   - **CSR (Certificate Signing Request)**: Anfrage zur Zertifikatsausstellung
   - **Certificate**: Das finale Zertifikat, das automatisch erneuert werden kann
2. **Wichtige Tools und Befehle**:
   - **Certbot**: ACME-Client für Let's Encrypt (automatisiert Challenges und Erneuerung)
   - `certbot certonly`: Erstellt Zertifikate manuell
   - `certbot renew`: Erneuert Zertifikate
   - `acme.sh`: Leichtgewichtiger ACME-Client für Skripting
3. **Wichtige Systembefehle**:
   - `crontab -e`: Plant Erneuerungen
   - `systemctl reload nginx`: Lädt Nginx neu nach Erneuerung

## Übungen zum Verinnerlichen

### Übung 1: ACME mit Certbot erkunden und Zertifikat erstellen
**Ziel**: Lernen, wie das ACME-Protokoll mit Certbot funktioniert, indem Sie ein Zertifikat erstellen.

1. **Schritt 1**: Installiere Certbot (falls nicht bereits vorhanden).
   ```bash
   sudo apt update
   sudo apt install -y certbot python3-certbot-nginx
   ```
2. **Schritt 2**: Erkunde ACME-Schritte mit Certbot (manueller Modus).
   ```bash
   sudo certbot certonly --manual --preferred-challenges http -d myserver.example.com
   ```
   - Certbot fordert Sie auf, eine HTTP-Challenge-Datei zu erstellen (z. B. unter `/.well-known/acme-challenge/`).
   - Erstelle die Datei in Nginx (z. B. mit einem `location`-Block) und lade die Seite mit `curl` hoch.
   - Certbot validiert die Domain und stellt das Zertifikat aus.
3. **Schritt 3**: Überprüfe den ACME-Prozess.
   ```bash
   sudo certbot certificates
   ```
   Die Ausgabe zeigt den ACME-Account, Challenges und das Zertifikat. Teste mit:
   ```bash
   openssl x509 -in /etc/letsencrypt/live/myserver.example.com/fullchain.pem -text -noout
   ```
   Die Ausgabe zeigt die Vertrauenskette und SANs.

**Reflexion**: Wie validiert ACME die Domainkontrolle durch Challenges, und warum ist HTTP-01 für Webserver geeignet?

### Übung 2: Skript für ACME-Automatisierung mit acme.sh erstellen
**Ziel**: Verstehen, wie man acme.sh als leichtgewichtigen ACME-Client für Skripting verwendet.

1. **Schritt 1**: Installiere acme.sh.
   ```bash
   curl https://get.acme.sh | sh
   source ~/.bashrc
   ```
2. **Schritt 2**: Erstelle ein Skript für ACME-Automatisierung.
   ```bash
   mkdir -p ~/acme-automation/scripts
   nano ~/acme-automation/scripts/acme_automate.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash

   # Konfiguration
   DOMAIN="myserver.example.com"
   EMAIL="admin@example.com"
   ACME_HOME="$HOME/.acme.sh"
   LOG_FILE="/var/log/acme-rotation.log"
   DATE_FORMAT=$(date +%Y%m%d%H%M%S)

   # Funktionen
   check_expiry() {
       local cert_file="$ACME_HOME/$DOMAIN/fullchain.cer"
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

   issue_cert() {
       acme.sh --issue -d "$DOMAIN" --webroot /var/www/myserver/html --email "$EMAIL" --force
       if [ $? -eq 0 ]; then
           echo "Zertifikat erfolgreich ausgestellt für $DOMAIN." >> "$LOG_FILE"
       else
           echo "Fehler bei der Ausstellung des Zertifikats." >> "$LOG_FILE"
           return 1
       fi
   }

   renew_cert() {
       local backup_file="$HOME/acme-backups/$DOMAIN-$DATE_FORMAT.tar.gz"
       mkdir -p "$HOME/acme-backups"
       tar -czf "$backup_file" -C "$ACME_HOME/$DOMAIN" fullchain.cer privkey.key
       echo "Backup erstellt: $backup_file" >> "$LOG_FILE"

       acme.sh --renew -d "$DOMAIN" --force
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
           issue_cert && reload_nginx
           return
       fi
       echo "Zertifikat ist noch $days_left Tage gültig." >> "$LOG_FILE"
       if [ "$days_left" -lt 30 ]; then
           echo "Zertifikat läuft in $days_left Tagen ab. Erneuerung..." >> "$LOG_FILE"
           renew_cert && reload_nginx
       fi
   }

   main
   ```
3. **Schritt 3**: Mache das Skript ausführbar und teste es.
   ```bash
   chmod +x ~/acme-automation/scripts/acme_automate.sh
   ~/acme-automation/scripts/acme_automate.sh
   ```
   Überprüfe die Logs:
   ```bash
   tail /var/log/acme-rotation.log
   ```

**Reflexion**: Wie ermöglicht acme.sh die Skripting-Automatisierung, und warum ist es eine Alternative zu Certbot?

### Übung 3: Cron-Job für ACME-Automatisierung einrichten
**Ziel**: Lernen, wie man die ACME-Automatisierung mit Cron plant und Benachrichtigungen hinzufügt.

1. **Schritt 1**: Erweitere das Skript um E-Mail-Benachrichtigungen.
   ```bash
   nano ~/acme-automation/scripts/acme_automate.sh
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
           if issue_cert && reload_nginx; then
               send_notification "ACME-Zertifikat ausgestellt" "Zertifikat für $DOMAIN ausgestellt."
           else
               send_notification "ACME-Zertifikat ausstellung fehlgeschlagen" "Fehler bei der Ausstellung oder Nginx-Reload."
           fi
           return
       fi
       echo "Zertifikat ist noch $days_left Tage gültig." >> "$LOG_FILE"
       if [ "$days_left" -lt 30 ]; then
           echo "Zertifikat läuft in $days_left Tagen ab. Erneuerung..." >> "$LOG_FILE"
           if renew_cert && reload_nginx; then
               send_notification "ACME-Zertifikat erneuert" "Zertifikat für $DOMAIN erneuert."
           else
               send_notification "ACME-Zertifikat erneuerung fehlgeschlagen" "Fehler bei der Erneuerung oder Nginx-Reload."
           fi
       fi
   }
   ```
   Installiere `mailutils`:
   ```bash
   sudo apt install -y mailutils
   ```
   Konfiguriere Postfix oder nutze einen externen SMTP-Dienst.
2. **Schritt 2**: Richte einen Cron-Job ein.
   ```bash
   crontab -e
   ```
   Füge folgende Zeile hinzu (täglich um 3 Uhr):
   ```bash
   0 3 * * * /home/user/acme-automation/scripts/acme_automate.sh >> /var/log/acme-rotation.log 2>&1
   ```
3. **Schritt 3**: Teste die Automatisierung.
   ```bash
   crontab -l
   tail -f /var/log/acme-rotation.log
   ```
   Simuliere einen Ablauf durch Ändern von `DAYS_THRESHOLD` und überprüfe die E-Mail.

**Reflexion**: Wie verbessert die Cron-Integration die Wartungsfreiheit, und welche Rolle spielen Benachrichtigungen bei der Überwachung?

## Tipps für den Erfolg
- Überprüfe Certbot-Logs (`/var/log/letsencrypt/`) und Nginx-Logs (`/var/log/nginx/error.log`).
- Sichere private Schlüssel (`chmod 600 /etc/letsencrypt/live/multi-domain-cert/privkey.pem`).
- Verwende `certbot renew --dry-run` für Tests.
- Stelle sicher, dass Port 80 für Challenges offen ist und DNS korrekt konfiguriert ist.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie das ACME-Protokoll mit Certbot und acme.sh für vollständige Automatisierung der Zertifikatserstellung nutzen, einschließlich Skripten, Cron und Benachrichtigungen. Durch die Übungen haben Sie praktische Erfahrung mit ACME-Challenges, Multi-Domain-Support und der Integration in Nginx gesammelt. Diese Fähigkeiten sind essenziell für sichere, automatisierte HTTPS-Setups. Üben Sie weiter, um Wildcard-Zertifikate oder Multi-Server-Support zu implementieren!

**Nächste Schritte**:
- Erweitern Sie für Wildcard-Zertifikate mit DNS-01-Challenge.
- Integrieren Sie in Ansible für Multi-Server.
- Erkunden Sie ACME-Alternativen wie Boulder für Tests.

**Quellen**:
- ACME-Protokoll (RFC 8555): https://datatracker.ietf.org/doc/html/rfc8555
- Certbot-Dokumentation: https://certbot.eff.org/docs/
- acme.sh-Dokumentation: https://github.com/acmesh-official/acme.sh
- Let's Encrypt-Dokumentation: https://letsencrypt.org/docs/
