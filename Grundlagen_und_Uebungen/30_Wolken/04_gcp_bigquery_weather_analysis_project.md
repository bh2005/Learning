# Lernprojekt: Wetterdatenanalyse mit Google BigQuery für Schüler

## Einführung

**Google BigQuery** ist ein serverloses, skalierbares Data-Warehouse in der Google Cloud Platform (GCP), das SQL-Abfragen für die Analyse großer Datensätze ermöglicht. Dieses Lernprojekt führt Schüler in Big Data und Cloud-basierte Datenanalyse ein, indem es die Analyse eines öffentlichen Wetterdatensatzes (NOAA GSOD) mit BigQuery demonstriert. Es baut auf den vorherigen Anleitungen (`01_gcp_cloud_computing_intro_guide.md`, `02_gcp_lamp_letsencrypt_guide.md`, `03_gcp_lamp_cloud_storage_backup_guide.md`) auf, die eine LAMP-Stack-VM und Backups auf GCP eingerichtet haben. Das Projekt umfasst die Einrichtung eines BigQuery-Datasets, das Laden von Wetterdaten, das Erstellen von SQL-Abfragen zur Analyse von Temperaturtrends und die Visualisierung der Ergebnisse mit Google Data Studio. Es integriert optional die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense) für Backups und ist für Schüler mit Grundkenntnissen in Linux, SQL und GCP geeignet.

**Voraussetzungen**:
- GCP-Konto mit aktiviertem Free Tier oder $300-Aktionsguthaben, Projekt `homelab-lamp` (Projekt-ID: z. B. `homelab-lamp-123456`).
- Grundkenntnisse in SQL (z. B. `SELECT`, `GROUP BY`) und Linux (z. B. aus dem LAMP-Stack-Setup).
- Optional: LAMP-Stack-VM (`lamp-vm`, Ubuntu 22.04 LTS, IP: z. B. `34.123.45.67`) mit Google Cloud SDK (`gcloud`) installiert, wie in `03_gcp_lamp_cloud_storage_backup_guide.md`.
- Google Cloud Storage Bucket (`homelab-lamp-backups`) für Zwischenspeicherung und Backups.
- Optional: HomeLab mit TrueNAS (`192.168.30.100`) für zusätzliche Backups und OPNsense für Netzwerkverständnis.
- Browser für die GCP-Konsole (`https://console.cloud.google.com`) und Google Data Studio (`https://datastudio.google.com`).

**Ziele**:
- Verstehen von BigQuery und Big Data-Konzepten (z. B. Data-Warehouse, SQL-Abfragen).
- Einrichten eines BigQuery-Datasets und Laden eines öffentlichen Wetterdatensatzes.
- Analysieren von Temperaturtrends mit SQL-Abfragen.
- Visualisieren der Ergebnisse mit Google Data Studio.
- Sichern der Analyseergebnisse in Google Cloud Storage und optional auf TrueNAS.

**Hinweis**: BigQuery bietet im Free Tier 10 GB Speicher und 1 TB Abfragevolumen pro Monat, ideal für Lernprojekte. Das $300-Guthaben ermöglicht zusätzliche Experimente.

**Quellen**:
- BigQuery-Dokumentation: https://cloud.google.com/bigquery/docs
- NOAA GSOD-Datensatz: https://cloud.google.com/bigquery/public-data/noaa-gsod
- Google Data Studio-Dokumentation: https://support.google.com/datastudio
- Webquellen:,,,,,,,,,,,,,,

## Lernprojekt: Analyse von Wetterdaten

### Projektübersicht
- **Datensatz**: NOAA Global Surface Summary of the Day (GSOD), verfügbar in BigQuery als öffentlicher Datensatz (`bigquery-public-data.noaa_gsod`).
- **Aufgabe**: Analysiere die durchschnittlichen Temperaturtrends (in °C) für eine Stadt (z. B. Berlin) von 2020 bis 2024.
- **Tools**: BigQuery für Datenanalyse, Google Data Studio für Visualisierung, Google Cloud Storage für Backups.
- **Ausgabe**: Ein Diagramm mit monatlichen Temperaturtrends und ein exportierter Bericht.

### Schritt 1: BigQuery einrichten
1. **BigQuery API aktivieren**:
   - Öffne die GCP-Konsole: `https://console.cloud.google.com`.
   - Gehe zu `APIs & Services > Library`.
   - Suche nach „BigQuery API“ und klicke auf „Aktivieren“ (dauert ~1 Minute).
2. **BigQuery-Dataset erstellen**:
   - In der GCP-Konsole: `Navigation > BigQuery > SQL Workspace`.
   - Wähle das Projekt `homelab-lamp` (links im Explorer).
   - Klicke auf „Create Dataset“.
   - Konfiguriere:
     - Dataset ID: `weather_analysis`.
     - Location: `europe-west1` (für Konsistenz mit VM und Bucket).
     - Default Table Expiration: Deaktiviere (für Lernprojekte nicht nötig).
   - Klicke auf „Create Dataset“.
3. **Öffentlichen Datensatz prüfen**:
   - In der BigQuery-Konsole: Suche im Explorer nach `bigquery-public-data`.
   - Erweitere `bigquery-public-data > noaa_gsod`.
   - Stelle sicher, dass Tabellen wie `gsod2020`, `gsod2021`, `gsod2022`, `gsod2023`, `gsod2024` verfügbar sind.

**Tipp**: Der NOAA GSOD-Datensatz ist kostenlos zugänglich, aber Abfragen zählen zum 1 TB Free Tier-Limit.

**Quelle**: https://cloud.google.com/bigquery/docs/public-datasets

### Schritt 2: Wetterdaten analysieren
1. **SQL-Abfrage für Temperaturtrends**:
   - In der BigQuery-Konsole: `New Query`.
   - Gib die folgende Abfrage ein, um die durchschnittliche Temperatur in Berlin (Station `EDDI`, Berlin-Tempelhof) pro Monat von 2020 bis 2024 zu berechnen:
     ```sql
     SELECT
       EXTRACT(YEAR FROM date) AS year,
       EXTRACT(MONTH FROM date) AS month,
       AVG(temp) AS avg_temp_celsius
     FROM
       `bigquery-public-data.noaa_gsod.gsod*`
     WHERE
       stn = '100200' -- Berlin-Tempelhof
       AND _TABLE_SUFFIX BETWEEN '2020' AND '2024'
     GROUP BY
       year, month
     ORDER BY
       year, month;
     ```
   - Klicke auf „Run“.
   - Ergebnisse: Eine Tabelle mit Jahr, Monat und durchschnittlicher Temperatur (in °C).
2. **Ergebnisse speichern**:
   - Klicke auf „Save Results > BigQuery Table“.
   - Konfiguriere:
     - Project: `homelab-lamp`.
     - Dataset: `weather_analysis`.
     - Table: `berlin_temp_trends`.
   - Klicke auf „Save“.
3. **Abfragekosten prüfen**:
   - In der Abfrageausgabe: Siehe „Query Details“ (z. B. „This query processed 1.2 GB“).
   - Stelle sicher, dass du im Free Tier-Limit (1 TB/Monat) bleibst.

**Tipp**: Nutze die Spalte `temp` (in Fahrenheit) und konvertiere sie bei Bedarf in Celsius: `(temp - 32) * 5/9`.

**Quelle**: https://cloud.google.com/bigquery/docs/querying-data

### Schritt 3: Ergebnisse visualisieren mit Google Data Studio
1. **Google Data Studio öffnen**:
   - Gehe zu `https://datastudio.google.com`.
   - Melde dich mit deinem Google-Konto an.
2. **Neuen Bericht erstellen**:
   - Klicke auf „Create > Report“.
   - Wähle „Data Source > BigQuery“.
   - Verbinde dich mit:
     - Project: `homelab-lamp`.
     - Dataset: `weather_analysis`.
     - Table: `berlin_temp_trends`.
   - Klicke auf „Add to Report“.
3. **Diagramm erstellen**:
   - Wähle „Time Series“ (Zeitreihe).
   - Konfiguriere:
     - Dimension: `year`, `month` (kombiniere zu einem Datum).
     - Metric: `avg_temp_celsius`.
   - Style: Passe Farben und Titel an (z. B. „Berlin Temperaturtrends 2020–2024“).
4. **Bericht speichern und teilen**:
   - Klicke auf „Save“.
   - Optional: Klicke auf „Share“ und erstelle einen öffentlichen Link (für Lernzwecke).
5. **PDF exportieren**:
   - Klicke auf „File > Download > PDF“.
   - Speichere die Datei lokal (z. B. `berlin_temp_trends.pdf`).

**Quelle**: https://support.google.com/datastudio/answer/6283323

### Schritt 4: Ergebnisse sichern
1. **BigQuery-Tabelle exportieren**:
   - In der BigQuery-Konsole: `weather_analysis > berlin_temp_trends > Export > Export to Cloud Storage`.
   - Konfiguriere:
     - Bucket: `homelab-lamp-backups`.
     - Path: `results/berlin_temp_trends.csv`.
     - Format: `CSV`.
   - Klicke auf „Export“.
2. **PDF in Cloud Storage sichern**:
   - Lade das PDF hoch:
     ```bash
     gsutil cp ~/berlin_temp_trends.pdf gs://homelab-lamp-backups/results/
     ```
     - Falls die LAMP-VM (`lamp-vm`) verwendet wird:
       ```bash
       ssh ubuntu@34.123.45.67
       gsutil cp ~/berlin_temp_trends.pdf gs://homelab-lamp-backups/results/
       ```
3. **Bucket-Inhalt prüfen**:
   ```bash
   gsutil ls gs://homelab-lamp-backups/results/
   ```
   - Erwartete Ausgabe:
     ```
     gs://homelab-lamp-backups/results/berlin_temp_trends.csv
     gs://homelab-lamp-backups/results/berlin_temp_trends.pdf
     ```

### Schritt 5: Integration mit HomeLab
1. **Backups auf TrueNAS sichern**:
   - Kopiere Ergebnisse von Google Cloud Storage auf TrueNAS:
     ```bash
     gsutil cp gs://homelab-lamp-backups/results/berlin_temp_trends.csv /home/ubuntu/
     gsutil cp gs://homelab-lamp-backups/results/berlin_temp_trends.pdf /home/ubuntu/
     rsync -av /home/ubuntu/berlin_temp_trends.* root@192.168.30.100:/mnt/tank/backups
     ```
   - Automatisiere im Backup-Skript (`/home/ubuntu/backup.sh` aus `03_gcp_lamp_cloud_storage_backup_guide.md`):
     ```bash
     # Am Ende des Skripts hinzufügen
     gsutil cp gs://homelab-lamp-backups/results/berlin_temp_trends.csv $BACKUP_DIR/
     gsutil cp gs://homelab-lamp-backups/results/berlin_temp_trends.pdf $BACKUP_DIR/
     rsync -av $BACKUP_DIR/berlin_temp_trends.* root@192.168.30.100:/mnt/tank/backups
     ```
2. **Vergleich mit OPNsense**:
   - HomeLab: OPNsense schützt TrueNAS mit Firewall-Regeln und Suricata IDS/IPS.
   - GCP: Simuliere OPNsense-Sicherheit, indem du den Bucket-Zugriff einschränkst:
     - In der GCP-Konsole: `Cloud Storage > homelab-lamp-backups > Permissions`.
     - Rolle `Storage Object Viewer` nur für `lamp-backup-sa` und deine Google-Konto-E-Mail.
   - Überwache Zugriffe:
     ```bash
     gsutil logging get gs://homelab-lamp-backups
     ```
3. **Wiederherstellung testen**:
   - Lade die CSV-Datei herunter:
     ```bash
     gsutil cp gs://homelab-lamp-backups/results/berlin_temp_trends.csv /home/ubuntu/
     ```
   - Importiere in BigQuery (falls nötig):
     - In der BigQuery-Konsole: `weather_analysis > Create Table > Source: Upload File > berlin_temp_trends.csv`.

### Schritt 6: Erweiterung des Projekts
1. **Zusätzliche Abfragen**:
   - Analysiere die jährliche Höchsttemperatur:
     ```sql
     SELECT
       EXTRACT(YEAR FROM date) AS year,
       MAX(temp) AS max_temp_celsius
     FROM
       `bigquery-public-data.noaa_gsod.gsod*`
     WHERE
       stn = '100200' -- Berlin-Tempelhof
       AND _TABLE_SUFFIX BETWEEN '2020' AND '2024'
     GROUP BY
       year
     ORDER BY
       year;
     ```
   - Speichere als `berlin_max_temp` in `weather_analysis`.
2. **Visualisierung erweitern**:
   - Füge `berlin_max_temp` als weitere Datenquelle in Google Data Studio hinzu.
   - Erstelle ein Säulendiagramm für jährliche Höchsttemperaturen.
3. **Automatisierung**:
   - Erstelle ein Skript für regelmäßige Abfragen:
     ```bash
     nano /home/ubuntu/run_weather_query.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       DATE=$(date +%F)
       bq query --destination_table=homelab-lamp:weather_analysis.berlin_temp_trends_$DATE \
       "SELECT EXTRACT(YEAR FROM date) AS year, EXTRACT(MONTH FROM date) AS month, AVG(temp) AS avg_temp_celsius
        FROM \`bigquery-public-data.noaa_gsod.gsod*\`
        WHERE stn = '100200' AND _TABLE_SUFFIX BETWEEN '2020' AND '2024'
        GROUP BY year, month
        ORDER BY year, month;"
       bq extract weather_analysis.berlin_temp_trends_$DATE gs://homelab-lamp-backups/results/berlin_temp_trends_$DATE.csv
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /home/ubuntu/run_weather_query.sh
       ```
     - Cron-Job hinzufügen (monatlich, am 1. um 03:00):
       ```bash
       crontab -e
       0 3 1 * * /home/ubuntu/run_weather_query.sh
       ```

## Best Practices für Schüler

- **Kostenmanagement**:
  - Bleibe im Free Tier (1 TB Abfragevolumen, 10 GB Speicher).
  - Überwache Abfragekosten: `BigQuery > Query History > Details`.
  - Setze ein Budget-Alarm: `Billing > Budgets & Alerts > Create Budget`.
- **Sicherheit**:
  - Schränke Bucket-Zugriff ein:
    ```bash
    gsutil iam ch allUsers:legacyObjectReader gs://homelab-lamp-backups
    ```
  - Verwende Servicekonten (`lamp-backup-sa`) für Skripte.
- **Automatisierung**:
  - Teste Skripte und Cron-Jobs:
    ```bash
    /home/ubuntu/run_weather_query.sh
    sudo tail -f /var/log/syslog | grep CRON
    ```
- **Lernziele**:
  - Verstehe Data-Warehouse-Konzepte (Spaltenorientierte Speicherung, skalierbare Abfragen).
  - Vergleiche Cloud-Analyse (BigQuery) mit HomeLab-Datenbanken (MariaDB).
  - Übe SQL-Abfragen und Visualisierung.
- **Backup-Strategie**:
  - Implementiere die 3-2-1-Regel:
    - 3 Kopien: BigQuery-Tabellen, Cloud Storage, TrueNAS.
    - 2 Medien: GCP Persistent Disk, TrueNAS HDD.
    - 1 Off-Site: Google Cloud Storage.

**Quelle**: https://cloud.google.com/bigquery/docs/best-practices-costs

## Empfehlungen für Schüler

- **Setup**:
  - **BigQuery**: Dataset `weather_analysis` in `europe-west1`.
  - **Cloud Storage**: Bucket `homelab-lamp-backups` für Ergebnisse.
  - **Workloads**: Analyse von NOAA GSOD-Daten, Visualisierung mit Data Studio.
- **Integration**:
  - GCP: Nutze Free Tier (1 TB Abfragen) und $300-Guthaben für Tests.
  - HomeLab: Sichere Ergebnisse auf TrueNAS (`/mnt/tank/backups`).
- **Beispiel**:
  - Monatliche Temperaturtrends für Berlin, visualisiert als Zeitreihe, gesichert in Cloud Storage und TrueNAS.

## Tipps für den Erfolg

- **Free Tier**: Nutze öffentliche Datensätze wie NOAA GSOD, um Kosten zu minimieren.
- **SQL-Übung**: Experimentiere mit weiteren Abfragen (z. B. Niederschlag, Windgeschwindigkeit).
- **Visualisierung**: Passe Data Studio-Berichte an (z. B. Farben, Filter).
- **Lernressourcen**: Nutze https://cloud.google.com/bigquery/docs und Qwiklabs (https://www.qwiklabs.com).
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`) für Referenz.

## Fazit

Dieses Lernprojekt mit BigQuery bietet:
- **Praxisorientiert**: Analyse echter Wetterdaten mit SQL und Visualisierung.
- **Einfachheit**: Free Tier und öffentliche Datensätze erleichtern den Einstieg.
- **Lernwert**: Verständnis von Big Data, Data-Warehouse und Cloud-Integration.

Es ist ideal für Schüler, die Cloud Computing und Datenanalyse lernen möchten, und verbindet GCP-Konzepte mit HomeLab-Erfahrungen (z. B. TrueNAS-Backups).

**Nächste Schritte**: Möchtest du eine Anleitung zu Kubernetes für skalierbare Webanwendungen, zu Monitoring mit Zabbix/Prometheus oder zu fortgeschrittenen BigQuery-Features (z. B. Machine Learning mit BigQuery ML)?

**Quellen**:
- BigQuery-Dokumentation: https://cloud.google.com/bigquery/docs
- NOAA GSOD-Datensatz: https://cloud.google.com/bigquery/public-data/noaa-gsod
- Google Data Studio-Dokumentation: https://support.google.com/datastudio
- Webquellen:,,,,,,,,,,,,,,