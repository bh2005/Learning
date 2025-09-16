# Praxisorientierte Anleitung: Integration von The Sleuth Kit mit Volatility für RAM-Analysen auf Debian

## Einführung
Die Integration von **The Sleuth Kit (TSK)** mit **Volatility** ermöglicht eine umfassende forensische Analyse, indem Dateisystem-Analysen (TSK) mit Speicher-Forensik (Volatility) kombiniert werden. TSK analysiert Festplatten und Dateisysteme (z. B. NTFS, ext4), während Volatility Speicherabbilder (RAM-Dumps) untersucht, um Prozesse, Netzwerkverbindungen und flüchtige Daten zu extrahieren. Diese Anleitung zeigt, wie man TSK und Volatility auf Debian integriert, um gelöschte Dateien von einem USB-Stick (ext4) und zugehörige RAM-Daten zu analysieren. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, kombinierte Festplatten- und Speicheranalysen durchzuführen. Diese Anleitung ist ideal für IT-Sicherheitsexperten, forensische Ermittler und Lernende, die fortgeschrittene forensische Techniken meistern möchten.

**Voraussetzungen:**
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Ein Test-USB-Stick mit ext4-Dateisystem und ein RAM-Dump (z. B. via `LiME`)
- Grundlegende Kenntnisse der Linux-Kommandozeile und digitaler Forensik
- The Sleuth Kit, Volatility 2 oder 3 und Autopsy installiert
- Mindestens 10 GB freier Speicher für Disk-Images und RAM-Dumps
- Optional: Hardware-Write-Blocker für physische Medien

## Grundlegende Konzepte der Integration
Hier sind die wichtigsten Konzepte und Tools, die wir behandeln:

1. **Forensische Konzepte**:
   - **Disk Image**: Bit-für-Bit-Kopie eines Speichermediums (TSK).
   - **RAM-Dump**: Schnappschuss des Arbeitsspeichers für flüchtige Daten (Volatility).
   - **Hash-Werte**: MD5/SHA-256 zur Integritätsprüfung.
   - **Chain of Custody**: Dokumentation aller Schritte für gerichtliche Gültigkeit.
2. **TSK-Tools**:
   - `mmls`: Listet Partitionen auf.
   - `fls`: Listet Dateien, inklusive gelöschter.
   - `icat`: Extrahiert Dateien basierend auf Inodes.
   - `tsk_recover`: Stellt gelöschte Dateien in ein Verzeichnis wieder her.
3. **Volatility**:
   - Analysiert RAM-Dumps, um Prozesse, Netzwerkverbindungen, Shell-Befehle und mehr zu extrahieren.
   - Unterstützt Profile für verschiedene Betriebssysteme (z. B. Linux, Windows).
   - Beispiele: `pslist` (Prozesse), `netscan` (Netzwerkverbindungen).
4. **Integrationsstrategie**:
   - Verwende TSK, um gelöschte Dateien oder Dateisystem-Metadaten zu extrahieren.
   - Nutze Volatility, um RAM-Daten zu analysieren, z. B. welche Prozesse mit Dateien interagierten.
   - Korreliere Ergebnisse, um ein vollständiges Bild der Aktivitäten zu erstellen.

## Übungen zum Verinnerlichen

### Übung 1: Vorbereitung und Installation der Tools
**Ziel**: Lernen, wie man TSK, Volatility und ein Test-Medium vorbereitet.

1. **Schritt 1**: Installiere The Sleuth Kit, Autopsy und Volatility.
   ```bash
   sudo apt update
   sudo apt install -y sleuthkit autopsy python3 python3-pip
   # Installiere Volatility 3 (kein Standard-Paket in Debian)
   pip3 install volatility3
   ```
2. **Schritt 2**: Überprüfe die Installation.
   ```bash
   mmls -V
   fls -V
   vol.py --version  # Für Volatility 3
   ```
   Die Ausgabe sollte die Versionen anzeigen (z. B. TSK 4.12.0, Volatility 3).
3. **Schritt 3**: Bereite ein Test-Medium (ext4) und einen RAM-Dump vor.
   - **USB-Stick (ext4)**:
     ```bash
     lsblk  # Ermittle Geräte-ID (z. B. /dev/sdb)
     sudo fdisk /dev/sdb
     # Erstelle Partition (n, p, 1), Typ ext4 (83), Schreib (w)
     sudo mkfs.ext4 /dev/sdb1
     sudo mkdir /mnt/test
     sudo mount /dev/sdb1 /mnt/test
     echo "Forensische Daten: user@example.com" > /mnt/test/evidence.txt
     sudo umount /mnt/test
     ```
   - **RAM-Dump** (mit LiME in einer Test-VM):
     ```bash
     # In einer Linux-VM:
     sudo apt install -y linux-headers-$(uname -r) build-essential
     git clone https://github.com/504ensicsLabs/LiME.git
     cd LiME/src
     make
     sudo insmod lime.ko "path=/tmp/memory.lime format=lime"
     # Kopiere /tmp/memory.lime nach Debian (z. B. via SCP)
     scp user@vm:/tmp/memory.lime /media/forensic/
     ```
   - **Warnung**: Verwende nur Test-Medien, um Datenverlust zu vermeiden!
4. **Schritt 4**: Berechne Hash-Werte.
   ```bash
   sudo md5sum /dev/sdb > /media/forensic/usb_hash.txt
   md5sum /media/forensic/memory.lime > /media/forensic/memory_hash.txt
   ```

**Reflexion**: Warum ist ein RAM-Dump für die forensische Analyse wichtig, und wie ergänzt er TSK?

### Übung 2: Wiederherstellung gelöschter Dateien mit TSK
**Ziel**: Verstehen, wie man gelöschte Dateien mit TSK extrahiert, um sie mit RAM-Daten zu korrelieren.

1. **Schritt 1**: Erstelle ein Disk-Image des USB-Sticks.
   ```bash
   sudo dd if=/dev/sdb of=/media/forensic/usb_image.dd bs=4M status=progress
   ```
2. **Schritt 2**: Analysiere Partitionen mit `mmls`.
   ```bash
   mmls /media/forensic/usb_image.dd
   ```
   Notiere den Offset der ext4-Partition (z. B. `2048` Sektoren).
3. **Schritt 3**: Liste Dateien mit `fls`.
   ```bash
   fls -o 2048 /media/forensic/usb_image.dd
   ```
   Die Ausgabe zeigt `evidence.txt` mit Inode (z. B. `12`).
4. **Schritt 4**: Simuliere Löschung und erstelle ein neues Image.
   ```bash
   sudo mount /dev/sdb1 /mnt/test
   rm /mnt/test/evidence.txt
   sudo umount /mnt/test
   sudo dd if=/dev/sdb of=/media/forensic/usb_deleted.dd bs=4M status=progress
   ```
5. **Schritt 5**: Identifiziere gelöschte Dateien.
   ```bash
   fls -o 2048 -d -D /media/forensic/usb_deleted.dd
   ```
   Suche nach `* evidence.txt` (gelöschte Dateien mit `*`).
6. **Schritt 6**: Stelle die Datei wieder her.
   ```bash
   icat -o 2048 -r /media/forensic/usb_deleted.dd 12 > /media/forensic/recovered_evidence.txt
   cat /media/forensic/recovered_evidence.txt
   ```
   Die Ausgabe sollte `Forensische Daten: user@example.com` sein.
7. **Schritt 7**: Prüfe die Integrität.
   ```bash
   md5sum /media/forensic/usb_deleted.dd
   ```
   Vergleiche mit `usb_hash.txt`.

**Reflexion**: Wie hilft TSK bei der Wiederherstellung gelöschter Dateien, und warum ist die Inode-Nummer entscheidend?

### Übung 3: RAM-Analyse mit Volatility und Korrelation mit TSK
**Ziel**: Lernen, wie man Volatility für RAM-Analysen nutzt und die Ergebnisse mit TSK-Daten korreliert.

1. **Schritt 1**: Identifiziere das Volatility-Profil.
   - Ermittle das Linux-Profil (z. B. für die Test-VM):
     ```bash
     vol.py -f /media/forensic/memory.lime linux_pslist
     ```
     Falls das Profil unbekannt ist, nutze:
     ```bash
     vol.py -f /media/forensic/memory.lime linux_info
     ```
     Typisches Profil: `LinuxUbuntu_x64` (anpassen nach Kernel-Version).
2. **Schritt 2**: Analysiere laufende Prozesse.
   ```bash
   vol.py -f /media/forensic/memory.lime --profile=LinuxUbuntu_x64 linux_pslist > /media/forensic/pslist.txt
   ```
   Suche nach Prozessen wie `nano` oder `vi`, die mit `evidence.txt` interagiert haben könnten.
3. **Schritt 3**: Extrahiere Netzwerkverbindungen.
   ```bash
   vol.py -f /media/forensic/memory.lime --profile=LinuxUbuntu_x64 linux_netstat > /media/forensic/netstat.txt
   ```
   Überprüfe Verbindungen, z. B. zu `example.com`.
4. **Schritt 4**: Korreliere TSK- und Volatility-Daten.
   - TSK liefert: Gelöschte Datei `evidence.txt` mit Inhalt `user@example.com`.
   - Volatility liefert: Prozesse (z. B. `nano`) und Netzwerkverbindungen (z. B. zu `example.com`).
   - Beispiel-Korrelation:
     ```bash
     echo "Korrelation am $(date): Gelöschte Datei evidence.txt (Inode 12) enthält user@example.com; Prozess nano (PID 1234) aktiv, Netzwerkverbindung zu example.com" >> /media/forensic/case_log.txt
     ```
5. **Schritt 5**: Analysiere mit Autopsy für visuelle Unterstützung.
   - Starte Autopsy:
     ```bash
     autopsy
     ```
     Öffne `http://localhost:9999/autopsy` im Browser.
   - Erstelle einen neuen Case: **Create New Case** > Name: `RAMCase` > Data Source: `/media/forensic/usb_deleted.dd`.
   - Füge RAM-Dump hinzu (manuell, da Autopsy RAM-Dumps nicht direkt unterstützt):
     - Exportiere Volatility-Ergebnisse (z. B. `pslist.txt`) und importiere sie in Autopsy als **Report**.
     - Analysiere: **Views** > **Deleted Files** > Suche nach `evidence.txt`.
     - Korreliere: Nutze **Keyword Search** für `user@example.com` und überprüfe Prozesse in importierten Berichten.
6. **Schritt 6**: Dokumentiere den Prozess (Chain of Custody).
   ```bash
   echo "Analyse am $(date): USB-Image usb_deleted.dd, RAM-Dump memory.lime, Extraktion von evidence.txt, Prozesse und Netzwerkverbindungen" >> /media/forensic/case_log.txt
   ```

**Reflexion**: Wie ergänzen sich TSK und Volatility, und warum ist die Korrelation von Festplatten- und RAM-Daten forensisch wertvoll?

## Tipps für den Erfolg
- Verwenden Sie einen Write-Blocker (Hardware oder Software, z. B. `hdparm --read-only`) für Original-Medien.
- Dokumentieren Sie jeden Schritt mit Zeitstempeln für die Chain of Custody.
- Verwenden Sie Volatility-Plugins wie `linux_bash` für Shell-Historie oder `linux_files` für offene Dateien.
- Testen Sie mit NIST-Test-Images (https://www.cfreds.nist.gov) für bekannte Ergebnisse.
- Optimieren Sie Volatility mit korrektem Profil für die Kernel-Version der VM.

## Fazit
In dieser Anleitung haben Sie die Integration von The Sleuth Kit mit Volatility für kombinierte Festplatten- und RAM-Analysen auf Debian erkundet. Durch die Übungen haben Sie praktische Erfahrung mit Disk-Images, Wiederherstellung gelöschter Dateien, RAM-Analysen und Datenkorrelation gesammelt. Diese Kombination ist essenziell für umfassende forensische Untersuchungen. Üben Sie weiter, um fortgeschrittene Plugins von Volatility oder andere Dateisysteme wie NTFS/APFS zu meistern!

**Nächste Schritte**:
- Erkunden Sie Volatility-Plugins wie `linux_yarascan` für Malware-Suche.
- Integrieren Sie TSK mit Bulk Extractor für massenhafte Datenextraktion.
- Analysieren Sie komplexe Szenarien mit mehreren RAM-Dumps.

**Quellen**:
- The Sleuth Kit-Dokumentation: https://www.sleuthkit.org/sleuthkit/docs.html
- Volatility 3-Dokumentation: https://github.com/volatilityfoundation/volatility3
- Autopsy-Dokumentation: https://www.autopsy.com/support/documentation/
- NIST Computer Forensics Reference Data Sets: https://www.cfreds.nist.gov/