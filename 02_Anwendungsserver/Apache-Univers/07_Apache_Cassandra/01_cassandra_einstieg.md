# Praxisorientierte Anleitung: Einstieg in Apache Cassandra auf Debian

## Einführung
Apache Cassandra ist eine verteilte NoSQL-Datenbank, die für hohe Verfügbarkeit, Skalierbarkeit und Leistung bei der Verarbeitung großer Datenmengen entwickelt wurde. Sie eignet sich besonders für Anwendungen, die hohe Schreib- und Lesezugriffe erfordern, wie z. B. Zeitreihen oder Echtzeit-Analysen. Diese Anleitung führt Sie in die Installation und Konfiguration von Apache Cassandra in einer Einzelknoten-Konfiguration auf einem Debian-System ein und zeigt Ihnen, wie Sie Keyspaces, Tabellen und Daten mit der Cassandra Query Language (CQL) verwalten. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, Cassandra für skalierbare Datenbankanwendungen einzusetzen. Diese Anleitung ist ideal für Entwickler und Administratoren, die mit NoSQL-Datenbanken beginnen möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Java Development Kit (JDK) installiert (mindestens Java 8, empfohlen Java 11)
- Mindestens 4 GB RAM und ausreichend Festplattenspeicher (mindestens 10 GB frei)
- Grundlegende Kenntnisse der Linux-Kommandozeile
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie IntelliJ IDEA)

## Grundlegende Apache Cassandra-Konzepte und Befehle
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **Cassandra-Komponenten**:
   - **Keyspace**: Äquivalent zu einer Datenbank, gruppiert Tabellen
   - **Tabelle**: Speichert Daten in Zeilen und Spalten (ähnlich wie in relationalen Datenbanken, aber flexibler)
   - **CQL (Cassandra Query Language)**: SQL-ähnliche Sprache für Datenbankoperationen
   - **Node**: Ein einzelner Cassandra-Server
2. **Wichtige Konfigurationsdateien**:
   - `cassandra.yaml`: Haupt-Konfigurationsdatei für Cassandra
   - `cassandra-env.sh`: Umgebungsvariablen für Cassandra
3. **Wichtige Befehle**:
   - `cassandra`: Startet den Cassandra-Dienst
   - `nodetool`: Verwaltet und überwacht den Cassandra-Knoten
   - `cqlsh`: Interaktive Shell für CQL-Abfragen

## Übungen zum Verinnerlichen

### Übung 1: Apache Cassandra installieren und konfigurieren
**Ziel**: Lernen, wie man Cassandra auf einem Debian-System installiert und für eine Einzelknoten-Konfiguration einrichtet.

1. **Schritt 1**: Installiere Java (falls nicht bereits vorhanden).
   ```bash
   sudo apt update
   sudo apt install -y openjdk-11-jdk
   java -version
   ```
2. **Schritt 2**: Füge das Cassandra-Repository hinzu und installiere Cassandra.
   ```bash
   sudo nano /etc/apt/sources.list.d/cassandra.sources.list
   ```
   Füge folgende Zeile hinzu:
   ```
   deb https://debian.cassandra.apache.org 40x main
   ```
   Füge den GPG-Schlüssel hinzu:
   ```bash
   curl https://downloads.apache.org/cassandra/KEYS | sudo apt-key add -
   ```
   Installiere Cassandra:
   ```bash
   sudo apt update
   sudo apt install -y cassandra
   ```
3. **Schritt 3**: Überprüfe, ob Cassandra läuft.
   ```bash
   sudo systemctl status cassandra
   ```
   Wenn der Dienst nicht aktiv ist, starte ihn:
   ```bash
   sudo systemctl start cassandra
   sudo systemctl enable cassandra
   ```
4. **Schritt 4**: Teste die Verbindung mit der CQL-Shell.
   ```bash
   cqlsh
   ```
   In der `cqlsh`-Shell führe eine einfache Abfrage aus:
   ```sql
   SELECT cluster_name, release_version FROM system.local;
   ```
   Beende die Shell mit `exit`.

**Reflexion**: Warum ist Cassandra für hohe Skalierbarkeit und Verfügbarkeit ausgelegt, und wie unterscheidet es sich von relationalen Datenbanken?

### Übung 2: Keyspace und Tabelle erstellen, Daten einfügen und abfragen
**Ziel**: Verstehen, wie man Keyspaces und Tabellen erstellt und grundlegende CQL-Operationen durchführt.

1. **Schritt 1**: Starte die CQL-Shell und erstelle einen Keyspace.
   ```bash
   cqlsh
   ```
   Führe in der Shell folgendes aus:
   ```sql
   CREATE KEYSPACE myapp
   WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
   ```
2. **Schritt 2**: Erstelle eine Tabelle für eine To-Do-Liste und füge Daten ein.
   ```sql
   USE myapp;
   CREATE TABLE todos (
       id UUID PRIMARY KEY,
       task text,
       completed boolean,
       created_at timestamp
   );
   INSERT INTO todos (id, task, completed, created_at)
   VALUES (uuid(), 'Lerne Cassandra', false, toTimestamp(now()));
   INSERT INTO todos (id, task, completed, created_at)
   VALUES (uuid(), 'Schreibe Dokumentation', true, toTimestamp(now()));
   ```
3. **Schritt 3**: Frage die Daten ab und überprüfe die Ergebnisse.
   ```sql
   SELECT * FROM todos;
   SELECT task, completed FROM todos WHERE completed = true ALLOW FILTERING;
   ```
   Beende die Shell mit `exit`.

**Reflexion**: Wie unterstützt die `SimpleStrategy` die Datenreplikation, und warum ist `ALLOW FILTERING` in manchen Abfragen problematisch?

### Übung 3: Eine Python-Anwendung mit Cassandra
**Ziel**: Lernen, wie man eine Python-Anwendung schreibt, die Daten in Cassandra speichert und abfragt.

1. **Schritt 1**: Installiere die Python-Bibliothek `cassandra-driver`.
   ```bash
   pip3 install cassandra-driver
   ```
2. **Schritt 2**: Erstelle ein Python-Skript für CRUD-Operationen.
   ```bash
   nano cassandra_todo.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from cassandra.cluster import Cluster
   from cassandra.query import SimpleStatement
   from uuid import uuid4
   from datetime import datetime

   # Verbindung zu Cassandra herstellen
   cluster = Cluster(['localhost'])
   session = cluster.connect('myapp')

   # Daten einfügen
   insert_query = """
   INSERT INTO todos (id, task, completed, created_at)
   VALUES (%s, %s, %s, %s)
   """
   session.execute(insert_query, (uuid4(), 'Python mit Cassandra', False, datetime.now()))

   # Daten abfragen
   select_query = "SELECT id, task, completed, created_at FROM todos"
   rows = session.execute(select_query)
   for row in rows:
       print(f"ID: {row.id}, Task: {row.task}, Completed: {row.completed}, Created: {row.created_at}")

   # Verbindung schließen
   cluster.shutdown()
   ```
3. **Schritt 3**: Führe das Skript aus und überprüfe die Ergebnisse.
   ```bash
   python3 cassandra_todo.py
   ```
   Die Ausgabe zeigt die gespeicherten To-Do-Einträge. Überprüfe in `cqlsh`:
   ```bash
   cqlsh
   USE myapp;
   SELECT * FROM todos;
   ```

**Reflexion**: Wie vereinfacht die `cassandra-driver`-Bibliothek die Interaktion mit Cassandra, und welche Vorteile bietet die Programmierung gegenüber der CQL-Shell?

## Tipps für den Erfolg
- Überprüfe die Cassandra-Logs in `/var/log/cassandra/` bei Problemen mit dem Dienst.
- Stelle sicher, dass `JAVA_HOME` korrekt gesetzt ist (`export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64`).
- Verwende `nodetool status`, um den Zustand des Cassandra-Knotens zu überprüfen.
- Teste mit kleinen Datenmengen, bevor du größere Datensätze verarbeitest.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Apache Cassandra auf einem Debian-System installieren, einen Keyspace und eine Tabelle erstellen, Daten mit CQL verwalten und eine Python-Anwendung für Cassandra entwickeln. Durch die Übungen haben Sie praktische Erfahrung mit Cassandra-Konfigurationen, CQL und der Programmierung gesammelt. Diese Fähigkeiten sind die Grundlage für skalierbare NoSQL-Datenbankanwendungen. Üben Sie weiter, um komplexere Szenarien wie Mehrknoten-Cluster zu meistern!

**Nächste Schritte**:
- Richten Sie einen Cassandra-Mehrknoten-Cluster ein, um verteilte Datenverarbeitung zu testen.
- Integrieren Sie Cassandra mit Apache Spark für Big-Data-Analysen.
- Erkunden Sie Cassandra-Features wie Zeitreihen-Daten oder Tombstone-Management.

**Quellen**:
- Offizielle Apache Cassandra-Dokumentation: https://cassandra.apache.org/doc/latest/
- DataStax Python Driver-Dokumentation: https://docs.datastax.com/en/developer/python-driver/
- DigitalOcean Cassandra-Tutorial: https://www.digitalocean.com/community/tutorials/how-to-install-cassandra-and-run-a-single-node-cluster-on-ubuntu-20-04