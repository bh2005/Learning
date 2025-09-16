# Praxisorientierte Anleitung: Disaster Recovery für Linux-Cluster

## Einführung
Disaster Recovery (DR) für Linux-Cluster beinhaltet Strategien und Tools, um hochverfügbare Systeme wie Cluster (z. B. HA-Cluster mit Pacemaker/Corosync oder Kubernetes) nach Ausfällen wie Hardwaredefekten, Softwarefehlern oder Cyberangriffen wiederherzustellen. Diese Anleitung konzentriert sich auf DR-Grundlagen für Linux-Cluster auf Debian, mit Fokus auf **Pacemaker/Corosync** für HA-Cluster und **Kubernetes** für containerisierte Workloads. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, effektive DR-Pläne für Linux-Cluster zu erstellen und umzusetzen. Diese Anleitung ist ideal für Administratoren, die resiliente Cluster-Umgebungen sicherstellen möchten.

**Voraussetzungen:**
- Ein Debian-basierter Cluster (z. B. Debian 11 oder 12) mit mindestens zwei Knoten
- Administratorrechte (Root oder Sudo)
- Grundlegende Kenntnisse der Linux-Kommandozeile und Cluster-Technologien
- Externer Speicher (z. B. NFS, Cloud) für Backups
- Netzwerkverbindung für Replikation und Offsite-Backups

## Grundlegende Disaster Recovery-Konzepte für Linux-Cluster
Hier sind die wichtigsten Konzepte, die wir behandeln:

1. **DR-Komponenten**:
   - **Replikation**: Synchronisation von Daten und Konfigurationen zwischen Knoten oder Standorten.
   - **Failover**: Automatische Umschaltung auf einen Standby-Knoten bei Ausfall.
   - **Failback**: Rückkehr zum primären Knoten nach Wiederherstellung.
   - **Point-in-Time Recovery**: Wiederherstellung zu einem bestimmten Zeitpunkt.
2. **Cluster-spezifische DR-Aspekte**:
   - **HA-Cluster**: Verwaltung von Ressourcen (z. B. IP-Adressen, Dienste) mit Pacemaker/Corosync.
   - **Kubernetes**: Wiederherstellung von Control Planes, Workloads und persistenten Daten.
   - **RTO/RPO**: Recovery Time Objective (Zeit bis Wiederherstellung) und Recovery Point Objective (Datenverlust).
3. **Best Practices**:
   - 3-2-1-Regel: 3 Kopien, 2 Medien, 1 offsite.
   - Regelmäßige DR-Tests und Dokumentation.

## Übungen zum Verinnerlichen

### Übung 1: Disaster Recovery für Pacemaker/Corosync HA-Cluster
**Ziel**: Lernen, wie man einen HA-Cluster mit Pacemaker/Corosync sichert und nach einem Ausfall wiederherstellt.

1. **Schritt 1**: Konfiguriere einen einfachen HA-Cluster.
   - Installiere Pacemaker/Corosync auf zwei Debian-Knoten:
     ```bash
     sudo apt update
     sudo apt install -y pacemaker corosync pcs
     ```
   - Konfiguriere Corosync (z. B. `/etc/corosync/corosync.conf`):
     ```bash
     sudo nano /etc/corosync/corosync.conf
     ```
     Beispiel:
     ```
     totem {
         version: 2
         cluster_name: mycluster
         transport: knet
     }
     nodelist {
         node {
             ring0_addr: node1
             nodeid: 1
         }
         node {
             ring0_addr: node2
             nodeid: 2
         }
     }
     ```
   - Starte Dienste:
     ```bash
     sudo systemctl enable --now corosync pacemaker
     sudo pcs cluster auth node1 node2 -u hacluster -p <password>
     sudo pcs cluster setup mycluster node1 node2
     sudo pcs cluster start --all
     ```
   - Füge eine Ressource hinzu (z. B. virtuelle IP):
     ```bash
     sudo pcs resource create vip ocf:heartbeat:IPaddr2 ip=192.168.1.100 cidr_netmask=24 op monitor interval=10s
     ```
2. **Schritt 2**: Erstelle ein Backup des Clusters.
   - Sichere Konfigurationen:
     ```bash
     sudo pcs config backup cluster_backup
     sudo rsync -av /etc/corosync /etc/pacemaker /media/backup/cluster-$(date +%Y%m%d)
     ```
   - Sichere Daten (z. B. einer App wie Nginx):
     ```bash
     sudo rsync -av /var/www /media/backup/www-$(date +%Y%m%d)
     ```
3. **Schritt 3**: Simuliere und teste einen Restore.
   - Simuliere Ausfall: `sudo systemctl stop corosync pacemaker` auf node1.
   - Restore Konfigurationen:
     ```bash
     sudo rsync -av /media/backup/cluster-20250916/ /etc/
     sudo pcs config restore cluster_backup.tar.bz2
     sudo systemctl restart corosync pacemaker
     ```
   - Überprüfe Cluster-Status:
     ```bash
     sudo pcs status
     ```
4. **Schritt 4**: Dokumentiere den DR-Plan.
   - Beispiel:
     ```
     - Backup: Täglich Konfigurationen und Daten auf NFS
     - RPO: 24 Stunden, RTO: 30 Minuten
     - Restore: rsync für Daten, pcs config restore für Cluster
     ```

**Reflexion**: Warum ist die Sicherung der Cluster-Konfiguration entscheidend, und wie unterstützt Pacemaker automatisches Failover?

### Übung 2: Disaster Recovery für Kubernetes-Cluster
**Ziel**: Verstehen, wie man einen Kubernetes-Cluster sichert und nach einem Ausfall wiederherstellt.

1. **Schritt 1**: Installiere einen Kubernetes-Cluster (z. B. mit kubeadm).
   - Auf Debian-Knoten:
     ```bash
     sudo apt update
     sudo apt install -y docker.io kubeadm kubectl kubelet
     sudo systemctl enable --now docker kubelet
     ```
   - Initialisiere Master:
     ```bash
     sudo kubeadm init --pod-network-cidr=10.244.0.0/16
     ```
   - Konfiguriere kubectl:
     ```bash
     mkdir -p $HOME/.kube
     sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
     sudo chown $(id -u):$(id -g) $HOME/.kube/config
     ```
   - Installiere CNI (z. B. Flannel):
     ```bash
     kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
     ```
   - Füge Worker-Knoten hinzu (mit `kubeadm join` vom Master).
2. **Schritt 2**: Sichere den Cluster mit Velero.
   - Installiere Velero CLI:
     ```bash
     wget https://github.com/vmware-tanzu/velero/releases/download/v1.14.0/velero-v1.14.0-linux-amd64.tar.gz
     tar -xvf velero-v1.14.0-linux-amd64.tar.gz
     sudo mv velero-v1.14.0-linux-amd64/velero /usr/local/bin/
     ```
   - Konfiguriere Velero mit Cloud-Storage (z. B. AWS S3):
     ```bash
     velero install --provider aws --plugins velero/velero-plugin-for-aws:v1.10.0 \
       --bucket k8s-backups --backup-location-config region=us-east-1 \
       --secret-file ./credentials-velero
     ```
     Beispiel `credentials-velero`:
     ```
     [default]
     aws_access_key_id = <AWS_ACCESS_KEY>
     aws_secret_access_key = <AWS_SECRET_KEY>
     ```
   - Erstelle ein Backup:
     ```bash
     velero backup create k8s-backup-$(date +%Y%m%d) --include-cluster-resources=true
     ```
3. **Schritt 3**: Teste einen Restore.
   - Simuliere Ausfall: Lösche einen Namespace:
     ```bash
     kubectl delete namespace default
     ```
   - Restore:
     ```bash
     velero restore create --from-backup k8s-backup-20250916
     ```
   - Überprüfe: `kubectl get pods -A`.
4. **Schritt 4**: Dokumentiere den DR-Plan.
   - Beispiel:
     ```
     - Backup: Täglich Velero zu S3
     - RPO: 24 Stunden, RTO: 1 Stunde
     - Restore: Velero restore, kubeadm für Control Plane
     ```

**Reflexion**: Wie unterstützt Velero Point-in-Time-Recovery, und warum ist die Sicherung der etcd-Datenbank entscheidend?

### Übung 3: Automatisierte DR-Tests und Offsite-Replikation
**Ziel**: Lernen, wie man DR-Tests automatisiert und Offsite-Replikation einrichtet.

1. **Schritt 1**: Erstelle ein DR-Test-Skript für Pacemaker.
   ```bash
   sudo nano /root/dr_test.sh
   ```
   Inhalt:
   ```bash
   #!/bin/bash
   # Simuliere Ausfall und teste Restore
   NODE="node1"
   BACKUP_DIR="/media/backup"
   sudo pcs cluster stop $NODE
   sudo rsync -av $BACKUP_DIR/cluster-$(date +%Y%m%d) /etc/
   sudo pcs config restore $BACKUP_DIR/cluster_backup.tar.bz2
   sudo pcs cluster start $NODE
   sudo pcs status
   ```
   Mach es ausführbar:
   ```bash
   chmod +x /root/dr_test.sh
   ```
2. **Schritt 2**: Plane den Test mit Cron.
   ```bash
   crontab -e
   ```
   Füge hinzu (wöchentlich, Sonntag 03:00):
   ```
   0 3 * * 0 /root/dr_test.sh >> /var/log/dr_test.log 2>&1
   ```
3. **Schritt 3**: Konfiguriere Offsite-Replikation für Kubernetes.
   - Erstelle einen zweiten S3-Bucket in einer anderen Region (z. B. us-west-2).
   - Nutze Velero für Cross-Region-Sync:
     ```bash
     velero backup-location create secondary --provider aws \
       --bucket k8s-backups-secondary --config region=us-west-2 \
       --secret-file ./credentials-velero-secondary
     ```
   - Plane Sync:
     ```bash
     velero schedule create offsite-sync --schedule "@every 24h" \
       --backup-location secondary
     ```
4. **Schritt 4**: Dokumentiere den DR-Plan.
   - Beispiel:
     ```
     - Backup: Täglich Velero (Kubernetes), wöchentlich rsync (HA-Cluster)
     - Offsite: S3 (us-west-2), NFS (sekundäres Rechenzentrum)
     - RPO: 24 Stunden, RTO: 2 Stunden
     - Test: Wöchentlich automatisiert, vierteljährlich manuell
     ```

**Reflexion**: Warum sind automatisierte DR-Tests kritisch, und wie verbessert Offsite-Replikation die Resilienz?

## Tipps für den Erfolg
- Testen Sie DR-Pläne vierteljährlich durch simulierte Ausfälle (z. B. Knotenabschaltung).
- Verwenden Sie die 3-2-1-Regel: 3 Kopien, 2 Medien, 1 offsite (z. B. AWS S3).
- Überwachen Sie Cluster-Gesundheit mit Tools wie `pcs status` oder `kubectl get nodes`.
- Dokumentieren Sie alle Schritte, Zugangsdaten und Verantwortlichkeiten.

## Fazit
In dieser Anleitung haben Sie die Grundlagen des Disaster Recovery für Linux-Cluster (Pacemaker/Corosync und Kubernetes) auf Debian erkundet. Durch die Übungen haben Sie praktische Erfahrung mit Backups, Restores, Automatisierung und Offsite-Replikation gesammelt. Diese Fähigkeiten sind essenziell für die Aufrechterhaltung hochverfügbarer Cluster. Üben Sie weiter, um Multi-Cloud-DR oder Integration mit Monitoring-Tools zu meistern!

**Nächste Schritte**:
- Integrieren Sie Monitoring-Tools wie Check_MK oder Prometheus für Cluster-Überwachung.
- Erkunden Sie Multi-Cloud-DR mit AWS EKS und Azure AKS.
- Implementieren Sie Chaos-Engineering-Tests (z. B. Chaos Mesh für Kubernetes).

**Quellen**:
- Pacemaker-Dokumentation: https://clusterlabs.org/pacemaker/doc/
- Kubernetes Backup mit Velero: https://velero.io/docs/
- Debian Cluster Guide: https://wiki.debian.org/Cluster