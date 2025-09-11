# Praxisorientierte Anleitung: Vertiefte Anwendung der Checkmk REST-API

## Einführung

Nachdem die Grundlagen der Checkmk REST-API etabliert sind, konzentrieren wir uns auf fortgeschrittene Anwendungsfälle, insbesondere die **Integration mit einem CMDB-System**. Diese Erweiterung zeigt, wie man Host-Daten aus einer CSV-Datei in Checkmk importiert und synchronisiert, um eine typische CMDB-Integration zu simulieren. Wir verwenden Python und die Checkmk REST-API, um Hosts automatisch zu erstellen oder zu aktualisieren, basierend auf einer CSV-Datei mit Hostnamen und IP-Adressen. Die Übungen sind für Nutzer mit fortgeschrittenen Kenntnissen in Python, grundlegenden API-Kenntnissen und Vertrautheit mit Checkmk geeignet.

**Voraussetzungen**:
- Ein Linux-System mit Checkmk Raw Edition installiert (z. B. Ubuntu 22.04 oder Debian 11).
- Eine Checkmk-Site (z. B. `mysite`) mit einem API-Benutzer (`api_user`) und Secret.
- Python 3 installiert.
- Python-Bibliotheken `requests` und `csv` (installiere mit `pip install requests`).
- Ein Terminal (z. B. `bash`) mit `omd su mysite`-Zugriff.
- Eine CSV-Datei (`cmdb_hosts.csv`) mit Host-Daten.

**Hinweis**: Die Übung setzt voraus, dass der API-Benutzer über die notwendigen Rechte verfügt, um Hosts zu erstellen, abzufragen und zu aktualisieren.

## Übung: Integration eines CMDB mit Checkmk

**Ziel**: Importiere Host-Daten aus einer CSV-Datei in Checkmk, um eine CMDB-Integration zu simulieren.

1. **Schritt 1**: Erstelle eine CSV-Datei `cmdb_hosts.csv` mit folgendem Inhalt:
   ```csv
   hostname,ip_address
   server-01,192.168.1.101
   server-02,192.168.1.102
   server-03,192.168.1.103
   ```
   Speichere die Datei im Verzeichnis `/opt/omd/sites/mysite`.

2. **Schritt 2**: Stelle sicher, dass die Python-Bibliothek `requests` installiert ist:
   ```bash
   sudo -u mysite pip install requests
   ```

3. **Schritt 3**: Erstelle ein Python-Skript `cmdb_integration.py`:
   ```python
   import requests
   import json
   import csv
   import os

   # Konfigurationsvariablen
   SERVER = "http://localhost/mysite"
   USER = "api_user"
   SECRET = "mysecret123"
   CMDB_FILE = "cmdb_hosts.csv"

   def read_cmdb_file(file_path):
       """Liest Host-Daten aus einer CSV-Datei."""
       hosts = []
       try:
           with open(file_path, mode='r', encoding='utf-8') as file:
               reader = csv.DictReader(file)
               if not all(col in reader.fieldnames for col in ['hostname', 'ip_address']):
                   raise ValueError("CSV-Datei muss 'hostname' und 'ip_address' Spalten enthalten.")
               for row in reader:
                   hosts.append({
                       "hostname": row['hostname'].strip(),
                       "ip_address": row['ip_address'].strip()
                   })
           print(f"{len(hosts)} Hosts aus {file_path} gelesen.")
           return hosts
       except FileNotFoundError:
           print(f"Fehler: Datei {file_path} nicht gefunden.")
           return []
       except Exception as e:
           print(f"Fehler beim Lesen der CSV-Datei: {e}")
           return []

   def get_existing_hosts():
       """Ruft die Liste aller bestehenden Hosts aus Checkmk ab."""
       url = f"{SERVER}/check_mk/api/1.0/domain-types/host_config/collections/all"
       headers = {"Accept": "application/json"}
       try:
           response = requests.get(url, auth=(USER, SECRET), headers=headers)
           response.raise_for_status()
           return [host['id'] for host in response.json().get("value", [])]
       except requests.RequestException as e:
           print(f"Fehler beim Abrufen der Hosts: {e}")
           return []

   def create_or_update_host(hostname, ip_address):
       """Erstellt oder aktualisiert einen Host in Checkmk."""
       url = f"{SERVER}/check_mk/api/1.0/domain-types/host_config/collections/all"
       headers = {"Accept": "application/json", "Content-Type": "application/json"}
       payload = {
           "host_name": hostname,
           "folder": "/",
           "attributes": {
               "ipaddress": ip_address
           }
       }
       
       # Prüfen, ob Host bereits existiert
       existing_hosts = get_existing_hosts()
       if hostname in existing_hosts:
           print(f"Host '{hostname}' existiert bereits, aktualisiere...")
           url = f"{SERVER}/check_mk/api/1.0/objects/host_config/{hostname}"
           response = requests.put(url, auth=(USER, SECRET), headers=headers, data=json.dumps(payload))
       else:
           print(f"Erstelle Host: {hostname}...")
           response = requests.post(url, auth=(USER, SECRET), headers=headers, data=json.dumps(payload))
       
       if response.status_code in [200, 201]:
           print(f"Host '{hostname}' erfolgreich erstellt/aktualisiert.")
       else:
           print(f"Fehler beim Erstellen/Aktualisieren von '{hostname}': {response.status_code} - {response.text}")

   def activate_changes():
       """Aktiviert ausstehende Änderungen."""
       url = f"{SERVER}/check_mk/api/1.0/domain-types/activation_tasks/actions/activate_changes"
       headers = {"Accept": "application/json"}
       try:
           response = requests.post(url, auth=(USER, SECRET), headers=headers)
           if response.status_code == 200:
               print("Änderungen erfolgreich aktiviert.")
           else:
               print(f"Fehler beim Aktivieren: {response.status_code} - {response.text}")
       except requests.RequestException as e:
           print(f"Fehler beim Aktivieren der Änderungen: {e}")

   if __name__ == "__main__":
       # CSV-Datei einlesen
       hosts = read_cmdb_file(CMDB_FILE)
       if not hosts:
           print("Keine Hosts zum Verarbeiten. Beende Skript.")
           exit(1)
       
       # Hosts erstellen oder aktualisieren
       for host in hosts:
           create_or_update_host(host['hostname'], host['ip_address'])
       
       # Änderungen aktivieren
       activate_changes()
   ```

4. **Schritt 4**: Führe das Skript aus:
   ```bash
   sudo -u mysite python3 cmdb_integration.py
   ```

5. **Schritt 5**: Überprüfe in der Checkmk-Weboberfläche (`http://localhost/mysite`), ob die Hosts (`server-01`, `server-02`, `server-03`) erstellt oder aktualisiert wurden:
   - Navigiere zu `Monitor > All hosts`.
   - Prüfe, ob die Hosts mit den korrekten IP-Adressen (z. B. `192.168.1.101`) angezeigt werden.

6. **Schritt 6**: Führe eine Service-Discovery durch, um die Services der neuen Hosts zu erkennen:
   ```bash
   sudo -u mysite cmk -I server-01 server-02 server-03
   cmk -O
   ```

**Reflexion**: Warum ist die Synchronisation mit einem CMDB wichtig? Wie könnte man das Skript anpassen, um zusätzliche Attribute (z. B. `alias` oder `site`) aus der CSV-Datei zu importieren? Konsultiere die Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/rest_api.html) für weitere Host-Attribute.

## Tipps für die Erweiterung
- **Erweiterte CSV-Attribute**: Passe die CSV-Datei und das Skript an, um zusätzliche Attribute wie `alias` oder `labels` zu unterstützen. Beispiel:
  ```csv
  hostname,ip_address,alias
  server-01,192.168.1.101,Webserver
  server-02,192.168.1.102,Database
  server-03,192.168.1.103,Application
  ```
  Aktualisiere das Skript, um `alias` in `payload["attributes"]` hinzuzufügen:
  ```python
  payload = {
      "host_name": hostname,
      "folder": "/",
      "attributes": {
          "ipaddress": ip_address,
          "alias": host.get("alias", "")
      }
  }
  ```
- **Fehlerbehebung**: Überprüfe die Checkmk-Logs (`tail -f /opt/omd/sites/mysite/var/log/web.log`), wenn Hosts nicht erstellt werden.
- **Idempotenz**: Das Skript prüft bereits, ob ein Host existiert, bevor es ihn erstellt oder aktualisiert, um Duplikate zu vermeiden.
- **Skalierung**: Für große CMDBs kannst du das Skript anpassen, um Hosts in Batches zu verarbeiten oder Parallelverarbeitung mit `concurrent.futures` hinzuzufügen.

## Fazit
Diese Übung erweitert die Checkmk REST-API-Anwendung, indem sie eine CMDB-Integration durch den Import von Host-Daten aus einer CSV-Datei in Checkmk demonstriert. Das Skript `cmdb_integration.py` automatisiert die Erstellung oder Aktualisierung von Hosts und aktiviert Änderungen über die REST-API, basierend auf der offiziellen Dokumentation (https://docs.checkmk.com/latest/de/rest_api.html). Dies ist ein typischer Anwendungsfall für die Verwaltung großer IT-Infrastrukturen, bei denen CMDB-Daten mit Monitoring-Systemen synchronisiert werden müssen.

**Nächste Schritte**: Möchtest du die API für Benachrichtigungen (z. B. Abruf von Benachrichtigungsregeln oder Triggern von Alerts) vertiefen, die CMDB-Integration weiter ausbauen (z. B. mit Löschfunktion für nicht mehr existierende Hosts), oder ein anderes Checkmk-Thema wie die Automatisierung von Service-Discovery untersuchen?

**Quelle**: Die Schritte basieren auf der Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/rest_api.html).