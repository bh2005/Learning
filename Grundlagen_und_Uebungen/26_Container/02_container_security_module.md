# Lernprojekt: Container-Sicherheit in einer HomeLab

## Einführung

**Container-Sicherheit** ist entscheidend, um Docker-Container vor Bedrohungen wie unbefugtem Zugriff, Schwachstellen in Images oder Datenlecks zu schützen. Dieses Lernprojekt führt **Best Practices für das Hardening von Docker-Containern** und die **Verwaltung von Geheimnissen** in einer HomeLab-Umgebung ein. Es läuft auf einer Ubuntu-VM (Proxmox VE, IP `192.168.30.101`) mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement und ist für Lernende mit Grundkenntnissen in Linux, Docker und Bash geeignet. Das Projekt baut auf `01_containerization_orchestration_module.md` auf und verwendet die Webanwendung aus diesem Modul. Es umfasst drei Übungen: Hardening von Docker-Containern (z. B. Minimierung von Images, Benutzerrechten, Netzwerksicherheit), Verwaltung von Geheimnissen mit Docker Secrets, und Sicherheitsüberprüfungen mit Trivy. Das Projekt ist lokal, kostenlos und datenschutzfreundlich.

**Voraussetzungen**:
- Ubuntu 22.04 VM auf Proxmox (ID 101, IP `192.168.30.101`), mit Docker installiert (siehe `01_containerization_orchestration_module.md`).
- Hardware: Mindestens 8 GB RAM, 4 CPU-Kerne, 20 GB freier Speicher.
- Grundkenntnisse in Linux (z. B. `bash`, `nano`), Docker (Images, Container, Volumes) und SSH.
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`).
- Internetzugang für initiale Downloads (z. B. Trivy).
- Webanwendung aus `01_containerization_orchestration_module.md` (`homelab-webapp:1.1`, Flask-basiert).

**Ziele**:
- Hardening von Docker-Containern durch Minimierung, Rechte-Management und Netzwerksicherheit.
- Verwaltung von Geheimnissen (z. B. API-Keys, Passwörter) mit Docker Secrets.
- Durchführung von Sicherheitsüberprüfungen mit Trivy.

**Hinweis**: Das Projekt ist lokal und nutzt Open-Source-Tools, um die Privatsphäre zu schützen.

**Quellen**:
- Docker-Dokumentation: https://docs.docker.com
- OWASP Container Security: https://owasp.org/www-project-container-security/
- Trivy-Dokumentation: https://aquasecurity.github.io/trivy
- Webquellen:,,,,,

## Lernprojekt: Container-Sicherheit

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
   mkdir ~/container-security
   cd ~/container-security
   ```
3. **Webanwendung aus vorherigem Projekt kopieren**:
   - Kopiere `Dockerfile` und `app.py` aus `~/container-project`:
     ```bash
     cp ~/container-project/Dockerfile .
     cp ~/container-project/app.py .
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Proxmox und TrueNAS.

### Übung 1: Hardening von Docker-Containern

**Ziel**: Hardening eines Docker-Containers durch Minimierung des Images, Einschränkung von Rechten und Netzwerksicherheit.

**Aufgabe**: Optimiere die Webanwendung (`homelab-webapp`) durch ein gehärtetes Image, nicht-root-Benutzer und Netzwerkschutz.

1. **Dockerfile für Hardening optimieren**:
   ```bash
   nano Dockerfile
   ```
   - Inhalt:
     ```dockerfile
     FROM python:3.9-slim
     WORKDIR /app
     RUN useradd -m appuser && chown -R appuser:appuser /app
     USER appuser
     COPY app.py .
     RUN pip install --no-cache-dir flask
     EXPOSE 5000
     CMD ["python", "app.py"]
     ```
   - **Erklärung**:
     - `python:3.9-slim`: Minimales Basis-Image zur Reduzierung der Angriffsfläche.
     - `useradd -m appuser`: Erstellt einen nicht-root-Benutzer.
     - `USER appuser`: Führt den Container als nicht-root aus.
     - `--no-cache-dir`: Reduziert Image-Größe durch Entfernen von pip-Cache.

2. **Image neu erstellen**:
   ```bash
   docker build -t homelab-webapp:2.0 .
   ```

3. **Container mit eingeschränkten Rechten starten**:
   ```bash
   docker run -d -p 5000:5000 --name webapp-secure \
     --read-only \
     --cap-drop=ALL \
     --cap-add=NET_BIND_SERVICE \
     -v webapp-data:/app/data \
     homelab-webapp:2.0
   ```
   - **Erklärung**:
     - `--read-only`: Macht das Dateisystem schreibgeschützt (außer `/app/data`).
     - `--cap-drop=ALL --cap-add=NET_BIND_SERVICE`: Entfernt alle Linux-Capabilities außer der für Port-Binding.
     - `-v webapp-data:/app/data`: Ermöglicht Schreiben in das Volume.

4. **Netzwerksicherheit einrichten**:
   - Erstelle ein benutzerdefiniertes Netzwerk:
     ```bash
     docker network create webapp-net
     ```
   - Starte den Container im Netzwerk:
     ```bash
     docker stop webapp-secure
     docker rm webapp-secure
     docker run -d -p 5000:5000 --name webapp-secure \
       --read-only \
       --cap-drop=ALL \
       --cap-add=NET_BIND_SERVICE \
       -v webapp-data:/app/data \
       --network webapp-net \
       homelab-webapp:2.0
     ```
   - Teste:
     ```bash
     curl http://192.168.30.101:5000
     ```
     - Erwartete Ausgabe:
       ```
       Willkommen in der HomeLab-Webanwendung!
       ```

5. **Container prüfen**:
   - Überprüfe den Benutzer:
     ```bash
     docker exec webapp-secure whoami
     ```
     - Erwartete Ausgabe:
       ```
       appuser
       ```
   - Prüfe die Capabilities:
     ```bash
     docker exec webapp-secure capsh --print
     ```
     - Erwartete Ausgabe: Nur `cap_net_bind_service` ist aktiv.

**Erkenntnis**: Hardening reduziert die Angriffsfläche durch minimale Images, nicht-root-Benutzer und eingeschränkte Netzwerke. OWASP-Richtlinien betonen diese Praktiken für sichere Container.

**Quelle**: https://docs.docker.com/engine/security/, https://owasp.org/www-project-container-security/

### Übung 2: Verwaltung von Geheimnissen mit Docker Secrets

**Ziel**: Sichere Verwaltung von sensiblen Daten (z. B. API-Keys, Passwörter) mit Docker Secrets.

**Aufgabe**: Passe die Webanwendung an, um einen API-Key aus einem Docker Secret zu lesen, und nutze Docker Compose für die Verwaltung.

1. **Docker Compose für Secrets einrichten**:
   - Erstelle `docker-compose.yml`:
     ```bash
     nano docker-compose.yml
     ```
     - Inhalt:
       ```yaml
       version: '3.7'
       services:
         webapp:
           image: homelab-webapp:2.0
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
             - webapp-net
       secrets:
         api_key:
           file: ./api_key.txt
       volumes:
         webapp-data:
       networks:
         webapp-net:
           driver: bridge
       ```
   - **Erklärung**:
     - `secrets`: Definiert ein Secret (`api_key`) aus einer Datei.
     - `API_KEY_FILE`: Umgebungsvariable für den Secret-Pfad.
     - `read_only`, `cap_drop`, `cap_add`: Setzen Hardening-Optionen.

2. **API-Key-Datei erstellen**:
   ```bash
   echo "my-secret-api-key-123" > api_key.txt
   chmod 600 api_key.txt
   ```

3. **Webanwendung anpassen**:
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
         api_key = "No API key found"
         api_key_file = os.getenv("API_KEY_FILE", "/run/secrets/api_key")
         if os.path.exists(api_key_file):
             with open(api_key_file, 'r') as f:
                 api_key = f.read().strip()
         with open('/app/data/log.txt', 'a') as f:
             f.write(f"Zugriff erfolgt, API-Key: {api_key}\n")
         return f"Willkommen in der HomeLab-Webanwendung! API-Key: {api_key}"

     if __name__ == "__main__":
         app.run(host="0.0.0.0", port=5000)
     ```
   - **Erklärung**:
     - Liest den API-Key aus `/run/secrets/api_key` und protokolliert ihn.

4. **Image neu erstellen**:
   ```bash
   docker build -t homelab-webapp:2.1 .
   ```

5. **Anwendung starten**:
   ```bash
   docker-compose up -d
   ```
   - Teste:
     ```bash
     curl http://192.168.30.101:5000
     ```
     - Erwartete Ausgabe:
       ```
       Willkommen in der HomeLab-Webanwendung! API-Key: my-secret-api-key-123
       ```
   - Prüfe das Log:
     ```bash
     docker exec $(docker ps -q -f name=webapp) cat /app/data/log.txt
     ```
     - Erwartete Ausgabe:
       ```
       Zugriff erfolgt, API-Key: my-secret-api-key-123
       ```

**Erkenntnis**: Docker Secrets ermöglichen die sichere Verwaltung sensibler Daten, indem sie außerhalb des Images gespeichert und nur zur Laufzeit bereitgestellt werden.

**Quelle**: https://docs.docker.com/engine/swarm/secrets/

### Übung 3: Sicherheitsüberprüfungen mit Trivy

**Ziel**: Durchführung von Sicherheitsüberprüfungen für Docker-Images mit Trivy.

**Aufgabe**: Installiere Trivy, überprüfe das Webanwendungs-Image auf Schwachstellen und behebe gefundene Probleme.

1. **Trivy installieren**:
   ```bash
   sudo apt update
   sudo apt install -y apt-transport-https gnupg
   echo "deb [signed-by=/usr/share/keyrings/aquasec.gpg] https://aquasecurity.github.io/trivy-deb stable main" | sudo tee /etc/apt/sources.list.d/trivy.list
   wget -qO - https://aquasecurity.github.io/trivy-deb/pubkey.gpg | sudo apt-key add -
   sudo apt update
   sudo apt install -y trivy
   trivy --version  # Erwartet: Trivy version 0.x.x
   ```

2. **Image auf Schwachstellen scannen**:
   ```bash
   trivy image homelab-webapp:2.1
   ```
   - Erwartete Ausgabe (Beispiel):
     ```
     homelab-webapp:2.1 (debian)
     ==========================
     Total: 10 (HIGH: 2, CRITICAL: 0)

     python:3.9-slim (debian)
     ==========================
     Total: 15 (HIGH: 5, CRITICAL: 1)
     ```

3. **Schwachstellen beheben**:
   - Beispiel: Angenommen, Trivy meldet eine Schwachstelle in `python:3.9-slim`. Aktualisiere das Basis-Image:
     ```bash
     nano Dockerfile
     ```
     - Ändere die erste Zeile zu:
       ```dockerfile
       FROM python:3.9-slim-bullseye
       ```
   - Baue das Image neu:
     ```bash
     docker build -t homelab-webapp:2.2 .
     ```
   - Scanne erneut:
     ```bash
     trivy image homelab-webapp:2.2
     ```

4. **Container scannen**:
   ```bash
   trivy image --severity CRITICAL,HIGH homelab-webapp:2.2
   ```
   - **Hinweis**: Filtert nur kritische und hohe Schwachstellen.

**Erkenntnis**: Trivy ermöglicht die Identifikation und Behebung von Schwachstellen in Docker-Images, was die Sicherheit der Container erhöht.

**Quelle**: https://aquasecurity.github.io/trivy

### Schritt 4: Integration mit HomeLab
1. **Backups auf TrueNAS**:
   - Archiviere das Projekt:
     ```bash
     tar -czf ~/container-security-backup-$(date +%F).tar.gz ~/container-security
     rsync -av ~/container-security-backup-$(date +%F).tar.gz root@192.168.30.100:/mnt/tank/backups/container-security/
     ```
   - Automatisiere:
     ```bash
     nano /home/ubuntu/backup.sh
     ```
     - Inhalt (am Ende hinzufügen):
       ```bash
       DATE=$(date +%F)
       tar -czf /home/ubuntu/container-security-backup-$DATE.tar.gz ~/container-security
       rsync -av /home/ubuntu/container-security-backup-$DATE.tar.gz root@192.168.30.100:/mnt/tank/backups/container-security/
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /home/ubuntu/backup.sh
       ```

2. **Netzwerkmanagement mit OPNsense**:
   - Aktualisiere die Firewall-Regel in OPNsense, um Zugriff auf `192.168.30.101:5000` von `192.168.30.0/24` zu erlauben:
     - Quelle: `192.168.30.0/24`
     - Ziel: `192.168.30.101`
     - Port: `5000`
     - Aktion: `Allow`

### Schritt 5: Erweiterung der Übungen
1. **Docker Bench for Security**:
   - Installiere Docker Bench:
     ```bash
     docker run -it --net host --pid host --userns host --cap-add audit_control \
       -v /var/lib:/var/lib -v /var/run/docker.sock:/var/run/docker.sock \
       docker/docker-bench-security
     ```
   - Analysiere den Bericht und behebe empfohlene Probleme (z. B. Host-Konfiguration).

2. **Secrets in Kubernetes**:
   - Erstelle ein Kubernetes Secret:
     ```bash
     kubectl create secret generic api-key-secret --from-file=api_key=api_key.txt
     ```
   - Passe das Deployment an (siehe `containerization_orchestration_module.md`):
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
             image: homelab-webapp:2.2
             ports:
             - containerPort: 5000
             volumeMounts:
             - name: webapp-storage
               mountPath: /app/data
             - name: api-key
               mountPath: /run/secrets
             env:
             - name: API_KEY_FILE
               value: /run/secrets/api_key
           volumes:
           - name: webapp-storage
             persistentVolumeClaim:
               claimName: webapp-pvc
           - name: api-key
             secret:
               secretName: api-key-secret
     ```

## Best Practices für Schüler

- **Hardening**:
  - Verwende minimale Basis-Images (z. B. `python:3.9-slim`).
  - Führe Container als nicht-root aus.
  - Schränke Capabilities ein (`--cap-drop=ALL`).
- **Geheimnisse**:
  - Vermeide Umgebungsvariablen für sensible Daten; nutze Docker Secrets.
  - Sichere Secret-Dateien (`chmod 600`).
- **Sicherheitsüberprüfungen**:
  - Scanne Images regelmäßig mit Trivy.
  - Aktualisiere Basis-Images bei Schwachstellen.
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe Docker-Logs:
    ```bash
    docker logs webapp-secure
    ```
  - Prüfe Trivy-Berichte:
    ```bash
    trivy image --format json homelab-webapp:2.2 > scan.json
    ```

**Quelle**: https://docs.docker.com/engine/security/, https://aquasecurity.github.io/trivy

## Empfehlungen für Schüler

- **Setup**: Docker auf Ubuntu-VM, Trivy, Docker Compose, TrueNAS-Backups.
- **Workloads**: Gehärtete Webanwendung, Secrets-Verwaltung, Schwachstellen-Scans.
- **Integration**: Proxmox (VM), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Flask-Webanwendung mit API-Key und persistenter Speicherung.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einem gehärteten Image und füge schrittweise Secrets hinzu.
- **Übung**: Scanne verschiedene Images (z. B. `nginx`) mit Trivy.
- **Fehlerbehebung**: Nutze `docker inspect` und `trivy --help` für Debugging.
- **Lernressourcen**: https://docs.docker.com, https://owasp.org/www-project-container-security/, https://aquasecurity.github.io/trivy.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Hardening von Containern, Verwaltung von Geheimnissen, Sicherheitsüberprüfungen.
- **Datenschutz**: Lokale Umgebung ohne Cloud-Abhängigkeit.
- **Lernwert**: Verständnis von Container-Sicherheitspraktiken nach OWASP-Standards.

Es ist ideal für Schüler, die Container-Sicherheit in einer HomeLab erkunden möchten.

**Nächste Schritte**: Möchtest du eine Anleitung zu Kubernetes-Sicherheit, Integration mit Terraform/Ansible, oder Monitoring mit Prometheus für Container?

**Quellen**:
- Docker-Dokumentation: https://docs.docker.com
- OWASP Container Security: https://owasp.org/www-project-container-security/
- Trivy-Dokumentation: https://aquasecurity.github.io/trivy
- Proxmox VE-Dokumentation: https://pve.proxmox.com/pve-docs/
- Webquellen:,,,,,
```