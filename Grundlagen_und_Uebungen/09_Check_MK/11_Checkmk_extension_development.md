# Praxisorientierte Anleitung: Checkmk-Erweiterungen entwickeln

## Einführung

Checkmk-Erweiterungen erweitern die Funktionalität von Checkmk durch benutzerdefinierte Überwachungsskripte. Diese Anleitung führt Anfänger in die Entwicklung eines **Agenten-Plugins** (für den Host) und eines **Check-Plugins** (für den Checkmk-Server) ein, um die Systemlaufzeit (Uptime) eines Hosts zu überwachen. Am Ende wird die Erweiterung in ein installierbares `.mkp`-Paket verpackt. Die Übungen verwenden die **Checkmk Raw Edition** und basieren auf der offiziellen Dokumentation (https://docs.checkmk.com/latest/de/devel_intro.html). Sie sind für Nutzer mit Grundkenntnissen in Linux und Python geeignet.

**Voraussetzungen**:
- Ein Linux-System mit Checkmk Raw Edition installiert (z. B. Ubuntu 22.04 oder Debian 11).
- Eine Checkmk-Site (z. B. `mysite`) mit installiertem Checkmk-Agenten auf dem Host (kann derselbe Server sein).
- Ein Terminal mit `omd su mysite`-Zugriff.
- Python 3 installiert.
- Grundkenntnisse in Linux-Dateisystemen und Python.

**Hinweis**: Alle Befehle auf dem Checkmk-Server werden in der OMD-Shell (`omd su mysite`) ausgeführt. Der Checkmk-Agent muss auf dem überwachten Host installiert sein.

## Grundlegende Konzepte

1. **Agenten-Plugin**:
   - Ein Skript auf dem Host im Verzeichnis `/usr/lib/check_mk_agent/plugins/`.
   - Sammelt Daten und gibt sie über `stdout` in einem Checkmk-kompatiblen Format mit einer Sektion (`<<<<<SECTION_NAME>>>>>`) aus.
2. **Check-Plugin**:
   - Ein Python-Skript auf dem Checkmk-Server in `~/local/share/check_mk/checks/`.
   - Verarbeitet Agenten-Daten und liefert Service-Status (`OK`, `WARN`, `CRIT`), Beschreibung und Performance-Daten.
3. **MKP-Paket**:
   - Ein `.mkp`-Paket ist ein ZIP-Archiv mit Agenten- und Check-Plugins sowie Metadaten.
   - Ermöglicht einfache Installation und Verteilung über die Checkmk-Weboberfläche.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Entwicklung des Agenten-Plugins

**Ziel**: Ein Python-Skript erstellen, das die Systemlaufzeit (Uptime) eines Hosts sammelt.

1. **Schritt 1**: Erstelle auf dem zu überwachenden Host die Datei `uptime.py`:
   ```bash
   sudo mkdir -p /usr/lib/check_mk_agent/plugins/
   sudo touch /usr/lib/check_mk_agent/plugins/uptime.py
   sudo chmod +x /usr/lib/check_mk_agent/plugins/uptime.py
   sudo nano /usr/lib/check_mk_agent/plugins/uptime.py
   ```

2. **Schritt 2**: Füge folgenden Python-Code ein:
   ```python
   #!/usr/bin/env python3
   import time

   print('<<<<<uptime>>>>>')
   try:
       with open('/proc/uptime', 'r') as f:
           uptime_seconds = float(f.readline().split()[0])
           print(f"uptime_seconds:{uptime_seconds}")
   except FileNotFoundError:
       print("Error: /proc/uptime not found")
   except Exception as e:
       print(f"Error: {e}")
   ```

3. **Schritt 3**: Teste das Agenten-Plugin manuell:
   ```bash
   /usr/lib/check_mk_agent/plugins/uptime.py
   ```
   Erwartete Ausgabe:
   ```
   <<<<<uptime>>>>>
   uptime_seconds:12345.67
   ```

**Reflexion**: Warum ist die Verwendung einer Sektion wie `<<<<<uptime>>>>>` wichtig? Wie könnte man das Skript anpassen, um weitere Metriken (z. B. Leerlaufzeit) zu sammeln?

### Übung 2: Entwicklung des Check-Plugins

**Ziel**: Ein Check-Plugin erstellen, das die Uptime-Daten verarbeitet und den Service-Status anzeigt.

1. **Schritt 1**: Wechsle in die OMD-Shell und erstelle die Datei für das Check-Plugin:
   ```bash
   sudo omd su mysite
   mkdir -p ~/local/share/check_mk/checks
   nano ~/local/share/check_mk/checks/uptime
   ```

2. **Schritt 2**: Füge folgenden Python-Code ein:
   ```python
   from cmk.base.plugins.agent_based.agent_based_api.v1 import (
       check_levels, render, Result, Service, State
   )

   def parse_uptime(string_table):
       """Parsen der Uptime-Daten aus der Agenten-Sektion."""
       for line in string_table:
           if line and line[0].startswith("uptime_seconds:"):
               try:
                   return float(line[0].split(":")[1])
               except (IndexError, ValueError):
                   return None
       return None

   def discover_uptime(section):
       """Service-Discovery für die Uptime-Sektion."""
       if section is not None:
           yield Service()

   def check_uptime(section):
       """Prüft die Uptime und gibt Status sowie Metriken zurück."""
       if section is None:
           yield Result(state=State.UNKNOWN, summary="Uptime-Daten nicht verfügbar")
           return

       uptime_seconds = section
       uptime_days = uptime_seconds / (24 * 60 * 60)

       # Schwellwerte: Warnung nach 10 Tagen, Kritisch nach 20 Tagen
       yield from check_levels(
           uptime_seconds,
           levels_upper=(10 * 24 * 60 * 60, 20 * 24 * 60 * 60),
           metric_name="uptime",
           label="Uptime",
           render_func=lambda v: render.timespan(v),
           notice_only=False,
       )

   register.agent_section(
       name="uptime",
       parse_function=parse_uptime,
   )

   register.check_plugin(
       name="uptime",
       service_name="System Uptime",
       discovery_function=discover_uptime,
       check_function=check_uptime,
   )
   ```

3. **Schritt 3**: Überprüfe die Syntax des Plugins:
   ```bash
   cmk --check-plugin uptime
   ```

**Reflexion**: Wie beeinflussen die Schwellwerte (`warning_days`, `critical_days`) die Überwachung? Wie könnte man das Plugin erweitern, um Performance-Daten für Grafiken bereitzustellen?

### Übung 3: Testen und Verpacken der Erweiterung

**Ziel**: Den neuen Service testen und die Erweiterung in ein `.mkp`-Paket verpacken.

1. **Schritt 1**: Führe eine Service-Discovery durch:
   ```bash
   cmk -I localhost
   cmk -O
   ```
   Überprüfe in der Weboberfläche (`http://localhost/mysite`) unter `Monitor > All hosts > localhost`, ob der Service `System Uptime` angezeigt wird.

2. **Schritt 2**: Erstelle eine Verzeichnisstruktur für das `.mkp`-Paket:
   ```bash
   mkdir -p ~/tmp/uptime_check/checks
   mkdir -p ~/tmp/uptime_check/agents/plugins
   cp ~/local/share/check_mk/checks/uptime ~/tmp/uptime_check/checks/
   cp /usr/lib/check_mk_agent/plugins/uptime.py ~/tmp/uptime_check/agents/plugins/
   ```

3. **Schritt 3**: Erstelle eine `info`-Datei für das Paket:
   ```bash
   nano ~/tmp/uptime_check/info
   ```
   Füge folgenden Inhalt ein:
   ```python
   {
       "title": "System Uptime Check",
       "name": "uptime_check",
       "version": "1.0.0",
       "author": "Dein Name",
       "description": "Überwacht die Systemlaufzeit eines Hosts.",
       "packages": {
           "check": ["uptime"],
           "agent": ["plugins/uptime.py"]
       },
       "version.min_required": "2.3.0",
       "version.packaged": "2.3.0"
   }
   ```

4. **Schritt 4**: Erstelle das `.mkp`-Paket:
   ```bash
   mkp pack ~/tmp/uptime_check
   ```
   Die Ausgabe ist eine Datei wie `uptime_check-1.0.0.mkp` in `~/var/check_mk/packages/`.

5. **Schritt 5**: Installiere das Paket über die Weboberfläche:
   - Gehe zu `Setup > Extension packages > Upload package`.
   - Lade die `.mkp`-Datei hoch und aktiviere die Änderungen.

**Reflexion**: Welche Vorteile bietet das Verpacken von Erweiterungen in `.mkp`-Pakete? Wie könnte man das Paket anpassen, um mehrere Plugins zu enthalten?

## Tipps für den Erfolg
- **Fehlerbehebung**: Überprüfe die Checkmk-Logs (`tail -f ~/var/log/web.log`) bei Problemen.
- **Testumgebung**: Nutze eine virtuelle Maschine, um Änderungen risikofrei zu testen.
- **Dokumentation**: Konsultiere https://docs.checkmk.com/latest/de/devel_intro.html für Details zu Plugin-Entwicklung.
- **Erweiterung**: Füge Performance-Daten (z. B. `uptime_seconds`) für Grafiken hinzu oder implementiere dynamische Schwellwerte.

## Fazit
Du hast ein Agenten-Plugin und ein Check-Plugin entwickelt, um die Systemlaufzeit zu überwachen, und diese in ein `.mkp`-Paket verpackt. Diese Fähigkeiten ermöglichen die Anpassung von Checkmk an spezifische Anforderungen, wie die Überwachung von Nischen-Anwendungen oder proprietären Systemen.

**Nächste Schritte**: Möchtest du die Entwicklung von **Check-Plugins ohne Agenten** (z. B. für API-Überwachung) oder **Benachrichtigungserweiterungen** vertiefen? Alternativ könntest du komplexere Plugins mit dynamischen Schwellwerten oder Integrationen mit externen Systemen erkunden.

**Quelle**: Die Schritte basieren auf der Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/devel_intro.html).