# Praxisorientierte Anleitung: Einstieg in Digitale Forensik mit The Sleuth Kit auf Debian

## Einführung
Digitale Forensik befasst sich mit der Untersuchung digitaler Geräte und Daten, um Beweise für kriminelle Aktivitäten zu sammeln, ohne diese zu verändern. **The Sleuth Kit (TSK)** ist ein Open-Source-Toolkit für forensische Analysen von Festplatten, Dateisystemen und Dateien. Es ermöglicht die Erstellung von Disk-Images, Dateisystem-Analysen und die Erholung gelöschter Daten. Diese Anleitung führt Sie in die Installation und grundlegende Nutzung von TSK auf einem Debian-System ein und zeigt, wie Sie eine forensische Untersuchung durchführen. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, erste forensische Analysen mit TSK durchzuführen. Diese Anleitung ist ideal für IT-Sicherheitsexperten, Ermittler und Lernende, die in die Digitale Forensik einsteigen möchten.

**Voraussetzungen:**
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Grundlegende Kenntnisse der Linux-Kommandozeile
- Ein Test-Datenträger (z. B. USB-Stick oder VM-Disk-Image) für forensische Übungen
- Ein Texteditor (z. B. `nano`, `vim`)
- Optional: Autopsy (GUI für TSK) für visuelle Analysen

## Grundlegende Digitale Forensik- und TSK-Konzepte
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **Digitale Forensik-Konzepte**:
   - **Write Blocker**: Verhindert Schreibzugriffe auf das Original-Medium.
   - **Disk Image**: Bit-für-Bit-Kopie des Originals für Analysen.
   - **Hash-Werte**: MD5/SHA-256 zur Integritätsprüfung.
   - **Chain of Custody**: Dokumentation der Beweiskette.
2. **TSK-Tools**:
   - `mmls`: Listet Partitionen auf.
   - `fls`: Listet Dateien in einem Dateisystem.
   - `icat`: Extrahiert Dateien.
   - `dd`: Erstellt Disk-Images.
3. **Wichtige Befehle**:
   - `the_sleuthkit`: TSK-Toolkit-Installation.
   - `md5sum`: Berechnet Hash-Werte.

## Übungen zum Verinnerlichen

### Übung 1: The Sleuth Kit installieren und konfigurieren
**Ziel**: Lernen, wie man TSK auf einem Debian-System installiert und die grundlegenden Tools testet.

1. **Schritt 1**: Installiere TSK und Abhängigkeiten.
   ```bash
   sudo apt update
   sudo apt install -y sleuthkit autopsy
   ```
2. **Schritt 2**: Überprüfe die Installation.
   ```bash
   mmls -V
   fls -V
   ```
   Die Ausgabe sollte die TSK-Version anzeigen (z. B. 4.12.0).
3. **Schritt 3**: Erstelle ein Test-Medium (z. B. USB-Stick).
   - Stecke einen USB-Stick ein und notiere die Geräte-ID (z. B. `/dev/sdb`):
     ```bash
     lsblk
     ```
   - **Warnung**: Verwende nur ein Test-Medium, um Datenverlust zu vermeiden!
   - Erstelle eine Partition und Dateisystem:
     ```bash
     sudo fdisk /dev/sdb
     # Erstelle eine Partition (n), Schreib (w)
     sudo mkfs.ext4 /dev/sdb1
     sudo mkdir /mnt/test
     sudo mount /dev/sdb1 /mnt/test
     echo "Testdatei" > /mnt/test/test.txt
     sudo umount /mnt/test
     ```
4. **Schritt 4**: Berechne den Hash des Mediums für Integritätsprüfung.
   ```bash
   sudo dd if=/dev/sdb of=image.hash bs=1M status=progress
   md5sum /dev/sdb > original_hash.txt
   ```
   Speichere den Hash für spätere Vergleiche.

**Reflexion**: Warum ist die Hash-Prüfung essenziell in der Digitalen Forensik, und wie verhindert TSK die Veränderung des Originals?

### Übung 2: Disk-Image erstellen und analysieren
**Ziel**: Verstehen, wie man ein forensisches Disk-Image erstellt und mit TSK analysiert.

1. **Schritt 1**: Erstelle ein Disk-Image mit `dd`.
   ```bash
   sudo dd if=/dev/sdb of=/media/forensic/image.dd bs=4M status=progress
   ```
   - `if`: Input-File (Original-Medium).
   - `of`: Output-File (Image).
   - `bs=4M`: Block-Size für Geschwindigkeit.
2. **Schritt 2**: Analysiere das Image mit `mmls`.
   ```bash
   mmls /media/forensic/image.dd
   ```
   Die Ausgabe zeigt Partitionen (z. B. FAT32 oder ext4).
3. **Schritt 3**: Liste Dateien mit `fls`.
   ```bash
   fls -r -d /media/forensic/image.dd 1  # Rekursiv, gelöschte Dateien ausgeschlossen, Partition 1
   ```
   Die Ausgabe listet Dateien und Verzeichnisse.
4. **Schritt 4**: Extrahiere eine Datei mit `icat`.
   ```bash
   icat /media/forensic/image.dd 123 > extracted_test.txt  # 123 ist die Inode-Nummer aus fls
   cat extracted_test.txt
   ```
   Die Ausgabe sollte `Testdatei` sein.
5. **Schritt 5**: Prüfe die Integrität des Images.
   ```bash
   md5sum /media/forensic/image.dd
   ```
   Vergleiche mit `original_hash.txt`.

**Reflexion**: Wie ermöglicht ein Disk-Image die sichere Analyse, und warum ist `dd` das Standard-Tool für forensische Images?

### Übung 3: Gelöschte Dateien wiederherstellen und Autopsy verwenden
**Ziel**: Lernen, wie man gelöschte Dateien mit TSK wiederherstellt und eine GUI-Analyse mit Autopsy durchführt.

1. **Schritt 1**: Lösche eine Datei und erstelle ein neues Image.
   - Mounte das Test-Medium:
     ```bash
     sudo mount /dev/sdb1 /mnt/test
     rm /mnt/test/test.txt
     sudo umount /mnt/test
     ```
   - Erstelle ein Image:
     ```bash
     sudo dd if=/dev/sdb of=/media/forensic/deleted_image.dd bs=4M status=progress
     ```
2. **Schritt 2**: Liste gelöschte Dateien mit `fls`.
   ```bash
   fls -r -d -D /media/forensic/deleted_image.dd 1  # -D: Zeige gelöschte Dateien
   ```
   Die Ausgabe zeigt gelöschte Dateien (z. B. `d/d 123 test.txt`).
3. **Schritt 3**: Stelle die gelöschte Datei wieder her.
   ```bash
   icat -r /media/forensic/deleted_image.dd 123 > recovered_test.txt  # -r: Raw-Recovery
   cat recovered_test.txt
   ```
   Die Ausgabe sollte `Testdatei` sein.
4. **Schritt 4**: Verwende Autopsy für eine GUI-Analyse.
   - Starte Autopsy:
     ```bash
     autopsy
     ```
   - Erstelle einen neuen Case: **Create New Case** > Name: `TestCase` > Data Source: `/media/forensic/deleted_image.dd`.
   - Analysiere: **Run Ingest Modules** > Wähle alle Module.
   - Überprüfe gelöschte Dateien: **Views** > **Deleted Files** > Suche nach `test.txt`.
   - Exportiere: Rechtsklick auf Datei > **Extract File**.

**Reflexion**: Wie hilft Autopsy bei der visuellen Analyse, und warum ist die Wiederherstellung gelöschter Dateien forensisch relevant?

## Tipps für den Erfolg
- Verwenden Sie immer Write Blocker (Hardware oder Software) für Original-Medien.
- Dokumentieren Sie jeden Schritt (Chain of Custody) für gerichtliche Gültigkeit.
- Testen Sie Tools mit bekannten Test-Daten (z. B. NIST-Images).
- Überwachen Sie Hash-Werte: `md5sum` oder `sha256sum` vor/nach Analysen.

## Fazit
In dieser Anleitung haben Sie die Grundlagen der Digitalen Forensik mit The Sleuth Kit auf Debian erkundet. Durch die Übungen haben Sie praktische Erfahrung mit Disk-Images, Dateisystem-Analysen, Datei-Extraktion und GUI-Tools wie Autopsy gesammelt. Diese Fähigkeiten sind essenziell für forensische Untersuchungen. Üben Sie weiter, um fortgeschrittene Tools wie Volatility oder Bulk Extractor zu meistern!

**Nächste Schritte**:
- Erkunden Sie Speicher-Forensik mit Volatility für RAM-Analysen.
- Integrieren Sie TSK mit Autopsy für komplexe Cases.
- Lernen Sie forensische Dateisysteme wie NTFS oder APFS.

**Quellen**:
- Offizielle Sleuth Kit-Dokumentation: https://www.sleuthkit.org/sleuthkit/docs.html
- Autopsy-Dokumentation: https://www.autopsy.com/support/documentation/
- NIST Computer Forensics Reference Data Sets: https://www.cfreds.nist.gov/