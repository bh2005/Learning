# Lernprojekt: Temperaturvorhersage mit BigQuery ML für Schüler

## Einführung

**BigQuery ML** ermöglicht die Erstellung und Ausführung von Machine Learning (ML)-Modellen direkt in Google BigQuery mit SQL, ohne Programmierkenntnisse in Python oder R. Dieses Lernprojekt führt Schüler in Machine Learning ein, indem es ein prädiktives Modell zur Vorhersage der durchschnittlichen monatlichen Temperatur in Berlin (basierend auf dem NOAA GSOD-Datensatz) erstellt. Es baut auf der vorherigen Anleitung (`04_gcp_bigquery_weather_analysis_project.md`) auf, die Wetterdatenanalysen mit BigQuery eingeführt hat, und nutzt die bestehende LAMP-Stack-VM (`lamp-vm`) und HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense). Das Projekt umfasst die Erstellung eines linearen Regressionsmodells, die Vorhersage von Temperaturen für 2025, die Visualisierung der Ergebnisse mit Google Data Studio und das Sichern der Ergebnisse in Google Cloud Storage und TrueNAS. Es ist schülerfreundlich und nutzt den GCP Free Tier sowie das $300-Aktionsguthaben.

**Voraussetzungen**:
- GCP-Konto mit aktiviertem Free Tier oder $300-Guthaben, Projekt `homelab-lamp` (Projekt-ID: z. B. `homelab-lamp-123456`).
- BigQuery-Dataset `weather_analysis` mit der Tabelle `berlin_temp_trends` (aus `04_gcp_bigquery_weather_analysis_project.md`).
- Grundkenntnisse in SQL (z. B. `SELECT`, `GROUP BY`) und Linux (z. B. aus dem LAMP-Stack-Setup).
- Optional: LAMP-Stack-VM (`lamp-vm`, Ubuntu 22.04 LTS, IP: z. B. `34.123.45.67`) mit Google Cloud SDK (`gcloud`) installiert, wie in `03_gcp_lamp_cloud_storage_backup_guide.md`.
- Google Cloud Storage Bucket (`homelab-lamp-backups`) für Ergebnisse und Backups.
- Optional: HomeLab mit TrueNAS (`192.168.30.100`) für zusätzliche Backups und OPNsense für Netzwerkverständnis.
- Browser für die GCP-Konsole (`https://console.cloud.google.com`) und Google Data Studio (`https://datastudio.google.com`).

**Ziele**:
- Verstehen von BigQuery ML und grundlegenden Machine Learning-Konzepten (z. B. lineare Regression, Training, Vorhersage).
- Erstellen eines ML-Modells zur Vorhersage der monatlichen Durchschnittstemperatur in Berlin.
- Visualisieren der Vorhersagen mit Google Data Studio.
- Sichern der Modell- und Vorhersagedaten in Google Cloud Storage und TrueNAS.
- Vergleich von Cloud-ML mit HomeLab-Datenanalysen (z. B. MariaDB).

**Hinweis**: BigQuery ML ist im Free Tier eingeschränkt (1 TB Abfragevolumen, 10 GB Speicher pro Monat), aber das $300-Guthaben ermöglicht Tests. Das NOAA GSOD-Dataset ist kostenlos.

**Quellen**:
- BigQuery ML-Dokumentation: https://cloud.google.com/bigquery-ml/docs
- NOAA GSOD-Datensatz: https://cloud.google.com/bigquery/public-data/noaa-gsod
- Google Data Studio-Dokumentation: https://support.google.com/datastudio
- Webquellen:,,,,,,,,,,,,,,

## Lernprojekt: Temperaturvorhersage mit BigQuery ML

### Projektübersicht
- **Datensatz**: NOAA Global Surface Summary of the Day (GSOD), `bigquery-public-data.noaa_gsod`, gefiltert für Berlin (Station `EDDI`, `100200`).
- **Aufgabe**: Erstelle ein lineares Regressionsmodell, um die durchschnittliche monatliche Temperatur in Berlin für 2025 basierend auf Daten von 2020–2024 vorherzusagen.
- **Tools**: BigQuery ML für Modelltraining, Google Data Studio für Visualisierung, Google Cloud Storage für Backups.
- **Ausgabe**: Vorhersagen für 2025, visualisiert als Zeitreihe, gesichert in Cloud Storage und TrueNAS.

### Schritt 1: BigQuery ML vorbereiten
1. **BigQuery ML aktivieren**:
   - BigQuery ML ist automatisch verfügbar, wenn die BigQuery API aktiviert ist (siehe `04_gcp_bigquery_weather_analysis_project.md`).
   - In der GCP-Konsole: `Navigation > BigQuery > SQL Workspace`.
   - Stelle sicher, dass das Projekt `homelab-lamp` und das Dataset `weather_analysis` ausgewählt sind.
2. **Datenbasis prüfen**:
   - Überprüfe die Tabelle `berlin_temp_trends` (aus dem vorherigen Projekt):
     ```sql
     SELECT * FROM `homelab-lamp.weather_analysis.berlin_temp_trends` LIMIT 10;
     ```
     - Erwartete Spalten: `year`, `month`, `avg_temp_celsius`.

**Tipp**: Falls `berlin_temp_trends` nicht existiert, erstelle sie wie in `04_gcp_bigquery_weather_analysis_project.md` beschrieben.

**Quelle**: https://cloud.google.com/bigquery-ml/docs/introduction

### Schritt 2: Lineares Regressionsmodell erstellen
1. **Modell trainieren**:
   - In der BigQuery-Konsole: `New Query`.
   - Gib die folgende SQL-Abfrage ein, um ein lineares Regressionsmodell zu erstellen:
     ```sql
     CREATE OR REPLACE MODEL `homelab-lamp.weather_analysis.berlin_temp_model`
     OPTIONS(
       model_type='linear_reg',
       input_label_cols=['avg_temp_celsius']
     ) AS
     SELECT
       year,
       month,
       avg_temp_celsius
     FROM
       `homelab-lamp.weather_analysis.berlin_temp_trends`
     WHERE
       year BETWEEN 2020 AND 2024;
     ```
   - Klicke auf „Run“ (Training dauert ~1–2 Minuten).
2. **Modell prüfen**:
   - In der BigQuery-Konsole: `weather_analysis > berlin_temp_model`.
   - Klicke auf „Details“ und überprüfe die Modellmetriken (z. B. RMSE, R²).
3. **Abfragekosten prüfen**:
   - In der Abfrageausgabe: Siehe „Query Details“ (z. B. „This query processed 100 MB“).
   - Stelle sicher, dass du im Free Tier-Limit (1 TB/Monat) bleibst.

**Tipp**: Lineare Regression ist ideal für Anfänger, da sie einfach zu verstehen ist und Trends in Zeitreihen gut modelliert.

**Quelle**: https://cloud.google.com/bigquery-ml/docs/reference/standard-sql/bigqueryml-syntax-create

### Schritt 3: Temperaturvorhersagen für 2025
1. **Vorhersagen erstellen**:
   - Erstelle eine Tabelle mit zukünftigen Monaten (2025) als Eingabe:
     ```sql
     CREATE OR REPLACE TABLE `homelab-lamp.weather_analysis.future_months_2025`
     AS
     SELECT
       2025 AS year,
       month
     FROM
       UNNEST(GENERATE_ARRAY(1, 12)) AS month;
     ```
   - Führe Vorhersagen durch:
     ```sql
     CREATE OR REPLACE TABLE `homelab-lamp.weather_analysis.berlin_temp_predictions_2025`
     AS
     SELECT
       year,
       month,
       predicted_avg_temp_celsius
     FROM
       ML.PREDICT(
         MODEL `homelab-lamp.weather_analysis.berlin_temp_model`,
         (
           SELECT
             year,
             month
           FROM
             `homelab-lamp.weather_analysis.future_months_2025`
         )
       );
     ```
   - Klicke auf „Run“.
2. **Vorhersagen prüfen**:
   ```sql
   SELECT * FROM `homelab-lamp.weather_analysis.berlin_temp_predictions_2025` ORDER BY month;
   ```
   - Erwartete Ausgabe: Jahr (2025), Monat (1–12), vorhergesagte Temperatur (`predicted_avg_temp_celsius`).

**Tipp**: Die Vorhersagen basieren auf historischen Trends. Für genauere Modelle könnten weitere Features (z. B. Niederschlag) hinzugefügt werden.

**Quelle**: https://cloud.google.com/bigquery-ml/docs/reference/standard-sql/bigqueryml-syntax-predict

### Schritt 4: Ergebnisse visualisieren mit Google Data Studio
1. **Google Data Studio öffnen**:
   - Gehe zu `https://datastudio.google.com`.
   - Melde dich mit deinem Google-Konto an.
2. **Neuen Bericht erstellen**:
   - Klicke auf „Create > Report“.
   - Wähle „Data Source > BigQuery“.
   - Verbinde dich mit:
     - Project: `homelab-lamp`.
     - Dataset: `weather_analysis`.
     - Table: `berlin_temp_predictions_2025`.
   - Klicke auf „Add to Report“.
3. **Diagramm erstellen**:
   - Wähle „Time Series“ (Zeitreihe).
   - Konfiguriere:
     - Dimension: `year`, `month` (kombiniere zu einem Datum).
     - Metric: `predicted_avg_temp_celsius`.
   - Style: Titel „Berlin Temperaturvorhersagen 2025“.
4. **Historische Daten hinzufügen** (optional):
   - Füge eine zweite Datenquelle hinzu: `weather_analysis.berlin_temp_trends`.
   - Erstelle ein kombiniertes Diagramm (historisch + Vorhersagen):
     - Metric: `avg_temp_celsius` (historisch), `predicted_avg_temp_celsius` (Vorhersagen).
5. **Bericht speichern und exportieren**:
   - Klicke auf „Save“.
   - Exportiere als PDF: `File > Download > PDF`.
   - Speichere lokal (z. B. `berlin_temp_predictions_2025.pdf`).

**Quelle**: https://support.google.com/datastudio/answer/6283323

### Schritt 5: Ergebnisse sichern
1. **Vorhersagen exportieren**:
   - In der BigQuery-Konsole: `weather_analysis > berlin_temp_predictions_2025 > Export > Export to Cloud Storage`.
   - Konfiguriere:
     - Bucket: `homelab-lamp-backups`.
     - Path: `results/berlin_temp_predictions_2025.csv`.
     - Format: `CSV`.
   - Klicke auf „Export“.
2. **PDF in Cloud Storage sichern**:
   - Auf der VM (falls verwendet):
     ```bash
     ssh ubuntu@34.123.45.67
     gsutil cp ~/berlin_temp_predictions_2025.pdf gs://homelab-lamp-backups/results/
     ```
   - Alternativ lokal hochladen:
     ```bash
     gsutil cp berlin_temp_predictions_2025.pdf gs://homelab-lamp-backups/results/
     ```
3. **Bucket-Inhalt prüfen**:
   ```bash
   gsutil ls gs://homelab-lamp-backups/results/
   ```
   - Erwartete Ausgabe:
     ```
     gs://homelab-lamp-backups/results/berlin_temp_predictions_2025.csv
     gs://homelab-lamp-backups/results/berlin_temp_predictions_2025.pdf
     ```

### Schritt 6: Integration mit HomeLab
1. **Backups auf TrueNAS sichern**:
   - Kopiere Ergebnisse auf TrueNAS:
     ```bash
     gsutil cp gs://homelab-lamp-backups/results/berlin_temp_predictions_2025.csv /home/ubuntu/
     gsutil cp gs://homelab-lamp-backups/results/berlin_temp_predictions_2025.pdf /home/ubuntu/
     rsync -av /home/ubuntu/berlin_temp_predictions_2025.* root@192.168.30.100:/mnt/tank/backups
     ```
   - Automatisiere im Backup-Skript (`/home/ubuntu/backup.sh` aus `03_gcp_lamp_cloud_storage_backup_guide.md`):
     ```bash
     # Am Ende des Skripts hinzufügen
     gsutil cp gs://homelab-lamp-backups/results/berlin_temp_predictions_2025.csv $BACKUP_DIR/
     gsutil cp gs://homelab-lamp-backups/results/berlin_temp_predictions_2025.pdf $BACKUP_DIR/
     rsync -av $BACKUP_DIR/berlin_temp_predictions_2025.* root@192.168.30.100:/mnt/tank/backups
     ```
2. **Vergleich mit OPNsense**:
   - HomeLab: OPNsense schützt TrueNAS mit Firewall-Regeln und Suricata IDS/IPS.
   - GCP: Simuliere OPNsense-Sicherheit durch IAM:
     - In der GCP-Konsole: `Cloud Storage > homelab-lamp-backups > Permissions`.
     - Rolle `Storage Object Viewer` nur für `lamp-backup-sa` und deine Google-Konto-E-Mail.
   - Überwache Zugriffe:
     ```bash
     gsutil logging get gs://homelab-lamp-backups
     ```
3. **Wiederherstellung testen**:
   - Lade die CSV-Datei herunter:
     ```bash
     gsutil cp gs://homelab-lamp-backups/results/berlin_temp_predictions_2025.csv /home/ubuntu/
     ```
   - Importiere in BigQuery:
     - In der BigQuery-Konsole: `weather_analysis > Create Table > Source: Upload File > berlin_temp_predictions_2025.csv`.

### Schritt 7: Erweiterung des Projekts
1. **Fortgeschrittenes Modell**:
   - Füge weitere Features hinzu (z. B. Niederschlag):
     ```sql
     CREATE OR REPLACE MODEL `homelab-lamp.weather_analysis.berlin_temp_model_advanced`
     OPTIONS(
       model_type='linear_reg',
       input_label_cols=['avg_temp_celsius']
     ) AS
     SELECT
       year,
       month,
       avg_temp_celsius,
       AVG(prcp) AS avg_precipitation
     FROM
       `bigquery-public-data.noaa_gsod.gsod*`
     WHERE
       stn = '100200' AND _TABLE_SUFFIX BETWEEN '2020' AND '2024'
     GROUP BY
       year, month;
     ```
   - Vorhersagen:
     ```sql
     CREATE OR REPLACE TABLE `homelab-lamp.weather_analysis.berlin_temp_predictions_2025_advanced`
     AS
     SELECT
       year,
       month,
       predicted_avg_temp_celsius
     FROM
       ML.PREDICT(
         MODEL `homelab-lamp.weather_analysis.berlin_temp_model_advanced`,
         (
           SELECT
             2025 AS year,
             month,
             0 AS avg_precipitation -- Placeholder
           FROM
             UNNEST(GENERATE_ARRAY(1, 12)) AS month
         )
       );
     ```
2. **Modellbewertung**:
   - Bewerte die Modellgenauigkeit:
     ```sql
     SELECT * FROM ML.EVALUATE(MODEL `homelab-lamp.weather_analysis.berlin_temp_model`);
     ```
   - Analysiere Metriken wie `mean_absolute_error` und `r2_score`.
3. **Automatisierung**:
   - Erstelle ein Skript für monatliches Training:
     ```bash
     nano /home/ubuntu/train_weather_model.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       DATE=$(date +%F)
       bq query --destination_table=homelab-lamp:weather_analysis.berlin_temp_predictions_$DATE \
       "SELECT year, month, predicted_avg_temp_celsius
        FROM ML.PREDICT(
          MODEL \`homelab-lamp.weather_analysis.berlin_temp_model\`,
          (SELECT 2025 AS year, month
           FROM UNNEST(GENERATE_ARRAY(1, 12)) AS month)
        );"
       bq extract weather_analysis.berlin_temp_predictions_$DATE gs://homelab-lamp-backups/results/berlin_temp_predictions_$DATE.csv
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /home/ubuntu/train_weather_model.sh
       ```
     - Cron-Job (monatlich, am 1. um 03:00):
       ```bash
       crontab -e
       0 3 1 * * /home/ubuntu/train_weather_model.sh
       ```

## Best Practices für Schüler

- **Kostenmanagement**:
  - Bleibe im Free Tier (1 TB Abfragevolumen, 10 GB Speicher).
  - Überwache Kosten: `BigQuery > Query History > Details`.
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
    /home/ubuntu/train_weather_model.sh
    sudo tail -f /var/log/syslog | grep CRON
    ```
- **Lernziele**:
  - Verstehe Machine Learning-Konzepte (z. B. lineare Regression, Features, Vorhersagen).
  - Vergleiche Cloud-ML (BigQuery ML) mit lokalen Datenanalysen (MariaDB im HomeLab).
  - Übe SQL für ML und Visualisierung.
- **Backup-Strategie**:
  - Implementiere die 3-2-1-Regel:
    - 3 Kopien: BigQuery-Tabellen, Cloud Storage, TrueNAS.
    - 2 Medien: GCP Persistent Disk, TrueNAS HDD.
    - 1 Off-Site: Google Cloud Storage.

**Quelle**: https://cloud.google.com/bigquery-ml/docs/best-practices

## Empfehlungen für Schüler

- **Setup**:
  - **BigQuery ML**: Modell `berlin_temp_model` in `weather_analysis`, Vorhersagen in `berlin_temp_predictions_2025`.
  - **Cloud Storage**: Bucket `homelab-lamp-backups` für Ergebnisse.
  - **Workloads**: Vorhersage von Temperaturtrends, Visualisierung mit Data Studio.
- **Integration**:
  - GCP: Nutze Free Tier (1 TB Abfragen) und $300-Guthaben für Tests.
  - HomeLab: Sichere Ergebnisse auf TrueNAS (`/mnt/tank/backups`).
- **Beispiel**:
  - Vorhersagen der monatlichen Temperaturen für Berlin 2025, visualisiert als Zeitreihe, gesichert in Cloud Storage und TrueNAS.

## Tipps für den Erfolg

- **Free Tier**: Nutze öffentliche Datensätze wie NOAA GSOD, um Kosten zu minimieren.
- **ML-Übung**: Experimentiere mit anderen Modellen (z. B. ARIMA für Zeitreihen).
- **Visualisierung**: Passe Data Studio-Berichte an (z. B. Farben, Vergleich historisch vs. Vorhersagen).
- **Lernressourcen**: Nutze https://cloud.google.com/bigquery-ml/docs und Qwiklabs (https://www.qwiklabs.com).
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`) für Referenz.

## Fazit

Dieses Lernprojekt mit BigQuery ML bietet:
- **Praxisorientiert**: Einfaches ML-Modell zur Temperaturvorhersage mit SQL.
- **Einfachheit**: Free Tier und BigQuery ML erleichtern den Einstieg in Machine Learning.
- **Lernwert**: Verständnis von ML, Big Data und Integration mit HomeLab-Konzepten.

Es ist ideal für Schüler, die Cloud Computing und Machine Learning lernen möchten, und verbindet GCP-Konzepte mit HomeLab-Erfahrungen (z. B. TrueNAS-Backups).

**Nächste Schritte**: Möchtest du eine Anleitung zu Kubernetes für skalierbare Webanwendungen, zu Monitoring mit Zabbix/Prometheus oder zu anderen BigQuery ML-Modellen (z. B. Klassifikation)?

**Quellen**:
- BigQuery ML-Dokumentation: https://cloud.google.com/bigquery-ml/docs
- NOAA GSOD-Datensatz: https://cloud.google.com/bigquery/public-data/noaa-gsod
- Google Data Studio-Dokumentation: https://support.google.com/datastudio
- Webquellen:,,,,,,,,,,,,,,