# Praxisorientierte Anleitung: PowerShell-Befehle für Windows zur Festplattenprüfung, Dateisystemverwaltung, Dienste, Paketverwaltung und Systemüberwachung

## Einführung
Die PowerShell ist ein leistungsstarkes Werkzeug unter Windows für die Verwaltung von Festplatten, Dateisystemen, Diensten und Systemressourcen. Diese Anleitung orientiert sich an den angegebenen Linux-Befehlen und zeigt deren Äquivalente in PowerShell. Die Schwerpunkte sind **Festplattenprüfung**, **Dateisystemverwaltung**, **Dienste und Systemverwaltung**, **Paketverwaltung** sowie **Prozess- und Systemüberwachung**. Durch praktische Übungen lernst du, PowerShell-Cmdlets anzuwenden, um ein Windows-System effizient zu verwalten und zu überwachen.

Voraussetzungen:
- Ein Windows-System (z. B. Windows 10 oder 11).
- PowerShell (vorinstalliert, starte mit `powershell` oder `pwsh` für PowerShell Core).
- Administratorrechte für einige Befehle (z. B. Festplattenprüfung, Dienste).
- Grundlegendes Verständnis von Dateisystemen, Prozessen und PowerShell-Befehlen.
- Sichere Testumgebung (z. B. Testverzeichnis oder VM), um Befehle risikofrei auszuprobieren.
- Optional: Chocolatey für Paketverwaltung (ähnlich `apt`).

## Grundlegende Befehle
Hier sind die wichtigsten PowerShell-Befehle, die den Linux-Pendants entsprechen, aufgeteilt nach den Schwerpunkten:

1. **Festplattenprüfung**:
   - `Get-Disk` (ähnlich `df`): Zeigt Festplatteninformationen an.
   - `Get-ChildItem | Measure-Object` (ähnlich `du`): Ermittelt die Größe von Dateien/Verzeichnissen.
   - `Repair-Volume` (ähnlich `fsck`): Prüft und repariert Dateisysteme.
2. **Dateisystemverwaltung**:
   - `Get-Volume` (ähnlich `lsblk`): Listet Laufwerke und Partitionen auf.
   - `Mount-DiskImage` (ähnlich `mount`): Bindet ISO-Dateien oder virtuelle Laufwerke ein.
   - `Dismount-DiskImage` (ähnlich `umount`): Bindet Laufwerke aus.
   - `New-Partition`/`Format-Volume` (ähnlich `mkfs`): Formatiert ein Dateisystem.
3. **Dienste und Systemverwaltung**:
   - `Get-Service`/`Start-Service`/`Stop-Service` (ähnlich `systemctl`): Verwaltet Dienste.
   - `Get-Process` (ähnlich `ps`): Zeigt laufende Prozesse an.
   - `Get-Counter` (ähnlich `top`): Zeigt Systemressourcen in Echtzeit an.
   - `Get-EventLog` (ähnlich `journalctl`): Zeigt System- und Anwendungslogs.
4. **Paketverwaltung (mit Chocolatey, ähnlich `apt`)**:
   - `choco upgrade chocolatey` (ähnlich `apt update`): Aktualisiert Paketlisten.
   - `choco upgrade all` (ähnlich `apt upgrade`): Aktualisiert installierte Pakete.
   - `choco install` (ähnlich `apt install`): Installiert neue Pakete.
   - `choco uninstall` (ähnlich `apt remove`): Entfernt Pakete.
5. **Prozessverwaltung**:
   - `Stop-Process` (ähnlich `kill`/`killall`): Beendet Prozesse nach PID oder Name.
   - `Start-Process -Priority` (ähnlich `nice`): Startet Prozesse mit Priorität.
   - `Set-ProcessPriority` (ähnlich `renice`): Ändert die Priorität eines Prozesses.
   - `Start-Job` (ähnlich `bg`): Führt Aufgaben im Hintergrund aus.
   - `Get-Job`/`Receive-Job` (ähnlich `fg`): Holt Hintergrundprozesse in den Vordergrund.
6. **Systemüberwachung und Leistungsanalyse**:
   - `Get-Process | Sort-Object CPU` (ähnlich `htop`): Zeigt Prozesse nach CPU-Nutzung.
   - `Get-CimInstance Win32_OperatingSystem` (ähnlich `free`): Zeigt Speicherverbrauch.
   - `Get-Counter -Counter "\Processor(_Total)\% Processor Time"` (ähnlich `vmstat`): Zeigt CPU-Statistiken.
   - `Get-Counter -Counter "\PhysicalDisk(_Total)\% Disk Time"` (ähnlich `iostat`): Zeigt Festplatten-I/O.
   - `Get-Uptime` (ähnlich `uptime`): Zeigt Systemlaufzeit und Last.
7. **Sonstige nützliche Befehle**:
   - `Get-Help` (ähnlich `man`): Zeigt die Hilfeseite eines Befehls an.
   - `Start-Process -Verb RunAs` (ähnlich `sudo`): Führt Befehle mit Administratorrechten aus.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Festplattenprüfung und Dateisystemverwaltung
**Ziel**: Lerne, Festplatten zu prüfen und Dateisysteme zu verwalten.

1. **Schritt 1**: Zeige Festplatteninformationen und Speicherplatz:
   ```powershell
   Get-Disk
   Get-Volume
   ```
2. **Schritt 2**: Ermittle die Größe eines Verzeichnisses (z. B. `C:\Users`):
   ```powershell
   Get-ChildItem C:\Users -Recurse | Measure-Object -Property Length -Sum
   ```
   Hinweis: Die Größe wird in Bytes angezeigt; teile durch `1MB` für Megabyte:
   ```powershell
   (Get-ChildItem C:\Users -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
   ```
3. **Schritt 3**: Prüfe ein Dateisystem (z. B. Laufwerk D:, benötigt Admin-Rechte):
   ```powershell
   Repair-Volume -DriveLetter D -Scan
   ```
   Führe eine Reparatur durch, falls Fehler gefunden werden:
   ```powershell
   Repair-Volume -DriveLetter D -OfflineScanAndFix
   ```
4. **Schritt 4**: Liste alle Blockgeräte (ähnlich Partitionen):
   ```powershell
   Get-Partition
   ```
5. **Schritt 5**: Formatiere eine Testpartition (Vorsicht: nur auf Testlaufwerken!):
   ```powershell
   # Beispiel für ein USB-Laufwerk (z. B. E:)
   New-Partition -DriveLetter E -UseMaximumSize
   Format-Volume -DriveLetter E -FileSystem NTFS -Confirm:$false
   ```

**Reflexion**: Wie unterscheidet sich `Repair-Volume` von `fsck`? Schaue in `Get-Help Repair-Volume` und überlege, warum NTFS in Windows häufig ist.

### Übung 2: Dienste und Paketverwaltung
**Ziel**: Lerne, Dienste zu verwalten und Pakete mit Chocolatey zu installieren.

1. **Schritt 1**: Liste alle laufenden Dienste:
   ```powershell
   Get-Service | Where-Object { $_.Status -eq "Running" }
   ```
2. **Schritt 2**: Starte und stoppe einen Dienst (z. B. Windows Update):
   ```powershell
   Stop-Service -Name wuauserv
   Get-Service -Name wuauserv
   Start-Service -Name wuauserv
   ```
3. **Schritt 3**: Installiere Chocolatey (falls nicht vorhanden):
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
   ```
   Überprüfe:
   ```powershell
   choco --version
   ```
4. **Schritt 4**: Aktualisiere Paketlisten und installiere ein Paket (z. B. 7-Zip):
   ```powershell
   choco upgrade chocolatey
   choco install 7zip -y
   ```
   Überprüfe die Installation:
   ```powershell
   choco list --local-only
   ```
5. **Schritt 5**: Deinstalliere ein Paket:
   ```powershell
   choco uninstall 7zip -y
   ```

**Reflexion**: Warum ist Chocolatey ein Äquivalent zu `apt`? Schaue in `Get-Help Get-Service` und überlege, wie Dienste automatisiert überwacht werden können.

### Übung 3: Prozess- und Systemüberwachung mit Automatisierung
**Ziel**: Lerne, Prozesse zu überwachen und Aufgaben zu automatisieren.

1. **Schritt 1**: Zeige laufende Prozesse, sortiert nach CPU-Nutzung:
   ```powershell
   Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
   ```
2. **Schritt 2**: Beende einen Prozess (z. B. Notepad):
   ```powershell
   Start-Process notepad
   Stop-Process -Name notepad
   ```
3. **Schritt 3**: Überwache Speicherverbrauch:
   ```powershell
   Get-CimInstance Win32_OperatingSystem | Select-Object TotalVisibleMemorySize, FreePhysicalMemory
   ```
4. **Schritt 4**: Erstelle ein Skript zur automatischen Systemüberwachung:
   ```powershell
   New-Item -ItemType File -Name monitor.ps1
   @"
   \$logFile = "\$HOME\system_log.txt"
   Get-Date | Out-File -FilePath \$logFile -Append
   Get-CimInstance Win32_OperatingSystem | Select-Object FreePhysicalMemory | Out-File -FilePath \$logFile -Append
   Get-Process | Sort-Object CPU -Descending | Select-Object -First 3 | Out-File -FilePath \$logFile -Append
   "@ | Out-File monitor.ps1
   ```
   Führe es aus:
   ```powershell
   .\monitor.ps1
   Get-Content $HOME\system_log.txt
   ```
5. **Schritt 5**: Plane das Skript mit dem Task Scheduler (stündlich):
   ```powershell
   $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File $HOME\monitor.ps1"
   $trigger = New-ScheduledTaskTrigger -Daily -At "12:00 AM" -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 1)
   Register-ScheduledTask -TaskName "SystemMonitor" -Action $action -Trigger $trigger -Description "Systemüberwachung"
   ```

**Reflexion**: Wie unterscheidet sich `Get-Counter` von `htop`? Schaue in `Get-Help Get-Counter` und überlege, wie du Alarme für hohe CPU-Nutzung einrichten könntest.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um die Cmdlets zu verinnerlichen.
- **Experimentiere sicher**: Nutze Testlaufwerke und Verzeichnisse, um Datenverlust zu vermeiden.
- **Fehler sind normal**: Lies Fehlermeldungen und nutze `Get-Help` oder Online-Ressourcen.
- **Vorsicht bei Admin-Befehlen**: Änderungen an Diensten oder Dateisystemen können das System beeinflussen.
- **Logs überprüfen**: Nutze `Get-EventLog` oder Skript-Logs (z. B. `system_log.txt`) zur Fehlersuche.
- **Skripte modular gestalten**: Verwende Variablen und Bedingungen für flexible Automatisierung.

## Fazit
Durch diese Übungen hast du PowerShell-Befehle für Festplattenprüfung, Dateisystemverwaltung, Dienste, Paketverwaltung und Systemüberwachung angewendet. Wiederhole die Übungen und experimentiere mit erweiterten Cmdlets (z. B. `Invoke-ScriptAnalyzer` für Skriptoptimierung oder `Get-WmiObject` für tiefere Systemdaten), um deine Fähigkeiten zu vertiefen.