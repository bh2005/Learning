# Praxisorientierte Anleitung: Distributed Tracing für Netzwerksicherheit mit GitOps im On-Premises-HomeLab

## Einführung
Distributed Tracing ermöglicht die Nachverfolgung von Anfragen durch verteilte Systeme, um Latenz, Fehler und Sicherheitsvorfälle (z. B. unbefugte Zugriffe) zu analysieren. Diese Anleitung zeigt, wie man Distributed Tracing mit OpenTelemetry und Jaeger in einem Debian-basierten HomeLab (z. B. mit LXC und Kubernetes) implementiert, um Netzwerksicherheit zu stärken. Alle Konfigurationen werden in einem Git-Repository gespeichert und über ArgoCD (GitOps) angewendet, um Zero-Trust-Prinzipien wie kontinuierliche Überwachung und Least Privilege zu gewährleisten. Ziel ist es, dir praktische Schritte zur Überwachung von Netzwerkverkehr und zur Erkennung von Anomalien zu vermitteln.

Voraussetzungen:
- Ein Debian-basiertes HomeLab mit LXC-Containern und einem Kubernetes-Cluster (z. B. MicroK8s oder K3s).
- Installierte Tools: `ansible`, `kubectl`, `argocd`, `git`, `iptables`, `rsyslog`, `auditd`, `docker` (für Jaeger).
- Ein GitHub-Repository für Konfigurationen.
- Grundkenntnisse in Kubernetes, GitOps, Netzwerksicherheit und Tracing.
- Testumgebung ohne Produktionsdaten.

## Grundlegende Konzepte
Hier sind die wichtigsten Konzepte für Distributed Tracing mit GitOps:

1. **Distributed Tracing**:
   - **Funktion**: Verfolgt Anfragen über Systemgrenzen hinweg (z. B. zwischen LXC-Containern, Kubernetes-Pods oder Cloud-Diensten).
   - **Tools**: OpenTelemetry (Instrumentation), Jaeger (Visualisierung/Storage).
   - **Zero Trust**: Erkennt unbefugte Zugriffe durch Anomalien in Trace-Daten.
2. **GitOps-Integration**:
   - Konfigurationen (z. B. Tracing-Agent, Network Policies) in Git speichern.
   - ArgoCD synchronisiert Konfigurationen mit dem Kubernetes-Cluster.
3. **On-Prem Netzwerksicherheit**:
   - Kombiniere Tracing mit `iptables` und Kubernetes Network Policies für Least Privilege.
   - Nutze `rsyslog` und `auditd` für zentralisierte Logs und Sicherheitsüberwachung.

## Übungen zum Verinnerlichen

### Übung 1: OpenTelemetry und Jaeger für Tracing im Kubernetes-Cluster
**Ziel**: Installiere und konfiguriere OpenTelemetry und Jaeger über GitOps für Netzwerküberwachung.

1. **Schritt 1**: Erstelle eine Kubernetes-Konfiguration für Jaeger und OpenTelemetry im Git-Repository (`k8s/jaeger.yaml`):
   ```yaml
   apiVersion: v1
   kind: Namespace
   metadata:
     name: tracing
   ---
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: jaeger
     namespace: tracing
   spec:
     selector:
       matchLabels:
         app: jaeger
     template:
       metadata:
         labels:
           app: jaeger
       spec:
         containers:
         - name: jaeger
           image: jaegertracing/all-in-one:latest
           ports:
           - containerPort: 16686  # Jaeger UI
           - containerPort: 4317   # OpenTelemetry gRPC
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: jaeger
     namespace: tracing
   spec:
     selector:
       app: jaeger
     ports:
     - name: ui
       port: 16686
       targetPort: 16686
     - name: otel-grpc
       port: 4317
       targetPort: 4317
   ```
2. **Schritt 2**: Erstelle eine Network Policy für Tracing (`k8s/network-policy.yaml`):
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: tracing-policy
     namespace: tracing
   spec:
     podSelector:
       matchLabels:
         app: jaeger
     policyTypes:
     - Ingress
     ingress:
     - from:
       - ipBlock:
           cidr: 192.168.1.0/24  # HomeLab-Netzwerk
       ports:
       - protocol: TCP
         port: 16686
       - protocol: TCP
         port: 4317
   ```
3. **Schritt 3**: Erstelle ein Ansible-Playbook, um MicroK8s und ArgoCD zu installieren (`setup_k8s_argocd.yml`):
   ```yaml
   - name: Installiere MicroK8s und ArgoCD
     hosts: k8s_nodes
     tasks:
       - name: Installiere MicroK8s
         ansible.builtin.shell: snap install microk8s --classic
       - name: Aktiviere MicroK8s Addons
         ansible.builtin.command: microk8s enable dns storage
       - name: Installiere ArgoCD
         ansible.builtin.shell: |
           microk8s kubectl create namespace argocd
           microk8s kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
       - name: Warte auf ArgoCD
         ansible.builtin.command: microk8s kubectl wait --for=condition=available --timeout=300s deployment -l app.kubernetes.io/name=argocd-server -n argocd
   ```
4. **Schritt 4**: Konfiguriere ArgoCD für GitOps (`k8s/argocd_app.yaml`):
   ```yaml
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: tracing
     namespace: argocd
   spec:
     project: default
     source:
       repoURL: https://github.com/your-username/your-repo.git
       targetRevision: main
       path: k8s
     destination:
       server: https://kubernetes.default.svc
       namespace: tracing
     syncPolicy:
       automated:
         prune: true
         selfHeal: true
   ```
5. **Schritt 5**: Führe das Setup aus und teste:
   ```bash
   # Installiere Ansible und MicroK8s
   ansible-playbook -i inventory.yml setup_k8s_argocd.yml
   # Füge Konfigurationen zum Repository
   git add k8s/
   git commit -m "Add Jaeger and Network Policy"
   git push
   # Wende ArgoCD-Konfiguration an
   microk8s kubectl apply -f k8s/argocd_app.yaml
   # Prüfe Jaeger UI
   microk8s kubectl port-forward svc/jaeger 16686:16686 -n tracing
   # Öffne http://localhost:16686 im Browser
   ```

**Reflexion**: Wie unterstützt Distributed Tracing die Erkennung von Netzwerkanomalien? Warum ist GitOps für Tracing-Konfigurationen vorteilhaft?

### Übung 2: On-Prem Firewall mit iptables und Tracing-Integration
**Ziel**: Konfiguriere `iptables` für LXC-Container und integriere Tracing-Daten.

1. **Schritt 1**: Erstelle eine iptables-Konfiguration im Git-Repository (`iptables_rules.conf`):
   ```bash
   *filter
   :INPUT DROP [0:0]
   :FORWARD ACCEPT [0:0]
   :OUTPUT ACCEPT [0:0]
   -A INPUT -p tcp --dport 22 -s 192.168.1.0/24 -j ACCEPT
   -A INPUT -p tcp --dport 4317 -s 192.168.1.0/24 -j ACCEPT  # OpenTelemetry
   COMMIT
   ```
2. **Schritt 2**: Erstelle ein Ansible-Playbook für iptables-Deployment (`deploy_iptables.yml`):
   ```yaml
   - name: Wende iptables-Regeln über GitOps an
     hosts: lxc_hosts
     tasks:
       - name: Installiere iptables
         ansible.builtin.apt:
           name: iptables
           state: present
           update_cache: yes
       - name: Kopiere iptables-Regeln aus Git
         ansible.builtin.copy:
           src: iptables_rules.conf
           dest: /etc/iptables/rules.v4
           mode: '0644'
       - name: Lade iptables-Regeln
         ansible.builtin.command: iptables-restore < /etc/iptables/rules.v4
   ```
3. **Schritt 3**: Integriere in GitHub Actions (`.github/workflows/iptables-gitops.yml`):
   ```yaml
   name: Deploy iptables via GitOps
   on:
     push:
       branches: [ main ]
   jobs:
     deploy:
       runs-on: ubuntu-latest
       steps:
       - uses: actions/checkout@v3
       - name: Installiere Ansible
         run: pip install ansible
       - name: Führe Playbook aus
         run: ansible-playbook -i inventory.yml deploy_iptables.yml
   ```
4. **Schritt 4**: Pushe und teste:
   ```bash
   git add iptables_rules.conf deploy_iptables.yml
   git commit -m "Add iptables for Tracing"
   git push
   ansible-playbook -i inventory.yml deploy_iptables.yml
   # Teste Tracing-Port
   nc -zv 192.168.1.100 4317  # Sollte von 192.168.1.0/24 aus funktionieren
   ```

**Reflexion**: Wie ergänzt `iptables` die Tracing-Sicherheit? Warum ist die Versionierung von Firewall-Regeln wichtig?

### Übung 3: Kontinuierliche Überwachung mit rsyslog und GitOps
**Ziel**: Implementiere zentralisiertes Logging für Tracing-Daten über GitOps.

1. **Schritt 1**: Erstelle eine rsyslog-Konfiguration im Git-Repository (`rsyslog.conf`):
   ```bash
   *.* @your-log-server:514
   ```
2. **Schritt 2**: Erstelle ein Ansible-Playbook für Logging (`deploy_rsyslog.yml`):
   ```yaml
   - name: Konfiguriere rsyslog über GitOps
     hosts: lxc_hosts
     tasks:
       - name: Installiere rsyslog
         ansible.builtin.apt:
           name: rsyslog
           state: present
       - name: Kopiere rsyslog-Konfiguration
         ansible.builtin.copy:
           src: rsyslog.conf
           dest: /etc/rsyslog.conf
           mode: '0644'
       - name: Starte rsyslog
         ansible.builtin.service:
           name: rsyslog
           state: restarted
   ```
3. **Schritt 3**: Integriere in GitHub Actions (siehe Übung 2, erweitere für `deploy_rsyslog.yml`).
4. **Schritt 4**: Pushe und teste:
   ```bash
   git add rsyslog.conf deploy_rsyslog.yml
   git commit -m "Add rsyslog for Tracing"
   git push
   ansible-playbook -i inventory.yml deploy_rsyslog.yml
   logger "Tracing Test: Access Attempt"
   tail -f /var/log/syslog  # Prüfe Logs
   # Prüfe Jaeger für Tracing-Daten
   microk8s kubectl port-forward svc/jaeger 16686:16686 -n tracing
   ```

**Reflexion**: Wie unterstützt rsyslog die Nachverfolgung von Tracing-Daten? Wie stärkt GitOps die Automatisierung?

## Tipps für den Erfolg
- **Least Privilege**: Beschränke Network Policies und `iptables` auf minimale IPs/Ports (z. B. 4317 für OpenTelemetry).
- **Monitoring**: Nutze Jaeger für visuelle Trace-Analyse; integriere `auditd` für Sicherheitslogs.
- **Fehlerbehebung**: Prüfe ArgoCD-Logs (`kubectl logs -n argocd`) und `/var/log/syslog` bei Problemen.
- **Best Practices**: Versioniere alle Konfigurationen in Git, teste lokal vor CI/CD, nutze `ansible-lint`.
- **2025-Fokus**: Erkunde OpenTelemetry-Integration mit Cloud-Diensten (z. B. AWS X-Ray) für hybride Setups.

## Fazit
Du hast gelernt, Distributed Tracing mit OpenTelemetry und Jaeger in einem HomeLab-Kubernetes-Cluster über GitOps-Workflows zu implementieren, kombiniert mit `iptables` und `rsyslog` für Netzwerksicherheit. Diese Übungen stärken die Überwachung und Sicherheit deines Setups. Wiederhole sie, um Tracing und GitOps zu verinnerlichen.

**Nächste Schritte**:
- Erkunde Cloud-Tracing-Dienste (z. B. AWS X-Ray, GCP Cloud Trace).
- Integriere hybride Verbindungen (z. B. WireGuard VPN).
- Vertiefe dich in Sicherheits-Checks mit `checkov` für Tracing-Konfigurationen.

**Quellen**: OpenTelemetry Docs, Jaeger Docs, ArgoCD Docs, Kubernetes NetworkPolicy Docs, Ansible Docs.