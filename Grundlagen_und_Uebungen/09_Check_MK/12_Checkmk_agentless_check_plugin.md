# Praxisorientierte Anleitung: Agentenlose Check-Plugins entwickeln

## Einführung

Agentenlose Check-Plugins, auch **aktive Checks** genannt, werden direkt vom Checkmk-Server ausgeführt und erfordern keinen Checkmk-Agenten auf dem Zielsystem. Sie eignen sich ideal zur Überwachung externer Dienste wie HTTP-APIs, DNS-Server oder andere Netzwerkdienste. Diese Anleitung führt dich in die Entwicklung eines Python-Plugins ein, das den HTTP-Statuscode einer öffentlichen API (z. B. `httpbin.org`) überwacht. Wir konfigurieren und testen das Plugin in Checkmk und integrieren es in die Weboberfläche. Die Übungen verwenden die **Checkmk Raw Edition** und basieren auf der offiziellen Dokumentation (https://docs.checkmk.com/latest/de/devel_check_plugins.html). Sie sind für Nutzer mit Grundkenntnissen in Python und HTTP geeignet.

**Voraussetzungen**:
- Ein Linux-System mit Checkmk Raw Edition installiert (z. B. Ubuntu 22.04 oder Debian 11).
- Eine Checkmk-Site (z. B. `mysite`) mit `omd su mysite`-Zugriff.
- Python 3 mit der Bibliothek `requests` (installiere mit `pip install requests`).
- Grundkenntnisse in Python und HTTP-Statuscodes.
- Internetzugang für API-Tests (z. B. zu `httpbin.org`).

**Hinweis**: Das Plugin wird vollständig auf dem Checkmk-Server ausgeführt. Es ist kein Agent auf dem Zielsystem erforderlich.

## Grundlegende Konzepte

1. **Aktiver Check**:
   - Wird direkt vom Checkmk-Server in regelmäßigen Intervallen ausgeführt.
   - Nutzt Netzwerkprotokolle wie HTTP, ICMP oder SNMP, um Zielsysteme direkt zu prüfen.
2. **Check-Plugin**:
   - Ein Python-Skript auf dem Server in `~/local/share/check_mk/checks/`.
   - Enthält die Logik für die Überprüfung und gibt den Service-Status (`OK`, `WARN`, `CRIT`), eine Beschreibung und optional Performance-Daten zurück.
3. **Agentenlos**:
   - Im Gegensatz zu agentenbasierten Checks benötigt es keine Daten von einem Checkmk-Agenten und somit keine Sektionen wie `<<<<<SECTION_NAME>>>>>`.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: Entwicklung des Check-Plugins

**Ziel**: Ein Python-Plugin erstellen, das den HTTP-Statuscode einer API überprüft.

1. **Schritt 1**: Wechsle in die OMD-Shell und erstelle eine Datei für das Check-Plugin:
   ```bash
   sudo omd su mysite
   mkdir -p ~/local/share/check_mk/checks
   nano ~/local/share/check_mk/checks/api_check
   ```

2. **Schritt 2**: Füge folgenden Python-Code ein:
   ```python
   from cmk.base.plugins.agent_based.agent_based_api.v1 import (
       Result, Service, State, check_levels, register
   )
   import requests

   def discover_api_check(params):
       """Service-Discovery für den API-Check."""
       yield Service(item="API Status", parameters=params)

   def check_api_status(item, params, section):
       """Prüft den HTTP-Statuscode einer API."""
       api_url = params.get("url", "https://httpbin.org/status/200")
       expected_status = params.get("expected_status_code", 200)
       timeout = params.get("timeout", 5)

       try:
           response = requests.get(api_url, timeout=timeout)
           status_code = response.status_code
           yield from check_levels(
               status_code,
               levels_upper=(expected_status, expected_status),
               metric_name="http_status",
               label="HTTP Status",
               render_func=str,
           )
           if status_code == expected_status:
               yield Result(state=State.OK, summary=f"API-Statuscode: {status_code}")
           else:
               yield Result(
                   state=State.CRIT,
                   summary=f"Erwarteter Statuscode: {expected_status}, erhalten: {status_code}"
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
           "timeout": 5
       },
   )
   ```

3. **Schritt 3**: Überprüfe die Syntax des Plugins:
   ```bash
   cmk --check-plugin api_check
   ```

**Reflexion**: Warum ist die `requests`-Bibliothek für agentenlose Checks geeignet? Wie könnte man das Plugin erweitern, um weitere HTTP-Header (z. B. `Content-Type`) zu prüfen?

### Übung 2: Konfiguration in Checkmk

**Ziel**: Einen Host konfigurieren und den aktiven Check in Checkmk integrieren.

1. **Schritt 1**: Füge einen Host in der Weboberfläche hinzu:
   - Gehe zu `Setup > Hosts > Add host`.
   - Hostname: `api.httpbin.org` (oder ein anderer Name, da die API extern ist).
   - Deaktiviere **Checkmk agent** unter **Monitoring Agents**, da kein Agent benötigt wird.
   - Speichere und wende die Änderungen an (`Activate changes`).

2. **Schritt 2**: Erstelle eine Regel für den Check:
   - Gehe zu `Setup > Services > Service monitoring rules > Create rule in folder`.
   - Wähle **API Status** (das Plugin) aus.
   - Konfiguriere Parameter (optional):
     - **URL**: `https://httpbin.org/status/200`
     - **Expected status code**: `200`
     - **Timeout**: `5` Sekunden
   - Wende die Regel auf den Host `api.httpbin.org` an.
   - Speichere und aktiviere die Änderungen.

3. **Schritt 3**: Führe eine Service-Discovery durch:
   ```bash
   cmk -I api.httpbin.org
   cmk -O
   ```

4. **Schritt 4**: Überprüfe den Service in der Weboberfläche:
   - Gehe zu `Monitor > All hosts > api.httpbin.org`.
   - Der Service `API Status API Status` sollte mit Status `OK` erscheinen, wenn die API antwortet.

**Reflexion**: Wie unterscheidet sich die Konfiguration eines agentenlosen Checks von einem agentenbasierten Check? Welche Vorteile bietet die Verwendung von Regelparametern?

### Übung 3: Testen und Fehlerbehebung

**Ziel**: Den Check testen und Fehler debuggen.

1. **Schritt 1**: Simuliere einen Fehler, indem du die URL änderst:
   - Bearbeite die Regel in der Weboberfläche (`Setup > Services > API Status`).
   - Ändere die URL zu `https://httpbin.org/status/404`.
   - Aktiviere die Änderungen (`cmk -O`).
   - Der Service sollte in den Zustand `CRIT` wechseln mit der Meldung „Erwarteter Statuscode: 200, erhalten: 404“.

2. **Schritt 2**: Debugge den Check manuell:
   ```bash
   cmk -v --debug api.httpbin.org
   ```
   Überprüfe die Ausgabe, um Fehlerdetails zu finden (z. B. Netzwerkprobleme oder ungültige URLs).

3. **Schritt 3**: Überprüfe die Checkmk-Logs bei Problemen:
   ```bash
   tail -f ~/var/log/web.log
   ```

**Reflexion**: Welche typischen Fehler können bei agentenlosen Checks auftreten? Wie könnte man das Plugin anpassen, um mehrere Statuscodes als `OK` zu akzeptieren (z. B. 200 und 201)?

## Tipps für den Erfolg
- **Fehlerbehebung**: Nutze `cmk -v --debug` und die Checkmk-Logs (`~/var/log/web.log`) für detaillierte Fehlerinformationen.
- **Testumgebung**: Teste mit einer öffentlichen API wie `httpbin.org`, bevor du eigene APIs überwachst.
- **Erweiterungen**: Füge Performance-Daten hinzu (z. B. Antwortzeit der API mit `response.elapsed.total_seconds()`).
- **Sicherheit**: Verwende sichere URLs und berücksichtige Authentifizierung für private APIs.
- **Dokumentation**: Konsultiere https://docs.checkmk.com/latest/de/devel_check_plugins.html für weitere Details.

## Fazit
Du hast ein agentenloses Check-Plugin entwickelt, das den HTTP-Statuscode einer API überwacht, und es erfolgreich in Checkmk integriert. Agentenlose Checks sind ideal für die Überwachung externer Dienste ohne direkte Kontrolle über das Zielsystem, wie z. B. Cloud-APIs oder öffentliche Endpunkte.

**Nächste Schritte**: Möchtest du die **Verwendung von Performance-Daten** (z. B. Antwortzeit) in agentenlosen Plugins vertiefen oder **Benachrichtigungsregeln** für Alarme konfigurieren? Alternativ könntest du ein komplexeres Plugin entwickeln, das mehrere API-Endpunkte oder Authentifizierung unterstützt.

**Quelle**: Die Schritte basieren auf der Checkmk-Dokumentation (https://docs.checkmk.com/latest/de/devel_check_plugins.html).