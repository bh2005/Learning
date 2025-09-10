# Lernprojekt: Monitoring von Microservices auf GCP mit Prometheus und Checkmk

## Einführung

**Monitoring mit Prometheus und Checkmk** ermöglicht eine umfassende Überwachung von Microservices durch Metriken (Prometheus) und agentenbasiertes Systemmonitoring (Checkmk). Dieses Lernprojekt baut auf `gcp_cicd_microservices_guide.md` () und `elk_checkmk_integration_guide.md` () auf, indem es Prometheus für Kubernetes-Metriken und Checkmk für System- und Serviceüberwachung in einer Google Kubernetes Engine (GKE)-Umgebung integriert. Es ist für Lernende mit Grundkenntnissen in Linux, Docker, Kubernetes und Monitoring geeignet und nutzt die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense) für Backups. Das Projekt umfasst drei Übungen: Einrichten von Prometheus auf GKE, Integration von Checkmk für Systemmetriken, und Erstellung eines kombinierten Dashboards mit Grafana und Checkmk. Es nutzt den GCP Free Tier und ist lokal sowie datenschutzfreundlich.

**Voraussetzungen**:
- GCP-Konto mit aktiviertem Free Tier oder $300-Guthaben, Projekt `homelab-lamp` (Projekt-ID: z. B. `homelab-lamp-123456`).
- GKE-Cluster `homelab-microservices` mit Microservices (Frontend und Backend aus `gcp_cicd_microservices_guide.md`).
- Ubuntu-VM auf Proxmox (IP `192.168.30.101`) mit Checkmk Raw Edition installiert (siehe `elk_checkmk_integration_guide.md`).
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement.
- Google Cloud SDK (`gcloud`) und `kubectl` installiert.
- Grundkenntnisse in Prometheus, Grafana, Checkmk und Kubernetes.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`).

**Ziele**:
- Einrichten von Prometheus auf GKE für Microservices-Metriken.
- Integration von Checkmk für System- und Serviceüberwachung.
- Erstellung eines kombinierten Dashboards mit Grafana und Checkmk.
- Integration mit HomeLab für Backups.

**Hinweis**: Prometheus sammelt und speichert Metriken zeitserienbasiert, während Checkmk agentenbasierte Überwachung bietet – ideal für hybride Umgebungen.

**Quellen**:
- Prometheus-Dokumentation: https://prometheus.io/docs
- Checkmk-Dokumentation: https://docs.checkmk.com
- Grafana-Dokumentation: https://grafana.com/docs
- GKE-Dokumentation: https://cloud.google.com/kubernetes-engine/docs
- Webquellen:,,,,,

## Lernprojekt: Monitoring mit Prometheus und Checkmk

### Vorbereitung: Umgebung einrichten
1. **GKE-Umgebung prüfen**:
   - Stelle sicher, dass das GCP-Projekt aktiv ist:
     ```bash
     gcloud config set project homelab-lamp-123456
     ```
   - Prüfe GKE-Cluster:
     ```bash
     gcloud container clusters get-credentials homelab-microservices --zone europe-west1-b
     kubectl get pods
     ```
     - Erwartete Ausgabe: Frontend- und Backend-Pods (`frontend-deployment-xxx`, `backend-deployment-xxx`).
2. **Checkmk auf Ubuntu-VM prüfen**:
   - Verbinde dich mit der VM:
     ```bash
     ssh ubuntu@192.168.30.101
     ```
   - Prüfe Checkmk:
     ```bash
     curl http://192.168.30.101:5000/homelab
     sudo omd status homelab
     ```
3. **Projektverzeichnis erstellen**:
   ```bash
   mkdir ~/prometheus-checkmk-monitoring
   cd ~/prometheus-checkmk-monitoring
   ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf GKE und TrueNAS.

### Übung 1: Einrichten von Prometheus auf GKE

**Ziel**: Installiere Prometheus auf GKE, um Microservices-Metriken zu sammeln.

**Aufgabe**: Deploye Prometheus und konfiguriere es für Frontend- und Backend-Metriken.

1. **Prometheus-Operator installieren**:
   - Füge das Prometheus-Helm-Repository hinzu:
     ```bash
     helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
     helm repo update
     ```
   - Installiere Prometheus:
     ```bash
     helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace
     ```
   - Prüfe:
     ```bash
     kubectl get pods -n monitoring
     ```
     - Erwartete Ausgabe: Pods wie `prometheus-kube-prometheus-operator-xxx`, `prometheus-grafana-xxx`.

2. **Microservices für Metriken konfigurieren**:
   - Füge Metriken zum Backend hinzu (`backend/server.js`):
     ```javascript
     const express = require('express');
     const prom = require('prom-client');
     const app = express();

     const collectDefaultMetrics = prom.collectDefaultMetrics;
     collectDefaultMetrics();
     app.get('/metrics', async (req, res) => res.send(await prom.register.metrics()));
     app.get('/api/data', (req, res) => res.json({ message: 'Backend Data' }));
     app.listen(3001, () => console.log('Backend on port 3001'));
     ```
   - Aktualisiere `backend/package.json`:
     ```json
     "dependencies": {
       "express": "^4.18.2",
       "prom-client": "^14.2.0"
     }
     ```
   - Erstelle neuen Docker-Image:
     ```bash
     docker build -t gcr.io/homelab-lamp/backend:v2 ./backend
     docker push gcr.io/homelab-lamp/backend:v2
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
             image: gcr.io/homelab-lamp/backend:v2
             ports:
             - containerPort: 3001
     ```
   - Deploye:
     ```bash
     kubectl apply -f backend-deployment.yaml
     ```

3. **Prometheus für Microservices konfigurieren**:
   - Erstelle einen ServiceMonitor:
     ```bash
     nano service-monitor.yaml
     ```
     - Inhalt:
       ```yaml
       apiVersion: monitoring.coreos.com/v1
       kind: ServiceMonitor
       metadata:
         name: backend-monitor
         namespace: monitoring
       spec:
         selector:
           matchLabels:
             app: backend
         endpoints:
         - port: web
           path: /metrics
           interval: 15s
       ```
   - Aktualisiere `backend-service.yaml`:
     ```yaml
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
   - Anwenden:
     ```bash
     kubectl apply -f service-monitor.yaml
     kubectl apply -f backend-service.yaml
     ```

4. **Grafana prüfen**:
   - Port-Forwarding für Grafana:
     ```bash
     kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
     ```
   - Öffne `http://localhost:3000` (Standard-Login: `admin` / `prom-operator`).
   - Füge Prometheus als Datenquelle hinzu:
     - URL: `http://prometheus-operated:9090`.
   - Erstelle ein Dashboard:
     - Gehe zu `Dashboards > New > New Dashboard`.
     - Füge ein Panel hinzu: Metrik `http_requests_total`.
     - Erwartete Ausgabe: Metriken für Backend-Anfragen.

**Erkenntnis**: Prometheus sammelt Kubernetes- und Anwendungsmetriken effizient, Grafana visualisiert sie benutzerfreundlich.

**Quelle**: https://prometheus.io/docs, https://grafana.com/docs

### Übung 2: Integration von Checkmk für System- und Serviceüberwachung

**Ziel**: Nutze Checkmk auf der Ubuntu-VM, um GKE-Nodes und Systemmetriken zu überwachen.

**Aufgabe**: Konfiguriere Checkmk für GKE-Nodes und Microservices.

1. **Checkmk-Agent auf GKE-Nodes installieren**:
   - Verbinde dich mit der Ubuntu-VM:
     ```bash
     ssh ubuntu@192.168.30.101
     ```
   - Lade den Checkmk-Agent herunter:
     ```bash
     sudo omd su homelab
     cmk -v --package /omd/sites/homelab/share/check_mk/agents/check-mk-agent_2.3.0-latest_amd64.deb
     ```
   - Kopiere den Agent auf einen GKE-Node (manuelle Installation, da GKE-VMs eingeschränkt sind):
     ```bash
     gcloud compute ssh homelab-microservices-node --zone europe-west1-b
     sudo apt update
     sudo dpkg -i check-mk-agent_2.3.0-latest_amd64.deb
     ```
   - Prüfe den Agent:
     ```bash
     sudo systemctl status check-mk-agent
     ```

2. **Checkmk für GKE konfigurieren**:
   - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
   - Melde dich an (`cmkadmin` / Passwort aus `omd config homelab show ADMIN_PASSWORD`).
   - Füge den GKE-Node hinzu:
     - Gehe zu `Setup > Hosts > Add host`.
     - Hostname: `homelab-microservices-node`.
     - IP: Interne IP des GKE-Nodes (z. B. `10.128.0.2`, via `gcloud compute instances list`).
     - Speichern und `Discover services`.
   - Prüfe:
     - Gehe zu `Monitor > All services`.
     - Erwartete Ausgabe: Services wie `CPU load`, `Memory`, `Checkmk Agent`.

3. **Microservices überwachen**:
   - Erstelle eine Regel für HTTP-Checks:
     - Gehe zu `Setup > Services > Manual checks > HTTP`.
     - Host: `homelab-microservices-node`.
     - Service: `Frontend Service`.
     - URL: `http://<frontend-service-ip>` (z. B. `http://10.123.45.67`).
     - Speichern und `Discover services`.

**Erkenntnis**: Checkmk bietet detailliertes Systemmonitoring, ergänzt Prometheus für GKE-Nodes und Services.

**Quelle**: https://docs.checkmk.com/latest/en/monitoring_kubernetes.html

### Übung 3: Kombiniertes Dashboard mit Grafana und Checkmk

**Ziel**: Erstelle ein kombiniertes Dashboard mit Grafana (Prometheus-Metriken) und Checkmk (Systemmetriken).

**Aufgabe**: Visualisiere Kubernetes-Metriken und Systemstatus in einem Dashboard.

1. **Grafana-Dashboard für Prometheus-Metriken**:
   - Öffne Grafana: `kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80`.
   - Gehe zu `http://localhost:3000`.
   - Erstelle ein Dashboard:
     - Gehe zu `Dashboards > New > New Dashboard`.
     - Füge Panels hinzu:
       - **Pod CPU Usage**: Metrik `container_cpu_usage_seconds_total{namespace="default"}`.
       - **HTTP Requests**: Metrik `http_requests_total`.
       - **Pod Status**: Metrik `kube_pod_status_phase`.
     - Speichere als `Microservices Dashboard`.

2. **Checkmk-Dashboard für Systemmetriken**:
   - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
   - Gehe zu `Customize > Dashboards > Create Dashboard`.
   - Name: `GKE System Dashboard`.
   - Füge Widgets hinzu:
     - **CPU Usage**: `Graph > CPU utilization` für `homelab-microservices-node`.
     - **Memory Usage**: `Graph > Memory`.
     - **Frontend Status**: `Service state > Frontend Service`.
   - Speichere das Dashboard.
   - Prüfe:
     - Öffne `Dashboards > GKE System Dashboard`.

**Erkenntnis**: Grafana visualisiert Prometheus-Metriken, Checkmk bietet detaillierte Systemansichten – ideal für hybrides Monitoring.

**Quelle**: https://grafana.com/docs, https://docs.checkmk.com/latest/en/dashboards.html

### Schritt 4: Integration mit HomeLab
1. **Backups auf TrueNAS**:
   - Archiviere das Projekt:
     ```bash
     tar -czf ~/prometheus-checkmk-backup-$(date +%F).tar.gz ~/prometheus-checkmk-monitoring /omd/sites/homelab
     rsync -av ~/prometheus-checkmk-backup-$(date +%F).tar.gz root@192.168.30.100:/mnt/tank/backups/prometheus-checkmk/
     ```
   - Automatisiere:
     ```bash
     nano /home/ubuntu/backup.sh
     ```
     - Inhalt (am Ende hinzufügen):
       ```bash
       DATE=$(date +%F)
       tar -czf /home/ubuntu/prometheus-checkmk-backup-$DATE.tar.gz ~/prometheus-checkmk-monitoring /omd/sites/homelab
       rsync -av /home/ubuntu/prometheus-checkmk-backup-$DATE.tar.gz root@192.168.30.100:/mnt/tank/backups/prometheus-checkmk/
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
1. **Prometheus-Alerts**:
   - Konfiguriere Alertmanager:
     ```bash
     nano alertmanager-config.yaml
     ```
     - Inhalt:
       ```yaml
       apiVersion: monitoring.coreos.com/v1
       kind: Alertmanager
       metadata:
         name: alertmanager
         namespace: monitoring
       spec:
         replicas: 1
       ```
     - Anwenden:
       ```bash
       kubectl apply -f alertmanager-config.yaml
       ```
     - Erstelle eine Alert-Regel:
       ```yaml
       apiVersion: monitoring.coreos.com/v1
       kind: PrometheusRule
       metadata:
         name: backend-alerts
         namespace: monitoring
       spec:
         groups:
         - name: backend
           rules:
           - alert: HighRequestLatency
             expr: rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m]) > 0.5
             for: 5m
             labels:
               severity: warning
             annotations:
               summary: "Hohe Latenz im Backend"
       ```
     - Anwenden:
       ```bash
       kubectl apply -f alert-rules.yaml
       ```

2. **Checkmk-Integration mit Prometheus**:
   - Nutze das Checkmk-Prometheus-Plugin:
     ```bash
     sudo apt install -y check-mk-agent-prometheus
     ```
   - Konfiguriere Checkmk für Prometheus-Metriken:
     - Gehe zu `Setup > Services > Manual checks > Prometheus`.

## Best Practices für Schüler

- **Monitoring-Design**:
  - Nutze Prometheus für Kubernetes-Metriken, Checkmk für Systemmetriken.
  - Kombiniere Grafana und Checkmk für visuelle Übersichten.
- **Sicherheit**:
  - Schränke Netzwerkzugriff ein:
    ```bash
    sudo ufw allow from 192.168.30.0/24 to any port 3000
    sudo ufw allow from 192.168.30.0/24 to any port 5000
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe Prometheus-Logs:
    ```bash
    kubectl logs -n monitoring deployment/prometheus-kube-prometheus-operator
    ```
  - Prüfe Checkmk-Logs:
    ```bash
    sudo tail -f /omd/sites/homelab/var/log/web.log
    ```

**Quelle**: https://prometheus.io/docs, https://docs.checkmk.com

## Empfehlungen für Schüler

- **Setup**: Prometheus auf GKE, Checkmk auf Ubuntu-VM, TrueNAS-Backups.
- **Workloads**: Microservices-Metriken (Prometheus) und Systemmetriken (Checkmk).
- **Integration**: Proxmox (VM), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Dashboard mit CPU, Metriken und Service-Status.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit Prometheus für Metriken, integriere Checkmk schrittweise.
- **Übung**: Experimentiere mit weiteren Metriken (z. B. Datenbank-Metriken).
- **Fehlerbehebung**: Nutze `kubectl logs` und Checkmk-Service-Scans.
- **Lernressourcen**: https://prometheus.io/docs, https://docs.checkmk.com, https://grafana.com/docs.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Kombination von Prometheus und Checkmk für umfassendes Monitoring.
- **Skalierbarkeit**: GKE-Metriken mit Prometheus, Systemmetriken mit Checkmk.
- **Lernwert**: Verständnis von hybriden Monitoring-Ansätzen.

**Nächste Schritte**: Möchtest du eine Anleitung zu Integration mit BigQuery ML, erweiterten Blue-Green Deployments oder Log-Aggregation mit Fluentd?

**Quellen**:
- Prometheus-Dokumentation: https://prometheus.io/docs
- Checkmk-Dokumentation: https://docs.checkmk.com
- Grafana-Dokumentation: https://grafana.com/docs
- GKE-Dokumentation: https://cloud.google.com/kubernetes-engine/docs
- Webquellen:,,,,,
```