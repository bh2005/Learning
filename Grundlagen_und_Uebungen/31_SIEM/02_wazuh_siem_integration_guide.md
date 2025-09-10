# Lernprojekt: Integration von Wazuh für erweitertes SIEM in einer HomeLab-Umgebung

## Einführung

**Wazuh** ist eine Open-Source-Plattform für Sicherheitsüberwachung, die als erweitertes Security Information and Event Management (SIEM)-System dient. Es ermöglicht die Sammlung, Analyse und Korrelation von Logs, die Erkennung von Bedrohungen sowie die Reaktion auf Sicherheitsvorfälle. Dieses Lernprojekt zeigt, wie man Wazuh in einer HomeLab-Umgebung einrichtet, um Logs von einer Ubuntu-VM und einem OPNsense-Router zu analysieren, und integriert es mit Checkmk für umfassende Überwachung. Es baut auf `syslog_snmp_checkmk_homelab_guide.md` () und `siem_introduction_guide.md` () auf und nutzt die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense) für Backups. Das Projekt ist für Lernende mit Grundkenntnissen in Linux, Netzwerkadministration und Checkmk geeignet und ist lokal, kostenlos und datenschutzfreundlich. Es umfasst drei Übungen: Einrichten von Wazuh, Integration von Syslog und SNMP-Traps, und Analyse von Sicherheitsvorfällen mit Backup auf TrueNAS.

**Voraussetzungen**:
- Ubuntu-VM auf Proxmox (IP `192.168.30.101`) mit Checkmk Raw Edition (Site `homelab`) installiert (siehe `syslog_snmp_checkmk_homelab_guide.md`).
- OPNsense-Router (IP `192.168.30.1`) mit Syslog und SNMP aktiviert.
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups.
- Grundkenntnisse in Linux, Syslog, SNMP, Checkmk und Sicherheitsüberwachung.
- `python3`, `pip`, `rsyslog`, `snmptrapd`, `curl`, und `openssl` installiert auf der Ubuntu-VM.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`).
- Syslog- und SNMP-Konfiguration aus `syslog_snmp_checkmk_homelab_guide.md`.

**Ziele**:
- Einrichten von Wazuh für zentrale Log-Sammlung und Bedrohungserkennung.
- Integration von Syslog und SNMP-Traps von OPNsense und Ubuntu-VM in Wazuh.
- Analyse von Sicherheitsvorfällen in Wazuh und Backup von Daten auf TrueNAS.

**Hinweis**: Wazuh erweitert Checkmk durch Funktionen wie Echtzeit-Bedrohungserkennung, Dateiintegritätsprüfung und Compliance-Reporting.

**Quellen**:
- Wazuh-Dokumentation: https://documentation.wazuh.com
- Checkmk-Dokumentation: https://docs.checkmk.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,,,,

## Lernprojekt: Wazuh für erweitertes SIEM

### Vorbereitung: Umgebung einrichten
1. **Ubuntu-VM prüfen**:
   - Verbinde dich mit der VM:
     ```bash
     ssh ubuntu@192.168.30.101
     ```
   - Installiere notwendige Pakete:
     ```bash
     sudo apt update
     sudo apt install -y curl apt-transport-https gnupg2 python3-pip
     pip3 install requests
     ```
   - Prüfe Checkmk:
     ```bash
     curl http://192.168.30.101:5000/homelab
     sudo omd status homelab
     ```
2. **OPNsense prüfen**:
   - Stelle sicher, dass Syslog und SNMP aktiviert sind (siehe `syslog_snmp_checkmk_homelab_guide.md`):
     - Syslog: Remote-Server `192.168.30.101:514` (UDP).
     - SNMP: Trap-Server `192.168.30.101:162`, Community `public`.
3. **Projektverzeichnis erstellen**:
   ```bash
   mkdir ~/wazuh-siem
   cd ~/wazuh-siem
   ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf OPNsense und TrueNAS.

### Übung 1: Einrichten von Wazuh

**Ziel**: Installiere und konfiguriere Wazuh auf der Ubuntu-VM für zentrale Log-Sammlung.

**Aufgabe**: Richte den Wazuh-Manager ein und füge Ubuntu-VM und OPNsense als Agenten hinzu.

1. **Wazuh-Manager installieren**:
   - Füge das Wazuh-Repository hinzu:
     ```bash
     curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --dearmor -o /usr/share/keyrings/wazuh.gpg
     echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list
     sudo apt update
     ```
   - Installiere Wazuh-Manager, Indexer und Dashboard:
     ```bash
     sudo apt install -y wazuh-manager opendistro-elasticsearch wazuh-dashboard
     ```
   - Starte die Dienste:
     ```bash
     sudo systemctl start wazuh-manager
     sudo systemctl start opendistro-elasticsearch
     sudo systemctl start wazuh-dashboard
     sudo systemctl enable wazuh-manager opendistro-elasticsearch wazuh-dashboard
     ```
   - Teste das Wazuh-Dashboard:
     ```bash
     curl https://192.168.30.101:5601
     ```
     - Öffne das Dashboard: `https://192.168.30.101:5601` (Standard-Benutzer: `admin`, Passwort wird automatisch generiert).

2. **Wazuh-Agent auf Ubuntu-VM installieren**:
   - Installiere den Wazuh-Agent:
     ```bash
     sudo apt install -y wazuh-agent
     ```
   - Konfiguriere den Agent:
     ```bash
     sudo nano /var/ossec/etc/ossec.conf
     ```
     - Ändere die Manager-Adresse:
       ```xml
       <client>
         <server>
           <address>192.168.30.101</address>
         </server>
       </client>
       ```
   - Starte den Agent:
     ```bash
     sudo systemctl start wazuh-agent
     sudo systemctl enable wazuh-agent
     ```

3. **Wazuh-Agent auf OPNsense installieren**:
   - Lade den FreeBSD-Agent herunter:
     ```bash
     ssh root@192.168.30.1
     pkg install -y curl
     curl -o wazuh-agent-4.9.0.pkg https://packages.wazuh.com/4.x/freebsd/wazuh-agent-4.9.0-freebsd-13.pkg
     pkg install -y wazuh-agent-4.9.0.pkg
     ```
   - Konfiguriere den Agent:
     ```bash
     nano /usr/local/etc/ossec.conf
     ```
     - Ändere:
       ```xml
       <client>
         <server>
           <address>192.168.30.101</address>
         </server>
       </client>
       ```
   - Starte den Agent:
     ```bash
     sysrc wazuh_agent_enable=YES
     service wazuh-agent start
     ```
   - Prüfe Agent-Registrierung:
     ```bash
     sudo /var/ossec/bin/manage_agents -l
     ```
     - Erwartete Ausgabe: Agenten `ubuntu-vm` und `opnsense`.

4. **Teste die Verbindung**:
   - Öffne das Wazuh-Dashboard: `https://192.168.30.101:5601`.
   - Gehe zu `Agents` und prüfe, ob `ubuntu-vm` und `opnsense` aktiv sind.

**Erkenntnis**: Wazuh bietet eine leistungsstarke Plattform für SIEM, die Agenten für Log-Sammlung und Bedrohungserkennung unterstützt.

**Quelle**: https://documentation.wazuh.com/current/installation-guide/index.html

### Übung 2: Integration von Syslog und SNMP-Traps in Wazuh

**Ziel**: Konfiguriere Wazuh, um Syslog- und SNMP-Trap-Daten von OPNsense und Ubuntu-VM zu verarbeiten.

**Aufgabe**: Richte Syslog- und SNMP-Empfang ein und analysiere die Daten in Wazuh.

1. **Syslog in Wazuh integrieren**:
   - Stelle sicher, dass Syslog von OPNsense und Ubuntu-VM an `192.168.30.101:514` gesendet wird (siehe `syslog_snmp_checkmk_homelab_guide.md`).
   - Konfiguriere Wazuh für Syslog:
     ```bash
     sudo nano /var/ossec/etc/ossec.conf
     ```
     - Füge hinzu:
       ```xml
       <ossec_config>
         <localfile>
           <log_format>syslog</log_format>
           <location>/var/log/opnsense.log</location>
         </localfile>
         <localfile>
           <log_format>syslog</log_format>
           <location>/var/log/syslog</location>
         </localfile>
       </ossec_config>
       ```
   - Starte Wazuh-Manager neu:
     ```bash
     sudo systemctl restart wazuh-manager
     ```
   - Teste Syslog-Erfassung:
     - Simuliere einen fehlgeschlagenen Login:
       ```bash
       ssh invalid_user@192.168.30.1
       ```
     - Öffne das Wazuh-Dashboard: `https://192.168.30.101:5601`.
     - Gehe zu `Security Events > Events`.
     - Erwartete Ausgabe: Syslog-Ereignisse wie `Failed password`.

2. **SNMP-Traps in Wazuh integrieren**:
   - Stelle sicher, dass SNMP-Traps von OPNsense an `192.168.30.101:162` gesendet werden (siehe `syslog_snmp_checkmk_homelab_guide.md`).
   - Konfiguriere Wazuh für SNMP-Traps:
     ```bash
     sudo nano /var/ossec/etc/ossec.conf
     ```
     - Füge hinzu:
       ```xml
       <ossec_config>
         <localfile>
           <log_format>snmptrap</log_format>
           <location>/var/log/snmp-traps.log</location>
         </localfile>
       </ossec_config>
       ```
   - Starte Wazuh-Manager neu:
     ```bash
     sudo systemctl restart wazuh-manager
     ```
   - Teste SNMP-Traps:
     - Simuliere einen Trap:
       ```bash
       ssh root@192.168.30.1 "reboot"
       ```
     - Prüfe in Wazuh:
       - Gehe zu `Security Events > Events`.
       - Erwartete Ausgabe: Traps wie `SNMPv2-MIB::coldStart`.

3. **Checkmk-Integration für Korrelation**:
   - Aktiviere Wazuh-Events in Checkmk:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Gehe zu `Setup > Services > Manual checks > Syslog`.
     - Host: `ubuntu-vm`.
     - Regel: Muster `.*(wazuh|alert).*`.
     - Speichern und `Discover services`.
   - Prüfe:
     - Gehe zu `Monitor > Event Console`.
     - Erwartete Ausgabe: Wazuh-Alerts wie `Authentication failure`.

**Erkenntnis**: Wazuh integriert Syslog und SNMP-Traps für umfassende Sicherheitsüberwachung und ergänzt Checkmk durch Bedrohungserkennung.

**Quelle**: https://documentation.wazuh.com/current/user-manual/ruleset/syslog.html

### Übung 3: Analyse von Sicherheitsvorfällen und Backup auf TrueNAS

**Ziel**: Analysiere Sicherheitsvorfälle in Wazuh und sichere Daten auf TrueNAS.

**Aufgabe**: Erstelle ein Wazuh-Dashboard für Sicherheitsvorfälle und automatisiere Backups.

1. **Wazuh-Dashboard für Sicherheitsvorfälle erstellen**:
   - Öffne das Wazuh-Dashboard: `https://192.168.30.101:5601`.
   - Gehe zu `Security Events > Dashboards > Create Dashboard`.
   - Füge Visualisierungen hinzu:
     - **Fehlgeschlagene Logins**:
       - Typ: `Metric`.
       - Filter: `rule.description: *failed* OR *denied*`.
       - Aggregation: `Count`.
       - Titel: `Failed Logins`.
     - **SNMP-Traps**:
       - Typ: `Line Chart`.
       - Filter: `data.srcfile: /var/log/snmp-traps.log`.
       - X-Achse: `@timestamp`, Y-Achse: `Count`.
       - Titel: `SNMP Traps Over Time`.
     - **Top-Quellen**:
       - Typ: `Pie Chart`.
       - Filter: `rule.level: >= 5`.
       - Aggregation: `Terms` auf `agent.name`.
       - Titel: `Top Sources of Alerts`.
   - Speichere als `SIEM Dashboard`.

2. **Sicherheitsvorfall analysieren**:
   - Simuliere einen Vorfall:
     ```bash
     for i in {1..6}; do ssh invalid_user@192.168.30.1; sleep 1; done
     ```
   - Prüfe im Wazuh-Dashboard:
     - Gehe zu `SIEM Dashboard`.
     - Erwartete Ausgabe: Anstieg bei `Failed Logins` und Eintrag für `opnsense` in `Top Sources`.

3. **Backup von Wazuh-Daten auf TrueNAS**:
   - Erstelle ein Backup-Skript:
     ```bash
     nano backup_wazuh.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       DATE=$(date +%F)
       BACKUP_DIR=/home/ubuntu/wazuh-siem/backup-$DATE
       mkdir -p $BACKUP_DIR
       # Export Wazuh alerts
       curl -k -u admin:admin "https://192.168.30.101:5601/api/alerts?pretty" > $BACKUP_DIR/wazuh-alerts-$DATE.json
       # Backup Wazuh and Checkmk logs
       cp /var/log/opnsense.log $BACKUP_DIR/
       cp /var/log/snmp-traps.log $BACKUP_DIR/
       sudo cp /omd/sites/homelab/var/log/ec.log $BACKUP_DIR/checkmk-ec.log
       # Transfer to TrueNAS
       rsync -av $BACKUP_DIR root@192.168.30.100:/mnt/tank/backups/wazuh-siem/
       ```
     - Ausführbar machen:
       ```bash
       chmod +x backup_wazuh.sh
       ```
     - Plane einen Cronjob:
       ```bash
       crontab -e
       ```
       - Füge hinzu:
         ```
         0 4 * * * /home/ubuntu/wazuh-siem/backup_wazuh.sh
         ```
       - **Erklärung**: Sichert Wazuh-Alerts und Logs täglich um 04:00 Uhr.

**Erkenntnis**: Wazuh ermöglicht die Analyse von Sicherheitsvorfällen mit visuellen Dashboards und unterstützt Backups für Datenintegrität.

**Quelle**: https://documentation.wazuh.com/current/user-manual/kibana-app/index.html

### Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Aktualisiere die Firewall-Regel in OPNsense, um Zugriff auf `192.168.30.101:514` (Syslog), `192.168.30.101:162` (SNMP-Traps), `192.168.30.101:5000` (Checkmk), und `192.168.30.101:5601` (Wazuh-Dashboard) von `192.168.30.0/24` zu erlauben:
     - Quelle: `192.168.30.0/24`
     - Ziel: `192.168.30.101`
     - Ports: `514,162,5000,5601`
     - Aktion: `Allow`

2. **Monitoring mit Checkmk**:
   - Füge Wazuh-Dienste in Checkmk hinzu:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Gehe zu `Setup > Services > Discover services`.
     - Host: `ubuntu-vm`.
     - Services: `wazuh-manager`, `wazuh-agent`, `opendistro-elasticsearch`, `wazuh-dashboard`.
     - Speichern.
   - Prüfe:
     - Gehe zu `Monitor > All services`.
     - Erwartete Ausgabe: Status `OK` für Wazuh-Dienste.

### Schritt 5: Erweiterung der Übungen
1. **Erweiterte Bedrohungserkennung**:
   - Aktiviere File Integrity Monitoring (FIM) in Wazuh:
     ```bash
     sudo nano /var/ossec/etc/ossec.conf
     ```
     - Füge hinzu:
       ```xml
       <ossec_config>
         <syscheck>
           <directories check_all="yes">/etc,/var/ossec</directories>
         </syscheck>
       </ossec_config>
       ```
     - Starte Wazuh-Manager neu:
       ```bash
       sudo systemctl restart wazuh-manager
       ```
     - Prüfe FIM-Alerts im Wazuh-Dashboard unter `Integrity Monitoring`.

2. **Wazuh-Alerting**:
   - Erstelle einen Alert in Wazuh:
     - Öffne das Wazuh-Dashboard: `https://192.168.30.101:5601`.
     - Gehe zu `Management > Rules > Create Rule`.
     - Regel: `Level >= 7` (hohe Bedrohung), Aktion: Log-Ausgabe.
     - Speichern und teste durch Simulation eines Vorfalls.

## Best Practices für Schüler

- **SIEM-Design**:
  - Nutze Wazuh für Bedrohungserkennung, Checkmk für Systemüberwachung.
  - Modularisiere Log- und Trap-Integrationen.
- **Sicherheit**:
  - Schränke Netzwerkzugriff ein:
    ```bash
    sudo ufw allow from 192.168.30.0/24 to any port 514
    sudo ufw allow from 192.168.30.0/24 to any port 162
    sudo ufw allow from 192.168.30.0/24 to any port 5000
    sudo ufw allow from 192.168.30.0/24 to any port 5601
    ```
  - Sichere SSH-Schlüssel und Wazuh-Credentials:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe Wazuh-Logs:
    ```bash
    sudo tail -f /var/ossec/logs/ossec.log
    ```
  - Prüfe Checkmk-Logs:
    ```bash
    sudo tail -f /omd/sites/homelab/var/log/ec.log
    ```

**Quelle**: https://documentation.wazuh.com, https://docs.checkmk.com

## Empfehlungen für Schüler

- **Setup**: Wazuh, Checkmk, Syslog, SNMP-Traps, TrueNAS-Backups.
- **Workloads**: Sicherheitsüberwachung und Bedrohungserkennung.
- **Integration**: Proxmox (VM), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Erkennung von fehlgeschlagenen Logins und SNMP-Traps.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit grundlegenden Syslog- und SNMP-Integrationen, erweitere zu FIM und Alerting.
- **Übung**: Experimentiere mit weiteren Wazuh-Modulen (z. B. Vulnerability Detection).
- **Fehlerbehebung**: Nutze Wazuh-Dashboard und Checkmk Event Console.
- **Lernressourcen**: https://documentation.wazuh.com, https://docs.checkmk.com, https://docs.opnsense.org.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Erweitertes SIEM mit Wazuh und Checkmk.
- **Skalierbarkeit**: Zentrale Log-Sammlung und Bedrohungserkennung.
- **Lernwert**: Verständnis von SIEM und Sicherheitsüberwachung.

**Nächste Schritte**: Möchtest du eine Anleitung zu Log-Aggregation mit Fluentd, Integration mit Ansible, oder erweiterten Netzwerk-Monitoring?

**Quellen**:
- Wazuh-Dokumentation: https://documentation.wazuh.com
- Checkmk-Dokumentation: https://docs.checkmk.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,,,,
```