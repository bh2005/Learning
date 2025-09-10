# Praxisorientierte Anleitung: Dateiüberwachung mit dem `mk_filestats`-Plugin in Checkmk für Anfänger

## Einführung
Das `mk_filestats`-Plugin in Checkmk ermöglicht die Überwachung von Dateien und Verzeichnissen, z. B. deren Größe, Anzahl, Alter oder Änderungszeitpunkt. Es ist besonders nützlich für die Überwachung von Logdateien, Datenbanken oder Konfigurationsdateien. Diese Anleitung führt Anfänger in die **Verwendung des `mk_filestats`-Plugins** ein, basierend auf der offiziellen Dokumentation (https://docs.checkmk.com/latest/de/mk_filestats.html). Der Fokus liegt auf **Grundlagen der Dateiüberwachung**, **Installation und Konfiguration des Plugins auf dem localhost**, **Integration in eine Checkmk-Site** sowie **Fehlerbehebung**. Eine **Spielerei** zeigt, wie du Dateiüberwachungsdaten über die Checkmk-REST-API abrufst und in Markdown- sowie JSON-Format exportierst, wobei der Hostname als Kommandozeilenparameter übergeben wird, um die Konsistenz mit vorherigen Anleitungen zu wahren. Die Übungen verwenden die **Checkmk Raw Edition** (Open Source) und sind für Nutzer mit grundlegenden Kenntnissen in Linux, Python und Checkmk geeignet.

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

**Hinweis**: Diese Anleitung setzt voraus, dass ein Checkmk-Server und der Checkmk-Agent auf dem localhost laufen. Das `mk_filestats`-Plugin wird auf dem localhost konfiguriert, um Dateien (z. B. Logdateien) zu überwachen.

## Grundlegende Begriffe und Befehle
Hier sind die wichtigsten Konzepte und Befehle für die Dateiüberwachung mit `mk_filestats` in Checkmk:

1. **Grundlagen der Dateiüberwachung**:
   - **mk_filestats**: Ein Checkmk-Agent-Plugin, das Dateien und Verzeichnisse überwacht (z. B. Größe, Anzahl, Alter).
   - **Konfigurationsdatei**: `/etc/check_mk/filestats.cfg` definiert, welche Dateien oder Verzeichnisse überwacht werden.
   - **Service**: Jede überwachte Datei oder Gruppe erscheint als Service in Checkmk (z. B. `File group logs`).
2. **Installation und Konfiguration**:
   - `sudo cp ~/share/check_mk/agents/plugins/mk_filestats /usr/lib/check_mk_agent/plugins/`: Kopiert das Plugin.
   - `sudo nano /etc/check_mk/filestats.cfg`: Konfiguriert zu überwachende Dateien oder Verzeichnisse.
   - `sudo systemctl restart check-mk-agent`: Startet den Agenten neu.
3. **Integration in eine Checkmk-Site**:
   - `cmk -I localhost`: Führt eine Service-Discovery durch, um Filestats-Services zu erkennen.
   - `cmk -O`: Aktiviert Änderungen.
4. **Integration mit externen Systemen**:
   - `curl -u <user>:<secret> http://<server>/<site>/check_mk/api/1.0/...`: Ruft Service-Daten (inkl. Filestats) über die REST-API ab.
   - Python mit `requests`: Vereinfacht API-Anfragen für externe Integration.
5. **Nützliche Zusatzbefehle**:
   - `cmk -d localhost`: Ruft Agent-Daten, einschließlich Filestats-Daten, ab.
   - `sudo /usr/lib/check_mk_agent/plugins/mk_filestats`: Testet das Plugin direkt.
   - `tail -f /opt/omd/sites/mysite/var/log/web.log`: Zeigt Checkmk-Logs in Echtzeit.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Installation und Konfiguration des `mk_filestats`-Plugins
**Ziel**: Installiere und konfiguriere das `mk_filestats`-Plugin auf dem localhost.

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

2. **Schritt 2**: Kopiere das `mk_filestats`-Plugin:
   ```bash
   sudo mkdir -p /usr/lib/check_mk_agent/plugins
   sudo cp /opt/omd/sites/mysite/share/check_mk/agents/plugins/mk_filestats /usr/lib/check_mk_agent/plugins/
   sudo chmod +x /usr/lib/check_mk_agent/plugins/mk_filestats
   ```

3. **Schritt 3**: Erstelle eine Konfigurationsdatei für `mk_filestats`:
   ```bash
   sudo mkdir -p /etc/check_mk
   sudo nano /etc/check_mk/filestats.cfg
   ```
   Füge folgenden Inhalt ein, um Logdateien in `/var/log` zu überwachen:
   ```ini
   [file]
   path=/var/log/*.log
   output=count,size_sum
   ```
   Speichere und schließe. Dies überwacht die Anzahl und Gesamtgröße von `.log`-Dateien.

4. **Schritt 4**: Teste das Plugin direkt:
   ```bash
   sudo /usr/lib/check_mk_agent/plugins/mk_filestats
   ```
   Die Ausgabe sollte Daten im Checkmk-Format anzeigen, z. B.:
   ```
   <<<filestats>>>
   [[[/var/log/*.log]]]
   count 5
   size_sum 123456
   ```

5. **Schritt 5**: Starte den Agenten neu:
   ```bash
   sudo systemctl restart check-mk-agent
   ```

**Reflexion**: Warum ist die Konfigurationsdatei `/etc/check_mk/filestats.cfg` flexibel? Nutze die Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/mk_filestats.html) und überlege, wie du andere Metriken (z. B. `age_oldest`) hinzufügen kannst.

### Übung 2: Integration in eine Checkmk-Site
**Ziel**: Integriere den localhost mit Filestats-Services in Checkmk.

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

3. **Schritt 3**: Führe eine Service-Discovery durch:
   ```bash
   cmk -I localhost
   ```
   Dies sollte einen Service wie `File group /var/log/*.log` erkennen. Aktiviere die Änderungen:
   ```bash
   cmk -O
   ```

4. **Schritt 4**: Überprüfe die Filestats-Daten in der Weboberfläche:
   - Gehe zu `http://localhost/mysite`.
   - Navigiere zu `Monitor > All hosts > localhost`.
   - Du solltest einen Service wie `File group /var/log/*.log` mit Details wie Anzahl und Gesamtgröße der Dateien sehen.

5. **Schritt 5**: Überprüfe die Agent-Daten:
   ```bash
   cmk -d localhost
   ```
   Suche nach dem Abschnitt `<<<filestats>>>` in der Ausgabe, der die Dateiüberwachungsdaten enthält.

**Reflexion**: Wie vereinfacht `mk_filestats` die Überwachung von Dateien? Nutze `cmk -I --help` und überlege, wie du die Konfiguration für spezifische Dateien (z. B. `/var/log/syslog`) anpassen kannst.

### Übung 3: Fehlerbehebung und Spielerei
**Ziel**: Behebe Fehler bei der Dateiüberwachung und exportiere Filestats-Daten über die REST-API in Markdown und JSON, wobei der Hostname als Parameter übergeben wird.

1. **Schritt 1**: Teste die Fehlerbehebung:
   - Wenn der Filestats-Service nicht erscheint, überprüfe das Plugin:
     ```bash
     sudo /usr/lib/check_mk_agent/plugins/mk_filestats
     ```
   - Überprüfe die Konfigurationsdatei:
     ```bash
     cat /etc/check_mk/filestats.cfg
     ```
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
   nano export_filestats_api.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import requests
   import json
   import argparse

   def get_filestats_data_api(hostname, site="mysite", server="localhost", username="api_user", secret="mysecret123"):
       """Ruft Filestats-Daten für einen Host über die Checkmk REST-API ab."""
       try:
           url = f"http://{server}/{site}/check_mk/api/1.0/hosts/{hostname}/services"
           headers = {"Accept": "application/json"}
           response = requests.get(url, auth=(username, secret), headers=headers)
           response.raise_for_status()
           data = response.json()
           services = []
           for service in data.get("value", []):
               if "File group" in service.get("service_description", ""):
                   metrics = service.get("service_metrics", {})
                   services.append({
                       "service_description": service["service_description"],
                       "state": service["service_state"],
                       "metrics": metrics
                   })
           return services
       except requests.RequestException as e:
           print(f"Fehler beim Abrufen der Daten für {hostname}: {e}")
           return []

   def to_markdown(services, hostname, output_file="filestats_api_data.md"):
       """Exportiert Filestats-Daten als Markdown-Tabelle."""
       if not services:
           return "Keine Daten verfügbar."
       header = "| Service | Status | Metriken |\n|---|--------|---------|\n"
       rows = [f"| {s['service_description']} | {s['state']} | {s['metrics']} |" for s in services]
       markdown = header + "\n".join(rows)
       with open(output_file, 'w') as f:
           f.write(f"# Filestats-Daten für {hostname} (via REST-API)\n\n" + markdown)
       return markdown

   def to_json(services, hostname, output_file="filestats_api_data.json"):
       """Exportiert Filestats-Daten als JSON-Datei."""
       if not services:
           return "Keine Daten verfügbar."
       json_data = {"hostname": hostname, "filestats": services}
       with open(output_file, 'w') as f:
           json.dump(json_data, f, indent=4)
       return json.dumps(json_data, indent=4)

   if __name__ == "__main__":
       parser = argparse.ArgumentParser(description="Exportiert Checkmk-Filestats-Daten in Markdown und JSON.")
       parser.add_argument("hostname", help="Name des Hosts für die Filestats-Daten")
       args = parser.parse_args()
       hostname = args.hostname

       services = get_filestats_data_api(hostname)
       print("Markdown-Ausgabe:")
       print(to_markdown(services, hostname))
       print("\nJSON-Ausgabe:")
       print(to_json(services, hostname))
   ```
   Speichere und schließe. Ersetze `api_user` und `mysecret123` mit deinem API-Benutzer und Secret.

5. **Schritt 5**: Führe das Skript mit einem Hostnamen aus:
   ```bash
   sudo -u mysite python3 export_filestats_api.py localhost
   ```
   Überprüfe die Markdown-Ausgabe:
   ```bash
   cat filestats_api_data.md
   ```
   Die Markdown-Ausgabe könnte so aussehen:
   ```
   # Filestats-Daten für localhost (via REST-API)

   | Service | Status | Metriken |
   |---|--------|---------|
   | File group /var/log/*.log | OK | {'count': 5, 'size_sum': 123456} |
   ```
   Überprüfe die JSON-Ausgabe:
   ```bash
   cat filestats_api_data.json
   ```
   Die JSON-Ausgabe könnte so aussehen:
   ```
   {
       "hostname": "localhost",
       "filestats": [
           {
               "service_description": "File group /var/log/*.log",
               "state": "OK",
               "metrics": {
                   "count": 5,
                   "size_sum": 123456
               }
           }
       ]
   }
   ```

6. **Spielerei**: Passe das Skript an, um nur Services mit bestimmten Metriken (z. B. `count`) zu exportieren:
   - Ändere `to_markdown` und `to_json`, um `services` zu filtern:
     ```python
     # In to_markdown
     rows = [f"| {s['service_description']} | {s['state']} | {s['metrics']} |" for s in services if 'count' in s['metrics']]
     # In to_json
     filtered_services = [s for s in services if 'count' in s['metrics']]
     json_data = {"hostname": hostname, "filestats": filtered_services}
     ```

**Reflexion**: Wie erleichtert die Übergabe des Hostnamens als Parameter die Automatisierung der Dateiüberwachung? Nutze die Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/rest_api.html) und überlege, wie du das Skript erweitern kannst, um mehrere Hosts oder spezifische Dateigruppen zu verarbeiten.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um das `mk_filestats`-Plugin und die REST-API zu verinnerlichen.
- **Sicheres Testen**: Nutze virtuelle Maschinen oder Container, um Änderungen risikofrei zu testen.
- **Fehler verstehen**: Lies Checkmk-Logs (`/opt/omd/sites/mysite/var/log/web.log`) und nutze die Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/mk_filestats.html).
- **Effiziente Entwicklung**: Nutze `cmk -I` für schnelle Service-Updates, `mk_filestats` für flexible Dateiüberwachung und die REST-API für externe Integration.
- **Kombiniere Tools**: Integriere Filestats-Daten mit Redis für Caching, Ansible für automatisierte Plugin-Installation oder APIs für externe Systeme.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Export in CSV oder Verarbeitung mehrerer Dateigruppen über die API.

## Fazit
Mit diesen Übungen hast du das `mk_filestats`-Plugin in Checkmk installiert, konfiguriert und in eine Checkmk-Site integriert, basierend auf der offiziellen Dokumentation (https://docs.checkmk.com/latest/de/mk_filestats.html). Die Spielerei zeigt, wie du Dateiüberwachungsdaten über die REST-API abrufst und in Markdown- sowie JSON-Format exportierst, wobei der Hostname als Kommandozeilenparameter übergeben wird. Das Plugin bietet flexible Möglichkeiten zur Überwachung von Dateien und Verzeichnissen, und die REST-API erleichtert die Integration in externe Systeme. Vertiefe dein Wissen, indem du fortgeschrittene Features wie komplexe `filestats.cfg`-Konfigurationen, API-Schleifen für mehrere Hosts oder Integration mit CMDBs ausprobierst. Wenn du ein spezifisches Thema (z. B. erweiterte Filestats-Konfigurationen oder CMDB-Integration) vertiefen möchtest, lass es mich wissen!

**Quelle**: Die Schritte basieren auf der offiziellen Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/mk_filestats.html und https://docs.checkmk.com/latest/de/rest_api.html).
