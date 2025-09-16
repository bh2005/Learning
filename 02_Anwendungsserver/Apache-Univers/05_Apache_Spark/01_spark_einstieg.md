# Praxisorientierte Anleitung: Einstieg in Apache Spark auf Debian

## Einführung
Apache Spark ist ein Open-Source-Framework für die verteilte Verarbeitung großer Datenmengen, das für seine Geschwindigkeit und Benutzerfreundlichkeit bekannt ist. Es bietet APIs für DataFrames, Spark SQL, maschinelles Lernen und Streaming. Diese Anleitung führt Sie in die Installation und Konfiguration von Apache Spark in einer Einzelknoten-Konfiguration auf einem Debian-System ein und zeigt Ihnen, wie Sie eine einfache Datenverarbeitungsanwendung mit Spark SQL ausführen. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, Spark für Big-Data-Analysen einzusetzen. Diese Anleitung ist ideal für Entwickler und Datenanalysten, die mit Big Data arbeiten möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Java Development Kit (JDK) installiert (mindestens Java 8, empfohlen Java 11)
- Mindestens 4 GB RAM und ausreichend Festplattenspeicher (mindestens 10 GB frei)
- Grundlegende Kenntnisse der Linux-Kommandozeile und Programmierung (z. B. Python oder Scala)
- Optional: Python installiert (für PySpark)
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie IntelliJ IDEA)

## Grundlegende Apache Spark-Konzepte und Befehle
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **Spark-Komponenten**:
   - **Spark Core**: Kernfunktionalität mit RDDs (Resilient Distributed Datasets)
   - **Spark SQL**: Verarbeitung strukturierter Daten mit DataFrames und SQL
   - **Driver und Executors**: Driver koordiniert, Executors führen Aufgaben aus
2. **Wichtige Konfigurationsdateien**:
   - `spark-defaults.conf`: Globale Spark-Einstellungen
   - `spark-env.sh`: Umgebungsvariablen für Spark
3. **Wichtige Befehle**:
   - `spark-shell`: Interaktive Scala-Shell für Spark
   - `pyspark`: Interaktive Python-Shell für Spark
   - `spark-submit`: Ausführen von Spark-Anwendungen
   - `jps`: Überprüft laufende Java-Prozesse (z. B. Spark-Prozesse)

## Übungen zum Verinnerlichen

### Übung 1: Apache Spark installieren und konfigurieren
**Ziel**: Lernen, wie man Spark auf einem Debian-System installiert und für die Einzelknoten-Verarbeitung einrichtet.

1. **Schritt 1**: Installiere Java und Python (falls nicht bereits vorhanden).
   ```bash
   sudo apt update
   sudo apt install -y openjdk-11-jdk python3
   ```
2. **Schritt 2**: Lade und installiere Apache Spark.
   ```bash
   wget https://downloads.apache.org/spark/spark-3.5.3/spark-3.5.3-bin-hadoop3.tgz
   tar -xzf spark-3.5.3-bin-hadoop3.tgz
   sudo mv spark-3.5.3-bin-hadoop3 /usr/local/spark
   ```
3. **Schritt 3**: Konfiguriere Umgebungsvariablen für Spark.
   ```bash
   nano ~/.bashrc
   ```
   Füge am Ende folgende Zeilen hinzu:
   ```bash
   export SPARK_HOME=/usr/local/spark
   export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin
   export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
   ```
   Aktiviere die Änderungen:
   ```bash
   source ~/.bashrc
   ```
4. **Schritt 4**: Teste die Spark-Installation mit der interaktiven Shell.
   ```bash
   spark-shell
   ```
   In der Spark-Shell führe ein einfaches Kommando aus:
   ```scala
   sc.parallelize(1 to 10).sum()
   ```
   Beende die Shell mit `:q`. Überprüfe mit `jps`, ob Spark-Prozesse liefen.

**Reflexion**: Warum ist Spark schneller als Hadoop MapReduce, und wie unterstützt die interaktive Shell die Entwicklung?

### Übung 2: Datenverarbeitung mit Spark SQL
**Ziel**: Verstehen, wie man Spark SQL verwendet, um strukturierte Daten zu analysieren.

1. **Schritt 1**: Erstelle eine Beispieldatendatei im JSON-Format.
   ```bash
   nano sample.json
   ```
   Füge folgenden Inhalt ein:
   ```json
   {"name": "Alice", "age": 25, "city": "Berlin"}
   {"name": "Bob", "age": 30, "city": "München"}
   {"name": "Charlie", "age": 35, "city": "Hamburg"}
   ```
2. **Schritt 2**: Starte die PySpark-Shell und lade die JSON-Datei.
   ```bash
   pyspark
   ```
   Führe in der PySpark-Shell folgendes aus:
   ```python
   df = spark.read.json("file:///home/$USER/sample.json")
   df.show()
   df.createOrReplaceTempView("people")
   spark.sql("SELECT name, age FROM people WHERE age > 25").show()
   ```
   Beende die Shell mit `exit()`.
3. **Schritt 3**: Überprüfe die Ausgabe. Die Ergebnisse sollten `Bob` und `Charlie` anzeigen.

**Reflexion**: Wie erleichtert Spark SQL die Arbeit mit strukturierten Daten im Vergleich zu reinen RDD-Operationen?

### Übung 3: Eine eigenständige Spark-Anwendung erstellen und ausführen
**Ziel**: Lernen, wie man eine einfache Spark-Anwendung in Python schreibt und mit `spark-submit` ausführt.

1. **Schritt 1**: Erstelle eine Python-Datei für die Spark-Anwendung.
   ```bash
   nano wordcount.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from pyspark.sql import SparkSession

   spark = SparkSession.builder.appName("WordCount").getOrCreate()
   text_file = spark.sparkContext.textFile("file:///home/$USER/test.txt")
   counts = text_file.flatMap(lambda line: line.split()) \
                     .map(lambda word: (word, 1)) \
                     .reduceByKey(lambda a, b: a + b)
   counts.saveAsTextFile("file:///home/$USER/output")
   spark.stop()
   ```
2. **Schritt 2**: Erstelle eine Testdatei für die Verarbeitung.
   ```bash
   echo "Hallo Spark\nDies ist ein Test\nApache Spark ist großartig" > test.txt
   ```
3. **Schritt 3**: Führe die Anwendung mit `spark-submit` aus.
   ```bash
   spark-submit wordcount.py
   ```
   Überprüfe die Ergebnisse:
   ```bash
   cat output/part*
   ```
   Die Ausgabe zeigt die Worthäufigkeit der Wörter (z. B. `('Hallo', 1)`, `('Spark', 2)`).

**Reflexion**: Wie vereinfacht `spark-submit` die Ausführung von Spark-Anwendungen, und welche Vorteile bietet die Python-API (PySpark)?

## Tipps für den Erfolg
- Überprüfe die Spark-Logs in `$SPARK_HOME/logs/` bei Problemen mit der Ausführung.
- Stelle sicher, dass `JAVA_HOME` korrekt gesetzt ist, da Spark darauf angewiesen ist.
- Verwende `jps`, um zu überprüfen, ob Spark-Prozesse laufen.
- Teste mit kleinen Datensätzen, bevor du größere Datenmengen verarbeitest.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Apache Spark auf einem Debian-System in einer Einzelknoten-Konfiguration installieren, Daten mit Spark SQL verarbeiten und eine eigenständige Spark-Anwendung ausführen. Durch die Übungen haben Sie praktische Erfahrung mit DataFrames, Spark SQL und PySpark gesammelt. Diese Fähigkeiten sind die Grundlage für die Arbeit mit Big Data in Spark. Üben Sie weiter, um komplexere Anwendungen oder Mehrknoten-Cluster zu meistern!

**Nächste Schritte**:
- Richten Sie einen Spark-Mehrknoten-Cluster ein, um verteilte Verarbeitung zu testen.
- Integrieren Sie Spark mit Hadoop HDFS für persistente Speicherung.
- Erkunden Sie Spark-Features wie MLlib für maschinelles Lernen oder Structured Streaming.

**Quellen**:
- Offizielle Apache Spark-Dokumentation: https://spark.apache.org/docs/latest/
- PySpark-Dokumentation: https://spark.apache.org/docs/latest/api/python/
- DigitalOcean Spark-Tutorial: https://www.digitalocean.com/community/tutorials/how-to-install-apache-spark-on-ubuntu-20-04