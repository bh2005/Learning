# Praxisorientierte Anleitung: PowerShell-Befehle für Windows zur Textverarbeitung, Skripting und Nutzung eines Texteditors

## Einführung
Die PowerShell ist ein leistungsfähiges Werkzeug unter Windows für Textverarbeitung, Datenmanipulation und Skriptautomatisierung. Diese Anleitung orientiert sich an den angegebenen Linux-Befehlen und zeigt deren Äquivalente in PowerShell, einschließlich der Nutzung eines Texteditors wie Notepad für einfache Bearbeitungen. Die Schwerpunkte sind **Textverarbeitung**, **Skripting** und **Umgang mit einem Texteditor**. Durch praktische Übungen lernst du, PowerShell-Cmdlets und Skripte anzuwenden, um Texte zu transformieren, zu analysieren und Prozesse zu automatisieren.

Voraussetzungen:
- Ein Windows-System (z. B. Windows 10 oder 11).
- PowerShell (vorinstalliert, starte mit `powershell` oder `pwsh` für PowerShell Core).
- Grundlegendes Verständnis von Textverarbeitung und Skripting-Konzepten.
- Sichere Testumgebung (z. B. Testverzeichnis), um Befehle und Skripte risikofrei auszuprobieren.
- Optional: Installation von `nano` für Windows via Chocolatey für Linux-ähnliche Editor-Erfahrung.

## Grundlegende Befehle
Hier sind die wichtigsten PowerShell-Befehle und Tools, die den Linux-Pendants entsprechen, aufgeteilt nach den Schwerpunkten:

1. **Textverarbeitung**:
   - `Select-String` und `ForEach-Object` (ähnlich `sed`): Sucht und ersetzt Text in Dateien oder Streams.
   - `ConvertFrom-Csv`/`Group-Object` (ähnlich `awk`): Verarbeitet und analysiert strukturierte Textdaten.
   - `Select-Object -Property` (ähnlich `cut`): Extrahiert Abschnitte aus Textzeilen.
   - `Sort-Object` (ähnlich `sort`): Sortiert Zeilen in Textdaten.
   - `Get-Unique` (ähnlich `uniq`): Entfernt oder zählt doppelte Einträge.
2. **Skripting**:
   - PowerShell-Skripte (ähnlich `bash`): Ermöglicht die Erstellung und Ausführung von Skripten mit `.ps1`-Dateien.
   - `Set-ExecutionPolicy` (ähnlich `chmod +x`): Steuert die Ausführungsberechtigungen für Skripte.
3. **Umgang mit einem Texteditor**:
   - `notepad` (ähnlich `nano`): Standard-Windows-Texteditor für einfache Bearbeitungen.
   - `nano` (optional, ähnlich `nano`): Linux-ähnlicher Editor, installierbar via Chocolatey.
4. **Sonstige nützliche Befehle**:
   - `Get-Help` (ähnlich `man`): Zeigt die Hilfeseite eines Befehls an.
   - `Start-Process -Verb RunAs` (ähnlich `sudo`): Führt Befehle mit Administratorrechten aus.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Textverarbeitung
**Ziel**: Lerne, wie du Textdateien verarbeitest, manipulierst und analysierst.

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
5. **Schritt 5**: Sortiere die Daten und entferne Duplikate:
   ```powershell
   Import-Csv daten.csv | Sort-Object Name | Get-Unique -AsString | Out-File sortiert.txt
   Get-Content sortiert.txt
   ```

**Reflexion**: Wie unterscheidet sich `Select-String` von `sed`? Schaue in `Get-Help Select-String` und überlege, wie du komplexere Texttransformationen durchführen könntest.

### Übung 2: Skripting
**Ziel**: Lerne, wie du PowerShell-Skripte erstellst und ausführst.

1. **Schritt 1**: Setze die Ausführungsrichtlinie für Skripte (benötigt Admin-Rechte):
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
   Get-ExecutionPolicy
   ```
2. **Schritt 2**: Erstelle ein einfaches Skript zur Textverarbeitung:
   ```powershell
   New-Item -ItemType File -Name text_verarbeitung.ps1
   @"
   \$sourceFile = "\$HOME\daten.csv"
   \$outputFile = "\$HOME\verarbeitete_daten.csv"
   if (Test-Path \$sourceFile) {
       Import-Csv \$sourceFile | Sort-Object Alter -Descending | Export-Csv \$outputFile -NoTypeInformation
       "Daten verarbeitet: \$(Get-Date)" | Out-File -FilePath "\$HOME\text_verarbeitung_log.txt" -Append
   } else {
       "Quelle nicht gefunden: \$(Get-Date)" | Out-File -FilePath "\$HOME\text_verarbeitung_log.txt" -Append
   }
   "@ | Out-File text_verarbeitung.ps1
   ```
3. **Schritt 3**: Führe das Skript aus und überprüfe die Ergebnisse:
   ```powershell
   .\text_verarbeitung.ps1
   Get-Content $HOME\verarbeitete_daten.csv
   Get-Content $HOME\text_verarbeitung_log.txt
   ```
4. **Schritt 4**: Plane das Skript mit dem Task Scheduler (stündlich):
   ```powershell
   $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File $HOME\text_verarbeitung.ps1"
   $trigger = New-ScheduledTaskTrigger -Daily -At "12:00 AM" -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 1)
   Register-ScheduledTask -TaskName "TextVerarbeitung" -Action $action -Trigger $trigger -Description "Automatische Textverarbeitung"
   ```

**Reflexion**: Wie unterscheidet sich PowerShell-Skripting von `bash`? Schaue in `Get-Help about_Scripts` und überlege, wie du Bedingungen oder Schleifen in Skripten erweitern könntest.

### Übung 3: Umgang mit einem Texteditor
**Ziel**: Lerne, wie du Dateien mit Notepad oder nano (optional) bearbeitest.

1. **Schritt 1**: Bearbeite eine Datei mit Notepad:
   ```powershell
   notepad daten.csv
   ```
   Füge eine neue Zeile hinzu (z. B. `David,35,Frankfurt`) und speichere.
2. **Schritt 2**: (Optional) Installiere `nano` über Chocolatey für eine Linux-ähnliche Erfahrung:
   ```powershell
   choco install nano -y
   nano daten.csv
   ```
   In nano: Nutze `Ctrl+O` zum Speichern, `Ctrl+X` zum Beenden, `Ctrl+S` zum Suchen, `Alt+^` zum Kopieren, `Alt+6` zum Einfügen.
3. **Schritt 3**: Suche und ersetze in nano (falls installiert):
   - Öffne `daten.csv` in nano, drücke `Ctrl+\`, gib Suchbegriff `Köln` und Ersatz `Berlin` ein, bestätige mit `Enter`.
4 eggplant
   ```powershell
   Get-Content daten.csv
   ```
4. **Schritt 4**: Erstelle ein Skript, um Änderungen in einer Datei zu protokollieren:
   ```powershell
   New-Item -ItemType File -Name edit_log.ps1
   @"
   \$fileToEdit = "\$HOME\daten.csv"
   \$logFile = "\$HOME\edit_log.txt"
   notepad \$fileToEdit
   "Datei bearbeitet: \$(Get-Date)" | Out-File -FilePath \$logFile -Append
   Get-Content \$fileToEdit | Out-File -FilePath \$logFile -Append
   "@ | Out-File edit_log.ps1
   ```
   Führe es aus:
   ```powershell
   .\edit_log.ps1
   Get-Content $HOME\edit_log.txt
   ```

**Reflexion**: Wie unterscheidet sich `notepad` von `nano`? Schaue in `Get-Help Start-Process` und überlege, wie du andere Editoren (z. B. VS Code) integrieren könntest.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um die Cmdlets und Skripting zu verinnerlichen.
- **Experimentiere sicher**: Nutze Testdateien, um Datenverlust zu vermeiden.
- **Fehler sind normal**: Lies Fehlermeldungen und nutze `Get-Help` oder Online-Ressourcen.
- **Vorsicht bei Skriptausführung**: Stelle sicher, dass `Set-ExecutionPolicy` korrekt konfiguriert ist.
- **Logs überprüfen**: Nutze Logdateien (z. B. `text_verarbeitung_log.txt`) zur Fehlersuche.
- **Skripte modular gestalten**: Verwende Variablen, Bedingungen und Funktionen für flexible Automatisierung.

## Fazit
Durch diese Übungen hast du PowerShell-Befehle für Textverarbeitung, Skripting und die Nutzung eines Texteditors angewendet. Wiederhole die Übungen und experimentiere mit erweiterten Cmdlets (z. B. `ConvertFrom-Json` für JSON-Daten oder `Select-String` für komplexe Textsuche), um deine Fähigkeiten zu vertiefen.