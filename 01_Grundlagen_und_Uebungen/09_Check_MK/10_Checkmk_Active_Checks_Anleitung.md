# Praxisorientierte Anleitung: Aktive Checks in Checkmk für Anfänger

## Einführung
Aktive Checks in Checkmk sind vordefinierte Überprüfungen, die direkt vom Checkmk-Server ausgeführt werden, um Dienste wie HTTP, ICMP oder SMTP zu überwachen, ohne dass ein Agent auf dem Zielhost erforderlich ist. Diese Anleitung führt Anfänger in die **Verwendung von aktiven Checks** ein, basierend auf der offiziellen Dokumentation (https://docs.checkmk.com/latest/de/active_checks.html). Der Fokus liegt auf **Grundlagen von aktiven Checks**, **Konfiguration eines HTTP-Checks auf dem localhost**, **Integration in eine Checkmk-Site** sowie **Fehlerbehebung**. Eine **Spielerei** zeigt, wie du Daten eines aktiven Checks über die Checkmk-REST-API abrufst und in Markdown- sowie JSON-Format exportierst, wobei der Hostname als Kommandozeilenparameter übergeben wird. Die Übungen verwenden die **Checkmk Raw Edition** (Open Source) und sind für Nutzer mit grundlegenden Kenntnissen in Linux, Python und Checkmk geeignet.

**Voraussetzungen**:
- Ein Linux-System mit Checkmk Raw Edition installiert (z. B. Ubuntu 22.04 oder Debian 11).
- Ein Terminal (z. B. `bash` oder `zsh`) mit Root-Zugriff oder `sudo`-Rechten.
- Eine Checkmk-Site (z. B. `mysite`) eingerichtet (siehe vorherige Anleitung, UUID: 3560880a-8a37-41a0-98f1-cd422c8a3e31).
- Ein Webserver (z. B. Apache oder Nginx) auf dem localhost für den HTTP-Check (installiere z. B. mit `sudo apt install apache2`).
- Python-Bibliotheken `requests`, `json` und `argparse` (installiere `requests` mit `pip install requests`; `json` und `argparse` sind Standard in Python 3).
- Ein API-Benutzer in Checkmk mit Zugriff auf die REST-API (siehe Dokumentation).
- Grundkenntnisse in Linux (z. B. `apt`, `systemctl`), Python (z. B. API-Anfragen, Kommandozeilenargumente) und Checkmk (z. B. Konzept von Hosts und Services).
- Sichere Testumgebung (z. B. `/opt/omd/sites/mysite` oder eine virtuelle Maschine).
- Ein Webbrowser (z. B. Chrome, Firefox) für die Checkmk-Weboberfläche.

**Hinweis**: Diese Anleitung setzt voraus, dass ein Checkmk-Server auf dem localhost läuft und ein Webserver (z. B. Apache) auf Port 80 erreichbar ist. Der HTTP-Check (`check_http`) wird verwendet, um die Verfügbarkeit einer Webseite zu überwachen.

## Grundlegende Begriffe und Befehle
Hier sind die wichtigsten Konzepte und Befehle für aktive Checks in Checkmk:

1. **Grundlagen von aktiven Checks**:
   - **Aktiver Check**: Ein Check, der direkt vom Checkmk-Server ausgeführt wird (z. B. `check_http` für HTTP-Dienste).
   - **Check-Parameter**: Parameter wie URL, Port oder erwartete Statuscodes werden in der Weboberfläche oder Konfigurationsdateien definiert.
   - **Service**: Jeder aktive Check erscheint als Service in Checkmk (z. B. `HTTP localhost`).
2. **Konfiguration**:
   - `cmk -I localhost`: Führt eine Service-Discovery durch, um aktive Checks zu erkennen.
   - `cmk -O`: Aktiviert Änderungen.
   - Konfiguration erfolgt meist über die Weboberfläche (`Setup > Services > Active checks`).
3. **Integration mit externen Systemen**:
   - `curl -u <user>:<secret> http://<server>/<site>/check_mk/api/1.0/...`: Ruft Service-Daten über die REST-API ab.
   - Python mit `requests`: Vereinfacht API-Anfragen für externe Integration.
4. **Nützliche Zusatzbefehle**:
   - `cmk -d localhost`: Ruft Agent-Daten ab (für passive Checks; bei aktiven Checks nicht relevant).
   - `tail -f /opt/omd/sites/mysite/var/log/web.log`: Zeigt Checkmk-Logs in Echtzeit.
   - `curl http://localhost`: Testet die Erreichbarkeit des Webservers manuell.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Konfiguration eines aktiven HTTP-Checks
**Ziel**: Konfiguriere einen aktiven HTTP-Check für den localhost.

1. **Schritt 1**: Stelle sicher, dass Checkmk und ein Webserver laufen:
   ```bash
   sudo omd status mysite
   sudo systemctl status apache2
   ```
   Wenn der Webserver nicht läuft, starte ihn:
   ```bash
   sudo systemctl start apache2
   ```
   Teste die Erreichbarkeit:
   ```bash
   curl http://localhost
   ```

2. **Schritt 2**: Wechsle in die Checkmk-Site:
   ```bash
   sudo omd su mysite
   ```

3. **Schritt 3**: Stelle sicher, dass der localhost als Host konfiguriert ist:
   - Bearbeite die Konfigurationsdatei:
     ```bash
     nano ~/etc/check_mk/main.mk
     ```
     Überprüfe, dass folgender Inhalt vorhanden ist:
     ```python
     all_hosts += ["localhost"]
     ipaddresses["localhost"] = "127.0.0.1"
     ```
     Speichere und schließe.

4. **Schritt 4**: Konfiguriere den HTTP-Check in der Weboberfläche:
   - Gehe zu `http://localhost/mysite`.
   - Navigiere zu `Setup > Services > Service monitoring rules > Check HTTP service`.
   - Erstelle eine Regel mit:
     - **Service description**: `HTTP localhost`
     - **Hostname**: `localhost`
     - **Port**: `80`
     - **Expected status code**: `200`
     - **Apply to**: `localhost`
   - Speichere und wende die Änderungen an (`Activate changes`).

5. **Schritt 5**: Führe eine Service-Discovery durch:
   ```bash
   cmk -I localhost
   ```
   Dies sollte einen Service wie `HTTP localhost` erkennen. Aktiviere die Änderungen:
   ```bash
   cmk -O
   ```

**Reflexion**: Warum sind aktive Checks nützlich für die Überwachung von Diensten ohne Agent? Nutze die Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/active_checks.html) und überlege, wie du andere aktive Checks (z. B. `check_icmp`) konfigurieren kannst.

### Übung 2: Integration und Überprüfung in einer Checkmk-Site
**Ziel**: Integriere und überprüfe den HTTP-Check in Checkmk.

1. **Schritt 1**: Überprüfe die Service-Daten in der Weboberfläche:
   - Gehe zu `http://localhost/mysite`.
   - Navigiere zu `Monitor > All hosts > localhost`.
   - Du solltest einen Service wie `HTTP localhost` mit Status (z. B. `OK` für Statuscode 200) sehen.

2. **Schritt 2**: Teste den Check manuell:
   - Führe den Check direkt aus (für Debugging):
     ```bash
     sudo -u mysite cmk -v --debug localhost
     ```
     Suche nach der Ausgabe des `HTTP localhost`-Service.

3. **Schritt 3**: Passe die Regel an (optional):
   - Gehe zu `Setup > Services > Check HTTP service`.
   - Ändere die Regel, z. B.:
     - **Expected string**: `Welcome` (prüft, ob „Welcome“ im HTML-Code vorhanden ist).
     - **Timeout**: `5` Sekunden.
   - Speichere und wende die Änderungen an.

4. **Schritt 4**: Überprüfe die Checkmk-Logs:
   ```bash
   tail -f /opt/omd/sites/mysite/var/log/web.log
   ```
   Suche nach Einträgen zum HTTP-Check, um Fehler zu identifizieren.

**Reflexion**: Wie verbessern aktive Checks die Überwachung von Netzwerkdiensten? Nutze `cmk -I --help` und überlege, wie du Parameter wie `SSL` oder `URI` für komplexere HTTP-Checks anpassen kannst.

### Übung 3: Fehlerbehebung und Spielerei
**Ziel**: Behebe Fehler beim HTTP-Check und exportiere dessen Daten über die REST-API in Markdown und JSON, wobei der Hostname als Parameter übergeben wird.

1. **Schritt 1**: Teste die Fehlerbehebung:
   - Wenn der `HTTP localhost`-Service nicht erscheint oder fehlerhaft ist, überprüfe den Webserver:
     ```bash
     sudo systemctl status apache2
     curl http://localhost
     ```
   - Überprüfe die Checkmk-Logs:
     ```bash
     tail -f /opt/omd/sites/mysite/var/log/web.log
     ```
   - Führe einen Debugging-Check durch:
     ```bash
     sudo -u mysite cmk -v --debug localhost
     ```

2. **Schritt 2**: Erstelle einen API-Benutzer für die REST-API:
   - Gehe in der Weboberfläche zu `Setup > Users > Add user`.
   - Erstelle einen Benutzer (z. B. `api_user`) mit Automation secret (z. B. `mysecret123`).
   - Aktiviere die Berechtigung `Access to Web API`.

3. **Schritt 3**: Installiere die Python-Bibliothek `requests`:
   ```bash
   sudo -u mysite pip install requests
   ```

4. **Schritt 4**: Erstelle ein Python-Skript für die Markdown- und JSON-Exportfunktion über die REST-API:
   ```bash
   nano export_active_check_api.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import requests
   import json
   import argparse

   def get_active_check_data_api(hostname, site="mysite", server="localhost", username="api_user", secret="mysecret123"):
       """Ruft Daten eines aktiven Checks für einen Host über die Checkmk REST-API ab."""
       try:
           url = f"http://{server}/{site}/check_mk/api/1.0/hosts/{hostname}/services"
           headers = {"Accept": "application/json"}
           response = requests.get(url, auth=(username, secret), headers=headers)
           response.raise_for_status()
           data = response.json()
           services = []
           for service in data.get("value", []):
               if "HTTP" in service.get("service_description", ""):
                   services.append({
                       "service_description": service["service_description"],
                       "state": service["service_state"],
                       "details": service.get("service_details", "")
                   })
           return services
       except requests.RequestException as e:
           print(f"Fehler beim Abrufen der Daten für {hostname}: {e}")
           return []

   def to_markdown(services, hostname, output_file="active_check_api_data.md"):
       """Exportiert Daten eines aktiven Checks als Markdown-Tabelle."""
       if not services:
           return "Keine Daten verfügbar."
       header = "| Service | Status | Details |\n|---|--------|---------|\n"
       rows = [f"| {s['service_description']} | {s['state']} | {s['details']} |" for s in services]
       markdown = header + "\n".join(rows)
       with open(output_file, 'w') as f:
           f.write(f"# Active Check-Daten für {hostname} (via REST-API)\n\n" + markdown)
       return markdown

   def to_json(services, hostname, output_file="active_check_api_data.json"):
       """Exportiert Daten eines aktiven Checks als JSON-Datei."""
       if not services:
           return "Keine Daten verfügbar."
       json_data = {"hostname": hostname, "active_check": services}
       with open(output_file, 'w') as f:
           json.dump(json_data, f, indent=4)
       return json.dumps(json_data, indent=4)

   if __name__ == "__main__":
       parser = argparse.ArgumentParser(description="Exportiert Checkmk-Active-Check-Daten in Markdown und JSON.")
       parser.add_argument("hostname", help="Name des Hosts für die Active-Check-Daten")
       args = parser.parse_args()
       hostname = args.hostname

       services = get_active_check_data_api(hostname)
       print("Markdown-Ausgabe:")
       print(to_markdown(services, hostname))
       print("\nJSON-Ausgabe:")
       print(to_json(services, hostname))
   ```
   Speichere und schließe. Ersetze `api_user` und `mysecret123` mit deinem API-Benutzer und Secret.

5. **Schritt 5**: Führe das Skript mit einem Hostnamen aus:
   ```bash
   sudo -u mysite python3 export_active_check_api.py localhost
   ```
   Überprüfe die Markdown-Ausgabe:
   ```bash
   cat active_check_api_data.md
   ```
   Die Markdown-Ausgabe könnte so aussehen:
   ```
   # Active Check-Daten für localhost (via REST-API)

   | Service | Status | Details |
   |---|--------|---------|
   | HTTP localhost | OK | HTTP/1.1 200 OK |
   ```
   Überprüfe die JSON-Ausgabe:
   ```bash
   cat active_check_api_data.json
   ```
   Die JSON-Ausgabe könnte so aussehen:
   ```
   {
       "hostname": "localhost",
       "active_check": [
           {
               "service_description": "HTTP localhost",
               "state": "OK",
               "details": "HTTP/1.1 200 OK"
           }
       ]
   }
   ```

6. **Spielerei**: Passe das Skript an, um nur Services mit `WARN` oder `CRIT` zu exportieren:
   - Ändere `to_markdown` und `to_json`, um `services` zu filtern:
     ```python
     # In to_markdown
     rows = [f"| {s['service_description']} | {s['state']} | {s['details']} |" for s in services if s['state'] in ['WARN', 'CRIT']]
     # In to_json
     filtered_services = [s for s in services if s['state'] in ['WARN', 'CRIT']]
     json_data = {"hostname": hostname, "active_check": filtered_services}
     ```

**Reflexion**: Wie ermöglichen aktive Checks die Überwachung von Diensten ohne Agent? Nutze die Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/active_checks.html) und überlege, wie du komplexere aktive Checks (z. B. `check_smtp` oder `check_dns`) konfigurieren kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um aktive Checks und die REST-API zu verinnerlichen.
- **Sicheres Testen**: Nutze virtuelle Maschinen oder Container, um Änderungen risikofrei zu testen.
- **Fehler verstehen**: Lies Checkmk-Logs (`/opt/omd/sites/mysite/var/log/web.log`) und nutze die Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/active_checks.html).
- **Effiziente Entwicklung**: Nutze `cmk -I` für schnelle Service-Updates, aktive Checks für agentlose Überwachung und die REST-API für externe Integration.
- **Kombiniere Tools**: Integriere Daten aktiver Checks mit Redis für Caching, Ansible für automatisierte Konfiguration oder APIs für externe Systeme.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Export in CSV oder Verarbeitung mehrerer Hosts über die API.

## Fazit
Mit diesen Übungen hast du einen aktiven HTTP-Check in Checkmk konfiguriert, integriert und in eine Checkmk-Site eingebunden, basierend auf der offiziellen Dokumentation (https://docs.checkmk.com/latest/de/active_checks.html). Die Spielerei zeigt, wie du Daten eines aktiven Checks über die REST-API abrufst und in Markdown- sowie JSON-Format exportierst, wobei der Hostname als Kommandozeilenparameter übergeben wird. Aktive Checks bieten eine flexible Möglichkeit zur Überwachung von Diensten ohne Agent, und die REST-API erleichtert die Integration in externe Systeme. Vertiefe dein Wissen, indem du komplexere aktive Checks (z. B. für SMTP, DNS oder SSL-Zertifikate), API-Schleifen für mehrere Hosts oder Integration mit CMDBs ausprobierst. Wenn du ein spezifisches Thema (z. B. komplexere aktive Checks oder CMDB-Integration) vertiefen möchtest, lass es mich wissen!

**Quelle**: Die Schritte basieren auf der offiziellen Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/active_checks.html und https://docs.checkmk.com/latest/de/rest_api.html).
