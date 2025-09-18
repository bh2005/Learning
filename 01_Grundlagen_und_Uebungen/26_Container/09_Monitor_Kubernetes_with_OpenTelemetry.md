# Praxisorientierte Anleitung: Kubernetes mit OpenTelemetry überwachen

## Einführung
**OpenTelemetry** ist ein offener Standard für die Erfassung von Telemetriedaten (Metriken, Traces, Logs), der ideal mit Kubernetes zusammenarbeitet, um eine umfassende Observability-Lösung zu schaffen. Diese Anleitung zeigt, wie Sie OpenTelemetry in einem Kubernetes-Cluster auf Debian 12 einrichten, um Anwendungen und Infrastruktur zu überwachen. Sie implementieren den **OpenTelemetry Collector** sowohl als **DaemonSet** (Agent-Modell) für Host-Metriken als auch als **Deployment** (Gateway-Modell) für zentrale Datenaggregation, mit **Prometheus** und **Jaeger** als Backends. Die Anleitung ergänzt die vorherige Checkmk-Überwachung, indem sie zusätzliche Telemetrie-Daten liefert.

**Voraussetzungen**:
- Debian 12 mit installiertem Kubernetes-Cluster (z. B. via `kubeadm`) und `kubectl` konfiguriert
- Root- oder Sudo-Zugriff
- Internetzugang für Paketinstallationen
- Optional: Checkmk-Server für erweiterte Integration (siehe vorherige Anleitung)
- Helm installiert (für einfache Bereitstellung)

## Grundlegende Konzepte
1. **OpenTelemetry-Komponenten**:
   - **Instrumentierung**: Generiert Telemetriedaten aus Anwendungen (manuell via SDKs oder automatisch via Operator).
   - **Collector**: Empfängt, verarbeitet und exportiert Telemetriedaten zu Backends (z. B. Prometheus, Jaeger).
   - **Backend**: Speichert und visualisiert Daten (z. B. Prometheus für Metriken, Jaeger für Traces).
2. **Deployment-Modelle**:
   - **Agent (DaemonSet)**: Läuft auf jedem Node, sammelt Host- und Pod-Metriken lokal.
   - **Gateway (Deployment)**: Zentraler Collector, aggregiert Daten von Agenten/Anwendungen.
3. **Vorteile**:
   - **Vendor-Neutralität**: Wechsel zwischen Backends ohne Codeänderung.
   - **Holistische Observability**: Metriken, Traces und Logs in einem Framework.
   - **Skalierbarkeit**: Effiziente Datenverarbeitung durch Agent-Gateway-Modell.
4. **Debian 12**:
   - Nutzt `apt` für Installationen, `kubectl` und `helm` für Kubernetes-Management.

## Übung 1: OpenTelemetry Collector als DaemonSet (Agent) einrichten
**Ziel**: Bereitstellung des OpenTelemetry Collectors als DaemonSet, um Host- und Pod-Metriken zu sammeln.

1. **Schritt 1**: Prüfe die Kubernetes-Umgebung.
   - Stelle sicher, dass der Cluster läuft:
     ```bash
     kubectl cluster-info
     ```
   - Installiere Helm (falls nicht vorhanden):
     ```bash
     sudo apt update
     sudo apt install -y curl
     curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
     ```

2. **Schritt 2**: Füge das OpenTelemetry Helm-Repository hinzu.
   ```bash
   helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
   helm repo update
   ```

3. **Schritt 3**: Erstelle eine Konfigurationsdatei für den Agent-Collector.
   - Erstelle eine YAML-Datei:
     ```bash
     nano otel-agent-values.yaml
     ```
   - Füge folgendes ein:
     ```yaml
     mode: daemonset
     image:
       repository: otel/opentelemetry-collector-contrib
       tag: 0.88.0
     config:
       receivers:
         otlp:
           protocols:
             grpc:
             http:
         hostmetrics:
           collection_interval: 10s
           scrapers:
             cpu:
             memory:
             disk:
       processors:
         batch:
       exporters:
         otlp:
           endpoint: "otel-gateway:4317" # Wird später im Gateway definiert
           tls:
             insecure: true
       service:
         pipelines:
           metrics:
             receivers: [otlp, hostmetrics]
             processors: [batch]
             exporters: [otlp]
     ```
   - **Erklärung**:
     - `mode: daemonset`: Stellt den Collector als DaemonSet bereit.
     - `hostmetrics`: Sammelt CPU-, RAM- und Speicher-Metriken vom Host.
     - `otlp` (Receiver/Exporter): Ermöglicht Empfang und Weiterleitung von Telemetriedaten.
     - `endpoint: otel-gateway:4317`: Sendet Daten an den Gateway-Collector (später konfiguriert).

4. **Schritt 4**: Bereitstellung des Agent-Collectors.
   ```bash
   kubectl create namespace otel
   helm install otel-agent open-telemetry/opentelemetry-collector -f otel-agent-values.yaml -n otel
   ```

5. **Schritt 5**: Überprüfe die Bereitstellung.
   ```bash
   kubectl -n otel get pods -l app.kubernetes.io/name=opentelemetry-collector
   ```
   - Stelle sicher, dass ein Pod pro Node läuft.

**Reflexion**: Warum ist das DaemonSet-Modell für Host-Metriken effizient? Wie unterscheiden sich die gesammelten Metriken von denen des Checkmk-Agenten?

## Übung 2: OpenTelemetry Collector als Deployment (Gateway) einrichten
**Ziel**: Bereitstellung des Collectors als zentrales Gateway, um Daten zu aggregieren und an Backends (Prometheus, Jaeger) zu exportieren.

1. **Schritt 1**: Erstelle eine Konfigurationsdatei für den Gateway-Collector.
   ```bash
   nano otel-gateway-values.yaml
   ```
   - Füge folgendes ein:
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
         prometheus:
           endpoint: "0.0.0.0:8889"
         jaeger:
           endpoint: "jaeger:14250"
           tls:
             insecure: true
       processors:
         batch:
       service:
         pipelines:
           metrics:
             receivers: [otlp]
             processors: [batch]
             exporters: [prometheus]
           traces:
             receivers: [otlp]
             processors: [batch]
             exporters: [jaeger]
     service:
       type: ClusterIP
       ports:
         - name: otlp-grpc
           port: 4317
           targetPort: 4317
           protocol: TCP
         - name: otlp-http
           port: 4318
           targetPort: 4318
           protocol: TCP
         - name: prometheus
           port: 8889
           targetPort: 8889
           protocol: TCP
     ```
   - **Erklärung**:
     - `mode: deployment`: Stellt den Collector als einzelnes Deployment bereit.
     - `exporters`: Sendet Metriken an Prometheus (Port 8889) und Traces an Jaeger.
     - `receivers`: Empfängt Daten von Agenten oder Anwendungen via OTLP (gRPC/HTTP).

2. **Schritt 2**: Bereitstellung von Prometheus und Jaeger.
   - Installiere Prometheus und Jaeger via Helm:
     ```bash
     helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
     helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
     helm repo update
     helm install prometheus prometheus-community/prometheus -n otel
     helm install jaeger jaegertracing/jaeger -n otel
     ```

3. **Schritt 3**: Bereitstellung des Gateway-Collectors.
   ```bash
   helm install otel-gateway open-telemetry/opentelemetry-collector -f otel-gateway-values.yaml -n otel
   ```

4. **Schritt 4**: Überprüfe die Bereitstellung.
   ```bash
   kubectl -n otel get pods -l app.kubernetes.io/name=opentelemetry-collector
   kubectl -n otel get svc
   ```
   - Notiere die Service-Namen (z. B. `otel-gateway-opentelemetry-collector`, `prometheus-server`, `jaeger`).

5. **Schritt 5**: Teste die Metriken/Traces.
   - Greife auf Prometheus zu:
     ```bash
     kubectl -n otel port-forward svc/prometheus-server 9090:9090
     ```
     - Öffne `http://localhost:9090` > Suche nach Metriken (z. B. `otelcol_receiver_accepted_spans`).
   - Greife auf Jaeger zu:
     ```bash
     kubectl -n otel port-forward svc/jaeger 16686:16686
     ```
     - Öffne `http://localhost:16686` > Prüfe Traces.

**Reflexion**: Wie erleichtert das Gateway-Modell die Backend-Integration? Warum ist die Trennung von Agent und Gateway skalierbar?

## Übung 3: Beispielanwendung mit automatischer Instrumentierung
**Ziel**: Instrumentiere eine Beispielanwendung automatisch mit dem OpenTelemetry Operator.

1. **Schritt 1**: Installiere den OpenTelemetry Operator.
   ```bash
   helm install opentelemetry-operator open-telemetry/opentelemetry-operator -n otel
   ```

2. **Schritt 2**: Bereitstelle eine Beispielanwendung.
   - Erstelle eine YAML-Datei:
     ```bash
     nano sample-app.yaml
     ```
   - Füge folgendes ein:
     ```yaml
     apiVersion: apps/v1
     kind: Deployment
     metadata:
       name: sample-app
       namespace: otel
     spec:
       replicas: 1
       selector:
         matchLabels:
           app: sample-app
       template:
         metadata:
           labels:
             app: sample-app
         spec:
           containers:
           - name: sample-app
             image: python:3.9-slim
             command: ["python", "-m", "http.server", "8000"]
     ---
     apiVersion: v1
     kind: Service
     metadata:
       name: sample-app
       namespace: otel
     spec:
       selector:
         app: sample-app
       ports:
       - port: 8000
         targetPort: 8000
     ```
   - Wende an:
     ```bash
     kubectl apply -f sample-app.yaml
     ```

3. **Schritt 3**: Erstelle eine Instrumentation-Ressource.
   ```bash
   nano otel-instrumentation.yaml
   ```
   - Füge folgendes ein:
     ```yaml
     apiVersion: opentelemetry.io/v1alpha1
     kind: Instrumentation
     metadata:
       name: python-instrumentation
       namespace: otel
     spec:
       exporter:
         endpoint: http://otel-gateway-opentelemetry-collector:4318
       propagators:
         - tracecontext
         - baggage
       sampler:
         type: always_on
       python:
         env:
           - name: OTEL_PYTHON_LOG_CORRELATION
             value: "true"
     ```
   - Wende an:
     ```bash
     kubectl apply -f otel-instrumentation.yaml
     ```

4. **Schritt 4**: Teste die Telemetriedaten.
   - Simuliere Anfragen:
     ```bash
     kubectl -n otel port-forward svc/sample-app 8000:8000
     curl http://localhost:8000
     ```
   - In Jaeger (`http://localhost:16686`): Suche nach Traces der `sample-app`.
   - In Prometheus (`http://localhost:9090`): Prüfe Metriken wie `http_server_duration_ms`.

**Reflexion**: Wie vereinfacht der OpenTelemetry Operator die Instrumentierung? Welche Vorteile bietet automatische vs. manuelle Instrumentierung?

## Tipps für den Erfolg
- **Sicherheit**:
  - Sichere die Kubernetes-API mit RBAC und Netzwerkrichtlinien.
  - Aktiviere TLS für OTLP (ändere `insecure: true` zu Zertifikaten).
  - Öffne Ports in der Firewall:
    ```bash
    sudo ufw allow 4317  # OTLP gRPC
    sudo ufw allow 4318  # OTLP HTTP
    sudo ufw allow 9090  # Prometheus
    sudo ufw allow 16686 # Jaeger
    ```
- **Performance**:
  - Konfiguriere `batch`-Prozessor für effiziente Datenverarbeitung.
  - Begrenze Namespaces im Collector, um Datenmengen zu reduzieren.
- **Fehlerbehebung**:
  - Prüfe Pod-Logs: `kubectl -n otel logs -l app.kubernetes.io/name=opentelemetry-collector`.
  - Teste Collector-Verbindung: `curl http://otel-gateway-opentelemetry-collector:4318`.
- **Integration mit Checkmk**:
  - Nutze den Checkmk Prometheus-Exporter, um OpenTelemetry-Metriken in Checkmk zu integrieren (siehe vorherige Anleitung).
  - Konfiguriere Checkmk-Regel für Prometheus: „Setup“ > „Agents“ > „Prometheus“ > Endpoint: `http://<prometheus-server>:9090`.

## Fazit
In dieser Anleitung hast du gelernt, wie du OpenTelemetry in Kubernetes auf Debian 12 einrichtest, um Metriken, Traces und Logs zu sammeln. Du hast den **OpenTelemetry Collector** als **DaemonSet** (Agent) für Host-Metriken und als **Deployment** (Gateway) für zentrale Aggregation bereitgestellt, mit **Prometheus** und **Jaeger** als Backends. Eine Beispielanwendung wurde automatisch instrumentiert. Diese Lösung bietet vendor-neutrale, skalierbare Observability und ergänzt Checkmk für holistische Überwachung. Übe mit Test-Daten, um komplexe Szenarien zu meistern!

**Nächste Schritte**:
- Füge Logs-Collection hinzu (z. B. via Fluentd-Exporter).
- Integriere OpenTelemetry-Daten in Checkmk-Dashboards.
- Erkunde OpenTelemetry für verteilte Tracing in Microservices.

**Quellen**:
- OpenTelemetry-Dokumentation: [https://opentelemetry.io/docs/](https://opentelemetry.io/docs/)
- OpenTelemetry Kubernetes: [https://opentelemetry.io/docs/kubernetes/](https://opentelemetry.io/docs/kubernetes/)
- Helm Charts: [https://open-telemetry.github.io/opentelemetry-helm-charts/](https://open-telemetry.github.io/opentelemetry-helm-charts/)
- Prometheus: [https://prometheus.io/docs/](https://prometheus.io/docs/)
- Jaeger: [https://www.jaegertracing.io/docs/](https://www.jaegertracing.io/docs/)