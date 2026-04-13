# Lernprojekt: Einrichtung eines zentralen RSyslog-Servers unter Debian (LXC auf Proxmox)

## Einführung

Ein zentraler Log-Server sammelt Systemmeldungen von allen Hosts im Netzwerk an einem Ort. Das erleichtert die Fehleranalyse, erhöht die Übersicht und ist eine Grundvoraussetzung für professionellen Betrieb und Compliance. RSyslog ist der De-facto-Standard-Syslog-Daemon unter Debian – leistungsstark, modular und gut dokumentiert.

In dieser Anleitung richtest du einen RSyslog-Server als LXC-Container auf Proxmox ein, konfigurierst ihn als zentralen Log-Empfänger (UDP und TCP) und strukturierst die eingehenden Logs nach Quell-Host und Facility.

**Voraussetzungen:**
- Proxmox VE läuft unter `https://192.168.30.2:8006`
- OPNsense als Router/DNS unter `192.168.30.1`
- Ubuntu-VM für Ansible unter `192.168.30.101`
- Grundkenntnisse in Linux und SSH
- RSyslog-Server erhält die IP `192.168.30.120` (DNS: `syslog.homelab.local`)

---

## Grundlegende Konzepte

Hier sind die wichtigsten Begriffe rund um RSyslog:

1. **Syslog-Protokoll**:
   - `Facility`: Kategorie der Nachricht (kern, auth, daemon, mail, local0–local7 …)
   - `Severity`: Schweregrad (emerg, alert, crit, err, warning, notice, info, debug)
   - `Message`: Eigentliche Log-Meldung mit Zeitstempel und Hostname
2. **RSyslog-Konfiguration**:
   - `/etc/rsyslog.conf`: Hauptkonfigurationsdatei
   - `/etc/rsyslog.d/*.conf`: Modulare Erweiterungskonfigurationen (werden automatisch eingebunden)
   - `$ModLoad imudp` / `$ModLoad imtcp`: Eingabe-Module für UDP/TCP-Empfang
3. **Log-Speicherung**:
   - `/var/log/`: Standard-Verzeichnis für lokale Logs
   - Template-basierte Pfade: eingehende Logs nach Quell-Host sortieren
   - `logrotate`: automatisches Rotieren und Archivieren älterer Log-Dateien

---

## Vorbereitung: Umgebung prüfen

1. **Proxmox VE prüfen**:
   - Melde dich an der Proxmox-Weboberfläche an: `https://192.168.30.2:8006`.
   - Stelle sicher, dass LXC-Unterstützung aktiviert ist:
     ```bash
     pveam update
     pveam list
     ```
   - Prüfe verfügbare Speicherorte (z. B. `local-lvm` oder `local-zfs`).
2. **DNS-Eintrag in OPNsense anlegen**:
   - Öffne die OPNsense-Weboberfläche: `http://192.168.30.1`.
   - Gehe zu `Services > Unbound DNS > Overrides > Host`.
   - Füge einen neuen Eintrag hinzu:
     - Host: `syslog`
     - Domäne: `homelab.local`
     - IP: `192.168.30.120`
     - Beschreibung: `Zentraler RSyslog-Server`
   - Teste die Auflösung:
     ```bash
     nslookup syslog.homelab.local 192.168.30.1
     ```
     - Erwartete Ausgabe: `192.168.30.120`
3. **Ansible-Umgebung prüfen**:
   - Auf der Ubuntu-VM (`192.168.30.101`):
     ```bash
     ssh ubuntu@192.168.30.101
     ansible --version
     ```
4. **Projektverzeichnis erstellen**:
   - Auf `192.168.30.101`:
     ```bash
     mkdir ~/rsyslog-setup
     cd ~/rsyslog-setup
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Proxmox (`192.168.30.2`), OPNsense (`192.168.30.1`) und TrueNAS (`192.168.30.100`).

---

## Übung 1: LXC-Container erstellen und Debian installieren

**Ziel**: Erstelle einen LXC-Container für den RSyslog-Server und installiere ein schlankes Debian 12.

**Aufgabe**: Lade die Debian-Vorlage herunter, erstelle den Container und richte die Basis-Netzwerkkonfiguration ein.

1. **Debian-Vorlage herunterladen**:
   ```bash
   # Auf dem Proxmox-Host
   pveam download local debian-12-standard_12.7-1_amd64.tar.zst
   ```

2. **LXC-Container erstellen** (Proxmox-Weboberfläche oder CLI):
   ```bash
   # Auf dem Proxmox-Host
   pct create 120 local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst \
     --hostname syslog \
     --memory 512 \
     --cores 1 \
     --rootfs local-lvm:8 \
     --net0 name=eth0,bridge=vmbr0,ip=192.168.30.120/24,gw=192.168.30.1 \
     --nameserver 192.168.30.1 \
     --password <root-passwort> \
     --unprivileged 1 \
     --start 1
   ```

3. **Container starten und SSH-Zugriff prüfen**:
   ```bash
   # Vom Proxmox-Host
   pct start 120
   ssh root@192.168.30.120
   ```

4. **System aktualisieren**:
   ```bash
   apt update && apt upgrade -y
   apt install -y rsyslog curl wget nano
   ```

5. **RSyslog-Version prüfen**:
   ```bash
   rsyslogd -v
   # Erwartete Ausgabe: rsyslogd 8.x.x (git), ...
   ```

**Reflexion**: Warum eignet sich ein LXC-Container mit minimalem Debian für einen Log-Server besser als eine vollständige VM?

---

## Übung 2: RSyslog als zentralen Empfänger konfigurieren

**Ziel**: Konfiguriere RSyslog so, dass er Logs von anderen Hosts über UDP (Port 514) und TCP (Port 514) empfängt und nach Quell-Host sortiert speichert.

**Aufgabe**: Aktiviere die Eingabe-Module, definiere ein Speicher-Template und teste den Empfang.

1. **Bestehende Konfiguration sichern**:
   ```bash
   cp /etc/rsyslog.conf /etc/rsyslog.conf.bak
   ```

2. **Server-Konfiguration anlegen**:
   ```bash
   nano /etc/rsyslog.d/10-server.conf
   ```
   Inhalt:
   ```
   # UDP-Empfang aktivieren
   module(load="imudp")
   input(type="imudp" port="514")

   # TCP-Empfang aktivieren
   module(load="imtcp")
   input(type="imtcp" port="514")

   # Template: Logs nach Quell-Host und Datum sortieren
   template(name="RemoteHostLogs" type="string"
     string="/var/log/remote/%HOSTNAME%/%$YEAR%-%$MONTH%-%$DAY%/%PROGRAMNAME%.log")

   # Alle eingehenden Remote-Logs ins Template schreiben
   if $fromhost-ip != '127.0.0.1' then {
     action(type="omfile" dynaFile="RemoteHostLogs")
     stop
   }
   ```

3. **Log-Verzeichnis anlegen und Rechte setzen**:
   ```bash
   mkdir -p /var/log/remote
   chown syslog:adm /var/log/remote
   chmod 750 /var/log/remote
   ```

4. **RSyslog neu starten und Status prüfen**:
   ```bash
   systemctl restart rsyslog
   systemctl status rsyslog
   ```

5. **Ports prüfen** (UDP und TCP 514 müssen lauschen):
   ```bash
   ss -ulnp | grep 514
   ss -tlnp | grep 514
   ```
   - Erwartete Ausgabe: je eine Zeile mit `0.0.0.0:514` für UDP und TCP.

6. **Firewall-Regeln prüfen** (falls `ufw` aktiv):
   ```bash
   ufw allow 514/udp
   ufw allow 514/tcp
   ufw reload
   ufw status
   ```

**Reflexion**: Was ist der Unterschied zwischen UDP und TCP als Transportprotokoll für Syslog – wann würdest du welches bevorzugen?

---

## Übung 3: Ansible-Playbook für die Serverkonfiguration

**Ziel**: Automatisiere die Einrichtung des RSyslog-Servers mit Ansible, damit sie reproduzierbar und versioniert ist.

**Aufgabe**: Erstelle ein Inventar und ein Playbook, das RSyslog installiert und konfiguriert.

1. **Ansible-Inventar anlegen**:
   ```bash
   # Auf 192.168.30.101
   cd ~/rsyslog-setup
   nano inventory.yml
   ```
   Inhalt:
   ```yaml
   all:
     children:
       syslog_server:
         hosts:
           syslog:
             ansible_host: 192.168.30.120
             ansible_user: root
             ansible_python_interpreter: /usr/bin/python3
   ```

2. **Konfigurationstemplate erstellen**:
   ```bash
   mkdir -p templates
   nano templates/10-server.conf.j2
   ```
   Inhalt:
   ```
   # Managed by Ansible – nicht manuell bearbeiten
   module(load="imudp")
   input(type="imudp" port="{{ rsyslog_port }}")

   module(load="imtcp")
   input(type="imtcp" port="{{ rsyslog_port }}")

   template(name="RemoteHostLogs" type="string"
     string="{{ rsyslog_log_dir }}/%HOSTNAME%/%$YEAR%-%$MONTH%-%$DAY%/%PROGRAMNAME%.log")

   if $fromhost-ip != '127.0.0.1' then {
     action(type="omfile" dynaFile="RemoteHostLogs")
     stop
   }
   ```

3. **Playbook schreiben**:
   ```bash
   nano setup_rsyslog_server.yml
   ```
   Inhalt:
   ```yaml
   ---
   - name: RSyslog-Server einrichten
     hosts: syslog_server
     vars:
       rsyslog_port: 514
       rsyslog_log_dir: /var/log/remote

     tasks:
       - name: System aktualisieren
         apt:
           update_cache: yes
           upgrade: dist

       - name: RSyslog installieren
         apt:
           name: rsyslog
           state: present

       - name: Log-Verzeichnis anlegen
         file:
           path: "{{ rsyslog_log_dir }}"
           state: directory
           owner: syslog
           group: adm
           mode: '0750'

       - name: Server-Konfiguration deployen
         template:
           src: templates/10-server.conf.j2
           dest: /etc/rsyslog.d/10-server.conf
           owner: root
           group: root
           mode: '0644'
         notify: RSyslog neu starten

       - name: RSyslog aktivieren und starten
         systemd:
           name: rsyslog
           enabled: yes
           state: started

     handlers:
       - name: RSyslog neu starten
         systemd:
           name: rsyslog
           state: restarted
   ```

4. **Playbook ausführen**:
   ```bash
   ansible-playbook -i inventory.yml setup_rsyslog_server.yml
   ```

5. **Ergebnis prüfen**:
   ```bash
   ansible syslog -i inventory.yml -m shell -a "systemctl is-active rsyslog && ss -ulnp | grep 514"
   ```

**Reflexion**: Welchen Vorteil bietet ein Ansible-Playbook gegenüber manueller Konfiguration, wenn du denselben Server nach einem Neuaufsetzen wiederherstellen musst?

---

## Tipps für den Erfolg

- Teste den Empfang sofort nach der Konfiguration mit `logger` (siehe Anleitung 02).
- Achte auf korrekte Rechte im Verzeichnis `/var/log/remote/` – RSyslog läuft als Nutzer `syslog`.
- Nutze `journalctl -u rsyslog -f` um Fehler in Echtzeit zu verfolgen, wenn RSyslog nicht startet.
- Verwende TCP statt UDP für wichtige Hosts (z. B. Server) – UDP kann Pakete verlieren.
- Das `dynaFile`-Template erzeugt Unterverzeichnisse automatisch, sobald die erste Nachricht eintrifft.

---

## Fazit

Du hast einen zentralen RSyslog-Server als LXC-Container aufgebaut, der Logs von beliebigen Hosts im Netzwerk empfängt und diese strukturiert nach Quell-Host, Datum und Programm ablegt. Die Konfiguration ist mit Ansible automatisiert und reproduzierbar.

**Nächste Schritte**:
- [02 – RSyslog-Clients konfigurieren](02_rsyslog_clients_konfiguration.md): Debian-Hosts so einrichten, dass sie ihre Logs an den zentralen Server weiterleiten
- [03 – Wartung und Betrieb](03_rsyslog_wartung_und_betrieb.md): Log-Rotation, Monitoring und Archivierung im laufenden Betrieb

**Quellen**:
- RSyslog-Dokumentation: https://www.rsyslog.com/doc/
- Debian RSyslog Wiki: https://wiki.debian.org/rsyslog
- RSyslog RainerScript-Referenz: https://www.rsyslog.com/doc/v8-stable/rainerscript/index.html
