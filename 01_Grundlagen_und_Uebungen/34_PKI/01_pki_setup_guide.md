# Praxisorientierte Anleitung: Erstellen einer eigenen Public Key Infrastructure (PKI) in einer neuen Debian VM

## Grundlagen einer PKI
Eine **Public Key Infrastructure (PKI)** ist ein System zur Erstellung, Verwaltung und Verteilung digitaler Zertifikate, die die Identität von Entitäten (z. B. Servern, Benutzern) verifizieren und sichere Kommunikation ermöglichen. Eine PKI besteht aus:
- **Root Certificate Authority (CA)**: Die vertrauenswürdige Basis, die Zertifikate signiert.
- **Intermediate CA**: Eine untergeordnete CA, die Zertifikate ausstellt, um die Root CA zu schützen.
- **Zertifikate**: Öffentliche Schlüssel mit Metadaten, signiert von einer CA.
- **Private Schlüssel**: Vertrauliche Schlüssel für Entitäten.
- **Certificate Revocation List (CRL)**: Liste widerrufener Zertifikate.

### Einsatzmöglichkeiten
- **VPNs**: Zertifikat-basierte Authentifizierung (z. B. IPsec, wie in `advanced_ipsec_multisite_vpn_guide.md`, Artifact ID: `d82e2c86-1a15-4e21-ba30-81dab2189bb8`).
- **Webserver**: HTTPS-Zertifikate.
- **E-Mail**: S/MIME-Verschlüsselung.
- **HomeLab**: Sichere Kommunikation zwischen Diensten (z. B. OPNsense, Proxmox).

### Sicherheitsaspekte
- **Vertraulichkeit**: Private Schlüssel schützen (z. B. `chmod 600`).
- **Integrität**: Root CA offline halten.
- **Authentizität**: Zertifikate mit korrekten Metadaten signieren.

## Vorbereitung: Debian VM einrichten
1. **Erstelle eine neue Debian VM in Proxmox**:
   - Öffne: `https://192.168.30.2:8006`.
   - Gehe zu `Datacenter > Node > Create VM`.
   - Konfiguriere:
     - Hostname: `pki`
     - Template: `debian-13-standard` (ISO herunterladen, falls nötig).
     - IP-Adresse: `192.168.30.123/24`
     - Gateway: `192.168.30.1`
     - DNS-Server: `192.168.30.1`
     - Speicher: 20 GB
     - CPU: 2, RAM: 2048 MB
   - Starte die VM:
     ```bash
     qm start <VMID>  # Ersetze <VMID> durch die VM-ID (z. B. 100)
     ```

2. **DNS-Eintrag in OPNsense hinzufügen**:
   - Öffne: `http://192.168.30.1`.
   - Gehe zu `Services > Unbound DNS > Overrides > Host`.
   - Füge hinzu: `pki.homelab.local` → `192.168.30.123`.
   - Teste:
     ```bash
     nslookup pki.homelab.local 192.168.30.1
     ```
     - Erwartete Ausgabe: `192.168.30.123`.

3. **Verbinde dich mit der VM**:
   ```bash
   ssh root@192.168.30.123
   ```

4. **Installiere OpenSSL und Tools**:
   ```bash
   apt update
   apt install -y openssl nano
   ```

5. **Sichere die .bashrc**:
   ```bash
   cp ~/.bashrc ~/.bashrc.bak
   ```

6. **Erstelle PKI-Verzeichnisstruktur**:
   ```bash
   mkdir -p /root/ca/{root,intermediate}/{certs,crl,csr,newcerts,private}
   chmod 700 /root/ca/{root,intermediate}/private
   ```

## Übung 1: Root CA erstellen
**Ziel**: Erstelle eine Root CA für die PKI.

1. **Erstelle OpenSSL-Konfiguration für Root CA**:
   ```bash
   nano /root/ca/root/openssl.cnf
   ```
   Füge hinzu:
   ```ini
   [ ca ]
   default_ca = CA_default

   [ CA_default ]
   dir = /root/ca/root
   certs = $dir/certs
   crl_dir = $dir/crl
   new_certs_dir = $dir/newcerts
   database = $dir/index.txt
   serial = $dir/serial
   RANDFILE = $dir/private/.rand
   private_key = $dir/private/ca.key.pem
   certificate = $dir/certs/ca.cert.pem
   crlnumber = $dir/crlnumber
   default_md = sha256
   name_opt = ca_default
   cert_opt = ca_default
   default_days = 3650
   preserve = no
   policy = policy_strict

   [ policy_strict ]
   countryName = match
   stateOrProvinceName = match
   organizationName = match
   organizationalUnitName = optional
   commonName = supplied
   emailAddress = optional

   [ req ]
   default_bits = 4096
   distinguished_name = req_distinguished_name
   string_mask = utf8only
   default_md = sha256
   x509_extensions = v3_ca

   [ req_distinguished_name ]
   countryName = Country Name (2 letter code)
   countryName_default = DE
   stateOrProvinceName = State or Province Name
   stateOrProvinceName_default = Hessen
   organizationName = Organization Name
   organizationName_default = HomeLab
   commonName = Common Name
   commonName_max = 64

   [ v3_ca ]
   subjectKeyIdentifier = hash
   authorityKeyIdentifier = keyid:always,issuer
   basicConstraints = critical, CA:true
   keyUsage = critical, digitalSignature, cRLSign, keyCertSign
   ```
   Speichere (Ctrl+O, Enter) und beende (Ctrl+X).

2. **Initialisiere Root CA**:
   ```bash
   cd /root/ca/root
   touch index.txt
   echo 1000 > serial
   ```

3. **Generiere Root CA-Schlüssel und Zertifikat**:
   ```bash
   openssl genrsa -aes256 -out private/ca.key.pem 4096
   chmod 400 private/ca.key.pem
   ```
   - Gib ein Passwort ein (z. B. `RootCAPass123!`).
   ```bash
   openssl req -config openssl.cnf -key private/ca.key.pem -new -x509 -days 3650 -sha256 -extensions v3_ca -out certs/ca.cert.pem
   ```
   - Eingaben: Land: `DE`, Bundesland: `Hessen`, Organisation: `HomeLab`, CN: `HomeLab Root CA`.

4. **Prüfe das Zertifikat**:
   ```bash
   openssl x509 -noout -text -in certs/ca.cert.pem
   ```
   - Erwartete Ausgabe: Zeigt Zertifikatdetails (z. B. `Issuer: C=DE, ST=Hessen, O=HomeLab, CN=HomeLab Root CA`).

**Reflexion**: Warum ist die Root CA offline zu halten? Überlege, wie das Passwort die Sicherheit erhöht.

## Übung 2: Intermediate CA erstellen
**Ziel**: Erstelle eine Intermediate CA, um die Root CA zu schützen.

1. **Erstelle OpenSSL-Konfiguration für Intermediate CA**:
   ```bash
   nano /root/ca/intermediate/openssl.cnf
   ```
   Füge hinzu:
   ```ini
   [ ca ]
   default_ca = CA_default

   [ CA_default ]
   dir = /root/ca/intermediate
   certs = $dir/certs
   crl_dir = $dir/crl
   new_certs_dir = $dir/newcerts
   database = $dir/index.txt
   serial = $dir/serial
   RANDFILE = $dir/private/.rand
   private_key = $dir/private/intermediate.key.pem
   certificate = $dir/certs/intermediate.cert.pem
   crlnumber = $dir/crlnumber
   default_md = sha256
   name_opt = ca_default
   cert_opt = ca_default
   default_days = 3650
   preserve = no
   policy = policy_loose

   [ policy_loose ]
   countryName = optional
   stateOrProvinceName = optional
   localityName = optional
   organizationName = optional
   organizationalUnitName = optional
   commonName = supplied
   emailAddress = optional

   [ req ]
   default_bits = 4096
   distinguished_name = req_distinguished_name
   string_mask = utf8only
   default_md = sha256
   x509_extensions = v3_intermediate_ca

   [ req_distinguished_name ]
   countryName = Country Name (2 letter code)
   countryName_default = DE
   stateOrProvinceName = State or Province Name
   stateOrProvinceName_default = Hessen
   organizationName = Organization Name
   organizationName_default = HomeLab
   commonName = Common Name
   commonName_max = 64

   [ v3_intermediate_ca ]
   subjectKeyIdentifier = hash
   authorityKeyIdentifier = keyid:always,issuer
   basicConstraints = critical, CA:true, pathlen:0
   keyUsage = critical, digitalSignature, cRLSign, keyCertSign
   ```
   Speichere und beende.

2. **Initialisiere Intermediate CA**:
   ```bash
   cd /root/ca/intermediate
   touch index.txt
   echo 1000 > serial
   ```

3. **Generiere Intermediate CA-Schlüssel und CSR**:
   ```bash
   openssl genrsa -aes256 -out private/intermediate.key.pem 4096
   chmod 400 private/intermediate.key.pem
   ```
   - Gib ein Passwort ein (z. B. `InterCAPass123!`).
   ```bash
   openssl req -config openssl.cnf -new -key private/intermediate.key.pem -out csr/intermediate.csr.pem
   ```
   - Eingaben: Land: `DE`, Bundesland: `Hessen`, Organisation: `HomeLab`, CN: `HomeLab Intermediate CA`.

4. **Signiere die Intermediate CA mit der Root CA**:
   ```bash
   openssl ca -config /root/ca/root/openssl.cnf -extensions v3_intermediate_ca -days 3650 -notext -md sha256 -in /root/ca/intermediate/csr/intermediate.csr.pem -out /root/ca/intermediate/certs/intermediate.cert.pem
   ```
   - Gib das Root CA-Passwort ein.

5. **Prüfe das Zertifikat**:
   ```bash
   openssl x509 -noout -text -in /root/ca/intermediate/certs/intermediate.cert.pem
   ```
   - Erwartete Ausgabe: Zeigt Zertifikatdetails.

6. **Erstelle Zertifikatkette**:
   ```bash
   cat /root/ca/intermediate/certs/intermediate.cert.pem /root/ca/root/certs/ca.cert.pem > /root/ca/intermediate/certs/ca-chain.cert.pem
   chmod 444 /root/ca/intermediate/certs/ca-chain.cert.pem
   ```

**Reflexion**: Warum ist eine Intermediate CA sicherer als direkte Nutzung der Root CA? Überlege, wie die Zertifikatkette Vertrauen aufbaut.

## Übung 3: Beispiel-Zertifikat erstellen
**Ziel**: Generiere und signiere ein Server-Zertifikat (z. B. für `vpn.homelab.local`).

1. **Generiere Server-Schlüssel und CSR**:
   ```bash
   cd /root/ca/intermediate
   openssl genrsa -out private/vpn.homelab.local.key.pem 2048
   chmod 400 private/vpn.homelab.local.key.pem
   openssl req -config openssl.cnf -key private/vpn.homelab.local.key.pem -new -sha256 -out csr/vpn.homelab.local.csr.pem
   ```
   - Eingaben: Land: `DE`, Bundesland: `Hessen`, Organisation: `HomeLab`, CN: `vpn.homelab.local`.

2. **Signiere das Zertifikat mit der Intermediate CA**:
   ```bash
   openssl ca -config openssl.cnf -extensions usr_cert -days 375 -notext -md sha256 -in csr/vpn.homelab.local.csr.pem -out certs/vpn.homelab.local.cert.pem
   ```
   - Gib das Intermediate CA-Passwort ein.
   - Füge `usr_cert` zur Konfiguration hinzu (vorher in `/root/ca/intermediate/openssl.cnf`):
     ```ini
     [ usr_cert ]
     basicConstraints = CA:FALSE
     subjectKeyIdentifier = hash
     authorityKeyIdentifier = keyid,issuer
     keyUsage = critical, digitalSignature, keyEncipherment
     extendedKeyUsage = serverAuth
     ```

3. **Prüfe das Zertifikat**:
   ```bash
   openssl x509 -noout -text -in certs/vpn.homelab.local.cert.pem
   ```
   - Erwartete Ausgabe: Zeigt Zertifikatdetails (CN: `vpn.homelab.local`).

**Reflexion**: Wie kann das Zertifikat in einem VPN (z. B. IPsec) verwendet werden? Überlege, wie SANs (Subject Alternative Names) die Flexibilität erhöhen.

## Übung 4: Backup und Automatisierung
**Ziel**: Sichere die PKI und automatisiere Backups.

1. **Erstelle Backup-Skript**:
   ```bash
   nano /usr/local/bin/pki_backup.sh
   ```
   Füge hinzu:
   ```bash
   #!/bin/bash
   trap 'echo "Backup unterbrochen"; exit 1' INT TERM
   tar -czf /tmp/pki-backup-$(date +%Y-%m-%d).tar.gz /root/ca
   scp /tmp/pki-backup-$(date +%Y-%m-%d).tar.gz root@192.168.30.100:/mnt/tank/backups/pki/
   echo "PKI-Konfiguration gesichert auf TrueNAS"
   trap - INT TERM
   ```
   Ausführbar machen:
   ```bash
   chmod +x /usr/local/bin/pki_backup.sh
   ```

2. **Teste das Backup**:
   ```bash
   /usr/local/bin/pki_backup.sh
   ```
   - Erwartete Ausgabe: Konfiguration wird auf TrueNAS gesichert.

3. **Automatisiere mit Cron**:
   ```bash
   nano /etc/crontab
   ```
   Füge hinzu:
   ```bash
   0 3 * * * root /usr/local/bin/pki_backup.sh >> /var/log/pki-backup.log 2>&1
   ```
   Speichere und beende.

**Reflexion**: Wie schützt das Backup die PKI? Überlege, wie regelmäßige Backups die Wiederherstellung erleichtern.

## Tipps für den Erfolg
- **Sicherheit**:
  - Schütze private Schlüssel:
    ```bash
    chmod 400 /root/ca/*/private/*.key.pem
    ```
  - Speichere die Root CA offline (z. B. auf einem USB-Stick).
- **Fehlerbehebung**:
  - Prüfe OpenSSL-Konfiguration: `openssl ca -config /root/ca/root/openssl.cnf -status 1000`.
  - Prüfe Logs: `tail /var/log/pki-backup.log`.
  - Teste Zertifikate: `openssl verify -CAfile /root/ca/root/certs/ca.cert.pem /root/ca/intermediate/certs/intermediate.cert.pem`.
- **Backup**:
  - Überprüfe Backups auf TrueNAS:
    ```bash
    ssh root@192.168.30.100 ls /mnt/tank/backups/pki/
    ```
- **Erweiterungen**:
  - Nutze Let’s Encrypt für externe Zertifikate.
  - Erstelle eine CRL (Certificate Revocation List):
    ```bash
    openssl ca -config /root/ca/intermediate/openssl.cnf -gencrl -out /root/ca/intermediate/crl/intermediate.crl.pem
    ```

## Fazit
Du hast eine eigene PKI mit einer Root CA, Intermediate CA und einem Beispiel-Zertifikat in einer Debian VM eingerichtet. Die Konfiguration ist gesichert und automatisiert durch Backups auf TrueNAS. Wiederhole die Übungen, um weitere Zertifikate (z. B. für OPNsense-VPNs) zu erstellen oder die PKI um CRLs zu erweitern.

**Nächste Schritte**: Möchtest du eine Anleitung zur Integration der PKI in OPNsense (z. B. für IPsec), zur Erstellung von Client-Zertifikaten, oder zu anderen HomeLab-Diensten (z. B. Papermerge)?

**Quellen**:
- OpenSSL-Dokumentation: https://www.openssl.org/docs/
- Webquellen: https://jamielinux.com/docs/openssl-certificate-authority/, https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-a-certificate-authority-ca-on-debian-10
```