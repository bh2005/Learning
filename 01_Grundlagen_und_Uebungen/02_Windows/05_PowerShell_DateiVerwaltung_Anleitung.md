# Praxisorientierte Anleitung: PowerShell-Befehle für Windows zur Datei- und Verzeichnisverwaltung, Ein-/Ausgabeumleitungen und Textmanipulation

## Einführung
Die PowerShell ist ein vielseitiges Werkzeug unter Windows für die Verwaltung von Dateien und Verzeichnissen, das Umleiten von Ein- und Ausgaben sowie die Manipulation von Textdaten. Diese Anleitung orientiert sich an den angegebenen Linux-Befehlen und zeigt deren Äquivalente in PowerShell. Die Schwerpunkte sind **Datei- und Verzeichnisverwaltung**, **Ein-/Ausgabeumleitungen und Pipelines** sowie **Textanzeige und -manipulation**. Durch praktische Übungen lernst du, PowerShell-Cmdlets anzuwenden, um Dateien effizient zu verwalten, Datenströme umzuleiten und Text zu bearbeiten.

Voraussetzungen:
- Ein Windows-System (z. B. Windows 10 oder 11).
- PowerShell (vorinstalliert, starte mit `powershell` oder `pwsh` für PowerShell Core).
- Grundlegendes Verständnis von Dateisystemen und Kommandozeilen.
- Sichere Testumgebung (z. B. Testverzeichnis), um Befehle risikofrei auszuprobieren.

## Grundlegende Befehle
Hier sind die wichtigsten PowerShell-Befehle, die den Linux-Pendants entsprechen, aufgeteilt nach den Schwerpunkten:

1. **Datei- und Verzeichnisverwaltung**:
   - `Get-ChildItem` (ähnlich `ls`): Listet den Inhalt eines Verzeichnisses auf.
   - `Set-Location` (ähnlich `cd`): Wechselt das aktuelle Verzeichnis.
   - `New-Item -ItemType Directory` (ähnlich `mkdir`): Erstellt ein neues Verzeichnis.
   - `Remove-Item` (ähnlich `rm`): Entfernt Dateien oder Verzeichnisse.
   - `Copy-Item` (ähnlich `cp`): Kopiert Dateien oder Verzeichnisse.
   - `Move-Item` (ähnlich `mv`): Verschiebt oder benennt Dateien/Verzeichnisse.
   - `New-Item -ItemType File` (ähnlich `touch`): Erstellt leere Dateien oder aktualisiert Zeitstempel.
   - `Get-ChildItem -Recurse` (ähnlich `find`): Sucht Dateien und Verzeichnisse.
   - `New-Item -ItemType SymbolicLink` (ähnlich `ln`): Erstellt symbolische Links.
2. **Ein-/Ausgabeumleitungen und Pipelines**:
   - `Out-File` oder `>` (ähnlich `>`): Leitet Ausgabe in eine Datei um (überschreibt).
   - `Out-File -Append` oder `>>` (ähnlich `>>`): Hängt Ausgabe an eine Datei an.
   - `Get-Content` mit `ForEach-Object` (ähnlich `<`): Liest Eingabe aus einer Datei.
   - `|` (ähnlich `|`): Leitet Ausgabe eines Befehls als Eingabe an einen anderen weiter.
   - `Tee-Object` (ähnlich `tee`): Leitet Ausgabe in eine Datei und zeigt sie gleichzeitig an.
3. **Grundlegende Textanzeige und -manipulation**:
   - `Get-Content` (ähnlich `cat`): Zeigt den Inhalt einer Datei an oder verkettet Dateien.
   - `Get-Content | more` (ähnlich `less`/`more`): Zeigt Dateien seitenweise an.
   - `Get-Content -Head` (ähnlich `head`): Zeigt die ersten Zeilen einer Datei.
   - `Get-Content -Tail` (ähnlich `tail`): Zeigt die letzten Zeilen einer Datei.
   - `Measure-Object` (ähnlich `wc`): Zählt Zeilen, Wörter und Zeichen in Dateien.
4. **Sonstige nützliche Befehle**:
   - `Get-Help` (ähnlich `man`): Zeigt die Hilfeseite eines Befehls an.
   - `Start-Process -Verb RunAs` (ähnlich `sudo`): Führt Befehle mit Administratorrechten aus.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Datei- und Verzeichnisverwaltung
**Ziel**: Lerne, wie du Verzeichnisse und Dateien erstellst, verwaltest und suchst.

1. **Schritt 1**: Liste den Inhalt des aktuellen Verzeichnisses auf:
   ```powershell
   Get-ChildItem
   ```
   Nutze den Alias `ls`:
   ```powershell
   ls
   ```
2. **Schritt 2**: Erstelle ein Verzeichnis und wechsle hinein:
   ```powershell
   New-Item -ItemType Directory -Name test_verzeichnis
   Set-Location test_verzeichnis
   Get-Location
   ```
3. **Schritt 3**: Erstelle eine leere Datei und überprüfe:
   ```powershell
   New-Item -ItemType File -Name test.txt
   ls
   ```
4. **Schritt 4**: Kopiere und benenne die Datei um:
   ```powershell
   Copy-Item test.txt test_kopie.txt
   Move-Item test_kopie.txt test_umbenannt.txt
   ls
   ```
5. **Schritt 5**: Suche rekursiv nach Dateien mit der Endung `.txt`:
   ```powershell
   Get-ChildItem -Recurse -Include *.txt
   ```
6. **Schritt 6**: Erstelle einen symbolischen Link und lösche das Verzeichnis:
   ```powershell
   New-Item -ItemType SymbolicLink -Name test_link.txt -Target test_umbenannt.txt
   ls
   Set-Location ..
   Remove-Item test_verzeichnis -Recurse
   ls
   ```

**Reflexion**: Wie unterscheidet sich `Get-ChildItem` von `ls` in Linux? Schaue in `Get-Help Get-ChildItem` und überlege, warum symbolische Links in Windows eingeschränkt sein könnten.

### Übung 2: Ein-/Ausgabeumleitungen und Pipelines
**Ziel**: Lerne, wie du Datenströme umleitest und kombinierst.

1. **Schritt 1**: Erstelle eine Datei und leite Textausgabe hinein:
   ```powershell
   "Hallo PowerShell" | Out-File ausgabe.txt
   Get-Content ausgabe.txt
   ```
2. **Schritt 2**: Hänge Text an die Datei an:
   ```powershell
   "Zweite Zeile" >> ausgabe.txt
   Get-Content ausgabe.txt
   ```
3. **Schritt 3**: Nutze eine Pipeline, um Dateien zu filtern:
   ```powershell
   Get-ChildItem | Where-Object { $_.Extension -eq ".txt" } | Out-File txt_dateien.txt
   Get-Content txt_dateien.txt
   ```
4. **Schritt 4**: Verwende `Tee-Object` zur gleichzeitigen Ausgabe und Speicherung:
   ```powershell
   Get-ChildItem | Tee-Object -FilePath liste.txt
   Get-Content liste.txt
   ```
5. **Schritt 5**: Lese Eingabe aus einer Datei und verarbeite sie:
   ```powershell
   Get-Content ausgabe.txt | ForEach-Object { $_ + " - Verarbeitet" } | Out-File verarbeitet.txt
   Get-Content verarbeitet.txt
   ```

**Reflexion**: Wie unterscheidet sich die PowerShell-Pipeline von Linux-Pipes? Schaue in `Get-Help about_Pipelines` und überlege, wie du komplexe Pipelines erstellen könntest.

### Übung 3: Textanzeige und -manipulation mit Automatisierung
**Ziel**: Lerne, wie du Text anzeigst, manipulierst und Aufgaben automatisierst.

1. **Schritt 1**: Zeige den Inhalt einer Datei:
   ```powershell
   Get-Content ausgabe.txt
   ```
2. **Schritt 2**: Zeige die ersten und letzten Zeilen:
   ```powershell
   Get-Content ausgabe.txt -Head 1
   Get-Content ausgabe.txt -Tail 1
   ```
3. **Schritt 3**: Zähle Zeilen, Wörter und Zeichen:
   ```powershell
   Get-Content ausgabe.txt | Measure-Object -Line -Word -Character
   ```
4. **Schritt 4**: Zeige Inhalt seitenweise:
   ```powershell
   Get-Content ausgabe.txt | more
   ```
5. **Schritt 5**: Erstelle ein Skript zur automatischen Textmanipulation:
   ```powershell
   New-Item -ItemType File -Name text_manipulation.ps1
   @"
   \$sourceFile = "\$HOME\ausgabe.txt"
   \$logFile = "\$HOME\text_log.txt"
   if (Test-Path \$sourceFile) {
       Get-Content \$sourceFile | ForEach-Object { \$_.ToUpper() } | Out-File "\$HOME\ausgabe_obercase.txt"
       "Text verarbeitet: \$(Get-Date)" | Out-File -FilePath \$logFile -Append
   } else {
       "Quelle nicht gefunden: \$(Get-Date)" | Out-File -FilePath \$logFile -Append
   }
   "@ | Out-File text_manipulation.ps1
   ```
   Führe es aus:
   ```powershell
   .\text_manipulation.ps1
   Get-Content $HOME\ausgabe_obercase.txt
   Get-Content $HOME\text_log.txt
   ```
6. **Schritt 6**: Plane das Skript mit dem Task Scheduler (stündlich):
   ```powershell
   $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File $HOME\text_manipulation.ps1"
   $trigger = New-ScheduledTaskTrigger -Daily -At "12:00 AM" -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 1)
   Register-ScheduledTask -TaskName "TextManipulation" -Action $action -Trigger $trigger -Description "Automatische Textmanipulation"
   ```

**Reflexion**: Wie unterscheidet sich `Measure-Object` von `wc`? Schaue in `Get-Help Measure-Object` und überlege, wie du Textmanipulation mit regulären Ausdrücken erweitern könntest.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um die Cmdlets zu verinnerlichen.
- **Experimentiere sicher**: Nutze Testverzeichnisse, um Datenverlust zu vermeiden.
- **Fehler sind normal**: Lies Fehlermeldungen und nutze `Get-Help` oder Online-Ressourcen.
- **Vorsicht bei `Remove-Item`**: Verwende `-Recurse` nur mit Bedacht.
- **Logs überprüfen**: Nutze Logdateien (z. B. `text_log.txt`) zur Fehlersuche.
- **Skripte modular gestalten**: Verwende Variablen und Bedingungen für flexible Automatisierung.

## Fazit
Durch diese Übungen hast du PowerShell-Befehle für Datei- und Verzeichnisverwaltung, Ein-/Ausgabeumleitungen und Textmanipulation angewendet. Wiederhole die Übungen und experimentiere mit erweiterten Cmdlets (z. B. `Select-String` für Textsuche oder `ConvertTo-Json` für Datenmanipulation), um deine Fähigkeiten zu vertiefen.