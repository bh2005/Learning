# Anleitung: ELK Stack-Installation auf Debian via APT und als LXC in Proxmox

## Einführung

Der **ELK Stack** (Elasticsearch, Logstash, Kibana) ist ein Open-Source-Framework für die zentralisierte Verarbeitung, Speicherung und Visualisierung von Log-Daten. Diese Anleitung beschreibt zwei Installationsmethoden für eine HomeLab-Umgebung: 1) **Nativ via APT auf Debian 12 (Bookworm)**, für eine stabile, integrierte Installation auf einer VM, und 2) **Als LXC-Container auf Proxmox VE**, für isolierte und ressourcenschonende Bereitstellung. Die Anleitung ist für Lernende mit Grundkenntnissen in Linux, Docker und Bash geeignet und baut auf vorherigen Projekten (z. B. `03_elk_stack_logging_module.md`, auf. Es nutzt eine Ubuntu/Debian-VM auf einem Proxmox VE-Server (IP `192.168.30.101`) in einer HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement. Die Installation verwendet die Open-Source-Version (Elastic Stack 8.15.0) und integriert Apache-Logs als Beispiel.

**Voraussetzungen**:
- Proxmox VE-Server (z. B. Version 8.x) mit einer Ubuntu 22.04 oder Debian 12 VM (ID 101, IP `192.168.30.101`).
- Hardware: Mindestens 8 GB RAM, 4 CPU-Kerne, 30 GB freier Speicher (ELK ist ressourcenintensiv).
- Grundkenntnisse in Linux (`bash`, `nano`), APT und SSH.
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`).
- Für LXC: LXC-Vorlage (z. B. Ubuntu 22.04) auf Proxmox verfügbar.
- Internetzugang für initiale Downloads (Elastic-Pakete).

**Ziele**:
- Nativer ELK Stack auf Debian via APT installieren.
- ELK Stack als LXC-Container auf Proxmox bereitstellen.
- Konfiguration für Apache-Log-Verarbeitung und Visualisierung.
- Integration mit der HomeLab für Backups und Netzwerkmanagement.

**Hinweis**: Die Open-Source-Version von ELK ist kostenlos, aber Elasticsearch benötigt eine Lizenz für fortgeschrittene Features (nicht erforderlich für dieses Projekt).

**Quellen**:
- Elastic-Dokumentation: https://www.elastic.co/guide/en/elastic-stack/current/index.html
- Proxmox LXC-Dokumentation: https://pve.proxmox.com/wiki/Linux_Container
- Webquellen:,,,,,

## Lernprojekt: ELK Stack-Installation

### Vorbereitung: Umgebung einrichten
1. **Proxmox-VM prüfen**:
   - Stelle sicher, dass die Ubuntu 22.04 oder Debian 12 VM (IP `192.168.30.101`) läuft:
     ```bash
     ssh ubuntu@192.168.30.101  # Oder root@ für Debian
     ```
   - Prüfe Ressourcen:
     ```bash
     free -h
     df -h
     ```
2. **Apache-Webserver installieren** (falls nicht vorhanden):
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
3. **Projektverzeichnis erstellen**:
   ```bash
   mkdir ~/elk-install
   cd ~/elk-install
   ```

**Tipp**: Für Debian 12 (Bookworm) verwende `root` als Benutzer; für Ubuntu 22.04 `ubuntu` mit `sudo`.

### Methode 1: ELK Stack via APT auf Debian/Ubuntu

**Ziel**: Nativer ELK Stack auf einer Debian/Ubuntu-VM via APT installieren.

**Aufgabe**: Installiere Elasticsearch, Logstash und Kibana, konfiguriere eine Pipeline für Apache-Logs und starte den Stack.

1. **Elastic-Repository hinzufügen** (für Ubuntu 22.04 oder Debian 12):
   ```bash
   wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
   sudo apt update
   ```

2. **Elasticsearch installieren**:
   ```bash
   sudo apt install -y elasticsearch
   ```
   - Konfiguriere `/etc/elasticsearch/elasticsearch.yml`:
     ```bash
     sudo nano /etc/elasticsearch/elasticsearch.yml
     ```
     - Inhalt:
       ```yaml
       network.host: localhost
       discovery.type: single-node
       xpack.security.enabled: false
       ```
   - Starte Elasticsearch:
     ```bash
     sudo systemctl daemon-reload
     sudo systemctl enable elasticsearch
     sudo systemctl start elasticsearch
     ```
   - Prüfe:
     ```bash
     curl http://localhost:9200
     ```
     - Erwartete Ausgabe:
       ```json
       {
         "name": "...",
         "version": { "number": "8.15.0" }
       }
       ```

3. **Logstash installieren**:
   ```bash
   sudo apt install -y logstash
   ```
   - Erstelle eine Pipeline-Konfiguration:
     ```bash
     sudo nano /etc/logstash/conf.d/apache-pipeline.conf
     ```
     - Inhalt:
       ```conf
       input {
         file {
           path => "/var/log/apache2/access.log"
           start_position => "beginning"
           sincedb_path => "/var/lib/logstash/apache.sincedb"
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
           hosts => ["http://localhost:9200"]
           index => "apache-logs-%{+YYYY.MM.dd}"
         }
       }
       ```
   - Starte Logstash:
     ```bash
     sudo systemctl enable logstash
     sudo systemctl start logstash
     ```
   - Prüfe:
     ```bash
     sudo journalctl -u logstash
     ```

4. **Kibana installieren**:
   ```bash
   sudo apt install -y kibana
   ```
   - Konfiguriere `/etc/kibana/kibana.yml`:
     ```bash
     sudo nano /etc/kibana/kibana.yml
     ```
     - Inhalt:
       ```yaml
       server.port: 5601
       server.host: "0.0.0.0"
       elasticsearch.hosts: ["http://localhost:9200"]
       ```
   - Starte Kibana:
     ```bash
     sudo systemctl enable kibana
     sudo systemctl start kibana
     ```
   - Prüfe:
     ```bash
     curl http://192.168.30.101:5601
     ```

5. **ELK Stack testen**:
   - Generiere Logs:
     ```bash
     for i in {1..100}; do curl http://192.168.30.101; done
     ```
   - Öffne Kibana: `http://192.168.30.101:5601`.
   - Erstelle ein Index-Pattern: `Stack Management` -> `Index Patterns` -> `apache-logs-*`.
   - Prüfe Logs: `Analytics` -> `Discover` -> Index `apache-logs-*`.
     - Erwartete Ausgabe: Apache-Logs mit Feldern wie `clientip`, `response`, `timestamp`.

**Erkenntnis**: Die nativen APT-Installationen bieten eine stabile, integrierte ELK-Umgebung, ideal für HomeLabs mit langfristiger Nutzung.

**Quelle**: https://www.elastic.co/guide/en/elastic-stack/current/installing-elastic-stack.html

### Methode 2: ELK Stack als LXC-Container auf Proxmox

**Ziel**: Bereitstellung des ELK Stacks als LXC-Container für isolierte und ressourcenschonende Installation.

**Aufgabe**: Erstelle einen LXC-Container mit Ubuntu 22.04, installiere ELK via APT und konfiguriere Apache-Log-Verarbeitung.

1. **LXC-Container erstellen** (auf Proxmox-Weboberfläche oder CLI):
   - CLI:
     ```bash
     pct create 102 local:vztmpl/ubuntu-22.04-standard_amd64.tar.gz --hostname elk-lxc --storage local-lvm --rootfs 20 --cores 2 --memory 4096 --net0 name=eth0,bridge=vmbr0,ip=192.168.30.102/24,gw=192.168.30.1
     pct start 102
     ```
   - Prüfe:
     ```bash
     pct status 102
     ```

2. **In den Container verbinden**:
   ```bash
   pct enter 102
   ```

3. **ELK Stack via APT installieren**:
   - Folge den Schritten aus Methode 1 (Schritte 1–5) innerhalb des Containers:
     - Elastic-Repository hinzufügen.
     - Elasticsearch, Logstash, Kibana installieren und konfigurieren.
     - Apache installieren (für Logs):
       ```bash
       apt update
       apt install -y apache2
       systemctl enable apache2
       systemctl start apache2
       ```
   - Generiere Logs:
     ```bash
     for i in {1..100}; do curl http://localhost; done
     ```

4. **ELK Stack testen**:
   - Elasticsearch: `curl http://localhost:9200`.
   - Kibana: `http://192.168.30.102:5601`.
   - Prüfe Logs in Kibana.

5. **Container prüfen**:
   - Von Proxmox aus:
     ```bash
     pct status 102
     ```

**Erkenntnis**: LXC-Container bieten Isolation und Ressourcenschonung für ELK, ideal für HomeLabs mit begrenztem RAM.

**Quelle**: https://pve.proxmox.com/wiki/Linux_Container

### Schritt 4: Integration mit HomeLab
1. **Backups auf TrueNAS**:
   - Für APT-Installation (VM):
     ```bash
     tar -czf ~/elk-apt-backup-$(date +%F).tar.gz /etc/elasticsearch /etc/logstash /etc/kibana /var/log/apache2
     rsync -av ~/elk-apt-backup-$(date +%F).tar.gz root@192.168.30.100:/mnt/tank/backups/elk-apt/
     ```
   - Für LXC:
     ```bash
     pct stop 102
     tar -czf ~/elk-lxc-backup-$(date +%F).tar.gz /var/lib/lxc/102/rootfs/etc/elasticsearch /var/lib/lxc/102/rootfs/etc/logstash /var/lib/lxc/102/rootfs/etc/kibana /var/lib/lxc/102/rootfs/var/log/apache2
     rsync -av ~/elk-lxc-backup-$(date +%F).tar.gz root@192.168.30.100:/mnt/tank/backups/elk-lxc/
     pct start 102
     ```
   - Automatisiere:
     ```bash
     nano /home/ubuntu/backup.sh
     ```
     - Inhalt (am Ende hinzufügen):
       ```bash
       DATE=$(date +%F)
       tar -czf /home/ubuntu/elk-backup-$DATE.tar.gz /etc/elasticsearch /etc/logstash /etc/kibana /var/log/apache2
       rsync -av /home/ubuntu/elk-backup-$DATE.tar.gz root@192.168.30.100:/mnt/tank/backups/elk/
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /home/ubuntu/backup.sh
       ```

2. **Netzwerkmanagement mit OPNsense**:
   - Aktualisiere die Firewall-Regel in OPNsense, um Zugriff auf `192.168.30.101:9200` (Elasticsearch), `192.168.30.101:5044` (Logstash), und `192.168.30.101:5601` (Kibana) von `192.168.30.0/24` zu erlauben:
     - Quelle: `192.168.30.0/24`
     - Ziel: `192.168.30.101`
     - Ports: `9200,5044,5601`
     - Aktion: `Allow`

### Schritt 5: Erweiterung der Übungen
1. **Filebeat statt Logstash**:
   - Installiere Filebeat:
     ```bash
     wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.15.0-amd64.deb
     sudo dpkg -i filebeat-8.15.0-amd64.deb
     ```
   - Konfiguriere `/etc/filebeat/filebeat.yml`:
     ```yaml
     filebeat.inputs:
     - type: log
       paths:
         - /var/log/apache2/access.log
     output.elasticsearch:
       hosts: ["localhost:9200"]
     ```
   - Starte Filebeat:
     ```bash
     sudo systemctl enable filebeat
     sudo systemctl start filebeat
     ```

2. **Kibana Alerts**:
   - Erstelle eine Alert-Regel:
     - Gehe zu `Stack Management` -> `Rules` -> `Create rule`.
     - Index: `apache-logs-*`.
     - Bedingung: `response:500` (HTTP-Fehler).
     - Aktion: E-Mail (konfiguriere SMTP in `Stack Management` -> `Notifications`).

## Best Practices für Schüler

- **Ressourcenmanagement**:
  - Begrenze ELK-Ressourcen:
    - Elasticsearch: `ES_JAVA_OPTS=-Xms512m -Xmx512m`.
  - Überwache:
    ```bash
    docker stats
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
  - Aktiviere Elasticsearch-Sicherheit (optional):
    - In `elasticsearch.yml`: `xpack.security.enabled: true`.
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe ELK-Logs:
    ```bash
    sudo journalctl -u elasticsearch
    sudo journalctl -u logstash
    sudo journalctl -u kibana
    ```

**Quelle**: https://www.elastic.co/guide/en/elastic-stack/current/index.html

## Empfehlungen für Schüler

- **Setup**: ELK Stack via APT oder LXC, Apache-Webserver, TrueNAS-Backups.
- **Workloads**: Verarbeitung und Visualisierung von Apache-Logs.
- **Integration**: Proxmox (VM/LXC), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Große Apache-Log-Dateien mit ELK Stack.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einer einfachen Logstash-Pipeline und füge komplexere Filter hinzu.
- **Übung**: Analysiere weitere Log-Formate (z. B. Systemlogs, Docker-Logs).
- **Fehlerbehebung**: Nutze Kibana `Discover` und Journalctl-Logs für Debugging.
- **Lernressourcen**: https://www.elastic.co/guide, https://pve.proxmox.com/wiki.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Zwei Installationsmethoden (APT, LXC) für ELK Stack.
- **Datenschutz**: Lokale Umgebung ohne Cloud-Abhängigkeit.
- **Lernwert**: Verständnis von zentralisierter Log-Verarbeitung und Visualisierung.

Es ist ideal für Schüler, die Log-Management in einer HomeLab erkunden möchten.

**Nächste Schritte**: Möchtest du eine Anleitung zu erweiterten ELK-Features (z. B. Filebeat, Alerts), Integration mit Kubernetes, oder Kombination mit Checkmk?

**Quellen**:
- Elastic-Dokumentation: https://www.elastic.co/guide/en/elastic-stack/current/index.html
- Proxmox LXC-Dokumentation: https://pve.proxmox.com/wiki/Linux_Container
- Apache-Dokumentation: https://httpd.apache.org/docs/2.4/
- Webquellen:,,,,,
```