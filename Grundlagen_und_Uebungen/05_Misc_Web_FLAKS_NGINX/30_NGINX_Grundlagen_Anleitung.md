# Praxisorientierte Anleitung: Grundlagen von NGINX auf Debian

## Einführung
NGINX ist ein leistungsstarker, vielseitiger Webserver, der für seine Geschwindigkeit und Effizienz bekannt ist. Diese Anleitung konzentriert sich auf die Schwerpunkte **Installation und Konfiguration von NGINX**, **Verwaltung von Webseiten** und **Grundlegende Sicherheitsmaßnahmen**, um statische Inhalte bereitzustellen und einfache Server-Setups zu erstellen. Durch praktische Übungen lernst du, NGINX auf einem Debian-System zu installieren, zu konfigurieren und zu verwalten, um einen funktionsfähigen Webserver zu betreiben.

**Voraussetzungen**:
- Ein Debian-basiertes System (z. B. Debian 12 oder Ubuntu 22.04).
- Ein Terminal (z. B. über `Ctrl + T` oder ein Terminal-Programm wie `bash`).
- Administratorrechte (`sudo`) für Installation und Konfiguration.
- Internetzugang für die Installation von Paketen.
- Grundlegendes Verständnis von Linux-Befehlen und Dateisystemen.
- Sichere Testumgebung (z. B. virtuelle Maschine oder Testverzeichnis), um Konfigurationen risikofrei auszuprobieren.

## Grundlegende Befehle
Hier sind die wichtigsten Befehle für die Arbeit mit NGINX, aufgeteilt nach den Hauptthemen:

1. **Installation und Konfiguration von NGINX**:
   - `apt install nginx`: Installiert NGINX auf Debian.
   - `systemctl start nginx`: Startet den NGINX-Dienst.
   - `systemctl enable nginx`: Aktiviert NGINX für den Autostart beim Booten.
   - `nginx -t`: Testet die Konfigurationsdateien auf Syntaxfehler.
   - `systemctl reload nginx`: Lädt die Konfiguration ohne Unterbrechung neu.
2. **Verwaltung von Webseiten**:
   - `nano /etc/nginx/sites-available/<site>`: Bearbeitet Konfigurationsdateien für virtuelle Hosts.
   - `ln -s`: Erstellt symbolische Links für aktivierte Sites.
   - `rm`: Entfernt symbolische Links, um Sites zu deaktivieren.
   - `mkdir`: Erstellt Verzeichnisse für Webseiteninhalte.
3. **Grundlegende Sicherheitsmaßnahmen**:
   - `ufw`: Konfiguriert die Firewall für HTTP/HTTPS-Zugriff.
   - `chown` und `chmod`: Setzt Berechtigungen für Webserver-Dateien.
4. **Nützliche Zusatzbefehle**:
   - `man nginx`: Zeigt die Hilfeseite für NGINX.
   - `curl`: Testet die Erreichbarkeit des Webservers.
   - `cat`: Zeigt den Inhalt von Konfigurationsdateien an.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Installation und Konfiguration von NGINX
**Ziel**: Installiere NGINX, starte den Dienst und überprüfe die Standard-Webseite.

1. **Schritt 1**: Aktualisiere die Paketlisten und installiere NGINX:
   ```bash
   sudo apt update
   sudo apt install nginx -y
   ```

2. **Schritt 2**: Starte den NGINX-Dienst und aktiviere ihn für den Autostart:
   ```bash
   sudo systemctl start nginx
   sudo systemctl enable nginx
   ```

3. **Schritt 3**: Überprüfe, ob NGINX läuft:
   ```bash
   sudo systemctl status nginx
   ```

4. **Schritt 4**: Teste die Standard-Webseite:
   ```bash
   curl http://localhost
   ```
   Öffne `http://localhost` in einem Browser (oder die Server-IP, falls du auf einer VM arbeitest). Du solltest die NGINX-Willkommensseite sehen.

**Reflexion**: Was zeigt die Ausgabe von `systemctl status nginx`? Nutze `man systemctl` und überlege, wie du den Dienststatus überwachst.

### Übung 2: Verwaltung von Webseiten
**Ziel**: Erstelle und konfiguriere eine virtuelle Host-Datei für eine einfache statische Webseite.

1. **Schritt 1**: Erstelle ein Verzeichnis für die Webseite:
   ```bash
   sudo mkdir -p /var/www/meineseite/html
   ```

2. **Schritt 2**: Erstelle eine einfache HTML-Seite:
   ```bash
   sudo nano /var/www/meineseite/html/index.html
   ```
   Füge folgenden Inhalt ein:
   ```html
   <!DOCTYPE html>
   <html>
   <head>
       <title>Meine Webseite</title>
   </head>
   <body>
       <h1>Willkommen auf meiner NGINX-Webseite!</h1>
   </body>
   </html>
   ```
   Speichere und schließe.

3. **Schritt 3**: Erstelle eine Konfigurationsdatei für die Webseite:
   ```bash
   sudo nano /etc/nginx/sites-available/meineseite
   ```
   Füge folgenden Inhalt ein:
   ```
   server {
       listen 80;
       server_name meineseite.local;
       root /var/www/meineseite/html;
       index index.html;
       location / {
           try_files $uri $uri/ /index.html;
       }
   }
   ```

4. **Schritt 4**: Aktiviere die Webseite durch einen symbolischen Link:
   ```bash
   sudo ln -s /etc/nginx/sites-available/meineseite /etc/nginx/sites-enabled/
   ```

5. **Schritt 5**: Teste die Konfiguration und lade NGINX neu:
   ```bash
   sudo nginx -t
   sudo systemctl reload nginx
   ```

6. **Schritt 6**: Teste die Webseite:
   - Bearbeite die `/etc/hosts`-Datei, um `meineseite.local` lokal aufzulösen:
     ```bash
     sudo nano /etc/hosts
     ```
     Füge hinzu:
     ```
     127.0.0.1 meineseite.local
     ```
   - Öffne `http://meineseite.local` im Browser oder teste mit:
     ```bash
     curl http://meineseite.local
     ```

**Reflexion**: Warum ist die Trennung von `sites-available` und `sites-enabled` nützlich? Nutze `man ln` und überlege, wie du mehrere Webseiten verwalten kannst.

### Übung 3: Grundlegende Sicherheitsmaßnahmen
**Ziel**: Konfiguriere eine Firewall und sichere Dateiberechtigungen für NGINX.

1. **Schritt 1**: Installiere und konfiguriere die Firewall (`ufw`):
   ```bash
   sudo apt install ufw -y
   sudo ufw allow 80
   sudo ufw allow 22
   sudo ufw enable
   ```
   Überprüfe den Status:
   ```bash
   sudo ufw status
   ```

2. **Schritt 2**: Setze korrekte Berechtigungen für die Webseite:
   ```bash
   sudo chown -R www-data:www-data /var/www/meineseite
   sudo chmod -R 755 /var/www/meineseite
   ```

3. **Schritt 3**: Erstelle eine einfache Zugriffsbeschränkung:
   ```bash
   sudo nano /etc/nginx/sites-available/meineseite
   ```
   Füge im `location`-Block eine IP-Beschränkung hinzu:
   ```
   server {
       listen 80;
       server_name meineseite.local;
       root /var/www/meineseite/html;
       index index.html;
       location / {
           try_files $uri $uri/ /index.html;
           allow 127.0.0.1;
           deny all;
       }
   }
   ```

4. **Schritt 4**: Teste die Konfiguration und lade NGINX neu:
   ```bash
   sudo nginx -t
   sudo systemctl reload nginx
   ```

5. **Schritt 5**: Überprüfe den Zugriff:
   ```bash
   curl http://meineseite.local
   ```
   Teste von einem anderen Gerät (z. B. einem zweiten Computer im Netzwerk), um die `deny all`-Regel zu prüfen (sollte blockiert werden).

**Reflexion**: Wie verbessert `ufw` die Sicherheit? Nutze `man ufw` und überlege, wie du HTTPS mit Let’s Encrypt einrichten könntest.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um NGINX-Befehle und Konfigurationen zu verinnerlichen.
- **Sicheres Testen**: Nutze eine virtuelle Maschine oder ein Testverzeichnis, um Konfigurationsfehler zu vermeiden.
- **Fehler verstehen**: Lies Fehlermeldungen von `nginx -t` genau und überprüfe Logs in `/var/log/nginx/`.
- **Effiziente Konfigurationen**: Organisiere Sites in `sites-available` und aktiviere sie nur bei Bedarf in `sites-enabled`.
- **Sicherheitsbewusstsein**: Setze immer korrekte Berechtigungen (`www-data`) und beschränke Zugriffe mit `ufw` oder NGINX-Regeln.
- **Kombiniere Tools**: Nutze NGINX mit statischen Site-Generatoren wie Hugo oder Tools wie `rsync` für automatisiertes Deployment.

## Fazit
Mit diesen Übungen hast du die Grundlagen von NGINX auf Debian gemeistert, einschließlich Installation, Konfiguration von Webseiten und grundlegender Sicherheitsmaßnahmen. Vertiefe dein Wissen, indem du fortgeschrittene Features wie HTTPS mit Let’s Encrypt, Load Balancing oder Reverse Proxy ausprobierst. Wenn du ein spezifisches Thema (z. B. HTTPS-Einrichtung oder Log-Analyse) vertiefen möchtest, lass es mich wissen!
