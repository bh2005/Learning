# Praxisorientierte Anleitung: Fortgeschrittene OpenSSL-Features – Erstellung von TLS-Zertifikaten auf Debian

## Einführung
OpenSSL ist ein leistungsstarkes Open-Source-Tool für kryptographische Operationen, einschließlich der Erstellung und Verwaltung von TLS-Zertifikaten, die für sichere Kommunikation (z. B. HTTPS) unerlässlich sind. TLS-Zertifikate gewährleisten Vertraulichkeit, Integrität und Authentizität von Daten. Diese Anleitung zeigt Ihnen, wie Sie OpenSSL auf einem Debian-System verwenden, um eine selbstsignierte Zertifizierungsstelle (CA) zu erstellen, Serverzertifikate zu generieren und zu signieren sowie Zertifikate zu verwalten. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, TLS-Zertifikate für Webanwendungen oder andere sichere Kommunikationsszenarien einzurichten. Diese Anleitung ist ideal für Administratoren und Entwickler, die TLS-Sicherheit in ihren Projekten implementieren möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- OpenSSL installiert (z. B. `openssl` Version 1.1.1 oder höher)
- Mindestens 2 GB RAM und ausreichend Festplattenspeicher (mindestens 5 GB frei)
- Grundlegende Kenntnisse der Linux-Kommandozeile und Kryptographie
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie VS Code)

## Grundlegende OpenSSL-TLS-Konzepte und Befehle
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **TLS-Konzepte**:
   - **Zertifizierungsstelle (CA)**: Eine Entität, die Zertifikate ausstellt und signiert
   - **Selbstsigniertes Zertifikat**: Ein Zertifikat, das von seinem eigenen Schlüssel signiert ist
   - **Certificate Signing Request (CSR)**: Anfrage an eine CA, ein Zertifikat zu signieren
   - **X.509-Zertifikat**: Standardformat für TLS-Zertifikate
2. **Wichtige OpenSSL-Befehle**:
   - `openssl genrsa`: Generiert einen privaten RSA-Schlüssel
   - `openssl req`: Erstellt Zertifikate oder CSRs
   - `openssl x509`: Signiert Zertifikate
   - `openssl verify`: Überprüft Zertifikate
3. **Wichtige Dateien**:
   - `*.key`: Privater Schlüssel
   - `*.crt`: Zertifikat
   - `*.csr`: Certificate Signing Request

## Übungen zum Verinnerlichen

### Übung 1: Selbstsigniertes TLS-Zertifikat erstellen
**Ziel**: Lernen, wie man ein selbstsigniertes TLS-Zertifikat erstellt, das für Testumgebungen geeignet ist.

1. **Schritt 1**: Stelle sicher, dass OpenSSL installiert ist.
   ```bash
   sudo apt update
   sudo apt install -y openssl
   openssl version
   ```
2. **Schritt 2**: Erstelle einen privaten Schlüssel und ein selbstsigniertes Zertifikat in einem Schritt.
   ```bash
   mkdir ~/tls-certs
   cd ~/tls-certs
   openssl req -x509 -newkey rsa:2048 -nodes -days 365 -keyout server.key -out server.crt
   ```
   - `-x509`: Erstellt ein selbstsigniertes Zertifikat
   - `-newkey rsa:2048`: Generiert einen 2048-Bit-RSA-Schlüssel
   - `-nodes`: Keine Passphrase für den Schlüssel
   - `-days 365`: Gültigkeit von 365 Tagen
   - Gib bei der Eingabeaufforderung folgende Details ein:
     - Country: `DE`
     - Organization: `MyOrg`
     - Common Name (CN): `localhost`
     - Andere Felder können leer bleiben
3. **Schritt 3**: Überprüfe das Zertifikat.
   ```bash
   openssl x509 -in server.crt -text -noout
   ```
   Die Ausgabe zeigt Details wie den Aussteller (`Issuer`), die Gültigkeit und den Common Name (`CN=localhost`).
4. **Schritt 4**: Teste das Zertifikat mit einem einfachen HTTPS-Server (optional, erfordert Python).
   ```bash
   python3 -m http.server --bind localhost 8443 --certfile server.crt --keyfile server.key
   ```
   Öffne `https://localhost:8443` im Browser (akzeptiere die Warnung für das selbstsignierte Zertifikat).

**Reflexion**: Warum sind selbstsignierte Zertifikate für Produktionsumgebungen ungeeignet, und welche Rolle spielt der Common Name (CN)?

### Übung 2: Eigene Zertifizierungsstelle (CA) erstellen
**Ziel**: Verstehen, wie man eine eigene CA erstellt, um Zertifikate für Server zu signieren.

1. **Schritt 1**: Erstelle einen privaten CA-Schlüssel und ein CA-Zertifikat.
   ```bash
   cd ~/tls-certs
   openssl genrsa -out ca.key 2048
   openssl req -x509 -new -key ca.key -days 3650 -out ca.crt
   ```
   - Gib für die CA Details ein:
     - Country: `DE`
     - Organization: `MyCA`
     - Common Name: `MyCA Root`
2. **Schritt 2**: Erstelle einen privaten Schlüssel und eine CSR für einen Server.
   ```bash
   openssl genrsa -out myserver.key 2048
   openssl req -new -key myserver.key -out myserver.csr
   ```
   - Gib für die CSR Details ein:
     - Country: `DE`
     - Organization: `MyOrg`
     - Common Name: `myserver.local`
3. **Schritt 3**: Signiere die CSR mit der CA, um ein Serverzertifikat zu erstellen.
   ```bash
   openssl x509 -req -in myserver.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days 365 -out myserver.crt
   ```
4. **Schritt 4**: Überprüfe das signierte Zertifikat.
   ```bash
   openssl verify -CAfile ca.crt myserver.crt
   ```
   Die Ausgabe sollte sein: `myserver.crt: OK`.

**Reflexion**: Wie gewährleistet eine CA die Vertrauenswürdigkeit eines Zertifikats, und warum ist die CA-Zertifikatverteilung kritisch?

### Übung 3: TLS-Zertifikat mit SAN (Subject Alternative Name) und Python-Integration
**Ziel**: Lernen, wie man ein Zertifikat mit SAN für mehrere Domänen erstellt und in einer Python-Anwendung verwendet.

1. **Schritt 1**: Erstelle eine OpenSSL-Konfigurationsdatei für SAN.
   ```bash
   nano ~/tls-certs/openssl-san.cnf
   ```
   Füge folgenden Inhalt ein:
   ```ini
   [req]
   distinguished_name = req_distinguished_name
   x509_extensions = v3_req
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
2. **Schritt 2**: Erstelle ein Zertifikat mit SAN, signiert von der CA.
   ```bash
   openssl req -new -key myserver.key -out myserver-san.csr -config openssl-san.cnf
   openssl x509 -req -in myserver-san.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days 365 -out myserver-san.crt -extfile openssl-san.cnf -extensions v3_req
   ```
3. **Schritt 3**: Erstelle ein Python-Skript, um das Zertifikat in einem HTTPS-Server zu verwenden.
   ```bash
   nano https_server.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import http.server
   import ssl
   import os

   server_address = ('localhost', 8443)
   httpd = http.server.HTTPServer(server_address, http.server.SimpleHTTPRequestHandler)
   httpd.socket = ssl.wrap_socket(httpd.socket, 
                                  certfile=os.path.expanduser('~/tls-certs/myserver-san.crt'),
                                  keyfile=os.path.expanduser('~/tls-certs/myserver.key'),
                                  server_side=True)
   print("HTTPS-Server läuft auf https://localhost:8443")
   httpd.serve_forever()
   ```
4. **Schritt 4**: Führe den Server aus und teste ihn.
   ```bash
   python3 https_server.py
   ```
   Öffne `https://localhost:8443` im Browser. Importiere `ca.crt` in den Browser, um die Warnung zu vermeiden.

**Reflexion**: Warum sind SAN-Zertifikate für moderne Anwendungen wichtig, und wie kann Python die Arbeit mit TLS-Zertifikaten vereinfachen?

## Tipps für den Erfolg
- Überprüfe Zertifikate mit `openssl x509 -in <file> -text -noout` für Debugging.
- Sichere private Schlüssel (`*.key`) und teile sie niemals.
- Verwende `openssl verify`, um die Vertrauenskette zu prüfen.
- Teste Zertifikate in einer Testumgebung, bevor du sie in Produktion einsetzt.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie fortgeschrittene OpenSSL-Features nutzen, um selbstsignierte TLS-Zertifikate, eine eigene CA und SAN-Zertifikate zu erstellen. Durch die Übungen haben Sie praktische Erfahrung mit der Erstellung, Signierung und Verwendung von Zertifikaten in einer Python-Anwendung gesammelt. Diese Fähigkeiten sind essenziell für die Absicherung von Kommunikation in Webanwendungen. Üben Sie weiter, um komplexere Szenarien wie Zertifikatketten oder CRLs (Certificate Revocation Lists) zu meistern!

**Nächste Schritte**:
- Integrieren Sie TLS-Zertifikate in einen Webserver wie Nginx oder Apache.
- Erkunden Sie OpenSSL für die Erstellung von Client-Zertifikaten.
- Automatisieren Sie die Zertifikatserstellung mit Skripten oder Tools wie Certbot.

**Quellen**:
- OpenSSL-Dokumentation: https://www.openssl.org/docs/
- OpenSSL TLS-Tutorial: https://www.openssl.org/docs/man1.1.1/man1/
- DigitalOcean TLS-Tutorial: https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-apache-in-ubuntu