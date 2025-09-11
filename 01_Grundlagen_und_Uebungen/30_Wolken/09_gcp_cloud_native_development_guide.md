# Lernprojekt: Cloud-native Entwicklung auf GCP

## Einführung

**Cloud-native Entwicklung** nutzt die Stärken der Cloud-Infrastruktur, um Anwendungen skalierbar, resilient und wartbar zu machen. Dieses Lernprojekt führt Schüler in cloud-native Konzepte ein, indem es Serverless Computing mit **Google Cloud Functions** und Microservices-Architektur mit **Docker Compose** und **Kubernetes (GKE)** behandelt. Es baut auf den vorherigen GCP-Anleitungen (`gcp_cloud_computing_intro_guide.md`, `gcp_terraform_lamp_iac_project.md`) auf und integriert die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense) für Backups. Das Projekt ist für Anfänger mit Grundkenntnissen in Linux, Python und Docker geeignet und nutzt den GCP Free Tier sowie das $300-Aktionsguthaben. Es umfasst zwei Teile: 1) Serverless mit Cloud Functions für eine einfache API, 2) Microservices mit Docker Compose und Kubernetes für eine skalierbare Webanwendung.

**Voraussetzungen**:
- GCP-Konto mit aktiviertem Free Tier oder $300-Guthaben, Projekt `homelab-lamp` (Projekt-ID: z. B. `homelab-lamp-123456`).
- Grundkenntnisse in Python, Docker und Kubernetes (z. B. aus `gcp_kubernetes_scalable_web_app_project.md`).
- Google Cloud SDK (`gcloud`) installiert (z. B. auf einer lokalen Maschine oder GCP-VM).
- Eine registrierte Domain (z. B. `mylampproject.tk`).
- Optional: HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense für Netzwerkverständnis.
- Browser für die GCP-Konsole (`https://console.cloud.google.com`).

**Ziele**:
- Serverless Computing mit Google Cloud Functions für eine einfache API.
- Microservices-Architektur mit Docker Compose und Kubernetes (GKE) für skalierbare Anwendungen.
- Integration mit HomeLab für Backups.

**Hinweis**: Cloud-native Ansätze vermeiden Server-Management und nutzen Cloud-Dienste für Skalierbarkeit.

**Quellen**:
- Google Cloud Functions-Dokumentation: https://cloud.google.com/functions/docs
- GKE-Dokumentation: https://cloud.google.com/kubernetes-engine/docs
- Docker Compose-Dokumentation: https://docs.docker.com/compose/
- Webquellen:,,,,,,,,,,,,,,

## Teil 1: Serverless Computing mit Google Cloud Functions

### Konzept
**Serverless Computing** (z. B. Google Cloud Functions) führt Code aus, ohne Server-Management. Es ist ideal für ereignisgesteuerte Anwendungen (z. B. HTTP-Requests) und skaliert automatisch.

### Übung 1: Einfache API mit Cloud Functions

**Ziel**: Erstelle eine Cloud Function, die eine HTTP-API für Temperaturdaten bereitstellt (aus BigQuery).

**Aufgabe**: Schreibe eine Python-Funktion, deploye sie und teste die API.

1. **Cloud Functions API aktivieren**:
   - In der GCP-Konsole: `APIs & Services > Library`.
   - Suche nach „Cloud Functions API" und aktiviere sie.

2. **Funktion lokal entwickeln**:
   - Erstelle `main.py`:
     ```bash
     mkdir ~/cloud-functions
     cd ~/cloud-functions
     nano main.py
     ```
     - Inhalt:
       ```python
       from flask import jsonify
       from google.cloud import bigquery

       client = bigquery.Client(project='homelab-lamp')

       def hello_world(request):
           query = """
           SELECT year, month, predicted_avg_temp_celsius
           FROM \`homelab-lamp.weather_analysis.berlin_temp_predictions_2025\`
           ORDER BY month LIMIT 3;
           """
           query_job = client.query(query)
           results = [dict(row) for row in query_job.result()]
           return jsonify({
               "message": "Serverless Temperatur-API",
               "data": results
           })
       ```
   - **Erklärung**: Die Funktion `hello_world` ruft BigQuery-Daten ab und gibt JSON zurück.

3. **Requirements erstellen**:
   ```bash
   nano requirements.txt
   ```
   - Inhalt:
     ```
     google-cloud-bigquery==3.11.4
     flask==2.3.3
     ```

4. **Funktion deployen**:
   - Installiere Google Cloud Functions CLI (falls nicht vorhanden):
     ```bash
     gcloud components install functions-framework
     ```
   - Deploye:
     ```bash
     gcloud functions deploy temperature-api \
       --runtime python39 \
       --trigger-http \
       --allow-unauthenticated \
       --source .
     ```
     - Erwartete Ausgabe: URL (z. B. `https://europe-west1-homelab-lamp.cloudfunctions.net/temperature-api`).

5. **Funktion testen**:
   ```bash
   curl https://europe-west1-homelab-lamp.cloudfunctions.net/temperature-api
   ```
   - Erwartete Ausgabe:
     ```json
     {
       "message": "Serverless Temperatur-API",
       "data": [
         {"year": 2025, "month": 1, "predicted_avg_temp_celsius": 2.5},
         {"year": 2025, "month": 2, "predicted_avg_temp_celsius": 3.1},
         {"year": 2025, "month": 3, "predicted_avg_temp_celsius": 6.2}
       ]
     }
     ```

**Erkenntnis**: Cloud Functions ermöglichen serverlose Ausführung von Code, skaliert automatisch und integriert sich nahtlos mit BigQuery.

**Quelle**: https://cloud.google.com/functions/docs

## Teil 2: Microservices-Architektur mit Docker Compose und Kubernetes

### Konzept
**Microservices-Architektur** teilt Anwendungen in unabhängige Dienste auf, die mit Docker Compose oder Kubernetes (GKE) bereitgestellt werden. Es fördert Skalierbarkeit und Wartbarkeit.

### Übung 2: Microservices mit Docker Compose

**Ziel**: Teile eine Monolith-Anwendung in Microservices auf und deploye sie mit Docker Compose.

**Aufgabe**: Erstelle eine Microservices-Anwendung (z. B. Frontend und Backend) und deploye sie.

1. **Projektstruktur erstellen**:
   ```bash
   mkdir ~/microservices-compose
   cd ~/microservices-compose
   mkdir frontend backend
   ```

2. **Backend (Node.js API)**:
   - Erstelle `backend/package.json`:
     ```json
     {
       "name": "backend",
       "version": "1.0.0",
       "main": "server.js",
       "dependencies": { "express": "^4.18.2" }
     }
     ```
   - Erstelle `backend/server.js`:
     ```javascript
     const express = require('express');
     const app = express();
     app.get('/api/data', (req, res) => res.json({ message: 'Backend Data' }));
     app.listen(3001, () => console.log('Backend on port 3001'));
     ```
   - Erstelle `backend/Dockerfile`:
     ```dockerfile
     FROM node:18-alpine
     WORKDIR /app
     COPY package*.json ./
     RUN npm install
     COPY . .
     EXPOSE 3001
     CMD ["node", "server.js"]
     ```

3. **Frontend (React oder HTML)**:
   - Erstelle `frontend/index.html`:
     ```html
     <!DOCTYPE html>
     <html>
     <head><title>Microservices Frontend</title></head>
     <body>
       <h1>Microservices Frontend</h1>
       <div id="data"></div>
       <script>
         fetch('http://backend:3001/api/data')
           .then(res => res.json())
           .then(data => document.getElementById('data').innerHTML = data.message);
       </script>
     </body>
     </html>
     ```
   - Erstelle `frontend/Dockerfile`:
     ```dockerfile
     FROM nginx:alpine
     COPY index.html /usr/share/nginx/html/
     EXPOSE 80
     CMD ["nginx", "-g", "daemon off;"]
     ```

4. **Docker Compose erstellen**:
   ```bash
   nano docker-compose.yml
   ```
   - Inhalt:
     ```yaml
     version: '3'
     services:
       frontend:
         build: ./frontend
         ports:
           - "80:80"
         depends_on:
           - backend
       backend:
         build: ./backend
         ports:
           - "3001:3001"
     ```
   - Starte:
     ```bash
     docker-compose up --build
     ```
   - Teste:
     ```bash
     curl http://192.168.30.101
     ```
     - Erwartete Ausgabe:
       ```
       <h1>Microservices Frontend</h1>
       <div id="data">Backend Data</div>
       ```

**Erkenntnis**: Docker Compose erleichtert den Deployment von Microservices, indem es Dienste orchestriert und Abhängigkeiten verwaltet.

**Quelle**: https://docs.docker.com/compose/

### Übung 3: Microservices mit Kubernetes (GKE)

**Ziel**: Deploye Microservices auf Kubernetes (GKE) für Skalierbarkeit.

**Aufgabe**: Erstelle Deployments und Services für Frontend und Backend auf GKE.

1. **GKE-Cluster einrichten** (siehe `gcp_kubernetes_scalable_web_app_project.md`):
   - Erstelle einen Cluster:
     ```bash
     gcloud container clusters create homelab-microservices --zone europe-west1-b --machine-type e2-small --num-nodes 1
     gcloud container clusters get-credentials homelab-microservices --zone europe-west1-b
     ```

2. **Images in Google Container Registry pushen**:
   ```bash
   gcloud auth configure-docker
   docker tag frontend gcr.io/homelab-lamp/frontend:v1
   docker tag backend gcr.io/homelab-lamp/backend:v1
   docker push gcr.io/homelab-lamp/frontend:v1
   docker push gcr.io/homelab-lamp/backend:v1
   ```

3. **Backend-Deployment**:
   ```bash
   nano backend-deployment.yaml
   ```
   - Inhalt:
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
             image: gcr.io/homelab-lamp/backend:v1
             ports:
             - containerPort: 3001
     ---
     apiVersion: v1
     kind: Service
     metadata:
       name: backend-service
     spec:
       selector:
         app: backend
       ports:
       - protocol: TCP
         port: 3001
         targetPort: 3001
       type: ClusterIP
     ```
   - Anwenden:
     ```bash
     kubectl apply -f backend-deployment.yaml
     ```

4. **Frontend-Deployment**:
   ```bash
   nano frontend-deployment.yaml
   ```
   - Inhalt:
     ```yaml
     apiVersion: apps/v1
     kind: Deployment
     metadata:
       name: frontend-deployment
     spec:
       replicas: 2
       selector:
         matchLabels:
           app: frontend
       template:
         metadata:
           labels:
             app: frontend
         spec:
           containers:
           - name: frontend
             image: gcr.io/homelab-lamp/frontend:v1
             ports:
             - containerPort: 80
     ---
     apiVersion: v1
     kind: Service
     metadata:
       name: frontend-service
     spec:
       selector:
         app: frontend
       ports:
       - protocol: TCP
         port: 80
         targetPort: 80
       type: LoadBalancer
     ```
   - Anwenden:
     ```bash
     kubectl apply -f frontend-deployment.yaml
     ```
   - Prüfe:
     ```bash
     kubectl get services
     ```
     - Erwartete Ausgabe: Externe IP für `frontend-service` (z. B. `10.123.45.67:80`).
   - Teste:
     ```bash
     curl http://10.123.45.67
     ```
     - Erwartete Ausgabe: Frontend mit Backend-Daten.

**Erkenntnis**: Kubernetes (GKE) skaliert Microservices automatisch und verbindet sie über Services.

**Quelle**: https://cloud.google.com/kubernetes-engine/docs

### Schritt 4: Integration mit HomeLab
1. **Backups auf TrueNAS**:
   - Archiviere das Projekt:
     ```bash
     tar -czf ~/microservices-backup-$(date +%F).tar.gz ~/microservices-compose
     rsync -av ~/microservices-backup-$(date +%F).tar.gz root@192.168.30.100:/mnt/tank/backups/microservices/
     ```
   - Automatisiere:
     ```bash
     nano /home/ubuntu/backup.sh
     ```
     - Inhalt (am Ende hinzufügen):
       ```bash
       DATE=$(date +%F)
       tar -czf /home/ubuntu/microservices-backup-$DATE.tar.gz ~/microservices-compose
       rsync -av /home/ubuntu/microservices-backup-$DATE.tar.gz root@192.168.30.100:/mnt/tank/backups/microservices/
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /home/ubuntu/backup.sh
       ```

2. **Netzwerkmanagement mit OPNsense**:
   - Aktualisiere die Firewall-Regel in OPNsense, um Zugriff auf `192.168.30.101:80` (Frontend) und `192.168.30.101:3001` (Backend) von `192.168.30.0/24` zu erlauben:
     - Quelle: `192.168.30.0/24`
     - Ziel: `192.168.30.101`
     - Ports: `80,3001`
     - Aktion: `Allow`

### Schritt 5: Erweiterung der Übungen
1. **Service Mesh mit Istio**:
   - Installiere Istio in GKE:
     ```bash
     gcloud container clusters get-credentials homelab-microservices --zone europe-west1-b
     curl -L https://istio.io/downloadIstio | sh -
     cd istio-1.20.3
     export PATH=$PWD/bin:$PATH
     istioctl install --set profile=demo
     ```
   - Deploye Microservices mit Istio und Traffic-Management.

2. **CI/CD für Microservices**:
   - Integriere GitHub Actions mit GKE für automatische Deployments:
     ```yaml
     # .github/workflows/deploy.yml
     name: Deploy to GKE
     on:
       push:
         branches:
           - main
     jobs:
       deploy:
         runs-on: ubuntu-latest
         steps:
         - uses: actions/checkout@v4
         - name: Set up Docker Buildx
           uses: docker/setup-buildx-action@v3
         - name: Build and push
           uses: docker/build-push-action@v5
           with:
             push: true
             tags: gcr.io/homelab-lamp/frontend:${{ github.sha }}
         - name: Deploy to GKE
           uses: google-github-actions/setup-gcloud@v1
           with:
             project_id: homelab-lamp
         - name: Get credentials
           run: gcloud container clusters get-credentials homelab-microservices --zone europe-west1-b
         - name: Deploy
           run: kubectl apply -f frontend-deployment.yaml
     ```

## Best Practices für Schüler

- **Architektur**:
  - Teile Anwendungen in kleine, unabhängige Dienste auf.
  - Nutze Docker Compose für lokale Tests, Kubernetes für Skalierung.
- **Sicherheit**:
  - Schränke Netzwerkzugriff ein:
    ```bash
    sudo ufw allow from 192.168.30.0/24 to any port 80
    sudo ufw allow from 192.168.30.0/24 to any port 3001
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe Docker-Logs:
    ```bash
    docker logs $(docker ps -q -f name=frontend)
    ```
  - Prüfe GKE:
    ```bash
    kubectl get pods
    kubectl logs deployment/backend-deployment
    ```

**Quelle**: https://docs.docker.com/compose/, https://cloud.google.com/kubernetes-engine/docs

## Empfehlungen für Schüler

- **Setup**: Docker Compose und GKE, TrueNAS-Backups.
- **Workloads**: Microservices-Anwendung (Frontend, Backend).
- **Integration**: Proxmox (VM), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Flask-Backend und HTML-Frontend, skaliert auf GKE.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit Docker Compose lokal, migriere zu GKE.
- **Übung**: Experimentiere mit weiteren Services (z. B. Datenbank).
- **Fehlerbehebung**: Nutze `docker-compose logs` und `kubectl describe`.
- **Lernressourcen**: https://docs.docker.com/compose, https://cloud.google.com/kubernetes-engine/docs.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Cloud-native Entwicklung mit Serverless und Microservices.
- **Skalierbarkeit**: Automatische Skalierung mit Cloud Functions und Kubernetes.
- **Lernwert**: Verständnis von Serverless und Microservices-Architektur.

Es ist ideal für Schüler, die cloud-native Entwicklung erkunden möchten.

**Nächste Schritte**: Möchtest du eine Anleitung zu CI/CD für Microservices, Monitoring mit Prometheus, oder Integration mit BigQuery ML?

**Quellen**:
- Google Cloud Functions-Dokumentation: https://cloud.google.com/functions/docs
- GKE-Dokumentation: https://cloud.google.com/kubernetes-engine/docs
- Docker Compose-Dokumentation: https://docs.docker.com/compose/
- Webquellen:,,,,,,,,,,,,,,
```