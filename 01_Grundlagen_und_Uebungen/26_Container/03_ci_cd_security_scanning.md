# Lernprojekt: Sicherheits-Scanning in CI/CD in einer HomeLab

## Einführung

**Sicherheits-Scanning in CI/CD** automatisiert die Überprüfung von Code und Containern auf Schwachstellen, um die Sicherheit von Anwendungen zu gewährleisten. Dieses Lernprojekt führt die Integration von **Trivy** (für Container-Scans) und **OWASP ZAP** (für Webanwendungs-Scans) in einer CI/CD-Pipeline ein, die in einer HomeLab-Umgebung auf einer Ubuntu-VM (Proxmox VE, IP `192.168.30.101`) mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement läuft. Es ist für Lernende mit Grundkenntnissen in Linux, Docker, Bash und Git geeignet und baut auf `02_container_security_module.md` auf, nutzt die gehärtete Webanwendung (`homelab-webapp:2.2`). Das Projekt umfasst drei Übungen: Einrichten einer lokalen CI/CD-Pipeline mit GitHub Actions (simuliert), Integration von Trivy für Container-Scans, und Integration von OWASP ZAP für Webanwendungs-Scans. Es ist lokal, kostenlos und datenschutzfreundlich.

**Voraussetzungen**:
- Ubuntu 22.04 VM auf Proxmox (ID 101, IP `192.168.30.101`), mit Docker installiert (siehe `02_container_security_module.md`).
- Hardware: Mindestens 8 GB RAM, 4 CPU-Kerne, 20 GB freier Speicher.
- Grundkenntnisse in Linux (`bash`, `nano`), Docker, Git und SSH.
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`).
- GitHub-Repository (oder lokales Git-Repository) für die Webanwendung.
- Webanwendung aus `02_container_security_module.md` (`homelab-webapp:2.2`, Flask-basiert).
- Internetzugang für initiale Downloads (Trivy, OWASP ZAP).

**Ziele**:
- Einrichten einer CI/CD-Pipeline mit GitHub Actions (lokal simuliert).
- Integration von Trivy für automatisierte Container-Scans.
- Integration von OWASP ZAP für Webanwendungs-Scans.
- Integration mit der HomeLab für Backups und Netzwerkmanagement.

**Hinweis**: GitHub Actions wird lokal simuliert, da die HomeLab keine Cloud-Dienste nutzt. Die Pipeline läuft auf der VM mit `act` (einem GitHub Actions Emulator).

**Quellen**:
- Trivy-Dokumentation: https://aquasecurity.github.io/trivy
- OWASP ZAP-Dokumentation: https://www.zaproxy.org
- GitHub Actions-Dokumentation: https://docs.github.com/en/actions
- Webquellen:,,,,,

## Lernprojekt: Sicherheits-Scanning in CI/CD

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
2. **Git und Abhängigkeiten installieren**:
   ```bash
   sudo apt update
   sudo apt install -y git
   ```
3. **Projektverzeichnis erstellen**:
   ```bash
   mkdir ~/ci-cd-security
   cd ~/ci-cd-security
   ```
4. **Webanwendung kopieren**:
   - Kopiere `Dockerfile`, `app.py`, `docker-compose.yml`, und `api_key.txt` aus `~/container-security`:
     ```bash
     cp ~/container-security/{Dockerfile,app.py,docker-compose.yml,api_key.txt} .
     ```
5. **Lokales Git-Repository initialisieren**:
   ```bash
   git init
   git add Dockerfile app.py docker-compose.yml api_key.txt
   git commit -m "Initial commit for CI/CD security project"
   ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Proxmox und TrueNAS.

### Übung 1: Einrichten einer lokalen CI/CD-Pipeline

**Ziel**: Einrichten einer simulierten CI/CD-Pipeline mit GitHub Actions und `act`.

**Aufgabe**: Installiere `act`, erstelle eine GitHub Actions Workflow-Datei und teste die Pipeline lokal.

1. **act installieren**:
   ```bash
   curl https://raw.githubusercontent.com/nektos/act/master/install.sh | bash
   sudo mv ./bin/act /usr/local/bin/
   act --version  # Erwartet: act version 0.x.x
   ```

2. **GitHub Actions Workflow erstellen**:
   ```bash
   mkdir -p .github/workflows
   nano .github/workflows/ci.yml
   ```
   - Inhalt:
     ```yaml
     name: CI Pipeline
     on:
       push:
         branches:
           - main
     jobs:
       build:
         runs-on: ubuntu-latest
         steps:
         - name: Checkout code
           uses: actions/checkout@v4
         - name: Set up Docker Buildx
           uses: docker/setup-buildx-action@v3
         - name: Build Docker image
           run: docker build -t homelab-webapp:${{ github.sha }} .
         - name: Run container
           run: |
             docker-compose up -d
             sleep 5
             curl http://localhost:5000
         - name: Stop container
           run: docker-compose down
     ```
   - **Erklärung**:
     - `on: push`: Startet die Pipeline bei Push auf `main`.
     - `build`: Baut das Docker-Image und testet den Container.
     - `actions/checkout@v4`, `docker/setup-buildx-action@v3`: Standard-Actions für Git-Checkout und Docker-Build.

3. **Workflow lokal testen**:
   ```bash
   act -j build
   ```
   - Erwartete Ausgabe:
     ```
     [CI Pipeline/build] 🚀  Start image=...
     [CI Pipeline/build]   ✅  Success - Checkout code
     [CI Pipeline/build]   ✅  Success - Set up Docker Buildx
     [CI Pipeline/build]   ✅  Success - Build Docker image
     [CI Pipeline/build]   ✅  Success - Run container
     [CI Pipeline/build]   ✅  Success - Stop container
     ```
   - Prüfe:
     ```bash
     curl http://192.168.30.101:5000
     ```
     - Erwartete Ausgabe:
       ```
       Willkommen in der HomeLab-Webanwendung! API-Key: my-secret-api-key-123
       ```

**Erkenntnis**: `act` ermöglicht das Testen von GitHub Actions lokal, ideal für die HomeLab ohne Cloud-Abhängigkeit.

**Quelle**: https://docs.github.com/en/actions, https://github.com/nektos/act

### Übung 2: Integration von Trivy für Container-Scans

**Ziel**: Automatisierte Container-Scans mit Trivy in der CI/CD-Pipeline.

**Aufgabe**: Integriere Trivy in den Workflow, um das Docker-Image auf Schwachstellen zu scannen.

1. **Trivy installieren** (falls nicht vorhanden, siehe `container_security_module.md`):
   ```bash
   sudo apt update
   sudo apt install -y apt-transport-https gnupg
   echo "deb [signed-by=/usr/share/keyrings/aquasec.gpg] https://aquasecurity.github.io/trivy-deb stable main" | sudo tee /etc/apt/sources.list.d/trivy.list
   wget -qO - https://aquasecurity.github.io/trivy-deb/pubkey.gpg | sudo apt-key add -
   sudo apt update
   sudo apt install -y trivy
   ```

2. **Workflow für Trivy erweitern**:
   ```bash
   nano .github/workflows/ci.yml
   ```
   - Inhalt:
     ```yaml
     name: CI Pipeline
     on:
       push:
         branches:
           - main
     jobs:
       build-and-scan:
         runs-on: ubuntu-latest
         steps:
         - name: Checkout code
           uses: actions/checkout@v4
         - name: Set up Docker Buildx
           uses: docker/setup-buildx-action@v3
         - name: Build Docker image
           run: docker build -t homelab-webapp:${{ github.sha }} .
         - name: Scan image with Trivy
           run: |
             trivy image --severity CRITICAL,HIGH --exit-code 1 homelab-webapp:${{ github.sha }}
         - name: Run container
           run: |
             docker-compose up -d
             sleep 5
             curl http://localhost:5000
         - name: Stop container
           run: docker-compose down
     ```
   - **Erklärung**:
     - `trivy image --severity CRITICAL,HIGH --exit-code 1`: Fails bei kritischen oder hohen Schwachstellen.
     - Integriert Trivy nach dem Image-Bau.

3. **Workflow testen**:
   ```bash
   act -j build-and-scan
   ```
   - Erwartete Ausgabe (bei Schwachstellen):
     ```
     [CI Pipeline/build-and-scan] 🚨 Failure - Scan image with Trivy
     ```
   - Prüfe Details:
     ```bash
     trivy image homelab-webapp:2.2
     ```

4. **Schwachstellen beheben**:
   - Beispiel: Wenn Trivy Schwachstellen in `python:3.9-slim` meldet, aktualisiere das Basis-Image in `Dockerfile`:
     ```bash
     nano Dockerfile
     ```
     - Ändere:
       ```dockerfile
       FROM python:3.9-slim-bookworm
       ```
     - Baue und teste erneut:
       ```bash
       docker build -t homelab-webapp:2.3 .
       act -j build-and-scan
       ```

**Erkenntnis**: Trivy in CI/CD automatisiert Schwachstellen-Scans und erhöht die Containersicherheit durch frühzeitige Erkennung.

**Quelle**: https://aquasecurity.github.io/trivy

### Übung 3: Integration von OWASP ZAP für Webanwendungs-Scans

**Ziel**: Automatisierte Sicherheitsüberprüfung der Webanwendung mit OWASP ZAP.

**Aufgabe**: Integriere OWASP ZAP in die Pipeline, um die Webanwendung auf Schwachstellen zu testen.

1. **OWASP ZAP Docker-Image verwenden**:
   - Teste ZAP lokal:
     ```bash
     docker run -u zap -p 8080:8080 -d owasp/zap2docker-stable zap.sh -daemon -port 8080 -host 0.0.0.0
     ```
   - Prüfe:
     ```bash
     curl http://192.168.30.101:8080
     ```

2. **ZAP in Workflow integrieren**:
   ```bash
   nano .github/workflows/ci.yml
   ```
   - Inhalt:
     ```yaml
     name: CI Pipeline
     on:
       push:
         branches:
           - main
     jobs:
       build-and-scan:
         runs-on: ubuntu-latest
         steps:
         - name: Checkout code
           uses: actions/checkout@v4
         - name: Set up Docker Buildx
           uses: docker/setup-buildx-action@v3
         - name: Build Docker image
           run: docker build -t homelab-webapp:${{ github.sha }} .
         - name: Scan image with Trivy
           run: |
             trivy image --severity CRITICAL,HIGH --exit-code 1 homelab-webapp:${{ github.sha }}
         - name: Run webapp
           run: |
             docker-compose up -d
             sleep 5
         - name: Run OWASP ZAP scan
           run: |
             docker run -v $(pwd)/zap:/zap/wrk/:rw -t owasp/zap2docker-stable zap-baseline.py \
               -t http://localhost:5000 -r zap_report.html
         - name: Archive ZAP report
           run: |
             mv zap_report.html zap_report_${{ github.sha }}.html
         - name: Stop container
           run: docker-compose down
     ```
   - **Erklärung**:
     - `zap-baseline.py`: Führt einen schnellen Sicherheits-Scan durch.
     - `-r zap_report.html`: Speichert den Bericht.
     - `Archive ZAP report`: Sichert den Bericht für die Analyse.

3. **Workflow testen**:
   ```bash
   act -j build-and-scan
   ```
   - Prüfe den ZAP-Bericht:
     ```bash
     cat zap_report_*.html
     ```
   - Erwartete Ausgabe: HTML-Bericht mit Schwachstellen (z. B. fehlende Security-Header).

4. **Schwachstellen beheben**:
   - Beispiel: ZAP meldet fehlende Security-Header. Passe `app.py` an:
     ```bash
     nano app.py
     ```
     - Inhalt:
       ```python
       from flask import Flask, Response
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
           response = Response(f"Willkommen in der HomeLab-Webanwendung! API-Key: {api_key}")
           response.headers['Content-Security-Policy'] = "default-src 'self'"
           response.headers['X-Content-Type-Options'] = 'nosniff'
           return response

       if __name__ == "__main__":
           app.run(host="0.0.0.0", port=5000)
       ```
   - Baue und teste erneut:
     ```bash
     docker build -t homelab-webapp:2.4 .
     act -j build-and-scan
     ```

**Erkenntnis**: OWASP ZAP in CI/CD automatisiert Webanwendungs-Scans und identifiziert Schwachstellen wie fehlende Header, die leicht behoben werden können.

**Quelle**: https://www.zaproxy.org/docs/docker/baseline-scan/

### Schritt 4: Integration mit HomeLab
1. **Backups auf TrueNAS**:
   - Archiviere das Projekt:
     ```bash
     tar -czf ~/ci-cd-security-backup-$(date +%F).tar.gz ~/ci-cd-security
     rsync -av ~/ci-cd-security-backup-$(date +%F).tar.gz root@192.168.30.100:/mnt/tank/backups/ci-cd-security/
     ```
   - Automatisiere:
     ```bash
     nano /home/ubuntu/backup.sh
     ```
     - Inhalt (am Ende hinzufügen):
       ```bash
       DATE=$(date +%F)
       tar -czf /home/ubuntu/ci-cd-security-backup-$DATE.tar.gz ~/ci-cd-security
       rsync -av /home/ubuntu/ci-cd-security-backup-$DATE.tar.gz root@192.168.30.100:/mnt/tank/backups/ci-cd-security/
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /home/ubuntu/backup.sh
       ```

2. **Netzwerkmanagement mit OPNsense**:
   - Aktualisiere die Firewall-Regel in OPNsense, um Zugriff auf `192.168.30.101:5000` (Webanwendung) und `192.168.30.101:8080` (ZAP) von `192.168.30.0/24` zu erlauben:
     - Quelle: `192.168.30.0/24`
     - Ziel: `192.168.30.101`
     - Ports: `5000,8080`
     - Aktion: `Allow`

### Schritt 5: Erweiterung der Übungen
1. **Integration mit GitLab CI**:
   - Simuliere GitLab CI lokal mit `gitlab-runner`:
     ```bash
     docker run -d --name gitlab-runner --restart always \
       -v /var/run/docker.sock:/var/run/docker.sock \
       gitlab/gitlab-runner:latest
     ```
   - Erstelle `.gitlab-ci.yml` analog zu `.github/workflows/ci.yml`.

2. **ZAP Full Scan**:
   - Nutze den vollständigen ZAP-Scan für tiefere Tests:
     ```bash
     docker run -v $(pwd)/zap:/zap/wrk/:rw -t owasp/zap2docker-stable zap-full-scan.py \
       -t http://localhost:5000 -r zap_full_report.html
     ```

## Best Practices für Schüler

- **Pipeline-Design**:
  - Integriere Sicherheits-Scans früh in die Pipeline.
  - Fail bei kritischen Schwachstellen (`--exit-code 1`).
- **Sicherheit**:
  - Schränke Netzwerkzugriff ein:
    ```bash
    sudo ufw allow from 192.168.30.0/24 to any port 5000
    sudo ufw allow from 192.168.30.0/24 to any port 8080
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe Pipeline-Logs:
    ```bash
    act -j build-and-scan --verbose
    ```
  - Prüfe ZAP-Berichte:
    ```bash
    cat zap_report_*.html
    ```

**Quelle**: https://aquasecurity.github.io/trivy, https://www.zaproxy.org

## Empfehlungen für Schüler

- **Setup**: Docker, Trivy, OWASP ZAP, `act` auf Ubuntu-VM, TrueNAS-Backups.
- **Workloads**: Automatisierte Container- und Webanwendungs-Scans in CI/CD.
- **Integration**: Proxmox (VM), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Flask-Webanwendung mit Trivy- und ZAP-Scans.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit Trivy für Container-Scans, füge ZAP hinzu.
- **Übung**: Teste andere Images (z. B. `nginx`) oder Webanwendungen.
- **Fehlerbehebung**: Nutze `act --verbose` und ZAP-Berichte für Debugging.
- **Lernressourcen**: https://aquasecurity.github.io/trivy, https://www.zaproxy.org, https://docs.github.com/en/actions.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Integration von Trivy und OWASP ZAP in CI/CD.
- **Datenschutz**: Lokale Pipeline mit `act` ohne Cloud-Abhängigkeit.
- **Lernwert**: Verständnis von automatisierten Sicherheits-Scans.

Es ist ideal für Schüler, die Sicherheits-Scanning in CI/CD in einer HomeLab erkunden möchten.

**Nächste Schritte**: Möchtest du eine Anleitung zu Kubernetes-Integration in CI/CD, Monitoring mit Prometheus, oder erweiterten ZAP-Scans?

**Quellen**:
- Trivy-Dokumentation: https://aquasecurity.github.io/trivy
- OWASP ZAP-Dokumentation: https://www.zaproxy.org
- GitHub Actions-Dokumentation: https://docs.github.com/en/actions
- Proxmox VE-Dokumentation: https://pve.proxmox.com/pve-docs/
- Webquellen:,,,,,
```