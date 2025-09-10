# Lernprojekt: Daten-Extraktion (ETL/ELT) mit Python und Checkmk API in Cloud SQL (PostgreSQL)

## Einführung

**ETL/ELT-Prozesse** (Extract, Transform, Load/Extract, Load, Transform) sind essenziell für die Datenintegration, um Rohdaten aus Quellen wie APIs in eine Datenbank für Analysen zu überführen. Dieses Lernprojekt zeigt, wie man mit Python Daten aus der **Checkmk API** extrahiert, transformiert und in eine **Google Cloud SQL PostgreSQL-Datenbank** lädt. Es baut auf `gcp_cloud_sql_database_guide.md` () und `elk_checkmk_integration_guide.md` () auf und integriert die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense) für Backups. Das Projekt ist für Lernende mit Grundkenntnissen in Python, SQL und GCP geeignet und nutzt den GCP Free Tier sowie das $300-Aktionsguthaben. Es umfasst drei Übungen: Einrichten einer Cloud SQL PostgreSQL-Instanz, Entwicklung eines ETL-Skripts mit Python, und Automatisierung des Prozesses mit Cron und TrueNAS-Backups.

**Voraussetzungen**:
- GCP-Konto mit aktiviertem Free Tier oder $300-Guthaben, Projekt `homelab-lamp` (Projekt-ID: z. B. `homelab-lamp-123456`).
- Ubuntu-VM auf Proxmox (IP `192.168.30.101`) mit Checkmk Raw Edition (Site `homelab`) installiert (siehe `elk_checkmk_integration_guide.md`).
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement.
- Google Cloud SDK (`gcloud`), `python3`, `pip`, und `psql` (PostgreSQL-Client) installiert.
- Grundkenntnisse in Python, SQL, REST-APIs und Checkmk.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`).
- Checkmk-API-Benutzer mit Token (siehe Übung 1).

**Ziele**:
- Bereitstellung einer PostgreSQL-Datenbank in Cloud SQL.
- Entwicklung eines Python-ETL-Skripts zur Extraktion von Checkmk-Metriken (z. B. CPU-Auslastung).
- Automatisierung des ETL-Prozesses mit Cron und Backup auf TrueNAS.

**Hinweis**: Der ETL-Prozess extrahiert Metriken von der Checkmk API, transformiert sie (z. B. Normalisierung) und lädt sie in Cloud SQL für Analysen.

**Quellen**:
- Cloud SQL-Dokumentation: https://cloud.google.com/sql/docs
- Checkmk API-Dokumentation: https://docs.checkmk.com/latest/en/rest_api.html
- PostgreSQL-Dokumentation: https://www.postgresql.org/docs
- Webquellen:,,,,,

## Lernprojekt: ETL mit Checkmk API und Cloud SQL

### Vorbereitung: Umgebung einrichten
1. **GCP-Umgebung prüfen**:
   - Stelle sicher, dass das GCP-Projekt aktiv ist:
     ```bash
     gcloud config set project homelab-lamp-123456
     ```
   - Installiere `psql` und Python-Bibliotheken auf der Ubuntu-VM:
     ```bash
     ssh ubuntu@192.168.30.101
     sudo apt update
     sudo apt install -y postgresql-client
     pip3 install requests psycopg2-binary
     ```
2. **Checkmk prüfen**:
   - Prüfe Checkmk-Site:
     ```bash
     curl http://192.168.30.101:5000/homelab
     sudo omd status homelab
     ```
3. **Projektverzeichnis erstellen**:
   ```bash
   mkdir ~/checkmk-etl
   cd ~/checkmk-etl
   ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Checkmk und TrueNAS.

### Übung 1: Bereitstellung einer Cloud SQL PostgreSQL-Instanz

**Ziel**: Erstelle und konfiguriere eine PostgreSQL-Instanz in Cloud SQL.

**Aufgabe**: Richte eine PostgreSQL-Datenbank ein und teste die Verbindung.

1. **Cloud SQL API aktivieren**:
   - In der GCP-Konsole: `APIs & Services > Library`.
   - Suche nach „Cloud SQL Admin API“ und aktiviere sie.

2. **Cloud SQL-Instanz erstellen**:
   - Erstelle eine PostgreSQL-Instanz:
     ```bash
     gcloud sql instances create homelab-postgres \
       --database-version=POSTGRES_15 \
       --tier=db-f1-micro \
       --region=europe-west1 \
       --root-password=securepassword123
     ```
     - **Erklärung**: `db-f1-micro` ist Free Tier-kompatibel, PostgreSQL 15 wird verwendet.
   - Prüfe:
     ```bash
     gcloud sql instances list
     ```
     - Erwartete Ausgabe: Instanz `homelab-postgres` mit Status `RUNNABLE`.

3. **Datenbank und Benutzer erstellen**:
   - Erstelle eine Datenbank:
     ```bash
     gcloud sql databases create metrics_db --instance=homelab-postgres
     ```
   - Erstelle einen Benutzer:
     ```bash
     gcloud sql users create app_user --instance=homelab-postgres --password=apppassword456
     ```

4. **Netzwerkzugriff konfigurieren**:
   - Erlaube Zugriff von der Ubuntu-VM:
     ```bash
     gcloud sql instances patch homelab-postgres --authorized-networks=192.168.30.101/32
     ```
     - **Hinweis**: Für Produktion restriktivere Netzwerkeinstellungen verwenden (z. B. VPC).
   - Hole die öffentliche IP:
     ```bash
     gcloud sql instances describe homelab-postgres | grep ipAddress
     ```
     - Erwartete Ausgabe: IP wie `34.123.45.67`.

5. **Datenbankstruktur erstellen**:
   - Verbinde dich mit `psql`:
     ```bash
     psql -h 34.123.45.67 -U app_user -d metrics_db -W
     ```
     - Passwort: `apppassword456`.
   - Erstelle eine Tabelle für Checkmk-Metriken:
     ```sql
     CREATE TABLE host_metrics (
       id SERIAL PRIMARY KEY,
       hostname VARCHAR(255),
       timestamp TIMESTAMP,
       cpu_usage_percent FLOAT,
       memory_used_percent FLOAT,
       recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
     );
     ```
   - Teste:
     ```sql
     SELECT 1;
     \q
     ```

**Erkenntnis**: Cloud SQL bietet eine verwaltete PostgreSQL-Umgebung mit einfacher Einrichtung und Skalierung.

**Quelle**: https://cloud.google.com/sql/docs/postgres

### Übung 2: Entwicklung eines ETL-Skripts mit Python

**Ziel**: Entwickle ein Python-Skript, um Checkmk-Metriken zu extrahieren, zu transformieren und in Cloud SQL zu laden.

**Aufgabe**: Extrahiere CPU- und Speichermetriken von der Checkmk API und speichere sie in PostgreSQL.

1. **Checkmk API-Benutzer erstellen**:
   - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
   - Gehe zu `Setup > Users > Add user`.
   - Benutzer: `api_user`, Rolle: `Automation`, generiere ein API-Token (z. B. `abc123def456`).
   - Speichere das Token sicher:
     ```bash
     echo "CHECKMK_API_TOKEN=abc123def456" > ~/.checkmk_api
     chmod 600 ~/.checkmk_api
     ```

2. **ETL-Skript erstellen**:
   - Erstelle `etl_checkmk.py`:
     ```bash
     nano etl_checkmk.py
     ```
     - Inhalt:
       ```python
       import requests
       import psycopg2
       from datetime import datetime
       import os

       # Checkmk API configuration
       CHECKMK_URL = "http://192.168.30.101:5000/homelab/check_mk/api/1.0"
       CHECKMK_USER = "api_user"
       CHECKMK_TOKEN = os.getenv("CHECKMK_API_TOKEN")

       # Cloud SQL configuration
       DB_HOST = "34.123.45.67"
       DB_NAME = "metrics_db"
       DB_USER = "app_user"
       DB_PASSWORD = "apppassword456"

       def extract_metrics():
           """Extract metrics from Checkmk API."""
           headers = {"Authorization": f"Bearer {CHECKMK_USER} {CHECKMK_TOKEN}"}
           response = requests.get(
               f"{CHECKMK_URL}/domain-types/host/collections/all?query=%7B%22op%22:%22=%22,%22left%22:%22name%22,%22right%22:%22ubuntu-vm%22%7D",
               headers=headers
           )
           response.raise_for_status()
           host_data = response.json()["value"][0]
           hostname = host_data["id"]

           # Get service metrics (CPU and memory)
           response = requests.get(
               f"{CHECKMK_URL}/objects/host/{hostname}/collections/services",
               headers=headers
           )
           response.raise_for_status()
           services = response.json()["value"]
           cpu_usage = None
           memory_usage = None
           for service in services:
               if "CPU" in service["title"]:
                   cpu_response = requests.get(
                       f"{CHECKMK_URL}/objects/service/{hostname}/{service['id']}/actions/timeseries/invoke",
                       headers=headers
                   )
                   cpu_usage = cpu_response.json()["value"]["timeseries"][0]["data"][-1]
               if "Memory" in service["title"]:
                   memory_response = requests.get(
                       f"{CHECKMK_URL}/objects/service/{hostname}/{service['id']}/actions/timeseries/invoke",
                       headers=headers
                   )
                   memory_usage = memory_response.json()["value"]["timeseries"][0]["data"][-1]
           return hostname, cpu_usage, memory_usage

       def transform_metrics(hostname, cpu_usage, memory_usage):
           """Transform extracted metrics."""
           timestamp = datetime.utcnow()
           return {
               "hostname": hostname,
               "timestamp": timestamp,
               "cpu_usage_percent": cpu_usage if cpu_usage else 0.0,
               "memory_used_percent": memory_usage if memory_usage else 0.0
           }

       def load_metrics(data):
           """Load transformed metrics into Cloud SQL."""
           conn = psycopg2.connect(
               host=DB_HOST, dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD
           )
           cursor = conn.cursor()
           cursor.execute(
               """
               INSERT INTO host_metrics (hostname, timestamp, cpu_usage_percent, memory_used_percent)
               VALUES (%s, %s, %s, %s)
               """,
               (
                   data["hostname"],
                   data["timestamp"],
                   data["cpu_usage_percent"],
                   data["memory_used_percent"]
               )
           )
           conn.commit()
           cursor.close()
           conn.close()

       def main():
           hostname, cpu_usage, memory_usage = extract_metrics()
           transformed_data = transform_metrics(hostname, cpu_usage, memory_usage)
           load_metrics(transformed_data)
           print(f"Loaded metrics for {hostname} at {transformed_data['timestamp']}")

       if __name__ == "__main__":
           main()
       ```
   - **Erklärung**:
     - **Extract**: Ruft Host- und Servicedaten von der Checkmk API ab (CPU- und Speichermetriken).
     - **Transform**: Normalisiert Metriken in ein einheitliches Format mit Timestamp.
     - **Load**: Speichert die Daten in der PostgreSQL-Tabelle `host_metrics`.

3. **Skript testen**:
   - Führe das Skript aus:
     ```bash
     source ~/.checkmk_api
     python3 etl_checkmk.py
     ```
     - Erwartete Ausgabe: `Loaded metrics for ubuntu-vm at <timestamp>`.
   - Prüfe die Datenbank:
     ```bash
     psql -h 34.123.45.67 -U app_user -d metrics_db -W
     ```
     ```sql
     SELECT * FROM host_metrics;
     \q
     ```
     - Erwartete Ausgabe: Eintrag mit `hostname`, `timestamp`, `cpu_usage_percent`, `memory_used_percent`.

**Erkenntnis**: Python ermöglicht effiziente ETL-Prozesse für die Integration von API-Daten in Cloud-Datenbanken.

**Quelle**: https://docs.checkmk.com/latest/en/rest_api.html, https://www.postgresql.org/docs

### Übung 3: Automatisierung des ETL-Prozesses und Backup auf TrueNAS

**Ziel**: Automatisiere den ETL-Prozess mit Cron und sichere die Datenbank auf TrueNAS.

**Aufgabe**: Plane das ETL-Skript und exportiere die Datenbank regelmäßig.

1. **ETL-Prozess automatisieren**:
   - Erstelle ein Shell-Skript für die Ausführung:
     ```bash
     nano run_etl.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       source /home/ubuntu/.checkmk_api
       cd /home/ubuntu/checkmk-etl
       python3 etl_checkmk.py >> /home/ubuntu/checkmk-etl/etl.log 2>&1
       ```
     - Ausführbar machen:
       ```bash
       chmod +x run_etl.sh
       ```
   - Plane einen Cronjob:
     ```bash
     crontab -e
     ```
     - Füge hinzu:
       ```
       */5 * * * * /home/ubuntu/checkmk-etl/run_etl.sh
       ```
     - **Erklärung**: Führt das Skript alle 5 Minuten aus.

2. **Cloud SQL-Backup einrichten**:
   - Aktiviere automatische Backups:
     ```bash
     gcloud sql instances patch homelab-postgres --backup-start-time 01:00
     ```
   - Erstelle einen Google Cloud Storage-Bucket:
     ```bash
     gsutil mb -l europe-west1 gs://homelab-postgres-backups
     ```
   - Exportiere die Datenbank:
     ```bash
     gcloud sql export sql homelab-postgres gs://homelab-postgres-backups/metrics_db-$(date +%F).sql.gz \
       --database=metrics_db
     ```

3. **Backup auf TrueNAS synchronisieren**:
   - Synchronisiere auf TrueNAS:
     ```bash
     gsutil cp gs://homelab-postgres-backups/metrics_db-$(date +%F).sql.gz .
     rsync -av metrics_db-$(date +%F).sql.gz root@192.168.30.100:/mnt/tank/backups/checkmk-etl/
     ```
   - Automatisiere:
     ```bash
     nano /home/ubuntu/backup.sh
     ```
     - Inhalt (am Ende hinzufügen):
       ```bash
       DATE=$(date +%F)
       gcloud sql export sql homelab-postgres gs://homelab-postgres-backups/metrics_db-$DATE.sql.gz --database=metrics_db
       gsutil cp gs://homelab-postgres-backups/metrics_db-$DATE.sql.gz /home/ubuntu
       rsync -av /home/ubuntu/metrics_db-$DATE.sql.gz root@192.168.30.100:/mnt/tank/backups/checkmk-etl/
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /home/ubuntu/backup.sh
       ```
     - Plane einen Cronjob:
       ```bash
       crontab -e
       ```
       - Füge hinzu:
         ```
         0 2 * * * /home/ubuntu/backup.sh
         ```

**Erkenntnis**: Automatisierte ETL-Prozesse und Backups gewährleisten kontinuierliche Datenintegration und Sicherheit.

**Quelle**: https://cloud.google.com/sql/docs/postgres/backup-recovery

### Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Aktualisiere die Firewall-Regel in OPNsense, um Zugriff auf `192.168.30.101:5000` (Checkmk) und `34.123.45.67:5432` (Cloud SQL PostgreSQL) von `192.168.30.0/24` zu erlauben:
     - Quelle: `192.168.30.0/24`
     - Ziel: `192.168.30.101`, `34.123.45.67`
     - Ports: `5000,5432`
     - Aktion: `Allow`

2. **Monitoring mit Checkmk (optional)**:
   - Konfiguriere Checkmk für PostgreSQL:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Füge einen PostgreSQL-Check hinzu:
       - Gehe zu `Setup > Services > Manual checks > PostgreSQL`.
       - Host: `homelab-postgres`.
       - Parameter: Host `34.123.45.67`, Benutzer `app_user`, Passwort `apppassword456`.
     - Prüfe:
       - Gehe zu `Monitor > All services > PostgreSQL`.
       - Erwartete Ausgabe: Status `OK` für Datenbankverfügbarkeit.

### Schritt 5: Erweiterung der Übungen
1. **Erweiterte Transformationen**:
   - Erweitere `etl_checkmk.py` für zusätzliche Metriken (z. B. Festplatten-I/O):
     ```python
     if "Disk" in service["title"]:
         disk_response = requests.get(
             f"{CHECKMK_URL}/objects/service/{hostname}/{service['id']}/actions/timeseries/invoke",
             headers=headers
         )
         disk_io = disk_response.json()["value"]["timeseries"][0]["data"][-1]
     ```
   - Füge `disk_io_bytes` zur Tabelle `host_metrics` hinzu:
     ```sql
     ALTER TABLE host_metrics ADD COLUMN disk_io_bytes FLOAT;
     ```

2. **Datenanalyse in Cloud SQL**:
   - Erstelle eine Analyseabfrage:
     ```bash
     psql -h 34.123.45.67 -U app_user -d metrics_db -W
     ```
     ```sql
     SELECT hostname, AVG(cpu_usage_percent) as avg_cpu, AVG(memory_used_percent) as avg_memory
     FROM host_metrics
     WHERE timestamp >= NOW() - INTERVAL '1 hour'
     GROUP BY hostname;
     ```

## Best Practices für Schüler

- **ETL-Design**:
  - Modularisiere ETL-Skripte (Extract, Transform, Load als separate Funktionen).
  - Verwende Umgebungsvariablen für sensible Daten (z. B. API-Token, DB-Passwort).
- **Sicherheit**:
  - Schränke Netzwerkzugriff ein:
    ```bash
    sudo ufw allow from 192.168.30.0/24 to any port 5000
    sudo ufw allow from 192.168.30.0/24 to any port 5432
    ```
  - Sichere SSH-Schlüssel und API-Token:
    ```bash
    chmod 600 ~/.ssh/id_rsa ~/.checkmk_api
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (Cloud SQL, GCS, TrueNAS), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe ETL-Logs:
    ```bash
    cat ~/checkmk-etl/etl.log
    ```
  - Prüfe Cloud SQL-Logs:
    ```bash
    gcloud sql instances describe homelab-postgres
    ```

**Quelle**: https://cloud.google.com/sql/docs/postgres, https://docs.checkmk.com

## Empfehlungen für Schüler

- **Setup**: Cloud SQL (PostgreSQL), Checkmk API, TrueNAS-Backups.
- **Workloads**: ETL-Prozess für Checkmk-Metriken.
- **Integration**: Proxmox (VM), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: CPU- und Speichermetriken in PostgreSQL.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit wenigen Metriken, erweitere bei Bedarf.
- **Übung**: Experimentiere mit weiteren Checkmk-Metriken (z. B. Netzwerk-I/O).
- **Fehlerbehebung**: Nutze `etl.log` und `gcloud sql logs`.
- **Lernressourcen**: https://cloud.google.com/sql/docs, https://docs.checkmk.com, https://www.postgresql.org/docs.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: ETL-Prozess mit Checkmk API und Cloud SQL.
- **Skalierbarkeit**: Automatisierte Datenintegration und Backups.
- **Lernwert**: Verständnis von ETL/ELT und Cloud-Datenbanken.

**Nächste Schritte**: Möchtest du eine Anleitung zu erweiterten Blue-Green Deployments, Log-Aggregation mit Fluentd, oder Integration mit Vertex AI?

**Quellen**:
- Cloud SQL-Dokumentation: https://cloud.google.com/sql/docs
- Checkmk API-Dokumentation: https://docs.checkmk.com/latest/en/rest_api.html
- PostgreSQL-Dokumentation: https://www.postgresql.org/docs
- Webquellen:,,,,,
```