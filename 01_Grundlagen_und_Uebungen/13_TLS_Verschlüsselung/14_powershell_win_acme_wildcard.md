# Praxisorientierte Anleitung: Automatisierung von Wildcard-Zertifikaten mit DNS-Validation auf Windows Server mit PowerShell und win-acme

## Einführung
Wildcard-Zertifikate (z. B. `*.example.com`) sichern alle Subdomains einer Domain mit einem einzigen TLS-Zertifikat ab, was besonders in dynamischen Umgebungen effizient ist. Für Wildcard-Zertifikate ist die DNS-01-Challenge erforderlich, da HTTP-01 nicht unterstützt wird. win-acme, ein ACME-Client für Windows, unterstützt DNS-Validation über API-Integration mit DNS-Providern wie Cloudflare. Diese Anleitung erweitert die vorherige Anleitung zur Automatisierung der Zertifikatserstellung mit PowerShell und win-acme, um Wildcard-Zertifikate mit DNS-Validation zu handhaben, einschließlich Ablaufüberprüfung, Erneuerung und Integration in IIS. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, Wildcard-Zertifikate auf Windows Server wartungsfrei zu verwalten. Diese Anleitung ist ideal für Windows-Administratoren, die skalierbare HTTPS-Lösungen für Subdomains einrichten möchten.

Voraussetzungen:
- Windows Server 2019 oder höher mit Administratorrechten
- PowerShell 5.1 oder höher (standardmäßig installiert)
- IIS installiert und konfiguriert (über Server Manager > Add Roles and Features)
- Mindestens 2 GB RAM und ausreichend Festplattenspeicher (mindestens 5 GB frei)
- Ein öffentlich erreichbarer Domainname (z. B. `example.com`) mit DNS-API-Zugriff (z. B. Cloudflare API-Token)
- Grundlegende Kenntnisse der PowerShell-Kommandozeile und IIS
- Ein Texteditor (z. B. Notepad++ oder VS Code)

## Grundlegende Konzepte und Befehle für Wildcard-Zertifikate
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **Wildcard-Konzepte**:
   - **Wildcard-Zertifikat**: Deckt `*.example.com` und `example.com` ab (beide müssen angegeben werden)
   - **DNS-01-Challenge**: Erfordert einen TXT-Record (z. B. `_acme-challenge.example.com`) zur Validierung
   - **API-Integration**: Automatisiert TXT-Records über DNS-Provider-APIs (z. B. Cloudflare)
   - **win-acme**: Unterstützt DNS-Validation mit Plugins (z. B. Cloudflare)
2. **Wichtige PowerShell-Befehle**:
   - `Get-ChildItem Cert:\LocalMachine\My`: Listet Zertifikate in der Windows Certificate Store
   - `Start-Process`: Führt win-acme aus
   - `Send-MailMessage`: Sendet Benachrichtigungen
3. **Wichtige win-acme-Befehle**:
   - `wacs.exe --target manual --host *.example.com,example.com`: Erstellt ein Wildcard-Zertifikat
   - `wacs.exe --renew`: Erneuert Zertifikate
   - `wacs.exe --test`: Testet die Konfiguration

## Übungen zum Verinnerlichen

### Übung 1: win-acme für Wildcard-Zertifikate mit DNS-Validation einrichten
**Ziel**: Lernen, wie man win-acme konfiguriert, um ein Wildcard-Zertifikat mit DNS-01-Challenge zu erstellen.

1. **Schritt 1**: Installiere win-acme (falls nicht bereits vorhanden).
   - Gehe zu [github.com/win-acme/win-acme/releases](https://github.com/win-acme/win-acme/releases) und lade die neueste Version (z. B. `win-acme.v2.2.9.1701.x64.zip`) herunter.
   - Entpacke die ZIP in `C:\Program Files\win-acme` und führe `wacs.exe` als Administrator aus.
2. **Schritt 2**: Erstelle ein Wildcard-Zertifikat.
   - Öffne PowerShell als Administrator und führe aus:
     ```powershell
     & "C:\Program Files\win-acme\wacs.exe" --target manual --host *.example.com,example.com --validation dns-01 --dnsplugin cloudflare --dnscloudflareapitoken YOUR_API_TOKEN --emailaddress admin@example.com --accepttos
     ```
     - Ersetze `YOUR_API_TOKEN` mit deinem Cloudflare API-Token (erhältlich in Cloudflare Dashboard > API Tokens > Create Token > Edit Zone DNS).
     - win-acme setzt den TXT-Record automatisch über die API und validiert die Domain.
3. **Schritt 3**: Überprüfe das Zertifikat in IIS.
   - Öffne IIS Manager > Server Certificates: Das Let's Encrypt-Wildcard-Zertifikat sollte angezeigt werden.
   - Binde es an eine Site: Bindings > Add > HTTPS > Wähle das Zertifikat > Port: 443.
4. **Schritt 4**: Teste die Webseite.
   - Öffne `https://sub.example.com` und `https://example.com` im Browser. Beide sollten das gleiche Zertifikat verwenden.

**Reflexion**: Warum ist DNS-01 für Wildcard-Zertifikate erforderlich, und wie vereinfacht die Cloudflare-API die Automatisierung?

### Übung 2: PowerShell-Skript für Wildcard-Zertifikatrotation erstellen
**Ziel**: Verstehen, wie man ein PowerShell-Skript schreibt, um Wildcard-Zertifikate zu überprüfen und mit win-acme zu erneuern.

1. **Schritt 1**: Erstelle ein Verzeichnis für Skripte.
   ```powershell
   New-Item -ItemType Directory -Path C:\cert-rotation -Force
   ```
2. **Schritt 2**: Erstelle das PowerShell-Skript `RotateWildcardCert.ps1`.
   ```powershell
   notepad C:\cert-rotation\RotateWildcardCert.ps1
   ```
   Füge folgenden Inhalt ein:
   ```powershell
   # Konfiguration
   $Domain = "example.com"
   $WildcardDomain = "*.example.com"
   $WinAcmePath = "C:\Program Files\win-acme\wacs.exe"
   $CertStore = "Cert:\LocalMachine\My"
   $DaysThreshold = 30
   $LogFile = "C:\cert-rotation\rotation.log"
   $CurrentDate = Get-Date
   $CloudflareApiToken = "YOUR_API_TOKEN"
   $EmailAddress = "admin@example.com"

   # Funktionen
   function Check-Expiry {
       $Cert = Get-ChildItem $CertStore | Where-Object { $_.Subject -like "*$Domain*" }
       if (-not $Cert) {
           Write-Output "Zertifikat für $Domain nicht gefunden." | Tee-Object -FilePath $LogFile -Append
           return $false
       }
       $ExpiryDate = $Cert.NotAfter
       $DaysLeft = ($ExpiryDate - $CurrentDate).Days
       Write-Output "Wildcard-Zertifikat läuft in $DaysLeft Tagen ab." | Tee-Object -FilePath $LogFile -Append
       return $DaysLeft -lt $DaysThreshold
   }

   function Renew-Certificate {
       $BackupPath = "C:\cert-rotation\backups\$Domain-$($CurrentDate.ToString('yyyyMMddHHmmss')).pfx"
       $Cert = Get-ChildItem $CertStore | Where-Object { $_.Subject -like "*$Domain*" }
       if ($Cert) {
           $CertBytes = $Cert.Export([Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, "password")
           [System.IO.File]::WriteAllBytes($BackupPath, $CertBytes)
           Write-Output "Backup erstellt: $BackupPath" | Tee-Object -FilePath $LogFile -Append
       }

       # Erneuere mit win-acme und DNS-Validation
       $WinAcmeArgs = "--target manual --host $WildcardDomain,$Domain --validation dns-01 --dnsplugin cloudflare --dnscloudflareapitoken $CloudflareApiToken --emailaddress $EmailAddress --accepttos --renew --quiet"
       Start-Process -FilePath $WinAcmePath -ArgumentList $WinAcmeArgs -Wait -NoNewWindow
       if ($LASTEXITCODE -eq 0) {
           Write-Output "Wildcard-Zertifikat erfolgreich erneuert für $WildcardDomain,$Domain." | Tee-Object -FilePath $LogFile -Append
       } else {
           Write-Output "Fehler bei der Erneuerung des Wildcard-Zertifikats." | Tee-Object -FilePath $LogFile -Append
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

   function Send-Notification {
       param($Subject, $Message)
       $Body = @"
   $Message
   Datum: $CurrentDate
   Log: $(Get-Content $LogFile -Tail 5)
   "@
       Send-MailMessage -To $EmailAddress -From "server@example.com" -Subject $Subject -Body $Body -SmtpServer "smtp.example.com" -Port 587 -UseSsl -Credential (Get-Credential)
   }

   # Hauptlogik
   $NeedsRenewal = Check-Expiry
   if ($NeedsRenewal) {
       Write-Output "Erneuerung des Wildcard-Zertifikats wird durchgeführt..." | Tee-Object -FilePath $LogFile -Append
       $RenewSuccess = Renew-Certificate
       if ($RenewSuccess) {
           if (Reload-IIS) {
               Send-Notification "Wildcard-Zertifikatrotation erfolgreich" "Zertifikat für $WildcardDomain,$Domain erneuert."
           } else {
               Send-Notification "Wildcard-Zertifikatrotation teilweise fehlgeschlagen" "Erneuerung erfolgreich, aber IIS-Fehler."
           }
       } else {
           Send-Notification "Wildcard-Zertifikatrotation fehlgeschlagen" "Fehler bei der Erneuerung."
       }
   } else {
       Write-Output "Keine Erneuerung notwendig." | Tee-Object -FilePath $LogFile -Append
   }
   ```
3. **Schritt 3**: Führe das Skript aus und teste es.
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   C:\cert-rotation\RotateWildcardCert.ps1
   ```
   Überprüfe die Logs:
   ```powershell
   Get-Content C:\cert-rotation\rotation.log
   ```

**Reflexion**: Wie handhabt das Skript die DNS-Validation für Wildcards, und warum ist die API-Integration mit Cloudflare entscheidend für die Automatisierung?

### Übung 3: Task Scheduler für automatisierte Wildcard-Rotation einrichten
**Ziel**: Lernen, wie man die Wildcard-Zertifikatrotation mit Task Scheduler plant.

1. **Schritt 1**: Richte einen Task Scheduler-Job ein.
   - Öffne Task Scheduler > Create Basic Task.
   - Name: "Wildcard-Zertifikatrotation".
   - Trigger: Daily, um 3:00 Uhr.
   - Action: Start a program > `powershell.exe` > Arguments: `-ExecutionPolicy Bypass -File C:\cert-rotation\RotateWildcardCert.ps1`.
   - Stelle sicher, dass der Task als Administrator ausgeführt wird (Properties > Run with highest privileges).
   - Speichern und teste: Rechtsklick > Run.
2. **Schritt 2**: Überprüfe die Ausführung.
   - In Task Scheduler > History: Überprüfen Sie den Status.
   - Logs: `Get-Content C:\cert-rotation\rotation.log`.
3. **Schritt 3**: Teste die Benachrichtigungen.
   - Simuliere einen Ablauf, indem du `$DaysThreshold` auf einen höheren Wert setzt (z. B. 90) und das Skript ausführst.
   - Überprüfe die E-Mail-Benachrichtigung (SMTP-Server muss konfiguriert sein).

**Reflexion**: Wie ist Task Scheduler im Vergleich zu Cron für Linux, und welche Herausforderungen könnten bei der SMTP-Konfiguration auftreten?

## Tipps für den Erfolg
- Sichere den Cloudflare API-Token in einer verschlüsselten Umgebungsvariablen oder Datei.
- Teste mit `wacs.exe --test` vor der Produktion, um Rate-Limits zu vermeiden.
- Überprüfe DNS-Propagation mit `nslookup -type=TXT _acme-challenge.example.com`.
- Stelle sicher, dass Port 443 für HTTPS offen ist und die DNS-Zone korrekt konfiguriert ist.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie die Automatisierung von Wildcard-Zertifikaten mit DNS-Validation auf Windows Server mit PowerShell und win-acme umsetzen, einschließlich Ablaufüberprüfung, Erneuerung und Task Scheduler-Integration. Durch die Übungen haben Sie praktische Erfahrung mit DNS-01-Challenges und Cloudflare-API-Integration gesammelt. Diese Fähigkeiten sind essenziell für skalierbare, sichere HTTPS-Infrastrukturen mit Subdomains. Üben Sie weiter, um Multi-Server-Support oder Integration mit Azure DevOps zu implementieren!

**Nächste Schritte**:
- Erweitern Sie für Multi-Domain-Wildcards (z. B. `*.site1.com,*.site2.com`).
- Integrieren Sie in Azure DevOps für CI/CD.
- Erkunden Sie NDES für Enterprise-PKI auf Windows.

**Quellen**:
- Offizielle win-acme-Dokumentation: https://www.win-acme.com/
- PowerShell-Dokumentation: https://learn.microsoft.com/en-us/powershell/
- Let's Encrypt-Dokumentation: https://letsencrypt.org/docs/
- Cloudflare API-Dokumentation: https://developers.cloudflare.com/api/
- Microsoft Learn: https://learn.microsoft.com/en-us/iis/manage/configuring-security/how-to-set-up-ssl-on-iis