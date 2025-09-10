# Praxisorientierte Anleitung: Hardware- und Software-Inventarisierung in Checkmk mit Integration in externe Systeme

## Einführung
Die Hardware- und Software-Inventarisierung in Checkmk ermöglicht die Erfassung detaillierter Informationen über Hosts, wie CPU, Speicher, Betriebssystem oder installierte Software, die im Inventarbaum der Weboberfläche dargestellt werden. Diese Anleitung führt Anfänger in die **manuelle Installation und Nutzung der Inventarisierung** ein, basierend auf der offiziellen Dokumentation (https://docs.checkmk.com/latest/de/inventory.html#_installation_von_hand), mit einem Fokus auf die **Integration mit externen Systemen** (https://docs.checkmk.com/latest/de/inventory.html#external) über die Checkmk-REST-API. Der Fokus liegt auf **Grundlagen der Inventarisierung**, **manuelle Installation und Konfiguration auf dem localhost**, **Integration in eine Checkmk-Site** sowie **Fehlerbehebung**. Eine **Spielerei** zeigt, wie du Inventurdaten über die REST-API abrufst und in Markdown- sowie JSON-Format exportierst, wobei der Hostname als Kommandozeilenparameter übergeben wird. Die Übungen verwenden die **Checkmk Raw Edition** (Open Source) und sind für Nutzer mit grundlegenden Kenntnissen in Linux, Python und Checkmk geeignet.

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

**Hinweis**: Diese Anleitung setzt voraus, dass ein Checkmk-Server und der Checkmk-Agent auf dem localhost laufen. Die Spielerei nutzt die Checkmk-REST-API, um Inventurdaten abzurufen, und akzeptiert den Hostnamen als Kommandozeilenparameter, wie in der Dokumentation beschrieben (https://docs.checkmk.com/latest/de/inventory.html#external).

## Grundlegende Begriffe und Befehle
Hier sind die wichtigsten Konzepte und Befehle für die Inventarisierung in Checkmk:

1. **Grundlagen der Inventarisierung**:
   - **Inventarbaum**: Eine hierarchische Darstellung von Hardware- und Software-Daten (z. B. CPU, RAM, installierte Pakete).
   - **Checkmk-Agent-Plugins**: Erweitern den Agenten um Inventurdaten (z. B. `mk_inventory.linux` für Linux).
   - **HW/SW Inventory Service**: Ein Service, der Inventurdaten sammelt und in Checkmk speichert.
2. **Manuelle Installation und Konfiguration**:
   - `sudo cp ~/share/check_mk/agents/plugins/mk_inventory.linux /usr/lib/check_mk_agent/plugins/`: Kopiert das Inventar-Plugin.
   - `sudo chmod +x /usr/lib/check_mk_agent/plugins/mk_inventory.linux`: Macht das Plugin ausführbar.
   - `sudo systemctl restart check-mk-agent`: Startet den Agenten neu.
3. **Integration in eine Checkmk-Site**:
   - `cmk -I localhost`: Führt eine Service-Discovery durch, um den Inventar-Service zu erkennen.
   - `cmk -II localhost`: Führt eine vollständige Inventur durch.
   - `cmk -O`: Aktiviert Änderungen.
4. **Integration mit externen Systemen**:
   - `curl -u <user>:<secret> http://<server>/<site>/check_mk/api/1.0/...`: Ruft Inventurdaten über die REST-API ab.
   - Python mit `requests`: Vereinfacht API-Anfragen für externe Integration.
5. **Nützliche Zusatzbefehle**:
   - `cmk -d localhost`: Ruft Agent-Daten, einschließlich Inventurdaten, ab.
   - `sudo /usr/lib/check_mk_agent/plugins/mk_inventory.linux`: Testet das Inventar-Plugin direkt.
   - `tail -f /opt/omd/sites/mysite/var/log/web.log`: Zeigt Checkmk-Logs in Echtzeit.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Manuelle Installation des Inventar-Plugins
**Ziel**: Installiere das Inventar-Plugin manuell auf dem localhost.

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

2. **Schritt 2**: Kopiere das Inventar-Plugin (gemäß https://docs.checkmk.com/latest/de/inventory.html#_installation_von_hand):
   ```bash
   sudo mkdir -p /usr/lib/check_mk_agent/plugins
   sudo cp /opt/omd/sites/mysite/share/check_mk/agents/plugins/mk_inventory.linux /usr/lib/check_mk_agent/plugins/
   sudo chmod +x /usr/lib/check_mk_agent/plugins/mk_inventory.linux
   ```

3. **Schritt 3**: Teste das Plugin direkt:
   ```bash
   sudo /usr/lib/check_mk_agent/plugins/mk_inventory.linux
   ```
   Die Ausgabe sollte Inventurdaten im Checkmk-Format anzeigen, z. B.:
   ```
   <<<cmk_inventory>>>
   ...
   ```

4. **Schritt 4**: Starte den Agenten neu:
   ```bash
   sudo systemctl restart check-mk-agent
   ```

5. **Schritt 5**: Überprüfe die Agent-Daten:
   ```bash
   sudo -u mysite cmk -d localhost
   ```
   Suche nach dem Abschnitt `<<<cmk_inventory>>>` in der Ausgabe, der die Inventurdaten enthält.

**Reflexion**: Warum ist die manuelle Installation des Plugins nützlich? Nutze `man check-mk-agent` und überlege, wie du zusätzliche Inventar-Plugins (z. B. für Docker) installieren kannst.

### Übung 2: Integration in eine Checkmk-Site
**Ziel**: Integriere den localhost mit Inventar-Service in Checkmk.

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
   Dies sollte den `HW/SW Inventory`-Service erkennen. Aktiviere die Änderungen:
   ```bash
   cmk -O
   ```

4. **Schritt 4**: Führe eine vollständige Inventur durch:
   ```bash
   cmk -II localhost
   cmk -O
   ```

5. **Schritt 5**: Überprüfe die Inventurdaten in der Weboberfläche:
   - Gehe zu `http://localhost/mysite`.
   - Navigiere zu `Monitor > All hosts > localhost > HW/SW Inventory`.
   - Du solltest einen Inventarbaum mit Details wie CPU-Typ, RAM oder installierte Software sehen.

**Reflexion**: Wie verbessert die Inventarisierung die Systemverwaltung? Nutze `cmk -II --help` und überlege, wie du Inventurdaten für Berichte nutzen kannst.

### Übung 3: Fehlerbehebung und Spielerei
**Ziel**: Behebe Inventar-Fehler und exportiere Inventurdaten über die REST-API in Markdown und JSON, wobei der Hostname als Parameter übergeben wird.

1. **Schritt 1**: Teste die Fehlerbehebung:
   - Wenn der `HW/SW Inventory`-Service nicht erscheint, überprüfe das Plugin:
     ```bash
     sudo /usr/lib/check_mk_agent/plugins/mk_inventory.linux
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
   nano export_inventory_api.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import requests
   import json
   import argparse

   def get_inventory_data_api(hostname, site="mysite", server="localhost", username="api_user", secret="mysecret123"):
       """Ruft Inventurdaten für einen Host über die Checkmk REST-API ab."""
       try:
           url = f"http://{server}/{site}/check_mk/api/1.0/hosts/{hostname}/inventory"
           headers = {"Accept": "application/json"}
           response = requests.get(url, auth=(username, secret), headers=headers)
           response.raise_for_status()
           data = response.json()
           services = []
           for node in data.get("nodes", []):
               for attr in node.get("attributes", []):
                   services.append({
                       "inventory_item": f"{node['path']}: {attr['key']}={attr['value']}"
                   })
           return services
       except requests.RequestException as e:
           print(f"Fehler beim Abrufen der Daten für {hostname}: {e}")
           return []

   def to_markdown(services, hostname, output_file="inventory_api_data.md"):
       """Exportiert Inventurdaten als Markdown-Tabelle."""
       if not services:
           return "Keine Daten verfügbar."
       header = "| Inventar-Eintrag |\n|---|\n"
       rows = [f"| {s['inventory_item']} |" for s in services]
       markdown = header + "\n".join(rows)
       with open(output_file, 'w') as f:
           f.write(f"# Inventurdaten für {hostname} (via REST-API)\n\n" + markdown)
       return markdown

   def to_json(services, hostname, output_file="inventory_api_data.json"):
       """Exportiert Inventurdaten als JSON-Datei."""
       if not services:
           return "Keine Daten verfügbar."
       json_data = {"hostname": hostname, "inventory": services}
       with open(output_file, 'w') as f:
           json.dump(json_data, f, indent=4)
       return json.dumps(json_data, indent=4)

   if __name__ == "__main__":
       parser = argparse.ArgumentParser(description="Exportiert Checkmk-Inventurdaten in Markdown und JSON.")
       parser.add_argument("hostname", help="Name des Hosts für die Inventurdaten")
       args = parser.parse_args()
       hostname = args.hostname

       services = get_inventory_data_api(hostname)
       print("Markdown-Ausgabe:")
       print(to_markdown(services, hostname))
       print("\nJSON-Ausgabe:")
       print(to_json(services, hostname))
   ```
   Speichere und schließe. Ersetze `api_user` und `mysecret123` mit deinem API-Benutzer und Secret.

5. **Schritt 5**: Führe das Skript mit einem Hostnamen aus:
   ```bash
   sudo -u mysite python3 export_inventory_api.py localhost
   ```
   Überprüfe die Markdown-Ausgabe:
   ```bash
   cat inventory_api_data.md
   ```
   Die Markdown-Ausgabe könnte so aussehen:
   ```
   # Inventurdaten für localhost (via REST-API)

   | Inventar-Eintrag |
   |---|
   | Hardware/CPU: model=Intel(R) Core(TM) i5-9600K |
   | Software/OS: name=Ubuntu 22.04 |
   | Hardware/Memory: total=16 GB |
   ```
   Überprüfe die JSON-Ausgabe:
   ```bash
   cat inventory_api_data.json
   ```
   Die JSON-Ausgabe könnte so aussehen:
   ```
   {
       "hostname": "localhost",
       "inventory": [
           {
               "inventory_item": "Hardware/CPU: model=Intel(R) Core(TM) i5-9600K"
           },
           {
               "inventory_item": "Software/OS: name=Ubuntu 22.04"
           },
           {
               "inventory_item": "Hardware/Memory: total=16 GB"
           }
       ]
   }
   ```

6. **Spielerei**: Passe das Skript an, um nur Hardware-Daten zu exportieren:
   - Ändere `to_markdown` und `to_json`, um `services` zu filtern:
     ```python
     # In to_markdown
     rows = [f"| {s['inventory_item']} |" for s in services if 'Hardware' in s['inventory_item']]
     # In to_json
     filtered_services = [s for s in services if 'Hardware' in s['inventory_item']]
     json_data = {"hostname": hostname, "inventory": filtered_services}
     ```

**Reflexion**: Wie erleichtert die Übergabe des Hostnamens als Parameter die Automatisierung? Nutze die Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/rest_api.html) und überlege, wie du das Skript erweitern kannst, um mehrere Hosts in einer Schleife zu verarbeiten.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um die Inventarisierung und REST-API zu verinnerlichen.
- **Sicheres Testen**: Nutze virtuelle Maschinen oder Container, um Änderungen risikofrei zu testen.
- **Fehler verstehen**: Lies Checkmk-Logs (`/opt/omd/sites/mysite/var/log/web.log`) und nutze die Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/inventory.html#external).
- **Effiziente Entwicklung**: Nutze `cmk -II` für vollständige Inventuren, die REST-API für externe Integration und Skripte für Automatisierung.
- **Kombiniere Tools**: Integriere Inventurdaten mit Redis für Caching, Ansible für automatisierte Plugin-Installation oder APIs für CMDBs.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Export in CSV oder Verarbeitung mehrerer Hosts über die API.

## Fazit
Mit diesen Übungen hast du die Hardware- und Software-Inventarisierung in Checkmk manuell eingerichtet, konfiguriert und in eine Checkmk-Site integriert, basierend auf der offiziellen Dokumentation (https://docs.checkmk.com/latest/de/inventory.html). Die Spielerei zeigt, wie du Inventurdaten über die REST-API abrufst und in Markdown- sowie JSON-Format exportierst, wobei der Hostname als Kommandozeilenparameter übergeben wird, um die Flexibilität für externe Systeme zu erhöhen. Die Inventarisierung bietet wertvolle Einblicke in Systemdetails, und die REST-API erleichtert die Anbindung an externe Tools wie CMDBs oder Analyse-Plattformen. Vertiefe dein Wissen, indem du fortgeschrittene Features wie benutzerdefinierte Inventar-Plugins, CMDB-Synchronisation oder API-Schleifen für mehrere Hosts ausprobierst. Wenn du ein spezifisches Thema (z. B. API-Schleifen oder CMDB-Integration) vertiefen möchtest, lass es mich wissen!

**Quelle**: Die Schritte basieren auf der offiziellen Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/inventory.html und https://docs.checkmk.com/latest/de/rest_api.html).
