# Praxisorientierte Anleitung: Integration von Apache Cassandra mit Apache Spark für Big-Data-Analysen auf Debian

## Einführung
Die Integration von Apache Cassandra mit Apache Spark ermöglicht die Verarbeitung und Analyse großer Datenmengen aus einer skalierbaren NoSQL-Datenbank mit Sparks leistungsstarker DataFrame- und SQL-API. Cassandra dient als persistente Datenquelle, während Spark komplexe Analysen und Aggregationen durchführt. Diese Anleitung zeigt Ihnen, wie Sie Cassandra und Spark auf einem Debian-System integrieren, Daten aus einer Cassandra-Tabelle in Spark laden und Analysen wie Aggregationen oder Filtern durchführen. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, Big-Data-Analysen mit Cassandra und Spark umzusetzen. Die Anleitung ist ideal für Datenanalysten und Entwickler, die skalierbare Datenverarbeitung erkunden möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit installiertem Apache Spark (z. B. Spark 3.5.3), Apache Cassandra (z. B. Cassandra 4.0) und Java JDK (mindestens Java 8, empfohlen Java 11)
- Python 3 und PySpark installiert
- Cassandra läuft auf `localhost:9042` mit einem Keyspace `myapp` und einer Tabelle `todos` (aus der vorherigen Cassandra-Anleitung)
- Root- oder Sudo-Zugriff
- Grundlegende Kenntnisse der Linux-Kommandozeile, Python, Cassandra und Spark
- Mindestens 4 GB RAM und ausreichend Festplattenspeicher
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie IntelliJ IDEA)

## Grundlegende Konzepte und Techniken
Hier sind die wichtigsten Konzepte und Techniken, die wir behandeln:

1. **Cassandra-Spark-Integration**:
   - **Spark-Cassandra-Connector**: Ermöglicht das Lesen und Schreiben von Cassandra-Daten in Spark
   - **DataFrame-API**: Verarbeitet Cassandra-Daten als Spark DataFrames
   - **Spark SQL**: Führt SQL-Abfragen auf Cassandra-Daten aus
2. **Wichtige Spark-Konfigurationen**:
   - `spark.cassandra.connection.host`: Verbindet Spark mit dem Cassandra-Cluster
   - `spark.sql.catalog`: Definiert einen Cassandra-Katalog für SQL-Abfragen
3. **Wichtige Befehle**:
   - `spark-submit`: Führt die Spark-Anwendung aus
   - `cqlsh`: Überprüft Cassandra-Daten
   - `jps`: Überprüft laufende Spark- und Cassandra-Prozesse

## Übungen zum Verinnerlichen

### Übung 1: Vorbereitung von Cassandra und Spark
**Ziel**: Lernen, wie man Cassandra und Spark vorbereitet und den Spark-Cassandra-Connector installiert.

1. **Schritt 1**: Stelle sicher, dass Cassandra läuft.
   ```bash
   sudo systemctl status cassandra
   ```
   Wenn der Dienst nicht aktiv ist, starte ihn:
   ```bash
   sudo systemctl start cassandra
   ```
   Überprüfe den Keyspace und die Tabelle in `cqlsh`:
   ```bash
   cqlsh
   ```
   ```sql
   USE myapp;
   SELECT * FROM todos;
   ```
   Stelle sicher, dass die Tabelle `todos` Daten enthält (z. B. aus der vorherigen Anleitung). Beende mit `exit`.
2. **Schritt 2**: Stelle sicher, dass Spark installiert ist und Umgebungsvariablen gesetzt sind.
   ```bash
   echo $SPARK_HOME
   echo $JAVA_HOME
   ```
   `SPARK_HOME` sollte `/usr/local/spark` und `JAVA_HOME` `/usr/lib/jvm/java-11-openjdk-amd64` sein.
3. **Schritt 3**: Füge den Spark-Cassandra-Connector zu Spark hinzu.
   Lade den Connector herunter (Version kompatibel mit Spark 3.5.3 und Scala 2.13):
   ```bash
   wget https://repo1.maven.org/maven2/com/datastax/spark/spark-cassandra-connector_2.13/3.5.0/spark-cassandra-connector_2.13-3.5.0.jar
   sudo mv spark-cassandra-connector_2.13-3.5.0.jar /usr/local/spark/jars/
   ```
4. **Schritt 4**: Installiere Python-Abhängigkeiten (falls nicht bereits vorhanden).
   ```bash
   pip3 install cassandra-driver
   ```

**Reflexion**: Warum ist der Spark-Cassandra-Connector notwendig, und wie erleichtert er die Interaktion zwischen Spark und Cassandra?

### Übung 2: Daten aus Cassandra in Spark laden und analysieren
**Ziel**: Verstehen, wie man Cassandra-Daten in Spark als DataFrame lädt und einfache Analysen durchführt.

1. **Schritt 1**: Erstelle ein Python-Skript, um Daten aus der `todos`-Tabelle zu laden und zu analysieren.
   ```bash
   nano cassandra_spark_read.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from pyspark.sql import SparkSession

   spark = SparkSession.builder \
       .appName("CassandraSparkIntegration") \
       .config("spark.cassandra.connection.host", "localhost") \
       .config("spark.cassandra.connection.port", "9042") \
       .getOrCreate()

   # Lade Daten aus Cassandra
   df = spark.read \
       .format("org.apache.spark.sql.cassandra") \
       .options(table="todos", keyspace="myapp") \
       .load()

   # Zeige Daten
   df.show()

   # Führe eine einfache Aggregation durch (z. B. zähle abgeschlossene Aufgaben)
   completed_count = df.filter(df.completed == True).count()
   print(f"Anzahl abgeschlossener Aufgaben: {completed_count}")

   spark.stop()
   ```
2. **Schritt 2**: Führe das Skript aus und überprüfe die Ergebnisse.
   ```bash
   spark-submit --jars /usr/local/spark/jars/spark-cassandra-connector_2.13-3.5.0.jar cassandra_spark_read.py
   ```
   Die Ausgabe zeigt die Daten aus der `todos`-Tabelle und die Anzahl abgeschlossener Aufgaben.

**Reflexion**: Wie erleichtert die DataFrame-API die Verarbeitung von Cassandra-Daten im Vergleich zu direkten CQL-Abfragen?

### Übung 3: Daten in Cassandra mit Spark schreiben und SQL-Analysen durchführen
**Ziel**: Lernen, wie man Daten mit Spark in Cassandra schreibt und Spark SQL für komplexe Analysen verwendet.

1. **Schritt 1**: Erstelle ein Python-Skript, um neue Daten in die `todos`-Tabelle zu schreiben und SQL-Abfragen auszuführen.
   ```bash
   nano cassandra_spark_write_sql.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from pyspark.sql import SparkSession
   from pyspark.sql.types import StructType, StructField, StringType, BooleanType, TimestampType
   from uuid import uuid4
   from datetime import datetime

   spark = SparkSession.builder \
       .appName("CassandraSparkWriteSQL") \
       .config("spark.cassandra.connection.host", "localhost") \
       .config("spark.cassandra.connection.port", "9042") \
       .getOrCreate()

   # Erstelle ein DataFrame mit neuen Daten
   schema = StructType([
       StructField("id", StringType(), False),
       StructField("task", StringType(), False),
       StructField("completed", BooleanType(), False),
       StructField("created_at", TimestampType(), False)
   ])
   new_data = [(str(uuid4()), "Analyse mit Spark", False, datetime.now())]
   new_df = spark.createDataFrame(new_data, schema)

   # Schreibe Daten in Cassandra
   new_df.write \
       .format("org.apache.spark.sql.cassandra") \
       .options(table="todos", keyspace="myapp") \
       .mode("append") \
       .save()

   # Lade Daten für SQL-Analyse
   df = spark.read \
       .format("org.apache.spark.sql.cassandra") \
       .options(table="todos", keyspace="myapp") \
       .load()

   # Registriere DataFrame als temporäre View
   df.createOrReplaceTempView("todos")

   # Führe SQL-Abfrage durch
   result = spark.sql("SELECT task, completed, created_at FROM todos WHERE completed = false")
   result.show()

   spark.stop()
   ```
2. **Schritt 2**: Führe das Skript aus und überprüfe die Ergebnisse.
   ```bash
   spark-submit --jars /usr/local/spark/jars/spark-cassandra-connector_2.13-3.5.0.jar cassandra_spark_write_sql.py
   ```
   Die Ausgabe zeigt nicht abgeschlossene Aufgaben. Überprüfe in `cqlsh`:
   ```bash
   cqlsh
   USE myapp;
   SELECT * FROM todos;
   ```
3. **Schritt 3**: Überprüfe, ob die neuen Daten in Cassandra gespeichert wurden.

**Reflexion**: Wie kann die Kombination von Spark SQL und Cassandra in realen Szenarien (z. B. Analyse von Nutzerdaten) genutzt werden, und welche Vorteile bietet der Schreibmodus `append`?

## Tipps für den Erfolg
- Überprüfe die Cassandra-Logs in `/var/log/cassandra/` und Spark-Logs in `$SPARK_HOME/logs/` bei Problemen.
- Stelle sicher, dass `JAVA_HOME` und `SPARK_HOME` korrekt gesetzt sind.
- Verwende `nodetool status`, um den Cassandra-Knoten zu überprüfen, und `jps`, um Spark-Prozesse zu prüfen.
- Teste mit kleinen Datensätzen, bevor du größere Datenmengen verarbeitest.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Apache Cassandra mit Apache Spark integrieren, um Big-Data-Analysen durchzuführen. Durch die Übungen haben Sie praktische Erfahrung mit dem Spark-Cassandra-Connector, dem Laden und Schreiben von Daten sowie Spark SQL gesammelt. Diese Fähigkeiten sind essenziell für skalierbare Datenanalysen in verteilten Systemen. Üben Sie weiter, um komplexere Analysen oder Mehrknoten-Setups zu meistern!

**Nächste Schritte**:
- Richten Sie einen Cassandra-Mehrknoten-Cluster ein, um Skalierbarkeit zu testen.
- Integrieren Sie Spark mit Kafka und Cassandra für Echtzeit-Datenpipelines.
- Erkunden Sie fortgeschrittene Cassandra-Features wie Materialized Views oder Spark MLlib für Analysen.

**Quellen**:
- Offizielle Apache Spark-Dokumentation: https://spark.apache.org/docs/latest/
- Spark-Cassandra-Connector-Dokumentation: https://github.com/datastax/spark-cassandra-connector
- Offizielle Apache Cassandra-Dokumentation: https://cassandra.apache.org/doc/latest/
- DataStax Tutorial: https://docs.datastax.com/en/developer/python-driver/