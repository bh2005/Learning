# Praxisorientierte Anleitung: NDES mit Microsoft Intune für Enterprise-PKI auf Windows

## Einführung
Der **Network Device Enrollment Service (NDES)** ist ein Role Service von Active Directory Certificate Services (AD CS) in Windows Server, der das **Simple Certificate Enrollment Protocol (SCEP)** implementiert. In Kombination mit **Microsoft Intune** ermöglicht NDES die sichere Ausstellung von Zertifikaten an verwaltete Geräte (z. B. Windows, iOS, Android) für Authentifizierungszwecke wie WiFi, VPN oder E-Mail-Verschlüsselung. NDES fungiert als Registration Authority (RA), die Zertifikatsanfragen an eine Zertifizierungsstelle (CA) weiterleitet, ohne dass Geräte Domänen-Anmeldeinformationen benötigen. Diese Anleitung führt Sie durch die Installation, Konfiguration und Integration von NDES mit Intune, einschließlich PowerShell-Automatisierung und Sicherheitsbest Practices. Ziel ist es, Administratoren und PKI-Spezialisten eine skalierbare Lösung für die Zertifikatsverwaltung in hybriden Umgebungen bereitzustellen.

**Voraussetzungen:**
- Windows Server 2019 oder höher mit Administratorrechten
- Active Directory Certificate Services (AD CS) mit einer Enterprise Issuing CA
- Microsoft Intune-Lizenz (Teil von Microsoft Endpoint Manager) und Entra ID P1/P2
- Dediziertes Service-Konto in Active Directory (z. B. `ndes-svc`)
- Mindestens 4 GB RAM und 10 GB freier Festplattenspeicher
- Grundlegende Kenntnisse in PowerShell, AD CS und Intune
- Texteditor (z. B. Notepad++ oder VS Code)
- Firewall-Regeln für Port 443 (HTTPS) für Intune-Kommunikation

## Grundlegende NDES- und Intune-Konzepte
Hier sind die wichtigsten Konzepte und Tools für die Integration von NDES mit Intune:

1. **NDES-Konzepte**:
   - **SCEP-Protokoll**: Standardprotokoll für Zertifikatsanfragen von Geräten ohne Domänenbeitritt (RFC 8894).
   - **Registration Authority (RA)**: NDES validiert Anfragen und leitet sie an die CA weiter.
   - **Intune Certificate Connector**: Verbindet die on-premises NDES-Infrastruktur mit Intune für die Zertifikatsverteilung.
   - **Sicherheitsaspekte**: NDES muss in einer sicheren Umgebung (Tier 0) betrieben werden, da es mit sensiblen Zertifikaten arbeitet.
2. **Wichtige Befehle**:
   - `certutil`: Verwaltet Zertifikate und CA-Einstellungen (z. B. `certutil -getreg CA\RoleSeparationEnabled`).
   - `Install-WindowsFeature`: Installiert NDES-Role Service.
   - `Get-ADUser`: Überprüft Service Accounts in Active Directory.
3. **Wichtige Konfigurationsdateien**:
   - `C:\Windows\System32\certsrv\mscep\mscep.dll`: NDES-Endpunkt.
   - Registry: `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography\MSCEP` für Template-Einstellungen.
4. **Intune-Komponenten**:
   - **Trusted Root Certificate Profile**: Verteilt das Root-CA-Zertifikat an Geräte.
   - **SCEP Certificate Profile**: Definiert Zertifikatsparameter und die NDES-URL.
   - **Entra Application Proxy** (optional): Ermöglicht externen Zugriff auf NDES.

## Übungen zum Verinnerlichen

### Übung 1: NDES installieren und initial konfigurieren
**Ziel**: Installieren Sie NDES als Role Service und richten Sie einen Service Account für Intune ein.

1. **Schritt 1**: Installiere AD CS und NDES.
   - Öffne Server Manager > Add Roles and Features > Wähle "Active Directory Certificate Services".
   - Wähle "Certification Authority" und "Network Device Enrollment Service" als Role Services.
   - Führe die Post-Installation aus:
     ```powershell
     certlm.msc
     ```
     Right-click CA > Properties > Configure.
2. **Schritt 2**: Erstelle einen dedizierten Service Account.
   - In Active Directory Users and Computers: New > User > Name: `NDESServiceAccount`, Password: Starkes Passwort (nicht ablaufend).
   - Füge den Account zur Gruppe "IIS_IUSRS" hinzu und gewähre Widerrufsrechte:
     ```powershell
     net localgroup IIS_IUSRS <domain>\NDESServiceAccount /Add
     ```
     ```powershell
     Get-ADUser NDESServiceAccount
     ```
3. **Schritt 3**: Konfiguriere NDES.
   - Öffne Server Manager > Tools > Certification Authority > Right-click CA > Properties > Policy Module > Configure NDES.
   - Gib den Service Account (`<domain>\NDESServiceAccount`) und ein Challenge-Password ein.
   - Konfiguriere die Registry für SCEP-Templates:
     ```powershell
     Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Cryptography\MSCEP" -Name "SignatureTemplate" -Value "NDESDeviceCert"
     Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Cryptography\MSCEP" -Name "EncryptionTemplate" -Value "NDESDeviceCert"
     ```
     Starte IIS neu:
     ```powershell
     iisreset
     ```
4. **Schritt 4**: Teste die NDES-URL.
   - Öffne `https://<server>/certsrv/mscep/` im Browser. Die Seite sollte die SCEP-Admin-Seite anzeigen.

**Reflexion**: Warum ist ein dedizierter Service Account für NDES sicherer, und wie schützt das Challenge-Password vor unbefugten Anfragen?

### Übung 2: Intune Certificate Connector einrichten
**Ziel**: Installieren und konfigurieren Sie den Intune Certificate Connector, um NDES mit Intune zu verbinden.

1. **Schritt 1**: Lade den Connector herunter.
   - Im Microsoft Intune Admin Center: **Tenant administration > Connectors and tokens > Certificate connectors > Add**.
   - Lade die Installationsdatei (`NDESConnectorSetup.exe`) herunter.
2. **Schritt 2**: Installiere den Connector.
   - Führe die Installation auf dem NDES-Server aus:
     ```powershell
     .\NDESConnectorSetup.exe
     ```
   - Melde dich mit einem Intune-Admin-Konto an (Global Admin oder Intune Service Admin).
   - Wähle **SCEP** und **Certificate Revocation** als Funktionen.
   - Gib das NDES-Service-Konto (`<domain>\NDESServiceAccount`) an.
3. **Schritt 3**: Konfiguriere den Entra Application Proxy (optional für externe Geräte).
   - Installiere den Entra Connector auf einem separaten Server.
   - Veröffentliche die NDES-URL (z. B. `https://ndes-app.msappproxy.net`) mit Passthrough-Authentifizierung.
   - Teste die externe Erreichbarkeit:
     ```powershell
     Test-NetConnection -ComputerName ndes-app.msappproxy.net -Port 443
     ```
4. **Schritt 4**: Überprüfe die Connector-Logs.
   - Öffne Event Viewer: `Applications and Services Logs > Microsoft > Intune > NDESConnector`.
   - Prüfe auf Fehler bei der Verbindung zu Intune.

**Reflexion**: Wie stellt der Intune Certificate Connector die sichere Kommunikation zwischen NDES und Intune sicher?

### Übung 3: SCEP-Zertifikat-Profile in Intune erstellen und testen
**Ziel**: Erstellen Sie Zertifikat-Profile in Intune und testen Sie die Zertifikatsausstellung an ein Gerät.

1. **Schritt 1**: Erstelle ein Trusted Root Certificate Profile.
   - In Intune: **Devices > Configuration profiles > Create profile > Trusted certificate**.
   - Lade das Root-CA-Zertifikat (`.cer`) hoch.
   - Weise das Profil einer Test-Gruppe zu (z. B. `TestDevices`).
2. **Schritt 2**: Erstelle ein SCEP Certificate Profile.
   - In Intune: **Devices > Configuration profiles > Create profile > SCEP certificate**.
   - Konfiguriere:
     - **Certificate type**: Device.
     - **Subject name format**: `CN={{DeviceName}}`.
     - **NDES-URL**: `https://ndes-app.msappproxy.net/certsrv/mscep/`.
     - **Subject alternative name**: `DNS Name={{DeviceName}}`.
     - **Key usage**: Digital Signature, Key Encipherment.
     - **Key size**: 2048.
   - Weise das Profil derselben Test-Gruppe zu.
3. **Schritt 3**: Teste das Enrollment.
   - Synchronisiere ein Testgerät in Intune.
   - Überprüfe das Zertifikat im Geräte-Zertifikat-Store:
     ```powershell
     Get-ChildItem Cert:\LocalMachine\My
     ```
4. **Schritt 4**: Automatisiere die Überprüfung mit PowerShell.
   - Prüfe die NDES-Konfiguration:
     ```powershell
     $url = "https://<server>/certsrv/mscep/?operation=GetCACert"
     Invoke-WebRequest -Uri $url -OutFile ca.crt
     certutil -dump ca.crt
     ```

**Reflexion**: Wie vereinfacht Intune die Verteilung von Zertifikaten, und welche Rolle spielt die NDES-URL?

## Tipps für den Erfolg
- **Sicherheit**: Betreibe NDES in einer Tier-0-Umgebung und beschränke die Rechte des Service Accounts.
- **Logging**: Überwache NDES-Logs (`Event Viewer > Applications and Services Logs > Microsoft > Windows > CertificateServices-Deployment`) und Intune-Logs.
- **Firewall**: Stelle sicher, dass Port 443 für Intune und NDES geöffnet ist.
- **Alternative**: Erwäge **Microsoft Cloud PKI** für eine cloudbasierte Lösung ohne on-premises NDES.
- **Backup**: Sichere CA-Zertifikate und NDES-Konfigurationen regelmäßig.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie NDES auf Windows Server einrichten, den Intune Certificate Connector konfigurieren und SCEP-Zertifikat-Profile in Intune erstellen. Die Übungen vermitteln praktische Erfahrung mit SCEP, AD CS und Intune-Integration. NDES mit Intune ist essenziell für die sichere Zertifikatsverwaltung in hybriden Umgebungen. Üben Sie weiter, um Szenarien wie Multi-Geräte-Enrollment oder erweiterte Sicherheitskonfigurationen zu meistern!

**Nächste Schritte**:
- Integrieren Sie NDES mit anderen MDM-Lösungen wie JAMF.
- Erkunden Sie Sicherheitsbest Practices (z. B. Entra Application Proxy und Tiering).
- Automatisieren Sie Zertifikats-Renewal mit PowerShell.

**Quellen**:
- Microsoft Learn: https://learn.microsoft.com/en-us/mem/intune/protect/certificates-scep-configure
- Microsoft Docs: https://learn.microsoft.com/en-us/windows-server/identity/ad-cs/network-device-enrollment-service
- TechCommunity: https://techcommunity.microsoft.com/t5/microsoft-intune/ndes-and-intune-deployment-guide/ba-p/123456
- SecureW2: https://www.securew2.com/blog/ndes-scep-server-configuration