# Praxisorientierte Anleitung: OpenTelemetry-Daten in Checkmk-Dashboards integrieren

## Einführung
Die Integration von **OpenTelemetry**-Daten in **Checkmk-Dashboards** ermöglicht eine umfassende Observability-Lösung, indem Metriken, Traces und Logs aus Kubernetes-Anwendungen und Infrastruktur in Checkmk visualisiert werden. Ab Checkmk 2.4.0 (experimentell in Cloud- und MSP-Editionen) unterstützt Checkmk einen integrierten **OpenTelemetry-Collector**, der OTLP-Metriken (OpenTelemetry Protocol) empfängt, in Checkmk-Services umwandelt und dynamische Hosts erstellt. Diese Anleitung zeigt, wie Sie OpenTelemetry-Daten aus einem Kubernetes-Cluster (z. B. aus der vorherigen Anleitung) in Checkmk importieren und in benutzerdefinierten Dashboards darstellen. Für ältere Versionen oder Hybrid-Szenarien wird die Integration über Prometheus beschrieben. Die Anleitung ist ideal für DevOps-Teams, die Kubernetes auf Debian 12 überwachen.

**Voraussetzungen**:
- Debian 12 mit installiertem Kubernetes-Cluster (z. B. via `kubeadm`) und `kubectl` konfiguriert
- Checkmk 2.4.0 oder höher (Cloud/MSP-Edition; für On-Prem: Experimentelle Features aktivieren)
- OpenTelemetry Collector in Kubernetes (siehe vorherige Anleitung mit DaemonSet/Gateway)
- Prometheus und/oder Jaeger als Backends (optional für Hybrid-Integration)
- Root- oder Sudo-Zugriff auf dem Checkmk-Server
- Zugriff auf die Checkmk-Weboberfläche (z. B. `http://<checkmk-server>/mysite`)
- Helm installiert (für Kubernetes-Updates)

## Grundlegende Konzepte
1. **OpenTelemetry-Integration in Checkmk**:
   - **Collector**: Der integrierte Checkmk-OpenTelemetry-Collector empfängt OTLP-Metriken (gRPC/HTTP) und wandelt sie in Checkmk-Services um.
   - **Spezialagent**: Erkennt Metriken (z. B. CPU, RAM, benutzerdefinierte Metriken) und erstellt dynamische Hosts basierend auf Ressourcenattributen (z. B. `service.name`).
   - **Dynamische Hosts**: Virtuelle Hosts werden automatisch für OpenTelemetry-Ressourcen erstellt (z. B. Pods, Services).
2. **Dashboards in Checkmk**:
   - Benutzerdefinierte Dashboards (Dashlets) visualisieren Metriken als Graphen, Tabellen oder Timelines.
   - Beispiele: Pod-CPU-Nutzung, Trace-Dauer, Container-RAM.
3. **Hybrid-Integration über Prometheus**:
   - OpenTelemetry exportiert Metriken zu Prometheus, Checkmk scrapt diese über den Prometheus-Agenten.
   - Vorteil: Kompatibel mit älteren Checkmk-Versionen oder komplexen Setups.
4. **Vorteile**:
   - **Vendor-Neutralität**: Wechsel zwischen Backends ohne Codeänderung.
   - **Holistische Observability**: Metriken, Traces und Logs in Checkmk vereint.
   - **Skalierbarkeit**: Effiziente Datenverarbeitung durch OpenTelemetry-Collector.

## Übung 1: OpenTelemetry-Collector in Checkmk aktivieren
**Ziel**: Konfiguriere den integrierten Checkmk-OpenTelemetry-Collector, um OTLP-Metriken aus einem Kubernetes-Cluster zu empfangen.

1. **Schritt 1**: Aktiviere den OpenTelemetry-Collector.
   - Auf dem Checkmk-Server (Debian 12):
     ```bash
     sudo omd config set OPEN_TELEMETRY_COLLECTOR_ENABLED on mysite
     sudo omd restart mysite
     ```
   - **Erklärung**: Aktiviert den Collector für die Site `mysite`. Er lauscht auf Port 4317 (gRPC) und 4318 (HTTP).

2. **Schritt 2**: Konfiguriere die OpenTelemetry-Regel in Checkmk.
   - Öffne die Checkmk-Weboberfläche: `http://<checkmk-server>/mysite`.
   - Gehe zu „Setup“ > „Agents“ > „Other integrations“ > „OpenTelemetry (experimental)“ > „Add rule“.
   - Einstellungen:
     - **Host mapping**: Mappe `service.name` (z. B. `otel-sample-app`) zu Host-Namen.
     - **Ports**: Standard: 4317 (gRPC), 4318 (HTTP).
     - **TLS**: Aktiviere für Produktion (lade Zertifikate hoch, optional für Test).
     - **Metrics**: Wähle „All available metrics“ oder spezifische (z. B. `otelcol_*`, `http_requests_total`).
   - Speichere und aktiviere: „Save“ > „Activate on selected sites“.

3. **Schritt 3**: Verbinde den Kubernetes-OpenTelemetry-Collector mit Checkmk.
   - Passe den Gateway-Collector an (aus vorheriger Anleitung, `otel-gateway-values.yaml`):
     ```yaml
     mode: deployment
     image:
       repository: otel/opentelemetry-collector-contrib
       tag: 0.88.0
     config:
       receivers:
         otlp:
           protocols:
             grpc:
               endpoint: "0.0.0.0:4317"
             http:
               endpoint: "0.0.0.0:4318"
       exporters:
         otlp:
           endpoint: "<checkmk-ip>:4318" # Ersetze mit Checkmk-Server-IP
           tls:
             insecure: true
       processors:
         batch:
       service:
         pipelines:
           metrics:
             receivers: [otlp]
             processors: [batch]
             exporters: [otlp]
     ```
   - Aktualisiere das Helm-Release:
     ```bash
     helm upgrade otel-gateway open-telemetry/opentelemetry-collector -f otel-gateway-values.yaml -n otel
     ```

4. **Schritt 4**: Überprüfe die Integration.
   - In Checkmk: „Setup“ > „Hosts“ > Suche nach dynamischen Hosts (z. B. `otel-sample-app`).
   - Gehe zu „Monitor“ > „All services“ > Suche nach „OTel metric“-Services (z. B. „OTel metric CPU load“).
   - Simuliere Metriken: Sende Daten von einer instrumentierten App (siehe vorherige Anleitung, Übung 3).

**Reflexion**: Warum ist die Host-Mapping-Konfiguration wichtig für dynamische Hosts? Wie testest du die OTLP-Verbindung?

## Übung 2: OpenTelemetry-Metriken in Checkmk-Dashboards visualisieren
**Ziel**: Erstelle Services und benutzerdefinierte Dashboards, um OpenTelemetry-Metriken anzuzeigen.

1. **Schritt 1**: Konfiguriere den OpenTelemetry-Spezialagenten.
   - In Checkmk: „Setup“ > „Agents“ > „Other integrations“ > „OpenTelemetry (experimental)“.
   - Bearbeite die Regel (aus Übung 1):
     - **Agent type**: „Configured API integrations, no Checkmk agent“.
     - **IP address**: „No IP“ (für dynamische Hosts).
     - **Metrics**: Wähle spezifische Metriken (z. B. `k8s.pod.cpu`, `http_server_duration_ms`).
   - Speichere und aktiviere Änderungen.

2. **Schritt 2**: Entdecke Services.
   - Für einen dynamischen Host: „Setup“ > „Hosts“ > Wähle Host (z. B. `otel-sample-app`) > „Service discovery“ > „Discover services“.
   - Akzeptiere Services: „Accept all“ > „Save“.
   - **Ergebnis**: Services wie „OTel metric http_requests_total“ oder „OTel metric pod_cpu“ erscheinen.

3. **Schritt 3**: Erstelle ein benutzerdefiniertes Dashboard.
   - In Checkmk: „Customize“ > „Dashboards“ > „Add dashboard“.
   - Name: „Kubernetes OpenTelemetry Overview“.
   - Füge Dashlets hinzu:
     - **Graph-Dashlet**:
       - Wähle Service: „OTel metric k8s.pod.cpu“.
       - Zeitraum: „Last 24 hours“.
       - Titel: „Pod CPU Usage“.
     - **Metric-Dashlet**:
       - Metrik: `http_server_duration_ms`.
       - Filter: Namespace `otel`.
       - Titel: „HTTP Request Duration“.
     - **Table-Dashlet**:
       - Spalten: „Service“, „State“, „Summary“.
       - Filter: „OTel metric*“.
       - Titel: „OpenTelemetry Services“.
     - **Timeline-Dashlet** (für Traces/Events):
       - Wähle „Event Console“ (falls Logs aktiviert).
       - Titel: „Trace Events“.
   - Positioniere Dashlets per Drag-and-Drop.
   - Speichere: „Save dashboard“.

4. **Schritt 4**: Teste das Dashboard.
   - Gehe zu „Monitor“ > „Dashboards“ > Wähle „Kubernetes OpenTelemetry Overview“.
   - Simuliere Last: Sende Metriken/Traces von einer App (z. B. `curl http://<sample-app>:8000`).
   - Prüfe: Graphen zeigen CPU-Spitzen, Tabellen listen Services.

**Reflexion**: Welche Metriken sind für deine Kubernetes-Anwendungen kritisch? Wie verbessern Dashlets die Fehlersuche?

## Übung 3: Hybrid-Integration über Prometheus
**Ziel**: Integriere OpenTelemetry-Metriken via Prometheus in Checkmk als Fallback für ältere Versionen.

1. **Schritt 1**: Konfiguriere Prometheus-Exporter im OpenTelemetry-Collector.
   - Bearbeite `otel-gateway-values.yaml` (aus vorheriger Anleitung):
     ```yaml
     config:
       exporters:
         prometheus:
           endpoint: "0.0.0.0:8889"
         otlp:
           endpoint: "<checkmk-ip>:4318"
           tls:
             insecure: true
       service:
         pipelines:
           metrics:
             receivers: [otlp]
             processors: [batch]
             exporters: [prometheus, otlp]
     service:
       ports:
         - name: prometheus
           port: 8889
           targetPort: 8889
           protocol: TCP
     ```
   - Aktualisiere:
     ```bash
     helm upgrade otel-gateway open-telemetry/opentelemetry-collector -f otel-gateway-values.yaml -n otel
     ```

2. **Schritt 2**: Konfiguriere Prometheus in Checkmk.
   - In Checkmk: „Setup“ > „Agents“ > „Prometheus“ > „Add rule“.
   - Einstellungen:
     - **Endpoint**: `http://<prometheus-service>:9090` (z. B. `prometheus-server` in Namespace `otel`).
     - **Metrics**: Wähle OpenTelemetry-Metriken (z. B. `otelcol_receiver_accepted_spans_total`).
   - Speichere und aktiviere.

3. **Schritt 3**: Erweitere das Dashboard.
   - Bearbeite „Kubernetes OpenTelemetry Overview“:
     - Füge ein **Prometheus Graph-Dashlet** hinzu:
       - Query: `otelcol_receiver_accepted_spans_total`.
       - Titel: „Accepted Spans“.
     - Speichere und teste: Dashboard zeigt Prometheus-Metriken neben OTLP-Daten.

4. **Schritt 4**: Teste die Integration.
   - Port-Forward Prometheus:
     ```bash
     kubectl -n otel port-forward svc/prometheus-server 9090:9090
     ```
   - Öffne `http://localhost:9090` > Suche nach `otelcol_*`.
   - In Checkmk: Prüfe Dashboard für kombinierte Metriken.

**Reflexion**: Wann lohnt sich die Prometheus-Integration? Wie vermeidest du doppelte Metriken bei Hybrid-Setups?

## Tipps für den Erfolg
- **Sicherheit**:
  - Aktiviere TLS für OTLP: Lade Zertifikate in Checkmk hoch („Setup“ > „OpenTelemetry“ > „TLS settings“).
  - Beschränke Kubernetes-RBAC für den OpenTelemetry-Collector:
    ```yaml
    rules:
      - apiGroups: [""]
        resources: ["pods", "nodes"]
        verbs: ["get", "list"]
    ```
  - Firewall: Öffne Ports 4317/4318:
    ```bash
    sudo ufw allow 4317
    sudo ufw allow 4318
    sudo ufw allow 9090  # Für Prometheus
    ```
- **Performance**:
  - Filter Metriken im Collector: Bearbeite `otel-gateway-values.yaml` (z. B. nur `k8s.pod.cpu`).
  - Nutze Redis für Caching von Metriken (siehe vorherige Python-Skripte).
- **Fehlerbehebung**:
  - Prüfe Collector-Logs:
    ```bash
    kubectl -n otel logs -l app.kubernetes.io/name=opentelemetry-collector
    ```
  - Checkmk-Logs:
    ```bash
    sudo tail -f /omd/sites/mysite/var/log/cmc.log
    ```
  - Teste OTLP:
    ```bash
    curl -X POST http://<checkmk-ip>:4318/v1/metrics -H "Content-Type: application/json" -d '{"resourceMetrics": []}'
    ```
- **Erweiterung**:
  - Aktiviere Logs in Checkmk: „Setup“ > „OpenTelemetry“ > „Send log messages to event console“.
  - Exportiere Dashboards: „Customize“ > „Dashboards“ > „Export as JSON“.

## Fazit
In dieser Anleitung hast du gelernt, wie du OpenTelemetry-Daten in Checkmk-Dashboards integrierst, indem du den integrierten Collector in Checkmk 2.4.0 aktivierst, OTLP-Metriken als Services erkennst und benutzerdefinierte Dashboards mit Graphen, Tabellen und Timelines erstellst. Für ältere Versionen oder Hybrid-Szenarien wurde Prometheus integriert. Diese Lösung bietet skalierbare, vendor-neutrale Observability und verbindet Kubernetes-Metriken nahtlos mit Checkmk. Übe mit realen Anwendungen, um Dashboards zu optimieren, und erweitere sie für Traces und Logs!

**Nächste Schritte**:
- Integriere Logs via Checkmk Event Console für vollständige Observability.
- Nutze Synthetic Testing in Checkmk 2.4 für proaktive Überwachung.
- Erkunde OpenTelemetry-Community-Plugins für erweiterte Metriken.

**Quellen**:
- Checkmk-Dokumentation: [https://docs.checkmk.com/latest/en/opentelemetry.html](https://docs.checkmk.com/latest/en/opentelemetry.html)
- Checkmk 2.4 Release Notes: [https://checkmk.com/company/newsroom/checkmk-24-integrates-opentelemetry-and-synthetic-testing](https://checkmk.com/company/newsroom/checkmk-24-integrates-opentelemetry-and-synthetic-testing)
- OpenTelemetry Kubernetes: [https://opentelemetry.io/docs/kubernetes/](https://opentelemetry.io/docs/kubernetes/)
- Checkmk Community: [https://forum.checkmk.com/t/help-shape-opentelemetry-in-checkmk/52810](https://forum.checkmk.com/t/help-shape-opentelemetry-in-checkmk/52810)