# Praxisorientierte Anleitung: Einstieg in Apache Flink auf Debian

## Einführung
Apache Flink ist ein Open-Source-Framework für die verteilte Verarbeitung von Datenströmen und Batch-Daten, das für seine niedrige Latenz, hohe Durchsatzraten und Zustandsverwaltung bekannt ist. Es eignet sich besonders für Echtzeit-Streaming-Anwendungen und komplexe Batch-Analysen. Diese Anleitung führt Sie in die Installation und Konfiguration von Apache Flink in einer Einzelknoten-Konfiguration auf einem Debian-System ein und zeigt Ihnen, wie Sie eine einfache Streaming- und Batch-Anwendung mit der DataStream- und DataSet-API entwickeln. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, Flink für Big-Data-Verarbeitung einzusetzen. Diese Anleitung ist ideal für Entwickler und Datenanalysten, die mit Streaming- und Batch-Verarbeitung beginnen möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Java Development Kit (JDK) installiert (mindestens Java 8, empfohlen Java 11)
- Mindestens 4 GB RAM und ausreichend Festplattenspeicher (mindestens 10 GB frei)
- Grundlegende Kenntnisse der Linux-Kommandozeile und Programmierung (z. B. Java oder Python)
- Optional: Maven für die Verwaltung von Abhängigkeiten (für Java-Anwendungen)
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie IntelliJ IDEA)

## Grundlegende Apache Flink-Konzepte und Befehle
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **Flink-Komponenten**:
   - **DataStream-API**: Verarbeitet kontinuierliche Datenströme
   - **DataSet-API**: Verarbeitet begrenzte Datensätze (Batch)
   - **JobManager und TaskManager**: JobManager koordiniert, TaskManager führt Aufgaben aus
2. **Wichtige Konfigurationsdateien**:
   - `flink-conf.yaml`: Haupt-Konfigurationsdatei für Flink
   - `masters` und `workers`: Definieren Master- und Worker-Knoten
3. **Wichtige Befehle**:
   - `start-cluster.sh`: Startet den Flink-Cluster
   - `flink run`: Führt Flink-Anwendungen aus
   - `jps`: Überprüft laufende Java-Prozesse (z. B. JobManager, TaskManager)

## Übungen zum Verinnerlichen

### Übung 1: Apache Flink installieren und konfigurieren
**Ziel**: Lernen, wie man Flink auf einem Debian-System installiert und für eine Einzelknoten-Konfiguration einrichtet.

1. **Schritt 1**: Installiere Java und Maven (falls nicht bereits vorhanden).
   ```bash
   sudo apt update
   sudo apt install -y openjdk-11-jdk maven
   java -version
   mvn -version
   ```
2. **Schritt 2**: Lade und installiere Apache Flink.
   ```bash
   wget https://downloads.apache.org/flink/flink-1.19.1/flink-1.19.1-bin-scala_2.12.tgz
   tar -xzf flink-1.19.1-bin-scala_2.12.tgz
   sudo mv flink-1.19.1 /usr/local/flink
   ```
3. **Schritt 3**: Konfiguriere Umgebungsvariablen für Flink.
   ```bash
   nano ~/.bashrc
   ```
   Füge am Ende folgende Zeilen hinzu:
   ```bash
   export FLINK_HOME=/usr/local/flink
   export PATH=$PATH:$FLINK_HOME/bin
   export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
   ```
   Aktiviere die Änderungen:
   ```bash
   source ~/.bashrc
   ```
4. **Schritt 4**: Starte den Flink-Cluster und überprüfe die Installation.
   ```bash
   /usr/local/flink/bin/start-cluster.sh
   ```
   Überprüfe, ob der Cluster läuft:
   ```bash
   jps
   ```
   Du solltest `JobManager` und `TaskManager` sehen. Öffne die Flink-Weboberfläche im Browser unter `http://localhost:8081`.

**Reflexion**: Warum ist die Trennung von JobManager und TaskManager wichtig für die Architektur von Flink?

### Übung 2: Eine einfache Batch-Verarbeitung mit der DataSet-API
**Ziel**: Verstehen, wie man eine Batch-Anwendung mit der DataSet-API entwickelt, um einen Datensatz zu verarbeiten.

1. **Schritt 1**: Erstelle ein Maven-Projekt für eine Flink-Anwendung.
   ```bash
   mkdir flink-batch
   cd flink-batch
   mvn archetype:generate -DgroupId=com.example -DartifactId=flink-batch -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
   ```
2. **Schritt 2**: Konfiguriere die `pom.xml` für Flink-Abhängigkeiten.
   ```bash
   nano pom.xml
   ```
   Ersetze den Inhalt durch:
   ```xml
   <project xmlns="http://maven.apache.org/POM/4.0.0"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
       <modelVersion>4.0.0</modelVersion>
       <groupId>com.example</groupId>
       <artifactId>flink-batch</artifactId>
       <version>1.0-SNAPSHOT</version>
       <dependencies>
           <dependency>
               <groupId>org.apache.flink</groupId>
               <artifactId>flink-java</artifactId>
               <version>1.19.1</version>
           </dependency>
           <dependency>
               <groupId>org.apache.flink</groupId>
               <artifactId>flink-clients</artifactId>
               <version>1.19.1</version>
           </dependency>
       </dependencies>
       <build>
           <plugins>
               <plugin>
                   <groupId>org.apache.maven.plugins</groupId>
                   <artifactId>maven-compiler-plugin</artifactId>
                   <version>3.8.1</version>
                   <configuration>
                       <source>11</source>
                       <target>11</target>
                   </configuration>
               </plugin>
           </plugins>
       </build>
   </project>
   ```
3. **Schritt 3**: Erstelle eine Java-Anwendung für Batch-WordCount.
   ```bash
   nano src/main/java/com/example/WordCount.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   package com.example;

   import org.apache.flink.api.java.DataSet;
   import org.apache.flink.api.java.ExecutionEnvironment;
   import org.apache.flink.api.java.tuple.Tuple2;

   public class WordCount {
       public static void main(String[] args) throws Exception {
           ExecutionEnvironment env = ExecutionEnvironment.getExecutionEnvironment();
           DataSet<String> text = env.fromElements(
               "Hallo Flink",
               "Dies ist ein Test",
               "Apache Flink ist großartig"
           );
           DataSet<Tuple2<String, Integer>> counts = text
               .flatMap((line, out) -> {
                   for (String word : line.split("\\s+")) {
                       out.collect(new Tuple2<>(word, 1));
                   }
               }, types(Tuple2.class))
               .groupBy(0)
               .sum(1);
           counts.print();
       }
   }
   ```
4. **Schritt 4**: Baue und führe die Anwendung aus.
   ```bash
   mvn clean package
   /usr/local/flink/bin/flink run -c com.example.WordCount target/flink-batch-1.0-SNAPSHOT.jar
   ```
   Die Ausgabe zeigt die Worthäufigkeiten (z. B. `Hallo: 1`, `Flink: 2`).

**Reflexion**: Wie unterscheidet sich die DataSet-API von Spark’s Batch-Verarbeitung, und welche Vorteile bietet Flink für Batch-Analysen?

### Übung 3: Eine einfache Streaming-Anwendung mit der DataStream-API
**Ziel**: Lernen, wie man eine Streaming-Anwendung mit der DataStream-API entwickelt, um einen simulierten Datenstrom zu verarbeiten.

1. **Schritt 1**: Erstelle ein Maven-Projekt für eine Streaming-Anwendung (oder erweitere das bestehende).
   ```bash
   mkdir flink-streaming
   cd flink-streaming
   mvn archetype:generate -DgroupId=com.example -DartifactId=flink-streaming -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
   ```
2. **Schritt 2**: Konfiguriere die `pom.xml` für Flink-Streaming-Abhängigkeiten.
   ```bash
   nano pom.xml
   ```
   Ersetze den Inhalt durch:
   ```xml
   <project xmlns="http://maven.apache.org/POM/4.0.0"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
       <modelVersion>4.0.0</modelVersion>
       <groupId>com.example</groupId>
       <artifactId>flink-streaming</artifactId>
       <version>1.0-SNAPSHOT</version>
       <dependencies>
           <dependency>
               <groupId>org.apache.flink</groupId>
               <artifactId>flink-streaming-java</artifactId>
               <version>1.19.1</version>
           </dependency>
           <dependency>
               <groupId>org.apache.flink</groupId>
               <artifactId>flink-clients</artifactId>
               <version>1.19.1</version>
           </dependency>
       </dependencies>
       <build>
           <plugins>
               <plugin>
                   <groupId>org.apache.maven.plugins</groupId>
                   <artifactId>maven-compiler-plugin</artifactId>
                   <version>3.8.1</version>
                   <configuration>
                       <source>11</source>
                       <target>11</target>
                   </configuration>
               </plugin>
           </plugins>
       </build>
   </project>
   ```
3. **Schritt 3**: Erstelle eine Java-Anwendung für Streaming-WordCount.
   ```bash
   nano src/main/java/com/example/StreamingWordCount.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   package com.example;

   import org.apache.flink.streaming.api.datastream.DataStream;
   import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
   import org.apache.flink.streaming.api.functions.source.SourceFunction;

   public class StreamingWordCount {
       public static void main(String[] args) throws Exception {
           StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
           DataStream<String> text = env.addSource(new SimpleStringSource());
           DataStream<String> words = text
               .flatMap((line, out) -> {
                   for (String word : line.split("\\s+")) {
                       out.collect(word);
                   }
               }, types(String.class))
               .keyBy(word -> word)
               .sum(1);
           words.print();
           env.execute("Streaming Word Count");
       }

       public static class SimpleStringSource implements SourceFunction<String> {
           private volatile boolean running = true;

           @Override
           public void run(SourceContext<String> ctx) throws Exception {
               String[] messages = {"Hallo Flink", "Dies ist ein Test", "Flink ist großartig"};
               int i = 0;
               while (running) {
                   ctx.collect(messages[i % messages.length]);
                   i++;
                   Thread.sleep(1000);
               }
           }

           @Override
           public void cancel() {
               running = false;
           }
       }
   }
   ```
4. **Schritt 4**: Baue und führe die Anwendung aus.
   ```bash
   mvn clean package
   /usr/local/flink/bin/flink run -c com.example.StreamingWordCount target/flink-streaming-1.0-SNAPSHOT.jar
   ```
   Die Ausgabe zeigt die Worthäufigkeiten in Echtzeit. Beende mit `Ctrl+C` oder stoppe den Cluster:
   ```bash
   /usr/local/flink/bin/stop-cluster.sh
   ```

**Reflexion**: Wie unterstützt die DataStream-API die Echtzeit-Verarbeitung, und welche Vorteile bietet Flink’s Zustandsverwaltung für Streaming-Anwendungen?

## Tipps für den Erfolg
- Überprüfe die Flink-Logs in `$FLINK_HOME/log/` bei Problemen mit der Ausführung.
- Stelle sicher, dass `JAVA_HOME` korrekt gesetzt ist (`export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64`).
- Verwende `jps`, um zu überprüfen, ob JobManager und TaskManager laufen.
- Teste mit kleinen Datensätzen, bevor du größere Datenmengen verarbeitest.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Apache Flink auf einem Debian-System in einer Einzelknoten-Konfiguration installieren, eine Batch-Anwendung mit der DataSet-API und eine Streaming-Anwendung mit der DataStream-API entwickeln. Durch die Übungen haben Sie praktische Erfahrung mit Flink’s APIs und der Cluster-Verwaltung gesammelt. Diese Fähigkeiten sind die Grundlage für skalierbare Streaming- und Batch-Verarbeitung. Üben Sie weiter, um komplexere Anwendungen oder Mehrknoten-Cluster zu meistern!

**Nächste Schritte**:
- Richten Sie einen Flink-Mehrknoten-Cluster ein, um verteilte Verarbeitung zu testen.
- Integrieren Sie Flink mit Apache Kafka für Echtzeit-Datenströme.
- Erkunden Sie Flink’s Table API oder SQL für einfachere Datenanalysen.

**Quellen**:
- Offizielle Apache Flink-Dokumentation: https://flink.apache.org/documentation/
- Flink Getting Started: https://nightlies.apache.org/flink/flink-docs-stable/docs/try-flink/local_installation/
- DigitalOcean Flink-Tutorial: https://www.digitalocean.com/community/tutorials/how-to-set-up-an-apache-flink-cluster-on-ubuntu-20-04