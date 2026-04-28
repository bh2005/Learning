# NTP Backup Konzept – Remote Datacenter

**Version:** 1.2  
**Datum:** 28.04.2026  
**Autor:** bh2005  
**Ziel:** Hohe Verfügbarkeit der Zeit-Synchronisation im Remote-DC bei Ausfall der zentralen NTP Appliance

## 1. Ausgangslage und Ziel

- Im Haupt-Rechenzentrum steht eine dedizierte **NTP Appliance** (primäre Zeitquelle).
- Im Remote-DC soll eine robuste Backup-Lösung aufgebaut werden.
- Bei Ausfall der Appliance oder der WAN-Verbindung soll das Remote-DC weiterhin eine konsistente und akzeptable Zeitverteilung haben.
- Alle Systeme im Remote-DC (Server, VMs, ESXi-Hosts, Netzwerkgeräte, Windows-DCs etc.) sollen primär lokale NTP-Server verwenden.

**Lösung:** Zwei NTP-VMs auf Basis von **Debian** mit **chrony**, die sich gegenseitig als Peer kennen und beide primär von der zentralen NTP Appliance synchronisieren.

## 2. Architektur

### Hostnamen & IP-Adressen (Beispiel)

| VM              | Hostname              | IP-Adresse       | Stratum (normal) | Stratum (bei Ausfall) |
|-----------------|-----------------------|------------------|------------------|-----------------------|
| NTP-VM 1        | ntp01.remote.dc       | 10.20.30.51      | 3 oder 4         | 9                     |
| NTP-VM 2        | ntp02.remote.dc       | 10.20.30.52      | 3 oder 4         | 9                     |

- Beide VMs laufen auf **zwei unterschiedlichen physischen Hosts**.
- Alle Clients im Remote-DC zeigen primär auf **ntp01** und **ntp02**.

## 3. Anforderungen an die NTP-VMs

### 3.1 Hardware- und Systemanforderungen

| Kategorie                    | Anforderung                                      | Empfehlung / Hinweis |
|-----------------------------|--------------------------------------------------|----------------------|
| **Betriebssystem**          | Debian 12 (Bookworm) oder neuer                  | Minimal-Installation |
| **NTP-Software**            | chrony                                           | ntpd wird nicht empfohlen |
| **Anzahl der VMs**          | 2 (ntp01 + ntp02)                                | Redundanz |
| **Host-Platzierung**        | Auf **zwei unterschiedlichen** physischen Hosts  | Vermeidung Single Point of Failure |
| **vCPU**                    | 2 vCPU                                           | Minimum, 4 vCPU bei hoher Last möglich |
| **RAM**                     | 2 GB                                             | 4 GB empfohlen |
| **Festplatte**              | 20 GB                                            | Dünn provisioniert ausreichend |
| **Netzwerk**                | 1 vNIC mit **statischer IP-Adresse**             | Feste IPs im Remote-DC-Netz |
| **Hostname**                | ntp01.remote.dc<br>ntp02.remote.dc               | FQDN muss auflösbar sein |
| **Hypervisor Time-Sync**    | **Komplett deaktiviert**                         | Sehr wichtig! |
| **Zeitquelle**              | Primär: NTP Appliance<br>Peer: jeweils andere NTP-VM | - |
| **Lokaler Fallback**        | `local stratum 9`                                | Aktivieren für Backup-Funktion |

### 3.2 Wichtige Konfigurationsanforderungen

- **Time-Synchronization durch den Hypervisor** muss deaktiviert werden (VMware Tools, Hyper-V Integration Services, QEMU Guest Agent etc.).
- Die VMs dürfen **nicht** über den Host ihre Uhrzeit beziehen.
- DNS-Auflösung der beiden NTP-VMs untereinander und der zentralen NTP Appliance muss funktionieren.
- UDP Port 123 muss aus dem Remote-DC Subnetz erreichbar sein.
- Die VMs sollten eine hohe Verfügbarkeit haben (laufend auf stabilen Hosts).
- Firewall: Beschränkung des NTP-Zugriffs (UDP/123) ausschließlich auf das interne Remote-DC-Netz.

### 3.3 Mindestspezifikation (Zusammenfassung)

- **OS**: Debian 12 oder höher (Minimal)
- **CPU**: 2 vCPU
- **RAM**: 2 GB (4 GB empfohlen)
- **Disk**: 20 GB
- **Netzwerk**: Statische IP + FQDN
- **Wichtigste Regel**: Hypervisor Time Sync **aus** und chrony Time Sync **ein**

## 4. Technische Umsetzung

### 4.1 chrony Konfiguration

Datei: `/etc/chrony/chrony.conf`

```conf
# Primäre Quelle
server ntp-appliance.haupt.dc iburst prefer

# Peer zwischen den beiden NTP-VMs
peer ntp01.remote.dc iburst
peer ntp02.remote.dc iburst

# Lokale Fallback-Funktion (wichtig für Backup-Rolle)
local stratum 9
manual

# Zugriff erlauben
allow 10.20.30.0/24          # Remote-DC Subnetz anpassen

# Allgemeine Einstellungen
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
dumponexit
dumpdir /var/lib/chrony

# Für bessere VM-Performance
noselect 127.127.1.0
```

## 5. Detaillierte Schritt-für-Schritt Installationsanleitung

### Schritt 1: VM erstellen
- Debian 12 minimal installieren
- Netzwerk: Statische IP vergeben
- Hostname setzen (`ntp01.remote.dc` bzw. `ntp02.remote.dc`)

### Schritt 2: System aktualisieren und chrony installieren

```bash
apt update && apt upgrade -y
apt install chrony -y
```

### Schritt 3: Originalkonfiguration sichern

```bash
cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.bak
```

### Schritt 4: Konfigurationsdatei anpassen

```bash
nano /etc/chrony/chrony.conf
```

→ Inhalt aus Abschnitt 4.1 einfügen (an deine IPs/FQDNs anpassen).

### Schritt 5: chrony neu starten und aktivieren

```bash
systemctl restart chrony
systemctl enable --now chrony
```

### Schritt 6: Konfiguration überprüfen

```bash
chronyc sources -v
chronyc tracking
chronyc peers
chronyc sourcestats
```

### Schritt 7: Hypervisor Time-Sync deaktivieren

**VMware:**
```bash
vmware-toolbox-cmd timesync disable
```

## 6. Firewall-Beispiele

### 6.1 ufw (Debian Standard)

```bash
apt install ufw -y
ufw allow from 10.20.30.0/24 to any port 123 proto udp
ufw allow from 10.20.10.0/24 to any port 22 proto tcp    # SSH optional
ufw --force enable
ufw status verbose
```

### 6.2 firewalld

```bash
apt install firewalld -y
systemctl enable --now firewalld

firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.20.30.0/24" port protocol="udp" port="123" accept'
firewall-cmd --reload
```

### 6.3 iptables (klassisch)

```bash
apt install iptables-persistent -y
iptables -A INPUT -s 10.20.30.0/24 -p udp --dport 123 -j ACCEPT
iptables -A INPUT -p udp --dport 123 -j DROP
iptables-save > /etc/iptables/rules.v4
```

## 7. Client-Konfiguration im Remote-DC

- **Linux:** `server ntp01.remote.dc iburst` und `server ntp02.remote.dc iburst`
- **Windows:** `w32tm /config /manualpeerlist:"ntp01.remote.dc,ntp02.remote.dc" /syncfromflags:manual /update`
- **Netzwerkgeräte:** Beide NTP-VMs als NTP-Server eintragen

## 8. Monitoring & Alarmierung

Überwache:
- Stratum-Wert
- Zeit-Offset
- Erreichbarkeit beider NTP-Server

Empfohlene Tools: Zabbix, Prometheus/Grafana, CheckMK

## 9. Vorteile dieser Lösung

- Hohe Ausfallsicherheit durch Peer-Beziehung
- Lokale Zeit bleibt bei Ausfall der Appliance stabil
- Geringe Abhängigkeit vom WAN
- Einfache Wartung und Erweiterbarkeit

## 10. To-Do Liste

- [ ] VMs auf unterschiedlichen Hosts erstellen
- [ ] Hostnamen und IPs final festlegen
- [ ] chrony.conf auf beiden VMs anpassen
- [ ] Hypervisor Time-Sync deaktivieren
- [ ] Firewall konfigurieren
- [ ] Clients umstellen
- [ ] Monitoring einrichten
- [ ] Dokumentation abschließen

---
