# Praxisorientierte Anleitung: Überwachung von Logdateien mit Checkmk und komplexen Regex-Mustern für Anfänger

## Einführung
Das Logfile Monitoring in Checkmk ermöglicht die Überwachung von Logdateien, um bestimmte Muster oder Fehler zu erkennen, z. B. in Systemlogs oder Anwendungslogs. Das `logwatch`-Plugin analysiert Logdateien und erzeugt Warnungen basierend auf definierten regulären Ausdrücken (Regex). Diese Anleitung führt Anfänger in die **Verwendung des Logfile Monitoring mit komplexen Regex-Mustern** ein, basierend auf der offiziellen Dokumentation (https://docs.checkmk.com/latest/de/monitoring_logfiles.html). Der Fokus liegt auf **Grundlagen der Logdateiüberwachung**, **Installation und Konfiguration des `logwatch`-Plugins auf dem localhost mit Regex**, **Integration in eine Checkmk-Site** sowie **Fehlerbehebung**. Eine **Spielerei** zeigt, wie du Logdateiüberwachungsdaten über die Checkmk-REST-API abrufst und in Markdown- sowie JSON-Format exportierst, wobei der Hostname als Kommandozeilenparameter übergeben wird, um die Konsistenz mit vorherigen Anleitungen zu wahren. Die Übungen verwenden die **Checkmk Raw Edition** (Open Source) und sind für Nutzer mit grundlegenden Kenntnissen in Linux, Python und Checkmk geeignet, wobei Regex-Kenntnisse hilfreich, aber nicht zwingend erforderlich sind.

**Voraussetzungen**:
- Ein Linux-System mit Checkmk Raw Edition installiert (z. B. Ubuntu 22.04 oder Debian 11).
- Ein Terminal (z. B. `bash` oder `zsh`) mit Root-Zugriff oder `sudo`-Rechten.
- Eine Checkmk-Site (z. B. `mysite`) eingerichtet (siehe vorherige Anleitung).
- Checkmk-Agent auf dem localhost installiert (siehe vorherige Anleitung).
- Python-Bibliotheken `requests`, `json` und `argparse` (installiere `requests` mit `pip install requests`; `json` und `argparse` sind Standard in Python 3).
- Ein API-Benutzer in Checkmk mit Zugriff auf die REST-API (siehe Dokumentation).
- Grundkenntnisse in Linux (z. B. `apt`, `systemctl`), Python (z. B. API-Anfragen, Kommandozeilenargumente) und Checkmk (z. B. Konzept von Hosts und Services). Grundkenntnisse in Regex sind hilfreich, werden aber erklärt.
- Sichere Testumgebung (z. B. `/opt/omd/sites/mysite` oder eine virtuelle Maschine).
- Ein Webbrowser (z. B. Chrome, Firefox) für die Checkmk-Weboberfläche.

**Hinweis**: Diese Anleitung setzt voraus, dass ein Checkmk-Server und der Checkmk-Agent auf dem localhost laufen. Das `logwatch`-Plugin wird konfiguriert, um `/var/log/syslog` mit komplexen Regex-Mustern zu überwachen.

## Grundlegende Begriffe und Befehle
Hier sind die wichtigsten Konzepte und Befehle für die Logdateiüberwachung mit `logwatch` in Checkmk:

1. **Grundlagen der Logdateiüberwachung**:
   - **logwatch-Plugin**: Überwacht Logdateien und sucht nach Mustern, die durch reguläre Ausdrücke definiert sind.
   - **Konfigurationsdatei**: `/etc/check_mk/logwatch.cfg` definiert, welche Logdateien überwacht werden.
   - **Regeln mit Regex**: Regeln in der Checkmk-Weboberfläche oder `/etc/check_mk/main.mk` verwenden Regex, um Muster wie `ERROR.*timeout` oder `CRITICAL.*\d+` zu erkennen und als `C` (CRITICAL), `W` (WARN) oder `O` (OK) zu klassifizieren.
2. **Installation und Konfiguration**:
   - `sudo cp ~/share/check_mk/agents/plugins/logwatch /usr/lib/check_mk_agent/plugins/`: Kopiert das Plugin.
   - `sudo nano /etc/check_mk/logwatch.cfg`: Konfiguriert zu überwachende Logdateien.
   - `sudo systemctl restart check-mk-agent`: Startet den Agenten neu.
3. **Integration in eine Checkmk-Site**:
   - `cmk -I localhost`: Führt eine Service-Discovery durch, um Logwatch-Services zu erkennen.
   - `cmk -O`: Aktiviert Änderungen.
4. **Integration mit externen Systemen**:
   - `curl -u <user>:<secret> http://<server>/<site>/check_mk/api/1.0/...`: Ruft Logwatch-Daten über die REST-API ab.
   - Python mit `requests`: Vereinfacht API-Anfragen für externe Integration.
5. **Nützliche Zusatzbefehle**:
   - `cmk -d localhost`: Ruft Agent-Daten, einschließlich Logwatch-Daten, ab.
   - `sudo /usr/lib/check_mk_agent/plugins/logwatch`: Testet das Plugin direkt.
   - `tail -f /opt/omd/sites/mysite/var/log/web.log`: Zeigt Checkmk-Logs in Echtzeit.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Installation und Konfiguration des `logwatch`-Plugins mit Regex
**Ziel**: Installiere und konfiguriere das `logwatch`-Plugin auf dem localhost mit komplexen Regex-Mustern.

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

2. **Schritt 2**: Kopiere das `logwatch`-Plugin:
   ```bash
   sudo mkdir -p /usr/lib/check_mk_agent/plugins
   sudo cp /opt/omd/sites/mysite/share/check_mk/agents/plugins/logwatch /usr/lib/check_mk_agent/plugins/
   sudo chmod +x /usr/lib/check_mk_agent/plugins/logwatch
   ```

3. **Schritt 3**: Erstelle eine Konfigurationsdatei für `logwatch` mit Regex:
   ```bash
   sudo mkdir -p /etc/check_mk
   sudo nano /etc/check_mk/logwatch.cfg
   ```
   Füge folgenden Inhalt ein, um `/var/log/syslog` mit komplexen Regex-Mustern zu überwachen:
   ```ini
   /var/log/syslog
   C ERROR.*timeout
   W WARNING.*\d{3}\s+ms
   O OK.*success
   ```
   **Erklärung**:
   - `ERROR.*timeout`: Erkennt Zeilen mit „ERROR“, gefolgt von beliebigen Zeichen und „timeout“ (z. B. „ERROR connection timeout“) als CRITICAL.
   - `WARNING.*\d{3}\s+ms`: Erkennt Zeilen mit „WARNING“, gefolgt von einer dreistelligen Zahl und „ms“ (z. B. „WARNING delay 500 ms“) als WARN.
   - `OK.*success`: Erkennt Zeilen mit „OK“, gefolgt von „success“ (z. B. „OK operation success“) als OK.
   Speichere und schließe.

4. **Schritt 4**: Teste das Plugin direkt:
   ```bash
   sudo /usr/lib/check_mk_agent/plugins/logwatch
   ```
   Die Ausgabe sollte Daten im Checkmk-Format anzeigen, z. B.:
   ```
   <<<logwatch>>>
   [[[/var/log/syslog]]]
   C Sep 08 08:00:00 localhost app: ERROR connection timeout
   W Sep 08 08:01:00 localhost app: WARNING delay 500 ms
   O Sep 08 08:02:00 localhost app: OK operation success
   ```

5. **Schritt 5**: Starte den Agenten neu:
   ```bash
   sudo systemctl restart check-mk-agent
   ```

**Reflexion**: Warum sind Regex-Muster mächtig für die Logdateiüberwachung? Nutze `man grep` oder Online-Ressourcen wie regex101.com, um weitere Regex-Muster (z. B. für IP-Adressen oder Zeitstempel) zu erstellen.

### Übung 2: Integration in eine Checkmk-Site mit Regex-Regeln
**Ziel**: Integriere den localhost mit Logwatch-Services in Checkmk und definiere Regex-Regeln in der Weboberfläche.

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
   Dies sollte einen Service wie `Log /var/log/syslog` erkennen. Aktiviere die Änderungen:
   ```bash
   cmk -O
   ```

4. **Schritt 4**: Konfiguriere Regex-basierte Logwatch-Regeln in der Weboberfläche:
   - Gehe zu `http://localhost/mysite`.
   - Navigiere zu `Setup > Services > Logfile patterns`.
   - Erstelle eine Regel für `/var/log/syslog` mit folgenden Mustern:
     - `CRITICAL: ERROR.*timeout` (z. B. für „ERROR connection timeout“).
     - `WARNING: WARNING.*\d{3}\s+ms` (z. B. für „WARNING delay 500 ms“).
     - `OK: OK.*success` (z. B. für „OK operation success“).
   - Setze die Regel auf `Apply to: localhost` und speichere.
   - Wende die Änderungen an (`Activate changes`).

5. **Schritt 5**: Überprüfe die Logwatch-Daten in der Weboberfläche:
   - Navigiere zu `Monitor > All hosts > localhost`.
   - Du solltest einen Service wie `Log /var/log/syslog` mit Status (z. B. `OK`, `WARN`, `CRIT`) sehen, basierend auf den erkannten Mustern.

**Reflexion**: Wie verbessern Regex-Muster die Präzision der Logüberwachung? Nutze die Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/monitoring_logfiles.html) und überlege, wie du Regex für spezifische Anwendungsfälle (z. B. Erkennung von HTTP-Fehlern) anpassen kannst.

### Übung 3: Fehlerbehebung und Spielerei
**Ziel**: Behebe Fehler bei der Logdateiüberwachung und exportiere Logwatch-Daten über die REST-API in Markdown und JSON, wobei der Hostname als Parameter übergeben wird.

1. **Schritt 1**: Teste die Fehlerbehebung:
   - Wenn der Logwatch-Service nicht erscheint, überprüfe das Plugin:
     ```bash
     sudo /usr/lib/check_mk_agent/plugins/logwatch
     ```
   - Überprüfe die Konfigurationsdatei:
     ```bash
     cat /etc/check_mk/logwatch.cfg
     ```
   - Überprüfe die Regex-Muster mit `grep`:
     ```bash
     grep -E 'ERROR.*timeout' /var/log/syslog
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
   nano export_logwatch_api.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import requests
   import json
   import argparse

   def get_logwatch_data_api(hostname, site="mysite", server="localhost", username="api_user", secret="mysecret123"):
       """Ruft Logwatch-Daten für einen Host über die Checkmk REST-API ab."""
       try:
           url = f"http://{server}/{site}/check_mk/api/1.0/hosts/{hostname}/services"
           headers = {"Accept": "application/json"}
           response = requests.get(url, auth=(username, secret), headers=headers)
           response.raise_for_status()
           data = response.json()
           services = []
           for service in data.get("value", []):
               if "Log " in service.get("service_description", ""):
                   services.append({
                       "service_description": service["service_description"],
                       "state": service["service_state"],
                       "details": service.get("service_details", "")
                   })
           return services
       except requests.RequestException as e:
           print(f"Fehler beim Abrufen der Daten für {hostname}: {e}")
           return []

   def to_markdown(services, hostname, output_file="logwatch_api_data.md"):
       """Exportiert Logwatch-Daten als Markdown-Tabelle."""
       if not services:
           return "Keine Daten verfügbar."
       header = "| Service | Status | Details |\n|---|--------|---------|\n"
       rows = [f"| {s['service_description']} | {s['state']} | {s['details']} |" for s in services]
       markdown = header + "\n".join(rows)
       with open(output_file, 'w') as f:
           f.write(f"# Logwatch-Daten für {hostname} (via REST-API)\n\n" + markdown)
       return markdown

   def to_json(services, hostname, output_file="logwatch_api_data.json"):
       """Exportiert Logwatch-Daten als JSON-Datei."""
       if not services:
           return "Keine Daten verfügbar."
       json_data = {"hostname": hostname, "logwatch": services}
       with open(output_file, 'w') as f:
           json.dump(json_data, f, indent=4)
       return json.dumps(json_data, indent=4)

   if __name__ == "__main__":
       parser = argparse.ArgumentParser(description="Exportiert Checkmk-Logwatch-Daten in Markdown und JSON.")
       parser.add_argument("hostname", help="Name des Hosts für die Logwatch-Daten")
       args = parser.parse_args()
       hostname = args.hostname

       services = get_logwatch_data_api(hostname)
       print("Markdown-Ausgabe:")
       print(to_markdown(services, hostname))
       print("\nJSON-Ausgabe:")
       print(to_json(services, hostname))
   ```
   Speichere und schließe. Ersetze `api_user` und `mysecret123` mit deinem API-Benutzer und Secret.

5. **Schritt 5**: Führe das Skript mit einem Hostnamen aus:
   ```bash
   sudo -u mysite python3 export_logwatch_api.py localhost
   ```
   Überprüfe die Markdown-Ausgabe:
   ```bash
   cat logwatch_api_data.md
   ```
   Die Markdown-Ausgabe könnte so aussehen:
   ```
   # Logwatch-Daten für localhost (via REST-API)

   | Service | Status | Details |
   |---|--------|---------|
   | Log /var/log/syslog | CRIT | Found 1 CRITICAL messages (e.g., "ERROR connection timeout") |
   ```
   Überprüfe die JSON-Ausgabe:
   ```bash
   cat logwatch_api_data.json
   ```
   Die JSON-Ausgabe könnte so aussehen:
   ```
   {
       "hostname": "localhost",
       "logwatch": [
           {
               "service_description": "Log /var/log/syslog",
               "state": "CRIT",
               "details": "Found 1 CRITICAL messages (e.g., \"ERROR connection timeout\")"
           }
       ]
   }
   ```

6. **Spielerei**: Passe das Skript an, um nur Services mit `CRIT` oder `WARN` zu exportieren:
   - Ändere `to_markdown` und `to_json`, um `services` zu filtern:
     ```python
     # In to_markdown
     rows = [f"| {s['service_description']} | {s['state']} | {s['details']} |" for s in services if s['state'] in ['CRIT', 'WARN']]
     # In to_json
     filtered_services = [s for s in services if s['state'] in ['CRIT', 'WARN']]
     json_data = {"hostname": hostname, "logwatch": filtered_services}
     ```

**Reflexion**: Wie verbessern Regex-Muster die Flexibilität und Präzision der Logdateiüberwachung? Nutze die Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/rest_api.html) und überlege, wie du Regex für spezifische Szenarien (z. B. Erkennung von HTTP-Statuscodes wie `404` oder IP-Adressen) erweitern kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um das `logwatch`-Plugin und Regex-Muster zu verinnerlichen.
- **Sicheres Testen**: Nutze virtuelle Maschinen oder Container, um Änderungen risikofrei zu testen. Teste Regex-Muster mit Tools wie `grep -E` oder regex101.com.
- **Fehler verstehen**: Lies Checkmk-Logs (`/opt/omd/sites/mysite/var/log/web.log`) und nutze die Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/monitoring_logfiles.html).
- **Effiziente Entwicklung**: Nutze `cmk -I` für schnelle Service-Updates, Regex für präzise Logmuster und die REST-API für externe Integration.
- **Kombiniere Tools**: Integriere Logwatch-Daten mit Redis für Caching, Ansible für automatisierte Plugin-Installation oder APIs für externe Systeme.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Export in CSV oder Verarbeitung mehrerer Logdateien/Hosts über die API.

## Fazit
Mit diesen Übungen hast du das `logwatch`-Plugin in Checkmk installiert, mit komplexen Regex-Mustern konfiguriert und in eine Checkmk-Site integriert, basierend auf der offiziellen Dokumentation (https://docs.checkmk.com/latest/de/monitoring_logfiles.html). Die Spielerei zeigt, wie du Logdateiüberwachungsdaten über die REST-API abrufst und in Markdown- sowie JSON-Format exportierst, wobei der Hostname als Kommandozeilenparameter übergeben wird. Regex-Muster erhöhen die Präzision und Flexibilität der Logüberwachung, und die REST-API erleichtert die Integration in externe Systeme. Vertiefe dein Wissen, indem du fortgeschrittene Regex-Muster (z. B. für HTTP-Fehler oder IP-Adressen), API-Schleifen für mehrere Hosts oder Integration mit CMDBs ausprobierst. Wenn du ein spezifisches Thema (z. B. Regex für bestimmte Anwendungsfälle oder CMDB-Integration) weiter vertiefen möchtest, lass es mich wissen!

**Quelle**: Die Schritte basieren auf der offiziellen Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/monitoring_logfiles.html und https://docs.checkmk.com/latest/de/rest_api.html).
