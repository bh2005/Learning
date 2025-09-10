# Praxisorientierte Anleitung: PowerShell-Befehle für Windows zur Backup- und Wiederherstellung, Aufgabenplanung und Skriptautomatisierung

## Einführung
Die PowerShell bietet leistungsstarke Werkzeuge für Backup- und Wiederherstellungsaufgaben, geplante Aufgaben und Skriptautomatisierung unter Windows. Diese Anleitung orientiert sich an den angegebenen Linux-Befehlen und zeigt deren Äquivalente in PowerShell. Die Schwerpunkte sind **Backup und Wiederherstellung**, **Aufgabenplanung** sowie **Skriptautomatisierung**. Durch praktische Übungen lernst du, PowerShell-Cmdlets anzuwenden, um Dateien zu sichern, Aufgaben zu planen und automatisierte Workflows zu erstellen.

Voraussetzungen:
- Ein Windows-System (z. B. Windows 10 oder 11).
- PowerShell (vorinstalliert, starte mit `powershell` oder `pwsh` für PowerShell Core).
- Administratorrechte für bestimmte Aktionen (z. B. Volume-Backups, Aufgabenplanung).
- Grundlegendes Verständnis von Dateisystemen, Backups und Skripting.
- Sichere Testumgebung (z. B. Testverzeichnis oder externes Laufwerk), um Befehle risikofrei auszuprobieren.
- Optional: `robocopy` oder Drittanbieter-Tools wie 7-Zip für erweiterte Backup-Funktionen.

## Grundlegende Befehle
Hier sind die wichtigsten PowerShell-Befehle, die den Linux-Pendants entsprechen, aufgeteilt nach den Schwerpunkten:

1. **Backup und Wiederherstellung**:
   - `robocopy` (ähnlich `rsync`): Synchronisiert Dateien und Verzeichnisse (inkrementelle Backups).
   - `Compress-Archive` (ähnlich `tar`): Archiviert und komprimiert Dateien in ZIP-Format.
   - `Copy-Item` mit `Backup-BitLockerKeyProtector` (ähnlich `dd`): Erstellt Kopien von Dateien oder sichert spezifische Daten.
   - `Export-Clixml` (ähnlich `cpio`): Speichert strukturierte Daten in XML-Format für Backups.
2. **Cron und Aufgabenplanung**:
   - `New-ScheduledTask` (ähnlich `crontab`): Erstellt geplante Aufgaben.
   - `Register-ScheduledTask` mit Trigger (ähnlich `at`): Plant einmalige oder wiederkehrende Aufgaben.
   - Kein direktes Äquivalent zu `anacron`, aber `Register-ScheduledTask` mit Wiederholungslogik für ähnliche Funktionalität.
3. **Skriptautomatisierung**:
   - PowerShell-Skripte (`.ps1`) (ähnlich `bash`): Ermöglicht die Erstellung und Ausführung von Skripten.
   - `Write-Output` oder `Write-Host` (ähnlich `echo`): Gibt Text oder Variablen aus.
   - `Set-ExecutionPolicy` (ähnlich `chmod +x`): Steuert die Ausführungsberechtigungen für Skripte.
   - `Test-Path` oder `if` (ähnlich `test`): Prüft Bedingungen wie Dateiexistenz.
4. **Sonstige nützliche Befehle**:
   - `Get-Help` (ähnlich `man`): Zeigt die Hilfeseite eines Befehls an.
   - `Start-Process -Verb RunAs` (ähnlich `sudo`): Führt Befehle mit Administratorrechten aus.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Backup und Wiederherstellung
**Ziel**: Lerne, wie du Dateien sicherst und wiederherstellst.

1. **Schritt 1**: Erstelle ein Testverzeichnis mit Dateien:
   ```powershell
   New-Item -ItemType Directory -Name test_backup
   "Testdaten" | Out-File test_backup\datei1.txt
   "Weitere Daten" | Out-File test_backup\datei2.txt
   Get-ChildItem test_backup
   ```
2. **Schritt 2**: Synchronisiere Dateien mit `robocopy` (inkrementelles Backup):
   ```powershell
   New-Item -ItemType Directory -Name backup_robocopy
   robocopy test_backup backup_robocopy /MIR
   Get-ChildItem backup_robocopy
   ```
   Hinweis: `/MIR` spiegelt Verzeichnisse (inkl. Löschen von Dateien, die im Quellverzeichnis nicht mehr existieren).
3. **Schritt 3**: Erstelle ein ZIP-Archiv (ähnlich `tar`):
   ```powershell
   Compress-Archive -Path test_backup\* -DestinationPath backup.zip
   Get-ChildItem backup.zip
   ```
4. **Schritt 4**: Entpacke das ZIP-Archiv zur Wiederherstellung:
   ```powershell
   New-Item -ItemType Directory -Name restored
   Expand-Archive -Path backup.zip -DestinationPath restored
   Get-ChildItem restored
   ```
5. **Schritt 5**: Erstelle ein Backup von Umgebungsvariablen (ähnlich `cpio`):
   ```powershell
   Get-ChildItem Env: | Export-Clixml env_backup.xml
   Get-Content env_backup.xml
   ```

**Reflexion**: Wie unterscheidet sich `robocopy` von `rsync`? Schaue in `robocopy /?` und überlege, wie du inkrementelle Backups optimieren könntest.

### Übung 2: Aufgabenplanung
**Ziel**: Lerne, wie du Aufgaben für automatische Backups planst.

1. **Schritt 1**: Erstelle ein Backup-Skript:
   ```powershell
   New-Item -ItemType File -Name backup_script.ps1
   @"
   \$source = "\$HOME\test_backup"
   \$destination = "\$HOME\backup_robocopy"
   \$logFile = "\$HOME\backup_log.txt"
   if (Test-Path \$source) {
       robocopy \$source \$destination /MIR
       "Backup durchgeführt: \$(Get-Date)" | Out-File -FilePath \$logFile -Append
   } else {
       "Quellverzeichnis nicht gefunden: \$(Get-Date)" | Out-File -FilePath \$logFile -Append
   }
   "@ | Out-File backup_script.ps1
   ```
   Teste das Skript:
   ```powershell
   .\backup_script.ps1
   Get-Content $HOME\backup_log.txt
   ```
2. **Schritt 2**: Plane das Skript stündlich mit dem Task Scheduler:
   ```powershell
   $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File $HOME\backup_script.ps1"
   $trigger = New-ScheduledTaskTrigger -Daily -At "12:00 AM" -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 1)
   Register-ScheduledTask -TaskName "AutoBackup" -Action $action -Trigger $trigger -Description "Automatisches Backup"
   ```
3. **Schritt 3**: Plane eine einmalige Aufgabe (ähnlich `at`):
   ```powershell
   $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File $HOME\backup_script.ps1"
   $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5)
   Register-ScheduledTask -TaskName "OnceBackup" -Action $action -Trigger $trigger -Description "Einmaliges Backup"
   ```

**Reflexion**: Wie unterscheidet sich der Task Scheduler von `crontab`? Schaue in `Get-Help Register-ScheduledTask` und überlege, wie du Aufgaben für verpasste Ausführungen konfigurieren könntest.

### Übung 3: Skriptautomatisierung
**Ziel**: Lerne, wie du Skripte für Backup und Überwachung automatisierst.

1. **Schritt 1**: Setze die Ausführungsrichtlinie für Skripte (falls nicht gesetzt):
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
   Get-ExecutionPolicy
   ```
2. **Schritt 2**: Erstelle ein Skript mit Bedingungen zur Überwachung des Backup-Verzeichnisses:
   ```powershell
   New-Item -ItemType File -Name monitor_backup.ps1
   @"
   \$backupDir = "\$HOME\backup_robocopy"
   \$logFile = "\$HOME\monitor_log.txt"
   if (Test-Path \$backupDir) {
       \$fileCount = (Get-ChildItem \$backupDir | Measure-Object).Count
       Write-Output "Backup-Verzeichnis enthält \$fileCount Dateien: \$(Get-Date)" | Out-File -FilePath \$logFile -Append
   } else {
       Write-Output "Backup-Verzeichnis nicht gefunden: \$(Get-Date)" | Out-File -FilePath \$logFile -Append
   }
   "@ | Out-File monitor_backup.ps1
   ```
   Führe es aus:
   ```powershell
   .\monitor_backup.ps1
   Get-Content $HOME\monitor_log.txt
   ```
3. **Schritt 3**: Plane das Skript täglich:
   ```powershell
   $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File $HOME\monitor_backup.ps1"
   $trigger = New-ScheduledTaskTrigger -Daily -At "8:00 AM"
   Register-ScheduledTask -TaskName "MonitorBackup" -Action $action -Trigger $trigger -Description "Überwachung des Backup-Verzeichnisses"
   ```

**Reflexion**: Wie unterscheiden sich PowerShell-Skripte von Bash-Skripten? Schaue in `Get-Help about_Scripts` und überlege, wie du Skripte mit Fehlerbehandlung erweitern könntest.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Skripting und Backup-Techniken zu verinnerlichen.
- **Experimentiere sicher**: Nutze Testverzeichnisse und -laufwerke, um Datenverlust zu vermeiden.
- **Fehler sind normal**: Lies Fehlermeldungen und nutze `Get-Help` oder Online-Ressourcen.
- **Vorsicht bei `robocopy /MIR`**: Diese Option löscht Dateien im Ziel, die im Quellverzeichnis fehlen.
- **Logs überprüfen**: Nutze Logdateien (z. B. `backup_log.txt`) zur Fehlersuche.
- **Skripte modular gestalten**: Verwende Funktionen, Parameter und Bedingungen für flexible Automatisierung.

## Fazit
Durch diese Übungen hast du PowerShell-Befehle für Backup, Wiederherstellung, Aufgabenplanung und Skriptautomatisierung angewendet. Wiederhole die Übungen und experimentiere mit erweiterten Cmdlets (z. B. `Backup-BitLockerKeyProtector` für BitLocker-Backups oder `Start-Job` für parallele Aufgaben), um deine Fähigkeiten zu vertiefen.