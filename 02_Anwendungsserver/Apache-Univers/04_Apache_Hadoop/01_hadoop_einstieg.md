# Praxisorientierte Anleitung: Einstieg in Apache Hadoop auf Debian

## Einführung
Apache Hadoop ist ein Open-Source-Framework für die verteilte Speicherung und Verarbeitung riesiger Datenmengen. Es besteht aus dem Hadoop Distributed File System (HDFS) für die Speicherung und MapReduce für die parallele Datenverarbeitung. Diese Anleitung führt Sie in die Installation und Konfiguration von Hadoop in einer Einzelknoten-Konfiguration auf einem Debian-System ein und zeigt Ihnen, wie Sie eine einfache MapReduce-Anwendung ausführen. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, Hadoop für Big-Data-Aufgaben einzusetzen. Diese Anleitung ist ideal für Entwickler und Administratoren, die in die Welt von Big Data eintauchen möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Java Development Kit (JDK) installiert (mindestens Java 8, empfohlen Java 11)
- Mindestens 4 GB RAM und ausreichend Festplattenspeicher (mindestens 10 GB frei)
- Grundlegende Kenntnisse der Linux-Kommandozeile und Java
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie IntelliJ IDEA)

## Grundlegende Hadoop-Konzepte und Befehle
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **Hadoop-Komponenten**:
   - **HDFS**: Verteiltes Dateisystem zur Speicherung großer Datenmengen
   - **MapReduce**: Programmiermodell für die parallele Verarbeitung
   - **YARN**: Ressourcenmanager für die Verwaltung von Rechenressourcen
2. **Wichtige Konfigurationsdateien**:
   - `core-site.xml`: Globale Hadoop-Einstellungen
   - `hdfs-site.xml`: Einstellungen für HDFS
   - `mapred-site.xml`: Einstellungen für MapReduce
   - `yarn-site.xml`: Einstellungen für YARN
3. **Wichtige Befehle**:
   - `hdfs dfs`: Interaktion mit HDFS (z. B. Dateien hochladen/abrufen)
   - `hadoop jar`: Ausführen von MapReduce-Jobs

## Übungen zum Verinnerlichen

### Übung 1: Hadoop installieren und konfigurieren
**Ziel**: Lernen, wie man Hadoop auf einem Debian-System installiert und für eine Einzelknoten-Konfiguration einrichtet.

1. **Schritt 1**: Installiere Java und lade Hadoop herunter.
   ```bash
   sudo apt update
   sudo apt install -y openjdk-11-jdk
   wget https://downloads.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz
   tar -xzf hadoop-3.3.6.tar.gz
   sudo mv hadoop-3.3.6 /usr/local/hadoop
   ```
2. **Schritt 2**: Konfiguriere Umgebungsvariablen für Hadoop.
   ```bash
   nano ~/.bashrc
   ```
   Füge am Ende folgende Zeilen hinzu:
   ```bash
   export HADOOP_HOME=/usr/local/hadoop
   export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
   export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
   ```
   Aktiviere die Änderungen:
   ```bash
   source ~/.bashrc
   ```
3. **Schritt 3**: Konfiguriere Hadoop für die Einzelknoten-Installation.
   - **core-site.xml**:
     ```bash
     nano /usr/local/hadoop/etc/hadoop/core-site.xml
     ```
     Füge innerhalb des `<configuration>`-Tags hinzu:
     ```xml
     <property>
         <name>fs.defaultFS</name>
         <value>hdfs://localhost:9000</value>
     </property>
     ```
   - **hdfs-site.xml**:
     ```bash
     nano /usr/local/hadoop/etc/hadoop/hdfs-site.xml
     ```
     Füge innerhalb des `<configuration>`-Tags hinzu:
     ```xml
     <property>
         <name>dfs.replication</name>
         <value>1</value>
     </property>
     <property>
         <name>dfs.namenode.name.dir</name>
         <value>/usr/local/hadoop/data/namenode</value>
     </property>
     <property>
         <name>dfs.datanode.data.dir</name>
         <value>/usr/local/hadoop/data/datanode</value>
     </property>
     ```
   - Erstelle die Verzeichnisse:
     ```bash
     sudo mkdir -p /usr/local/hadoop/data/namenode /usr/local/hadoop/data/datanode
     sudo chown -R $USER /usr/local/hadoop
     ```
   - Formatiere den Namenode:
     ```bash
     /usr/local/hadoop/bin/hdfs namenode -format
     ```

**Reflexion**: Warum ist die Konfiguration von `fs.defaultFS` in `core-site.xml` wichtig für die Kommunikation mit HDFS?

### Übung 2: HDFS starten und Dateien hochladen
**Ziel**: Verstehen, wie man HDFS startet und Dateien im verteilten Dateisystem verwaltet.

1. **Schritt 1**: Starte die Hadoop-Dienste (NameNode und DataNode).
   ```bash
   /usr/local/hadoop/sbin/start-dfs.sh
   ```
   Überprüfe, ob die Dienste laufen:
   ```bash
   jps
   ```
   Du solltest `NameNode` und `DataNode` in der Ausgabe sehen.
2. **Schritt 2**: Erstelle ein Testverzeichnis und lade eine Datei in HDFS hoch.
   ```bash
   echo "Hallo Hadoop\nDies ist ein Test\nApache Hadoop ist großartig" > test.txt
   /usr/local/hadoop/bin/hdfs dfs -mkdir /input
   /usr/local/hadoop/bin/hdfs dfs -put test.txt /input
   ```
3. **Schritt 3**: Überprüfe die hochgeladene Datei in HDFS.
   ```bash
   /usr/local/hadoop/bin/hdfs dfs -ls /input
   /usr/local/hadoop/bin/hdfs dfs -cat /input/test.txt
   ```

**Reflexion**: Wie unterscheidet sich HDFS von einem lokalen Dateisystem, und warum ist es für Big Data geeignet?

### Übung 3: Eine einfache MapReduce-Anwendung ausführen
**Ziel**: Lernen, wie man ein MapReduce-Programm ausführt, um Daten in HDFS zu verarbeiten.

1. **Schritt 1**: Verwende das mit Hadoop gelieferte Beispielprogramm `wordcount`.
   ```bash
   /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar wordcount /input/test.txt /output
   ```
2. **Schritt 2**: Überprüfe die Ergebnisse in HDFS.
   ```bash
   /usr/local/hadoop/bin/hdfs dfs -cat /output/part-r-00000
   ```
   Die Ausgabe zeigt die Worthäufigkeit der Wörter in `test.txt` (z. B. `Apache 1`, `Hadoop 2`).
3. **Schritt 3**: Stoppe die Hadoop-Dienste.
   ```bash
   /usr/local/hadoop/sbin/stop-dfs.sh
   ```

**Reflexion**: Wie funktioniert das MapReduce-Paradigma, und warum ist es für die Verarbeitung großer Datenmengen effizient?

## Tipps für den Erfolg
- Überprüfe die Hadoop-Logs (`/usr/local/hadoop/logs/`) bei Problemen mit HDFS oder MapReduce.
- Stelle sicher, dass `JAVA_HOME` korrekt gesetzt ist, da Hadoop darauf angewiesen ist.
- Verwende `jps`, um zu überprüfen, ob alle Hadoop-Dienste (NameNode, DataNode) laufen.
- Teste die Konfiguration mit kleinen Datensätzen, bevor du größere Datenmengen verarbeitest.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Apache Hadoop auf einem Debian-System in einer Einzelknoten-Konfiguration installieren, HDFS einrichten und eine einfache MapReduce-Anwendung ausführen. Durch die Übungen haben Sie praktische Erfahrung mit der Verwaltung von HDFS und der Verarbeitung von Daten mit MapReduce gesammelt. Diese Fähigkeiten sind die Grundlage für die Arbeit mit Big Data. Üben Sie weiter, um komplexere Hadoop-Szenarien wie Mehrknoten-Cluster oder Integration mit anderen Tools zu meistern!

**Nächste Schritte**:
- Richten Sie einen Hadoop-Mehrknoten-Cluster ein, um verteilte Verarbeitung zu testen.
- Erkunden Sie Tools wie Apache Hive oder Apache Spark für einfachere Datenanalysen.
- Lesen Sie die offizielle Hadoop-Dokumentation für fortgeschrittene Konfigurationsoptionen.

**Quellen**:
- Offizielle Apache Hadoop-Dokumentation: https://hadoop.apache.org/docs/stable/
- Debian Wiki: https://wiki.debian.org/Hadoop
- DigitalOcean Hadoop-Tutorial: https://www.digitalocean.com/community/tutorials/how-to-install-hadoop-in-stand-alone-mode-on-ubuntu-20-04