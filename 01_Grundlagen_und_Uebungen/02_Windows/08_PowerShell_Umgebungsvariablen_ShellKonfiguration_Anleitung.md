# Praxisorientierte Anleitung: PowerShell-Befehle für Windows zur Verwaltung von Umgebungsvariablen, Shell-Konfiguration, Aliases und Funktionen

## Einführung
Die PowerShell bietet leistungsstarke Werkzeuge zur Verwaltung von Umgebungsvariablen, zur Anpassung der Shell und zur Erstellung von Aliases und Funktionen unter Windows. Diese Anleitung orientiert sich an den angegebenen Linux-Befehlen und zeigt deren Äquivalente in PowerShell. Die Schwerpunkte sind **Umgebungsvariablen und Shell-Konfiguration**, **Aliases** sowie **PowerShell-Funktionen**. Durch praktische Übungen lernst du, PowerShell-Cmdlets anzuwenden, um Umgebungsvariablen zu verwalten, die Shell anzupassen und benutzerdefinierte Befehle zu erstellen.

Voraussetzungen:
- Ein Windows-System (z. B. Windows 10 oder 11).
- PowerShell (vorinstalliert, starte mit `powershell` oder `pwsh` für PowerShell Core).
- Grundlegendes Verständnis von Variablen, Shell-Konfigurationen und Skripting.
- Sichere Testumgebung (z. B. Testverzeichnis), um Änderungen risikofrei auszuprobieren.
- Optional: Administratorrechte für systemweite Umgebungsvariablen.

## Grundlegende Befehle
Hier sind die wichtigsten PowerShell-Befehle, die den Linux-Pendants entsprechen, aufgete制度

System: teilt nach den Schwerpunkten:

1. **Umgebungsvariablen und Shell-Konfiguration**:
   - `Get-ChildItem Env:` (ähnlich `env`): Zeigt alle Umgebungsvariablen an.
   - `$Env:Variablenname = "Wert"` (ähnlich `export`): Setzt oder exportiert Umgebungsvariablen für die aktuelle Sitzung.
   - `Get-Variable` (ähnlich `set`): Zeigt Shell-Variablen und deren Werte an.
   - `Remove-Item Env:Variablenname` (ähnlich `unset`): Entfernt eine Umgebungsvariable.
   - `. $PROFILE` (ähnlich `source` oder `.`): Lädt die PowerShell-Profilkonfiguration (z. B. `$PROFILE`).
   - `Write-Output $Env:Variablenname` oder `$Variablenname` (ähnlich `echo $PATH`): Gibt den Wert einer Variable aus.
   - `$PSPrompt` oder `function prompt` (ähnlich `PS1`): Anpassen des PowerShell-Prompts im Profil.
2. **Aliases und Shell-Funktionen**:
   - `Get-Alias` oder `New-Alias` (ähnlich `alias`): Erstellt oder zeigt Aliases.
   - `Remove-Alias` (ähnlich `unalias`): Entfernt Aliases.
   - `function Funktionsname` (ähnlich `function`): Definiert PowerShell-Funktionen im Profil oder in Skripten.
3. **Sonstige nützliche Befehle**:
   - `Get-Help` (ähnlich `man`): Zeigt die Hilfeseite eines Befehls an.
   - `Start-Process -Verb RunAs` (ähnlich `sudo`): Führt Befehle mit Administratorrechten aus.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Umgebungsvariablen und Shell-Konfiguration
**Ziel**: Lerne, wie du Umgebungsvariablen verwaltest und die PowerShell anpasst.

1. **Schritt 1**: Zeige alle Umgebungsvariablen:
   ```powershell
   Get-ChildItem Env:
   ```
   Filtere nach einer bestimmten Variable (z. B. PATH):
   ```powershell
   $Env:PATH
   ```
2. **Schritt 2**: Erstelle eine neue Umgebungsvariable für die aktuelle Sitzung:
   ```powershell
   $Env:MY_VAR = "TestWert"
   Write-Output $Env:MY_VAR
   ```
3. **Schritt 3**: Entferne die Umgebungsvariable:
   ```powershell
   Remove-Item Env:MY_VAR
   Get-ChildItem Env:MY_VAR -ErrorAction SilentlyContinue
   ```
4. **Schritt 4**: Erstelle oder bearbeite das PowerShell-Profil:
   ```powershell
   if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force }
   notepad $PROFILE
   ```
   Füge eine einfache Anpassung hinzu, z. B.:
   ```powershell
   $Env:MY_PERM_VAR = "PermanenterWert"
   ```
   Lade das Profil:
   ```powershell
   . $PROFILE
   Write-Output $Env:MY_PERM_VAR
   ```
5. **Schritt 5**: Passe den PowerShell-Prompt an, indem du das Profil bearbeitest:
   ```powershell
   notepad $PROFILE
   ```
   Füge hinzu:
   ```powershell
   function prompt {
       "PS [$Env:USERNAME@$(Get-Date -Format 'HH:mm')] > "
   }
   ```
   Lade das Profil neu:
   ```powershell
   . $PROFILE
   ```
   Der Prompt zeigt nun Benutzername und Uhrzeit an.

**Reflexion**: Wie unterscheiden sich temporäre und permanente Umgebungsvariablen? Schaue in `Get-Help about_Environment_Variables` und überlege, wann systemweite Variablen sinnvoll sind.

### Übung 2: Aliases
**Ziel**: Lerne, wie du Aliases erstellst und verwaltest.

1. **Schritt 1**: Zeige alle vorhandenen Aliases:
   ```powershell
   Get-Alias
   ```
2. **Schritt 2**: Erstelle einen Alias für `Get-ChildItem`:
   ```powershell
   New-Alias -Name dir -Value Get-ChildItem
   dir
   ```
3. **Schritt 3**: Mache den Alias dauerhaft im Profil:
   ```powershell
   notepad $PROFILE
   ```
   Füge hinzu:
   ```powershell
   New-Alias -Name dir -Value Get-ChildItem
   ```
   Lade das Profil:
   ```powershell
   . $PROFILE
   dir
   ```
4. **Schritt 4**: Entferne den Alias:
   ```powershell
   Remove-Alias -Name dir
   Get-Alias -Name dir -ErrorAction SilentlyContinue
   ```

**Reflexion**: Warum sind Aliases nützlich? Schaue in `Get-Help New-Alias` und überlege, wie Aliases für häufig genutzte Befehle Zeit sparen können.

### Übung 3: PowerShell-Funktionen und Automatisierung
**Ziel**: Lerne, wie du Funktionen definierst und automatisierte Aufgaben erstellst.

1. **Schritt 1**: Erstelle eine einfache Funktion im Profil:
   ```powershell
   notepad $PROFILE
   ```
   Füge hinzu:
   ```powershell
   function Show-Info {
       Write-Output "System: $Env:COMPUTERNAME"
       Write-Output "User: $Env:USERNAME"
       Write-Output "Time: $(Get-Date)"
   }
   ```
   Lade das Profil:
   ```powershell
   . $PROFILE
   Show-Info
   ```
2. **Schritt 2**: Erstelle ein Skript mit einer Funktion zur Protokollierung von Umgebungsvariablen:
   ```powershell
   New-Item -ItemType File -Name log_vars.ps1
   @"
   function Log-Variables {
       param (
           [string]$LogFile = "$HOME\vars_log.txt"
       )
       \$date = Get-Date
       "Umgebungsvariablen von \$date" | Out-File -FilePath \$LogFile -Append
       Get-ChildItem Env: | Select-Object Name, Value | Out-File -FilePath \$LogFile -Append
   }
   Log-Variables
   "@ | Out-File log_vars.ps1
   ```
   Führe es aus:
   ```powershell
   .\log_vars.ps1
   Get-Content $HOME\vars_log.txt
   ```
3. **Schritt 3**: Plane das Skript mit dem Task Scheduler (stündlich):
   ```powershell
   $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File $HOME\log_vars.ps1"
   $trigger = New-ScheduledTaskTrigger -Daily -At "12:00 AM" -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 1)
   Register-ScheduledTask -TaskName "LogVariables" -Action $action -Trigger $trigger -Description "Protokollierung von Umgebungsvariablen"
   ```

**Reflexion**: Wie unterscheiden sich PowerShell-Funktionen von Bash-Funktionen? Schaue in `Get-Help about_Functions` und überlege, wie du Parameter oder Bedingungen in Funktionen einbauen könntest.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um die Cmdlets und Skripting zu verinnerlichen.
- **Experimentiere sicher**: Nutze Testskripte und temporäre Variablen, um Fehler zu vermeiden.
- **Fehler sind normal**: Lies Fehlermeldungen und nutze `Get-Help` oder Online-Ressourcen.
- **Vorsicht bei `Set-ExecutionPolicy`**: Verwende `RemoteSigned` nur für vertrauenswürdige Skripte.
- **Logs überprüfen**: Nutze Logdateien (z. B. `vars_log.txt`) zur Fehlersuche.
- **Skripte modular gestalten**: Verwende Funktionen, Parameter und Bedingungen für flexible Automatisierung.

## Fazit
Durch diese Übungen hast du PowerShell-Befehle für die Verwaltung von Umgebungsvariablen, Shell-Konfiguration, Aliases und Funktionen angewendet. Wiederhole die Übungen und experimentiere mit erweiterten Konzepten (z. B. `about_Profiles` für komplexe Shell-Anpassungen oder `Add-Member` für Objektmanipulation), um deine Fähigkeiten zu vertiefen.