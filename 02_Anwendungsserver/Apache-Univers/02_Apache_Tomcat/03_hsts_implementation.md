# Praxisorientierte Anleitung: Implementierung von HSTS (HTTP Strict Transport Security) mit Apache auf Debian

## Einführung
HTTP Strict Transport Security (HSTS) ist ein Sicherheitsmechanismus, der Browser anweist, ausschließlich HTTPS für eine Website zu verwenden, wodurch Angriffe wie Man-in-the-Middle (MITM) erschwert werden. Diese Anleitung zeigt Ihnen, wie Sie HSTS in einer Apache-Konfiguration auf einem Debian-System aktivieren, um die Sicherheit Ihrer HTTPS-Websites zu erhöhen. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, HSTS für eine bestehende Apache-Website (z. B. `tomcat.hostname`) zu implementieren. Diese Anleitung ist ideal für Administratoren und Entwickler, die die Sicherheit ihrer Webanwendungen verbessern möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit installiertem Apache HTTP Server (`apache2`) und aktiviertem `mod_ssl`
- Root- oder Sudo-Zugriff
- Eine funktionierende HTTPS-Website mit einem Let’s Encrypt-Zertifikat (z. B. für `tomcat.hostname`)
- Aktivierte Apache-Module `headers` und `ssl`
- Grundlegende Kenntnisse der Linux-Kommandozeile und von Apache-Konfiguration

## Grundlegende HSTS-Konzepte und Direktiven
Hier sind die wichtigsten Konzepte und Direktiven, die wir behandeln:

1. **HSTS-Header**:
   - `Strict-Transport-Security`: HTTP-Header, der HSTS aktiviert
   - `max-age`: Zeit in Sekunden, für die der Browser HTTPS erzwingen soll
   - `includeSubDomains`: Erzwingt HSTS auch für Subdomains
   - `preload`: Optional, um die Domain in Browser-Preload-Listen aufzunehmen
2. **Apache-Module**:
   - `a2enmod headers`: Aktiviert das `mod_headers`-Modul, um HTTP-Header zu setzen
   - `Header always set`: Setzt den HSTS-Header in der Apache-Konfiguration
3. **HTTPS-Konfiguration**:
   - `<VirtualHost *:443>`: HSTS wird nur in HTTPS-Virtual-Hosts angewendet
   - `Redirect`: Leitet HTTP-Anfragen auf HTTPS um, um HSTS effektiv zu nutzen

## Übungen zum Verinnerlichen

### Übung 1: mod_headers aktivieren und HSTS testen
**Ziel**: Lernen, wie man das `mod_headers`-Modul aktiviert und einen einfachen HSTS-Header testet.

1. **Schritt 1**: Aktiviere das `mod_headers`-Modul in Apache.
   ```bash
   sudo a2enmod headers
   sudo systemctl restart apache2
   ```
2. **Schritt 2**: Füge einen Test-HSTS-Header in die bestehende HTTPS-Konfiguration hinzu.
   ```bash
   sudo nano /etc/apache2/sites-available/tomcat.conf
   ```
   Füge innerhalb des `<VirtualHost *:443>`-Blocks (z. B. aus der vorherigen Tomcat-Anleitung) folgendes hinzu:
   ```apache
   Header always set Strict-Transport-Security "max-age=63072000"
   ```
   Der vollständige `<VirtualHost *:443>`-Block könnte wie folgt aussehen:
   ```apache
   <VirtualHost *:443>
       ServerName tomcat.hostname
       ProxyPreserveHost On
       ProxyPass / http://localhost:8080/
       ProxyPassReverse / http://localhost:8080/
       SSLEngine On
       SSLCertificateFile /etc/letsencrypt/live/tomcat.hostname/fullchain.pem
       SSLCertificateKeyFile /etc/letsencrypt/live/tomcat.hostname/privkey.pem
       Header always set Strict-Transport-Security "max-age=63072000"
   </VirtualHost>
   ```
3. **Schritt 3**: Starte Apache neu und überprüfe den HSTS-Header mit `curl`.
   ```bash
   sudo systemctl restart apache2
   curl -s -D- https://tomcat.hostname | grep -i Strict-Transport-Security
   ```

**Reflexion**: Warum ist die `max-age`-Einstellung wichtig, und was bedeutet ein Wert wie 63072000 Sekunden (2 Jahre)?

### Übung 2: HSTS mit includeSubDomains einrichten
**Ziel**: Verstehen, wie man HSTS für Subdomains aktiviert und HTTP zu HTTPS umleitet.

1. **Schritt 1**: Aktualisiere die HSTS-Konfiguration, um Subdomains einzuschließen.
   ```bash
   sudo nano /etc/apache2/sites-available/tomcat.conf
   ```
   Ändere den HSTS-Header im `<VirtualHost *:443>`-Block zu:
   ```apache
   Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains"
   ```
2. **Schritt 2**: Stelle sicher, dass HTTP-Anfragen auf HTTPS umgeleitet werden (bereits in der vorherigen Konfiguration enthalten, aber zur Sicherheit überprüfen).
   ```bash
   sudo nano /etc/apache2/sites-available/tomcat.conf
   ```
   Überprüfe, dass der `<VirtualHost *:80>`-Block eine Umleitung enthält:
   ```apache
   <VirtualHost *:80>
       ServerName tomcat.hostname
       Redirect permanent / https://tomcat.hostname/
   </VirtualHost>
   ```
3. **Schritt 3**: Starte Apache neu und teste die HSTS-Konfiguration.
   ```bash
   sudo systemctl restart apache2
   ```
   Öffne `http://tomcat.hostname` im Browser (sollte zu `https://tomcat.hostname` umleiten) und überprüfe den HSTS-Header mit `curl`:
   ```bash
   curl -s -D- https://tomcat.hostname | grep -i Strict-Transport-Security
   ```

**Reflexion**: Welche Vorteile bietet die `includeSubDomains`-Direktive, und welche Vorsichtsmaßnahmen solltest du bei ihrer Verwendung treffen?

### Übung 3: Vorbereitung für HSTS-Preload (optional)
**Ziel**: Lernen, wie man eine Website für die HSTS-Preload-Liste vorbereitet.

1. **Schritt 1**: Aktualisiere die HSTS-Konfiguration, um die `preload`-Direktive hinzuzufügen.
   ```bash
   sudo nano /etc/apache2/sites-available/tomcat.conf
   ```
   Ändere den HSTS-Header im `<VirtualHost *:443>`-Block zu:
   ```apache
   Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
   ```
2. **Schritt 2**: Teste die Konfiguration und überprüfe die HSTS-Header.
   ```bash
   sudo systemctl restart apache2
   curl -s -D- https://tomcat.hostname | grep -i Strict-Transport-Security
   ```
3. **Schritt 3**: Besuche `https://hstspreload.org` und überprüfe die Anforderungen für die HSTS-Preload-Liste (Hinweis: Die tatsächliche Einreichung erfordert, dass alle Subdomains HTTPS unterstützen und keine Fehler auftreten).

**Reflexion**: Warum könnte die Aufnahme in die HSTS-Preload-Liste sinnvoll sein, und welche Herausforderungen könnten bei der Einreichung auftreten?

## Tipps für den Erfolg
- Teste HSTS zunächst mit einem niedrigen `max-age` (z. B. 3600 Sekunden = 1 Stunde), um Probleme zu vermeiden, bevor du einen langen Zeitraum wie 2 Jahre setzt.
- Stelle sicher, dass alle Ressourcen (z. B. Bilder, Skripte) über HTTPS geladen werden, um Mixed-Content-Fehler zu vermeiden.
- Überprüfe die Apache-Logs (`/var/log/apache2/error.log`) bei Problemen mit der HSTS-Konfiguration.
- Verwende `apache2ctl configtest`, um die Syntax der Konfigurationsdateien vor dem Neustart zu überprüfen.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie HSTS (HTTP Strict Transport Security) mit Apache auf einem Debian-System implementieren, um die Sicherheit Ihrer HTTPS-Websites zu verbessern. Durch die Übungen haben Sie praktische Erfahrung mit dem `mod_headers`-Modul, der Konfiguration des HSTS-Headers und der Vorbereitung für die HSTS-Preload-Liste gesammelt. Diese Fähigkeiten sind essenziell für die Absicherung moderner Webanwendungen. Üben Sie weiter, um HSTS in komplexeren Szenarien wie Multi-Domain-Umgebungen zu meistern!

**Nächste Schritte**:
- Kombinieren Sie HSTS mit anderen Sicherheits-Headern wie Content Security Policy (CSP).
- Integrieren Sie HSTS in bestehende Reverse-Proxy-Konfigurationen (z. B. für Tomcat oder andere Backend-Server).
- Lesen Sie die offizielle Apache-Dokumentation zu `mod_headers` für weitere Header-Optionen.

**Quellen**:
- Offizielle Apache mod_headers-Dokumentation: https://httpd.apache.org/docs/current/mod/mod_headers.html
- HSTS-Spezifikation: https://tools.ietf.org/html/rfc6797
- HSTS Preload-Website: https://hstspreload.org/
- DigitalOcean Apache-Sicherheits-Tutorial: https://www.digitalocean.com/community/tutorials/recommended-steps-to-harden-the-security-of-your-apache-web-server