# Praxisorientierte Anleitung: PowerShell-Befehle für Windows zur Erfassung von Systeminformationen, Hardware-Diagnose und Systemüberwachung

## Einführung
Die PowerShell bietet leistungsstarke Werkzeuge zur Erfassung von System- und Hardwareinformationen sowie zur Diagnose und Überwachung unter Windows. Diese Anleitung orientiert sich an den angegebenen Linux-Befehlen und zeigt deren Äquivalente in PowerShell. Die Schwerpunkte sind **Systeminformationen und Hardware**, **Kernel- und Systemdiagnose** sowie **Systemüberwachung**. Durch praktische Übungen lernst du, PowerShell-Cmdlets anzuwenden, um detaillierte Informationen über dein System zu erhalten, Hardware zu analysieren und Systemereignisse zu überwachen.

Voraussetzungen:
- Ein Windows-System (z. B. Windows 10 oder 11).
- PowerShell (vorinstalliert, starte mit `powershell` oder `pwsh` für PowerShell Core).
- Administratorrechte für einige Befehle (z. B. detaillierte Hardwareinformationen).
- Grundlegendes Verständnis von Systemkomponenten (z. B. CPU, RAM, Festplatten).
- Sichere Testumgebung (z. B. Testverzeichnis oder VM), um Befehle risikofrei auszuprobieren.

## Grundlegende Befehle
Hier sind die wichtigsten PowerShell-Befehle, die den Linux-Pendants entsprechen, aufgeteilt nach den Schwerpunkten:

1. **Systeminformationen und Hardware**:
   - `Get-CimInstance Win32_Processor` (ähnlich `lscpu`): Zeigt CPU-Informationen an.
   - `Get-PnpDevice -Class USB` (ähnlich `lsusb`): Listet angeschlossene USB-Geräte auf.
   - `Get-CimInstance Win32_PnPEntity` (ähnlich `lspci`): Listet PCI-Geräte auf.
   - `Get-CimInstance Win32_BIOS`, `Win32_PhysicalMemory` (ähnlich `dmidecode`): Zeigt BIOS- und RAM-Details.
   - `Get-CimInstance Win32_OperatingSystem` (ähnlich `uname`): Zeigt Systeminformationen.
   - `Get-CimInstance Win32_OperatingSystem` (ähnlich `free`): Zeigt Speicherverbrauch.
   - `Get-Volume` (ähnlich `df`): Zeigt Festplattennutzung.
2. **Kernel- und Systemdiagnose**:
   - `Get-WinEvent -LogName System` (ähnlich `dmesg`): Zeigt System- und Kernel-Logs.
   - `Get-EventLog` oder `Get-WinEvent` (ähnlich `journalctl`): Zeigt System- und Dienstlogs.
   - `Get-Process | Sort-Object CPU` (ähnlich `top`): Zeigt Prozesse und Ressourcen.
   - `Get-Counter` (ähnlich `vmstat`): Zeigt Prozess-, Speicher- und CPU-Statistiken.
   - `Get-Partition` (ähnlich `lsblk`): Listet Blockgeräte und Partitionen.
3. **Sonstige nützliche Befehle**:
   - `Get-Help` (ähnlich `man`): Zeigt die Hilfeseite eines Befehls an.
   - `Start-Process -Verb RunAs` (ähnlich `sudo`): Führt Befehle mit Administratorrechten aus.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Systeminformationen und Hardware
**Ziel**: Lerne, wie du Informationen über CPU, USB, PCI, BIOS, RAM und Festplatten abrufst.

1. **Schritt 1**: Zeige CPU-Informationen:
   ```powershell
   Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, MaxClockSpeed
   ```
2. **Schritt 2**: Liste angeschlossene USB-Geräte auf:
   ```powershell
   Get-PnpDevice -Class USB | Select-Object Name, Status, DeviceID
   ```
3. **Schritt 3**: Zeige PCI-Geräte (z. B. Grafikkarten, Netzwerkkarten):
   ```powershell
   Get-CimInstance Win32_PnPEntity | Where-Object { $_.PNPClass -eq "Display" -or $_.PNPClass -eq "Net" } | Select-Object Name, DeviceID
   ```
4. **Schritt 4**: Zeige BIOS- und RAM-Details:
   ```powershell
   Get-CimInstance Win32_BIOS | Select-Object Manufacturer, Version, ReleaseDate
   Get-CimInstance Win32_PhysicalMemory | Select-Object Manufacturer, Capacity
   ```
5. **Schritt 5**: Zeige Systeminformationen und Speicherverbrauch:
   ```powershell
   Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, OSArchitecture, TotalVisibleMemorySize, FreePhysicalMemory
   ```
6. **Schritt 6**: Zeige Festplattennutzung:
   ```powershell
   Get-Volume | Select-Object DriveLetter, FileSystemLabel, Size, SizeRemaining
   ```

**Reflexion**: Wie unterscheidet sich `Get-CimInstance` von `dmidecode`? Schaue in `Get-Help Get-CimInstance` und überlege, wie du spezifische Hardwareinformationen filtern könntest.

### Übung 2: Kernel- und Systemdiagnose
**Ziel**: Lerne, wie du Systemlogs und Geräteinformationen analysierst.

1. **Schritt 1**: Zeige die neuesten Systemereignisse (ähnlich Kernel-Logs):
   ```powershell
   Get-WinEvent -LogName System -MaxEvents 5 | Select-Object TimeCreated, Message
   ```
2. **Schritt 2**: Zeige detaillierte Logs für einen bestimmten Dienst (z. B. Windows Update):
   ```powershell
   Get-EventLog -LogName System -Source "WindowsUpdateClient" -Newest 5
   ```
3. **Schritt 3**: Liste Blockgeräte und Partitionen:
   ```powershell
   Get-Partition | Select-Object DiskNumber, PartitionNumber, DriveLetter, Size
   ```
4. **Schritt 4**: Überwache CPU- und Speicherauslastung:
   ```powershell
   Get-Counter -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 2 -MaxSamples 3
   Get-Counter -Counter "\Memory\Available MBytes" -SampleInterval 2 -MaxSamples 3
   ```

**Reflexion**: Wie unterscheidet sich `Get-WinEvent` von `journalctl`? Schaue in `Get-Help Get-WinEvent` und überlege, wie du Ereignisse nach bestimmten Kriterien filtern könntest.

### Übung 3: Systemüberwachung mit Automatisierung
**Ziel**: Lerne, wie du Systemressourcen überwachst und Daten automatisch protokollierst.

1. **Schritt 1**: Zeige die Top-Prozesse nach CPU-Nutzung:
   ```powershell
   Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 | Select-Object Name, CPU, WorkingSet
   ```
2. **Schritt 2**: Erstelle ein Skript zur automatischen Erfassung von Systeminformationen:
   ```powershell
   New-Item -ItemType File -Name system_monitor.ps1
   @"
   \$logFile = "\$HOME\system_monitor_log.txt"
   \$date = Get-Date
   "Systeminfo von \$date" | Out-File -FilePath \$logFile -Append
   Get-CimInstance Win32_Processor | Select-Object Name, LoadPercentage | Out-File -FilePath \$logFile -Append
   Get-CimInstance Win32_OperatingSystem | Select-Object TotalVisibleMemorySize, FreePhysicalMemory | Out-File -FilePath \$logFile -Append
   Get-Volume | Select-Object DriveLetter, Size, SizeRemaining | Out-File -FilePath \$logFile -Append
   Get-Process | Sort-Object CPU -Descending | Select-Object -First 3 | Out-File -FilePath \$logFile -Append
   "@ | Out-File system_monitor.ps1
   ```
   Führe es aus:
   ```powershell
   .\system_monitor.ps1
   Get-Content $HOME\system_monitor_log.txt
   ```
3. **Schritt 3**: Plane das Skript mit dem Task Scheduler (stündlich):
   ```powershell
   $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File $HOME\system_monitor.ps1"
   $trigger = New-ScheduledTaskTrigger -Daily -At "12:00 AM" -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 1)
   Register-ScheduledTask -TaskName "SystemMonitor" -Action $action -Trigger $trigger -Description "Systemüberwachung"
   ```

**Reflexion**: Wie unterscheidet sich `Get-Counter` von `vmstat`? Schaue in `Get-Help Get-Counter` und überlege, wie du Alarme für hohe CPU-Auslastung einrichten könntest.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um die Cmdlets zu verinnerlichen.
- **Experimentiere sicher**: Nutze Testumgebungen, um Systemänderungen zu vermeiden.
- **Fehler sind normal**: Lies Fehlermeldungen und nutze `Get-Help` oder Online-Ressourcen.
- **Vorsicht bei Admin-Befehlen**: Einige Cmdlets wie `Get-CimInstance` benötigen erhöhte Rechte.
- **Logs überprüfen**: Nutze Logdateien (z. B. `system_monitor_log.txt`) oder `Get-WinEvent` zur Fehlersuche.
- **Skripte modular gestalten**: Verwende Variablen und Bedingungen für flexible Automatisierung.

## Fazit
Durch diese Übungen hast du PowerShell-Befehle für die Erfassung von Systeminformationen, Hardware-Diagnose und Systemüberwachung angewendet. Wiederhole die Übungen und experimentiere mit erweiterten Cmdlets (z. B. `Get-WmiObject` für tiefere Hardware-Daten oder `Invoke-CimMethod` für erweiterte Diagnosen), um deine Fähigkeiten zu vertiefen.