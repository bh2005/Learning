# Anleitung: Konfiguration von IDS/IPS mit Suricata auf OPNsense im HomeLab

## Einführung

**Suricata** ist ein leistungsstarkes Open-Source-IDS/IPS (Intrusion Detection and Prevention System), das in OPNsense integriert werden kann, um Netzwerkverkehr auf verdächtige Aktivitäten zu überwachen und Bedrohungen zu blockieren. Im Kontext eines HomeLabs mit Proxmox VE 9.0 und TrueNAS CORE 13.0 schützt Suricata kritische Dienste (z. B. Proxmox-Management, TrueNAS NFS) durch Erkennung und Prävention von Angriffen wie Malware, Brute-Force oder Exploits. Diese Anleitung beschreibt die Installation des Suricata-Plugins auf einer OPNsense-VM (Version 24.7 oder neuer), die Konfiguration von IDS (Erkennung) und IPS (Prävention) für VLANs (VMs, Management, Storage, Gäste), die Optimierung von Regeln und die Integration mit der bestehenden HomeLab-Infrastruktur. Sie ist auf die Netzwerkstruktur aus der vorherigen Anleitung (`opnsense_homelab_installation_guide.md`) abgestimmt.

**Voraussetzungen**:
- OPNsense 24.7 (oder neuer) als VM auf Proxmox VE 9.0, mit mindestens 2 GB RAM (4 GB empfohlen) und 2 Kernen.
- Netzwerkkonfiguration mit VLANs:
  - VLAN 10: VMs (`192.168.10.0/24`).
  - VLAN 20: Management (Proxmox: `192.168.20.10`, TrueNAS: `192.168.20.100`, OPNsense: `192.168.20.1`).
  - VLAN 30: Storage (TrueNAS: `192.168.30.100`).
  - VLAN 40: Gäste/IoT (`192.168.40.0/24`).
- Managed Switch mit VLAN-Unterstützung (z. B. TP-Link TL-SG108E).
- Zugriff auf die OPNsense-Weboberfläche (`https://192.168.20.1`).
- Grundkenntnisse in Netzwerkprotokollen, Firewall-Regeln und Suricata.

**Hinweis**: IDS (Intrusion Detection System) erkennt und protokolliert verdächtige Aktivitäten, während IPS (Intrusion Prevention System) aktiv eingreift und Bedrohungen blockiert. Suricata kann beide Modi unterstützen, benötigt jedoch ausreichend CPU- und RAM-Ressourcen für die Paketanalyse.

**Quellen**:
- OPNsense-Dokumentation: https://docs.opnsense.org/manual/ips.html
- Suricata-Dokumentation: https://suricata.readthedocs.io/
- Webquellen:,,,,,,,,,,,,,,

## Voraussetzungen und Planung

### Netzwerkübersicht
- **WAN**: Verbunden mit dem Router (z. B. `192.168.1.1`).
- **LAN**:
  - VLAN 10 (VMs): `192.168.10.1/24` (DHCP für VMs/LXC).
  - VLAN 20 (Management): `192.168.20.1/24` (Proxmox, TrueNAS, OPNsense).
  - VLAN 30 (Storage): `192.168.30.1/24` (TrueNAS NFS).
  - VLAN 40 (Guests): `192.168.40.1/24` (IoT, Gäste).
- **Ziel**: Suricata überwacht und schützt:
  - VLAN 10: Schutz vor Exploit-Versuchen in VMs/LXC (z. B. Pi-hole, Nextcloud).
  - VLAN 20: Schutz von Management-Zugriffen (Proxmox: `8006`, TrueNAS: `80/443`).
  - VLAN 30: Schutz des NFS-Traffics (Port `2049`).
  - VLAN 40: Erkennung von verdächtigen IoT-/Gäste-Aktivitäten.

### Hardwareanforderungen für Suricata
- **CPU**: 2–4 Kerne (VirtIO in Proxmox, z. B. `host`).
- **RAM**: 4 GB (für Suricata-Logs und Regelsätze, 2 GB Minimum).
- **Speicher**: 20 GB (für Logs, `qcow2` auf NFS oder ZFS).
- **Netzwerk**: VirtIO-NICs für WAN und LAN (VLANs 10, 20, 30, 40).

**Tipp**: Erhöhe die CPU-Zuweisung (z. B. 4 Kerne) bei intensiver Nutzung von IPS (Inline-Blocking).

## Installation von Suricata

### Schritt 1: Suricata-Plugin installieren
1. **Zugriff auf OPNsense-Weboberfläche**:
   - Öffne `https://192.168.20.1` und melde dich als `root` an.
2. **Plugin installieren**:
   - Gehe zu `System > Firmware > Plugins`.
   - Suche nach `os-suricata` und klicke auf `+` (Installieren).
   - Warte, bis die Installation abgeschlossen ist (ca. 1–2 Minuten).
3. **Prüfen**:
   - Navigiere zu `Services > Intrusion Detection`.
   - Stelle sicher, dass Suricata aktiviert ist (`Enable` angehakt).

**Quelle**: https://docs.opnsense.org/manual/ips.html#installation

### Schritt 2: Suricata-Regeln herunterladen
1. **Regelquellen konfigurieren**:
   - Gehe zu `Services > Intrusion Detection > Administration > Download`.
   - Aktiviere folgende Regelsätze (kostenlos, für HomeLabs geeignet):
     - **Emerging Threats Open**: Grundlegender Schutz gegen Malware, Exploits.
     - **ET Open (Optimized)**: Optimiert für Performance.
     - Optional: **Snort VRT** (erfordert kostenlosen Oinkcode von https://www.snort.org/).
   - Klicke auf `Download & Update Rules`.
2. **Regeln prüfen**:
   - Gehe zu `Services > Intrusion Detection > Administration > Global Settings`.
   - Stelle sicher, dass „Enable automatic rules update“ aktiviert ist (täglicher Update).
3. **CLI-Alternative** (falls nötig):
   ```bash
   opnsense-update -p suricata
   ```

**Tipp**: Starte mit Emerging Threats Open, da es für HomeLabs ausreichend ist und keine Registrierung erfordert.

**Quelle**: https://docs.opnsense.org/manual/ips.html#rulesets

## Konfiguration von IDS

### Schritt 1: IDS aktivieren
1. **Globale Einstellungen**:
   - Gehe zu `Services > Intrusion Detection > Settings > General`.
   - Aktiviere „Enable Intrusion Detection“.
   - Modus: `IDS` (für Erkennung ohne Blocking).
   - Log-Level: `Medium` (für ausreichende Details ohne Überlastung).
2. **Schnittstellen zuweisen**:
   - Gehe zu `Services > Intrusion Detection > Settings > Interfaces`.
   - Füge Schnittstellen hinzu:
     - `WAN` (vtnet0): Überwachung externer Bedrohungen.
     - `VMs` (vlan0, VLAN 10): Schutz für VMs/LXC.
     - `Management` (vlan1, VLAN 20): Schutz für Proxmox/TrueNAS.
     - `Storage` (vlan2, VLAN 30): Schutz für NFS-Traffic.
     - `Guests` (vlan3, VLAN 40): Überwachung von IoT/Gästen.
   - Aktiviere „Enable“ für jede Schnittstelle, Modus: `IDS`.
3. **Regeln anpassen**:
   - Gehe zu `Services > Intrusion Detection > Policy`.
   - Wähle Regeln aus (z. B. `emerging-malware.rules`, `emerging-exploit.rules`).
   - Setze Aktion auf `Alert` für IDS-Modus.
4. **Testen**:
   - Simuliere einen Angriff (z. B. `nmap -sS 192.168.10.102` auf einem Client in VLAN 40).
   - Prüfe Logs: `Services > Intrusion Detection > Alerts`.
     - Beispiel: Erkennung eines Port-Scans.

**Tipp**: Reduziere die Anzahl aktiver Regeln (z. B. nur `emerging-malware`, `emerging-exploit`), um CPU-Last zu minimieren.

### Schritt 2: Benachrichtigungen einrichten
1. **Syslog aktivieren**:
   - Gehe zu `System > Settings > Logging / Targets`.
   - Füge einen Remote-Syslog-Server hinzu (z. B. Proxmox-Host oder TrueNAS, `192.168.20.10:514`).
   - Aktiviere `Intrusion Detection` als Quelle.
2. **E-Mail-Benachrichtigungen** (optional):
   - Gehe zu `System > Settings > Notifications`.
   - Konfiguriere einen SMTP-Server (z. B. Gmail).
   - Aktiviere Benachrichtigungen für „Intrusion Detection Alerts“.

**Quelle**: https://docs.opnsense.org/manual/logging.html

## Konfiguration von IPS

### Schritt 1: IPS aktivieren
1. **Modus ändern**:
   - Gehe zu `Services > Intrusion Detection > Settings > General`.
   - Aktiviere „Enable Intrusion Prevention“.
   - Stelle sicher, dass „Enable Intrusion Detection“ ebenfalls aktiviert ist.
2. **Schnittstellen anpassen**:
   - Gehe zu `Services > Intrusion Detection > Settings > Interfaces`.
   - Ändere den Modus für `VMs`, `Management`, `Storage` und `Guests` auf `IPS`.
   - Behalte `WAN` auf `IDS` (IPS auf WAN kann legitimen Traffic blockieren).
3. **Regeln für IPS**:
   - Gehe zu `Services > Intrusion Detection > Policy`.
   - Wähle kritische Regeln (z. B. `emerging-exploit.rules`, `emerging-malware.rules`).
   - Setze Aktion auf `Drop` für IPS (blockiert verdächtigen Traffic).
4. **Netmap aktivieren** (für bessere Performance):
   - Gehe zu `Services > Intrusion Detection > Settings > Advanced`.
   - Aktiviere „Use netmap“ (erfordert VirtIO-NICs).
   - Setze „IPS mode“ auf `Inline`.
5. **Testen**:
   - Simuliere einen Exploit (z. B. mit `metasploit` oder einem Test-Tool wie `hping3`):
     ```bash
     hping3 -S -p 80 --flood 192.168.10.102
     ```
   - Prüfe Logs (`Services > Intrusion Detection > Alerts`) und blockierten Traffic (`Services > Intrusion Detection > Blocks`).

**Tipp**: IPS kann die Netzwerkleistung beeinträchtigen. Teste zunächst mit wenigen Regeln und überprüfe die CPU-Auslastung:
```bash
top -P
```

**Quelle**: https://docs.opnsense.org/manual/ips.html#ips-mode

### Schritt 2: HomeLab-spezifische Regeln
1. **Schutz für Proxmox-Management (VLAN 20)**:
   - Erstelle eine Regel für Port `8006` (Proxmox-Weboberfläche):
     - Gehe zu `Services > Intrusion Detection > Policy`.
     - Filter: `http`, Aktion: `Drop`, Ziel: `192.168.20.10:8006`.
   - Erlaube legitimen Traffic explizit:
     - Gehe zu `Firewall > Rules > Management`.
     - Regel: Aktion: `Pass`, Quelle: `192.168.20.0/24`, Ziel: `192.168.20.10`, Port: `8006`.
2. **Schutz für TrueNAS NFS (VLAN 30)**:
   - Regel für NFS-Port `2049`:
     - Filter: `nfs`, Aktion: `Drop`, Ziel: `192.168.30.100:2049`.
   - Firewall-Regel:
     - Gehe zu `Firewall > Rules > Storage`.
     - Regel: Aktion: `Pass`, Quelle: `192.168.30.10` (Proxmox), Ziel: `192.168.30.100`, Port: `2049`.
3. **Schutz für Gäste (VLAN 40)**:
   - Aktiviere `emerging-botnet.rules` für IoT-Geräte:
     - Aktion: `Drop`, Ziel: `192.168.40.0/24`.
   - Blockiere Zugriff auf interne VLANs:
     - Firewall-Regel: Aktion: `Block`, Quelle: `Guests net`, Ziel: `VMs net`, `Management net`, `Storage net`.

**Tipp**: Verwende Aliases (`Firewall > Aliases`) für IPs (z. B. `Proxmox: 192.168.20.10`, `TrueNAS: 192.168.30.100`).

## Optimierung und Best Practices

### Performance-Optimierung
- **Regeln reduzieren**:
  - Deaktiviere unnötige Regeln (z. B. `emerging-games.rules` für HomeLabs).
  - Gehe zu `Services > Intrusion Detection > Administration > Rules`.
  - Filter: `Enabled`, deaktiviere irrelevante Kategorien.
- **CPU/RAM**: Erhöhe die VM-Ressourcen in Proxmox (z. B. 4 GB RAM, 4 Kerne):
  ```bash
  qm set 100 --memory 4096 --cores 4
  ```
- **Netmap**: Stelle sicher, dass VirtIO-NICs und `netmap` aktiviert sind für Inline-IPS.
- **Jumbo Frames**: Aktiviere MTU 9000 für VLAN 30 (Storage) in OPNsense und auf dem Switch.

### Sicherheit
- **Regelmäßige Updates**:
  - Aktualisiere Suricata-Regeln täglich (`Services > Intrusion Detection > Administration > Download`).
  - Aktualisiere OPNsense: `System > Firmware > Updates`.
- **False Positives vermeiden**:
  - Analysiere Alerts (`Services > Intrusion Detection > Alerts`).
  - Deaktiviere Regeln, die legitimen Traffic blockieren (z. B. `suppress` in `Services > Intrusion Detection > Settings > Suppress`).
  - Beispiel: Unterdrücke False Positives für Proxmox-Weboberfläche:
    ```yaml
    suppress gen_id 1, sig_id 123456, track by_src, ip 192.168.20.10
    ```
- **Logs sichern**:
  - Exportiere Suricata-Logs auf TrueNAS:
    ```bash
    rsync -av /var/log/suricata root@192.168.30.100:/mnt/tank/logs
    ```

### Monitoring
- **Suricata-Logs**:
  - Prüfe `fast.log` und `eve.json`:
    ```bash
    tail -f /var/log/suricata/fast.log
    ```
  - Integriere mit Zabbix/Prometheus via `os-zabbix` Plugin:
    - Installiere: `System > Firmware > Plugins > os-zabbix`.
- **Performance-Monitoring**:
  - Überwache CPU/Memory in OPNsense (`System > Diagnostics > System Activity`).
  - Prüfe Netzwerk-Traffic:
    ```bash
    netstat -i
    ```

**Quelle**: https://docs.opnsense.org/manual/reporting.html

### Integration mit Proxmox und TrueNAS
- **Proxmox-Management schützen**:
  - Erlaube nur Traffic von VLAN 20 auf `192.168.20.10:8006`.
  - Überwache verdächtige Zugriffe mit Suricata (z. B. Brute-Force auf `https`).
- **TrueNAS NFS schützen**:
  - Schränke NFS-Traffic auf `192.168.30.10` (Proxmox) ein.
  - Erkenne Anomalien (z. B. ungewöhnlich hohe NFS-Anfragen).
- **Gäste/IoT isolieren**:
  - Verwende IPS, um verdächtige IoT-Aktivitäten (z. B. Botnet-Traffic) zu blockieren.

## Empfehlungen für HomeLab

- **Setup**:
  - **OPNsense-VM**: 4 GB RAM, 4 Kerne, 20 GB Speicher (NFS oder ZFS).
  - **Suricata-Modus**: IDS für VLAN 10, 20, 40; IPS für VLAN 30 (Storage).
  - **Regelsätze**: Emerging Threats Open (`emerging-malware`, `emerging-exploit`, `emerging-botnet`).
- **Netzwerk**:
  - VLAN 10: VMs/LXC (z. B. Pi-hole, Nextcloud).
  - VLAN 20: Management (Proxmox, TrueNAS, OPNsense).
  - VLAN 30: Storage (NFS, hohe Sicherheit).
  - VLAN 40: Gäste/IoT (starke Isolation).
- **Workloads**:
  - Schutz von Pi-hole (VLAN 10, `192.168.10.102`) gegen DNS-Angriffe.
  - Schutz von TrueNAS (VLAN 30, `192.168.30.100`) gegen unbefugten NFS-Zugriff.
  - Überwachung von IoT-Geräten (VLAN 40) gegen Botnet-Aktivitäten.

## Tipps für den Erfolg

- **Start mit IDS**: Nutze zunächst den IDS-Modus, um False Positives zu analysieren, bevor du IPS aktivierst.
- **Regel-Management**: Deaktiviere irrelevante Regeln, um CPU-Last zu reduzieren (z. B. `emerging-games`).
- **Performance**: Überwache die CPU-Auslastung in OPNsense und Proxmox (`qm monitor 100`).
- **Sicherung**: Speichere Suricata-Logs und OPNsense-Konfigurationen auf TrueNAS:
  ```bash
  opnsense-backup -o /mnt/tank/backup/opnsense
  ```
- **Dokumentation**: Konsultiere https://docs.opnsense.org/manual/ips.html und https://suricata.readthedocs.io/ für erweiterte Konfigurationen.

## Fazit

Die Konfiguration von Suricata als IDS/IPS auf OPNsense bietet:
- **Sicherheit**: Erkennung und Prävention von Bedrohungen in VLANs (VMs, Management, Storage, Gäste).
- **Flexibilität**: Anpassbare Regeln für HomeLab-spezifische Workloads (z. B. Proxmox, TrueNAS).
- **Integration**: Nahtlose Einbindung in ein Proxmox-TrueNAS-HomeLab mit VLAN-Segmentierung.

Dieses Setup schützt das HomeLab vor internen und externen Bedrohungen, ist ressourcenschonend und für HomeLab-Nutzer mit begrenztem Budget geeignet. Teste die Regeln in einer nicht-produktiven Umgebung, um False Positives zu minimieren.

**Nächste Schritte**: Möchtest du eine detaillierte Anleitung zu WireGuard für Remote-Zugriff, Integration von Suricata mit Zabbix/Prometheus oder fortgeschrittene Regel-Optimierung?

**Quellen**:
- OPNsense-Dokumentation: https://docs.opnsense.org/manual/ips.html
- Suricata-Dokumentation: https://suricata.readthedocs.io/
- Webquellen:,,,,,,,,,,,,,,