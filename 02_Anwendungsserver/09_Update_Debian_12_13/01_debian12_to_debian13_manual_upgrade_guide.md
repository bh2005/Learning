# Lernprojekt: Manuelles Upgrade von Debian 12 (Bookworm) auf Debian 13 (Trixie)

## Vorbereitung: Umgebung prüfen
1. **Proxmox VE prüfen**:
   - Melde dich an der Proxmox-Weboberfläche an: `https://192.168.30.2:8006`.
   - Stelle sicher, dass der LXC-Container (`192.168.30.120`) läuft:
     ```bash
     pct list
     ```
     - Erwartete Ausgabe: Container `papermerge` mit Status `running`.
2. **DNS in OPNsense prüfen**:
   - Öffne die OPNsense-Weboberfläche: `http://192.168.30.1`.
   - Gehe zu `Services > Unbound DNS > Overrides > Host`.
   - Überprüfe den Eintrag: `papermerge.homelab.local` → `192.168.30.120`.
   - Teste die DNS-Auflösung:
     ```bash
     nslookup papermerge.homelab.local 192.168.30.1
     ```
     - Erwartete Ausgabe: `192.168.30.120`.
3. **Debian-Version prüfen**:
   - Verbinde dich mit dem Container:
     ```bash
     ssh root@192.168.30.120
     cat /etc/os-release
     ```
     - Erwartete Ausgabe: `VERSION_CODENAME=bookworm`.
4. **Internetzugang prüfen**:
   - Teste die Verbindung:
     ```bash
     ping -c 4 deb.debian.org
     ```
     - Erwartete Ausgabe: Antwortzeiten ohne Paketverlust.

**Tipp**: Arbeite direkt auf dem Debian 12 Container (`192.168.30.120`) und stelle sicher, dass TrueNAS (`192.168.30.100`) für Backups zugänglich ist.

## Übung 1: Manuelles Backup des Debian 12 Systems

**Ziel**: Erstelle ein vollständiges Backup des Debian 12 Systems, einschließlich Papermerge-Konfiguration, Datenbank und Systemdateien.

**Aufgabe**: Sichere die Papermerge-Konfiguration, PostgreSQL-Datenbank und wichtige Systemverzeichnisse auf TrueNAS.

1. **Verbinde dich mit dem Container**:
   ```bash
   ssh root@192.168.30.120
   ```

2. **Stoppe Dienste**:
   - Stoppe Gunicorn, Nginx und PostgreSQL, um konsistente Backups zu gewährleisten:
     ```bash
     systemctl stop gunicorn
     systemctl stop nginx
     systemctl stop postgresql
     ```

3. **Erstelle Backups**:
   - **Papermerge-Konfiguration**:
     ```bash
     tar -czf /tmp/papermerge-config-backup-$(date +%Y-%m-%d).tar.gz /opt/papermerge
     ```
   - **Papermerge-Datenbank**:
     ```bash
     su - postgres -c "pg_dump -U papermerge_user papermerge" | gzip > /tmp/papermerge-db-backup-$(date +%Y-%m-%d).sql.gz
     ```
     - **Hinweis**: Falls ein Passwort benötigt wird, setze es temporär:
       ```bash
       export PGPASSWORD=securepassword456
       ```
   - **Systemkonfiguration**:
     ```bash
     tar -czf /tmp/system-backup-$(date +%Y-%m-%d).tar.gz /etc /var/lib/postgresql
     ```

4. **Kopiere Backups nach TrueNAS**:
   - Kopiere die Backups auf TrueNAS:
     ```bash
     scp /tmp/papermerge-config-backup-$(date +%Y-%m-%d).tar.gz root@192.168.30.100:/mnt/tank/backups/debian-upgrade/
     scp /tmp/papermerge-db-backup-$(date +%Y-%m-%d).sql.gz root@192.168.30.100:/mnt/tank/backups/debian-upgrade/
     scp /tmp/system-backup-$(date +%Y-%m-%d).tar.gz root@192.168.30.100:/mnt/tank/backups/debian-upgrade/
     ```

5. **Begrenze Backups auf fünf Versionen**:
   - Auf TrueNAS:
     ```bash
     ssh root@192.168.30.100
     cd /mnt/tank/backups/debian-upgrade
     ls -t *-backup-*.{tar.gz,sql.gz} | tail -n +6 | xargs -I {} rm {}
     ```

6. **Starte Dienste**:
   - Starte die Dienste wieder:
     ```bash
     systemctl start postgresql
     systemctl start gunicorn
     systemctl start nginx
     ```

7. **Prüfe Backups auf TrueNAS**:
   ```bash
   ssh root@192.168.30.100 ls /mnt/tank/backups/debian-upgrade/
   ```
   - Erwartete Ausgabe: Maximal fünf Backups pro Typ (`papermerge-config-backup-<date>.tar.gz`, `papermerge-db-backup-<date>.sql.gz`, `system-backup-<date>.tar.gz`).

**Erkenntnis**: Ein manuelles Backup schützt vor Datenverlust und ermöglicht eine Wiederherstellung bei Problemen während des Upgrades.

**Quelle**: https://wiki.debian.org/DebianUpgrade

## Übung 2: Manuelles Upgrade auf Debian 13

**Ziel**: Führe das Upgrade von Debian 12 (Bookworm) auf Debian 13 (Trixie) durch und stelle sicher, dass Papermerge weiter funktioniert.

**Aufgabe**: Aktualisiere die Paketquellen, führe das Upgrade durch und überprüfe die Dienste.

1. **Verbinde dich mit dem Container**:
   ```bash
   ssh root@192.168.30.120
   ```

2. **Aktualisiere Debian 12 vollständig**:
   ```bash
   apt update
   apt full-upgrade -y
   apt autoremove -y
   apt autoclean
   ```

3. **Sichere die aktuelle sources.list**:
   ```bash
   cp /etc/apt/sources.list /etc/apt/sources.list.bak
   ```

4. **Aktualisiere sources.list für Debian 13**:
   - Bearbeite die Paketquellen:
     ```bash
     nano /etc/apt/sources.list
     ```
   - Ersetze den Inhalt durch:
     ```
     deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
     deb http://deb.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
     deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
     ```
   - Speichere und schließe die Datei.

5. **Führe das Upgrade durch**:
   - Aktualisiere die Paketlisten:
     ```bash
     apt update
     ```
   - Führe ein minimales Upgrade durch:
     ```bash
     apt upgrade -y
     ```
   - Führe ein vollständiges Dist-Upgrade durch:
     ```bash
     apt dist-upgrade -y
     ```
   - Bereinige das System:
     ```bash
     apt autoremove -y
     apt autoclean
     ```

6. **Prüfe die Debian-Version**:
   ```bash
   cat /etc/os-release
   ```
   - Erwartete Ausgabe: `VERSION_CODENAME=trixie`.

7. **Überprüfe Abhängigkeiten für Papermerge**:
   - Installiere die benötigten Pakete erneut, um Kompatibilitätsprobleme zu vermeiden:
     ```bash
     apt install -y python3 python3-pip python3-venv git nginx postgresql postgresql-contrib libpq-dev tesseract-ocr tesseract-ocr-eng tesseract-ocr-deu tesseract-ocr-fra tesseract-ocr-spa imagemagick poppler-utils pdftk nfs-common
     pip3 install gunicorn
     ```

8. **Überprüfe die Papermerge-Konfiguration**:
   - Stelle sicher, dass der NFS-Mount aktiv ist:
     ```bash
     mount | grep /var/lib/papermerge
     ```
     - Erwartete Ausgabe: `192.168.30.100:/mnt/tank/papermerge on /var/lib/papermerge type nfs`.
     - Falls nicht gemountet:
       ```bash
       mount -t nfs 192.168.30.100:/mnt/tank/papermerge /var/lib/papermerge
       ```
   - Aktualisiere die virtuelle Umgebung von Papermerge:
     ```bash
     rm -rf /opt/papermerge/.venv
     python3 -m venv /opt/papermerge/.venv
     /opt/papermerge/.venv/bin/pip install -r /opt/papermerge/requirements/base.txt
     ```
   - Führe Datenbankmigrationen durch:
     ```bash
     export PAPERMERGE_CONFIG=/opt/papermerge/papermerge.conf.py
     /opt/papermerge/.venv/bin/python /opt/papermerge/manage.py migrate
     ```

9. **Starte Dienste**:
   ```bash
   systemctl start postgresql
   systemctl start gunicorn
   systemctl start nginx
   ```

10. **Teste Papermerge**:
    - Öffne `http://papermerge.homelab.local` in einem Browser.
    - Melde dich an (Benutzer: `admin`, Passwort: `securepassword789`).
    - Lade ein Testdokument hoch (z. B. PDF in `/mnt/tank/papermerge`) und teste OCR.
    - Erwartete Ausgabe: Papermerge-Weboberfläche ist zugänglich, OCR funktioniert.
    - **Hinweis**: Falls Papermerge nicht lädt, überprüfe die Logs:
      ```bash
      cat /var/log/nginx/error.log
      journalctl -u gunicorn
      cat /var/log/postgresql/postgresql-15-main.log
      ```
    - Falls Python-Versionen inkompatibel sind (Papermerge benötigt Python 3.9–3.11), installiere eine ältere Version:
      ```bash
      apt install -y python3.11
      rm -rf /opt/papermerge/.venv
      python3.11 -m venv /opt/papermerge/.venv
      /opt/papermerge/.venv/bin/pip install -r /opt/papermerge/requirements/base.txt
      ```

**Erkenntnis**: Das manuelle Upgrade erfordert sorgfältige Schritte, um Paketquellen zu aktualisieren, das System zu upgraden und Anwendungen wie Papermerge zu überprüfen.

**Quelle**: https://wiki.debian.org/DebianUpgrade, https://www.debian.org/releases/trixie/releasenotes

## Übung 3: Überprüfung des Systems nach dem Upgrade

**Ziel**: Überprüfe die Funktionalität des Debian 13 Systems und der Papermerge-Dienste.

**Aufgabe**: Teste das System, die Dienste und die Papermerge-Weboberfläche.

1. **Prüfe Systemstatus**:
   ```bash
   ssh root@192.168.30.120
   uname -a
   ```
   - Erwartete Ausgabe: Kernel-Version für Debian 13 (z. B. `6.x`).
   ```bash
   dpkg -l | grep linux-image
   ```
   - Erwartete Ausgabe: Installierte Kernel-Pakete für Debian 13.

2. **Prüfe Dienste**:
   - Überprüfe PostgreSQL, Gunicorn und Nginx:
     ```bash
     systemctl status postgresql
     systemctl status gunicorn
     systemctl status nginx
     ```
     - Erwartete Ausgabe: Status `active (running)` für alle Dienste.

3. **Prüfe Papermerge**:
   - Teste die Weboberfläche:
     ```bash
     curl -s -o /dev/null -w "%{http_code}" http://192.168.30.120/
     ```
     - Erwartete Ausgabe: `200`.
   - Öffne `http://papermerge.homelab.local` im Browser.
   - Lade ein PDF hoch und teste die Volltextsuche.
   - Erwartete Ausgabe: Dokumente werden hochgeladen, OCR funktioniert.

4. **Prüfe NFS-Mount**:
   ```bash
   df -h | grep /var/lib/papermerge
   ```
   - Erwartete Ausgabe: NFS-Mount von `192.168.30.100:/mnt/tank/papermerge`.

5. **Fehlerbehebung**:
   - Falls Dienste nicht starten, überprüfe Logs:
     ```bash
     cat /var/log/nginx/error.log
     journalctl -u gunicorn
     cat /var/log/postgresql/postgresql-15-main.log
     ```
   - Falls Paketkonflikte auftreten:
     ```bash
     apt install -f
     ```
   - Falls Papermerge nicht funktioniert, überprüfe die Python-Version:
     ```bash
     python3 --version
     ```
     - Stelle sicher, dass Python 3.9–3.11 verwendet wird, und aktualisiere die virtuelle Umgebung bei Bedarf (siehe Übung 2, Schritt 10).

**Erkenntnis**: Eine gründliche Überprüfung nach dem Upgrade stellt sicher, dass das System und die Anwendungen stabil laufen.

**Quelle**: https://wiki.debian.org/DebianUpgrade

## Best Practices für Schüler

- **Upgrade-Design**:
  - Teste das Upgrade in einem geklonten LXC-Container, bevor du es auf dem Produktivsystem durchführst.
  - Lies die Debian-Releasenotes (https://www.debian.org/releases/trixie/releasenotes) für bekannte Probleme.
- **Sicherheit**:
  - Schränke Zugriff ein:
    ```bash
    ufw allow from 192.168.30.0/24 to any port 80 proto tcp
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
  - Verwende HTTPS für Papermerge bei externem Zugriff:
    ```bash
    turnkey-letsencrypt papermerge.homelab.local
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
  - Teste Backups vor dem Upgrade:
    ```bash
    mkdir /tmp/test-restore
    tar -xzf /mnt/tank/backups/debian-upgrade/papermerge-config-backup-<date>.tar.gz -C /tmp/test-restore
    gunzip -c /mnt/tank/backups/debian-upgrade/papermerge-db-backup-<date>.sql.gz | su - postgres -c "psql -d papermerge_restore"
    ```
- **Fehlerbehebung**:
  - Prüfe Apt-Logs:
    ```bash
    cat /var/log/apt/history.log
    cat /var/log/apt/term.log
    ```
  - Prüfe System-Logs:
    ```bash
    journalctl -xb
    ```
  - Prüfe Papermerge-Logs:
    ```bash
    cat /var/log/nginx/error.log
    journalctl -u gunicorn
    cat /var/log/postgresql/postgresql-15-main.log
    ```

**Quellen**: https://wiki.debian.org/DebianUpgrade, https://www.debian.org/releases/trixie/releasenotes, https://docs.papermerge.io

## Empfehlungen für Schüler

- **Setup**: Debian 13, Papermerge DMS, TrueNAS-Backups.
- **Workloads**: System-Upgrade, Backup, Überwachung.
- **Integration**: Proxmox (LXC), TrueNAS (NFS), OPNsense (DNS).
- **Beispiel**: Manuelles Upgrade eines produktiven Systems mit laufendem DMS.

## Tipps für den Erfolg

- **Einfachheit**: Führe das Upgrade schrittweise durch und teste nach jedem Schritt.
- **Übung**: Teste Backups und Wiederherstellung in einer Testumgebung.
- **Fehlerbehebung**: Nutze System- und Anwendungslogs für Debugging.
- **Lernressourcen**: https://wiki.debian.org/DebianUpgrade, https://www.debian.org/releases/trixie/releasenotes, https://docs.papermerge.io.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Manuelles Upgrade von Debian 12 auf Debian 13 mit Backup und Überprüfung.
- **Lernwert**: Verständnis von Linux-Systemupgrades und Anwendungskontinuität.
- **Sicherheit**: Backup-Strategien und Fehlerbehebung für stabile Systeme.

**Nächste Schritte**: Möchtest du eine Anleitung zur manuellen Integration von Debian 13 mit Checkmk, Home Assistant oder anderen HomeLab-Diensten?

**Quellen**:
- Debian-Dokumentation: https://www.debian.org/releases/trixie
- Webquellen: https://wiki.debian.org/DebianUpgrade, https://www.debian.org/releases/trixie/releasenotes
```