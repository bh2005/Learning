# Lernprojekt: Containerisierung und Orchestrierung in einer HomeLab

## Einführung

**Containerisierung** mit **Docker** ermöglicht das Verpacken und Ausführen von Anwendungen in isolierten Umgebungen, während **Orchestrierung** mit **Kubernetes** die Skalierung und Verwaltung von Containern automatisiert. Dieses Lernprojekt führt Docker und Kubernetes in einer HomeLab-Umgebung ein, die auf einer Ubuntu-VM (Proxmox VE, IP `192.168.30.101`) mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement läuft. Es ist für Lernende mit Grundkenntnissen in Linux, Bash und Webservern geeignet und nutzt **k3s**, eine leichtgewichtige Kubernetes-Distribution, um die Hardwareanforderungen der HomeLab (z. B. 8 GB RAM, 4 CPU-Kerne) zu erfüllen. Das Projekt umfasst drei Übungen: Einführung in Docker (Images, Container, Volumes), Aufbau eines k3s-Clusters, und Bereitstellung einer Webanwendung mit Docker und Kubernetes. Es ist lokal, kostenlos und datenschutzfreundlich, da keine Cloud-Dienste genutzt werden.

**Voraussetzungen**:
- Ubuntu 22.04 VM auf Proxmox (ID 101, IP `192.168.30.101`), wie in vorherigen Projekten (z. B. `terraform_ansible_local_module.md`).
- Hardware: Mindestens 8 GB RAM, 4 CPU-Kerne, 20 GB freier Speicher.
- Grundkenntnisse in Linux (z. B. `bash`, `nano`) und SSH.
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`).
- Internetzugang für initiale Downloads (Docker, k3s).

**Ziele**:
- Verstehen von Docker-Grundlagen: Erstellen und Verwalten von Images, Containern und Volumes.
- Aufbau eines Kubernetes-Clusters mit k3s (Pods, Deployments, Services).
- Bereitstellung einer skalierbaren Webanwendung mit Docker und Kubernetes.
- Integration mit der HomeLab für Backups und Netzwerkmanagement.

**Hinweis**: Das Projekt ist lokal und kostenlos, nutzt Open-Source-Tools und schützt die Privatsphäre.

**Quellen**:
- Docker-Dokumentation: https://docs.docker.com
- Kubernetes-Dokumentation: https://kubernetes.io
- k3s-Dokumentation: https://k3s.io
- Webquellen:,,,,,

## Lernprojekt: Containerisierung und Orchestrierung

### Vorbereitung: VM und Umgebung einrichten
1. **Ubuntu-VM prüfen**:
   - Stelle sicher, dass die Ubuntu 22.04 VM (ID 101, IP `192.168.30.101`) auf Proxmox läuft:
     ```bash
     ssh ubuntu@192.168.30.101
     ```
   - Prüfe Ressourcen:
     ```bash
     free -h
     df -h
     ```
2. **Docker installieren**:
   ```bash
   sudo apt update
   sudo apt install -y docker.io
   sudo systemctl enable docker
   sudo systemctl start docker
   sudo usermod -aG docker ubuntu
   ```
   - Melde dich ab und erneut an:
     ```bash
     exit
     ssh ubuntu@192.168.30.101
     ```
   - Prüfe:
     ```bash
     docker --version  # Erwartet: Docker version 20.x oder höher
     ```
3. **Projektverzeichnis erstellen**:
   ```bash
   mkdir ~/container-project
   cd ~/container-project
   ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Proxmox und TrueNAS.

### Übung 1: Docker-Grundlagen (Images, Container, Volumes)

**Ziel**: Erstellen und Verwalten von Docker-Images, Containern und Volumes.

**Aufgabe**: Erstelle ein Docker-Image für eine einfache Webanwendung, starte einen Container und persistiere Daten mit Volumes.

1. **Dockerfile für eine Webanwendung erstellen**:
   ```bash
   nano Dockerfile
   ```
   - Inhalt:
     ```dockerfile
     FROM python:3.9-slim
     WORKDIR /app
     COPY app.py .
     RUN pip install flask
     EXPOSE 5000
     CMD ["python", "app.py"]
     ```
   - **Erklärung**:
     - `FROM python:3.9-slim`: Basis-Image mit Python.
     - `WORKDIR /app`: Arbeitsverzeichnis im Container.
     - `COPY app.py`: Kopiert die Anwendung.
     - `RUN pip install flask`: Installiert Flask.
     - `EXPOSE 5000`: Öffnet Port 5000.
     - `CMD`: Startet die Anwendung.

2. **Python-Webanwendung erstellen**:
   ```bash
   nano app.py
   ```
   - Inhalt:
     ```python
     from flask import Flask
     app = Flask(__name__)

     @app.route('/')
     def home():
         return "Willkommen in der HomeLab-Webanwendung!"

     if __name__ == "__main__":
         app.run(host="0.0.0.0", port=5000)
     ```

3. **Docker-Image erstellen**:
   ```bash
   docker build -t homelab-webapp:1.0 .
   ```
   - Prüfe:
     ```bash
     docker images
     ```

4. **Container starten**:
   ```bash
   docker run -d -p 5000:5000 --name webapp-container homelab-webapp:1.0
   ```
   - Teste:
     ```bash
     curl http://192.168.30.101:5000
     ```
     - Erwartete Ausgabe:
       ```
       Willkommen in der HomeLab-Webanwendung!
       ```

5. **Volume für persistente Daten erstellen**:
   - Erstelle ein Volume:
     ```bash
     docker volume create webapp-data
     ```
   - Stoppe und entferne den Container:
     ```bash
     docker stop webapp-container
     docker rm webapp-container
     ```
   - Starte mit Volume:
     ```bash
     docker run -d -p 5000:5000 --name webapp-container -v webapp-data:/app/data homelab-webapp:1.0
     ```
   - **Hinweis**: Das Volume speichert Daten in `/app/data` im Container.

6. **Daten persistieren**:
   - Passe `app.py` an, um eine Datei zu schreiben:
     ```bash
     nano app.py
     ```
     - Inhalt:
       ```python
       from flask import Flask
       import os

       app = Flask(__name__)

       @app.route('/')
       def home():
           with open('/app/data/log.txt', 'a') as f:
               f.write("Zugriff erfolgt!\n")
           return "Willkommen in der HomeLab-Webanwendung!"

       if __name__ == "__main__":
           app.run(host="0.0.0.0", port=5000)
       ```
   - Baue das Image neu:
     ```bash
     docker build -t homelab-webapp:1.1 .
     ```
   - Starte den Container neu:
     ```bash
     docker stop webapp-container
     docker rm webapp-container
     docker run -d -p 5000:5000 --name webapp-container -v webapp-data:/app/data homelab-webapp:1.1
     ```
   - Teste und prüfe die persistente Datei:
     ```bash
     curl http://192.168.30.101:5000
     docker exec webapp-container cat /app/data/log.txt
     ```
     - Erwartete Ausgabe:
       ```
       Zugriff erfolgt!
       ```

**Erkenntnis**: Docker ermöglicht das Erstellen von Images mit `Dockerfile`, das Ausführen von Containern und das Persistieren von Daten mit Volumes, ideal für isolierte Anwendungen in der HomeLab.

**Quelle**: https://docs.docker.com/get-started/

### Übung 2: Kubernetes-Einstieg mit k3s (Pods, Deployments, Services)

**Ziel**: Aufbau eines einfachen Kubernetes-Clusters mit k3s und Einführung in Pods, Deployments und Services.

**Aufgabe**: Installiere k3s, erstelle ein Deployment und mache die Webanwendung über einen Service zugänglich.

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
   - Kopiere die Konfiguration für `kubectl`:
     ```bash
     mkdir ~/.kube
     sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
     sudo chown ubuntu:ubuntu ~/.kube/config
     export KUBECONFIG=~/.kube/config
     ```

2. **Pod erstellen**:
   ```bash
   nano pod.yaml
   ```
   - Inhalt:
     ```yaml
     apiVersion: v1
     kind: Pod
     metadata:
       name: webapp-pod
     spec:
       containers:
       - name: webapp
         image: homelab-webapp:1.1
         ports:
         - containerPort: 5000
     ```
   - Anwenden:
     ```bash
     kubectl apply -f pod.yaml
     ```
   - Prüfe:
     ```bash
     kubectl get pods
     ```
     - Erwartete Ausgabe:
       ```
       NAME         READY   STATUS    RESTARTS   AGE
       webapp-pod   1/1     Running   0          10s
       ```

3. **Deployment erstellen**:
   - Lösche den Pod:
     ```bash
     kubectl delete -f pod.yaml
     ```
   - Erstelle ein Deployment:
     ```bash
     nano deployment.yaml
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
               image: homelab-webapp:1.1
               ports:
               - containerPort: 5000
       ```
   - Anwenden:
     ```bash
     kubectl apply -f deployment.yaml
     ```
   - Prüfe:
     ```bash
     kubectl get deployments
     kubectl get pods
     ```
     - Erwartete Ausgabe:
       ```
       NAME               READY   UP-TO-DATE   AVAILABLE   AGE
       webapp-deployment  2/2     2            2           10s

       NAME                                READY   STATUS    RESTARTS   AGE
       webapp-deployment-xxx-pod1          1/1     Running   0          10s
       webapp-deployment-xxx-pod2          1/1     Running   0          10s
       ```

4. **Service erstellen**:
   ```bash
   nano service.yaml
   ```
   - Inhalt:
     ```yaml
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
     kubectl apply -f service.yaml
     ```
   - Prüfe:
     ```bash
     kubectl get services
     ```
     - Erwartete Ausgabe:
       ```
       NAME            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
       webapp-service  NodePort   10.43.x.x       <none>        80:3xxxx/TCP   10s
       ```
   - Finde den NodePort (z. B. 30001):
     ```bash
     kubectl describe service webapp-service
     ```
   - Teste:
     ```bash
     curl http://192.168.30.101:30001
     ```
     - Erwartete Ausgabe:
       ```
       Willkommen in der HomeLab-Webanwendung!
       ```

**Erkenntnis**: k3s ermöglicht einen einfachen Kubernetes-Cluster in der HomeLab. Pods, Deployments und Services bieten eine skalierbare Möglichkeit, Container-Anwendungen zu verwalten.

**Quelle**: https://k3s.io, https://kubernetes.io/docs/concepts/

### Übung 3: Bereitstellung einer skalierbaren Webanwendung

**Ziel**: Bereitstellen einer Webanwendung mit Docker und Kubernetes, inklusive persistenter Speicherung und Skalierung.

**Aufgabe**: Bereitstelle die Webanwendung aus Übung 1 mit Kubernetes, füge persistente Speicherung hinzu und skaliere das Deployment.

1. **Persistente Speicherung mit PersistentVolume (PV) und PersistentVolumeClaim (PVC)**:
   - Erstelle ein PV:
     ```bash
     nano pv.yaml
     ```
     - Inhalt:
       ```yaml
       apiVersion: v1
       kind: PersistentVolume
       metadata:
         name: webapp-pv
       spec:
         capacity:
           storage: 1Gi
         accessModes:
           - ReadWriteOnce
         hostPath:
           path: /mnt/webapp-data
       ```
   - Erstelle einen PVC:
     ```bash
     nano pvc.yaml
     ```
     - Inhalt:
       ```yaml
       apiVersion: v1
       kind: PersistentVolumeClaim
       metadata:
         name: webapp-pvc
       spec:
         accessModes:
           - ReadWriteOnce
         resources:
           requests:
             storage: 1Gi
       ```
   - Anwenden:
     ```bash
     kubectl apply -f pv.yaml
     kubectl apply -f pvc.yaml
     ```

2. **Deployment mit PVC aktualisieren**:
   ```bash
   nano deployment.yaml
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
             image: homelab-webapp:1.1
             ports:
             - containerPort: 5000
             volumeMounts:
             - name: webapp-storage
               mountPath: /app/data
           volumes:
           - name: webapp-storage
             persistentVolumeClaim:
               claimName: webapp-pvc
     ```
   - Anwenden:
     ```bash
     kubectl apply -f deployment.yaml
     ```

3. **Service prüfen**:
   - Stelle sicher, dass der Service aus Übung 2 aktiv ist:
     ```bash
     kubectl get services
     curl http://192.168.30.101:30001
     ```
   - Prüfe persistente Daten:
     ```bash
     kubectl exec -it $(kubectl get pods -l app=webapp -o jsonpath="{.items[0].metadata.name}") -- cat /app/data/log.txt
     ```
     - Erwartete Ausgabe:
       ```
       Zugriff erfolgt!
       ```

4. **Deployment skalieren**:
   ```bash
   kubectl scale deployment webapp-deployment --replicas=3
   ```
   - Prüfe:
     ```bash
     kubectl get pods
     ```
     - Erwartete Ausgabe: 3 Pods laufen.
   - Teste erneut:
     ```bash
     curl http://192.168.30.101:30001
     ```

**Erkenntnis**: Kubernetes ermöglicht die Skalierung von Containern und die Verwaltung persistenter Daten, was Webanwendungen in der HomeLab robust und flexibel macht.

**Quelle**: https://kubernetes.io/docs/concepts/storage/persistent-volumes/

### Schritt 4: Integration mit HomeLab
1. **Backups auf TrueNAS**:
   - Archiviere das Projekt:
     ```bash
     tar -czf ~/container-project-backup-$(date +%F).tar.gz ~/container-project
     rsync -av ~/container-project-backup-$(date +%F).tar.gz root@192.168.30.100:/mnt/tank/backups/container/
     ```
   - Automatisiere:
     ```bash
     nano /home/ubuntu/backup.sh
     ```
     - Inhalt (am Ende hinzufügen):
       ```bash
       DATE=$(date +%F)
       tar -czf /home/ubuntu/container-project-backup-$DATE.tar.gz ~/container-project
       rsync -av /home/ubuntu/container-project-backup-$DATE.tar.gz root@192.168.30.100:/mnt/tank/backups/container/
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /home/ubuntu/backup.sh
       ```

2. **Netzwerkmanagement mit OPNsense**:
   - Füge eine Firewall-Regel in OPNsense hinzu, um Zugriff auf `192.168.30.101:30001` (NodePort) von `192.168.30.0/24` zu erlauben:
     - Quelle: `192.168.30.0/24`
     - Ziel: `192.168.30.101`
     - Port: `30001`
     - Aktion: `Allow`

### Schritt 5: Erweiterung der Übungen
1. **Docker Compose**:
   - Erstelle eine `docker-compose.yml` für die Webanwendung:
     ```bash
     nano docker-compose.yml
     ```
     - Inhalt:
       ```yaml
       version: '3'
       services:
         webapp:
           image: homelab-webapp:1.1
           ports:
             - "5000:5000"
           volumes:
             - webapp-data:/app/data
       volumes:
         webapp-data:
       ```
   - Starte:
     ```bash
     docker-compose up -d
     ```

2. **Kubernetes Ingress**:
   - Installiere einen Ingress-Controller (z. B. Traefik) in k3s:
     ```bash
     kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v2.10/docs/content/reference/dynamic-configuration/k8s-crd-rbac.yaml
     ```
   - Erstelle ein Ingress:
     ```bash
     nano ingress.yaml
     ```
     - Inhalt:
       ```yaml
       apiVersion: networking.k8s.io/v1
       kind: Ingress
       metadata:
         name: webapp-ingress
       spec:
         rules:
         - http:
             paths:
             - path: /
               pathType: Prefix
               backend:
                 service:
                   name: webapp-service
                   port:
                     number: 80
       ```
   - Anwenden:
     ```bash
     kubectl apply -f ingress.yaml
     ```

## Best Practices für Schüler

- **Ressourcenmanagement**:
  - Überwache Docker und k3s:
    ```bash
    docker ps
    kubectl get pods --all-namespaces
    free -h
    df -h
    ```
- **Sicherheit**:
  - Schränke Zugriff ein:
    ```bash
    sudo ufw allow from 192.168.30.0/24 to any port 30001
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
    docker logs webapp-container
    ```
  - Prüfe k3s-Logs:
    ```bash
    sudo journalctl -u k3s
    ```

**Quelle**: https://docs.docker.com, https://k3s.io

## Empfehlungen für Schüler

- **Setup**: Docker und k3s auf Ubuntu-VM, TrueNAS-Backups.
- **Workloads**: Webanwendung mit Docker, skalierbar mit Kubernetes.
- **Integration**: Proxmox (VM), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Flask-Webanwendung mit persistenter Speicherung.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einem einzelnen Container und skaliere schrittweise.
- **Übung**: Experimentiere mit weiteren Images (z. B. `nginx`) oder Kubernetes-Ressourcen (z. B. ConfigMaps).
- **Fehlerbehebung**: Nutze `docker logs` und `kubectl describe` für Debugging.
- **Lernressourcen**: https://docs.docker.com, https://kubernetes.io, https://k3s.io.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Containerisierung mit Docker, Orchestrierung mit Kubernetes.
- **Datenschutz**: Lokale Umgebung ohne Cloud-Abhängigkeit.
- **Lernwert**: Verständnis von Images, Containern, Pods, Deployments und Services.

Es ist ideal für Schüler, die Containerisierung und Orchestrierung in einer HomeLab erkunden möchten.

**Nächste Schritte**: Möchtest du eine Anleitung zu Docker Compose, Kubernetes Ingress, Monitoring mit Prometheus, oder Integration mit Terraform/Ansible?

**Quellen**:
- Docker-Dokumentation: https://docs.docker.com
- Kubernetes-Dokumentation: https://kubernetes.io
- k3s-Dokumentation: https://k3s.io
- Proxmox VE-Dokumentation: https://pve.proxmox.com/pve-docs/
- Webquellen:,,,,,