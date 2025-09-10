# Einführung in Cloud Computing: LAMP-Stack auf Google Cloud Platform (GCP) für Schüler

## Einführung

**Cloud Computing** ermöglicht den Zugriff auf Rechenressourcen wie virtuelle Maschinen (VMs), Speicher und Datenbanken über das Internet, ohne dass physische Hardware vor Ort verwaltet werden muss. Für Schüler, die Cloud-Computing-Grundlagen erlernen möchten, ist die **Google Cloud Platform (GCP)** ideal, da sie einen großzügigen Free Tier, ein $300-Aktionsguthaben und eine intuitive Benutzeroberfläche bietet. Diese Anleitung zeigt, wie Schüler ein GCP-Konto erstellen, eine virtuelle Maschine (VM) im Free Tier einrichten, einen LAMP-Stack (Linux, Apache, MySQL/MariaDB, PHP) installieren und eine einfache Webanwendung (z. B. WordPress) bereitstellen können. Sie ist für Anfänger mit Grundkenntnissen in Linux (z. B. aus einem HomeLab mit Proxmox VE, TrueNAS und OPNsense) geeignet und verknüpft Cloud-Konzepte mit praktischen Übungen.

**Voraussetzungen**:
- Ein Google-Konto (z. B. Gmail).
- Internetzugang und ein Browser für die GCP-Konsole (`https://console.cloud.google.com`).
- Grundkenntnisse in Linux (z. B. SSH, `apt`-Befehle, wie aus vorherigen HomeLab-Anleitungen).
- Optional: Kreditkarte oder Zahlungsmethode für die GCP-Kontoverifizierung (keine Kosten im Free Tier).
- Netzwerkverständnis (z. B. Firewall-Regeln, HTTP/HTTPS-Ports).

**Ziele**:
- Verstehen grundlegender Cloud-Computing-Konzepte (z. B. VMs, Netzwerke, Skalierbarkeit).
- Erstellen einer VM in GCPs Free Tier.
- Installieren eines LAMP-Stacks und Bereitstellen einer Webanwendung.
- Vergleich mit HomeLab-Setups (Proxmox VE).

**Hinweis**: GCPs Free Tier umfasst eine e2-micro-VM (1 vCPU, 1 GB RAM) und 30 GB HDD-Speicher pro Monat, ideal für Lernprojekte. Das $300-Aktionsguthaben ermöglicht zusätzliche Experimente.

**Quellen**:
- GCP-Dokumentation: https://cloud.google.com/docs, https://cloud.google.com/free
- Ubuntu-Dokumentation: https://ubuntu.com/server/docs
- Webquellen:,,,,,,,,,,,,,,

## Warum GCP für Schüler?

- **Großzügiger Free Tier**: Kostenlose e2-micro-VM (1 vCPU, 1 GB RAM) und 5 GB Speicher, ausreichend für einfache Webserver oder Datenbanken.
- **$300-Aktionsguthaben**: 90 Tage Zeit, um GCP-Dienste wie Compute Engine, Cloud Storage oder BigQuery zu testen.
- **Intuitive Benutzeroberfläche**: Die GCP-Konsole ist übersichtlich und anfängerfreundlich, im Gegensatz zu komplexeren Plattformen wie AWS.
- **Integration mit Google-Tools**: Vertraute Tools wie Google Drive vereinfachen den Einstieg.
- **Linux-Kompatibilität**: Perfekt für Schüler, die Linux-Kenntnisse aus HomeLab-Projekten (z. B. Proxmox LAMP-Setup) anwenden möchten.

**Vergleich**:
- **AWS**: Umfangreich, aber komplexer Free Tier und steilere Lernkurve.
- **Azure**: Gut für Windows-Nutzer, aber weniger intuitiv für Linux-basierte Projekte.

## Schritt-für-Schritt-Anleitung

### Schritt 1: GCP-Konto einrichten
1. **Google Cloud Console öffnen**:
   - Gehe zu `https://console.cloud.google.com`.
   - Melde dich mit deinem Google-Konto an.
2. **Free Tier aktivieren**:
   - Klicke auf „Kostenlos starten“ oder „Kostenlos testen“.
   - Gib eine Zahlungsmethode ein (zur Verifizierung, keine Abbuchung im Free Tier).
   - Aktiviere das $300-Guthaben (90 Tage gültig).
3. **Projekt erstellen**:
   - In der GCP-Konsole: `Projekt auswählen > Neues Projekt`.
   - Name: `homelab-lamp` (beliebig).
   - Klicke auf „Erstellen“.
   - Wähle das Projekt aus dem Dropdown-Menü oben.

**Tipp**: Notiere die Projekt-ID (z. B. `homelab-lamp-123456`), die für CLI-Befehle benötigt wird.

**Quelle**: https://cloud.google.com/free/docs/gcp-free-tier

### Schritt 2: Virtuelle Maschine (VM) erstellen
1. **Compute Engine aktivieren**:
   - In der GCP-Konsole: `Navigation > Compute Engine > VM-Instanzen`.
   - Klicke auf „Compute Engine API aktivieren“ (dauert ~1 Minute).
2. **VM erstellen**:
   - Klicke auf „Instanz erstellen“.
   - Konfiguriere:
     - Name: `lamp-vm`.
     - Region: `europe-west1` (z. B. Belgien, nahe für geringe Latenz).
     - Zone: `europe-west1-b`.
     - Maschinentyp: `e2-micro` (Free Tier, 1 vCPU, 1 GB RAM).
     - Boot-Disk: `Ubuntu 22.04 LTS`, 10 GB SSD (Free Tier-kompatibel).
     - Firewall: Aktiviere „HTTP-Traffic zulassen“ und „HTTPS-Traffic zulassen“.
   - Klicke auf „Erstellen“ (VM startet in ~1 Minute).
3. **Öffentliche IP prüfen**:
   - In der VM-Liste: Notiere die externe IP (z. B. `34.123.45.67`).
   - Teste SSH-Zugriff:
     ```bash
     ssh ubuntu@34.123.45.67
     ```
     - Falls nötig, generiere SSH-Schlüssel:
       ```bash
       ssh-keygen -t rsa -b 4096
       ```
       - Füge den öffentlichen Schlüssel (`~/.ssh/id_rsa.pub`) in der GCP-Konsole hinzu: `Compute Engine > Metadata > SSH Keys`.

**Tipp**: Verwende die Free Tier-kompatible `e2-micro`-Instanz, um Kosten zu vermeiden.

**Quelle**: https://cloud.google.com/compute/docs/instances/create-start-instance

### Schritt 3: LAMP-Stack installieren
1. **SSH in die VM**:
   ```bash
   ssh ubuntu@34.123.45.67
   ```
2. **System aktualisieren**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```
3. **Apache installieren**:
   ```bash
   sudo apt install apache2 -y
   sudo systemctl enable apache2
   sudo systemctl start apache2
   ```
   - Teste: Öffne `http://34.123.45.67` im Browser (zeigt die Apache-Standardseite).
4. **MariaDB installieren**:
   ```bash
   sudo apt install mariadb-server mariadb-client -y
   sudo systemctl enable mariadb
   sudo systemctl start mariadb
   sudo mysql_secure_installation
   ```
   - Setze ein Root-Passwort, entferne anonyme Benutzer, deaktiviere Remote-Root-Login, entferne Testdatenbank.
   - Erstelle eine Testdatenbank:
     ```bash
     sudo mysql -u root -p
     CREATE DATABASE testdb;
     GRANT ALL PRIVILEGES ON testdb.* TO 'testuser'@'localhost' IDENTIFIED BY 'securepassword';
     FLUSH PRIVILEGES;
     EXIT;
     ```
5. **PHP installieren**:
   ```bash
   sudo apt install php libapache2-mod-php php-mysql php-gd php-curl php-mbstring php-xml -y
   ```
   - Teste PHP:
     ```bash
     sudo nano /var/www/html/info.php
     ```
     - Inhalt:
       ```php
       <?php phpinfo(); ?>
       ```
     - Öffne `http://34.123.45.67/info.php` (nach Tests löschen).
   - PHP-Konfiguration anpassen (optional):
     ```bash
     sudo nano /etc/php/8.1/apache2/php.ini
     ```
     - Beispiel: Erhöhe `upload_max_filesize`:
       ```ini
       upload_max_filesize = 64M
       post_max_size = 64M
       ```
   - Apache neu starten:
     ```bash
     sudo systemctl restart apache2
     ```

### Schritt 4: WordPress-Installation (optional)
1. **WordPress herunterladen**:
   ```bash
   cd /var/www/html
   sudo wget https://wordpress.org/latest.tar.gz
   sudo tar -xzvf latest.tar.gz
   sudo mv wordpress/* .
   sudo rm -rf wordpress latest.tar.gz
   ```
2. **Datenbank erstellen**:
   ```bash
   sudo mysql -u root -p
   CREATE DATABASE wordpress;
   GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost' IDENTIFIED BY 'wpsecurepassword';
   FLUSH PRIVILEGES;
   EXIT;
   ```
3. **WordPress konfigurieren**:
   ```bash
   sudo cp wp-config-sample.php wp-config.php
   sudo nano wp-config.php
   ```
   - Passe an:
     ```php
     define('DB_NAME', 'wordpress');
     define('DB_USER', 'wpuser');
     define('DB_PASSWORD', 'wpsecurepassword');
     define('DB_HOST', 'localhost');
     ```
4. **Berechtigungen setzen**:
   ```bash
   sudo chown -R www-data:www-data /var/www/html
   sudo chmod -R 755 /var/www/html
   ```
5. **WordPress-Setup abschließen**:
   - Öffne `http://34.123.45.67/wp-admin/install.php` und folge dem Installationsassistenten.

**Tipp**: Sichere die Datenbank regelmäßig:
```bash
mysqldump -u wpuser -p wordpress > /var/www/html/backup-$(date +%F).sql
```

### Schritt 5: Firewall und Sicherheit
1. **GCP Firewall-Regeln anpassen**:
   - In der GCP-Konsole: `VPC Network > Firewall`.
   - Regel hinzufügen:
     - Name: `allow-http-https`.
     - Ziel: `All instances in the network`.
     - Quelle: `0.0.0.0/0`.
     - Protokolle/Ports: `tcp:80,443`.
     - Klicke auf „Erstellen“.
   - Optional: Schränke SSH-Zugriff ein:
     - Quelle: `<deine-IP>/32` (z. B. `203.0.113.1/32`).
     - Port: `tcp:22`.
2. **UFW auf Ubuntu aktivieren**:
   ```bash
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw allow 22/tcp
   sudo ufw enable
   ```
3. **Fail2Ban installieren**:
   ```bash
   sudo apt install fail2ban -y
   sudo systemctl enable fail2ban
   sudo systemctl start fail2ban
   ```

**Tipp**: Verwende ein starkes Passwort für MariaDB und WordPress. Für HTTPS nutze Let’s Encrypt (siehe nächste Schritte).

## Integration mit HomeLab-Kenntnissen

### Vergleich mit HomeLab
- **Proxmox VE**:
  - HomeLab: VMs/LXC auf lokaler Hardware (z. B. Ryzen 5, 32 GB RAM).
  - GCP: VMs in der Cloud, keine lokale Hardware erforderlich.
  - Gemeinsamkeit: LAMP-Stack-Setup (Apache, MariaDB, PHP) ist ähnlich.
- **TrueNAS**:
  - HomeLab: NFS-Speicher (`/mnt/tank/vmdata`) für VMs/LXC.
  - GCP: Cloud Storage oder Persistent Disks (z. B. 5 GB im Free Tier).
  - Alternative: Sichere Backups auf TrueNAS via `rsync`:
    ```bash
    rsync -av /var/www/html/backup-*.sql root@192.168.30.100:/mnt/tank/backups
    ```
- **OPNsense**:
  - HomeLab: Firewall-Regeln und Suricata IDS/IPS für VLANs.
  - GCP: Nutze GCP-Firewall-Regeln und IAM für Sicherheit.
  - Tipp: Simuliere OPNsense-Regeln in GCP (z. B. nur `192.168.20.0/24` für Admin-Zugriff).

### Backup-Strategie
1. **Snapshots in GCP**:
   - In der GCP-Konsole: `Compute Engine > Snapshots > Create Snapshot`.
   - Wähle `lamp-vm` Disk, Name: `lamp-snapshot-$(date +%F)`.
2. **Datenbank-Backups**:
   - Sichere auf Google Cloud Storage:
     ```bash
     gsutil cp /var/www/html/backup-*.sql gs://homelab-lamp-backups/
     ```
   - Erstelle einen Storage-Bucket:
     - `Navigation > Cloud Storage > Buckets > Create`.
     - Name: `homelab-lamp-backups`, Region: `europe-west1`.
3. **HomeLab-Integration**:
   - Kopiere Backups auf TrueNAS:
     ```bash
     gsutil cp gs://homelab-lamp-backups/backup-*.sql .
     rsync -av backup-*.sql root@192.168.30.100:/mnt/tank/backups
     ```

## Best Practices für Schüler

- **Kostenmanagement**:
  - Verwende nur Free Tier-Ressourcen (e2-micro, 10 GB SSD).
  - Überwache Kosten: `Billing > Overview` in der GCP-Konsole.
  - Deaktiviere VMs, wenn nicht benötigt:
    ```bash
    gcloud compute instances stop lamp-vm
    ```
- **Sicherheit**:
  - Schränke Firewall-Regeln ein (z. B. nur HTTP/HTTPS).
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
- **Lernziele**:
  - Experimentiere mit GCP-Diensten (z. B. Cloud Storage, BigQuery) im $300-Guthaben.
  - Vergleiche Cloud- (GCP) und On-Premise-Setups (Proxmox).
- **Monitoring**:
  - Nutze `htop` oder `systemctl status` für Apache/MariaDB.
  - Aktiviere GCP Monitoring: `Monitoring > Dashboards > Create Dashboard`.

**Quelle**: https://cloud.google.com/compute/docs/security

## Empfehlungen für Schüler

- **Setup**:
  - **LAMP-VM**: e2-micro (1 vCPU, 1 GB RAM), 10 GB SSD, Ubuntu 22.04 LTS.
  - **Netzwerk**: Öffentliche IP, Firewall-Regeln für `80, 443, 22`.
  - **Workloads**: Hoste eine einfache Webseite oder WordPress.
- **Integration**:
  - GCP: Nutze Free Tier und $300-Guthaben für Lernprojekte.
  - HomeLab: Sichere Backups auf TrueNAS, simuliere OPNsense-Regeln in GCP.
- **Beispiel**:
  - LAMP-VM mit WordPress, gesichert durch GCP-Snapshots und TrueNAS-Backups.
  - Zugriff nur über HTTP/HTTPS, geschützt durch GCP-Firewall.

## Tipps für den Erfolg

- **Free Tier**: Bleibe im Free Tier, um Kosten zu vermeiden (z. B. e2-micro, 10 GB SSD).
- **Lernressourcen**: Nutze die GCP-Dokumentation (https://cloud.google.com/docs) und Tutorials wie „Qwiklabs“ (https://www.qwiklabs.com).
- **Sicherheit**: Teste Firewall-Regeln und überprüfe Logs:
  ```bash
  sudo tail -f /var/log/apache2/access.log
  ```
- **Backup**: Implementiere die 3-2-1-Regel:
  - 3 Kopien: VM-Daten (GCP), Snapshots, TrueNAS-Backups.
  - 2 Medien: GCP Persistent Disk, TrueNAS HDD.
  - 1 Off-Site: Cloud Storage oder TrueNAS.
- **Dokumentation**: Konsultiere https://cloud.google.com/free und https://ubuntu.com/server/docs.

## Fazit

Die Einrichtung eines LAMP-Stacks auf GCP ist ein hervorragender Einstieg in Cloud Computing für Schüler:
- **Einfachheit**: Der Free Tier und die intuitive GCP-Konsole erleichtern das Lernen.
- **Praxisorientiert**: Ähnliche Konzepte wie im HomeLab (z. B. Proxmox LAMP-Setup).
- **Flexibilität**: Das $300-Guthaben ermöglicht Experimente mit fortgeschrittenen Diensten.

Dieses Setup ist ideal für Schüler, die Cloud-Computing-Grundlagen mit praktischen Übungen erlernen möchten. Es verbindet lokale HomeLab-Erfahrungen mit der Skalierbarkeit der Cloud.

**Nächste Schritte**: Möchtest du eine detaillierte Anleitung zu Let’s Encrypt für HTTPS, Integration mit Google Cloud Storage oder einer anderen GCP-Dienst (z. B. Kubernetes)? Alternativ kann ich ein Lernprojekt mit BigQuery oder Cloud Functions erstellen.

**Quellen**:
- GCP-Dokumentation: https://cloud.google.com/docs, https://cloud.google.com/free
- Ubuntu-Dokumentation: https://ubuntu.com/server/docs
- Webquellen:,,,,,,,,,,,,,,
