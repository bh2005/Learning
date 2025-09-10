# Praxisorientierte Anleitung: PowerShell-Befehle für Windows zur Benutzerverwaltung, Sicherheits- und Berechtigungsmanagement sowie Auditing und Logging

## Einführung
Die PowerShell bietet leistungsstarke Werkzeuge zur Verwaltung von Benutzern, Berechtigungen und Systemprotokollen unter Windows. Diese Anleitung orientiert sich an den angegebenen Linux-Befehlen und zeigt deren Äquivalente in PowerShell. Die Schwerpunkte sind **Benutzerverwaltung**, **Sicherheits- und Berechtigungsmanagement** sowie **Auditing und Logging**. Durch praktische Übungen lernst du, PowerShell-Cmdlets anzuwenden, um Benutzerkonten, Berechtigungen und Systemereignisse effizient zu verwalten und zu überwachen.

Voraussetzungen:
- Ein Windows-System (z. B. Windows 10 oder 11).
- PowerShell (vorinstalliert, starte mit `powershell` oder `pwsh` für PowerShell Core).
- Administratorrechte für die meisten Befehle (z. B. Benutzerverwaltung, ACLs).
- Grundlegendes Verständnis von Benutzern, Gruppen und Berechtigungen.
- Sichere Testumgebung (z. B. Testbenutzer oder VM), um Änderungen risikofrei auszuprobieren.
- Optional: `NTFSSecurity`-Modul für erweiterte Berechtigungsverwaltung.

## Grundlegende Befehle
Hier sind die wichtigsten PowerShell-Befehle, die den Linux-Pendants entsprechen, aufgeteilt nach den Schwerpunkten:

1. **Benutzerverwaltung**:
   - `New-LocalUser` (ähnlich `useradd`): Erstellt einen neuen Benutzer.
   - `Set-LocalUser` (ähnlich `usermod`): Modifiziert Benutzerkonten (z. B. Passwort, Beschreibung).
   - `Remove-LocalUser` (ähnlich `userdel`): Löscht einen Benutzer.
   - `Set-LocalUser -Password` (ähnlich `passwd`): Ändert das Passwort eines Benutzers.
   - `Get-LocalUser`/`Get-CimInstance Win32_UserAccount` (ähnlich `id`): Zeigt Benutzer- und Gruppeninformationen.
   - `Enter-PSSession` oder `RunAs` (ähnlich `su`): Wechselt zu einem anderen Benutzerkonto.
   - `New-LocalGroup` (ähnlich `groupadd`): Erstellt eine neue Gruppe.
2. **Sicherheits- und Berechtigungsmanagement**:
   - `Set-Acl` (ähnlich `chmod`): Ändert Berechtigungen von Dateien/Verzeichnissen.
   - `Set-Owner` (ähnlich `chown`, benötigt `NTFSSecurity`-Modul): Ändert den Eigentümer.
   - Kein direktes Äquivalent zu `chattr`/`lsattr`, aber `Set-ItemProperty` für bestimmte Attribute.
   - `Set-Acl -AclObject` (ähnlich `setfacl`): Setzt Zugriffssteuerungslisten (ACLs).
   - `Get-Acl` (ähnlich `getfacl`): Zeigt Zugriffssteuerungslisten an.
   - `$PSDefaultParameterValues` oder Skripte (ähnlich `umask`): Beeinflusst Standardberechtigungen.
3. **Auditing und Logging**:
   - `Get-WinEvent -LogName Security` (ähnlich `last`): Zeigt Anmeldeereignisse.
   - `Get-CimInstance Win32_LoggedOnUser` (ähnlich `who`): Zeigt aktuell angemeldete Benutzer.
   - `Get-EventLog` oder `Get-WinEvent` (ähnlich `journalctl`): Zeigt System- und Benutzerlogs.
   - `wevtutil` oder `Set-EventLog` (ähnlich `auditctl`): Konfiguriert Ereignisprotokollierung.
4. **Sonstige nützliche Befehle**:
   - `Get-Help` (ähnlich `man`): Zeigt die Hilfeseite eines Befehls an.
   - `Start-Process -Verb RunAs` (ähnlich `sudo`): Führt Befehle mit Administratorrechten aus.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Benutzerverwaltung
**Ziel**: Lerne, wie du Benutzer und Gruppen erstellst, modifizierst und löschst.

1. **Schritt 1**: Erstelle einen neuen Benutzer (benötigt Admin-Rechte):
   ```powershell
   New-LocalUser -Name "TestUser" -Password (ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force) -FullName "Test Benutzer" -Description "Testkonto"
   ```
   Überprüfe:
   ```powershell
   Get-LocalUser -Name TestUser
   ```
2. **Schritt 2**: Ändere das Passwort und die Beschreibung des Benutzers:
   ```powershell
   Set-LocalUser -Name TestUser -Password (ConvertTo-SecureString "NeuesP@ssw0rd456" -AsPlainText -Force) -Description "Geändertes Testkonto"
   Get-LocalUser -Name TestUser
   ```
3. **Schritt 3**: Erstelle eine Gruppe und füge den Benutzer hinzu:
   ```powershell
   New-LocalGroup -Name "TestGruppe" -Description "Testgruppe"
   Add-LocalGroupMember -Group "TestGruppe" -Member "TestUser"
   Get-LocalGroupMember -Group "TestGruppe"
   ```
4. **Schritt 4**: Zeige Benutzer- und Gruppeninformationen:
   ```powershell
   Get-CimInstance Win32_UserAccount -Filter "Name='TestUser'" | Select-Object Name, SID
   ```
5. **Schritt 5**: Lösche den Benutzer und die Gruppe:
   ```powershell
   Remove-LocalUser -Name TestUser
   Remove-LocalGroup -Name TestGruppe
   Get-LocalUser -Name TestUser -ErrorAction SilentlyContinue
   ```

**Reflexion**: Warum ist `ConvertTo-SecureString` für Passwörter notwendig? Schaue in `Get-Help New-LocalUser` und überlege, wie du Benutzer in Active Directory verwalten könntest.

### Übung 2: Sicherheits- und Berechtigungsmanagement
**Ziel**: Lerne, wie du Berechtigungen und Eigentümer von Dateien/Verzeichnissen änderst.

1. **Schritt 1**: Erstelle ein Testverzeichnis und eine Datei:
   ```powershell
   New-Item -ItemType Directory -Name test_verzeichnis
   New-Item -ItemType File -Name test_verzeichnis\test.txt
   "Testdaten" | Out-File test_verzeichnis\test.txt
   ```
2. **Schritt 2**: Zeige die aktuellen Berechtigungen:
   ```powershell
   Get-Acl test_verzeichnis\test.txt | Format-List
   ```
3. **Schritt 3**: Ändere die Berechtigungen, um "Everyone" Leserechte zu geben:
   ```powershell
   $acl = Get-Acl test_verzeichnis\test.txt
   $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "Read", "Allow")
   $acl.AddAccessRule($rule)
   Set-Acl test_verzeichnis\test.txt -AclObject $acl
   Get-Acl test_verzeichnis\test.txt | Format-List
   ```
4. **Schritt 4**: Installiere das `NTFSSecurity`-Modul für erweiterte Berechtigungen (optional):
   ```powershell
   Install-Module -Name NTFSSecurity -Force
   Set-Owner -Path test_verzeichnis\test.txt -Account "Administrators"
   Get-Owner -Path test_verzeichnis\test.txt
   ```
5. **Schritt 5**: Setze ein Attribut (z. B. schreibgeschützt):
   ```powershell
   Set-ItemProperty -Path test_verzeichnis\test.txt -Name IsReadOnly -Value $true
   Get-ItemProperty -Path test_verzeichnis\test.txt | Select-Object IsReadOnly
   ```

**Reflexion**: Wie unterscheidet sich `Set-Acl` von `chmod`? Schaue in `Get-Help Set-Acl` und überlege, wie ACLs feingranulare Berechtigungen ermöglichen.

### Übung 3: Auditing und Logging
**Ziel**: Lerne, wie du Anmeldungen und Systemereignisse überwachst und automatisiert protokollierst.

1. **Schritt 1**: Zeige die letzten Anmeldeereignisse:
   ```powershell
   Get-WinEvent -LogName Security -MaxEvents 5 | Where-Object { $_.Id -eq 4624 } | Select-Object TimeCreated, @{Name="User";Expression={$_.Properties[5].Value}}
   ```
   Hinweis: Event-ID 4624 steht für erfolgreiche Anmeldungen.
2. **Schritt 2**: Zeige aktuell angemeldete Benutzer:
   ```powershell
   Get-CimInstance Win32_LoggedOnUser | Select-Object @{Name="User";Expression={$_.Antecedent.Name}} | Sort-Object User -Unique
   ```
3. **Schritt 3**: Überwache Systemlogs:
   ```powershell
   Get-EventLog -LogName System -Newest 5
   ```
4. **Schritt 4**: Erstelle ein Skript zur automatischen Protokollierung von Anmeldungen:
   ```powershell
   New-Item -ItemType File -Name audit_log.ps1
   @"
   \$logFile = "\$HOME\audit_log.txt"
   Get-Date | Out-File -FilePath \$logFile -Append
   Get-WinEvent -LogName Security -MaxEvents 1 | Where-Object { \$_.Id -eq 4624 } | Select-Object TimeCreated, @{Name="User";Expression={\$_.Properties[5].Value}} | Out-File -FilePath \$logFile -Append
   "@ | Out-File audit_log.ps1
   ```
   Führe es aus:
   ```powershell
   .\audit_log.ps1
   Get-Content $HOME\audit_log.txt
   ```
5. **Schritt 5**: Plane das Skript mit dem Task Scheduler (stündlich):
   ```powershell
   $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File $HOME\audit_log.ps1"
   $trigger = New-ScheduledTaskTrigger -Daily -At "12:00 AM" -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 1)
   Register-ScheduledTask -TaskName "AuditLog" -Action $action -Trigger $trigger -Description "Audit-Überwachung"
   ```

**Reflexion**: Wie unterscheidet sich `Get-WinEvent` von `journalctl`? Schaue in `Get-Help Get-WinEvent` und überlege, wie du spezifische Ereignisse filtern könntest.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um die Cmdlets zu verinnerlichen.
- **Experimentiere sicher**: Nutze Testbenutzer und -verzeichnisse, um Systemänderungen zu vermeiden.
- **Fehler sind normal**: Lies Fehlermeldungen und nutze `Get-Help` oder Online-Ressourcen.
- **Vorsicht bei Admin-Befehlen**: Änderungen an Benutzern oder Berechtigungen können das System beeinflussen.
- **Logs überprüfen**: Nutze `Get-EventLog` oder Skript-Logs (z. B. `audit_log.txt`) zur Fehlersuche.
- **Skripte modular gestalten**: Verwende Variablen und Bedingungen für flexible Automatisierung.

## Fazit
Durch diese Übungen hast du PowerShell-Befehle für Benutzerverwaltung, Sicherheits- und Berechtigungsmanagement sowie Auditing und Logging angewendet. Wiederhole die Übungen und experimentiere mit erweiterten Cmdlets (z. B. `Get-ADUser` für Active Directory oder `wevtutil` für detaillierte Protokollierung), um deine Fähigkeiten zu vertiefen.