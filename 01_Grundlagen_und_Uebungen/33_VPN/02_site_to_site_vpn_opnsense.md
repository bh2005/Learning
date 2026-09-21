# Praxisorientierte Anleitung: Einrichtung eines Site-to-Site-VPN mit OPNsense an beiden Standorten

## Grundlagen eines Site-to-Site-VPNs
Ein **Site-to-Site-VPN** verbindet zwei Netzwerke (z. B. Standort A und B) über einen sicheren Tunnel, um den Datenverkehr zwischen ihnen zu verschlüsseln. IPsec ist ein weit verbreitetes Protokoll für Site-to-Site-VPNs, da es robuste Verschlüsselung und Authentifizierung bietet ().[](https://docs.opnsense.org/manual/how-tos/ipsec-s2s.html)

### Wichtige Konzepte
- **Definition**: Ein Site-to-Site-VPN ermöglicht die sichere Kommunikation zwischen zwei Netzwerken über ein öffentliches Netz (z. B. Internet) durch Verschlüsselung und Authentifizierung.
- **Einsatzmöglichkeiten**: Verbindung von Unternehmensstandorten, HomeLab-Netzwerken oder Rechenzentren.
- **IPsec-Phasen**:
  - **Phase 1**: Etabliert die sichere Verbindung zwischen den Firewalls (Authentifizierung, Schlüsselaustausch).
  - **Phase 2**: Definiert den Datenverkehr, der durch den Tunnel geleitet wird (z. B. LAN-Netzwerke).
- **Sicherheitsaspekte**:
  - **Authentizität**: Pre-Shared Key (PSK) oder Zertifikate.
  - **Vertraulichkeit**: Verschlüsselung (z. B. AES-256).
  - **Integrität**: Schutz vor Datenmanipulation (z. B. SHA-256).
- **Warum IPsec auf OPNsense?**:
  - **Robustheit**: Unterstützt komplexe Netzwerkkonfigurationen ().[](https://docs.opnsense.org/manual/how-tos/ipsec-s2s.html)
  - **Einfache GUI**: Konfiguration über die OPNsense-Weboberfläche.
  - **HomeLab-Eignung**: Ideal für Proxmox-basierte Umgebungen.

## Netzwerkkonfiguration
- **Standort A**:
  - Hostname: `fw1.homelab.local`
  - WAN-IP: `192.168.30.1/24`
  - LAN-Net: `192.168.1.0/24`
  - LAN-DHCP: `192.168.1.100-200`
- **Standort B**:
  - Hostname: `fw2.homelab.local`
  - WAN-IP: `192.168.40.1/24`
  - LAN-Net: `192.168.2.0/24`
  - LAN-DHCP: `192.168.2.100-200`
- **Ziel**: Geräte in `192.168.1.0/24` können auf `192.168.2.0/24` zugreifen und umgekehrt.

## Vorbereitung: OPNsense in LXC-Containern einrichten
1. **Erstelle zwei Debian LXC-Container in Proxmox**:
   - Öffne: `https://192.168.30.2:8006` (Proxmox-Weboberfläche).
   - Erstelle Container für Standort A:
     - Hostname: `fw1`
     - Template: `debian-13-standard`
     - WAN-IP: `192.168.30.1/24`, Gateway: `192.168.30.254`
     - LAN-IP: `192.168.1.1/24`
     - Speicher: 20 GB, CPU: 2, RAM: 2048 MB
   - Erstelle Container für Standort B:
     - Hostname: `fw2`
     - Template: `debian-13-standard`
     - WAN-IP: `192.168.40.1/24`, Gateway: `192.168.40.254`
     - LAN-IP: `192.168.2.1/24`
     - Speicher: 20 GB, CPU: 2, RAM: 2048 MB
   - Starte beide Container:
     ```bash
     pct start <CTID_A>  # z. B. 101
     pct start <CTID_B>  # z. B. 102
     ```

2. **Installiere OPNsense in beiden Containern**:
   - Verbinde dich mit Container A:
     ```bash
     ssh root@192.168.30.1
     ```
   - Lade und installiere OPNsense:
     ```bash
     apt update
     apt install -y nano
     wget https://pkg.opnsense.org/FreeBSD/13/amd64/latest/Latest/OPNsense-25.7-OpenSSL-amd64.tar.bz2
     tar -xjf OPNsense-25.7-OpenSSL-amd64.tar.bz2 -C /
     /usr/local/etc/rc.d/opnsense enable
     /usr/local/etc/rc.d/opnsense start
     ```
   - Wiederhole für Container B (`192.168.40.1`).

3. **DNS-Einträge in OPNsense konfigurieren**:
   - Öffne die OPNsense-Weboberfläche von Standort A: `http://192.168.30.1`.
   - Gehe zu `Services > Unbound DNS > Overrides > Host`.
   - Füge hinzu:
     - `fw1.homelab.local` → `192.168.30.1`
     - `fw2.homelab.local` → `192.168.40.1`
   - Teste die DNS-Auflösung:
     ```bash
     nslookup fw2.homelab.local 192.168.30.1
     ```
     - Erwartete Ausgabe: `192.168.40.1`.

4. **Sichere die .bashrc**:
   ```bash
   cp ~/.bashrc ~/.bashrc.bak
   ```

## Übung 1: IPsec-Tunnel konfigurieren (Standort A)
**Ziel**: Konfiguriere Phase 1 und Phase 2 für den IPsec-Tunnel auf der OPNsense-Firewall von Standort A.

1. **Verbinde dich mit der OPNsense-Weboberfläche**:
   - Öffne: `http://192.168.30.1`.
   - Standard-Login: `root` / `opnsense` (ändere das Passwort nach dem ersten Login).

2. **Aktiviere IPsec**:
   - Gehe zu `VPN > IPsec > Tunnel Settings [Legacy]`.
   - Aktiviere: `Enable IPsec` (Häkchen setzen).
   - Speichere und wende Änderungen an.

3. **Konfiguriere Firewall-Regeln (WAN)**:
   - Gehe zu `Firewall > Rules > WAN`.
   - Füge zwei Regeln hinzu:
     - **Regel 1**:
       - Protokoll: ESP
       - Quelle: `192.168.40.1`
       - Ziel: `any`
       - Aktion: Pass
     - **Regel 2**:
       - Protokoll: UDP
       - Quelle: `192.168.40.1`
       - Zielport: `500, 4500` (ISAKMP, NAT-T)
       - Aktion: Pass
   - Speichere und wende an.

4. **Deaktiviere Blockierung privater Netzwerke** (für private WAN-IPs):
   - Gehe zu `Interfaces > [WAN]`.
   - Deaktiviere: `Block private networks`.
   - Speichere und wende an.

5. **Konfiguriere Phase 1**:
   - Gehe zu `VPN > IPsec > Tunnel Settings [Legacy]`.
   - Klicke auf `+` (neuer Tunnel).
   - Einstellungen:
     - **Disabled**: Nicht aktiviert (kein Häkchen).
     - **Connection method**: `Start immediate`
     - **Key Exchange version**: `V2`
     - **Internet Protocol**: `IPv4`
     - **Interface**: `WAN`
     - **Remote gateway**: `192.168.40.1` (WAN-IP von Standort B)
     - **Description**: `Site-to-Site-VPN-to-SiteB`
     - **Phase 1 proposal (Authentication)**:
       - Authentication method: `Mutual PSK`
       - Pre-Shared Key: `<DeinGeheimerSchlüssel>` (z. B. `MySecretKey123!`)
       - Encryption algorithm: `AES (256 bits)`
       - Hash algorithm: `SHA256`
       - DH key group: `14 (2048 bit)`
     - **Advanced Settings**:
       - Lifetime: `28800 seconds`
   - Speichere und wende an.

6. **Konfiguriere Phase 2**:
   - Unter `VPN > IPsec > Tunnel Settings [Legacy]`, klicke auf `+` unter Phase 2 (im erstellten Phase-1-Eintrag).
   - Einstellungen:
     - **Mode**: `Tunnel IPv4`
     - **Local Network**: `LAN subnet` (192.168.1.0/24)
     - **Remote Network**: `Network` > `192.168.2.0/24`
     - **Description**: `SiteB-LAN`
     - **Phase 2 proposal (SA/Key Exchange)**:
       - Protocol: `ESP`
       - Encryption algorithms: `AES-256`
       - Hash algorithms: `SHA256`
       - PFS key group: `14 (2048 bit)`
     - **Lifetime**: `3600 seconds`
   - Speichere und wende an.

## Übung 2: IPsec-Tunnel konfigurieren (Standort B)
**Ziel**: Konfiguriere den IPsec-Tunnel auf der OPNsense-Firewall von Standort B, um den Tunnel zu vervollständigen.

1. **Verbinde dich mit der OPNsense-Weboberfläche**:
   - Öffne: `http://192.168.40.1`.

2. **Aktiviere IPsec**:
   - Gehe zu `VPN > IPsec > Tunnel Settings [Legacy]`.
   - Aktiviere: `Enable IPsec`.
   - Speichere und wende an.

3. **Konfiguriere Firewall-Regeln (WAN)**:
   - Gehe zu `Firewall > Rules > WAN`.
   - Füge zwei Regeln hinzu:
     - **Regel 1**:
       - Protokoll: ESP
       - Quelle: `192.168.30.1`
       - Ziel: `any`
       - Aktion: Pass
     - **Regel 2**:
       - Protokoll: UDP
       - Quelle: `192.168.30.1`
       - Zielport: `500, 4500`
       - Aktion: Pass
   - Speichere und wende an.

4. **Deaktiviere Blockierung privater Netzwerke**:
   - Gehe zu `Interfaces > [WAN]`.
   - Deaktiviere: `Block private networks`.
   - Speichere und wende an.

5. **Konfiguriere Phase 1**:
   - Gehe zu `VPN > IPsec > Tunnel Settings [Legacy]`.
   - Klicke auf `+`.
   - Einstellungen:
     - **Disabled**: Nicht aktiviert.
     - **Connection method**: `Start immediate`
     - **Key Exchange version**: `V2`
     - **Internet Protocol**: `IPv4`
     - **Interface**: `WAN`
     - **Remote gateway**: `192.168.30.1` (WAN-IP von Standort A)
     - **Description**: `Site-to-Site-VPN-to-SiteA`
     - **Phase 1 proposal (Authentication)**:
       - Authentication method: `Mutual PSK`
       - Pre-Shared Key: `<DeinGeheimerSchlüssel>` (derselbe wie bei Standort A)
       - Encryption algorithm: `AES (256 bits)`
       - Hash algorithm: `SHA256`
       - DH key group: `14 (2048 bit)`
     - **Advanced Settings**:
       - Lifetime: `28800 seconds`
   - Speichere und wende an.

6. **Konfiguriere Phase 2**:
   - Unter `VPN > IPsec > Tunnel Settings [Legacy]`, klicke auf `+` unter Phase 2.
   - Einstellungen:
     - **Mode**: `Tunnel IPv4`
     - **Local Network**: `LAN subnet` (192.168.2.0/24)
     - **Remote Network**: `Network` > `192.168.1.0/24`
     - **Description**: `SiteA-LAN`
     - **Phase 2 proposal (SA/Key Exchange)**:
       - Protocol: `ESP`
       - Encryption algorithms: `AES-256`
       - Hash algorithms: `SHA256`
       - PFS key group: `14 (2048 bit)`
     - **Lifetime**: `3600 seconds`
   - Speichere und wende an.

## Übung 3: Testen und Backup
**Ziel**: Teste die VPN-Verbindung und automatisiere Backups der OPNsense-Konfiguration.

1. **Teste die Verbindung**:
   - Von einem Client in Standort A (`192.168.1.x`):
     ```bash
     ping 192.168.2.100
     ```
     - Erwartete Ausgabe: Erfolgreiche Pings zum LAN von Standort B.
   - Von einem Client in Standort B (`192.168.2.x`):
     ```bash
     ping 192.168.1.100
     ```
     - Erwartete Ausgabe: Erfolgreiche Pings zum LAN von Standort A.
   - Prüfe den IPsec-Status in OPNsense:
     - Gehe zu `VPN > IPsec > Status > Overview`.
     - Erwartete Ausgabe: Tunnel ist „Connected“.

2. **Konfiguriere Backup in .bashrc**:
   - Verbinde dich mit Standort A (`192.168.30.1`):
     ```bash
     ssh root@192.168.30.1
     nano ~/.bashrc
     ```
     Füge hinzu:
     ```bash
     function vpn_backup() {
         trap 'echo "Backup unterbrochen"; exit 1' INT TERM
         /usr/local/opnsense/scripts/backup/backup.sh > /tmp/opnsense-backup.xml
         tar -czf /tmp/vpn-backup-$(date +%Y-%m-%d).tar.gz /tmp/opnsense-backup.xml
         scp /tmp/vpn-backup-$(date +%Y-%m-%d).tar.gz root@192.168.30.100:/mnt/tank/backups/vpn/
         echo "OPNsense-Konfiguration (Standort A) gesichert auf TrueNAS"
         trap - INT TERM
     }
     ```
     Speichere (Ctrl+O, Enter) und beende (Ctrl+X).
   - Lade die Konfiguration:
     ```bash
     source ~/.bashrc
     ```
   - Wiederhole für Standort B (`192.168.40.1`), passe die Beschreibung an (`Standort B`).

3. **Teste das Backup**:
   - Auf Standort A:
     ```bash
     vpn_backup
     ```
     - Erwartete Ausgabe: Konfiguration wird auf TrueNAS gesichert.
   - Auf Standort B:
     ```bash
     vpn_backup
     ```
     - Erwartete Ausgabe: Konfiguration wird auf TrueNAS gesichert.

4. **Automatisiere Backups mit Cron**:
   - Auf Standort A:
     ```bash
     nano /etc/crontab
     ```
     Füge hinzu:
     ```bash
     0 3 * * * root /bin/bash -c "source /root/.bashrc && vpn_backup" >> /var/log/vpn-backup.log 2>&1
     ```
     Speichere und beende.
   - Wiederhole für Standort B.

**Reflexion**: Wie erleichtert die OPNsense-GUI die IPsec-Konfiguration? Überlege, wie `iptables` oder OPNsense-Firewall-Regeln den Datenverkehr steuern.

## Tipps für den Erfolg
- **Sicherheit**:
  - Verwende einen starken Pre-Shared Key (z. B. mindestens 20 Zeichen, alphanumerisch).
  - Schütze Backup-Dateien:
    ```bash
    chmod 600 /tmp/vpn-backup-*.tar.gz
    ```
- **Fehlerbehebung**:
  - Prüfe IPsec-Logs in OPNsense: `VPN > IPsec > Log File`.
  - Prüfe Firewall-Regeln: `Firewall > Diagnostics > States`.
  - Teste Konnektivität: `tcpdump -i WAN esp or udp port 500 or udp port 4500`.
- **Backup**:
  - Überprüfe Backups auf TrueNAS:
    ```bash
    ssh root@192.168.30.100 ls /mnt/tank/backups/vpn/
    ```
- **Erweiterungen**:
  - Nutze Zertifikate statt PSK für höhere Sicherheit (siehe OPNsense-Dokumentation).
  - Teste alternative Protokolle wie WireGuard oder OpenVPN (,).[](https://www.thomas-krenn.com/de/wiki/OPNsense_OpenVPN_Instances_Site-to-Site_einrichten)[](https://www.thomas-krenn.com/de/wiki/OPNsense_WireGuard_VPN_Site-to-Site_einrichten)

## Fazit
Durch diese Übungen hast du einen IPsec-Site-to-Site-VPN-Tunnel zwischen zwei OPNsense-Firewalls in der HomeLab eingerichtet, die Netzwerke `192.168.1.0/24` und `192.168.2.0/24` verbunden und Backups automatisiert. Die OPNsense-GUI erleichtert die Konfiguration, während Cron und `.bashrc` die Verwaltung optimieren. Wiederhole die Tests, um die Stabilität zu prüfen, oder erweitere das Setup um weitere Standorte.

**Nächste Schritte**: Möchtest du eine Anleitung zu OpenVPN oder WireGuard für Site-to-Site-VPNs, fortgeschrittenen IPsec-Features (z. B. Zertifikate), oder Integration mit anderen HomeLab-Diensten (z. B. Papermerge)?

**Quellen**:
- OPNsense-Dokumentation: https://docs.opnsense.org/manual/vpnet.html
- Webquellen: https://docs.opnsense.org/manual/how-tos/ipsec-s2s.html, https://www.zenarmor.com/docs/network-security-tutorials/how-to-configure-ipsec-site-to-site-vpn-tunnel-on-opnsense[](https://docs.opnsense.org/manual/how-tos/ipsec-s2s.html)[](https://www.zenarmor.com/docs/de/netzwerksicherheitstutorials/wie-konfiguriert-man-einen-ipsec-site-to-site-vpn-tunnel-auf-opnsense)
```