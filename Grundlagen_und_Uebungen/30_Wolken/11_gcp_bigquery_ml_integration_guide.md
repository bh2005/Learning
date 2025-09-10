# Lernprojekt: Integration von BigQuery ML mit Microservices auf GCP

## Einführung

**BigQuery ML** ermöglicht maschinelles Lernen direkt in Google BigQuery, ohne Datenextraktion, und eignet sich ideal für die Integration mit Microservices für datengetriebene Anwendungen. Dieses Lernprojekt baut auf `gcp_cicd_microservices_guide.md` () und `gcp_prometheus_checkmk_monitoring_guide.md` () auf, indem es BigQuery ML in eine Microservices-Anwendung integriert, die auf **Google Kubernetes Engine (GKE)** läuft. Es ist für Lernende mit Grundkenntnissen in Python, SQL, Kubernetes und GCP geeignet und nutzt die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense) für Backups. Das Projekt umfasst drei Übungen: Erstellung eines ML-Modells in BigQuery, Integration mit einem Backend-Microservice, und Monitoring der Vorhersagen mit Prometheus und Checkmk. Es nutzt den GCP Free Tier und ist lokal sowie datenschutzfreundlich.

**Voraussetzungen**:
- GCP-Konto mit aktiviertem Free Tier oder $300-Guthaben, Projekt `homelab-lamp` (Projekt-ID: z. B. `homelab-lamp-123456`).
- GKE-Cluster `homelab-microservices` mit Microservices (Frontend und Backend aus `gcp_cicd_microservices_guide.md`).
- Prometheus und Checkmk installiert (siehe `gcp_prometheus_checkmk_monitoring_guide.md`).
- Ubuntu-VM auf Proxmox (IP `192.168.30.101`) mit Checkmk Raw Edition.
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement.
- Google Cloud SDK (`gcloud`), `kubectl`, und Python 3 installiert.
- Grundkenntnisse in BigQuery, SQL, und Microservices.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`).

**Ziele**:
- Erstellung eines ML-Modells in BigQuery für Vorhersagen (z. B. Temperaturprognosen).
- Integration des Modells in einen Backend-Microservice auf GKE.
- Monitoring der Vorhersagen mit Prometheus und Checkmk.
- Integration mit HomeLab für Backups.

**Hinweis**: BigQuery ML ermöglicht ML direkt in der Datenbank, ideal für datenintensive Microservices.

**Quellen**:
- BigQuery ML-Dokumentation: https://cloud.google.com/bigquery-ml/docs
- GKE-Dokumentation: https://cloud.google.com/kubernetes-engine/docs
- Prometheus-Dokumentation: https://prometheus.io/docs
- Checkmk-Dokumentation: https://docs.checkmk.com
- Webquellen:,,,,,

## Lernprojekt: BigQuery ML Integration

### Vorbereitung: Umgebung einrichten
1. **GCP-Umgebung prüfen**:
   - Stelle sicher, dass das GCP-Projekt aktiv ist:
     ```bash
     gcloud config set project homelab-lamp-123456
     ```
   - Prüfe GKE-Cluster:
     ```bash
     gcloud container clusters get-credentials homelab-microservices --zone europe-west1-b
     kubectl get pods
     ```
     - Erwartete Ausgabe: Pods wie `frontend-deployment-xxx`, `backend-deployment-xxx`.
   - Prüfe BigQuery:
     ```bash
     bq show homelab-lamp:weather_analysis
     ```
     - Stelle sicher, dass ein Dataset `weather_analysis` existiert (falls nicht, erstelle es in Übung 1).
2. **Checkmk und Prometheus prüfen**:
   - Verbinde dich mit der Ubuntu-VM:
     ```bash
     ssh ubuntu@192.168.30.101
     ```
   - Prüfe Checkmk:
     ```bash
     curl http://192.168.30.101:5000/homelab
     ```
   - Prüfe Prometheus/Grafana:
     ```bash
     kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
     ```
     - Öffne `http://localhost:3000`.
3. **Projektverzeichnis erstellen**:
   ```bash
   mkdir ~/bigquery-ml-integration
   cd ~/bigquery-ml-integration
   ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf GKE und TrueNAS.

### Übung 1: Erstellung eines ML-Modells in BigQuery

**Ziel**: Erstelle ein lineares Regressionsmodell in BigQuery ML für Temperaturvorhersagen.

**Aufgabe**: Lade Wetterdaten, trainiere ein Modell und teste Vorhersagen.

1. **Dataset und Tabelle erstellen**:
   - Erstelle ein Dataset:
     ```bash
     bq mk --dataset homelab-lamp:weather_analysis
     ```
   - Erstelle eine Tabelle mit Beispieldaten:
     ```bash
     nano weather_data.csv
     ```
     - Inhalt:
       ```
       year,month,avg_temp_celsius
       2023,1,2.0
       2023,2,3.5
       2023,3,5.8
       2024,1,2.2
       2024,2,3.7
       2024,3,6.0
       ```
   - Lade die Daten:
     ```bash
     bq load --source_format=CSV --autodetect weather_analysis.berlin_weather weather_data.csv
     ```

2. **Modell trainieren**:
   - Erstelle ein lineares Regressionsmodell:
     ```bash
     bq query --use_legacy_sql=false \
     'CREATE OR REPLACE MODEL `homelab-lamp.weather_analysis.temp_prediction_model`
      OPTIONS(model_type="linear_reg", input_label_cols=["avg_temp_celsius"])
      AS
      SELECT year, month, avg_temp_celsius
      FROM `homelab-lamp.weather_analysis.berlin_weather`'
     ```

3. **Vorhersagen testen**:
   - Teste das Modell:
     ```bash
     bq query --use_legacy_sql=false \
     'SELECT *
      FROM ML.PREDICT(MODEL `homelab-lamp.weather_analysis.temp_prediction_model`,
        (SELECT 2025 AS year, 1 AS month UNION ALL
         SELECT 2025, 2 UNION ALL
         SELECT 2025, 3))'
     ```
     - Erwartete Ausgabe:
       ```
       +------+-------+--------------------------+
       | year | month | predicted_avg_temp_celsius |
       +------+-------+--------------------------+
       | 2025 |     1 |                     2.25 |
       | 2025 |     2 |                     3.65 |
       | 2025 |     3 |                     6.10 |
       +------+-------+--------------------------+
       ```

**Erkenntnis**: BigQuery ML ermöglicht schnelles Training und Vorhersagen direkt in der Datenbank.

**Quelle**: https://cloud.google.com/bigquery-ml/docs

### Übung 2: Integration mit Backend-Microservice

**Ziel**: Integriere das BigQuery ML-Modell in den Backend-Microservice auf GKE.

**Aufgabe**: Erweitere den Backend-Microservice, um Temperaturvorhersagen über eine API bereitzustellen.

1. **Backend aktualisieren**:
   - Aktualisiere `backend/server.js` (aus `gcp_cicd_microservices_guide.md`):
     ```bash
     nano backend/server.js
     ```
     - Inhalt:
       ```javascript
       const express = require('express');
       const { BigQuery } = require('@google-cloud/bigquery');
       const prom = require('prom-client');
       const app = express();

       const collectDefaultMetrics = prom.collectDefaultMetrics;
       collectDefaultMetrics();
       const bigqueryClient = new BigQuery({ projectId: 'homelab-lamp' });

       app.get('/metrics', async (req, res) => res.send(await prom.register.metrics()));
       app.get('/api/data', (req, res) => res.json({ message: 'Backend Data' }));
       app.get('/api/predict-temperature', async (req, res) => {
         const query = `
           SELECT *
           FROM ML.PREDICT(MODEL \`homelab-lamp.weather_analysis.temp_prediction_model\`,
             (SELECT @year AS year, @month AS month))`;
         const options = {
           query: query,
           params: { year: parseInt(req.query.year), month: parseInt(req.query.month) }
         };
         const [rows] = await bigqueryClient.query(options);
         res.json({ prediction: rows[0] });
       });
       app.listen(3001, () => console.log('Backend on port 3001'));
       ```
   - Aktualisiere `backend/package.json`:
     ```json
     {
       "name": "backend",
       "version": "1.0.0",
       "main": "server.js",
       "dependencies": {
         "express": "^4.18.2",
         "prom-client": "^14.2.0",
         "@google-cloud/bigquery": "^6.2.0"
       }
     }
     ```
   - Aktualisiere `backend/Dockerfile`:
     ```dockerfile
     FROM node:18-alpine
     WORKDIR /app
     COPY package*.json ./
     RUN npm install
     COPY . .
     EXPOSE 3001
     CMD ["node", "server.js"]
     ```

2. **Servicekonto für BigQuery**:
   - Erstelle ein Servicekonto:
     - In der GCP-Konsole: `IAM & Admin > Service Accounts > Create Service Account`.
     - Name: `bigquery-access`.
     - Rolle: `BigQuery Data Viewer`, `BigQuery Job User`.
     - Lade den JSON-Schlüssel herunter (z. B. `bigquery-key.json`).
   - Setze Umgebungsvariablen in GKE:
     ```bash
     kubectl create secret generic bigquery-key --from-file=key.json=bigquery-key.json
     ```
   - Aktualisiere `backend-deployment.yaml`:
     ```yaml
     apiVersion: apps/v1
     kind: Deployment
     metadata:
       name: backend-deployment
     spec:
       replicas: 2
       selector:
         matchLabels:
           app: backend
       template:
         metadata:
           labels:
             app: backend
         spec:
           containers:
           - name: backend
             image: gcr.io/homelab-lamp/backend:v3
             ports:
             - containerPort: 3001
             env:
             - name: GOOGLE_APPLICATION_CREDENTIALS
               value: /app/key.json
             volumeMounts:
             - name: bigquery-key
               mountPath: "/app"
               readOnly: true
           volumes:
           - name: bigquery-key
             secret:
               secretName: bigquery-key
     ---
     apiVersion: v1
     kind: Service
     metadata:
       name: backend-service
     spec:
       selector:
         app: backend
       ports:
       - name: web
         protocol: TCP
         port: 3001
         targetPort: 3001
       type: ClusterIP
     ```

3. **Build, Push und Deploy**:
   ```bash
   docker build -t gcr.io/homelab-lamp/backend:v3 ./backend
   docker push gcr.io/homelab-lamp/backend:v3
   kubectl apply -f backend-deployment.yaml
   ```

4. **API testen**:
   - Port-Forwarding für Backend:
     ```bash
     kubectl port-forward svc/backend-service 3001:3001
     ```
   - Teste:
     ```bash
     curl http://localhost:3001/api/predict-temperature?year=2025&month=1
     ```
     - Erwartete Ausgabe:
       ```json
       { "prediction": { "year": 2025, "month": 1, "predicted_avg_temp_celsius": 2.25 } }
       ```

**Erkenntnis**: BigQuery ML lässt sich nahtlos in Microservices integrieren, um datengetriebene APIs bereitzustellen.

**Quelle**: https://cloud.google.com/bigquery-ml/docs

### Übung 3: Monitoring der Vorhersagen mit Prometheus und Checkmk

**Ziel**: Überwache BigQuery ML-Vorhersagen und Backend-Performance mit Prometheus und Checkmk.

**Aufgabe**: Konfiguriere Prometheus für API-Metriken und Checkmk für Service-Checks.

1. **Prometheus-Metriken erweitern**:
   - Aktualisiere `backend/server.js` für benutzerdefinierte Metriken:
     ```javascript
     const express = require('express');
     const { BigQuery } = require('@google-cloud/bigquery');
     const prom = require('prom-client');
     const app = express();

     const collectDefaultMetrics = prom.collectDefaultMetrics;
     collectDefaultMetrics();
     const bigqueryClient = new BigQuery({ projectId: 'homelab-lamp' });
     const predictionCounter = new prom.Counter({
       name: 'temperature_predictions_total',
       help: 'Total number of temperature predictions'
     });

     app.get('/metrics', async (req, res) => res.send(await prom.register.metrics()));
     app.get('/api/data', (req, res) => res.json({ message: 'Backend Data' }));
     app.get('/api/predict-temperature', async (req, res) => {
       const query = `
         SELECT *
         FROM ML.PREDICT(MODEL \`homelab-lamp.weather_analysis.temp_prediction_model\`,
           (SELECT @year AS year, @month AS month))`;
       const options = {
         query: query,
         params: { year: parseInt(req.query.year), month: parseInt(req.query.month) }
       };
       const [rows] = await bigqueryClient.query(options);
       predictionCounter.inc();
       res.json({ prediction: rows[0] });
     });
     app.listen(3001, () => console.log('Backend on port 3001'));
     ```
   - Rebuild und redeploy:
     ```bash
     docker build -t gcr.io/homelab-lamp/backend:v4 ./backend
     docker push gcr.io/homelab-lamp/backend:v4
     sed -i 's/v3/v4/' backend-deployment.yaml
     kubectl apply -f backend-deployment.yaml
     ```

2. **Prometheus-Metriken in Grafana visualisieren**:
   - Öffne Grafana: `kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80`.
   - Gehe zu `http://localhost:3000`.
   - Erstelle ein Dashboard:
     - Gehe zu `Dashboards > New > New Dashboard`.
     - Füge ein Panel hinzu:
       - Metrik: `temperature_predictions_total`.
       - Titel: `Total Temperature Predictions`.
     - Speichere als `BigQuery ML Dashboard`.
   - Prüfe:
     - Generiere Vorhersagen:
       ```bash
       curl http://localhost:3001/api/predict-temperature?year=2025&month=1
       ```
     - Erwartete Ausgabe: Steigende Zähler in Grafana.

3. **Checkmk für Service-Überwachung**:
   - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
   - Füge einen HTTP-Check hinzu:
     - Gehe zu `Setup > Services > Manual checks > HTTP`.
     - Host: `homelab-microservices-node`.
     - Service: `BigQuery ML API`.
     - URL: `http://<frontend-service-ip>/api/predict-temperature?year=2025&month=1`.
     - Speichern und `Discover services`.
   - Prüfe:
     - Gehe zu `Monitor > All services > BigQuery ML API`.
     - Erwartete Ausgabe: Status `OK` für API-Verfügbarkeit.

**Erkenntnis**: Prometheus und Checkmk ergänzen sich für ML-Metriken und Service-Überwachung.

**Quelle**: https://prometheus.io/docs, https://docs.checkmk.com

### Schritt 4: Integration mit HomeLab
1. **Backups auf TrueNAS**:
   - Archiviere das Projekt:
     ```bash
     tar -czf ~/bigquery-ml-backup-$(date +%F).tar.gz ~/bigquery-ml-integration /omd/sites/homelab
     rsync -av ~/bigquery-ml-backup-$(date +%F).tar.gz root@192.168.30.100:/mnt/tank/backups/bigquery-ml/
     ```
   - Automatisiere:
     ```bash
     nano /home/ubuntu/backup.sh
     ```
     - Inhalt (am Ende hinzufügen):
       ```bash
       DATE=$(date +%F)
       tar -czf /home/ubuntu/bigquery-ml-backup-$DATE.tar.gz ~/bigquery-ml-integration /omd/sites/homelab
       rsync -av /home/ubuntu/bigquery-ml-backup-$DATE.tar.gz root@192.168.30.100:/mnt/tank/backups/bigquery-ml/
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /home/ubuntu/backup.sh
       ```

2. **Netzwerkmanagement mit OPNsense**:
   - Aktualisiere die Firewall-Regel in OPNsense, um Zugriff auf `192.168.30.101:5000` (Checkmk), `192.168.30.101:3000` (Grafana), und `<frontend-service-ip>:80` (Frontend) von `192.168.30.0/24` zu erlauben:
     - Quelle: `192.168.30.0/24`
     - Ziel: `192.168.30.101`, `<frontend-service-ip>`
     - Ports: `80,3000,5000`
     - Aktion: `Allow`

### Schritt 5: Erweiterung der Übungen
1. **Erweitertes ML-Modell**:
   - Trainiere ein komplexeres Modell (z. B. ARIMA für Zeitreihen):
     ```bash
     bq query --use_legacy_sql=false \
     'CREATE OR REPLACE MODEL `homelab-lamp.weather_analysis.temp_arima_model`
      OPTIONS(model_type="ARIMA_PLUS")
      AS
      SELECT avg_temp_celsius AS value, TIMESTAMP(CONCAT(year, "-", month, "-01")) AS time
      FROM `homelab-lamp.weather_analysis.berlin_weather`'
     ```

2. **Alerting für ML-Vorhersagen**:
   - Konfiguriere Prometheus-Alert:
     ```bash
     nano alert-rules.yaml
     ```
     - Inhalt:
       ```yaml
       apiVersion: monitoring.coreos.com/v1
       kind: PrometheusRule
       metadata:
         name: ml-alerts
         namespace: monitoring
       spec:
         groups:
         - name: ml
           rules:
           - alert: HighPredictionError
             expr: temperature_predictions_total > 100
             for: 5m
             labels:
               severity: warning
             annotations:
               summary: "Hohe Anzahl an ML-Vorhersagen"
       ```
     - Anwenden:
       ```bash
       kubectl apply -f alert-rules.yaml
       ```

## Best Practices für Schüler

- **ML-Integration**:
  - Nutze BigQuery ML für einfache Modelle, vermeide Datenextraktion.
  - Integriere Modelle in Microservices mit minimaler Latenz.
- **Sicherheit**:
  - Schränke Netzwerkzugriff ein:
    ```bash
    sudo ufw allow from 192.168.30.0/24 to any port 80
    sudo ufw allow from 192.168.30.0/24 to any port 3000
    sudo ufw allow from 192.168.30.0/24 to any port 5000
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
  - Sichere Servicekonten:
    ```bash
    chmod 600 bigquery-key.json
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe BigQuery-Logs:
    ```bash
    bq show --job <job_id>
    ```
  - Prüfe Prometheus-Logs:
    ```bash
    kubectl logs -n monitoring deployment/prometheus-kube-prometheus-operator
    ```
  - Prüfe Checkmk-Logs:
    ```bash
    sudo tail -f /omd/sites/homelab/var/log/web.log
    ```

**Quelle**: https://cloud.google.com/bigquery-ml/docs, https://prometheus.io/docs, https://docs.checkmk.com

## Empfehlungen für Schüler

- **Setup**: BigQuery ML, GKE, Prometheus, Checkmk, TrueNAS-Backups.
- **Workloads**: ML-Vorhersagen in Microservices, Monitoring mit Prometheus/Checkmk.
- **Integration**: Proxmox (VM), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Temperaturvorhersage-API mit Monitoring.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einfachen ML-Modellen, integriere schrittweise in Microservices.
- **Übung**: Experimentiere mit komplexeren Modellen (z. B. ARIMA, DNN).
- **Fehlerbehebung**: Nutze `bq show`, `kubectl logs`, und Checkmk-Service-Scans.
- **Lernressourcen**: https://cloud.google.com/bigquery-ml/docs, https://prometheus.io/docs, https://docs.checkmk.com.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Integration von BigQuery ML in Microservices.
- **Skalierbarkeit**: GKE-Deployment mit ML-Vorhersagen.
- **Lernwert**: Verständnis von ML-Integration und Monitoring.

**Nächste Schritte**: Möchtest du eine Anleitung zu erweiterten Blue-Green Deployments, Log-Aggregation mit Fluentd, oder Integration mit Vertex AI?

**Quellen**:
- BigQuery ML-Dokumentation: https://cloud.google.com/bigquery-ml/docs
- GKE-Dokumentation: https://cloud.google.com/kubernetes-engine/docs
- Prometheus-Dokumentation: https://prometheus.io/docs
- Checkmk-Dokumentation: https://docs.checkmk.com
- Webquellen:,,,,,
```