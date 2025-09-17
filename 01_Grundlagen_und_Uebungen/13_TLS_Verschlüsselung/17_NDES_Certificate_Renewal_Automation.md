# Praxisorientierte Anleitung: Automatisieren von Zertifikats-Renewal mit PowerShell für NDES und Intune

## Einführung
Das **Zertifikats-Renewal** ist ein kritischer Prozess in Enterprise-PKI-Umgebungen, um die Gültigkeit von Zertifikaten zu gewährleisten und Ausfälle zu vermeiden (z. B. bei NDES-Service-Zertifikaten, die für SCEP in Microsoft Intune verwendet werden). Ohne Automatisierung kann das manuelle Renewal zeitaufwendig und fehleranfällig sein. Diese Anleitung zeigt, wie Sie PowerShell nutzen, um das Renewal von **NDES-Service-Zertifikaten** (Enrollment Agent und Key Exchange) und **Client-Zertifikaten** via SCEP zu automatisieren. Wir integrieren dies in NDES mit Intune, inklusive Scheduled Tasks für periodische Ausführung. Ziel ist es, Administratoren Tools bereitzustellen, die Renewal-Prozesse skalierbar und sicher machen. Die Anleitung basiert auf offiziellen Microsoft-Tools und Community-Modulen wie PSCertificateEnrollment.

**Voraussetzungen:**
- Windows Server 2019 oder höher mit NDES und AD CS installiert
- PowerShell 5.1 oder höher (PowerShell 7 empfohlen)
- Zugriff auf das NDES-Server-Zertifikat-Store (LocalMachine\My)
- Intune Certificate Connector konfiguriert (für SCEP-Integration)
- Grundkenntnisse in PowerShell und Zertifikatsverwaltung
- Module: Installieren Sie PSCertificateEnrollment via `Install-Module -Name PSCertificateEnrollment` (aus PowerShell Gallery)
- Texteditor (z. B. VS Code) für Skripte

## Grundlegende Konzepte und Befehle
Hier sind die Kernkonzepte und PowerShell-Befehle für automatisches Zertifikats-Renewal:

1. **Renewal-Konzepte**:
   - **NDES-Service-Zertifikate**: Enrollment Agent (Offline Request) und Key Exchange (CEP Encryption) – müssen erneuert werden, um SCEP-Anfragen zu handhaben.
   - **SCEP-Renewal**: Client-Geräte erneuern Zertifikate automatisch via NDES, wenn das Modul PSCertificateEnrollment verwendet wird.
   - **Automatisierung**: Nutzen Sie Scheduled Tasks oder Event-Triggered Tasks, um Skripte bei Ablaufwarnungen auszuführen (z. B. via Certificate Services Lifecycle Notifications).
   - **Sicherheitsaspekte**: Speichern Sie Private Keys sicher und validieren Sie Templates vor Renewal.
2. **Wichtige Befehle**:
   - `Get-ChildItem Cert:\LocalMachine\My`: Listet Zertifikate im Store.
   - `certreq.exe`: Generiert und submitet Renewal-Anfragen.
   - `Get-SCEPCertificate`: Erneuert SCEP-Zertifikate (aus PSCertificateEnrollment).
   - `Register-ScheduledTask`: Plant automatisierte Ausführungen.
3. **Wichtige Konfigurationsdateien**:
   - `.inf`-Dateien für certreq (z. B. EEARequest.inf für Enrollment Agent).
   - Registry: `HKLM\SOFTWARE\Microsoft\Cryptography\MSCEP` für NDES-Templates.

## Übungen zum Verinnerlichen

### Übung 1: NDES-Service-Zertifikate mit PowerShell erneuern
**Ziel**: Automatisieren Sie das Renewal des Enrollment Agent- und Key Exchange-Zertifikats mit einem PowerShell-Skript, das certreq und Task Scheduler integriert.

1. **Schritt 1**: Überprüfen Sie aktuelle Zertifikate.
   - Öffnen Sie PowerShell als Administrator und führen Sie aus:
     ```powershell
     Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Subject -like "*NDES*" -or $_.Template -eq "CEPEncryption" } | Select-Object Thumbprint, Subject, NotAfter
     ```
     Notieren Sie den Thumbprint des Enrollment Agent-Zertifikats (z. B. für Offline Request).

2. **Schritt 2**: Erstellen Sie ein Renewal-Skript für das Enrollment Agent-Zertifikat.
   - Speichern Sie das folgende Skript als `Renew-NDES-EnrollmentAgent.ps1` (ersetzen Sie `<THUMBPRINT>` und `<DOMAIN>\<CA-NAME>`):
     ```powershell
     # Renew-NDES-EnrollmentAgent.ps1
     param([string]$Thumbprint = "<THUMBPRINT>", [string]$CAConfig = "<DOMAIN>\<CA-NAME>")

     # Extrahiere Subject
     $Cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $Thumbprint }
     $Subject = $Cert.Subject

     # Erstelle INF-Datei
     $InfContent = @"
     [Version]
     Signature="$Windows NT$"
     [NewRequest]
     Subject = "$Subject"
     Exportable = TRUE
     KeyLength = 2048
     KeySpec = 2
     KeyUsage = 0x80
     MachineKeySet = TRUE
     ProviderName = "Microsoft Enhanced Cryptographic Provider v1.0"
     ProviderType = 1
     [EnhancedKeyUsageExtension]
     OID = 1.3.6.1.4.1.311.20.2.1
     [RequestAttributes]
     CertificateTemplate = EnrollmentAgentOffline
     "@
     $InfContent | Out-File -FilePath "C:\Temp\EEARequest.inf" -Encoding ASCII

     # Führe Renewal aus
     Set-Location C:\Temp
     certreq.exe -f -new EEARequest.inf EEARequest.req
     certreq.exe -submit -config $CAConfig EEARequest.req EEARequest.cer
     certreq.exe -accept EEARequest.cer

     # IIS Reset
     iisreset /restart

     Write-Output "Renewal abgeschlossen. Neues Zertifikat: $($Cert.Thumbprint)"
     ```
   - Testen Sie: `.\Renew-NDES-EnrollmentAgent.ps1 -Thumbprint "ABC123..." -CAConfig "CONTOSO\MyCA"`.

3. **Schritt 3**: Automatisieren mit Scheduled Task.
   - Führen Sie aus (ersetzen Sie Pfade):
     ```powershell
     $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Scripts\Renew-NDES-EnrollmentAgent.ps1 -Thumbprint 'ABC123...' -CAConfig 'CONTOSO\MyCA'"
     $Trigger = New-ScheduledTaskTrigger -At 2025-09-17T02:00:00 -Once  # Oder wöchentlich: -Weekly -DaysOfWeek Monday
     Register-ScheduledTask -TaskName "NDES-Renewal" -Action $Action -Trigger $Trigger -Description "Automatisches NDES-Renewal"
     ```

4. **Schritt 4**: Validieren.
   - Überprüfen Sie im Event Viewer (CertificateServices-Deployment) auf Erfolge.

**Reflexion**: Warum ist das Extrahieren des Subjects vor dem Renewal entscheidend, und wie minimiert die Automatisierung manuelle Fehler?

### Übung 2: Client-Zertifikate via SCEP mit PSCertificateEnrollment erneuern
**Ziel**: Nutzen Sie das PSCertificateEnrollment-Modul, um SCEP-Zertifikate auf Geräten automatisch zu erneuern, integriert mit Intune.

1. **Schritt 1**: Installieren und importieren Sie das Modul.
   - Führen Sie aus:
     ```powershell
     Install-Module -Name PSCertificateEnrollment -Force -Scope CurrentUser
     Import-Module PSCertificateEnrollment
     ```

2. **Schritt 2**: Erstellen Sie ein Renewal-Skript für SCEP-Zertifikate.
   - Speichern Sie als `Renew-SCEP-Certificate.ps1` (ersetzen Sie NDES-URL und Thumbprint):
     ```powershell
     # Renew-SCEP-Certificate.ps1
     param([string]$NDESServer = "ndes-server.contoso.com", [string]$Thumbprint = "85CF977C7E32CE808E9D92C61FDB9A43437DC4A2")

     # Lade existierendes Zertifikat für Renewal
     $ExistingCert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Thumbprint -eq $Thumbprint }

     # Erneuere via SCEP (Renewal-Modus)
     $NewCert = $ExistingCert | Get-SCEPCertificate -ComputerName $NDESServer

     if ($NewCert) {
         Write-Output "Erneuertes Zertifikat: $($NewCert.Thumbprint) - Gültig bis: $($NewCert.NotAfter)"
         # Optional: Exportiere als PFX für Intune-Backup
         $Password = ConvertTo-SecureString -String "SecurePass123!" -AsPlainText -Force
         $NewCert | Export-PfxCertificate -FilePath "C:\Temp\RenewedCert.pfx" -Password $Password
     } else {
         Write-Error "Renewal fehlgeschlagen."
     }
     ```
   - Testen Sie: `.\Renew-SCEP-Certificate.ps1 -NDESServer "ndes.contoso.com" -Thumbprint "85CF977C..."`.

3. **Schritt 3**: Integrieren in Intune (als PowerShell-Skript-Deployment).
   - In Intune: **Devices > Scripts > Add > Windows 10 and later**.
   - Laden Sie `Renew-SCEP-Certificate.ps1` hoch, setzen Sie Run as: System, und weisen Sie einer Gruppe zu.
   - Für Automatisierung: Erstellen Sie einen Proactive Remediation Script in Intune, der das Skript bei Ablauf (< 30 Tage) ausführt.

4. **Schritt 4**: Testen auf einem Gerät.
   - Sync das Gerät in Intune und prüfen Sie: `Get-ChildItem Cert:\CurrentUser\My | Select Thumbprint, NotAfter`.

**Reflexion**: Wie ermöglicht Get-SCEPCertificate nahtloses Renewal ohne manuelle Anfragen, und welche Rolle spielt Intune bei der Skript-Verteilung?

## Tipps für den Erfolg
- **Sicherheit**: Verschlüsseln Sie Passwörter in Skripten mit `ConvertTo-SecureString` und speichern Sie sie in Azure Key Vault für Produktion.
- **Logging**: Fügen Sie `Start-Transcript -Path C:\Logs\Renewal.log` zu Skripten hinzu, um Ausführungen zu protokollieren.
- **Fehlerbehandlung**: Wrapen Sie certreq-Aufrufe in Try-Catch-Blöcke, z. B. `try { certreq.exe ... } catch { Write-Error $_.Exception.Message }`.
- **Häufigkeit**: Planen Sie Tasks monatlich, aber triggern Sie bei Events (z. B. via Certificate Lifecycle Notifications).
- **Alternative**: Für Cloud-PKI nutzen Sie Intune's integrierte Renewal; vermeiden Sie on-premises NDES wo möglich.

## Fazit
In dieser Anleitung haben Sie gelernt, PowerShell-Skripte zu erstellen und zu automatisieren, um NDES-Service- und Client-Zertifikate zu erneuern – von certreq-basierten Prozessen bis hin zu SCEP-Modulen. Die Übungen bieten praktische Erfahrung mit Automatisierung in Intune-Umgebungen. Automatisiertes Renewal minimiert Ausfälle und stärkt die PKI-Sicherheit. Erweitern Sie dies auf Multi-Server-Setups oder benachrichtigungsbasierte Triggers!

**Nächste Schritte**:
- Integrieren Sie E-Mail-Benachrichtigungen via Send-MailMessage bei Fehlern.
- Testen Sie in einer Lab-Umgebung mit Expired-Zertifikaten.
- Erkunden Sie Azure Automation für cloudbasierte Ausführung.

**Quellen**:
- Microsoft Endpoint Manager: https://msendpointmgr.com/2020/06/15/how-to-renew-ndes-service-certificates-for-usage-with-microsoft-intune/
- PSCertificateEnrollment GitHub: https://github.com/Sleepw4lker/PSCertificateEnrollment
- CertificateNotificationTasks GitHub: https://github.com/Borgquite/CertificateNotificationTasks
- Microsoft Learn: https://learn.microsoft.com/en-us/windows-server/identity/ad-cs/network-device-enrollment-service