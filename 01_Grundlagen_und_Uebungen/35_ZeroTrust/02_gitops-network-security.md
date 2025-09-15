# Praxisorientierte Anleitung: GitOps-Workflows für Netzwerksicherheit im On-Premises-HomeLab

## Einführung
GitOps ist ein Ansatz, bei dem alle Infrastruktur- und Anwendungskonfigurationen in einem Git-Repository gespeichert und deklarativ über einen Operator (z. B. ArgoCD) in einem Kubernetes-Cluster angewendet werden. Diese Anleitung zeigt, wie man GitOps-Workflows für Netzwerksicherheit in einem Debian-basierten HomeLab (z. B. mit LXC und Kubernetes) implementiert. Der Fokus liegt auf Zero-Trust-Prinzipien, indem Netzwerksicherheitskonfigurationen wie `iptables`, `nftables` und Kubernetes Network Policies automatisiert verwaltet werden. Ziel ist es, dir praktische Schritte zur Umsetzung von GitOps für sichere Netzwerke zu vermitteln.

Voraussetzungen:
- Ein Debian-basiertes HomeLab mit LXC-Containern und einem Kubernetes-Cluster (z. B. MicroK8s oder K3s).
- Installierte Tools: `ansible`, `kubectl`, `argocd`, `git`, `iptables`, `nftables`, `rsyslog`, `auditd`.
- Ein GitHub-Repository für Konfigurationen.
- Grundkenntnisse in Kubernetes, GitOps und Netzwerksicherheit (z. B. Ports, IP-Bereiche).
- Testumgebung ohne Produktionsdaten.

## Grundlegende Konzepte
Hier sind die wichtigsten Konzepte für GitOps-Workflows mit Netzwerksicherheit:

1. **GitOps-Prinzipien**:
   - **Deklarative Konfiguration**: Alle Netzwerksicherheitsregeln (z. B. Network Policies, `iptables`) in Git.
   - **Automatische Synchronisation**: Operator (z. B. ArgoCD) wendet Änderungen aus Git auf den Cluster an.
   - **Versionierung**: Änderungen sind nachvollziehbar und rollbacks möglich.
2. **Netzwerksicherheit im HomeLab**:
   - **Kubernetes Network Policies**: Steuern Ingress/Egress-Verkehr zwischen Pods.
   - **On-Prem Firewall**: Nutze `iptables` oder `nftables` für Host- und LXC-Sicherheit.
   - **Zero Trust**: Verifiziere jeden Zugriff, beschränke auf Least Privilege.
3. **GitOps-Tools**:
   - **ArgoCD**: Synchronisiert Kubernetes-Ressourcen mit Git.
   - **Ansible**: Konfiguriert On-Prem-Firewalls und Logging.

## Übungen zum Verinnerlichen

### Übung 1: GitOps-Setup mit ArgoCD für Kubernetes Network Policies
**Ziel**: Konfiguriere Netzwerksicherheit mit Kubernetes Network Policies über GitOps.

1. **Schritt 1**: Erstelle ein Git-Repository mit einer Network Policy (`network-policy.yaml`):
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: web-policy
     namespace: default
   spec:
     podSelector:
       matchLabels:
         app: web
     policyTypes:
     - Ingress
     - Egress
     ingress:
     - from:
       - ipBlock:
           cidr: 192.168.1.0/24
       ports:
       - protocol: TCP
         port: 80
     egress:
     - to:
       - ipBlock:
           cidr: 0.0.0.0/0
       ports:
       - protocol: TCP
         port: 443  # Für externe API-Aufrufe
   ```
2. **Schritt 2**: Erstelle ein Ansible-Playbook, um MicroK8s und ArgoCD zu installieren (`setup_k8s_argocd.yml`):
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
3. **Schritt 3**: Konfiguriere ArgoCD für GitOps (`argocd_app.yaml`):
   ```yaml
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: network-security
     namespace: argocd
   spec:
     project: default
     source:
       repoURL: https://github.com/your-username/your-repo.git
       targetRevision: main
       path: k8s
     destination:
       server: https://kubernetes.default.svc
       namespace: default
     syncPolicy:
       automated:
         prune: true
         selfHeal: true
   ```
4. **Schritt 4**: Führe das Setup aus und teste:
   ```bash
   # Installiere Ansible und MicroK8s
   ansible-playbook -i inventory.yml setup_k8s_argocd.yml
   # Füge Network Policy zum Repository
   git add network-policy.yaml
   git commit -m "Add Network Policy"
   git push
   # Wende ArgoCD-Konfiguration an
   microk8s kubectl apply -f argocd_app.yaml
   # Prüfe Synchronisation
   microk8s kubectl get networkpolicy
   # Teste Zugriff
   microk8s kubectl run test-pod --image=nginx --labels=app=web
   curl http://<pod-ip>  # Sollte von 192.168.1.0/24 aus funktionieren
   ```

**Reflexion**: Wie gewährleistet ArgoCD die Konsistenz von Netzwerksicherheitsregeln? Warum ist Git die „Single Source of Truth“?

### Übung 2: On-Prem Firewall mit iptables über GitOps
**Ziel**: Konfiguriere `iptables` für LXC-Container über ein Git-Repository.

1. **Schritt 1**: Erstelle eine iptables-Konfiguration im Git-Repository (`iptables_rules.conf`):
   ```bash
   *filter
   :INPUT DROP [0:0]
   :FORWARD ACCEPT [0:0]
   :OUTPUT ACCEPT [0:0]
   -A INPUT -p tcp --dport 22 -s 192.168.1.0/24 -j ACCEPT
   -A INPUT -p tcp --dport 80 -s your-ip/32 -j ACCEPT
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
   git commit -m "Add iptables GitOps"
   git push
   # Teste lokal
   ansible-playbook -i inventory.yml deploy_iptables.yml
   ssh root@192.168.1.100  # Sollte funktionieren
   curl http://192.168.1.100  # Sollte nur von your-ip funktionieren
   ```

**Reflexion**: Wie unterstützt GitOps die Nachvollziehbarkeit von Firewall-Änderungen? Warum ist `iptables-restore` für Konsistenz wichtig?

### Übung 3: Kontinuierliche Überwachung mit rsyslog und GitOps
**Ziel**: Implementiere zentralisiertes Logging für Netzwerksicherheit über GitOps.

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
   git commit -m "Add rsyslog GitOps"
   git push
   # Teste lokal
   ansible-playbook -i inventory.yml deploy_rsyslog.yml
   logger "Netzwerkzugriff: Test"
   tail -f /var/log/syslog  # Prüfe Logs
   ```

**Reflexion**: Wie stärkt zentralisiertes Logging die Zero-Trust-Überwachung? Wie automatisiert GitOps die Log-Verwaltung?

## Tipps für den Erfolg
- **Least Privilege**: Beschränke Network Policies und `iptables` auf minimale IPs/Ports.
- **Monitoring**: Nutze `auditd` und `rsyslog` für Echtzeit-Logs; integriere mit CloudWatch für hybride Setups.
- **Fehlerbehebung**: Prüfe ArgoCD-Logs (`kubectl logs -n argocd`) und `/var/log/syslog` bei Problemen.
- **Best Practices**: Versioniere alle Konfigurationen in Git, teste lokal vor CI/CD, nutze `ansible-lint`.
- **2025-Fokus**: Erkunde GitOps-Tools wie Flux oder erweiterte ArgoCD-Features (z. B. App of Apps).

## Fazit
Du hast gelernt, GitOps-Workflows für Netzwerksicherheit im HomeLab zu implementieren, indem du Kubernetes Network Policies, `iptables` und Logging über ArgoCD und Ansible aus einem Git-Repository anwendest. Diese Übungen stärken die Automatisierung und Sicherheit deines Setups. Wiederhole sie, um GitOps zu verinnerlichen.

**Nächste Schritte**:
- Erkunde Flux als Alternative zu ArgoCD.
- Integriere hybride Cloud-Verbindungen (z. B. AWS VPN).
- Vertiefe dich in Sicherheits-Checks mit `checkov` für Kubernetes.

**Quellen**: ArgoCD Docs, Kubernetes NetworkPolicy Docs, Ansible Docs, Debian Security Docs.