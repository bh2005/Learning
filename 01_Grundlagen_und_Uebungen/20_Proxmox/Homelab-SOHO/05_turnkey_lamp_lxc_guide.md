# Anleitung: Erstellung eines LAMP-Stack LXC-Containers mit TurnKey Linux auf Proxmox VE

## Einführung

Die **TurnKey Linux LAMP-Stack-Vorlage** bietet eine vorgefertigte Lösung für einen Linux-Container mit einem LAMP-Stack (Linux, Apache, MySQL/MariaDB, PHP), der für Webhosting, Entwicklung oder HomeLab-Anwendungen wie WordPress oder Nextcloud geeignet ist. Diese Anleitung beschreibt die Erstellung eines LXC-Containers mit der TurnKey LAMP-Stack-Vorlage auf Proxmox VE 9.0, die Konfiguration des LAMP-Stacks und die Integration in ein HomeLab mit OPNsense-Firewall (VLANs) und TrueNAS NFS-Speicher. Sie baut auf der Netzwerkstruktur aus der vorherigen Anleitung (`opnsense_homelab_installation_guide.md`) auf und ist für HomeLab-Nutzer mit begrenzter Hardware optimiert.

**Voraussetzungen**:
- Proxmox VE 9.0 auf einem Server mit mindestens 16 GB RAM, 4–8 Kerne, 1–2 TB SSD/NVMe, 1 GbE NICs.
- TrueNAS CORE 13.0 mit einer NFS-Freigabe (`/mnt/tank/vmdata`, IP: `192.168.30.100`).
- OPNsense 24.7 als VM mit VLANs:
  - VLAN 10: VMs (`192.168.10.0/24`, DHCP).
  - VLAN 20: Management (Proxmox: `192.168.20.10`, OPNsense: `192.168.20.1`).
  - VLAN 30: Storage (TrueNAS: `192.168.30.100`).
  - VLAN 40: Gäste/IoT (`192.168.40.0/24`).
- Zugriff auf die Proxmox-Weboberfläche (`https://192.168.20.10:8006`).
- Internetzugang für den Download der TurnKey-Vorlage.
- Grundkenntnisse in Linux, Netzwerkkonfiguration und Webserver-Verwaltung.

**Netzwerkplan**:
- Der LAMP-Container wird in VLAN 10 (`192.168.10.0/24`) betrieben.
- Zugriff auf den Webserver erfolgt über HTTP/HTTPS (Ports 80/443).
- OPNsense schützt den Container mit Firewall-Regeln und Suricata IDS/IPS.

**Hinweis**: Die TurnKey LAMP-Stack-Vorlage basiert auf Debian (z. B. Debian 11 oder 12) und enthält Apache 2.4, MariaDB 10.x, PHP 8.x sowie Tools wie phpMyAdmin und Webmin.

**Quellen**:
- TurnKey Linux-Dokumentation: https://www.turnkeylinux.org/lampstack
- Proxmox-Dokumentation: https://pve.proxmox.com/wiki/Linux_Container
- Webquellen:,,,,,,,,,,,,,,

## Vorbereitung

### Schritt 1: TurnKey LAMP-Stack-Vorlage herunterladen
1. **Vorlagenliste aktualisieren**:
   - In der Proxmox-Weboberfläche: `local > CT Templates > Templates`.
   - Klicke auf „Templates“, suche nach „turnkey-lamp“ und lade die neueste Vorlage (z. B. `turnkey-lamp-18.0-bookworm-amd64.tar.gz`).
   - CLI-Alternative:
     ```bash
     pveam update
     pveam download local turnkey-lamp-18.0-bookworm-amd64.tar.gz
     ```
2. **Prüfen**:
   - Navigiere zu `local > CT Templates` und vergewissere dich, dass die Vorlage verfügbar ist.

**Quelle**: https://www.turnkeylinux.org/lampstack

### Schritt 2: Netzwerk und Speicher prüfen
1. **NFS-Speicher**:
   - Stelle sicher, dass die NFS-Freigabe von TrueNAS (`192.168.30.100:/mnt/tank/vmdata`) in Proxmox konfiguriert ist:
     ```bash
     pvesm status
     ```
   - Falls nicht vorhanden, füge sie hinzu:
     ```bash
     pvesm add nfs nfs-vmstore --server 192.168.30.100 --export /mnt/tank/vmdata --content images,iso,rootdir
     ```
2. **VLAN-Konfiguration**:
   - Vergewissere dich, dass die Netzwerkbrücke `vmbr0` VLAN-Tagging unterstützt:
     ```bash
     cat /etc/network/interfaces
     ```
     - Beispiel:
       ```bash
       auto vmbr0
       iface vmbr0 inet manual
           bridge-ports enp0s3
           bridge-stp off
           bridge-fd 0
           bridge-vlan-aware yes
           bridge-vids 10,20,30,40

       auto vmbr0.20
       iface vmbr0.20 inet static
           address 192.168.20.10/24
           gateway 192.168.20.1
       ```

**Tipp**: Stelle sicher, dass der Managed Switch (z. B. TP-Link TL-SG108E) VLAN 10 für VM-Traffic konfiguriert hat.

## Erstellung des LAMP-Stack LXC-Containers

### Schritt 1: LXC-Container erstellen
1. **Container erstellen** (in der Proxmox-Weboberfläche, `Create CT`):
   - **General**:
     - Hostname: `lamp`.
     - CT ID: `103` (oder automatisch).
     - Passwort: Setze ein sicheres Passwort für den `root`-Benutzer.
   - **Template**:
     - Wähle `local > turnkey-lamp-18.0-bookworm-amd64.tar.gz`.
   - **Root Disk**:
     - Speicher: `nfs-vmstore`.
     - Größe: 10 GB.
   - **CPU**:
     - Cores: 1 (2 für höhere Last, z. B. WordPress).
   - **Memory**:
     - RAM: 1024 MB (2048 MB für komplexe Anwendungen).
   - **Network**:
     - Name: `eth0`.
     - Bridge: `vmbr0`.
     - VLAN Tag: `10`.
     - IP: `192.168.10.103/24`, Gateway: `192.168.10.1` (OPNsense).
   - **DNS**:
     - Verwende Standard-DNS oder setze `192.168.10.102` (falls Pi-hole in VLAN 10 läuft).
   - Klicke auf „Create“.
2. **CLI-Alternative**:
   ```bash
   pct create 103 local:vztmpl/turnkey-lamp-18.0-bookworm-amd64.tar.gz --hostname lamp --storage nfs-vmstore --rootfs 10 --cores 1 --memory 1024 --net0 name=eth0,bridge=vmbr0,tag=10,ip=192.168.10.103/24,gw=192.168.10.1 --password <secure-password>
   ```
3. **Container starten**:
   ```bash
   pct start 103
   ```

**Tipp**: Verwende unprivilegierte Container (Standard in Proxmox) für bessere Sicherheit.

### Schritt 2: TurnKey-Initialisierung
1. **Zugriff auf die Konsole**:
   - In der Proxmox-Weboberfläche: `lamp > Console`.
   - Alternativ via SSH:
     ```bash
     ssh root@192.168.10.103
     ```
2. **TurnKey Initial Setup**:
   - Beim ersten Start zeigt die Konsole oder Weboberfläche (`https://192.168.10.103`) das TurnKey-Setup:
     - **Root-Passwort**: Bestätige oder ändere das Passwort.
     - **Admin-E-Mail**: Gib eine E-Mail-Adresse für Benachrichtigungen ein.
     - **Hub Services** (optional): Überspringe die Registrierung für TurnKey Hub (Cloud-Backups).
     - **Security Updates**: Aktiviere automatische Sicherheitsupdates.
     - **Webmin/phpMyAdmin**: Notiere die URLs (z. B. `https://192.168.10.103:12321` für Webmin).
3. **System aktualisieren**:
   ```bash
   apt update && apt upgrade
   ```

**Quelle**: https://www.turnkeylinux.org/lampstack

## Konfiguration des LAMP-Stacks

### Schritt 1: Apache überprüfen
1. **Apache-Status prüfen**:
   ```bash
   systemctl status apache2
   ```
   - Stelle sicher, dass Apache läuft (`active (running)`).
2. **Testseite aufrufen**:
   - Öffne einen Browser und gehe zu `http://192.168.10.103`.
   - Du solltest die TurnKey LAMP-Startseite oder eine Standard-Apache-Seite sehen.
3. **Webroot**:
   - Der Apache-Webroot liegt unter `/var/www/html`:
     ```bash
     ls /var/www/html
     ```
   - Füge eine Testdatei hinzu:
     ```bash
     echo "<?php phpinfo(); ?>" > /var/www/html/info.php
     ```
   - Teste: `http://192.168.10.103/info.php` (zeigt PHP-Informationen).

### Schritt 2: MariaDB konfigurieren
1. **MariaDB-Status prüfen**:
   ```bash
   systemctl status mariadb
   ```
2. **Datenbankzugriff sichern**:
   - Starte das Sicherheits-Skript:
     ```bash
     mysql_secure_installation
     ```
     - Setze ein neues Root-Passwort für MariaDB.
     - Entferne anonyme Benutzer, deaktiviere Remote-Root-Login, entferne Testdatenbank.
3. **Testdatenbank erstellen**:
   ```bash
   mysql -u root -p
   CREATE DATABASE testdb;
   GRANT ALL PRIVILEGES ON testdb.* TO 'testuser'@'localhost' IDENTIFIED BY 'securepassword';
   FLUSH PRIVILEGES;
   EXIT;
   ```
4. **phpMyAdmin testen**:
   - Öffne `https://192.168.10.103:12322` (Standard-Port für phpMyAdmin).
   - Melde dich mit `testuser` und `securepassword` an, prüfe die Datenbank `testdb`.

### Schritt 3: PHP überprüfen
1. **PHP-Version prüfen**:
   ```bash
   php -v
   ```
   - Erwartete Ausgabe: PHP 8.x (z. B. 8.1 oder 8.2).
2. **PHP-Module prüfen**:
   ```bash
   php -m
   ```
   - Stelle sicher, dass Module wie `mysqli`, `gd`, `curl` aktiviert sind.
3. **PHP-Konfiguration anpassen** (falls nötig):
   - Bearbeite `/etc/php/8.x/apache2/php.ini`:
     ```bash
     nano /etc/php/8.x/apache2/php.ini
     ```
     - Beispiel: Erhöhe `upload_max_filesize` für größere Uploads:
       ```ini
       upload_max_filesize = 64M
       post_max_size = 64M
       ```
   - Apache neu starten:
     ```bash
     systemctl restart apache2
     ```

**Tipp**: Installiere zusätzliche PHP-Module, falls erforderlich:
```bash
apt install php8.1-mbstring php8.1-xml
```

## Integration mit HomeLab

### Schritt 1: OPNsense Firewall-Regeln anpassen
1. **Zugriff auf LAMP erlauben**:
   - In der OPNsense-Weboberfläche (`https://192.168.20.1`): `Firewall > Rules > VMs` (VLAN 10).
   - Regel hinzufügen:
     - Aktion: `Pass`.
     - Quelle: `any` oder `192.168.20.0/24` (Management für Admin-Zugriff).
     - Ziel: `192.168.10.103`.
     - Protokoll: `TCP`.
     - Ports: `80, 443, 12321` (Webmin), `12322` (phpMyAdmin).
2. **Suricata IDS/IPS anpassen**:
   - Gehe zu `Services > Intrusion Detection > Policy`.
   - Deaktiviere Regeln, die legitimen Web-Traffic blockieren (z. B. `http` False Positives):
     - Unterdrücke Regel für `192.168.10.103`:
       ```yaml
       suppress gen_id 1, sig_id 123456, track by_dst, ip 192.168.10.103
       ```
   - Aktiviere `emerging-web.rules` für Schutz vor Web-Exploits.

**Tipp**: Verwende einen Alias in OPNsense (`Firewall > Aliases`) für `192.168.10.103` (z. B. `LAMP-Server`).

### Schritt 2: TrueNAS NFS-Integration
1. **Speicher prüfen**:
   - Stelle sicher, dass der LXC-Container auf `nfs-vmstore` (`192.168.30.100:/mnt/tank/vmdata`) läuft.
   - Prüfe Mount:
     ```bash
     pct enter 103
     df -h
     ```
2. **Webdaten auf NFS speichern** (optional):
   - Füge ein zusätzliches NFS-Mount hinzu:
     ```bash
     pct set 103 --mp0 192.168.30.100:/mnt/tank/webdata,mp=/var/www/html
     ```
   - Teste den Zugriff:
     ```bash
     touch /var/www/html/test.txt
     ```

### Schritt 3: Backup mit Proxmox Backup Server (PBS)
1. **Backup-Job hinzufügen**:
   - In der Proxmox-Weboberfläche: `Datacenter > Backup > Add`.
   - Wähle CT 103 (`lamp`), Speicher: `pbs-backup`, Schedule: Täglich um 03:00.
   - CLI-Alternative:
     ```bash
     pve-backup add lamp-backup --storage pbs-backup --schedule "mon..sun 03:00" --vmlist 103
     ```
2. **Testen**:
   ```bash
   pve-backup run lamp-backup
   ```

## Beispiel: WordPress-Installation (optional)

1. **WordPress herunterladen**:
   ```bash
   pct enter 103
   cd /var/www/html
   wget https://wordpress.org/latest.tar.gz
   tar -xzvf latest.tar.gz
   mv wordpress/* .
   rm -rf wordpress latest.tar.gz
   ```
2. **Datenbank erstellen**:
   ```bash
   mysql -u root -p
   CREATE DATABASE wordpress;
   GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost' IDENTIFIED BY 'wpsecurepassword';
   FLUSH PRIVILEGES;
   EXIT;
   ```
3. **WordPress konfigurieren**:
   - Kopiere die Konfigurationsvorlage:
     ```bash
     cp wp-config-sample.php wp-config.php
     nano wp-config.php
     ```
     - Passe an:
       ```php
       define('DB_NAME', 'wordpress');
       define('DB_USER', 'wpuser');
       define('DB_PASSWORD', 'wpsecurepassword');
       define('DB_HOST', 'localhost');
       ```
4. **Berechtigungen setzen**:
   ```bash
   chown -R www-data:www-data /var/www/html
   chmod -R 755 /var/www/html
   ```
5. **WordPress-Setup abschließen**:
   - Öffne `http://192.168.10.103/wp-admin/install.php` und folge dem Installationsassistenten.

**Tipp**: Sichere die WordPress-Datenbank regelmäßig mit mysqldump:
```bash
mysqldump -u wpuser -p wordpress > /var/www/html/backup-$(date +%F).sql
```

## Best Practices für HomeLab

- **Ressourcen**:
  - Weise dem Container moderate Ressourcen zu (1–2 Kerne, 1–2 GB RAM).
  - Erhöhe RAM auf 4 GB für komplexe Anwendungen wie WordPress mit vielen Plugins.
- **Sicherheit**:
  - Deaktiviere SSH-Passwort-Login:
    ```bash
    echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config
    systemctl restart ssh
    ```
  - Verwende starke Passwörter für MariaDB und Webmin.
  - Aktiviere Fail2Ban (vorinstalliert in TurnKey):
    ```bash
    systemctl enable fail2ban
    systemctl start fail2ban
    ```
- **Netzwerk**:
  - Nutze VLAN 10 für den LAMP-Container, um ihn von Management (VLAN 20) und Storage (VLAN 30) zu trennen.
  - Aktiviere HTTPS in Apache:
    ```bash
    a2enmod ssl
    systemctl restart apache2
    ```
    - Optional: Erstelle ein selbstsigniertes Zertifikat oder nutze Let’s Encrypt.
- **Backup**:
  - Integriere regelmäßige Backups mit PBS.
  - Speichere Datenbank-Backups auf TrueNAS:
    ```bash
    rsync -av /var/www/html/backup-*.sql root@192.168.30.100:/mnt/tank/backups
    ```
- **Monitoring**:
  - Überwache Apache/MariaDB mit Webmin (`https://192.168.10.103:12321`).
  - Integriere Zabbix/Prometheus via OPNsense (`os-zabbix` Plugin).

**Quelle**: https://www.turnkeylinux.org/lampstack

## Empfehlungen für HomeLab

- **Setup**:
  - **LAMP-Container**: 1 GB RAM, 1 Kern, 10 GB Speicher auf NFS (`nfs-vmstore`).
  - **Netzwerk**: VLAN 10 (`192.168.10.103`), geschützt durch OPNsense/Suricata.
  - **Workloads**: Hoste Webseiten (z. B. WordPress, Joomla) oder Entwicklungsprojekte.
- **Integration**:
  - Proxmox: Verwende `nfs-vmstore` für Container-Speicher.
  - TrueNAS: Speichere Webdaten oder Backups auf `/mnt/tank/webdata`.
  - OPNsense: Schütze den Webserver mit Firewall-Regeln und Suricata IDS/IPS.
- **Beispiel**:
  - LAMP-Container mit WordPress, gesichert durch PBS und Suricata.
  - Zugriff nur von VLAN 20 (Management) auf `80/443`.

## Tipps für den Erfolg

- **Vorlage**: Nutze die TurnKey LAMP-Vorlage für eine schnelle Einrichtung; aktualisiere regelmäßig:
  ```bash
  apt update && apt upgrade
  ```
- **Sicherheit**: Verwende OPNsense, um den Webserver vor externen Angriffen zu schützen (z. B. `emerging-web.rules` in Suricata).
- **Performance**: Aktiviere ZFS-Komprimierung (`zstd`) auf TrueNAS für NFS-Speicher.
- **Backup**: Teste Wiederherstellungen regelmäßig:
  ```bash
  pct restore 103 pbs-backup:ct/103/<snapshot-id>
  ```
- **Dokumentation**: Konsultiere https://www.turnkeylinux.org/lampstack und https://pve.proxmox.com/wiki/Linux_Container für Details.

## Fazit

Die Erstellung eines LAMP-Stack LXC-Containers mit TurnKey Linux auf Proxmox VE bietet:
- **Einfachheit**: Vorkonfigurierter LAMP-Stack mit Apache, MariaDB, PHP und Tools wie Webmin/phpMyAdmin.
- **Integration**: Nahtlose Einbindung in ein HomeLab mit TrueNAS (NFS) und OPNsense (Firewall/IDS).
- **Flexibilität**: Ideal für Webhosting, Entwicklungsprojekte oder HomeLab-Anwendungen wie WordPress.

Dieses Setup ist ressourcenschonend und ideal für HomeLabs mit begrenzter Hardware. Teste die Konfiguration in einer nicht-produktiven Umgebung, um Probleme zu vermeiden.

**Nächste Schritte**: Möchtest du eine detaillierte Anleitung zur Installation von WordPress/Nextcloud, Konfiguration von Let’s Encrypt für HTTPS oder Integration mit Check_MK für Monitoring?

**Quellen**:
- TurnKey Linux-Dokumentation: https://www.turnkeylinux.org/lampstack
- Proxmox-Dokumentation: https://pve.proxmox.com/wiki/Linux_Container
- Webquellen:,,,,,,,,,,,,,,
