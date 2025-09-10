# Lernprojekt: Integration von ELK Stack mit Kubernetes in einer HomeLab

## Einführung

Die **Integration von ELK Stack** (Elasticsearch, Logstash, Kibana) mit **Kubernetes** ermöglicht die zentralisierte Sammlung, Verarbeitung und Visualisierung von Logs aus Containern und Pods. Dieses Lernprojekt erweitert die vorherige ELK-Anleitung (`04_elk_installation_debian_lxc_guide.md`, und integriert ELK mit einem Kubernetes-Cluster (k3s) in einer HomeLab-Umgebung. Es ist für Lernende mit Grundkenntnissen in Linux, Docker, Kubernetes und Bash geeignet und nutzt eine Ubuntu-VM auf einem Proxmox VE-Server (IP `192.168.30.101`) mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement. Das Projekt umfasst drei Übungen: Einrichten von k3s, Integration von Filebeat für Log-Sammlung aus Kubernetes, und Visualisierung von Pod-Logs mit Kibana. Es baut auf der Webanwendung (`homelab-webapp`) aus `ci_cd_security_scanning_module.md` (artifact_id: `1e1b8b3b-2d70-4df2-a98d-eb84a96fbb95`) auf und ist lokal, kostenlos und datenschutzfreundlich.

**Voraussetzungen**:
- Ubuntu 22.04 VM auf Proxmox (ID 101, IP `192.168.30.101`), mit Docker installiert (siehe `01_containerization_orchestration_module.md`).
- Hardware: Mindestens 8 GB RAM, 4 CPU-Kerne, 30 GB freier Speicher (ELK + k3s).
- Grundkenntnisse in Linux (`bash`, `nano`), Docker, Kubernetes (k3s) und SSH.
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`).
- ELK Stack installiert (via APT oder LXC, siehe `04_elk_installation_debian_lxc_guide.md`).
- Webanwendung (`homelab-webapp:2.4`) aus `03_ci-cd_security_scanning_module.md`.
- Internetzugang für initiale Downloads (k3s, Filebeat).

**Ziele**:
- Einrichten eines Kubernetes-Clusters mit k3s.
- Integration von Filebeat zur Log-Sammlung aus Kubernetes-Pods.
- Visualisierung von Pod-Logs mit Kibana-Dashboards.
- Integration mit der HomeLab für Backups und Netzwerkmanagement.

**Hinweis**: Das Projekt verwendet k3s für einen leichtgewichtigen Kubernetes-Cluster und Filebeat für effiziente Log-Sammlung. Es ist lokal und nutzt Open-Source-Tools.

**Quellen**:
- k3s-Dokumentation: https://k3s.io
- Filebeat-Dokumentation: https://www.elastic.co/guide/en/beats/filebeat/current/index.html
- Kibana-Dokumentation: https://www.elastic.co/guide/en/kibana/current/index.html
- Webquellen:,,,,,

## Lernprojekt: ELK mit Kubernetes

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
2. **ELK Stack prüfen** (aus `elk_installation_debian_lxc_guide.md`):
   - Stelle sicher, dass Elasticsearch (`localhost:9200`), Logstash (`localhost:5044`) und Kibana (`localhost:5601`) laufen.
3. **Projektverzeichnis erstellen**:
   ```bash
   mkdir ~/elk-kubernetes
   cd ~/elk-kubernetes
   ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Proxmox und TrueNAS.

### Übung 1: Einrichten eines Kubernetes-Clusters mit k3s

**Ziel**: Einrichten eines Kubernetes-Clusters mit k3s für die Integration mit ELK.

**Aufgabe**: Installiere k3s, deploye die Webanwendung als Pod und überprüfe die Logs.

1. **k3s installieren**:
   ```bash
   curl -sfL https://get.k3s.io | sh -
   ```
   - Prüfe:
     ```bash
     sudo k3s kubectl get nodes
     ```
     - Erwartete Ausgabe:
       ```
       NAME      STATUS   ROLES                  AGE   VERSION
       ubuntu    Ready    control-plane,master   1m    v1.28.x+k3s1
       ```
   - Kopiere die Konfiguration:
     ```bash
     mkdir ~/.kube
     sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
     sudo chown ubuntu:ubuntu ~/.kube/config
     export KUBECONFIG=~/.kube/config
     ```

2. **Webanwendung als Pod deployen**:
   - Erstelle ein Deployment:
     ```bash
     nano webapp-deployment.yaml
     ```
     - Inhalt:
       ```yaml
       apiVersion: apps/v1
       kind: Deployment
       metadata:
         name: webapp-deployment
       spec:
         replicas: 2
         selector:
           matchLabels:
             app: webapp
         template:
           metadata:
             labels:
               app: webapp
           spec:
             containers:
             - name: webapp
               image: homelab-webapp:2.4
               ports:
               - containerPort: 5000
       ---
       apiVersion: v1
       kind: Service
       metadata:
         name: webapp-service
       spec:
         selector:
           app: webapp
         ports:
         - protocol: TCP
           port: 80
           targetPort: 5000
         type: NodePort
       ```
   - Anwenden:
     ```bash
     kubectl apply -f webapp-deployment.yaml
     ```
   - Prüfe:
     ```bash
     kubectl get pods
     kubectl get services
     ```
     - Erwartete Ausgabe:
       ```
       NAME                                READY   STATUS    RESTARTS   AGE
       webapp-deployment-xxx-pod1          1/1     Running   0          10s
       webapp-deployment-xxx-pod2          1/1     Running   0          10s

       NAME            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
       webapp-service  NodePort   10.43.x.x       <none>        80:3xxxx/TCP   10s
       ```
   - Teste:
     ```bash
     curl http://192.168.30.101:3xxxx  # NodePort aus kubectl get services
     ```
     - Erwartete Ausgabe:
       ```
       Willkommen in der HomeLab-Webanwendung! API-Key: my-secret-api-key-123
       ```

**Erkenntnis**: k3s ermöglicht einen einfachen Kubernetes-Cluster in der HomeLab, der Container-Anwendungen skaliert und Logs generiert.

**Quelle**: https://k3s.io

### Übung 2: Integration von Filebeat für Log-Sammlung aus Kubernetes

**Ziel**: Sammlung von Pod-Logs mit Filebeat und Weiterleitung zu Elasticsearch.

**Aufgabe**: Installiere Filebeat, konfiguriere es für Kubernetes-Logs und integriere es mit dem ELK Stack.

1. **Filebeat installieren**:
   ```bash
   wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.15.0-amd64.deb
   sudo dpkg -i filebeat-8.15.0-amd64.deb
   ```

2. **Filebeat für Kubernetes konfigurieren**:
   - Erstelle `/etc/filebeat/filebeat.yml`:
     ```bash
     sudo nano /etc/filebeat/filebeat.yml
     ```
     - Inhalt:
       ```yaml
       filebeat.inputs:
       - type: container
         paths:
           - '/var/lib/docker/containers/*/*.log'
         processors:
           - add_kubernetes_metadata:
               host: ${NODE_NAME}
               matchers:
               - logs_path:
                   logs_path: "/var/lib/docker/containers/"
       output.elasticsearch:
         hosts: ["http://localhost:9200"]
         index: "k8s-logs-%{+YYYY.MM.dd}"
       ```
   - **Erklärung**:
     - `type: container`: Sammelt Docker-Container-Logs.
     - `add_kubernetes_metadata`: Fügt Kubernetes-Metadaten (z. B. Pod-Name) hinzu.
     - `output.elasticsearch`: Sendet Logs an Elasticsearch.

3. **Filebeat starten**:
   ```bash
   sudo systemctl enable filebeat
   sudo systemctl start filebeat
   ```
   - Prüfe:
     ```bash
     sudo journalctl -u filebeat
     ```

4. **Logs generieren und prüfen**:
   - Generiere Logs in der Webanwendung:
     ```bash
     for i in {1..50}; do curl http://192.168.30.101:3xxxx; done
     ```
   - Prüfe in Kibana:
     - Öffne `http://192.168.30.101:5601`.
     - Erstelle ein Index-Pattern: `k8s-logs-*`.
     - Gehe zu `Analytics` -> `Discover` -> Index `k8s-logs-*`.
     - Erwartete Ausgabe: Logs mit Feldern wie `container.name`, `kubernetes.pod_name`, `message` (Apache-Logs).

**Erkenntnis**: Filebeat sammelt Kubernetes-Pod-Logs effizient und leitet sie an Elasticsearch weiter, ideal für containerisierte Umgebungen.

**Quelle**: https://www.elastic.co/guide/en/beats/filebeat/current/running-on-kubernetes.html

### Übung 3: Visualisierung von Kubernetes-Logs mit Kibana-Dashboards

**Ziel**: Visualisierung und Analyse von Kubernetes-Logs mit Kibana.

**Aufgabe**: Erstelle ein Kibana-Dashboard für Pod-Logs und Metriken.

1. **Index-Pattern in Kibana erstellen**:
   - Öffne `http://192.168.30.101:5601`.
   - Gehe zu `Stack Management` -> `Index Patterns` -> `Create index pattern`.
   - Name: `k8s-logs-*`.
   - Zeitfeld: `@timestamp`.
   - Klicke auf `Create index pattern`.

2. **Dashboard erstellen**:
   - Gehe zu `Analytics` -> `Dashboard` -> `Create dashboard`.
   - Füge Visualisierungen hinzu:
     - **Pod-Logs pro Minute**:
       - Typ: `Metric`.
       - Metrik: `Count`.
       - Zeitbereich: `Last 1 hour`.
     - **Top Pods**:
       - Typ: `Pie`.
       - Feld: `kubernetes.pod_name.keyword`.
     - **Anfragen pro Pod**:
       - Typ: `Bar`.
       - X-Achse: `kubernetes.pod_name.keyword`.
       - Y-Achse: `Count`.
       - Filter: `message: "Zugriff erfolgt"`.
   - Speichere das Dashboard als `Kubernetes Logs Dashboard`.

3. **Dashboard prüfen**:
   - Öffne das Dashboard unter `Dashboard` -> `Kubernetes Logs Dashboard`.
   - Erwartete Ausgabe: Visualisierungen zeigen Pod-Logs, Top-Pods und Anfragen.

**Erkenntnis**: Kibana ermöglicht die benutzerfreundliche Visualisierung von Kubernetes-Logs, ideal für die Fehlersuche in containerisierten Anwendungen.

**Quelle**: https://www.elastic.co/guide/en/kibana/current/dashboard.html

### Schritt 4: Integration mit HomeLab
1. **Backups auf TrueNAS**:
   - Archiviere das Projekt:
     ```bash
     tar -czf ~/elk-kubernetes-backup-$(date +%F).tar.gz ~/elk-kubernetes
     rsync -av ~/elk-kubernetes-backup-$(date +%F).tar.gz root@192.168.30.100:/mnt/tank/backups/elk-kubernetes/
     ```
   - Automatisiere:
     ```bash
     nano /home/ubuntu/backup.sh
     ```
     - Inhalt (am Ende hinzufügen):
       ```bash
       DATE=$(date +%F)
       tar -czf /home/ubuntu/elk-kubernetes-backup-$DATE.tar.gz ~/elk-kubernetes
       rsync -av /home/ubuntu/elk-kubernetes-backup-$DATE.tar.gz root@192.168.30.100:/mnt/tank/backups/elk-kubernetes/
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /home/ubuntu/backup.sh
       ```

2. **Netzwerkmanagement mit OPNsense**:
   - Aktualisiere die Firewall-Regel in OPNsense, um Zugriff auf `192.168.30.101:9200` (Elasticsearch), `192.168.30.101:5044` (Logstash), `192.168.30.101:5601` (Kibana), und `192.168.30.101:3xxxx` (Kubernetes Service) von `192.168.30.0/24` zu erlauben:
     - Quelle: `192.168.30.0/24`
     - Ziel: `192.168.30.101`
     - Ports: `9200,5044,5601,3xxxx`
     - Aktion: `Allow`

### Schritt 5: Erweiterung der Übungen
1. **Metricbeat für Metriken**:
   - Installiere Metricbeat:
     ```bash
     wget https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-8.15.0-amd64.deb
     sudo dpkg -i metricbeat-8.15.0-amd64.deb
     ```
   - Konfiguriere `/etc/metricbeat/metricbeat.yml`:
     ```yaml
     metricbeat.modules:
     - module: kubernetes
       enabled: true
       metricsets:
         - node
         - system
         - pod
         - container
     output.elasticsearch:
       hosts: ["http://localhost:9200"]
     ```
   - Starte Metricbeat:
     ```bash
     sudo systemctl enable metricbeat
     sudo systemctl start metricbeat
     ```
   - Prüfe Metriken in Kibana (Index `metricbeat-*`).

2. **Kibana Alerts**:
   - Erstelle eine Alert-Regel:
     - Gehe zu `Stack Management` -> `Rules` -> `Create rule`.
     - Index: `k8s-logs-*`.
     - Bedingung: `response:500` (HTTP-Fehler).
     - Aktion: E-Mail (konfiguriere SMTP in `Stack Management` -> `Notifications`).

## Best Practices für Schüler

- **Ressourcenmanagement**:
  - Begrenze ELK-Ressourcen:
    - Elasticsearch: `ES_JAVA_OPTS=-Xms512m -Xmx512m`.
  - Überwache:
    ```bash
    docker stats  # Für Docker-ELK
    free -h
    ```
- **Sicherheit**:
  - Schränke Netzwerkzugriff ein:
    ```bash
    sudo ufw allow from 192.168.30.0/24 to any port 9200
    sudo ufw allow from 192.168.30.0/24 to any port 5044
    sudo ufw allow from 192.168.30.0/24 to any port 5601
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kop