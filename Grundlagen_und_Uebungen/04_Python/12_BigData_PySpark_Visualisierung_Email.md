# Praxisorientierte Anleitung: Big Data Visualisierung mit PySpark und E-Mail-Versand

## Einführung
Die Visualisierung von Big Data hilft, Muster in großen Datensätzen zu erkennen, und der Versand der Ergebnisse per E-Mail ist ein häufiger Anwendungsfall in der Automatisierung von Berichten. Mit **PySpark** kannst du große Datenmengen analysieren, die Ergebnisse in ein Pandas-DataFrame übertragen und mit **Matplotlib** und **Seaborn** visualisieren. Mit **smtplib** kannst du die Ergebnisse (Markdown-Bericht und Diagramme) per E-Mail versenden. Diese Anleitung führt Anfänger durch praktische Übungen zur **Analyse von Daten mit PySpark**, **Konvertierung in Pandas**, **Erstellung von Diagrammen** (Balkendiagramme, Histogramme, Zeitreihen), **Einbettung in Markdown** und **Versand per E-Mail**. Die Übungen verwenden die JSON-Datei `large_data.json` (100.000 Log-Einträge) und die optimierte `optimized_data.parquet`. Eine **Spielerei** zeigt, wie du die Visualisierungen und den Bericht per E-Mail versendest. Die Übungen sind auf einem Debian-basierten System ausführbar und für Nutzer mit grundlegenden Kenntnissen in Bash, Python, PySpark und E-Mail-Konfiguration geeignet.

**Voraussetzungen**:
- Ein Debian-basiertes System (z. B. Ubuntu 22.04, Debian 11); Windows-Nutzer können WSL2 verwenden; macOS ist kompatibel.
- Ein Terminal (z. B. Bash unter Linux).
- Installierte Tools:
  - Java Runtime Environment (JRE): `sudo apt install default-jre`
  - Python 3 und `pip`: `sudo apt install python3 python3-pip`
  - PySpark und `findspark`: `pip install pyspark findspark`
  - Matplotlib und Seaborn: `pip install matplotlib seaborn`
  - Die Dateien `large_data.json`, `large_data_variable.json`, `optimized_data.parquet` und `optimized_data_variable.parquet` aus den vorherigen Übungen.
- Grundkenntnisse in Bash (Befehle, Skripte), Python, PySpark, Visualisierung und E-Mail-Konfiguration.
- Sichere Testumgebung (z. B. `$HOME/bigdata_tests` oder `~/bigdata_tests`).
- E-Mail-Konfiguration:
  - Zugriff auf einen SMTP-Server (z. B. Gmail mit App-Passwort oder lokaler SMTP-Server).
  - Python-Bibliothek `smtplib` (in der Standardbibliothek enthalten).
- Optional: Bildbetrachter (z. B. `eog`: `sudo apt install eog`).

## Grundlegende Befehle
Hier sind die wichtigsten Bash- und Python-Befehle für die Übungen:

1. **Datenanalyse mit PySpark**:
   - `spark.read.parquet(<Datei>)`: Lädt Parquet-Daten in einen DataFrame.
   - `df.groupBy().count()`: Gruppiert und aggregiert Daten.
   - `df.toPandas()`: Konvertiert einen PySpark-DataFrame in ein Pandas-DataFrame.
2. **Visualisierung mit Matplotlib/Seaborn**:
   - `plt.bar()`: Erstellt ein Balkendiagramm.
   - `sns.countplot()`: Erstellt ein Histogramm für kategorische Daten.
   - `plt.savefig(<Datei>)`: Speichert das Diagramm als PNG.
3. **E-Mail-Versand mit smtplib**:
   - `smtplib.SMTP()`: Verbindet zum SMTP-Server.
   - `email.mime`: Erstellt E-Mails mit Anhängen.
4. **Markdown-Einbettung**:
   - `echo "![Beschreibung](Datei)"`: Fügt Bilder in Markdown ein.
5. **Nützliche Zusatzbefehle**:
   - `man python3`: Dokumentation für Python.
   - `eog <Datei>`: Öffnet PNG-Dateien (Ubuntu).
   - `du -sh <Datei>`: Prüft die Dateigröße.
   - `date`: Fügt Zeitstempel in Protokollen hinzu.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Visualisierungsvoraussetzungen installieren
**Ziel**: Installiere Matplotlib, Seaborn und überprüfe die E-Mail-Voraussetzungen.

1. **Schritt 1**: Wechsle in das Testverzeichnis:
   ```bash
   cd bigdata_tests
   ```

2. **Schritt 2**: Installiere Matplotlib und Seaborn:
   ```bash
   pip install matplotlib seaborn
   ```

3. **Schritt 3**: Überprüfe die Installation:
   ```bash
   python3 -c "import matplotlib; import seaborn; import smtplib; print(matplotlib.__version__, seaborn.__version__)"
   ```
   **Beispielausgabe**:
   ```
   3.8.2 0.13.2
   ```

4. **Schritt 4**: Protokolliere die Installation:
   ```bash
   echo "Visualisierungstools und smtplib geprüft am $(date)" >> bigdata_log.txt
   python3 -c "import matplotlib; import seaborn; print(matplotlib.__version__, seaborn.__version__)" >> bigdata_log.txt
   cat bigdata_log.txt
   ```

**Reflexion**: Warum ist `smtplib` für den E-Mail-Versand geeignet? Nutze die Python-Dokumentation (`help(smtplib)`) und überlege, wie du einen lokalen SMTP-Server einrichtest.

### Übung 2: Balkendiagramm für Ereignisse pro Benutzer
**Ziel**: Erstelle ein Balkendiagramm der Top-10-Benutzer nach Ereignisanzahl.

1. **Schritt 1**: Erstelle ein Python-Skript für die Visualisierung:
   ```bash
   nano user_events_plot.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import findspark
   from pyspark.sql import SparkSession
   import pandas as pd
   import matplotlib.pyplot as plt

   findspark.init()
   spark = SparkSession.builder.appName("UserEventsPlot").getOrCreate()

   df = spark.read.parquet("optimized_data.parquet")
   user_counts = df.groupBy("user_id").count().sort("count", ascending=False).limit(10)
   pandas_df = user_counts.toPandas()

   plt.figure(figsize=(10, 6))
   plt.bar(pandas_df["user_id"].astype(str), pandas_df["count"], color="skyblue")
   plt.xlabel("User ID")
   plt.ylabel("Anzahl der Ereignisse")
   plt.title("Top 10 Benutzer nach Ereignisanzahl")
   plt.tight_layout()
   plt.savefig("user_events_plot.png")
   plt.close()

   print("Balkendiagramm erstellt: user_events_plot.png")
   spark.stop()
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   python3 user_events_plot.py
   ```

3. **Schritt 3**: Überprüfe das Diagramm:
   ```bash
   eog user_events_plot.png
   ```

4. **Schritt 4**: Protokolliere die Erstellung:
   ```bash
   echo "Balkendiagramm erstellt am $(date)" >> bigdata_log.txt
   ls -lh user_events_plot.png >> bigdata_log.txt
   cat bigdata_log.txt
   ```

**Reflexion**: Wie hilft ein Balkendiagramm bei der Identifikation von Top-Benutzern? Nutze die Matplotlib-Dokumentation und überlege, wie du die Visualisierung anpasst.

### Übung 3: Histogramm für Ereignistypen
**Ziel**: Erstelle ein Histogramm der Verteilung der Ereignistypen (`event`) mit Seaborn.

1. **Schritt 1**: Erstelle ein Python-Skript für das Histogramm:
   ```bash
   nano event_distribution_plot.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import findspark
   from pyspark.sql import SparkSession
   import pandas as pd
   import seaborn as sns
   import matplotlib.pyplot as plt

   findspark.init()
   spark = SparkSession.builder.appName("EventDistributionPlot").getOrCreate()

   df = spark.read.parquet("optimized_data.parquet")
   event_counts = df.groupBy("event").count().toPandas()

   plt.figure(figsize=(10, 6))
   sns.countplot(data=event_counts, x="event", hue="event", palette="viridis", legend=False)
   plt.xlabel("Ereignistyp")
   plt.ylabel("Anzahl")
   plt.title("Verteilung der Ereignistypen")
   plt.xticks(rotation=45)
   plt.tight_layout()
   plt.savefig("event_distribution_plot.png")
   plt.close()

   print("Histogramm erstellt: event_distribution_plot.png")
   spark.stop()
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   python3 event_distribution_plot.py
   ```

3. **Schritt 3**: Überprüfe das Diagramm:
   ```bash
   eog event_distribution_plot.png
   ```

4. **Schritt 4**: Protokolliere die Erstellung:
   ```bash
   echo "Histogramm erstellt am $(date)" >> bigdata_log.txt
   ls -lh event_distribution_plot.png >> bigdata_log.txt
   cat bigdata_log.txt
   ```

**Reflexion**: Warum ist ein Histogramm für Ereignistypen nützlich? Nutze die Seaborn-Dokumentation und überlege, wie du andere Visualisierungen erstellst.

### Übung 4: Zeitreihenanalyse der Ereignisse
**Ziel**: Erstelle eine Zeitreihenvisualisierung der Ereignisse pro Minute mit variablen Timestamps.

1. **Schritt 1**: Verwende die Datei `optimized_data_variable.parquet` aus der vorherigen Anleitung (mit variablen Timestamps).

2. **Schritt 2**: Erstelle ein Skript für die Zeitreihenvisualisierung:
   ```bash
   nano time_series_plot.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import findspark
   from pyspark.sql import SparkSession
   from pyspark.sql.functions import from_unixtime, date_format
   import pandas as pd
   import matplotlib.pyplot as plt

   findspark.init()
   spark = SparkSession.builder.appName("TimeSeriesPlot").getOrCreate()

   df = spark.read.parquet("optimized_data_variable.parquet")
   df = df.withColumn("time", from_unixtime("timestamp"))
   df = df.withColumn("time_bucket", date_format("time", "yyyy-MM-dd HH:mm"))
   time_counts = df.groupBy("time_bucket").count().sort("time_bucket").toPandas()

   plt.figure(figsize=(12, 6))
   plt.plot(time_counts["time_bucket"], time_counts["count"], marker='o', linestyle='-', color='teal')
   plt.xlabel("Zeit (YYYY-MM-DD HH:MM)")
   plt.ylabel("Anzahl der Ereignisse")
   plt.title("Zeitreihenanalyse: Ereignisse pro Minute")
   plt.xticks(rotation=45)
   plt.tight_layout()
   plt.savefig("time_series_plot.png")
   plt.close()

   print("Zeitreihendiagramm erstellt: time_series_plot.png")
   spark.stop()
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   python3 time_series_plot.py
   ```

4. **Schritt 4**: Überprüfe das Diagramm:
   ```bash
   eog time_series_plot.png
   ```

5. **Schritt 5**: Protokolliere die Erstellung:
   ```bash
   echo "Zeitreihendiagramm erstellt am $(date)" >> bigdata_log.txt
   ls -lh time_series_plot.png >> bigdata_log.txt
   cat bigdata_log.txt
   ```

**Reflexion**: Wie hilft die Zeitreihenanalyse bei der Mustererkennung? Nutze die PySpark-Dokumentation (`pyspark.sql.functions`) und überlege, wie du andere Zeitintervalle analysierst.

### Übung 5: Ergebnisse per E-Mail versenden
**Ziel**: Versende den Markdown-Bericht und die Visualisierungen per E-Mail mit `smtplib`.

1. **Schritt 1**: Erstelle ein Python-Skript für den E-Mail-Versand:
   ```bash
   nano send_email.py
   ```
   Füge folgenden Inhalt ein (passe die E-Mail-Einstellungen an):
   ```python
   import smtplib
   from email.mime.text import MIMEText
   from email.mime.multipart import MIMEMultipart
   from email.mime.base import MIMEBase
   from email import encoders
   import os

   # E-Mail-Konfiguration (Beispiel für Gmail)
   smtp_server = "smtp.gmail.com"
   smtp_port = 587
   sender_email = "dein.email@gmail.com"  # Ersetze mit deiner E-Mail
   sender_password = "dein-app-passwort"  # Ersetze mit deinem App-Passwort
   receiver_email = "empfänger@example.com"  # Ersetze mit Empfänger-E-Mail

   # Erstelle E-Mail
   msg = MIMEMultipart()
   msg["From"] = sender_email
   msg["To"] = receiver_email
   msg["Subject"] = "Big Data Analysebericht"

   # Füge Markdown-Bericht als Text hinzu
   with open("visualization_summary.md", "r") as f:
       body = f.read()
   msg.attach(MIMEText(body, "plain"))

   # Füge Visualisierungen als Anhänge hinzu
   attachments = ["user_events_plot.png", "event_distribution_plot.png", "time_series_plot.png"]
   for file in attachments:
       if os.path.exists(file):
           with open(file, "rb") as attachment:
               part = MIMEBase("application", "octet-stream")
               part.set_payload(attachment.read())
           encoders.encode_base64(part)
           part.add_header(
               "Content-Disposition",
               f"attachment; filename= {os.path.basename(file)}"
           )
           msg.attach(part)

   # Sende E-Mail
   try:
       server = smtplib.SMTP(smtp_server, smtp_port)
       server.starttls()
       server.login(sender_email, sender_password)
       server.sendmail(sender_email, receiver_email, msg.as_string())
       server.quit()
       print("E-Mail erfolgreich gesendet.")
   except Exception as e:
       print(f"Fehler beim Senden der E-Mail: {e}")

   ```
   Speichere und schließe.

   **Hinweis**: Für Gmail benötigst du ein **App-Passwort** (aktiviere die Zwei-Faktor-Authentifizierung und erstelle ein App-Passwort in den Google-Kontoeinstellungen). Alternativ kannst du einen lokalen SMTP-Server (z. B. Postfix) verwenden.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   python3 send_email.py
   ```

3. **Schritt 3**: Protokolliere den Versand:
   ```bash
   echo "E-Mail-Versand versucht am $(date)" >> bigdata_log.txt
   python3 send_email.py | tee -a bigdata_log.txt
   cat bigdata_log.txt
   ```

**Reflexion**: Wie automatisiert der E-Mail-Versand die Berichterstellung? Nutze die Python-Dokumentation (`help(smtplib)`) und überlege, wie du CC-Empfänger oder HTML-Inhalte hinzufügst.

### Übung 6: Spielerei – Markdown mit eingebetteten Visualisierungen und E-Mail-Versand
**Ziel**: Erstelle ein Markdown-Dokument mit Analyseergebnissen und Visualisierungen und versende es per E-Mail.

1. **Schritt 1**: Erstelle ein Python-Skript für die kombinierte Ausgabe und den E-Mail-Versand:
   ```bash
   nano visualization_email_summary.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import findspark
   from pyspark.sql import SparkSession
   from pyspark.sql.functions import from_unixtime, date_format
   import pandas as pd
   import matplotlib.pyplot as plt
   import seaborn as sns
   import smtplib
   from email.mime.text import MIMEText
   from email.mime.multipart import MIMEMultipart
   from email.mime.base import MIMEBase
   from email import encoders
   import os
   import time

   findspark.init()
   spark = SparkSession.builder.appName("VisualizationEmailSummary").getOrCreate()

   # Lade Parquet-Datei
   df = spark.read.parquet("optimized_data.parquet")
   error_count = df.filter(df.event == "ERROR").count()
   user_counts = df.groupBy("user_id").count().sort("count", ascending=False).limit(10).toPandas()
   event_counts = df.groupBy("event").count().toPandas()

   # Balkendiagramm für Top-Benutzer
   plt.figure(figsize=(10, 6))
   plt.bar(user_counts["user_id"].astype(str), user_counts["count"], color="skyblue")
   plt.xlabel("User ID")
   plt.ylabel("Anzahl der Ereignisse")
   plt.title("Top 10 Benutzer nach Ereignisanzahl")
   plt.tight_layout()
   plt.savefig("user_events_plot.png")
   plt.close()

   # Histogramm für Ereignistypen
   plt.figure(figsize=(10, 6))
   sns.countplot(data=event_counts, x="event", hue="event", palette="viridis", legend=False)
   plt.xlabel("Ereignistyp")
   plt.ylabel("Anzahl")
   plt.title("Verteilung der Ereignistypen")
   plt.xticks(rotation=45)
   plt.tight_layout()
   plt.savefig("event_distribution_plot.png")
   plt.close()

   # Zeitreihenanalyse
   df_var = spark.read.parquet("optimized_data_variable.parquet")
   df_var = df_var.withColumn("time", from_unixtime("timestamp"))
   df_var = df_var.withColumn("time_bucket", date_format("time", "yyyy-MM-dd HH:mm"))
   time_counts = df_var.groupBy("time_bucket").count().sort("time_bucket").toPandas()
   plt.figure(figsize=(12, 6))
   plt.plot(time_counts["time_bucket"], time_counts["count"], marker='o', linestyle='-', color='teal')
   plt.xlabel("Zeit (YYYY-MM-DD HH:MM)")
   plt.ylabel("Anzahl der Ereignisse")
   plt.title("Zeitreihenanalyse: Ereignisse pro Minute")
   plt.xticks(rotation=45)
   plt.tight_layout()
   plt.savefig("time_series_plot.png")
   plt.close()

   # Markdown-Ausgabe
   with open("visualization_summary.md", "w") as f:
       f.write("# Big Data Visualisierung Zusammenfassung\n")
       f.write(f"Erstellt am: {time.strftime('%Y-%m-%d %H:%M:%S')}\n\n")
       f.write("## Analyseergebnisse\n")
       f.write("| Metrik | Wert |\n")
       f.write("|--------|------|\n")
       f.write(f"| Anzahl der Fehler | {error_count} |\n")
       f.write("\n## Top 10 Benutzer (nach Ereignissen)\n")
       f.write("| User ID | Anzahl Ereignisse |\n")
       f.write("|---------|-------------------|\n")
       for _, row in user_counts.iterrows():
           f.write(f"| {row['user_id']} | {row['count']} |\n")
       f.write("\n## Visualisierungen\n")
       f.write("### Top 10 Benutzer nach Ereignisanzahl\n")
       f.write("![Balkendiagramm](user_events_plot.png)\n")
       f.write("\n### Verteilung der Ereignistypen\n")
       f.write("![Histogramm](event_distribution_plot.png)\n")
       f.write("\n### Zeitreihenanalyse: Ereignisse pro Minute\n")
       f.write("![Zeitreihendiagramm](time_series_plot.png)\n")

   # E-Mail-Versand
   smtp_server = "smtp.gmail.com"
   smtp_port = 587
   sender_email = "dein.email@gmail.com"  # Ersetze mit deiner E-Mail
   sender_password = "dein-app-passwort"  # Ersetze mit deinem App-Passwort
   receiver_email = "empfänger@example.com"  # Ersetze mit Empfänger-E-Mail

   msg = MIMEMultipart()
   msg["From"] = sender_email
   msg["To"] = receiver_email
   msg["Subject"] = "Big Data Analysebericht"

   with open("visualization_summary.md", "r") as f:
       body = f.read()
   msg.attach(MIMEText(body, "plain"))

   attachments = ["user_events_plot.png", "event_distribution_plot.png", "time_series_plot.png"]
   for file in attachments:
       if os.path.exists(file):
           with open(file, "rb") as attachment:
               part = MIMEBase("application", "octet-stream")
               part.set_payload(attachment.read())
           encoders.encode_base64(part)
           part.add_header(
               "Content-Disposition",
               f"attachment; filename= {os.path.basename(file)}"
           )
           msg.attach(part)

   try:
       server = smtplib.SMTP(smtp_server, smtp_port)
       server.starttls()
       server.login(sender_email, sender_password)
       server.sendmail(sender_email, receiver_email, msg.as_string())
       server.quit()
       print("E-Mail erfolgreich gesendet.")
   except Exception as e:
       print(f"Fehler beim Senden der E-Mail: {e}")

   print("Zusammenfassung erstellt: visualization_summary.md")
   spark.stop()
   ```
   Speichere und schließe.

2. **Schritt 2**: Führe das Skript aus:
   ```bash
   python3 visualization_email_summary.py
   ```

3. **Spielerei**: Überprüfe die Markdown-Ausgabe und die E-Mail:
   ```bash
   cat visualization_summary.md
   eog user_events_plot.png event_distribution_plot.png time_series_plot.png
   ```
   **Beispielausgabe** (`visualization_summary.md`):
   ```
   # Big Data Visualisierung Zusammenfassung
   Erstellt am: 2025-09-05 12:57:00

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

   ## Visualisierungen
   ### Top 10 Benutzer nach Ereignisanzahl
   ![Balkendiagramm](user_events_plot.png)

   ### Verteilung der Ereignistypen
   ![Histogramm](event_distribution_plot.png)

   ### Zeitreihenanalyse: Ereignisse pro Minute
   ![Zeitreihendiagramm](time_series_plot.png)
   ```

4. **Schritt 4**: Protokolliere die Erstellung und den E-Mail-Versand:
   ```bash
   echo "Zusammenfassung und E-Mail-Versand versucht am $(date)" >> bigdata_log.txt
   python3 visualization_email_summary.py | tee -a bigdata_log.txt
   cat bigdata_log.txt
   ```

**Reflexion**: Wie verbessert der automatisierte E-Mail-Versand die Berichterstellung? Nutze die Python-Dokumentation (`help(smtplib)`) und überlege, wie du HTML-E-Mails oder mehrere Empfänger hinzufügst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um PySpark, Visualisierung und E-Mail-Versand zu verinnerlichen.
- **Sicheres Testen**: Arbeite in einer Testumgebung und sichere Dateien (`cp optimized_data.parquet optimized_data.parquet.bak`).
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze die PySpark-, Matplotlib-, Seaborn- oder smtplib-Dokumentation für Details.
- **Effiziente Entwicklung**: Nutze `toPandas()` sparsam, `df.cache()` für wiederholte Abfragen, `smtplib` für sicheren Versand und Skripte für Automatisierung.
- **Kombiniere Tools**: Integriere `plotly` für interaktive Diagramme oder `cron` für regelmäßigen E-Mail-Versand.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Hinzufügen von Boxplots, HTML-E-Mails oder Datenbank-Export.

## Fazit
Mit diesen Übungen hast du gelernt, Big Data mit PySpark zu analysieren, Ergebnisse in Pandas zu konvertieren, Balkendiagramme, Histogramme und Zeitreihen mit Matplotlib/Seaborn zu erstellen, die Ergebnisse in ein Markdown-Dokument einzubetten und per E-Mail mit Anhängen zu versenden. Die Spielerei zeigt, wie du Analyse, Visualisierung und E-Mail-Versand kombinierst. Vertiefe dein Wissen, indem du fortgeschrittene Themen (z. B. interaktive Dashboards, Spark Streaming, automatisierte Berichte) oder Tools wie `plotly` oder `airflow` ausprobierst. Wenn du ein spezifisches Thema (z. B. HTML-E-Mails oder Echtzeit-Daten) vertiefen möchtest, lass es mich wissen!
