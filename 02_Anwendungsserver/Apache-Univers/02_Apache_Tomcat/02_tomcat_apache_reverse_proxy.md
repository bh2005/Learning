# Praxisorientierte Anleitung: Integration von Apache Tomcat mit Apache HTTP Server (apache2) als Reverse-Proxy für HTTPS-Unterstützung auf Debian

## Einführung
Die Integration von Apache Tomcat mit Apache HTTP Server (`apache2`) als Reverse-Proxy ermöglicht es, Tomcat-Webanwendungen über den Apache-Webserver bereitzustellen und HTTPS mit Let’s Encrypt-Zertifikaten abzusichern. Dies verbessert die Sicherheit und Flexibilität, da Apache zusätzliche Funktionen wie Lastverteilung oder erweiterte Konfigurationen bietet. Diese Anleitung zeigt Ihnen, wie Sie Apache als Reverse-Proxy vor Tomcat konfigurieren, um eine Tomcat-Anwendung über HTTPS unter einer Domain wie `tomcat.hostname` verfügbar zu machen. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, eine sichere und skalierbare Webumgebung einzurichten. Diese Anleitung ist ideal für Administratoren und Entwickler, die Java-Webanwendungen sicher bereitstellen möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit installiertem Apache HTTP Server (`apache2`) und Apache Tomcat (z. B. `tomcat9`)
- Root- oder Sudo-Zugriff
- Eine Domain (z. B. `tomcat.hostname`), die auf die Server-IP zeigt
- Installiertes `certbot` für Let’s Encrypt-Zertifikate
- Grundlegende Kenntnisse der Linux-Kommandozeile und von Apache/Tomcat-Konfiguration
- Eine laufende Tomcat-Anwendung (z. B. die `sample`-Anwendung aus der vorherigen Anleitung)

## Grundlegende Konzepte und Befehle
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **Apache-Module für Reverse-Proxy und HTTPS**:
   - `a2enmod proxy`, `a2enmod proxy_http`: Aktiviert Reverse-Proxy-Funktionen
   - `a2enmod ssl`: Aktiviert HTTPS-Unterstützung
2. **Reverse-Proxy-Direktiven**:
   - `ProxyPass`: Leitet Anfragen von Apache an Tomcat weiter
   - `ProxyPassReverse`: Passt Antwort-Header an, um die ursprüngliche URL beizubehalten
3. **Let’s Encrypt für HTTPS**:
   - `certbot`: Generiert und installiert SSL-Zertifikate für die Domain
   - `/etc/letsencrypt/live/`: Speicherort der Zertifikate

## Übungen zum Verinnerlichen

### Übung 1: Apache-Module aktivieren und Tomcat überprüfen
**Ziel**: Lernen, wie man die erforderlichen Apache-Module aktiviert und sicherstellt, dass Tomcat läuft.

1. **Schritt 1**: Aktiviere die notwendigen Apache-Module und installiere `certbot`.
   ```bash
   sudo apt update
   sudo apt install -y python3-certbot-apache
   sudo a2enmod proxy proxy_http ssl
   ```
2. **Schritt 2**: Überprüfe, ob Tomcat läuft und die Beispielanwendung verfügbar ist.
   ```bash
   sudo systemctl status tomcat9
   ```
   Öffne `http://localhost:8080/sample` im Browser, um sicherzustellen, dass die Tomcat-Beispielanwendung (aus der vorherigen Anleitung) funktioniert.
3. **Schritt 3**: Überprüfe, ob die Apache-Module geladen sind.
   ```bash
   apache2ctl -M | grep -E 'proxy|ssl'
   ```

**Reflexion**: Warum ist es wichtig, die Funktionalität von Tomcat separat zu testen, bevor der Reverse-Proxy eingerichtet wird?

### Übung 2: Apache als Reverse-Proxy für Tomcat mit HTTPS einrichten
**Ziel**: Konfiguriere Apache, um Anfragen an `tomcat.hostname` an Tomcat weiterzuleiten und HTTPS zu verwenden.

1. **Schritt 1**: Erstelle eine Apache-Konfigurationsdatei für den Reverse-Proxy.
   ```bash
   sudo nano /etc/apache2/sites-available/tomcat.conf
   ```
   Füge folgenden Inhalt ein:
   ```apache
   <VirtualHost *:80>
       ServerName tomcat.hostname
       Redirect permanent / https://tomcat.hostname/
   </VirtualHost>

   <VirtualHost *:443>
       ServerName tomcat.hostname
       ProxyPreserveHost On
       ProxyPass / http://localhost:8080/
       ProxyPassReverse / http://localhost:8080/
       SSLEngine On
       SSLCertificateFile /etc/letsencrypt/live/tomcat.hostname/fullchain.pem
       SSLCertificateKeyFile /etc/letsencrypt/live/tomcat.hostname/privkey.pem
   </VirtualHost>
   ```
2. **Schritt 2**: Generiere ein Let’s Encrypt-Zertifikat und aktiviere die Konfiguration.
   ```bash
   sudo certbot --apache -d tomcat.hostname
   sudo a2ensite tomcat.conf
   sudo systemctl restart apache2
   ```
3. **Schritt 3**: Teste die Konfiguration im Browser unter `https://tomcat.hostname`. Du solltest die Tomcat-Startseite sehen. Teste auch `https://tomcat.hostname/sample`, um die Beispielanwendung zu erreichen.
   ```bash
   # Kein Befehl nötig; öffne den Browser manuell
   ```

**Reflexion**: Wie verbessert die Verwendung von Apache als Reverse-Proxy die Sicherheit und Flexibilität im Vergleich zur direkten Nutzung von Tomcat?

### Übung 3: Reverse-Proxy für eine spezifische Tomcat-Anwendung einrichten
**Ziel**: Konfiguriere Apache, um nur eine spezifische Tomcat-Anwendung (z. B. `/sample`) unter einem bestimmten Pfad (z. B. `/myapp`) bereitzustellen.

1. **Schritt 1**: Passe die Apache-Konfigurationsdatei an, um nur die `/sample`-Anwendung unter `/myapp` weiterzuleiten.
   ```bash
   sudo nano /etc/apache2/sites-available/tomcat.conf
   ```
   Ersetze den `<VirtualHost *:443>`-Block durch:
   ```apache
   <VirtualHost *:443>
       ServerName tomcat.hostname
       ProxyPreserveHost On
       ProxyPass /myapp http://localhost:8080/sample
       ProxyPassReverse /myapp http://localhost:8080/sample
       SSLEngine On
       SSLCertificateFile /etc/letsencrypt/live/tomcat.hostname/fullchain.pem
       SSLCertificateKeyFile /etc/letsencrypt/live/tomcat.hostname/privkey.pem
   </VirtualHost>
   ```
2. **Schritt 2**: Stelle sicher, dass die Dateiberechtigungen korrekt sind und starte Apache neu.
   ```bash
   sudo chown www-data:www-data /etc/letsencrypt/live/tomcat.hostname/*
   sudo chmod 600 /etc/letsencrypt/live/tomcat.hostname/privkey.pem
   sudo chmod 644 /etc/letsencrypt/live/tomcat.hostname/fullchain.pem
   sudo systemctl restart apache2
   ```
3. **Schritt 3**: Teste die Konfiguration im Browser unter `https://tomcat.hostname/myapp`. Du solltest die Tomcat-Beispielanwendung (`sample`) sehen.
   ```bash
   # Kein Befehl nötig; öffne den Browser manuell
   ```

**Reflexion**: Warum könnte es nützlich sein, nur eine spezifische Tomcat-Anwendung unter einem neuen Pfad bereitzustellen, anstatt das gesamte Tomcat-Root-Verzeichnis weiterzuleiten?

## Tipps für den Erfolg
- Stelle sicher, dass die Domain (`tomcat.hostname`) im DNS auf die Server-IP zeigt, bevor du `certbot` ausführst.
- Überprüfe die Apache-Logs (`/var/log/apache2/error.log`) und Tomcat-Logs (`/var/log/tomcat9/catalina.out`) bei Problemen.
- Verwende `apache2ctl configtest`, um die Syntax der Konfigurationsdateien vor dem Neustart zu überprüfen.
- Konfiguriere `certbot renew --dry-run`, um die automatische Verlängerung von Let’s Encrypt-Zertifikaten zu testen.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Apache HTTP Server (`apache2`) als Reverse-Proxy vor Apache Tomcat konfigurieren, um Java-Webanwendungen über HTTPS mit Let’s Encrypt-Zertifikaten bereitzustellen. Durch die Übungen haben Sie praktische Erfahrung mit `mod_proxy`, `mod_ssl` und der Weiterleitung spezifischer Anwendungen gesammelt. Diese Fähigkeiten sind essenziell für die sichere und skalierbare Bereitstellung von Java-Webanwendungen. Üben Sie weiter, um komplexere Szenarien wie Lastverteilung oder Authentifizierung zu meistern!

**Nächste Schritte**:
- Erkunden Sie `mod_proxy_balancer`, um Lastverteilung über mehrere Tomcat-Instanzen einzurichten.
- Implementieren Sie HSTS (HTTP Strict Transport Security) für zusätzliche Sicherheit.
- Lesen Sie die Tomcat- und Apache-Dokumentationen für fortgeschrittene Konfigurationsoptionen.

**Quellen**:
- Offizielle Apache Tomcat-Dokumentation: https://tomcat.apache.org/tomcat-9.0-doc/
- Offizielle Apache mod_proxy-Dokumentation: https://httpd.apache.org/docs/current/mod/mod_proxy.html
- Let’s Encrypt Certbot-Anleitung: https://certbot.eff.org/instructions?ws=apache&os=debian-11
- DigitalOcean Tomcat-Apache-Tutorial: https://www.digitalocean.com/community/tutorials/how-to-install-apache-tomcat-9-on-debian-10