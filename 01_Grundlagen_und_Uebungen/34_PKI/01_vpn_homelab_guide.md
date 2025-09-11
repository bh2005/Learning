# Praxisorientierte Anleitung: Grundlagen zu Virtual Private Networks (VPN) in einem neuen Debian LXC-Container

## Grundlagen von VPNs
Ein **Virtual Private Network (VPN)** ist ein sicheres, verschlüsseltes Netzwerk, das über ein öffentliches Netz (z. B. Internet) aufgebaut wird, um private Kommunikation zwischen zwei oder mehr Parteien zu ermöglichen. VPNs schaffen einen virtuellen „Tunnel“, der Daten vor Abhören und Manipulation schützt.

### Wichtige Konzepte
- **Definition**: Ein VPN ermöglicht die sichere Verbindung zwischen zwei Hosts oder Netzwerken über ein öffentliches Netz durch Verschlüsselung, Authentifizierung und Integrität.
- **Einsatzmöglichkeiten**:
  - **Privater Gebrauch**: Anonymität, Schutz auf öffentlichen WLANs, Umgehung von Geoblocking.
  - **Unternehmensgebrauch**: Sicherer Zugriff auf Firmennetzwerke (z. B. Remote-Access-VPN).
  - **HomeLab**: Sicherer Zugriff auf interne Dienste (z. B. Proxmox VE, Papermerge) von extern.
- **Sicherheitsaspekte**:
  - **Authentizität**: Überprüfung der Identität der Kommunikationspartner.
  - **Vertraulichkeit**: Verschlüsselung der Daten (z. B. AES-256 bei WireGuard).
  - **Integrität**: Schutz vor Datenmanipulation.
- **VPN-Typen**:
  - **Remote-Access-VPN**: Verbindet Einzelnutzer mit einem Netzwerk.
  - **Site-to-Site-VPN**: Verbindet zwei Netzwerke.
  - **End-to-End-VPN**: Sichert die Kommunikation zwischen zwei Hosts.
- **Warum WireGuard?**:
  - **Einfachheit**: Minimalistisches Protokoll (~4.000 Codezeilen vs. ~600.000 bei OpenVPN).
  - **Sicherheit**: Moderne Kryptografie (ChaCha20, Curve25519).
  - **Performance**: Geringe Latenz, hohe Geschwindigkeit.
  - **HomeLab-Eignung**: Leicht in Debian LXC-Containern zu konfigurieren.

## Vorbereitung: Einrichtung eines neuen Debian LXC-Containers
1. **Melde dich an der Proxmox-Weboberfläche an**:
   - Öffne: `https://192.168.30.2:8006`.
   - Logge dich ein (z. B. `root@pam`).

2. **Erstelle einen neuen Debian 13 LXC-Container**:
   - Gehe zu `Datacenter > Node > Create CT`.
   - Konfiguriere:
     - Hostname: `vpn`
     - Template: `debian-13-standard`
     - IP-Adresse: `192.168.30.122/24`
     - Gateway: `192.168.30.1`
     - DNS-Server: `192.168.30.1`
     - Speicher: 10 GB
     - CPU: 2, RAM: 1024 MB
   - Starte den Container:
     ```bash
     pct start <CTID>  # Ersetze <CTID> durch die Container-ID (z. B. 102)
     ```

3. **DNS-Eintrag in OPNsense hinzufügen**:
   - Öffne die OPNsense-Weboberfläche: `http://192.168.30.1`.
   - Gehe zu `Services > Unbound DNS > Overrides > Host`.
   - Füge hinzu: `vpn.homelab.local` → `192.168.30.122`.
   - Teste die DNS-Auflösung:
     ```bash
     nslookup vpn.homelab.local 192.168.30.1
     ```
     - Erwartete Ausgabe: `192.168.30.122`.

4. **Verbinde dich mit dem Container**:
   ```bash
   ssh root@192.168.30.122
   ```

5. **Installiere grundlegende Tools**:
   ```bash
   apt update
   apt install -y wireguard nano qrencode
   ```

6. **Sichere die .bashrc**:
   ```bash
   cp ~/.bashrc ~/.bashrc.bak
   ```

7. **Erstelle VPN-Verzeichnis**:
   ```bash
   mkdir -p ~/vpn
   ```

**Tipp**: Nutze TrueNAS (`192.168.30.100`) für Backups unter `/mnt/tank/backups/vpn`.

## Übung 1: WireGuard-Server einrichten
**Ziel**: Richte einen WireGuard-VPN-Server ein, um sicheren Zugriff auf den Debian-Container zu ermöglichen.

1. **Generiere Schlüsselpaare**:
   ```bash
   cd ~/vpn
   umask 077
   wg genkey | tee server_private.key | wg pubkey > server_public.key
   wg genkey | tee client_private.key | wg pubkey > client_public.key
   ```

2. **Erstelle WireGuard-Konfiguration**:
   ```bash
   nano ~/vpn/wg0.conf
   ```
   Füge hinzu:
   ```ini
   [Interface]
   PrivateKey = <server_private.key>
   Address = 10.0.0.1/24
   ListenPort = 51820
   PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
   PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

   [Peer]
   PublicKey = <client_public.key>
   AllowedIPs = 10.0.0.2/32
   ```
   - Ersetze `<server_private.key>` und `<client_public.key>` mit den Inhalten der generierten Schlüssel:
     ```bash
     cat ~/vpn/server_private.key
     cat ~/vpn/client_public.key
     ```
   - Speichere (Ctrl+O, Enter) und beende (Ctrl+X).

3. **Kopiere Konfiguration**:
   ```bash
   cp ~/vpn/wg0.conf /etc/wireguard/
   ```

4. **Aktiviere IP-Forwarding**:
   ```bash
   echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
   sysctl -p
   ```

5. **Starte WireGuard**:
   ```bash
   systemctl enable wg-quick@wg0
   systemctl start wg-quick@wg0
   ```

6. **Prüfe den Status**:
   ```bash
   wg show
   ```
   - Erwartete Ausgabe: Zeigt die `wg0`-Schnittstelle und den Server-Schlüssel.

7. **Konfiguriere OPNsense-Firewall**:
   - Öffne die OPNsense-Weboberfläche: `http://192.168.30.1`.
   - Gehe zu `Firewall > Rules > WAN`.
   - Füge eine Regel hinzu:
     - Protokoll: UDP
     - Ziel: `192.168.30.122`
     - Port: `51820`
     - Aktion: Pass
   - Speichere und wende die Regel an.

**Reflexion**: Wie schützt WireGuard die Verbindung? Überlege, wie `iptables` den Datenverkehr steuert.

## Übung 2: WireGuard-Client einrichten
**Ziel**: Konfiguriere einen Client (z. B. ein Laptop) für den Zugriff auf die HomeLab.

1. **Erstelle Client-Konfiguration**:
   ```bash
   nano ~/vpn/client.conf
   ```
   Füge hinzu:
   ```ini
   [Interface]
   PrivateKey = <client_private.key>
   Address = 10.0.0.2/24
   DNS = 192.168.30.1

   [Peer]
   PublicKey = <server_public.key>
   Endpoint = 192.168.30.122:51820
   AllowedIPs = 192.168.30.0/24
   ```
   - Ersetze `<client_private.key>` und `<server_public.key>` mit:
     ```bash
     cat ~/vpn/client_private.key
     cat ~/vpn/server_public.key
     ```
   - Speichere (Ctrl+O, Enter) und beende (Ctrl+X).

2. **Generiere QR-Code für mobile Clients** (optional):
   ```bash
   qrencode -t ansiutf8 < ~/vpn/client.conf
   ```
   - Erwartete Ausgabe: Ein QR-Code, den du mit einer WireGuard-App (z. B. auf Android/iOS) scannen kannst.

3. **Kopiere Client-Konfiguration auf den Client**:
   - Übertrage `client.conf` auf deinen Client (z. B. Laptop):
     ```bash
     scp ~/vpn/client.conf user@<client-ip>:~/vpn/
     ```
   - Auf dem Client (z. B. Debian/Ubuntu):
     ```bash
     sudo apt install wireguard
     sudo cp ~/vpn/client.conf /etc/wireguard/wg0.conf
     sudo systemctl enable wg-quick@wg0
     sudo systemctl start wg-quick@wg0
     ```

4. **Teste die Verbindung**:
   - Auf dem Client:
     ```bash
     ping 192.168.30.121
     ```
   - Erwartete Ausgabe: Erfolgreiche Pings zum HomeLab-Netzwerk.
   - Auf dem Server:
     ```bash
     wg show
     ```
   - Erwartete Ausgabe: Zeigt aktive Peers (Client).

**Reflexion**: Wie erleichtert der QR-Code die Client-Konfiguration? Überlege, wie `AllowedIPs` den Zugriff steuert.

## Übung 3: Backup und Automatisierung mit .bashrc
**Ziel**: Automatisiere die Verwaltung und Sicherung der VPN-Konfiguration.

1. **Erstelle .bashrc-Funktionen**:
   ```bash
   nano ~/.bashrc
   ```
   Füge hinzu:
   ```bash
   function vpn_status() {
       wg show
   }
   function vpn_backup() {
       trap 'echo "Backup unterbrochen"; exit 1' INT TERM
       tar -czf /tmp/vpn-backup-$(date +%Y-%m-%d).tar.gz ~/vpn /etc/wireguard
       scp /tmp/vpn-backup-$(date +%Y-%m-%d).tar.gz root@192.168.30.100:/mnt/tank/backups/vpn/
       echo "VPN-Konfiguration gesichert auf TrueNAS"
       trap - INT TERM
   }
   function vpn_add_client() {
       if [ $# -lt 1 ]; then
           echo "Usage: vpn_add_client <client_name>"
           return 1
       fi
       cd ~/vpn
       umask 077
       wg genkey | tee ${1}_private.key | wg pubkey > ${1}_public.key
       echo "[Peer]" >> /etc/wireguard/wg0.conf
       echo "PublicKey = $(cat ${1}_public.key)" >> /etc/wireguard/wg0.conf
       echo "AllowedIPs = 10.0.0.$(( $(grep -c AllowedIPs /etc/wireguard/wg0.conf) + 1 ))/32" >> /etc/wireguard/wg0.conf
       systemctl restart wg-quick@wg0
       echo "Client $1 hinzugefügt"
   }
   ```
   Speichere (Ctrl+O, Enter) und beende (Ctrl+X). Lade die Konfiguration:
   ```bash
   source ~/.bashrc
   ```

2. **Teste die Funktionen**:
   - Prüfe den Status:
     ```bash
     vpn_status
     ```
   - Erstelle ein Backup:
     ```bash
     vpn_backup
     ```
     - Erwartete Ausgabe: Konfiguration wird auf TrueNAS gesichert.
   - Füge einen neuen Client hinzu:
     ```bash
     vpn_add_client client2
     ```
     - Erwartete Ausgabe: Neuer Peer wird zu `/etc/wireguard/wg0.conf` hinzugefügt.

3. **Automatisiere Backups mit Cron**:
   ```bash
   crontab -e
   ```
   Füge hinzu (mit `nano`):
   ```bash
   0 3 * * * /bin/bash -c "source ~/.bashrc && vpn_backup" >> /var/log/vpn-backup.log 2>&1
   ```
   Speichere (Ctrl+O, Enter) und beende (Ctrl+X).

**Reflexion**: Wie vereinfacht die `.bashrc`-Funktion `vpn_add_client` die Verwaltung? Überlege, wie Cron die Datensicherung automatisiert.

## Tipps für den Erfolg
- **Sicherheit**:
  - Schütze Schlüsseldateien:
    ```bash
    chmod 600 ~/vpn/*.key
    ```
  - Verwende starke Schlüssel und regelmäßige Rotation.
- **Fehlerbehebung**:
  - Prüfe WireGuard: `wg show`.
  - Prüfe Firewall: `iptables -L -v -n`.
  - Prüfe Logs: `journalctl -u wg-quick@wg0`.
- **Backup**: Überprüfe Backups auf TrueNAS:
  ```bash
  ssh root@192.168.30.100 ls /mnt/tank/backups/vpn/
  ```
- **Erweiterungen**:
  - Nutze `wg-quick` für dynamische Konfigurationen.
  - Integriere mit OPNsense für erweiterte Firewall-Regeln.

## Fazit
Durch diese Übungen hast du die Grundlagen von VPNs verstanden, einen WireGuard-VPN-Server in einem neuen Debian LXC-Container eingerichtet und einen Client für den sicheren Zugriff auf die HomeLab konfiguriert. Die `.bashrc`-Funktionen und Cron automatisieren Verwaltung und Backups. Wiederhole die Übungen, um weitere Clients oder erweiterte Konfigurationen (z. B. Site-to-Site-VPN) einzurichten.

**Nächste Schritte**: Möchtest du eine Anleitung zu fortgeschrittenen WireGuard-Konfigurationen, OpenVPN als Alternative, oder Integration mit anderen HomeLab-Diensten (z. B. Papermerge)?

**Quellen**:
- WireGuard-Dokumentation: https://www.wireguard.com/
- Debian-Dokumentation: https://www.debian.org/releases/trixie/
- Webquellen: https://www.cybercademy.org/configuring-a-vpn-server-in-cybersecurity-homelab-via-openvpn/, https://ricoberger.de/blog/2025-03-24-use-a-vpn-to-access-your-homelab/
```