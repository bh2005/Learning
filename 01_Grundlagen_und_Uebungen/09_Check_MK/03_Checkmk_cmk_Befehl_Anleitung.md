# Praxisorientierte Anleitung: Der Checkmk-Befehl `cmk` für Anfänger

## Einführung
Der `cmk`-Befehl ist das zentrale Kommandozeilenwerkzeug von Checkmk, einer leistungsstarken Open-Source- und Enterprise-Software für IT-Monitoring. Es ermöglicht Administratoren, Hosts und Services zu verwalten, Service-Discoveries durchzuführen und Fehler zu beheben. Diese Anleitung führt Anfänger in die **Verwendung des `cmk`-Befehls** ein, mit Fokus auf **Grundlegende Befehle**, **Service-Discovery und Inventur**, **Fehlerbehebung** sowie **Automatisierung von Monitoring-Aufgaben**. Eine **Spielerei** zeigt, wie du die Ausgabe von `cmk` in eine Markdown-Tabelle umwandelst, um die Verbindung zu vorherigen Themen (z. B. Markdown-Ausgabe) herzustellen. Die Übungen sind für Nutzer mit grundlegenden Kenntnissen in Checkmk und Linux geeignet und verwenden die **Checkmk Raw Edition** (Open Source), da sie kostenlos ist.

**Voraussetzungen**:
- Ein Linux-System mit Checkmk Raw Edition installiert (z. B. Ubuntu 22.04 oder Debian 11).
- Ein Terminal (z. B. `bash` oder `zsh`) mit Zugriff auf eine Checkmk-Site (z. B. `mysite`).
- Root-Zugriff oder `sudo`-Rechte sowie Berechtigungen für die Checkmk-Site (z. B. als Benutzer `mysite`).
- Checkmk-Agent auf mindestens einem überwachten Host installiert.
- Grundkenntnisse in Linux (z. B. `sudo`, `cd`) und Checkmk (z. B. Konzept von Hosts und Services).
- Sichere Testumgebung (z. B. `/opt/omd/sites/mysite` oder eine virtuelle Maschine).
- Ein Webbrowser (z. B. Chrome, Firefox) für die Checkmk-Weboberfläche.

**Hinweis**: Diese Anleitung setzt voraus, dass ein Checkmk-Server bereits eingerichtet ist (siehe vorherige Anleitung). Falls nicht, installiere die Raw Edition und erstelle eine Site (`mysite`).

## Grundlegende Befehle
Hier sind die wichtigsten `cmk`-Befehle und Konzepte für Checkmk:

1. **Grundlegende `cmk`-Befehle**:
   - `cmk -I <hostname>`: Führt eine Service-Discovery für einen Host durch (findet neue Services).
   - `cmk -O`: Aktiviert Änderungen (übernimmt neue Services oder Konfigurationen).
   - `cmk -d <hostname>`: Ruft Agent-Daten eines Hosts ab.
   - `cmk -v`: Führt eine Überprüfung aller Hosts und Services aus (Verbose-Modus).
2. **Service-Discovery und Inventur**:
   - `cmk -II <hostname>`: Führt eine vollständige Inventur (inkl. Hardware/Software-Inventar) durch.
   - `cmk -D <hostname>`: Zeigt detaillierte Informationen zu einem Host (z. B. Services, Status).
   - `cmk --scan-parents <hostname>`: Erkennt Netzwerkabhängigkeiten (z. B. Switches).
3. **Fehlerbehebung**:
   - `cmk -v --debug`: Führt Checks mit Debugging-Informationen aus.
   - `cmk --check-discovery <hostname>`: Prüft die Service-Discovery auf Fehler.
   - `tail -f ~/var/log/web.log`: Zeigt Checkmk-Logs in Echtzeit.
4. **Nützliche Zusatzbefehle**:
   - `omd status mysite`: Zeigt den Status der Checkmk-Site.
   - `cmk --help`: Zeigt die Hilfe für `cmk`-Befehle.
   - `redis-cli`: Kann für erweiterte Integrationen genutzt werden (z. B. Caching von `cmk`-Ausgaben).

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Grundlegende `cmk`-Befehle
**Ziel**: Verwende `cmk`, um einen Host zu überwachen und grundlegende Checks durchzuführen.

1. **Schritt 1**: Stelle sicher, dass Checkmk läuft:
   ```bash
   sudo omd status mysite
   ```
   Wenn die Site nicht läuft, starte sie:
   ```bash
   sudo omd start mysite
   ```

2. **Schritt 2**: Wechsle in die Checkmk-Site:
   ```bash
   sudo -u mysite bash
   cd ~/etc/check_mk
   ```

3. **Schritt 3**: Füge einen Host manuell hinzu:
   - Bearbeite die Konfigurationsdatei:
     ```bash
     nano main.mk
     ```
     Füge folgenden Inhalt hinzu (ersetze `remote-host` und `192.168.1.100` durch den Namen und die IP des Hosts):
     ```python
     all_hosts += ["remote-host"]
     ipaddresses["remote-host"] = "192.168.1.100"
     ```
     Speichere und schließe.

4. **Schritt 4**: Führe eine Service-Discovery durch:
   ```bash
   cmk -I remote-host
   ```
   Aktiviere die Änderungen:
   ```bash
   cmk -O
   ```

5. **Schritt 5**: Überprüfe die Agent-Daten:
   ```bash
   cmk -d remote-host
   ```
   Du solltest die Rohdaten des Checkmk-Agenten sehen (z. B. CPU, Speicher, Dateisysteme).

6. **Schritt 6**: Führe eine Überprüfung aller Hosts aus:
   ```bash
   cmk -v
   ```
   Die Ausgabe zeigt den Status aller Hosts und Services (z. B. `OK`, `WARN`, `CRIT`).

**Reflexion**: Warum ist `cmk -O` für die Aktivierung von Änderungen wichtig? Nutze `cmk --help` und überlege, wie du mehrere Hosts gleichzeitig hinzufügen kannst.

### Übung 2: Service-Discovery und Inventur
**Ziel**: Nutze `cmk` für eine vollständige Service- und Hardware-Inventur.

1. **Schritt 1**: Führe eine vollständige Inventur für den Host durch:
   ```bash
   cmk -II remote-host
   ```
   Aktiviere die Änderungen:
   ```bash
   cmk -O
   ```

2. **Schritt 2**: Zeige detaillierte Informationen zum Host:
   ```bash
   cmk -D remote-host
   ```
   Die Ausgabe zeigt alle Services (z. B. `CPU utilization`, `Memory`) und deren Status.

3. **Schritt 3**: Überprüfe die Weboberfläche:
   - Gehe zu `http://<deine-server-ip>/mysite`.
   - Navigiere zu `Monitor > All hosts > remote-host`.
   - Du solltest neue Services und Inventurdaten (z. B. Hardware-Details wie CPU-Typ) sehen.

**Reflexion**: Wie verbessert die Inventur (`cmk -II`) die Übersicht über ein System? Nutze `cmk -D --help` und überlege, wie du spezifische Plugins (z. B. für Docker) aktivieren kannst.

### Übung 3: Fehlerbehebung und Spielerei
**Ziel**: Behebe Fehler mit `cmk` und exportiere Monitoring-Daten als Markdown.

1. **Schritt 1**: Teste die Fehlerbehebung:
   - Führe einen Check mit Debugging aus:
     ```bash
     cmk -v --debug remote-host
     ```
     Suche in der Ausgabe nach Fehlern (z. B. Verbindungsprobleme zum Agenten).
   - Überprüfe die Logs:
     ```bash
     tail -f ~/var/log/web.log
     ```

2. **Schritt 2**: Erstelle ein Python-Skript für die Markdown-Exportfunktion:
   ```bash
   nano export_cmk_data.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import subprocess
   import re

   def get_cmk_data(hostname):
       """Ruft Monitoring-Daten für einen Host mit cmk -D ab."""
       try:
           result = subprocess.run(['cmk', '-D', hostname], capture_output=True, text=True, check=True)
           output = result.stdout
           services = []
           current_service = None
           for line in output.splitlines():
               if line.startswith('  '):  # Service-Zeile
                   parts = line.strip().split()
                   if len(parts) >= 2:
                       service_name = parts[0]
                       status = parts[1]
                       services.append({'service': service_name, 'status': status})
           return services
       except subprocess.CalledProcessError as e:
           print(f"Fehler beim Abrufen der Daten für {hostname}: {e}")
           return []

   def to_markdown(hostname, output_file="cmk_services.md"):
       """Exportiert Monitoring-Daten als Markdown-Tabelle."""
       services = get_cmk_data(hostname)
       if not services:
           return "Keine Daten verfügbar."
       header = "| Service | Status |\n|---|--------|\n"
       rows = [f"| {s['service']} | {s['status']} |" for s in services]
       markdown = header + "\n".join(rows)
       with open(output_file, 'w') as f:
           f.write(f"# Monitoring-Daten für {hostname}\n\n" + markdown)
       return markdown

   if __name__ == "__main__":
       hostname = "remote-host"
       print(to_markdown(hostname))
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   sudo -u mysite python3 export_cmk_data.py
   ```
   Überprüfe die Markdown-Ausgabe:
   ```bash
   cat cmk_services.md
   ```
   Die Ausgabe könnte so aussehen:
   ```
   # Monitoring-Daten für remote-host

   | Service | Status |
   |---|--------|
   | CPU_utilization | OK |
   | Memory | OK |
   | Filesystem_/ | WARN |
   ```

4. **Spielerei**: Passe das Skript an, um nur Services mit `WARN` oder `CRIT` zu exportieren:
   - Ändere `to_markdown`, um `services` zu filtern:
     ```python
     rows = [f"| {s['service']} | {s['status']} |" for s in services if s['status'] in ['WARN', 'CRIT']]
     ```

**Reflexion**: Wie hilft `cmk --debug` bei der Fehlersuche? Nutze `cmk --help` und überlege, wie du `cmk` in einem Skript für automatisierte Checks nutzen kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um den `cmk`-Befehl zu verinnerlichen.
- **Sicheres Testen**: Nutze eine virtuelle Maschine oder Container, um Änderungen risikofrei zu testen.
- **Fehler verstehen**: Lies `cmk`-Ausgaben und Logs (`~/var/log/web.log`) genau und nutze die Checkmk-Dokumentation (https://docs.checkmk.com).
- **Effiziente Entwicklung**: Nutze `cmk -I` für schnelle Service-Updates, `cmk -D` für detaillierte Informationen und Skripte für Automatisierung.
- **Kombiniere Tools**: Integriere `cmk` mit Redis für Caching, Python für Datenverarbeitung oder Ansible für automatisierte Host-Konfiguration.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Integration mit Redis für Echtzeit-Daten oder Export in andere Formate (z. B. CSV).

## Fazit
Mit diesen Übungen hast du die grundlegenden und fortgeschrittenen Funktionen des `cmk`-Befehls gemeistert, einschließlich Service-Discovery, Inventur und Fehlerbehebung. Die Spielerei zeigt, wie du Monitoring-Daten als Markdown exportierst. Der `cmk`-Befehl ist ein mächtiges Werkzeug für die Kommandozeilenverwaltung von Checkmk, das die Weboberfläche ergänzt. Vertiefe dein Wissen, indem du fortgeschrittene Features wie verteiltes Monitoring oder benutzerdefinierte Checks mit `cmk` ausprobierst. Wenn du ein spezifisches Thema (z. B. benutzerdefinierte Checks oder Integration mit anderen Tools) vertiefen möchtest, lass es mich wissen!
