# Praxisorientierte Anleitung: Automatisierung der Zertifikatserstellung mit PowerShell und win-acme auf Windows Server

## Einführung
win-acme ist ein Open-Source-ACME-Client für Windows, der das ACME-Protokoll (RFC 8555) nutzt, um kostenlose TLS-Zertifikate von Let's Encrypt automatisch zu erstellen, zu erneuern und zu verwalten. In Kombination mit PowerShell ermöglicht win-acme die vollständige Automatisierung der Zertifikatserstellung, einschließlich der Überprüfung von Ablaufdaten, Erneuerung und Integration in IIS (Internet Information Services). Diese Anleitung zeigt Ihnen, wie Sie win-acme auf Windows Server installieren, PowerShell-Skripte für die Automatisierung erstellen und die Rotation mit dem Task Scheduler planen. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, TLS-Zertifikate auf Windows Server wartungsfrei zu verwalten. Diese Anleitung ist ideal für Windows-Administratoren und Entwickler, die sichere HTTPS-Infrastrukturen automatisieren möchten.

Voraussetzungen:
- Windows Server 2019 oder höher mit Administratorrechten
- PowerShell 5.1 oder höher (standardmäßig installiert)
- IIS installiert und konfiguriert (über Server Manager > Add Roles and Features)
- Mindestens 2 GB RAM und ausreichend Festplattenspeicher (mindestens 5 GB frei)
- Ein öffentlich erreichbarer Domainname (z. B. `myserver.example.com`), der auf die Server-IP zeigt
- Grundlegende Kenntnisse der PowerShell-Kommandozeile und IIS
- Ein Texteditor (z. B. Notepad++ oder VS Code)

## Grundlegende Konzepte und Befehle für PowerShell und win-acme
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **win-acme-Konzepte**:
   - **ACME-Protokoll**: Automatisiert die Validierung und Ausstellung von Zertifikaten (z. B. HTTP-01-Challenge)
   - **win-acme**: Windows-spezifischer Client, der Zertifikate in die Windows Certificate Store importiert
   - **PowerShell-Integration**: Skripte für Ablaufüberprüfung und Erneuerung
   - **Task Scheduler**: Windows-Äquivalent zu Cron für geplante Aufgaben
2. **Wichtige PowerShell-Befehle**:
   - `Get-ChildItem Cert:\LocalMachine\My`: Listet Zertifikate in der Store
   - `Get-Date`: Prüft aktuelles Datum
   - `Start-Process`: Führt win-acme aus
3. **Wichtige win-acme-Befehle**:
   - `wacs.exe --test`: Testet die Erneuerung
   - `wacs.exe --renew`: Erneuert Zertifikate

## Übungen zum Verinnerlichen

### Übung 1: win-acme installieren und initiales Zertifikat erstellen
**Ziel**: Lernen, wie man win-acme installiert und ein initiales TLS-Zertifikat für IIS erstellt.

1. **Schritt 1**: Lade und installiere win-acme.
   - Gehe zu [github.com/win-acme/win-acme/releases](https://github.com/win-acme/win-acme/releases) und lade die neueste Version (z. B. `win-acme.v2.2.9.1701.x64.zip`) herunter.
   - Entpacke die ZIP in `C:\Program Files\win-acme` und führe `wacs.exe` als Administrator aus.
2. **Schritt 2**: Erstelle ein Zertifikat.
   - Wähle "Create certificate (full options)" > "Manual input" > Gib `myserver.example.com` ein.
   - Wähle "HTTP validation (webroot)" und gib den Webroot-Pfad ein (z. B. `C:\inetpub\wwwroot`).
   - Wähle "IIS binding" für die Integration.
   - Gib eine E-Mail-Adresse ein und akzeptiere die Terms.
   - win-acme validiert die Domain und importiert das Zertifikat in die Store.
3. **Schritt 3**: Überprüfe das Zertifikat in IIS.
   - Öffne IIS Manager > Server Certificates: Sie sehen das Let's Encrypt-Zertifikat.
   - Binden Sie es an eine Site: Bindings > Add > HTTPS > Wählen Sie das Zertifikat > Port: 443.
4. **Schritt 4**: Teste die Webseite.
   - Öffne `https://myserver.example.com` im Browser. Das Zertifikat sollte gültig sein.

**Reflexion**: Wie vereinfacht win-acme die ACME-Integration auf Windows, und warum ist die HTTP-Validation für Webserver geeignet?

### Übung 2: PowerShell-Skript für Zertifikatablaufüberprüfung und Erneuerung erstellen
**Ziel**: Verstehen, wie man ein PowerShell-Skript schreibt, das Zertifikate überprüft und mit win-acme erneuert.

1. **Schritt 1**: Erstelle ein Verzeichnis für Skripte.
   ```
   New-Item -ItemType Directory -Path C:\cert-rotation -Force
   ```
2. **Schritt 2**: Erstelle das PowerShell-Skript `RotateCert.ps1`.
   ```
   notepad C:\cert-rotation\RotateCert.ps1
   ```
   Füge folgenden Inhalt ein:
   ```powershell
   # Konfiguration
   $Domain = "myserver.example.com"
   $WinAcmePath = "C:\Program Files\win-acme"
   $CertStore = "Cert:\LocalMachine\My"
   $DaysThreshold = 30
   $LogFile = "C:\cert-rotation\rotation.log"
   $CurrentDate = Get-Date

   # Funktionen
   function Check-Expiry {
       $Cert = Get-ChildItem $CertStore | Where-Object { $_.Subject -like "*$Domain*" }
       if (-not $Cert) {
           Write-Output "Zertifikat für $Domain nicht gefunden." | Tee-Object -FilePath $LogFile -Append
           return $false
       }
       $ExpiryDate = $Cert.NotAfter
       $DaysLeft = ($ExpiryDate - $CurrentDate).Days
       Write-Output "Zertifikat läuft in $DaysLeft Tagen ab." | Tee-Object -FilePath $LogFile -Append
       return $DaysLeft -lt $DaysThreshold
   }

   function Renew-Certificate {
       $BackupPath = "C:\cert-rotation\backups\$Domain-$($CurrentDate.ToString('yyyyMMddHHmmss')).pfx"
       # Exportiere altes Zertifikat als Backup (mit Passwort)
       $Cert = Get-ChildItem $CertStore | Where-Object { $_.Subject -like "*$Domain*" }
       $CertBytes = $Cert.Export([Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, "password")
       [System.IO.File]::WriteAllBytes($BackupPath, $CertBytes)
       Write-Output "Backup erstellt: $BackupPath" | Tee-Object -FilePath $LogFile -Append

       # Erneuere mit win-acme
       & "$WinAcmePath\wacs.exe" --renew --test --quiet
       if ($LASTEXITCODE -eq 0) {
           Write-Output "Zertifikat erfolgreich erneuert für $Domain." | Tee-Object -FilePath $LogFile -Append
       } else {
           Write-Output "Fehler bei der Erneuerung." | Tee-Object -FilePath $LogFile -Append
           return $false
       }
       return $true
   }

   function Reload-IIS {
       iisreset /restart
       if ($LASTEXITCODE -eq 0) {
           Write-Output "IIS erfolgreich neu gestartet." | Tee-Object -FilePath $LogFile -Append
       } else {
           Write-Output "Fehler beim Neustart von IIS." | Tee-Object -FilePath $LogFile -Append
           return $false
       }
       return $true
   }

   # Hauptlogik
   $NeedsRenewal = Check-Expiry
   if ($NeedsRenewal) {
       Write-Output "Erneuerung wird durchgeführt..." | Tee-Object -FilePath $LogFile -Append
       $RenewSuccess = Renew-Certificate
       if ($RenewSuccess) {
           Reload-IIS
       }
   } else {
       Write-Output "Kein Erneuerung notwendig." | Tee-Object -FilePath $LogFile -Append
   }
   ```
3. **Schritt 3**: Führe das Skript aus und teste es.
   ```
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   C:\cert-rotation\RotateCert.ps1
   ```
   Überprüfe die Logs:
   ```
   Get-Content C:\cert-rotation\rotation.log
   ```

**Reflexion**: Wie vereinfacht PowerShell die Zertifikatsüberwachung auf Windows, und warum ist der Export als PFX für Backups praktisch?

### Übung 3: Task Scheduler für automatisierte Rotation einrichten
**Ziel**: Lernen, wie man das Skript mit dem Task Scheduler plant und Benachrichtigungen hinzufügt.

1. **Schritt 1**: Erweitere das Skript um E-Mail-Benachrichtigungen.
   ```
   notepad C:\cert-rotation\RotateCert.ps1
   ```
   Füge vor der Hauptlogik eine Benachrichtigungsfunktion hinzu:
   ```powershell
   function Send-Notification {
       param($Subject, $Message)
       $Body = @"
   $Message
   Datum: $CurrentDate
   Log: $(Get-Content $LogFile -Tail 5)
   "@
       Send-MailMessage -To "admin@example.com" -From "server@example.com" -Subject $Subject -Body $Body -SmtpServer "smtp.example.com" -Port 587 -UseSsl -Credential (Get-Credential)
   }
   ```
   Passe die Hauptlogik an:
   ```powershell
   if ($NeedsRenewal) {
       $RenewSuccess = Renew-Certificate
       if ($RenewSuccess) {
           if (Reload-IIS) {
               Send-Notification "Zertifikatrotation erfolgreich" "Zertifikat für $Domain erneuert."
           } else {
               Send-Notification "Zertifikatrotation teilweise fehlgeschlagen" "Erneuerung erfolgreich, aber IIS-Fehler."
           }
       } else {
           Send-Notification "Zertifikatrotation fehlgeschlagen" "Fehler bei der Erneuerung."
       }
   } else {
       Write-Output "Kein Erneuerung notwendig." | Tee-Object -FilePath $LogFile -Append
   }
   ```
   Konfiguriere SMTP in PowerShell (z. B. mit Outlook oder einem SMTP-Server).
2. **Schritt 2**: Richte einen Task Scheduler-Job ein.
   - Öffne Task Scheduler > Create Basic Task.
   - Name: "Zertifikatrotation".
   - Trigger: Daily, um 3:00 Uhr.
   - Action: Start a program > `powershell.exe` > Arguments: `-ExecutionPolicy Bypass -File C:\cert-rotation\RotateCert.ps1`.
   - Speichern und testen: Rechtsklick > Run.
3. **Schritt 3**: Überprüfe die Ausführung.
   - In Task Scheduler > History: Überprüfen Sie den Status.
   - Logs: `Get-Content C:\cert-rotation\rotation.log`.

**Reflexion**: Wie ist Task Scheduler dem Cron-Job ähnlich, und welche Vorteile bietet es für Windows-Umgebungen?

## Tipps für den Erfolg
- Führen Sie PowerShell-Skripte als Administrator aus (`Run as Administrator`).
- Sichere private Schlüssel in der Certificate Store (Export mit Passwort).
- Verwenden Sie `Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.NotAfter -lt (Get-Date).AddDays(30)}` für schnelle Checks.
- Testen Sie mit `wacs.exe --test` vor der Produktion.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie die Zertifikatserstellung mit PowerShell und win-acme auf Windows Server automatisieren, einschließlich Ablaufüberprüfung, Erneuerung und Task Scheduler-Integration. Durch die Übungen haben Sie praktische Erfahrung mit ACME auf Windows gesammelt. Diese Fähigkeiten sind essenziell für sichere, automatisierte HTTPS-Infrastrukturen. Üben Sie weiter, um Multi-Domain-Support oder Integration mit Azure zu implementieren!

**Nächste Schritte**:
- Erweitern Sie für Wildcard-Zertifikate mit DNS-Validation.
- Integrieren Sie in Azure DevOps für CI/CD.
- Erkunden Sie NDES für Enterprise-Automatisierung.

**Quellen**:
- Offizielle win-acme-Dokumentation: https://www.win-acme.com/
- PowerShell-Dokumentation: https://learn.microsoft.com/en-us/powershell/
- Let's Encrypt-Dokumentation: https://letsencrypt.org/docs/
- Microsoft Learn: https://learn.microsoft.com/en-us/iis/manage/configuring-security/how-to-set-up-ssl-on-iis