# Anleitung: HTTPS mit Let’s Encrypt für einen LAMP-Stack auf GCP einrichten

## Einführung

Die Sicherung eines Webservers mit **HTTPS** ist entscheidend, um Datenverschlüsselung, Benutzervertrauen und Schutz vor Man-in-the-Middle-Angriffen zu gewährleisten. **Let’s Encrypt** bietet kostenlose, automatisierte SSL/TLS-Zertifikate, die sich ideal für Lernprojekte eignen. Diese Anleitung beschreibt, wie Schüler ein Let’s Encrypt-Zertifikat mit **Certbot** für einen LAMP-Stack (Linux, Apache, MySQL/MariaDB, PHP) auf einer Ubuntu 22.04 LTS VM in der Google Cloud Platform (GCP) einrichten. Sie baut auf der vorherigen Anleitung (`01_gcp_cloud_computing_intro_guide.md`) auf, die eine LAMP-VM (`lamp-vm`, IP: z. B. `34.123.45.67`) in GCPs Free Tier erstellt hat, und integriert Konzepte aus einem HomeLab (Proxmox VE, TrueNAS, OPNsense). Die Anleitung deckt die Domain-Einrichtung, die Zertifikatsinstallation, die Apache-Konfiguration für HTTPS und die automatische Zertifikatserneuerung ab, mit Fokus auf schülerfreundliche Schritte.

**Voraussetzungen**:
- GCP-VM (`lamp-vm`) mit Ubuntu 22.04 LTS, LAMP-Stack (Apache, MariaDB, PHP) und optional WordPress, wie in `01_gcp_cloud_computing_intro_guide.md` beschrieben.
- Öffentliche IP-Adresse der VM (z. B. `34.123.45.67`).
- Eine registrierte Domain (z. B. `example.com`), die auf die VM-IP zeigt (kostenlos über Dienste wie Freenom möglich).
- GCP-Konto mit aktiviertem Free Tier oder $300-Guthaben.
- Grundkenntnisse in Linux (z. B. SSH, `apt`-Befehle) und Netzwerkkonfiguration (z. B. DNS, Firewall).
- GCP-Firewall-Regeln für HTTP (`tcp:80`) und HTTPS (`tcp:443`) aktiviert.
- Optional: HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense für Netzwerkverständnis.

**Ziele**:
- Einrichten einer Domain für die GCP-VM.
- Installation eines Let’s Encrypt-Zertifikats mit Certbot.
- Konfiguration von Apache für HTTPS und automatische Weiterleitung von HTTP zu HTTPS.
- Sicherung von Zertifikaten auf TrueNAS (optional).
- Verständnis von HTTPS und SSL/TLS im Cloud-Computing-Kontext.

**Hinweis**: Let’s Encrypt-Zertifikate sind 90 Tage gültig, aber Certbot automatisiert die Erneuerung. Eine Domain ist erforderlich, da Let’s Encrypt keine Zertifikate für reine IP-Adressen ausstellt.

**Quellen**:
- Let’s Encrypt-Dokumentation: https://letsencrypt.org/docs/
- Certbot-Dokumentation: https://certbot.eff.org/instructions?ws=apache&os=ubuntu-22
- GCP-Dokumentation: https://cloud.google.com/compute/docs/instances/adding-removing-ssl-certificates
- Webquellen:,,,,,,,,,,,,,,

## Schritt-für-Schritt-Anleitung

### Schritt 1: Domain einrichten
1. **Domain registrieren**:
   - Registriere eine kostenlose Domain bei einem Anbieter wie Freenom (https://www.freenom.com), z. B. `mylampproject.tk`.
   - Alternativ: Verwende eine kostenpflichtige Domain (z. B. `example.com` von Namecheap oder GoDaddy).
2. **DNS-Einträge konfigurieren**:
   - In der DNS-Verwaltung des Domain-Anbieters:
     - Erstelle einen `A`-Eintrag:
       - Name: `@` oder `www`.
       - Wert: Öffentliche IP der VM (z. B. `34.123.45.67`).
       - TTL: 3600 Sekunden (Standard).
     - Beispiel:
       ```
       Type: A, Name: www, Value: 34.123.45.67, TTL: 3600
       Type: A, Name: @, Value: 34.123.45.67, TTL: 3600
       ```
   - Warte auf DNS-Propagation (5–60 Minuten):
     ```bash
     dig www.mylampproject.tk
     ```
     - Prüfe, ob die IP `34.123.45.67` zurückgegeben wird.
3. **Webserver testen**:
   - Öffne `http://www.mylampproject.tk` im Browser.
   - Du solltest die Apache-Standardseite oder WordPress (falls installiert) sehen.

**Tipp**: Verwende ein kostenloses DNS-Tool wie Freenom für Lernprojekte, um Kosten zu sparen.

### Schritt 2: Certbot und Let’s Encrypt installieren
1. **SSH in die VM**:
   ```bash
   ssh ubuntu@34.123.45.67
   ```
2. **Snapd installieren** (erforderlich für Certbot):
   ```bash
   sudo apt update
   sudo apt install snapd -y
   sudo snap install core
   sudo snap refresh core
   ```
3. **Certbot installieren**:
   ```bash
   sudo snap install --classic certbot
   sudo ln -s /snap/bin/certbot /usr/bin/certbot
   ```
4. **Zertifikat anfordern**:
   ```bash
   sudo certbot --apache -d mylampproject.tk -d www.mylampproject.tk
   ```
   - Folge den Anweisungen:
     - Gib eine E-Mail-Adresse für Erneuerungsbenachrichtigungen ein.
     - Akzeptiere die Nutzungsbedingungen.
     - Wähle, ob du HTTP zu HTTPS umleiten möchtest (empfohlen: `2` für Weiterleitung).
   - Certbot validiert die Domain via HTTP (Port 80) und erstellt Zertifikate unter `/etc/letsencrypt/live/mylampproject.tk/`.
5. **Zertifikat prüfen**:
   ```bash
   ls /etc/letsencrypt/live/mylampproject.tk/
   ```
   - Erwartete Ausgabe: `cert.pem`, `chain.pem`, `fullchain.pem`, `privkey.pem`.

**Quelle**: https://certbot.eff.org/instructions?ws=apache&os=ubuntu-22

### Schritt 3: Apache für HTTPS konfigurieren
1. **Apache SSL-Modul aktivieren**:
   ```bash
   sudo a2enmod ssl
   ```
2. **Virtuellen Host für HTTPS anpassen**:
   - Certbot erstellt automatisch eine HTTPS-Konfiguration, z. B. `/etc/apache2/sites-available/000-default-le-ssl.conf`.
   - Überprüfe die Konfiguration:
     ```bash
     sudo nano /etc/apache2/sites-available/000-default-le-ssl.conf
     ```
     - Beispiel:
       ```apache
       <VirtualHost *:443>
           ServerName mylampproject.tk
           ServerAlias www.mylampproject.tk
           DocumentRoot /var/www/html
           SSLEngine on
           SSLCertificateFile /etc/letsencrypt/live/mylampproject.tk/fullchain.pem
           SSLCertificateKeyFile /etc/letsencrypt/live/mylampproject.tk/privkey.pem
           <Directory /var/www/html>
               AllowOverride All
           </Directory>
       </VirtualHost>
       ```
   - Stelle sicher, dass `AllowOverride All` für WordPress aktiviert ist (für `.htaccess`).
3. **HTTP zu HTTPS umleiten**:
   - Wenn Certbot die Weiterleitung nicht automatisch eingerichtet hat, bearbeite `/etc/apache2/sites-available/000-default.conf`:
     ```bash
     sudo nano /etc/apache2/sites-available/000-default.conf
     ```
     - Füge hinzu:
       ```apache
       <VirtualHost *:80>
           ServerName mylampproject.tk
           ServerAlias www.mylampproject.tk
           Redirect permanent / https://www.mylampproject.tk/
       </VirtualHost>
       ```
4. **Apache neu starten**:
   ```bash
   sudo systemctl restart apache2
   ```
5. **HTTPS testen**:
   - Öffne `https://www.mylampproject.tk` im Browser.
   - Prüfe das Zertifikat (Schlosssymbol im Browser, ausgestellt von Let’s Encrypt).
   - Teste die Weiterleitung: `http://www.mylampproject.tk` sollte zu `https://` umleiten.

### Schritt 4: Zertifikatserneuerung einrichten
1. **Automatische Erneuerung testen**:
   ```bash
   sudo certbot renew --dry-run
   ```
   - Erwartete Ausgabe: Erfolgreiche Simulation der Erneuerung.
2. **Cron-Job prüfen**:
   - Certbot erstellt automatisch einen Cron-Job oder Systemd-Timer für die Erneuerung:
     ```bash
     sudo systemctl status certbot.timer
     ```
   - Der Timer führt `certbot renew` zweimal täglich aus.
3. **Manuelle Erneuerung (falls nötig)**:
   ```bash
   sudo certbot renew
   sudo systemctl restart apache2
   ```

**Tipp**: Let’s Encrypt-Zertifikate sind 90 Tage gültig. Der automatische Timer sorgt dafür, dass sie rechtzeitig erneuert werden.

### Schritt 5: Integration mit HomeLab
1. **GCP-Firewall-Regeln prüfen**:
   - In der GCP-Konsole: `VPC Network > Firewall`.
   - Stelle sicher, dass `tcp:80` (für Certbot) und `tcp:443` erlaubt sind:
     - Regel: `allow-http-https`, Quelle: `0.0.0.0/0`, Ports: `tcp:80,443`.
   - Optional: Schränke SSH-Zugriff ein:
     - Quelle: `<deine-IP>/32` (z. B. `203.0.113.1/32`), Port: `tcp:22`.
2. **Zertifikate sichern (auf TrueNAS)**:
   - Kopiere Zertifikate auf TrueNAS:
     ```bash
     sudo rsync -av /etc/letsencrypt root@192.168.30.100:/mnt/tank/backups/letsencrypt
     ```
   - Optional: Sichere in Google Cloud Storage:
     ```bash
     gsutil cp -r /etc/letsencrypt gs://homelab-lamp-backups/letsencrypt
     ```
3. **Vergleich mit OPNsense**:
   - HomeLab: OPNsense schützt den Webserver mit Firewall-Regeln und Suricata IDS/IPS.
   - GCP: Simuliere OPNsense-Regeln, indem du GCP-Firewall-Regeln auf `192.168.20.0/24` (Management) beschränkst:
     - Bearbeite die Regel `allow-http-https` in GCP:
       - Quelle: `192.168.20.0/24`, Ports: `tcp:80,443`.
   - Überwache Zugriffe mit Suricata-ähnlicher Log-Analyse:
     ```bash
     sudo tail -f /var/log/apache2/access.log
     ```

### Schritt 6: WordPress mit HTTPS (optional)
1. **WordPress an HTTPS anpassen**:
   - Bearbeite `wp-config.php`:
     ```bash
     sudo nano /var/www/html/wp-config.php
     ```
     - Füge hinzu:
       ```php
       define('FORCE_SSL_ADMIN', true);
       ```
   - In der WordPress-Admin-Oberfläche (`https://www.mylampproject.tk/wp-admin`):
     - Gehe zu `Einstellungen > Allgemein`.
     - Setze „WordPress-Adresse (URL)“ und „Website-Adresse (URL)“ auf `https://www.mylampproject.tk`.
2. **.htaccess für Weiterleitung**:
   - Bearbeite `/var/www/html/.htaccess`:
     ```bash
     sudo nano /var/www/html/.htaccess
     ```
     - Füge hinzu (vor bestehenden WordPress-Regeln):
       ```apache
       RewriteEngine On
       RewriteCond %{HTTPS} off
       RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
       ```
3. **Berechtigungen prüfen**:
   ```bash
   sudo chown -R www-data:www-data /var/www/html
   sudo chmod -R 755 /var/www/html
   ```

## Best Practices für Schüler

- **Sicherheit**:
  - Verwende HTTPS für alle Webzugriffe, um Daten zu verschlüsseln.
  - Schränke GCP-Firewall-Regeln ein (z. B. nur `192.168.20.0/24` für Admin-Zugriff).
  - Deaktiviere SSH-Passwort-Login:
    ```bash
    sudo nano /etc/ssh/sshd_config
    ```
    - Setze:
      ```ini
      PermitRootLogin prohibit-password
      PasswordAuthentication no
      ```
    - Neustart:
      ```bash
      sudo systemctl restart ssh
      ```
  - Installiere Fail2Ban:
    ```bash
    sudo apt install fail2ban -y
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban
    ```
- **Kostenmanagement**:
  - Bleibe im Free Tier (e2-micro, 10 GB SSD).
  - Überwache Kosten: `Billing > Overview` in der GCP-Konsole.
  - Stoppe die VM, wenn nicht benötigt:
    ```bash
    gcloud compute instances stop lamp-vm
    ```
- **Backup**:
  - Sichere Zertifikate und Datenbanken auf TrueNAS oder Google Cloud Storage.
  - Implementiere die 3-2-1-Regel:
    - 3 Kopien: Zertifikate (GCP), Snapshots, TrueNAS-Backups.
    - 2 Medien: GCP Persistent Disk, TrueNAS HDD.
    - 1 Off-Site: Cloud Storage.
- **Monitoring**:
  - Überwache Apache-Zugriffe:
    ```bash
    sudo tail -f /var/log/apache2/access.log
    ```
  - Nutze GCP Monitoring: `Monitoring > Dashboards > Create Dashboard`.
- **Lernziele**:
  - Verstehe SSL/TLS und die Bedeutung von HTTPS.
  - Vergleiche Cloud-Sicherheit (GCP-Firewall) mit HomeLab-Sicherheit (OPNsense/Suricata).

**Quelle**: https://letsencrypt.org/docs/, https://cloud.google.com/compute/docs/instances/adding-removing-ssl-certificates

## Empfehlungen für Schüler

- **Setup**:
  - **LAMP-VM**: e2-micro (1 vCPU, 1 GB RAM), 10 GB SSD, Ubuntu 22.04 LTS.
  - **Netzwerk**: Öffentliche IP, HTTPS aktiviert mit Let’s Encrypt.
  - **Workloads**: Sichere Webanwendungen wie WordPress mit HTTPS.
- **Integration**:
  - GCP: Nutze Free Tier und $300-Guthaben für Lernprojekte.
  - HomeLab: Sichere Zertifikate auf TrueNAS, simuliere OPNsense-Regeln in GCP.
- **Beispiel**:
  - WordPress mit HTTPS unter `https://www.mylampproject.tk`, gesichert durch Let’s Encrypt.
  - Zugriff geschützt durch GCP-Firewall und Fail2Ban.

## Tipps für den Erfolg

- **Domain**: Verwende eine kostenlose Domain (z. B. Freenom) für Lernprojekte.
- **Sicherheit**: Stelle sicher, dass Port 80 für Certbot geöffnet bleibt (für Erneuerungen).
- **Automatisierung**: Verlasse dich auf Certbots automatische Erneuerung, aber teste regelmäßig.
- **Lernressourcen**: Nutze die Let’s Encrypt-Dokumentation (https://letsencrypt.org/docs/) und GCP-Tutorials (https://cloud.google.com/docs).
- **Dokumentation**: Konsultiere https://certbot.eff.org/ und https://cloud.google.com/compute/docs/instances/adding-removing-ssl-certificates.

## Fazit

Die Einrichtung von HTTPS mit Let’s Encrypt auf einer GCP-LAMP-VM bietet:
- **Sicherheit**: Verschlüsselte Verbindungen für Webanwendungen wie WordPress.
- **Einfachheit**: Certbot automatisiert die Zertifikatsverwaltung.
- **Lernwert**: Verständnis von SSL/TLS, Cloud-Sicherheit und Integration mit HomeLab-Konzepten.

Dieses Setup ist ideal für Schüler, die Cloud Computing und Webserver-Sicherheit lernen möchten. Es verbindet praktische Übungen mit Konzepten aus dem HomeLab (z. B. OPNsense-Firewall).

**Nächste Schritte**: Möchtest du eine Anleitung zur Integration mit Google Cloud Storage für Backups, zur Nutzung von Kubernetes für skalierbare Webanwendungen oder zur Einrichtung eines Monitoring-Systems mit Zabbix/Prometheus?

**Quellen**:
- Let’s Encrypt-Dokumentation: https://letsencrypt.org/docs/
- Certbot-Dokumentation: https://certbot.eff.org/instructions?ws=apache&os=ubuntu-22
- GCP-Dokumentation: https://cloud.google.com/compute/docs/instances/adding-removing-ssl-certificates
- Webquellen:,,,,,,,,,,,,,,