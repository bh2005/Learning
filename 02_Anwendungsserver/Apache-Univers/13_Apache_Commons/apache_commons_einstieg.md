# Praxisorientierte Anleitung: Einstieg in Apache Commons auf Debian

## Einführung
Apache Commons ist eine Sammlung von Open-Source-Java-Bibliotheken, die nützliche Funktionen für allgemeine Programmieraufgaben bereitstellen, wie String-Manipulation, Dateioperationen, Mathematik und mehr. Diese Bibliotheken ergänzen die Java-Standardbibliothek und sparen Entwicklungszeit durch vorgefertigte, getestete Lösungen. Diese Anleitung zeigt Ihnen, wie Sie Apache Commons-Bibliotheken in einem Java-Projekt auf einem Debian-System mit Maven integrieren und verwenden. Wir konzentrieren uns auf die Bibliotheken **Commons Lang**, **Commons IO** und **Commons Math**. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, Apache Commons für effiziente Java-Entwicklung einzusetzen. Diese Anleitung ist ideal für Java-Entwickler, die ihre Projekte mit robusten Hilfsbibliotheken erweitern möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Java Development Kit (JDK) installiert (mindestens Java 8, empfohlen Java 11)
- Apache Maven installiert (z. B. Maven 3.9.9, wie in der vorherigen Maven-Anleitung)
- Mindestens 2 GB RAM und ausreichend Festplattenspeicher (mindestens 5 GB frei)
- Grundlegende Kenntnisse der Linux-Kommandozeile, Java und Maven
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie IntelliJ IDEA)

## Grundlegende Apache Commons-Konzepte und Tools
Hier sind die wichtigsten Konzepte und Tools, die wir behandeln:

1. **Apache Commons-Bibliotheken**:
   - **Commons Lang**: Erweitert die Java-Standardbibliothek für String-Manipulation, Datum/Zeit, Objektprüfungen
   - **Commons IO**: Vereinfacht Datei- und Stream-Operationen
   - **Commons Math**: Bietet mathematische und statistische Funktionen
2. **Integration mit Maven**:
   - Abhängigkeiten werden in der `pom.xml`-Datei definiert
   - Bibliotheken werden automatisch aus dem Maven Central Repository geladen
3. **Wichtige Befehle**:
   - `mvn compile`: Kompiliert das Projekt mit Apache Commons-Abhängigkeiten
   - `mvn package`: Erstellt ein ausführbares JAR
   - `mvn dependency:tree`: Zeigt die Abhängigkeitsstruktur

## Übungen zum Verinnerlichen

### Übung 1: Apache Commons-Bibliotheken in ein Maven-Projekt integrieren
**Ziel**: Lernen, wie man Apache Commons-Bibliotheken in ein Maven-Projekt auf einem Debian-System einfügt.

1. **Schritt 1**: Stelle sicher, dass Java und Maven installiert sind.
   ```bash
   java -version
   mvn -version
   ```
   Wenn nicht installiert, befolge die vorherige Maven-Anleitung.
2. **Schritt 2**: Erstelle ein neues Maven-Projekt.
   ```bash
   mvn archetype:generate \
       -DgroupId=com.example \
       -DartifactId=commons-app \
       -DarchetypeArtifactId=maven-archetype-quickstart \
       -DinteractiveMode=false
   cd commons-app
   ```
3. **Schritt 3**: Füge Apache Commons-Abhängigkeiten zur `pom.xml` hinzu.
   ```bash
   nano pom.xml
   ```
   Ersetze den `<dependencies>`-Abschnitt durch:
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
       <dependency>
           <groupId>commons-io</groupId>
           <artifactId>commons-io</artifactId>
           <version>2.16.1</version>
       </dependency>
       <dependency>
           <groupId>org.apache.commons</groupId>
           <artifactId>commons-math3</artifactId>
           <version>3.6.1</version>
       </dependency>
   </dependencies>
   ```
4. **Schritt 4**: Überprüfe die Abhängigkeiten.
   ```bash
   mvn dependency:tree
   ```
   Die Ausgabe zeigt die geladenen Apache Commons-Bibliotheken.

**Reflexion**: Wie vereinfacht Maven das Hinzufügen von Apache Commons-Bibliotheken, und warum ist das Maven Central Repository wichtig?

### Übung 2: Verwendung von Commons Lang und Commons IO
**Ziel**: Verstehen, wie man Commons Lang für String-Manipulation und Commons IO für Dateioperationen nutzt.

1. **Schritt 1**: Erstelle eine Java-Klasse, die Commons Lang und Commons IO verwendet.
   ```bash
   nano src/main/java/com/example/App.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   package com.example;

   import org.apache.commons.lang3.StringUtils;
   import org.apache.commons.io.FileUtils;
   import java.io.File;
   import java.io.IOException;

   public class App {
       public static void main(String[] args) {
           // Commons Lang: String-Manipulation
           String input = "  Hallo Apache Commons  ";
           String trimmed = StringUtils.trim(input);
           String reversed = StringUtils.reverse(trimmed);
           System.out.println("Original: " + input);
           System.out.println("Getrimmt und umgedreht: " + reversed);

           // Commons IO: Dateioperationen
           try {
               File file = new File("output.txt");
               FileUtils.writeStringToFile(file, reversed, "UTF-8");
               String content = FileUtils.readFileToString(file, "UTF-8");
               System.out.println("Dateiinhalt: " + content);
           } catch (IOException e) {
               e.printStackTrace();
           }
       }
   }
   ```
2. **Schritt 2**: Baue und führe die Anwendung aus.
   ```bash
   mvn clean package
   java -cp target/commons-app-1.0-SNAPSHOT.jar com.example.App
   ```
   Die Ausgabe sollte sein:
   ```
   Original:   Hallo Apache Commons  
   Getrimmt und umgedreht: snommoC ehcapA ollaH
   Dateiinhalt: snommoC ehcapA ollaH
   ```
   Überprüfe die erstellte Datei:
   ```bash
   cat output.txt
   ```

**Reflexion**: Wie vereinfachen Commons Lang und Commons IO alltägliche Programmieraufgaben, und welche Vorteile bieten sie gegenüber der Java-Standardbibliothek?

### Übung 3: Statistische Analysen mit Commons Math
**Ziel**: Lernen, wie man Commons Math für statistische Berechnungen in einem Java-Projekt verwendet.

1. **Schritt 1**: Erstelle eine Java-Klasse, die Commons Math für statistische Analysen nutzt.
   ```bash
   nano src/main/java/com/example/StatsApp.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   package com.example;

   import org.apache.commons.math3.stat.descriptive.DescriptiveStatistics;

   public class StatsApp {
       public static void main(String[] args) {
           // Erstelle ein Dataset
           double[] values = {1.2, 3.4, 2.5, 4.8, 2.9, 3.6};

           // Verwende DescriptiveStatistics für Berechnungen
           DescriptiveStatistics stats = new DescriptiveStatistics();
           for (double value : values) {
               stats.addValue(value);
           }

           // Berechne Statistiken
           double mean = stats.getMean();
           double stdDev = stats.getStandardDeviation();
           double max = stats.getMax();
           double min = stats.getMin();

           // Ausgabe
           System.out.println("Daten: " + java.util.Arrays.toString(values));
           System.out.printf("Mittelwert: %.2f%n", mean);
           System.out.printf("Standardabweichung: %.2f%n", stdDev);
           System.out.printf("Maximum: %.2f%n", max);
           System.out.printf("Minimum: %.2f%n", min);
       }
   }
   ```
2. **Schritt 2**: Aktualisiere die `pom.xml`, um den Hauptklassen-Eintrag für die neue Klasse zu setzen.
   ```bash
   nano pom.xml
   ```
   Füge innerhalb des `<build>`-Tags folgendes hinzu:
   ```xml
   <plugins>
       <plugin>
           <groupId>org.apache.maven.plugins</groupId>
           <artifactId>maven-jar-plugin</artifactId>
           <version>3.3.0</version>
           <configuration>
               <archive>
                   <manifest>
                       <mainClass>com.example.StatsApp</mainClass>
                   </manifest>
               </archive>
           </configuration>
       </plugin>
   </plugins>
   ```
3. **Schritt 3**: Baue und führe die Anwendung aus.
   ```bash
   mvn clean package
   java -jar target/commons-app-1.0-SNAPSHOT.jar
   ```
   Die Ausgabe sollte ungefähr so aussehen:
   ```
   Daten: [1.2, 3.4, 2.5, 4.8, 2.9, 3.6]
   Mittelwert: 3.07
   Standardabweichung: 1.21
   Maximum: 4.80
   Minimum: 1.20
   ```

**Reflexion**: Wie unterstützt Commons Math komplexe statistische Berechnungen, und in welchen Szenarien könnte diese Bibliothek in Big-Data-Projekten nützlich sein?

## Tipps für den Erfolg
- Überprüfe die Maven-Logs in der Konsole oder in `target/surefire-reports/` bei Build-Problemen.
- Stelle sicher, dass `JAVA_HOME` korrekt gesetzt ist (`export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64`).
- Verwende `mvn dependency:tree`, um Abhängigkeitskonflikte zu erkennen.
- Teste mit kleinen Projekten, bevor du komplexere Anwendungen mit mehreren Apache Commons-Bibliotheken entwickelst.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Apache Commons-Bibliotheken (Commons Lang, Commons IO, Commons Math) in ein Java-Projekt auf einem Debian-System mit Maven integrieren. Durch die Übungen haben Sie praktische Erfahrung mit String-Manipulation, Dateioperationen und statistischen Berechnungen gesammelt. Diese Fähigkeiten sind die Grundlage für effiziente Java-Entwicklung mit wiederverwendbaren Bibliotheken. Üben Sie weiter, um weitere Apache Commons-Bibliotheken oder Integrationen mit anderen Tools zu erkunden!

**Nächste Schritte**:
- Erkunden Sie weitere Apache Commons-Bibliotheken wie Commons Collections oder Commons Configuration.
- Integrieren Sie Apache Commons in Big-Data-Projekte mit Tools wie Apache Spark oder Flink.
- Verwenden Sie eine IDE wie IntelliJ IDEA, um die Entwicklung mit Apache Commons zu optimieren.

**Quellen**:
- Offizielle Apache Commons-Dokumentation: https://commons.apache.org/
- Commons Lang-Dokumentation: https://commons.apache.org/proper/commons-lang/
- Commons IO-Dokumentation: https://commons.apache.org/proper/commons-io/
- Commons Math-Dokumentation: https://commons.apache.org/proper/commons-math/