# Praxisorientierte Anleitung: Einstieg in Apache Struts auf Debian

## Einführung
Apache Struts ist ein Open-Source-Framework für die Entwicklung von Java-Webanwendungen, das das MVC-Modell (Model-View-Controller) unterstützt. Es erleichtert die Erstellung skalierbarer und wartbarer Webanwendungen durch vordefinierte Komponenten und Konventionen. Diese Anleitung führt Sie in die Grundlagen der Installation und Nutzung von Apache Struts auf einem Debian-System ein, zeigt Ihnen, wie Sie eine einfache Webanwendung erstellen und diese mit Apache Tomcat bereitstellen. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, eine Struts-basierte Anwendung zu entwickeln. Diese Anleitung ist ideal für Java-Entwickler, die moderne Webanwendungen erstellen möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit installiertem Apache Tomcat (z. B. `tomcat9`)
- Java Development Kit (JDK) installiert (mindestens Java 8, empfohlen Java 11)
- Maven für die Verwaltung von Abhängigkeiten
- Root- oder Sudo-Zugriff für die Installation
- Grundlegende Kenntnisse der Linux-Kommandozeile, Java und Webentwicklung
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie IntelliJ IDEA)

## Grundlegende Apache Struts-Konzepte und Befehle
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **Struts-Installation und Setup**:
   - Maven: Verwaltet Struts-Abhängigkeiten in einer `pom.xml`-Datei
   - `struts2-core`: Kernbibliothek für Struts 2
2. **Struts-Komponenten**:
   - `struts.xml`: Konfigurationsdatei für Struts-Aktionen und Ergebnisse
   - Actions: Java-Klassen, die die Logik der Anwendung verarbeiten
   - JSPs: Views für die Darstellung der Benutzeroberfläche
3. **Bereitstellung in Tomcat**:
   - `mvn package`: Erstellt eine WAR-Datei für die Bereitstellung
   - `/var/lib/tomcat9/webapps/`: Verzeichnis für die Bereitstellung der Anwendung

## Übungen zum Verinnerlichen

### Übung 1: Maven und Struts einrichten
**Ziel**: Lernen, wie man Maven installiert und ein Struts-Projekt initialisiert.

1. **Schritt 1**: Installiere Maven und überprüfe die Java-Installation.
   ```bash
   sudo apt update
   sudo apt install -y maven
   java -version
   mvn -version
   ```
2. **Schritt 2**: Erstelle ein neues Maven-Projekt für Struts.
   ```bash
   mkdir my-struts-app
   cd my-struts-app
   mvn archetype:generate -DgroupId=com.example -DartifactId=my-struts-app -DarchetypeArtifactId=maven-archetype-webapp -DinteractiveMode=false
   ```
3. **Schritt 3**: Füge Struts-Abhängigkeiten zur `pom.xml` hinzu.
   ```bash
   nano pom.xml
   ```
   Ersetze den Inhalt der `pom.xml` durch:
   ```xml
   <project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
       <modelVersion>4.0.0</modelVersion>
       <groupId>com.example</groupId>
       <artifactId>my-struts-app</artifactId>
       <version>1.0-SNAPSHOT</version>
       <packaging>war</packaging>
       <dependencies>
           <dependency>
               <groupId>org.apache.struts</groupId>
               <artifactId>struts2-core</artifactId>
               <version>6.3.0</version>
           </dependency>
       </dependencies>
       <build>
           <finalName>my-struts-app</finalName>
           <plugins>
               <plugin>
                   <groupId>org.apache.maven.plugins</groupId>
                   <artifactId>maven-war-plugin</artifactId>
                   <version>3.3.2</version>
               </plugin>
           </plugins>
       </build>
   </project>
   ```

**Reflexion**: Warum ist Maven für die Verwaltung von Abhängigkeiten in einem Struts-Projekt nützlich?

### Übung 2: Eine einfache Struts-Anwendung erstellen
**Ziel**: Verstehen, wie man eine einfache Struts-Anwendung mit einer Action und einer JSP-Seite erstellt.

1. **Schritt 1**: Erstelle die Struts-Konfigurationsdatei.
   ```bash
   mkdir -p src/main/resources
   nano src/main/resources/struts.xml
   ```
   Füge folgenden Inhalt ein:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE struts PUBLIC
       "-//Apache Software Foundation//DTD Struts Configuration 2.5//EN"
       "http://struts.apache.org/dtds/struts-2.5.dtd">
   <struts>
       <package name="default" extends="struts-default">
           <action name="welcome" class="com.example.WelcomeAction">
               <result name="success">/welcome.jsp</result>
           </action>
       </package>
   </struts>
   ```
2. **Schritt 2**: Erstelle eine Action-Klasse.
   ```bash
   mkdir -p src/main/java/com/example
   nano src/main/java/com/example/WelcomeAction.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   package com.example;
   public class WelcomeAction {
       private String message;
       public String execute() {
           message = "Willkommen zu Apache Struts!";
           return "success";
       }
       public String getMessage() {
           return message;
       }
       public void setMessage(String message) {
           this.message = message;
       }
   }
   ```
3. **Schritt 3**: Erstelle eine JSP-Seite für die Anzeige.
   ```bash
   mkdir -p src/main/webapp
   nano src/main/webapp/welcome.jsp
   ```
   Füge folgenden Inhalt ein:
   ```jsp
   <%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
   <%@ taglib prefix="s" uri="/struts-tags" %>
   <!DOCTYPE html>
   <html>
   <head>
       <title>Struts-Anwendung</title>
   </head>
   <body>
       <h1><s:property value="message"/></h1>
   </body>
   </html>
   ```

**Reflexion**: Wie unterstützt die `struts.xml`-Datei die Organisation der Anwendung, und welche Rolle spielt die Action-Klasse?

### Übung 3: Struts-Anwendung in Tomcat bereitstellen
**Ziel**: Lernen, wie man die Struts-Anwendung als WAR-Datei erstellt und in Tomcat bereitstellt.

1. **Schritt 1**: Erstelle die WAR-Datei mit Maven.
   ```bash
   cd my-struts-app
   mvn clean package
   ```
   Die WAR-Datei wird in `target/my-struts-app.war` erstellt.
2. **Schritt 2**: Stelle die WAR-Datei in Tomcat bereit.
   ```bash
   sudo cp target/my-struts-app.war /var/lib/tomcat9/webapps/
   sudo chown tomcat:tomcat /var/lib/tomcat9/webapps/my-struts-app.war
   sudo chmod 644 /var/lib/tomcat9/webapps/my-struts-app.war
   ```
3. **Schritt 3**: Starte Tomcat neu und teste die Anwendung im Browser unter `http://localhost:8080/my-struts-app/welcome`.
   ```bash
   sudo systemctl restart tomcat9
   ```

**Reflexion**: Warum ist die Bereitstellung einer WAR-Datei in Tomcat eine effiziente Methode, um Java-Webanwendungen bereitzustellen?

## Tipps für den Erfolg
- Überprüfe die Tomcat-Logs (`/var/log/tomcat9/catalina.out`) bei Problemen mit der Anwendungsbereitstellung.
- Verwende eine IDE wie IntelliJ IDEA oder Eclipse, um die Struts-Entwicklung zu vereinfachen.
- Stelle sicher, dass die Struts-Version in der `pom.xml` mit den verfügbaren Maven-Repository-Versionen übereinstimmt.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Apache Struts auf einem Debian-System einrichten, eine einfache Struts-Webanwendung erstellen und diese mit Apache Tomcat bereitstellen. Durch die Übungen haben Sie praktische Erfahrung mit Maven, Struts-Konfigurationen und der Bereitstellung von WAR-Dateien gesammelt. Diese Fähigkeiten sind die Grundlage für die Entwicklung moderner Java-Webanwendungen. Üben Sie weiter, um komplexere Struts-Anwendungen zu entwickeln!

**Nächste Schritte**:
- Integrieren Sie Struts mit einer Datenbank wie MySQL für dynamische Daten.
- Konfigurieren Sie Apache HTTP Server als Reverse-Proxy für HTTPS-Unterstützung (siehe vorherige Anleitung).
- Erkunden Sie die offizielle Struts-Dokumentation für fortgeschrittene Features wie Validierung oder Plugins.

**Quellen**:
- Offizielle Apache Struts-Dokumentation: https://struts.apache.org/
- Apache Tomcat-Dokumentation: https://tomcat.apache.org/tomcat-9.0-doc/
- Maven-Dokumentation: https://maven.apache.org/guides/
- DigitalOcean Tomcat-Tutorial: https://www.digitalocean.com/community/tutorials/how-to-install-apache-tomcat-9-on-debian-10