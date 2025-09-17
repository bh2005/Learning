# Praxisorientierte Anleitung: Integration von TLS-Zertifikaten mit Zwischenzertifikaten in Nginx auf Debian

## Einführung
Zwischenzertifikate (Intermediate Certificates) sind ein wichtiger Bestandteil der TLS-Vertrauenskette, insbesondere in Szenarien mit Proxies oder Firewalls, die ihre eigenen Zwischen-CAs verwenden, um Zertifikate zu signieren. Eine vollständige Vertrauenskette besteht aus dem Serverzertifikat, einem oder mehreren Zwischenzertifikaten und dem Root-Zertifikat. Diese Anleitung zeigt Ihnen, wie Sie mit OpenSSL auf einem Debian-System eine eigene Root-CA und eine Zwischen-CA erstellen, ein Serverzertifikat signieren und die Vertrauenskette in Nginx integrieren, um HTTPS für einen Webserver zu aktivieren. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, TLS-Zertifikate mit Zwischenzertifikaten korrekt zu konfigurieren, wie es bei Proxies oder Firewalls erforderlich sein kann. Diese Anleitung ist ideal für Administratoren und Entwickler, die sichere Kommunikation mit komplexen Vertrauensketten einrichten möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- OpenSSL und Nginx installiert (z. B. aus den vorherigen Anleitungen)
- TLS-Zertifikate aus der vorherigen Anleitung verfügbar (z. B. in `~/tls-certs`: `ca.crt`, `myserver.key`, `myserver-san.crt`)
- Mindestens 2 GB RAM und ausreichend Festplattenspeicher (mindestens 5 GB frei)
- Grundlegende Kenntnisse der Linux-Kommandozeile, Kryptographie und Nginx
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie VS Code)

## Grundlegende Konzepte und Befehle für Zwischenzertifikate
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **TLS-Konzepte mit Zwischenzertifikaten**:
   - **Root-CA**: Die oberste Zertifizierungsstelle, die Zwischenzertifikate signiert
   - **Zwischen-CA (Intermediate CA)**: Signiert Serverzertifikate und wird von der Root-CA signiert
   - **Vertrauenskette**: Kombination aus Serverzertifikat, Zwischenzertifikat(en) und Root-Zertifikat
   - **Zertifikatbündel**: Eine Datei, die Server- und Zwischenzertifikate für Nginx enthält
2. **Wichtige OpenSSL-Befehle**:
   - `openssl genrsa`: Generiert private Schlüssel
   - `openssl req`: Erstellt Zertifikate oder Certificate Signing Requests (CSRs)
   - `openssl x509`: Signiert Zertifikate
   - `openssl ca`: Verwaltet eine CA für das Signieren von CSRs
3. **Wichtige Nginx-Konfigurationsdirektiven**:
   - `ssl_certificate`: Gibt die Datei mit Server- und Zwischenzertifikaten an
   - `ssl_certificate_key`: Gibt den privaten Schlüssel an
   - `ssl_trusted_certificate`: Gibt das Root-Zertifikat für die Vertrauenskette an

## Übungen zum Verinnerlichen

### Übung 1: Root-CA und Zwischen-CA erstellen
**Ziel**: Lernen, wie man eine Root-CA und eine Zwischen-CA erstellt, um eine Vertrauenskette aufzubauen.

1. **Schritt 1**: Erstelle ein Verzeichnis für die CA-Struktur.
   ```bash
   mkdir -p ~/ca/root ~/ca/intermediate
   cd ~/ca
   ```
2. **Schritt 2**: Erstelle die Root-CA (Schlüssel und Zertifikat).
   ```bash
   openssl genrsa -out root/ca.key 4096
   openssl req -x509 -new -key root/ca.key -days 3650 -out root/ca.crt
   ```
   - Gib für die Root-CA Details ein:
     - Country: `DE`
     - Organization: `MyRootCA`
     - Common Name: `MyRootCA`
3. **Schritt 3**: Erstelle die Zwischen-CA (Schlüssel und CSR).
   ```bash
   openssl genrsa -out intermediate/intermediate.key 2048
   openssl req -new -key intermediate/intermediate.key -out intermediate/intermediate.csr
   ```
   - Gib für die Zwischen-CA Details ein:
     - Country: `DE`
     - Organization: `MyIntermediateCA`
     - Common Name: `MyIntermediateCA`
4. **Schritt 4**: Signiere die Zwischen-CA mit der Root-CA.
   ```bash
   nano intermediate/openssl.cnf
   ```
   Füge eine Konfigurationsdatei für die CA ein:
   ```ini
   [ ca ]
   default_ca = CA_default

   [ CA_default ]
   dir = .
   database = $dir/index.txt
   serial = $dir/serial
   private_key = $dir/../root/ca.key
   certificate = $dir/../root/ca.crt
   new_certs_dir = $dir/certs
   default_md = sha256
   policy = policy_any
   default_days = 365

   [ policy_any ]
   countryName = match
   organizationName = match
   commonName = supplied
   ```
   Initialisiere die CA-Datenbank:
   ```bash
   mkdir intermediate/certs
   touch intermediate/index.txt
   echo 1000 > intermediate/serial
   ```
   Signiere die Zwischen-CA:
   ```bash
   openssl ca -config intermediate/openssl.cnf -extensions v3_ca -in intermediate/intermediate.csr -out intermediate/intermediate.crt
   ```

**Reflexion**: Warum ist die Trennung von Root- und Zwischen-CA wichtig, und wie schützt sie die Sicherheit der Vertrauenskette?

### Übung 2: Serverzertifikat mit Zwischen-CA signieren und Nginx konfigurieren
**Ziel**: Verstehen, wie man ein Serverzertifikat mit der Zwischen-CA signiert und in Nginx integriert.

1. **Schritt 1**: Erstelle einen privaten Schlüssel und eine CSR für den Server.
   ```bash
   cd ~/ca
   openssl genrsa -out intermediate/myserver.key 2048
   nano intermediate/openssl-san.cnf
   ```
   Füge für SAN (Subject Alternative Name) ein:
   ```ini
   [req]
   distinguished_name = req_distinguished_name
   req_extensions = v3_req
   prompt = no

   [req_distinguished_name]
   C = DE
   O = MyOrg
   CN = myserver.local

   [v3_req]
   keyUsage = keyEncipherment, dataEncipherment
   extendedKeyUsage = serverAuth
   subjectAltName = @alt_names

   [alt_names]
   DNS.1 = myserver.local
   DNS.2 = localhost
   IP.1 = 127.0.0.1
   ```
   Erstelle die CSR:
   ```bash
   openssl req -new -key intermediate/myserver.key -out intermediate/myserver.csr -config intermediate/openssl-san.cnf
   ```
2. **Schritt 2**: Signiere die CSR mit der Zwischen-CA.
   ```bash
   openssl ca -config intermediate/openssl.cnf -extensions v3_req -in intermediate/myserver.csr -out intermediate/myserver.crt
   ```
3. **Schritt 3**: Erstelle ein Zertifikatbündel für Nginx.
   ```bash
   cat intermediate/myserver.crt intermediate/intermediate.crt > intermediate/myserver-bundle.crt
   ```
4. **Schritt 4**: Kopiere die Zertifikate in Nginx.
   ```bash
   sudo mkdir -p /etc/nginx/ssl
   sudo cp intermediate/myserver.key /etc/nginx/ssl/
   sudo cp intermediate/myserver-bundle.crt /etc/nginx/ssl/
   sudo cp root/ca.crt /etc/nginx/ssl/
   ```
5. **Schritt 5**: Konfiguriere Nginx für HTTPS mit Zwischenzertifikaten.
   ```bash
   sudo nano /etc/nginx/sites-available/myserver
   ```
   Füge folgenden Inhalt ein:
   ```nginx
   server {
       listen 80;
       server_name myserver.local;
       return 301 https://$server_name$request_uri;
   }

   server {
       listen 443 ssl;
       server_name myserver.local;

       ssl_certificate /etc/nginx/ssl/myserver-bundle.crt;
       ssl_certificate_key /etc/nginx/ssl/myserver.key;
       ssl_trusted_certificate /etc/nginx/ssl/ca.crt;

       ssl_protocols TLSv1.2 TLSv1.3;
       ssl_prefer_server_ciphers on;
       ssl_ciphers EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH;

       root /var/www/myserver/html;
       index index.html;

       location / {
           try_files $uri $uri/ /index.html;
       }
   }
   ```
   Stelle sicher, dass die Webseite existiert:
   ```bash
   sudo mkdir -p /var/www/myserver/html
   echo "<h1>Sicherer Server mit Zwischenzertifikat</h1>" | sudo tee /var/www/myserver/html/index.html
   ```
6. **Schritt 6**: Aktiviere die Konfiguration und teste.
   ```bash
   sudo ln -s /etc/nginx/sites-available/myserver /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl reload nginx
   ```
   Bearbeite `/etc/hosts`:
   ```bash
   sudo nano /etc/hosts
   ```
   Füge hinzu:
   ```
   127.0.0.1 myserver.local
   ```
   Importiere `ca.crt` in den Browser und öffne `https://myserver.local`.

**Reflexion**: Warum ist das Zertifikatbündel (`myserver-bundle.crt`) notwendig, und wie simuliert diese Konfiguration einen Proxy oder eine Firewall?

### Übung 3: Vertrauenskette testen und debuggen
**Ziel**: Lernen, wie man die Vertrauenskette mit OpenSSL und Python überprüft.

1. **Schritt 1**: Überprüfe die Vertrauenskette mit OpenSSL.
   ```bash
   openssl verify -CAfile root/ca.crt -untrusted intermediate/intermediate.crt intermediate/myserver.crt
   ```
   Die Ausgabe sollte sein: `intermediate/myserver.crt: OK`.
2. **Schritt 2**: Erstelle ein Python-Skript, um die Vertrauenskette zu prüfen.
   ```bash
   nano check_cert_chain.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import ssl
   import socket
   from OpenSSL import SSL

   hostname = 'myserver.local'
   context = SSL.Context(SSL.TLS_CLIENT_METHOD)
   context.load_verify_locations(cafile='/home/user/ca/root/ca.crt', capath=None)
   conn = SSL.Connection(context, socket.socket(socket.AF_INET, socket.SOCK_STREAM))
   conn.connect((hostname, 443))
   conn.do_handshake()
   cert_chain = conn.get_peer_cert_chain()
   for cert in cert_chain:
       print(f"Aussteller: {cert.get_issuer().CN}, Subjekt: {cert.get_subject().CN}")
   conn.close()
   ```
3. **Schritt 3**: Installiere die Python-Bibliothek `pyOpenSSL` und führe das Skript aus.
   ```bash
   pip3 install pyOpenSSL
   python3 check_cert_chain.py
   ```
   Die Ausgabe zeigt die Vertrauenskette, z. B.:
   ```
   Aussteller: MyRootCA, Subjekt: MyIntermediateCA
   Aussteller: MyIntermediateCA, Subjekt: myserver.local
   ```

**Reflexion**: Wie hilft die programmgesteuerte Überprüfung der Vertrauenskette bei der Fehlersuche, und warum ist dies in Proxy-Szenarien wichtig?

## Tipps für den Erfolg
- Überprüfe Nginx-Logs in `/var/log/nginx/` und OpenSSL-Ausgaben bei Problemen.
- Sichere private Schlüssel (`chmod 600 /etc/nginx/ssl/myserver.key`).
- Verwende `openssl s_client -connect myserver.local:443 -CAfile ~/ca/root/ca.crt` für TLS-Debugging.
- Teste die Vertrauenskette mit Tools wie `ssllabs.com/ssltest`.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie eine Root-CA und eine Zwischen-CA erstellen, ein Serverzertifikat signieren und die Vertrauenskette in Nginx integrieren. Durch die Übungen haben Sie praktische Erfahrung mit Zwischenzertifikaten, wie sie in Proxy- oder Firewall-Szenarien verwendet werden, und der programmgesteuerten Überprüfung gesammelt. Diese Fähigkeiten sind essenziell für die Absicherung komplexer Systeme. Üben Sie weiter, um Szenarien wie Zertifikatrotation oder CRLs zu meistern!

**Nächste Schritte**:
- Implementieren Sie Zertifikatrotation mit automatisierten Skripten.
- Erkunden Sie Client-Zertifikate für Proxy-Authentifizierung.
- Verwenden Sie Let’s Encrypt für echte Zwischenzertifikate in Produktion.

**Quellen**:
- Nginx-Dokumentation: https://nginx.org/en/docs/
- OpenSSL-Dokumentation: https://www.openssl.org/docs/
- DigitalOcean Nginx-TLS-Tutorial: https://www.digitalocean.com/community/tutorials/how-to-create-a-ssl-certificate-on-nginx-for-ubuntu