# Praxisorientierte Anleitung: Integration von Check_MK und OpenTelemetry mit Jaeger für Tracing im Debian-basierten HomeLab

## Einführung
Check_MK ist ein umfassendes Monitoring-Tool für IT-Infrastrukturen, das Server, Netzwerke und Services überwacht. OpenTelemetry ist ein Standard für Distributed Tracing, der mit Jaeger (einem Open-Source-Tracing-System) integriert werden kann, um Anfragen durch verteilte Systeme zu verfolgen. Diese Anleitung zeigt, wie man Check_MK und OpenTelemetry mit Jaeger in einem Debian-basierten HomeLab (z. B. mit LXC-Containern) integriert, um Netzwerkverkehr und Anomalien zu überwachen. Konfigurationen werden in einem Git-Repository gespeichert und über Ansible mit GitHub Actions angewendet, um Zero-Trust-Prinzipien zu unterstützen. Ziel ist es, dir praktische Schritte zur Kombination von Monitoring und Tracing für verbesserte Beobachtbarkeit zu vermitteln.

Voraussetzungen:
- Ein Debian-basiertes HomeLab mit LXC-Containern (z. B. `game-container`).
- Installierte Tools: `ansible`, `git`, `python3`, `docker` (für Jaeger), `iptables`, `rsyslog`, `auditd`.
- Ein GitHub-Repository für Konfigurationen.
- Grundkenntnisse in Python, Ansible, GitOps und Netzwerksicherheit.
- Testumgebung ohne Produktionsdaten; simulierte Netzwerkdaten.

## Grundlegende Konzepte
Hier sind die wichtigsten Konzepte für die Integration von Check_MK und OpenTelemetry mit Jaeger:

1. **Check_MK**:
   - **Funktion**: Überwacht Ressourcen (CPU, RAM, Netzwerk) und sendet Alerts bei Anomalien.
   - **Integration**: Erweitert mit Plugins für Tracing-Daten (z. B. Jaeger-Logs).
2. **OpenTelemetry mit Jaeger**:
   - **Funktion**: Sammelt Traces (Spannweiten) für verteilte Anfragen und visualisiert sie in Jaeger.
   - **Zero Trust**: Erkennt unbefugte Zugriffe durch Trace-Analyse.
3. **GitOps-Integration**:
   - Speichere Konfigurationen (Check_MK, Jaeger) in Git.
   - Ansible wendet Konfigurationen auf LXC-Container an.

## Übungen zum Verinnerlichen

### Übung 1: Check_MK installieren und konfigurieren
**Ziel**: Installiere Check_MK und konfiguriere grundlegende Überwachung.

1. **Schritt 1**: Erstelle ein Ansible-Playbook für Check_MK (`deploy_checkmk.yml`):
   ```yaml
   - name: Installiere und konfiguriere Check_MK
     hosts: lxc_hosts
     tasks:
       - name: Installiere Check_MK (via Docker)
         ansible.builtin.shell: |
           docker run -d --name checkmk \
             -p 8080:5000 \
             -v /opt/checkmk:/omd/sites/cmk \
             checkmk/check-mk-raw:2023.10.0
       - name: Erstelle Check_MK-Konfiguration
         ansible.builtin.copy:
           content: |
             # Überwache CPU, RAM, Netzwerk
             omd config set APACHE_TCP_ADDR 0.0.0.0
             omd config set APACHE_TCP_PORT 8080
             omd start
           dest: /tmp/checkmk_setup.sh
           mode: '0755'
       - name: Führe Setup aus
         ansible.builtin.shell: /tmp/checkmk_setup.sh
   ```
2. **Schritt 2**: Pushe ins Repository und teste:
   ```bash
   git add deploy_checkmk.yml
   git commit -m "Add Check_MK deployment"
   git push
   ansible-playbook -i inventory.yml deploy_checkmk.yml
   # Zugriff auf Check_MK UI
   curl http://192.168.1.100:8080
   # Login: cmkadmin / cmk
   ```
3. **Schritt 3**: Konfiguriere Überwachung für LXC:
   ```bash
   # In Check_MK UI: Add Host > 192.168.1.100 (LXC-Host)
   # Überwache Services: CPU, Memory, Network Interfaces
   ```

**Reflexion**: Wie unterstützt Check_MK die Überwachung von Netzwerkressourcen? Warum ist Docker-Integration nützlich?

### Übung 2: OpenTelemetry mit Jaeger für Tracing implementieren
**Ziel**: Installiere Jaeger und integriere OpenTelemetry für Tracing.

1. **Schritt 1**: Erstelle ein Ansible-Playbook für Jaeger (`deploy_jaeger.yml`):
   ```yaml
   - name: Installiere Jaeger mit Docker
     hosts: lxc_hosts
     tasks:
       - name: Installiere Docker
         ansible.builtin.apt:
           name: docker.io
           state: present
           update_cache: yes
       - name: Starte Jaeger
         ansible.builtin.shell: |
           docker run -d --name jaeger \
             -p 16686:16686 \
             -p 4317:4317 \
             -p 4318:4318 \
             jaegertracing/all-in-one:latest
       - name: Erstelle OpenTelemetry-Konfiguration
         ansible.builtin.copy:
           content: |
             exporters:
               otlp:
                 endpoint: localhost:4317
             service:
               pipelines:
                 traces:
                   exporters: [otlp]
             receivers:
               otlp:
                 protocols:
                   grpc:
                     endpoint: 0.0.0.0:4317
           dest: /etc/otelcol/config.yaml
           mode: '0644'
       - name: Installiere OpenTelemetry Collector
         ansible.builtin.shell: |
           curl -L https://github.com/open-telemetry/opentelemetry-collector/releases/download/v0.96.0/otelcol-contrib_0.96.0_linux_amd64.tar.gz | tar xz
           mv otelcol-contrib /usr/local/bin/otelcol
           otelcol --config /etc/otelcol/config.yaml &
   ```
2. **Schritt 2**: Erstelle ein Python-Skript für OpenTelemetry-Tracing (`tracing/app.py`):
   ```python
   from opentelemetry import trace
   from opentelemetry.sdk.trace import TracerProvider
   from opentelemetry.sdk.trace.export import BatchSpanProcessor
   from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
   from opentelemetry.sdk.resources import Resource

   # Konfiguriere Tracer
   trace.set_tracer_provider(TracerProvider(resource=Resource.create({"service.name": "home-lab-app"})))
   tracer = trace.get_tracer(__name__)
   otlp_exporter = OTLPSpanExporter(endpoint="localhost:4317", insecure=True)
   span_processor = BatchSpanProcessor(otlp_exporter)
   trace.get_tracer_provider().add_span_processor(span_processor)

   with tracer.start_as_current_span("network_request") as span:
       span.set_attribute("http.method", "GET")
       span.set_attribute("net.peer.ip", "192.168.1.100")
       print("Tracing network request...")
   ```
3. **Schritt 3**: Pushe und teste:
   ```bash
   git add deploy_jaeger.yml tracing/
   git commit -m "Add Jaeger and OpenTelemetry"
   git push
   ansible-playbook -i inventory.yml deploy_jaeger.yml
   pip install opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp-proto-grpc
   python3 /app/tracing/app.py
   # Zugriff auf Jaeger UI
   curl http://192.168.1.100:16686
   ```

**Reflexion**: Wie verbessert OpenTelemetry die Nachverfolgung von Netzwerkanfragen? Warum ist Jaeger für Visualisierung nützlich?

### Übung 3: Check_MK und Jaeger integrieren für Monitoring und Tracing
**Ziel**: Integriere Check_MK mit Jaeger-Logs für umfassende Überwachung.

1. **Schritt 1**: Erstelle ein Ansible-Playbook für Integration (`integrate_checkmk_jaeger.yml`):
   ```yaml
   - name: Integriere Check_MK mit Jaeger
     hosts: lxc_hosts
     tasks:
       - name: Installiere Check_MK Plugin für Tracing
         ansible.builtin.shell: |
           docker exec checkmk pip install opentelemetry-api opentelemetry-sdk
       - name: Konfiguriere Check_MK für Jaeger-Logs
         ansible.builtin.copy:
           content: |
             # In Check_MK: Add Special Agent > Jaeger
             # Endpoint: http://localhost:16686
             # Überwache Traces und Metrics
           dest: /tmp/checkmk_jaeger_setup.sh
           mode: '0755'
       - name: Führe Integration aus
         ansible.builtin.shell: /tmp/checkmk_jaeger_setup.sh
       - name: Konfiguriere rsyslog für Jaeger-Logs
         ansible.builtin.copy:
           content: "*.* @your-log-server:514"
           dest: /etc/rsyslog.conf
           mode: '0644'
       - name: Starte rsyslog
         ansible.builtin.service:
           name: rsyslog
           state: restarted
   ```
2. **Schritt 2**: Pushe und teste:
   ```bash
   git add integrate_checkmk_jaeger.yml
   git commit -m "Add Check_MK Jaeger Integration"
   git push
   ansible-playbook -i inventory.yml integrate_checkmk_jaeger.yml
   # In Check_MK UI: Überwache Jaeger-Service
   # Generiere Test-Traces
   python3 /app/tracing/app.py
   # Prüfe Logs in Check_MK
   tail -f /var/log/syslog
   ```
3. **Schritt 3**: Überwache in Check_MK:
   - Add Host > Jaeger-Endpoint (localhost:16686).
   - Überwache Metrics: Trace Count, Latency.

**Reflexion**: Wie verbessert die Integration von Check_MK und Jaeger die Beobachtbarkeit? Warum ist zentralisiertes Logging entscheidend?

## Tipps für den Erfolg
- **Least Privilege**: Beschränke `iptables` auf Tracing-Ports (z. B. 4317, 16686).
- **Monitoring**: Nutze Check_MK-Alerts für Jaeger-Down-Zeiten; integriere `auditd` für Sicherheitslogs.
- **Fehlerbehebung**: Prüfe Docker-Logs (`docker logs checkmk`) und `/var/log/syslog`.
- **Best Practices**: Versioniere Konfigurationen in Git, teste lokal vor CI/CD, nutze `ansible-lint`.
- **2025-Fokus**: Erkunde erweiterte Tracing mit OpenTelemetry-Metrics und Check_MK-Dashboards.

## Fazit
Du hast gelernt, Check_MK und OpenTelemetry mit Jaeger in einem Debian-basierten HomeLab zu integrieren, um Monitoring und Tracing für Netzwerksicherheit zu verbessern. Diese Übungen stärken die Automatisierung und Beobachtbarkeit deines Setups. Wiederhole sie, um die Integration zu verinnerlichen.

**Nächste Schritte**:
- Erkunde Check_MK-Plugins für fortgeschrittene Tracing.
- Integriere mit Cloud-Monitoring (z. B. AWS CloudWatch).
- Vertiefe dich in Sicherheits-Checks mit `checkov` für Konfigurationen.

**Quellen**: Check_MK Docs, OpenTelemetry Docs, Jaeger Docs, Ansible Docs.