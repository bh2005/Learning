# Praxisorientierte Anleitung: Integration der PKI in OPNsense für IPsec und Erstellung von Client-Zertifikaten

## Einführung
Diese Anleitung integriert die PKI aus `pki_setup_guide.md` (Artifact ID: `1c042e3b-cdbc-4654-8db3-50ec9fc91d9c`) in OPNsense, um ein zertifikatbasiertes IPsec-Site-to-Site-VPN zwischen zwei Standorten (`fw1.homelab.local`, `fw2.homelab.local`) und ein IPsec-Remote-Access-VPN für Clients einzurichten. Die PKI umfasst eine Root CA und Intermediate CA auf einer Debian VM (`192.168.30.123`). Wir erstellen Client-Zertifikate für Remote-Benutzer und sichern die Konfiguration auf TrueNAS.

## Netzwerkkonfiguration
- **PKI-Server**: `pki.homelab.local` (`192.168.30.123`)
- **Standort A**: OPNsense-Firewall, `fw1.homelab.local`, WAN: `192.168.30.1`, LAN: `192.168.1.0/24`
- **Standort B**: OPNsense-Firewall, `fw2.homelab.local`, WAN: `192.168.40.1`, LAN: `192.168.2.0/24`
- **Client**: Remote-Benutzer mit Zertifikat, verbindet sich mit Standort A
- **Ziel**: 
  - Site-to-Site-VPN zwischen `192.168.1.0/24` und `192.168.2.0/24` mit Zertifikaten.
  - Remote-Access-VPN für Clients, die auf `192.168.1.0/24` zugreifen.

## Vorbereitung
1. **Prüfe PKI-Server**:
   - Verbinde dich: `ssh root@192.168.30.123`.
   - Überprüfe Zertifikate:
     ```bash
     ls /root/ca/root/certs/ca.cert.pem
     ls /root/ca/intermediate/certs/intermediate.cert.pem
     ```
   - Stelle sicher, dass die Konfiguration (`/root/ca/root/openssl.cnf`, `/root/ca/intermediate/openssl.cnf`) existiert.

2. **Prüfe OPNsense-Firewalls**:
   - Öffne: `http://192.168.30.1` (Standort A) und `http://192.168.40.1` (Standort B).
   - Stelle sicher, dass IPsec aktiviert ist (`VPN > IPsec > Tunnel Settings [Legacy] > Enable IPsec`).

3. **DNS-Einträge prüfen**:
   - Auf Standort A: `Services > Unbound DNS > Overrides > Host`:
     - `pki.homelab.local` → `192.168.30.123`
     - `fw2.homelab.local` → `192.168.40.1`
   - Teste: `nslookup fw2.homelab.local 192.168.30.1` → `192.168.40.1`.

## Übung 1: Zertifikate für IPsec-Site-to-Site-VPN erstellen
**Ziel**: Erstelle und verteile Zertifikate für Standort A und B.

1. **Generiere Zertifikate für Standort A (fw1)**:
   - Auf dem PKI-Server (`192.168.30.123`):
     ```bash
     cd /root/ca/intermediate
     openssl genrsa -out private/fw1.homelab.local.key.pem 2048
     chmod 400 private/fw1.homelab.local.key.pem
     openssl req -config openssl.cnf -key private/fw1.homelab.local.key.pem -new -sha256 -out csr/fw1.homelab.local.csr.pem
     ```
     - Eingaben: Land: `DE`, Bundesland: `Hessen`, Organisation: `HomeLab`, CN: `fw1.homelab.local`.
   - Signiere das Zertifikat:
     ```bash
     openssl ca -config openssl.cnf -extensions usr_cert -days 375 -notext -md sha256 -in csr/fw1.homelab.local.csr.pem -out certs/fw1.homelab.local.cert.pem
     ```
     - Gib das Intermediate CA-Passwort ein.
   - Prüfe:
     ```bash
     openssl x509 -noout -text -in certs/fw1.homelab.local.cert.pem
     ```

2. **Generiere Zertifikate für Standort B (fw2)**:
   - Wiederhole die Schritte für `fw2.homelab.local`:
     ```bash
     openssl genrsa -out private/fw2.homelab.local.key.pem 2048
     chmod 400 private/fw2.homelab.local.key.pem
     openssl req -config openssl.cnf -key private/fw2.homelab.local.key.pem -new -sha256 -out csr/fw2.homelab.local.csr.pem
     ```
     - Eingaben: Land: `DE`, Bundesland: `Hessen`, Organisation: `HomeLab`, CN: `fw2.homelab.local`.
   - Signiere:
     ```bash
     openssl ca -config openssl.cnf -extensions usr_cert -days 375 -notext -md sha256 -in csr/fw2.homelab.local.csr.pem -out certs/fw2.homelab.local.cert.pem
     ```

3. **Exportiere Zertifikate und Schlüssel**:
   - Kopiere die Zertifikate und Schlüssel:
     ```bash
     mkdir -p /root/ca/export
     cp /root/ca/intermediate/certs/{fw1,fw2}.homelab.local.cert.pem /root/ca/intermediate/private/{fw1,fw2}.homelab.local.key.pem /root/ca/intermediate/certs/ca-chain.cert.pem /root/ca/export/
     chmod 600 /root/ca/export/*.key.pem
     ```
   - Übertrage nach Standort A:
     ```bash
     scp /root/ca/export/{fw1.homelab.local.cert.pem,fw1.homelab.local.key.pem,ca-chain.cert.pem} root@192.168.30.1:/tmp/
     ```
   - Übertrage nach Standort B:
     ```bash
     scp /root/ca/export/{fw2.homelab.local.cert.pem,fw2.homelab.local.key.pem,ca-chain.cert.pem} root@192.168.40.1:/tmp/
     ```

## Übung 2: Integriere Zertifikate in OPNsense für Site-to-Site-VPN
**Ziel**: Konfiguriere ein zertifikatbasiertes IPsec-Site-to-Site-VPN.

1. **Importiere Zertifikate in Standort A**:
   - Öffne: `http://192.168.30.1`.
   - Gehe zu `System > Trust > Certificates`.
   - Klicke auf `+`:
     - Method: `Import Certificate`
     - Certificate: Inhalt von `/tmp/fw1.homelab.local.cert.pem`
     - Private Key: Inhalt von `/tmp/fw1.homelab.local.key.pem`
     - Description: `fw1-cert`
   - Importiere die CA-Kette:
     - Method: `Import CA`
     - Certificate: Inhalt von `/tmp/ca-chain.cert.pem`
     - Description: `HomeLab CA`
   - Speichere.

2. **Importiere Zertifikate in Standort B**:
   - Öffne: `http://192.168.40.1`.
   - Wiederhole den Import für `fw2.homelab.local.cert.pem`, `fw2.homelab.local.key.pem` (Description: `fw2-cert`) und `ca-chain.cert.pem` (Description: `HomeLab CA`).

3. **Konfiguriere IPsec auf Standort A**:
   - Gehe zu `VPN > IPsec > Tunnel Settings [Legacy]`.
   - Bearbeite den bestehenden Tunnel oder erstelle einen neuen:
     - **Phase 1**:
       - Authentication method: `Mutual Certificate`
       - My Certificate: `fw1-cert`
       - Peer Certificate: `fw2-cert`
       - Remote gateway: `192.168.40.1`
       - Encryption algorithm: `AES (256 bits)`
       - Hash algorithm: `SHA256`
       - DH key group: `14 (2048 bit)`
       - Lifetime: `28800 seconds`
     - **Phase 2**:
       - Local Network: `LAN subnet` (192.168.1.0/24)
       - Remote Network: `Network` > `192.168.2.0/24`
       - Protocol: `ESP`
       - Encryption algorithms: `AES-256`
       - Hash algorithms: `SHA256`
       - PFS key group: `14 (2048 bit)`
       - Lifetime: `3600 seconds`
   - Speichere und wende an.
   - Firewall-Regeln (WAN):
     - Regel 1: Protokoll: ESP, Quelle: `192.168.40.1`, Ziel: `any`, Aktion: Pass
     - Regel 2: Protokoll: UDP, Quelle: `192.168.40.1`, Zielport: `500, 4500`, Aktion: Pass

4. **Konfiguriere IPsec auf Standort B**:
   - Öffne: `http://192.168.40.1`.
   - Konfiguriere Phase 1:
     - Authentication method: `Mutual Certificate`
     - My Certificate: `fw2-cert`
     - Peer Certificate: `fw1-cert`
     - Remote gateway: `192.168.30.1`
     - Encryption algorithm: `AES (256 bits)`
     - Hash algorithm: `SHA256`
     - DH key group: `14 (2048 bit)`
     - Lifetime: `28800 seconds`
   - Phase 2:
     - Local Network: `LAN subnet` (192.168.2.0/24)
     - Remote Network: `Network` > `192.168.1.0/24`
     - Protocol: `ESP`
     - Encryption algorithms: `AES-256`
     - Hash algorithms: `SHA256`
     - PFS key group: `14 (2048 bit)`
     - Lifetime: `3600 seconds`
   - Firewall-Regeln (WAN):
     - Regel 1: Protokoll: ESP, Quelle: `192.168.30.1`, Ziel: `any`, Aktion: Pass
     - Regel 2: Protokoll: UDP, Quelle: `192.168.30.1`, Zielport: `500, 4500`, Aktion: Pass
   - Speichere und wende an.

5. **Teste die Verbindung**:
   - Von einem Client in `192.168.1.x`: `ping 192.168.2.100`.
   - Von einem Client in `192.168.2.x`: `ping 192.168.1.100`.
   - Prüfe IPsec-Status: `VPN > IPsec > Status > Overview` → „Connected“.

**Reflexion**: Wie erhöht die Zertifikat-Authentifizierung die Sicherheit gegenüber PSK? Überlege, wie die CA-Kette Vertrauen aufbaut.

## Übung 3: Client-Zertifikate für Remote-Access-VPN erstellen
**Ziel**: Erstelle ein Client-Zertifikat und konfiguriere ein Remote-Access-VPN.

1. **Generiere Client-Zertifikat auf dem PKI-Server**:
   - Auf `192.168.30.123`:
     ```bash
     cd /root/ca/intermediate
     openssl genrsa -out private/client1.homelab.local.key.pem 2048
     chmod 400 private/client1.homelab.local.key.pem
     openssl req -config openssl.cnf -key private/client1.homelab.local.key.pem -new -sha256 -out csr/client1.homelab.local.csr.pem
     ```
     - Eingaben: Land: `DE`, Bundesland: `Hessen`, Organisation: `HomeLab`, CN: `client1.homelab.local`.
   - Signiere:
     ```bash
     openssl ca -config openssl.cnf -extensions usr_cert -days 375 -notext -md sha256 -in csr/client1.homelab.local.csr.pem -out certs/client1.homelab.local.cert.pem
     ```
   - Exportiere:
     ```bash
     cp certs/client1.homelab.local.cert.pem private/client1.homelab.local.key.pem certs/ca-chain.cert.pem /root/ca/export/
     ```

2. **Konfiguriere Remote-Access-VPN auf Standort A**:
   - Öffne: `http://192.168.30.1`.
   - Gehe zu `VPN > IPsec > Mobile Clients`.
   - Aktiviere: `Enable IPsec Mobile Client Support`.
   - Einstellungen:
     - Virtual Address Pool: `192.168.10.0/24`
     - DNS Default Domain: `homelab.local`
     - DNS Servers: `192.168.30.1`
   - Speichere und wende an.
   - Gehe zu `VPN > IPsec > Tunnel Settings [Legacy]`.
   - Erstelle neuen Tunnel für Mobile Clients:
     - **Phase 1**:
       - Authentication method: `Mutual Certificate`
       - My Certificate: `fw1-cert`
       - Peer Certificate: `HomeLab CA` (als CA auswählen)
       - Interface: `WAN`
       - Description: `Mobile-VPN`
       - Encryption algorithm: `AES (256 bits)`
       - Hash algorithm: `SHA256`
       - DH key group: `14 (2048 bit)`
     - **Phase 2**:
       - Local Network: `LAN subnet` (192.168.1.0/24)
       - Remote Network: `Network` > `192.168.10.0/24`
       - Protocol: `ESP`
       - Encryption algorithms: `AES-256`
       - Hash algorithms: `SHA256`
       - PFS key group: `14 (2048 bit)`
   - Speichere und wende an.
   - Firewall-Regeln (IPsec):
     - Gehe zu `Firewall > Rules > IPsec`.
     - Füge hinzu: Quelle: `192.168.10.0/24`, Ziel: `192.168.1.0/24`, Aktion: Pass.

3. **Konfiguriere Client (z. B. auf einem Laptop)**:
   - Übertrage Client-Zertifikate:
     ```bash
     scp /root/ca/export/{client1.homelab.local.cert.pem,client1.homelab.local.key.pem,ca-chain.cert.pem} user@<client-ip>:~/vpn/
     ```
   - Auf dem Client (z. B. Debian/Ubuntu):
     ```bash
     sudo apt install strongswan
     sudo nano /etc/ipsec.conf
     ```
     Füge hinzu:
     ```ini
     conn homelab-vpn
         leftcert=client1.homelab.local.cert.pem
         leftid=client1.homelab.local
         leftsourceip=%config
         right=192.168.30.1
         rightid=fw1.homelab.local
         rightsubnet=192.168.1.0/24
         authby=pubkey
         auto=start
     ```
     Speichere und beende.
   - Kopiere Zertifikate:
     ```bash
     sudo cp ~/vpn/{client1.homelab.local.cert.pem,client1.homelab.local.key.pem,ca-chain.cert.pem} /etc/ipsec.d/
     ```
   - Starte strongSwan:
     ```bash
     sudo systemctl restart ipsec
     ```
   - Teste:
     ```bash
     ping 192.168.1.100
     ```

**Reflexion**: Wie erleichtert die PKI die Verwaltung von Client-Zertifikaten? Überlege, wie CRLs die Sicherheit erhöhen könnten.

## Übung 4: Backup und Automatisierung
**Ziel**: Sichere die OPNsense-Konfiguration und PKI-Zertifikate.

1. **Erweitere Backup-Skript auf Standort A**:
   ```bash
   ssh root@192.168.30.1
   nano /usr/local/bin/vpn_backup.sh
   ```
   Aktualisiere:
   ```bash
   #!/bin/bash
   trap 'echo "Backup unterbrochen"; exit 1' INT TERM
   /usr/local/opnsense/scripts/backup/backup.sh > /tmp/opnsense-backup.xml
   tar -czf /tmp/vpn-backup-$(date +%Y-%m-%d).tar.gz /tmp/opnsense-backup.xml /tmp/*.pem
   scp /tmp/vpn-backup-$(date +%Y-%m-%d).tar.gz root@192.168.30.100:/mnt/tank/backups/vpn/
   echo "OPNsense-Konfiguration und Zertifikate (Standort A) gesichert auf TrueNAS"
   trap - INT TERM
   ```
   Ausführbar machen:
   ```bash
   chmod +x /usr/local/bin/vpn_backup.sh
   ```

2. **Teste das Backup**:
   ```bash
   /usr/local/bin/vpn_backup.sh
   ```
   - Erwartete Ausgabe: Konfiguration und Zertifikate werden auf TrueNAS gesichert.
   - Wiederhole für Standort B.

3. **Prüfe Cron**:
   - Stelle sicher, dass Cron konfiguriert ist:
     ```bash
     cat /etc/crontab
     ```
     - Erwartete Zeile: `0 3 * * * root /usr/local/bin/vpn_backup.sh >> /var/log/vpn-backup.log 2>&1`.

**Reflexion**: Wie schützt das Backup die PKI-Integration? Überlege, wie regelmäßige Backups die Wiederherstellung erleichtern.

## Tipps für den Erfolg
- **Sicherheit**:
  - Schütze private Schlüssel:
    ```bash
    chmod 600 /tmp/*.key.pem
    ```
  - Nutze CRLs für widerrufene Zertifikate:
    ```bash
    openssl ca -config /root/ca/intermediate/openssl.cnf -gencrl -out /root/ca/intermediate/crl/intermediate.crl.pem
    ```
- **Fehlerbehebung**:
  - Prüfe IPsec-Logs: `VPN > IPsec > Log File`.
  - Prüfe strongSwan-Logs: `sudo journalctl -u ipsec`.
  - Teste Zertifikate: `openssl verify -CAfile /root/ca/export/ca-chain.cert.pem /root/ca/export/client1.homelab.local.cert.pem`.
- **Backup**:
  - Überprüfe Backups:
    ```bash
    ssh root@192.168.30.100 ls /mnt/tank/backups/{pki,vpn}/
    ```
- **Erweiterungen**:
  - Nutze Let’s Encrypt für externe Zertifikate.
  - Erweitere das Remote-Access-VPN für mehrere Clients.

## Fazit
Du hast die PKI in OPNsense für ein zertifikatbasiertes IPsec-Site-to-Site-VPN integriert, ein Remote-Access-VPN mit Client-Zertifikaten eingerichtet und Backups automatisiert. Wiederhole die Tests, um die Stabilität zu prüfen, oder erweitere die PKI um CRLs oder weitere Client-Zertifikate.

**Nächste Schritte**: Möchtest du eine Anleitung zur Erstellung einer CRL, Integration mit anderen Diensten (z. B. Papermerge), oder zu OpenVPN mit PKI?

**Quellen**:
- OPNsense-Dokumentation: https://docs.opnsense.org/manual/vpnet.html
- OpenSSL-Dokumentation: https://www.openssl.org/docs/
- Webquellen: https://docs.opnsense.org/manual/how-tos/ipsec-s2s.html, https://docs.opnsense.org/manual/how-tos/sslvpn_client.html
```