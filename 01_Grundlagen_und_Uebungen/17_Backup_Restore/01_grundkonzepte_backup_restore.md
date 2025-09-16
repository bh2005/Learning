# Praxisorientierte Anleitung: Grundkonzepte Backup und Restore für Windows, Debian und macOS

## Einführung
Backup und Restore sind fundamentale Prozesse zur Datensicherung und -wiederherstellung, um Datenverluste durch Hardwareausfälle, Malware oder menschliche Fehler zu minimieren. Diese Anleitung gibt einen Überblick über die grundlegenden Konzepte und Tools für **Windows**, **Debian** (Linux) und **macOS**. Sie erklärt Strategien wie Full-, Incremental- und Differential-Backups sowie Restore-Optionen. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, effektive Backup-Strategien zu planen und umzusetzen. Diese Anleitung ist ideal für Administratoren und Nutzer, die ihre Systeme schützen möchten.

**Voraussetzungen:**
- Ein Windows-, Debian- oder macOS-System mit Administratorrechten
- Grundlegende Kenntnisse der Kommandozeile (CMD/PowerShell für Windows, Bash für Debian, Terminal für macOS)
- Externe Speichermedien (z. B. USB-Stick oder externe Festplatte) für Backups

## Grundlegende Backup- und Restore-Konzepte
Hier sind die wichtigsten Konzepte, die wir behandeln:

1. **Backup-Typen**:
   - **Full Backup**: Vollständige Kopie aller Daten (hoher Speicherbedarf, aber einfacher Restore).
   - **Incremental Backup**: Nur Änderungen seit dem letzten Backup (schnell, aber komplexer Restore).
   - **Differential Backup**: Änderungen seit dem letzten Full Backup (Balance zwischen Speicher und Restore-Zeit).
2. **Restore-Strategien**:
   - **Point-in-Time Recovery**: Wiederherstellung zu einem bestimmten Zeitpunkt.
   - **Bare-Metal Restore**: Vollständige Systemwiederherstellung.
3. **Tools und Best Practices**:
   - Automatisierung (z. B. Skripte oder Planer).
   - 3-2-1-Regel: 3 Kopien, 2 Medien, 1 offsite.

## Übungen zum Verinnerlichen

### Übung 1: Backup und Restore auf Windows
**Ziel**: Lernen, wie man Windows Backup und Restore mit integrierten Tools verwendet.

1. **Schritt 1**: Erstelle ein Systemimage mit dem Windows Backup-Tool.
   - Öffne **Einstellungen** > **Update & Sicherheit** > **Wiederherstellung** > **Erweiterte Startoptionen** > **Wiederherstellungsbild erstellen**.
   - Wähle ein externes Laufwerk als Ziel.
   - Folge dem Assistenten: Wähle Dateien, System und Anwendungen.
2. **Schritt 2**: Führe einen manuellen Datei-Backup durch.
   - Öffne **Datei-Explorer** > Rechtsklick auf Ordner > **Eigenschaften** > **Sicherungskonfiguration**.
   - Wähle Ordner zum Sichern und starte den Backup.
3. **Schritt 3**: Teste einen Restore.
   - Gehe zu **Wiederherstellung** > **Dateien wiederherstellen**.
   - Wähle ein Backup und extrahiere Dateien.
   - Für System-Restore: Starte im **Wiederherstellungsmodus** (F11 beim Booten) > **Problembehandlung** > **Erweiterte Optionen** > **Systemabbild wiederherstellen**.

**Reflexion**: Warum ist ein Systemimage für Bare-Metal-Restore nützlich, und wie unterscheidet sich es von Datei-Backups?

### Übung 2: Backup und Restore auf Debian (Linux)
**Ziel**: Verstehen, wie man rsync und Timeshift für Backups auf Debian verwendet.

1. **Schritt 1**: Installiere Tools.
   ```bash
   sudo apt update
   sudo apt install -y rsync timeshift
   ```
2. **Schritt 2**: Erstelle ein Incremental-Backup mit rsync.
   ```bash
   rsync -avh --delete /home/user/Documents/ /media/backup/backup-$(date +%Y%m%d)
   ```
   - `-a`: Archiv-Modus (rekursiv, Symlinks erhalten).
   - `-v`: Verbose-Ausgabe.
   - `--delete`: Löscht Dateien im Ziel, die im Quell fehlen.
3. **Schritt 3**: Konfiguriere Timeshift für System-Backups.
   - Starte `sudo timeshift-gtk`.
   - Wähle **RSYNC** als Typ, ein externes Laufwerk als Ziel.
   - Erstelle einen Snapshot: **Create**.
4. **Schritt 5**: Teste einen Restore.
   - Für rsync: `rsync -avh /media/backup/backup-20250916/ /home/user/Documents/`.
   - Für Timeshift: Booten Sie von einem Live-USB, wählen Sie den Snapshot und stellen Sie wieder her.

**Reflexion**: Warum ist rsync für Incremental-Backups effizient, und wie unterstützt Timeshift Bare-Metal-Restore?

### Übung 3: Backup und Restore auf macOS
**Ziel**: Lernen, wie man Time Machine und manuellen Backup mit rsync auf macOS verwendet.

1. **Schritt 1**: Konfiguriere Time Machine.
   - Gehe zu **Systemeinstellungen** > **Time Machine**.
   - Wähle ein externes Laufwerk als Backup-Disk.
   - Aktiviere **Backups automatisch sichern**.
2. **Schritt 2**: Erstelle ein manuelles Backup mit rsync (über Terminal).
   ```bash
   rsync -avh --delete /Users/user/Documents/ /Volumes/Backup/backup-$(date +%Y%m%d)
   ```
3. **Schritt 3**: Teste einen Restore.
   - Für Time Machine: **Time Machine** > Wähle Zeitpunkt > **Wiederherstellen**.
   - Für rsync: `rsync -avh /Volumes/Backup/backup-20250916/ /Users/user/Documents/`.

**Reflexion**: Wie vereinfacht Time Machine den Restore-Prozess im Vergleich zu manuellen Tools, und wann ist rsync vorzuziehen?

## Tipps für den Erfolg
- Folgen Sie der **3-2-1-Regel**: 3 Kopien der Daten, auf 2 verschiedenen Medien, 1 offsite (z. B. Cloud).
- Testen Sie Backups regelmäßig, um die Integrität zu überprüfen.
- Automatisieren Sie mit Cron-Jobs auf Debian/macOS oder Task Scheduler auf Windows.
- Verschlüsseln Sie Backups (z. B. mit LUKS auf Linux oder FileVault auf macOS).

## Fazit
In dieser Anleitung haben Sie die Grundkonzepte von Backup und Restore für Windows, Debian und macOS kennengelernt. Durch die Übungen haben Sie praktische Erfahrung mit Tools wie Windows Backup, rsync/Timeshift und Time Machine gesammelt. Diese Fähigkeiten sind essenziell für Datensicherung. Üben Sie weiter, um automatisierte Strategien oder Cloud-Backups zu implementieren!

**Nächste Schritte**:
- Erkunden Sie Cloud-Backups (z. B. AWS S3, Azure Backup).
- Integrieren Sie Backups in CI/CD-Pipelines mit Tools wie Jenkins.
- Lernen Sie fortgeschrittene Tools wie BorgBackup oder Duplicati.

**Quellen**:
- Microsoft Docs: https://docs.microsoft.com/en-us/windows/backup/
- Debian Wiki: https://wiki.debian.org/BackupAndRecovery
- Apple Support: https://support.apple.com/time-machine