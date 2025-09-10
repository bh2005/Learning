# Anleitung: Erstellung einer LAMP-Stack-VM mit Ubuntu 22.04 auf Proxmox VE

## Einführung

Ein **LAMP-Stack** (Linux, Apache, MySQL/MariaDB, PHP) ist eine weit verbreitete Plattform für Webhosting und Entwicklung, ideal für Anwendungen wie WordPress oder Nextcloud. Diese Anleitung beschreibt die Erstellung einer virtuellen Maschine (VM) mit **Ubuntu 22.04 LTS** auf Proxmox VE 9.0, die manuelle Installation und Konfiguration des LAMP-Stacks, sowie die Integration in ein HomeLab mit OPNsense-Firewall (VLANs) und TrueNAS NFS-Speicher. Im Vergleich zur TurnKey LAMP-LXC-Vorlage bietet eine Ubuntu-VM mehr Flexibilität und Kontrolle über die Installation. Die Anleitung ist für HomeLab-Nutzer mit begrenztem Budget optimiert und kompatibel mit der Netzwerkstruktur aus der vorherigen Anleitung (`04_opnsense_homelab_installation_guide.md`).

**Voraussetzungen**:
- Proxmox VE 9.0 auf einem Server mit mindestens 16 GB RAM, 4–8 Kerne, 1–2 TB SSD/NVMe, 1 GbE NICs.
- TrueNAS CORE 13.0 mit einer NFS-Freigabe (`/mnt/tank/vmdata`, IP: `192.168.30.100`).
- OPNsense 24.7 als VM mit VLANs:
  - VLAN 10: VMs (`192.168.10.0/24`, DHCP).
  - VLAN 20: Management (Proxmox: `192.168.20.10`, OPNsense: `192.168.20.1`).
  - VLAN 30: Storage (TrueNAS: `192.168.30.100`).
  - VLAN 40: Gäste/IoT (`192.168.40.0/24`).
- Ubuntu 22.04 LTS ISO (herunterladbar von https://ubuntu.com/download/server).
- Zugriff auf die Proxmox-Weboberfläche (`https://192.168.20.10:8006`).
- Grundkenntnisse in Linux, Netzwerkkonfiguration und Webserver-Verwaltung.

**Netzwerkplan**:
- Die LAMP-VM wird in VLAN 10 (`192.168.10.0/24`) betrieben.
- Zugriff auf den Webserver erfolgt über HTTP/HTTPS (Ports 80/443).
- OPNsense schützt die VM mit Firewall-Regeln und Suricata IDS/IPS.

**Hinweis**: Diese Anleitung verwendet Ubuntu 22.04 LTS für eine stabile, langfristig unterstützte Basis. Der LAMP-Stack wird manuell installiert, um Anpassungen zu erleichtern.

**Quellen**:
- Ubuntu-Dokumentation: https://ubuntu.com/server/docs
- Proxmox-Dokumentation: https://pve.proxmox.com/wiki/Virtual_Machines
- Webquellen:,,,,,,,,,,,,,,

## Vorbereitung

### Schritt 1: Ubuntu 22.04 ISO herunterladen
1. Lade die Ubuntu 22.04 LTS Server ISO von https://ubuntu.com/download/server.
   - Datei: `ubuntu-22.04.5-live-server-amd64.iso` (oder neueste Version).
2. Lade die ISO in Proxmox hoch:
   - In der Proxmox-Weboberfläche: `local > ISO Images > Upload`.
   - Wähle die Datei `ubuntu-22.04.5-live-server-amd64.iso`.

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

## Erstellung der LAMP-Stack-VM

### Schritt 1: VM erstellen
1. **VM erstellen** (in der Proxmox-Weboberfläche, `Create VM`):
   - **General**:
     - Name: `lamp-vm`.
     - VM ID: `104` (oder automatisch).
   - **OS**:
     - ISO Image: `local:iso/ubuntu-22.04.5-live-server-amd64.iso`.
     - Typ: `Linux`, Version: `6.x - 2.6 Kernel`.
   - **System**:
     - Machine: `q35`.
     - BIOS: `OVMF (UEFI)` (oder `SeaBIOS` für ältere Hardware).
     - SCSI Controller: `VirtIO SCSI`.
   - **Disk**:
     - Speicher: `nfs-vmstore`.
     - Größe: 20 GB.
     - Format: `qcow2`.
   - **CPU**:
     - Cores: 2.
     - Typ: `kvm64` oder `host`.
   - **Memory**:
     - RAM: 2048 MB (4096 MB für komplexe Anwendungen wie WordPress).
   - **Network**:
     - Bridge: `vmbr0`.
     - VLAN Tag: `10`.
     - Model: `VirtIO`.
     - Firewall: Aktiviert.
   - Klicke auf „Create“.
2. **CLI-Alternative**:
   ```bash
   qm create 104 --name lamp-vm --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0,tag=10 --scsi0 nfs-vmstore:20,format=qcow2 --ostype l26 --cdrom local:iso/ubuntu-22.04.5-live-server-amd64.iso
   ```
3. **VM starten**:
   ```bash
   qm start 104
   ```

### Schritt 2: Ubuntu 22.04 installieren
1. **Zugriff auf die Konsole**:
   - In der Proxmox-Weboberfläche: `lamp-vm > Console`.
2. **Ubuntu-Installation**:
   - Wähle „Install Ubuntu Server“ und drücke `Enter`.
   - Sprache: Deutsch (oder bevorzugte Sprache).
   - Netzwerk: Konfiguriere eine statische IP:
     - IP: `192.168.10.104/24`.
     - Gateway: `192.168.10.1` (OPNsense).
     - DNS: `192.168.10.1` (oder `192.168.10.102`, falls Pi-hole in VLAN 10 läuft).
   - Speicher: Standardpartitionierung (LVM, ext4), 20 GB.
   - Benutzer: Erstelle einen Benutzer (z. B. `admin`, Passwort: `<secure-password>`).
   - SSH: Aktiviere „Install OpenSSH server“.
   - Features: Keine zusätzlichen Snaps auswählen.
   - Schließe die Installation ab und starte die VM neu:
     ```bash
     qm set 104 --cdrom none
     qm start 104
     ```
3. **System aktualisieren**:
   ```bash
   ssh admin@192.168.10.104
   sudo apt update && sudo apt upgrade -y
   ```

## Konfiguration des LAMP-Stacks

### Schritt 1: Apache installieren
1. **Apache2 installieren**:
   ```bash
   sudo apt install apache2 -y
   ```
2. **Apache-Status prüfen**:
   ```bash
   sudo systemctl status apache2
   ```
   - Stelle sicher, dass Apache läuft (`active (running)`).
3. **Testseite aufrufen**:
   - Öffne einen Browser und gehe zu `http://192.168.10.104`.
   - Du solltest die Standard-Apache-Seite sehen.
4. **Webroot prüfen**:
   - Der Apache-Webroot liegt unter `/var/www/html`:
     ```bash
     ls /var/www/html
     ```
   - Füge eine Testdatei hinzu:
     ```bash
     sudo nano /var/www/html/info.php
     ```
     - Inhalt:
       ```php
       <?php phpinfo(); ?>
       ```
   - Teste: `http://192.168.10.104/info.php` (zeigt PHP-Informationen, nach Tests löschen).

### Schritt 2: MariaDB installieren
1. **MariaDB installieren**:
   ```bash
   sudo apt install mariadb-server mariadb-client -y
   ```
2. **MariaDB-Status prüfen**:
   ```bash
   sudo systemctl status mariadb
   ```
3. **Datenbankzugriff sichern**:
   ```bash
   sudo mysql_secure_installation
   ```
   - Setze ein Root-Passwort für MariaDB.
   - Entferne anonyme Benutzer, deaktiviere Remote-Root-Login, entferne Testdatenbank.
4. **Testdatenbank erstellen**:
   ```bash
   sudo mysql -u root -p
   CREATE DATABASE testdb;
   GRANT ALL PRIVILEGES ON testdb.* TO 'testuser'@'localhost' IDENTIFIED BY 'securepassword';
   FLUSH PRIVILEGES;
   EXIT;
   ```

### Schritt 3: PHP installieren
1. **PHP und Module installieren**:
   ```bash
   sudo apt install php libapache2-mod-php php-mysql php-gd php-curl php-mbstring php-xml -y
   ```
2. **PHP-Version prüfen**:
   ```bash
   php -v
   ```
   - Erwartete Ausgabe: PHP 8.1 oder 8.2.
3. **PHP-Konfiguration anpassen** (falls nötig):
   - Bearbeite `/etc/php/8.1/apache2/php.ini`:
     ```bash
     sudo nano /etc/php/8.1/apache2/php.ini
     ```
     - Beispiel: Erhöhe `upload_max_filesize`:
       ```ini
       upload_max_filesize = 64M
       post_max_size = 64M
       ```
   - Apache neu starten:
     ```bash
     sudo systemctl restart apache2
     ```

### Schritt 4: phpMyAdmin installieren (optional)
1. **phpMyAdmin installieren**:
   ```bash
   sudo apt install phpmyadmin -y
   ```
   - Wähle `apache2` als Webserver.
   - Konfiguriere die Datenbank für phpMyAdmin (dbconfig-common): `Ja`.
   - Setze ein Passwort für die phpMyAdmin-Datenbank.
2. **Zugriff testen**:
   - Öffne `http://192.168.10.104/phpmyadmin`.
   - Melde dich mit `testuser` und `securepassword` an, prüfe die Datenbank `testdb`.
3. **Sicherheit erhöhen**:
   - Verschiebe phpMyAdmin zu einem benutzerdefinierten Pfad:
     ```bash
     sudo mv /usr/share/phpmyadmin /var/www/html/admin
     ```
   - Aktualisiere Apache-Konfiguration:
     ```bash
     sudo nano /etc/apache2/conf-available/phpmyadmin.conf
     ```
     - Passe `Alias` an:
       ```apache
       Alias /admin /var/www/html/admin
       ```
   - Aktiviere die Konfiguration:
     ```bash
     sudo a2enconf phpmyadmin
     sudo systemctl reload apache2
     ```

## Integration mit HomeLab

### Schritt 1: OPNsense Firewall-Regeln anpassen
1. **Zugriff auf LAMP-VM erlauben**:
   - In der OPNsense-Weboberfläche (`https://192.168.20.1`): `Firewall > Rules > VMs` (VLAN 10).
   - Regel hinzufügen:
     - Aktion: `Pass`.
     - Quelle: `any` oder `192.168.20.0/24` (Management für Admin-Zugriff).
     - Ziel: `192.168.10.104`.
     - Protokoll: `TCP`.
     - Ports: `80, 443, 3306` (MariaDB, optional), `admin` (phpMyAdmin).
2. **Suricata IDS/IPS anpassen**:
   - Gehe zu `Services > Intrusion Detection > Policy`.
   - Deaktiviere Regeln, die legitimen Web-Traffic blockieren (z. B. `http` False Positives):
     - Unterdrücke Regel für `192.168.10.104`:
       ```yaml
       suppress gen_id 1, sig_id 123456, track by_dst, ip 192.168.10.104
       ```
   - Aktiviere `emerging-web.rules` für Schutz vor Web-Exploits.

**Tipp**: Verwende einen Alias in OPNsense (`Firewall > Aliases`) für `192.168.10.104` (z. B. `LAMP-VM`).

### Schritt 2: TrueNAS NFS-Integration
1. **Speicher prüfen**:
   - Stelle sicher, dass die VM auf `nfs-vmstore` (`192.168.30.100:/mnt/tank/vmdata`) läuft:
     ```bash
     qm disk list 104
     ```
2. **Webdaten auf NFS speichern** (optional):
   - Füge ein zusätzliches NFS-Mount hinzu:
     ```bash
     qm set 104 --scsi1 nfs-vmstore:10,format=raw
     ```
   - In der VM:
     ```bash
     sudo mkfs.ext4 /dev/sdb
     sudo mkdir /var/www/html/webdata
     sudo mount /dev/sdb /var/www/html/webdata
     ```
   - Permanent mounten:
     ```bash
     echo "/dev/sdb /var/www/html/webdata ext4 defaults 0 2" | sudo tee -a /etc/fstab
     ```

### Schritt 3: Backup mit Proxmox Backup Server (PBS)
1. **Backup-Job hinzufügen**:
   - In der Proxmox-Weboberfläche: `Datacenter > Backup > Add`.
   - Wähle VM 104 (`lamp-vm`), Speicher: `pbs-backup`, Schedule: Täglich um 03:00.
   - CLI-Alternative:
     ```bash
     pve-backup add lamp-vm-backup --storage pbs-backup --schedule "mon..sun 03:00" --vmlist 104
     ```
2. **Testen**:
   ```bash
   pve-backup run lamp-vm-backup
   ```

## Beispiel: WordPress-Installation (optional)

1. **WordPress herunterladen**:
   ```bash
   cd /var/www/html
   sudo wget https://wordpress.org/latest.tar.gz
   sudo tar -xzvf latest.tar.gz
   sudo mv wordpress/* .
   sudo rm -rf wordpress latest.tar.gz
   ```
2. **Datenbank erstellen**:
   ```bash
   sudo mysql -u root -p
   CREATE DATABASE wordpress;
   GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost' IDENTIFIED BY 'wpsecurepassword';
   FLUSH PRIVILEGES;
   EXIT;
   ```
3. **WordPress konfigurieren**:
   - Kopiere die Konfigurationsvorlage:
     ```bash
     sudo cp wp-config-sample.php wp-config.php
     sudo nano wp-config.php
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
   sudo chown -R www-data:www-data /var/www/html
   sudo chmod -R 755 /var/www/html
   ```
5. **WordPress-Setup abschließen**:
   - Öffne `http://192.168.10.104/wp-admin/install.php` und folge dem Installationsassistenten.

**Tipp**: Sichere die WordPress-Datenbank regelmäßig mit mysqldump:
```bash
mysqldump -u wpuser -p wordpress > /var/www/html/backup-$(date +%F).sql
```

## Best Practices für HomeLab

- **Ressourcen**:
  - Weise der VM moderate Ressourcen zu (2 Kerne, 2–4 GB RAM).
  - Erhöhe RAM auf 4 GB für komplexe Anwendungen wie WordPress mit vielen Plugins.
- **Sicherheit**:
  - Deaktiviere SSH-Passwort-Login:
    ```bash
    sudo nano /etc/ssh/sshd_config
    ```
    - Setze:
      ```ini
      PermitRootLogin prohibit-password
      ```
    - Neustart:
      ```bash
      sudo systemctl restart ssh
      ```
  - Verwende starke Passwörter für MariaDB und phpMyAdmin.
  - Installiere Fail2Ban:
    ```bash
    sudo apt install fail2ban -y
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban
    ```
- **Netzwerk**:
  - Nutze VLAN 10 für die LAMP-VM, um sie von Management (VLAN 20) und Storage (VLAN 30) zu trennen.
  - Aktiviere HTTPS in Apache:
    ```bash
    sudo a2enmod ssl
    sudo systemctl restart apache2
    ```
    - Optional: Erstelle ein selbstsigniertes Zertifikat oder nutze Let’s Encrypt.
- **Backup**:
  - Integriere regelmäßige Backups mit PBS.
  - Speichere Datenbank-Backups auf TrueNAS:
    ```bash
    rsync -av /var/www/html/backup-*.sql root@192.168.30.100:/mnt/tank/backups
    ```
- **Monitoring**:
  - Überwache Apache/MariaDB mit `htop` oder `systemctl status`.
  - Integriere Zabbix/Prometheus via OPNsense (`os-zabbix` Plugin).

**Quelle**: https://ubuntu.com/server/docs

## Empfehlungen für HomeLab

- **Setup**:
  - **LAMP-VM**: 2 GB RAM, 2 Kerne, 20 GB Speicher auf NFS (`nfs-vmstore`).
  - **Netzwerk**: VLAN 10 (`192.168.10.104`), geschützt durch OPNsense/Suricata.
  - **Workloads**: Hoste Webseiten (z. B. WordPress, Joomla) oder Entwicklungsprojekte.
- **Integration**:
  - Proxmox: Verwende `nfs-vmstore` für VM-Speicher.
  - TrueNAS: Speichere Webdaten oder Backups auf `/mnt/tank/webdata`.
  - OPNsense: Schütze die VM mit Firewall-Regeln und Suricata IDS/IPS.
- **Beispiel**:
  - LAMP-VM mit WordPress, gesichert durch PBS und Suricata.
  - Zugriff nur von VLAN 20 (Management) auf `80/443`.

## Tipps für den Erfolg

- **Installation**: Nutze Ubuntu 22.04 LTS für langfristige Unterstützung; aktualisiere regelmäßig:
  ```bash
  sudo apt update && sudo apt upgrade -y
  ```
- **Sicherheit**: Verwende OPNsense, um die VM vor externen Angriffen zu schützen (z. B. `emerging-web.rules` in Suricata).
- **Performance**: Aktiviere ZFS-Komprimierung (`zstd`) auf TrueNAS für NFS-Speicher.
- **Backup**: Teste Wiederherstellungen regelmäßig:
  ```bash
  qm restore 104 pbs-backup:vm/104/<snapshot-id>
  ```
- **Dokumentation**: Konsultiere https://ubuntu.com/server/docs und https://pve.proxmox.com/wiki/Virtual_Machines für Details.

## Fazit

Die Erstellung einer LAMP-Stack-VM mit Ubuntu 22.04 auf Proxmox VE bietet:
- **Flexibilität**: Manuelle Installation ermöglicht Anpassungen an spezifische Anforderungen.
- **Integration**: Nahtlose Einbindung in ein HomeLab mit TrueNAS (NFS) und OPNsense (Firewall/IDS).
- **Anwendungen**: Ideal für Webhosting, Entwicklungsprojekte oder HomeLab-Anwendungen wie WordPress.

Dieses Setup ist ressourcenschonend und ideal für HomeLabs mit begrenzter Hardware. Teste die Konfiguration in einer nicht-produktiven Umgebung, um Probleme zu vermeiden.

**Nächste Schritte**: Möchtest du eine detaillierte Anleitung zur Installation von WordPress/Nextcloud, Konfiguration von Let’s Encrypt für HTTPS oder Integration mit Zabbix für Monitoring?

**Quellen**:
- Ubuntu-Dokumentation: https://ubuntu.com/server/docs
- Proxmox-Dokumentation: https://pve.proxmox.com/wiki/Virtual_Machines
- Webquellen:,,,,,,,,,,,,,,