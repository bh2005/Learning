# Praxisorientierte Anleitung: Kubernetes mit Checkmk überwachen

## Einführung
Kubernetes ist eine weit verbreitete Plattform für containerisierte Anwendungen, und eine effektive Überwachung ist entscheidend, um die Stabilität und Performance von Clustern sicherzustellen. Checkmk bietet zwei leistungsstarke Methoden zur Überwachung: den **Checkmk Agenten als DaemonSet** für die Host-Überwachung und den **Kubernetes-Spezialagenten** für clusterinterne Metriken. Diese Anleitung zeigt, wie du beide Methoden auf einem Debian 12-System einrichtest, um Kubernetes-Nodes, Pods, Container und Deployments zu überwachen. Die Kombination beider Ansätze ermöglicht eine umfassende Überwachung der Infrastruktur und Cluster-Ressourcen.

**Voraussetzungen**:
- Debian 12 mit installiertem Kubernetes-Cluster (z. B. via `kubeadm`) und `kubectl` konfiguriert
- Checkmk-Server (z. B. Checkmk Raw Edition) installiert (siehe [Checkmk-Dokumentation](https://docs.checkmk.com))
- Root- oder Sudo-Zugriff auf dem Debian-System
- Kubernetes-API-Zugriff (z. B. via ServiceAccount und ClusterRole)
- Internetzugang für Paketinstallationen

## Grundlegende Konzepte
1. **Checkmk Agent als DaemonSet**:
   - **Funktion**: Läuft auf jedem Kubernetes-Node (Worker/Master) als Pod und sammelt Host-Metriken (z. B. CPU, RAM, Speicher).
   - **Vorteil**: Skalierbar, effizient, sieht den Host wie eine lokale Installation.
   - **Nutzung**: Überwachung der Infrastruktur (Nodes).
2. **Kubernetes-Spezialagent**:
   - **Funktion**: Läuft als einzelner Pod, greift auf die Kubernetes-API zu und sammelt Cluster-Metriken (Pods, Container, Deployments).
   - **Vorteil**: Detaillierte Einblicke in Cluster-Objekte und Ressourcen.
   - **Nutzung**: Überwachung von Kubernetes-spezifischen Metriken.
3. **Kombination**:
   - DaemonSet-Agent: Host-Überwachung (Infrastruktur).
   - Spezialagent: Cluster-Überwachung (Pods, Deployments).
4. **Debian 12**:
   - Nutzt `apt` für Installationen und `kubectl` für Kubernetes-Management.

## Übung 1: Checkmk Agent als DaemonSet einrichten
**Ziel**: Bereitstellung des Checkmk Agenten als DaemonSet, um Host-Metriken von Kubernetes-Nodes zu sammeln.

1. **Schritt 1**: Prüfe die Checkmk-Umgebung.
   - Stelle sicher, dass der Checkmk-Server läuft:
     ```bash
     sudo systemctl status cmk
     ```
   - Notiere die Checkmk-Server-IP (z. B. `192.168.1.100`) und die Site-ID (z. B. `mysite`).
   - Teste die Verbindung: `telnet 192.168.1.100 6556` (Checkmk-Agent-Port).

2. **Schritt 2**: Erstelle ein DaemonSet-Manifest.
   - Erstelle eine YAML-Datei:
     ```bash
     nano checkmk-agent-daemonset.yaml
     ```
   - Füge folgendes ein:
     ```yaml
     apiVersion: apps/v1
     kind: DaemonSet
     metadata:
       name: checkmk-agent
       namespace: monitoring
     spec:
       selector:
         matchLabels:
           app: checkmk-agent
       template:
         metadata:
           labels:
             app: checkmk-agent
         spec:
           hostNetwork: true
           hostPID: true
           containers:
           - name: checkmk-agent
             image: checkmk/checkmk:2.3.0-latest
             args: ["agent"]
             env:
             - name: CMK_SERVER
               value: "192.168.1.100" # Ersetze mit Checkmk-Server-IP
             - name: CMK_SITE
               value: "mysite" # Ersetze mit deiner Site-ID
             securityContext:
               privileged: true
             volumeMounts:
             - name: host-root
               mountPath: /host
               readOnly: true
           volumes:
           - name: host-root
             hostPath:
               path: /
     ```
   - **Erklärung**:
     - `hostNetwork: true` und `hostPID: true`: Ermöglicht Zugriff auf Host-Metriken.
     - `image: checkmk/checkmk`: Offizielles Checkmk-Image.
     - `CMK_SERVER` und `CMK_SITE`: Verbindet den Agenten mit dem Checkmk-Server.
     - `privileged: true`: Erlaubt Zugriff auf Host-Ressourcen.

3. **Schritt 3**: Erstelle den Namespace und wende das Manifest an.
   ```bash
   kubectl create namespace monitoring
   kubectl apply -f checkmk-agent-daemonset.yaml
   ```

4. **Schritt 4**: Überprüfe die Bereitstellung.
   ```bash
   kubectl -n monitoring get pods -l app=checkmk-agent
   ```
   - Stelle sicher, dass ein Pod pro Node läuft.

5. **Schritt 5**: Konfiguriere Checkmk-Server.
   - Öffne die Checkmk-Weboberfläche (z. B. `http://192.168.1.100/mysite`).
   - Gehe zu „Setup“ > „Hosts“ > „Add host“.
   - Füge jeden Node hinzu (z. B. `node1`, `node2`), mit „Agent type“: „Checkmk agent“.
   - Aktiviere die Überwachung: „Save & go to service discovery“ > „Accept all“.

6. **Schritt 6**: Teste die Metriken.
   - In Checkmk: Gehe zu „Monitor“ > „All hosts“ > Wähle einen Node.
   - Prüfe Metriken wie CPU-Last, RAM-Nutzung, Speicherauslastung.

**Reflexion**: Warum ist `hostNetwork` für den DaemonSet-Agent wichtig? Wie unterscheiden sich die gesammelten Metriken von denen eines normalen Host-Agenten?

## Übung 2: Kubernetes-Spezialagent einrichten
**Ziel**: Bereitstellung des Checkmk Kubernetes-Spezialagenten, um Cluster-Metriken zu sammeln.

1. **Schritt 1**: Erstelle ein ServiceAccount und ClusterRole.
   - Erstelle eine YAML-Datei für RBAC:
     ```bash
     nano checkmk-k8s-rbac.yaml
     ```
   - Füge folgendes ein:
     ```yaml
     apiVersion: v1
     kind: ServiceAccount
     metadata:
       name: checkmk-k8s-agent
       namespace: monitoring
     ---
     apiVersion: rbac.authorization.k8s.io/v1
     kind: ClusterRole
     metadata:
       name: checkmk-k8s-agent
     rules:
     - apiGroups: [""]
       resources: ["nodes", "pods", "services", "namespaces"]
       verbs: ["get", "list", "watch"]
     - apiGroups: ["apps"]
       resources: ["deployments", "daemonsets", "statefulsets"]
       verbs: ["get", "list", "watch"]
     - apiGroups: ["metrics.k8s.io"]
       resources: ["pods", "nodes"]
       verbs: ["get", "list"]
     ---
     apiVersion: rbac.authorization.k8s.io/v1
     kind: ClusterRoleBinding
     metadata:
       name: checkmk-k8s-agent
     subjects:
     - kind: ServiceAccount
       name: checkmk-k8s-agent
       namespace: monitoring
     roleRef:
       kind: ClusterRole
       name: checkmk-k8s-agent
       apiGroup: rbac.authorization.k8s.io
     ```
   - Wende an:
     ```bash
     kubectl apply -f checkmk-k8s-rbac.yaml
     ```

2. **Schritt 2**: Erstelle das Manifest für den Spezialagenten.
   - Erstelle eine YAML-Datei:
     ```bash
     nano checkmk-k8s-agent.yaml
     ```
   - Füge folgendes ein:
     ```yaml
     apiVersion: apps/v1
     kind: Deployment
     metadata:
       name: checkmk-k8s-agent
       namespace: monitoring
     spec:
       replicas: 1
       selector:
         matchLabels:
           app: checkmk-k8s-agent
       template:
         metadata:
           labels:
             app: checkmk-k8s-agent
         spec:
           serviceAccountName: checkmk-k8s-agent
           containers:
           - name: checkmk-k8s-agent
             image: checkmk/checkmk:2.3.0-latest
             args: ["k8s-agent"]
             env:
             - name: CMK_SERVER
               value: "192.168.1.100" # Ersetze mit Checkmk-Server-IP
             - name: CMK_SITE
               value: "mysite" # Ersetze mit deiner Site-ID
             - name: KUBE_TOKEN
               valueFrom:
                 secretKeyRef:
                   name: checkmk-k8s-token
                   key: token
     ---
     apiVersion: v1
     kind: Secret
     metadata:
       name: checkmk-k8s-token
       namespace: monitoring
     type: Opaque
     data:
       token: "" # Wird später gefüllt
     ```
   - Erstelle das Secret mit dem ServiceAccount-Token:
     ```bash
     TOKEN=$(kubectl -n monitoring get secret $(kubectl -n monitoring get sa checkmk-k8s-agent -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 -d)
     kubectl -n monitoring patch secret checkmk-k8s-token -p "{\"data\":{\"token\":\"$(echo -n $TOKEN | base64)\"}}"
     ```

3. **Schritt 3**: Wende das Manifest an.
   ```bash
   kubectl apply -f checkmk-k8s-agent.yaml
   ```

4. **Schritt 4**: Konfiguriere Checkmk-Server.
   - In der Checkmk-Weboberfläche: „Setup“ > „Agents“ > „Kubernetes“ > „Add rule“.
   - Gib Cluster-Details ein:
     - „API-Server“: URL des Kubernetes-API-Servers (z. B. `https://<master-ip>:6443`).
     - „Token“: Verwende den Token aus dem ServiceAccount (optional, da im Pod gesetzt).
     - „Namespaces“: Wähle „All namespaces“ oder spezifische.
   - Speichere und aktiviere: „Save & go to service discovery“ > „Accept all“.

5. **Schritt 5**: Teste die Metriken.
   - In Checkmk: Gehe zu „Monitor“ > „All hosts“ > Wähle den Cluster.
   - Prüfe Metriken wie Pod-Status, Container-CPU/RAM, Deployment-Status.

**Reflexion**: Welche Metriken des Spezialagenten sind für deine Anwendung kritisch? Wie ergänzt er den DaemonSet-Agent?

## Tipps für den Erfolg
- **Sicherheit**:
  - Sichere die Kubernetes-API mit RBAC und Netzwerkrichtlinien.
  - Verwende SSL für Checkmk-Verbindungen (konfiguriere in `/etc/checkmk`).
  - Stelle sicher, dass Port 6556 (Checkmk-Agent) und 6443 (Kubernetes-API) in der Firewall offen sind:
    ```bash
    sudo ufw allow 6556
    sudo ufw allow 6443
    ```
- **Performance**:
  - Begrenze die Abfragefrequenz im Spezialagenten (Checkmk-Einstellung: „Check interval“).
  - Nutze Filter für Namespaces, um Datenmengen zu reduzieren.
- **Fehlerbehebung**:
  - Prüfe Pod-Logs: `kubectl -n monitoring logs -l app=checkmk-agent`.
  - Überprüfe Checkmk-Logs: `sudo journalctl -u cmk`.
  - Teste API-Zugriff: `kubectl cluster-info`.
- **Erweiterung**:
  - Integriere mit Redis für Metriken-Caching (siehe vorherige Anleitungen).
  - Nutze Checkmk-Dashboards für Visualisierungen.

## Fazit
In dieser Anleitung hast du gelernt, wie du Kubernetes mit Checkmk überwachst, indem du den **Checkmk Agenten als DaemonSet** für Host-Metriken und den **Kubernetes-Spezialagenten** für Cluster-Metriken einrichtest. Die DaemonSet-Methode sammelt Infrastrukturdaten (CPU, RAM), während der Spezialagent Pod-, Container- und Deployment-Details liefert. Auf Debian 12 ist die Einrichtung mit `kubectl` und Checkmk einfach umsetzbar. Übe mit Test-Clustern, um die Überwachung zu optimieren, und erweitere sie für Produktionsszenarien!

**Nächste Schritte**:
- Konfiguriere Alarme in Checkmk für kritische Metriken (z. B. Pod-Crash).
- Integriere mit Grafana für erweiterte Visualisierungen.
- Erkunde Checkmk-Plugins für spezifische Kubernetes-Metriken.

**Quellen**:
- Checkmk-Dokumentation: [https://docs.checkmk.com/latest/en/monitoring_kubernetes.html](https://docs.checkmk.com/latest/en/monitoring_kubernetes.html)
- Kubernetes-Dokumentation: [https://kubernetes.io/docs/concepts/overview/working-with-objects/](https://kubernetes.io/docs/concepts/overview/working-with-objects/)
- Debian Kubernetes: [https://wiki.debian.org/Kubernetes](https://wiki.debian.org/Kubernetes)
- Checkmk Kubernetes-Agent: [https://checkmk.com/integrations/kubernetes](https://checkmk.com/integrations/kubernetes)