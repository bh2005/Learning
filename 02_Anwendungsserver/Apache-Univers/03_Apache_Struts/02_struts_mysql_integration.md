# Praxisorientierte Anleitung: Integration von Apache Struts mit MySQL für dynamische Daten auf Debian

## Einführung
Die Integration von Apache Struts mit einer MySQL-Datenbank ermöglicht die Entwicklung dynamischer Java-Webanwendungen, die Daten persistent speichern und abrufen. Diese Anleitung zeigt Ihnen, wie Sie eine Struts-Webanwendung auf einem Debian-System erstellen, die mit MySQL verbunden ist, um eine To-Do-Listen-Anwendung zu implementieren. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, Struts mit MySQL zu integrieren und dynamische Daten zu verwalten. Die Anleitung ist ideal für Java-Entwickler, die datenbankgestützte Webanwendungen entwickeln möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit installiertem Apache Tomcat (`tomcat9`), Maven und Java JDK (mindestens Java 8, empfohlen Java 11)
- MySQL-Server installiert
- Root- oder Sudo-Zugriff
- Grundlegende Kenntnisse der Linux-Kommandozeile, Java, Struts und MySQL
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie IntelliJ IDEA)

## Grundlegende Konzepte und Techniken
Hier sind die wichtigsten Konzepte und Techniken, die wir behandeln:

1. **Struts und MySQL-Integration**:
   - `mysql-connector-java`: JDBC-Treiber für die Verbindung mit MySQL
   - Struts Actions: Verarbeiten Datenbankoperationen (z. B. CRUD: Create, Read, Update, Delete)
2. **Struts-Komponenten**:
   - `struts.xml`: Konfiguriert die Aktionen und Ergebnisse der Anwendung
   - JSPs: Views für die Anzeige dynamischer Daten
3. **Bereitstellung in Tomcat**:
   - `mvn package`: Erstellt eine WAR-Datei für die Bereitstellung
   - `/var/lib/tomcat9/webapps/`: Verzeichnis für die Anwendungsbereitstellung

## Übungen zum Verinnerlichen

### Übung 1: MySQL-Datenbank und Abhängigkeiten einrichten
**Ziel**: Lernen, wie man eine MySQL-Datenbank vorbereitet und die erforderlichen Abhängigkeiten in einem Struts-Projekt hinzufügt.

1. **Schritt 1**: Installiere MySQL und erstelle eine Datenbank für die To-Do-Liste.
   ```bash
   sudo apt update
   sudo apt install -y mysql-server
   sudo mysql_secure_installation
   sudo mysql -u root -p
   ```
   Führe in der MySQL-Konsole folgendes aus:
   ```sql
   CREATE DATABASE todo_struts;
   GRANT ALL PRIVILEGES ON todo_struts.* TO 'todo_user'@'localhost' IDENTIFIED BY 'secure_password';
   CREATE TABLE tasks (
       id INT AUTO_INCREMENT PRIMARY KEY,
       task VARCHAR(255) NOT NULL,
       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );
   INSERT INTO tasks (task) VALUES ('Erste Aufgabe');
   FLUSH PRIVILEGES;
   EXIT;
   ```
2. **Schritt 2**: Erstelle ein neues Struts-Projekt (oder verwende das bestehende aus der vorherigen Anleitung) und füge den MySQL-Connector hinzu.
   ```bash
   mkdir my-struts-todo
   cd my-struts-todo
   mvn archetype:generate -DgroupId=com.example -DartifactId=my-struts-todo -DarchetypeArtifactId=maven-archetype-webapp -DinteractiveMode=false
   nano pom.xml
   ```
   Ersetze den Inhalt der `pom.xml` durch:
   ```xml
   <project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
       <modelVersion>4.0.0</modelVersion>
       <groupId>com.example</groupId>
       <artifactId>my-struts-todo</artifactId>
       <version>1.0-SNAPSHOT</version>
       <packaging>war</packaging>
       <dependencies>
           <dependency>
               <groupId>org.apache.struts</groupId>
               <artifactId>struts2-core</artifactId>
               <version>6.3.0</version>
           </dependency>
           <dependency>
               <groupId>mysql</groupId>
               <artifactId>mysql-connector-java</artifactId>
               <version>8.0.33</version>
           </dependency>
       </dependencies>
       <build>
           <finalName>my-struts-todo</finalName>
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
3. **Schritt 3**: Überprüfe die Installation von Maven und Java.
   ```bash
   mvn -version
   java -version
   ```

**Reflexion**: Warum ist der MySQL-Connector notwendig, und wie erleichtert Maven die Verwaltung solcher Abhängigkeiten?

### Übung 2: Struts-Anwendung mit MySQL-Integration erstellen
**Ziel**: Verstehen, wie man eine Struts-Anwendung erstellt, die Daten aus einer MySQL-Datenbank anzeigt.

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
           <action name="listTasks" class="com.example.ListTasksAction">
               <result name="success">/tasks.jsp</result>
           </action>
       </package>
   </struts>
   ```
2. **Schritt 2**: Erstelle eine Action-Klasse, die Daten aus der MySQL-Datenbank abruft.
   ```bash
   mkdir -p src/main/java/com/example
   nano src/main/java/com/example/ListTasksAction.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   package com.example;
   import com.opensymphony.xwork2.ActionSupport;
   import java.sql.*;
   import java.util.ArrayList;
   import java.util.List;

   public class ListTasksAction extends ActionSupport {
       private List<String> tasks = new ArrayList<>();

       public String execute() {
           try {
               Class.forName("com.mysql.cj.jdbc.Driver");
               Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/todo_struts", "todo_user", "secure_password");
               Statement stmt = conn.createStatement();
               ResultSet rs = stmt.executeQuery("SELECT task FROM tasks");
               while (rs.next()) {
                   tasks.add(rs.getString("task"));
               }
               rs.close();
               stmt.close();
               conn.close();
           } catch (Exception e) {
               e.printStackTrace();
               return ERROR;
           }
           return SUCCESS;
       }

       public List<String> getTasks() {
           return tasks;
       }
   }
   ```
3. **Schritt 3**: Erstelle eine JSP-Seite zur Anzeige der Aufgaben.
   ```bash
   mkdir -p src/main/webapp
   nano src/main/webapp/tasks.jsp
   ```
   Füge folgenden Inhalt ein:
   ```jsp
   <%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
   <%@ taglib prefix="s" uri="/struts-tags" %>
   <!DOCTYPE html>
   <html>
   <head>
       <title>To-Do-Liste</title>
   </head>
   <body>
       <h1>Meine To-Do-Liste</h1>
       <ul>
           <s:iterator value="tasks">
               <li><s:property /></li>
           </s:iterator>
       </ul>
   </body>
   </html>
   ```

**Reflexion**: Wie erleichtert die Struts-Action-Klasse die Trennung von Logik und Präsentation in einer datenbankgestützten Anwendung?

### Übung 3: Aufgaben hinzufügen und die Anwendung in Tomcat bereitstellen
**Ziel**: Lernen, wie man ein Formular erstellt, um Aufgaben in die Datenbank einzufügen, und die Anwendung in Tomcat bereitstellt.

1. **Schritt 1**: Aktualisiere die Struts-Konfiguration, um eine Aktion zum Hinzufügen von Aufgaben zu unterstützen.
   ```bash
   nano src/main/resources/struts.xml
   ```
   Ersetze den Inhalt durch:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE struts PUBLIC
       "-//Apache Software Foundation//DTD Struts Configuration 2.5//EN"
       "http://struts.apache.org/dtds/struts-2.5.dtd">
   <struts>
       <package name="default" extends="struts-default">
           <action name="listTasks" class="com.example.ListTasksAction">
               <result name="success">/tasks.jsp</result>
           </action>
           <action name="addTask" class="com.example.AddTaskAction" method="add">
               <result name="success" type="redirectAction">listTasks</result>
           </action>
       </package>
   </struts>
   ```
2. **Schritt 2**: Erstelle eine Action-Klasse zum Hinzufügen von Aufgaben.
   ```bash
   nano src/main/java/com/example/AddTaskAction.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   package com.example;
   import com.opensymphony.xwork2.ActionSupport;
   import java.sql.*;

   public class AddTaskAction extends ActionSupport {
       private String task;

       public String add() {
           try {
               Class.forName("com.mysql.cj.jdbc.Driver");
               Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/todo_struts", "todo_user", "secure_password");
               PreparedStatement stmt = conn.prepareStatement("INSERT INTO tasks (task) VALUES (?)");
               stmt.setString(1, task);
               stmt.executeUpdate();
               stmt.close();
               conn.close();
           } catch (Exception e) {
               e.printStackTrace();
               return ERROR;
           }
           return SUCCESS;
       }

       public String getTask() {
           return task;
       }

       public void setTask(String task) {
           this.task = task;
       }
   }
   ```
3. **Schritt 3**: Aktualisiere die JSP-Seite, um ein Formular zum Hinzufügen von Aufgaben einzufügen.
   ```bash
   nano src/main/webapp/tasks.jsp
   ```
   Ersetze den Inhalt durch:
   ```jsp
   <%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
   <%@ taglib prefix="s" uri="/struts-tags" %>
   <!DOCTYPE html>
   <html>
   <head>
       <title>To-Do-Liste</title>
   </head>
   <body>
       <h1>Meine To-Do-Liste</h1>
       <s:form action="addTask">
           <s:textfield name="task" label="Neue Aufgabe" required="true"/>
           <s:submit value="Hinzufügen"/>
       </s:form>
       <ul>
           <s:iterator value="tasks">
               <li><s:property /></li>
           </s:iterator>
       </ul>
   </body>
   </html>
   ```
4. **Schritt 4**: Erstelle die WAR-Datei und stelle sie in Tomcat bereit.
   ```bash
   cd my-struts-todo
   mvn clean package
   sudo cp target/my-struts-todo.war /var/lib/tomcat9/webapps/
   sudo chown tomcat:tomcat /var/lib/tomcat9/webapps/my-struts-todo.war
   sudo chmod 644 /var/lib/tomcat9/webapps/my-struts-todo.war
   sudo systemctl restart tomcat9
   ```
5. **Schritt 5**: Teste die Anwendung im Browser unter `http://localhost:8080/my-struts-todo/listTasks`. Füge eine neue Aufgabe hinzu und überprüfe, ob sie in der Liste erscheint.

**Reflexion**: Wie verbessert die Verwendung von `PreparedStatement` die Sicherheit der Anwendung im Vergleich zu einfachen SQL-Abfragen?

## Tipps für den Erfolg
- Überprüfe die Tomcat-Logs (`/var/log/tomcat9/catalina.out`) und MySQL-Logs (`/var/log/mysql/error.log`) bei Problemen.
- Verwende eine IDE wie IntelliJ IDEA, um die Struts-Entwicklung und Datenbankzugriffe zu vereinfachen.
- Sichere die Datenbankverbindung durch einen dedizierten Benutzer mit eingeschränkten Rechten.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Apache Struts mit einer MySQL-Datenbank integrieren, um eine dynamische To-Do-Listen-Anwendung zu erstellen. Durch die Übungen haben Sie praktische Erfahrung mit Struts-Aktionen, MySQL-Verbindungen und der Bereitstellung in Tomcat gesammelt. Diese Fähigkeiten sind die Grundlage für die Entwicklung datenbankgestützter Java-Webanwendungen. Üben Sie weiter, um komplexere Anwendungen mit erweiterten Struts-Features zu entwickeln!

**Nächste Schritte**:
- Implementieren Sie Validierungslogik in Struts, um Benutzereingaben zu prüfen.
- Konfigurieren Sie Apache HTTP Server als Reverse-Proxy für HTTPS-Unterstützung (siehe vorherige Anleitung).
- Erkunden Sie Struts-Plugins wie das Hibernate-Plugin für ORM (Object-Relational Mapping).

**Quellen**:
- Offizielle Apache Struts-Dokumentation: https://struts.apache.org/
- MySQL Connector/J-Dokumentation: https://dev.mysql.com/doc/connector-j/en/
- Apache Tomcat-Dokumentation: https://tomcat.apache.org/tomcat-9.0-doc/
- Maven-Dokumentation: https://maven.apache.org/guides/