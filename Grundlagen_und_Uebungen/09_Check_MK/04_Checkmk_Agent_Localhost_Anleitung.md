# Praxisorientierte Anleitung: Installation eines Checkmk-Agenten auf dem localhost für Anfänger

## Einführung
Der Checkmk-Agent ist ein leichtgewichtiges Programm, das auf einem zu überwachenden Host installiert wird, um Systemdaten wie CPU, Speicher oder Dateisysteme an einen Checkmk-Server zu senden. Diese Anleitung führt Anfänger in die **Installation eines Checkmk-Agenten auf dem localhost** ein, mit Fokus auf **Installation des Agenten**, **Konfiguration für localhost-Überwachung**, **Integration mit einer Checkmk-Site** sowie **Fehlerbehebung**. Eine **Spielerei** zeigt, wie du die Agent-Daten als Markdown-Tabelle exportierst, um die Verbindung zu vorherigen Themen (z. B. Markdown-Ausgabe) herzustellen. Die Übungen sind für Nutzer mit grundlegenden Kenntnissen in Linux und Checkmk geeignet und verwenden die **Checkmk Raw Edition** (Open Source). Die Schritte folgen der offiziellen Dokumentation (https://docs.checkmk.com/latest/de/agent_linux.html#install) und korrigieren den Fehler in Schritt 2 der vorherigen Anleitung.

**Voraussetzungen**:
- Ein Linux-System mit Checkmk Raw Edition installiert (z. B. Ubuntu 22.04 oder Debian 11).
- Ein Terminal (z. B. `bash` oder `zsh`) mit Root-Zugriff oder `sudo`-Rechten.
- Eine Checkmk-Site (z. B. `mysite`) eingerichtet (siehe vorherige Anleitung).
- Internetzugang oder Zugriff auf die Checkmk-Weboberfläche für den Agent-Download.
- Grundkenntnisse in Linux (z. B. `apt`, `systemctl`) und Checkmk (z. B. Konzept von Hosts und Services).
- Sichere Testumgebung (z. B. `/opt/omd/sites/mysite` oder eine virtuelle Maschine).
- Ein Webbrowser (z. B. Chrome, Firefox) für die Checkmk-Weboberfläche.

**Hinweis**: Diese Anleitung setzt voraus, dass ein Checkmk-Server auf dem localhost läuft. Der Agent wird ebenfalls auf dem localhost installiert, um das System selbst zu überwachen. Der korrigierte Schritt 2 in Übung 1 verwendet den Download aus der Checkmk-Site oder der REST-API, wie in der offiziellen Dokumentation empfohlen.

## Grundlegende Befehle
Hier sind die wichtigsten Befehle und Konzepte für den Checkmk-Agenten:

1. **Installation des Checkmk-Agenten**:
   - `wget http://<server>/<site>/check_mk/agents/check-mk-agent_*.deb`: Lädt das Agent-Paket von der Checkmk-Site herunter.
   - `sudo apt install ./check-mk-agent_*.deb`: Installiert den Agenten.
   - `sudo systemctl enable check-mk-agent`: Aktiviert den Agenten beim Systemstart.
2. **Konfiguration für localhost-Überwachung**:
   - `sudo nano /etc/check_mk/check_mk_agent.local`: Konfiguriert benutzerdefinierte Checks.
   - `sudo systemctl restart check-mk-agent`: Startet den Agenten neu nach Konfigurationsänderungen.
3. **Integration mit einer Checkmk-Site**:
   - `cmk -I localhost`: Führt eine Service-Discovery für den localhost durch.
   - `cmk -O`: Aktiviert Änderungen in der Checkmk-Site.
   - `cmk -d localhost`: Ruft Agent-Daten vom localhost ab.
4. **Nützliche Zusatzbefehle**:
   - `sudo systemctl status check-mk-agent`: Überprüft den Status des Agenten.
   - `telnet localhost 6556`: Testet die Verbindung zum Agenten (Standardport: 6556).
   - `tail -f /opt/omd/sites/mysite/var/log/web.log`: Zeigt Checkmk-Logs in Echtzeit.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Installation des Checkmk-Agenten
**Ziel**: Installiere den Checkmk-Agenten auf dem localhost gemäß der offiziellen Dokumentation.

1. **Schritt 1**: Stelle sicher, dass Checkmk läuft:
   ```bash
   sudo omd status mysite
   ```
   Wenn die Site nicht läuft, starte sie:
   ```bash
   sudo omd start mysite
   ```

2. **Schritt 2**: Lade den Checkmk-Agenten von der Checkmk-Site herunter (korrigierter Schritt):
   - Navigiere in der Checkmk-Weboberfläche zu `Setup > Agents > Linux`.
   - Kopiere den Download-Link für das DEB-Paket (z. B. `check-mk-agent_2.4.0p10-1_all.deb`) aus dem Abschnitt „Packaged Agents“.
   - Alternativ, lade das Paket direkt mit `wget` von der Site:
     ```bash
     wget http://localhost/mysite/check_mk/agents/check-mk-agent_2.4.0p10-1_all.deb
     ```
     **Hinweis**: Ersetze `localhost` durch die IP-Adresse deines Servers, falls nötig, und `mysite` durch den Namen deiner Site. Stelle sicher, dass die Version (z. B. `2.4.0p10`) mit deiner Checkmk-Version übereinstimmt. Du kannst den genauen Link auch über die REST-API abrufen (siehe Dokumentation).

3. **Schritt 3**: Installiere den Agenten:
   ```bash
   sudo apt install -y ./check-mk-agent_2.4.0p10-1_all.deb
   ```

4. **Schritt 4**: Überprüfe den Agenten-Status:
   ```bash
   sudo systemctl status check-mk-agent
   ```
   Stelle sicher, dass der Dienst `active (running)` ist.

5. **Schritt 5**: Teste die Agent-Verbindung:
   ```bash
   telnet localhost 6556
   ```
   Du solltest eine Verbindung herstellen können und Agent-Daten (z. B. `<<<check_mk>>>`) sehen. Beende mit `Ctrl+C`.

**Reflexion**: Warum ist der Download von der Checkmk-Site sicherer als von der allgemeinen Download-Seite? Nutze `man check-mk-agent` und überlege, wie du die Agent-Version mit `cmk-agent-ctl --version` überprüfen kannst.

### Übung 2: Konfiguration für localhost-Überwachung
**Ziel**: Konfiguriere den Agenten und füge den localhost als Host in Checkmk hinzu.

1. **Schritt 1**: Erstelle eine benutzerdefinierte Konfiguration (optional):
   ```bash
   sudo mkdir -p /etc/check_mk
   sudo nano /etc/check_mk/check_mk_agent.local
   ```
   Füge einen einfachen benutzerdefinierten Check hinzu (z. B. für eine Prozessanzahl):
   ```bash
   #!/bin/bash
   echo '<<<local>>>'
   echo "0 Process_Count processes=$(ps aux | wc -l) Number of running processes"
   ```
   Speichere und schließe. Setze Berechtigungen:
   ```bash
   sudo chmod +x /etc/check_mk/check_mk_agent.local
   ```

2. **Schritt 2**: Starte den Agenten neu:
   ```bash
   sudo systemctl restart check-mk-agent
   ```

3. **Schritt 3**: Wechsle in die Checkmk-Site:
   ```bash
   sudo omd su mysite
   ```

4. **Schritt 4**: Füge den localhost als Host hinzu:
   - Bearbeite die Konfigurationsdatei:
     ```bash
     nano ~/etc/check_mk/main.mk
     ```
     Füge folgenden Inhalt hinzu:
     ```python
     all_hosts += ["localhost"]
     ipaddresses["localhost"] = "127.0.0.1"
     ```
     Speichere und schließe.

5. **Schritt 5**: Führe eine Service-Discovery durch:
   ```bash
   cmk -I localhost
   cmk -O
   ```

6. **Schritt 6**: Überprüfe die Agent-Daten:
   ```bash
   cmk -d localhost
   ```
   Du solltest Daten wie `<<<check_mk>>>`, `<<<cpu>>>` oder `<<<local>>>` sehen.

**Reflexion**: Wie vereinfacht die Konfigurationsdatei `/etc/check_mk/check_mk_agent.local` benutzerdefinierte Checks? Nutze `cmk -d --help` und überlege, wie du zusätzliche Plugins (z. B. für Docker) aktivieren kannst.

### Übung 3: Integration und Spielerei
**Ziel**: Integriere den localhost in die Checkmk-Site und exportiere Agent-Daten als Markdown.

1. **Schritt 1**: Überprüfe die Überwachung in der Weboberfläche:
   - Gehe zu `http://localhost/mysite`.
   - Navigiere zu `Monitor > All hosts > localhost`.
   - Du solltest Services wie `CPU utilization`, `Memory` und `Process_Count` (vom benutzerdefinierten Check) sehen.

2. **Schritt 2**: Erstelle ein Python-Skript für die Markdown-Exportfunktion:
   ```bash
   nano export_agent_data.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import subprocess
   import re

   def get_agent_data(hostname):
       """Ruft Agent-Daten für einen Host mit cmk -d ab."""
       try:
           result = subprocess.run(['cmk', '-d', hostname], capture_output=True, text=True, check=True)
           output = result.stdout
           services = []
           current_service = None
           for line in output.splitlines():
               if line.startswith('<<<') and '>>>' in line:
                   current_service = line.strip('<<<>>>')
               elif current_service and re.match(r'\w+.*\d+', line):
                   services.append({'service': current_service, 'data': line.strip()})
           return services
       except subprocess.CalledProcessError as e:
           print(f"Fehler beim Abrufen der Daten für {hostname}: {e}")
           return []

   def to_markdown(hostname, output_file="agent_data.md"):
       """Exportiert Agent-Daten als Markdown-Tabelle."""
       services = get_agent_data(hostname)
       if not services:
           return "Keine Daten verfügbar."
       header = "| Service | Daten |\n|---|------|\n"
       rows = [f"| {s['service']} | {s['data']} |" for s in services]
       markdown = header + "\n".join(rows)
       with open(output_file, 'w') as f:
           f.write(f"# Agent-Daten für {hostname}\n\n" + markdown)
       return markdown

   if __name__ == "__main__":
       hostname = "localhost"
       print(to_markdown(hostname))
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   sudo -u mysite python3 export_agent_data.py
   ```
   Überprüfe die Markdown-Ausgabe:
   ```bash
   cat agent_data.md
   ```
   Die Ausgabe könnte so aussehen (abhängig von den Services):
   ```
   # Agent-Daten für localhost

   | Service | Daten |
   |---|------|
   | check_mk | Version: 2.4.0p10 AgentOS: linux |
   | cpu | 0.12 0.08 0.05 1/1 |
   | local | 0 Process_Count processes=123 Number of running processes |
   ```

4. **Spielerei**: Passe das Skript an, um nur benutzerdefinierte Checks (z. B. `local`) zu exportieren:
   - Ändere `to_markdown`, um `services` zu filtern:
     ```python
     rows = [f"| {s['service']} | {s['data']} |" for s in services if s['service'] == 'local']
     ```

**Reflexion**: Wie verbessert die direkte Installation von der Checkmk-Site die Sicherheit? Nutze `cmk-agent-ctl status` und überlege, wie du TLS-Verschlüsselung für den Agenten aktivieren kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um den Checkmk-Agenten zu verinnerlichen.
- **Sicheres Testen**: Nutze virtuelle Maschinen oder Container, um Änderungen risikofrei zu testen.
- **Fehler verstehen**: Lies Logs (`/opt/omd/sites/mysite/var/log/web.log`) und nutze die Checkmk-Dokumentation (https://docs.checkmk.com).
- **Effiziente Entwicklung**: Nutze `cmk -I` für schnelle Service-Updates, benutzerdefinierte Checks für Flexibilität und Skripte für Automatisierung.
- **Kombiniere Tools**: Integriere den Agenten mit Redis für Echtzeit-Caching oder Ansible für automatisierte Installationen.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Integration mit Redis oder Export in andere Formate (z. B. JSON).

## Fazit
Mit diesen Übungen hast du den Checkmk-Agenten auf dem localhost installiert, konfiguriert und in eine Checkmk-Site integriert, wobei der korrigierte Schritt 2 die Best Practices der offiziellen Dokumentation (https://docs.checkmk.com/latest/de/agent_linux.html#install) widerspiegelt. Die Spielerei zeigt, wie du Agent-Daten als Markdown exportierst. Der Agent ist essenziell für die Überwachung und ermöglicht detaillierte Einblicke in Systemmetriken. Vertiefe dein Wissen, indem du fortgeschrittene Features wie Agent-Plugins (z. B. für Docker), TLS-Verschlüsselung oder verteiltes Monitoring ausprobierst. Wenn du ein spezifisches Thema (z. B. benutzerdefinierte Agent-Checks oder verteiltes Monitoring) vertiefen möchtest, lass es mich wissen!

**Quelle**: Die Schritte zur Installation des Agenten basieren auf der offiziellen Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/agent_linux.html#install).[](https://docs.checkmk.com/latest/en/agent_linux.html)
