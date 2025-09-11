# Praxisorientierte Anleitung: Perfdata in agentenlosen Check-Plugins

## Einführung

Performance-Daten (Perfdata) sind entscheidend für die Analyse historischer Metriken, das Erkennen von Trends und die Prognose von Engpässen in der IT-Überwachung. Checkmk visualisiert Perfdata in Graphen, die wertvolle Einblicke in die Leistung von Systemen liefern. Diese Anleitung erweitert das zuvor entwickelte agentenlose `api_check`-Plugin, um die **Antwortzeit** und **Antwortgröße** einer API als Perfdata zu erfassen. Wir implementieren die Metriken, konfigurieren Schwellwerte und visualisieren die Daten in Checkmk. Die Übungen verwenden die **Checkmk Raw Edition** und basieren auf der Dokumentation (https://docs.checkmk.com/latest/de/devel_check_plugins.html). Sie sind für Nutzer mit Grundkenntnissen in Python und HTTP geeignet.

**Voraussetzungen**:
- Ein Linux-System mit Checkmk Raw Edition installiert (z. B. Ubuntu 22.04 oder Debian 11).
- Eine Checkmk-Site (z. B. `mysite`) mit `omd su mysite`-Zugriff.
- Das `api_check`-Plugin aus der vorherigen Anleitung (siehe `checkmk_agentless_check_plugin.md`).
- Python 3 mit der Bibliothek `requests` (installiere mit `pip install requests`).
- Internetzugang für API-Tests (z. B. zu `httpbin.org`).

**Hinweis**: Die Übungen bauen auf dem bestehenden `api_check`-Plugin auf. Stelle sicher, dass es funktioniert, bevor du fortfährst.

## Grundlegende Konzepte

1. **Perfdata-Format**:
   - Perfdata sind numerische Metriken im Format: `label=value[unit];warn;crit;min;max`.
   - Beispiel: `response_time=1.23s;1.0;2.0;0` (Antwortzeit in Sekunden, Warnung bei 1s, Kritisch bei 2s, Minimum 0).
   - `label`: Name der Metrik (z. B. `response_time`).
   - `value[unit]`: Gemessener Wert mit Einheit.
   - `warn/crit`: Schwellwerte für `WARN`/`CRIT`-Status.
   - `min/max`: Optionale Grenzen für Graphen-Skalierung.
2. **Checkmk-API für Perfdata**:
   - Die `check_levels`-Funktion erleichtert die Verarbeitung von Metriken und Schwellwerten.
   - Perfdata werden automatisch in Graphen umgewandelt, wenn sie im Plugin definiert sind.
3. **Visualisierung**:
   - Checkmk erstellt für jede Metrik einen Graphen, der historische Daten in der Weboberfläche anzeigt.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Entwicklung des Perfdata-Plugins

**Ziel**: Das `api_check`-Plugin erweitern, um die API-Antwortzeit und -größe als Perfdata zu erfassen.

1. **Schritt 1**: Wechsle in die OMD-Shell und öffne das `api_check`-Plugin:
   ```bash
   sudo omd su mysite
   nano ~/local/share/check_mk/checks/api_check
   ```

2. **Schritt 2**: Ersetze den bestehenden Code durch folgenden, der Perfdata hinzufügt:
   ```python
   from cmk.base.plugins.agent_based.agent_based_api.v1 import (
       Result, Service, State, check_levels, register, render
   )
   import requests

   def discover_api_check(params):
       """Service-Discovery für den API-Check."""
       yield Service(item="API Status", parameters=params)

   def check_api_status(item, params, section):
       """Prüft den HTTP-Statuscode und liefert Perfdata."""
       api_url = params.get("url", "https://httpbin.org/status/200")
       expected_status = params.get("expected_status_code", 200)
       timeout = params.get("timeout", 5)
       response_time_warn = params.get("response_time_warn", 1.0)
       response_time_crit = params.get("response_time_crit", 2.0)

       try:
           # Zeitmessung starten
           start_time = time.perf_counter()
           response = requests.get(api_url, timeout=timeout)
           # Zeitmessung beenden
           response_time = time.perf_counter() - start_time
           response_size = len(response.content)

           # Perfdata für Antwortzeit und -größe
           yield from check_levels(
               response_time,
               levels_upper=(response_time_warn, response_time_crit),
               metric_name="response_time",
               label="Antwortzeit",
               render_func=render.timespan,
           )
           yield from check_levels(
               response_size,
               metric_name="response_size",
               label="Antwortgröße",
               render_func=lambda v: f"{v} B",
           )

           # Statusprüfung
           if response.status_code == expected_status:
               yield Result(
                   state=State.OK,
                   summary=f"Status: {response.status_code}, Zeit: {render.timespan(response_time)}, Größe: {response_size} B"
               )
           else:
               yield Result(
                   state=State.CRIT,
                   summary=f"Erwarteter Status: {expected_status}, erhalten: {response.status_code}"
               )
       except requests.RequestException as e:
           yield Result(state=State.CRIT, summary=f"Fehler bei der API-Anfrage: {e}")
       except Exception as e:
           yield Result(state=State.UNKNOWN, summary=f"Unerwarteter Fehler: {e}")

   register.check_plugin(
       name="api_check",
       service_name="API Status %s",
       discovery_function=discover_api_check,
       check_function=check_api_status,
       check_default_parameters={
           "url": "https://httpbin.org/status/200",
           "expected_status_code": 200,
           "timeout": 5,
           "response_time_warn": 1.0,
           "response_time_crit": 2.0
       },
   )
   ```

3. **Schritt 3**: Überprüfe die Syntax des Plugins:
   ```bash
   cmk --check-plugin api_check
   ```

**Reflexion**: Warum ist `time.perf_counter()` für die Zeitmessung besser als `time.time()`? Wie könnten zusätzliche Metriken (z. B. Latenz) die Überwachung verbessern?

### Übung 2: Konfiguration und Visualisierung

**Ziel**: Den Check konfigurieren und die Perfdata-Graphen in Checkmk visualisieren.

1. **Schritt 1**: Erstelle oder aktualisiere eine Regel für den Check:
   - Gehe zu `Setup > Services > Service monitoring rules > Create rule in folder`.
   - Wähle **API Status** aus.
   - Konfiguriere Parameter:
     - **URL**: `https://httpbin.org/status/200`
     - **Expected status code**: `200`
     - **Timeout**: `5` Sekunden
     - **Response time warn**: `1.0` Sekunden
     - **Response time crit**: `2.0` Sekunden
   - Wende die Regel auf den Host `api.httpbin.org` an.
   - Speichere und aktiviere die Änderungen (`Activate changes`).

2. **Schritt 2**: Führe eine Service-Discovery durch:
   ```bash
   cmk -I api.httpbin.org
   cmk -O
   ```

3. **Schritt 3**: Überprüfe die Graphen in der Weboberfläche:
   - Gehe zu `Monitor > All hosts > api.httpbin.org > API Status API Status`.
   - Klicke auf das **Graphen-Icon** oder den **Graph-Tab**, um die Graphen für `response_time` und `response_size` anzuzeigen.

**Reflexion**: Wie beeinflussen die Schwellwerte (`response_time_warn`, `response_time_crit`) die Alarme? Welche Vorteile bietet die Visualisierung von Perfdata für die API-Überwachung?

### Übung 3: Spielerei: Testen mit Fehlerfällen

**Ziel**: Simuliere Fehler, um die Robustheit des Plugins und die Perfdata zu testen.

1. **Schritt 1**: Simuliere einen langsamen API-Aufruf:
   - Ändere die Regel in der Weboberfläche:
     - Setze **URL** auf `https://httpbin.org/delay/3` (verzögert die Antwort um 3 Sekunden).
     - Speichere und aktiviere die Änderungen (`cmk -O`).
   - Der Service sollte in den `CRIT`-Zustand wechseln, da die Antwortzeit die Schwelle von 2 Sekunden überschreitet.

2. **Schritt 2**: Debugge den Check manuell:
   ```bash
   cmk -v --debug api.httpbin.org
   ```
   Überprüfe die Ausgabe, um Perfdata und Statusdetails zu sehen.

3. **Schritt 3**: Überprüfe die Logs bei Problemen:
   ```bash
   tail -f ~/var/log/web.log
   ```

**Reflexion**: Welche Fehlerquellen können Perfdata beeinflussen? Wie könnte man das Plugin anpassen, um dynamische Schwellwerte basierend auf Tageszeiten zu definieren?

## Tipps für den Erfolg
- **Fehlerbehebung**: Nutze `cmk -v --debug` und `~/var/log/web.log` für detaillierte Fehlerinformationen.
- **Testumgebung**: Verwende `httpbin.org` für zuverlässige Tests, bevor du produktive APIs überwachst.
- **Erweiterungen**: Füge Metriken wie HTTP-Header-Größe oder Statuscode-Häufigkeit hinzu.
- **Performance**: Beachte, dass häufige API-Aufrufe die Serverlast erhöhen können; passe das Check-Intervall an.
- **Dokumentation**: Konsultiere https://docs.checkmk.com/latest/de/devel_check_plugins.html für Details zu Perfdata.

## Fazit
Du hast das `api_check`-Plugin erfolgreich um Perfdata für Antwortzeit und -größe erweitert, Schwellwerte konfiguriert und Graphen in Checkmk visualisiert. Perfdata sind essenziell für die Analyse und Prognose von Systemleistungen, insbesondere bei der Überwachung externer APIs.

**Nächste Schritte**: Möchtest du **Benachrichtigungsregeln** für Perfdata-basierte Alarme konfigurieren oder ein komplexeres Plugin mit Authentifizierung oder mehreren Metriken entwickeln? Alternativ könntest du die Integration von Perfdata in agentenbasierte Checks untersuchen.

**Quelle**: Die Schritte basieren auf der Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/devel_check_plugins.html).