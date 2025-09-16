# Praxisorientierte Anleitung: Einstieg in Apache CouchDB auf Debian

## Einführung
Apache CouchDB ist eine Open-Source-NoSQL-Datenbank, die für ihre verteilte Architektur, Skalierbarkeit und die Arbeit mit JSON-Dokumenten über eine HTTP/REST-API bekannt ist. Sie eignet sich besonders für Anwendungen, die flexible Dokumentenspeicherung und Replikation erfordern, wie z. B. mobile Apps oder Webanwendungen. Diese Anleitung führt Sie in die Installation und Konfiguration von Apache CouchDB auf einem Debian-System in einer Einzelknoten-Konfiguration ein und zeigt Ihnen, wie Sie Datenbanken erstellen, Dokumente speichern und abfragen. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, CouchDB für dokumentenbasierte Datenverwaltung einzusetzen. Diese Anleitung ist ideal für Entwickler und Administratoren, die mit NoSQL-Datenbanken beginnen möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Mindestens 4 GB RAM und ausreichend Festplattenspeicher (mindestens 10 GB frei)
- Grundlegende Kenntnisse der Linux-Kommandozeile
- Ein Webbrowser oder ein Tool wie `curl` für HTTP-Anfragen
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie IntelliJ IDEA)

## Grundlegende Apache CouchDB-Konzepte und Befehle
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **CouchDB-Komponenten**:
   - **Datenbank**: Container für JSON-Dokumente
   - **Dokument**: JSON-Objekt mit einem eindeutigen `_id`-Feld
   - **REST-API**: HTTP-basierte Schnittstelle für Datenbankoperationen
   - **Fauxton**: Weboberfläche für die Verwaltung von CouchDB
2. **Wichtige Konfigurationsdateien**:
   - `local.ini`: Haupt-Konfigurationsdatei für CouchDB
3. **Wichtige Befehle und Tools**:
   - `couchdb`: Startet den CouchDB-Dienst
   - `curl`: Führt HTTP-Anfragen an die CouchDB-API aus
   - `systemctl`: Verwaltet den CouchDB-Dienst
   - Fauxton-Weboberfläche: Erreichbar unter `http://localhost:5984/_utils`

## Übungen zum Verinnerlichen

### Übung 1: Apache CouchDB installieren und konfigurieren
**Ziel**: Lernen, wie man CouchDB auf einem Debian-System installiert und für eine Einzelknoten-Konfiguration einrichtet.

1. **Schritt 1**: Füge das CouchDB-Repository hinzu und installiere CouchDB.
   ```bash
   sudo apt update
   sudo apt install -y curl
   echo "deb https://apache.bintray.com/couchdb-deb bullseye main" | sudo tee /etc/apt/sources.list.d/couchdb.list
   curl -L https://couchdb.apache.org/repo/keys.asc | sudo apt-key add -
   sudo apt update
   sudo apt install -y couchdb
   ```
   Während der Installation:
   - Wähle **single-node** (Einzelknoten) statt Cluster.
   - Setze einen Admin-Benutzer (z. B. Benutzername: `admin`, Passwort: `password`).
   - Binde die Adresse an `0.0.0.0` (für externen Zugriff) oder `127.0.0.1` (lokal).
2. **Schritt 2**: Überprüfe, ob CouchDB läuft.
   ```bash
   sudo systemctl status couchdb
   ```
   Wenn der Dienst nicht aktiv ist, starte ihn:
   ```bash
   sudo systemctl start couchdb
   sudo systemctl enable couchdb
   ```
3. **Schritt 3**: Teste die Installation mit `curl`.
   ```bash
   curl http://admin:password@localhost:5984/
   ```
   Die Ausgabe sollte eine JSON-Antwort anzeigen, z. B.:
   ```json
   {"couchdb":"Welcome","version":"3.3.3",...}
   ```
4. **Schritt 4**: Öffne die Fauxton-Weboberfläche im Browser unter `http://localhost:5984/_utils` und melde dich mit `admin` und `password` an.

**Reflexion**: Warum ist die REST-API ein zentraler Bestandteil von CouchDB, und wie unterscheidet sich CouchDB von anderen NoSQL-Datenbanken wie Cassandra?

### Übung 2: Datenbank erstellen, Dokumente speichern und abfragen
**Ziel**: Verstehen, wie man Datenbanken und Dokumente in CouchDB erstellt und mit der HTTP-API abfragt.

1. **Schritt 1**: Erstelle eine Datenbank namens `myapp`.
   ```bash
   curl -X PUT http://admin:password@localhost:5984/myapp
   ```
   Die Ausgabe sollte bestätigen: `{"ok":true}`.
2. **Schritt 2**: Füge ein Dokument zur `myapp`-Datenbank hinzu.
   ```bash
   curl -X POST http://admin:password@localhost:5984/myapp -H "Content-Type: application/json" -d '{"_id": "1", "name": "Alice", "age": 25, "city": "Berlin"}'
   ```
   Die Ausgabe sollte eine erfolgreiche Antwort zeigen, z. B.:
   ```json
   {"ok":true,"id":"1","rev":"1-..."}
   ```
3. **Schritt 3**: Frage das Dokument ab.
   ```bash
   curl http://admin:password@localhost:5984/myapp/1
   ```
   Die Ausgabe zeigt das gespeicherte Dokument:
   ```json
   {"_id":"1","_rev":"1-...","name":"Alice","age":25,"city":"Berlin"}
   ```
4. **Schritt 4**: Liste alle Dokumente in der Datenbank auf.
   ```bash
   curl http://admin:password@localhost:5984/myapp/_all_docs
   ```

**Reflexion**: Wie erleichtert die JSON-basierte Dokumentenspeicherung die Entwicklung, und warum ist das `_rev`-Feld wichtig für die Datenintegrität?

### Übung 3: Eine Python-Anwendung mit CouchDB
**Ziel**: Lernen, wie man eine Python-Anwendung schreibt, die Dokumente in CouchDB speichert und abfragt.

1. **Schritt 1**: Installiere die Python-Bibliothek `couchdb`.
   ```bash
   pip3 install couchdb
   ```
2. **Schritt 2**: Erstelle ein Python-Skript für CRUD-Operationen.
   ```bash
   nano couchdb_python.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import couchdb

   # Verbindung zu CouchDB herstellen
   server = couchdb.Server('http://admin:password@localhost:5984/')

   # Datenbank erstellen oder öffnen
   db_name = 'myapp'
   if db_name not in server:
       db = server.create(db_name)
   else:
       db = server[db_name]

   # Dokument speichern
   doc = {'name': 'Bob', 'age': 30, 'city': 'München'}
   db.save(doc)

   # Alle Dokumente abrufen
   for doc_id in db:
       doc = db[doc_id]
       print(f"ID: {doc_id}, Name: {doc.get('name')}, Age: {doc.get('age')}, City: {doc.get('city')}")

   # Beispiel: Dokument aktualisieren
   doc = db['1']
   doc['age'] = 26
   db.save(doc)
   ```
3. **Schritt 3**: Führe das Skript aus und überprüfe die Ergebnisse.
   ```bash
   python3 couchdb_python.py
   ```
   Die Ausgabe zeigt die gespeicherten Dokumente. Überprüfe in Fauxton (`http://localhost:5984/_utils`) oder mit `curl`:
   ```bash
   curl http://admin:password@localhost:5984/myapp/_all_docs
   ```

**Reflexion**: Wie vereinfacht die `couchdb`-Bibliothek die Interaktion mit CouchDB, und welche Vorteile bietet die Python-Programmierung gegenüber direkten HTTP-Anfragen?

## Tipps für den Erfolg
- Überprüfe die CouchDB-Logs in `/var/log/couchdb/` bei Problemen mit dem Dienst.
- Stelle sicher, dass der Admin-Benutzer und das Passwort sicher sind, insbesondere bei externem Zugriff.
- Verwende Fauxton für eine visuelle Verwaltung von Datenbanken und Dokumenten.
- Teste mit kleinen Datenmengen, bevor du größere Datensätze verarbeitest.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Apache CouchDB auf einem Debian-System installieren, eine Datenbank und Dokumente erstellen, mit der HTTP-API arbeiten und eine Python-Anwendung für CouchDB entwickeln. Durch die Übungen haben Sie praktische Erfahrung mit CouchDB’s REST-API und JSON-Dokumenten gesammelt. Diese Fähigkeiten sind die Grundlage für dokumentenbasierte NoSQL-Anwendungen. Üben Sie weiter, um komplexere Szenarien wie Replikation oder Mehrknoten-Setups zu meistern!

**Nächste Schritte**:
- Richten Sie einen CouchDB-Mehrknoten-Cluster ein, um Replikation und Skalierbarkeit zu testen.
- Integrieren Sie CouchDB mit Apache Spark für Big-Data-Analysen.
- Erkunden Sie CouchDB-Features wie MapReduce-Views oder Replikation.

**Quellen**:
- Offizielle Apache CouchDB-Dokumentation: https://docs.couchdb.org/en/stable/
- CouchDB Python Library: https://python-couchdb.readthedocs.io/en/latest/
- DigitalOcean CouchDB-Tutorial: https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-couchdb-on-ubuntu-20-04