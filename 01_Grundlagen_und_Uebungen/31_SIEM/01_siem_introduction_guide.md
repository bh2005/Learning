# Lernprojekt: Einführung in Security Information and Event Management (SIEM) mit ELK Stack und Checkmk

## Einführung

**Security Information and Event Management (SIEM)** ist eine Methode zur zentralisierten Sammlung, Korrelation und Analyse von Logs aus verschiedenen Quellen, um Sicherheitsvorfälle zu erkennen und darauf zu reagieren. Dieses Lernprojekt führt in die Grundlagen von SIEM ein, indem es zeigt, wie man Logs von einer Ubuntu-VM und einem OPNsense-Router mit der **ELK Stack (Elasticsearch, Logstash, Kibana)** und **Checkmk** zentralisiert, korreliert und analysiert. Es baut auf `elk_checkmk_integration_guide.md` () und `network_automation_guide.md` () auf und nutzt die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense) für Backups. Das Projekt ist für Lernende mit Grundkenntnissen in Linux, Python und Netzwerkadministration geeignet und ist lokal, kostenlos und datenschutzfreundlich. Es umfasst drei Übungen: Einrichten von ELK Stack für Log-Sammlung, Konfiguration von Checkmk für Sicherheitsüberwachung, und Analyse von Logs für Sicherheitsvorfälle mit Kibana.

**Voraussetzungen**:
- Ubuntu-VM auf Proxmox (IP `192.168.30.101`) mit Checkmk Raw Edition (Site `homelab`) installiert (siehe `elk_checkmk_integration_guide.md`).
- OPNsense-Router (IP `192.168.30.1`) mit Syslog aktiviert.
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups.
- Grundkenntnisse in Linux, Python, Log-Management und Netzwerkkonfiguration.
- `python3`, `pip`, `curl`, und `rsync` installiert auf der Ubuntu-VM.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`).

**Ziele**:
- Einrichten der ELK Stack für zentrale Log-Sammlung von Ubuntu-VM und OPNsense.
- Konfiguration von Checkmk für Sicherheitsüberwachung und Event-Korrelation.
- Analyse von Logs in Kibana zur Erkennung von Sicherheitsvorfällen.
- Backup von Logs auf TrueNAS.

**Hinweis**: Die ELK Stack sammelt und visualisiert Logs, während Checkmk Sicherheitsmetriken und -events korreliert, um ein einfaches SIEM-Setup zu erstellen.

**Quellen**:
- ELK Stack-Dokumentation: https://www.elastic.co/guide/index.html
- Checkmk-Dokumentation: https://docs.checkmk.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,,,,

## Lernprojekt: SIEM mit ELK Stack und Checkmk

### Vorbereitung: Umgebung einrichten
1. **Ubuntu-VM prüfen**:
   - Verbinde dich mit der VM:
     ```bash
     ssh ubuntu@192.168.30.101
     ```
   - Installiere notwendige Pakete:
     ```bash
     sudo apt update
     sudo apt install -y openjdk-17-jdk curl python3-pip
     pip3 install requests
     ```
   - Prüfe Checkmk:
     ```bash
     curl http://192.168.30.101:5000/homelab
     sudo omd status homelab
     ```
2. **OPNsense Syslog aktivieren**:
   - Öffne die OPNsense-Weboberfläche: `http://192.168.30.1`.
   - Gehe zu `System > Settings > Logging / Targets`.
   - Füge einen Remote-Syslog-Server hinzu:
     - Host: `192.168.30.101`
     - Port: `514`
     - Protokoll: `UDP`
     - Anwendungen: `Firewall`, `System`
     - Speichern und anwenden.
3. **Projektverzeichnis erstellen**:
   ```bash
   mkdir ~/siem-elk
   cd ~/siem-elk
   ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf OPNsense und TrueNAS.

### Übung 1: Einrichten der ELK Stack für Log-Sammlung

**Ziel**: Installiere und konfiguriere die ELK Stack, um Logs von Ubuntu-VM und OPNsense zu zentralisieren.

**Aufgabe**: Richte Elasticsearch, Logstash und Kibana ein und sammle Syslogs.

1. **Elasticsearch installieren**:
   - Lade und installiere Elasticsearch:
     ```bash
     wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.15.0-amd64.deb
     sudo dpkg -i elasticsearch-8.15.0-amd64.deb
     ```
   - Konfiguriere Elasticsearch:
     ```bash
     sudo nano /etc/elasticsearch/elasticsearch.yml
     ```
     - Ändere:
       ```
       network.host: 192.168.30.101
       http.port: 9200
       ```
   - Starte Elasticsearch:
     ```bash
     sudo systemctl start elasticsearch
     sudo systemctl enable elasticsearch
     ```
   - Teste:
     ```bash
     curl http://192.168.30.101:9200
     ```
     - Erwartete Ausgabe: JSON mit Cluster-Informationen.

2. **Logstash installieren**:
   - Lade und installiere Logstash:
     ```bash
     wget https://artifacts.elastic.co/downloads/logstash/logstash-8.15.0-amd64.deb
     sudo dpkg -i logstash-8.15.0-amd64.deb
     ```
   - Erstelle eine Logstash-Konfigurationsdatei:
     ```bash
     sudo nano /etc/logstash/conf.d/syslog.conf
     ```
     - Inhalt:
       ```
       input {
         syslog {
           port => 514
         }
       }
       filter {
         if [type] == "syslog" {
           grok {
             match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
           }
           date {
             match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
           }
         }
       }
       output {
         elasticsearch {
           hosts => ["http://192.168.30.101:9200"]
           index => "syslog-%{+YYYY.MM.dd}"
         }
       }
       ```
   - Starte Logstash:
     ```bash
     sudo systemctl start logstash
     sudo systemctl enable logstash
     ```

3. **Kibana installieren**:
   - Lade und installiere Kibana:
     ```bash
     wget https://artifacts.elastic.co/downloads/kibana/kibana-8.15.0-amd64.deb
     sudo dpkg -i kibana-8.15.0-amd64.deb
     ```
   - Konfiguriere Kibana:
     ```bash
     sudo nano /etc/kibana/kibana.yml
     ```
     - Ändere:
       ```
       server.host: "192.168.30.101"
       server.port: 5601
       elasticsearch.hosts: ["http://192.168.30.101:9200"]
       ```
   - Starte Kibana:
     ```bash
     sudo systemctl start kibana
     sudo systemctl enable kibana
     ```
   - Teste:
     ```bash
     curl http://192.168.30.101:5601
     ```
     - Öffne Kibana: `http://192.168.30.101:5601`.

4. **Syslog-Daten prüfen**:
   - Erstelle einen Index in Kibana:
     - Gehe zu `Management > Index Patterns > Create Index Pattern`.
     - Name: `syslog-*`.
     - Zeitfeld: `@timestamp`.
   - Gehe zu `Discover` und prüfe Logs von `192.168.30.1` (OPNsense) und `192.168.30.101` (Ubuntu-VM).
   - Erwartete Ausgabe: Syslog-Einträge wie Firewall-Logs (`pf`) und System-Logs.

**Erkenntnis**: Die ELK Stack ermöglicht die zentrale Sammlung und Visualisierung von Logs aus verschiedenen Quellen.

**Quelle**: https://www.elastic.co/guide/en/elastic-stack/current/index.html

### Übung 2: Konfiguration von Checkmk für Sicherheitsüberwachung

**Ziel**: Nutze Checkmk, um Sicherheitsmetriken zu überwachen und Events zu korrelieren.

**Aufgabe**: Konfiguriere Checkmk für die Überwachung von Ubuntu-VM und OPNsense mit Fokus auf Sicherheitsvorfälle.

1. **Checkmk für Sicherheitsmetriken konfigurieren**:
   - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
   - Füge OPNsense als Host hinzu (falls nicht bereits vorhanden):
     - Gehe zu `Setup > Hosts > Add host`.
     - Hostname: `opnsense`, IP: `192.168.30.1`.
     - Speichern und `Discover services`.
   - Aktiviere Syslog-Überwachung:
     - Gehe zu `Setup > Services > Manual checks > Syslog`.
     - Host: `opnsense`.
     - Regel: `Syslog messages`, Muster: `.*(failed|denied).*`.
     - Speichern und `Discover services`.

2. **Event-Korrelation einrichten**:
   - Erstelle eine Regel für Sicherheitsvorfälle:
     - Gehe zu `Setup > Events > Event Console > Rule Packs > Add rule pack`.
     - Name: `Security Events`.
     - Regel: 
       - Bedingung: `Text to match`: `failed|denied|unauthorized`.
       - Aktion: `Set state to CRITICAL`.
     - Speichern.
   - Prüfe:
     - Gehe zu `Monitor > Event Console`.
     - Erwartete Ausgabe: Events wie `failed login` oder `denied connection`.

3. **Teste einen Sicherheitsvorfall**:
   - Simuliere einen fehlgeschlagenen SSH-Login auf OPNsense:
     ```bash
     ssh invalid_user@192.168.30.1
     ```
   - Prüfe in Checkmk:
     - Gehe zu `Monitor > Event Console`.
     - Erwartete Ausgabe: Event mit `failed login` und Status `CRITICAL`.

**Erkenntnis**: Checkmk bietet leistungsstarke Event-Korrelation für Sicherheitsüberwachung in einem SIEM-Setup.

**Quelle**: https://docs.checkmk.com/latest/en/monitoring_syslog.html

### Übung 3: Analyse von Logs für Sicherheitsvorfälle in Kibana

**Ziel**: Analysiere Logs in Kibana, um Sicherheitsvorfälle zu erkennen und zu visualisieren.

**Aufgabe**: Erstelle ein Dashboard in Kibana zur Analyse von potenziellen Sicherheitsvorfällen.

1. **Kibana-Dashboard erstellen**:
   - Öffne Kibana: `http://192.168.30.101:5601`.
   - Gehe zu `Dashboard > Create Dashboard`.
   - Füge Visualisierungen hinzu:
     - **Fehlgeschlagene Logins**:
       - Typ: `Metric`.
       - Datenquelle: `syslog-*`.
       - Filter: `syslog_message: failed OR denied`.
       - Aggregation: `Count`.
       - Titel: `Failed Logins`.
     - **Firewall-Blockierungen**:
       - Typ: `Line Chart`.
       - Datenquelle: `syslog-*`.
       - Filter: `syslog_program: pf AND syslog_message: block`.
       - X-Achse: `@timestamp`, Y-Achse: `Count`.
       - Titel: `Firewall Blocks Over Time`.
     - **Top-Quellen**:
       - Typ: `Pie Chart`.
       - Datenquelle: `syslog-*`.
       - Filter: `syslog_message: failed OR denied`.
       - Aggregation: `Terms` auf `syslog_hostname`.
       - Titel: `Top Sources of Security Events`.
   - Speichere als `Security Dashboard`.

2. **Sicherheitsvorfall analysieren**:
   - Simuliere einen weiteren Vorfall:
     ```bash
     ssh invalid_user@192.168.30.101
     ```
   - Prüfe in Kibana:
     - Gehe zu `Dashboard > Security Dashboard`.
     - Erwartete Ausgabe: Anstieg bei `Failed Logins` und Eintrag für `192.168.30.101` in `Top Sources`.

3. **Alerting einrichten**:
   - Erstelle einen Alert in Kibana:
     - Gehe zu `Observability > Alerts > Create Alert`.
     - Trigger: `syslog-*`, Bedingung: `syslog_message` enthält `failed OR denied`, Schwellwert: `> 5 in 5 minutes`.
     - Aktion: Log-Ausgabe (z. B. in Konsole).
     - Speichern als `Security Alert`.
   - Teste durch wiederholte fehlgeschlagene Logins:
     ```bash
     for i in {1..6}; do ssh invalid_user@192.168.30.101; sleep 1; done
     ```

**Erkenntnis**: Kibana ermöglicht die Visualisierung und Analyse von Sicherheitsvorfällen für schnelle Erkennung.

**Quelle**: https://www.elastic.co/guide/en/kibana/current/alerting-getting-started.html

### Schritt 4: Integration mit HomeLab
1. **Backup von Logs auf TrueNAS**:
   - Erstelle ein Backup-Skript:
     ```bash
     nano backup_logs.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       DATE=$(date +%F)
       BACKUP_DIR=/home/ubuntu/siem-elk/backup-$DATE
       mkdir -p $BACKUP_DIR
       # Export Elasticsearch indices
       curl -X GET "http://192.168.30.101:9200/syslog-$DATE/_search?pretty" > $BACKUP_DIR/syslog-$DATE.json
       # Backup Logstash and Kibana configs
       cp /etc/logstash/conf.d/syslog.conf $BACKUP_DIR/
       cp /etc/kibana/kibana.yml $BACKUP_DIR/
       # Transfer to TrueNAS
       rsync -av $BACKUP_DIR root@192.168.30.100:/mnt/tank/backups/siem-elk/
       ```
     - Ausführbar machen:
       ```bash
       chmod +x backup_logs.sh
       ```
     - Plane einen Cronjob:
       ```bash
       crontab -e
       ```
       - Füge hinzu:
         ```
         0 4 * * * /home/ubuntu/siem-elk/backup_logs.sh
         ```
       - **Erklärung**: Sichert Logs und Konfigurationen täglich um 04:00 Uhr.

2. **Netzwerkmanagement mit OPNsense**:
   - Aktualisiere die Firewall-Regel in OPNsense, um Zugriff auf `192.168.30.101:514` (Syslog), `192.168.30.101:9200` (Elasticsearch), und `192.168.30.101:5601` (Kibana) von `192.168.30.0/24` zu erlauben:
     - Quelle: `192.168.30.0/24`
     - Ziel: `192.168.30.101`
     - Ports: `514,9200,5601`
     - Aktion: `Allow`

### Schritt 5: Erweiterung der Übungen
1. **Erweiterte Korrelation**:
   - Erstelle eine komplexere Checkmk-Regel:
     - Gehe zu `Setup > Events > Event Console > Rule Packs`.
     - Regel: Kombiniere `failed login` mit `source IP` für Brute-Force-Erkennung.
     - Bedingung: `Text to match`: `failed login`, `Count > 5 in 5 minutes`.

2. **Erweiterte Visualisierung**:
   - Erstelle ein Kibana-Dashboard für Netzwerkverkehr:
     - Typ: `Area Chart`.
     - Datenquelle: `syslog-*`.
     - Filter: `syslog_program: pf`.
     - X-Achse: `@timestamp`, Y-Achse: `Count`, Split: `destination_ip`.

## Best Practices für Schüler

- **SIEM-Design**:
  - Zentralisiere Logs mit ELK Stack, korreliere Events mit Checkmk.
  - Nutze einfache Filter für den Einstieg (z. B. `failed`, `denied`).
- **Sicherheit**:
  - Schränke Netzwerkzugriff ein:
    ```bash
    sudo ufw allow from 192.168.30.0/24 to any port 514
    sudo ufw allow from 192.168.30.0/24 to any port 9200
    sudo ufw allow from 192.168.30.0/24 to any port 5601
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe Elasticsearch-Logs:
    ```bash
    sudo tail -f /var/log/elasticsearch/elasticsearch.log
    ```
  - Prüfe Logstash-Logs:
    ```bash
    sudo tail -f /var/log/logstash/logstash-plain.log
    ```
  - Prüfe Checkmk-Logs:
    ```bash
    sudo tail -f /omd/sites/homelab/var/log/web.log
    ```

**Quelle**: https://www.elastic.co/guide, https://docs.checkmk.com

## Empfehlungen für Schüler

- **Setup**: ELK Stack, Checkmk, TrueNAS-Backups.
- **Workloads**: Log-Sammlung und Sicherheitsanalyse.
- **Integration**: Proxmox (VM), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Erkennung von fehlgeschlagenen Logins und Firewall-Blockierungen.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einfachen Log-Filtern, erweitere zu komplexeren Korrelationen.
- **Übung**: Experimentiere mit weiteren Log-Quellen (z. B. Apache, Docker).
- **Fehlerbehebung**: Nutze Kibana `Discover` und Checkmk Event Console.
- **Lernressourcen**: https://www.elastic.co/guide, https://docs.checkmk.com, https://docs.opnsense.org.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: SIEM-Setup mit ELK Stack und Checkmk.
- **Skalierbarkeit**: Zentrale Log-Sammlung und Analyse.
- **Lernwert**: Verständnis von Log-Management und Sicherheitsüberwachung.

**Nächste Schritte**: Möchtest du eine Anleitung zu erweiterten Blue-Green Deployments, Log-Aggregation mit Fluentd, oder Integration mit Wazuh für erweitertes SIEM?

**Quellen**:
- ELK Stack-Dokumentation: https://www.elastic.co/guide/index.html
- Checkmk-Dokumentation: https://docs.checkmk.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,,,,
```