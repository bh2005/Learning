# Praxisorientierte Anleitung: Einstieg in forensische Analyse von Dateisystemen (NTFS und APFS) mit The Sleuth Kit auf Debian

## Einführung
Die forensische Analyse von Dateisystemen wie **NTFS** (New Technology File System, Windows) und **APFS** (Apple File System, macOS) ist ein zentraler Bestandteil der digitalen Forensik, um Beweise aus Speichermedien zu extrahieren, ohne die Integrität der Daten zu beeinträchtigen. **The Sleuth Kit (TSK)** bietet leistungsstarke Tools zur Analyse dieser Dateisysteme, einschließlich Partitionserkennung, Datei-Extraktion und Wiederherstellung gelöschter Daten. Diese Anleitung führt Sie in die forensische Untersuchung von NTFS- und APFS-Dateisystemen auf Debian ein, mit Fokus auf TSK und ergänzenden Tools wie Autopsy. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, forensische Analysen von NTFS- und APFS-Medien durchzuführen. Diese Anleitung ist ideal für IT-Sicherheitsexperten, Ermittler und Lernende, die in die forensische Analyse von Dateisystemen einsteigen möchten.

**Voraussetzungen:**
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Grundlegende Kenntnisse der Linux-Kommandozeile und digitaler Forensik
- Ein Test-Datenträger mit NTFS oder APFS (z. B. USB-Stick oder VM-Disk-Image)
- The Sleuth Kit und Autopsy installiert
- Ein Texteditor (z. B. `nano`, `vim`)
- Optional: Hardware-Write-Blocker für physische Medien

## Grundlegende Konzepte der forensischen Dateisystem-Analyse
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **Dateisystem-Konzepte**:
   - **NTFS**: Windows-Dateisystem mit MFT (Master File Table), Journaling und Metadaten wie $FILE_NAME.
   - **APFS**: Apple-Dateisystem mit Container-Struktur, Snapshots und Verschlüsselung.
   - **Inodes/Blocks**: Speicherorte für Datei-Metadaten und Inhalte.
2. **Forensische Konzepte**:
   - **Disk Image**: Bit-für-Bit-Kopie des Original-Mediums.
   - **Hash-Werte**: MD5/SHA-256 zur Integritätsprüfung.
   - **Chain of Custody**: Dokumentation aller Schritte für gerichtliche Gültigkeit.
3. **TSK-Tools**:
   - `mmls`: Listet Partitionen auf.
   - `fsstat`: Zeigt Dateisystem-Details.
   - `fls`: Listet Dateien, inklusive gelöschter.
   - `icat`: Extrahiert Dateien basierend auf Inodes.
4. **Wichtige Befehle**:
   - `dd`: Erstellt Disk-Images.
   - `md5sum`/`sha256sum`: Prüft Integrität.

## Übungen zum Verinnerlichen

### Übung 1: Vorbereitung und Installation von Tools
**Ziel**: Lernen, wie man TSK und ergänzende Tools auf Debian installiert und ein Test-Medium vorbereitet.

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
3. **Schritt 3**: Erstelle Test-Medien für NTFS und APFS.
   - **NTFS**:
     ```bash
     sudo fdisk /dev/sdb  # Erstelle eine Partition (n, t, 7 für NTFS)
     sudo mkfs.ntfs /dev/sdb1
     sudo mkdir /mnt/ntfs
     sudo mount /dev/sdb1 /mnt/ntfs
     echo "NTFS-Testdatei" > /mnt/ntfs/test_ntfs.txt
     sudo umount /mnt/ntfs
     ```
   - **APFS** (in einer VM oder mit macOS-Tool):
     ```bash
     # Auf macOS (für Test-Image):
     hdiutil create -size 1g -type UDIF -fs APFS -volname TestAPFS test_apfs.dmg
     echo "APFS-Testdatei" > /Volumes/TestAPFS/test_apfs.txt
     hdiutil detach /Volumes/TestAPFS
     # Kopiere test_apfs.dmg nach Debian
     ```
   - **Warnung**: Verwende nur Test-Medien, um Datenverlust zu vermeiden!
4. **Schritt 4**: Berechne Hash-Werte für Integritätsprüfung.
   ```bash
   sudo md5sum /dev/sdb > /media/forensic/ntfs_hash.txt
   md5sum test_apfs.dmg > /media/forensic/apfs_hash.txt
   ```

**Reflexion**: Warum sind Hash-Werte in der forensischen Analyse unerlässlich, und wie unterstützt ein Write-Blocker die Beweissicherung?

### Übung 2: Analyse eines NTFS-Dateisystems
**Ziel**: Verstehen, wie man ein NTFS-Dateisystem forensisch analysiert und gelöschte Dateien wiederherstellt.

1. **Schritt 1**: Erstelle ein Disk-Image von NTFS.
   ```bash
   sudo dd if=/dev/sdb of=/media/forensic/ntfs_image.dd bs=4M status=progress
   ```
2. **Schritt 2**: Analysiere Partitionen mit `mmls`.
   ```bash
   mmls /media/forensic/ntfs_image.dd
   ```
   Notiere die Offset-Werte für NTFS-Partitionen (z. B. `2048` Sektoren).
3. **Schritt 3**: Untersuche das Dateisystem mit `fsstat`.
   ```bash
   fsstat -o 2048 /media/forensic/ntfs_image.dd
   ```
   Die Ausgabe zeigt Details wie MFT-Position und Cluster-Größe.
4. **Schritt 4**: Liste Dateien mit `fls`.
   ```bash
   fls -o 2048 /media/forensic/ntfs_image.dd
   ```
   Die Ausgabe listet Dateien wie `test_ntfs.txt` mit Inode-Nummern.
5. **Schritt 5**: Simuliere Löschung und Wiederherstellung.
   - Mounte das Original (nur für Test!):
     ```bash
     sudo mount /dev/sdb1 /mnt/ntfs
     rm /mnt/ntfs/test_ntfs.txt
     sudo umount /mnt/ntfs
     sudo dd if=/dev/sdb of=/media/forensic/ntfs_deleted.dd bs=4M status=progress
     ```
   - Suche gelöschte Dateien:
     ```bash
     fls -o 2048 -d /media/forensic/ntfs_deleted.dd
     ```
   - Stelle die Datei wieder her:
     ```bash
     icat -o 2048 /media/forensic/ntfs_deleted.dd <inode> > recovered_ntfs.txt
     cat recovered_ntfs.txt
     ```
     Ausgabe sollte `NTFS-Testdatei` sein.
6. **Schritt 6**: Prüfe die Integrität.
   ```bash
   md5sum /media/forensic/ntfs_deleted.dd
   ```
   Vergleiche mit `ntfs_hash.txt`.

**Reflexion**: Wie hilft die MFT bei der Wiederherstellung gelöschter Dateien in NTFS, und warum ist die Offset-Angabe bei TSK wichtig?

### Übung 3: Analyse eines APFS-Dateisystems mit Autopsy
**Ziel**: Lernen, wie man ein APFS-Dateisystem mit TSK und Autopsy analysiert.

1. **Schritt 1**: Erstelle ein Disk-Image von APFS.
   ```bash
   cp test_apfs.dmg /media/forensic/apfs_image.dmg
   ```
2. **Schritt 2**: Analysiere Partitionen mit `mmls`.
   ```bash
   mmls /media/forensic/apfs_image.dmg
   ```
   Notiere die Offset-Werte für APFS-Container.
3. **Schritt 3**: Untersuche das Dateisystem mit `fsstat`.
   ```bash
   fsstat -o <offset> /media/forensic/apfs_image.dmg
   ```
   Die Ausgabe zeigt APFS-spezifische Details wie Container-ID.
4. **Schritt 4**: Liste Dateien mit `fls`.
   ```bash
   fls -o <offset> /media/forensic/apfs_image.dmg
   ```
   Die Ausgabe zeigt `test_apfs.txt`.
5. **Schritt 5**: Verwende Autopsy für eine GUI-Analyse.
   - Starte Autopsy:
     ```bash
     autopsy
     ```
   - Erstelle einen neuen Case: **Create New Case** > Name: `APFSCase` > Data Source: `/media/forensic/apfs_image.dmg`.
   - Wähle **Ingest Modules** > Aktiviere alle (z. B. File Type Identification).
   - Analysiere: **Views** > **File Systems** > Suche nach `test_apfs.txt`.
   - Exportiere: Rechtsklick auf Datei > **Extract File**.
6. **Schritt 6**: Simuliere Löschung und Wiederherstellung.
   - Lösche auf macOS (für Test):
     ```bash
     # Auf macOS:
     hdiutil attach test_apfs.dmg
     rm /Volumes/TestAPFS/test_apfs.txt
     hdiutil detach /Volumes/TestAPFS
     ```
   - Analysiere in Autopsy: **Views** > **Deleted Files** > Suche nach `test_apfs.txt`.
   - Exportiere gelöschte Datei.

**Reflexion**: Wie unterscheidet sich die APFS-Analyse von NTFS, und warum erleichtert Autopsy die Untersuchung komplexer Dateisysteme?

## Tipps für den Erfolg
- Verwenden Sie immer einen Write-Blocker (Hardware oder Software) für Original-Medien.
- Dokumentieren Sie jeden Schritt für die Chain of Custody (z. B. mit Zeitstempeln).
- Testen Sie Analysen mit bekannten NIST-Test-Images (https://www.cfreds.nist.gov).
- Überprüfen Sie Hash-Werte vor und nach der Analyse mit `md5sum` oder `sha256sum`.

## Fazit
In dieser Anleitung haben Sie die Grundlagen der forensischen Analyse von NTFS- und APFS-Dateisystemen mit The Sleuth Kit auf Debian erkundet. Durch die Übungen haben Sie praktische Erfahrung mit Disk-Images, Partitionserkennung, Datei-Extraktion und Autopsy gesammelt. Diese Fähigkeiten sind essenziell für forensische Untersuchungen moderner Dateisysteme. Üben Sie weiter, um fortgeschrittene Techniken wie Speicheranalyse oder Cloud-Forensik zu meistern!

**Nächste Schritte**:
- Erkunden Sie Speicher-Forensik mit Volatility für RAM-Analysen.
- Analysieren Sie andere Dateisysteme wie ext4 oder FAT32.
- Integrieren Sie TSK mit Tools wie Bulk Extractor für großvolumige Daten.

**Quellen**:
- The Sleuth Kit-Dokumentation: https://www.sleuthkit.org/sleuthkit/docs.html
- Autopsy-Dokumentation: https://www.autopsy.com/support/documentation/
- NIST Computer Forensics Reference Data Sets: https://www.cfreds.nist.gov/
- NTFS-Dokumentation: https://docs.microsoft.com/en-us/windows/win32/fileio/ntfs
- APFS-Dokumentation: https://developer.apple.com/documentation/apfs