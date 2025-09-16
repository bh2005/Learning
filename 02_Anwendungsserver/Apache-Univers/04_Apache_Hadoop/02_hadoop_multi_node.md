# Praxisorientierte Anleitung: Einrichtung eines Hadoop-Mehrknoten-Clusters auf Debian

## Einführung
Ein Hadoop-Mehrknoten-Cluster ermöglicht die verteilte Speicherung und Verarbeitung großer Datenmengen über mehrere Knoten, was die Skalierbarkeit und Ausfallsicherheit verbessert. Diese Anleitung führt Sie in die Einrichtung eines Mehrknoten-Clusters (1 Master + 2 Slaves) auf Debian-Systemen ein, einschließlich der Konfiguration von SSH, Java, Hadoop und dem Testen der verteilten Verarbeitung mit MapReduce. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, einen funktionsfähigen Cluster aufzubauen und zu testen. Diese Anleitung ist ideal für Administratoren und Entwickler, die verteilte Big-Data-Verarbeitung testen möchten.

Voraussetzungen:
- Drei Debian-Systeme (z. B. Debian 12): 1 Master (z. B. IP: 192.168.0.1, Hostname: master) und 2 Slaves (z. B. IPs: 192.168.0.2/slave1, 192.168.0.3/slave2)
- Root- oder Sudo-Zugriff auf allen Knoten
- Java Development Kit (JDK) installiert (mindestens Java 8, empfohlen Java 11)
- SSH installiert und konfiguriert für passwordless-Zugriff
- Mindestens 4 GB RAM pro Knoten und ausreichend Festplattenspeicher (mindestens 10 GB frei pro Knoten)
- Grundlegende Kenntnisse der Linux-Kommandozeile und Hadoop (z. B. aus der Einzelknoten-Anleitung)
- Ein Texteditor (z. B. `nano` oder `vim`)

## Grundlegende Konzepte und Befehle
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **Cluster-Komponenten**:
   - **Master (NameNode)**: Verwaltet HDFS-Metadaten und koordiniert Jobs
   - **Slaves (DataNodes)**: Speichern Datenblöcke und führen Tasks aus
2. **Konfigurationsdateien**:
   - `core-site.xml`: Definiert den Default-File-System (HDFS-URL)
   - `hdfs-site.xml`: Einstellungen für HDFS-Replikation und Verzeichnisse
   - `yarn-site.xml`: Einstellungen für YARN (Ressourcenmanagement)
   - `mapred-site.xml`: Einstellungen für MapReduce
   - `slaves`: Liste der Slave-Knoten auf dem Master
3. **Wichtige Befehle**:
   - `hdfs namenode -format`: Formatiert den NameNode
   - `start-dfs.sh`: Startet HDFS-Dienste
   - `start-yarn.sh`: Startet YARN-Dienste
   - `hadoop jar`: Führt MapReduce-Jobs aus
   - `jps`: Überprüft laufende Java-Prozesse (z. B. NameNode, DataNode)

## Übungen zum Verinnerlichen

### Übung 1: Vorbereitung der Knoten (SSH, Java und Hosts-Konfiguration)
**Ziel**: Lernen, wie man die Knoten für passwordless-Kommunikation vorbereitet und grundlegende Software installiert.

1. **Schritt 1**: Installiere Java und SSH auf allen Knoten.
   ```bash
   sudo apt update
   sudo apt install -y openjdk-11-jdk openssh-server
   ```
2. **Schritt 2**: Erstelle einen dedizierten Hadoop-Benutzer auf allen Knoten.
   ```bash
   sudo adduser hadoop
   sudo usermod -aG sudo hadoop
   su - hadoop
   ```
3. **Schritt 3**: Konfiguriere passwordless-SSH vom Master zu allen Knoten (einschließlich sich selbst).
   - Auf dem Master (als hadoop):
     ```bash
     ssh-keygen -t rsa -P ""
     cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
     chmod 0600 ~/.ssh/authorized_keys
     ```
   - Kopiere den öffentlichen Schlüssel zu den Slaves:
     ```bash
     ssh-copy-id hadoop@slave1
     ssh-copy-id hadoop@slave2
     ```
   - Teste den Zugriff:
     ```bash
     ssh slave1
     ssh slave2
     ```
4. **Schritt 4**: Konfiguriere `/etc/hosts` auf allen Knoten für Hostname-Auflösung.
   ```bash
   sudo nano /etc/hosts
   ```
   Füge hinzu:
   ```
   192.168.0.1 master
   192.168.0.2 slave1
   192.168.0.3 slave2
   ```

**Reflexion**: Warum ist passwordless-SSH essenziell für einen Hadoop-Cluster, und wie verhindert es Sicherheitsrisiken?

### Übung 2: Hadoop installieren und konfigurieren
**Ziel**: Verstehen, wie man Hadoop auf allen Knoten installiert und die Konfigurationsdateien anpasst.

1. **Schritt 1**: Lade und installiere Hadoop auf allen Knoten (als hadoop).
   ```bash
   wget https://downloads.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz
   tar -xzf hadoop-3.3.6.tar.gz
   mv hadoop-3.3.6 ~/hadoop
   ```
2. **Schritt 2**: Konfiguriere Umgebungsvariablen auf allen Knoten (in `~/.bashrc`).
   ```bash
   nano ~/.bashrc
   ```
   Füge hinzu:
   ```
   export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
   export HADOOP_HOME=~/hadoop
   export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
   ```
   Aktiviere:
   ```bash
   source ~/.bashrc
   ```
3. **Schritt 3**: Konfiguriere Hadoop-Dateien auf dem Master und kopiere sie zu den Slaves.
   - `hadoop-env.sh` (auf allen):
     ```bash
     nano $HADOOP_HOME/etc/hadoop/hadoop-env.sh
     ```
     Füge hinzu:
     ```
     export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
     ```
   - `core-site.xml` (auf allen):
     ```bash
     nano $HADOOP_HOME/etc/hadoop/core-site.xml
     ```
     Füge in `<configuration>` hinzu:
     ```xml
     <property>
         <name>fs.defaultFS</name>
         <value>hdfs://master:9000</value>
     </property>
     ```
   - `hdfs-site.xml` (auf allen):
     ```bash
     nano $HADOOP_HOME/etc/hadoop/hdfs-site.xml
     ```
     Füge in `<configuration>` hinzu:
     ```xml
     <property>
         <name>dfs.replication</name>
         <value>2</value>
     </property>
     <property>
         <name>dfs.namenode.name.dir</name>
         <value>file:///home/hadoop/hadoopdata/namenode</value>
     </property>
     <property>
         <name>dfs.datanode.data.dir</name>
         <value>file:///home/hadoop/hadoopdata/datanode</value>
     </property>
     ```
   - `yarn-site.xml` (auf allen):
     ```bash
     nano $HADOOP_HOME/etc/hadoop/yarn-site.xml
     ```
     Füge in `<configuration>` hinzu:
     ```xml
     <property>
         <name>yarn.nodemanager.aux-services</name>
         <value>mapreduce_shuffle</value>
     </property>
     <property>
         <name>yarn.resourcemanager.hostname</name>
         <value>master</value>
     </property>
     ```
   - `mapred-site.xml` (auf allen):
     ```bash
     cp $HADOOP_HOME/etc/hadoop/mapred-site.xml.template $HADOOP_HOME/etc/hadoop/mapred-site.xml
     nano $HADOOP_HOME/etc/hadoop/mapred-site.xml
     ```
     Füge in `<configuration>` hinzu:
     ```xml
     <property>
         <name>mapreduce.framework.name</name>
         <value>yarn</value>
     </property>
     ```
   - `slaves` (nur auf Master):
     ```bash
     nano $HADOOP_HOME/etc/hadoop/slaves
     ```
     Füge hinzu:
     ```
     slave1
     slave2
     ```
   - Kopiere die Konfigurationen zu den Slaves (vom Master):
     ```bash
     scp -r ~/hadoop/etc/hadoop/* hadoop@slave1:~/hadoop/etc/hadoop/
     scp -r ~/hadoop/etc/hadoop/* hadoop@slave2:~/hadoop/etc/hadoop/
     ```

**Reflexion**: Wie beeinflusst die Replikationsfaktor-Einstellung in `hdfs-site.xml` die Datensicherheit und Verfügbarkeit im Cluster?

### Übung 3: Cluster starten und verteilte Verarbeitung testen
**Ziel**: Lernen, wie man den Cluster startet, HDFS verwaltet und einen MapReduce-Job ausführt.

1. **Schritt 1**: Formatiere den NameNode auf dem Master.
   ```bash
   hdfs namenode -format
   ```
2. **Schritt 2**: Starte die Dienste auf dem Master.
   ```bash
   start-dfs.sh
   start-yarn.sh
   ```
   Überprüfe mit `jps` auf Master: NameNode, SecondaryNameNode, ResourceManager.
   Auf Slaves: DataNode, NodeManager.
3. **Schritt 3**: Teste HDFS und MapReduce.
   - Erstelle ein Verzeichnis in HDFS:
     ```bash
     hdfs dfs -mkdir /input
     hdfs dfs -put test.txt /input
     ```
   - Führe WordCount aus:
     ```bash
     hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar wordcount /input /output
     ```
   - Überprüfe Ergebnis:
     ```bash
     hdfs dfs -cat /output/part-r-00000
     ```
   - Stoppe den Cluster:
     ```bash
     stop-yarn.sh
     stop-dfs.sh
     ```

**Reflexion**: Wie zeigt der WordCount-Job die verteilte Verarbeitung, und welche Vorteile bietet ein Mehrknoten-Cluster im Vergleich zu einem Einzelknoten?

## Tipps für den Erfolg
- Deaktiviere Firewalls vorübergehend mit `sudo ufw disable` (oder `sudo systemctl stop firewalld`), um Verbindungsprobleme zu vermeiden; aktiviere sie später mit Regeln für Hadoop-Ports (z. B. 9000, 9870).
- Überprüfe Logs in `$HADOOP_HOME/logs/` bei Fehlern.
- Verwende `hdfs dfsadmin -report`, um den Cluster-Status zu prüfen.
- Für Produktion: Verwende dedizierte Knoten und passe Replikationsfaktor an (z. B. 3).

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie einen Hadoop-Mehrknoten-Cluster auf Debian einrichten, konfigurieren und mit MapReduce testen. Durch die Übungen haben Sie praktische Erfahrung mit SSH-Setup, Konfigurationsdateien und verteilter Verarbeitung gesammelt. Diese Fähigkeiten sind essenziell für skalierbare Big-Data-Anwendungen. Üben Sie weiter, um komplexere Cluster oder Integrationen zu meistern!

**Nächste Schritte**:
- Integrieren Sie Apache Hive für SQL-ähnliche Abfragen auf Hadoop.
- Erkunden Sie Apache Spark für schnellere Datenverarbeitung auf Hadoop.
- Lesen Sie die offizielle Hadoop-Dokumentation für Hochverfügbarkeits-Setups.

**Quellen**:
- Offizielle Apache Hadoop-Dokumentation: https://hadoop.apache.org/docs/stable/
- Running Hadoop on Ubuntu (Multi-Node): https://www.michael-noll.com/tutorials/running-hadoop-on-ubuntu-linux-multi-node-cluster/
- How to Install Hadoop on Debian 11: https://www.rosehosting.com/blog/how-to-install-hadoop-on-debian-11/
- Setting Up a Multi-Node Cluster: https://www.edureka.co/blog/setting-up-a-multi-node-cluster-in-hadoop-2-x/
- How to Install and Set Up a 3-Node Hadoop Cluster: https://utho.com/docs/database/hadoop/setting-up-a-hadoop-cluster/