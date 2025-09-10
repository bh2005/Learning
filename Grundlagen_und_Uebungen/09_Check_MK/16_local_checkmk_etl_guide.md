# Lernprojekt: Daten-Extraktion (ETL/ELT) mit Python und Checkmk API in eine lokale PostgreSQL-Datenbank

## Einführung

**ETL/ELT-Prozesse** (Extract, Transform, Load/Extract, Load, Transform) sind zentral für die Datenintegration, um Rohdaten aus Quellen wie APIs in eine Datenbank für Analysen zu überführen. Dieses Lernprojekt zeigt, wie man mit Python Daten aus der **Checkmk API** extrahiert, transformiert und in eine **lokale PostgreSQL-Datenbank** lädt, die auf einer Ubuntu-VM in einer HomeLab-Umgebung läuft. Es baut auf `elk_checkmk_integration_guide.md` () auf und integriert die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense) für Backups. Das Projekt ist für Lernende mit Grundkenntnissen in Python, SQL und Linux geeignet und nutzt ausschließlich lokale Ressourcen, um Kosten zu vermeiden und Datenschutz zu gewährleisten. Es umfasst drei Übungen: Einrichten einer lokalen PostgreSQL-Datenbank, Entwicklung eines ETL-Skripts mit Python, und Automatisierung des Prozesses mit Cron und TrueNAS-Backups.

**Voraussetzungen**:
- Ubuntu-VM auf Proxmox (IP `192.168.30.101`) mit Checkmk Raw Edition (Site `homelab`) installiert (siehe `elk_checkmk_integration_guide.md`).
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement.
- `python3`, `pip`, und `postgresql` installiert auf der Ubuntu-VM.
- Grundkenntnisse in Python, SQL, REST-APIs und Checkmk.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`).
- Checkmk-API-Benutzer mit Token (siehe Übung 1).

**Ziele**:
- Einrichten einer lokalen PostgreSQL-Datenbank auf der Ubuntu-VM.
- Entwicklung eines Python-ETL-Skripts zur Extraktion von Checkmk-Metriken (z. B. CPU-Auslastung).
- Automatisierung des ETL-Prozesses mit Cron und Backup auf TrueNAS.

**Hinweis**: Die lokale PostgreSQL-Datenbank läuft auf der Ubuntu-VM und wird mit Checkmk-Metriken befüllt, um eine vollständig lokale ETL-Pipeline zu demonstrieren.

**Quellen**:
- Checkmk API-Dokumentation: https://docs.checkmk.com/latest/en/rest_api.html
- PostgreSQL-Dokumentation: https://www.postgresql.org/docs
- Webquellen:,,,,,

## Lernprojekt: ETL mit Checkmk API und lokaler PostgreSQL-Datenbank

### Vorbereitung: Umgebung einrichten
1. **Ubuntu-VM prüfen**:
   - Verbinde dich mit der VM:
     ```bash
     ssh ubuntu@192.168.30.101
     ```
   - Installiere notwendige Pakete:
     ```bash
     sudo apt update
     sudo apt install -y postgresql postgresql-contrib python3-pip
     pip3 install requests psycopg2-binary
     ```
   - Prüfe Checkmk-Site:
     ```bash
     curl http://192.168.30.101:5000/homelab
     sudo omd status homelab
     ```
2. **Projektverzeichnis erstellen**:
   ```bash
   mkdir ~/checkmk-etl-local
   cd ~/checkmk-etl-local
   ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Checkmk und TrueNAS.

### Übung 1: Einrichten einer lokalen PostgreSQL-Datenbank

**Ziel**: Installiere und konfiguriere eine PostgreSQL-Datenbank auf der Ubuntu-VM.

**Aufgabe**: Richte eine PostgreSQL-Datenbank ein und teste die Verbindung.

1. **PostgreSQL starten und Benutzer konfigurieren**:
   - Starte den PostgreSQL-Dienst:
     ```bash
     sudo systemctl start postgresql
     sudo systemctl enable postgresql
     ```
   - Erstelle einen Datenbankbenutzer:
     ```bash
     sudo -u postgres psql -c "CREATE USER app_user WITH PASSWORD 'apppassword456';"
     ```
   - Erstelle eine Datenbank:
     ```bash
     sudo -u postgres createdb metrics_db
     sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE metrics_db TO app_user;"
     ```

2. **Datenbankstruktur erstellen**:
   - Verbinde dich mit `psql`:
     ```bash
     psql -h localhost -U app_user -d metrics_db -W
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

3. **Netzwerkzugriff konfigurieren**:
   - Bearbeite die PostgreSQL-Konfiguration:
     ```bash
     sudo nano /etc/postgresql/*/main/postgresql.conf
     ```
     - Ändere die Zeile:
       ```
       #listen_addresses = 'localhost'
       ```
       zu:
       ```
       listen_addresses = '192.168.30.101'
       ```
   - Bearbeite die Zugriffsregeln:
     ```bash
     sudo nano /etc/postgresql/*/main/pg_hba.conf
     ```
     - Füge hinzu:
       ```
       host metrics_db app_user 192.168.30.0/24 md5
       ```
   - Starte PostgreSQL neu:
     ```bash
     sudo systemctl restart postgresql
     ```
   - Teste die Verbindung:
     ```bash
     psql -h 192.168.30.101 -U app_user -d metrics_db -W
     ```
     - Erwartete Ausgabe: `psql` Konsole.

**Erkenntnis**: Eine lokale PostgreSQL-Datenbank ist einfach einzurichten und ideal für HomeLab-Umgebungen.

**Quelle**: https://www.postgresql.org/docs

### Übung 2: Entwicklung eines ETL-Skripts mit Python

**Ziel**: Entwickle ein Python-Skript, um Checkmk-Metriken zu extrahieren, zu transformieren und in die lokale PostgreSQL-Datenbank zu laden.

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
   - Erstelle `etl_checkmk_local.py`:
     ```bash
     nano etl_checkmk_local.py
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

       # Local PostgreSQL configuration
       DB_HOST = "192.168.30.101"
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
           """Load transformed metrics into local PostgreSQL."""
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
     - **Load**: Speichert die Daten in der lokalen PostgreSQL-Tabelle `host_metrics`.

3. **Skript testen**:
   - Führe das Skript aus:
     ```bash
     source ~/.checkmk_api
     python3 etl_checkmk_local.py
     ```
     - Erwartete Ausgabe: `Loaded metrics for ubuntu-vm at <timestamp>`.
   - Prüfe die Datenbank:
     ```bash
     psql -h 192.168.30.101 -U app_user -d metrics_db -W
     ```
     ```sql
     SELECT * FROM host_metrics;
     \q
     ```
     - Erwartete Ausgabe: Eintrag mit `hostname`, `timestamp`, `cpu_usage_percent`, `memory_used_percent`.

**Erkenntnis**: Python ermöglicht effiziente ETL-Prozesse für lokale Datenbanken, ideal für HomeLab-Setups.

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
       cd /home/ubuntu/checkmk-etl-local
       python3 etl_checkmk_local.py >> /home/ubuntu/checkmk-etl-local/etl.log 2>&1
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
       */5 * * * * /home/ubuntu/checkmk-etl-local/run_etl.sh
       ```
     - **Erklärung**: Führt das Skript alle 5 Minuten aus.

2. **Datenbank-Backup einrichten**:
   - Erstelle ein Backup-Skript:
     ```bash
     nano backup_db.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       DATE=$(date +%F)
       BACKUP_FILE=/home/ubuntu/checkmk-etl-local/metrics_db-$DATE.sql.gz
       pg_dump -h 192.168.30.101 -U app_user -d metrics_db | gzip > $BACKUP_FILE
       rsync -av $BACKUP_FILE root@192.168.30.100:/mnt/tank/backups/checkmk-etl-local/
       ```
     - Ausführbar machen:
       ```bash
       chmod +x backup_db.sh
       ```
   - Setze das Passwort für `pg_dump`:
     ```bash
     echo "192.168.30.101:5432:metrics_db:app_user:apppassword456" > ~/.pgpass
     chmod 600 ~/.pgpass
     ```
   - Teste das Backup:
     ```bash
     ./backup_db.sh
     ```
     - Prüfe auf TrueNAS:
       ```bash
       ssh root@192.168.30.100 ls /mnt/tank/backups/checkmk-etl-local/
       ```
     - Erwartete Ausgabe: `metrics_db-<date>.sql.gz`.

3. **Backup automatisieren**:
   - Plane einen Cronjob:
     ```bash
     crontab -e
     ```
     - Füge hinzu:
       ```
       0 2 * * * /home/ubuntu/checkmk-etl-local/backup_db.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 02:00 Uhr aus.

**Erkenntnis**: Automatisierte ETL-Prozesse und lokale Backups auf TrueNAS gewährleisten Datenintegrität und Verfügbarkeit.

**Quelle**: https://www.postgresql.org/docs

### Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Aktualisiere die Firewall-Regel in OPNsense, um Zugriff auf `192.168.30.101:5000` (Checkmk) und `192.168.30.101:5432` (PostgreSQL) von `192.168.30.0/24` zu erlauben:
     - Quelle: `192.168.30.0/24`
     - Ziel: `192.168.30.101`
     - Ports: `5000,5432`
     - Aktion: `Allow`

2. **Monitoring mit Checkmk (optional)**:
   - Konfiguriere Checkmk für PostgreSQL:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Füge einen PostgreSQL-Check hinzu:
       - Gehe zu `Setup > Services > Manual checks > PostgreSQL`.
       - Host: `ubuntu-vm`.
       - Parameter: Host `192.168.30.101`, Benutzer `app_user`, Passwort `apppassword456`.
     - Prüfe:
       - Gehe zu `Monitor > All services > PostgreSQL`.
       - Erwartete Ausgabe: Status `OK` für Datenbankverfügbarkeit.

### Schritt 5: Erweiterung der Übungen
1. **Erweiterte Transformationen**:
   - Erweitere `etl_checkmk_local.py` für zusätzliche Metriken (z. B. Festplatten-I/O):
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

2. **Datenanalyse in PostgreSQL**:
   - Erstelle eine Analyseabfrage:
     ```bash
     psql -h 192.168.30.101 -U app_user -d metrics_db -W
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
    chmod 600 ~/.ssh/id_rsa ~/.checkmk_api ~/.pgpass
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe ETL-Logs:
    ```bash
    cat ~/checkmk-etl-local/etl.log
    ```
  - Prüfe PostgreSQL-Logs:
    ```bash
    sudo tail -f /var/log/postgresql/postgresql-*-main.log
    ```

**Quelle**: https://docs.checkmk.com/latest/en/rest_api.html, https://www.postgresql.org/docs

## Empfehlungen für Schüler

- **Setup**: Lokale PostgreSQL-Datenbank, Checkmk API, TrueNAS-Backups.
- **Workloads**: ETL-Prozess für Checkmk-Metriken.
- **Integration**: Proxmox (VM), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: CPU- und Speichermetriken in PostgreSQL.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit wenigen Metriken, erweitere bei Bedarf.
- **Übung**: Experimentiere mit weiteren Checkmk-Metriken (z. B. Netzwerk-I/O).
- **Fehlerbehebung**: Nutze `etl.log` und PostgreSQL-Logs.
- **Lernressourcen**: https://docs.checkmk.com, https://www.postgresql.org/docs.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: ETL-Prozess mit Checkmk API und lokaler PostgreSQL-Datenbank.
- **Skalierbarkeit**: Automatisierte Datenintegration und Backups.
- **Lernwert**: Verständnis von ETL/ELT in einer lokalen Umgebung.

**Nächste Schritte**: Möchtest du eine Anleitung zu erweiterten Blue-Green Deployments, Log-Aggregation mit Fluentd, oder Integration mit einer Cloud-Datenbank (z. B. Cloud SQL)?

**Quellen**:
- Checkmk API-Dokumentation: https://docs.checkmk.com/latest/en/rest_api.html
- PostgreSQL-Dokumentation: https://www.postgresql.org/docs
- Webquellen:,,,,,
```