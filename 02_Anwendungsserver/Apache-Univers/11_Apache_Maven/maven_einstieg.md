# Praxisorientierte Anleitung: Einstieg in Apache Maven auf Debian

## Einführung
Apache Maven ist ein Open-Source-Build-Management-Tool, das hauptsächlich für Java-Projekte verwendet wird. Es vereinfacht und standardisiert den Build-Prozess durch eine zentrale Konfigurationsdatei (`pom.xml`) und automatisiert Abhängigkeitsmanagement, Kompilierung und Packaging. Diese Anleitung führt Sie in die Installation und Konfiguration von Apache Maven auf einem Debian-System ein und zeigt Ihnen, wie Sie ein einfaches Java-Projekt erstellen, Abhängigkeiten hinzufügen und einen Build durchführen. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, Maven für die Verwaltung von Softwareprojekten einzusetzen. Diese Anleitung ist ideal für Entwickler, die den Build-Prozess ihrer Java-Anwendungen optimieren möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Java Development Kit (JDK) installiert (mindestens Java 8, empfohlen Java 11)
- Mindestens 2 GB RAM und ausreichend Festplattenspeicher (mindestens 5 GB frei)
- Grundlegende Kenntnisse der Linux-Kommandozeile und Java
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie IntelliJ IDEA)

## Grundlegende Apache Maven-Konzepte und Befehle
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **Maven-Konzepte**:
   - **POM (Project Object Model)**: Die `pom.xml`-Datei definiert Projektmetadaten, Abhängigkeiten und Build-Konfigurationen
   - **Repositories**: Zentrale oder lokale Speicherorte für Bibliotheken und Abhängigkeiten
   - **Lifecycle und Phases**: Standardisierte Build-Phasen wie `compile`, `test`, `package`, `install`
2. **Wichtige Konfigurationsdateien**:
   - `pom.xml`: Haupt-Konfigurationsdatei für ein Maven-Projekt
   - `settings.xml`: Globale Konfiguration für Maven (z. B. für benutzerdefinierte Repositories)
3. **Wichtige Befehle**:
   - `mvn archetype:generate`: Erstellt ein neues Projekt aus einer Vorlage
   - `mvn clean`: Löscht Build-Artefakte
   - `mvn compile`: Kompiliert den Quellcode
   - `mvn package`: Erstellt ein ausführbares Artefakt (z. B. JAR-Datei)
   - `mvn install`: Installiert das Artefakt im lokalen Repository

## Übungen zum Verinnerlichen

### Übung 1: Apache Maven installieren und konfigurieren
**Ziel**: Lernen, wie man Maven auf einem Debian-System installiert und für die Projektverwaltung einrichtet.

1. **Schritt 1**: Installiere Java (falls nicht bereits vorhanden).
   ```bash
   sudo apt update
   sudo apt install -y openjdk-11-jdk
   java -version
   ```
2. **Schritt 2**: Lade und installiere Apache Maven.
   ```bash
   wget https://downloads.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz
   tar -xzf apache-maven-3.9.9-bin.tar.gz
   sudo mv apache-maven-3.9.9 /usr/local/maven
   ```
3. **Schritt 3**: Konfiguriere Umgebungsvariablen für Maven.
   ```bash
   nano ~/.bashrc
   ```
   Füge am Ende folgende Zeilen hinzu:
   ```bash
   export MAVEN_HOME=/usr/local/maven
   export PATH=$PATH:$MAVEN_HOME/bin
   export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
   ```
   Aktiviere die Änderungen:
   ```bash
   source ~/.bashrc
   ```
4. **Schritt 4**: Teste die Maven-Installation.
   ```bash
   mvn -version
   ```
   Die Ausgabe sollte die Maven-Version (z. B. 3.9.9) und die Java-Version anzeigen.

**Reflexion**: Warum ist das Konzept des zentralen Repositories in Maven wichtig, und wie unterscheidet sich Maven von anderen Build-Tools wie Ant?

### Übung 2: Ein einfaches Maven-Projekt erstellen und bauen
**Ziel**: Verstehen, wie man ein Java-Projekt mit Maven erstellt, konfiguriert und kompiliert.

1. **Schritt 1**: Erstelle ein neues Maven-Projekt mit einer Vorlage.
   ```bash
   mvn archetype:generate \
       -DgroupId=com.example \
       -DartifactId=myapp \
       -DarchetypeArtifactId=maven-archetype-quickstart \
       -DinteractiveMode=false
   cd myapp
   ```
   Dies erstellt eine Projektstruktur mit einer `pom.xml`-Datei und einem Beispiel-Java-Programm.
2. **Schritt 2**: Überprüfe die `pom.xml`-Datei.
   ```bash
   cat pom.xml
   ```
   Die Datei enthält Metadaten, Abhängigkeiten (z. B. JUnit) und Build-Konfigurationen.
3. **Schritt 3**: Kompiliere und teste das Projekt.
   ```bash
   mvn compile
   mvn test
   ```
   Die Ausgabe zeigt, dass der Quellcode kompiliert und die Tests ausgeführt wurden.
4. **Schritt 4**: Verpacke das Projekt in eine JAR-Datei.
   ```bash
   mvn package
   ```
   Überprüfe das erstellte Artefakt:
   ```bash
   ls target/
   ```
   Du solltest `myapp-1.0-SNAPSHOT.jar` sehen. Führe die JAR-Datei aus:
   ```bash
   java -cp target/myapp-1.0-SNAPSHOT.jar com.example.App
   ```

**Reflexion**: Wie vereinfacht die `pom.xml`-Datei die Verwaltung von Abhängigkeiten und Build-Prozessen, und was sind die Vorteile der standardisierten Projektstruktur?

### Übung 3: Eine Abhängigkeit hinzufügen und eine benutzerdefinierte Anwendung erstellen
**Ziel**: Lernen, wie man externe Abhängigkeiten hinzufügt und eine benutzerdefinierte Java-Anwendung mit Maven erstellt.

1. **Schritt 1**: Füge eine Abhängigkeit zu `pom.xml` hinzu (z. B. Apache Commons Lang für String-Operationen).
   ```bash
   nano pom.xml
   ```
   Füge innerhalb des `<dependencies>`-Tags folgendes hinzu:
   ```xml
   <dependency>
       <groupId>org.apache.commons</groupId>
       <artifactId>commons-lang3</artifactId>
       <version>3.17.0</version>
   </dependency>
   ```
   Die aktualisierte `pom.xml` sollte wie folgt aussehen (Auszug):
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
2. **Schritt 2**: Erstelle eine benutzerdefinierte Java-Anwendung, die die Abhängigkeit nutzt.
   ```bash
   nano src/main/java/com/example/App.java
   ```
   Ersetze den Inhalt durch:
   ```java
   package com.example;

   import org.apache.commons.lang3.StringUtils;

   public class App {
       public static void main(String[] args) {
           String input = "  Hallo Maven  ";
           String result = StringUtils.reverse(StringUtils.trim(input));
           System.out.println("Original: " + input);
           System.out.println("Umgedreht und getrimmt: " + result);
       }
   }
   ```
3. **Schritt 3**: Baue und führe die Anwendung aus.
   ```bash
   mvn clean package
   java -cp target/myapp-1.0-SNAPSHOT.jar com.example.App
   ```
   Die Ausgabe sollte sein:
   ```
   Original:   Hallo Maven  
   Umgedreht und getrimmt: nevaM ollaH
   ```

**Reflexion**: Wie automatisiert Maven das Hinzufügen von Abhängigkeiten, und welche Rolle spielt das zentrale Maven-Repository bei diesem Prozess?

## Tipps für den Erfolg
- Überprüfe die Maven-Logs in der Konsole oder in `target/surefire-reports/` bei Testfehlern.
- Stelle sicher, dass `JAVA_HOME` korrekt gesetzt ist (`export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64`).
- Verwende `mvn dependency:tree`, um die Abhängigkeitsstruktur eines Projekts zu überprüfen.
- Teste mit einfachen Projekten, bevor du komplexe Anwendungen entwickelst.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Apache Maven auf einem Debian-System installieren, ein Java-Projekt erstellen, Abhängigkeiten verwalten und Builds durchführen. Durch die Übungen haben Sie praktische Erfahrung mit der `pom.xml`-Datei, Maven-Befehlen und der Entwicklung einer Java-Anwendung gesammelt. Diese Fähigkeiten sind die Grundlage für effizientes Build-Management in Java-Projekten. Üben Sie weiter, um komplexere Projekte oder Integrationen mit anderen Tools zu meistern!

**Nächste Schritte**:
- Integrieren Sie Maven mit einer IDE wie IntelliJ IDEA oder Eclipse für eine bessere Entwicklungserfahrung.
- Erkunden Sie Maven-Plugins für fortgeschrittene Aufgaben wie Code-Analyse oder Deployment.
- Verwenden Sie Maven in Kombination mit anderen Big-Data-Tools wie Apache Spark oder Flink.

**Quellen**:
- Offizielle Apache Maven-Dokumentation: https://maven.apache.org/guides/
- Maven Getting Started: https://maven.apache.org/guides/getting-started/
- DigitalOcean Maven-Tutorial: https://www.digitalocean.com/community/tutorials/how-to-install-apache-maven-on-ubuntu-20-04