# Praxisorientierte Anleitung: Einrichtung von Grafana und Checkmk mit Apache Reverse-Proxy auf Debian

## Einführung
Grafana und Checkmk sind leistungsstarke Tools für Monitoring und Visualisierung. In dieser Anleitung richten wir Grafana so ein, dass es über `grafana.hostname` auf Port 3000 erreichbar ist, und Checkmk so, dass es über `monitoring.hostname/site` verfügbar ist, beide abgesichert mit HTTPS über Apache als Reverse-Proxy. Ziel ist es, eine sichere und benutzerfreundliche Zugriffsmethode für beide Dienste einzurichten. Diese Anleitung ist ideal für Administratoren, die Monitoring-Tools auf einem Debian-Server bereitstellen möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit installiertem Apache Web Server (`apache2`)
- Root- oder Sudo-Zugriff
- Zwei Domainnamen (z. B. `grafana.hostname` und `monitoring.hostname`), die auf die Server-IP zeigen
- Installiertes `certbot` für Let’s Encrypt-Zertifikate
- Grundlegende Kenntnisse der Linux-Kommandozeile und Apache-Konfiguration

## Grundlegende Konzepte und Befehle
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **Apache-Module für Reverse-Proxy und SSL**:
   - `a2enmod proxy`, `a2enmod proxy_http`: Aktiviert Reverse-Proxy-Funktionen
   - `a2enmod ssl`: Aktiviert HTTPS-Unterstützung
2. **Reverse-Proxy-Direktiven**:
   - `ProxyPass`: Leitet Anfragen an den Backend-Server (z. B. Grafana oder Checkmk)
   - `ProxyPassReverse`: Passt Antwort-Header an, um die ursprüngliche URL beizubehalten
3. **Let’s Encrypt für HTTPS**:
   - `certbot`: Generiert und installiert SSL-Zertifikate für die Domains
   - `/etc/letsencrypt/live/`: Speicherort der Zertifikate

## Übungen zum Verinnerlichen

### Übung 1: Installation und Grundkonfiguration von Grafana und Checkmk
**Ziel**: Grafana und Checkmk installieren und sicherstellen, dass sie lokal laufen.

1. **Schritt 1**: Installiere Grafana und starte den Dienst.
   ```bash
   sudo apt update
   sudo apt install -y apt-transport-https software-properties-common
   wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
   echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
   sudo apt update
   sudo apt install -y grafana
   sudo systemctl start grafana-server
   sudo systemctl enable grafana-server
   ```
   Teste Grafana unter `http://localhost:3000` (Standard-Login: admin/admin).
2. **Schritt 2**: Installiere Checkmk (Raw Edition) und richte eine Site ein.
   ```bash
   wget https://download.checkmk.com/checkmk/2.2.0p11/check-mk-raw-2.2.0p11_0.bullseye_amd64.deb
   sudo apt install -y ./check-mk-raw-2.2.0p11_0.bullseye_amd64.deb
   sudo omd create site
   sudo omd start site
   ```
   Teste Checkmk unter `http://localhost:5000/site` (Standard-Login: cmkadmin, Passwort wird bei `omd create` angezeigt).
3. **Schritt 3**: Überprüfe, ob beide Dienste laufen.
   ```bash
   sudo systemctl status grafana-server
   sudo omd status site
   ```

**Reflexion**: Warum ist es wichtig, die Backend-Dienste lokal zu testen, bevor der Reverse-Proxy eingerichtet wird?

### Übung 2: Apache Reverse-Proxy für Grafana einrichten
**Ziel**: Konfiguriere Apache, um Grafana über `grafana.hostname` mit HTTPS zu erreichen.

1. **Schritt 1**: Aktiviere die erforderlichen Apache-Module und installiere `certbot`.
   ```bash
   sudo a2enmod proxy proxy_http ssl
   sudo apt install -y python3-certbot-apache
   ```
2. **Schritt 2**: Erstelle eine Apache-Konfigurationsdatei für Grafana.
   ```bash
   sudo nano /etc/apache2/sites-available/grafana.conf
   ```
   Füge folgenden Inhalt ein:
   ```apache
   <VirtualHost *:80>
       ServerName grafana.hostname
       Redirect permanent / https://grafana.hostname/
   </VirtualHost>

   <VirtualHost *:443>
       ServerName grafana.hostname
       ProxyPreserveHost On
       ProxyPass / http://localhost:3000/
       ProxyPassReverse / http://localhost:3000/
       SSLEngine On
       SSLCertificateFile /etc/letsencrypt/live/grafana.hostname/fullchain.pem
       SSLCertificateKeyFile /etc/letsencrypt/live/grafana.hostname/privkey.pem
   </VirtualHost>
   ```
3. **Schritt 3**: Generiere ein Let’s Encrypt-Zertifikat und aktiviere die Konfiguration.
   ```bash
   sudo certbot --apache -d grafana.hostname
   sudo a2ensite grafana.conf
   sudo systemctl restart apache2
   ```
   Teste Grafana im Browser unter `https://grafana.hostname`.

**Reflexion**: Wie verbessert die Verwendung von HTTPS die Sicherheit des Zugriffs auf Grafana?

### Übung 3: Apache Reverse-Proxy für Checkmk einrichten
**Ziel**: Konfiguriere Apache, um Checkmk über `monitoring.hostname/site` mit HTTPS zu erreichen.

1. **Schritt 1**: Erstelle eine Apache-Konfigurationsdatei für Checkmk.
   ```bash
   sudo nano /etc/apache2/sites-available/monitoring.conf
   ```
   Füge folgenden Inhalt ein:
   ```apache
   <VirtualHost *:80>
       ServerName monitoring.hostname
       Redirect permanent / https://monitoring.hostname/
   </VirtualHost>

   <VirtualHost *:443>
       ServerName monitoring.hostname
       ProxyPreserveHost On
       ProxyPass /site http://localhost:5000/site
       ProxyPassReverse /site http://localhost:5000/site
       SSLEngine On
       SSLCertificateFile /etc/letsencrypt/live/monitoring.hostname/fullchain.pem
       SSLCertificateKeyFile /etc/letsencrypt/live/monitoring.hostname/privkey.pem
   </VirtualHost>
   ```
2. **Schritt 2**: Generiere ein Let’s Encrypt-Zertifikat und aktiviere die Konfiguration.
   ```bash
   sudo certbot --apache -d monitoring.hostname
   sudo a2ensite monitoring.conf
   sudo systemctl restart apache2
   ```
3. **Schritt 3**: Teste Checkmk im Browser unter `https://monitoring.hostname/site`.

**Reflexion**: Warum ist es wichtig, den korrekten Pfad (`/site`) in den `ProxyPass`-Direktiven für Checkmk zu spezifizieren?

## Tipps für den Erfolg
- Stelle sicher, dass die Domains (`grafana.hostname`, `monitoring.hostname`) auf die Server-IP im DNS verweisen.
- Überprüfe die Apache-Logs (`/var/log/apache2/error.log`) bei Problemen mit der Proxy-Konfiguration.
- Teste die Backend-Dienste (Grafana auf Port 3000, Checkmk auf Port 5000) separat, bevor du den Proxy einrichtest.
- Konfiguriere die automatische Verlängerung von Let’s Encrypt-Zertifikaten mit `sudo certbot renew --dry-run`.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Grafana und Checkmk auf einem Debian-Server installieren und über Apache als Reverse-Proxy mit HTTPS unter `grafana.hostname` und `monitoring.hostname/site` bereitstellen. Durch die Übungen haben Sie praktische Erfahrung mit der Konfiguration von `mod_proxy`, `mod_ssl` und Let’s Encrypt gesammelt. Diese Fähigkeiten sind essenziell für die sichere Bereitstellung von Monitoring-Tools. Üben Sie weiter, um komplexere Szenarien wie Lastverteilung oder zusätzliche Sicherheitsmaßnahmen zu meistern!

**Nächste Schritte**:
- Erkunden Sie `mod_proxy_balancer` für Lastverteilung, falls mehrere Grafana- oder Checkmk-Instanzen benötigt werden.
- Implementieren Sie HSTS (HTTP Strict Transport Security) für zusätzliche Sicherheit.
- Lesen Sie die Dokumentationen von Grafana und Checkmk für fortgeschrittene Konfigurationsoptionen.

**Quellen**:
- Offizielle Grafana-Dokumentation: https://grafana.com/docs/grafana/latest/
- Offizielle Checkmk-Dokumentation: https://docs.checkmk.com/latest/en/
- Apache mod_proxy-Dokumentation: https://httpd.apache.org/docs/current/mod/mod_proxy.html
- Let’s Encrypt Certbot-Anleitung: https://certbot.eff.org/instructions?ws=apache&os=debian-11