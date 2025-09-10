# Praxisorientierte Anleitung: Big Data mit PySpark in Bash

## Einführung
Big Data umfasst die Verarbeitung massiver Datenmengen, oft mit verteilten Systemen. **Apache Spark** mit seiner Python-API **PySpark** ist ideal für Big-Data-Analysen, kann aber über Bash-Skripte automatisiert werden, um Installation, Datengenerierung, Analyse und Dokumentation zu steuern. Diese Anleitung führt Anfänger durch praktische Übungen zur **Automatisierung der PySpark-Installation**, **Erstellung eines simulierten Datensatzes**, **Ausführung von PySpark-Analysen**, **Aggregation mit Bash-Tools** (z. B. `jq`), **Konvertierung in Parquet** und **Dokumentation in Markdown**. Eine **Spielerei** zeigt, wie du Ergebnisse in Markdown zusammenfasst und per E-Mail versendest (mit `mail`). Die Übungen verwenden die JSON-Datei `large_data.json` (100.000 Einträge) und sind auf einem Debian-basierten System ausführbar, geeignet für Nutzer mit grundlegenden Kenntnissen in Bash und Python.

**Voraussetzungen**:
- Ein Debian-basiertes System (z. B. Ubuntu 22.04, Debian 11); Windows-Nutzer können WSL2 verwenden; macOS ist kompatibel.
- Ein Terminal (z. B. Bash unter Linux).
- Installierte Tools:
  - `jq` für JSON-Verarbeitung: `sudo apt install jq`
  - Java Runtime Environment (JRE): `sudo apt install default-jre`
  - Python 3 und `pip`: `sudo apt install python3 python3-pip`
  - PySpark und `findspark`: `pip install pyspark findspark`
  - `mail` für E-Mail-Versand: `sudo apt install mailutils`
- Grundkenntnisse in Bash (Befehle, Skripte) und Python.
- Sichere Testumgebung (z. B. `$HOME/bigdata_tests` oder `~/bigdata_tests`).
- E-Mail-Konfiguration (z. B. Postfix oder Gmail über `mail`).
- Optional: Internetzugriff für die Installation von Paketen.

## Grundlegende Befehle
Hier sind die wichtigsten Bash-Befehle für die Übungen:

1. **Installation und Vorbereitung**:
   - `java -version`: Prüft die Java-Installation.
   - `sudo apt install default-jre python3 python3-pip jq mailutils`: Installiert Abhängigkeiten.
   - `pip install pyspark findspark`: Installiert PySpark und `findspark`.
2. **Datensatz erstellen**:
   - `python3 data_gen.py`: Generiert eine JSON-Log-Datei.
3. **PySpark-Analysen ausführen**:
   - `python3 <Skript>`: Führt PySpark-Skripte aus.
   - `jq 'select(.event == "ERROR")' large_data.json`: Filtert JSON-Daten.
4. **Datenanalyse mit Bash**:
   - `jq -r '.[] | .user_id' large_data.json | sort | uniq -c`: Gruppiert und zählt Ereignisse.
   - `grep -c '"ERROR"' large_data.json`: Zählt Fehlerereignisse.
5. **Logging und Dokumentation**:
   - `echo "Nachricht" >> bigdata_log.txt`: Protokolliert in eine Datei.
   - `mail -s "Betreff" empfänger@example.com < file`: Versendet E-Mails.
6. **Nützliche Zusatzbefehle**:
   - `man jq`: Dokumentation für `jq`.
   - `man mail`: Dokumentation für `mail`.
   - `du -sh <Datei>`: Prüft die Dateigröße.
   - `time <Befehl>`: Misst die Ausführungszeit.
   - `date`: Fügt Zeitstempel in Protokollen hinzu.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: PySpark-Installation automatisieren
**Ziel**: Automatisiere die Installation von PySpark und Abhängigkeiten.

1. **Schritt 1**: Erstelle ein Testverzeichnis:
   ```bash
   mkdir bigdata_tests
   cd bigdata_tests
   ```

2. **Schritt 2**: Erstelle ein Bash-Skript für die Installation:
   ```bash
   nano install_spark.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash

   LOG_FILE="bigdata_log.txt"

   log_message() {
       echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
   }

   log_message "Starte Installation"

   # Prüfe und installiere Java
   if ! java -version 2>/dev/null; then
       log_message "Installiere Java"
       sudo apt update && sudo apt install -y default-jre
       if [ $? -ne 0 ]; then
           log_message "Fehler: Java-Installation fehlgeschlagen"
           exit 1
       fi
   fi

   # Prüfe und installiere Python und pip
   if ! python3 --version 2>/dev/null || ! pip3 --version 2>/dev/null; then
       log_message "Installiere Python und pip"
       sudo apt install -y python3 python3-pip
       if [ $? -ne 0 ]; then
           log_message "Fehler: Python/pip-Installation fehlgeschlagen"
           exit 1
       fi
   fi

   # Installiere jq
   if ! jq --version 2>/dev/null; then
       log_message "Installiere jq"
       sudo apt install -y jq
       if [ $? -ne 0 ]; then
           log_message "Fehler: jq-Installation fehlgeschlagen"
           exit 1
       fi
   fi

   # Installiere PySpark und findspark
   if ! pip show pyspark >/dev/null 2>&1; then
       log_message "Installiere PySpark und findspark"
       pip3 install pyspark findspark
       if [ $? -ne 0 ]; then
           log_message "Fehler: PySpark/findspark-Installation fehlgeschlagen"
           exit 1
       fi
   fi

   # Überprüfe Installation
   pyspark_version=$(python3 -c "import pyspark; print(pyspark.__version__)" 2>/dev/null)
   if [ $? -eq 0 ]; then
       log_message "PySpark-Version: $pyspark_version"
       echo "Installation erfolgreich: PySpark $pyspark_version"
   else
       log_message "Fehler: PySpark-Version konnte nicht überprüft werden"
       exit 1
   fi
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   chmod +x install_spark.sh
   ./install_spark.sh
   ```

4. **Schritt 4**: Protokolliere die Ergebnisse:
   ```bash
   cat bigdata_log.txt
   ```
   **Beispielausgabe**:
   ```
   2025-09-05 13:20:00 - Starte Installation
   2025-09-05 13:20:02 - Installiere Java
   2025-09-05 13:20:10 - Installiere Python und pip
   2025-09-05 13:20:15 - Installiere jq
   2025-09-05 13:20:20 - Installiere PySpark und findspark
   2025-09-05 13:20:25 - PySpark-Version: 3.5.1
   ```

**Reflexion**: Wie automatisiert ein Bash-Skript die Installation? Nutze `man apt` und überlege, wie du andere Abhängigkeiten prüfst.

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
       for i in range(100000):
           entry = {
               'timestamp': int(time.time()),
               'user_id': random.randint(1, 1000),
               'event': random.choice(log_events)
           }
           f.write(json.dumps(entry) + '\n')

   print("Datensatz erstellt.")
   ```
   Speichere und schließe.

2. **Schritt 2**: Erstelle ein Bash-Skript zur Ausführung:
   ```bash
   nano generate_data.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash

   LOG_FILE="bigdata_log.txt"

   log_message() {
       echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
   }

   log_message "Starte Datengenerierung"
   if [ ! -f "data_gen.py" ]; then
       log_message "Fehler: data_gen.py nicht gefunden"
       echo "Fehler: data_gen.py nicht gefunden" >&2
       exit 1
   fi

   python3 data_gen.py
   if [ $? -eq 0 ]; then
       log_message "Datensatz erstellt: large_data.json"
       du -sh large_data.json >> "$LOG_FILE"
       head -n 5 large_data.json >> "$LOG_FILE"
       echo "Datensatz erstellt: large_data.json"
   else
       log_message "Fehler: Datengenerierung fehlgeschlagen"
       echo "Fehler: Datengenerierung fehlgeschlagen" >&2
       exit 1
   fi
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   chmod +x generate_data.sh
   ./generate_data.sh
   ```

4. **Schritt 4**: Protokolliere die Ergebnisse:
   ```bash
   cat bigdata_log.txt
   ```
   **Beispielausgabe**:
   ```
   2025-09-05 13:25:00 - Starte Datengenerierung
   2025-09-05 13:25:05 - Datensatz erstellt: large_data.json
   12M     large_data.json
   {"timestamp":1725532080,"user_id":542,"event":"LOGIN"}
   {"timestamp":1725532080,"user_id":123,"event":"ERROR"}
   {"timestamp":1725532080,"user_id":987,"event":"VIEW_PAGE"}
   {"timestamp":1725532080,"user_id":456,"event":"PURCHASE"}
   {"timestamp":1725532080,"user_id":789,"event":"LOGOUT"}
   ```

**Reflexion**: Wie simuliert die JSON-Datei Big-Data-Szenarien? Nutze `man jq` und überlege, wie du die Daten mit `jq` direkt in Bash analysierst.

### Übung 3: Daten laden und filtern
**Ziel**: Führe ein PySpark-Skript aus Bash aus, um "ERROR"-Ereignisse zu filtern, und analysiere die Ausgabe.

1. **Schritt 1**: Erstelle ein PySpark-Skript für die Analyse:
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

2. **Schritt 2**: Erstelle ein Bash-Skript zur Ausführung:
   ```bash
   nano run_analyze.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash

   LOG_FILE="bigdata_log.txt"

   log_message() {
       echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
   }

   log_message "Starte Fehleranalyse"
   if [ ! -f "large_data.json" ]; then
       log_message "Fehler: large_data.json nicht gefunden"
       echo "Fehler: large_data.json nicht gefunden" >&2
       exit 1
   fi
   if [ ! -f "analyze.py" ]; then
       log_message "Fehler: analyze.py nicht gefunden"
       echo "Fehler: analyze.py nicht gefunden" >&2
       exit 1
   fi

   python3 analyze.py > error_output.txt
   if [ $? -eq 0 ]; then
       error_count=$(grep "Anzahl der Fehler" error_output.txt | cut -d' ' -f4)
       log_message "Fehleranalyse abgeschlossen: $error_count Fehler"
       echo "Fehleranalyse abgeschlossen: $error_count Fehler"
   else
       log_message "Fehler: Analyse fehlgeschlagen"
       echo "Fehler: Analyse fehlgeschlagen" >&2
       exit 1
   fi
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   chmod +x run_analyze.sh
   ./run_analyze.sh
   ```

4. **Schritt 4**: Protokolliere die Ergebnisse:
   ```bash
   cat bigdata_log.txt
   ```
   **Beispielausgabe**:
   ```
   2025-09-05 13:30:00 - Starte Fehleranalyse
   2025-09-05 13:30:05 - Fehleranalyse abgeschlossen: 19987 Fehler
   ```

**Reflexion**: Wie steuert Bash PySpark-Skripte? Nutze `man grep` und überlege, wie du `jq` für die Fehlerzählung nutzt.

### Übung 4: Daten gruppieren und aggregieren
**Ziel**: Führe eine PySpark-Aggregation aus und verarbeite die Ergebnisse in Bash.

1. **Schritt 1**: Aktualisiere das PySpark-Skript:
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
   error_count = error_df.count()
   print(f"Anzahl der Fehler: {error_count}")

   user_event_counts = df.groupBy("user_id").count().sort("count", ascending=False).limit(10)
   user_event_counts.write.csv("user_counts.csv", mode="overwrite", header=True)
   print("Top 10 Benutzer gespeichert in user_counts.csv")

   spark.stop()
   ```
   Speichere und schließe.

2. **Schritt 2**: Erstelle ein Bash-Skript zur Ausführung und Verarbeitung:
   ```bash
   nano run_agg.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash

   LOG_FILE="bigdata_log.txt"

   log_message() {
       echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
   }

   log_message "Starte Aggregation"
   if [ ! -f "large_data.json" ]; then
       log_message "Fehler: large_data.json nicht gefunden"
       echo "Fehler: large_data.json nicht gefunden" >&2
       exit 1
   fi
   if [ ! -f "analyze.py" ]; then
       log_message "Fehler: analyze.py nicht gefunden"
       echo "Fehler: analyze.py nicht gefunden" >&2
       exit 1
   fi

   python3 analyze.py > agg_output.txt
   if [ $? -eq 0 ]; then
       error_count=$(grep "Anzahl der Fehler" agg_output.txt | cut -d' ' -f4)
       log_message "Aggregation abgeschlossen: $error_count Fehler"
       if [ -d "user_counts.csv" ]; then
           user_counts=$(find user_counts.csv -type f -name "*.csv" -exec cat {} \; | tail -n +2 | head -n 10)
           log_message "Top 10 Benutzer:\n$user_counts"
           echo "Aggregation abgeschlossen: $error_count Fehler"
           echo "Top 10 Benutzer:"
           echo "$user_counts"
       else
           log_message "Fehler: user_counts.csv nicht gefunden"
           echo "Fehler: user_counts.csv nicht gefunden" >&2
           exit 1
       fi
   else
       log_message "Fehler: Aggregation fehlgeschlagen"
       echo "Fehler: Aggregation fehlgeschlagen" >&2
       exit 1
   fi
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   chmod +x run_agg.sh
   ./run_agg.sh
   ```

4. **Schritt 4**: Protokolliere die Ergebnisse:
   ```bash
   cat bigdata_log.txt
   ```
   **Beispielausgabe**:
   ```
   2025-09-05 13:35:00 - Starte Aggregation
   2025-09-05 13:35:05 - Aggregation abgeschlossen: 19987 Fehler
   2025-09-05 13:35:05 - Top 10 Benutzer:
   543,127
   876,123
   234,119
   ...
   ```

**Reflexion**: Wie kann Bash PySpark-Ausgaben verarbeiten? Nutze `man find` und überlege, wie du Aggregationen direkt in Bash mit `jq` durchführst.

### Übung 5: Daten in Parquet schreiben
**Ziel**: Konvertiere die JSON-Datei in Parquet und vergleiche die Dateigröße.

1. **Schritt 1**: Erstelle ein PySpark-Skript für Parquet:
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

2. **Schritt 2**: Erstelle ein Bash-Skript zur Ausführung:
   ```bash
   nano run_parquet.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash

   LOG_FILE="bigdata_log.txt"

   log_message() {
       echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
   }

   log_message "Starte Parquet-Konvertierung"
   if [ ! -f "large_data.json" ]; then
       log_message "Fehler: large_data.json nicht gefunden"
       echo "Fehler: large_data.json nicht gefunden" >&2
       exit 1
   fi
   if [ ! -f "write_parquet.py" ]; then
       log_message "Fehler: write_parquet.py nicht gefunden"
       echo "Fehler: write_parquet.py nicht gefunden" >&2
       exit 1
   fi

   python3 write_parquet.py
   if [ $? -eq 0 ]; then
       json_size=$(du -sh large_data.json | cut -f1)
       parquet_size=$(du -sh optimized_data.parquet | cut -f1)
       log_message "Parquet-Konvertierung abgeschlossen"
       log_message "Dateigrößen: JSON=$json_size, Parquet=$parquet_size"
       echo "Parquet-Konvertierung abgeschlossen"
       echo "Dateigrößen: JSON=$json_size, Parquet=$parquet_size"
   else
       log_message "Fehler: Parquet-Konvertierung fehlgeschlagen"
       echo "Fehler: Parquet-Konvertierung fehlgeschlagen" >&2
       exit 1
   fi
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   chmod +x run_parquet.sh
   ./run_parquet.sh
   ```

4. **Schritt 4**: Protokolliere die Ergebnisse:
   ```bash
   cat bigdata_log.txt
   ```
   **Beispielausgabe**:
   ```
   2025-09-05 13:40:00 - Starte Parquet-Konvertierung
   2025-09-05 13:40:05 - Parquet-Konvertierung abgeschlossen
   2025-09-05 13:40:05 - Dateigrößen: JSON=12M, Parquet=4.0M
   ```

**Reflexion**: Warum ist Parquet effizienter als JSON? Nutze `man du` und überlege, wie du Partitionierung in PySpark einrichtest.

### Übung 6: Performance vergleichen
**Ziel**: Vergleiche die Ladezeit von JSON- und Parquet-Dateien.

1. **Schritt 1**: Erstelle ein PySpark-Skript für den Performance-Test:
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

2. **Schritt 2**: Erstelle ein Bash-Skript zur Ausführung:
   ```bash
   nano run_perf_test.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash

   LOG_FILE="bigdata_log.txt"

   log_message() {
       echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
   }

   log_message "Starte Performance-Test"
   if [ ! -f "large_data.json" ] || [ ! -d "optimized_data.parquet" ]; then
       log_message "Fehler: Eingabedateien fehlen"
       echo "Fehler: Eingabedateien fehlen" >&2
       exit 1
   fi
   if [ ! -f "perf_test.py" ]; then
       log_message "Fehler: perf_test.py nicht gefunden"
       echo "Fehler: perf_test.py nicht gefunden" >&2
       exit 1
   fi

   python3 perf_test.py > perf_output.txt
   if [ $? -eq 0 ]; then
       json_time=$(grep "JSON-Datei" perf_output.txt | cut -d' ' -f4)
       parquet_time=$(grep "Parquet-Datei" perf_output.txt | cut -d' ' -f4)
       log_message "Performance-Test abgeschlossen: JSON=$json_time s, Parquet=$parquet_time s"
       echo "Performance-Test abgeschlossen: JSON=$json_time s, Parquet=$parquet_time s"
   else
       log_message "Fehler: Performance-Test fehlgeschlagen"
       echo "Fehler: Performance-Test fehlgeschlagen" >&2
       exit 1
   fi
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   chmod +x run_perf_test.sh
   ./run_perf_test.sh
   ```

4. **Schritt 4**: Protokolliere die Ergebnisse:
   ```bash
   cat bigdata_log.txt
   ```
   **Beispielausgabe**:
   ```
   2025-09-05 13:45:00 - Starte Performance-Test
   2025-09-05 13:45:05 - Performance-Test abgeschlossen: JSON=2.45 s, Parquet=0.78 s
   ```

**Reflexion**: Warum ist Parquet schneller? Nutze `man time` und überlege, wie du die Performance weiter optimierst.

### Übung 7: Spielerei – Ergebnisse in Markdown-Tabelle zusammenfassen und per E-Mail versenden
**Ziel**: Erstelle ein Markdown-Dokument mit Analyseergebnissen und versende es per E-Mail.

1. **Schritt 1**: Erstelle ein PySpark-Skript für die Analyse:
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

   df = spark.read.json("large_data.json")
   error_count = df.filter(df.event == "ERROR").count()
   user_counts = df.groupBy("user_id").count().sort("count", ascending=False).limit(10).collect()

   start_time = time.time()
   df_json = spark.read.json("large_data.json")
   df_json.count()
   json_time = time.time() - start_time

   start_time = time.time()
   df_parquet = spark.read.parquet("optimized_data.parquet")
   df_parquet.count()
   parquet_time = time.time() - start_time

   spark.stop()

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

   print("Zusammenfassung erstellt: bigdata_summary.md")
   ```
   Speichere und schließe.

2. **Schritt 2**: Erstelle ein Bash-Skript für die Ausführung und den E-Mail-Versand:
   ```bash
   nano run_summary.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash

   LOG_FILE="bigdata_log.txt"
   OUTPUT_FILE="bigdata_summary.md"
   RECIPIENT="empfänger@example.com"  # Ersetze mit Empfänger-E-Mail

   log_message() {
       echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
   }

   log_message "Starte Zusammenfassung und E-Mail-Versand"
   if [ ! -f "large_data.json" ] || [ ! -d "optimized_data.parquet" ]; then
       log_message "Fehler: Eingabedateien fehlen"
       echo "Fehler: Eingabedateien fehlen" >&2
       exit 1
   fi
   if [ ! -f "summary.py" ]; then
       log_message "Fehler: summary.py nicht gefunden"
       echo "Fehler: summary.py nicht gefunden" >&2
       exit 1
   fi

   python3 summary.py
   if [ $? -eq 0 ] && [ -f "$OUTPUT_FILE" ]; then
       log_message "Zusammenfassung erstellt: $OUTPUT_FILE"
       echo "Zusammenfassung erstellt: $OUTPUT_FILE"
       mail -s "Big Data Analyse Zusammenfassung" "$RECIPIENT" < "$OUTPUT_FILE"
       if [ $? -eq 0 ]; then
           log_message "E-Mail erfolgreich an $RECIPIENT gesendet"
           echo "E-Mail erfolgreich an $RECIPIENT gesendet"
       else
           log_message "Fehler: E-Mail-Versand fehlgeschlagen"
           echo "Fehler: E-Mail-Versand fehlgeschlagen" >&2
           exit 1
       fi
   else
       log_message "Fehler: Zusammenfassung fehlgeschlagen"
       echo "Fehler: Zusammenfassung fehlgeschlagen" >&2
       exit 1
   fi
   ```
   Speichere und schließe.

3. **Schritt 3**: Konfiguriere `mail` (falls nötig):
   ```bash
   sudo apt install mailutils
   ```
   Für Gmail oder einen externen SMTP-Server konfiguriere Postfix:
   ```bash
   sudo dpkg-reconfigure postfix
   ```
   Alternativ bearbeite `/etc/postfix/main.cf` für Gmail (Beispiel):
   ```
   relayhost = [smtp.gmail.com]:587
   smtp_sasl_auth_enable = yes
   smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
   smtp_sasl_security_options = noanonymous
   smtp_tls_security_level = encrypt
   ```
   Erstelle `/etc/postfix/sasl_passwd`:
   ```bash
   sudo nano /etc/postfix/sasl_passwd
   ```
   Füge ein:
   ```
   [smtp.gmail.com]:587 dein.email@gmail.com:dein-app-passwort
   ```
   Aktualisiere die Postfix-Datenbank:
   ```bash
   sudo postmap /etc/postfix/sasl_passwd
   sudo chown root:root /etc/postfix/sasl_passwd
   sudo chmod 600 /etc/postfix/sasl_passwd
   sudo systemctl restart postfix
   ```

4. **Schritt 4**: Führe das Skript aus:
   ```bash
   chmod +x run_summary.sh
   ./run_summary.sh
   ```

5. **Schritt 5**: Überprüfe die Markdown-Ausgabe:
   ```bash
   cat bigdata_summary.md
   ```
   **Beispielausgabe**:
   ```
   # Big Data Analyse Zusammenfassung
   Erstellt am: 2025-09-05 13:50:00

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

6. **Schritt 6**: Protokolliere die Ergebnisse:
   ```bash
   cat bigdata_log.txt
   ```
   **Beispielausgabe**:
   ```
   2025-09-05 13:50:00 - Starte Zusammenfassung und E-Mail-Versand
   2025-09-05 13:50:05 - Zusammenfassung erstellt: bigdata_summary.md
   2025-09-05 13:50:06 - E-Mail erfolgreich an empfänger@example.com gesendet
   ```

**Reflexion**: Wie verbessert die Automatisierung mit Bash die Dokumentation und den Versand? Nutze `man mail` und überlege, wie du Anhänge (z. B. CSV-Dateien) versendest.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Bash-Automatisierung zu verinnerlichen.
- **Sicheres Testen**: Arbeite in einer Testumgebung und sichere Dateien (`cp large_data.json large_data.json.bak`).
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze `man bash`, `man jq` oder die PySpark-Dokumentation.
- **Effiziente Entwicklung**: Nutze Bash-Funktionen für Modularität, Exit-Codes für Fehlerbehandlung und Logging für Nachvollziehbarkeit.
- **Kombiniere Tools**: Integriere `awk` oder `sed` für erweiterte Textverarbeitung oder `cron` für regelmäßige Ausführung.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Hinzufügen von Visualisierungen (via `gnuplot`) oder komplexere E-Mail-Inhalte.

## Fazit
Mit diesen Übungen hast du gelernt, PySpark-Installation und -Analysen mit Bash zu automatisieren, einen simulierten Datensatz zu erstellen, PySpark-Skripte auszuführen, Aggregationen mit Bash-Tools zu verarbeiten, Daten in Parquet zu speichern und Ergebnisse in Markdown zu dokumentieren sowie per E-Mail zu versenden. Die Spielerei zeigt, wie du Analyse, Dokumentation und Versand kombinierst. Vertiefe dein Wissen, indem du fortgeschrittene Themen (z. B. Bash-Skripte für Spark-Cluster, komplexe `jq`-Abfragen) oder Tools wie `gnuplot` oder `airflow` ausprobierst. Wenn du ein spezifisches Thema (z. B. Visualisierung oder verteilte Verarbeitung) vertiefen möchtest, lass es mich wissen!
