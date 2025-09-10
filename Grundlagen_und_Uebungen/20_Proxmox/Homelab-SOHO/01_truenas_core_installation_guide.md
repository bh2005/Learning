# Anleitung: Installation von TrueNAS CORE auf eigener Hardware

## Einführung

TrueNAS CORE ist ein kostenloses, auf FreeBSD basierendes Open-Source-Betriebssystem für Network Attached Storage (NAS), das auf ZFS setzt. Es verwandelt Standard-Hardware in einen leistungsstarken NAS-Server mit Unterstützung für Protokolle wie NFS, SMB und iSCSI sowie Funktionen wie Snapshots, Komprimierung und Deduplizierung. Diese Anleitung beschreibt die Installation von TrueNAS CORE 13.0 (oder neuer) auf eigener Hardware für ein HomeLab, einschließlich Hardwareauswahl, Installation, Konfiguration eines ZFS-Pools und Einrichtung einer NFS-Freigabe für die Nutzung mit einem Proxmox VE HomeLab. Die Anleitung ist für Anfänger und Fortgeschrittene geeignet und basiert auf der offiziellen Dokumentation sowie Community-Erfahrungen.

**Voraussetzungen**:
- Hardware: 64-Bit-System mit Intel- oder AMD-Prozessor, mindestens 8 GB RAM, separate SSD/HDD für das OS (mind. 16 GB), mindestens 1–2 Festplatten für Daten.
- Netzwerk: Ethernet-Anschluss (kein WLAN), statische IP empfohlen (z. B. `192.168.1.100/24`).
- Installationsmedium: USB-Stick (mind. 8 GB) oder DVD.
- Temporäre Peripherie: Monitor und Tastatur für die Installation.
- Internetzugang für Downloads und Updates.

**Hinweis**: TrueNAS unterstützt kein Dual-Boot, benötigt eine dedizierte Festplatte für das OS und bevorzugt Intel-basierte Netzwerkkarten (Realtek-Chips können Probleme verursachen). USB-Sticks als Bootmedium werden aufgrund hoher Schreibzyklen nicht empfohlen.

**Quellen**:
- Offizielle TrueNAS-Dokumentation: https://www.truenas.com/docs/core/
- Webquellen:,,,,,,,,,,,,,,[](https://www.veuhoff.net/truenas-die-ersten-schritte-nach-der-installation-ersteinrichtung/)[](https://www.windowspro.de/thomas-joos/truenas-installieren-konfigurieren)[](https://hetmanrecovery.com/de/recovery_news/how-to-install-and-configure-truenas-core.htm)

## Hardwareanforderungen

### Minimale Anforderungen
- **Prozessor**: 64-Bit Intel oder AMD (kein ARM), mind. 2–4 Kerne (z. B. Intel Core i3-10100 oder AMD Ryzen 3 3200G).
- **RAM**: 8 GB (16–32 GB empfohlen für ZFS, Plugins oder VMs).
- **Boot-Laufwerk**: Separate SSD/HDD mit mind. 16 GB (32 GB für Updates empfohlen, z. B. Samsung 870 EVO 250 GB).
- **Datenlaufwerke**: Mind. 1–2 HDDs/SSDs für ZFS-Pool (z. B. Seagate IronWolf 4 TB, vermeide SMR-Festplatten).
- **Netzwerk**: Ethernet mit Intel-NIC (z. B. Intel I219-V), 1 GbE oder besser.
- **Peripherie**: Monitor, Tastatur für die Installation.

### Empfohlene HomeLab-Konfiguration
- **Mainboard**: ASUS PRIME B550M-A (Intel-NIC, ECC-Unterstützung).
- **CPU**: AMD Ryzen 5 5600X (6 Kerne, 12 Threads).
- **RAM**: 16–32 GB DDR4 ECC (z. B. Kingston Server Premier).
- **Boot-Laufwerk**: 128 GB NVMe SSD (z. B. Samsung 970 EVO Plus).
- **Datenlaufwerke**: 2x 4 TB Seagate IronWolf (RAID-Z1 für Redundanz).
- **Netzwerk**: 1 GbE Switch (z. B. TP-Link TL-SG108E).
- **Gehäuse**: Fractal Design Node 804 (Platz für 8+ Festplatten).
- **Kosten**: ~600–900 € (ohne Datenlaufwerke).

**Tipp**: Verwende ECC-RAM für ZFS, um Datenintegrität zu maximieren. Vermeide SMR-Festplatten (Shingled Magnetic Recording), da sie die ZFS-Performance beeinträchtigen.

**Quelle**:,,[](https://hetmanrecovery.com/recovery_news/how-to-install-and-configure-truenas-core.htm)[](https://www.thomas-krenn.com/de/wiki/TrueNAS_CORE)[](https://www.computerbase.de/forum/threads/truenas-selbstbau-welche-hardware.2204711/)

## Vorbereitung

### Schritt 1: TrueNAS ISO herunterladen
1. Lade die TrueNAS CORE ISO (Version 13.0 oder neuer) von https://www.truenas.com/download-truenas-core/.
2. Optional: Registriere dich für den Download (nicht zwingend erforderlich).

### Schritt 2: Bootfähigen USB-Stick erstellen
1. **Tool**: Verwende Balena Etcher (https://etcher.balena.io/) oder Rufus (https://rufus.ie/de/) (Rufus kann bei neueren Versionen Probleme verursachen,).[](https://seel.re/datenverarbeitung/truenas-installation)
2. **Vorgehen**:
   - Starte Etcher, wähle die TrueNAS ISO und den USB-Stick (mind. 8 GB).
   - Schreibe die ISO auf den Stick (alle Daten auf dem Stick werden gelöscht).
   - Überprüfe die Integrität des Sticks (in Etcher optional).
3. **Hinweis**: Stelle sicher, dass der USB-Stick für den BIOS-Modus (UEFI oder Legacy) korrekt formatiert ist.

**Quelle**:,,[](https://hetmanrecovery.com/de/recovery_news/how-to-install-and-configure-truenas-core.htm)[](https://hetmanrecovery.com/recovery_news/how-to-install-and-configure-truenas-core.htm)[](https://seel.re/datenverarbeitung/truenas-installation)

### Schritt 3: BIOS/UEFI konfigurieren
1. Starte den Rechner und öffne das BIOS/UEFI (z. B. mit `F2`, `F11` oder `Del`, siehe Mainboard-Handbuch).
2. **Einstellungen**:
   - Setze den Boot-Modus auf **UEFI** (für Hardware <10 Jahre) oder **Legacy** (für ältere Hardware).
   - Deaktiviere „Watch Dog Controller“ (falls vorhanden,).[](https://www.pcwelt.de/article/2503700/truenas-so-nutzen-sie-das-alternative-nas-betriebssysten.html)
   - Stelle den USB-Stick als erste Boot-Option ein.
   - Optional: Aktiviere Secure Boot (für UEFI).
3. Speichere und starte neu.

**Quelle**:,,[](https://recoverhdd.de/blog/how-to-installing-and-configuring-truenas.html)[](https://recoverhdd.com/blog/how-to-installing-and-configuring-truenas.html)[](https://www.pcwelt.de/article/2503700/truenas-so-nutzen-sie-das-alternative-nas-betriebssysten.html)

## Installation von TrueNAS CORE

### Schritt 1: TrueNAS Installer starten
1. Stecke den USB-Stick ein, starte den Rechner und boote vom USB-Stick.
2. Wähle im Boot-Menü „Boot TrueNAS Installer“ und drücke `Enter`.

### Schritt 2: Installation durchführen
1. **Console Setup**: Wähle „1 Install/Upgrade“ und drücke `Enter`.
2. **Ziellaufwerk auswählen**:
   - Wähle die separate SSD/HDD für das OS (z. B. `/dev/sda`, 128 GB) mit der `Leertaste`.
   - Optional: Wähle zwei Laufwerke für einen Software-Mirror (z. B. `/dev/sda`, `/dev/sdb`).
   - Drücke `Enter`.
3. **Warnung bestätigen**: Bestätige die Datenlöschung mit „Yes“ (`Enter`).
4. **Root-Passwort festlegen**:
   - Gib ein sicheres Passwort für den `root`-Benutzer ein und bestätige es.
   - Drücke `Enter`.
5. **Boot-Modus wählen**:
   - Wähle „Boot via UEFI“ (für moderne Hardware) oder „Boot via BIOS“ (Legacy).
   - Drücke `Enter`.
6. **Swap-Partition**: Wähle „Create swap“ (16 GB empfohlen) und drücke `Enter`.
7. **Installation starten**: Die Installation dauert 5–10 Minuten.
8. **Neustart**:
   - Wähle „Reboot System“ und drücke `Enter`.
   - Entferne den USB-Stick nach dem Neustart.

**Quelle**:,,,,[](https://hetmanrecovery.com/recovery_news/how-to-install-and-configure-truenas-core.htm)[](https://www.starline.de/magazin/technische-artikel/installation-und-konfiguration-eines-truenas-core-server)[](https://www.starline.de/en/magazine/technical-articles/installation-and-configuration-of-a-truenas-core-server)

### Schritt 3: Zugriff auf die Weboberfläche
1. **IP-Adresse prüfen**:
   - Nach dem Neustart zeigt die Konsole die IP-Adresse (z. B. `192.168.1.100`) unter „The Web user interface is at“.
   - Falls keine IP angezeigt wird, überprüfe die Netzwerkverbindung (DHCP oder statische IP).
2. **Weboberfläche aufrufen**:
   - Öffne einen Browser im gleichen Netzwerk (z. B. `192.168.1.0/24`).
   - Gib `https://192.168.1.100` ein.
   - Melde dich mit `root` und dem festgelegten Passwort an.
3. **Grundeinstellungen**:
   - Unter `System > General`:
     - Stelle Sprache (z. B. Deutsch) und Zeitzone (z. B. Europe/Berlin) ein.
     - Optional: Passe das Tastaturlayout an.

**Quelle**:,,[](https://www.starline.de/magazin/technische-artikel/installation-und-konfiguration-eines-truenas-core-server)[](https://www.starline.de/en/magazine/technical-articles/installation-and-configuration-of-a-truenas-core-server)[](https://www.starline.de/magazin/technische-artikel/wie-sie-truenas-scale-richtig-installieren)

## Grundkonfiguration

### Schritt 1: ZFS-Pool erstellen
1. **Weboberfläche**: Navigiere zu `Storage > Pools > Add`.
2. **Pool erstellen**:
   - Name: `tank` (beliebig, z. B. `data`).
   - Wähle Datenlaufwerke (z. B. 2x 4 TB HDDs) unter „Available Disks“.
   - Konfiguration: Wähle `RAID-Z1` (1 Festplatte redundant, mind. 2 Laufwerke) oder `Mirror` (für 2 Laufwerke).
   - Aktiviere Komprimierung (`zstd`) und Deduplizierung (optional, benötigt viel RAM).
   - Klicke auf „Create“.
3. **CLI-Alternative**:
   ```bash
   zpool create -f tank raidz1 /dev/sdb /dev/sdc
   zfs set compression=zstd tank
   ```
4. **Status prüfen**:
   ```bash
   zpool status tank
   ```

**Tipp**: Verwende RAID-Z1 oder RAID-Z2 für Redundanz. Vermeide SMR-Laufwerke für ZFS (z. B. WD Red mit SMR,).[](https://www.elefacts.de/suchen-NAS)

**Quelle**:,,,[](https://www.veuhoff.net/truenas-die-ersten-schritte-nach-der-installation-ersteinrichtung/)[](https://hetmanrecovery.com/de/recovery_news/how-to-install-and-configure-truenas-core.htm)[](https://hetmanrecovery.com/recovery_news/how-to-install-and-configure-truenas-core.htm)

### Schritt 2: NFS-Freigabe für Proxmox einrichten
1. **Dataset erstellen**:
   - Navigiere zu `Storage > Pools > tank > Add Dataset`.
   - Name: `vmdata` (z. B. für Proxmox-VMs).
   - Typ: `Filesystem`.
   - Klicke auf „Save“.
2. **NFS-Freigabe erstellen**:
   - Gehe zu `Sharing > Unix Shares (NFS) > Add`.
   - Pfad: `/mnt/tank/vmdata`.
   - Erlaubte Netzwerke: `192.168.1.0/24`.
   - Aktiviere „Mapall User/Group“ (z. B. `root/root` für Proxmox).
   - Klicke auf „Save“ und aktiviere den NFS-Dienst.
3. **CLI-Alternative**:
   ```bash
   zfs create tank/vmdata
   echo "/mnt/tank/vmdata 192.168.1.0/24(rw,sync,no_subtree_check)" >> /etc/exports
   service nfsd restart
   ```
4. **Testen**:
   - Auf dem Proxmox-Host:
     ```bash
     mount -t nfs 192.168.1.100:/mnt/tank/vmdata /mnt/test
     ```
   - Prüfe den Zugriff und unmount:
     ```bash
     umount /mnt/test
     ```

**Tipp**: Verwende NFS 4.2 mit `nconnect=2` für bessere Performance:
```bash
mount -o vers=4.2,nconnect=2 192.168.1.100:/mnt/tank/vmdata /mnt/test
```

**Quelle**:,[](https://www.veuhoff.net/truenas-die-ersten-schritte-nach-der-installation-ersteinrichtung/)[](https://www.windowspro.de/thomas-joos/truenas-installieren-konfigurieren)

### Schritt 3: Benutzer und Berechtigungen (optional)
1. **Benutzer erstellen**:
   - Gehe zu `Accounts > Users > Add`.
   - Name: z. B. `user1`, Passwort festlegen.
   - Gruppe: Automatisch erstellt oder wähle eine bestehende.
   - Klicke auf „Save“.
2. **Berechtigungen für Dataset**:
   - Gehe zu `Storage > Pools > tank > vmdata > Edit Permissions`.
   - Wähle Benutzer/Gruppe (`user1`) und setze Berechtigungen (z. B. Lesen/Schreiben/Ausführen).
   - Aktiviere „Apply permissions recursively“.
3. **CLI-Alternative**:
   ```bash
   adduser user1
   zfs set acltype=posix tank/vmdata
   chown user1 /mnt/tank/vmdata
   chmod 750 /mnt/tank/vmdata
   ```

**Quelle**:,,[](https://www.veuhoff.net/truenas-die-ersten-schritte-nach-der-installation-ersteinrichtung/)[](https://www.starline.de/magazin/technische-artikel/installation-und-konfiguration-eines-truenas-core-server)[](https://www.hardwareluxx.de/community/threads/truenas-einrichten.1286882/)

## Best Practices für HomeLab

- **Hardware**:
  - Verwende Intel-NICs für Stabilität (Realtek kann Probleme verursachen,).[](https://www.computerbase.de/forum/threads/truenas-selbstbau-welche-hardware.2204711/)
  - Nutze ECC-RAM (16–32 GB) für ZFS.
  - Wähle CMR-Festplatten (z. B. Seagate IronWolf) statt SMR.
- **Speicher**:
  - Erstelle RAID-Z1 (mind. 2 Laufwerke) oder RAID-Z2 (mind. 3 Laufwerke) für Redundanz.
  - Aktiviere ZFS-Komprimierung (`zstd`) und prüfe Deduplizierung (benötigt >16 GB RAM).
- **Netzwerk**:
  - Nutze statische IPs für TrueNAS und Proxmox.
  - Optional: Aktiviere Jumbo Frames (MTU 9000) für bessere NFS-Performance.
- **Backup**:
  - Erstelle regelmäßige ZFS-Snapshots:
    ```bash
    zfs snapshot tank/vmdata@daily-$(date +%F)
    ```
  - Repliziere Snapshots auf ein externes Gerät:
    ```bash
    zfs send tank/vmdata@daily-$(date +%F) | ssh backup@192.168.1.200 zfs receive backup/vmdata
    ```
- **Sicherheit**:
  - Deaktiviere SSH-Passwort-Login:
    ```bash
    echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config
    service sshd restart
    ```
  - Verwende ein starkes `root`-Passwort.
- **Monitoring**:
  - Überwache ZFS-Pool:
    ```bash
    zpool status tank
    ```
  - Prüfe Systemlogs:
    ```bash
    tail -f /var/log/messages
    ```

**Quelle**:,[](https://hetmanrecovery.com/de/recovery_news/how-to-install-and-configure-truenas-core.htm)[](https://www.thomas-krenn.com/de/wiki/TrueNAS_CORE)

## Integration mit Proxmox VE

1. **NFS-Speicher in Proxmox hinzufügen**:
   - In der Proxmox-Weboberfläche: `Datacenter > Storage > Add > NFS`.
   - ID: `nfs-vmstore`, Server: `192.168.1.100`, Export: `/mnt/tank/vmdata`, Inhalt: `Images, Containers, ISO`.
   - CLI-Alternative:
     ```bash
     pvesm add nfs nfs-vmstore --server 192.168.1.100 --export /mnt/tank/vmdata --content images,iso,rootdir
     ```
2. **Testen**:
   - Erstelle eine VM/LXC auf dem NFS-Speicher und überprüfe die Performance.

**Tipp**: Stelle sicher, dass TrueNAS und Proxmox im gleichen Subnetz sind (z. B. `192.168.1.0/24`).

**Quelle**:[](https://www.veuhoff.net/truenas-die-ersten-schritte-nach-der-installation-ersteinrichtung/)

## Tipps für den Erfolg

- **Boot-Laufwerk**: Verwende eine kleine SSD (128–250 GB) statt USB-Sticks, da diese bei hohem Schreibaufkommen ausfallen können (,).[](https://www.starline.de/magazin/technische-artikel/installation-und-konfiguration-eines-truenas-core-server)[](https://www.hardwareluxx.de/community/threads/truenas-scale-installation-von-software-direkt-auf-dem-blech.1351320/)
- **ZFS-Optimierung**: Aktiviere Komprimierung (`zstd`) und überprüfe regelmäßig den Pool-Status.
- **Erweiterungen**: Installiere Plugins wie Nextcloud über `Apps > Available Apps` für zusätzliche Funktionen (z. B. private Cloud).
- **Backup-Strategie**: Implementiere die 3-2-1-Regel:
  - 3 Kopien: Produktivdaten (TrueNAS), lokale Snapshots, externe Backups.
  - 2 Medien: SSD (OS), HDD (Daten).
  - 1 Off-Site: Repliziere Snapshots auf ein externes NAS oder Cloud.
- **Dokumentation**: Konsultiere https://www.truenas.com/docs/core/ für Details zu Plugins, Snapshots oder Replikation.

## Fazit

Die Installation von TrueNAS CORE auf eigener Hardware ist unkompliziert und ermöglicht einen leistungsstarken NAS-Server für HomeLabs:
- **Hardware**: Intel/AMD-basierte Systeme mit 16–32 GB ECC-RAM und CMR-Festplatten.
- **Speicher**: ZFS mit RAID-Z1/Z2 für Redundanz und Komprimierung.
- **Integration**: NFS für Proxmox VE, unterstützt VMs und LXC.
- **Kosten**: ~600–900 € für ein robustes Setup (ohne Datenlaufwerke).

Diese Anleitung bietet eine solide Grundlage für ein HomeLab-NAS mit TrueNAS CORE. Für weitere Anpassungen (z. B. Nextcloud-Installation, ZFS-Optimierung oder Cloud-Backups) können zusätzliche Details angefordert werden.

**Nächste Schritte**: Möchtest du eine detaillierte Anleitung zu Plugins (z. B. Nextcloud), ZFS-Snapshots oder der Einbindung in einen Proxmox-Cluster?

**Quellen**:
- https://www.truenas.com/docs/core/
- Webquellen:,,,,,,,,,,,,,,[](https://www.veuhoff.net/truenas-die-ersten-schritte-nach-der-installation-ersteinrichtung/)[](https://www.windowspro.de/thomas-joos/truenas-installieren-konfigurieren)[](https://hetmanrecovery.com/de/recovery_news/how-to-install-and-configure-truenas-core.htm)