# Praxisorientierte Anleitung: Integration von Apache Kafka mit Apache Spark für Streaming-Datenanalysen auf Debian

## Einführung
Die Integration von Apache Kafka mit Apache Spark Structured Streaming ermöglicht die Verarbeitung von Echtzeit-Datenströmen mit skalierbaren Analysen. Kafka dient als Nachrichten-Broker, während Spark die Daten aggregiert und analysiert. Diese Anleitung zeigt Ihnen, wie Sie Kafka und Spark auf einem Debian-System kombinieren, um Nachrichten aus einem Kafka-Topic zu konsumieren und einfache Aggregationen (z. B. Zählen von Nachrichten) durchzuführen. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, Streaming-Datenanalysen mit Kafka und Spark umzusetzen. Die Anleitung ist ideal für Entwickler und Datenanalysten, die Echtzeit-Datenverarbeitung erkunden möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit installiertem Apache Spark (z. B. Spark 3.5.3), Apache Kafka (z. B. Kafka 3.8.0) und Java JDK (mindestens Java 8, empfohlen Java 11)
- Python 3 und PySpark installiert
- Kafka-Broker und Zookeeper laufen auf `localhost:9092` bzw. `localhost:2181`
- Root- oder Sudo-Zugriff
- Grundlegende Kenntnisse der Linux-Kommandozeile, Python, Kafka und Spark
- Mindestens 4 GB RAM und ausreichend Festplattenspeicher
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie IntelliJ IDEA)

## Grundlegende Konzepte und Techniken
Hier sind die wichtigsten Konzepte und Techniken, die wir behandeln:

1. **Kafka-Spark-Integration**:
   - **Kafka als Quelle**: Spark liest Nachrichten aus einem Kafka-Topic als Streaming DataFrame
   - **Structured Streaming**: Verarbeitet Datenströme mit der DataFrame-API
   - **spark-sql-kafka**: Bibliothek für die Kafka-Integration in Spark
2. **Wichtige Spark-Konfigurationen**:
   - `spark.sql.streaming`: Parameter für Streaming-Verarbeitung
   - `option("kafka.bootstrap.servers", ...)`: Verbindet Spark mit dem Kafka-Broker
   - `writeStream`: Gibt Streaming-Ergebnisse aus (z. B. Konsole, Datei)
3. **Wichtige Befehle**:
   - `kafka-console-producer.sh`: Produziert Testnachrichten für das Topic
   - `spark-submit`: Führt die Spark-Streaming-Anwendung aus
   - `jps`: Überprüft laufende Spark- und Kafka-Prozesse

## Übungen zum Verinnerlichen

### Übung 1: Vorbereitung von Kafka und Spark
**Ziel**: Lernen, wie man Kafka und Spark vorbereitet und die erforderlichen Bibliotheken installiert.

1. **Schritt 1**: Stelle sicher, dass Kafka und Zookeeper laufen.
   ```bash
   jps
   ```
   Wenn `ZooKeeperServer` oder `Kafka` nicht angezeigt werden, starte sie:
   ```bash
   /usr/local/kafka/bin/zookeeper-server-start.sh -daemon /usr/local/kafka/config/zookeeper.properties
   /usr/local/kafka/bin/kafka-server-start.sh -daemon /usr/local/kafka/config/server.properties
   ```
2. **Schritt 2**: Erstelle ein Kafka-Topic für die Streaming-Daten.
   ```bash
   /usr/local/kafka/bin/kafka-topics.sh --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1 --topic stream-test
   ```
   Überprüfe das Topic:
   ```bash
   /usr/local/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092
   ```
3. **Schritt 3**: Stelle sicher, dass Spark und die Kafka-Integration verfügbar sind.
   - Die Spark-Installation (`/usr/local/spark`) sollte bereits die `spark-sql-kafka`-Bibliothek enthalten (Teil von Spark 3.5.3 mit Hadoop 3).
   - Überprüfe die Umgebungsvariablen:
     ```bash
     echo $SPARK_HOME
     echo $JAVA_HOME
     ```
     Stelle sicher, dass `SPARK_HOME=/usr/local/spark` und `JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64` gesetzt sind.
4. **Schritt 4**: Installiere die Python-Bibliothek `confluent-kafka` für Testnachrichten (optional).
   ```bash
   pip3 install confluent-kafka
   ```

**Reflexion**: Warum ist die `spark-sql-kafka`-Bibliothek notwendig, und wie erleichtert sie die Integration mit Kafka?

### Übung 2: Streaming-Daten mit Spark und Kafka verarbeiten
**Ziel**: Verstehen, wie man Spark Structured Streaming verwendet, um Nachrichten aus einem Kafka-Topic zu konsumieren und zu aggregieren.

1. **Schritt 1**: Erstelle ein Python-Skript für die Streaming-Verarbeitung.
   ```bash
   nano kafka_spark_streaming.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from pyspark.sql import SparkSession
   from pyspark.sql.functions import col, count

   spark = SparkSession.builder.appName("KafkaSparkStreaming").getOrCreate()

   # Lese Streaming-Daten aus Kafka
   df = spark.readStream \
       .format("kafka") \
       .option("kafka.bootstrap.servers", "localhost:9092") \
       .option("subscribe", "stream-test") \
       .load()

   # Extrahiere Nachrichten (value) und konvertiere sie zu Strings
   messages = df.selectExpr("CAST(value AS STRING)")

   # Zähle Nachrichten pro Wort
   word_counts = messages.groupBy("value").agg(count("*").alias("count"))

   # Schreibe Ergebnisse in die Konsole
   query = word_counts.writeStream \
       .outputMode("complete") \
       .format("console") \
       .start()

   query.awaitTermination(60)  # Läuft 60 Sekunden
   spark.stop()
   ```
2. **Schritt 2**: Starte das Skript in einem Terminal.
   ```bash
   spark-submit kafka_spark_streaming.py &
   ```
3. **Schritt 3**: Produziere Testnachrichten in das Topic mit dem Konsolen-Producer.
   Öffne ein neues Terminal und führe aus:
   ```bash
   /usr/local/kafka/bin/kafka-console-producer.sh --broker-list localhost:9092 --topic stream-test
   ```
   Gib ein paar Nachrichten ein (z. B. `Hallo`, `Hallo`, `Spark`, `Kafka`), und beende mit `Ctrl+C`.
4. **Schritt 4**: Überprüfe die Konsolenausgabe des Spark-Skripts. Sie sollte die Worthäufigkeiten anzeigen (z. B. `Hallo: 2`, `Spark: 1`, `Kafka: 1`).

**Reflexion**: Wie ermöglicht Structured Streaming die Verarbeitung von Kafka-Nachrichten in Echtzeit, und was bedeutet der `outputMode("complete")`?

### Übung 3: Erweiterte Aggregation mit Spark Streaming
**Ziel**: Lernen, wie man komplexere Aggregationen (z. B. Fensteraggregationen) auf Kafka-Datenströme anwendet.

1. **Schritt 1**: Erstelle ein Python-Skript für eine Fensteraggregation.
   ```bash
   nano kafka_window_streaming.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from pyspark.sql import SparkSession
   from pyspark.sql.functions import col, window, count
   from pyspark.sql.types import StructType, StructField, StringType, TimestampType

   spark = SparkSession.builder.appName("KafkaWindowStreaming").getOrCreate()

   # Definiere Schema für JSON-Daten
   schema = StructType([
       StructField("timestamp", StringType(), True),
       StructField("value", StringType(), True)
   ])

   # Lese Streaming-Daten aus Kafka
   df = spark.readStream \
       .format("kafka") \
       .option("kafka.bootstrap.servers", "localhost:9092") \
       .option("subscribe", "stream-test") \
       .load()

   # Extrahiere JSON-Daten aus value
   messages = df.selectExpr("CAST(value AS STRING) as json") \
                .select(from_json("json", schema).alias("data")) \
                .select("data.*")

   # Konvertiere timestamp zu TimestampType
   messages = messages.withColumn("timestamp", col("timestamp").cast("timestamp"))

   # Zähle Nachrichten pro 10-Sekunden-Fenster
   windowed_counts = messages.groupBy(window("timestamp", "10 seconds"), "value") \
                            .agg(count("*").alias("count"))

   # Schreibe Ergebnisse in die Konsole
   query = windowed_counts.writeStream \
       .outputMode("complete") \
       .format("console") \
       .start()

   query.awaitTermination(60)
   spark.stop()
   ```
2. **Schritt 2**: Erstelle ein Python-Skript, um JSON-Nachrichten an Kafka zu senden.
   ```bash
   nano kafka_producer.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from confluent_kafka import Producer
   import json
   import time

   p = Producer({'bootstrap.servers': 'localhost:9092'})
   topic = "stream-test"

   messages = [
       {"timestamp": "2025-09-16T08:00:00", "value": "Hallo"},
       {"timestamp": "2025-09-16T08:00:02", "value": "Spark"},
       {"timestamp": "2025-09-16T08:00:05", "value": "Hallo"},
       {"timestamp": "2025-09-16T08:00:12", "value": "Kafka"}
   ]

   for msg in messages:
       p.produce(topic, json.dumps(msg).encode('utf-8'))
       time.sleep(1)
   p.flush()
   print("Nachrichten gesendet")
   ```
3. **Schritt 3**: Starte das Streaming-Skript und sende Nachrichten.
   ```bash
   spark-submit kafka_window_streaming.py &
   python3 kafka_producer.py
   ```
   Überprüfe die Konsolenausgabe des Spark-Skripts. Sie sollte die Worthäufigkeiten pro 10-Sekunden-Fenster anzeigen.

**Reflexion**: Wie können Fensteraggregationen in realen Szenarien (z. B. Überwachung von Sensordaten) genutzt werden, und welche Herausforderungen könnten bei der Verarbeitung großer Datenströme auftreten?

## Tipps für den Erfolg
- Überprüfe die Spark-Logs in `$SPARK_HOME/logs/` und Kafka-Logs in `/usr/local/kafka/logs/` bei Problemen.
- Stelle sicher, dass `JAVA_HOME` und `SPARK_HOME` korrekt gesetzt sind.
- Verwende `jps`, um zu überprüfen, ob Zookeeper, Kafka und Spark-Prozesse laufen.
- Teste mit kleinen Nachrichtenmengen, bevor du größere Datenströme verarbeitest.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Apache Kafka mit Apache Spark Structured Streaming integrieren, um Echtzeit-Datenströme zu verarbeiten. Durch die Übungen haben Sie praktische Erfahrung mit dem Konsumieren von Kafka-Nachrichten, einfachen Aggregationen und Fensteraggregationen gesammelt. Diese Fähigkeiten sind essenziell für Echtzeit-Datenanalysen in Big-Data-Systemen. Üben Sie weiter, um komplexere Streaming-Szenarien oder Mehrknoten-Setups zu meistern!

**Nächste Schritte**:
- Richten Sie einen Kafka-Mehrknoten-Cluster ein, um Skalierbarkeit zu testen.
- Integrieren Sie Spark mit Hadoop HDFS, um Streaming-Ergebnisse persistent zu speichern.
- Erkunden Sie Kafka Connect für die Integration mit Datenbanken.

**Quellen**:
- Offizielle Apache Spark-Dokumentation: https://spark.apache.org/docs/latest/
- Structured Streaming mit Kafka: https://spark.apache.org/docs/latest/structured-streaming-kafka-integration.html
- Offizielle Apache Kafka-Dokumentation: https://kafka.apache.org/documentation/
- Confluent Kafka Python-Dokumentation: https://docs.confluent.io/platform/current/clients/consumer.html