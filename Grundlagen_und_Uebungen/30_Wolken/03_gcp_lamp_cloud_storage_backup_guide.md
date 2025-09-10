# Anleitung: Integration von Google Cloud Storage für Backups eines LAMP-Stacks auf GCP

## Einführung

**Google Cloud Storage** ist ein skalierbarer, objektbasierter Speicherdienst, ideal für Backups von Webanwendungen wie einem LAMP-Stack (Linux, Apache, MySQL/MariaDB, PHP) auf der Google Cloud Platform (GCP). Diese Anleitung richtet sich an Schüler, die Cloud Computing lernen und automatische Backups für ihre LAMP-Stack-VM (z. B. `lamp-vm` mit WordPress, gesichert mit Let’s Encrypt) einrichten möchten. Sie baut auf den vorherigen Anleitungen (`01_gcp_cloud_computing_intro_guide.md` und `02_gcp_lamp_letsencrypt_guide.md`) auf, die eine LAMP-VM in GCPs Free Tier mit HTTPS eingerichtet haben. Die Anleitung beschreibt die Erstellung eines Cloud Storage Buckets, die Sicherung von Webinhalten, Datenbanken und Let’s Encrypt-Zertifikaten, die Automatisierung von Backups mit Cron-Jobs und die optionale Integration mit einem HomeLab (Proxmox VE, TrueNAS, OPNsense). Sie ist praxisorientiert und schülerfreundlich.

**Voraussetzungen**:
- GCP-VM (`lamp-vm`, Ubuntu 22.04 LTS) mit LAMP-Stack, HTTPS (Let’s Encrypt) und optional WordPress, wie in den vorherigen Anleitungen beschrieben.
- Öffentliche IP (z. B. `34.123.45.67`) und Domain (z. B. `mylampproject.tk`).
- GCP-Konto mit aktiviertem Free Tier oder $300-Guthaben.
- Grundkenntnisse in Linux (z. B. SSH, `apt`, Cron) und Netzwerkkonfiguration (z. B. DNS, Firewall).
- GCP-Firewall-Regeln für `tcp:80,443` aktiviert.
- Optional: HomeLab mit TrueNAS (`192.168.30.100`) für zusätzliche Backups und OPNsense für Netzwerkverständnis.
- Google Cloud SDK (`gcloud`) auf der VM installiert (wird in der Anleitung beschrieben).

**Ziele**:
- Erstellen eines Google Cloud Storage Buckets für Backups.
- Sichern von Webinhalten (`/var/www/html`), Datenbanken und Let’s Encrypt-Zertifikaten.
- Automatisieren von Backups mit Cron-Jobs.
- Optionale Übertragung von Backups auf TrueNAS.
- Verständnis von Cloud Storage im Kontext von Cloud Computing und HomeLab-Integration.

**Hinweis**: Google Cloud Storage ist im Free Tier eingeschränkt (5 GB Standard-Speicher in bestimmten Regionen), aber das $300-Guthaben ermöglicht Tests. Für Lernprojekte reicht ein kleiner Bucket aus.

**Quellen**:
- GCP Cloud Storage-Dokumentation: https://cloud.google.com/storage/docs
- Ubuntu-Dokumentation: https://ubuntu.com/server/docs
- Webquellen:,,,,,,,,,,,,,,

## Schritt-für-Schritt-Anleitung

### Schritt 1: Google Cloud Storage vorbereiten
1. **GCP-Konto und Projekt prüfen**:
   - Öffne die GCP-Konsole: `https://console.cloud.google.com`.
   - Stelle sicher, dass das Projekt `homelab-lamp` (aus `01_gcp_cloud_computing_intro_guide.md`) ausgewählt ist.
   - Notiere die Projekt-ID (z. B. `homelab-lamp-123456`).
2. **Cloud Storage API aktivieren**:
   - In der GCP-Konsole: `APIs & Services > Library`.
   - Suche nach „Cloud Storage API“ und klicke auf „Aktivieren“ (dauert ~1 Minute).
3. **Bucket erstellen**:
   - In der GCP-Konsole: `Navigation > Cloud Storage > Buckets > Create`.
   - Konfiguriere:
     - Name: `homelab-lamp-backups` (muss global eindeutig sein, z. B. `homelab-lamp-backups-123456`).
     - Region: `europe-west1` (für geringe Latenz, Free Tier-kompatibel).
     - Storage Class: `Standard` (für häufigen Zugriff).
     - Access Control: `Uniform` (empfohlen für einfache Verwaltung).
     - Protection Tools: Deaktiviere (für Lernprojekte nicht nötig).
   - Klicke auf „Create“.
4. **Bucket prüfen**:
   - In der GCP-Konsole: `Cloud Storage > Buckets`.
   - Stelle sicher, dass `homelab-lamp-backups` angezeigt wird.

**Tipp**: Wähle `europe-west1` für Konsistenz mit der VM-Region (`lamp-vm`) und zur Minimierung von Latenz.

**Quelle**: https://cloud.google.com/storage/docs/creating-buckets

### Schritt 2: Google Cloud SDK installieren
1. **SSH in die VM**:
   ```bash
   ssh ubuntu@34.123.45.67
   ```
2. **Google Cloud SDK installieren**:
   ```bash
   sudo apt update
   sudo apt install apt-transport-https ca-certificates gnupg curl -y
   curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
   echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
   sudo apt update
   sudo apt install google-cloud-sdk -y
   ```
3. **SDK initialisieren**:
   ```bash
   gcloud init
   ```
   - Folge den Anweisungen:
     - Melde dich mit deinem Google-Konto an (Browser-Fenster öffnet sich).
     - Wähle das Projekt `homelab-lamp` (Projekt-ID: `homelab-lamp-123456`).
     - Setze die Standardregion: `europe-west1`.
4. **Servicekonto erstellen** (für Backup-Zugriff):
   - In der GCP-Konsole: `IAM & Admin > Service Accounts > Create Service Account`.
     - Name: `lamp-backup-sa`.
     - Rolle: `Storage Admin` (für vollen Bucket-Zugriff).
     - Klicke auf „Create and Continue“, dann „Create Key“ (Typ: JSON).
     - Lade die JSON-Schlüsseldatei herunter (z. B. `homelab-lamp-123456-abc123.json`).
   - Kopiere die JSON-Datei auf die VM:
     ```bash
     scp homelab-lamp-123456-abc123.json ubuntu@34.123.45.67:/home/ubuntu/
     ```
   - Auf der VM:
     ```bash
     export GOOGLE_APPLICATION_CREDENTIALS="/home/ubuntu/homelab-lamp-123456-abc123.json"
     ```
     - Permanent setzen:
       ```bash
       echo 'export GOOGLE_APPLICATION_CREDENTIALS="/home/ubuntu/homelab-lamp-123456-abc123.json"' >> ~/.bashrc
       source ~/.bashrc
       ```

**Tipp**: Speichere die JSON-Schlüsseldatei sicher und teile sie nicht öffentlich.

**Quelle**: https://cloud.google.com/storage/docs/authentication#service-accounts

### Schritt 3: Daten für Backups vorbereiten
1. **Webinhalte sichern** (`/var/www/html`):
   - Erstelle ein Archiv von `/var/www/html` (z. B. WordPress-Dateien):
     ```bash
     sudo tar -czf /home/ubuntu/web-backup-$(date +%F).tar.gz /var/www/html
     ```
2. **Datenbank sichern**:
   - Sichere die WordPress-Datenbank (z. B. `wordpress`):
     ```bash
     mysqldump -u wpuser -p wordpress > /home/ubuntu/db-backup-$(date +%F).sql
     ```
     - Gib das Passwort (`wpsecurepassword`) ein.
3. **Let’s Encrypt-Zertifikate sichern**:
   - Erstelle ein Archiv von `/etc/letsencrypt`:
     ```bash
     sudo tar -czf /home/ubuntu/letsencrypt-backup-$(date +%F).tar.gz /etc/letsencrypt
     ```
4. **Backup-Verzeichnis prüfen**:
   ```bash
   ls /home/ubuntu/
   ```
   - Erwartete Ausgabe: `web-backup-2025-09-09.tar.gz`, `db-backup-2025-09-09.sql`, `letsencrypt-backup-2025-09-09.tar.gz`.

### Schritt 4: Backups in Google Cloud Storage hochladen
1. **Einzelnes Backup hochladen**:
   - Lade die Backups in den Bucket:
     ```bash
     gsutil cp /home/ubuntu/web-backup-$(date +%F).tar.gz gs://homelab-lamp-backups/web/
     gsutil cp /home/ubuntu/db-backup-$(date +%F).sql gs://homelab-lamp-backups/db/
     gsutil cp /home/ubuntu/letsencrypt-backup-$(date +%F).tar.gz gs://homelab-lamp-backups/letsencrypt/
     ```
2. **Bucket-Inhalt prüfen**:
   - In der GCP-Konsole: `Cloud Storage > Buckets > homelab-lamp-backups`.
   - Alternativ via CLI:
     ```bash
     gsutil ls gs://homelab-lamp-backups/
     ```
     - Erwartete Ausgabe:
       ```
       gs://homelab-lamp-backups/db/db-backup-2025-09-09.sql
       gs://homelab-lamp-backups/letsencrypt/letsencrypt-backup-2025-09-09.tar.gz
       gs://homelab-lamp-backups/web/web-backup-2025-09-09.tar.gz
       ```

### Schritt 5: Backup-Automatisierung mit Cron
1. **Backup-Skript erstellen**:
   ```bash
   nano /home/ubuntu/backup.sh
   ```
   - Inhalt:
     ```bash
     #!/bin/bash
     # Backup-Skript für LAMP-Stack
     DATE=$(date +%F)
     BACKUP_DIR="/home/ubuntu"
     BUCKET="gs://homelab-lamp-backups"

     # Webinhalte sichern
     sudo tar -czf $BACKUP_DIR/web-backup-$DATE.tar.gz /var/www/html

     # Datenbank sichern
     mysqldump -u wpuser -p'wpsecurepassword' wordpress > $BACKUP_DIR/db-backup-$DATE.sql

     # Let’s Encrypt-Zertifikate sichern
     sudo tar -czf $BACKUP_DIR/letsencrypt-backup-$DATE.tar.gz /etc/letsencrypt

     # Backups hochladen
     gsutil cp $BACKUP_DIR/web-backup-$DATE.tar.gz $BUCKET/web/
     gsutil cp $BACKUP_DIR/db-backup-$DATE.sql $BUCKET/db/
     gsutil cp $BACKUP_DIR/letsencrypt-backup-$DATE.tar.gz $BUCKET/letsencrypt/

     # Alte Backups lokal löschen (älter als 7 Tage)
     find $BACKUP_DIR -name "*-backup-*.tar.gz" -mtime +7 -delete
     find $BACKUP_DIR -name "db-backup-*.sql" -mtime +7 -delete
     ```
2. **Skript ausführbar machen**:
   ```bash
   chmod +x /home/ubuntu/backup.sh
   ```
3. **Cron-Job einrichten**:
   ```bash
   crontab -e
   ```
   - Füge hinzu (täglich um 03:00 Uhr):
     ```bash
     0 3 * * * /home/ubuntu/backup.sh
     ```
4. **Skript testen**:
   ```bash
   /home/ubuntu/backup.sh
   gsutil ls gs://homelab-lamp-backups/
   ```

**Tipp**: Passe das Passwort (`wpsecurepassword`) im Skript an deine Umgebung an.

### Schritt 6: Integration mit HomeLab
1. **Backups auf TrueNAS sichern**:
   - Kopiere Backups von Google Cloud Storage auf TrueNAS:
     ```bash
     gsutil cp gs://homelab-lamp-backups/db/db-backup-$(date +%F).sql /home/ubuntu/
     gsutil cp gs://homelab-lamp-backups/web/web-backup-$(date +%F).tar.gz /home/ubuntu/
     gsutil cp gs://homelab-lamp-backups/letsencrypt/letsencrypt-backup-$(date +%F).tar.gz /home/ubuntu/
     rsync -av /home/ubuntu/*-backup-$(date +%F).* root@192.168.30.100:/mnt/tank/backups
     ```
   - Automatisiere im Skript (`/home/ubuntu/backup.sh`):
     ```bash
     # Am Ende des Skripts hinzufügen
     rsync -av $BACKUP_DIR/*-backup-$DATE.* root@192.168.30.100:/mnt/tank/backups
     ```
2. **Vergleich mit OPNsense**:
   - HomeLab: OPNsense schützt TrueNAS mit Firewall-Regeln und Suricata IDS/IPS.
   - GCP: Simuliere OPNsense-Regeln, indem du den Zugriff auf den Bucket einschränkst:
     - In der GCP-Konsole: `Cloud Storage > homelab-lamp-backups > Permissions`.
     - Rolle `Storage Object Viewer` nur für `lamp-backup-sa` und deine Google-Konto-E-Mail.
   - Überwache Backup-Zugriffe:
     ```bash
     gsutil logging get gs://homelab-lamp-backups
     ```
3. **Backup-Wiederherstellung testen**:
   - Lade ein Backup herunter:
     ```bash
     gsutil cp gs://homelab-lamp-backups/db/db-backup-2025-09-09.sql /home/ubuntu/
     ```
   - Stelle die Datenbank wieder her:
     ```bash
     mysql -u wpuser -p wordpress < /home/ubuntu/db-backup-2025-09-09.sql
     ```
   - Stelle Webinhalte wieder her:
     ```bash
     sudo tar -xzf /home/ubuntu/web-backup-2025-09-09.tar.gz -C /
     ```

## Best Practices für Schüler

- **Kostenmanagement**:
  - Verwende den Free Tier (5 GB Standard-Speicher in `us-central1` oder `europe-west1`).
  - Überwache Kosten: `Billing > Overview` in der GCP-Konsole.
  - Setze ein Budget-Alarm: `Billing > Budgets & Alerts > Create Budget`.
- **Sicherheit**:
  - Schütze den Bucket mit IAM-Rollen (`Storage Admin` nur für `lamp-backup-sa`).
  - Verschlüssle sensible Daten vor dem Upload (optional):
    ```bash
    gpg -c /home/ubuntu/db-backup-$(date +%F).sql
    gsutil cp /home/ubuntu/db-backup-$(date +%F).sql.gpg gs://homelab-lamp-backups/db/
    ```
  - Deaktiviere öffentlichen Bucket-Zugriff:
    ```bash
    gsutil iam ch allUsers:legacyObjectReader gs://homelab-lamp-backups
    ```
- **Automatisierung**:
  - Teste das Backup-Skript regelmäßig:
    ```bash
    /home/ubuntu/backup.sh
    ```
  - Überwache Cron-Jobs:
    ```bash
    sudo tail -f /var/log/syslog | grep CRON
    ```
- **Lernziele**:
  - Verstehe Objektspeicher vs. Dateispeicher (z. B. TrueNAS NFS).
  - Vergleiche Cloud-Backups (GCP) mit HomeLab-Backups (TrueNAS, Proxmox Backup Server).
- **Backup-Strategie**:
  - Implementiere die 3-2-1-Regel:
    - 3 Kopien: VM-Daten (GCP), Cloud Storage, TrueNAS.
    - 2 Medien: GCP Persistent Disk, TrueNAS HDD.
    - 1 Off-Site: Google Cloud Storage.

**Quelle**: https://cloud.google.com/storage/docs/backup-disaster-recovery

## Empfehlungen für Schüler

- **Setup**:
  - **LAMP-VM**: e2-micro (1 vCPU, 1 GB RAM), 10 GB SSD, Ubuntu 22.04 LTS.
  - **Cloud Storage**: Bucket `homelab-lamp-backups` in `europe-west1`, Standard-Klasse.
  - **Workloads**: Sichere Webinhalte, Datenbanken und Let’s Encrypt-Zertifikate.
- **Integration**:
  - GCP: Nutze Free Tier und $300-Guthaben für Backups.
  - HomeLab: Kopiere Backups auf TrueNAS, simuliere OPNsense-Sicherheit mit IAM.
- **Beispiel**:
  - Automatische tägliche Backups von WordPress-Daten (`/var/www/html`, `wordpress`-Datenbank) in Google Cloud Storage.
  - Zusätzliche Kopien auf TrueNAS (`/mnt/tank/backups`).

## Tipps für den Erfolg

- **Free Tier**: Nutze die 5 GB Standard-Speicher im Free Tier, um Kosten zu minimieren.
- **Sicherheit**: Verwende Servicekonten und IAM-Rollen statt Benutzerzugriff.
- **Automatisierung**: Teste das Backup-Skript und die Wiederherstellung regelmäßig.
- **Lernressourcen**: Konsultiere https://cloud.google.com/storage/docs und Tutorials wie „Qwiklabs“ (https://www.qwiklabs.com).
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`) für Referenz.

## Fazit

Die Integration von Google Cloud Storage für Backups eines LAMP-Stacks auf GCP bietet:
- **Zuverlässigkeit**: Sichere, skalierbare Backups für Webinhalte, Datenbanken und Zertifikate.
- **Automatisierung**: Cron-Jobs und `gsutil` vereinfachen die Verwaltung.
- **Lernwert**: Verständnis von Objektspeicher, Backup-Strategien und Integration mit HomeLab-Konzepten.

Dieses Setup ist ideal für Schüler, die Cloud Computing und Backup-Strategien lernen möchten. Es verbindet Cloud- (GCP) und On-Premise-Lösungen (TrueNAS) und ist mit dem Free Tier kosteneffizient.

**Nächste Schritte**: Möchtest du eine Anleitung zur Nutzung von Kubernetes für skalierbare Webanwendungen, zur Einrichtung eines Monitoring-Systems mit Zabbix/Prometheus oder zu fortgeschrittenen Cloud Storage-Features (z. B. Lifecycle-Regeln)?

**Quellen**:
- GCP Cloud Storage-Dokumentation: https://cloud.google.com/storage/docs
- Ubuntu-Dokumentation: https://ubuntu.com/server/docs
- Webquellen:,,,,,,,,,,,,,,
