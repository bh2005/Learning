# Lernprojekt: Grundlagen von Datenbanken in der Cloud mit GCP Cloud SQL

## Einführung

**Cloud-Datenbanken** wie Google Cloud SQL ermöglichen die einfache Bereitstellung, Verwaltung und Skalierung relationaler Datenbanken in der Cloud, ohne komplexes Servermanagement. Dieses Lernprojekt führt Schüler in die Grundlagen der Bereitstellung und Verwaltung einer relationalen Datenbank mit **Google Cloud SQL (MySQL)** ein. Es baut auf den vorherigen GCP-Anleitungen (z. B. `gcp_cicd_microservices_guide.md`, ) auf und integriert die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense) für Backups. Das Projekt ist für Anfänger mit Grundkenntnissen in SQL, Linux und GCP geeignet und nutzt den GCP Free Tier sowie das $300-Aktionsguthaben. Es umfasst drei Übungen: Einrichten einer Cloud SQL-Instanz, Integration mit einem Microservice auf GKE, und Backup-Management mit TrueNAS. Es ist lokal, kostenlos (im Free Tier) und datenschutzfreundlich.

**Voraussetzungen**:
- GCP-Konto mit aktiviertem Free Tier oder $300-Guthaben, Projekt `homelab-lamp` (Projekt-ID: z. B. `homelab-lamp-123456`).
- GKE-Cluster `homelab-microservices` mit Microservices (Frontend und Backend aus `gcp_cicd_microservices_guide.md`).
- Ubuntu-VM auf Proxmox (IP `192.168.30.101`) mit `gcloud` und `mysql-client` installiert.
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement.
- Grundkenntnisse in SQL, Python, Docker und Kubernetes.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`).

**Ziele**:
- Bereitstellung und Konfiguration einer MySQL-Datenbank mit Cloud SQL.
- Integration der Datenbank in einen Backend-Microservice auf GKE.
- Verwaltung von Backups mit TrueNAS.
- Monitoring der Datenbank mit Checkmk (optional, basierend auf `gcp_prometheus_checkmk_monitoring_guide.md`).

**Hinweis**: Cloud SQL bietet verwaltete MySQL/PostgreSQL-Datenbanken mit automatischer Skalierung, Hochverfügbarkeit und Backups.

**Quellen**:
- Cloud SQL-Dokumentation: https://cloud.google.com/sql/docs
- GKE-Dokumentation: https://cloud.google.com/kubernetes-engine/docs
- MySQL-Dokumentation: https://dev.mysql.com/doc
- Webquellen:,,,,,

## Lernprojekt: Cloud SQL Bereitstellung und Verwaltung

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
   - Installiere `mysql-client` auf der Ubuntu-VM:
     ```bash
     ssh ubuntu@192.168.30.101
     sudo apt update
     sudo apt install -y mysql-client
     ```
2. **Projektverzeichnis erstellen**:
   ```bash
   mkdir ~/cloud-sql-integration
   cd ~/cloud-sql-integration
   ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf GKE und TrueNAS.

### Übung 1: Bereitstellung einer Cloud SQL-Instanz

**Ziel**: Erstelle und konfiguriere eine MySQL-Instanz in Cloud SQL.

**Aufgabe**: Richte eine MySQL-Datenbank ein und teste die Verbindung.

1. **Cloud SQL API aktivieren**:
   - In der GCP-Konsole: `APIs & Services > Library`.
   - Suche nach „Cloud SQL Admin API“ und aktiviere sie.

2. **Cloud SQL-Instanz erstellen**:
   - Erstelle eine MySQL-Instanz:
     ```bash
     gcloud sql instances create homelab-mysql \
       --database-version=MYSQL_8_0 \
       --tier=db-f1-micro \
       --region=europe-west1 \
       --root-password=securepassword123
     ```
     - **Erklärung**: `db-f1-micro` ist Free Tier-kompatibel, MySQL 8.0 wird verwendet.
   - Prüfe:
     ```bash
     gcloud sql instances list
     ```
     - Erwartete Ausgabe: Instanz `homelab-mysql` mit Status `RUNNABLE`.

3. **Datenbank und Benutzer erstellen**:
   - Erstelle eine Datenbank:
     ```bash
     gcloud sql databases create weather_db --instance=homelab-mysql
     ```
   - Erstelle einen Benutzer:
     ```bash
     gcloud sql users create app_user --instance=homelab-mysql --password=apppassword456
     ```

4. **Netzwerkzugriff konfigurieren**:
   - Erlaube Zugriff von GKE:
     ```bash
     gcloud sql instances patch homelab-mysql --authorized-networks=0.0.0.0/0
     ```
     - **Hinweis**: Für Produktion restriktivere Netzwerkeinstellungen verwenden (z. B. VPC).
   - Hole die öffentliche IP:
     ```bash
     gcloud sql instances describe homelab-mysql | grep ipAddress
     ```
     - Erwartete Ausgabe: IP wie `34.123.45.67`.

5. **Verbindung testen**:
   - Verbinde dich von der Ubuntu-VM:
     ```bash
     mysql -h 34.123.45.67 -u app_user -papppassword456 -e "SELECT 1"
     ```
     - Erwartete Ausgabe: `1`.
   - Erstelle eine Beispieltabelle:
     ```bash
     mysql -h 34.123.45.67 -u app_user -papppassword456 weather_db <<EOF
     CREATE TABLE weather_data (
       id INT AUTO_INCREMENT PRIMARY KEY,
       year INT,
       month INT,
       avg_temp_celsius FLOAT
     );
     INSERT INTO weather_data (year, month, avg_temp_celsius) VALUES
       (2023, 1, 2.0), (2023, 2, 3.5), (2023, 3, 5.8),
       (2024, 1, 2.2), (2024, 2, 3.7), (2024, 3, 6.0);
     EOF
     ```

**Erkenntnis**: Cloud SQL vereinfacht die Bereitstellung und Verwaltung relationaler Datenbanken mit automatischer Skalierung und Wartung.

**Quelle**: https://cloud.google.com/sql/docs/mysql

### Übung 2: Integration mit Backend-Microservice

**Ziel**: Integriere Cloud SQL in den Backend-Microservice auf GKE.

**Aufgabe**: Erweitere den Backend-Microservice, um Wetterdaten aus Cloud SQL bereitzustellen.

1. **Backend aktualisieren**:
   - Aktualisiere `backend/server.js` (aus `gcp_cicd_microservices_guide.md`):
     ```bash
     nano backend/server.js
     ```
     - Inhalt:
       ```javascript
       const express = require('express');
       const mysql = require('mysql2/promise');
       const prom = require('prom-client');
       const app = express();

       const collectDefaultMetrics = prom.collectDefaultMetrics;
       collectDefaultMetrics();
       const queryCounter = new prom.Counter({
         name: 'sql_queries_total',
         help: 'Total number of SQL queries executed'
       });

       const pool = mysql.createPool({
         host: process.env.DB_HOST,
         user: process.env.DB_USER,
         password: process.env.DB_PASSWORD,
         database: process.env.DB_NAME,
         waitForConnections: true,
         connectionLimit: 10
       });

       app.get('/metrics', async (req, res) => res.send(await prom.register.metrics()));
       app.get('/api/data', (req, res) => res.json({ message: 'Backend Data' }));
       app.get('/api/weather', async (req, res) => {
         try {
           const [rows] = await pool.query('SELECT * FROM weather_data WHERE year = ? AND month = ?', [req.query.year, req.query.month]);
           queryCounter.inc();
           res.json(rows[0] || { message: 'No data found' });
         } catch (error) {
           res.status(500).json({ error: error.message });
         }
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
         "mysql2": "^3.6.0",
         "prom-client": "^14.2.0"
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

2. **Umgebungsvariablen für GKE**:
   - Erstelle ein Kubernetes-Secret für DB-Credentials:
     ```bash
     kubectl create secret generic db-credentials \
       --from-literal=DB_HOST=34.123.45.67 \
       --from-literal=DB_USER=app_user \
       --from-literal=DB_PASSWORD=apppassword456 \
       --from-literal=DB_NAME=weather_db
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
             image: gcr.io/homelab-lamp/backend:v5
             ports:
             - containerPort: 3001
             env:
             - name: DB_HOST
               valueFrom:
                 secretKeyRef:
                   name: db-credentials
                   key: DB_HOST
             - name: DB_USER
               valueFrom:
                 secretKeyRef:
                   name: db-credentials
                   key: DB_USER
             - name: DB_PASSWORD
               valueFrom:
                 secretKeyRef:
                   name: db-credentials
                   key: DB_PASSWORD
             - name: DB_NAME
               valueFrom:
                 secretKeyRef:
                   name: db-credentials
                   key: DB_NAME
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
   docker build -t gcr.io/homelab-lamp/backend:v5 ./backend
   docker push gcr.io/homelab-lamp/backend:v5
   kubectl apply -f backend-deployment.yaml
   ```

4. **API testen**:
   - Port-Forwarding für Backend:
     ```bash
     kubectl port-forward svc/backend-service 3001:3001
     ```
   - Teste:
     ```bash
     curl http://localhost:3001/api/weather?year=2023&month=1
     ```
     - Erwartete Ausgabe:
       ```json
       { "id": 1, "year": 2023, "month": 1, "avg_temp_celsius": 2.0 }
       ```

**Erkenntnis**: Cloud SQL lässt sich einfach in Microservices integrieren, mit sicheren Verbindungen über Secrets.

**Quelle**: https://cloud.google.com/sql/docs/mysql/connect-kubernetes

### Übung 3: Backup-Management mit TrueNAS

**Ziel**: Konfiguriere und automatisiere Cloud SQL-Backups mit Export nach TrueNAS.

**Aufgabe**: Erstelle automatische Backups und speichere sie auf TrueNAS.

1. **Cloud SQL-Backup einrichten**:
   - Aktiviere automatische Backups:
     ```bash
     gcloud sql instances patch homelab-mysql --backup-start-time 01:00
     ```
   - Prüfe Backups:
     ```bash
     gcloud sql backups list --instance=homelab-mysql
     ```

2. **Backup exportieren**:
   - Erstelle einen Google Cloud Storage-Bucket:
     ```bash
     gsutil mb -l europe-west1 gs://homelab-mysql-backups
     ```
   - Exportiere die Datenbank:
     ```bash
     gcloud sql export sql homelab-mysql gs://homelab-mysql-backups/weather_db-$(date +%F).sql.gz \
       --database=weather_db
     ```

3. **Backup auf TrueNAS synchronisieren**:
   - Installiere `gsutil` auf der Ubuntu-VM (falls nicht vorhanden):
     ```bash
     curl https://sdk.cloud.google.com | bash
     exec -l $SHELL
     gcloud init
     ```
   - Synchronisiere auf TrueNAS:
     ```bash
     gsutil cp gs://homelab-mysql-backups/weather_db-$(date +%F).sql.gz .
     rsync -av weather_db-$(date +%F).sql.gz root@192.168.30.100:/mnt/tank/backups/cloud-sql/
     ```
   - Automatisiere:
     ```bash
     nano /home/ubuntu/backup.sh
     ```
     - Inhalt (am Ende hinzufügen):
       ```bash
       DATE=$(date +%F)
       gcloud sql export sql homelab-mysql gs://homelab-mysql-backups/weather_db-$DATE.sql.gz --database=weather_db
       gsutil cp gs://homelab-mysql-backups/weather_db-$DATE.sql.gz /home/ubuntu
       rsync -av /home/ubuntu/weather_db-$DATE.sql.gz root@192.168.30.100:/mnt/tank/backups/cloud-sql/
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

**Erkenntnis**: Cloud SQL-Backups mit TrueNAS-Integration sichern Daten zuverlässig und lokal.

**Quelle**: https://cloud.google.com/sql/docs/mysql/backup-recovery

### Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Aktualisiere die Firewall-Regel in OPNsense, um Zugriff auf `192.168.30.101:3306` (Cloud SQL Proxy, falls verwendet), `<frontend-service-ip>:80` (Frontend), und `34.123.45.67:3306` (Cloud SQL) von `192.168.30.0/24` zu erlauben:
     - Quelle: `192.168.30.0/24`
     - Ziel: `192.168.30.101`, `<frontend-service-ip>`, `34.123.45.67`
     - Ports: `80,3306`
     - Aktion: `Allow`

2. **Monitoring mit Checkmk (optional)**:
   - Konfiguriere Checkmk für Cloud SQL:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Füge einen MySQL-Check hinzu:
       - Gehe zu `Setup > Services > Manual checks > MySQL`.
       - Host: `homelab-microservices-node`.
       - Parameter: Host `34.123.45.67`, Benutzer `app_user`, Passwort `apppassword456`.
     - Prüfe:
       - Gehe zu `Monitor > All services > MySQL`.
       - Erwartete Ausgabe: Status `OK` für Datenbankverfügbarkeit.

### Schritt 5: Erweiterung der Übungen
1. **Cloud SQL Proxy für sichere Verbindungen**:
   - Installiere den Cloud SQL Proxy:
     ```bash
     wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O cloud_sql_proxy
     chmod +x cloud_sql_proxy
     ./cloud_sql_proxy -instances=homelab-lamp:europ
e-west1:homelab-mysql=tcp:3306
     ```
   - Aktualisiere `backend-deployment.yaml` mit `DB_HOST=127.0.0.1`.

2. **Datenbank-Skalierung**:
   - Skaliere die Cloud SQL-Instanz:
     ```bash
     gcloud sql instances patch homelab-mysql --tier=db-n1-standard-1
     ```
   - Teste die Performance mit mehr Daten:
     ```bash
     mysql -h 34.123.45.67 -u app_user -papppassword456 weather_db -e "INSERT INTO weather_data (year, month, avg_temp_celsius) SELECT year, month, avg_temp_celsius FROM weather_data"
     ```

## Best Practices für Schüler

- **Datenbank-Design**:
  - Nutze Cloud SQL für verwaltete Datenbanken, vermeide lokale Installationen.
  - Verwende Secrets für sichere Credentials.
- **Sicherheit**:
  - Schränke Netzwerkzugriff ein:
    ```bash
    sudo ufw allow from 192.168.30.0/24 to any port 80
    sudo ufw allow from 192.168.30.0/24 to any port 3306
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (Cloud SQL, GCS, TrueNAS), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe Cloud SQL-Logs:
    ```bash
    gcloud sql instances describe homelab-mysql
    ```
  - Prüfe GKE-Logs:
    ```bash
    kubectl logs deployment/backend-deployment
    ```

**Quelle**: https://cloud.google.com/sql/docs/mysql, https://cloud.google.com/kubernetes-engine/docs

## Empfehlungen für Schüler

- **Setup**: Cloud SQL (MySQL), GKE, TrueNAS-Backups.
- **Workloads**: Wetterdaten-API mit Cloud SQL-Integration.
- **Integration**: Proxmox (VM), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: MySQL-Datenbank mit Microservice-Zugriff.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einer kleinen Cloud SQL-Instanz, erweitere bei Bedarf.
- **Übung**: Experimentiere mit komplexeren SQL-Abfragen oder Skalierung.
- **Fehlerbehebung**: Nutze `gcloud sql logs` und `kubectl logs`.
- **Lernressourcen**: https://cloud.google.com/sql/docs, https://dev.mysql.com/doc.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Bereitstellung und Verwaltung von Cloud SQL für Microservices.
- **Skalierbarkeit**: Automatische Backups und Integration mit GKE.
- **Lernwert**: Verständnis von Cloud-Datenbanken und Microservices.

**Nächste Schritte**: Möchtest du eine Anleitung zu erweiterten Blue-Green Deployments, Log-Aggregation mit Fluentd, oder Integration mit Vertex AI?

**Quellen**:
- Cloud SQL-Dokumentation: https://cloud.google.com/sql/docs
- GKE-Dokumentation: https://cloud.google.com/kubernetes-engine/docs
- MySQL-Dokumentation: https://dev.mysql.com/doc
- Webquellen:,,,,,
```