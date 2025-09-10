# Lernprojekt: Erweitertes Monitoring und Logging in einer HomeLab

## Einführung

**Erweitertes Monitoring und Logging** mit **Prometheus** (pull-basiertes Monitoring) und **Grafana** (Metrik-Visualisierung) ermöglicht die Überwachung und Analyse von Systemen und Anwendungen in Echtzeit. Dieses Lernprojekt führt die Einrichtung von Prometheus und Grafana in einer HomeLab-Umgebung ein, die auf einer Ubuntu-VM (Proxmox VE, IP `192.168.30.101`) mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement läuft. Es ist für Lernende mit Grundkenntnissen in Linux, Docker, Bash und Netzwerkkonzepten geeignet und baut auf `ci_cd_security_scanning_module.md` auf, nutzt die Webanwendung (`homelab-webapp:2.4`). Das Projekt umfasst drei Übungen: Einrichten von Prometheus für pull-basiertes Monitoring, Einrichten von Grafana für Visualisierung, und Integration mit der Webanwendung für anwendungsspezifisches Monitoring. Es ist lokal, kostenlos und datenschutzfreundlich.

**Voraussetzungen**:
- Ubuntu 22.04 VM auf Proxmox (ID 101, IP `192.168.30.101`), mit Docker installiert (siehe `03_ci_cd_security_scanning_module.md`).
- Hardware: Mindestens 8 GB RAM, 4 CPU-Kerne, 20 GB freier Speicher.
- Grundkenntnisse in Linux (`bash`, `nano`), Docker, Git und SSH.
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`).
- Webanwendung aus `03_ci_cd_security_scanning_module.md` (`homelab-webapp:2.4`, Flask-basiert).
- Internetzugang für initiale Downloads (Prometheus, Grafana).

**Ziele**:
- Einrichten von Prometheus für pull-basiertes Monitoring von System- und Anwendungsmetriken.
- Einrichten von Grafana für die Visualisierung von Metriken.
- Integration mit der Webanwendung für anwendungsspezifisches Monitoring.
- Integration mit der HomeLab für Backups und Netzwerkmanagement.

**Hinweis**: Das Projekt ist lokal und nutzt Open-Source-Tools, um die Privatsphäre zu schützen.

**Quellen**:
- Prometheus-Dokumentation: https://prometheus.io/docs
- Grafana-Dokumentation: https://grafana.com/docs
- Webquellen:,,,,,

## Lernprojekt: Erweitertes Monitoring und Logging

### Vorbereitung: Umgebung einrichten
1. **Ubuntu-VM prüfen**:
   - Stelle sicher, dass die Ubuntu-VM (IP `192.168.30.101`) läuft:
     ```bash
     ssh ubuntu@192.168.30.101
     ```
   - Prüfe Docker:
     ```bash
     docker --version  # Erwartet: Docker version 20.x oder höher
     ```
   - Prüfe Ressourcen:
     ```bash
     free -h
     df -h
     ```
2. **Projektverzeichnis erstellen**:
   ```bash
   mkdir ~/monitoring-logging
   cd ~/monitoring-logging
   ```
3. **Webanwendung kopieren**:
   - Kopiere `Dockerfile`, `app.py`, `docker-compose.yml`, und `api_key.txt` aus `~/ci-cd-security`:
     ```bash
     cp ~/ci-cd-security/{Dockerfile,app.py,docker-compose.yml,api_key.txt} .
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Proxmox und TrueNAS.

### Übung 1: Einrichten von Prometheus für pull-basiertes Monitoring

**Ziel**: Einrichten von Prometheus zur Erfassung von System- und Container-Metriken.

**Aufgabe**: Installiere Prometheus, konfiguriere es für die Überwachung der VM und der Webanwendung, und überprüfe die Metriken.

1. **Prometheus mit Docker einrichten**:
   - Erstelle eine Prometheus-Konfigurationsdatei:
     ```bash
     mkdir prometheus
     nano prometheus/prometheus.yml
     ```
     - Inhalt:
       ```yaml
       global:
         scrape_interval: 15s
       scrape_configs:
         - job_name: 'prometheus'
           static_configs:
             - targets: ['localhost:9090']
         - job_name: 'node'
           static_configs:
             - targets: ['node-exporter:9100']
         - job_name: 'webapp'
           static_configs:
             - targets: ['webapp:5000']
       ```
   - **Erklärung**:
     - `scrape_interval`: Metriken werden alle 15 Sekunden abgefragt.
     - `prometheus`: Überwacht Prometheus selbst.
     - `node`: Überwacht die VM mit Node Exporter.
     - `webapp`: Überwacht die Webanwendung.

2. **Node Exporter für Systemmetriken starten**:
   ```bash
   docker run -d --name node-exporter \
     -p 9100:9100 \
     prom/node-exporter:latest
   ```

3. **Prometheus starten**:
   ```bash
   docker run -d --name prometheus \
     -p 9090:9090 \
     -v $(pwd)/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
     prom/prometheus:latest
   ```

4. **Webanwendung starten**:
   ```bash
   docker-compose up -d
   ```

5. **Prometheus prüfen**:
   - Öffne `http://192.168.30.101:9090` in einem Browser (oder via `curl`):
     ```bash
     curl http://192.168.30.101:9090
     ```
   - Prüfe Targets:
     - Gehe zu `http://192.168.30.101:9090/targets` (Status -> Targets).
     - Erwartete Ausgabe: `prometheus`, `node`, `webapp` sind "UP".
   - Teste eine Metrik (z. B. CPU-Nutzung):
     ```bash
     curl http://192.168.30.101:9100/metrics | grep node_cpu_seconds_total
     ```

**Erkenntnis**: Prometheus ermöglicht pull-basiertes Monitoring von System- und Anwendungsmetriken, ideal für die HomeLab.

**Quelle**: https://prometheus.io/docs/introduction/overview/

### Übung 2: Einrichten von Grafana für Metrik-Visualisierung

**Ziel**: Einrichten von Grafana zur Visualisierung von Prometheus-Metriken.

**Aufgabe**: Installiere Grafana, verbinde es mit Prometheus, und erstelle ein Dashboard.

1. **Grafana mit Docker einrichten**:
   ```bash
   docker run -d --name grafana \
     -p 3000:3000 \
     grafana/grafana-oss:latest
   ```

2. **Grafana konfigurieren**:
   - Öffne `http://192.168.30.101:3000` in einem Browser.
   - Standard-Login: `admin` / `admin` (ändere das Passwort bei der ersten Anmeldung).
   - Füge Prometheus als Datenquelle hinzu:
     - Gehe zu `Configuration` -> `Data Sources` -> `Add data source`.
     - Wähle `Prometheus`.
     - Setze URL: `http://prometheus:9090`.
     - Klicke auf `Save & Test`.

3. **Dashboard erstellen**:
   - Gehe zu `Create` -> `Dashboard` -> `Add new panel`.
   - Beispiel-Metriken:
     - **CPU-Nutzung**: `rate(node_cpu_seconds_total{mode="user"}[5m])`
     - **Speicher**: `node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes`
     - Titel: `System CPU and Memory`.
     - Speichere das Dashboard als `HomeLab Monitoring`.

4. **Dashboard prüfen**:
   - Öffne `http://192.168.30.101:3000` und überprüfe das Dashboard.
   - Erwartete Ausgabe: Grafiken zeigen CPU- und Speicherauslastung.

**Erkenntnis**: Grafana visualisiert Prometheus-Metriken in benutzerfreundlichen Dashboards, ideal für die Analyse von Systemleistung.

**Quelle**: https://grafana.com/docs/grafana/latest/

### Übung 3: Integration mit der Webanwendung für anwendungsspezifisches Monitoring

**Ziel**: Erweitere die Webanwendung um Metriken und überwache sie mit Prometheus und Grafana.

**Aufgabe**: Passe die Webanwendung an, um Metriken bereitzustellen, und integriere sie in Prometheus und Grafana.

1. **Webanwendung für Metriken anpassen**:
   ```bash
   nano app.py
   ```
   - Inhalt:
     ```python
     from flask import Flask, Response
     from prometheus_client import Counter, generate_latest, REGISTRY
     import os

     app = Flask(__name__)

     # Prometheus-Metriken
     request_counter = Counter('webapp_requests_total', 'Total number of requests')

     @app.route('/')
     def home():
         request_counter.inc()
         api_key = "No API key found"
         api_key_file = os.getenv("API_KEY_FILE", "/run/secrets/api_key")
         if os.path.exists(api_key_file):
             with open(api_key_file, 'r') as f:
                 api_key = f.read().strip()
         with open('/app/data/log.txt', 'a') as f:
             f.write(f"Zugriff erfolgt, API-Key: {api_key}\n")
         response = Response(f"Willkommen in der HomeLab-Webanwendung! API-Key: {api_key}")
         response.headers['Content-Security-Policy'] = "default-src 'self'"
         response.headers['X-Content-Type-Options'] = 'nosniff'
         return response

     @app.route('/metrics')
     def metrics():
         return generate_latest(REGISTRY), 200, {'Content-Type': 'text/plain; version=0.0.4'}

     if __name__ == "__main__":
         app.run(host="0.0.0.0", port=5000)
     ```
   - **Erklärung**:
     - `prometheus_client`: Fügt Metriken hinzu.
     - `request_counter`: Zählt HTTP-Anfragen.
     - `/metrics`: Stellt Prometheus-Metriken bereit.

2. **Dockerfile aktualisieren**:
   ```bash
   nano Dockerfile
   ```
   - Inhalt:
     ```dockerfile
     FROM python:3.9-slim-bullseye
     WORKDIR /app
     RUN useradd -m appuser && chown -R appuser:appuser /app
     USER appuser
     COPY app.py .
     RUN pip install --no-cache-dir flask prometheus_client
     EXPOSE 5000
     CMD ["python", "app.py"]
     ```

3. **Image neu erstellen**:
   ```bash
   docker build -t homelab-webapp:2.5 .
   ```

4. **docker-compose.yml aktualisieren**:
   ```bash
   nano docker-compose.yml
   ```
   - Inhalt:
     ```yaml
     version: '3.7'
     services:
       webapp:
         image: homelab-webapp:2.5
         ports:
           - "5000:5000"
         volumes:
           - webapp-data:/app/data
         secrets:
           - api_key
         environment:
           - API_KEY_FILE=/run/secrets/api_key
         read_only: true
         cap_drop:
           - ALL
         cap_add:
           - NET_BIND_SERVICE
         networks:
           - monitoring-net
       prometheus:
         image: prom/prometheus:latest
         ports:
           - "9090:9090"
         volumes:
           - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
         networks:
           - monitoring-net
       node-exporter:
         image: prom/node-exporter:latest
         ports:
           - "9100:9100"
         networks:
           - monitoring-net
       grafana:
         image: grafana/grafana-oss:latest
         ports:
           - "3000:3000"
         networks:
           - monitoring-net
     secrets:
       api_key:
         file: ./api_key.txt
     volumes:
       webapp-data:
     networks:
       monitoring-net:
         driver: bridge
     ```

5. **Anwendung starten**:
   ```bash
   docker-compose up -d
   ```

6. **Metriken prüfen**:
   - Öffne `http://192.168.30.101:5000/metrics`:
     ```bash
     curl http://192.168.30.101:5000/metrics
     ```
     - Erwartete Ausgabe:
       ```
       webapp_requests_total 1.0
       ```
   - Füge ein Dashboard in Grafana hinzu:
     - Gehe zu `Create` -> `Dashboard` -> `Add new panel`.
     - Metrik: `rate(webapp_requests_total[5m])`.
     - Titel: `Webanwendung Requests`.
     - Speichere das Dashboard.

**Erkenntnis**: Die Integration von Prometheus-Metriken in die Webanwendung ermöglicht anwendungsspezifisches Monitoring, das in Grafana visualisiert wird.

**Quelle**: https://prometheus.io/docs/instrumenting/clientlibs/

### Schritt 4: Integration mit HomeLab
1. **Backups auf TrueNAS**:
   - Archiviere das Projekt:
     ```bash
     tar -czf ~/monitoring-logging-backup-$(date +%F).tar.gz ~/monitoring-logging
     rsync -av ~/monitoring-logging-backup-$(date +%F).tar.gz root@192.168.30.100:/mnt/tank/backups/monitoring-logging/
     ```
   - Automatisiere:
     ```bash
     nano /home/ubuntu/backup.sh
     ```
     - Inhalt (am Ende hinzufügen):
       ```bash
       DATE=$(date +%F)
       tar -czf /home/ubuntu/monitoring-logging-backup-$DATE.tar.gz ~/monitoring-logging
       rsync -av /home/ubuntu/monitoring-logging-backup-$DATE.tar.gz root@192.168.30.100:/mnt/tank/backups/monitoring-logging/
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /home/ubuntu/backup.sh
       ```

2. **Netzwerkmanagement mit OPNsense**:
   - Aktualisiere die Firewall-Regel in OPNsense, um Zugriff auf `192.168.30.101:5000` (Webanwendung), `192.168.30.101:9090` (Prometheus), `192.168.30.101:9100` (Node Exporter), und `192.168.30.101:3000` (Grafana) von `192.168.30.0/24` zu erlauben:
     - Quelle: `192.168.30.0/24`
     - Ziel: `192.168.30.101`
     - Ports: `5000,9090,9100,3000`
     - Aktion: `Allow`

### Schritt 5: Erweiterung der Übungen
1. **Alerting mit Prometheus**:
   - Konfiguriere Alerts in `prometheus/prometheus.yml`:
     ```yaml
     alerting:
       alertmanagers:
         - static_configs:
             - targets: ['alertmanager:9093']
     ```
   - Starte Alertmanager:
     ```bash
     docker run -d --name alertmanager -p 9093:9093 prom/alertmanager:latest
     ```
   - Füge eine Regel hinzu (z. B. für hohe CPU-Nutzung).

2. **Grafana Dashboards importieren**:
   - Importiere ein vorgefertigtes Dashboard (z. B. Node Exporter Dashboard ID 1860):
     - Gehe zu `Create` -> `Import` in Grafana.
     - ID: `1860`, Quelle: Prometheus.

## Best Practices für Schüler

- **Monitoring**:
  - Setze sinnvolle `scrape_interval` (z. B. 15s) für Echtzeit-Daten.
  - Verwende minimale Container (z. B. `prom/prometheus:latest`).
- **Sicherheit**:
  - Schränke Netzwerkzugriff ein:
    ```bash
    sudo ufw allow from 192.168.30.0/24 to any port 5000
    sudo ufw allow from 192.168.30.0/24 to any port 9090
    sudo ufw allow from 192.168.30.0/24 to any port 9100
    sudo ufw allow from 192.168.30.0/24 to any port 3000
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
    docker logs prometheus
    ```
  - Prüfe Grafana-Logs:
    ```bash
    docker logs grafana
    ```

**Quelle**: https://prometheus.io/docs, https://grafana.com/docs

## Empfehlungen für Schüler

- **Setup**: Prometheus, Grafana, Node Exporter, Webanwendung auf Ubuntu-VM, TrueNAS-Backups.
- **Workloads**: System- und Anwendungsmetriken, visualisiert in Grafana.
- **Integration**: Proxmox (VM), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Flask-Webanwendung mit Prometheus-Metriken.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einfachen Metriken (z. B. CPU, Speicher) und füge anwendungsspezifische hinzu.
- **Übung**: Experimentiere mit weiteren Metriken (z. B. `prometheus_http_requests_total`).
- **Fehlerbehebung**: Nutze Prometheus-Queries und Grafana-Logs für Debugging.
- **Lernressourcen**: https://prometheus.io/docs, https://grafana.com/docs, https://pve.proxmox.com/wiki.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Pull-basiertes Monitoring mit Prometheus, Visualisierung mit Grafana.
- **Datenschutz**: Lokale Umgebung ohne Cloud-Abhängigkeit.
- **Lernwert**: Verständnis von Metrik-Erfassung und Visualisierung.

Es ist ideal für Schüler, die erweitertes Monitoring in einer HomeLab erkunden möchten.

**Nächste Schritte**: Möchtest du eine Anleitung zu Alerting mit Alertmanager, Integration mit Kubernetes, oder Log-Aggregation mit Loki?

**Quellen**:
- Prometheus-Dokumentation: https://prometheus.io/docs
- Grafana-Dokumentation: https://grafana.com/docs
- Proxmox VE-Dokumentation: https://pve.proxmox.com/pve-docs/
- Webquellen:,,,,,