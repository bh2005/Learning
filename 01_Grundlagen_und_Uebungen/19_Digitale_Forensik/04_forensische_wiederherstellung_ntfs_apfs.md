# Praxisorientierte Anleitung: Forensische Wiederherstellung gelöschter Dateien auf NTFS- und APFS-Dateisystemen mit The Sleuth Kit auf Debian

## Einführung
Die forensische Wiederherstellung gelöschter Dateien auf Dateisystemen wie **NTFS** (New Technology File System, Windows) und **APFS** (Apple File System, macOS) ist eine zentrale Aufgabe in der digitalen Forensik, um verlorene oder absichtlich entfernte Daten wiederherzustellen, ohne die Integrität des Mediums zu beeinträchtigen. **The Sleuth Kit (TSK)** ist ein Open-Source-Toolkit, das die Analyse dieser Dateisysteme unterstützt, einschließlich der Identifizierung und Wiederherstellung gelöschter Dateien. Diese Anleitung zeigt, wie man gelöschte Dateien auf NTFS- und APFS-Medien (z. B. USB-Stick oder Festplatte) unter Debian mit TSK und optional Autopsy wiederherstellt. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, forensische Analysen und Wiederherstellungen auf diesen Dateisystemen durchzuführen. Diese Anleitung ist ideal für IT-Sicherheitsexperten, Ermittler und Lernende, die ihre forensischen Kenntnisse erweitern möchten.

**Voraussetzungen:**
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Ein Test-Medium (z. B. USB-Stick oder VM-Disk-Image) mit NTFS- oder APFS-Dateisystem
- Grundlegende Kenntnisse der Linux-Kommandozeile und digitaler Forensik
- The Sleuth Kit und Autopsy installiert
- Optional: Hardware-Write-Blocker für physische Medien
- Mindestens 10 GB freier Speicher für Disk-Images

## Grundlegende Konzepte der forensischen Wiederherstellung
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **Dateisystem-Konzepte**:
   - **NTFS**: Nutzt die Master File Table (MFT) für Metadaten, Journaling ($LogFile), und speichert gelöschte Dateien, bis sie überschrieben werden.
   - **APFS**: Unterstützt Snapshots, Container-Struktur und Verschlüsselung; gelöschte Dateien bleiben in Blöcken, bis sie überschrieben werden.
   - **Inodes/Blocks**: Speicherorte für Datei-Metadaten und Inhalte.
2. **Forensische Konzepte**:
   - **Disk Image**: Bit-für-Bit-Kopie des Original-Mediums für sichere Analyse.
   - **Hash-Werte**: MD5/SHA-256 zur Integritätsprüfung.
   - **Chain of Custody**: Dokumentation aller Schritte für gerichtliche Gültigkeit.
3. **TSK-Tools**:
   - `mmls`: Listet Partitionen auf.
   - `fsstat`: Zeigt Dateisystem-Details.
   - `fls`: Listet Dateien, inklusive gelöschter.
   - `icat`: Extrahiert Dateien basierend auf Inodes.
   - `dd`: Erstellt Disk-Images.

## Übungen zum Verinnerlichen

### Übung 1: Vorbereitung und Erstellung eines Test-Mediums
**Ziel**: Lernen, wie man TSK installiert und Test-Medien für NTFS und APFS vorbereitet.

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
3. **Schritt 3**: Bereite Test-Medien vor.
   - **NTFS** (USB-Stick, z. B. `/dev/sdb`):
     ```bash
     lsblk  # Ermittle Geräte-ID
     sudo fdisk /dev/sdb
     # Erstelle Partition (n, p, 1), Typ NTFS (t, 7), Schreib (w)
     sudo mkfs.ntfs /dev/sdb1
     sudo mkdir /mnt/ntfs
     sudo mount /dev/sdb1 /mnt/ntfs
     echo "NTFS-Testdatei" > /mnt/ntfs/important_ntfs.txt
     sudo umount /mnt/ntfs
     ```
   - **APFS** (Image-Datei, erstellt auf macOS oder mit Tools wie `hdiutil`):
     ```bash
     # Auf macOS:
     hdiutil create -size 1g -type UDIF -fs APFS -volname TestAPFS test_apfs.dmg
     echo "APFS-Testdatei" > /Volumes/TestAPFS/important_apfs.txt
     hdiutil detach /Volumes/TestAPFS
     # Kopiere test_apfs.dmg nach Debian (z. B. via SCP)
     scp user@macos:/path/test_apfs.dmg /media/forensic/
     ```
   - **Warnung**: Verwende nur Test-Medien, um Datenverlust zu vermeiden!
4. **Schritt 4**: Berechne Hash-Werte.
   ```bash
   sudo md5sum /dev/sdb > /media/forensic/ntfs_hash.txt
   md5sum /media/forensic/test_apfs.dmg > /media/forensic/apfs_hash.txt
   ```

**Reflexion**: Warum ist die Integritätsprüfung mit Hash-Werten entscheidend, und wie schützt ein Write-Blocker die Beweissicherung?

### Übung 2: Wiederherstellung gelöschter Dateien auf NTFS
**Ziel**: Verstehen, wie man gelöschte Dateien auf einem NTFS-Dateisystem mit TSK wiederherstellt.

1. **Schritt 1**: Erstelle ein Disk-Image des NTFS-Mediums.
   ```bash
   sudo dd if=/dev/sdb of=/media/forensic/ntfs_image.dd bs=4M status=progress
   ```
2. **Schritt 2**: Analysiere Partitionen mit `mmls`.
   ```bash
   mmls /media/forensic/ntfs_image.dd
   ```
   Notiere den Offset der NTFS-Partition (z. B. `2048` Sektoren).
3. **Schritt 3**: Liste Dateien mit `fls`.
   ```bash
   fls -o 2048 /media/forensic/ntfs_image.dd
   ```
   Die Ausgabe zeigt Dateien wie `important_ntfs.txt` mit Inode-Nummern.
4. **Schritt 4**: Simuliere Löschung und erstelle ein neues Image.
   ```bash
   sudo mount /dev/sdb1 /mnt/ntfs
   rm /mnt/ntfs/important_ntfs.txt
   sudo umount /mnt/ntfs
   sudo dd if=/dev/sdb of=/media/forensic/ntfs_deleted.dd bs=4M status=progress
   ```
5. **Schritt 5**: Identifiziere gelöschte Dateien.
   ```bash
   fls -o 2048 -d -D /media/forensic/ntfs_deleted.dd
   ```
   Suche nach `* important_ntfs.txt` (gelöschte Dateien sind mit `*` markiert).
6. **Schritt 6**: Stelle die gelöschte Datei wieder her.
   ```bash
   icat -o 2048 -r /media/forensic/ntfs_deleted.dd <inode> > recovered_ntfs.txt
   cat recovered_ntfs.txt
   ```
   Die Ausgabe sollte `NTFS-Testdatei` sein. (`-r` aktiviert Raw-Recovery.)
7. **Schritt 7**: Prüfe die Integrität.
   ```bash
   md5sum /media/forensic/ntfs_deleted.dd
   ```
   Vergleiche mit `ntfs_hash.txt`.

**Reflexion**: Wie erleichtert die Master File Table (MFT) die Wiederherstellung in NTFS, und warum können gelöschte Dateien überschrieben werden?

### Übung 3: Wiederherstellung gelöschter Dateien auf APFS mit Autopsy
**Ziel**: Lernen, wie man gelöschte Dateien auf einem APFS-Dateisystem mit TSK und Autopsy wiederherstellt.

1. **Schritt 1**: Erstelle ein Disk-Image des APFS-Mediums.
   ```bash
   cp /media/forensic/test_apfs.dmg /media/forensic/apfs_image.dmg
   ```
2. **Schritt 2**: Analysiere Partitionen mit `mmls`.
   ```bash
   mmls /media/forensic/apfs_image.dmg
   ```
   Notiere den Offset des APFS-Containers (z. B. `409640`).
3. **Schritt 3**: Liste Dateien mit `fls`.
   ```bash
   fls -o 409640 /media/forensic/apfs_image.dmg
   ```
   Die Ausgabe zeigt Dateien wie `important_apfs.txt`.
4. **Schritt 4**: Simuliere Löschung (auf macOS) und erstelle ein neues Image.
   ```bash
   # Auf macOS:
   hdiutil attach test_apfs.dmg
   rm /Volumes/TestAPFS/important_apfs.txt
   hdiutil detach /Volumes/TestAPFS
   # Kopiere neues Image nach Debian
   scp user@macos:/path/test_apfs.dmg /media/forensic/apfs_deleted.dmg
   ```
5. **Schritt 5**: Analysiere mit Autopsy.
   - Starte Autopsy:
     ```bash
     autopsy
     ```
     Öffne `http://localhost:9999/autopsy` im Browser.
   - Erstelle einen neuen Case: **Create New Case** > Name: `APFSCase` > Data Source: `/media/forensic/apfs_deleted.dmg`.
   - Wähle **Ingest Modules** (z. B. Deleted Files, File Type Identification).
   - Analysiere: **Views** > **Deleted Files** > Suche nach `important_apfs.txt`.
   - Exportiere: Rechtsklick auf `important_apfs.txt` > **Extract File**.
   - Überprüfe die extrahierte Datei im Ausgabeordner (z. B. `/var/lib/autopsy/APFSCase`).
6. **Schritt 6**: Stelle mit TSK wieder her (falls Autopsy nicht ausreicht).
   ```bash
   fls -o 409640 -d -D /media/forensic/apfs_deleted.dmg
   icat -o 409640 -r /media/forensic/apfs_deleted.dmg <inode> > recovered_apfs.txt
   cat recovered_apfs.txt
   ```
   Die Ausgabe sollte `APFS-Testdatei` sein.
7. **Schritt 7**: Dokumentiere den Prozess (Chain of Custody).
   ```bash
   echo "Analyse am $(date): APFS-Image apfs_deleted.dmg, Wiederherstellung von important_apfs.txt" >> /media/forensic/case_log.txt
   ```

**Reflexion**: Warum ist die Wiederherstellung auf APFS komplexer als auf NTFS, und wie hilft Autopsy bei der Analyse von Snapshots?

## Tipps für den Erfolg
- Verwenden Sie immer einen Write-Blocker (Hardware oder Software, z. B. `hdparm --read-only`) für Original-Medien.
- Dokumentieren Sie jeden Schritt mit Zeitstempeln für die Chain of Custody.
- Testen Sie mit NIST-Test-Images (https://www.cfreds.nist.gov) für bekannte Ergebnisse.
- Überprüfen Sie Hash-Werte vor und nach der Analyse mit `md5sum` oder `sha256sum`.
- Beachten Sie APFS-Besonderheiten wie Verschlüsselung oder Snapshots, die Wiederherstellung erschweren können.

## Fazit
In dieser Anleitung haben Sie die forensische Wiederherstellung gelöschter Dateien auf NTFS- und APFS-Dateisystemen mit The Sleuth Kit und Autopsy auf Debian erkundet. Durch die Übungen haben Sie praktische Erfahrung mit Disk-Images, Dateisystem-Analysen und Wiederherstellung gesammelt. Diese Fähigkeiten sind essenziell für forensische Untersuchungen. Üben Sie weiter, um andere Dateisysteme wie ext4 oder fortgeschrittene Tools wie Volatility zu meistern!

**Nächste Schritte**:
- Erkunden Sie die Wiederherstellung auf ext4 oder FAT32 mit TSK.
- Integrieren Sie TSK mit Bulk Extractor für massenhafte Datenextraktion.
- Lernen Sie Speicher-Forensik mit Volatility für RAM-Analysen.

**Quellen**:
- The Sleuth Kit-Dokumentation: https://www.sleuthkit.org/sleuthkit/docs.html
- Autopsy-Dokumentation: https://www.autopsy.com/support/documentation/
- NIST Computer Forensics Reference Data Sets: https://www.cfreds.nist.gov/
- NTFS-Dokumentation: https://docs.microsoft.com/en-us/windows/win32/fileio/ntfs
- APFS-Dokumentation: https://developer.apple.com/documentation/apfs