# Lernprojekt: Kombination von ELK Stack mit Checkmk in einer HomeLab

## Einführung

Die **Kombination von ELK Stack** (Elasticsearch, Logstash, Kibana) mit **Checkmk** erweitert Monitoring und Logging in einer HomeLab, indem Checkmk agentenbasiertes Systemmonitoring und ELK detaillierte Log-Analyse bereitstellen. Dieses Lernprojekt integriert beide Tools für eine umfassende Überwachung, z. B. Systemmetriken (Checkmk) mit Apache-Logs (ELK). Es ist für Lernende mit Grundkenntnissen in Linux, Docker, Bash und Monitoring geeignet und baut auf `04_elk_installation_debian_lxc_guide.md` und `01_Checkmk_Einfuehrung_Grundlagen.md` auf. Es nutzt eine Ubuntu-VM auf einem Proxmox VE-Server (IP `192.168.30.101`) mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement. Das Projekt umfasst drei Übungen: Integration von Checkmk mit ELK, Erstellung eines kombinierten Dashboards, und Konfiguration von Alerts mit Log-Eventen. Es ist lokal, kostenlos (Checkmk Raw Edition, ELK Open-Source) und datenschutzfreundlich.

**Voraussetzungen**:
- Ubuntu 22.04 VM auf Proxmox (ID 101, IP `192.168.30.101`), mit ELK Stack (via APT oder LXC, siehe `04_elk_installation_debian_lxc_guide.md`) und Checkmk Raw Edition (siehe `01_Checkmk_Einfuehrung_Grundlagen.md` installiert.
- Hardware: Mindestens 8 GB RAM, 4 CPU-Kerne, 30 GB freier Speicher.
- Grundkenntnisse in Linux (`bash`, `nano`), Docker, Monitoring und SSH.
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`).
- Apache-Webserver auf der VM (`sudo systemctl status apache2`).
- Checkmk-Site `homelab` (Port 5000) und Kibana (Port 5601) erreichbar.
- Internetzugang für initiale Downloads (Metricbeat).

**Ziele**:
- Integration von Checkmk mit ELK für kombinierte Monitoring- und Log-Analyse.
- Erstellung eines Dashboards mit Metriken und Logs.
- Konfiguration von Alerts basierend auf Log-Eventen.
- Integration mit HomeLab für Backups und Netzwerkmanagement.

**Hinweis**: Checkmk überwacht Systemmetriken, während ELK Log-Analysen durchführt – eine ideale Kombination für HomeLabs.

**Quellen**:
- Checkmk-Dokumentation: https://docs.checkmk.com
- Elastic-Dokumentation: https://www.elastic.co/guide/en/elastic-stack/current/index.html
- Proxmox VE-Dokumentation: https://pve.proxmox.com/pve-docs/
- Webquellen:,,,,,

## Lernprojekt: ELK und Checkmk Kombination

### Vorbereitung: Umgebung einrichten
1. **Ubuntu-VM prüfen**:
   - Stelle sicher, dass die Ubuntu-VM (IP `192.168.30.101`) läuft:
     ```bash
     ssh ubuntu@192.168.30.101
     ```
   - Prüfe ELK Stack:
     ```bash
     curl http://localhost:9200  # Elasticsearch
     curl http://localhost:5601  # Kibana
     ```
   - Prüfe Checkmk:
     ```bash
     curl http://localhost:5000/homelab
     ```
   - Prüfe Apache:
     ```bash
     sudo systemctl status apache2
     curl http://192.168.30.101
     ```
2. **Projektverzeichnis erstellen**:
   ```bash
   mkdir ~/elk-checkmk-integration
   cd ~/elk-checkmk-integration
   ```

**Tipp**: Stelle sicher, dass ELK und Checkmk auf der gleichen VM laufen.

### Übung 1: Integration von Checkmk mit ELK

**Ziel**: Checkmk für ELK-Logs und ELK für Checkmk-Metriken konfigurieren.

**Aufgabe**: Richte Checkmk für Elasticsearch-Überwachung und ELK für Systemmetriken ein.

1. **Checkmk für ELK-Logs konfigurieren**:
   - Öffne die Checkmk-Weboberfläche: `http://192.168.30.101:5000/homelab`.
   - Melde dich an (`cmkadmin` / Passwort aus `sudo omd config homelab show ADMIN_PASSWORD`).
   - Gehe zu `Setup` -> `Hosts` -> `ubuntu-vm` -> `Discover services`.
   - Installiere das Checkmk-Elasticsearch-Plugin (falls nicht vorhanden):
     ```bash
     sudo apt update
     sudo apt install -y check-mk-agent-elasticsearch
     ```
   - Führe einen Service-Scan durch:
     - Klicke auf `Discover services` -> `Accept all`.
   - Prüfe:
     - Gehe zu `Monitor` -> `All services` -> `Elasticsearch`.
     - Erwartete Ausgabe: Metriken wie Elasticsearch-Cluster-Status, Indizes.

2. **ELK für Checkmk-Metriken konfigurieren**:
   - Installiere Metricbeat:
     ```bash
     wget https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-8.15.0-amd64.deb
     sudo dpkg -i metricbeat-8.15.0-amd64.deb
     ```
   - Konfiguriere `/etc/metricbeat/metricbeat.yml`:
     ```bash
     sudo nano /etc/metricbeat/metricbeat.yml
     ```
     - Inhalt:
       ```yaml
       metricbeat.modules:
       - module: system
         metricsets:
           - cpu
           - memory
           - network
         period: 10s
       output.elasticsearch:
         hosts: ["http://localhost:9200"]
         index: "checkmk-metrics-%{+YYYY.MM.dd}"
       ```
   - Starte Metricbeat:
     ```bash
     sudo systemctl enable metricbeat
     sudo systemctl start metricbeat
     ```
   - Prüfe in Kibana:
     - Öffne `http://192.168.30.101:5601`.
     - Erstelle ein Index-Pattern: `checkmk-metrics-*` (`Stack Management` -> `Index Patterns`).
     - Gehe zu `Analytics` -> `Discover` -> Index `checkmk-metrics-*`.
     - Erwartete Ausgabe: Metriken wie `system.cpu.user.pct`, `system.memory.used.pct`.

**Erkenntnis**: Checkmk und ELK ergänzen sich durch Metriken (Checkmk) und Log-Analysen (ELK).

**Quelle**: https://docs.checkmk.com/latest/en/integrations.html

### Übung 2: Erstellung eines kombinierten Dashboards

**Ziel**: Erstelle Dashboards in Checkmk und Kibana für Metriken und Logs.

**Aufgabe**: Kombiniere Systemmetriken (Checkmk) mit Apache-Logs (ELK).

1. **Checkmk-Dashboard erstellen**:
   - Öffne `http://192.168.30.101:5000/homelab`.
   - Gehe zu `Customize` -> `Dashboards` -> `Create Dashboard`.
   - Name: `HomeLab Combined Dashboard`.
   - Füge Widgets hinzu:
     - **CPU Usage**: `Graph` -> `CPU utilization` für `ubuntu-vm`.
     - **Memory Usage**: `Graph` -> `Memory` für `ubuntu-vm`.
     - **Apache Status**: `Service state` -> `Apache`.
     - **Elasticsearch Status**: `Service state` -> `Elasticsearch`.
   - Speichere das Dashboard.
   - Prüfe:
     - Öffne `Dashboards` -> `HomeLab Combined Dashboard`.
     - Erwartete Ausgabe: Grafiken für CPU, Speicher, Apache- und Elasticsearch-Status.

2. **Kibana-Dashboard erstellen**:
   - Öffne `http://192.168.30.101:5601`.
   - Gehe zu `Analytics` -> `Dashboard` -> `Create dashboard`.
   - Füge Visualisierungen hinzu:
     - **Log-Events pro Minute**: `Metric` -> `Count`, Zeitbereich: `Last 1 hour`, Index: `apache-logs-*`.
     - **Top Clients**: `Pie` -> Feld `clientip.keyword`.
     - **Response Codes**: `Bar` -> X-Achse `response.keyword`, Y-Achse `Count`.
     - **CPU Usage (Checkmk)**: `Line` -> Feld `system.cpu.user.pct` (aus `checkmk-metrics-*`).
   - Speichere als `ELK Checkmk Combined Dashboard`.
   - Prüfe:
     - Öffne das Dashboard und überprüfe Logs und Metriken.

**Erkenntnis**: Kombinierte Dashboards bieten eine einheitliche Sicht auf Systemmetriken und Logs.

**Quelle**: https://www.elastic.co/guide/en/kibana/current/dashboard.html

### Übung 3: Konfiguration von Alerts basierend auf Log-Eventen

**Ziel**: Richte Alerts in Checkmk und Kibana ein, die auf Log-Eventen und Metriken reagieren.

**Aufgabe**: Konfiguriere Alerts für HTTP-Fehler (ELK) und hohe CPU-Auslastung (Checkmk).

1. **Checkmk-Alerts für Systemmetriken**:
   - Öffne `http://192.168.30.101:5000/homelab`.
   - Gehe zu `Setup` -> `Notifications` -> `Create rule`.
   - Regel:
     - Notification method: `Email` (konfiguriere SMTP, z. B. `postfix`):
       ```bash
       sudo apt install -y postfix  # Wähle "Local only"
       ```
     - Contact: `cmkadmin`.
     - Conditions: `Host: ubuntu-vm`, `Service: CPU utilization`, `State: WARN`.
     - Speichern und aktivieren.
   - Teste:
     - Simuliere hohe CPU-Last:
       ```bash
       sudo apt install -y stress
       stress --cpu 4 --timeout 300
       ```
     - Prüfe Benachrichtigungen:
       ```bash
       sudo tail -f /var/log/mail.log
       ```

2. **Kibana-Alerts für Log-Eventen**:
   - Öffne `http://192.168.30.101:5601`.
   - Gehe zu `Stack Management` -> `Rules` -> `Create rule`.
   - Regel:
     - Index: `apache-logs-*`.
     - Bedingung: `response:500` (HTTP-Fehler).
     - Threshold: `IS ABOVE 0`.
     - Aktion: E-Mail (konfiguriere SMTP in `Stack Management` -> `Notifications`).
     - Speichern.
   - Teste:
     - Simuliere einen Fehler (z. B. `/error` in `app.py` anpassen und neu deployen):
       ```bash
       curl http://192.168.30.101/error
       ```
     - Prüfe Alerts in Kibana: `Stack Management` -> `Alerts`.

**Erkenntnis**: Alerts in Checkmk und Kibana ermöglichen proaktive Überwachung von Metriken und Logs.

**Quelle**: https://docs.checkmk.com/latest/en/notifications.html, https://www.elastic.co/guide/en/kibana/current/alerting.html

### Schritt 4: Integration mit HomeLab
1. **Backups auf TrueNAS**:
   - Archiviere das Projekt:
     ```bash
     tar -czf ~/elk-checkmk-backup-$(date +%F).tar.gz ~/elk-checkmk-integration /etc/elasticsearch /etc/logstash /etc/kibana /omd/sites/homelab
     rsync -av ~/elk-checkmk-backup-$(date +%F).tar.gz root@192.168.30.100:/mnt/tank/backups/elk-checkmk/
     ```
   - Automatisiere:
     ```bash
     nano /home/ubuntu/backup.sh
     ```
     - Inhalt (am Ende hinzufügen):
       ```bash
       DATE=$(date +%F)
       tar -czf /home/ubuntu/elk-checkmk-backup-$DATE.tar.gz ~/elk-checkmk-integration /etc/elasticsearch /etc/logstash /etc/kibana /omd/sites/homelab
       rsync -av /home/ubuntu/elk-checkmk-backup-$DATE.tar.gz root@192.168.30.100:/mnt/tank/backups/elk-checkmk/
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /home/ubuntu/backup.sh
       ```

2. **Netzwerkmanagement mit OPNsense**:
   - Aktualisiere die Firewall-Regel in OPNsense, um Zugriff auf `192.168.30.101:5000` (Checkmk), `192.168.30.101:9200` (Elasticsearch), und `192.168.30.101:5601` (Kibana) von `192.168.30.0/24` zu erlauben:
     - Quelle: `192.168.30.0/24`
     - Ziel: `192.168.30.101`
     - Ports: `5000,9200,5601`
     - Aktion: `Allow`

### Schritt 5: Erweiterung der Übungen
1. **Erweiterte Checkmk-ELK-Integration**:
   - Nutze das Checkmk-Event-Console-Plugin, um ELK-Logs in Checkmk zu importieren:
     ```bash
     sudo nano /omd/sites/homelab/etc/check_mk/mkeventd.d/elk_integration.mk
     ```
     - Inhalt:
       ```python
       logstash_output = {
           "type": "tcp",
           "host": "localhost",
           "port": 5044,
       }
       ```
   - Starte Checkmk neu:
     ```bash
     sudo omd restart homelab
     ```

2. **Kibana für Checkmk-Logs**:
   - Konfiguriere Filebeat für Checkmk-Logs:
     ```bash
     sudo nano /etc/filebeat/filebeat.yml
     ```
     - Inhalt (am Ende hinzufügen):
       ```yaml
       - type: log
         paths:
           - /omd/sites/homelab/var/log/*.log
         output.elasticsearch:
           hosts: ["http://localhost:9200"]
           index: "checkmk-logs-%{+YYYY.MM.dd}"
       ```

## Best Practices für Schüler

- **Integration**:
  - Nutze Checkmk für Systemmetriken und ELK für detaillierte Logs.
  - Synchronisiere Alerts für kohärente Benachrichtigungen.
- **Sicherheit**:
  - Schränke Netzwerkzugriff ein:
    ```bash
    sudo ufw allow from 192.168.30.0/24 to any port 5000
    sudo ufw allow from 192.168.30.0/24 to any port 9200
    sudo ufw allow from 192.168.30.0/24 to any port 5601
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
  - Ändere Checkmk-Passwort:
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
  - Prüfe ELK-Logs:
    ```bash
    sudo journalctl -u elasticsearch
    sudo journalctl -u logstash
    sudo journalctl -u kibana
    ```

**Quelle**: https://docs.checkmk.com, https://www.elastic.co/guide

## Empfehlungen für Schüler

- **Setup**: Checkmk und ELK auf Ubuntu-VM, TrueNAS-Backups.
- **Workloads**: Systemmetriken und Apache-Logs in kombinierten Dashboards.
- **Integration**: Proxmox (VM), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Dashboard mit CPU, Speicher und Log-Eventen.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einfachen Metriken und Logs, erweitere schrittweise.
- **Übung**: Experimentiere mit weiteren Log-Quellen (z. B. Docker, Systemlogs).
- **Fehlerbehebung**: Nutze Checkmk-Service-Scans und Kibana-Discover.
- **Lernressourcen**: https://docs.checkmk.com, https://www.elastic.co/guide, https://pve.proxmox.com/wiki.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Kombination von Checkmk und ELK für umfassendes Monitoring.
- **Datenschutz**: Lokale Umgebung ohne Cloud-Abhängigkeit.
- **Lernwert**: Verständnis von Metrik- und Log-Integration.

**Nächste Schritte**: Möchtest du eine Anleitung zu erweiterten Checkmk-Plugins, ELK-Integration mit Kubernetes, oder Log-Aggregation mit Fluentd?

**Quellen**:
- Checkmk-Dokumentation: https://docs.checkmk.com
- Elastic-Dokumentation: https://www.elastic.co/guide/en/elastic-stack/current/index.html
- Proxmox VE-Dokumentation: https://pve.proxmox.com/pve-docs/
- Webquellen:,,,,,
```