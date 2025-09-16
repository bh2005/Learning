# Praxisorientierte Anleitung: Integration von Java mit Maven für größere Projekte mit Abhängigkeiten auf Debian

## Einführung
**Apache Maven** ist ein leistungsstarkes Build-Management-Tool für Java-Projekte, das die Verwaltung von Abhängigkeiten, Builds und Projektstrukturen vereinfacht. Es verwendet eine `pom.xml`-Datei (Project Object Model), um Projektkonfigurationen und Abhängigkeiten zu definieren, und ermöglicht skalierbare Projekte durch standardisierte Prozesse. Diese Anleitung zeigt, wie Sie Maven auf einem Debian-System installieren, ein Java-Projekt mit Abhängigkeiten erstellen und es bauen. Ziel ist es, Anfängern mit Java-Grundkenntnissen die Fähigkeiten zu vermitteln, größere Projekte mit externen Bibliotheken zu verwalten. Diese Anleitung ist ideal für Lernende, die ihre Java-Projekte professionell strukturieren möchten.

**Voraussetzungen:**
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Java Development Kit (JDK) installiert (z. B. OpenJDK 11, wie in der vorherigen Java-Anleitung)
- Mindestens 2 GB RAM und ausreichend Festplattenspeicher (mindestens 5 GB frei)
- Grundlegende Kenntnisse der Linux-Kommandozeile und Java (z. B. Klassen, Methoden, Packages)
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie IntelliJ IDEA Community Edition)

## Grundlegende Maven-Konzepte und Befehle
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **Maven-Konzepte**:
   - **POM-Datei (`pom.xml`)**: Definiert Projektmetadaten, Abhängigkeiten und Build-Regeln
   - **Abhängigkeiten**: Externe Bibliotheken, die aus dem Maven Central Repository geladen werden
   - **Build-Lifecycle**: Phasen wie `compile`, `test`, `package`, `install`
2. **Wichtige Konfigurationsdateien**:
   - `pom.xml`: Hauptkonfigurationsdatei für das Projekt
   - `settings.xml`: Globale Maven-Konfiguration (optional, in `~/.m2/`)
3. **Wichtige Befehle**:
   - `mvn clean`: Löscht Build-Artefakte
   - `mvn compile`: Kompiliert den Quellcode
   - `mvn package`: Erstellt ein JAR oder WAR
   - `mvn dependency:tree`: Zeigt die Abhängigkeitsstruktur
   - `mvn archetype:generate`: Erstellt ein Projektgerüst

## Übungen zum Verinnerlichen

### Übung 1: Maven installieren und ein Projekt erstellen
**Ziel**: Lernen, wie man Maven auf einem Debian-System installiert und ein Java-Projekt mit einer Standardstruktur erstellt.

1. **Schritt 1**: Installiere Maven.
   ```bash
   sudo apt update
   sudo apt install -y maven
   ```
2. **Schritt 2**: Überprüfe die Maven-Installation.
   ```bash
   mvn -version
   ```
   Die Ausgabe sollte die Maven-Version (z. B. 3.6.3 oder höher) und die Java-Version anzeigen.
3. **Schritt 3**: Erstelle ein neues Maven-Projekt.
   ```bash
   mvn archetype:generate \
       -DgroupId=com.example \
       -DartifactId=my-maven-app \
       -DarchetypeArtifactId=maven-archetype-quickstart \
       -DinteractiveMode=false
   cd my-maven-app
   ```
   Dies erstellt eine Standard-Projektstruktur:
   ```
   my-maven-app/
   ├── pom.xml
   └── src
       ├── main
       │   └── java
       │       └── com
       │           └── example
       │               └── App.java
       └── test
           └── java
               └── com
                   └── example
                       └── AppTest.java
   ```
4. **Schritt 4**: Überprüfe die `pom.xml`-Datei.
   ```bash
   nano pom.xml
   ```
   Der Inhalt sieht etwa so aus:
   ```xml
   <project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
     <modelVersion>4.0.0</modelVersion>
     <groupId>com.example</groupId>
     <artifactId>my-maven-app</artifactId>
     <version>1.0-SNAPSHOT</version>
     <dependencies>
       <dependency>
         <groupId>junit</groupId>
         <artifactId>junit</artifactId>
         <version>3.8.1</version>
         <scope>test</scope>
       </dependency>
     </dependencies>
   </project>
   ```
5. **Schritt 5**: Baue und führe das Projekt aus.
   ```bash
   mvn clean compile
   mvn exec:java -Dexec.mainClass="com.example.App"
   ```
   Die Ausgabe sollte sein: `Hello World!` (Standardausgabe von `App.java`).

**Reflexion**: Wie strukturiert Maven Projekte, und warum ist die `pom.xml`-Datei zentral für die Projektverwaltung?

### Übung 2: Abhängigkeiten hinzufügen und verwenden
**Ziel**: Verstehen, wie man externe Bibliotheken (z. B. Apache Commons Lang) hinzufügt und in einem Java-Projekt verwendet.

1. **Schritt 1**: Füge eine Abhängigkeit zu `pom.xml` hinzu.
   ```bash
   nano pom.xml
   ```
   Füge die Abhängigkeit für Apache Commons Lang im `<dependencies>`-Abschnitt hinzu:
   ```xml
   <dependencies>
       <dependency>
           <groupId>junit</groupId>
           <artifactId>junit</artifactId>
           <version>3.8.1</version>
           <scope>test</scope>
       </dependency>
       <dependency>
           <groupId>org.apache.commons</groupId>
           <artifactId>commons-lang3</artifactId>
           <version>3.17.0</version>
       </dependency>
   </dependencies>
   ```
2. **Schritt 2**: Aktualisiere die Hauptklasse, um die Bibliothek zu nutzen.
   ```bash
   nano src/main/java/com/example/App.java
   ```
   Ersetze den Inhalt durch:
   ```java
   package com.example;

   import org.apache.commons.lang3.StringUtils;

   public class App {
       public static void main(String[] args) {
           String input = "  Hallo, Maven!  ";
           String trimmed = StringUtils.trim(input);
           String reversed = StringUtils.reverse(trimmed);
           System.out.println("Original: " + input);
           System.out.println("Getrimmt: " + trimmed);
           System.out.println("Umgedreht: " + reversed);
       }
   }
   ```
3. **Schritt 3**: Baue und führe das Projekt aus.
   ```bash
   mvn clean package
   mvn exec:java -Dexec.mainClass="com.example.App"
   ```
   Die Ausgabe sollte sein:
   ```
   Original:   Hallo, Maven!  
   Getrimmt: Hallo, Maven!
   Umgedreht: !nevaM ,ollaH
   ```
4. **Schritt 4**: Überprüfe die Abhängigkeiten.
   ```bash
   mvn dependency:tree
   ```
   Die Ausgabe zeigt die Abhängigkeitsstruktur, einschließlich `commons-lang3`.

**Reflexion**: Wie vereinfacht Maven die Verwaltung von Abhängigkeiten im Vergleich zu manuellem Herunterladen von JAR-Dateien?

### Übung 3: Ein größeres Projekt mit mehreren Klassen und Tests
**Ziel**: Lernen, wie man ein größeres Projekt mit mehreren Klassen, Abhängigkeiten und Unit-Tests erstellt.

1. **Schritt 1**: Füge JUnit 5 für Tests hinzu.
   ```bash
   nano pom.xml
   ```
   Ersetze die JUnit-Abhängigkeit durch JUnit 5:
   ```xml
   <dependencies>
       <dependency>
           <groupId>org.junit.jupiter</groupId>
           <artifactId>junit-jupiter-api</artifactId>
           <version>5.11.2</version>
           <scope>test</scope>
       </dependency>
       <dependency>
           <groupId>org.apache.commons</groupId>
           <artifactId>commons-lang3</artifactId>
           <version>3.17.0</version>
       </dependency>
   </dependencies>
   <build>
       <plugins>
           <plugin>
               <groupId>org.apache.maven.plugins</groupId>
               <artifactId>maven-surefire-plugin</artifactId>
               <version>3.5.0</version>
           </plugin>
       </plugins>
   </build>
   ```
2. **Schritt 2**: Erstelle eine neue Klasse für Berechnungen.
   ```bash
   nano src/main/java/com/example/Calculator.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   package com.example;

   import org.apache.commons.lang3.StringUtils;

   public class Calculator {
       public int add(int a, int b) {
           return a + b;
       }

       public String formatResult(String prefix, int result) {
           return StringUtils.capitalize(prefix) + ": " + result;
       }
   }
   ```
3. **Schritt 3**: Erstelle einen Unit-Test für die Klasse.
   ```bash
   nano src/test/java/com/example/CalculatorTest.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   package com.example;

   import org.junit.jupiter.api.Test;
   import static org.junit.jupiter.api.Assertions.assertEquals;

   public class CalculatorTest {
       @Test
       void testAdd() {
           Calculator calc = new Calculator();
           assertEquals(5, calc.add(2, 3), "2 + 3 sollte 5 ergeben");
       }

       @Test
       void testFormatResult() {
           Calculator calc = new Calculator();
           assertEquals("Summe: 10", calc.formatResult("summe", 10), "Formatierung sollte korrekt sein");
       }
   }
   ```
4. **Schritt 4**: Baue das Projekt und führe die Tests aus.
   ```bash
   mvn clean test
   ```
   Die Ausgabe sollte erfolgreiche Tests anzeigen (z. B. "Tests run: 2, Failures: 0").
5. **Schritt 5**: Erstelle ein ausführbares JAR.
   ```bash
   nano pom.xml
   ```
   Füge im `<build>`-Abschnitt einen Plugin-Eintrag hinzu:
   ```xml
   <build>
       <plugins>
           <plugin>
               <groupId>org.apache.maven.plugins</groupId>
               <artifactId>maven-surefire-plugin</artifactId>
               <version>3.5.0</version>
           </plugin>
           <plugin>
               <groupId>org.apache.maven.plugins</groupId>
               <artifactId>maven-jar-plugin</artifactId>
               <version>3.4.2</version>
               <configuration>
                   <archive>
                       <manifest>
                           <mainClass>com.example.App</mainClass>
                       </manifest>
                   </archive>
               </configuration>
           </plugin>
       </plugins>
   </build>
   ```
   Baue das JAR und führe es aus:
   ```bash
   mvn clean package
   java -jar target/my-maven-app-1.0-SNAPSHOT.jar
   ```
   Die Ausgabe sollte die Ergebnisse aus `App.java` zeigen.

**Reflexion**: Wie unterstützen Unit-Tests die Qualitätssicherung, und warum ist die Standard-Projektstruktur von Maven für größere Projekte nützlich?

## Tipps für den Erfolg
- Überprüfe die Maven-Logs in der Konsole oder in `target/surefire-reports/` bei Build-Problemen.
- Verwende `mvn dependency:tree`, um Abhängigkeitskonflikte zu erkennen.
- Stelle sicher, dass `JAVA_HOME` korrekt gesetzt ist (`export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64`).
- Nutze eine IDE wie IntelliJ IDEA, um die `pom.xml`-Datei und Abhängigkeiten einfacher zu verwalten.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Maven auf einem Debian-System installieren, ein Java-Projekt mit Abhängigkeiten erstellen und Unit-Tests sowie Builds für größere Projekte durchführen. Durch die Übungen haben Sie praktische Erfahrung mit der Strukturierung von Projekten, der Verwaltung von Bibliotheken und der Automatisierung von Builds gesammelt. Diese Fähigkeiten sind essenziell für die Entwicklung skalierbarer Java-Anwendungen. Üben Sie weiter, um fortgeschrittene Maven-Features wie Multi-Module-Projekte zu meistern!

**Nächste Schritte**:
- Erkunden Sie fortgeschrittene Maven-Konzepte wie Multi-Module-Projekte oder benutzerdefinierte Plugins.
- Integrieren Sie Maven mit Tools wie Jenkins für Continuous Integration.
- Verwenden Sie eine IDE wie IntelliJ IDEA, um die Entwicklung und das Debugging zu optimieren.

**Quellen**:
- Offizielle Maven-Dokumentation: https://maven.apache.org/guides/
- Maven Getting Started: https://maven.apache.org/guides/getting-started/
- DigitalOcean Maven-Tutorial: https://www.digitalocean.com/community/tutorials/how-to-install-apache-maven-on-ubuntu-20-04