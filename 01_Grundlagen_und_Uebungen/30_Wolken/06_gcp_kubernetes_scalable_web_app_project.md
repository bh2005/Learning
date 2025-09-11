# Lernprojekt: Skalierbare Webanwendung mit Kubernetes (GKE) für Schüler

## Einführung

**Kubernetes** ist ein Open-Source-Plattform zur Orchestrierung von Containern, die Anwendungen skalierbar und hochverfügbar macht. In der Google Cloud Platform (GCP) wird Kubernetes über **Google Kubernetes Engine (GKE)** bereitgestellt, das managed Kubernetes-Cluster ermöglicht. Dieses Lernprojekt führt Schüler in Kubernetes ein, indem es eine skalierbare Webanwendung (z. B. eine Node.js-App, die Temperaturdaten aus BigQuery anzeigt) auf GKE deployt. Es baut auf den vorherigen Anleitungen (`01_gcp_cloud_computing_intro_guide.md`, `02_gcp_lamp_letsencrypt_guide.md`, `03_gcp_lamp_cloud_storage_backup_guide.md`, `04_gcp_bigquery_weather_analysis_project.md`, `05_gcp_bigquery_ml_weather_prediction_project.md`) auf, die GCP-Grundlagen, LAMP-Stack, Backups und BigQuery/ML eingeführt haben. Das Projekt umfasst die Erstellung eines GKE-Clusters im Free Tier, das Dockerisieren einer App, das Deployen mit Deployments und Services, das Skalieren von Pods und die Integration mit BigQuery für dynamische Daten. Es integriert optional die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense) für Backups und ist schülerfreundlich.

**Voraussetzungen**:
- GCP-Konto mit aktiviertem Free Tier oder $300-Aktionsguthaben, Projekt `homelab-lamp` (Projekt-ID: z. B. `homelab-lamp-123456`).
- Grundkenntnisse in Docker (z. B. Container erstellen), Kubernetes-Konzepten (Pods, Deployments) und SQL (aus BigQuery-Projekten).
- Google Cloud SDK (`gcloud`) installiert (z. B. auf der LAMP-VM `lamp-vm`, IP: z. B. `34.123.45.67`).
- BigQuery-Dataset `weather_analysis` mit Tabelle `berlin_temp_predictions_2025` (aus `05_gcp_bigquery_ml_weather_prediction_project.md`).
- Google Cloud Storage Bucket (`homelab-lamp-backups`) für Backups.
- Optional: HomeLab mit TrueNAS (`192.168.30.100`) für zusätzliche Backups und OPNsense für Netzwerkverständnis.
- Browser für die GCP-Konsole (`https://console.cloud.google.com`).

**Ziele**:
- Verstehen von Kubernetes-Konzepten (Pods, Deployments, Services, Scaling).
- Erstellen eines GKE-Clusters im Free Tier.
- Dockerisieren und Deployen einer skalierbaren Node.js-Webanwendung, die BigQuery-Daten anzeigt.
- Testen von Horizontal Pod Autoscaling (HPA).
- Sichern der App-Konfiguration in Cloud Storage und TrueNAS.

**Hinweis**: GKE Free Tier bietet $74.40 monatliche Credits für einen zonalen Standard-Cluster oder Autopilot, ausreichend für Lernprojekte. Das $300-Guthaben ermöglicht Tests.

**Quellen**:
- GKE-Dokumentation: https://cloud.google.com/kubernetes-engine/docs
- Kubernetes-Dokumentation: https://kubernetes.io/docs
- Webquellen:,,,,,,,,,,,,,,

## Lernprojekt: Skalierbare Wetter-App mit Kubernetes

### Projektübersicht
- **Anwendung**: Eine Node.js-Webanwendung, die Temperaturvorhersagen aus BigQuery (`berlin_temp_predictions_2025`) anzeigt und skalierbar ist.
- **Kubernetes-Komponenten**: Deployment (Pods), Service (Load Balancing), HPA (Autoscaling).
- **Tools**: GKE für Kubernetes, Docker für Containerisierung, BigQuery für Daten, Google Data Studio für Visualisierung (optional).
- **Ausgabe**: Eine skalierbare Web-App, die bei Last zunimmt, mit Backups in Cloud Storage.

### Schritt 1: GKE-Cluster einrichten
1. **GKE API aktivieren**:
   - Öffne die GCP-Konsole: `https://console.cloud.google.com`.
   - Gehe zu `APIs & Services > Library`.
   - Suche nach „Kubernetes Engine API“ und klicke auf „Aktivieren“.
2. **Cluster erstellen**:
   - In der GCP-Konsole: `Navigation > Kubernetes Engine > Clusters > Create`.
   - Konfiguriere:
     - Name: `homelab-k8s-cluster`.
     - Release Channel: `Rapid` (für aktuelle Features).
     - Environment: `Standard` (Free Tier-kompatibel).
     - Location Type: `Zonal` (für Free Tier).
     - Zone: `europe-west1-b` (Konsistenz mit VM).
     - Control Plane: Standard (Standard-Cluster).
     - Nodes: `e2-small` (2 vCPU, 2 GB RAM, Free Tier-kompatibel).
     - Number of Nodes: `1` (Minimum für Lernprojekte).
   - Klicke auf „Create“ (Cluster erstellt in ~5–10 Minuten).
3. **Cluster prüfen**:
   - In der GKE-Konsole: `Kubernetes Engine > Clusters > homelab-k8s-cluster`.
   - Status: „Running“.

**Tipp**: Der Free Tier deckt einen zonalen Standard-Cluster mit 1 Node ab (ca. $74.40/Monat Credits).

**Quelle**: https://cloud.google.com/kubernetes-engine/docs/quickstart

### Schritt 2: Node.js-Webanwendung erstellen und Dockerisieren
1. **SSH in die LAMP-VM** (falls verwendet):
   ```bash
   ssh ubuntu@34.123.45.67
   ```
2. **Node.js installieren**:
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
   sudo apt install nodejs -y
   node -v  # Erwartet: v20.x
   ```
3. **Webanwendung erstellen**:
   ```bash
   mkdir ~/weather-app
   cd ~/weather-app
   npm init -y
   npm install express @google-cloud/bigquery
   ```
   - Erstelle `app.js`:
     ```bash
     nano app.js
     ```
     - Inhalt:
       ```javascript
       const express = require('express');
       const { BigQuery } = require('@google-cloud/bigquery');
       const app = express();
       const bigquery = new BigQuery({ projectId: 'homelab-lamp' });

       app.get('/', async (req, res) => {
         try {
           const query = `
             SELECT year, month, predicted_avg_temp_celsius
             FROM \`homelab-lamp.weather_analysis.berlin_temp_predictions_2025\`
             ORDER BY month;
           `;
           const [rows] = await bigquery.query(query);
           res.json({ message: 'Berlin Temperaturvorhersagen 2025', data: rows });
         } catch (error) {
           res.status(500).json({ error: error.message });
         }
       });

       app.listen(8080, () => {
         console.log('Server läuft auf Port 8080');
       });
       ```
4. **App testen**:
   ```bash
   node app.js
   ```
   - Öffne `http://localhost:8080` (oder `http://34.123.45.67:8080`) im Browser.
   - Erwartete Ausgabe: JSON mit Temperaturvorhersagen.
5. **Dockerfile erstellen**:
   ```bash
   nano Dockerfile
   ```
   - Inhalt:
     ```dockerfile
     FROM node:20-alpine
     WORKDIR /app
     COPY package*.json ./
     RUN npm install
     COPY . .
     EXPOSE 8080
     CMD ["node", "app.js"]
     ```
6. **Docker-Image bauen**:
   ```bash
   docker build -t weather-app .
   docker run -p 8080:8080 weather-app
   ```
   - Teste: `http://34.123.45.67:8080`.

**Tipp**: Die App ruft BigQuery-Daten ab; stelle sicher, dass `GOOGLE_APPLICATION_CREDENTIALS` gesetzt ist (aus `03_gcp_lamp_cloud_storage_backup_guide.md`).

**Quelle**: https://cloud.google.com/kubernetes-engine/docs/tutorials/hello-app

### Schritt 3: App in GKE deployen
1. **kubectl installieren**:
   - Auf der VM:
     ```bash
     curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
     sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
     kubectl version --client
     ```
2. **GKE-Cluster konfigurieren**:
   ```bash
   gcloud container clusters get-credentials homelab-k8s-cluster --zone europe-west1-b
   kubectl get nodes
   ```
   - Erwartete Ausgabe: 1 Node (`gke-homelab-k8s-cluster-default-pool-abc123`).
3. **Docker-Image in Google Container Registry (GCR) pushen**:
   ```bash
   gcloud auth configure-docker
   docker tag weather-app gcr.io/homelab-lamp/weather-app:v1
   docker push gcr.io/homelab-lamp/weather-app:v1
   ```
4. **Deployment erstellen**:
   ```bash
   kubectl create deployment weather-app --image=gcr.io/homelab-lamp/weather-app:v1
   kubectl get deployments
   ```
5. **Service erstellen**:
   ```bash
   kubectl expose deployment weather-app --type=LoadBalancer --port=80 --target-port=8080
   kubectl get services
   ```
   - Erwartete Ausgabe: Externe IP (z. B. `10.123.45.67`).
6. **App testen**:
   - Öffne `http://10.123.45.67` im Browser.
   - Erwartete Ausgabe: JSON mit Temperaturvorhersagen.

**Tipp**: Der LoadBalancer-Service erstellt eine externe IP; warte ~2 Minuten.

**Quelle**: https://cloud.google.com/kubernetes-engine/docs/quickstart

### Schritt 4: Skalierung testen
1. **Horizontal Pod Autoscaler (HPA) einrichten**:
   ```bash
   kubectl autoscale deployment weather-app --cpu-percent=50 --min=1 --max=5
   kubectl get hpa
   ```
2. **Load simulieren**:
   - Installiere `hey` (HTTP-Load-Tester):
     ```bash
     curl -sL https://github.com/rakyll/hey/releases/latest/download/hey_linux_amd64.tar.gz | tar xz
     sudo mv hey /usr/local/bin/
     ```
   - Simuliere Load:
     ```bash
     hey -n 1000 -c 50 http://10.123.45.67
     ```
   - Prüfe Scaling:
     ```bash
     kubectl get pods
     kubectl get hpa
     ```
     - Erwartete Ausgabe: Pods skalieren auf 2–5 bei hoher CPU-Last.
3. **Scaling zurücksetzen**:
   ```bash
   kubectl scale deployment weather-app --replicas=1
   ```

**Tipp**: HPA skaliert basierend auf CPU-Nutzung (50%); passe für Lernzwecke an.

**Quelle**: https://cloud.google.com/kubernetes-engine/docs/concepts/horizontalpodautoscaler

### Schritt 5: Ergebnisse sichern
1. **Kubernetes-Konfiguration exportieren**:
   ```bash
   kubectl get all -o yaml > /home/ubuntu/k8s-config-$(date +%F).yaml
   gsutil cp /home/ubuntu/k8s-config-$(date +%F).yaml gs://homelab-lamp-backups/k8s/
   ```
2. **App-Logs sichern**:
   ```bash
   kubectl logs deployment/weather-app > /home/ubuntu/app-logs-$(date +%F).log
   gsutil cp /home/ubuntu/app-logs-$(date +%F).log gs://homelab-lamp-backups/app-logs/
   ```
3. **Bucket-Inhalt prüfen**:
   ```bash
   gsutil ls gs://homelab-lamp-backups/k8s/
   ```

### Schritt 6: Integration mit HomeLab
1. **Backups auf TrueNAS sichern**:
   ```bash
   gsutil cp gs://homelab-lamp-backups/k8s/k8s-config-$(date +%F).yaml /home/ubuntu/
   rsync -av /home/ubuntu/k8s-config-$(date +%F).yaml root@192.168.30.100:/mnt/tank/backups/k8s/
   ```
   - Automatisiere im Backup-Skript (`/home/ubuntu/backup.sh` aus `03_gcp_lamp_cloud_storage_backup_guide.md`):
     ```bash
     # Am Ende des Skripts hinzufügen
     kubectl get all -o yaml > $BACKUP_DIR/k8s-config-$DATE.yaml
     gsutil cp $BACKUP_DIR/k8s-config-$DATE.yaml $BUCKET/k8s/
     rsync -av $BACKUP_DIR/k8s-config-$DATE.yaml root@192.168.30.100:/mnt/tank/backups/k8s/
     ```
2. **Vergleich mit OPNsense**:
   - HomeLab: OPNsense schützt Kubernetes-Traffic mit Firewall-Regeln und Suricata IDS/IPS.
   - GCP: Simuliere OPNsense-Sicherheit durch GKE-Netzwerk-Policies:
     - In der GCP-Konsole: `Kubernetes Engine > Workloads > weather-app > Edit & Deploy New Replica`.
     - Füge Network Policy hinzu (z. B. nur Zugriff von `192.168.20.0/24`).
   - Überwache Traffic:
     ```bash
     kubectl logs deployment/weather-app
     ```
3. **Wiederherstellung testen**:
   - Lade die YAML-Konfiguration herunter:
     ```bash
     gsutil cp gs://homelab-lamp-backups/k8s/k8s-config-2025-09-09.yaml /home/ubuntu/
     ```
   - Deploye neu:
     ```bash
     kubectl apply -f /home/ubuntu/k8s-config-2025-09-09.yaml
     ```

## Best Practices für Schüler

- **Kostenmanagement**:
  - Bleibe im Free Tier (1 Node-Cluster, e2-small).
  - Überwache Kosten: `Kubernetes Engine > Clusters > homelab-k8s-cluster > Pricing`.
  - Lösche Ressourcen nach dem Test:
    ```bash
    gcloud container clusters delete homelab-k8s-cluster --zone europe-west1-b
    ```
- **Sicherheit**:
  - Verwende IAM-Rollen für GKE (`Container Engine Admin` für `lamp-backup-sa`).
  - Schränke Cluster-Zugriff ein:
    ```bash
    gcloud container clusters get-credentials homelab-k8s-cluster --zone europe-west1-b
    ```
  - Aktiviere Network Policies:
    ```bash
    kubectl apply -f - <<EOF
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: allow-internal
    spec:
      podSelector: {}
      policyTypes:
      - Ingress
      ingress:
      - from:
        - namespaceSelector: {}
    EOF
    ```
- **Automatisierung**:
  - Teste Deployments:
    ```bash
    kubectl rollout status deployment/weather-app
    ```
  - Überwache Scaling:
    ```bash
    kubectl get hpa
    ```
- **Lernziele**:
  - Verstehe Kubernetes-Komponenten (Pods, Deployments, Services, HPA).
  - Vergleiche Cloud-Kubernetes (GKE) mit HomeLab-Container (Proxmox LXC).
  - Übe Docker und YAML-Konfigurationen.
- **Backup-Strategie**:
  - Implementiere die 3-2-1-Regel:
    - 3 Kopien: GKE-Konfiguration, Cloud Storage, TrueNAS.
    - 2 Medien: GCP Persistent Disk, TrueNAS HDD.
    - 1 Off-Site: Google Cloud Storage.

**Quelle**: https://cloud.google.com/kubernetes-engine/docs/best-practices

## Empfehlungen für Schüler

- **Setup**:
  - **GKE-Cluster**: Zonal Standard-Cluster mit 1 e2-small-Node in `europe-west1-b`.
  - **App**: Node.js-Webanwendung mit BigQuery-Integration, skalierbar mit HPA.
  - **Workloads**: Skalierbare Wetter-App, die bei Last Pods erhöht.
- **Integration**:
  - GCP: Nutze Free Tier ($74.40/Monat) und $300-Guthaben für Tests.
  - HomeLab: Sichere YAML-Konfigurationen auf TrueNAS (`/mnt/tank/backups/k8s`).
- **Beispiel**:
  - Deployment von `weather-app` mit 1–5 Pods, LoadBalancer-Service, HPA bei 50% CPU.
  - Backups in Cloud Storage und TrueNAS.

## Tipps für den Erfolg

- **Free Tier**: Nutze zonalen Standard-Cluster, um Kosten zu minimieren.
- **Docker-Übung**: Experimentiere mit Multi-Container-Apps (z. B. WordPress + MariaDB).
- **Scaling**: Teste HPA mit `hey` (Load-Tester):
  ```bash
  hey -n 1000 -c 50 http://10.123.45.67
  ```
- **Lernressourcen**: Nutze https://cloud.google.com/kubernetes-engine/docs und Kubernetes-Tutorials (https://kubernetes.io/docs/tutorials).
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`) für Referenz.

## Fazit

Dieses Lernprojekt mit Kubernetes auf GKE bietet:
- **Praxisorientiert**: Skalierbare Webanwendung mit BigQuery-Integration.
- **Einfachheit**: Free Tier und managed GKE erleichtern den Einstieg.
- **Lernwert**: Verständnis von Orchestrierung, Scaling und Cloud-Integration.

Es ist ideal für Schüler, die Cloud Computing und Kubernetes lernen möchten, und verbindet GCP-Konzepte mit HomeLab-Erfahrungen (z. B. TrueNAS-Backups).

**Nächste Schritte**: Möchtest du eine Anleitung zu Monitoring mit Check_MK/Prometheus, zu fortgeschrittenen Kubernetes-Features (z. B. Ingress, Helm) oder zu einer anderen GCP-Dienst (z. B. Cloud Run)?

**Quellen**:
- GKE-Dokumentation: https://cloud.google.com/kubernetes-engine/docs
- Kubernetes-Dokumentation: https://kubernetes.io/docs
- Webquellen:,,,,,,,,,,,,,,