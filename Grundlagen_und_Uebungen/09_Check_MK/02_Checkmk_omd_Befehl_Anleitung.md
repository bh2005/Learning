# Praxisorientierte Anleitung: Der Checkmk-OMD-Befehl für Anfänger

## Einführung
Die **Open Monitoring Distribution (OMD)** ist ein Framework, das Checkmk und seine Abhängigkeiten (z. B. Nagios, Apache, RRDtool) in einer isolierten Umgebung, genannt **Site**, bereitstellt. Der `omd`-Befehl ist das zentrale Kommandozeilenwerkzeug zur Verwaltung dieser Sites in Checkmk, einer leistungsstarken Open-Source- und Enterprise-Software für IT-Monitoring. Diese Anleitung führt Anfänger in die **Verwendung des `omd`-Befehls** ein, mit Fokus auf **Erstellen und Verwalten von Checkmk-Sites**, **Konfiguration und Start/Stopp von Sites**, **Fehlerbehebung und Backup** sowie **Automatisierung von Verwaltungsaufgaben**. Eine **Spielerei** zeigt, wie du den Status von Sites als Markdown-Tabelle exportierst, um die Verbindung zu vorherigen Themen (z. B. Markdown-Ausgabe) herzustellen. Die Übungen sind für Nutzer mit grundlegenden Kenntnissen in Linux und Checkmk geeignet und verwenden die **Checkmk Raw Edition** (Open Source).

**Voraussetzungen**:
- Ein Linux-System mit Checkmk Raw Edition installiert (z. B. Ubuntu 22.04 oder Debian 11).
- Ein Terminal (z. B. `bash` oder `zsh`) mit Root-Zugriff oder `sudo`-Rechten.
- Checkmk Raw Edition installiert (siehe vorherige Anleitung).
- Grundkenntnisse in Linux (z. B. `sudo`, `systemctl`) und Checkmk (z. B. Konzept von Sites).
- Sichere Testumgebung (z. B. `/opt/omd/sites/` oder eine virtuelle Maschine).
- Ein Webbrowser (z. B. Chrome, Firefox) für die Checkmk-Weboberfläche.

**Hinweis**: Diese Anleitung setzt voraus, dass Checkmk installiert ist. Falls nicht, lade und installiere die Raw Edition (z. B. `sudo apt install ./check-mk-raw-2.4.0_0.focal_amd64.deb`).

## Grundlegende Befehle
Hier sind die wichtigsten `omd`-Befehle und Konzepte für Checkmk:

1. **Erstellen und Verwalten von Checkmk-Sites**:
   - `omd create <site>`: Erstellt eine neue Checkmk-Site.
   - `omd rm <site>`: Löscht eine Site.
   - `omd list`: Listet alle Sites auf dem System.
2. **Konfiguration und Start/Stopp von Sites**:
   - `omd start <site>`: Startet alle Dienste einer Site (z. B. Apache, Nagios).
   - `omd stop <site>`: Stoppt alle Dienste einer Site.
   - `omd restart <site>`: Startet eine Site neu.
   - `omd config <site>`: Öffnet die Konfigurationsoberfläche für eine Site.
3. **Fehlerbehebung und Backup**:
   - `omd status <site>`: Zeigt den Status der Dienste einer Site (z. B. `rrdcached`, `cmc`).
   - `omd backup <site> <backup-file>`: Erstellt ein Backup einer Site.
   - `omd restore <site> <backup-file>`: Stellt eine Site aus einem Backup wieder her.
4. **Nützliche Zusatzbefehle**:
   - `omd version`: Zeigt die installierte Checkmk-Version.
   - `omd su <site>`: Wechselt in die Umgebung einer Site (z. B. für `cmk`-Befehle).
   - `tail -f /opt/omd/sites/<site>/var/log/web.log`: Zeigt Logs in Echtzeit.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Erstellen und Verwalten von Checkmk-Sites
**Ziel**: Erstelle und verwalte eine Checkmk-Site mit dem `omd`-Befehl.

1. **Schritt 1**: Stelle sicher, dass Checkmk installiert ist:
   ```bash
   dpkg -l | grep check-mk-raw
   ```
   Falls nicht installiert, lade und installiere die Raw Edition in der aktuellen Version(siehe https://checkmk.com/download):
   ```bash
   wget https://download.checkmk.com/checkmk/2.4.0/check-mk-raw-2.4.0_0.focal_amd64.deb
   sudo apt install -y ./check-mk-raw-2.4.0_0.focal_amd64.deb
   ```

2. **Schritt 2**: Erstelle eine neue Site (z. B. `mysite`):
   ```bash
   sudo omd create mysite
   ```
   Notiere das generierte Passwort für den Benutzer `cmkadmin`.

3. **Schritt 3**: Liste alle Sites auf:
   ```bash
   sudo omd list
   ```
   Die Ausgabe sollte `mysite` anzeigen, z. B.:
   ```
   mysite   2.4.0.cre
   ```

4. **Schritt 4**: Starte die Site:
   ```bash
   sudo omd start mysite
   ```
   Überprüfe den Status:
   ```bash
   sudo omd status mysite
   ```
   Die Ausgabe sollte alle Dienste (z. B. `apache`, `rrdcached`) als `running` anzeigen.

5. **Schritt 5**: Öffne die Weboberfläche:
   - Gehe im Browser zu `http://<deine-server-ip>/mysite`.
   - Melde dich mit `cmkadmin` und dem generierten Passwort an.

6. **Schritt 6**: Stoppe und lösche die Site (optional):
   ```bash
   sudo omd stop mysite
   sudo omd rm mysite
   ```

**Reflexion**: Warum ist die Isolierung von Sites in OMD nützlich? Nutze `omd help` und überlege, wie du mehrere Sites für unterschiedliche Abteilungen einrichten kannst.

### Übung 2: Konfiguration und Start/Stopp von Sites
**Ziel**: Konfiguriere eine Site und steuere ihre Dienste.

1. **Schritt 1**: Erstelle eine neue Site (falls nicht bereits vorhanden):
   ```bash
   sudo omd create testsite
   ```

2. **Schritt 2**: Konfiguriere die Site:
   ```bash
   sudo omd config testsite
   ```
   - Navigiere zu `Web > GUI` und ändere z. B. `HTTP port` auf `8080`.
   - Speichere mit `Save & Exit`.

3. **Schritt 3**: Starte die Site und überprüfe die neue Port-Konfiguration:
   ```bash
   sudo omd start testsite
   ```
   Gehe im Browser zu `http://<deine-server-ip>:8080/testsite` und melde dich an.

4. **Schritt 4**: Stoppe und starte die Site neu:
   ```bash
   sudo omd stop testsite
   sudo omd restart testsite
   ```

5. **Schritt 5**: Wechsle in die Site-Umgebung:
   ```bash
   sudo omd su testsite
   ```
   Führe einen `cmk`-Befehl aus (z. B. für einen Host):
   ```bash
   cmk -D remote-host
   exit
   ```

**Reflexion**: Wie vereinfacht `omd config` die Site-Verwaltung? Nutze `omd config --help` und überlege, wie du die Konfiguration für verteiltes Monitoring anpassen kannst.

### Übung 3: Fehlerbehebung, Backup und Spielerei
**Ziel**: Behebe Fehler, erstelle ein Backup und exportiere Site-Status als Markdown.

1. **Schritt 1**: Überprüfe den Status einer Site:
   ```bash
   sudo omd status testsite
   ```
   Wenn ein Dienst nicht läuft (z. B. `apache stopped`), starte ihn:
   ```bash
   sudo omd restart testsite apache
   ```

2. **Schritt 2**: Erstelle ein Backup:
   ```bash
   sudo omd backup testsite testsite_backup.tar.gz
   ```
   Überprüfe das Backup:
   ```bash
   ls -l testsite_backup.tar.gz
   ```

3. **Schritt 3**: Stelle eine Site aus einem Backup wieder her:
   ```bash
   sudo omd stop testsite
   sudo omd rm testsite
   sudo omd restore testsite testsite_backup.tar.gz
   sudo omd start testsite
   ```

4. **Schritt 4**: Erstelle ein Python-Skript für die Markdown-Exportfunktion:
   ```bash
   nano export_omd_status.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import subprocess
   import re

   def get_omd_status(site):
       """Ruft den Status einer Checkmk-Site ab."""
       try:
           result = subprocess.run(['omd', 'status', site], capture_output=True, text=True, check=True)
           output = result.stdout
           services = []
           for line in output.splitlines():
               match = re.match(r'(\w+)\s*:\s*(running|stopped)', line)
               if match:
                   services.append({'service': match.group(1), 'status': match.group(2)})
           return services
       except subprocess.CalledProcessError as e:
           print(f"Fehler beim Abrufen des Status für {site}: {e}")
           return []

   def to_markdown(site, output_file="omd_status.md"):
       """Exportiert Site-Status als Markdown-Tabelle."""
       services = get_omd_status(site)
       if not services:
           return "Keine Daten verfügbar."
       header = "| Dienst | Status |\n|---|--------|\n"
       rows = [f"| {s['service']} | {s['status']} |" for s in services]
       markdown = header + "\n".join(rows)
       with open(output_file, 'w') as f:
           f.write(f"# Status der Checkmk-Site {site}\n\n" + markdown)
       return markdown

   if __name__ == "__main__":
       site = "testsite"
       print(to_markdown(site))
   ```
   Speichere und schließe.

5. **Schritt 5**: Führe das Skript aus:
   ```bash
   python3 export_omd_status.py
   ```
   Überprüfe die Markdown-Ausgabe:
   ```bash
   cat omd_status.md
   ```
   Die Ausgabe könnte so aussehen:
   ```
   # Status der Checkmk-Site testsite

   | Dienst | Status |
   |---|--------|
   | apache | running |
   | rrdcached | running |
   | npcd | running |
   | nagios | running |
   ```

6. **Spielerei**: Passe das Skript an, um nur gestoppte Dienste zu exportieren:
   - Ändere `to_markdown`, um `services` zu filtern:
     ```python
     rows = [f"| {s['service']} | {s['status']} |" for s in services if s['status'] == 'stopped']
     ```

**Reflexion**: Wie hilft `omd status` bei der Fehlerbehebung? Nutze `omd help` und überlege, wie du `omd` in einem Skript für automatisierte Backups nutzen kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um den `omd`-Befehl zu verinnerlichen.
- **Sicheres Testen**: Nutze virtuelle Maschinen oder Container, um Änderungen risikofrei zu testen.
- **Fehler verstehen**: Lies Logs (`/opt/omd/sites/<site>/var/log/web.log`) und nutze die Checkmk-Dokumentation (https://docs.checkmk.com).
- **Effiziente Entwicklung**: Nutze `omd config` für schnelle Anpassungen, `omd backup` für Sicherheit und Skripte für Automatisierung.
- **Kombiniere Tools**: Integriere `omd` mit Redis für Caching, Python für Datenverarbeitung oder Ansible für automatisierte Site-Erstellung.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Integration mit Redis für Echtzeit-Status oder Export in andere Formate (z. B. JSON).

## Fazit
Mit diesen Übungen hast du die grundlegenden und fortgeschrittenen Funktionen des `omd`-Befehls gemeistert, einschließlich Site-Erstellung, Konfiguration, Fehlerbehebung und Backup. Die Spielerei zeigt, wie du Site-Status als Markdown exportierst. Der `omd`-Befehl ist ein zentrales Werkzeug für die Verwaltung von Checkmk-Sites, das die Administration vereinfacht. Vertiefe dein Wissen, indem du fortgeschrittene Features wie verteiltes Monitoring oder benutzerdefinierte Konfigurationen mit `omd` ausprobierst. Wenn du ein spezifisches Thema (z. B. verteiltes Monitoring oder Automatisierung mit Ansible) vertiefen möchtest, lass es mich wissen!
