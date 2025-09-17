# Praxisorientierte Anleitung: Integration von TLS-Zertifikaten in Nginx auf Debian

## Einführung
Nginx ist ein leistungsstarker Open-Source-Webserver, der häufig für die Bereitstellung von Webanwendungen verwendet wird. Durch die Integration von TLS-Zertifikaten kann Nginx HTTPS aktivieren, um sichere, verschlüsselte Kommunikation zu gewährleisten. Diese Anleitung zeigt Ihnen, wie Sie TLS-Zertifikate (z. B. ein selbstsigniertes Zertifikat oder ein von einer CA signiertes Zertifikat) in Nginx auf einem Debian-System einrichten. Wir verwenden die Zertifikate aus der vorherigen OpenSSL-Anleitung (`ca.crt`, `myserver.key`, `myserver-san.crt`) und konfigurieren Nginx, um eine einfache Webseite über HTTPS bereitzustellen. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, einen sicheren Webserver einzurichten. Diese Anleitung ist ideal für Administratoren und Entwickler, die HTTPS für ihre Webanwendungen implementieren möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- OpenSSL installiert und TLS-Zertifikate verfügbar (z. B. in `~/tls-certs` aus der vorherigen Anleitung: `ca.crt`, `myserver.key`, `myserver-san.crt`)
- Mindestens 2 GB RAM und ausreichend Festplattenspeicher (mindestens 5 GB frei)
- Grundlegende Kenntnisse der Linux-Kommandozeile und Kryptographie
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie VS Code)

## Grundlegende Konzepte und Befehle für Nginx und TLS
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **TLS-Konzepte in Nginx**:
   - **TLS-Zertifikat**: Enthält den öffentlichen Schlüssel und Serverinformationen (z. B. `myserver-san.crt`)
   - **Privater Schlüssel**: Wird zum Entschlüsseln verwendet (z. B. `myserver.key`)
   - **CA-Zertifikat**: Validiert die Vertrauenskette (z. B. `ca.crt`)
   - **HTTPS-Konfiguration**: Aktiviert TLS in Nginx mit `ssl`-Direktiven
2. **Wichtige Nginx-Konfigurationsdateien**:
   - `/etc/nginx/nginx.conf`: Haupt-Konfigurationsdatei
   - `/etc/nginx/sites-available/`: Verzeichnis für virtuelle Hosts
   - `/etc/nginx/sites-enabled/`: Verzeichnis für aktivierte Konfigurationen
3. **Wichtige Befehle**:
   - `nginx -t`: Testet die Nginx-Konfiguration
   - `systemctl reload nginx`: Lädt die Nginx-Konfiguration neu
   - `openssl verify`: Überprüft Zertifikate

## Übungen zum Verinnerlichen

### Übung 1: Nginx installieren und eine einfache Webseite einrichten
**Ziel**: Lernen, wie man Nginx installiert und eine einfache HTTP-Webseite einrichtet, bevor TLS integriert wird.

1. **Schritt 1**: Installiere Nginx.
   ```bash
   sudo apt update
   sudo apt install -y nginx
   ```
2. **Schritt 2**: Starte Nginx und überprüfe den Status.
   ```bash
   sudo systemctl start nginx
   sudo systemctl enable nginx
   sudo systemctl status nginx
   ```
3. **Schritt 3**: Erstelle eine einfache Webseite.
   ```bash
   sudo mkdir -p /var/www/myserver/html
   sudo nano /var/www/myserver/html/index.html
   ```
   Füge folgenden Inhalt ein:
   ```html
   <!DOCTYPE html>
   <html>
   <head>
       <title>Mein Sicherer Server</title>
   </head>
   <body>
       <h1>Willkommen auf meinem sicheren Server!</h1>
   </body>
   </html>
   ```
4. **Schritt 4**: Konfiguriere einen virtuellen Host für HTTP.
   ```bash
   sudo nano /etc/nginx/sites-available/myserver
   ```
   Füge folgenden Inhalt ein:
   ```nginx
   server {
       listen 80;
       server_name myserver.local;

       root /var/www/myserver/html;
       index index.html;

       location / {
           try_files $uri $uri/ /index.html;
       }
   }
   ```
5. **Schritt 5**: Aktiviere den virtuellen Host und teste die Konfiguration.
   ```bash
   sudo ln -s /etc/nginx/sites-available/myserver /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl reload nginx
   ```
6. **Schritt 6**: Teste die Webseite.
   - Bearbeite `/etc/hosts`:
     ```bash
     sudo nano /etc/hosts
     ```
     Füge hinzu:
     ```
     127.0.0.1 myserver.local
     ```
   - Öffne `http://myserver.local` im Browser. Du solltest die Webseite sehen.

**Reflexion**: Warum ist die Trennung von `sites-available` und `sites-enabled` in Nginx nützlich, und wie bereitet dies die Integration von TLS vor?

### Übung 2: TLS-Zertifikate in Nginx integrieren
**Ziel**: Verstehen, wie man TLS-Zertifikate in Nginx einrichtet, um HTTPS zu aktivieren.

1. **Schritt 1**: Kopiere die Zertifikate aus `~/tls-certs` an einen sicheren Ort.
   ```bash
   sudo mkdir -p /etc/nginx/ssl
   sudo cp ~/tls-certs/myserver-san.crt /etc/nginx/ssl/
   sudo cp ~/tls-certs/myserver.key /etc/nginx/ssl/
   sudo cp ~/tls-certs/ca.crt /etc/nginx/ssl/
   ```
2. **Schritt 2**: Aktualisiere die Nginx-Konfiguration für HTTPS.
   ```bash
   sudo nano /etc/nginx/sites-available/myserver
   ```
   Ersetze den Inhalt durch:
   ```nginx
   server {
       listen 80;
       server_name myserver.local;
       return 301 https://$server_name$request_uri; # Redirect HTTP zu HTTPS
   }

   server {
       listen 443 ssl;
       server_name myserver.local;

       ssl_certificate /etc/nginx/ssl/myserver-san.crt;
       ssl_certificate_key /etc/nginx/ssl/myserver.key;

       root /var/www/myserver/html;
       index index.html;

       location / {
           try_files $uri $uri/ /index.html;
       }
   }
   ```
3. **Schritt 3**: Teste und lade die Konfiguration.
   ```bash
   sudo nginx -t
   sudo systemctl reload nginx
   ```
4. **Schritt 4**: Importiere das CA-Zertifikat in den Browser.
   - Kopiere `ca.crt` auf deinen lokalen Rechner (z. B. per `scp` oder manuell).
   - Importiere `ca.crt` in den Browser (z. B. Firefox: Einstellungen > Datenschutz & Sicherheit > Zertifikate > Zertifikat importieren).
5. **Schritt 5**: Teste die HTTPS-Webseite.
   - Öffne `https://myserver.local` im Browser. Du solltest die Webseite ohne Warnung sehen, wenn das CA-Zertifikat importiert ist.

**Reflexion**: Warum ist die Umleitung von HTTP zu HTTPS wichtig, und wie verbessert die Verwendung eines SAN-Zertifikats die Flexibilität?

### Übung 3: TLS-Sicherheit optimieren und Zertifikat überprüfen
**Ziel**: Lernen, wie man die TLS-Konfiguration in Nginx optimiert und Zertifikate programmgesteuert prüft.

1. **Schritt 1**: Optimiere die TLS-Konfiguration für bessere Sicherheit.
   ```bash
   sudo nano /etc/nginx/sites-available/myserver
   ```
   Erweitere den HTTPS-Block um Sicherheitsdirektiven:
   ```nginx
   server {
       listen 80;
       server_name myserver.local;
       return 301 https://$server_name$request_uri;
   }

   server {
       listen 443 ssl;
       server_name myserver.local;

       ssl_certificate /etc/nginx/ssl/myserver-san.crt;
       ssl_certificate_key /etc/nginx/ssl/myserver.key;

       ssl_protocols TLSv1.2 TLSv1.3;
       ssl_prefer_server_ciphers on;
       ssl_ciphers EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH;
       ssl_session_cache shared:SSL:10m;
       ssl_session_timeout 1d;

       root /var/www/myserver/html;
       index index.html;

       location / {
           try_files $uri $uri/ /index.html;
       }
   }
   ```
2. **Schritt 2**: Teste und lade die Konfiguration.
   ```bash
   sudo nginx -t
   sudo systemctl reload nginx
   ```
3. **Schritt 3**: Erstelle ein Python-Skript, um das Zertifikat zu prüfen.
   ```bash
   nano check_cert.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import ssl
   import socket
   from OpenSSL import SSL
   from datetime import datetime

   hostname = 'myserver.local'
   context = SSL.Context(SSL.TLS_CLIENT_METHOD)
   conn = SSL.Connection(context, socket.socket(socket.AF_INET, socket.SOCK_STREAM))
   conn.connect((hostname, 443))
   conn.do_handshake()
   cert = conn.get_peer_certificate()
   print(f"Aussteller: {cert.get_issuer().CN}")
   print(f"Gültig bis: {datetime.strptime(cert.get_notAfter().decode(), '%Y%m%d%H%M%SZ')}")
   conn.close()
   ```
4. **Schritt 4**: Installiere die Python-Bibliothek `pyOpenSSL` und führe das Skript aus.
   ```bash
   pip3 install pyOpenSSL
   python3 check_cert.py
   ```
   Die Ausgabe zeigt den Aussteller (`MyCA Root`) und das Ablaufdatum des Zertifikats.

**Reflexion**: Wie verbessern TLS-Sicherheitsdirektiven die Sicherheit, und warum ist die programmgesteuerte Zertifikatsprüfung nützlich?

## Tipps für den Erfolg
- Überprüfe Nginx-Logs in `/var/log/nginx/` bei Problemen.
- Sichere private Schlüssel (`myserver.key`) mit eingeschränkten Berechtigungen (`chmod 600`).
- Verwende `openssl s_client -connect myserver.local:443` für TLS-Debugging.
- Teste die TLS-Konfiguration mit Tools wie `ssllabs.com/ssltest`.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie TLS-Zertifikate in Nginx auf einem Debian-System integrieren, HTTPS aktivieren und die TLS-Konfiguration optimieren. Durch die Übungen haben Sie praktische Erfahrung mit der Einrichtung eines sicheren Webservers und der programmgesteuerten Zertifikatsprüfung gesammelt. Diese Fähigkeiten sind essenziell für die Absicherung von Webanwendungen. Üben Sie weiter, um komplexere Szenarien wie Load-Balancing oder Client-Zertifikate zu meistern!

**Nächste Schritte**:
- Erkunden Sie Let’s Encrypt mit Certbot für kostenlose, vertrauenswürdige Zertifikate.
- Konfigurieren Sie Nginx für Load-Balancing mit TLS.
- Integrieren Sie Client-Zertifikate für zusätzliche Sicherheit.

**Quellen**:
- Nginx-Dokumentation: https://nginx.org/en/docs/
- OpenSSL-Dokumentation: https://www.openssl.org/docs/
- DigitalOcean Nginx-TLS-Tutorial: https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-ssl-on-ubuntu