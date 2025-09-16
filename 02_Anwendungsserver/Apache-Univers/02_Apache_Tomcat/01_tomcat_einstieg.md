# Praxisorientierte Anleitung: Einstieg in Apache Tomcat auf Debian

## Einführung
Apache Tomcat ist ein Open-Source-Webserver und Servlet-Container, der Java-Webanwendungen (Servlets und JSPs) bereitstellt. Er wird häufig für die Ausführung von Java-basierten Webanwendungen verwendet. Diese Anleitung führt Sie in die Grundlagen der Installation, Konfiguration und Nutzung von Apache Tomcat auf einem Debian-System ein. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, Tomcat zu installieren, eine einfache Webanwendung bereitzustellen und grundlegende Verwaltungsaufgaben durchzuführen. Diese Anleitung ist ideal für Entwickler und Administratoren, die mit Java-Webanwendungen beginnen möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Java Development Kit (JDK) installiert (mindestens Java 8, empfohlen Java 11 oder höher)
- Ein Terminal für die Ausführung von Befehlen
- Grundlegende Kenntnisse der Linux-Kommandozeile
- Optional: Ein Texteditor (z. B. `nano` oder `vim`)

## Grundlegende Apache Tomcat-Konzepte und Befehle
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **Installation und Dienstverwaltung**:
   - `apt install tomcat9`: Installiert Tomcat 9 auf Debian
   - `systemctl`: Verwaltet den Tomcat-Dienst (Start, Stop, Status)
2. **Tomcat-Verzeichnisstruktur**:
   - `/var/lib/tomcat9/webapps/`: Verzeichnis für die Bereitstellung von Webanwendungen
   - `/etc/tomcat9/`: Konfigurationsdateien, z. B. `server.xml` und `tomcat-users.xml`
3. **Webanwendungen bereitstellen**:
   - WAR-Dateien (Web Application Archive): Dateien, die in `/webapps/` bereitgestellt werden
   - `manager-gui`: Weboberfläche zur Verwaltung von Anwendungen

## Übungen zum Verinnerlichen

### Übung 1: Apache Tomcat installieren und starten
**Ziel**: Lernen, wie man Tomcat installiert und den Dienst startet.

1. **Schritt 1**: Installiere Java und Tomcat 9.
   ```bash
   sudo apt update
   sudo apt install -y openjdk-11-jdk tomcat9
   ```
2. **Schritt 2**: Starte den Tomcat-Dienst und überprüfe seinen Status.
   ```bash
   sudo systemctl start tomcat9
   sudo systemctl status tomcat9
   sudo systemctl enable tomcat9
   ```
3. **Schritt 3**: Öffne einen Browser und rufe `http://localhost:8080` auf, um die Tomcat-Standardseite zu sehen.
   ```bash
   # Kein Befehl nötig; öffne den Browser manuell
   ```

**Reflexion**: Was zeigt die Tomcat-Standardseite an, und wie kannst du überprüfen, ob der Server korrekt läuft?

### Übung 2: Tomcat-Manager einrichten und eine einfache Webanwendung bereitstellen
**Ziel**: Verstehen, wie man den Tomcat-Manager aktiviert und eine Beispiel-Webanwendung bereitstellt.

1. **Schritt 1**: Konfiguriere den Tomcat-Manager, indem du einen Benutzer erstellst.
   ```bash
   sudo nano /etc/tomcat9/tomcat-users.xml
   ```
   Füge innerhalb des `<tomcat-users>`-Tags folgendes hinzu:
   ```xml
   <role rolename="manager-gui"/>
   <user username="admin" password="secure_password" roles="manager-gui"/>
   ```
2. **Schritt 2**: Lade eine Beispiel-WAR-Datei herunter und stelle sie bereit.
   ```bash
   sudo wget -O /var/lib/tomcat9/webapps/sample.war https://tomcat.apache.org/tomcat-9.0-doc/appdev/sample/sample.war
   sudo chown tomcat:tomcat /var/lib/tomcat9/webapps/sample.war
   sudo chmod 644 /var/lib/tomcat9/webapps/sample.war
   ```
3. **Schritt 3**: Starte Tomcat neu und greife auf die Webanwendung zu.
   ```bash
   sudo systemctl restart tomcat9
   ```
   Öffne `http://localhost:8080/sample` im Browser, um die Beispielanwendung zu sehen. Greife auf den Manager unter `http://localhost:8080/manager/html` zu (Login: admin/secure_password).

**Reflexion**: Warum ist es wichtig, den Zugriff auf den Tomcat-Manager durch Benutzer und Passwörter zu sichern?

### Übung 3: Eigene einfache JSP-Seite erstellen und bereitstellen
**Ziel**: Lernen, wie man eine eigene JSP-Seite erstellt und in Tomcat bereitstellt.

1. **Schritt 1**: Erstelle ein Verzeichnis für eine neue Webanwendung und eine JSP-Seite.
   ```bash
   sudo mkdir -p /var/lib/tomcat9/webapps/myapp
   sudo nano /var/lib/tomcat9/webapps/myapp/index.jsp
   ```
   Füge folgenden Inhalt ein:
   ```jsp
   <%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
   <!DOCTYPE html>
   <html>
   <head>
       <title>Meine JSP-Seite</title>
   </head>
   <body>
       <h1>Willkommen zu meiner Tomcat-Anwendung!</h1>
       <p>Aktuelle Zeit: <%= new java.util.Date() %></p>
   </body>
   </html>
   ```
2. **Schritt 2**: Stelle sicher, dass die Dateiberechtigungen korrekt sind.
   ```bash
   sudo chown -R tomcat:tomcat /var/lib/tomcat9/webapps/myapp
   sudo chmod -R 644 /var/lib/tomcat9/webapps/myapp
   ```
3. **Schritt 3**: Starte Tomcat neu und teste die Seite im Browser unter `http://localhost:8080/myapp`.
   ```bash
   sudo systemctl restart tomcat9
   ```

**Reflexion**: Wie unterscheiden sich JSP-Seiten von statischen HTML-Seiten, und warum sind sie für dynamische Inhalte nützlich?

## Tipps für den Erfolg
- Überprüfe die Tomcat-Logs (`/var/log/tomcat9/catalina.out`) bei Problemen mit der Anwendungsbereitstellung.
- Sichere den Zugriff auf den Manager und andere sensible Bereiche mit starken Passwörtern und IP-Einschränkungen in `context.xml`.
- Verwende `systemctl` für die Verwaltung des Tomcat-Dienstes, um sicherzustellen, dass er automatisch startet.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Apache Tomcat auf einem Debian-System installieren, den Tomcat-Manager konfigurieren und sowohl eine Beispiel-Webanwendung als auch eine eigene JSP-Seite bereitstellen. Diese Fähigkeiten sind die Grundlage für die Entwicklung und Bereitstellung von Java-Webanwendungen. Durch die Übungen haben Sie praktische Erfahrung gesammelt, die Sie in realen Projekten anwenden können. Üben Sie weiter, um komplexere Webanwendungen zu entwickeln!

**Nächste Schritte**:
- Integrieren Sie Tomcat mit Apache HTTP Server (`apache2`) als Reverse-Proxy für HTTPS-Unterstützung.
- Erkunden Sie die Entwicklung von Java Servlets oder Frameworks wie Spring Boot.
- Lesen Sie die offizielle Tomcat-Dokumentation für fortgeschrittene Konfigurationsoptionen.

**Quellen**:
- Offizielle Apache Tomcat-Dokumentation: https://tomcat.apache.org/tomcat-9.0-doc/
- Debian Wiki zu Tomcat: https://wiki.debian.org/Tomcat
- DigitalOcean Tomcat-Tutorial: https://www.digitalocean.com/community/tutorials/how-to-install-apache-tomcat-9-on-debian-10