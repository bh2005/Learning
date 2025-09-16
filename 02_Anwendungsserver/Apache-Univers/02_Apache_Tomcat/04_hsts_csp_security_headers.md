# Praxisorientierte Anleitung: Kombination von HSTS mit Content Security Policy (CSP) und anderen Sicherheits-Headern in Apache auf Debian

## Einführung
Die Kombination von HTTP Strict Transport Security (HSTS) mit Content Security Policy (CSP) und anderen Sicherheits-Headern wie `X-Content-Type-Options` und `X-Frame-Options` erhöht die Sicherheit von Webseiten, indem sie Angriffe wie Man-in-the-Middle, Cross-Site-Scripting (XSS) und Clickjacking verhindert. Diese Anleitung zeigt Ihnen, wie Sie diese Sicherheits-Header in einer Apache-Konfiguration auf einem Debian-System implementieren. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, eine sichere HTTPS-Website (z. B. `tomcat.hostname`) mit robusten Sicherheits-Headern auszustatten. Diese Anleitung ist ideal für Administratoren und Entwickler, die die Sicherheit ihrer Webanwendungen maximieren möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit installiertem Apache HTTP Server (`apache2`), aktiviertem `mod_ssl` und `mod_headers`
- Root- oder Sudo-Zugriff
- Eine funktionierende HTTPS-Website mit einem Let’s Encrypt-Zertifikat (z. B. für `tomcat.hostname`)
- Grundlegende Kenntnisse der Linux-Kommandozeile und von Apache-Konfiguration
- Eine bestehende Apache-Konfiguration (z. B. aus der vorherigen Tomcat- oder HSTS-Anleitung)

## Grundlegende Sicherheits-Header-Konzepte und Direktiven
Hier sind die wichtigsten Konzepte und Direktiven, die wir behandeln:

1. **HTTP Strict Transport Security (HSTS)**:
   - `Strict-Transport-Security`: Erzwingt HTTPS-Verbindungen
   - Parameter: `max-age`, `includeSubDomains`, `preload`
2. **Content Security Policy (CSP)**:
   - `Content-Security-Policy`: Steuert, welche Ressourcen (z. B. Skripte, Bilder) geladen werden dürfen
   - Direktiven: `default-src`, `script-src`, `style-src`, etc.
3. **Weitere Sicherheits-Header**:
   - `X-Content-Type-Options: nosniff`: Verhindert MIME-Type-Sniffing
   - `X-Frame-Options: DENY`: Verhindert Clickjacking durch iFrames
   - `mod_headers`: Ermöglicht das Setzen dieser Header in Apache

## Übungen zum Verinnerlichen

### Übung 1: HSTS und grundlegende Sicherheits-Header einrichten
**Ziel**: Lernen, wie man HSTS, `X-Content-Type-Options` und `X-Frame-Options` in einer Apache-Konfiguration implementiert.

1. **Schritt 1**: Stelle sicher, dass das `mod_headers`-Modul aktiviert ist.
   ```bash
   sudo a2enmod headers
   sudo systemctl restart apache2
   ```
2. **Schritt 2**: Füge HSTS und weitere Sicherheits-Header zur bestehenden HTTPS-Konfiguration hinzu.
   ```bash
   sudo nano /etc/apache2/sites-available/tomcat.conf
   ```
   Aktualisiere den `<VirtualHost *:443>`-Block (z. B. aus der vorherigen Tomcat-Anleitung) wie folgt:
   ```apache
   <VirtualHost *:443>
       ServerName tomcat.hostname
       ProxyPreserveHost On
       ProxyPass / http://localhost:8080/
       ProxyPassReverse / http://localhost:8080/
       SSLEngine On
       SSLCertificateFile /etc/letsencrypt/live/tomcat.hostname/fullchain.pem
       SSLCertificateKeyFile /etc/letsencrypt/live/tomcat.hostname/privkey.pem
       Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains"
       Header always set X-Content-Type-Options "nosniff"
       Header always set X-Frame-Options "DENY"
   </VirtualHost>
   ```
3. **Schritt 3**: Starte Apache neu und überprüfe die Header mit `curl`.
   ```bash
   sudo systemctl restart apache2
   curl -s -D- https://tomcat.hostname | grep -iE 'Strict-Transport-Security|X-Content-Type-Options|X-Frame-Options'
   ```

**Reflexion**: Wie schützen `X-Content-Type-Options` und `X-Frame-Options` vor spezifischen Angriffen wie MIME-Type-Sniffing oder Clickjacking?

### Übung 2: Content Security Policy (CSP) implementieren
**Ziel**: Verstehen, wie man eine CSP-Richtlinie hinzufügt, um die Quellen für Skripte und andere Ressourcen zu beschränken.

1. **Schritt 1**: Füge eine einfache CSP-Richtlinie zur Apache-Konfiguration hinzu.
   ```bash
   sudo nano /etc/apache2/sites-available/tomcat.conf
   ```
   Füge im `<VirtualHost *:443>`-Block die folgende Zeile hinzu:
   ```apache
   Header always set Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self';"
   ```
   Der aktualisierte `<VirtualHost *:443>`-Block könnte wie folgt aussehen:
   ```apache
   <VirtualHost *:443>
       ServerName tomcat.hostname
       ProxyPreserveHost On
       ProxyPass / http://localhost:8080/
       ProxyPassReverse / http://localhost:8080/
       SSLEngine On
       SSLCertificateFile /etc/letsencrypt/live/tomcat.hostname/fullchain.pem
       SSLCertificateKeyFile /etc/letsencrypt/live/tomcat.hostname/privkey.pem
       Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains"
       Header always set X-Content-Type-Options "nosniff"
       Header always set X-Frame-Options "DENY"
       Header always set Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self';"
   </VirtualHost>
   ```
2. **Schritt 2**: Starte Apache neu und teste die CSP-Richtlinie.
   ```bash
   sudo systemctl restart apache2
   curl -s -D- https://tomcat.hostname | grep -i Content-Security-Policy
   ```
3. **Schritt 3**: Öffne `https://tomcat.hostname` im Browser, öffne die Entwicklerkonsole (F12) und überprüfe, ob externe Ressourcen blockiert werden.

**Reflexion**: Wie kann eine restriktive CSP-Richtlinie wie `default-src 'self'` XSS-Angriffe verhindern, und welche Herausforderungen könnten bei ihrer Implementierung auftreten?

### Übung 3: CSP für eine spezifische Anwendung anpassen
**Ziel**: Lernen, wie man die CSP-Richtlinie für eine Tomcat-Anwendung (z. B. `/sample`) anpasst, um externe Ressourcen zuzulassen.

1. **Schritt 1**: Analysiere die Anforderungen der Tomcat-Beispielanwendung (`/sample`). Angenommen, sie benötigt Skripte von einer externen Quelle wie `https://code.jquery.com`.
2. **Schritt 2**: Passe die CSP-Richtlinie an, um jQuery zuzulassen.
   ```bash
   sudo nano /etc/apache2/sites-available/tomcat.conf
   ```
   Ändere die CSP-Zeile im `<VirtualHost *:443>`-Block zu:
   ```apache
   Header always set Content-Security-Policy "default-src 'self'; script-src 'self' https://code.jquery.com; style-src 'self'; img-src 'self';"
   ```
3. **Schritt 3**: Starte Apache neu und teste die Anwendung unter `https://tomcat.hostname/sample`. Überprüfe in der Browser-Entwicklerkonsole (F12), ob Skripte korrekt geladen werden.
   ```bash
   sudo systemctl restart apache2
   ```

**Reflexion**: Warum ist es wichtig, CSP-Richtlinien spezifisch an die Anforderungen einer Anwendung anzupassen, und wie kann man Fehler durch zu restriktive Richtlinien debuggen?

## Tipps für den Erfolg
- Teste CSP-Richtlinien zunächst mit `Content-Security-Policy-Report-Only`, um Probleme ohne sofortige Blockierung zu identifizieren.
- Verwende kurze `max-age`-Werte für HSTS während der Testphase (z. B. 3600 Sekunden), um Änderungen flexibel zu halten.
- Überprüfe die Apache-Logs (`/var/log/apache2/error.log`) und die Browser-Entwicklerkonsole für CSP-Fehlermeldungen.
- Stelle sicher, dass alle Ressourcen über HTTPS geladen werden, um Mixed-Content-Fehler zu vermeiden.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie HSTS, CSP, `X-Content-Type-Options` und `X-Frame-Options` in einer Apache-Konfiguration kombinieren, um die Sicherheit einer HTTPS-Website zu maximieren. Durch die Übungen haben Sie praktische Erfahrung mit dem `mod_headers`-Modul und der Konfiguration sicherer Header gesammelt. Diese Fähigkeiten sind essenziell für die Absicherung moderner Webanwendungen gegen gängige Angriffe. Üben Sie weiter, um komplexere CSP-Richtlinien oder zusätzliche Sicherheitsmechanismen zu implementieren!

**Nächste Schritte**:
- Erkunden Sie weitere Sicherheits-Header wie `Referrer-Policy` oder `Permissions-Policy`.
- Implementieren Sie einen Berichtsserver für CSP-Verletzungen (`report-uri`).
- Lesen Sie die offizielle CSP-Dokumentation für fortgeschrittene Direktiven.

**Quellen**:
- Offizielle Apache mod_headers-Dokumentation: https://httpd.apache.org/docs/current/mod/mod_headers.html
- HSTS-Spezifikation: https://tools.ietf.org/html/rfc6797
- Content Security Policy (CSP) Dokumentation: https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
- OWASP Sicherheits-Header: https://owasp.org/www-project-secure-headers/