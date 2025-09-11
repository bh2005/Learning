# Praxisorientierte Anleitung: Überwachung mit SNMP in Checkmk für Anfänger

## Einführung
Simple Network Management Protocol (SNMP) ist ein Standardprotokoll zur Überwachung von Netzwerkgeräten wie Switches, Router, Drucker oder Server. Checkmk nutzt SNMP, um Daten von Geräten ohne installierten Checkmk-Agenten zu sammeln, und bietet umfangreiche Unterstützung für SNMP v1, v2c und v3. Diese Anleitung führt Anfänger in die **Überwachung mit SNMP in Checkmk** ein, mit Fokus auf **Grundlagen von SNMP**, **Konfiguration von SNMP auf einem Gerät**, **Integration eines SNMP-Hosts in Checkmk** sowie **Fehlerbehebung**. Eine **Spielerei** zeigt, wie du SNMP-Daten als Markdown-Tabelle exportierst, um die Verbindung zu vorherigen Themen (z. B. Markdown-Ausgabe) herzustellen. Die Übungen verwenden die **Checkmk Raw Edition** (Open Source) und sind für Nutzer mit grundlegenden Kenntnissen in Linux, Netzwerken und Checkmk geeignet.

**Voraussetzungen**:
- Ein Linux-System mit Checkmk Raw Edition installiert (z. B. Ubuntu 22.04 oder Debian 11).
- Ein Terminal (z. B. `bash` oder `zsh`) mit Root-Zugriff oder `sudo`-Rechten.
- Eine Checkmk-Site (z. B. `mysite`) eingerichtet (siehe vorherige Anleitung).
- Ein SNMP-fähiges Gerät (z. B. ein Switch, Router oder ein Linux-Server mit `snmpd`) im Netzwerk.
- Grundkenntnisse in Linux (z. B. `apt`, `systemctl`), Netzwerken (z. B. IP-Adressen, SNMP) und Checkmk (z. B. Konzept von Hosts und Services).
- Sichere Testumgebung (z. B. `/opt/omd/sites/mysite` oder eine virtuelle Maschine).
- Ein Webbrowser (z. B. Chrome, Firefox) für die Checkmk-Weboberfläche.

**Hinweis**: Diese Anleitung setzt voraus, dass ein Checkmk-Server läuft. Wir verwenden ein Linux-System mit `snmpd` als Beispielgerät für die SNMP-Konfiguration, da es einfach einzurichten ist. Für echte Netzwerkgeräte (z. B. Cisco-Switches) können die SNMP-Einstellungen abweichen.

## Grundlegende Begriffe und Befehle
Hier sind die wichtigsten Konzepte und Befehle für die SNMP-Überwachung in Checkmk:

1. **Grundlagen von SNMP**:
   - **SNMP-Versionen**: v1 (veraltet, unsicher), v2c (Community-basierte Authentifizierung), v3 (sicher mit Benutzername/Passwort und Verschlüsselung).
   - **Community-String**: Ein Passwort für SNMP v1/v2c (z. B. `public` oder `private`).
   - **OID (Object Identifier)**: Eindeutige Kennung für SNMP-Daten (z. B. `.1.3.6.1.2.1.1.1.0` für Systembeschreibung).
   - **MIB (Management Information Base)**: Strukturierte Beschreibung von SNMP-Daten (Checkmk enthält viele MIBs).
2. **Konfiguration von SNMP auf einem Gerät**:
   - `sudo apt install snmpd`: Installiert den SNMP-Daemon auf einem Linux-System.
   - `sudo nano /etc/snmp/snmpd.conf`: Konfiguriert SNMP-Community und Zugriffsrechte.
   - `sudo systemctl restart snmpd`: Startet den SNMP-Daemon neu.
3. **Integration eines SNMP-Hosts in Checkmk**:
   - `Setup > Hosts > Add host`: Fügt einen SNMP-Host in der Weboberfläche hinzu.
   - `cmk -I <hostname>`: Führt eine Service-Discovery für den Host durch.
   - `cmk -O`: Aktiviert Änderungen.
4. **Nützliche Zusatzbefehle**:
   - `snmpwalk -v2c -c <community> <hostname> .1`: Testet SNMP-Daten eines Geräts.
   - `cmk -v --debug <hostname>`: Führt Checks mit Debugging-Informationen aus.
   - `tail -f /opt/omd/sites/mysite/var/log/web.log`: Zeigt Checkmk-Logs in Echtzeit.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Konfiguration von SNMP auf einem Gerät
**Ziel**: Richte SNMP auf dem localhost ein (als Beispielgerät).

1. **Schritt 1**: Stelle sicher, dass Checkmk läuft:
   ```bash
   sudo omd status mysite
   ```
   Wenn die Site nicht läuft, starte sie:
   ```bash
   sudo omd start mysite
   ```

2. **Schritt 2**: Installiere den SNMP-Daemon:
   ```bash
   sudo apt update
   sudo apt install -y snmpd
   ```

3. **Schritt 3**: Konfiguriere SNMP (v2c für Einfachheit):
   ```bash
   sudo nano /etc/snmp/snmpd.conf
   ```
   Füge oder ändere die folgenden Zeilen, um eine Community-String (`mycommunity`) einzurichten:
   ```bash
   rocommunity mycommunity 127.0.0.1
   sysLocation "Local Server"
   sysContact "admin@example.com"
   ```
   Kommentiere andere `rocommunity`-Zeilen aus (füge `#` voran), um die Sicherheit zu erhöhen. Speichere und schließe.

4. **Schritt 4**: Starte den SNMP-Daemon neu:
   ```bash
   sudo systemctl restart snmpd
   ```

5. **Schritt 5**: Teste die SNMP-Konfiguration:
   ```bash
   snmpwalk -v2c -c mycommunity localhost .1.3.6.1.2.1.1.1.0
   ```
   Die Ausgabe sollte die Systembeschreibung anzeigen, z. B.:
   ```
   SNMPv2-MIB::sysDescr.0 = STRING: Linux localhost 5.15.0-73-generic #80-Ubuntu SMP Mon May 15 15:16:52 UTC 2023 x86_64
   ```

**Reflexion**: Warum ist eine eingeschränkte Community-String wichtig? Nutze `man snmpd.conf` und überlege, wie du SNMP v3 für mehr Sicherheit konfigurieren kannst.

### Übung 2: Integration eines SNMP-Hosts in Checkmk
**Ziel**: Füge den localhost als SNMP-Host in Checkmk hinzu und überwache ihn.

1. **Schritt 1**: Wechsle in die Checkmk-Site:
   ```bash
   sudo omd su mysite
   ```

2. **Schritt 2**: Füge den localhost als SNMP-Host hinzu:
   - Bearbeite die Konfigurationsdatei:
     ```bash
     nano ~/etc/check_mk/main.mk
     ```
     Füge folgenden Inhalt hinzu:
     ```python
     all_hosts += ["localhost|snmp"]
     ipaddresses["localhost"] = "127.0.0.1"
     snmp_community["localhost"] = "mycommunity"
     ```
     Speichere und schließe.

3. **Schritt 3**: Führe eine Service-Discovery durch:
   ```bash
   cmk -I localhost
   cmk -O
   ```

4. **Schritt 4**: Überprüfe die Weboberfläche:
   - Gehe zu `http://localhost/mysite`.
   - Navigiere zu `Monitor > All hosts > localhost`.
   - Du solltest Services wie `Interface eth0`, `Uptime` oder `System Description` sehen.

5. **Schritt 5**: Teste die SNMP-Daten manuell:
   ```bash
   cmk -v localhost
   ```
   Die Ausgabe zeigt die SNMP-basierten Services und ihren Status (z. B. `OK`, `WARN`).

**Reflexion**: Wie erkennt Checkmk SNMP-Services automatisch? Nutze `cmk --help` und überlege, wie du spezifische OIDs für benutzerdefinierte Checks hinzufügen kannst.

### Übung 3: Fehlerbehebung und Spielerei
**Ziel**: Behebe SNMP-Fehler und exportiere SNMP-Daten als Markdown.

1. **Schritt 1**: Teste die Fehlerbehebung:
   - Wenn Services nicht erscheinen, überprüfe die SNMP-Verbindung:
     ```bash
     snmpwalk -v2c -c mycommunity localhost .1
     ```
   - Überprüfe Checkmk-Logs:
     ```bash
     tail -f ~/var/log/web.log
     ```
   - Führe einen Debugging-Check durch:
     ```bash
     cmk -v --debug localhost
     ```

2. **Schritt 2**: Erstelle ein Python-Skript für die Markdown-Exportfunktion:
   ```bash
   nano export_snmp_data.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import subprocess
   import re

   def get_snmp_data(hostname):
       """Ruft SNMP-Daten für einen Host mit cmk -v ab."""
       try:
           result = subprocess.run(['cmk', '-v', hostname], capture_output=True, text=True, check=True)
           output = result.stdout
           services = []
           for line in output.splitlines():
               match = re.match(r'(\S+)\s+(OK|WARN|CRIT|UNKNOWN)\s+-\s+(.+)', line)
               if match:
                   services.append({
                       'service': match.group(1),
                       'status': match.group(2),
                       'details': match.group(3)
                   })
           return services
       except subprocess.CalledProcessError as e:
           print(f"Fehler beim Abrufen der Daten für {hostname}: {e}")
           return []

   def to_markdown(hostname, output_file="snmp_data.md"):
       """Exportiert SNMP-Daten als Markdown-Tabelle."""
       services = get_snmp_data(hostname)
       if not services:
           return "Keine Daten verfügbar."
       header = "| Service | Status | Details |\n|---|--------|---------|\n"
       rows = [f"| {s['service']} | {s['status']} | {s['details']} |" for s in services]
       markdown = header + "\n".join(rows)
       with open(output_file, 'w') as f:
           f.write(f"# SNMP-Daten für {hostname}\n\n" + markdown)
       return markdown

   if __name__ == "__main__":
       hostname = "localhost"
       print(to_markdown(hostname))
   ```
   Speichere und schließe.

3. **Schritt 3**: Führe das Skript aus:
   ```bash
   sudo -u mysite python3 export_snmp_data.py
   ```
   Überprüfe die Markdown-Ausgabe:
   ```bash
   cat snmp_data.md
   ```
   Die Ausgabe könnte so aussehen (abhängig von den Services):
   ```
   # SNMP-Daten für localhost

   | Service | Status | Details |
   |---|--------|---------|
   | Uptime | OK | Up since Mon Sep 08 07:49:00 2025, uptime: 5 days |
   | Interface_eth0 | OK | Speed: 1Gbit/s, In: 10MB/s, Out: 5MB/s |
   ```

4. **Spielerei**: Passe das Skript an, um nur Services mit `WARN` oder `CRIT` zu exportieren:
   - Ändere `to_markdown`, um `services` zu filtern:
     ```python
     rows = [f"| {s['service']} | {s['status']} | {s['details']} |" for s in services if s['status'] in ['WARN', 'CRIT']]
     ```

**Reflexion**: Wie hilft `snmpwalk` bei der Fehlerbehebung von SNMP? Nutze `man snmpwalk` und überlege, wie du SNMP v3 mit Authentifizierung und Verschlüsselung in Checkmk einrichten kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um SNMP in Checkmk zu verinnerlichen.
- **Sicheres Testen**: Nutze virtuelle Maschinen oder Container, um Änderungen risikofrei zu testen.
- **Fehler verstehen**: Lies Checkmk-Logs (`/opt/omd/sites/mysite/var/log/web.log`) und nutze die Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/snmp.html).
- **Effiziente Entwicklung**: Nutze `cmk -I` für schnelle Service-Updates, `snmpwalk` für Debugging und Skripte für Automatisierung.
- **Kombiniere Tools**: Integriere SNMP-Daten mit Redis für Echtzeit-Caching oder Ansible für automatisierte Gerätekonfiguration.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Integration mit Redis oder Export in andere Formate (z. B. CSV).

## Fazit
Mit diesen Übungen hast du die Grundlagen der SNMP-Überwachung in Checkmk gemeistert, einschließlich der Konfiguration eines Geräts und der Integration in eine Checkmk-Site. Die Spielerei zeigt, wie du SNMP-Daten als Markdown exportierst. SNMP ist ein leistungsstarkes Protokoll für die Überwachung von Netzwerkgeräten, und Checkmk vereinfacht die Nutzung durch automatische Erkennung und umfangreiche MIB-Unterstützung. Vertiefe dein Wissen, indem du fortgeschrittene Features wie SNMP v3 oder benutzerdefinierte OIDs ausprobierst. Wenn du ein spezifisches Thema (z. B. SNMP v3, benutzerdefinierte Checks oder verteiltes Monitoring) vertiefen möchtest, lass es mich wissen!

**Quelle**: Die Schritte basieren auf der offiziellen Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/snmp.html).
