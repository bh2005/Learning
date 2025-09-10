# Lernprojekt: Zentralisierte Log-Verarbeitung mit ELK Stack in einer HomeLab

## Einführung

Der **ELK Stack** (Elasticsearch, Logstash, Kibana) ist ein Open-Source-Framework für die zentralisierte Verarbeitung, Speicherung und Visualisierung von Log-Daten. Dieses Lernprojekt führt die Grundlagen des ELK Stacks in einer HomeLab-Umgebung ein, die auf einer Ubuntu-VM (Proxmox VE, IP `192.168.30.101`) mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement läuft. Es ist für Lernende mit Grundkenntnissen in Linux, Docker, Bash und Netzwerkkonzepten geeignet und baut auf `02_checkmk_monitoring_module.md` auf. Das Projekt nutzt einen Apache-Webserver, um große Log-Dateien zu simulieren, und umfasst drei Übungen: Einrichten des ELK Stacks mit Docker, Konfiguration von Logstash zur Verarbeitung von Apache-Logs, und Visualisierung der Logs mit Kibana. Es ist lokal, kostenlos (Open-Source-Version) und datenschutzfreundlich.

**Voraussetzungen**:
- Ubuntu 22.04 VM auf Proxmox (ID 101, IP `192.168.30.101`), mit Docker installiert (siehe `03_ci_cd_security_scanning_module.md`).
- Hardware: Mindestens 8 GB RAM, 4 CPU-Kerne, 30 GB freier Speicher (ELK ist ressourcenintensiv).
- Grundkenntnisse in Linux (`bash`, `nano`), Docker, Git und SSH.
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`).
- Internetzugang für initiale Downloads (ELK Stack, Apache).

**Ziele**:
- Einrichten des ELK Stacks mit Docker für zentralisierte Log-Verarbeitung.
- Konfiguration von Logstash zur Verarbeitung großer Apache-Log-Dateien.
- Visualisierung und Analyse der Logs mit Kibana-Dashboards.
- Integration mit der HomeLab für Backups und Netzwerkmanagement.

**Hinweis**: Das Projekt verwendet die Open-Source-Version des ELK Stacks (keine Elastic-Lizenz) und läuft lokal, um die Privatsphäre zu schützen.

**Quellen**:
- Elastic-Dokumentation: https://www.elastic.co/guide/en/elastic-stack/current/index.html
- Apache-Dokumentation: https://httpd.apache.org/docs/2.4/
- Webquellen:,,,,,

## Lernprojekt: ELK Stack für zentralisierte Log-Verarbeitung

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
   mkdir ~/elk-logging
   cd ~/elk-logging
   ```
3. **Apache-Webserver installieren**:
   - Installiere Apache:
     ```bash
     sudo apt update
     sudo apt install -y apache2
     sudo systemctl enable apache2
     sudo systemctl start apache2
     ```
   - Prüfe:
     ```bash
     curl http://192.168.30.101
     ```
     - Erwartete Ausgabe: Standard-Apache-Seite.

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Proxmox und TrueNAS.

### Übung 1: Einrichten des ELK Stacks mit Docker

**Ziel**: Einrichten von Elasticsearch, Logstash und Kibana mit Docker für zentralisierte Log-Verarbeitung.

**Aufgabe**: Starte den ELK Stack mit Docker Compose und überprüfe die Funktionalität.

1. **Docker Compose für ELK Stack erstellen**:
   ```bash
   nano docker-compose.yml
   ```
   - Inhalt:
     ```yaml
     version: '3.7'
     services:
       elasticsearch:
         image: docker.elastic.co/elasticsearch/elasticsearch:8.15.0
         environment:
           - discovery.type=single-node
           - xpack.security.enabled=false
           - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
         volumes:
           - es-data:/usr/share/elasticsearch/data
         ports:
           - "9200:9200"
         networks:
           - elk-net
       logstash:
         image: docker.elastic.co/logstash/logstash:8.15.0
         volumes:
           - ./logstash:/usr/share/logstash/pipeline
         ports:
           - "5044:5044"
         depends_on:
           - elasticsearch
         networks:
           - elk-net
       kibana:
         image: docker.elastic.co/kibana/kibana:8.15.0
         environment:
           - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
         ports:
           - "5601:5601"
         depends_on:
           - elasticsearch
         networks:
           - elk-net
     volumes:
       es-data:
     networks:
       elk-net:
         driver: bridge
     ```
   - **Erklärung**:
     - `elasticsearch`: Speichert und indiziert Logs.
     - `logstash`: Verarbeitet und leitet Logs weiter.
     - `kibana`: Visualisiert Logs.
     - `xpack.security.enabled=false`: Deaktiviert Sicherheitsfeatures für Einfachheit.
     - `ES_JAVA_OPTS`: Begrenzt Speichernutzung für HomeLab.

2. **ELK Stack starten**:
   ```bash
   docker-compose up -d
   ```

3. **ELK Stack prüfen**:
   - Elasticsearch:
     ```bash
     curl http://192.168.30.101:9200
     ```
     - Erwartete Ausgabe:
       ```json
       {
         "name": "...",
         "version": { "number": "8.15.0" }
       }
       ```
   - Kibana:
     - Öffne `http://192.168.30.101:5601` in einem Browser.
     - Erwartete Ausgabe: Kibana-Weboberfläche.
   - Logstash:
     ```bash
     docker logs $(docker ps -q -f name=logstash)
     ```

**Erkenntnis**: Der ELK Stack mit Docker ermöglicht eine einfache Einrichtung für zentralisierte Log-Verarbeitung in der HomeLab.

**Quelle**: https://www.elastic.co/guide/en/elastic-stack/current/index.html

### Übung 2: Konfiguration von Logstash zur Verarbeitung von Apache-Logs

**Ziel**: Konfiguration von Logstash zur Verarbeitung und Indizierung von Apache-Log-Dateien.

**Aufgabe**: Erstelle eine Logstash-Pipeline, um Apache-Logs zu verarbeiten, und sende sie an Elasticsearch.

1. **Apache-Logs generieren**:
   - Simuliere Zugriffe, um große Log-Dateien zu erzeugen:
     ```bash
     for i in {1..1000}; do curl http://192.168.30.101; done
     ```
   - Prüfe Apache-Logs:
     ```bash
     sudo tail /var/log/apache2/access.log
     ```
     - Erwartete Ausgabe: Common Log Format (z. B. `192.168.30.101 - - [...] "GET / HTTP/1.1" 200 ...`).

2. **Logstash-Pipeline erstellen**:
   ```bash
   mkdir logstash
   nano logstash/apache-pipeline.conf
   ```
   - Inhalt:
     ```conf
     input {
       file {
         path => "/var/log/apache2/access.log"
         start_position => "beginning"
       }
     }
     filter {
       grok {
         match => { "message" => "%{COMBINEDAPACHELOG}" }
       }
       date {
         match => [ "timestamp", "dd/MMM/yyyy:HH:mm:ss Z" ]
       }
     }
     output {
       elasticsearch {
         hosts => ["http://elasticsearch:9200"]
         index => "apache-logs-%{+YYYY.MM.dd}"
       }
     }
     ```
   - **Erklärung**:
     - `input`: Liest Apache-Logs aus `/var/log/apache2/access.log`.
     - `filter`: Parsed Logs mit `COMBINEDAPACHELOG` und extrahiert Zeitstempel.
     - `output`: Sendet Logs an Elasticsearch in tägliche Indizes.

3. **Logstash neu starten**:
   - Stelle sicher, dass Apache-Logs für Logstash lesbar sind:
     ```bash
     sudo chmod -R 644 /var/log/apache2/access.log
     ```
   - Aktualisiere `docker-compose.yml`:
     ```bash
     nano docker-compose.yml
     ```
     - Füge ein Volume für Logstash hinzu:
       ```yaml
       logstash:
         image: docker.elastic.co/logstash/logstash:8.15.0
         volumes:
           - ./logstash:/usr/share/logstash/pipeline
           - /var/log/apache2:/var/log/apache2:ro
         ports:
           - "5044:5044"
         depends_on:
           - elasticsearch
         networks:
           - elk-net
     ```
   - Starte neu:
     ```bash
     docker-compose down
     docker-compose up -d
     ```

4. **Logs in Elasticsearch prüfen**:
   - Überprüfe den Index:
     ```bash
     curl http://192.168.30.101:9200/_cat/indices/apache-logs*
     ```
     - Erwartete Ausgabe:
       ```
       yellow open apache-logs-2025.09.10 ...
       ```

**Erkenntnis**: Logstash parst und leitet Apache-Logs effizient an Elasticsearch weiter, ideal für die Verarbeitung großer Log-Dateien.

**Quelle**: https://www.elastic.co/guide/en/logstash/current/plugins-inputs-file.html

### Übung 3: Visualisierung der Logs mit Kibana-Dashboards

**Ziel**: Visualisierung und Analyse der Apache-Logs mit Kibana.

**Aufgabe**: Erstelle einen Kibana-Index-Pattern und ein Dashboard für Apache-Logs.

1. **Index-Pattern in Kibana erstellen**:
   - Öffne `http://192.168.30.101:5601`.
   - Gehe zu `Stack Management` -> `Index Patterns` -> `Create index pattern`.
   - Name: `apache-logs-*`.
   - Zeitfeld: `@timestamp`.
   - Klicke auf `Create index pattern`.

2. **Dashboard erstellen**:
   - Gehe zu `Analytics` -> `Dashboard` -> `Create dashboard`.
   - Füge Visualisierungen hinzu:
     - **Anfragen pro Minute**:
       - Typ: `Metric`.
       - Metrik: `Count`.
       - Zeitbereich: `Last 1 hour`.
     - **Top URLs**:
       - Typ: `Pie`.
       - Feld: `request.keyword`.
     - **Status Codes**:
       - Typ: `Bar`.
       - X-Achse: `response.keyword`.
       - Y-Achse: `Count`.
   - Speichere das Dashboard als `Apache Logs Dashboard`.

3. **Dashboard prüfen**:
   - Öffne das Dashboard unter `Dashboard` -> `Apache Logs Dashboard`.
   - Erwartete Ausgabe: Visualisierungen zeigen Anfragen, URLs und Status-Codes.

**Erkenntnis**: Kibana ermöglicht die benutzerfreundliche Visualisierung und Analyse von Apache-Logs, ideal für die Fehlersuche und Leistungsüberwachung.

**Quelle**: https://www.elastic.co/guide/en/kibana/current/dashboard.html

### Schritt 4: Integration mit HomeLab
1. **Backups auf TrueNAS**:
   - Archiviere das Projekt:
     ```bash
     tar -czf ~/elk-logging-backup-$(date +%F).tar.gz ~/elk-logging
     rsync -av ~/elk-logging-backup-$(date +%F).tar.gz root@192.168.30.100:/mnt/tank/backups/elk-logging/
     ```
   - Automatisiere:
     ```bash
     nano /home/ubuntu/backup.sh
     ```
     - Inhalt (am Ende hinzufügen):
       ```bash
       DATE=$(date +%F)
       tar -czf /home/ubuntu/elk-logging-backup-$DATE.tar.gz ~/elk-logging
       rsync -av /home/ubuntu/elk-logging-backup-$DATE.tar.gz root@192.168.30.100:/mnt/tank/backups/elk-logging/
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /home/ubuntu/backup.sh
       ```

2. **Netzwerkmanagement mit OPNsense**:
   - Aktualisiere die Firewall-Regel in OPNsense, um Zugriff auf `192.168.30.101:80` (Apache), `192.168.30.101:9200` (Elasticsearch), und `192.168.30.101:5601` (Kibana) von `192.168.30.0/24` zu erlauben:
     - Quelle: `192.168.30.0/24`
     - Ziel: `192.168.30.101`
     - Ports: `80,9200,5601`
     - Aktion: `Allow`

### Schritt 5: Erweiterung der Übungen
1. **Filebeat statt Logstash**:
   - Verwende Filebeat für leichtgewichtige Log-Übertragung:
     ```bash
     nano docker-compose.yml
     ```
     - Füge hinzu:
       ```yaml
       filebeat:
         image: docker.elastic.co/beats/filebeat:8.15.0
         volumes:
           - ./filebeat.yml:/usr/share/filebeat/filebeat.yml:ro
           - /var/log/apache2:/var/log/apache2:ro
         depends_on:
           - elasticsearch
         networks:
           - elk-net
       ```
     - Erstelle `filebeat.yml`:
       ```yaml
       filebeat.inputs:
       - type: log
         paths:
           - /var/log/apache2/access.log
       output.elasticsearch:
         hosts: ["http://elasticsearch:9200"]
         index: "apache-logs-%{+yyyy.MM.dd}"
       ```
2. **Kibana Alerts**:
   - Erstelle eine Benachrichtigung für HTTP 500-Fehler:
     - Gehe zu `Analytics` -> `Discover`, filtere auf `response:500`.
     - Erstelle eine Alert-Regel in `Stack Management` -> `Alerts`.

## Best Practices für Schüler

- **Ressourcenmanagement**:
  - Begrenze ELK-Ressourcen:
    ```bash
    docker-compose.yml
    ```
    - Setze `ES_JAVA_OPTS=-Xms512m -Xmx512m` für Elasticsearch.
  - Überwache:
    ```bash
    docker stats
    ```
- **Sicherheit**:
  - Schränke Netzwerkzugriff ein:
    ```bash
    sudo ufw allow from 192.168.30.0/24 to any port 80
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
  - Prüfe ELK-Logs:
    ```bash
    docker logs $(docker ps -q -f name=elasticsearch)
    docker logs $(docker ps -q -f name=logstash)
    docker logs $(docker ps -q -f name=kibana)
    ```

**Quelle**: https://www.elastic.co/guide, https://httpd.apache.org/docs/2.4/

## Empfehlungen für Schüler

- **Setup**: ELK Stack, Apache-Webserver auf Ubuntu-VM, TrueNAS-Backups.
- **Workloads**: Verarbeitung und Visualisierung von Apache-Logs.
- **Integration**: Proxmox (VM), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Apache-Logs mit ELK Stack.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einer einfachen Logstash-Pipeline und füge komplexere Filter hinzu.
- **Übung**: Analysiere weitere Log-Formate (z. B. Nginx, Systemlogs).
- **Fehlerbehebung**: Nutze Kibana `Discover` und Docker-Logs für Debugging.
- **Lernressourcen**: https://www.elastic.co/guide, https://httpd.apache.org/docs, https://pve.proxmox.com/wiki.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Zentralisierte Log-Verarbeitung mit ELK Stack.
- **Datenschutz**: Lokale Umgebung ohne Cloud-Abhängigkeit.
- **Lernwert**: Verständnis von Log-Sammlung, -Verarbeitung und -Visualisierung.

Es ist ideal für Schüler, die Log-Management in einer HomeLab erkunden möchten.

**Nächste Schritte**: Möchtest du eine Anleitung zu erweiterten ELK-Features (z. B. Filebeat, Alerts), Integration mit Kubernetes, oder Kombination mit Checkmk?

**Quellen**:
- Elastic-Dokumentation: https://www.elastic.co/guide/en/elastic-stack/current/index.html
- Apache-Dokumentation: https://httpd.apache.org/docs/2.4/
- Proxmox VE-Dokumentation: https://pve.proxmox.com/pve-docs/
- Webquellen:,,,,,
```