# Praxisorientierte Anleitung: Fortgeschrittene IPsec-Features (z. B. Zertifikate) und Multi-Site-VPN mit OPNsense

## Einführung
Diese Anleitung erweitert die Site-to-Site-VPN-Konfiguration (siehe `site_to_site_vpn_opnsense.md`, Artifact ID: `fb77e796-c4e4-4f58-be27-2a582079ab39`) und zeigt fortgeschrittene IPsec-Features wie Zertifikat-basierte Authentifizierung (statt Pre-Shared Key, PSK) und die Einrichtung eines Multi-Site-VPNs (mehr als zwei Standorte). Wir verwenden OPNsense-Firewalls in der HomeLab-Umgebung und konfigurieren alles über die Weboberfläche oder Bash-Befehle, ohne `vim` oder `tmux`. Die Anleitung ist für Anfänger geeignet, die grundlegende VPN-Kenntnisse haben, und basiert auf den Suchergebnissen (z. B.,,), angepasst an die HomeLab mit Proxmox VE und TrueNAS-Backups.

**Voraussetzungen**:
- Zwei OPNsense-Firewalls (Standort A: `192.168.30.1`, Standort B: `192.168.40.1`) aus der vorherigen Anleitung.
- Ein dritter Standort (Standort C: `192.168.50.1`, LAN: `192.168.3.0/24`) für Multi-Site-Demonstration.
- Proxmox VE (`https://192.168.30.2:8006`) für Container-Verwaltung.
- TrueNAS (`192.168.30.100`) für Backups unter `/mnt/tank/backups/vpn-multi`.
- Grundkenntnisse in Bash und Netzwerkkonzepte.
- Internetzugang für Paketquellen.
- **Hinweis**: Wir verwenden IPsec mit Zertifikaten für höhere Sicherheit (statt PSK). Für Multi-Site wird Standort A als Hub verwendet. Alle Konfigurationen werden über die OPNsense-Weboberfläche oder Bash durchgeführt.

**Ziele**:
- Ersetze PSK durch Zertifikate für fortgeschrittene Authentifizierung.
- Richte ein Multi-Site-VPN mit drei Standorten ein.
- Automatisiere Backups der Konfiguration.

**Quellen**:
- OPNsense-Dokumentation: https://docs.opnsense.org/manual/vpnet.html
- Webquellen: https://docs.opnsense.org/manual/how-tos/ipsec-s2s.html, https://docs.opnsense.org/manual/how-tos/sslvpn_client.html

## Netzwerkkonfiguration
- **Standort A (Hub)**: WAN-IP: `192.168.30.1`, LAN: `192.168.1.0/24`
- **Standort B**: WAN-IP: `192.168.40.1`, LAN: `192.168.2.0/24`
- **Standort C**: WAN-IP: `192.168.50.1`, LAN: `192.168.3.0/24`
- **Ziel**: Standort A verbindet sich mit B und C; B und C können über A kommunizieren (Hub-and-Spoke).

## Vorbereitung: Dritter Standort einrichten
1. **Erstelle einen neuen Debian LXC-Container für Standort C**:
   - In Proxmox: `Create CT`.
     - Hostname: `fw3`
     - Template: `debian-13-standard`
     - WAN-IP: `192.168.50.1/24`
     - Gateway: `192.168.50.254`
     - LAN-IP: `192.168.3.1/24`
     - Speicher: 20 GB, CPU: 2, RAM: 2048 MB
   - Starte den Container.

2. **Installiere OPNsense in Standort C**:
   - Verbinde dich: `ssh root@192.168.50.1`.
   - Lade und installiere OPNsense:
     ```bash
     apt update
     apt install -y nano
     wget https://pkg.opnsense.org/FreeBSD/13/amd64/latest/Latest/OPNsense-25.7-OpenSSL-amd64.tar.bz2
     tar -xjf OPNsense-25.7-OpenSSL-amd64.tar.bz2 -C /
     /usr/local/etc/rc.d/opnsense enable
     /usr/local/etc/rc.d/opnsense start
     ```

3. **DNS-Eintrag in OPNsense (Standort A)**:
   - Öffne: `http://192.168.30.1`.
   - Gehe zu `Services > Unbound DNS > Overrides > Host`.
   - Füge hinzu: `fw3.homelab.local` → `192.168.50.1`.
   - Teste: `nslookup fw3.homelab.local 192.168.30.1` → `192.168.50.1`.

4. **Sichere die .bashrc**:
   - Auf jedem Standort:
     ```bash
     cp ~/.bashrc ~/.bashrc.bak
     ```

## Übung 1: Erweiterte IPsec-Authentifizierung mit Zertifikaten
**Ziel**: Ersetze PSK durch Zertifikate für sichere Authentifizierung.

1. **Erstelle Zertifikate in OPNsense (Standort A)**:
   - Öffne: `http://192.168.30.1`.
   - Gehe zu `System > Trust > Certificates`.
   - Klicke auf `+` (neues Zertifikat).
     - Method: `Generate new certificate`
     - Common Name: `fw1.homelab.local`
     - Organization: `HomeLab`
     - Country: `DE`
     - Key Type: `RSA`
     - Key Length: `2048`
     - Digest Algorithm: `SHA256`
     - Lifetime: `3650`
   - Speichere. Erzeuge ähnlich Zertifikate für Standort B und C (`fw2.homelab.local`, `fw3.homelab.local`).

2. **Exportiere Zertifikate**:
   - Gehe zu `System > Trust > Certificates`.
   - Exportiere die Zertifikate (CRT) und Privatschlüssel (KEY) für Standort B und C.

3. **Importiere Zertifikate in Standort B und C**:
   - Öffne: `http://192.168.40.1` (Standort B).
   - Gehe zu `System > Trust > Certificates`.
   - Importiere das Zertifikat und den Schlüssel von Standort A.
   - Wiederhole für Standort C (`http://192.168.50.1`).

4. **Aktualisiere Phase 1 auf Zertifikate (Standort A)**:
   - Gehe zu `VPN > IPsec > Tunnel Settings [Legacy]`.
   - Bearbeite Phase 1 für Standort B:
     - Authentication method: `Mutual Certificate`
     - My Certificate: `fw1.homelab.local`
     - Peer Certificate: `fw2.homelab.local`
   - Speichere und wende an.
   - Wiederhole für Standort C.

5. **Aktualisiere Phase 1 auf Zertifikate (Standort B und C)**:
   - Auf Standort B: Authentication method: `Mutual Certificate`, My Certificate: `fw2.homelab.local`, Peer Certificate: `fw1.homelab.local`.
   - Auf Standort C: Authentication method: `Mutual Certificate`, My Certificate: `fw3.homelab.local`, Peer Certificate: `fw1.homelab.local`.
   - Speichere und wende an.

6. **Teste die Verbindung**:
   - Von einem Client in Standort A (`192.168.1.x`):
     ```bash
     ping 192.168.2.100  # Standort B
     ping 192.168.3.100  # Standort C
     ```
     - Erwartete Ausgabe: Erfolgreiche Pings.
   - Überprüfe den IPsec-Status: `VPN > IPsec > Status > Overview` → „Connected“.

**Reflexion**: Wie erhöht Zertifikat-Authentifizierung die Sicherheit im Vergleich zu PSK? Überlege, wie Multi-Site-VPNs Skalierbarkeit bieten.

## Übung 2: Multi-Site-VPN einrichten
**Ziel**: Erweitere das VPN auf drei Standorte (Multi-Site), mit Standort A als Hub.

1. **Konfiguriere Phase 2 für Standort C (Standort A)**:
   - Öffne: `http://192.168.30.1`.
   - Gehe zu `VPN > IPsec > Tunnel Settings [Legacy]`.
   - Klicke auf `+` unter Phase 2 (neuer Tunnel für Standort C).
     - Mode: `Tunnel IPv4`
     - Local Network: `LAN subnet` (192.168.1.0/24)
     - Remote Network: `Network` > `192.168.3.0/24`
     - Description: `SiteC-LAN`
     - Phase 2 proposal: `ESP`, `AES-256`, `SHA256`, `PFS 14`
     - Lifetime: `3600 seconds`
   - Speichere und wende an.

2. **Konfiguriere Phase 2 für Standort A (Standort C)**:
   - Öffne: `http://192.168.50.1`.
   - Gehe zu `VPN > IPsec > Tunnel Settings [Legacy]`.
   - Klicke auf `+` unter Phase 2.
     - Mode: `Tunnel IPv4`
     - Local Network: `LAN subnet` (192.168.3.0/24)
     - Remote Network: `Network` > `192.168.1.0/24`
     - Description: `SiteA-LAN`
     - Phase 2 proposal: `ESP`, `AES-256`, `SHA256`, `PFS 14`
     - Lifetime: `3600 seconds`
   - Speichere und wende an.

3. **Konfiguriere Routing für Multi-Site (Standort A)**:
   - Gehe zu `Firewall > Rules > LAN`.
   - Füge Regeln hinzu, um Verkehr zu Standort B und C zu erlauben (falls nicht automatisch).
     - Quelle: `192.168.1.0/24`, Ziel: `192.168.2.0/24` oder `192.168.3.0/24`, Aktion: Pass.
   - Speichere und wende an.

4. **Teste die Multi-Site-Verbindung**:
   - Von Standort B: `ping 192.168.3.100` (Standort C).
   - Erwartete Ausgabe: Erfolgreiche Pings über Standort A (Hub).

**Reflexion**: Wie ermöglicht ein Hub-and-Spoke-Modell die Multi-Site-Verbindung? Überlege, wie Zertifikate die Skalierbarkeit verbessern.

## Übung 3: Backup der OPNsense-Konfiguration
**Ziel**: Automatisiere Backups der OPNsense-Konfiguration auf TrueNAS.

1. **Verbinde dich mit Standort A**:
   ```bash
   ssh root@192.168.30.1
   ```

2. **Erstelle Backup-Skript**:
   ```bash
   nano /usr/local/bin/vpn_backup.sh
   ```
   Füge hinzu:
   ```bash
   #!/bin/bash
   /usr/local/opnsense/scripts/backup/backup.sh > /tmp/opnsense-backup.xml
   tar -czf /tmp/vpn-backup-$(date +%Y-%m-%d).tar.gz /tmp/opnsense-backup.xml
   scp /tmp/vpn-backup-$(date +%Y-%m-%d).tar.gz root@192.168.30.100:/mnt/tank/backups/vpn-multi/
   echo "OPNsense-Konfiguration (Standort A) gesichert auf TrueNAS"
   ```
   Ausführbar machen:
   ```bash
   chmod +x /usr/local/bin/vpn_backup.sh
   ```

3. **Teste das Backup**:
   ```bash
   /usr/local/bin/vpn_backup.sh
   ```
   - Erwartete Ausgabe: Konfiguration wird auf TrueNAS gesichert.
   - Wiederhole für Standort B und C, passe die Beschreibung an.

4. **Automatisiere mit Cron**:
   ```bash
   nano /etc/crontab
   ```
   Füge hinzu:
   ```bash
   0 3 * * * root /usr/local/bin/vpn_backup.sh >> /var/log/vpn-backup.log 2>&1
   ```
   Speichere und beende.

**Reflexion**: Wie hilft das Backup-Skript bei der Wiederherstellung? Überlege, wie Multi-Site-VPNs die HomeLab erweitern.

## Tipps für den Erfolg
- **Sicherheit**:
  - Verwende starke Zertifikate und regelmäßige Rotation.
  - Schütze Backup-Dateien:
    ```bash
    chmod 600 /tmp/vpn-backup-*.tar.gz
    ```
- **Fehlerbehebung**:
  - Prüfe IPsec-Logs: `VPN > IPsec > Log File`.
  - Prüfe Firewall-Regeln: `Firewall > Diagnostics > States`.
  - Teste Konnektivität: `tcpdump -i WAN esp or udp port 500 or udp port 4500`.
- **Backup**:
  - Überprüfe Backups auf TrueNAS:
    ```bash
    ssh root@192.168.30.100 ls /mnt/tank/backups/vpn-multi/
    ```
- **Erweiterungen**:
  - Nutze Zertifikate von Let’s Encrypt für externe Zugriffe (,).
  - Teste alternative Protokolle wie WireGuard für einfachere Multi-Site-Setups.

## Fazit
Durch diese Übungen hast du fortgeschrittene IPsec-Features (Zertifikate) und ein Multi-Site-VPN mit OPNsense eingerichtet, drei Standorte verbunden und Backups automatisiert. Die OPNsense-Weboberfläche erleichtert die Konfiguration, während Cron die Verwaltung optimiert. Wiederhole die Tests, um die Stabilität zu prüfen, oder erweitere das Setup um weitere Features (z. B. Mobile Clients).

**Nächste Schritte**: Möchtest du eine Anleitung zu OpenVPN, WireGuard, oder Integration mit anderen HomeLab-Diensten (z. B. Papermerge)?

**Quellen**:
- OPNsense-Dokumentation: https://docs.opnsense.org/manual/vpnet.html
- Webquellen: https://docs.opnsense.org/manual/how-tos/ipsec-s2s.html, https://docs.opnsense.org/manual/how-tos/sslvpn_client.html
```