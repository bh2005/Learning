# Anleitung: Hyperkonvergentes Ceph-Storage in Proxmox VE

## Einführung

**Ceph** ist ein verteiltes, quelloffenes Storage-System, das Proxmox VE als integrierten Bestandteil mitbringt (`pveceph`). Anders als bei klassischem ZFS mit Replikation (siehe [07_proxmox_replication_pbs_guide.md](07_proxmox_replication_pbs_guide.md)) ist Ceph **echtes Shared Storage**: Alle Cluster-Knoten schreiben gleichzeitig auf denselben logischen Datenpool, VM-Disks werden dabei redundant über mehrere Knoten verteilt. Das ermöglicht Live-Migration ohne Kopiervorgang und Hochverfügbarkeit ohne die Verzögerung eines Replikations-Zeitplans. Diese Anleitung erklärt Grundkonzepte, Einrichtung und Best Practices für ein hyperkonvergentes Ceph-Cluster (Ceph läuft auf denselben Knoten wie die VMs/LXC) unter Proxmox VE 9.0.

**Voraussetzungen**:
- Mindestens 3 Proxmox-VE-Knoten im Cluster (Ceph benötigt ein ungerades Quorum an Monitoren, 3 ist das gängige Minimum).
- Pro Knoten mindestens eine zusätzliche, ungenutzte Festplatte/SSD für OSDs (Object Storage Daemons) – nicht die System-Platte verwenden.
- Ein **dediziertes Netzwerk** für den Ceph-Storage-Traffic, getrennt von Corosync (Cluster-Kommunikation) und Management. Empfohlen: eigenes VLAN oder eigene NICs mit mindestens 10 GbE, da Ceph bei Replikation und Recovery viel Bandbreite benötigt.
- Grundkenntnisse in Proxmox-Cluster-Verwaltung (`pvecm`) und Blockspeicher-Konzepten.

**Hinweis**: Ceph lohnt sich ab 3 Knoten aufwärts und wird mit wachsender Knotenzahl relativ gesehen effizienter. Für 2-Knoten-HomeLabs ist ZFS mit Replikation (siehe vorherige Anleitung) meist die pragmatischere Wahl.

**Quellen**:
- Proxmox-Dokumentation: https://pve.proxmox.com/wiki/Deploy_Hyper-Converged_Ceph_Cluster
- Ceph-Dokumentation: https://docs.ceph.com/en/latest/

## Grundkonzepte

- **OSD (Object Storage Daemon)**: Ein Dienst pro physischer Festplatte/SSD, der die eigentlichen Daten speichert. Mehr OSDs = mehr Kapazität und Performance.
- **MON (Monitor)**: Hält die Cluster-Map und den Konsens-Status. Läuft in ungerader Anzahl (3, 5, ...) für Quorum.
- **MGR (Manager)**: Liefert Metriken, Status und das Ceph-Dashboard.
- **Pool**: Logischer Container für Daten, definiert Replikationsfaktor bzw. Erasure-Coding-Profil.
- **Placement Groups (PG)**: Interne Sharding-Einheit, über die Objekte auf OSDs verteilt werden.
- **CRUSH-Map**: Algorithmus, der bestimmt, auf welchen OSDs Daten redundant abgelegt werden (z. B. verteilt über Racks/Knoten, um korrelierte Ausfälle zu vermeiden).
- **Replica vs. Erasure Coding**: Replica-Pools (z. B. `size=3`) speichern jede Kopie vollständig auf 3 OSDs – einfach und schnell, aber speicherintensiv. Erasure-Coding-Pools sind speichereffizienter, aber rechenintensiver und für latenzkritische VM-Disks meist ungeeignet.

**Vorteile**:
- Echtes Shared Storage – Live-Migration ohne Datenkopie, Basis für nahtloses HA.
- Skaliert horizontal: Kapazität und Performance wachsen mit jedem zusätzlichen Knoten/OSD.
- Selbstheilend: Bei Ausfall eines OSDs/Knotens verteilt Ceph die Daten automatisch neu (Recovery).
- Kein Single Point of Failure, sofern Monitore und Replikate über mehrere Knoten verteilt sind.

**Nachteile**:
- Höhere Komplexität als ZFS+Replikation, mehr Betriebsaufwand (Monitoring von Health-Status, PG-Zustand, OSD-Wearout).
- Netzwerk wird schnell zum Flaschenhals – ohne dediziertes, schnelles Storage-Netz sind Performance-Probleme vorprogrammiert.
- Effektive Kapazität sinkt durch Replikation (bei `size=3` bleiben nur ca. 33 % der Rohkapazität nutzbar).
- Erfordert mindestens 3 Knoten, damit sich der Aufwand lohnt.

## Einrichtung eines Ceph-Clusters

### Schritt 1: Ceph auf allen Knoten installieren
```bash
pveceph install --version squid
```
Führe dies auf **jedem** Cluster-Knoten aus, der Ceph-Dienste (Monitor/Manager/OSD) bereitstellen soll.

### Schritt 2: Ceph-Netzwerk initialisieren
Auf dem ersten Knoten, unter Angabe des dedizierten Storage-Netzes:
```bash
pveceph init --network 10.10.10.0/24
```

**Tipp**: Trenne öffentliches Ceph-Netz (Client-Zugriff) und internes Cluster-Netz (Replikation zwischen OSDs), falls die Bandbreite es hergibt – das entlastet den Replikations-Traffic zusätzlich vom VM-I/O.

### Schritt 3: Monitor und Manager erstellen
Auf mindestens 3 Knoten (für Quorum):
```bash
pveceph mon create
pveceph mgr create
```

### Schritt 4: OSDs anlegen
Auf jedem Knoten für jede dafür vorgesehene Festplatte:
```bash
pveceph osd create /dev/sdb
```
Status prüfen:
```bash
ceph osd tree
```

### Schritt 5: Pool erstellen
Über die Weboberfläche (`Ceph > Pools > Create`) oder per CLI, z. B. mit Replikationsfaktor 3:
```bash
pveceph pool create vm-storage --size 3 --min_size 2
```
- `size 3`: drei Kopien jedes Objekts.
- `min_size 2`: Pool bleibt schreibbar, solange mindestens 2 Kopien verfügbar sind (bei einem Ausfall).

### Schritt 6: Pool als Storage einbinden
Der neue Pool erscheint automatisch unter `Datacenter > Storage` als RBD-Storage (`vm-storage`) und kann direkt für VM-Disks und Container ausgewählt werden.

### Schritt 7: Testen
```bash
ceph -s
ceph health detail
```
Erstelle testweise eine VM mit Disk auf dem Ceph-Pool und teste eine Live-Migration auf einen anderen Knoten – dank Shared Storage ohne spürbare Downtime.

## Monitoring und Wartung

- **Health-Status im Blick behalten**:
  ```bash
  ceph health
  ceph -w   # laufende Ereignisse live verfolgen
  ```
- **Ceph-Dashboard** über die Proxmox-Weboberfläche (`Datacenter > Ceph`) nutzen für PG-Status, OSD-Auslastung und Latenzen.
- **SSD/NVMe-Verschleiß (Wearout) regelmäßig prüfen**, insbesondere bei consumer-grade SSDs als OSDs – Ceph erzeugt durch Replikation deutlich mehr Schreiblast als lokales ZFS:
  ```bash
  smartctl -a /dev/sdb | grep -i wear
  ```
- **Integration in bestehendes Monitoring** (z. B. Checkmk): Ceph liefert Metriken über das MGR-Modul `prometheus`, die sich per HTTP-Endpoint abgreifen lassen.

## Best Practices

- **Ungerade Monitor-Anzahl**: 3 oder 5 Monitore, nie eine gerade Zahl (Split-Brain-Risiko bei Quorum-Verlust).
- **Dediziertes Storage-Netz**: Mindestens 10 GbE, idealerweise getrennt von Corosync- und Management-Traffic, um Latenzspitzen bei Recovery zu vermeiden.
- **Replikationsfaktor 3** für Produktionsumgebungen; `size=2` nur für unkritische Testumgebungen, da bei einem Knotenausfall keine Redundanz mehr besteht.
- **Homogene Hardware pro Knoten** (gleiche Disk-Typen/-Größen) vereinfacht Kapazitätsplanung und CRUSH-Verteilung.
- **Ausreichend Kapazitätsreserve** einplanen: Ceph benötigt Headroom für Recovery-Vorgänge nach einem Knotenausfall – nie auf über ~80 % Auslastung fahren.
- **Vergleich zu ZFS+Replikation**: Für 2-Knoten-Setups oder kleine HomeLabs bleibt ZFS mit Replikation (siehe [07_proxmox_replication_pbs_guide.md](07_proxmox_replication_pbs_guide.md)) einfacher zu betreiben; Ceph spielt seine Stärken erst ab 3+ Knoten und wachsender Cluster-Größe aus.

## Empfehlungen für Anwendungsfälle

- **HomeLab**: Nur sinnvoll, wenn bereits 3+ Knoten vorhanden sind, z. B. 3 Mini-PCs mit je einer zusätzlichen NVMe für OSDs. Sonst ZFS+Replikation bevorzugen.
- **Unternehmensumgebung**: 4+ Knoten mit dediziertem 10/25-GbE-Storage-Netz, `size=3`-Pools, laufendem Health-Monitoring und geplanter Kapazitätsreserve für Knotenausfälle. Ideal als Basis für HA-Cluster mit vielen VMs.

## Fazit

Ceph macht aus einem Proxmox-Cluster echtes hyperkonvergentes Shared Storage: keine Kopiervorgänge bei Migration, automatische Selbstheilung bei Ausfällen, horizontale Skalierung mit jedem weiteren Knoten. Der Preis dafür ist höhere Komplexität und ein deutlich netzwerklastigerer Betrieb als bei ZFS+Replikation. Für Cluster ab 3 Knoten mit ausreichend schnellem, dediziertem Storage-Netz ist Ceph die robustere Wahl für Produktionsumgebungen; für kleine 2-Knoten-HomeLabs bleibt ZFS+Replikation der pragmatischere Einstieg.

**Quellen**:
- https://pve.proxmox.com/wiki/Deploy_Hyper-Converged_Ceph_Cluster
- https://docs.ceph.com/en/latest/
