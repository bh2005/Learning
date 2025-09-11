# Praxisorientierte Anleitung: Erstellung eines CSR und eines Zertifikats mit der PKI in einer Debian VM

## Grundlagen eines CSR und Zertifikats
Ein **Certificate Signing Request (CSR)** ist eine Datei, die einen öffentlichen Schlüssel und Metadaten (z. B. Common Name, Organisation) enthält und an eine Certificate Authority (CA) gesendet wird, um ein Zertifikat zu erhalten. Das Zertifikat wird von der CA signiert und dient zur sicheren Identitätsprüfung.

### Wichtige Konzepte
- **CSR**: Enthält den öffentlichen Schlüssel und Informationen wie Common Name (CN), Land, Organisation.
- **Zertifikat**: Ergebnis der Signierung des CSR durch die CA, enthält den öffentlichen Schlüssel und ist vertrauenswürdig.
- **Einsatzmöglichkeiten**:
  - **Webserver**: HTTPS-Zertifikate (z. B. für `webserver.homelab.local`).
  - **VPNs**: Authentifizierung in IPsec oder OpenVPN.
  - **HomeLab**: Sicherung von Diensten wie OPNsense oder Proxmox.
- **Sicherheitsaspekte**:
  - **Vertraulichkeit**: Private Schlüssel schützen (z. B. `chmod 400`).
  - **Integrität**: Korrekte Metadaten im CSR verwenden.
  - **Authentizität**: Signierung durch eine vertrauenswürdige CA.

## Vorbereitung
1. **Prüfe PKI-Server**:
   - Verbinde dich: `ssh root@192.168.30.123`.
   - Überprüfe die PKI:
     ```bash
     ls /root/ca/intermediate/certs/intermediate.cert.pem
     ls /root/ca/intermediate/private/intermediate.key.pem
     ls /root/ca/intermediate/openssl.cnf
     ```
   - Stelle sicher, dass die Intermediate CA konfiguriert ist.

2. **DNS-Eintrag prüfen**:
   - Auf der OPNsense-Firewall (`http://192.168.30.1`):
     - Gehe zu `Services > Unbound DNS > Overrides > Host`.
     - Füge hinzu (falls nötig): `webserver.homelab.local` → `192.168.1.100` (Beispiel-IP für den Webserver).
     - Teste: `nslookup webserver.homelab.local 192.168.30.1`.

3. **Erstelle Export-Verzeichnis**:
   ```bash
   mkdir -p /root/ca/export
   chmod 700 /root/ca/export
   ```

## Übung 1: CSR für einen Webserver erstellen
**Ziel**: Erstelle einen CSR für `webserver.homelab.local`.

1. **Generiere privaten Schlüssel**:
   - Auf dem PKI-Server:
     ```bash
     cd /root/ca/intermediate
     openssl genrsa -out private/webserver.homelab.local.key.pem 2048
     chmod 400 private/webserver.homelab.local.key.pem
     ```

2. **Erstelle CSR**:
   ```bash
   openssl req -config openssl.cnf -key private/webserver.homelab.local.key.pem -new -sha256 -out csr/webserver.homelab.local.csr.pem
   ```
   - Eingaben:
     - Land: `DE`
     - Bundesland: `Hessen`
     - Organisation: `HomeLab`
     - Common Name: `webserver.homelab.local`
     - Andere Felder (z. B. E-Mail): Optional, können leer bleiben (Enter drücken).

3. **Prüfe den CSR**:
   ```bash
   openssl req -noout -text -in csr/webserver.homelab.local.csr.pem
   ```
   - Erwartete Ausgabe: Zeigt CSR-Details (z. B. `CN=webserver.homelab.local`).

**Reflexion**: Warum sind korrekte Metadaten im CSR wichtig? Überlege, wie Subject Alternative Names (SANs) die Flexibilität erhöhen könnten.

## Übung 2: Zertifikat mit der Intermediate CA signieren
**Ziel**: Signiere den CSR, um ein Zertifikat zu erstellen.

1. **Aktualisiere OpenSSL-Konfiguration**:
   - Auf dem PKI-Server:
     ```bash
     nano /root/ca/intermediate/openssl.cnf
     ```
   - Stelle sicher, dass die `usr_cert`-Sektion für Server-Zertifikate enthalten ist (füge hinzu, falls nötig):
     ```ini
     [ usr_cert ]
     basicConstraints = CA:FALSE
     subjectKeyIdentifier = hash
     authorityKeyIdentifier = keyid,issuer
     keyUsage = critical, digitalSignature, keyEncipherment
     extendedKeyUsage = serverAuth
     ```
   - Speichere (Ctrl+O, Enter) und beende (Ctrl+X).

2. **Signiere den CSR**:
   ```bash
   cd /root/ca/intermediate
   openssl ca -config openssl.cnf -extensions usr_cert -days 375 -notext -md sha256 -in csr/webserver.homelab.local.csr.pem -out certs/webserver.homelab.local.cert.pem
   ```
   - Gib das Intermediate CA-Passwort ein (z. B. `InterCAPass123!`).

3. **Prüfe das Zertifikat**:
   ```bash
   openssl x509 -noout -text -in certs/webserver.homelab.local.cert.pem
   ```
   - Erwartete Ausgabe: Zeigt Zertifikatdetails (z. B. `Issuer: CN=HomeLab Intermediate CA`, `Subject: CN=webserver.homelab.local`).

4. **Exportiere Zertifikat und Schlüssel**:
   ```bash
   cp certs/webserver.homelab.local.cert.pem private/webserver.homelab.local.key.pem certs/ca-chain.cert.pem /root/ca/export/
   chmod 600 /root/ca/export/webserver.homelab.local.key.pem
   chmod 644 /root/ca/export/{webserver.homelab.local.cert.pem,ca-chain.cert.pem}
   ```

**Reflexion**: Wie unterscheidet sich ein signiertes Zertifikat vom CSR? Überlege, wie das Zertifikat in einem Webserver (z. B. Nginx) verwendet werden kann.

## Übung 3: Beispiel-Integration in einen Webserver
**Ziel**: Teste das Zertifikat in einem einfachen Nginx-Webserver.

1. **Installiere Nginx**:
   - Auf einem Server mit `webserver.homelab.local` (z. B. `192.168.1.100`):
     ```bash
     ssh root@192.168.1.100
     apt update
     apt install -y nginx
     ```

2. **Übertrage Zertifikate**:
   - Vom PKI-Server:
     ```bash
     scp /root/ca/export/{webserver.homelab.local.cert.pem,webserver.homelab.local.key.pem,ca-chain.cert.pem} root@192.168.1.100:/etc/nginx/
     ```

3. **Konfiguriere Nginx**:
   - Auf dem Webserver:
     ```bash
     nano /etc/nginx/sites-available/webserver.homelab.local
     ```
     Füge hinzu:
     ```nginx
     server {
         listen 443 ssl;
         server_name webserver.homelab.local;
         ssl_certificate /etc/nginx/webserver.homelab.local.cert.pem;
         ssl_certificate_key /etc/nginx/webserver.homelab.local.key.pem;
         root /var/www/html;
         index index.html;
     }
     ```
   - Aktiviere die Konfiguration:
     ```bash
     ln -s /etc/nginx/sites-available/webserver.homelab.local /etc/nginx/sites-enabled/
     systemctl restart nginx
     ```

4. **Teste die Verbindung**:
   - Auf einem Client:
     ```bash
     curl --cacert ca-chain.cert.pem https://webserver.homelab.local
     ```
   - Erwartete Ausgabe: HTML-Inhalt von `/var/www/html/index.html`.

**Reflexion**: Wie erleichtert die PKI die Zertifikatsverwaltung für Webserver? Überlege, wie die CA-Kette Vertrauen aufbaut.

## Übung 4: Backup und Automatisierung
**Ziel**: Sichere das neue Zertifikat und aktualisiere Backups.

1. **Erweitere Backup-Skript**:
   - Auf dem PKI-Server:
     ```bash
     nano /usr/local/bin/pki_backup.sh
     ```
   - Aktualisiere:
     ```bash
     #!/bin/bash
     trap 'echo "Backup unterbrochen"; exit 1' INT TERM
     tar -czf /tmp/pki-backup-$(date +%Y-%m-%d).tar.gz /root/ca
     scp /tmp/pki-backup-$(date +%Y-%m-%d).tar.gz root@192.168.30.100:/mnt/tank/backups/pki/
     echo "PKI-Konfiguration und Zertifikate gesichert auf TrueNAS"
     trap - INT TERM
     ```
   - Ausführbar machen:
     ```bash
     chmod +x /usr/local/bin/pki_backup.sh
     ```

2. **Teste das Backup**:
   ```bash
   /usr/local/bin/pki_backup.sh
   ```
   - Erwartete Ausgabe: Zertifikate und PKI-Konfiguration werden auf TrueNAS gesichert.

3. **Prüfe Cron**:
   - Stelle sicher, dass Cron konfiguriert ist:
     ```bash
     cat /etc/crontab
     ```
     - Erwartete Zeile: `0 4 * * * root /usr/local/bin/pki_backup.sh >> /var/log/pki-backup.log 2>&1`.

**Reflexion**: Wie schützt das Backup die PKI? Überlege, wie regelmäßige Backups die Wiederherstellung erleichtern.

## Tipps für den Erfolg
- **Sicherheit**:
  - Schütze private Schlüssel:
    ```bash
    chmod 400 /root/ca/intermediate/private/*.key.pem
    ```
  - Verwende starke Passwörter für die CA.
- **Fehlerbehebung**:
  - Prüfe CSR: `openssl req -noout -text -in /root/ca/intermediate/csr/webserver.homelab.local.csr.pem`.
  - Prüfe Zertifikat: `openssl verify -CAfile /root/ca/intermediate/certs/ca-chain.cert.pem /root/ca/intermediate/certs/webserver.homelab.local.cert.pem`.
  - Prüfe Backup-Logs: `tail /var/log/pki-backup.log`.
- **Backup**:
  - Überprüfe Backups:
    ```bash
    ssh root@192.168.30.100 ls /mnt/tank/backups/pki/
    ```
- **Erweiterungen**:
  - Füge Subject Alternative Names (SANs) zum CSR hinzu:
    ```bash
    nano /tmp/san.cnf
    ```
    ```ini
    [req]
    req_extensions = v3_req
    [v3_req]
    subjectAltName = DNS:webserver.homelab.local,DNS:www.webserver.homelab.local
    ```
    ```bash
    openssl req -config openssl.cnf -key private/webserver.homelab.local.key.pem -new -sha256 -out csr/webserver.homelab.local.csr.pem -extensions v3_req -config /tmp/san.cnf
    ```
  - Integriere das Zertifikat in OPNsense für IPsec oder OpenVPN.

## Fazit
Du hast einen CSR für `webserver.homelab.local` erstellt, ihn mit der Intermediate CA signiert, das Zertifikat in einem Nginx-Webserver getestet und Backups automatisiert. Das Zertifikat kann in Diensten wie OPNsense oder anderen HomeLab-Anwendungen verwendet werden. Wiederhole die Übungen, um weitere Zertifikate zu erstellen, oder erweitere die PKI um SANs oder CRLs.

**Nächste Schritte**: Möchtest du eine Anleitung zur Integration des Zertifikats in OPNsense, zur Erstellung von SAN-Zertifikaten, oder zu anderen HomeLab-Diensten (z. B. OpenVPN)?

**Quellen**:
- OpenSSL-Dokumentation: https://www.openssl.org/docs/
- Webquellen: https://jamielinux.com/docs/openssl-certificate-authority/, https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-a-certificate-authority-ca-on-debian-10
```