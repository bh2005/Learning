# NTP Backup Konzept – Remote Datacenter

**Version:** 1.3  
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
| **vCPU**                    | 2 vCPU                                           | Minimum |
| **RAM**                     | 2 GB                                             | chrony benötigt < 50 MB, 2 GB für OS-Overhead |
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
- **RAM**: 2 GB
- **Disk**: 20 GB
- **Netzwerk**: Statische IP + FQDN
- **Wichtigste Regel**: Hypervisor Time Sync **aus** und chrony Time Sync **ein**

## 4. Technische Umsetzung

### 4.1 chrony Konfiguration

> **Wichtig:** Die Konfigurationen für ntp01 und ntp02 unterscheiden sich nur in der `peer`-Zeile –  
> jede VM trägt ausschließlich die **andere** VM als Peer ein.

**ntp01** – Datei: `/etc/chrony/chrony.conf`

```conf
# Primäre Quelle (Zentrales RZ)
server ntp-appliance.haupt.dc iburst prefer

# Peer: nur ntp02 eintragen
peer ntp02.remote.dc iburst

# Optionaler Internet-Fallback (nur wenn Internetzugang vorhanden)
# pool de.pool.ntp.org iburst

# Lokale Fallback-Funktion: Zeit wird auch ohne Upstream-Kontakt verteilt
local stratum 9

# Zugriff für Remote-DC-Clients erlauben
allow 10.20.30.0/24

# Drift-Datei und Optimierungen
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync

# Logging
logdir /var/log/chrony
log tracking measurements statistics
```

**ntp02** – Datei: `/etc/chrony/chrony.conf`

```conf
# Primäre Quelle (Zentrales RZ)
server ntp-appliance.haupt.dc iburst prefer

# Peer: nur ntp01 eintragen
peer ntp01.remote.dc iburst

# Optionaler Internet-Fallback (nur wenn Internetzugang vorhanden)
# pool de.pool.ntp.org iburst

# Lokale Fallback-Funktion
local stratum 9

# Zugriff für Remote-DC-Clients erlauben
allow 10.20.30.0/24

# Drift-Datei und Optimierungen
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync

# Logging
logdir /var/log/chrony
log tracking measurements statistics
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

→ Inhalt aus Abschnitt 4.1 einfügen – für ntp01 die ntp01-Variante, für ntp02 die ntp02-Variante.

### Schritt 5: chrony aktivieren und starten

```bash
systemctl enable chrony
systemctl restart chrony
```

### Schritt 6: Konfiguration überprüfen

```bash
chronyc sources -v      # Zeigt alle Quellen; Peers erscheinen mit Prefix "="
chronyc tracking        # Aktueller Synchronisationsstatus
chronyc sourcestats     # Statistik aller Quellen
```

Falls die Uhr beim ersten Start stark abweicht (> 1 s), einmalig manuell angleichen:

```bash
chronyc makestep
```

### Schritt 7: Hypervisor Time-Sync deaktivieren

**VMware (im Gast):**
```bash
vmware-toolbox-cmd timesync disable
```
Alternativ in der `.vmx`-Datei:
```
tools.syncTime = "FALSE"
time.synchronize.continue = "FALSE"
time.synchronize.restore = "FALSE"
time.synchronize.resume.disk = "FALSE"
time.synchronize.shrink = "FALSE"
```

**Hyper-V (auf dem Hyper-V-Host, PowerShell):**
```powershell
Disable-VMIntegrationService -VMName "ntp01" -Name "Time Synchronization"
Disable-VMIntegrationService -VMName "ntp02" -Name "Time Synchronization"
```

**KVM / QEMU (libvirt XML):**
```xml
<clock offset='utc'>
  <timer name='rtc' tickpolicy='catchup'/>
  <timer name='pit' tickpolicy='delay'/>
  <timer name='hpet' present='no'/>
</clock>
```
Den `qemu-guest-agent` nicht für Time-Sync konfigurieren bzw. nicht installieren, falls nicht anderweitig benötigt.

## 6. Firewall-Beispiele

### 6.1 ufw (Debian Standard)

```bash
apt install ufw -y
ufw default deny incoming
ufw default allow outgoing
ufw allow from 10.20.30.0/24 to any port 123 proto udp   # NTP für Remote-DC-Clients
ufw allow from 10.20.10.0/24 to any port 22 proto tcp    # SSH aus Management-Netz
ufw --force enable
ufw status verbose
```

> Die SSH-Regel nutzt das Management-Subnetz `10.20.10.0/24`, NTP das DC-Subnetz `10.20.30.0/24` –  
> beide Subnetze anpassen falls abweichend.

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

# Loopback immer erlauben
iptables -A INPUT  -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Bestehende Verbindungen durchlassen
iptables -A INPUT  -m state --state ESTABLISHED,RELATED -j ACCEPT

# Ausgehende NTP-Abfragen an Upstream-Appliance und Peer erlauben
iptables -A OUTPUT -p udp --dport 123 -j ACCEPT

# Eingehende NTP-Anfragen nur aus Remote-DC-Subnetz erlauben
iptables -A INPUT -s 10.20.30.0/24 -p udp --dport 123 -j ACCEPT
iptables -A INPUT -p udp --dport 123 -j DROP

iptables-save > /etc/iptables/rules.v4
```

## 7. Client-Konfiguration im Remote-DC

### Linux

```bash
# /etc/chrony/chrony.conf
server ntp01.remote.dc iburst
server ntp02.remote.dc iburst
```

### Windows – Standalone-Systeme

```cmd
w32tm /config /manualpeerlist:"ntp01.remote.dc,ntp02.remote.dc" /syncfromflags:manual /update
w32tm /resync /force
```

### Windows – Active Directory Domain

In einer AD-Umgebung gilt eine feste Zeithierarchie:

| Rolle | NTP-Quelle |
|---|---|
| **PDC-Emulator** (FSMO) | ntp01.remote.dc, ntp02.remote.dc |
| Alle anderen DCs | PDC-Emulator (automatisch via AD) |
| Member-Server / Clients | Domäne (automatisch via AD) |

Nur auf dem **PDC-Emulator** wird der externe NTP-Server konfiguriert:

```cmd
w32tm /config /manualpeerlist:"ntp01.remote.dc,ntp02.remote.dc" /syncfromflags:manual /reliable:YES /update
w32tm /resync /force
```

Alle anderen Domänenmitglieder synchronisieren automatisch über die AD-Hierarchie – dort keine manuelle NTP-Konfiguration nötig.

### ESXi / vSphere

```bash
# Per esxcli im ESXi-Host (SSH oder vSphere CLI)
esxcli system ntp set --server ntp01.remote.dc --server ntp02.remote.dc --enabled true
/etc/init.d/ntpd restart
esxcli system ntp get   # Prüfen
```

Alternativ über vSphere Client: **Host → Konfiguration → Zeit und Datum → NTP-Einstellungen bearbeiten**

> Wichtig: Auch bei ESXi den **VMware-Tools-Time-Sync für alle Gast-VMs** deaktivieren (betrifft die Gäste, nicht den Host selbst).

### Netzwerkgeräte (Cisco-Beispiel)

```
ntp server 10.20.30.51 prefer
ntp server 10.20.30.52
```

## 8. Monitoring & Alarmierung

### Zu überwachende Metriken

| Metrik | Warning | Critical | Befehl zur Prüfung |
|---|---|---|---|
| **Stratum** | > 5 | > 8 | `chronyc tracking` |
| **Zeit-Offset** | > 50 ms | > 200 ms | `chronyc tracking` |
| **Erreichbarkeit NTP-VM** | — | nicht erreichbar | ICMP + UDP/123 |
| **Erreichbarkeit Upstream** | — | nicht erreichbar | `chronyc sources` |

> Stratum 9 bedeutet: lokaler Fallback aktiv, Upstream-Verbindung ausgefallen → Critical.

### Empfohlene Prüfbefehle

```bash
chronyc tracking           # System Clock, Stratum, Offset
chronyc sources -v         # Alle Quellen und Peers mit Status
chronyc sourcestats        # Statistik (Jitter, Drift)
```

**Empfohlene Tools:** CheckMK (`check_chrony`-Plugin), Prometheus `ntpmon_exporter` / Grafana

## 9. Failover-Test

Um sicherzustellen, dass das Backup-Konzept tatsächlich funktioniert:

1. **Upstream blocken** – NTP Appliance auf Netzwerkebene für das Remote-DC sperren (ACL oder Firewall-Regel).
2. **Warten** – chrony benötigt einige Minuten um die Quelle als ausgefallen zu markieren.
3. **Status prüfen** auf beiden VMs:
   ```bash
   chronyc sources -v     # Appliance sollte "?" zeigen, Peer "="
   chronyc tracking       # Stratum muss auf 9 wechseln
   ```
4. **Clients prüfen** – Clients sollen weiterhin synchronisieren (Stratum 10 bei Linux-Clients, da sie von Stratum-9-Servern holen).
5. **Upstream wiederherstellen** – Sperre aufheben, prüfen ob beide VMs automatisch zurück synchronisieren.

## 10. Vorteile dieser Lösung

- Hohe Ausfallsicherheit durch Peer-Beziehung
- Lokale Zeit bleibt bei Ausfall der Appliance stabil
- Geringe Abhängigkeit vom WAN
- Einfache Wartung und Erweiterbarkeit

## 11. To-Do Liste

- [ ] VMs auf unterschiedlichen Hosts erstellen
- [ ] Hostnamen und IPs final festlegen
- [ ] chrony.conf auf beiden VMs anpassen (ntp01 ↔ ntp02 Peer-Zeile beachten)
- [ ] Hypervisor Time-Sync deaktivieren (VMware / Hyper-V / KVM je nach Umgebung)
- [ ] Firewall konfigurieren
- [ ] ESXi-Hosts auf neue NTP-Server umstellen
- [ ] Windows PDC-Emulator umstellen
- [ ] Linux-Clients umstellen
- [ ] Netzwerkgeräte umstellen
- [ ] Monitoring einrichten (Schwellwerte laut Abschnitt 8)
- [ ] Failover-Test durchführen (Abschnitt 9)
- [ ] Dokumentation abschließen

---
