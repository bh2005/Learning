# Praxisorientierte Anleitung: Einstieg in Apache Kafka auf Debian

## Einführung
Apache Kafka ist eine Open-Source-Plattform für die verteilte Verarbeitung und Speicherung von Datenströmen in Echtzeit. Sie wird für die Verarbeitung großer Datenmengen in skalierbaren, fehlertoleranten Systemen verwendet, z. B. für Event-Streaming und Datenintegration. Diese Anleitung führt Sie in die Installation und Konfiguration von Apache Kafka in einer Einzelknoten-Konfiguration auf einem Debian-System ein und zeigt Ihnen, wie Sie ein Topic erstellen, Nachrichten produzieren und konsumieren. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, Kafka für Echtzeit-Datenverarbeitung einzusetzen. Diese Anleitung ist ideal für Entwickler und Administratoren, die mit Event-Streaming beginnen möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Java Development Kit (JDK) installiert (mindestens Java 8, empfohlen Java 11)
- Mindestens 4 GB RAM und ausreichend Festplattenspeicher (mindestens 10 GB frei)
- Grundlegende Kenntnisse der Linux-Kommandozeile
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie IntelliJ IDEA)

## Grundlegende Apache Kafka-Konzepte und Befehle
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **Kafka-Komponenten**:
   - **Zookeeper**: Verwaltet die Koordination und Konfiguration des Kafka-Clusters
   - **Broker**: Kafka-Server, der Nachrichten speichert und verteilt
   - **Topics**: Kategorien, in die Nachrichten geschrieben werden
   - **Produzenten und Konsumenten**: Senden (Produzenten) und empfangen (Konsumenten) Nachrichten
2. **Wichtige Konfigurationsdateien**:
   - `server.properties`: Konfiguration des Kafka-Brokers
   - `zookeeper.properties`: Konfiguration von Zookeeper
3. **Wichtige Befehle**:
   - `zookeeper-server-start.sh`: Startet Zookeeper
   - `kafka-server-start.sh`: Startet den Kafka-Broker
   - `kafka-topics.sh`: Verwaltet Topics
   - `kafka-console-producer.sh` und `kafka-console-consumer.sh`: Produzieren und konsumieren Nachrichten

## Übungen zum Verinnerlichen

### Übung 1: Apache Kafka und Zookeeper installieren und konfigurieren
**Ziel**: Lernen, wie man Kafka und Zookeeper auf einem Debian-System installiert und für eine Einzelknoten-Konfiguration einrichtet.

1. **Schritt 1**: Installiere Java (falls nicht bereits vorhanden).
   ```bash
   sudo apt update
   sudo apt install -y openjdk-11-jdk
   java -version
   ```
2. **Schritt 2**: Lade und installiere Apache Kafka.
   ```bash
   wget https://downloads.apache.org/kafka/3.8.0/kafka_2.13-3.8.0.tgz
   tar -xzf kafka_2.13-3.8.0.tgz
   sudo mv kafka_2.13-3.8.0 /usr/local/kafka
   ```
3. **Schritt 3**: Konfiguriere Umgebungsvariablen für Kafka.
   ```bash
   nano ~/.bashrc
   ```
   Füge am Ende folgende Zeilen hinzu:
   ```bash
   export KAFKA_HOME=/usr/local/kafka
   export PATH=$PATH:$KAFKA_HOME/bin
   export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
   ```
   Aktiviere die Änderungen:
   ```bash
   source ~/.bashrc
   ```
4. **Schritt 4**: Konfiguriere Zookeeper und Kafka-Broker.
   - **Zookeeper**:
     ```bash
     nano /usr/local/kafka/config/zookeeper.properties
     ```
     Stelle sicher, dass die folgende Zeile vorhanden ist (Standardwert):
     ```properties
     dataDir=/tmp/zookeeper
     ```
   - **Kafka-Broker**:
     ```bash
     nano /usr/local/kafka/config/server.properties
     ```
     Stelle sicher, dass die folgenden Einstellungen vorhanden sind:
     ```properties
     broker.id=0
     listeners=PLAINTEXT://localhost:9092
     log.dirs=/tmp/kafka-logs
     zookeeper.connect=localhost:2181
     ```
5. **Schritt 5**: Starte Zookeeper und Kafka.
   ```bash
   zookeeper-server-start.sh -daemon /usr/local/kafka/config/zookeeper.properties
   kafka-server-start.sh -daemon /usr/local/kafka/config/server.properties
   ```
   Überprüfe, ob die Dienste laufen:
   ```bash
   jps
   ```
   Du solltest `ZooKeeperServer` und `Kafka` in der Ausgabe sehen.

**Reflexion**: Warum ist Zookeeper für den Betrieb von Kafka notwendig, und welche Rolle spielt der Broker in der Nachrichtenverarbeitung?

### Übung 2: Ein Topic erstellen und Nachrichten produzieren/konsumieren
**Ziel**: Verstehen, wie man ein Kafka-Topic erstellt und Nachrichten mit Konsolen-Tools sendet und empfängt.

1. **Schritt 1**: Erstelle ein Topic namens `test-topic`.
   ```bash
   kafka-topics.sh --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1 --topic test-topic
   ```
   Überprüfe die Topic-Erstellung:
   ```bash
   kafka-topics.sh --list --bootstrap-server localhost:9092
   ```
2. **Schritt 2**: Produziere Nachrichten in das Topic.
   ```bash
   kafka-console-producer.sh --broker-list localhost:9092 --topic test-topic
   ```
   Gib im Terminal ein paar Nachrichten ein (z. B. `Hallo Kafka`, `Testnachricht`), und beende mit `Ctrl+C`.
3. **Schritt 3**: Konsumiere Nachrichten aus dem Topic.
   ```bash
   kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic test-topic --from-beginning
   ```
   Die Ausgabe zeigt die gesendeten Nachrichten. Beende mit `Ctrl+C`.

**Reflexion**: Wie unterstützt Kafka die Trennung von Produzenten und Konsumenten, und warum ist die Option `--from-beginning` nützlich?

### Übung 3: Eine einfache Python-Anwendung mit Kafka
**Ziel**: Lernen, wie man eine Python-Anwendung schreibt, die Nachrichten in ein Kafka-Topic produziert und konsumiert.

1. **Schritt 1**: Installiere die Python-Bibliothek `confluent-kafka`.
   ```bash
   pip3 install confluent-kafka
   ```
2. **Schritt 2**: Erstelle ein Python-Skript für Produzenten und Konsumenten.
   ```bash
   nano kafka_python.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from confluent_kafka import Producer, Consumer, KafkaError

   # Produzent
   def produce_messages(topic):
       p = Producer({'bootstrap.servers': 'localhost:9092'})
       messages = ["Hallo Kafka", "Python mit Kafka", "Testnachricht"]
       for msg in messages:
           p.produce(topic, msg.encode('utf-8'))
       p.flush()
       print("Nachrichten gesendet")

   # Konsument
   def consume_messages(topic):
       c = Consumer({
           'bootstrap.servers': 'localhost:9092',
           'group.id': 'my-group',
           'auto.offset.reset': 'earliest'
       })
       c.subscribe([topic])
       try:
           while True:
               msg = c.poll(1.0)
               if msg is None:
                   continue
               if msg.error():
                   if msg.error().code() == KafkaError._PARTITION_EOF:
                       continue
                   else:
                       print(msg.error())
                       break
               print(f"Empfangene Nachricht: {msg.value().decode('utf-8')}")
       except KeyboardInterrupt:
           c.close()

   if __name__ == '__main__':
       topic = "test-topic"
       produce_messages(topic)
       consume_messages(topic)
   ```
3. **Schritt 3**: Führe das Skript aus und überprüfe die Ergebnisse.
   ```bash
   python3 kafka_python.py
   ```
   Die Ausgabe zeigt die gesendeten und empfangenen Nachrichten. Beende mit `Ctrl+C`.

**Reflexion**: Wie vereinfacht die `confluent-kafka`-Bibliothek die Arbeit mit Kafka, und welche Vorteile bietet die Programmierung gegenüber Konsolen-Tools?

## Tipps für den Erfolg
- Überprüfe die Kafka-Logs in `/usr/local/kafka/logs/` bei Problemen mit Zookeeper oder dem Broker.
- Stelle sicher, dass `JAVA_HOME` korrekt gesetzt ist (`export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64`).
- Verwende `jps`, um zu überprüfen, ob Zookeeper und Kafka laufen.
- Teste mit kleinen Nachrichtenmengen, bevor du größere Datenströme verarbeitest.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Apache Kafka auf einem Debian-System installieren, ein Topic erstellen, Nachrichten mit Konsolen-Tools produzieren und konsumieren und eine Python-Anwendung für Kafka entwickeln. Durch die Übungen haben Sie praktische Erfahrung mit Kafka-Brokern, Zookeeper und der Programmierung von Produzenten/Konsumenten gesammelt. Diese Fähigkeiten sind die Grundlage für Echtzeit-Datenverarbeitung in skalierbaren Systemen. Üben Sie weiter, um komplexere Kafka-Szenarien wie Mehrknoten-Cluster zu meistern!

**Nächste Schritte**:
- Richten Sie einen Kafka-Mehrknoten-Cluster ein, um verteilte Verarbeitung zu testen.
- Integrieren Sie Kafka mit Apache Spark für Streaming-Datenanalysen.
- Erkunden Sie Kafka Connect für die Integration mit Datenbanken oder anderen Systemen.

**Quellen**:
- Offizielle Apache Kafka-Dokumentation: https://kafka.apache.org/documentation/
- Confluent Kafka Python-Dokumentation: https://docs.confluent.io/platform/current/clients/consumer.html
- DigitalOcean Kafka-Tutorial: https://www.digitalocean.com/community/tutorials/how-to-install-apache-kafka-on-ubuntu-20-04