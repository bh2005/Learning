# Praxisorientierte Anleitung: Integration eines Zertifikats in OPNsense für IPsec und HTTPS

## Einführung
Diese Anleitung integriert das Zertifikat `webserver.homelab.local`, erstellt in `csr_and_certificate_creation_guide.md` (Artifact ID: `3621be19-f3cb-4d30-9cae-00d57b3a3f35`), in OPNsense (`fw1.homelab.local`, `192.168.30.1`) für ein zertifikatbasiertes IPsec-Site-to-Site-VPN mit einer zweiten Firewall (`fw2.homelab.local`, `192.168.40.1`) und zur Absicherung der OPNsense-Weboberfläche (HTTPS). Die PKI-Dateien (`webserver.homelab.local.cert.pem`, `webserver.homelab.local.key.pem`, `ca-chain.cert.pem`) befinden sich auf dem PKI-Server (`192.168.30.123`). Backups werden auf TrueNAS gesichert.

## Netzwerkkonfiguration
- **PKI-Server**: `pki.homelab.local` (`192.168.30.123`)
- **Standort A**: OPNsense-Firewall, `fw1.homelab.local`, WAN: `192.168.30.1`, LAN: `192.168.1.0/24`
- **Standort B**: OPNsense-Firewall, `fw2.homelab.local`, WAN: `192.168.40.1`, LAN: `192.168.2.0/24`
- **Ziel**: 
  - Site-to-Site-VPN zwischen `192.168.1.0/24` und `192.168.2.0/24` mit Zertifikat `webserver.homelab.local`.
  - HTTPS-Absicherung der OPNsense-Weboberfläche (`https://192.168.30.1`).

## Vorbereitung
1. **Prüfe PKI-Server**:
   - Verbinde dich: `ssh root@192.168.30.123`.
   - Überprüfe Zertifikate:
     ```bash
     ls /root/ca/export/{webserver.homelab.local.cert.pem,webserver.homelab.local.key.pem,ca-chain.cert.pem}
     ```

2. **Prüfe OPNsense-Firewalls**:
   - Öffne: `http://192.168.30.1` (Standort A) und `http://192.168.40.1` (Standort B).
   - Stelle sicher, dass IPsec aktiviert ist (`VPN > IPsec > Tunnel Settings [Legacy] > Enable IPsec`).

3. **DNS-Einträge prüfen**:
   - Auf Standort A (`http://192.168.30.1`):
     - Gehe zu `Services > Unbound DNS > Overrides > Host`.
     - Prüfe: `webserver.homelab.local` → `192.168.30.1`, `fw2.homelab.local` → `192.168.40.1`.
     - Teste: `nslookup webserver.homelab.local 192.168.30.1` → `192.168.30.1`.

4. **Erstelle Zertifikat für Standort B** (falls nicht vorhanden):
   - Auf dem PKI-Server:
     ```bash
     cd /root/ca/intermediate
     openssl genrsa -out private/fw2.homelab.local.key.pem 2048
     chmod 400 private/fw2.homelab.local.key.pem
     openssl req -config openssl.cnf -key private/fw2.homelab.local.key.pem -new -sha256 -out csr/fw2.homelab.local.csr.pem
     ```
     - Eingaben: Land: `DE`, Bundesland: `Hessen`, Organisation: `HomeLab`, CN: `fw2.homelab.local`.
     ```bash
     openssl ca -config openssl.cnf -extensions usr_cert -days 375 -notext -md sha256 -in csr/fw2.homelab.local.csr.pem -out certs/fw2.homelab.local.cert.pem
     ```
     - Exportiere:
     ```bash
     cp certs/fw2.homelab.local.cert.pem private/fw2.homelab.local.key.pem certs/ca-chain.cert.pem /root/ca/export/
     chmod 600 /root/ca/export/fw2.homelab.local.key.pem
     chmod 644 /root/ca/export/{fw2.homelab.local.cert.pem,ca-chain.cert.pem}
     ```

## Übung 1: Zertifikate in OPNsense importieren
**Ziel**: Importiere die Zertifikate für `webserver.homelab.local` und `fw2.homelab.local` in OPNsense.

1. **Übertrage Zertifikate nach Standort A**:
   - Auf dem PKI-Server:
     ```bash
     scp /root/ca/export/{webserver.homelab.local.cert.pem,webserver.homelab.local.key.pem,ca-chain.cert.pem} root@192.168.30.1:/tmp/
     ```

2. **Übertrage Zertifikate nach Standort B**:
   ```bash
   scp /root/ca/export/{fw2.homelab.local.cert.pem,fw2.homelab.local.key.pem,ca-chain.cert.pem} root@192.168.40.1:/tmp/
   ```

3. **Importiere Zertifikate in Standort A**:
   - Öffne: `http://192.168.30.1`.
   - Gehe zu `System > Trust > Certificates`.
   - Klicke auf `+` (neues Zertifikat):
     - Method: `Import Certificate`
     - Certificate: Inhalt von `/tmp/webserver.homelab.local.cert.pem`
     - Private Key: Inhalt von `/tmp/webserver.homelab.local.key.pem`
     - Description: `webserver-cert`
   - Importiere die CA-Kette:
     - Method: `Import CA`
     - Certificate: Inhalt von `/tmp/ca-chain.cert.pem`
     - Description: `HomeLab CA`
   - Speichere.

4. **Importiere Zertifikate in Standort B**:
   - Öffne: `http://192.168.40.1`.
   - Wiederhole den Import:
     - Zertifikat: `/tmp/fw2.homelab.local.cert.pem`, Schlüssel: `/tmp/fw2.homelab.local.key.pem`, Description: `fw2-cert`.
     - CA: `/tmp/ca-chain.cert.pem`, Description: `HomeLab CA`.

**Reflexion**: Warum ist der Import der CA-Kette wichtig? Überlege, wie die Zertifikate die Vertrauensbasis für IPsec und HTTPS schaffen.

## Übung 2: IPsec-Site-to-Site-VPN mit Zertifikat konfigurieren
**Ziel**: Konfiguriere ein IPsec-VPN zwischen Standort A und B mit zertifikatbasierter Authentifizierung.

1. **Konfiguriere IPsec auf Standort A**:
   - Öffne: `http://192.168.30.1`.
   - Gehe zu `VPN > IPsec > Tunnel Settings [Legacy]`.
   - Erstelle oder bearbeite einen Tunnel:
     - **Phase 1**:
       - Authentication method: `Mutual Certificate`
       - My Certificate: `webserver-cert`
       - Peer Certificate: `fw2-cert`
       - Remote gateway: `192.168.40.1`
       - Description: `Site-to-Site-VPN-to-SiteB`
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
   - Firewall-Regeln (WAN):
     - Regel 1: Protokoll: ESP, Quelle: `192.168.40.1`, Ziel: `any`, Aktion: Pass
     - Regel 2: Protokoll: UDP, Quelle: `192.168.40.1`, Zielport: `500, 4500`, Aktion: Pass
   - Deaktiviere `Block private networks` unter `Interfaces > [WAN]`.
   - Speichere und wende an.

2. **Konfiguriere IPsec auf Standort B**:
   - Öffne: `http://192.168.40.1`.
   - Konfiguriere Phase 1:
     - Authentication method: `Mutual Certificate`
     - My Certificate: `fw2-cert`
     - Peer Certificate: `webserver-cert`
     - Remote gateway: `192.168.30.1`
     - Description: `Site-to-Site-VPN-to-SiteA`
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
   - Deaktiviere `Block private networks` unter `Interfaces > [WAN]`.
   - Speichere und wende an.

3. **Teste die Verbindung**:
   - Von einem Client in `192.168.1.x`:
     ```bash
     ping 192.168.2.100
     ```
   - Von einem Client in `192.168.2.x`:
     ```bash
     ping 192.168.1.100
     ```
   - Prüfe IPsec-Status: `VPN > IPsec > Status > Overview` → „Connected“.

**Reflexion**: Wie verbessert die zertifikatbasierte Authentifizierung die Sicherheit des VPNs? Überlege, wie die CA-Kette Vertrauen aufbaut.

## Übung 3: OPNsense-Weboberfläche mit HTTPS absichern
**Ziel**: Verwende das Zertifikat `webserver.homelab.local` für die OPNsense-Weboberfläche.

1. **Konfiguriere HTTPS in OPNsense**:
   - Öffne: `http://192.168.30.1`.
   - Gehe zu `System > Settings > Administration`.
   - Unter „Web GUI“:
     - Protocol: `HTTPS`
     - SSL Certificate: `webserver-cert`
     - Listen Interfaces: `LAN` (192.168.1.1)
     - Port: `443`
   - Speichere und wende an.

2. **Teste die HTTPS-Verbindung**:
   - Auf einem Client in `192.168.1.x`:
     ```bash
     curl --cacert ca-chain.cert.pem https://192.168.30.1
     ```
   - Oder öffne: `https://192.168.30.1` im Browser (importiere `ca-chain.cert.pem` in den Browser).
   - Erwartete Ausgabe: OPNsense-Weboberfläche lädt sicher.

3. **Prüfe Zertifikat**:
   - Im Browser: Klicke auf das Schloss-Symbol → Zertifikat anzeigen.
   - Erwartete Ausgabe: CN=`webserver.homelab.local`, Issuer=`HomeLab Intermediate CA`.

**Reflexion**: Wie erhöht HTTPS die Sicherheit der Weboberfläche? Überlege, wie Subject Alternative Names (SANs) die Flexibilität verbessern könnten.

## Übung 4: Backup und Automatisierung
**Ziel**: Sichere die OPNsense-Konfiguration und Zertifikate.

1. **Erweitere Backup-Skript auf Standort A**:
   - Verbinde dich: `ssh root@192.168.30.1`.
   - Bearbeite:
     ```bash
     nano /usr/local/bin/vpn_backup.sh
     ```
   - Aktualisiere:
     ```bash
     #!/bin/bash
     trap 'echo "Backup unterbrochen"; exit 1' INT TERM
     /usr/local/opnsense/scripts/backup/backup.sh > /tmp/opnsense-backup.xml
     tar -czf /tmp/vpn-backup-$(date +%Y-%m-%d).tar.gz /tmp/opnsense-backup.xml /tmp/*.pem
     scp /tmp/vpn-backup-$(date +%Y-%m-%d).tar.gz root@192.168.30.100:/mnt/tank/backups/vpn/
     echo "OPNsense-Konfiguration und Zertifikate (Standort A) gesichert auf TrueNAS"
     trap - INT TERM
     ```
   - Ausführbar machen:
     ```bash
     chmod +x /usr/local/bin/vpn_backup.sh
     ```

2. **Teste das Backup**:
   ```bash
   /usr/local/bin/vpn_backup.sh
   ```
   - Erwartete Ausgabe: Konfiguration und Zertifikate werden auf TrueNAS gesichert.

3. **Prüfe Cron**:
   - Stelle sicher, dass Cron konfiguriert ist:
     ```bash
     cat /etc/crontab
     ```
     - Erwartete Zeile: `0 3 * * * root /usr/local/bin/vpn_backup.sh >> /var/log/vpn-backup.log 2>&1`.

4. **Wiederhole für Standort B**:
   - Passe das Skript an (z. B. Beschreibung: „Standort B“) und wiederhole die Schritte.

**Reflexion**: Wie schützt das Backup die Zertifikatsintegration? Überlege, wie regelmäßige Backups die Wiederherstellung erleichtern.

## Tipps für den Erfolg
- **Sicherheit**:
  - Schütze private Schlüssel:
    ```bash
    chmod 600 /tmp/*.key.pem
    ```
  - Nutze die CRL aus `pki_crl_setup_guide.md` (Artifact ID: `f2c23f7d-1b16-4a54-a863-8942edf5610f`):
    ```bash
    scp /root/ca/export/intermediate.crl.pem root@192.168.30.1:/tmp/
    ```
    - Importiere in OPNsense: `System > Trust > CRLs`.
- **Fehlerbehebung**:
  - Prüfe IPsec-Logs: `VPN > IPsec > Log File`.
  - Prüfe Weboberfläche: `tail /var/log/nginx/error.log`.
  - Teste Zertifikate: `openssl verify -CAfile /tmp/ca-chain.cert.pem /tmp/webserver.homelab.local.cert.pem`.
- **Backup**:
  - Überprüfe Backups:
    ```bash
    ssh root@192.168.30.100 ls /mnt/tank/backups/vpn/
    ```
- **Erweiterungen**:
  - Füge SANs zum Zertifikat hinzu (siehe `csr_and_certificate_creation_guide.md`).
  - Integriere das Zertifikat in andere Dienste (z. B. OpenVPN).

## Fazit
Du hast das Zertifikat `webserver.homelab.local` in OPNsense integriert, ein IPsec-Site-to-Site-VPN mit zertifikatbasierter Authentifizierung eingerichtet, die Weboberfläche mit HTTPS gesichert und Backups automatisiert. Wiederhole die Tests, um die Stabilität zu prüfen, oder erweitere die Konfiguration um CRLs oder weitere Dienste.

**Nächste Schritte**: Möchtest du eine Anleitung zu OpenVPN mit PKI, Integration mit anderen HomeLab-Diensten (z. B. Papermerge), oder zur Erstellung von SAN-Zertifikaten?

**Quellen**:
- OPNsense-Dokumentation: https://docs.opnsense.org/manual/vpnet.html
- Webquellen: https://docs.opnsense.org/manual/how-tos/ipsec-s2s.html, https://docs.opnsense.org/manual/how-tos/sslvpn_client.html
```