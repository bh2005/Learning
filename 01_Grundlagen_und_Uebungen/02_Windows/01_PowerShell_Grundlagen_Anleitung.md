# Praxisorientierte Anleitung: Grundlegende PowerShell-Befehle für Windows zur Navigation, Datei- und Benutzerverwaltung, Suche und Automatisierung

## Einführung
Die PowerShell ist ein leistungsstarkes Werkzeug unter Windows für die Verwaltung von Dateien, Benutzern und Systemprozessen sowie für die Automatisierung von Aufgaben. Diese Anleitung orientiert sich an den grundlegenden Linux-Befehlen und zeigt deren Äquivalente in PowerShell. Die Schwerpunkte sind **Navigation und Verzeichnisverwaltung**, **Datei- und Benutzerverwaltung**, **Suche und Filterung** sowie **Ein-/Ausgabeumleitungen und Skriptautomatisierung**. Durch praktische Übungen lernst du, PowerShell-Befehle anzuwenden, um ein Windows-System effizient zu verwalten.

Voraussetzungen:
- Ein Windows-System (z. B. Windows 10 oder 11).
- PowerShell (vorinstalliert, starte mit `powershell` oder `pwsh` für PowerShell Core).
- Administratorrechte für einige Befehle (z. B. Benutzerverwaltung).
- Grundlegendes Verständnis von Dateien, Verzeichnissen und Kommandozeilen.
- Sichere Testumgebung (z. B. Testverzeichnis), um Befehle risikofrei auszuprobieren.

## Grundlegende Befehle
Hier sind die wichtigsten PowerShell-Befehle, die den Linux-Pendants entsprechen, aufgeteilt nach den Schwerpunkten:

1. **Navigationsbefehle**:
   - `Get-Location` (ähnlich `pwd`): Zeigt das aktuelle Arbeitsverzeichnis an.
   - `Get-ChildItem` (ähnlich `ls`): Listet Dateien und Verzeichnisse auf.
   - `Set-Location` (ähnlich `cd`): Wechselt das Verzeichnis.
2. **Datei- und Verzeichnisverwaltung**:
   - `New-Item -ItemType Directory` (ähnlich `mkdir`): Erstellt ein neues Verzeichnis.
   - `New-Item -ItemType File` (ähnlich `touch`): Erstellt eine neue leere Datei.
   - `Remove-Item` (ähnlich `rm`): Löscht Dateien oder Verzeichnisse.
   - `Copy-Item` (ähnlich `cp`): Kopiert Dateien oder Verzeichnisse.
   - `Move-Item` (ähnlich `mv`): Verschiebt oder benennt Dateien/Verzeichnisse.
   - `Set-Acl` (ähnlich `chmod`): Ändert Berechtigungen von Dateien/Verzeichnissen.
   - `Set-Owner` (ähnlich `chown`): Ändert den Eigentümer (benötigt `NTFSSecurity`-Modul).
   - `New-LocalUser` (ähnlich `useradd`): Erstellt einen neuen Benutzer.
   - `New-LocalGroup` (ähnlich `groupadd`): Erstellt eine neue Gruppe.
3. **Dateiinhalte anzeigen und bearbeiten**:
   - `Get-Content` (ähnlich `cat`): Zeigt den Inhalt einer Datei an.
   - `more` oder `Get-Content | more` (ähnlich `less`): Ermöglicht das Durchscrollen langer Dateien.
   - `Tee-Object` (ähnlich `tee`): Schreibt in Dateien und die Ausgabe gleichzeitig.
4. **Suche und Filterung**:
   - `Select-String` (ähnlich `grep`): Durchsucht Text in Dateien nach Mustern.
   - `Get-ChildItem -Recurse` (ähnlich `find`): Sucht Dateien/Verzeichnisse im Dateisystem.
5. **Ein- und Ausgabeumleitungen & Pipes**:
   - `>` oder `Out-File` (ähnlich `>`): Leitet die Ausgabe in eine Datei um (überschreibt).
   - `>>` oder `Out-File -Append` (ähnlich `>>`): Hängt die Ausgabe an eine Datei an.
   - `|` (ähnlich `|`): Leitet die Ausgabe eines Befehls als Eingabe an einen anderen weiter.
6. **Dateikomprimierung und -archivierung**:
   - `Compress-Archive` (ähnlich `zip`): Erstellt ZIP-Archive.
   - `Expand-Archive` (ähnlich `unzip`): Entpackt ZIP-Archive.
   - `tar` (in neueren Windows-Versionen, ähnlich `tar`): Archiviert Dateien (benötigt `tar` oder Drittanbieter-Tools wie 7-Zip für `.gz`).
7. **Sonstige nützliche Befehle**:
   - `Get-Help` (ähnlich `man`): Zeigt die Hilfeseite eines Befehls an.
   - `Clear-Host` (ähnlich `clear`): Löscht die Terminalanzeige.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Navigation und Verzeichnisverwaltung
**Ziel**: Lerne, wie du dich im Dateisystem bewegst und Verzeichnisse verwaltest.

1. **Schritt 1**: Zeige das aktuelle Arbeitsverzeichnis:
   ```powershell
   Get-Location
   ```
2. **Schritt 2**: Liste alle Dateien und Verzeichnisse im aktuellen Verzeichnis auf:
   ```powershell
   Get-ChildItem
   ```
   Nutze den Alias `ls` für Kürze:
   ```powershell
   ls
   ```
3. **Schritt 3**: Erstelle ein Testverzeichnis und wechsle hinein:
   ```powershell
   New-Item -ItemType Directory -Name test_verzeichnis
   Set-Location test_verzeichnis
   Get-Location
   ```
4. **Schritt 4**: Erstelle eine leere Datei und überprüfe:
   ```powershell
   New-Item -ItemType File -Name test.txt
   Get-ChildItem
   ```
5. **Schritt 5**: Kopiere die Datei und benenne eine Kopie um:
   ```powershell
   Copy-Item test.txt test_kopie.txt
   Move-Item test_kopie.txt test_umbenannt.txt
   ls
   ```
6. **Schritt 6**: Lösche die Datei und das Verzeichnis:
   ```powershell
   Remove-Item test_umbenannt.txt
   Set-Location ..
   Remove-Item test_verzeichnis -Recurse
   ls
   ```

**Reflexion**: Wie unterscheiden sich Aliase wie `ls` von Linux? Schaue in `Get-Help Get-ChildItem` und überlege, warum PowerShell-Cmdlets strukturierter sind.

### Übung 2: Datei- und Benutzerverwaltung
**Ziel**: Lerne, wie du Dateien bearbeitest und Benutzer/Gruppen verwaltest.

1. **Schritt 1**: Erstelle eine Datei mit Inhalt:
   ```powershell
   "Hallo PowerShell" | Out-File test.txt
   Get-Content test.txt
   ```
2. **Schritt 2**: Füge Text an die Datei an und überprüfe:
   ```powershell
   "Zweite Zeile" | Out-File test.txt -Append
   Get-Content test.txt
   ```
3. **Schritt 3**: Zeige den Inhalt mit Paginierung:
   ```powershell
   Get-Content test.txt | more
   ```
4. **Schritt 4**: Erstelle einen neuen Benutzer (benötigt Admin-Rechte):
   ```powershell
   New-LocalUser -Name "TestUser" -Password (ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force) -FullName "Test Benutzer" -Description "Testkonto"
   ```
   Überprüfe:
   ```powershell
   Get-LocalUser -Name TestUser
   ```
5. **Schritt 5**: Erstelle eine Gruppe und füge den Benutzer hinzu:
   ```powershell
   New-LocalGroup -Name "TestGruppe" -Description "Testgruppe"
   Add-LocalGroupMember -Group "TestGruppe" -Member "TestUser"
   Get-LocalGroupMember -Group "TestGruppe"
   ```

**Reflexion**: Warum ist `ConvertTo-SecureString` wichtig für `New-LocalUser`? Schaue in `Get-Help New-LocalUser` und überlege, wie Berechtigungen (`Set-Acl`) genutzt werden könnten.

### Übung 3: Suche, Filterung und Automatisierung
**Ziel**: Lerne, wie du Dateien durchsuchst und einfache PowerShell-Skripte erstellst.

1. **Schritt 1**: Suche nach Text in einer Datei:
   ```powershell
   Select-String -Path test.txt -Pattern "Hallo"
   ```
   Nutze den Alias `sls`:
   ```powershell
   sls -Path test.txt -Pattern "Hallo"
   ```
2. **Schritt 2**: Suche rekursiv nach Dateien:
   ```powershell
   Get-ChildItem -Recurse -Include *.txt
   ```
3. **Schritt 3**: Erstelle ein ZIP-Archiv:
   ```powershell
   Compress-Archive -Path test.txt -DestinationPath test.zip
   ls
   ```
   Entpacke es:
   ```powershell
   Expand-Archive -Path test.zip -DestinationPath entpackt
   ls entpackt
   ```
4. **Schritt 4**: Erstelle ein Skript für automatische Dateierstellung:
   ```powershell
   New-Item -ItemType File -Name auto_file.ps1
   "Get-Date | Out-File -FilePath log.txt -Append" | Out-File auto_file.ps1
   ```
   Führe es aus:
   ```powershell
   .\auto_file.ps1
   Get-Content log.txt
   ```
5. **Schritt 5**: Plane das Skript mit dem Windows Task Scheduler (PowerShell-Befehl für einmalige Ausführung):
   ```powershell
   $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File $HOME\auto_file.ps1"
   $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5)
   Register-ScheduledTask -TaskName "AutoFileTask" -Action $action -Trigger $trigger -Description "Testaufgabe"
   ```
   Überprüfe nach 5 Minuten:
   ```powershell
   Get-Content log.txt
   ```

**Reflexion**: Wie unterscheidet sich `Select-String` von `grep`? Schaue in `Get-Help Select-String` und überlege, wie du das Skript mit Bedingungen erweitern könntest.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um die Cmdlets zu verinnerlichen.
- **Experimentiere sicher**: Nutze ein Testverzeichnis, um Datenverlust zu vermeiden.
- **Fehler sind normal**: Lies Fehlermeldungen und nutze `Get-Help` oder Online-Ressourcen.
- **Vorsicht bei Admin-Befehlen**: Benutzerverwaltung kann das System beeinflussen.
- **Logs überprüfen**: Verwende Logdateien (z. B. `log.txt`) zur Fehlersuche.
- **Skripte modular gestalten**: Nutze Variablen und Bedingungen für flexible Skripte.

## Fazit
Durch diese Übungen hast du grundlegende PowerShell-Befehle für Navigation, Datei- und Benutzerverwaltung sowie Automatisierung angewendet. Wiederhole die Übungen und experimentiere mit erweiterten Cmdlets (z. B. `Invoke-WebRequest` für Netzwerkaufgaben oder `ForEach-Object` für Schleifen), um deine Fähigkeiten zu vertiefen.