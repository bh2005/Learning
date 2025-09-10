# Lernprojekt: Syslog und SNMP-Traps im HomeLab mit Checkmk

## Einführung

**Syslog** und **SNMP-Traps** sind zentrale Mechanismen zur Überwachung und Protokollierung von Ereignissen in Netzwerkumgebungen. Syslog ermöglicht die zentrale Sammlung von Log-Nachrichten, während SNMP-Traps Ereignismeldungen von Netzwerkgeräten wie Routern und Switches liefern. Dieses Lernprojekt zeigt, wie man Syslog und SNMP-Traps in einer HomeLab-Umgebung mit **Checkmk Raw Edition** konfiguriert, um Geräte wie den OPNsense-Router zu überwachen. Es baut auf `siem_introduction_guide.md` () und `network_automation_guide.md` () auf und nutzt die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense) für Backups. Das Projekt ist für Lernende mit Grundkenntnissen in Linux, Netzwerkadministration und Checkmk geeignet und ist lokal, kostenlos und datenschutzfreundlich. Es umfasst drei Übungen: Einrichten von Syslog auf OPNsense und Ubuntu-VM, Konfiguration von SNMP-Traps, und Analyse sowie Backup der Daten mit Checkmk und TrueNAS.

**Voraussetzungen**:
- Ubuntu-VM auf Proxmox (IP `192.168.30.101`) mit Checkmk Raw Edition (Site `homelab`) installiert (siehe `siem_introduction_guide.md`).
- OPNsense-Router (IP `192.168.30.1`) mit Syslog und SNMP aktiviert.
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups.
- Grundkenntnisse in Linux, Syslog, SNMP und Checkmk.
- `python3`, `pip`, `rsyslog`, und `snmptrapd` installiert auf der Ubuntu-VM.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`).

**Ziele**:
- Einrichten von Syslog auf OPNsense und Ubuntu-VM für zentrale Log-Sammlung in Checkmk.
- Konfiguration von SNMP-Traps für OPNsense und Integration in Checkmk.
- Analyse von Syslog- und SNMP-Daten in Checkmk und Backup auf TrueNAS.

**Hinweis**: Checkmk bietet integrierte Unterstützung für Syslog und SNMP-Traps, um Ereignisse in einer HomeLab-Umgebung zu überwachen.

**Quellen**:
- Checkmk-Dokumentation: https://docs.checkmk.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Syslog-Dokumentation: https://www.rsyslog.com/doc
- SNMP-Dokumentation: https://www.net-snmp.org/docs
- Webquellen:,,,,,

## Lernprojekt: Syslog und SNMP-Traps mit Checkmk

### Vorbereitung: Umgebung einrichten
1. **Ubuntu-VM prüfen**:
   - Verbinde dich mit der VM:
     ```bash
     ssh ubuntu@192.168.30.101
     ```
   - Installiere notwendige Pakete:
     ```bash
     sudo apt update
     sudo apt install -y rsyslog snmp snmptrapd python3-pip
     pip3 install requests
     ```
   - Prüfe Checkmk:
     ```bash
     curl http://192.168.30.101:5000/homelab
     sudo omd status homelab
     ```
2. **OPNsense prüfen**:
   - Stelle sicher, dass SSH-Zugriff aktiviert ist:
     - Öffne die OPNsense-Weboberfläche: `http://192.168.30.1`.
     - Gehe zu `System > Settings > Administration`.
     - Aktiviere `Enable Secure Shell` und erlaube `root`-Zugriff.
   - Teste SSH:
     ```bash
     ssh root@192.168.30.1
     ```
3. **Projektverzeichnis erstellen**:
   ```bash
   mkdir ~/syslog-snmp-checkmk
   cd ~/syslog-snmp-checkmk
   ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf OPNsense und TrueNAS.

### Übung 1: Einrichten von Syslog für OPNsense und Ubuntu-VM

**Ziel**: Konfiguriere Syslog auf OPNsense und Ubuntu-VM und integriere es in Checkmk.

**Aufgabe**: Sende Syslog-Nachrichten an die Ubuntu-VM und überwache sie mit Checkmk.

1. **Syslog auf OPNsense aktivieren**:
   - Öffne die OPNsense-Weboberfläche: `http://192.168.30.1`.
   - Gehe zu `System > Settings > Logging / Targets`.
   - Füge einen Remote-Syslog-Server hinzu:
     - Host: `192.168.30.101`
     - Port: `514`
     - Protokoll: `UDP`
     - Anwendungen: `Firewall`, `System`, `Webserver`
     - Speichern und anwenden.
   - Teste Syslog:
     - Simuliere einen Firewall-Log:
       ```bash
       ssh invalid_user@192.168.30.1
       ```

2. **Syslog auf Ubuntu-VM konfigurieren**:
   - Konfiguriere `rsyslog`:
     ```bash
     sudo nano /etc/rsyslog.conf
     ```
     - Stelle sicher, dass folgende Zeilen entkommentiert sind:
       ```
       module(load="imudp")
       input(type="imudp" port="514")
       ```
   - Erstelle eine Regel für eingehende Logs:
     ```bash
     sudo nano /etc/rsyslog.d/opnsense.conf
     ```
     - Inhalt:
       ```
       :fromhost-ip, isequal, "192.168.30.1" /var/log/opnsense.log
       & stop
       ```
   - Starte rsyslog neu:
     ```bash
     sudo systemctl restart rsyslog
     ```
   - Prüfe Logs:
     ```bash
     sudo tail -f /var/log/opnsense.log
     ```
     - Erwartete Ausgabe: Logs wie `pf: block` oder `sshd: Failed password`.

3. **Checkmk für Syslog konfigurieren**:
   - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
   - Füge Syslog-Überwachung hinzu:
     - Gehe zu `Setup > Services > Manual checks > Syslog`.
     - Host: `opnsense` (IP: `192.168.30.1`).
     - Regel: `Syslog messages`, Muster: `.*(failed|denied|error).*`.
     - Speichern und `Discover services`.
   - Prüfe:
     - Gehe zu `Monitor > All services > Syslog`.
     - Erwartete Ausgabe: Syslog-Ereignisse wie `Failed password`.

**Erkenntnis**: Syslog ermöglicht die zentrale Sammlung von Logs, die in Checkmk für Sicherheits- und Systemüberwachung analysiert werden können.

**Quelle**: https://docs.checkmk.com/latest/en/monitoring_syslog.html, https://docs.opnsense.org/manual/logging.html

### Übung 2: Konfiguration von SNMP-Traps für OPNsense

**Ziel**: Konfiguriere SNMP-Traps auf OPNsense und integriere sie in Checkmk.

**Aufgabe**: Sende SNMP-Traps von OPNsense an die Ubuntu-VM und überwache sie in Checkmk.

1. **SNMP auf OPNsense aktivieren**:
   - Öffne die OPNsense-Weboberfläche: `http://192.168.30.1`.
   - Gehe zu `Services > SNMP > General`.
   - Aktiviere SNMP:
     - Community: `public`
     - Traps: Aktiviere `Enable Traps`.
     - Trap Server: `192.168.30.101`, Port: `162`, Version: `v2c`.
     - Speichern und anwenden.
   - Teste SNMP:
     ```bash
     snmpwalk -v2c -c public 192.168.30.1 sysName
     ```
     - Erwartete Ausgabe: `sysName.0 = STRING: opnsense.localdomain`.

2. **SNMP-Traps auf Ubuntu-VM konfigurieren**:
   - Konfiguriere `snmptrapd`:
     ```bash
     sudo nano /etc/snmp/snmptrapd.conf
     ```
     - Inhalt:
       ```
       authCommunity log,execute,net public
       traphandle default /usr/bin/perl /usr/local/bin/traptofile
       ```
   - Erstelle ein Skript für Traps:
     ```bash
     sudo nano /usr/local/bin/traptofile
     ```
     - Inhalt:
       ```perl
       #!/usr/bin/perl
       use strict;
       use warnings;
       my $logfile = "/var/log/snmp-traps.log";
       open(my $fh, ">>", $logfile) or die "Cannot open $logfile: $!";
       while (<STDIN>) {
           print $fh scalar localtime . ": $_";
       }
       close $fh;
       ```
     - Ausführbar machen:
       ```bash
       sudo chmod +x /usr/local/bin/traptofile
       ```
   - Starte snmptrapd:
     ```bash
     sudo systemctl start snmptrapd
     sudo systemctl enable snmptrapd
     ```
   - Teste Traps:
     - Simuliere einen Trap auf OPNsense (z. B. durch Neustart):
       ```bash
       ssh root@192.168.30.1 "reboot"
       ```
     - Prüfe Logs:
       ```bash
       sudo tail -f /var/log/snmp-traps.log
       ```
       - Erwartete Ausgabe: Traps wie `SNMPv2-MIB::coldStart`.

3. **Checkmk für SNMP-Traps konfigurieren**:
   - Aktiviere SNMP-Trap-Integration in Checkmk:
     - Gehe zu `Setup > Agents > Rules > SNMP traps`.
     - Regel: `Process SNMP traps`, Ziel: `192.168.30.101:162`, Community: `public`.
     - Speichern.
   - Füge OPNsense für Traps hinzu:
     - Gehe zu `Setup > Services > Manual checks > SNMP Traps`.
     - Host: `opnsense`.
     - Muster: `.*coldStart.*|.*authenticationFailure.*`.
     - Speichern und `Discover services`.
   - Prüfe:
     - Gehe zu `Monitor > Event Console`.
     - Erwartete Ausgabe: Trap-Ereignisse wie `coldStart`.

**Erkenntnis**: SNMP-Traps ergänzen Syslog durch ereignisgesteuerte Meldungen, die in Checkmk korreliert werden können.

**Quelle**: https://docs.checkmk.com/latest/en/snmp.html, https://www.net-snmp.org/docs

### Übung 3: Analyse und Backup von Syslog- und SNMP-Daten

**Ziel**: Analysiere Syslog- und SNMP-Daten in Checkmk und sichere sie auf TrueNAS.

**Aufgabe**: Erstelle Regeln für Sicherheitsvorfälle und automatisiere Backups.

1. **Sicherheitsvorfälle in Checkmk analysieren**:
   - Erstelle eine Korrelationsregel:
     - Gehe zu `Setup > Events > Event Console > Rule Packs > Add rule pack`.
     - Name: `Security Traps`.
     - Regel:
       - Bedingung: `Text to match`: `failed|denied|authenticationFailure|coldStart`.
       - Aktion: `Set state to WARNING`.
     - Speichern.
   - Teste:
     - Simuliere einen fehlgeschlagenen SNMP-Zugriff:
       ```bash
       snmpwalk -v2c -c wrongcommunity 192.168.30.1 sysName
       ```
     - Prüfe in Checkmk:
       - Gehe zu `Monitor > Event Console`.
       - Erwartete Ausgabe: Event wie `authenticationFailure` mit Status `WARNING`.

2. **Backup von Logs auf TrueNAS**:
   - Erstelle ein Backup-Skript:
     ```bash
     nano backup_logs.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       DATE=$(date +%F)
       BACKUP_DIR=/home/ubuntu/syslog-snmp-checkmk/backup-$DATE
       mkdir -p $BACKUP_DIR
       # Backup Syslog and SNMP logs
       cp /var/log/opnsense.log $BACKUP_DIR/
       cp /var/log/snmp-traps.log $BACKUP_DIR/
       # Backup Checkmk event logs
       sudo cp /omd/sites/homelab/var/log/ec.log $BACKUP_DIR/checkmk-ec.log
       # Transfer to TrueNAS
       rsync -av $BACKUP_DIR root@192.168.30.100:/mnt/tank/backups/syslog-snmp-checkmk/
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
         0 4 * * * /home/ubuntu/syslog-snmp-checkmk/backup_logs.sh
         ```
       - **Erklärung**: Sichert Logs täglich um 04:00 Uhr.

3. **Analyse in Checkmk**:
   - Erstelle ein Dashboard:
     - Gehe zu `Views > Create View`.
     - Datenquelle: `Event Console`.
     - Filter: `State = WARNING OR CRITICAL`.
     - Titel: `Security Events Dashboard`.
     - Speichern.
   - Prüfe:
     - Gehe zu `Views > Security Events Dashboard`.
     - Erwartete Ausgabe: Ereignisse wie `failed login` oder `authenticationFailure`.

**Erkenntnis**: Checkmk ermöglicht die Analyse und Korrelation von Syslog- und SNMP-Daten für eine effektive Überwachung.

**Quelle**: https://docs.checkmk.com/latest/en/event_console.html

### Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Aktualisiere die Firewall-Regel in OPNsense, um Zugriff auf `192.168.30.101:514` (Syslog), `192.168.30.101:162` (SNMP-Traps), und `192.168.30.101:5000` (Checkmk) von `192.168.30.0/24` zu erlauben:
     - Quelle: `192.168.30.0/24`
     - Ziel: `192.168.30.101`
     - Ports: `514,162,5000`
     - Aktion: `Allow`

2. **Monitoring mit Checkmk**:
   - Prüfe bestehende Hosts:
     - Gehe zu `Setup > Hosts`.
     - Stelle sicher, dass `opnsense` (IP: `192.168.30.1`) und `ubuntu-vm` (IP: `192.168.30.101`) überwacht werden.
   - Prüfe Services:
     - Gehe zu `Monitor > All services`.
     - Erwartete Ausgabe: `Syslog`, `SNMP Traps`.

### Schritt 5: Erweiterung der Übungen
1. **Erweiterte Korrelation**:
   - Erstelle eine komplexere Regel in Checkmk:
     - Gehe zu `Setup > Events > Event Console > Rule Packs`.
     - Regel: Kombiniere `authenticationFailure` mit `source IP` für Brute-Force-Erkennung.
     - Bedingung: `Text to match`: `authenticationFailure`, `Count > 5 in 5 minutes`.

2. **Erweiterte SNMP-Traps**:
   - Konfiguriere zusätzliche Traps in OPNsense:
     - Gehe zu `Services > SNMP > Traps`.
     - Aktiviere Traps für `Interface Status` oder `CPU Load`.
   - Prüfe in Checkmk:
     - Gehe zu `Monitor > Event Console`.
     - Erwartete Ausgabe: Traps wie `linkDown`.

## Best Practices für Schüler

- **Syslog/SNMP-Design**:
  - Zentralisiere Logs mit Syslog und Traps mit SNMP in Checkmk.
  - Nutze einfache Muster für den Einstieg (z. B. `failed`, `authenticationFailure`).
- **Sicherheit**:
  - Schränke Netzwerkzugriff ein:
    ```bash
    sudo ufw allow from 192.168.30.0/24 to any port 514
    sudo ufw allow from 192.168.30.0/24 to any port 162
    sudo ufw allow from 192.168.30.0/24 to any port 5000
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe Syslog:
    ```bash
    sudo tail -f /var/log/opnsense.log
    ```
  - Prüfe SNMP-Traps:
    ```bash
    sudo tail -f /var/log/snmp-traps.log
    ```
  - Prüfe Checkmk-Logs:
    ```bash
    sudo tail -f /omd/sites/homelab/var/log/ec.log
    ```

**Quelle**: https://docs.checkmk.com, https://docs.opnsense.org, https://www.net-snmp.org

## Empfehlungen für Schüler

- **Setup**: Syslog, SNMP-Traps, Checkmk, TrueNAS-Backups.
- **Workloads**: Log-Sammlung und Ereignisüberwachung.
- **Integration**: Proxmox (VM), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Überwachung von Firewall-Logs und SNMP-Traps.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit grundlegenden Syslog- und SNMP-Regeln, erweitere zu komplexeren Korrelationen.
- **Übung**: Experimentiere mit weiteren SNMP-Traps (z. B. Interface-Events).
- **Fehlerbehebung**: Nutze Checkmk Event Console und Log-Dateien.
- **Lernressourcen**: https://docs.checkmk.com, https://docs.opnsense.org, https://www.net-snmp.org.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Syslog- und SNMP-Integration mit Checkmk.
- **Skalierbarkeit**: Zentrale Log- und Trap-Überwachung.
- **Lernwert**: Verständnis von Syslog und SNMP in einer HomeLab.

**Nächste Schritte**: Möchtest du eine Anleitung zu Integration mit Wazuh für erweitertes SIEM, Log-Aggregation mit Fluentd, oder erweiterten Netzwerk-Monitoring?

**Quellen**:
- Checkmk-Dokumentation: https://docs.checkmk.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Syslog-Dokumentation: https://www.rsyslog.com/doc
- SNMP-Dokumentation: https://www.net-snmp.org/docs
- Webquellen:,,,,,
```