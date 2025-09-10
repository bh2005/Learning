# Praxisorientierte Anleitung: Grundlegende Linux-Kommandozeilenbefehle für Backup und Wiederherstellung, Cron und Aufgabenplanung sowie Skriptautomatisierung

## Einführung
Die Linux-Kommandozeile bietet leistungsstarke Werkzeuge für die Datensicherung, geplante Aufgaben und die Automatisierung von Prozessen. Diese Anleitung konzentriert sich auf die Schwerpunkte **Backup und Wiederherstellung**, **Cron und Aufgabenplanung** sowie **Skriptautomatisierung**, um wiederkehrende Aufgaben effizient zu gestalten. Durch praktische Übungen lernst du, die wichtigsten Befehle direkt anzuwenden und zu verinnerlichen, um ein Linux-System sicher und automatisiert zu verwalten.

Voraussetzungen:
- Ein Linux-System (z. B. Ubuntu, Debian oder eine virtuelle Maschine).
- Ein Terminal (z. B. über `Ctrl + T` oder ein Terminal-Programm wie `bash`).
- Administratorrechte (`sudo`) für einige Befehle, insbesondere bei Backup und Cron-Konfiguration.
- Grundlegendes Verständnis von Dateien, Verzeichnissen und Shell-Befehlen.
- Sichere Testumgebung (z. B. virtuelle Maschine), um Backups ohne Risiko auszuprobieren.

## Grundlegende Befehle
Hier sind die wichtigsten Linux-Befehle, die wir in dieser Anleitung behandeln, aufgeteilt nach den Schwerpunkten:

1. **Backup und Wiederherstellung**:
   - `rsync`: Synchronisiert Dateien und Verzeichnisse (ideal für inkrementelle Backups).
   - `tar`: Archiviert und komprimiert Dateien.
   - `dd`: Erstellt exakte Kopien von Dateien oder Partitionen.
   - `cpio`: Erstellt und extrahiert Archive (alternative zu `tar`).
2. **Cron und Aufgabenplanung**:
   - `crontab`: Verwaltet geplante Aufgaben für Benutzer.
   - `at`: Plant einmalige Aufgaben zu einem bestimmten Zeitpunkt.
   - `anacron`: Führt geplante Aufgaben aus, auch wenn das System zeitweise ausgeschaltet war.
3. **Skriptautomatisierung**:
   - `bash`: Shell für die Erstellung und Ausführung von Skripten.
   - `echo`: Gibt Text oder Variablen aus (nützlich in Skripten).
   - `chmod +x`: Macht Skripte ausführbar.
   - `test`: Prüft Bedingungen in Shell-Skripten (z. B. Existenz von Dateien).
4. **Sonstige nützliche Befehle**:
   - `man`: Zeigt die Hilfeseite eines Befehls an.
   - `sudo`: Führt Befehle mit Administratorrechten aus.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Backup und Wiederherstellung
**Ziel**: Lerne, wie du Dateien sicherst und wiederherstellst.

1. **Schritt 1**: Erstelle ein Testverzeichnis mit einigen Dateien:
   ```bash
   mkdir test_backup
   echo "Daten 1" > test_backup/datei1.txt
   echo "Daten 2" > test_backup/datei2.txt
   ```
2. **Schritt 2**: Erstelle ein inkrementelles Backup von `test_backup` mit `rsync` in ein Verzeichnis `backup`:
   ```bash
   mkdir backup
   rsync -av test_backup/ backup/
   ```
   Die Optionen `-a` (Archivmodus) und `-v` (ausführlich) kopieren Verzeichnisse und zeigen den Fortschritt.
3. **Schritt 3**: Ändere eine Datei und aktualisiere das Backup:
   ```bash
   echo "Geänderte Daten" > test_backup/datei1.txt
   rsync -av test_backup/ backup/
   ```
   Überprüfe, ob nur geänderte Dateien kopiert wurden:
   ```bash
   ls -l backup
   ```
4. **Schritt 4**: Erstelle ein komprimiertes Tar-Archiv von `test_backup`:
   ```bash
   tar -czvf test_backup.tar.gz test_backup/
   ```
   Die Option `-z` komprimiert mit `gzip`. Überprüfe:
   ```bash
   ls
   ```
5. **Schritt 5**: Stelle das Archiv in ein neues Verzeichnis `restore` wieder her:
   ```bash
   mkdir restore
   tar -xzvf test_backup.tar.gz -C restore
   ```
   Überprüfe den Inhalt:
   ```bash
   ls restore/test_backup
   ```
6. **Schritt 6**: Erstelle eine exakte Kopie einer Datei mit `dd` (z. B. `datei1.txt`):
   ```bash
   dd if=test_backup/datei1.txt of=backup/datei1_kopie.txt
   ```
   Die Optionen `if` (input file) und `of` (output file) definieren Quelle und Ziel. Überprüfe:
   ```bash
   cat backup/datei1_kopie.txt
   ```

**Reflexion**: Was ist der Vorteil von `rsync` gegenüber `cp` für Backups? Schaue in `man rsync` und überlege, warum `dd` für Partitionen nützlich ist, aber Vorsicht erfordert.

### Übung 2: Cron und Aufgabenplanung
**Ziel**: Lerne, wie du Aufgaben planst, die regelmäßig oder einmalig ausgeführt werden.

1. **Schritt 1**: Öffne den Crontab-Editor für deinen Benutzer:
   ```bash
   crontab -e
   ```
   Füge eine Aufgabe hinzu, die jede Minute eine Nachricht in eine Logdatei schreibt (füge diese Zeile am Ende der Datei hinzu):
   ```bash
   * * * * * echo "Cron-Test: $(date)" >> ~/cron_log.txt
   ```
   Speichere und schließe den Editor. Warte eine Minute und überprüfe:
   ```bash
   cat ~/cron_log.txt
   ```
2. **Schritt 2**: Plane eine einmalige Aufgabe mit `at`, die in 5 Minuten eine Datei erstellt (benötigt `at`, falls nicht installiert: `sudo apt install at`):
   ```bash
   echo "touch ~/at_test.txt" | at now + 5 minutes
   ```
   Überprüfe nach 5 Minuten:
   ```bash
   ls ~
   ```
3. **Schritt 3**: Liste alle geplanten `at`-Aufgaben auf:
   ```bash
   atq
   ```
4. **Schritt 4**: Erstelle eine `anacron`-Aufgabe für tägliche Backups (benötigt `sudo` und `anacron`, falls nicht installiert: `sudo apt install anacron`):
   ```bash
   sudo mkdir -p /etc/cron.daily
   sudo nano /etc/cron.daily/backup_script
   ```
   Füge folgendes Skript hinzu:
   ```bash
   #!/bin/bash
   echo "Backup am $(date)" >> /var/log/backup.log
   ```
   Mache das Skript ausführbar:
   ```bash
   sudo chmod +x /etc/cron.daily/backup_script
   ```
   Überprüfe nach einiger Zeit (je nach Systemkonfiguration):
   ```bash
   sudo cat /var/log/backup.log
   ```
5. **Schritt 5**: Entferne die Crontab-Aufgabe aus Schritt 1:
   ```bash
   crontab -e
   ```
   Lösche die Zeile mit `cron_log.txt` und speichere.

**Reflexion**: Was ist der Unterschied zwischen `cron` und `anacron`? Schaue in `man crontab` und `man anacron` und überlege, wann du `at` verwenden würdest.

### Übung 3: Skriptautomatisierung
**Ziel**: Lerne, wie du einfache Shell-Skripte erstellst, um Backups und andere Aufgaben zu automatisieren.

1. **Schritt 1**: Erstelle ein einfaches Bash-Skript für ein Backup:
   ```bash
   nano backup_script.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash
   SOURCE_DIR="$HOME/test_backup"
   BACKUP_DIR="$HOME/backup"
   TIMESTAMP=$(date +%Y%m%d_%H%M%S)
   rsync -av $SOURCE_DIR/ $BACKUP_DIR/backup_$TIMESTAMP
   echo "Backup erstellt: $BACKUP_DIR/backup_$TIMESTAMP" >> ~/backup_log.txt
   ```
   Speichere und schließe die Datei.
2. **Schritt 2**: Mache das Skript ausführbar:
   ```bash
   chmod +x backup_script.sh
   ```
3. **Schritt 3**: Führe das Skript aus:
   ```bash
   ./backup_script.sh
   ```
   Überprüfe das Backup-Verzeichnis und das Log:
   ```bash
   ls backup
   cat ~/backup_log.txt
   ```
4. **Schritt 4**: Füge eine Bedingung hinzu, um zu prüfen, ob das Quellverzeichnis existiert. Bearbeite das Skript:
   ```bash
   nano backup_script.sh
   ```
   Ändere es wie folgt:
   ```bash
   #!/bin/bash
   SOURCE_DIR="$HOME/test_backup"
   BACKUP_DIR="$HOME/backup"
   TIMESTAMP=$(date +%Y%m%d_%H%M%S)
   if [ -d "$SOURCE_DIR" ]; then
       rsync -av $SOURCE_DIR/ $BACKUP_DIR/backup_$TIMESTAMP
       echo "Backup erstellt: $BACKUP_DIR/backup_$TIMESTAMP" >> ~/backup_log.txt
   else
       echo "Fehler: Quellverzeichnis $SOURCE_DIR existiert nicht" >> ~/backup_log.txt
   fi
   ```
   Speichere und schließe.
5. **Schritt 5**: Teste das Skript mit einem nicht existierenden Verzeichnis:
   ```bash
   mv test_backup test_backup_alt
   ./backup_script.sh
   cat ~/backup_log.txt
   ```
   Stelle das Verzeichnis wieder her:
   ```bash
   mv test_backup_alt test_backup
   ```
6. **Schritt 6**: Plane das Skript mit `crontab`, um täglich um 2 Uhr morgens zu laufen:
   ```bash
   crontab -e
   ```
   Füge hinzu:
   ```bash
   0 2 * * * /bin/bash $HOME/backup_script.sh
   ```
   Überprüfe die Crontab:
   ```bash
   crontab -l
   ```

**Reflexion**: Warum ist die Bedingung `[ -d "$SOURCE_DIR" ]` im Skript wichtig? Schaue in `man test` und überlege, wie du das Skript erweitern könntest (z. B. mit Komprimierung via `tar`).

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um die Befehle zu verinnerlichen.
- **Experimentiere sicher**: Verwende `man <befehl>`, um Optionen zu verstehen, bevor du sie ausprobierst. Teste Backup- und Cron-Aufgaben in einer sicheren Umgebung (z. B. virtuelle Maschine).
- **Fehler sind normal**: Lies Fehlermeldungen sorgfältig und nutze `man` oder Online-Ressourcen.
- **Vorsicht bei `sudo`**: Befehle wie `dd` oder `anacron` können das System verändern. Überprüfe immer, was du tust.
- **Logs überprüfen**: Nutze Logdateien (z. B. `backup_log.txt`) zur Fehlersuche bei automatisierten Aufgaben.
- **Skripte modular gestalten**: Schreibe Skripte mit Variablen und Bedingungen, um sie flexibel und wiederverwendbar zu machen.

## Fazit
Durch diese Übungen hast du grundlegende Linux-Kommandozeilenbefehle für Backup und Wiederherstellung, Cron und Aufgabenplanung sowie Skriptautomatisierung angewendet. Wiederhole die Übungen und experimentiere mit weiteren Optionen (z. B. `rsync --exclude` für selektive Backups, `crontab` mit Umgebungen oder `bash` mit Schleifen), um deine Fähigkeiten weiter zu verbessern.