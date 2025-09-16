# Praxisorientierte Anleitung: Wiederherstellung gelöschter Dateien auf einem USB-Stick mit The Sleuth Kit auf Debian

## Einführung
Die Wiederherstellung gelöschter Dateien auf einem USB-Stick ist eine zentrale Aufgabe in der digitalen Forensik, um verlorene oder absichtlich entfernte Daten wiederherzustellen, ohne die Integrität des Mediums zu beeinträchtigen. **The Sleuth Kit (TSK)** ist ein Open-Source-Toolkit, das Dateisystem-Analysen ermöglicht, insbesondere für Dateisysteme wie FAT32 oder NTFS, die häufig auf USB-Sticks verwendet werden. Diese Anleitung führt Sie durch die forensische Wiederherstellung gelöschter Dateien auf einem USB-Stick unter Debian, mit Fokus auf TSK und ergänzend Autopsy für eine visuelle Analyse. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, gelöschte Dateien sicher zu identifizieren und wiederherzustellen. Diese Anleitung ist ideal für IT-Sicherheitsexperten, Ermittler und Lernende, die in die digitale Forensik einsteigen möchten.

**Voraussetzungen:**
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Ein USB-Stick mit FAT32 oder NTFS (für Tests, keine produktiven Daten!)
- Grundlegende Kenntnisse der Linux-Kommandozeile
- The Sleuth Kit und Autopsy installiert
- Optional: Hardware-Write-Blocker für forensische Integrität
- Mindestens 10 GB freier Speicher für Disk-Images

## Grundlegende Konzepte der forensischen Wiederherstellung
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **Forensische Konzepte**:
   - **Disk Image**: Bit-für-Bit-Kopie des USB-Sticks für sichere Analyse.
   - **Hash-Werte**: MD5/SHA-256 zur Überprüfung der Integrität.
   - **Gelöschte Dateien**: Dateien, die im Dateisystem als gelöscht markiert sind, aber noch physisch vorhanden sein können.
   - **Chain of Custody**: Dokumentation aller Schritte für gerichtliche Gültigkeit.
2. **TSK-Tools**:
   - `mmls`: Listet Partitionen eines Images auf.
   - `fls`: Listet Dateien, inklusive gelöschter.
   - `icat`: Extrahiert Dateien basierend auf Inodes.
   - `dd`: Erstellt Disk-Images.
3. **Wichtige Befehle**:
   - `md5sum`/`sha256sum`: Berechnet Hash-Werte.
   - `autopsy`: GUI für TSK zur vereinfachten Analyse.

## Übungen zum Verinnerlichen

### Übung 1: Vorbereitung und Installation von Tools
**Ziel**: Lernen, wie man TSK und Autopsy installiert und einen USB-Stick für Tests vorbereitet.

1. **Schritt 1**: Installiere The Sleuth Kit und Autopsy.
   ```bash
   sudo apt update
   sudo apt install -y sleuthkit autopsy
   ```
2. **Schritt 2**: Überprüfe die Installation.
   ```bash
   mmls -V
   fls -V
   autopsy -V
   ```
   Die Ausgabe sollte die Versionen anzeigen (z. B. TSK 4.12.0).
3. **Schritt 3**: Bereite den USB-Stick vor.
   - Stecke einen USB-Stick ein und ermittle die Geräte-ID (z. B. `/dev/sdb`):
     ```bash
     lsblk
     ```
   - **Warnung**: Verwende nur einen Test-USB-Stick, um Datenverlust zu vermeiden!
   - Erstelle ein FAT32-Dateisystem und Testdateien:
     ```bash
     sudo fdisk /dev/sdb
     # Erstelle eine Partition (n, p, 1), setze Typ auf FAT32 (t, b), Schreib (w)
     sudo mkfs.vfat -F 32 /dev/sdb1
     sudo mkdir /mnt/usb
     sudo mount /dev/sdb1 /mnt/usb
     echo "Wichtige Datei" > /mnt/usb/important.txt
     echo "Geheime Notiz" > /mnt/usb/secret.txt
     sudo umount /mnt/usb
     ```
4. **Schritt 4**: Berechne den Hash des USB-Sticks.
   ```bash
   sudo md5sum /dev/sdb > /media/forensic/usb_hash.txt
   ```

**Reflexion**: Warum ist die Erstellung eines Hash-Werts vor der Analyse wichtig, und wie schützt ein Write-Blocker die Integrität des USB-Sticks?

### Übung 2: Erstellen eines Disk-Images und Analyse mit TSK
**Ziel**: Verstehen, wie man ein forensisches Disk-Image erstellt und mit TSK gelöschte Dateien identifiziert.

1. **Schritt 1**: Erstelle ein Disk-Image des USB-Sticks.
   ```bash
   sudo dd if=/dev/sdb of=/media/forensic/usb_image.dd bs=4M status=progress
   ```
   - `if`: Input (USB-Stick).
   - `of`: Output (Image-Datei).
   - `bs=4M`: Block-Size für Geschwindigkeit.
2. **Schritt 2**: Analysiere Partitionen mit `mmls`.
   ```bash
   mmls /media/forensic/usb_image.dd
   ```
   Notiere den Offset der FAT32-Partition (z. B. `2048` Sektoren).
3. **Schritt 3**: Liste Dateien mit `fls`.
   ```bash
   fls -o 2048 /media/forensic/usb_image.dd
   ```
   Die Ausgabe zeigt Dateien wie `important.txt` und `secret.txt` mit Inode-Nummern (z. B. `5`, `6`).
4. **Schritt 4**: Extrahiere eine Datei mit `icat`.
   ```bash
   icat -o 2048 /media/forensic/usb_image.dd 5 > recovered_important.txt
   cat recovered_important.txt
   ```
   Die Ausgabe sollte `Wichtige Datei` sein.
5. **Schritt 5**: Prüfe die Integrität des Images.
   ```bash
   md5sum /media/forensic/usb_image.dd
   ```
   Vergleiche mit `usb_hash.txt`.

**Reflexion**: Warum ist ein Disk-Image für die forensische Analyse notwendig, und wie erleichtert `fls` die Identifizierung von Dateien?

### Übung 3: Wiederherstellung gelöschter Dateien mit TSK und Autopsy
**Ziel**: Lernen, wie man gelöschte Dateien auf einem USB-Stick mit TSK und Autopsy wiederherstellt.

1. **Schritt 1**: Simuliere das Löschen einer Datei.
   - Mounte den USB-Stick:
     ```bash
     sudo mount /dev/sdb1 /mnt/usb
     rm /mnt/usb/secret.txt
     sudo umount /mnt/usb
     ```
   - Erstelle ein neues Disk-Image:
     ```bash
     sudo dd if=/dev/sdb of=/media/forensic/usb_deleted.dd bs=4M status=progress
     ```
2. **Schritt 2**: Liste gelöschte Dateien mit `fls`.
   ```bash
   fls -o 2048 -d -D /media/forensic/usb_deleted.dd
   ```
   Die Ausgabe zeigt gelöschte Dateien, z. B. `* 6 secret.txt` (`*` markiert gelöschte Dateien).
3. **Schritt 3**: Stelle die gelöschte Datei mit `icat` wieder her.
   ```bash
   icat -o 2048 -r /media/forensic/usb_deleted.dd 6 > recovered_secret.txt
   cat recovered_secret.txt
   ```
   Die Ausgabe sollte `Geheime Notiz` sein. (`-r` aktiviert Raw-Recovery für gelöschte Dateien.)
4. **Schritt 4**: Analysiere mit Autopsy.
   - Starte Autopsy:
     ```bash
     autopsy
     ```
     Öffne `http://localhost:9999/autopsy` im Browser.
   - Erstelle einen neuen Case: **Create New Case** > Name: `USBCase` > Data Source: `/media/forensic/usb_deleted.dd`.
   - Wähle **Ingest Modules** (z. B. File Type Identification, Deleted Files).
   - Analysiere: **Views** > **Deleted Files** > Suche nach `secret.txt`.
   - Exportiere: Rechtsklick auf `secret.txt` > **Extract File**.
   - Überprüfe die extrahierte Datei im Ausgabeordner von Autopsy (z. B. `/var/lib/autopsy/USBCase`).
5. **Schritt 5**: Dokumentiere den Prozess (Chain of Custody).
   - Erstelle ein Log:
     ```bash
     echo "Analyse am $(date): USB-Stick /dev/sdb, Image: usb_deleted.dd, Wiederherstellung von secret.txt" >> /media/forensic/case_log.txt
     ```

**Reflexion**: Wie erleichtert Autopsy die Wiederherstellung gegenüber TSK-Befehlen, und warum sind gelöschte Dateien auf FAT32 oft leichter wiederherstellbar als auf NTFS?

## Tipps für den Erfolg
- Verwenden Sie immer einen Write-Blocker (Hardware oder Software, z. B. `hdparm --read-only`) für Original-Medien.
- Dokumentieren Sie jeden Schritt mit Zeitstempeln für die Chain of Custody.
- Testen Sie mit bekannten Test-Daten (z. B. NIST CFReDS: https://www.cfreds.nist.gov).
- Überprüfen Sie Hash-Werte vor und nach der Analyse: `md5sum` oder `sha256sum`.
- Arbeiten Sie nur mit Images, um das Original-Medium zu schützen.

## Fazit
In dieser Anleitung haben Sie gelernt, wie man gelöschte Dateien auf einem USB-Stick mit The Sleuth Kit und Autopsy auf Debian wiederherstellt. Durch die Übungen haben Sie praktische Erfahrung mit der Erstellung von Disk-Images, der Analyse von FAT32-Dateisystemen, der Wiederherstellung gelöschter Dateien und der Nutzung von Autopsy gesammelt. Diese Fähigkeiten sind essenziell für forensische Untersuchungen. Üben Sie weiter, um fortgeschrittene Techniken wie die Analyse von NTFS, APFS oder Speicher-Forensik zu meistern!

**Nächste Schritte**:
- Erkunden Sie die Wiederherstellung auf anderen Dateisystemen (z. B. NTFS, APFS).
- Integrieren Sie TSK mit Tools wie Volatility für RAM-Analysen.
- Lernen Sie fortgeschrittene forensische Tools wie Bulk Extractor oder Scalpel.

**Quellen**:
- The Sleuth Kit-Dokumentation: https://www.sleuthkit.org/sleuthkit/docs.html
- Autopsy-Dokumentation: https://www.autopsy.com/support/documentation/
- NIST Computer Forensics Reference Data Sets: https://www.cfreds.nist.gov/