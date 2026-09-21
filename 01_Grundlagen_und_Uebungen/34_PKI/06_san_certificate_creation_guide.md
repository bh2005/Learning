# Praxisorientierte Anleitung: Erstellung eines SAN-Zertifikats mit der PKI in einer Debian VM

## Grundlagen eines SAN-Zertifikats
Ein **Subject Alternative Name (SAN)-Zertifikat** ist ein X.509-Zertifikat, das mehrere Identitäten (z. B. DNS-Namen, IP-Adressen) in der SAN-Erweiterung enthält. Dadurch kann ein einziges Zertifikat für mehrere Hostnamen oder Adressen verwendet werden, was die Flexibilität erhöht.

### Wichtige Konzepte
- **SAN**: Erweiterung im Zertifikat, die zusätzliche Identitäten wie `DNS:www.example.com` oder `IP:192.168.1.100` definiert.
- **Vorteile**:
  - Ein Zertifikat für mehrere Domänen (z. B. `webserver.homelab.local`, `www.webserver.homelab.local`).
  - Unterstützung für IP-Adressen, nützlich in HomeLab-Umgebungen.
  - Vereinfacht die Zertifikatsverwaltung.
- **Einsatzmöglichkeiten**:
  - **Webserver**: HTTPS für mehrere Domänen (z. B. Nginx).
  - **VPNs**: Authentifizierung in IPsec oder OpenVPN mit mehreren Hostnamen.
  - **HomeLab**: Sicherung von Diensten wie OPNsense oder Proxmox.
- **Sicherheitsaspekte**:
  - **Vertraulichkeit**: Private Schlüssel schützen (z. B. `chmod 400`).
  - **Integrität**: Korrekte SANs im CSR angeben.
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

2. **DNS-Einträge prüfen**:
   - Auf der OPNsense-Firewall (`http://192.168.30.1`):
     - Gehe zu `Services > Unbound DNS > Overrides > Host`.
     - Prüfe oder füge hinzu:
       - `webserver.homelab.local` → `192.168.1.100`
       - `www.webserver.homelab.local` → `192.168.1.100`
     - Teste: `nslookup webserver.homelab.local 192.168.30.1` → `192.168.1.100`.

3. **Erstelle SAN-Konfigurationsdatei**:
   - Auf dem PKI-Server:
     ```bash
     nano /root/ca/intermediate/san.cnf
     ```
     Füge hinzu:
     ```ini
     [req]
     req_extensions = v3_req
     distinguished_name = req_distinguished_name
     prompt = no

     [req_distinguished_name]
     C = DE
     ST = Hessen
     O = HomeLab
     CN = webserver.homelab.local

     [v3_req]
     subjectAltName = @alt_names

     [alt_names]
     DNS.1 = webserver.homelab.local
     DNS.2 = www.webserver.homelab.local
     IP.1 = 192.168.1.100
     ```
     Speichere (Ctrl+O, Enter) und beende (Ctrl+X).

## Übung 1: CSR mit SANs erstellen
**Ziel**: Erstelle einen CSR mit SANs für `webserver.homelab.local`.

1. **Generiere privaten Schlüssel**:
   ```bash
   cd /root/ca/intermediate
   openssl genrsa -out private/webserver-san.homelab.local.key.pem 2048
   chmod 400 private/webserver-san.homelab.local.key.pem
   ```

2. **Erstelle CSR mit SANs**:
   ```bash
   openssl req -config san.cnf -key private/webserver-san.homelab.local.key.pem -new -sha256 -out csr/webserver-san.homelab.local.csr.pem
   ```
   - **Hinweis**: Die `san.cnf`-Datei definiert die Metadaten und SANs, daher sind keine Eingaben erforderlich.

3. **Prüfe den CSR**:
   ```bash
   openssl req -noout -text -in csr/webserver-san.homelab.local.csr.pem
   ```
   - Erwartete Ausgabe: Zeigt CSR-Details, einschließlich `Subject Alternative Name: DNS:webserver.homelab.local, DNS:www.webserver.homelab.local, IP Address:192.168.1.100`.

**Reflexion**: Warum sind SANs für moderne Anwendungen wichtig? Überlege, wie SANs die Zertifikatsverwaltung vereinfachen.

## Übung 2: SAN-Zertifikat mit der Intermediate CA signieren
**Ziel**: Signiere den CSR, um ein SAN-Zertifikat zu erstellen.

1. **Aktualisiere OpenSSL-Konfiguration**:
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
     subjectAltName = @alt_names
     ```
   - Speichere (Ctrl+O, Enter) und beende (Ctrl+X).

2. **Signiere den CSR**:
   ```bash
   cd /root/ca/intermediate
   openssl ca -config openssl.cnf -extensions usr_cert -days 375 -notext -md sha256 -in csr/webserver-san.homelab.local.csr.pem -out certs/webserver-san.homelab.local.cert.pem
   ```
   - Gib das Intermediate CA-Passwort ein (z. B. `InterCAPass123!`).

3. **Prüfe das Zertifikat**:
   ```bash
   openssl x509 -noout -text -in certs/webserver-san.homelab.local.cert.pem
   ```
   - Erwartete Ausgabe: Zeigt Zertifikatdetails, einschließlich `X509v3 Subject Alternative Name: DNS:webserver.homelab.local, DNS:www.webserver.homelab.local, IP Address:192.168.1.100`.

4. **Exportiere Zertifikat und Schlüssel**:
   ```bash
   cp certs/webserver-san.homelab.local.cert.pem private/webserver-san.homelab.local.key.pem certs/ca-chain.cert.pem /root/ca/export/
   chmod 600 /root/ca/export/webserver-san.homelab.local.key.pem
   chmod 644 /root/ca/export/{webserver-san.homelab.local.cert.pem,ca-chain.cert.pem}
   ```

**Reflexion**: Wie unterscheidet sich ein SAN-Zertifikat von einem Standard-Zertifikat? Überlege, wie SANs die Flexibilität in einer HomeLab-Umgebung erhöhen.

## Übung 3: Beispiel-Integration in einen Webserver
**Ziel**: Teste das SAN-Zertifikat in einem Nginx-Webserver.

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
     scp /root/ca/export/{webserver-san.homelab.local.cert.pem,webserver-san.homelab.local.key.pem,ca-chain.cert.pem} root@192.168.1.100:/etc/nginx/
     ```

3. **Konfiguriere Nginx**:
   ```bash
   nano /etc/nginx/sites-available/webserver.homelab.local
   ```
   Füge hinzu:
   ```nginx
   server {
       listen 443 ssl;
       server_name webserver.homelab.local www.webserver.homelab.local;
       ssl_certificate /etc/nginx/webserver-san.homelab.local.cert.pem;
       ssl_certificate_key /etc/nginx/webserver-san.homelab.local.key.pem;
       root /var/www/html;
       index index.html;
   }
   ```
   Aktiviere die Konfiguration:
   ```bash
   ln -s /etc/nginx/sites-available/webserver.homelab.local /etc/nginx/sites-enabled/
   systemctl restart nginx
   ```

4. **Teste die Verbindung**:
   - Auf einem Client:
     ```bash
     curl --cacert ca-chain.cert.pem https://webserver.homelab.local
     curl --cacert ca-chain.cert.pem https://www.webserver.homelab.local
     curl --cacert ca-chain.cert.pem https://192.168.1.100
     ```
   - Erwartete Ausgabe: HTML-Inhalt von `/var/www/html/index.html` für alle Adressen.

**Reflexion**: Wie erleichtert das SAN-Zertifikat die Nutzung mehrerer Hostnamen? Überlege, wie es in einem VPN verwendet werden könnte.

## Übung 4: Backup und Automatisierung
**Ziel**: Sichere das SAN-Zertifikat und aktualisiere Backups.

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
     echo "PKI-Konfiguration und SAN-Zertifikate gesichert auf TrueNAS"
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
  - Prüfe CSR: `openssl req -noout -text -in /root/ca/intermediate/csr/webserver-san.homelab.local.csr.pem`.
  - Prüfe Zertifikat: `openssl verify -CAfile /root/ca/intermediate/certs/ca-chain.cert.pem /root/ca/intermediate/certs/webserver-san.homelab.local.cert.pem`.
  - Prüfe Nginx-Logs: `tail /var/log/nginx/error.log`.
  - Prüfe Backup-Logs: `tail /var/log/pki-backup.log`.
- **Backup**:
  - Überprüfe Backups:
    ```bash
    ssh root@192.168.30.100 ls /mnt/tank/backups/pki/
    ```
- **Erweiterungen**:
  - Integriere das SAN-Zertifikat in OPNsense für IPsec oder HTTPS (siehe `certificate_opnsense_integration.md`, Artifact ID: `8fe33303-8ea0-4bc1-b4f6-1f7a887e7f29`).
  - Nutze die CRL aus `pki_crl_setup_guide.md` (Artifact ID: `f2c23f7d-1b16-4a54-a863-8942edf5610f`) für Widerrufe.

## Fazit
Du hast ein SAN-Zertifikat für `webserver.homelab.local` mit zusätzlichen DNS-Namen und IPs erstellt, es mit der Intermediate CA signiert, in einem Nginx-Webserver getestet und Backups automatisiert. Das Zertifikat ist flexibel für Dienste wie OPNsense oder Webserver einsetzbar. Wiederhole die Übungen, um weitere SAN-Zertifikate zu erstellen, oder erweitere die PKI um weitere Funktionen.

**Nächste Schritte**: Möchtest du eine Anleitung zu OpenVPN mit SAN-Zertifikaten, Integration mit anderen HomeLab-Diensten (z. B. Papermerge), oder weitere PKI-Erweiterungen?

**Quellen**:
- OpenSSL-Dokumentation: https://www.openssl.org/docs/
- Webquellen: https://jamielinux.com/docs/openssl-certificate-authority/, https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-a-certificate-authority-ca-on-debian-10
```