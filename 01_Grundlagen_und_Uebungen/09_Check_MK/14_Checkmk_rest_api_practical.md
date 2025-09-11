# Praxisorientierte Anleitung: Automatisierung mit der Checkmk REST-API

## Einführung

Die Checkmk REST-API ermöglicht die Automatisierung von Monitoring-Aufgaben wie Host-Management, Service-Abfragen und Konfigurationsänderungen. Diese Anleitung führt in die praktische Nutzung der REST-API ein, basierend auf der offiziellen Dokumentation (https://docs.checkmk.com/latest/de/rest_api.html). Ziel ist es, wiederkehrende Aufgaben zu automatisieren und Daten mit externen Systemen wie einem CMDB zu integrieren. Wir verwenden Python-Skripte, um **Hosts zu erstellen**, **Services mit Problemzuständen abzufragen** und **Host-Daten aus einer CSV-Datei zu importieren**. Die Übungen sind für Nutzer mit Grundkenntnissen in Python und APIs geeignet und verwenden die **Checkmk Raw Edition** (Version 2.3).

**Voraussetzungen**:
- Ein Linux-System mit Checkmk Raw Edition installiert (z. B. Ubuntu 22.04 oder Debian 11).
- Eine Checkmk-Site (z. B. `mysite`) mit einem API-Benutzer (`api_user`) und Secret.
- Python 3 mit den Bibliotheken `requests` und `csv` (installiere mit `pip install requests`).
- Ein Terminal mit `omd su mysite`-Zugriff.
- Optional: `jq` für die formatierte Ausgabe von JSON-Daten (`sudo apt install jq`).

**Hinweis**: Der API-Benutzer muss Berechtigungen für das Erstellen, Abfragen und Löschen von Hosts sowie für das Aktivieren von Änderungen haben.

## Grundlegende Konzepte

1. **REST-API-Endpunkte**:
   - Die API ist unter `/check_mk/api/1.0/` erreichbar und bietet Endpunkte wie `/domain-types/host_config/collections/all` für Host-Management.
   - Die Dokumentation ist selbst eine API-Ressource unter `/check_mk/api/1.0/doc/`.
2. **Idempotenz**:
   - `GET` und `PUT` sind idempotent (wiederholte Aufrufe ändern nichts), während `POST` und `DELETE` dies oft nicht sind.
   - Wichtig für die Vermeidung von Duplikaten bei der Automatisierung.
3. **Python `requests` vs. `curl`**:
   - `curl` eignet sich für schnelle Tests, während `requests` durch JSON-Verarbeitung und Fehlerbehandlung ideal für Skripte ist.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: API-Dokumentation erkunden

**Ziel**: Einen Überblick über die verfügbaren API-Endpunkte gewinnen.

1. **Schritt 1**: Erkunde die API-Dokumentation mit `curl`:
   ```bash
   curl -X GET -u "api_user:mysecret123" "http://localhost/mysite/check_mk/api/1.0/doc/" | jq
   ```
   Die Ausgabe listet alle Endpunkte, z. B. `/domain-types/host_config`.

2. **Schritt 2**: Untersuche die Details der `host_config`-Ressource:
   ```bash
   curl -X GET -u "api_user:mysecret123" "http://localhost/mysite/check_mk/api/1.0/doc/domain-types/host_config" | jq
   ```
   Dies zeigt Operationen (`GET`, `POST`, `PUT`, `DELETE`) und Parameter.

**Reflexion**: Welche Parameter sind für die Host-Erstellung essenziell? Warum ist die API-Dokumentation vor der Skripterstellung wichtig?

### Übung 2: Automatisierte Host-Erstellung

**Ziel**: Ein Python-Skript erstellen, das mehrere Hosts automatisch anlegt.

1. **Schritt 1**: Erstelle eine Datei `create_hosts.py`:
   ```bash
   sudo omd su mysite
   nano create_hosts.py
   ```

2. **Schritt 2**: Füge folgenden Code ein:
   ```python
   import requests
   import json

   SERVER = "http://localhost/mysite"
   USER = "api_user"
   SECRET = "mysecret123"
   HEADERS = {"Accept": "application/json", "Content-Type": "application/json"}

   new_hosts = [
       {"host_name": "server-01", "ip_address": "192.168.1.101"},
       {"host_name": "server-02", "ip_address": "192.168.1.102"},
       {"host_name": "server-03", "ip_address": "192.168.1.103"}
   ]

   def create_host(host):
       """Erstellt einen Host über die REST-API."""
       url = f"{SERVER}/check_mk/api/1.0/domain-types/host_config/collections/all"
       payload = {
           "host_name": host["host_name"],
           "folder": "/",
           "attributes": {"ipaddress": host["ip_address"]}
       }
       print(f"Erstelle Host: {host['host_name']}...")
       try:
           response = requests.post(url, auth=(USER, SECRET), headers=HEADERS, data=json.dumps(payload))
           response.raise_for_status()
           print(f"Host '{host['host_name']}' erfolgreich erstellt.")
       except requests.RequestException as e:
           print(f"Fehler beim Erstellen von '{host['host_name']}': {e}")

   def activate_changes():
       """Aktiviert ausstehende Änderungen."""
       url = f"{SERVER}/check_mk/api/1.0/domain-types/activation_run/actions/activate-changes/invoke"
       try:
           response = requests.post(url, auth=(USER, SECRET), headers=HEADERS)
           response.raise_for_status()
           print("Änderungen erfolgreich aktiviert.")
       except requests.RequestException as e:
           print(f"Fehler beim Aktivieren: {e}")

   if __name__ == "__main__":
       for host in new_hosts:
           create_host(host)
       activate_changes()
   ```

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   python3 create_hosts.py
   ```

4. **Schritt 4**: Überprüfe die Hosts in der Weboberfläche unter `Monitor > All hosts`.

**Reflexion**: Wie könnte man das Skript anpassen, um bestehende Hosts zu aktualisieren? Welche Attribute könnten noch hinzugefügt werden (z. B. `alias`)?

### Übung 3: Abfrage von Services mit Problemzuständen

**Ziel**: Ein Skript erstellen, das Services im Zustand `WARN` oder `CRIT` abruft.

1. **Schritt 1**: Erstelle eine Datei `get_alerts.py`:
   ```bash
   nano get_alerts.py
   ```

2. **Schritt 2**: Füge folgenden Code ein:
   ```python
   import requests
   import json

   SERVER = "http://localhost/mysite"
   USER = "api_user"
   SECRET = "mysecret123"
   HEADERS = {"Accept": "application/json"}

   def get_alert_services():
       """Ruft Services mit Status WARN oder CRIT ab."""
       url = f"{SERVER}/check_mk/api/1.0/domain-types/service/collections/all"
       try:
           response = requests.get(url, auth=(USER, SECRET), headers=HEADERS)
           response.raise_for_status()
           services = response.json().get("value", [])
           return [s for s in services if s.get("extensions", {}).get("state") in ["WARN", "CRIT"]]
       except requests.RequestException as e:
           print(f"Fehler bei der API-Anfrage: {e}")
           return []

   if __name__ == "__main__":
       alert_services = get_alert_services()
       if alert_services:
           print("\nServices im Problemzustand:")
           for service in alert_services:
               extensions = service.get("extensions", {})
               host_name = extensions.get("host_name")
               description = extensions.get("service_description")
               state = extensions.get("state")
               output = extensions.get("plugin_output", "")
               print(f"  - Host: {host_name}, Service: {description}, Status: {state}, Ausgabe: {output}")
       else:
           print("\nKeine Services im Problemzustand gefunden.")
   ```

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   python3 get_alerts.py
   ```

**Reflexion**: Wie könnte man das Skript filtern, um nur Services eines bestimmten Hosts anzuzeigen? Welche weiteren API-Endpunkte könnten für Alarme nützlich sein?

### Übung 4: CMDB-Integration mit CSV-Import

**Ziel**: Ein Skript erstellen, das Host-Daten aus einer CSV-Datei importiert.

1. **Schritt 1**: Erstelle eine CSV-Datei `cmdb_hosts.csv`:
   ```bash
   nano cmdb_hosts.csv
   ```
   Inhalt:
   ```csv
   hostname,ip_address,alias
   server-01,192.168.1.101,Webserver
   server-02,192.168.1.102,Database
   server-03,192.168.1.103,Application
   ```

2. **Schritt 2**: Erstelle eine Datei `import_cmdb.py`:
   ```bash
   nano import_cmdb.py
   ```

3. **Schritt 3**: Füge folgenden Code ein:
   ```python
   import requests
   import json
   import csv

   SERVER = "http://localhost/mysite"
   USER = "api_user"
   SECRET = "mysecret123"
   HEADERS = {"Accept": "application/json", "Content-Type": "application/json"}
   CMDB_FILE = "cmdb_hosts.csv"

   def read_cmdb_file(file_path):
       """Liest Host-Daten aus einer CSV-Datei."""
       hosts = []
       try:
           with open(file_path, mode="r", encoding="utf-8") as file:
               reader = csv.DictReader(file)
               if not all(col in reader.fieldnames for col in ["hostname", "ip_address"]):
                   raise ValueError("CSV muss 'hostname' und 'ip_address' enthalten")
               for row in reader:
                   hosts.append({
                       "host_name": row["hostname"].strip(),
                       "ip_address": row["ip_address"].strip(),
                       "alias": row.get("alias", "").strip()
                   })
           print(f"{len(hosts)} Hosts aus {file_path} gelesen.")
           return hosts
       except FileNotFoundError:
           print(f"Fehler: {file_path} nicht gefunden.")
           return []
       except Exception as e:
           print(f"Fehler beim Lesen der CSV: {e}")
           return []

   def get_existing_hosts():
       """Ruft bestehende Hosts aus Checkmk ab."""
       url = f"{SERVER}/check_mk/api/1.0/domain-types/host_config/collections/all"
       try:
           response = requests.get(url, auth=(USER, SECRET), headers=HEADERS)
           response.raise_for_status()
           return [host["id"] for host in response.json().get("value", [])]
       except requests.RequestException as e:
           print(f"Fehler beim Abrufen der Hosts: {e}")
           return []

   def create_or_update_host(host):
       """Erstellt oder aktualisiert einen Host."""
       url = f"{SERVER}/check_mk/api/1.0/domain-types/host_config/collections/all"
       payload = {
           "host_name": host["host_name"],
           "folder": "/",
           "attributes": {
               "ipaddress": host["ip_address"],
               "alias": host["alias"] if host["alias"] else None
           }
       }
       existing_hosts = get_existing_hosts()
       if host["host_name"] in existing_hosts:
           print(f"Host '{host['host_name']}' existiert, aktualisiere...")
           url = f"{SERVER}/check_mk/api/1.0/objects/host_config/{host['host_name']}"
           try:
               response = requests.put(url, auth=(USER, SECRET), headers=HEADERS, data=json.dumps(payload))
               response.raise_for_status()
               print(f"Host '{host['host_name']}' erfolgreich aktualisiert.")
           except requests.RequestException as e:
               print(f"Fehler beim Aktualisieren von '{host['host_name']}': {e}")
       else:
           print(f"Erstelle Host: {host['host_name']}...")
           try:
               response = requests.post(url, auth=(USER, SECRET), headers=HEADERS, data=json.dumps(payload))
               response.raise_for_status()
               print(f"Host '{host['host_name']}' erfolgreich erstellt.")
           except requests.RequestException as e:
               print(f"Fehler beim Erstellen von '{host['host_name']}': {e}")

   def activate_changes():
       """Aktiviert ausstehende Änderungen."""
       url = f"{SERVER}/check_mk/api/1.0/domain-types/activation_run/actions/activate-changes/invoke"
       try:
           response = requests.post(url, auth=(USER, SECRET), headers=HEADERS)
           response.raise_for_status()
           print("Änderungen erfolgreich aktiviert.")
       except requests.RequestException as e:
           print(f"Fehler beim Aktivieren: {e}")

   if __name__ == "__main__":
       hosts = read_cmdb_file(CMDB_FILE)
       if not hosts:
           print("Keine Hosts zum Verarbeiten. Beende Skript.")
           exit(1)
       for host in hosts:
           create_or_update_host(host)
       activate_changes()
   ```

4. **Schritt 4**: Führe das Skript aus:
   ```bash
   python3 import_cmdb.py
   ```

5. **Schritt 5**: Überprüfe die Hosts in der Weboberfläche unter `Monitor > All hosts` und führe eine Service-Discovery durch:
   ```bash
   cmk -I server-01 server-02 server-03
   cmk -O
   ```

**Reflexion**: Warum ist die CMDB-Integration für große Umgebungen wichtig? Wie könnte man das Skript erweitern, um gelöschte Hosts aus der CSV-Datei zu entfernen?

## Tipps für den Erfolg
- **Fehlerbehebung**: Überprüfe die Checkmk-Logs (`tail -f ~/var/log/web.log`) bei API-Fehlern.
- **Sicherheit**: Verwende sichere API-Secrets und beschränke die Berechtigungen des API-Benutzers.
- **Skalierung**: Für große CMDBs nutze Batches oder `concurrent.futures` für parallele Verarbeitung.
- **Dokumentation**: Konsultiere https://docs.checkmk.com/latest/de/rest_api.html für weitere Endpunkte und Parameter.

## Fazit
Du hast gelernt, die Checkmk REST-API für die Automatisierung von Host-Management, Service-Abfragen und CMDB-Integration zu nutzen. Diese Fähigkeiten sind entscheidend für die Verwaltung großer IT-Infrastrukturen und die Integration mit externen Systemen.

**Nächste Schritte**: Möchtest du die API für Benachrichtigungen (z. B. Abruf von Benachrichtigungsregeln) vertiefen, die CMDB-Integration um Löschfunktionen erweitern oder die Automatisierung von Service-Discovery untersuchen?

**Quelle**: Die Schritte basieren auf der Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/rest_api.html).