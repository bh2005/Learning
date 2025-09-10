# Praxisorientierte Anleitung: Einstieg in PowerShell-Skripting und Textverarbeitung unter Windows

## Einführung
PowerShell ist ein leistungsstarkes Werkzeug für Skripting und Textverarbeitung unter Windows, das Bash-Skripting unter Linux entspricht. Diese Anleitung zeigt PowerShell-Äquivalente zu den angegebenen Linux-Befehlen und konzentriert sich auf **PowerShell-Skripting**, **Textverarbeitung** und **Nutzung eines Texteditors** (Notepad oder optional nano). Durch praktische Übungen lernst du, Skripte zu erstellen, Textdaten zu manipulieren und grundlegende Automatisierungsaufgaben durchzuführen.

Voraussetzungen:
- Ein Windows-System (z. B. Windows 10 oder 11).
- PowerShell (vorinstalliert, starte mit `powershell` oder `pwsh` für PowerShell Core).
- Grundlegendes Verständnis von Skripting und Textverarbeitung.
- Sichere Testumgebung (z. B. Testverzeichnis), um Befehle und Skripte risikofrei auszuprobieren.
- Optional: Chocolatey und `nano` für eine Linux-ähnliche Editor-Erfahrung.
- Administratorrechte für bestimmte Aktionen (z. B. `Set-ExecutionPolicy`).

## Grundlegende Befehle
Hier sind die wichtigsten PowerShell-Befehle, die den Linux-Pendants entsprechen, aufgeteilt nach den Schwerpunkten:

1. **PowerShell-Skripting**:
   - PowerShell-Skripte (`.ps1`) (ähnlich `bash`): Ermöglicht die Erstellung und Ausführung von Skripten.
   - `Set-ExecutionPolicy` (ähnlich `chmod +x`): Steuert die Ausführungsberechtigungen für Skripte.
   - `Write-Output` oder `Write-Host` (ähnlich `echo`): Gibt Text oder Variablen aus.
   - `Test-Path`, `if` (ähnlich `test`): Prüft Bedingungen wie Dateiexistenz oder Vergleiche.
2. **Textverarbeitung**:
   - `Select-String` und `ForEach-Object` (ähnlich `sed`): Sucht und ersetzt Text in Dateien oder Streams.
   - `ConvertFrom-Csv`/`Group-Object` (ähnlich `awk`): Verarbeitet und analysiert strukturierte Textdaten.
   - `Select-Object -Property` (ähnlich `cut`): Extrahiert Abschnitte aus Textzeilen.
   - `Sort-Object` (ähnlich `sort`): Sortiert Zeilen in Textdaten.
   - `Get-Unique` (ähnlich `uniq`): Entfernt oder zählt doppelte Einträge.
3. **Umgang mit einem Texteditor**:
   - `notepad` (ähnlich `nano`): Standard-Windows-Texteditor für einfache Bearbeitungen.
   - `nano` (optional, ähnlich `nano`): Linux-ähnlicher Editor, installierbar via Chocolatey.
4. **Sonstige nützliche Befehle**:
   - `Get-Help` (ähnlich `man`): Zeigt die Hilfeseite eines Befehls an.
   - `Start-Process -Verb RunAs` (ähnlich `sudo`): Führt Befehle mit Administratorrechten aus.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: PowerShell-Skripting
**Ziel**: Lerne, wie du einfache Skripte erstellst, ausführst und Bedingungen prüfst.

1. **Schritt 1**: Setze die Ausführungsrichtlinie für Skripte (benötigt Admin-Rechte):
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
   Get-ExecutionPolicy
   ```
2. **Schritt 2**: Erstelle ein einfaches Skript zur Ausgabe von Text und Variablen:
   ```powershell
   New-Item -ItemType File -Name hello.ps1
   @"
   \$user = \$Env:USERNAME
   Write-Output "Hallo \$user, es ist \$(Get-Date)"
   "@ | Out-File hello.ps1
   ```
   Führe es aus:
   ```powershell
   .\hello.ps1
   ```
3. **Schritt 3**: Erstelle ein Skript mit Bedingungsprüfung:
   ```powershell
   New-Item -ItemType File -Name check_file.ps1
   @"
   \$file = "\$HOME\test.txt"
   if (Test-Path \$file) {
       Write-Output "Datei \$file existiert."
   } else {
       Write-Output "Datei \$file existiert nicht."
       New-Item -ItemType File -Name test.txt
   }
   "@ | Out-File check_file.ps1
   ```
   Führe es aus und überprüfe:
   ```powershell
   .\check_file.ps1
   Get-ChildItem test.txt
   ```

**Reflexion**: Wie unterscheidet sich `Test-Path` von `test`? Schaue in `Get-Help Test-Path` und überlege, wie du komplexere Bedingungen (z. B. Vergleiche) einbauen könntest.

### Übung 2: Textverarbeitung
**Ziel**: Lerne, wie du Textdaten manipulierst und analysierst.

1. **Schritt 1**: Erstelle eine Testdatei mit Beispieldaten:
   ```powershell
   @"
   Name,Alter,Stadt
   Anna,25,Berlin
   Ben,30,Hamburg
   Anna,25,Berlin
   Clara,28,München
   "@ | Out-File daten.csv
   Get-Content daten.csv
   ```
2. **Schritt 2**: Suche und ersetze Text (ähnlich `sed`):
   ```powershell
   (Get-Content daten.csv) -replace "Berlin", "Köln" | Out-File daten_ersetzung.csv
   Get-Content daten_ersetzung.csv
   ```
3. **Schritt 3**: Analysiere strukturierte Daten (ähnlich `awk`):
   ```powershell
   Import-Csv daten.csv | Group-Object Stadt | Select-Object Name, Count
   ```
4. **Schritt 4**: Extrahiere eine Spalte (ähnlich `cut`):
   ```powershell
   Import-Csv daten.csv | Select-Object -Property Name | Out-File namen.txt
   Get-Content namen.txt
   ```
5. **Schritt 5**: Sortiere und entferne Duplikate:
   ```powershell
   Import-Csv daten.csv | Sort-Object Name | Get-Unique -AsString | Out-File sortiert.txt
   Get-Content sortiert.txt
   ```

**Reflexion**: Wie unterscheidet sich `ConvertFrom-Csv` von `awk`? Schaue in `Get-Help ConvertFrom-Csv` und überlege, wie du komplexere Datenanalysen (z. B. mit Filtern) durchführen könntest.

### Übung 3: Umgang mit einem Texteditor und Skriptautomatisierung
**Ziel**: Lerne, wie du Dateien mit Notepad oder nano bearbeitest und Skripte automatisierst.

1. **Schritt 1**: Bearbeite die Testdatei mit Notepad:
   ```powershell
   notepad daten.csv
   ```
   Füge eine neue Zeile hinzu (z. B. `David,35,Frankfurt`) und speichere.
2. **Schritt 2**: (Optional) Installiere `nano` über Chocolatey:
   ```powershell
   choco install nano -y
   nano daten.csv
   ```
   In nano: Nutze `Ctrl+O` zum Speichern, `Ctrl+X` zum Beenden, `Ctrl+\` zum Suchen/Ersetzen (z. B. `Köln` durch `Berlin`).
   Überprüfe:
   ```powershell
   Get-Content daten.csv
   ```
3. **Schritt 3**: Erstelle ein automatisiertes Skript zur Textverarbeitung:
   ```powershell
   New-Item -ItemType File -Name auto_process.ps1
   @"
   \$sourceFile = "\$HOME\daten.csv"
   \$outputFile = "\$HOME\verarbeitete_daten.csv"
   \$logFile = "\$HOME\process_log.txt"
   if (Test-Path \$sourceFile) {
       Import-Csv \$sourceFile | Sort-Object Alter -Descending | Export-Csv \$outputFile -NoTypeInformation
       "Daten verarbeitet: \$(Get-Date)" | Out-File -FilePath \$logFile -Append
   } else {
       "Quelle nicht gefunden: \$(Get-Date)" | Out-File -FilePath \$logFile -Append
   }
   "@ | Out-File auto_process.ps1
   ```
   Führe es aus:
   ```powershell
   .\auto_process.ps1
   Get-Content $HOME\verarbeitete_daten.csv
   Get-Content $HOME\process_log.txt
   ```
4. **Schritt 4**: Plane das Skript mit dem Task Scheduler (stündlich):
   ```powershell
   $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File $HOME\auto_process.ps1"
   $trigger = New-ScheduledTaskTrigger -Daily -At "12:00 AM" -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 1)
   Register-ScheduledTask -TaskName "AutoTextProcess" -Action $action -Trigger $trigger -Description "Automatische Textverarbeitung"
   ```

**Reflexion**: Wie unterscheidet sich `notepad` von `nano` in der Bedienung? Schaue in `Get-Help Start-Process` und überlege, wie du andere Editoren (z. B. VS Code) in Skripte integrieren könntest.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Skripting und Textverarbeitung zu verinnerlichen.
- **Experimentiere sicher**: Nutze Testdateien, um Datenverlust zu vermeiden.
- **Fehler sind normal**: Lies Fehlermeldungen und nutze `Get-Help` oder Online-Ressourcen.
- **Vorsicht bei `Set-ExecutionPolicy`**: Verwende `RemoteSigned` nur für vertrauenswürdige Skripte.
- **Logs überprüfen**: Nutze Logdateien (z. B. `process_log.txt`) zur Fehlersuche.
- **Skripte modular gestalten**: Verwende Funktionen, Parameter und Bedingungen für flexible Automatisierung.

## Fazit
Durch diese Übungen hast du PowerShell-Skripting, Textverarbeitung und die Nutzung eines Texteditors erlernt. Wiederhole die Übungen und experimentiere mit erweiterten Cmdlets (z. B. `Select-String` für komplexe Textsuche oder `ConvertTo-Json` für Datenmanipulation), um deine Fähigkeiten zu vertiefen.