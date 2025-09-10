# Praxisorientierte Anleitung: Datasource-Programme in Checkmk für Anfänger

## Einführung
Datasource-Programme in Checkmk ermöglichen die Erweiterung der Datenquellen des Checkmk-Agenten, um benutzerdefinierte Daten (z. B. Prozessanzahl, benutzerdefinierte Metriken) zu erfassen. Sie ersetzen oder ergänzen den Standard-Agenten und geben Daten im Checkmk-Format aus. Diese Anleitung führt Anfänger in die **Verwendung von Datasource-Programmen** ein, basierend auf der offiziellen Dokumentation (https://docs.checkmk.com/latest/de/datasource_programs.html). Der Fokus liegt auf **Grundlagen von Datasource-Programmen**, **Erstellung und Konfiguration eines einfachen Datasource-Programms auf dem localhost**, **Integration in eine Checkmk-Site** sowie **Fehlerbehebung**. Eine **Spielerei** zeigt, wie du Daten eines Datasource-Programms über die Checkmk-REST-API abrufst und in Markdown- sowie JSON-Format exportierst, wobei der Hostname als Kommandozeilenparameter übergeben wird. Die Übungen verwenden die **Checkmk Raw Edition** (Open Source) und sind für Nutzer mit grundlegenden Kenntnissen in Linux, Python und Checkmk geeignet.

**Voraussetzungen**:
- Ein Linux-System mit Checkmk Raw Edition installiert (z. B. Ubuntu 22.04 oder Debian 11).
- Ein Terminal (z. B. `bash` oder `zsh`) mit Root-Zugriff oder `sudo`-Rechten.
- Eine Checkmk-Site (z. B. `mysite`) eingerichtet (siehe vorherige Anleitung).
- Checkmk-Agent auf dem localhost installiert (siehe vorherige Anleitung).
- Python-Bibliotheken `requests`, `json` und `argparse` (installiere `requests` mit `pip install requests`; `json` und `argparse` sind Standard in Python 3).
- Ein API-Benutzer in Checkmk mit Zugriff auf die REST-API (siehe Dokumentation).
- Grundkenntnisse in Linux (z. B. `apt`, `systemctl`), Python (z. B. API-Anfragen, Kommandozeilenargumente) und Checkmk (z. B. Konzept von Hosts und Services).
- Sichere Testumgebung (z. B. `/opt/omd/sites/mysite` oder eine virtuelle Maschine).
- Ein Webbrowser (z. B. Chrome, Firefox) für die Checkmk-Weboberfläche.

**Hinweis**: Diese Anleitung setzt voraus, dass ein Checkmk-Server und der Checkmk-Agent auf dem localhost laufen. Es wird ein einfaches Datasource-Programm erstellt, um die Anzahl laufender Prozesse zu überwachen.

## Grundlegende Begriffe und Befehle
Hier sind die wichtigsten Konzepte und Befehle für Datasource-Programme in Checkmk:

1. **Grundlagen von Datasource-Programmen**:
   - **Datasource-Programm**: Ein Skript (z. B. in Bash oder Python), das Daten im Checkmk-Format (`<<<section>>>`) ausgibt.
   - **Checkmk-Agent**: Datasource-Programme ersetzen oder ergänzen den Agenten und liefern benutzerdefinierte Daten.
   - **Service**: Jede Metrik eines Datasource-Programms erscheint als Service in Checkmk (z. B. `Process Count`).
2. **Erstellung und Konfiguration**:
   - `sudo nano /usr/lib/check_mk_agent/plugins/process_count.sh`: Erstellt ein Datasource-Skript.
   - `sudo chmod +x /usr/lib/check_mk_agent/plugins/process_count.sh`: Macht das Skript ausführbar.
   - `sudo systemctl restart check-mk-agent`: Startet den Agenten neu.
3. **Integration in eine Checkmk-Site**:
   - `cmk -I localhost`: Führt eine Service-Discovery durch, um Services des Datasource-Programms zu erkennen.
   - `cmk -O`: Aktiviert Änderungen.
4. **Integration mit externen Systemen**:
   - `curl -u <user>:<secret> http://<server>/<site>/check_mk/api/1.0/...`: Ruft Service-Daten über die REST-API ab.
   - Python mit `requests`: Vereinfacht API-Anfragen für externe Integration.
5. **Nützliche Zusatzbefehle**:
   - `cmk -d localhost`: Ruft Agent-Daten, einschließlich Datasource-Daten, ab.
   - `sudo /usr/lib/check_mk_agent/plugins/process_count.sh`: Testet das Datasource-Skript direkt.
   - `tail -f /opt/omd/sites/mysite/var/log/web.log`: Zeigt Checkmk-Logs in Echtzeit.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Erstellung und Konfiguration eines Datasource-Programms
**Ziel**: Erstelle und konfiguriere ein einfaches Datasource-Programm zur Überwachung der Prozessanzahl.

1. **Schritt 1**: Stelle sicher, dass Checkmk und der Agent laufen:
   ```bash
   sudo omd status mysite
   sudo systemctl status check-mk-agent
   ```
   Wenn die Site oder der Agent nicht läuft, starte sie:
   ```bash
   sudo omd start mysite
   sudo systemctl start check-mk-agent
   ```

2. **Schritt 2**: Erstelle ein Bash-Datasource-Programm:
   ```bash
   sudo mkdir -p /usr/lib/check_mk_agent/plugins
   sudo nano /usr/lib/check_mk_agent/plugins/process_count.sh
   ```
   Füge folgenden Inhalt ein, um die Anzahl laufender Prozesse zu erfassen:
   ```bash
   #!/bin/bash
   echo '<<<process_count>>>'
   COUNT=$(ps aux | wc -l)
   echo "process_count $COUNT"
   ```
   Speichere und schließe. Dieses Skript gibt die Anzahl der Prozesse im Checkmk-Format aus.

3. **Schritt 3**: Mache das Skript ausführbar:
   ```bash
   sudo chmod +x /usr/lib/check_mk_agent/plugins/process_count.sh
   ```

4. **Schritt 4**: Teste das Skript direkt:
   ```bash
   sudo /usr/lib/check_mk_agent/plugins/process_count.sh
   ```
   Die Ausgabe sollte so aussehen:
   ```
   <<<process_count>>>
   process_count 123
   ```

5. **Schritt 5**: Starte den Agenten neu:
   ```bash
   sudo systemctl restart check-mk-agent
   ```

**Reflexion**: Warum sind Datasource-Programme flexibel für benutzerdefinierte Überwachung? Nutze die Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/datasource_programs.html) und überlege, wie du weitere Metriken (z. B. Speicherauslastung) hinzufügen kannst.

### Übung 2: Integration in eine Checkmk-Site
**Ziel**: Integriere den localhost mit dem Datasource-Programm in Checkmk.

1. **Schritt 1**: Wechsle in die Checkmk-Site:
   ```bash
   sudo omd su mysite
   ```

2. **Schritt 2**: Stelle sicher, dass der localhost als Host konfiguriert ist:
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

3. **Schritt 3**: Erstelle eine Check-Regel für das Datasource-Programm:
   - Gehe zu `http://localhost/mysite`.
   - Navigiere zu `Setup > Services > Service monitoring rules > Custom checks`.
   - Erstelle eine Regel mit:
     - **Service description**: `Process Count`
     - **Check command**: `check_mk_active-process_count`
     - **Custom check parameters**:
       ```python
       {
           "levels": {"upper": (200, 300)}  # WARN bei 200, CRIT bei 300 Prozessen
       }
       ```
     - **Apply to**: `localhost`
   - Speichere und wende die Änderungen an.

4. **Schritt 4**: Führe eine Service-Discovery durch:
   ```bash
   cmk -I localhost
   ```
   Dies sollte einen Service wie `Process Count` erkennen. Aktiviere die Änderungen:
   ```bash
   cmk -O
   ```

5. **Schritt 5**: Überprüfe die Datasource-Daten in der Weboberfläche:
   - Navigiere zu `Monitor > All hosts > localhost`.
   - Du solltest einen Service wie `Process Count` mit Status (z. B. `OK`, `WARN`, `CRIT`) sehen, basierend auf der Prozessanzahl.

**Reflexion**: Wie vereinfachen Datasource-Programme die Überwachung benutzerdefinierter Metriken? Nutze `cmk -I --help` und überlege, wie du das Skript für andere Metriken (z. B. Festplatten-I/O) anpassen kannst.

### Übung 3: Fehlerbehebung und Spielerei
**Ziel**: Behebe Fehler beim Datasource-Programm und exportiere dessen Daten über die REST-API in Markdown und JSON, wobei der Hostname als Parameter übergeben wird.

1. **Schritt 1**: Teste die Fehlerbehebung:
   - Wenn der `Process Count`-Service nicht erscheint, überprüfe das Skript:
     ```bash
     sudo /usr/lib/check_mk_agent/plugins/process_count.sh
     ```
   - Überprüfe die Agent-Daten:
     ```bash
     cmk -d localhost
     ```
     Suche nach dem Abschnitt `<<<process_count>>>`.
   - Überprüfe Checkmk-Logs:
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
   nano export_datasource_api.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import requests
   import json
   import argparse

   def get_datasource_data_api(hostname, site="mysite", server="localhost", username="api_user", secret="mysecret123"):
       """Ruft Datasource-Daten für einen Host über die Checkmk REST-API ab."""
       try:
           url = f"http://{server}/{site}/check_mk/api/1.0/hosts/{hostname}/services"
           headers = {"Accept": "application/json"}
           response = requests.get(url, auth=(username, secret), headers=headers)
           response.raise_for_status()
           data = response.json()
           services = []
           for service in data.get("value", []):
               if "Process Count" in service.get("service_description", ""):
                   services.append({
                       "service_description": service["service_description"],
                       "state": service["service_state"],
                       "details": service.get("service_details", "")
                   })
           return services
       except requests.RequestException as e:
           print(f"Fehler beim Abrufen der Daten für {hostname}: {e}")
           return []

   def to_markdown(services, hostname, output_file="datasource_api_data.md"):
       """Exportiert Datasource-Daten als Markdown-Tabelle."""
       if not services:
           return "Keine Daten verfügbar."
       header = "| Service | Status | Details |\n|---|--------|---------|\n"
       rows = [f"| {s['service_description']} | {s['state']} | {s['details']} |" for s in services]
       markdown = header + "\n".join(rows)
       with open(output_file, 'w') as f:
           f.write(f"# Datasource-Daten für {hostname} (via REST-API)\n\n" + markdown)
       return markdown

   def to_json(services, hostname, output_file="datasource_api_data.json"):
       """Exportiert Datasource-Daten als JSON-Datei."""
       if not services:
           return "Keine Daten verfügbar."
       json_data = {"hostname": hostname, "datasource": services}
       with open(output_file, 'w') as f:
           json.dump(json_data, f, indent=4)
       return json.dumps(json_data, indent=4)

   if __name__ == "__main__":
       parser = argparse.ArgumentParser(description="Exportiert Checkmk-Datasource-Daten in Markdown und JSON.")
       parser.add_argument("hostname", help="Name des Hosts für die Datasource-Daten")
       args = parser.parse_args()
       hostname = args.hostname

       services = get_datasource_data_api(hostname)
       print("Markdown-Ausgabe:")
       print(to_markdown(services, hostname))
       print("\nJSON-Ausgabe:")
       print(to_json(services, hostname))
   ```
   Speichere und schließe. Ersetze `api_user` und `mysecret123` mit deinem API-Benutzer und Secret.

5. **Schritt 5**: Führe das Skript mit einem Hostnamen aus:
   ```bash
   sudo -u mysite python3 export_datasource_api.py localhost
   ```
   Überprüfe die Markdown-Ausgabe:
   ```bash
   cat datasource_api_data.md
   ```
   Die Markdown-Ausgabe könnte so aussehen:
   ```
   # Datasource-Daten für localhost (via REST-API)

   | Service | Status | Details |
   |---|--------|---------|
   | Process Count | OK | 123 processes running |
   ```
   Überprüfe die JSON-Ausgabe:
   ```bash
   cat datasource_api_data.json
   ```
   Die JSON-Ausgabe könnte so aussehen:
   ```
   {
       "hostname": "localhost",
       "datasource": [
           {
               "service_description": "Process Count",
               "state": "OK",
               "details": "123 processes running"
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
     json_data = {"hostname": hostname, "datasource": filtered_services}
     ```

**Reflexion**: Wie ermöglichen Datasource-Programme die Überwachung benutzerdefinierter Metriken? Nutze die Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/datasource_programs.html) und überlege, wie du das Skript für komplexere Metriken (z. B. CPU-Auslastung oder Netzwerkverkehr) erweitern kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Datasource-Programme und die REST-API zu verinnerlichen.
- **Sicheres Testen**: Nutze virtuelle Maschinen oder Container, um Änderungen risikofrei zu testen.
- **Fehler verstehen**: Lies Checkmk-Logs (`/opt/omd/sites/mysite/var/log/web.log`) und nutze die Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/datasource_programs.html).
- **Effiziente Entwicklung**: Nutze `cmk -I` für schnelle Service-Updates, Datasource-Programme für benutzerdefinierte Metriken und die REST-API für externe Integration.
- **Kombiniere Tools**: Integriere Datasource-Daten mit Redis für Caching, Ansible für automatisierte Skript-Installation oder APIs für externe Systeme.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Export in CSV oder Verarbeitung mehrerer Hosts über die API.

## Fazit
Mit diesen Übungen hast du ein Datasource-Programm in Checkmk erstellt, konfiguriert und in eine Checkmk-Site integriert, basierend auf der offiziellen Dokumentation (https://docs.checkmk.com/latest/de/datasource_programs.html). Die Spielerei zeigt, wie du Datasource-Daten über die REST-API abrufst und in Markdown- sowie JSON-Format exportierst, wobei der Hostname als Kommandozeilenparameter übergeben wird. Datasource-Programme bieten eine flexible Möglichkeit zur Überwachung benutzerdefinierter Metriken, und die REST-API erleichtert die Integration in externe Systeme. Vertiefe dein Wissen, indem du komplexere Datasource-Programme (z. B. für CPU-Auslastung oder Netzwerkmetriken), API-Schleifen für mehrere Hosts oder Integration mit CMDBs ausprobierst. Wenn du ein spezifisches Thema (z. B. komplexere Datasource-Programme oder CMDB-Integration) vertiefen möchtest, lass es mich wissen!

**Quelle**: Die Schritte basieren auf der offiziellen Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/datasource_programs.html und https://docs.checkmk.com/latest/de/rest_api.html).
