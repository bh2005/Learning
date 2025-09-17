# Praxisorientierte Anleitung: Sichere Konfiguration von NDES mit Microsoft Intune

## Einführung
Der **Network Device Enrollment Service (NDES)** ist ein kritischer Bestandteil der Enterprise-PKI, da er Zertifikatsanfragen über das **Simple Certificate Enrollment Protocol (SCEP)** verarbeitet, um Geräte (z. B. Windows, iOS, Android) mit Zertifikaten für Authentifizierungszwecke wie WiFi, VPN oder E-Mail-Verschlüsselung zu versorgen. In Kombination mit **Microsoft Intune** ermöglicht NDES eine skalierbare Zertifikatsverwaltung in hybriden Umgebungen. Eine unsichere Konfiguration kann jedoch schwerwiegende Sicherheitsrisiken wie unbefugten Zugriff oder Kompromittierung der Zertifizierungsstelle (CA) nach sich ziehen. Diese Anleitung konzentriert sich auf **Best Practices für die Sicherheit** von NDES, einschließlich des **Tiering-Modells**, spezifischer **Firewall-Regeln** und der **SSL/TLS-Bindung** für die NDES-Website. Ziel ist es, Administratoren und PKI-Spezialisten die Werkzeuge an die Hand zu geben, um NDES sicher in einer Intune-Umgebung zu betreiben.

**Voraussetzungen:**
- Windows Server 2019 oder höher mit NDES und AD CS installiert
- Active Directory Certificate Services (AD CS) mit einer Enterprise Issuing CA
- Intune Certificate Connector konfiguriert
- Administratorrechte auf dem NDES-Server
- Zugriff auf IIS Manager und PowerShell
- Grundkenntnisse in Netzwerksicherheit, PKI und TLS-Konfiguration
- Texteditor (z. B. VS Code) für Skripte

## Sichere NDES-Konfiguration

### Tiering-Modell: NDES in Tier 0
**Warum Tier 0?**
Das Tiering-Modell (z. B. Microsofts Active Directory Administrative Tier Model) unterteilt IT-Systeme in Sicherheitsstufen (Tier 0, 1, 2), um die Auswirkungen einer Kompromittierung zu minimieren. NDES sollte in **Tier 0** (höchste Sicherheitsstufe) platziert werden, da:
- **Sensible Zertifikate ausgestellt werden**: NDES agiert als Registration Authority (RA) und kommuniziert direkt mit der CA. Eine Kompromittierung könnte die Ausstellung gefälschter Zertifikate ermöglichen, die für Authentifizierung (z. B. WiFi, VPN) missbraucht werden könnten.
- **Hohe Berechtigungen des Service-Kontos**: Das NDES-Service-Konto benötigt oft Rechte wie "Issue and Manage Certificates", die bei Missbrauch zu einer Privilegieneskalation bis hin zu Domain-Admin-Rechten führen können.
- **Externe Exposition**: Wenn NDES über den Entra Application Proxy extern erreichbar ist (z. B. für Intune-Geräte im Internet), erhöht sich das Risiko von Angriffen wie Man-in-the-Middle oder Credential Harvesting.

**Best Practices für Tier 0**:
- **Isolierte Netzwerkzone**: Platzieren Sie den NDES-Server in einem dedizierten VLAN oder Netzwerksegment mit eingeschränktem Zugriff. Nur autorisierte Systeme (z. B. CA, Intune Certificate Connector) dürfen kommunizieren. Verwenden Sie eine Firewall mit Whitelisting.
- **Dedizierter Server**: Installieren Sie keine weiteren Rollen oder Dienste (z. B. File Server, DNS) auf dem NDES-Server, um die Angriffsfläche zu minimieren.
- **Server-Härtung**: Wenden Sie Microsofts Security Baseline für Windows Server an (via Security Compliance Toolkit). Deaktivieren Sie nicht benötigte Protokolle wie SMBv1 und veraltete TLS-Versionen (z. B. TLS 1.0/1.1).
- **Eingeschränktes Service-Konto**: Verwenden Sie ein dediziertes NDES-Service-Konto (z. B. `ndes-svc`) mit minimalen Rechten (nur "Issue and Manage Certificates" und "Log on as a service"). Überwachen Sie dieses Konto mit einem SIEM-System (z. B. Microsoft Sentinel).
- **Multi-Faktor-Authentifizierung (MFA)**: Administratoren, die auf Tier-0-Systeme zugreifen, sollten MFA über Entra ID verwenden.
- **Erweitertes Monitoring**: Aktivieren Sie Audit-Logs für AD CS (Event IDs 4886, 4887) und überwachen Sie NDES-Zugriffe in Echtzeit. Verwenden Sie `Event Viewer > Applications and Services Logs > Microsoft > Windows > CertificateServices-Deployment`.

**Reflexion**: Wie würde eine Kompromittierung von NDES die gesamte PKI gefährden, und warum ist die Isolation in Tier 0 effektiver als in Tier 1 oder 2?

### Firewall-Regeln
NDES erfordert spezifische Netzwerkports für die Kommunikation mit der CA, Active Directory, dem Intune Certificate Connector und anfragenden Geräten (z. B. über Intune). Eine restriktive Firewall-Konfiguration ist entscheidend, um unautorisierten Zugriff zu verhindern. Die folgende Tabelle listet die erforderlichen Ports:

| **Protokoll/Port** | **Quelle** | **Ziel** | **Zweck** | **Richtung** |
|--------------------|------------|----------|-----------|--------------|
| **TCP 443 (HTTPS)** | NDES-Server | Intune Certificate Connector, Entra Application Proxy, Geräte | SCEP-Anfragen und Intune-Kommunikation | Eingehend/Ausgehend |
| **TCP 445 (SMB)** | NDES-Server | CA-Server | Zertifikatsausstellung und -verwaltung | Ausgehend |
| **TCP 135 (RPC)** | NDES-Server | CA-Server | DCOM/RPC für CA-Kommunikation | Ausgehend |
| **TCP 49152-65535 (RPC Dynamic Ports)** | NDES-Server | CA-Server | Dynamische Ports für RPC (abhängig von Windows-Version) | Ausgehend |
| **TCP 389 (LDAP)** | NDES-Server | Domain Controller | Active Directory-Abfragen für Service-Konto | Ausgehend |
| **TCP 636 (LDAPS)** | NDES-Server | Domain Controller | Sichere AD-Abfragen (empfohlen) | Ausgehend |
| **TCP 80 (HTTP)** | NDES-Server | CA-Server | Zertifikats- und CRL-Download (optional, wenn HTTP verwendet) | Ausgehend |

**Best Practices für Firewall-Regeln**:
- **Whitelisting**: Erlauben Sie nur spezifische IP-Adressen oder Subnetze für eingehende Verbindungen zu NDES (z. B. Entra Application Proxy oder Intune-Geräte).
- **LDAPS bevorzugen**: Verwenden Sie TCP 636 (LDAPS) statt TCP 389 (LDAP) für sichere AD-Kommunikation.
- **Port-Minimierung**: Schließen Sie nicht benötigte Ports (z. B. SMB auf externen Schnittstellen) und deaktivieren Sie HTTP (TCP 80), wenn HTTPS ausreicht.
- **Logging**: Aktivieren Sie Firewall-Logs für eingehende/ausgehende Verbindungen, um Anomalien zu erkennen.

**PowerShell zur Überprüfung der Port-Erreichbarkeit**:
```powershell
Test-NetConnection -ComputerName ca.contoso.com -Port 445  # Testet CA-Verbindung
Test-NetConnection -ComputerName dc.contoso.com -Port 636  # Testet LDAPS
Test-NetConnection -ComputerName ndes.contoso.com -Port 443  # Testet NDES-URL
```

**Reflexion**: Warum ist Whitelisting effektiver als Blacklisting für NDES, und wie beeinflusst die Wahl zwischen LDAP und LDAPS die Sicherheit?

### SSL/TLS-Bindung für die NDES-Website
Standardmäßig verwendet die NDES-Website (gehostet in IIS) ein selbstsigniertes oder generisches IIS-Zertifikat, was ein Sicherheitsrisiko darstellt (z. B. fehlende Vertrauenskette oder schwache Konfiguration). Ein dediziertes TLS-Zertifikat mit starker Verschlüsselung (z. B. RSA 2048 oder ECDSA) erhöht die Sicherheit der SCEP-Kommunikation.

**Schritte zur Einrichtung eines dedizierten TLS-Zertifikats**:
1. **Zertifikat anfordern**:
   - Erstellen Sie ein Zertifikat mit dem Template `Web Server` in Ihrer CA:
     ```powershell
     $InfContent = @"
     [Version]
     Signature="$Windows NT$"
     [NewRequest]
     Subject = "CN=ndes.contoso.com"
     Exportable = TRUE
     KeyLength = 2048
     KeySpec = 1
     KeyUsage = 0xa0
     MachineKeySet = TRUE
     ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
     [EnhancedKeyUsageExtension]
     OID = 1.3.6.1.5.5.7.3.1  ; Server Authentication
     "@
     $InfContent | Out-File -FilePath "C:\Temp\TLSRequest.inf" -Encoding ASCII
     ```
   - Fordern Sie das Zertifikat an:
     ```powershell
     certreq.exe -new C:\Temp\TLSRequest.inf C:\Temp\TLSRequest.req
     certreq.exe -submit -config "CONTOSO\MyCA" C:\Temp\TLSRequest.req C:\Temp\TLSRequest.cer
     certreq.exe -accept C:\Temp\TLSRequest.cer
     ```

2. **Zertifikat in IIS binden**:
   - Öffnen Sie IIS Manager: `inetmgr`.
   - Navigieren Sie zu **Sites > Default Web Site > Bindings**.
   - Wählen Sie **https**, klicken Sie auf **Edit**, und wählen Sie das neue Zertifikat (Subject: `ndes.contoso.com`).
   - Alternativ via PowerShell:
     ```powershell
     $Cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Subject -eq "CN=ndes.contoso.com" }
     New-WebBinding -Name "Default Web Site" -IPAddress "*" -Port 443 -Protocol https
     New-Item -Path IIS:\SslBindings\0.0.0.0!443 -Value $Cert
     ```

3. **TLS-Einstellungen härten**:
   - Deaktivieren Sie schwache Protokolle (TLS 1.0/1.1) und Ciphers:
     ```powershell
     New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server" -Force
     Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server" -Name "Enabled" -Value 0
     Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server" -Name "Enabled" -Value 0
     ```
   - Erzwingen Sie starke Ciphers (z. B. AES-256-GCM):
     ```powershell
     Disable-TlsCipherSuite -Name "TLS_RSA_WITH_3DES_EDE_CBC_SHA"
     Enable-TlsCipherSuite -Name "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
     ```

4. **Testen der Bindung**:
   - Öffnen Sie `https://ndes.contoso.com/certsrv/mscep/` im Browser und überprüfen Sie das Zertifikat.
   - Verwenden Sie `Test-NetConnection` oder Tools wie `openssl s_client`:
     ```powershell
     Test-NetConnection -ComputerName ndes.contoso.com -Port 443
     ```

**Best Practices für TLS-Bindung**:
- **SAN (Subject Alternative Name)**: Stellen Sie sicher, dass das Zertifikat den FQDN des NDES-Servers (z. B. `ndes.contoso.com`) im SAN-Feld enthält.
- **Lange Schlüssellänge**: Verwenden Sie mindestens 2048-Bit RSA oder ECDSA für höhere Sicherheit.
- **Automatisiertes Renewal**: Automatisieren Sie die Zertifikatserneuerung (siehe vorherige Anleitung), um Abläufe zu vermeiden.
- **HSTS (HTTP Strict Transport Security)**: Aktivieren Sie HSTS in IIS, um HTTP-Zugriffe zu verhindern:
  ```powershell
  Set-WebConfiguration -Location "Default Web Site" -Filter "system.webServer/httpRedirect" -Value @{enabled=$true;destination="https://ndes.contoso.com$1";exactDestination=$false;httpResponseStatus="Permanent"}
  ```

**Reflexion**: Warum ist ein dediziertes TLS-Zertifikat sicherer als ein selbstsigniertes Zertifikat, und wie beeinflusst die TLS-Version die Sicherheit der SCEP-Kommunikation?

## Tipps für den Erfolg
- **Sicherheit**: Platzieren Sie NDES in Tier 0 und verwenden Sie ein dediziertes Service-Konto mit minimalen Rechten. Überwachen Sie Zugriffe mit einem SIEM-System.
- **Firewall**: Nutzen Sie Whitelisting und LDAPS, um die Kommunikation abzusichern.
- **TLS-Härtung**: Deaktivieren Sie veraltete Protokolle (TLS 1.0/1.1) und schwache Ciphers. Verwenden Sie Tools wie Qualys SSL Labs, um die TLS-Konfiguration zu prüfen.
- **Logging**: Aktivieren Sie erweiterte AD CS-Logs und überwachen Sie NDES-Zugriffe in Echtzeit (Event Viewer: CertificateServices-Deployment).
- **Backup**: Sichern Sie das TLS-Zertifikat und die CA-Konfiguration regelmäßig.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie NDES sicher konfigurieren, indem Sie das Tiering-Modell (Tier 0), restriktive Firewall-Regeln und eine dedizierte SSL/TLS-Bindung implementieren. Diese Maßnahmen minimieren Sicherheitsrisiken und schützen die PKI-Umgebung in einer Intune-Integration. Durch die praktische Anwendung von PowerShell und Best Practices können Sie NDES robust und sicher betreiben.

**Nächste Schritte**:
- Testen Sie die NDES-Konfiguration mit Tools wie Qualys SSL Labs oder nmap.
- Automatisieren Sie die TLS-Zertifikatserneuerung mit PowerShell (siehe vorherige Anleitung).
- Integrieren Sie NDES-Logs in ein SIEM-System für Echtzeit-Überwachung.

**Quellen**:
- Microsoft Learn: https://learn.microsoft.com/en-us/windows-server/identity/ad-cs/network-device-enrollment-service
- Microsoft Security Baseline: https://learn.microsoft.com/en-us/windows/security/threat-protection/windows-security-baselines
- Microsoft Intune: https://learn.microsoft.com/en-us/mem/intune/protect/certificates-scep-configure
- SecureW2 NDES Guide: https://www.securew2.com/blog/ndes-scep-server-configuration