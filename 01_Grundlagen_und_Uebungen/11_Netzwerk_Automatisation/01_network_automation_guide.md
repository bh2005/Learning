# Lernprojekt: Netzwerk-Automatisierung mit Python und Netmiko in einer HomeLab-Umgebung

## Einführung

**Netzwerk-Automatisierung** ermöglicht die programmgesteuerte Konfiguration und Verwaltung von Netzwerkgeräten wie Routern und Switches, um manuelle Aufgaben zu reduzieren und Konsistenz zu gewährleisten. Dieses Lernprojekt zeigt, wie man mit der Python-Bibliothek **Netmiko** Netzwerkgeräte (z. B. OPNsense-Router) in einer HomeLab-Umgebung konfiguriert. Es ist für Lernende mit Grundkenntnissen in Python, Linux und Netzwerkadministration geeignet und nutzt die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense) für Backups und Tests. Das Projekt umfasst drei Übungen: Einrichten der Umgebung und Verbindung zu OPNsense, Automatisierung von Firewall-Regeln, und Backup von Konfigurationen auf TrueNAS. Es ist lokal, kostenlos und datenschutzfreundlich.

**Voraussetzungen**:
- Ubuntu-VM auf Proxmox (IP `192.168.30.101`) mit Python 3 und `pip` installiert.
- OPNsense-Router (IP `192.168.30.1`) mit SSH-Zugriff aktiviert.
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups.
- Grundkenntnisse in Python, SSH und Netzwerkkonfiguration (z. B. Firewall-Regeln).
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`) oder Benutzername/Passwort für OPNsense.
- Netzwerkgerät (z. B. OPNsense oder ein Cisco/HPE-Switch mit SSH).

**Ziele**:
- Einrichten einer Netzwerk-Automatisierungs-Umgebung mit Netmiko.
- Automatisierte Konfiguration von Firewall-Regeln auf OPNsense.
- Backup von Gerätekonfigurationen auf TrueNAS.
- Optional: Monitoring der Konfiguration mit Checkmk (siehe `elk_checkmk_integration_guide.md`, ).

**Hinweis**: Netmiko ist eine Python-Bibliothek, die SSH-basierte Konfigurationen für verschiedene Netzwerkgeräte unterstützt, einschließlich OPNsense (FreeBSD-basiert).

**Quellen**:
- Netmiko-Dokumentation: https://ktbyers.github.io/netmiko
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,,,,

## Lernprojekt: Netzwerk-Automatisierung mit Netmiko

### Vorbereitung: Umgebung einrichten
1. **Ubuntu-VM prüfen**:
   - Verbinde dich mit der VM:
     ```bash
     ssh ubuntu@192.168.30.101
     ```
   - Installiere notwendige Pakete:
     ```bash
     sudo apt update
     sudo apt install -y python3-pip
     pip3 install netmiko
     ```
2. **OPNsense prüfen**:
   - Stelle sicher, dass SSH-Zugriff aktiviert ist:
     - Öffne die OPNsense-Weboberfläche: `http://192.168.30.1`.
     - Gehe zu `System > Settings > Administration`.
     - Aktiviere `Enable Secure Shell` und erlaube `root`-Zugriff.
     - Optional: Füge den öffentlichen SSH-Schlüssel (`~/.ssh/id_rsa.pub`) zu `root` hinzu.
   - Teste die SSH-Verbindung:
     ```bash
     ssh root@192.168.30.1
     ```
     - Passwort: Standard-OPNsense-Passwort oder konfiguriertes Passwort.
3. **Projektverzeichnis erstellen**:
   ```bash
   mkdir ~/network-automation
   cd ~/network-automation
   ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf OPNsense und TrueNAS.

### Übung 1: Einrichten der Netmiko-Umgebung und Verbindung zu OPNsense

**Ziel**: Stelle eine SSH-Verbindung zu OPNsense her und führe grundlegende Befehle aus.

**Aufgabe**: Verbinde dich mit Netmiko zu OPNsense und teste die Konfiguration.

1. **Netmiko-Skript erstellen**:
   - Erstelle `connect_opnsense.py`:
     ```bash
     nano connect_opnsense.py
     ```
     - Inhalt:
       ```python
       from netmiko import ConnectHandler

       # OPNsense device configuration
       device = {
           "device_type": "freebsd",
           "host": "192.168.30.1",
           "username": "root",
           "password": "opnsense",  # Ersetze mit deinem Passwort
       }

       def connect_and_run():
           try:
               # Establish SSH connection
               connection = ConnectHandler(**device)
               print("Connected to OPNsense")

               # Run a command (e.g., show system information)
               output = connection.send_command("uname -a")
               print("System Info:")
               print(output)

               # Disconnect
               connection.disconnect()
               print("Disconnected")
           except Exception as e:
               print(f"Error: {e}")

       if __name__ == "__main__":
           connect_and_run()
       ```
   - **Erklärung**:
     - `device_type: freebsd`: OPNsense ist FreeBSD-basiert.
     - `send_command`: Führt einen Befehl auf dem Gerät aus (z. B. `uname -a`).

2. **Skript testen**:
   - Führe das Skript aus:
     ```bash
     python3 connect_opnsense.py
     ```
     - Erwartete Ausgabe:
       ```
       Connected to OPNsense
       System Info:
       FreeBSD opnsense.localdomain 13.2-RELEASE-p7 FreeBSD 13.2-RELEASE-p7 ...
       Disconnected
       ```

**Erkenntnis**: Netmiko ermöglicht einfache SSH-Verbindungen zu Netzwerkgeräten wie OPNsense für automatisierte Konfigurationen.

**Quelle**: https://ktbyers.github.io/netmiko/docs/netmiko/index.html

### Übung 2: Automatisierung von Firewall-Regeln

**Ziel**: Automatisiere die Erstellung und Verwaltung von Firewall-Regeln auf OPNsense.

**Aufgabe**: Erstelle ein Skript, um eine Firewall-Regel hinzuzufügen und zu prüfen.

1. **Firewall-Regel-Skript erstellen**:
   - Erstelle `configure_firewall.py`:
     ```bash
     nano configure_firewall.py
     ```
     - Inhalt:
       ```python
       from netmiko import ConnectHandler
       import json

       # OPNsense device configuration
       device = {
           "device_type": "freebsd",
           "host": "192.168.30.1",
           "username": "root",
           "password": "opnsense",  # Ersetze mit deinem Passwort
       }

       def add_firewall_rule():
           try:
               connection = ConnectHandler(**device)
               print("Connected to OPNsense")

               # Define firewall rule (allow HTTP from 192.168.30.0/24 to 192.168.30.101)
               rule_commands = [
                   "opnsense-shell",
                   "configctl firewall rule add '{" +
                   '"action":"pass",' +
                   '"interface":"lan",' +
                   '"direction":"in",' +
                   '"protocol":"tcp",' +
                   '"source_net":"192.168.30.0/24",' +
                   '"destination":"192.168.30.101",' +
                   '"destination_port":"80",' +
                   '"description":"Allow HTTP to Ubuntu-VM"' +
                   "}'"
               ]

               # Add firewall rule
               output = connection.send_config_set(rule_commands)
               print("Firewall Rule Output:")
               print(output)

               # Verify rule
               output = connection.send_command("configctl firewall list_rules")
               print("Current Rules:")
               print(output)

               connection.disconnect()
               print("Disconnected")
           except Exception as e:
               print(f"Error: {e}")

       if __name__ == "__main__":
           add_firewall_rule()
       ```
   - **Erklärung**:
     - `opnsense-shell`: Wechselt in die OPNsense-Konfigurations-Shell.
     - `configctl firewall rule add`: Fügt eine Firewall-Regel hinzu (JSON-Format).
     - Regel: Erlaubt TCP/80 von `192.168.30.0/24` zu `192.168.30.101` (Ubuntu-VM).

2. **Skript testen**:
   - Führe das Skript aus:
     ```bash
     python3 configure_firewall.py
     ```
     - Erwartete Ausgabe:
       ```
       Connected to OPNsense
       Firewall Rule Output:
       ...
       Current Rules:
       ... Allow HTTP to Ubuntu-VM ...
       Disconnected
       ```
   - Prüfe in der OPNsense-Weboberfläche:
     - Gehe zu `Firewall > Rules > LAN`.
     - Erwartete Regel: `pass`, Quelle `192.168.30.0/24`, Ziel `192.168.30.101:80`.

**Erkenntnis**: Netmiko ermöglicht die Automatisierung komplexer Konfigurationsaufgaben wie Firewall-Regeln.

**Quelle**: https://docs.opnsense.org/manual/firewall.html

### Übung 3: Backup von Konfigurationen auf TrueNAS

**Ziel**: Automatisiere das Backup der OPNsense-Konfiguration und speichere es auf TrueNAS.

**Aufgabe**: Erstelle ein Skript für Konfigurations-Backups und automatisiere es mit Cron.

1. **Backup-Skript erstellen**:
   - Erstelle `backup_opnsense.py`:
     ```bash
     nano backup_opnsense.py
     ```
     - Inhalt:
       ```python
       from netmiko import ConnectHandler
       import os
       from datetime import datetime

       # OPNsense device configuration
       device = {
           "device_type": "freebsd",
           "host": "192.168.30.1",
           "username": "root",
           "password": "opnsense",  # Ersetze mit deinem Passwort
       }

       def backup_config():
           try:
               connection = ConnectHandler(**device)
               print("Connected to OPNsense")

               # Backup configuration
               output = connection.send_command("opnsense-backup")
               timestamp = datetime.now().strftime("%Y-%m-%d")
               backup_file = f"/home/ubuntu/network-automation/opnsense-backup-{timestamp}.xml"

               # Save backup to file
               with open(backup_file, "w") as f:
                   f.write(output)
               print(f"Backup saved to {backup_file}")

               # Transfer to TrueNAS
               os.system(f"rsync -av {backup_file} root@192.168.30.100:/mnt/tank/backups/network-automation/")
               print("Backup transferred to TrueNAS")

               connection.disconnect()
               print("Disconnected")
           except Exception as e:
               print(f"Error: {e}")

       if __name__ == "__main__":
           backup_config()
       ```
   - **Erklärung**:
     - `opnsense-backup`: Erstellt ein XML-Backup der OPNsense-Konfiguration.
     - `rsync`: Überträgt das Backup an TrueNAS.

2. **Skript testen**:
   - Führe das Skript aus:
     ```bash
     python3 backup_opnsense.py
     ```
     - Erwartete Ausgabe:
       ```
       Connected to OPNsense
       Backup saved to /home/ubuntu/network-automation/opnsense-backup-<date>.xml
       Backup transferred to TrueNAS
       Disconnected
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/network-automation/
     ```
     - Erwartete Ausgabe: `opnsense-backup-<date>.xml`.

3. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/network-automation
       python3 backup_opnsense.py >> backup.log 2>&1
       ```
     - Ausführbar machen:
       ```bash
       chmod +x run_backup.sh
       ```
   - Plane einen Cronjob:
     ```bash
     crontab -e
     ```
     - Füge hinzu:
       ```
       0 3 * * * /home/ubuntu/network-automation/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Automatisierte Backups mit Netmiko und TrueNAS sichern Netzwerkkonfigurationen zuverlässig.

**Quelle**: https://docs.opnsense.org/manual/backup.html

### Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass SSH-Zugriff erlaubt ist:
     - Quelle: `192.168.30.0/24`
     - Ziel: `192.168.30.1`
     - Port: `22`
     - Aktion: `Allow`
   - Prüfe bestehende Firewall-Regeln:
     ```bash
     ssh root@192.168.30.1 "configctl firewall list_rules"
     ```

2. **Monitoring mit Checkmk (optional)**:
   - Konfiguriere Checkmk für OPNsense:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Füge OPNsense als Host hinzu:
       - Gehe zu `Setup > Hosts > Add host`.
       - Hostname: `opnsense`, IP: `192.168.30.1`.
       - Speichern und `Discover services`.
     - Prüfe:
       - Gehe zu `Monitor > All services`.
       - Erwartete Ausgabe: Services wie `CPU load`, `Memory`.

### Schritt 5: Erweiterung der Übungen
1. **Erweiterte Konfiguration**:
   - Erstelle ein Skript für VLAN-Konfiguration:
     ```python
     vlan_commands = [
         "opnsense-shell",
         "configctl interface vlan create '{" +
         '"interface":"lan",' +
         '"vlan_id":"10",' +
         '"description":"VLAN10"' +
         "}'"
     ]
     output = connection.send_config_set(vlan_commands)
     ```
   - Teste mit `configctl interface list`.

2. **Validierung von Konfigurationen**:
   - Erstelle ein Skript zur Prüfung von Firewall-Regeln:
     ```python
     output = connection.send_command("configctl firewall list_rules | grep 'Allow HTTP'")
     if "Allow HTTP" in output:
         print("Firewall rule verified")
     else:
         print("Firewall rule not found")
     ```

## Best Practices für Schüler

- **Automatisierungs-Design**:
  - Modularisiere Skripte (z. B. separate Funktionen für Verbindung, Konfiguration, Backup).
  - Verwende sichere Credentials (z. B. SSH-Schlüssel statt Passwörter).
- **Sicherheit**:
  - Schränke SSH-Zugriff ein:
    ```bash
    sudo ufw allow from 192.168.30.0/24 to any port 22
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe Netmiko-Logs:
    ```bash
    cat ~/network-automation/backup.log
    ```
  - Prüfe OPNsense-Logs:
    ```bash
    ssh root@192.168.30.1 "cat /var/log/system/latest.log"
    ```

**Quelle**: https://ktbyers.github.io/netmiko, https://docs.opnsense.org

## Empfehlungen für Schüler

- **Setup**: Netmiko, OPNsense, TrueNAS-Backups.
- **Workloads**: Automatisierte Firewall-Regeln und Konfigurations-Backups.
- **Integration**: Proxmox (VM), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Firewall-Regel für HTTP-Zugriff.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einfachen Befehlen, erweitere zu komplexeren Konfigurationen.
- **Übung**: Experimentiere mit VLANs oder NAT-Regeln.
- **Fehlerbehebung**: Nutze `backup.log` und OPNsense-Logs.
- **Lernressourcen**: https://ktbyers.github.io/netmiko, https://docs.opnsense.org.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Netzwerk-Automatisierung mit Netmiko und OPNsense.
- **Skalierbarkeit**: Automatisierte Konfigurationen und Backups.
- **Lernwert**: Verständnis von Netzwerk-Automatisierung in einer HomeLab.

**Nächste Schritte**: Möchtest du eine Anleitung zu Log-Aggregation mit Fluentd, Integration mit Ansible, oder erweiterten Netzwerk-Monitoring mit Checkmk?

**Quellen**:
- Netmiko-Dokumentation: https://ktbyers.github.io/netmiko
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,,,,
```