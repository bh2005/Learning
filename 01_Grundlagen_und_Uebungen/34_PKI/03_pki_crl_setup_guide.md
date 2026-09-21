# Praxisorientierte Anleitung: Erstellung einer Certificate Revocation List (CRL) für die PKI in einer Debian VM

## Grundlagen einer CRL
Eine **Certificate Revocation List (CRL)** ist eine Liste von Zertifikaten, die von einer Certificate Authority (CA) widerrufen wurden, z. B. wegen Kompromittierung oder Ablauf der Gültigkeit. Die CRL wird von Diensten (z. B. OPNsense) genutzt, um ungültige Zertifikate zu erkennen und Verbindungen zu blockieren.

### Wichtige Konzepte
- **Definition**: Eine CRL enthält Seriennummern widerrufener Zertifikate und wird von der CA signiert.
- **Einsatzmöglichkeiten**:
  - **VPNs**: Blockieren widerrufener Client-Zertifikate (z. B. IPsec-Remote-Access-VPN).
  - **Webserver**: Verhindern der Nutzung kompromittierter Zertifikate.
  - **HomeLab**: Sicherstellung der Vertrauenswürdigkeit von Zertifikaten.
- **Sicherheitsaspekte**:
  - **Aktualität**: CRLs müssen regelmäßig aktualisiert und verteilt werden.
  - **Verfügbarkeit**: CRLs sollten z. B. über HTTP bereitgestellt werden.
  - **Integrität**: Signierte CRLs verhindern Manipulation.
- **Warum CRL in OPNsense?**:
  - Unterstützt zertifikatbasierte IPsec-VPNs (siehe `pki_opnsense_integration.md`).
  - Ermöglicht dynamische Zertifikatsprüfung für Remote-Clients.

## Vorbereitung
1. **Prüfe PKI-Server**:
   - Verbinde dich: `ssh root@192.168.30.123`.
   - Überprüfe die PKI:
     ```bash
     ls /root/ca/intermediate/certs/{intermediate,client1.homelab.local}.cert.pem
     ls /root/ca/intermediate/private/intermediate.key.pem
     ```
   - Stelle sicher, dass `/root/ca/intermediate/openssl.cnf` existiert.

2. **Prüfe OPNsense-Firewall**:
   - Öffne: `http://192.168.30.1`.
   - Gehe zu `System > Trust > Certificates` und prüfe, ob `HomeLab CA` und `fw1-cert` importiert sind.
   - Stelle sicher, dass das IPsec-Remote-Access-VPN aktiv ist (`VPN > IPsec > Mobile Clients`).

3. **Erstelle CRL-Verzeichnis**:
   - Auf dem PKI-Server:
     ```bash
     mkdir -p /root/ca/intermediate/crl
     chmod 700 /root/ca/intermediate/crl
     echo 1000 > /root/ca/intermediate/crlnumber
     ```

## Übung 1: CRL erstellen und Zertifikat widerrufen
**Ziel**: Erstelle eine CRL für die Intermediate CA und widerrufe das Zertifikat `client1.homelab.local`.

1. **Aktualisiere OpenSSL-Konfiguration**:
   - Auf dem PKI-Server:
     ```bash
     nano /root/ca/intermediate/openssl.cnf
     ```
   - Stelle sicher, dass die CRL-Konfiguration enthalten ist (füge hinzu, falls nötig):
     ```ini
     [ ca ]
     default_ca = CA_default

     [ CA_default ]
     crl_dir = $dir/crl
     crlnumber = $dir/crlnumber
     default_crl_days = 30
     default_crl_md = sha256

     [ crl_ext ]
     authorityKeyIdentifier = keyid:always
     ```
   - Speichere (Ctrl+O, Enter) und beende (Ctrl+X).

2. **Generiere die CRL**:
   ```bash
   cd /root/ca/intermediate
   openssl ca -config openssl.cnf -gencrl -out crl/intermediate.crl.pem
   ```
   - Gib das Intermediate CA-Passwort ein (z. B. `InterCAPass123!`).

3. **Widerrufe ein Zertifikat**:
   - Widerrufe das Zertifikat `client1.homelab.local`:
     ```bash
     openssl ca -config openssl.cnf -revoke certs/client1.homelab.local.cert.pem
     ```
     - Gib das Intermediate CA-Passwort ein.
   - Aktualisiere die CRL:
     ```bash
     openssl ca -config openssl.cnf -gencrl -out crl/intermediate.crl.pem
     ```

4. **Prüfe die CRL**:
   ```bash
   openssl crl -in crl/intermediate.crl.pem -noout -text
   ```
   - Erwartete Ausgabe: Zeigt die Seriennummer von `client1.homelab.local` als widerrufen.

**Reflexion**: Warum ist das Widerrufen eines Zertifikats wichtig? Überlege, wie die CRL die Sicherheit des IPsec-VPNs erhöht.

## Übung 2: CRL in OPNsense integrieren
**Ziel**: Verteile die CRL an OPNsense und aktiviere die CRL-Prüfung für das Remote-Access-VPN.

1. **Exportiere die CRL**:
   - Auf dem PKI-Server:
     ```bash
     cp /root/ca/intermediate/crl/intermediate.crl.pem /root/ca/export/
     chmod 644 /root/ca/export/intermediate.crl.pem
     scp /root/ca/export/intermediate.crl.pem root@192.168.30.1:/tmp/
     ```

2. **Importiere die CRL in OPNsense**:
   - Öffne: `http://192.168.30.1`.
   - Gehe zu `System > Trust > CRLs`.
   - Klicke auf `+`:
     - Method: `Import CRL`
     - CRL Data: Inhalt von `/tmp/intermediate.crl.pem`
     - Description: `HomeLab Intermediate CRL`
   - Speichere.

3. **Aktiviere CRL-Prüfung im IPsec-VPN**:
   - Gehe zu `VPN > IPsec > Mobile Clients`.
   - Bearbeite die Einstellungen:
     - Stelle sicher, dass `HomeLab CA` als CA ausgewählt ist.
   - Gehe zu `VPN > IPsec > Tunnel Settings [Legacy]` und bearbeite den Mobile-VPN-Tunnel:
     - Phase 1: Stelle sicher, dass `Peer Certificate` auf `HomeLab CA` gesetzt ist.
     - Aktiviere: `Enable CRL checking` (falls verfügbar, oder prüfe die OPNsense-Version).
   - Speichere und wende an.

4. **Teste die CRL**:
   - Auf dem Client mit `client1.homelab.local`:
     ```bash
     sudo systemctl restart ipsec
     ping 192.168.1.100
     ```
     - Erwartete Ausgabe: Verbindung schlägt fehl, da das Zertifikat widerrufen ist.
   - Erstelle ein neues Client-Zertifikat (`client2.homelab.local`):
     ```bash
     cd /root/ca/intermediate
     openssl genrsa -out private/client2.homelab.local.key.pem 2048
     openssl req -config openssl.cnf -key private/client2.homelab.local.key.pem -new -sha256 -out csr/client2.homelab.local.csr.pem
     ```
     - Eingaben: Land: `DE`, Bundesland: `Hessen`, Organisation: `HomeLab`, CN: `client2.homelab.local`.
     ```bash
     openssl ca -config openssl.cnf -extensions usr_cert -days 375 -notext -md sha256 -in csr/client2.homelab.local.csr.pem -out certs/client2.homelab.local.cert.pem
     ```
   - Übertrage und teste mit `client2.homelab.local` (wie in `pki_opnsense_integration.md`).

**Reflexion**: Wie beeinflusst die CRL die VPN-Sicherheit? Überlege, wie regelmäßige CRL-Updates verwaltet werden können.

## Übung 3: CRL-Verteilung und Automatisierung
**Ziel**: Automatisiere die CRL-Erstellung und -Verteilung sowie Backups.

1. **Erstelle CRL-Update-Skript**:
   ```bash
   nano /usr/local/bin/crl_update.sh
   ```
   Füge hinzu:
   ```bash
   #!/bin/bash
   trap 'echo "CRL-Update unterbrochen"; exit 1' INT TERM
   cd /root/ca/intermediate
   openssl ca -config openssl.cnf -gencrl -out crl/intermediate.crl.pem
   cp crl/intermediate.crl.pem /root/ca/export/
   chmod 644 /root/ca/export/intermediate.crl.pem
   scp /root/ca/export/intermediate.crl.pem root@192.168.30.1:/tmp/
   echo "CRL aktualisiert und an OPNsense verteilt"
   trap - INT TERM
   ```
   Ausführbar machen:
   ```bash
   chmod +x /usr/local/bin/crl_update.sh
   ```

2. **Erweitere Backup-Skript**:
   ```bash
   nano /usr/local/bin/pki_backup.sh
   ```
   Aktualisiere:
   ```bash
   #!/bin/bash
   trap 'echo "Backup unterbrochen"; exit 1' INT TERM
   /usr/local/bin/crl_update.sh
   tar -czf /tmp/pki-backup-$(date +%Y-%m-%d).tar.gz /root/ca
   scp /tmp/pki-backup-$(date +%Y-%m-%d).tar.gz root@192.168.30.100:/mnt/tank/backups/pki/
   echo "PKI-Konfiguration und CRL gesichert auf TrueNAS"
   trap - INT TERM
   ```
   Ausführbar machen:
   ```bash
   chmod +x /usr/local/bin/pki_backup.sh
   ```

3. **Teste Skripte**:
   ```bash
   /usr/local/bin/crl_update.sh
   /usr/local/bin/pki_backup.sh
   ```
   - Erwartete Ausgabe: CRL wird aktualisiert, verteilt und gesichert.

4. **Automatisiere mit Cron**:
   ```bash
   nano /etc/crontab
   ```
   Füge hinzu:
   ```bash
   0 4 * * * root /usr/local/bin/pki_backup.sh >> /var/log/pki-backup.log 2>&1
   ```
   Speichere und beende.

**Reflexion**: Wie erleichtert die Automatisierung die CRL-Verwaltung? Überlege, wie ein HTTP-Server die CRL-Verteilung verbessern könnte.

## Tipps für den Erfolg
- **Sicherheit**:
  - Schütze private Schlüssel:
    ```bash
    chmod 400 /root/ca/intermediate/private/*.key.pem
    ```
  - Verwende starke Passwörter für die CA.
- **Fehlerbehebung**:
  - Prüfe CRL: `openssl crl -in /root/ca/intermediate/crl/intermediate.crl.pem -noout -text`.
  - Prüfe OPNsense-Logs: `VPN > IPsec > Log File`.
  - Prüfe Backup-Logs: `tail /var/log/pki-backup.log`.
- **Backup**:
  - Überprüfe Backups:
    ```bash
    ssh root@192.168.30.100 ls /mnt/tank/backups/pki/
    ```
- **Erweiterungen**:
  - Stelle die CRL über HTTP bereit:
    ```bash
    apt install -y nginx
    cp /root/ca/intermediate/crl/intermediate.crl.pem /var/www/html/
    ```
  - Konfiguriere OPNsense, um die CRL regelmäßig abzurufen (`System > Trust > CRLs > Auto-update`).

## Fazit
Du hast eine CRL für die Intermediate CA erstellt, ein Zertifikat widerrufen, die CRL in OPNsense integriert und die Verwaltung automatisiert. Die CRL erhöht die Sicherheit des IPsec-VPNs, indem sie widerrufene Zertifikate blockiert. Wiederhole die Tests, um die Stabilität zu prüfen, oder erweitere die PKI um weitere Funktionen (z. B. HTTP-Verteilung).

**Nächste Schritte**: Möchtest du eine Anleitung zur CRL-Verteilung über HTTP, Integration mit anderen Diensten (z. B. Papermerge), oder zu OpenVPN mit PKI?

**Quellen**:
- OpenSSL-Dokumentation: https://www.openssl.org/docs/
- OPNsense-Dokumentation: https://docs.opnsense.org/manual/vpnet.html
- Webquellen: https://jamielinux.com/docs/openssl-certificate-authority/, https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-a-certificate-authority-ca-on-debian-10
```