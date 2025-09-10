# Lernprojekt: Erweitertes Monitoring und Logging mit Checkmk in einer HomeLab

## Einführung

**Checkmk** ist ein leistungsstarkes Open-Source-Monitoring-Tool, das agentenbasiertes Monitoring von Systemen, Diensten und Anwendungen ermöglicht und eine benutzerfreundliche Weboberfläche für Visualisierung und Benachrichtigungen bietet. Dieses Lernprojekt führt die Einrichtung von Checkmk in einer HomeLab-Umgebung ein, die auf einer Ubuntu-VM (Proxmox VE, IP `192.168.30.101`) mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement läuft. Es ist für Lernende mit Grundkenntnissen in Linux, Docker, Bash und Netzwerkkonzepten geeignet und vergleichbar mit `01_monitoring_logging_module.md` , nutzt die Webanwendung (`homelab-webapp:2.4`). Das Projekt umfasst drei Übungen: Einrichten von Checkmk für agentenbasiertes Monitoring, Konfiguration von Dashboards und Benachrichtigungen, und Integration mit der Webanwendung für anwendungsspezifisches Monitoring. Es ist lokal, kostenlos (Checkmk Raw Edition) und datenschutzfreundlich.

**Voraussetzungen**:
- Ubuntu 22.04 VM auf Proxmox (ID 101, IP `192.168.30.101`), mit Docker installiert (siehe `03_ci_cd_security_scanning_module.md`).
- Hardware: Mindestens 8 GB RAM, 4 CPU-Kerne, 20 GB freier Speicher.
- Grundkenntnisse in Linux (`bash`, `nano`), Docker, Git und SSH.
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`).
- Webanwendung aus `03_ci_cd_security_scanning_module.md` (`homelab-webapp:2.4`, Flask-basiert).
- Internetzugang für initiale Downloads (Checkmk).

**Ziele**:
- Einrichten von Checkmk (Raw Edition) für agentenbasiertes Monitoring von System- und Anwendungsmetriken.
- Konfiguration von Dashboards und Benachrichtigungen in Checkmk.
- Integration mit der Webanwendung für anwendungsspezifisches Monitoring.
- Integration mit der HomeLab für Backups und Netzwerkmanagement.

**Hinweis**: Das Projekt verwendet die kostenlose **Checkmk Raw Edition**, die für HomeLabs geeignet ist und lokal läuft, um die Privatsphäre zu schützen.

**Quellen**:
- Checkmk-Dokumentation: https://docs.checkmk.com
- Webquellen:,,,,,

## Lernprojekt: Erweitertes Monitoring und Logging mit Checkmk

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
   mkdir ~/checkmk-monitoring
   cd ~/checkmk-monitoring
   ```
3. **Webanwendung kopieren**:
   - Kopiere `Dockerfile`, `app.py`, `docker-compose.yml`, und `api_key.txt` aus `~/ci-cd-security`:
     ```bash
     cp ~/ci-cd-security/{Dockerfile,app.py,docker-compose.yml,api_key.txt} .
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Proxmox und TrueNAS.

### Übung 1: Einrichten von Checkmk für agentenbasiertes Monitoring

**Ziel**: Einrichten von Checkmk (Raw Edition) zur Überwachung der VM und der Webanwendung.

**Aufgabe**: Installiere Checkmk, konfiguriere den Agenten und überwache Systemmetriken.

1. **Checkmk Raw Edition installieren**:
   - Lade das Checkmk-Paket für Ubuntu 22.04 herunter:
     ```bash
     wget https://download.checkmk.com/checkmk/2.3.0p10/check-mk-raw-2.3.0p10_0.jammy_amd64.deb
     ```
   - Installiere:
     ```bash
     sudo apt update
     sudo apt install -y ./check-mk-raw-2.3.0p10_0.jammy_amd64.deb
     ```
   - Prüfe:
     ```bash
     cmk --version  # Erwartet: Checkmk version 2.3.0p10 CRE
     ```

2. **Checkmk-Site erstellen**:
   - Erstelle eine Monitoring-Site namens `homelab`:
     ```bash
     sudo omd create homelab
     sudo omd start homelab
     ```
   - Prüfe:
     ```bash
     curl http://192.168.30.101:5000/homelab
     ```
     - Erwartete Ausgabe: Checkmk-Weboberfläche (Login: `cmkadmin`, Passwort im Terminal mit `sudo omd config homelab show ADMIN_PASSWORD`).

3. **Checkmk-Agent installieren**:
   - Installiere den Agenten auf der VM:
     ```bash
     sudo apt install -y check-mk-agent
     ```
   - Aktiviere den Agenten:
     ```bash
     sudo systemctl enable check-mk-agent
     sudo systemctl start check-mk-agent
     ```

4. **Host in Checkmk hinzufügen**:
   - Öffne `http://192.168.30.101:5000/homelab` in einem Browser.
   - Melde dich an (Standard: `cmkadmin` / Passwort aus `omd config`).
   - Gehe zu `Setup` -> `Hosts` -> `Add host`.
   - Hostname: `ubuntu-vm`.
   - IP-Adresse: `192.168.30.101`.
   - Speichern und aktivieren (`Save & go to service configuration`).
   - Führe einen Service-Scan durch:
     - Klicke auf `Discover services` -> `Accept all`.
   - Prüfe:
     - Gehe zu `Monitor` -> `All hosts` -> `ubuntu-vm`.
     - Erwartete Ausgabe: Metriken wie CPU, Speicher, Festplatte.

5. **Webanwendung überwachen**:
   - Starte die Webanwendung:
     ```bash
     docker-compose up -d
     ```
   - Füge einen HTTP-Check in Checkmk hinzu:
     - Gehe zu `Setup` -> `Services` -> `Manual checks` -> `HTTP`.
     - Erstelle einen Check für `webapp`:
       - Host: `ubuntu-vm`.
       - Service description: `Webapp HTTP`.
       - URL: `http://192.168.30.101:5000`.
       - Speichern und aktivieren.
   - Prüfe:
     - Gehe zu `Monitor` -> `All services` -> `Webapp HTTP`.
     - Erwartete Ausgabe: Status `OK` für HTTP 200.

**Erkenntnis**: Checkmk ermöglicht agentenbasiertes Monitoring von System- und Anwendungsdiensten mit einer benutzerfreundlichen Oberfläche.

**Quelle**: https://docs.checkmk.com/latest/en/intro_setup.html

### Übung 2: Konfiguration von Dashboards und Benachrichtigungen

**Ziel**: Erstellen eines Dashboards und Einrichten von Benachrichtigungen in Checkmk.

**Aufgabe**: Erstelle ein Dashboard für System- und Webanwendungsmetriken und konfiguriere E-Mail-Benachrichtigungen.

1. **Dashboard erstellen**:
   - Öffne `http://192.168.30.101:5000/homelab`.
   - Gehe zu `Customize` -> `Dashboards` -> `Create Dashboard`.
   - Name: `HomeLab Dashboard`.
   - Füge Widgets hinzu:
     - **CPU Usage**: Wähle `Graph` -> `CPU utilization` für `ubuntu-vm`.
     - **Memory Usage**: Wähle `Graph` -> `Memory` für `ubuntu-vm`.
     - **Webapp Status**: Wähle `Service state` -> `Webapp HTTP`.
   - Speichere das Dashboard.
   - Prüfe:
     - Öffne das Dashboard unter `Dashboards` -> `HomeLab Dashboard`.
     - Erwartete Ausgabe: Grafiken für CPU, Speicher und Webapp-Status.

2. **E-Mail-Benachrichtigungen einrichten**:
   - Installiere einen Mail-Server (z. B. `postfix` für lokale Tests):
     ```bash
     sudo apt install -y postfix
     ```
     - Wähle `Local only` während der Installation.
   - Konfiguriere Checkmk für E-Mail-Benachrichtigungen:
     - Gehe zu `Setup` -> `Notifications` -> `Create rule`.
     - Regel:
       - Notification method: `Email`.
       - Contact: `cmkadmin`.
       - Conditions: `Host: ubuntu-vm`, `Service: Webapp HTTP`, `State: CRIT`.
       - SMTP server: `localhost`.
     - Speichern und aktivieren.
   - Teste:
     - Simuliere einen Fehler (stoppe die Webanwendung):
       ```bash
       docker-compose down
       ```
     - Prüfe Benachrichtigungen:
       ```bash
       sudo tail -f /var/log/mail.log
       ```
     - Starte die Webanwendung wieder:
       ```bash
       docker-compose up -d
       ```

**Erkenntnis**: Checkmk bietet flexible Dashboards und Benachrichtigungen, die für HomeLab-Monitoring einfach zu konfigurieren sind.

**Quelle**: https://docs.checkmk.com/latest/en/monitoring_basics.html

### Übung 3: Integration mit der Webanwendung für anwendungsspezifisches Monitoring

**Ziel**: Erweitere die Webanwendung um benutzerdefinierte Metriken und überwache sie mit Checkmk.

**Aufgabe**: Passe die Webanwendung an, um benutzerdefinierte Metriken bereitzustellen, und integriere sie in Checkmk.

1. **Webanwendung für Metriken anpassen**:
   - Erstelle ein Skript für benutzerdefinierte Metriken:
     ```bash
     nano webapp_metrics.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       echo "<<<local>>>"
       container_id=$(docker ps -q -f name=webapp)
       if [ -n "$container_id" ]; then
           requests=$(docker exec $container_id cat /app/data/log.txt | grep "Zugriff erfolgt" | wc -l)
           echo "0 Webapp_Requests requests=$requests|requests_per_min=$requests OK - Total requests: $requests"
       else
           echo "2 Webapp_Requests - CRITICAL - Webapp container not running"
       fi
       ```
     - Ausführbar machen:
       ```bash
       chmod +x webapp_metrics.sh
       ```

2. **Checkmk-Agent für benutzerdefinierte Metriken konfigurieren**:
   - Kopiere das Skript in den Agenten-Plugin-Ordner:
     ```bash
     sudo cp webapp_metrics.sh /usr/lib/check_mk_agent/plugins/
     ```
   - Führe einen Service-Scan durch:
     - Öffne `http://192.168.30.101:5000/homelab`.
     - Gehe zu `Setup` -> `Services` -> `ubuntu-vm` -> `Discover services`.
     - Akzeptiere den neuen Service `Webapp_Requests`.
   - Prüfe:
     - Gehe zu `Monitor` -> `All services` -> `Webapp_Requests`.
     - Erwartete Ausgabe: Metrik `requests` zeigt die Anzahl der Zugriffe.

3. **Metriken im Dashboard hinzufügen**:
   - Gehe zu `Customize` -> `Dashboards` -> `HomeLab Dashboard`.
   - Füge ein Widget hinzu:
     - Typ: `Graph`.
     - Metrik: `Webapp_Requests`.
     - Speichern.
   - Prüfe:
     - Öffne das Dashboard und überprüfe die Anzahl der Webanwendungs-Zugriffe.

**Erkenntnis**: Checkmk ermöglicht anwendungsspezifisches Monitoring durch benutzerdefinierte Agenten-Skripte, die leicht in Dashboards integriert werden können.

**Quelle**: https://docs.checkmk.com/latest/en/localchecks.html

### Schritt 4: Integration mit HomeLab
1. **Backups auf TrueNAS**:
   - Archiviere das Projekt:
     ```bash
     tar -czf ~/checkmk-monitoring-backup-$(date +%F).tar.gz ~/checkmk-monitoring
     rsync -av ~/checkmk-monitoring-backup-$(date +%F).tar.gz root@192.168.30.100:/mnt/tank/backups/checkmk-monitoring/
     ```
   - Automatisiere:
     ```bash
     nano /home/ubuntu/backup.sh
     ```
     - Inhalt (am Ende hinzufügen):
       ```bash
       DATE=$(date +%F)
       tar -czf /home/ubuntu/checkmk-monitoring-backup-$DATE.tar.gz ~/checkmk-monitoring
       rsync -av /home/ubuntu/checkmk-monitoring-backup-$DATE.tar.gz root@192.168.30.100:/mnt/tank/backups/checkmk-monitoring/
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /home/ubuntu/backup.sh
       ```

2. **Netzwerkmanagement mit OPNsense**:
   - Aktualisiere die Firewall-Regel in OPNsense, um Zugriff auf `192.168.30.101:5000` (Webanwendung) und `192.168.30.101:5000/homelab` (Checkmk) von `192.168.30.0/24` zu erlauben:
     - Quelle: `192.168.30.0/24`
     - Ziel: `192.168.30.101`
     - Ports: `5000`
     - Aktion: `Allow`

### Schritt 5: Erweiterung der Übungen
1. **Benachrichtigungen über andere Kanäle**:
   - Konfiguriere Benachrichtigungen über Telegram oder Slack:
     - Gehe zu `Setup` -> `Notifications` -> `Create rule`.
     - Nutze ein Checkmk-Plugin für Telegram (siehe https://docs.checkmk.com/latest/en/notifications.html).
2. **Monitoring von Docker-Containern**:
   - Installiere das Checkmk-Docker-Plugin:
     ```bash
     sudo apt install -y check-mk-agent-docker
     ```
   - Füge einen Docker-Check in Checkmk hinzu:
     - Gehe zu `Setup` -> `Services` -> `Manual checks` -> `Docker`.

## Best Practices für Schüler

- **Monitoring**:
  - Verwende die Checkmk Raw Edition für einfache HomeLab-Setups.
  - Führe regelmäßige Service-Scans durch (`Discover services`).
- **Sicherheit**:
  - Schränke Netzwerkzugriff ein:
    ```bash
    sudo ufw allow from 192.168.30.0/24 to any port 5000
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
  - Ändere das Checkmk-Admin-Passwort:
    ```bash
    sudo omd config homelab set ADMIN_PASSWORD neues-passwort
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe Checkmk-Logs:
    ```bash
    sudo omd status homelab
    sudo tail -f /omd/sites/homelab/var/log/web.log
    ```
  - Prüfe Agenten-Logs:
    ```bash
    sudo tail -f /var/log/check_mk_agent.log
    ```

**Quelle**: https://docs.checkmk.com/latest/en/

## Empfehlungen für Schüler

- **Setup**: Checkmk Raw Edition, Webanwendung auf Ubuntu-VM, TrueNAS-Backups.
- **Workloads**: System- und Anwendungsmetriken, Dashboards, Benachrichtigungen.
- **Integration**: Proxmox (VM), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Flask-Webanwendung mit benutzerdefinierten Metriken.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit grundlegenden Checks (CPU, Speicher) und füge benutzerdefinierte hinzu.
- **Übung**: Experimentiere mit weiteren Checks (z. B. Docker, Netzwerk).
- **Fehlerbehebung**: Nutze `cmk -I` für Service-Discovery und Checkmk-Logs.
- **Lernressourcen**: https://docs.checkmk.com, https://pve.proxmox.com/wiki.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Agentenbasiertes Monitoring mit Checkmk, inklusive Dashboards und Benachrichtigungen.
- **Datenschutz**: Lokale Umgebung ohne Cloud-Abhängigkeit.
- **Lernwert**: Verständnis von Monitoring und Visualisierung mit Checkmk.

Es ist ideal für Schüler, die erweitertes Monitoring in einer HomeLab erkunden möchten und eine Alternative zu Prometheus/Grafana suchen.

**Vergleich zu Prometheus/Grafana**:
- **Checkmk**: Benutzerfreundlicher, agentenbasiert, einfache Einrichtung, ideal für Anfänger.
- **Prometheus/Grafana**: Pull-basiert, flexibler für benutzerdefinierte Metriken, steilere Lernkurve.
- **Einsatz**: Checkmk für schnelles Setup und breite Abdeckung; Prometheus/Grafana für tiefes, anwendungsspezifisches Monitoring.

**Nächste Schritte**: Möchtest du eine Anleitung zu erweiterten Checkmk-Plugins, Integration mit Kubernetes, oder Log-Aggregation mit ELK?

**Quellen**:
- Checkmk-Dokumentation: https://docs.checkmk.com
- Proxmox VE-Dokumentation: https://pve.proxmox.com/pve-docs/
- Webquellen:,,,,,