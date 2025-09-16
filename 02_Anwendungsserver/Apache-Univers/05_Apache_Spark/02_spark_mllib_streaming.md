# Praxisorientierte Anleitung: Einstieg in Apache Spark MLlib und Structured Streaming auf Debian

## Einführung
Apache Spark bietet leistungsstarke Features wie **MLlib** für maschinelles Lernen und **Structured Streaming** für die Verarbeitung von Datenströmen in Echtzeit. MLlib ermöglicht skalierbare Machine-Learning-Algorithmen, während Structured Streaming die Verarbeitung kontinuierlicher Datenströme mit der DataFrame-API erleichtert. Diese Anleitung zeigt Ihnen, wie Sie MLlib für eine einfache Klassifikationsaufgabe und Structured Streaming für die Verarbeitung eines simulierten Datenstroms auf einem Debian-System einsetzen. Ziel ist es, Ihnen praktische Erfahrung mit diesen Spark-Features zu vermitteln. Die Anleitung ist ideal für Datenanalysten und Entwickler, die Big-Data-Analysen und Echtzeitverarbeitung erkunden möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit installiertem Apache Spark (z. B. Spark 3.5.3) und Java JDK (mindestens Java 8, empfohlen Java 11)
- Python 3 und PySpark installiert
- Root- oder Sudo-Zugriff
- Grundlegende Kenntnisse der Linux-Kommandozeile, Python und Spark (z. B. aus der vorherigen Spark-Anleitung)
- Mindestens 4 GB RAM und ausreichend Festplattenspeicher
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie IntelliJ IDEA)

## Grundlegende Konzepte und Techniken
Hier sind die wichtigsten Konzepte und Techniken, die wir behandeln:

1. **MLlib (Machine Learning Library)**:
   - **DataFrame-basierte API**: Nutzt Spark DataFrames für ML-Workflows
   - **Transformer und Estimator**: Transformer (z. B. `VectorAssembler`) und Estimator (z. B. `LogisticRegression`) für Feature-Engineering und Modelltraining
   - **Pipeline**: Verkettet Datenverarbeitung und Modelltraining
2. **Structured Streaming**:
   - **Streaming DataFrames**: DataFrame-API für kontinuierliche Datenströme
   - **Quelle und Senke**: Datenquellen (z. B. Dateien, Kafka) und Senken (z. B. Konsole, Dateien)
   - **Trigger**: Steuert, wann Daten verarbeitet werden
3. **Wichtige Befehle**:
   - `pyspark`: Interaktive Python-Shell für Spark
   - `spark-submit`: Ausführen von Spark-Anwendungen
   - `jps`: Überprüft laufende Spark-Prozesse

## Übungen zum Verinnerlichen

### Übung 1: Klassifikation mit MLlib
**Ziel**: Lernen, wie man MLlib verwendet, um ein logistisches Regressionsmodell für eine Klassifikationsaufgabe zu trainieren.

1. **Schritt 1**: Erstelle eine Beispieldatendatei im CSV-Format.
   ```bash
   nano iris.csv
   ```
   Füge folgenden Inhalt ein (vereinfachte Iris-Daten):
   ```csv
   sepal_length,sepal_width,petal_length,petal_width,species
   5.1,3.5,1.4,0.2,0
   4.9,3.0,1.4,0.2,0
   7.0,3.2,4.7,1.4,1
   6.4,3.2,4.5,1.5,1
   6.3,3.3,6.0,2.5,2
   5.8,2.7,5.1,1.9,2
   ```
   (0 = Setosa, 1 = Versicolor, 2 = Virginica)
2. **Schritt 2**: Erstelle ein Python-Skript für die Klassifikation mit MLlib.
   ```bash
   nano iris_classification.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from pyspark.sql import SparkSession
   from pyspark.ml.feature import VectorAssembler
   from pyspark.ml.classification import LogisticRegression
   from pyspark.ml import Pipeline

   spark = SparkSession.builder.appName("IrisClassification").getOrCreate()

   # Lade Daten
   df = spark.read.csv("file:///home/$USER/iris.csv", header=True, inferSchema=True)

   # Feature-Engineering
   assembler = VectorAssembler(inputCols=["sepal_length", "sepal_width", "petal_length", "petal_width"], outputCol="features")
   lr = LogisticRegression(labelCol="species", featuresCol="features")

   # Pipeline
   pipeline = Pipeline(stages=[assembler, lr])
   model = pipeline.fit(df)

   # Vorhersagen
   predictions = model.transform(df)
   predictions.select("species", "prediction", "probability").show()

   spark.stop()
   ```
3. **Schritt 3**: Führe das Skript aus und überprüfe die Ergebnisse.
   ```bash
   spark-submit iris_classification.py
   ```
   Die Ausgabe zeigt die tatsächlichen und vorhergesagten Klassen sowie die Wahrscheinlichkeiten.

**Reflexion**: Wie vereinfacht die Pipeline-API in MLlib die Entwicklung von Machine-Learning-Workflows?

### Übung 2: Structured Streaming mit simulierten Daten
**Ziel**: Verstehen, wie man Structured Streaming verwendet, um einen simulierten Datenstrom zu verarbeiten.

1. **Schritt 1**: Erstelle einen Ordner für Eingabedaten und simuliere einen Datenstrom durch das Hinzufügen von JSON-Dateien.
   ```bash
   mkdir input_stream
   nano input_stream/data1.json
   ```
   Füge folgenden Inhalt ein:
   ```json
   {"timestamp": "2025-09-16T08:00:00", "value": 10}
   {"timestamp": "2025-09-16T08:00:01", "value": 15}
   ```
   Erstelle eine zweite Datei:
   ```bash
   nano input_stream/data2.json
   ```
   ```json
   {"timestamp": "2025-09-16T08:00:02", "value": 20}
   {"timestamp": "2025-09-16T08:00:03", "value": 25}
   ```
2. **Schritt 2**: Erstelle ein Python-Skript für Structured Streaming.
   ```bash
   nano stream_processing.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from pyspark.sql import SparkSession
   from pyspark.sql.functions import window

   spark = SparkSession.builder.appName("StreamProcessing").getOrCreate()

   # Lese Streaming-Daten
   schema = "timestamp STRING, value INTEGER"
   streaming_df = spark.readStream.schema(schema).json("file:///home/$USER/input_stream")

   # Verarbeite Daten (z. B. Mittelwert pro 10-Sekunden-Fenster)
   windowed_avg = streaming_df.groupBy(window("timestamp", "10 seconds")).avg("value")

   # Schreibe Ergebnisse in die Konsole
   query = windowed_avg.writeStream.outputMode("complete").format("console").start()

   # Warte auf Beendigung
   query.awaitTermination(30)  # Läuft 30 Sekunden
   spark.stop()
   ```
3. **Schritt 3**: Starte das Skript und simuliere den Datenstrom.
   ```bash
   spark-submit stream_processing.py &
   ```
   Während das Skript läuft, füge eine weitere JSON-Datei hinzu:
   ```bash
   nano input_stream/data3.json
   ```
   ```json
   {"timestamp": "2025-09-16T08:00:04", "value": 30}
   ```
   Überprüfe die Konsolenausgabe für die berechneten Mittelwerte.

**Reflexion**: Wie unterscheidet sich Structured Streaming von Batch-Verarbeitung, und welche Vorteile bietet es für Echtzeit-Anwendungen?

### Übung 3: Kombination von MLlib und Structured Streaming
**Ziel**: Lernen, wie man ein trainiertes MLlib-Modell auf einen Datenstrom anwendet.

1. **Schritt 1**: Speichere das trainierte Modell aus Übung 1.
   Modifiziere `iris_classification.py`, um das Modell zu speichern:
   ```python
   from pyspark.sql import SparkSession
   from pyspark.ml.feature import VectorAssembler
   from pyspark.ml.classification import LogisticRegression
   from pyspark.ml import Pipeline

   spark = SparkSession.builder.appName("IrisClassification").getOrCreate()

   # Lade Daten
   df = spark.read.csv("file:///home/$USER/iris.csv", header=True, inferSchema=True)

   # Feature-Engineering
   assembler = VectorAssembler(inputCols=["sepal_length", "sepal_width", "petal_length", "petal_width"], outputCol="features")
   lr = LogisticRegression(labelCol="species", featuresCol="features")

   # Pipeline
   pipeline = Pipeline(stages=[assembler, lr])
   model = pipeline.fit(df)

   # Speichere Modell
   model.writeTo("file:///home/$USER/iris_model")

   spark.stop()
   ```
   Führe das Skript aus:
   ```bash
   spark-submit iris_classification.py
   ```
2. **Schritt 2**: Erstelle ein Streaming-Skript, das das Modell auf einen Datenstrom anwendet.
   ```bash
   nano stream_prediction.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from pyspark.sql import SparkSession
   from pyspark.ml import PipelineModel

   spark = SparkSession.builder.appName("StreamPrediction").getOrCreate()

   # Lese Streaming-Daten
   schema = "sepal_length DOUBLE, sepal_width DOUBLE, petal_length DOUBLE, petal_width DOUBLE"
   streaming_df = spark.readStream.schema(schema).csv("file:///home/$USER/stream_input")

   # Lade Modell
   model = PipelineModel.load("file:///home/$USER/iris_model")

   # Wende Modell an
   predictions = model.transform(streaming_df)

   # Schreibe Vorhersagen in die Konsole
   query = predictions.select("sepal_length", "sepal_width", "petal_length", "petal_width", "prediction").writeStream.outputMode("append").format("console").start()

   query.awaitTermination(30)
   spark.stop()
   ```
3. **Schritt 3**: Simuliere einen Datenstrom und teste die Vorhersagen.
   ```bash
   mkdir stream_input
   nano stream_input/data1.csv
   ```
   ```csv
   5.1,3.5,1.4,0.2
   7.0,3.2,4.7,1.4
   ```
   Starte das Skript:
   ```bash
   spark-submit stream_prediction.py &
   ```
   Füge eine weitere Datei hinzu:
   ```bash
   nano stream_input/data2.csv
   ```
   ```csv
   6.3,3.3,6.0,2.5
   ```
   Überprüfe die Konsolenausgabe für die Vorhersagen.

**Reflexion**: Wie kann die Kombination von MLlib und Structured Streaming in realen Szenarien (z. B. Betrugserkennung) genutzt werden?

## Tipps für den Erfolg
- Überprüfe die Spark-Logs in `$SPARK_HOME/logs/` bei Problemen.
- Stelle sicher, dass `JAVA_HOME` und `SPARK_HOME` korrekt gesetzt sind.
- Verwende kleine Datensätze für Tests, um Ressourcen zu schonen.
- Teste Streaming mit `outputMode("append")` oder `outputMode("complete")`, je nach Anwendungsfall.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Apache Spark MLlib für Klassifikationsaufgaben und Structured Streaming für Echtzeit-Datenverarbeitung einsetzen. Durch die Übungen haben Sie praktische Erfahrung mit DataFrame-basiertem Machine Learning, Streaming und der Kombination beider gesammelt. Diese Fähigkeiten sind essenziell für Big-Data-Anwendungen in der Datenanalyse und Echtzeitverarbeitung. Üben Sie weiter, um komplexere Modelle oder verteilte Cluster zu meistern!

**Nächste Schritte**:
- Richten Sie einen Spark-Mehrknoten-Cluster ein, um verteilte Verarbeitung zu testen.
- Integrieren Sie Spark mit Hadoop HDFS für persistente Speicherung.
- Erkunden Sie weitere MLlib-Algorithmen wie Entscheidungsbäume oder Clustering.

**Quellen**:
- Offizielle Apache Spark-Dokumentation: https://spark.apache.org/docs/latest/
- MLlib-Dokumentation: https://spark.apache.org/docs/latest/ml-guide.html
- Structured Streaming-Dokumentation: https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html
- PySpark-Tutorial: https://www.datacamp.com/tutorial/pyspark-tutorial-getting-started-with-pyspark