# Praxisorientierte Anleitung: Big Data mit PySpark (Datenanalyse und Optimierung)

## Einführung
Big Data umfasst die Verarbeitung massiver Datenmengen, die oft verteilte Systeme erfordern. Mit **Apache Spark** und seiner Python-API **PySpark** kannst du Big-Data-Konzepte lokal simulieren, indem du DataFrames, verteilte Verarbeitung und optimierte Dateiformate wie Parquet nutzt. Diese Anleitung führt Anfänger durch praktische Übungen zur **Installation von PySpark**, **Erstellung eines simulierten Datensatzes**, **Datenanalyse mit DataFrames**, **Aggregation von Daten** und **Optimierung mit Parquet**. Eine **Spielerei** zeigt, wie du die Ergebnisse in einer Markdown-Tabelle zusammenfasst, um die Verbindung zu vorherigen Themen (z. B. Markdown-Ausgabe) herzustellen. Die Übungen sind auf einem Debian-basierten System ausführbar und für Nutzer mit grundlegenden Kenntnissen in Bash, Python und Big-Data-Konzepten geeignet.

**Voraussetzungen**:
- Ein Debian-basiertes System (z. B. Ubuntu 22.04, Debian 11); Windows-Nutzer können WSL2 verwenden; macOS ist kompatibel.
- Ein Terminal (z. B. Bash unter Linux).
- Installierte Tools:
  - Java Runtime Environment (JRE): `sudo apt install default-jre`
  - Python 3 und `pip`: `sudo apt install python3 python3-pip`
  - PySpark und `findspark`: `pip install pyspark findspark`
- Grundkenntnisse in Bash (Befehle, Skripte), Python und Big-Data-Konzepte (DataFrames, Parquet).
- Sichere Testumgebung (z. B. `$HOME/bigdata_tests` oder `~/bigdata_tests`).
- Optional: Internetzugriff für die Installation von Paketen.

## Grundlegende Befehle
Hier sind die wichtigsten Bash- und Python-Befehle für die PySpark-Übungen:

1. **Installation und Vorbereitung**:
   - `java -version`: Prüft die Java-Installation.
   - `sudo apt install default-jre`: Installiert JRE.
   - `pip install pyspark findspark`: Installiert PySpark und `findspark`.
2. **Datensatz erstellen**:
   - `python3 data_gen.py`: Generiert eine JSON-Log-Datei.
3. **Datenanalyse mit PySpark**:
   - `spark.read.json(<Datei>)`: Lädt JSON-Daten in einen DataFrame.
   - `df.filter()`: Filtert Daten basierend auf Bedingungen.
   - `df.groupBy().count()`: Gruppiert und aggregiert Daten.
   - `df.show()`: Zeigt DataFrame-Inhalte an.
4. **Optimierung mit Parquet**:
   - `df.write.parquet(<Datei>)`: Speichert Daten im Parquet-Format.
   - `spark.read.parquet(<Datei>)`: Lädt Parquet-Daten.
5. **Nützliche Zusatzbefehle**:
   - `man python3`: Dokumentation für Python.
   - `time python3 <Skript>`: Misst die Ausführungszeit.
   - `du -sh <Datei>`: Prüft die Dateigröße.
   - `date`: Fügt Zeitstempel in Protokollen hinzu.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: PySpark installieren
**Ziel**: Installiere PySpark und die notwendigen Abhängigkeiten auf deinem Debian-System.

1. **Schritt 1**: Erstelle ein Testverzeichnis:
   ```bash
   mkdir bigdata_tests
   cd bigdata_tests
   ```

2. **Schritt 2**: Prüfe und installiere Java:
   ```bash
   java -version || sudo apt install default-jre
   ```

3. **Schritt 3**: Installiere PySpark und `findspark`:
   ```bash
   pip install pyspark findspark
   ```

4. **Schritt 4**: Überprüfe die Installation:
   ```bash
   python3 -c "import pyspark; print(pyspark.__version__)"
   ```
   **Beispielausgabe**:
   ```
   3.5.1
   ```

5. **Schritt 5**: Protokolliere die Installation:
   ```bash
   echo "PySpark-Installation am $(date)" > bigdata_log.txt
   python3 -c "import pyspark; print(pyspark.__version__)" >> bigdata_log.txt
   pip show findspark >> bigdata_log.txt
   cat bigdata_log.txt
   ```

**Reflexion**: Warum ist Java für PySpark notwendig? Nutze `man java` und überlege, wie du die Spark-Version anpasst.

### Übung 2: Eine "Log-Datei" generieren
**Ziel**: Erstelle eine JSON-Datei mit simulierten Log-Einträgen für Big-Data-Übungen.

1. **Schritt 1**: Erstelle ein Python-Skript zur Datengenerierung:
   ```bash
   nano data_gen.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import json
   import random
   import time

   log_events = ['LOGIN', 'LOGOUT', 'ERROR', 'VIEW_PAGE', 'PURCHASE']

   with open('large_data.json', 'w') as f:
       for i in range(100000):  # Erzeugt 100.000 Einträge
           entry = {
               'timestamp': int(time.time()),
               'user_id': random.randint(1, 1000),
               'event': random.choice(log_events)
           }
           f.write(json.dumps(entry) + '\n')

   print("Datensatz erstellt.")
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   python3 data_gen.py
   ```

3. **Schritt 3**: Überprüfe die Datei:
   ```bash
   head -n 5 large_data.json
   du -sh large_data.json
   ```
   **Beispielausgabe**:
   ```
   {"timestamp":1725532080,"user_id":542,"event":"LOGIN"}
   {"timestamp":1725532080,"user_id":123,"event":"ERROR"}
   {"timestamp":1725532080,"user_id":987,"event":"VIEW_PAGE"}
   {"timestamp":1725532080,"user_id":456,"event":"PURCHASE"}
   {"timestamp":1725532080,"user_id":789,"event":"LOGOUT"}
   12M     large_data.json
   ```

4. **Schritt 4**: Protokolliere die Erstellung:
   ```bash
   echo "Datensatz erstellt am $(date)" >> bigdata_log.txt
   du -sh large_data.json >> bigdata_log.txt
   cat bigdata_log.txt
   ```

**Reflexion**: Wie simuliert die JSON-Datei Big-Data-Szenarien? Nutze `man head` und überlege, wie du größere Datensätze generierst.

### Übung 3: Daten laden und filtern
**Ziel**: Lade die JSON-Datei in einen PySpark-DataFrame und filtere "ERROR"-Ereignisse.

1. **Schritt 1**: Erstelle ein Python-Skript für die Analyse:
   ```bash
   nano analyze.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import findspark
   from pyspark.sql import SparkSession

   findspark.init()
   spark = SparkSession.builder.appName("BigDataAnalyse").getOrCreate()

   df = spark.read.json("large_data.json")
   error_df = df.filter(df.event == "ERROR")
   error_df.show(100)
   print(f"Anzahl der Fehler: {error_df.count()}")

   spark.stop()
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   python3 analyze.py > error_output.txt
   ```

3. **Schritt 3**: Protokolliere die Ergebnisse:
   ```bash
   echo "Fehleranalyse am $(date)" >> bigdata_log.txt
   grep "Anzahl der Fehler" error_output.txt >> bigdata_log.txt
   cat bigdata_log.txt
   ```
   **Beispielausgabe** (gekürzt):
   ```
   Anzahl der Fehler: 19987
   ```

**Reflexion**: Wie erleichtert der DataFrame die Datenanalyse? Nutze die PySpark-Dokumentation (`pyspark.sql`) und überlege, wie du andere Ereignisse filterst.

### Übung 4: Daten gruppieren und aggregieren
**Ziel**: Gruppiere die Daten nach `user_id` und zähle die Ereignisse pro Benutzer.

1. **Schritt 1**: Aktualisiere das Analyse-Skript:
   ```bash
   nano analyze.py
   ```
   Ersetze den Inhalt durch:
   ```python
   import findspark
   from pyspark.sql import SparkSession

   findspark.init()
   spark = SparkSession.builder.appName("BigDataAnalyse").getOrCreate()

   df = spark.read.json("large_data.json")
   error_df = df.filter(df.event == "ERROR")
   error_df.show(100)
   print(f"Anzahl der Fehler: {error_df.count()}")

   user_event_counts = df.groupBy("user_id").count()
   user_event_counts.sort("count", ascending=False).show(10)

   spark.stop()
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   python3 analyze.py > agg_output.txt
   ```

3. **Schritt 3**: Protokolliere die Ergebnisse:
   ```bash
   echo "Aggregation am $(date)" >> bigdata_log.txt
   tail -n 12 agg_output.txt | grep -A 10 "+-------+" >> bigdata_log.txt
   cat bigdata_log.txt
   ```
   **Beispielausgabe** (gekürzt):
   ```
   +-------+-----+
   |user_id|count|
   +-------+-----+
   |    543|  127|
   |    876|  123|
   |    234|  119|
   ...
   ```

**Reflexion**: Warum sind Aggregationen in Big Data wichtig? Nutze die PySpark-Dokumentation und überlege, wie du andere Aggregationen (z. B. nach `event`) durchführst.

### Übung 5: Daten in Parquet schreiben
**Ziel**: Speichere den DataFrame im Parquet-Format und vergleiche die Dateigröße.

1. **Schritt 1**: Erstelle ein Python-Skript für Parquet:
   ```bash
   nano write_parquet.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import findspark
   from pyspark.sql import SparkSession

   findspark.init()
   spark = SparkSession.builder.appName("ParquetWrite").getOrCreate()

   df = spark.read.json("large_data.json")
   df.write.mode("overwrite").parquet("optimized_data.parquet")
   print("Parquet-Datensatz erstellt.")

   spark.stop()
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   python3 write_parquet.py
   ```

3. **Schritt 3**: Vergleiche die Dateigrößen:
   ```bash
   du -sh large_data.json
   du -sh optimized_data.parquet
   ```
   **Beispielausgabe**:
   ```
   12M     large_data.json
   4.0M    optimized_data.parquet
   ```

4. **Schritt 4**: Protokolliere die Ergebnisse:
   ```bash
   echo "Parquet-Konvertierung am $(date)" >> bigdata_log.txt
   du -sh large_data.json optimized_data.parquet >> bigdata_log.txt
   cat bigdata_log.txt
   ```

**Reflexion**: Warum ist Parquet effizienter als JSON? Nutze die PySpark-Dokumentation und überlege, wie du Partitionierung hinzufügst.

### Übung 6: Performance vergleichen
**Ziel**: Vergleiche die Ladezeit von JSON- und Parquet-Dateien.

1. **Schritt 1**: Erstelle ein Python-Skript für den Performance-Test:
   ```bash
   nano perf_test.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import time
   import findspark
   from pyspark.sql import SparkSession

   findspark.init()
   spark = SparkSession.builder.appName("PerfTest").getOrCreate()

   start_time = time.time()
   df_json = spark.read.json("large_data.json")
   df_json.count()
   end_time = time.time()
   print(f"Laden der JSON-Datei dauerte: {end_time - start_time:.2f} Sekunden")

   start_time = time.time()
   df_parquet = spark.read.parquet("optimized_data.parquet")
   df_parquet.count()
   end_time = time.time()
   print(f"Laden der Parquet-Datei dauerte: {end_time - start_time:.2f} Sekunden")

   spark.stop()
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   python3 perf_test.py > perf_output.txt
   ```

3. **Schritt 3**: Protokolliere die Ergebnisse:
   ```bash
   echo "Performance-Test am $(date)" >> bigdata_log.txt
   cat perf_output.txt >> bigdata_log.txt
   cat bigdata_log.txt
   ```
   **Beispielausgabe**:
   ```
   Laden der JSON-Datei dauerte: 2.45 Sekunden
   Laden der Parquet-Datei dauerte: 0.78 Sekunden
   ```

**Reflexion**: Warum ist Parquet schneller? Nutze die PySpark-Dokumentation und überlege, wie du die Performance weiter optimierst.

### Übung 7: Spielerei – Ergebnisse in Markdown-Tabelle zusammenfassen
**Ziel**: Erstelle ein Markdown-Dokument, das die Analyseergebnisse und Performance-Daten zusammenfasst.

1. **Schritt 1**: Erstelle ein Python-Skript für die kombinierte Ausgabe:
   ```bash
   nano summary.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import findspark
   from pyspark.sql import SparkSession
   import time

   findspark.init()
   spark = SparkSession.builder.appName("BigDataSummary").getOrCreate()

   # Daten laden
   df = spark.read.json("large_data.json")
   error_count = df.filter(df.event == "ERROR").count()
   user_counts = df.groupBy("user_id").count().sort("count", ascending=False).limit(10).collect()

   # Performance-Test
   start_time = time.time()
   df_json = spark.read.json("large_data.json")
   df_json.count()
   json_time = time.time() - start_time

   start_time = time.time()
   df_parquet = spark.read.parquet("optimized_data.parquet")
   df_parquet.count()
   parquet_time = time.time() - start_time

   spark.stop()

   # Markdown-Ausgabe
   with open("bigdata_summary.md", "w") as f:
       f.write("# Big Data Analyse Zusammenfassung\n")
       f.write(f"Erstellt am: {time.strftime('%Y-%m-%d %H:%M:%S')}\n\n")
       f.write("## Analyseergebnisse\n")
       f.write("| Metrik | Wert |\n")
       f.write("|--------|------|\n")
       f.write(f"| Anzahl der Fehler | {error_count} |\n")
       f.write("\n## Top 10 Benutzer (nach Ereignissen)\n")
       f.write("| User ID | Anzahl Ereignisse |\n")
       f.write("|---------|-------------------|\n")
       for row in user_counts:
           f.write(f"| {row['user_id']} | {row['count']} |\n")
       f.write("\n## Performance-Vergleich\n")
       f.write("| Dateiformat | Ladezeit (Sekunden) |\n")
       f.write("|-------------|---------------------|\n")
       f.write(f"| JSON | {json_time:.2f} |\n")
       f.write(f"| Parquet | {parquet_time:.2f} |\n")

   print("Zusammenfassung erstellt. Ergebnisse in bigdata_summary.md.")
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   python3 summary.py
   ```

3. **Spielerei**: Überprüfe die Markdown-Ausgabe:
   ```bash
   cat bigdata_summary.md
   ```
   **Beispielausgabe** (`bigdata_summary.md`):
   ```
   # Big Data Analyse Zusammenfassung
   Erstellt am: 2025-09-05 12:31:00

   ## Analyseergebnisse
   | Metrik | Wert |
   |--------|------|
   | Anzahl der Fehler | 19987 |

   ## Top 10 Benutzer (nach Ereignissen)
   | User ID | Anzahl Ereignisse |
   |---------|-------------------|
   | 543     | 127               |
   | 876     | 123               |
   | 234     | 119               |
   | ...     | ...               |

   ## Performance-Vergleich
   | Dateiformat | Ladezeit (Sekunden) |
   |-------------|---------------------|
   | JSON        | 2.45                |
   | Parquet     | 0.78                |
   ```

**Reflexion**: Wie hilft die Markdown-Zusammenfassung bei der Dokumentation? Nutze die PySpark-Dokumentation und überlege, wie du Visualisierungen hinzufügst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um PySpark und Big-Data-Konzepte zu verinnerlichen.
- **Sicheres Testen**: Arbeite in einer Testumgebung und sichere Dateien (`cp large_data.json large_data.json.bak`).
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze die PySpark-Dokumentation oder `man python3` für Details.
- **Effiziente Entwicklung**: Nutze `spark.read` für flexible Datenformate, `df.cache()` für wiederholte Abfragen und Skripte für Automatisierung.
- **Kombiniere Tools**: Integriere `pandas` für kleinere Analysen oder `matplotlib` für Visualisierungen.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Hinzufügen von SQL-Abfragen mit `spark.sql` oder Partitionierung.

## Fazit
Mit diesen Übungen hast du gelernt, PySpark lokal zu installieren, einen simulierten Datensatz zu erstellen, Daten mit DataFrames zu analysieren, Aggregationen durchzuführen, Daten in Parquet zu speichern und die Performance zu vergleichen. Die Spielerei zeigt, wie du die Ergebnisse in einer Markdown-Tabelle zusammenfasst. Vertiefe dein Wissen, indem du fortgeschrittene Themen (z. B. Spark SQL, Streaming) oder Tools wie `hadoop` ausprobierst. Wenn du ein spezifisches Thema (z. B. verteilte Verarbeitung oder Visualisierung) vertiefen möchtest, lass es mich wissen!
