# Praxisorientierte Anleitung: Enterprise Monitoring mit Checkmk für Anfänger

## Einführung
Checkmk ist eine führende Open-Source- und Enterprise-Software für IT-Monitoring, die Server, Netzwerke, Anwendungen, Clouds und Container überwacht. Mit über 2.000 Plugins und einer skalierbaren Architektur ist sie ideal für Unternehmensumgebungen. Diese Anleitung führt Anfänger in **Enterprise Monitoring mit Checkmk** ein, mit Fokus auf **Grundlagen von Checkmk**, **Einrichtung eines Checkmk-Servers**, **Hinzufügen von Hosts und Services** sowie **Automatisierung von Monitoring-Aufgaben**. Eine **Spielerei** zeigt, wie du Monitoring-Daten als Markdown-Tabelle exportierst, um eine Verbindung zu vorherigen Themen (z. B. Markdown-Ausgabe) herzustellen. Durch praktische Übungen lernst du, ein Monitoring-System für eine Unternehmensumgebung aufzusetzen.

**Voraussetzungen**:
- Ein Linux-System.
- Ein Terminal (z. B. `bash` oder `zsh`).
- Root-Zugriff oder `sudo`-Rechte.
- Internetzugang für den Download von Checkmk-Paketen.
- Grundkenntnisse in Linux (z. B. `apt`, `systemctl`) und Netzwerkkonzepten (z. B. IP-Adressen, DNS).
- Sichere Testumgebung (z. B. `/opt/checkmk` oder eine virtuelle Maschine).
- Ein Webbrowser (z. B. Chrome, Firefox) für die Checkmk-Weboberfläche.

**Hinweis**: Diese Anleitung verwendet die **Checkmk Raw Edition** (Open Source), da sie kostenlos ist und für Lernzwecke ideal ist. Die Enterprise Edition bietet zusätzliche Features wie verteiltes Monitoring und Agent Bakery, die hier optional erwähnt werden.[](https://de.wikipedia.org/wiki/Checkmk)[](https://en.wikipedia.org/wiki/Checkmk)

## Grundlegende Begriffe und Befehle
Hier sind die wichtigsten Konzepte und Befehle für Checkmk:

1. **Grundlagen von Checkmk**:
   - **Host**: Ein Gerät oder eine Instanz (z. B. Server, Switch, Container) mit einer IP-Adresse oder logischem Namen. Status: UP, DOWN, UNREACH, PEND.[](https://docs.checkmk.com/latest/en/intro_setup_monitor.html)
   - **Service**: Eine überwachte Komponente eines Hosts (z. B. CPU-Auslastung, Dateisystem). Status: OK, WARN, CRIT, UNKNOWN, PEND.[](https://docs.checkmk.com/latest/en/intro_setup_monitor.html)
   - **Checkmk-Agent**: Ein Programm, das Daten von einem Host sammelt (z. B. für Linux/Windows).[](https://docs.checkmk.com/latest/en/wato_monitoringagents.html)
   - **Auto-Discovery**: Automatische Erkennung von Hosts und Services mit relevanten Metriken.[](https://checkmk.com/product/features)
2. **Einrichtung eines Checkmk-Servers**:
   - `sudo apt install check-mk-raw`: Installiert die Checkmk Raw Edition.
   - `omd create <site>`: Erstellt eine Checkmk-Site (Instanz).
   - `omd start <site>`: Startet die Site.
3. **Hinzufügen von Hosts und Services**:
   - `Setup > Hosts`: Fügt Hosts über die Weboberfläche hinzu.
   - `cmk -I <hostname>`: Führt eine Service-Discovery durch.
   - `cmk -O`: Aktiviert Änderungen.
4. **Nützliche Zusatzbefehle**:
   - `omd status <site>`: Zeigt den Status der Checkmk-Site.
   - `redis-cli`: Kann für erweiterte Integrationen genutzt werden (z. B. Caching von Monitoring-Daten).
   - `cmk -d <hostname>`: Ruft Agent-Daten eines Hosts ab.[](https://docs.checkmk.com/latest/en/wato_monitoringagents.html)

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Einrichtung eines Checkmk-Servers
**Ziel**: Installiere und starte einen Checkmk-Server auf Ubuntu.

1. **Schritt 1**: Aktualisiere das System und installiere Abhängigkeiten:
   ```bash
   sudo apt update && sudo apt upgrade -y
   sudo apt install -y wget
   ```

2. **Schritt 2**: Lade die Checkmk Raw Edition herunter (ersetze `2.4.0` durch die aktuelle Version, siehe https://checkmk.com/download):
   ```bash
   wget https://download.checkmk.com/checkmk/2.4.0/check-mk-raw-2.4.0_0.focal_amd64.deb
   ```

3. **Schritt 3**: Installiere Checkmk:
   ```bash
   sudo apt install -y ./check-mk-raw-2.4.0_0.focal_amd64.deb
   ```

4. **Schritt 4**: Erstelle eine Checkmk-Site (z. B. `mysite`):
   ```bash
   sudo omd create mysite
   sudo omd start mysite
   ```

5. **Schritt 5**: Öffne die Weboberfläche:
   - Gehe im Browser zu `http://<deine-server-ip>/mysite`.
   - Melde dich mit Benutzername `cmkadmin` und dem generierten Passwort an (siehe Ausgabe von `omd create mysite`).
   - Du solltest die Checkmk-Oberfläche sehen.

**Reflexion**: Warum ist die Verwendung von Sites in Checkmk nützlich? Überprüfe `omd help` und überlege, wie du mehrere Sites für unterschiedliche Abteilungen einrichten kannst.

### Übung 2: Hinzufügen von Hosts und Services
**Ziel**: Füge einen Host hinzu und überwache dessen Services.

1. **Schritt 1**: Installiere den Checkmk-Agent auf einem zu überwachenden Linux-Host (z. B. einem zweiten Ubuntu-Server):
   ```bash
   ssh user@remote-host
   sudo apt update
   wget https://download.checkmk.com/checkmk/2.4.0/check-mk-agent_2.4.0p10-1_all.deb
   sudo apt install -y ./check-mk-agent_2.4.0p10-1_all.deb
   ```
   Prüfe, ob der Agent läuft:
   ```bash
   sudo systemctl status check-mk-agent
   ```

2. **Schritt 2**: Füge den Host in Checkmk hinzu:
   - Gehe in der Weboberfläche zu `Setup > Hosts > Add host`.
   - Gib den Hostnamen (z. B. `remote-host`) und die IP-Adresse ein.
   - Wähle `Checkmk agent` als Datenquelle.
   - Speichere und klicke auf `Save & go to service configuration`.

3. **Schritt 3**: Führe eine Service-Discovery durch:
   - Klicke auf `Discover services` und dann auf `Accept all`, um alle erkannten Services (z. B. CPU, Dateisysteme) hinzuzufügen.
   - Aktiviere die Änderungen mit `Activate changes`.

4. **Schritt 4**: Überprüfe die Services in der Weboberfläche:
   - Gehe zu `Monitor > All hosts` und klicke auf `remote-host`.
   - Du solltest Services wie `CPU utilization`, `Memory` oder `Filesystem /` mit Status `OK` oder `WARN` sehen.

**Reflexion**: Warum ist die Auto-Discovery von Checkmk effizient? Nutze `cmk --help` und überlege, wie du spezifische Services (z. B. nur CPU) überwachen kannst.[](https://docs.checkmk.com/latest/en/wato_services.html)

### Übung 3: Automatisierung und Spielerei
**Ziel**: Automatisiere die Service-Discovery und exportiere Monitoring-Daten als Markdown.

1. **Schritt 1**: Aktiviere automatische Service-Discovery:
   - Gehe in der Weboberfläche zu `Setup > Services > Periodic service discovery`.
   - Erstelle eine Regel mit `Automatically update service configuration` und setze das Intervall auf 2 Stunden.
   - Speichere und aktiviere die Änderungen.

2. **Schritt 2**: Erstelle ein Python-Skript, um Monitoring-Daten als Markdown zu exportieren:
   ```bash
   nano export_monitoring.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import json
   import subprocess
   import re

   def get_monitoring_data(hostname):
       """Ruft Monitoring-Daten für einen Host ab."""
       try:
           # Führe cmk -d aus, um Agent-Daten zu holen
           result = subprocess.run(['cmk', '-d', hostname], capture_output=True, text=True, check=True)
           output = result.stdout
           # Parse relevante Daten (vereinfachtes Beispiel)
           services = []
           for line in output.splitlines():
               if line.startswith('<<<') and '>>>' in line:
                   service_name = line.strip('<<<>>>')
               elif re.match(r'\w+.*\d+', line):  # Einfache Regex für Metriken
                   services.append({'service': service_name, 'data': line.strip()})
           return services
       except subprocess.CalledProcessError as e:
           print(f"Fehler beim Abrufen der Daten für {hostname}: {e}")
           return []

   def to_markdown(hostname, output_file="monitoring.md"):
       """Exportiert Monitoring-Daten als Markdown-Tabelle."""
       services = get_monitoring_data(hostname)
       if not services:
           return "Keine Daten verfügbar."
       header = "| Service | Daten |\n|---|------|\n"
       rows = [f"| {s['service']} | {s['data']} |" for s in services]
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
   sudo -u mysite python3 export_monitoring.py
   ```
   Überprüfe die Markdown-Ausgabe:
   ```bash
   cat monitoring.md
   ```
   Die Ausgabe könnte so aussehen (abhängig von den Services):
   ```
   # Monitoring-Daten für remote-host

   | Service | Daten |
   |---|------|
   | check_mk | Version: 2.4.0p10 AgentOS: linux |
   | cpu | 0.12 0.08 0.05 1/1 |
   | memory | used_mb: 1024 total_mb: 2048 |
   ```

4. **Spielerei**: Passe das Skript an, um spezifische Services (z. B. CPU-Auslastung) zu filtern:
   - Ändere die Regex in `get_monitoring_data` oder füge Logik hinzu, um nur `cpu`-Daten zu exportieren.

**Reflexion**: Wie vereinfacht die Verwendung von Python mit Checkmk die Datenextraktion? Nutze `cmk --help` und überlege, wie du die Ausgabe mit Redis für Echtzeit-Caching kombinieren kannst.[](https://docs.checkmk.com/latest/en/wato_monitoringagents.html)

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Checkmk-Konzepte zu verinnerlichen.
- **Sicheres Testen**: Nutze eine virtuelle Maschine oder Container, um Änderungen risikofrei zu testen.
- **Fehler verstehen**: Lies Checkmk-Logs (`~/var/log/web.log`) und nutze die Dokumentation (https://docs.checkmk.com).
- **Effiziente Entwicklung**: Nutze Auto-Discovery für schnelle Konfiguration, Skripte für Automatisierung und die Weboberfläche für Übersicht.
- **Kombiniere Tools**: Integriere Checkmk mit Tools wie Redis für Caching oder Ansible für automatisierte Bereitstellung.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Integration von Prometheus oder benutzerdefinierten Dashboards.

## Fazit
Mit diesen Übungen hast du ein grundlegendes Enterprise-Monitoring mit Checkmk aufgebaut, einen Server eingerichtet und Hosts überwacht. Die Spielerei zeigt, wie du Monitoring-Daten als Markdown exportierst. Checkmk’s Stärke liegt in seiner Skalierbarkeit und Auto-Discovery, die komplexe Umgebungen vereinfachen. Vertiefe dein Wissen, indem du fortgeschrittene Features wie verteiltes Monitoring oder die Agent Bakery (Enterprise Edition) ausprobierst. Wenn du ein spezifisches Thema (z. B. verteiltes Monitoring oder Prometheus-Integration) vertiefen möchtest, lass es mich wissen![](https://checkmk.com/product/checkmk-enterprise)[](https://checkmk.com/product/features)[](https://checkmk.com/product/container-monitoring)
