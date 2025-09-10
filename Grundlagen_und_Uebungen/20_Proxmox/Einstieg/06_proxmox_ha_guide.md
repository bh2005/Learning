# Anleitung: Hochverfügbarkeit (HA) mit Proxmox VE und auf Betriebssystem-Ebene

## Einführung

Hochverfügbarkeit (HA) sorgt dafür, dass kritische Dienste in Proxmox Virtual Environment (PVE) bei Hardware- oder Softwarefehlern weiterlaufen. Proxmox bietet HA auf Cluster-Ebene durch automatische Neustarts von VMs und LXC auf anderen Knoten, während HA auf Betriebssystem-Ebene (innerhalb von VMs/LXC) Redundanz für Anwendungen oder Datenbanken ermöglicht. Diese Anleitung erklärt beide Ansätze, vergleicht ihre Vor- und Nachteile und bietet praktische Schritte zur Einrichtung in Proxmox VE 8.3. Sie ist für HomeLab-Nutzer und Unternehmensumgebungen geeignet und basiert auf der Proxmox-Dokumentation (https://pve.proxmox.com/wiki/High_Availability_Cluster).

**Voraussetzungen**:
- Proxmox VE 8.3 auf mindestens 3 Knoten (für Quorum).
- Hardware: 32 GB RAM pro Knoten (64 GB+ für Ceph), SSDs/NVMes, 10 GbE Netzwerk.
- Shared Storage (z. B. Ceph, NFS, iSCSI) für HA-VMs/LXC.
- Zugriff auf die Proxmox-Weboberfläche (`https://<IP>:8006`) oder SSH.
- Grundkenntnisse in Linux, Netzwerkkonfiguration und Virtualisierung.

**Hinweis**: HA auf Proxmox-Ebene erfordert einen Cluster und Shared Storage, während HA auf Betriebssystem-Ebene unabhängig vom Cluster implementiert werden kann.

## HA auf Proxmox-Ebene

### Konzept
Proxmox HA ermöglicht automatische Neustarts von VMs und LXC auf anderen Knoten bei Ausfall eines Knotens. Dies erfordert:
- **Cluster**: Mindestens 3 Knoten für Quorum (Corosync).
- **Shared Storage**: Ceph, NFS oder iSCSI, damit alle Knoten auf VM-Disk-Images zugreifen können.
- **Fencing**: Mechanismus zum Isolieren fehlerhafter Knoten (z. B. Watchdog, IPMI).
- **HA-Manager**: Verwaltet den Zustand von VMs/LXC (z. B. gestartet, gestoppt).

### Vorteile
- **Automatische Wiederherstellung**: VMs/LXC starten auf einem anderen Knoten nach Ausfall.
- **Live-Migration**: Verschieben von VMs/LXC ohne Ausfallzeit.
- **Skalierbarkeit**: Einfaches Hinzufügen von Knoten für mehr Redundanz.
- **Integrierte Verwaltung**: HA-Konfiguration über die Proxmox-Weboberfläche.

### Nachteile
- **Komplexität**: Erfordert Cluster, Shared Storage und Fencing.
- **Ressourcenbedarf**: Höherer Bedarf an Hardware (mindestens 3 Knoten, 10 GbE).
- **Kosten**: Zusätzliche Server und Netzwerk-Hardware erhöhen die Investition.
- **Abhängigkeit von Shared Storage**: Single Point of Failure (SPoF), wenn Storage nicht redundant ist.

### Einsatzbereich
Unternehmensumgebungen mit kritischen Diensten (z. B. Webserver, Datenbanken) oder HomeLabs mit ausreichend Hardware für HA.

## HA auf Betriebssystem-Ebene

### Konzept
HA auf Betriebssystem-Ebene wird innerhalb von VMs oder LXC implementiert, um Anwendungen oder Datenbanken redundant zu betreiben. Beispiele:
- **Load Balancer**: HAProxy oder Nginx für Webserver.
- **Datenbank-Replikation**: MySQL/MariaDB (Master-Slave), PostgreSQL (Streaming Replication).
- **Failover-Clustering**: Pacemaker/Corosync für Dienste in VMs/LXC.
- **Container-Orchestrierung**: Kubernetes für LXC-basierte Microservices.

### Vorteile
- **Flexibilität**: Kann ohne Proxmox-Cluster oder Shared Storage implementiert werden.
- **Geringerer Hardwarebedarf**: Funktioniert auf einem einzelnen Knoten oder kleinen Clustern.
- **Anwendungsspezifisch**: Optimiert für spezifische Dienste (z. B. Datenbanken).
- **Kosteneffizient**: Weniger Hardware und Netzwerk-Investitionen.

### Nachteile
- **Komplexe Konfiguration**: Erfordert Expertise in der jeweiligen Anwendung (z. B. MySQL-Replikation).
- **Keine automatische Migration**: Keine Live-Migration ohne Proxmox-Cluster.
- **Begrenzte Isolation**: LXC-basierte HA ist anfälliger für Kernel-Exploits.
- **Manuelle Verwaltung**: Weniger Integration in Proxmox-Weboberfläche.

### Einsatzbereich
HomeLabs mit begrenztem Budget, kleinere Umgebungen oder spezifische Anwendungen, die eigene HA-Mechanismen bieten.

## Vergleichstabelle

| **Kriterium**            | **Proxmox HA**                     | **Betriebssystem HA**              |
|--------------------------|------------------------------------|------------------------------------|
| **Technologie**          | Cluster, Shared Storage, HA-Manager | Load Balancer, DB-Replikation, Clustering |
| **Redundanz**            | Knoten-Ausfall (automatisch)       | Anwendungs-Ausfall (manuell/konfiguriert) |
| **Hardware-Bedarf**      | Hoch (3+ Knoten, Shared Storage)   | Niedrig (1+ Knoten)                |
| **Netzwerk**             | 10 GbE+ für Cluster/Storage        | Optional (abhängig von Anwendung)  |
| **Komplexität**          | Hoch (Cluster, Fencing)            | Mittel (anwendungsspezifisch)      |
| **Live-Migration**       | Ja                                 | Nein (ohne Cluster)                |
| **Einsatzbereich**       | Unternehmen, kritische Dienste     | HomeLabs, spezifische Anwendungen  |

## Anleitung: HA-Einrichtung in Proxmox VE

### Vorbereitung
1. **Hardware prüfen**:
   - Mindestens 3 Knoten mit 32 GB ECC-RAM, 16 Kerne, 2x 1 TB NVMe, 2x 10 GbE NICs.
   - Beispiel: Dell R640 (2x Xeon Silver 4210, 64 GB RAM, 4x 1.92 TB NVMe).
2. **Netzwerk planen**:
   - VLANs:
     - VLAN 10: VM-Traffic.
     - VLAN 20: Quorum (Corosync).
     - VLAN 30: Management.
     - VLAN 40: Storage (Ceph/NFS/iSCSI).
   - Switch: Managed Switch mit 10 GbE (z. B. MikroTik CRS317).
3. **Backup**: Konfiguriere Proxmox Backup Server (PBS) für inkrementelle Backups.

### Teil 1: HA auf Proxmox-Ebene

#### Schritt 1: Cluster einrichten
1. **Cluster initialisieren** (auf Knoten 1):
   ```bash
   pvecm create mycluster
   ```
2. **Knoten hinzufügen** (auf Knoten 2 und 3):
   ```bash
   pvecm add <IP-of-node1> --link0 <IP-in-VLAN20>
   ```
3. **Cluster-Status prüfen**:
   ```bash
   pvecm status
   ```
   Stelle sicher, dass das Quorum erreicht ist (mindestens 3 Knoten).

**Tipp**: Verwende ein dediziertes 10 GbE-Netzwerk für Corosync (VLAN 20) mit niedriger Latenz.

**Quelle**: https://pve.proxmox.com/wiki/Cluster_Manager

#### Schritt 2: Shared Storage konfigurieren (Ceph)
1. **Ceph installieren**:
   - In der Weboberfläche: `Datacenter > Ceph > Install Ceph`.
   - Installiere auf allen Knoten.
2. **Ceph-Cluster einrichten**:
   - Erstelle Monitor und Manager:
     ```bash
     pveceph mon create
     pveceph mgr create
     ```
   - Füge OSDs hinzu (z. B. 4x NVMe pro Knoten):
     ```bash
     pveceph disk init /dev/nvme0n1
     pveceph osd create /dev/nvme0n1
     ```
3. **Pool erstellen**:
   ```bash
   pveceph pool create vmdata
   ceph osd pool set vmdata size 3
   ```
4. **Speicher hinzufügen**:
   - In der Weboberfläche: `Datacenter > Storage > Add > RBD`, wähle Pool `vmdata`.
5. **Netzwerk optimieren**:
   ```bash
   ceph config set mon public_network 192.168.40.0/24
   ```

**Alternative**: Verwende NFS oder iSCSI (siehe vorherige Anleitung „proxmox_shared_storage_guide.md“).

**Tipp**: Nutze enterprise-grade SSDs (DWPD > 1) und 25 GbE für Ceph.

**Quelle**: https://pve.proxmox.com/wiki/Storage#_ceph_rados_block_device_rbd

#### Schritt 3: HA-Gruppen und Fencing einrichten
1. **HA-Gruppe erstellen**:
   - In der Weboberfläche: `Datacenter > HA > Groups > Create`.
   - Beispiel: Gruppe `ha-group1`, alle Knoten, Priorität auf NVMe-Knoten.
2. **VMs/LXC für HA aktivieren**:
   - Wähle VM/CT: `Edit > HA > Request State: Started`.
   - Beispiel CLI:
     ```bash
     ha-manager add vm:100 --group ha-group1
     ```
3. **Fencing konfigurieren**:
   - Installiere Watchdog oder IPMI-Tools:
     ```bash
     apt install fence-agents
     ```
   - Konfiguriere IPMI (z. B. für Dell iDRAC):
     ```bash
     echo "fence_ipmilan -a <iDRAC-IP> -l <iDRAC-user> -p <iDRAC-password>" > /etc/pve/priv/fence.cfg
     ```
4. **HA testen**:
   - Simuliere Knoten-Ausfall:
     ```bash
     systemctl poweroff
     ```
   - Überprüfe, ob VMs/LXC auf anderen Knoten starten:
     ```bash
     ha-manager status
     ```

**Tipp**: Stelle sicher, dass Shared Storage redundant ist (z. B. Ceph mit size=3).

### Teil 2: HA auf Betriebssystem-Ebene

#### Beispiel 1: HAProxy für Webserver (in LXC)
1. **Zwei LXC-Container erstellen** (z. B. Ubuntu 22.04):
   ```bash
   pct create 101 local:vztmpl/ubuntu-22.04-standard_amd64.tar.gz --hostname web1 --storage local-zfs --rootfs 10 --cores 1 --memory 512 --net0 name=eth0,bridge=vmbr0,ip=192.168.10.101/24
   pct create 102 local:vztmpl/ubuntu-22.04-standard_amd64.tar.gz --hostname web2 --storage local-zfs --rootfs 10 --cores 1 --memory 512 --net0 name=eth0,bridge=vmbr0,ip=192.168.10.102/24
   ```
2. **HAProxy-Container erstellen**:
   ```bash
   pct create 103 local:vztmpl/ubuntu-22.04-standard_amd64.tar.gz --hostname haproxy --storage local-zfs --rootfs 10 --cores 1 --memory 512 --net0 name=eth0,bridge=vmbr0,ip=192.168.10.100/24
   ```
3. **HAProxy installieren** (in LXC 103):
   ```bash
   pct enter 103
   apt update && apt install haproxy
   ```
4. **HAProxy konfigurieren**:
   - Bearbeite `/etc/haproxy/haproxy.cfg`:
     ```bash
     frontend http_front
         bind *:80
         mode http
         default_backend web_back

     backend web_back
         mode http
         balance roundrobin
         server web1 192.168.10.101:80 check
         server web2 192.168.10.102:80 check
     ```
   - Starte HAProxy:
     ```bash
     systemctl restart haproxy
     ```
5. **Webserver einrichten** (in LXC 101 und 102):
   ```bash
   pct enter 101
   apt update && apt install nginx
   echo "Webserver 1" > /var/www/html/index.html
   systemctl restart nginx
   ```
   - Wiederhole für LXC 102 („Webserver 2“).
6. **Testen**:
   - Greife auf `http://192.168.10.100` zu; HAProxy verteilt Anfragen an Web1/Web2.

**Tipp**: Verwende Keepalived für eine virtuelle IP (VIP) zur Vermeidung von SPoF.

#### Beispiel 2: MySQL-Replikation (in VMs)
1. **Zwei VMs erstellen** (z. B. Ubuntu 22.04):
   ```bash
   qm create 100 --name mysql-master --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0,ip=192.168.10.201/24 --scsi0 local-zfs:20
   qm create 101 --name mysql-slave --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0,ip=192.168.10.202/24 --scsi0 local-zfs:20
   ```
   - Installiere Ubuntu via ISO.
2. **MySQL installieren** (auf beiden VMs):
   ```bash
   apt update && apt install mysql-server
   ```
3. **Master konfigurieren** (auf VM 100):
   - Bearbeite `/etc/mysql/my.cnf`:
     ```bash
     [mysqld]
     server-id = 1
     log_bin = /var/log/mysql/mysql-bin.log
     ```
   - Starte MySQL neu:
     ```bash
     systemctl restart mysql
     ```
   - Erstelle Replikationsbenutzer:
     ```sql
     mysql -u root -p
     GRANT REPLICATION SLAVE ON *.* TO 'repl'@'192.168.10.202' IDENTIFIED BY 'secure_password';
     FLUSH PRIVILEGES;
     SHOW MASTER STATUS;
     ```
4. **Slave konfigurieren** (auf VM 101):
   - Bearbeite `/etc/mysql/my.cnf`:
     ```bash
     [mysqld]
     server-id = 2
     ```
   - Starte MySQL neu und verbinde mit Master:
     ```bash
     mysql -u root -p
     CHANGE MASTER TO MASTER_HOST='192.168.10.201', MASTER_USER='repl', MASTER_PASSWORD='secure_password', MASTER_LOG_FILE='mysql-bin.000001', MASTER_LOG_POS=123;
     START SLAVE;
     SHOW SLAVE STATUS\G
     ```
5. **Testen**:
   - Erstelle eine Test-Datenbank auf dem Master und prüfe die Replikation auf dem Slave.

**Tipp**: Nutze VIP (z. B. via Keepalived) für automatischen Failover.

## Empfehlungen für Anwendungsfälle

- **HomeLab (begrenzte Hardware)**:
  - **Empfehlung**: HA auf Betriebssystem-Ebene (z. B. HAProxy, MySQL-Replikation).
  - **Begründung**: Geringerer Hardwarebedarf, funktioniert auf 1–2 Knoten ohne Shared Storage.
  - **Beispiel**: 2 LXC mit HAProxy und Nginx, 1 Knoten mit 16 GB RAM, ZFS Mirror.

- **Unternehmensumgebung (kritische Dienste)**:
  - **Empfehlung**: Proxmox HA mit Ceph.
  - **Begründung**: Automatische Wiederherstellung, Live-Migration, hohe Redundanz.
  - **Beispiel**: 5 Knoten, 64 GB RAM, Ceph (6 OSDs pro Knoten), HA für 20 VMs.

- **Hybrid-Ansatz**:
  - **Empfehlung**: Kombination aus Proxmox HA und Betriebssystem-HA.
  - **Begründung**: Proxmox HA für Knoten-Ausfälle, Betriebssystem-HA für Anwendungs-Redundanz.
  - **Beispiel**: Proxmox-Cluster mit Ceph, VMs mit MySQL-Replikation und HAProxy.

## Tipps für den Erfolg
- **Quorum**: Stelle sicher, dass immer eine Mehrheit der Knoten (z. B. 3 von 5) online ist.
- **Fencing**: Verwende Watchdog oder IPMI, um Zombie-Knoten zu vermeiden.
- **Netzwerk**: Nutze 10–25 GbE mit VLANs und Bonding für Redundanz.
- **Backup**: Integriere Proxmox Backup Server (PBS) für inkrementelle Backups:
  ```bash
  pvesm add pbs backup --server 192.168.30.200 --datastore backup
  ```
- **Monitoring**: Nutze Checkmk oder Prometheus für Cluster- und Anwendungsüberwachung.
- **Dokumentation**: Konsultiere https://pve.proxmox.com/wiki/High_Availability_Cluster.

## Fazit
- **Proxmox HA**: Ideal für Unternehmen mit Shared Storage und Cluster, bietet automatische Wiederherstellung und Live-Migration, aber ressourcenintensiv.
- **Betriebssystem-HA**: Kosteneffizient und flexibel für HomeLabs oder kleinere Umgebungen, erfordert jedoch anwendungsspezifische Konfiguration.

Für HomeLabs ist Betriebssystem-HA (z. B. HAProxy, MySQL-Replikation) oft ausreichend, während Unternehmensumgebungen Proxmox HA mit Ceph oder iSCSI bevorzugen. Teste die Konfiguration in einer nicht-produktiven Umgebung, um Ausfallzeiten zu minimieren.

**Nächste Schritte**: Möchtest du eine detaillierte Anleitung zu Fencing-Mechanismen (z. B. IPMI), Kubernetes in LXC für HA oder Integration mit Proxmox Backup Server?

**Quellen**:
- Proxmox-Dokumentation: https://pve.proxmox.com/wiki/High_Availability_Cluster, https://pve.proxmox.com/wiki/Storage
- Community-Diskussionen:,,,,,,