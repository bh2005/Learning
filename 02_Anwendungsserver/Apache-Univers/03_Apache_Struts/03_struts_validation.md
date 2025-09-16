# Praxisorientierte Anleitung: Implementierung von Validierungslogik in Apache Struts für Benutzereingaben auf Debian

## Einführung
Die Validierung von Benutzereingaben ist ein wesentlicher Bestandteil sicherer Webanwendungen, um ungültige oder schädliche Daten zu verhindern. Apache Struts 2 bietet leistungsstarke Mechanismen wie XML-basierte und Annotationsbasierte Validierung, um Eingaben zu prüfen. Diese Anleitung zeigt Ihnen, wie Sie Validierungslogik in die To-Do-Listen-Anwendung aus der vorherigen Anleitung integrieren, um sicherzustellen, dass Aufgaben nicht leer sind und bestimmte Kriterien erfüllen. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, Struts-Validierungen zu implementieren und Benutzereingaben sicher zu verarbeiten. Diese Anleitung ist ideal für Java-Entwickler, die robuste Webanwendungen entwickeln möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit installiertem Apache Tomcat (`tomcat9`), Maven, Java JDK (mindestens Java 8, empfohlen Java 11) und MySQL
- Die To-Do-Listen-Anwendung aus der vorherigen Anleitung (im Verzeichnis `my-struts-todo`)
- Root- oder Sudo-Zugriff für die Bereitstellung
- Grundlegende Kenntnisse der Linux-Kommandozeile, Java, Struts und MySQL
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie IntelliJ IDEA)

## Grundlegende Struts-Validierungs-Konzepte und Techniken
Hier sind die wichtigsten Konzepte und Techniken, die wir behandeln:

1. **Struts-Validierungsmechanismus**:
   - **XML-basierte Validierung**: Validierungsregeln in einer XML-Datei (`ActionClass-validation.xml`)
   - **Annotationsbasierte Validierung**: Validierungsregeln direkt in der Action-Klasse mit Annotationen
   - Struts `validation`-Framework: Integrierte Validatoren wie `requiredstring`, `stringlength`
2. **Validierungsfehler anzeigen**:
   - `<s:fielderror>`: JSP-Tag zur Anzeige von Validierungsfehlern
   - `addFieldError`: Methode zum Hinzufügen von Fehlern in der Action-Klasse
3. **Bereitstellung**:
   - `mvn package`: Erstellt die WAR-Datei
   - `/var/lib/tomcat9/webapps/`: Verzeichnis für die Anwendungsbereitstellung

## Übungen zum Verinnerlichen

### Übung 1: XML-basierte Validierung für die To-Do-Listen-Anwendung
**Ziel**: Lernen, wie man XML-basierte Validierung implementiert, um sicherzustellen, dass Aufgaben nicht leer sind und eine Mindestlänge haben.

1. **Schritt 1**: Erstelle eine Validierungsdatei für die `AddTaskAction`-Klasse.
   ```bash
   cd my-struts-todo
   nano src/main/resources/com/example/AddTaskAction-validation.xml
   ```
   Füge folgenden Inhalt ein:
   ```xml
   <!DOCTYPE validators PUBLIC
       "-//Apache Struts//XWork Validator 1.0.3//EN"
       "http://struts.apache.org/dtds/xwork-validator-1.0.3.dtd">
   <validators>
       <field name="task">
           <field-validator type="requiredstring">
               <message>Die Aufgabe darf nicht leer sein.</message>
           </field-validator>
           <field-validator type="stringlength">
               <param name="minLength">3</param>
               <param name="maxLength">100</param>
               <message>Die Aufgabe muss zwischen 3 und 100 Zeichen lang sein.</message>
           </field-validator>
       </field>
   </validators>
   ```
2. **Schritt 2**: Aktualisiere die `tasks.jsp`, um Validierungsfehler anzuzeigen.
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
           <s:fielderror fieldName="task"/>
       </s:form>
       <ul>
           <s:iterator value="tasks">
               <li><s:property /></li>
           </s:iterator>
       </ul>
   </body>
   </html>
   ```
3. **Schritt 3**: Baue die Anwendung, stelle sie in Tomcat bereit und teste die Validierung.
   ```bash
   mvn clean package
   sudo cp target/my-struts-todo.war /var/lib/tomcat9/webapps/
   sudo chown tomcat:tomcat /var/lib/tomcat9/webapps/my-struts-todo.war
   sudo chmod 644 /var/lib/tomcat9/webapps/my-struts-todo.war
   sudo systemctl restart tomcat9
   ```
   Öffne `http://localhost:8080/my-struts-todo/listTasks` im Browser, versuche eine leere Aufgabe oder eine Aufgabe mit weniger als 3 Zeichen hinzuzufügen und überprüfe die Fehlermeldungen.

**Reflexion**: Warum ist die XML-basierte Validierung nützlich, und wie erleichtert sie die Wartung von Validierungsregeln?

### Übung 2: Annotationsbasierte Validierung für die To-Do-Listen-Anwendung
**Ziel**: Verstehen, wie man Annotationsbasierte Validierung in der `AddTaskAction`-Klasse implementiert.

1. **Schritt 1**: Aktualisiere die `AddTaskAction`-Klasse, um Annotationsbasierte Validierung zu verwenden.
   ```bash
   nano src/main/java/com/example/AddTaskAction.java
   ```
   Ersetze den Inhalt durch:
   ```java
   package com.example;
   import com.opensymphony.xwork2.ActionSupport;
   import org.apache.struts2.convention.annotation.Result;
   import org.apache.struts2.convention.annotation.Action;
   import com.opensymphony.xwork2.validator.annotations.RequiredStringValidator;
   import com.opensymphony.xwork2.validator.annotations.StringLengthFieldValidator;
   import java.sql.*;

   public class AddTaskAction extends ActionSupport {
       private String task;

       @Action(value = "addTask", results = {
           @Result(name = SUCCESS, type = "redirectAction", location = "listTasks"),
           @Result(name = INPUT, location = "/tasks.jsp")
       })
       @RequiredStringValidator(message = "Die Aufgabe darf nicht leer sein.")
       @StringLengthFieldValidator(message = "Die Aufgabe muss zwischen 3 und 100 Zeichen lang sein.", minLength = "3", maxLength = "100")
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
2. **Schritt 2**: Entferne die XML-Validierungsdatei, da sie durch Annotationen ersetzt wird.
   ```bash
   rm src/main/resources/com/example/AddTaskAction-validation.xml
   ```
3. **Schritt 3**: Baue die Anwendung, stelle sie in Tomcat bereit und teste die Validierung.
   ```bash
   mvn clean package
   sudo cp target/my-struts-todo.war /var/lib/tomcat9/webapps/
   sudo chown tomcat:tomcat /var/lib/tomcat9/webapps/my-struts-todo.war
   sudo chmod 644 /var/lib/tomcat9/webapps/my-struts-todo.war
   sudo systemctl restart tomcat9
   ```
   Öffne `http://localhost:8080/my-struts-todo/listTasks` im Browser, versuche ungültige Eingaben (z. B. leer oder zu kurz) und überprüfe die Fehlermeldungen.

**Reflexion**: Wie unterscheidet sich die Annotationsbasierte Validierung von der XML-basierten, und wann ist welche Methode vorzuziehen?

### Übung 3: Benutzerdefinierte Validierung mit addFieldError
**Ziel**: Lernen, wie man benutzerdefinierte Validierungslogik mit `addFieldError` in der Action-Klasse implementiert.

1. **Schritt 1**: Aktualisiere die `AddTaskAction`-Klasse, um eine benutzerdefinierte Validierung hinzuzufügen, die prüft, ob die Aufgabe das Wort "verboten" enthält.
   ```bash
   nano src/main/java/com/example/AddTaskAction.java
   ```
   Ersetze den Inhalt durch:
   ```java
   package com.example;
   import com.opensymphony.xwork2.ActionSupport;
   import org.apache.struts2.convention.annotation.Result;
   import org.apache.struts2.convention.annotation.Action;
   import com.opensymphony.xwork2.validator.annotations.RequiredStringValidator;
   import com.opensymphony.xwork2.validator.annotations.StringLengthFieldValidator;
   import java.sql.*;

   public class AddTaskAction extends ActionSupport {
       private String task;

       @Action(value = "addTask", results = {
           @Result(name = SUCCESS, type = "redirectAction", location = "listTasks"),
           @Result(name = INPUT, location = "/tasks.jsp")
       })
       @RequiredStringValidator(message = "Die Aufgabe darf nicht leer sein.")
       @StringLengthFieldValidator(message = "Die Aufgabe muss zwischen 3 und 100 Zeichen lang sein.", minLength = "3", maxLength = "100")
       public String add() {
           if (task != null && task.toLowerCase().contains("verboten")) {
               addFieldError("task", "Die Aufgabe darf das Wort 'verboten' nicht enthalten.");
               return INPUT;
           }
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
2. **Schritt 2**: Baue die Anwendung, stelle sie in Tomcat bereit und teste die benutzerdefinierte Validierung.
   ```bash
   mvn clean package
   sudo cp target/my-struts-todo.war /var/lib/tomcat9/webapps/
   sudo chown tomcat:tomcat /var/lib/tomcat9/webapps/my-struts-todo.war
   sudo chmod 644 /var/lib/tomcat9/webapps/my-struts-todo.war
   sudo systemctl restart tomcat9
   ```
3. **Schritt 3**: Öffne `http://localhost:8080/my-struts-todo/listTasks` im Browser, versuche eine Aufgabe mit dem Wort "verboten" hinzuzufügen und überprüfe die Fehlermeldung.

**Reflexion**: Wie kann `addFieldError` für komplexe Validierungslogik verwendet werden, und warum ist es wichtig, benutzerdefinierte Validierungen zu implementieren?

## Tipps für den Erfolg
- Überprüfe die Tomcat-Logs (`/var/log/tomcat9/catalina.out`) bei Validierungs- oder Bereitstellungsproblemen.
- Verwende eine IDE wie IntelliJ IDEA, um Struts-Annotationen und Validierungsfehler einfacher zu debuggen.
- Teste Validierungsregeln schrittweise, um sicherzustellen, dass sie wie erwartet funktionieren.
- Sichere die Anwendung weiter, indem du Eingaben mit `PreparedStatement` (bereits verwendet) und zusätzlichen Sicherheits-Headern (z. B. CSP) schützt.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Validierungslogik in Apache Struts mit XML-basierten, Annotationsbasierten und benutzerdefinierten Methoden implementieren, um Benutzereingaben in einer To-Do-Listen-Anwendung zu prüfen. Durch die Übungen haben Sie praktische Erfahrung mit Struts-Validierungsmechanismen und der Anzeige von Fehlern in JSPs gesammelt. Diese Fähigkeiten sind essenziell für die Entwicklung sicherer und benutzerfreundlicher Webanwendungen. Üben Sie weiter, um komplexere Validierungen oder fortgeschrittene Struts-Features zu meistern!

**Nächste Schritte**:
- Erkunden Sie Struts-Plugins wie das Hibernate-Plugin für ORM-Integration.
- Implementieren Sie Sicherheits-Header wie CSP und HSTS (siehe vorherige Anleitung).
- Lesen Sie die Struts-Dokumentation für fortgeschrittene Validierungsoptionen wie benutzerdefinierte Validatoren.

**Quellen**:
- Offizielle Apache Struts-Dokumentation: https://struts.apache.org/
- Struts 2 Validation-Dokumentation: https://struts.apache.org/core-developers/validation
- Apache Tomcat-Dokumentation: https://tomcat.apache.org/tomcat-9.0-doc/
- MySQL Connector/J-Dokumentation: https://dev.mysql.com/doc/connector-j/en/