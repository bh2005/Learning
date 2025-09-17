# Praxisorientierte Anleitung: Erkundung von NDES für Enterprise-PKI auf Windows

## Einführung
Der Network Device Enrollment Service (NDES) ist ein Role Service von Active Directory Certificate Services (AD CS) in Windows Server, der das Simple Certificate Enrollment Protocol (SCEP) implementiert. NDES ermöglicht es Netzwerkgeräten (z. B. Router, Switches oder IoT-Geräte), die keine Domain-Credentials besitzen, Zertifikate von einer Enterprise-PKI zu erhalten. Es fungiert als Registration Authority (RA), die Anfragen an die Zertifizierungsstelle (CA) weiterleitet und Zertifikate für Authentifizierung (z. B. IPsec, VPN oder 802.1X) ausstellt. NDES ist seit Windows Server 2008 R2 verfügbar und spielt eine Schlüsselrolle in Enterprise-PKI-Umgebungen. Diese Anleitung führt Sie durch die Installation, Konfiguration und Nutzung von NDES auf Windows Server, einschließlich Sicherheitsbest Practices und Automatisierung mit PowerShell. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, NDES für sichere Geräte-Authentifizierung in einer Enterprise-PKI einzusetzen. Diese Anleitung ist ideal für Windows-Administratoren und PKI-Spezialisten, die skalierbare Zertifikatsverwaltung implementieren möchten.

**Voraussetzungen:**
- Windows Server 2019 oder höher mit Administratorrechten
- Active Directory Certificate Services (AD CS) installiert und konfiguriert (Enterprise CA)
- Mindestens 4 GB RAM und ausreichend Festplattenspeicher (mindestens 10 GB frei)
- Grundlegende Kenntnisse der Windows-Kommandozeile (PowerShell oder CMD) und AD CS
- Ein Texteditor (z. B. Notepad++ oder VS Code)

## Grundlegende NDES-Konzepte und Befehle
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **NDES-Konzepte**:
   - **SCEP-Protokoll**: Einfaches Protokoll für Zertifikatsanfragen von Geräten ohne Domain-Join (RFC 8894)
   - **Registration Authority (RA)**: NDES leitet Anfragen an die CA weiter und stellt sicher, dass Geräte Zertifikate erhalten
   - **Enterprise-PKI**: NDES integriert sich in AD CS, um Zertifikate für IPsec, VPN oder 802.1X auszugeben
   - **Sicherheitsaspekte**: NDES muss in Tier 0 (hochprivilegiert) platziert werden, da es potenziell Domain-Admin-Rechte ermöglichen kann
2. **Wichtige Befehle**:
   - `certutil`: Verwaltet Zertifikate und Templates (z. B. `certutil -getreg CA\RoleSeparationEnabled`)
   - `Install-WindowsFeature`: Installiert NDES-Role Service
   - `Get-ADUser`: Überprüft Service Accounts in Active Directory
3. **Wichtige Konfigurationsdateien**:
   - `C:\Windows\System32\certsrv\mscep\mscep.dll`: NDES-Konfiguration
   - Registry: `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography\MSCEP` für Einstellungen

## Übungen zum Verinnerlichen

### Übung 1: NDES installieren und initial konfigurieren
**Ziel**: Lernen, wie man NDES als Role Service in AD CS installiert und einen Service Account einrichtet.

1. **Schritt 1**: Installiere AD CS, falls nicht vorhanden.
   - Öffne Server Manager > Add Roles and Features > Wähle "Active Directory Certificate Services".
   - Wähle "Certification Authority" und "Network Device Enrollment Service" als Role Services.
   - Führe die Post-Installation aus:
     ```powershell
     certlm.msc
     ```
     Right-click CA > Properties > Configure.
2. **Schritt 2**: Erstelle einen dedizierten Service Account.
   - In Active Directory Users and Computers: New > User > Name: `NDESServiceAccount`, Password: Starkes Passwort (nicht ablaufend).
   - Füge den Account zur Gruppe "IIS_IUSRS" hinzu:
     ```powershell
     net localgroup IIS_IUSRS <domain>\NDESServiceAccount /Add
     ```
   - Überprüfe mit PowerShell:
     ```powershell
     Get-ADUser NDESServiceAccount
     ```
3. **Schritt 3**: Konfiguriere NDES.
   - Öffne Server Manager > Tools > Certification Authority > Right-click CA > Properties > Policy Module > Configure NDES.
   - Gib den Service Account (`<domain>\NDESServiceAccount`) und ein Challenge-Password ein (für Geräte-Authentifizierung).
   - Überprüfe die Registry:
     ```powershell
     certutil -getreg CA\RoleSeparationEnabled
     ```
     Stelle sicher, dass Role Separation deaktiviert ist (`0`), um NDES zu ermöglichen.
4. **Schritt 4**: Teste die NDES-URL.
   - Öffne `https://<server>/certsrv/mscep/` im Browser. Die Seite sollte die SCEP-Admin-Seite anzeigen.

**Reflexion**: Warum ist ein dedizierter Service Account für NDES sicherer, und wie verhindert das Challenge-Password unbefugte Anfragen?

### Übung 2: Zertifikat-Template für NDES konfigurieren
**Ziel**: Verstehen, wie man ein Certificate Template für NDES anpasst, um Geräte-Zertifikate auszugeben.

1. **Schritt 1**: Öffne Certificate Templates Console.
   - Starte:
     ```powershell
     certtmpl.msc
     ```
   - Right-click "Certificate Templates" > Manage.
   - Kopiere das "IPSEC (Offline request)" Template: Right-click > Duplicate Template > Compatibility: Windows Server 2016 > General > Name: `NDESDeviceCert`.
2. **Schritt 2**: Konfiguriere das Template.
   - **General**: Validity: 1 Year, Publish to AD: Enabled.
   - **Request Handling**: Allow private key to be exported: Enabled (für Geräte).
   - **Subject Name**: Supply in the request: Enabled (Geräte liefern SAN/UPN).
   - **Security**: Grant "Read" und "Enroll" für `NDESServiceAccount`.
   - Speichern und schließen.
3. **Schritt 3**: Veröffentliche das Template.
   - In CA Console (`certsrv.msc`): Right-click Certificate Templates > New > Certificate Template to Issue > Wähle `NDESDeviceCert`.
4. **Schritt 4**: Teste mit einem Gerät-Simulator.
   - Hole das CA-Zertifikat:
     ```powershell
     $url = "https://<server>/certsrv/mscep/?operation=GetCACert"
     Invoke-WebRequest -Uri $url -OutFile ca.crt
     ```
   - Überprüfe das CA-Zertifikat:
     ```powershell
     certutil -dump ca.crt
     ```

**Reflexion**: Wie ermöglicht das Template die Flexibilität für Geräte-Anfragen, und warum ist "Export private key" für NDES kritisch?

### Übung 3: NDES für Geräte-Enrollment automatisieren
**Ziel**: Lernen, wie man NDES für ein Gerät (z. B. Cisco-Router-Simulation) konfiguriert und PowerShell für automatisches Enrollment nutzt.

1. **Schritt 1**: Konfiguriere NDES-URL und Password.
   - In NDES-Properties (via CA Console): Setze das Challenge-Password (z. B. `MySCEPPassword`).
   - Die Enrollment-URL ist `http://<server>/certsrv/mscep/mscep.dll`.
2. **Schritt 2**: Simuliere Enrollment mit PowerShell (SCEP-Client).
   - Installiere das `PSCertificateEnrollment`-Modul:
     ```powershell
     Install-Module -Name PSCertificateEnrollment -Force
     ```
   - Führe Enrollment aus:
     ```powershell
     $ScepUrl = "http://<server>/certsrv/mscep/?operation=PKIOperation"
     $Template = "NDESDeviceCert"
     $ChallengePassword = "MySCEPPassword"
     $CertRequest = New-CertificateRequest -Subject "CN=TestDevice" -KeyLength 2048 -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider"
     $Cert = Submit-ScepCertificateRequest -Url $ScepUrl -CertificateRequest $CertRequest -ChallengePassword $ChallengePassword -Template $Template
     Write-Output "Zertifikat erhalten: $($Cert.Thumbprint)"
     ```
3. **Schritt 3**: Überprüfe und exportiere das Zertifikat.
   - Überprüfe in der Certificate Store:
     ```powershell
     Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -like "*TestDevice*"}
     ```
   - Exportiere als PFX für Geräte:
     ```powershell
     $Cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Thumbprint -eq "<Thumbprint>"}
     $Cert.Export([Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, "password") | Set-Content -Path "C:\cert-rotation\TestDevice.pfx" -Encoding Byte
     ```
4. **Schritt 4**: Teste die Integration.
   - Importiere `TestDevice.pfx` in IIS oder ein Gerät (z. B. für IPsec).
   - Teste mit `https://<server>` (bei IIS-Binding).

**Reflexion**: Wie integriert NDES SCEP in Enterprise-PKI, und welche Sicherheitsrisiken birgt es, wenn nicht richtig konfiguriert?

## Tipps für den Erfolg
- **Sicherheit**: Platziere NDES in Tier 0 (hochprivilegiert) und verwende einen dedizierten Service Account mit eingeschränkten Rechten.
- **Logging**: Überprüfe Logs in Event Viewer > Applications and Services Logs > Microsoft > Windows > CertificateServices-Deployment.
- **Role Separation**: Deaktiviere Role Separation (`certutil -setreg CA\RoleSeparationEnabled 0`) für NDES, aber überprüfe Sicherheitsimplikationen.
- **Produktion**: Verwende NDES mit Microsoft Intune oder JAMF für Geräte-Management und sichere Challenge-Passwords.
- **Backup**: Sichere CA-Zertifikate und NDES-Konfigurationen regelmäßig.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie NDES für Enterprise-PKI auf Windows Server einrichten, Zertifikat-Templates konfigurieren und Geräte-Enrollment mit PowerShell automatisieren. Durch die Übungen haben Sie praktische Erfahrung mit SCEP, AD CS und Geräte-Integration gesammelt. NDES ist essenziell für die sichere Authentifizierung von Netzwerkgeräten in Windows-Umgebungen. Üben Sie weiter, um Szenarien wie Intune-Integration oder Multi-CA-Setups zu meistern!

**Nächste Schritte**:
- Integrieren Sie NDES mit Microsoft Intune für mobile Geräte.
- Erkunden Sie NDES-Sicherheitsbest Practices (z. B. Tiering und Firewall-Regeln).
- Automatisieren Sie Enrollment für mehrere Geräte mit PowerShell-Skripten.

**Quellen**:
- Microsoft Learn: https://learn.microsoft.com/en-us/windows-server/identity/ad-cs/network-device-enrollment-service
- Microsoft Docs: https://learn.microsoft.com/en-us/windows/security/identity-protection/network-device-enrollment-service
- TechTarget: https://www.techtarget.com/searchwindowsserver/definition/Network-Device-Enrollment-Service-NDES
- Encryption Consulting: https://www.encryptionconsulting.com/education/network-device-enrollment-service-ndes/
- SecureW2: https://www.securew2.com/blog/ndes-scep-server-configuration
- Microsoft Community Hub: https://techcommunity.microsoft.com/t5/windows-server/ndes-deployment-and-configuration/ba-p/123456
- Neoconsulting: https://www.neoconsulting.com/ndes-deployment-guide
- Uwe Gradenegger: https://www.gradenegger.eu/en/ndes-deployment/
- PeteNetLive: https://www.petenetlive.com/KB/Article/0001234