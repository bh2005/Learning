# Praxisorientierte Anleitung: OpenSSL-Features auf Windows Server – Erstellung von Zertifikaten für TLS

## Einführung
OpenSSL ist ein leistungsstarkes Open-Source-Tool für kryptographische Operationen, das auch auf Windows Server verfügbar ist und die Erstellung von TLS-Zertifikaten ermöglicht. Auf Windows Server kann OpenSSL verwendet werden, um selbstsignierte Zertifikate, Certificate Signing Requests (CSRs) oder vollständige PKI-Strukturen (z. B. mit einer eigenen CA) zu generieren. Diese Anleitung führt Sie durch die Installation von OpenSSL auf Windows Server, die Erstellung von TLS-Zertifikaten (einschließlich privater Schlüssel, CSRs und selbstsignierter Zertifikate) und deren Integration in IIS (Internet Information Services). Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, TLS-Zertifikate für sichere Kommunikation (z. B. HTTPS) auf Windows Server einzurichten. Diese Anleitung ist ideal für Windows-Administratoren und Entwickler, die OpenSSL-Features in einer Windows-Umgebung nutzen möchten.

Voraussetzungen:
- Windows Server 2019 oder höher mit Administratorrechten
- Mindestens 2 GB RAM und ausreichend Festplattenspeicher (mindestens 5 GB frei)
- Grundlegende Kenntnisse der Windows-Kommandozeile (PowerShell oder CMD)
- Ein Texteditor (z. B. Notepad++ oder VS Code)
- Optional: IIS installiert für die Integration (über Server Manager > Add Roles and Features)

## Grundlegende OpenSSL-Konzepte und Befehle auf Windows
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **OpenSSL-Konzepte auf Windows**:
   - **Private Schlüssel**: RSA- oder ECDSA-Schlüssel (z. B. 2048-Bit RSA)
   - **CSR (Certificate Signing Request)**: Anfrage an eine CA (z. B. Let's Encrypt oder interne CA)
   - **Selbstsigniertes Zertifikat**: Für Tests; nicht für Produktion geeignet
   - **X.509-Format**: Standard für TLS-Zertifikate (PEM oder PFX für Windows)
2. **Wichtige OpenSSL-Befehle**:
   - `openssl genrsa`: Generiert einen privaten RSA-Schlüssel
   - `openssl req`: Erstellt CSRs oder selbstsignierte Zertifikate
   - `openssl x509`: Signiert Zertifikate
   - `openssl pkcs12`: Konvertiert zu PFX für Windows
3. **Windows-spezifische Tools**:
   - PowerShell: Für Automatisierung
   - IIS Manager: Für Zertifikat-Import und Binding

## Übungen zum Verinnerlichen

### Übung 1: OpenSSL auf Windows Server installieren
**Ziel**: Lernen, wie man OpenSSL auf Windows Server installiert und testet.

1. **Schritt 1**: Lade OpenSSL herunter.
   - Gehe zu [slproweb.com/products/Win32OpenSSL.html](https://slproweb.com/products/Win32OpenSSL.html) und lade die Win64 OpenSSL v3.x.x Installer (z. B. Win64 OpenSSL v3.0.14) herunter.
   - Führe den Installer als Administrator aus und wähle "The Windows system directory" für die Installation (z. B. `C:\Program Files\OpenSSL-Win64`).
2. **Schritt 2**: Füge OpenSSL zum PATH hinzu.
   - Öffne Systemeigenschaften > Erweiterte Systemeinstellungen > Umgebungsvariablen.
   - Füge `C:\Program Files\OpenSSL-Win64\bin` zum PATH hinzu.
   - Öffne eine neue PowerShell als Administrator und teste:
     ```powershell
     openssl version
     ```
     Die Ausgabe sollte die Version anzeigen (z. B. `OpenSSL 3.0.14`).
3. **Schritt 3**: Erstelle ein Testverzeichnis.
   ```powershell
   mkdir C:\openssl-certs
   cd C:\openssl-certs
   ```

**Reflexion**: Warum ist die PATH-Konfiguration entscheidend, und wie unterscheidet sich die Installation von OpenSSL auf Windows von Linux (apt vs. Installer)?

### Übung 2: Privaten Schlüssel und CSR erstellen
**Ziel**: Verstehen, wie man einen privaten Schlüssel und eine CSR mit OpenSSL auf Windows generiert.

1. **Schritt 1**: Generiere einen privaten RSA-Schlüssel.
   ```powershell
   openssl genrsa -out myserver.key 2048
   ```
   Dies erstellt `myserver.key` (2048-Bit RSA, ohne Passphrase).
2. **Schritt 2**: Erstelle eine CSR.
   ```powershell
   openssl req -new -key myserver.key -out myserver.csr
   ```
   - Gib Details ein:
     - Country Name: `DE`
     - State or Province: `State`
     - Locality: `City`
     - Organization: `MyOrg`
     - Common Name: `myserver.example.com` (FQDN des Servers)
     - Andere Felder können leer bleiben.
3. **Schritt 3**: Überprüfe die CSR.
   ```powershell
   openssl req -in myserver.csr -text -noout
   ```
   Die Ausgabe zeigt die CSR-Details, einschließlich des Common Names.

**Reflexion**: Warum ist der Common Name (CN) entscheidend für TLS, und wie kann man die CSR an eine CA (z. B. Let's Encrypt) senden?

### Übung 3: Selbstsigniertes Zertifikat erstellen und in IIS integrieren
**Ziel**: Lernen, wie man ein selbstsigniertes Zertifikat erstellt und in IIS für HTTPS bindet.

1. **Schritt 1**: Erstelle ein selbstsigniertes Zertifikat.
   ```powershell
   openssl req -x509 -new -nodes -key myserver.key -sha256 -days 365 -out myserver.crt
   ```
   - Verwende die gleichen Details wie bei der CSR.
2. **Schritt 2**: Konvertiere zu PFX für Windows.
   ```powershell
   openssl pkcs12 -export -out myserver.pfx -inkey myserver.key -in myserver.crt
   ```
   - Gib ein Export-Passwort ein (z. B. `password`).
3. **Schritt 3**: Importiere das Zertifikat in Windows.
   - Öffne MMC (Microsoft Management Console): `Win + R` > `mmc` > Hinzufügen/Snap-ins > Certificates > Computer Account > Local Computer.
   - Navigiere zu Personal > Certificates > Rechtsklick > All Tasks > Import > Wähle `myserver.pfx` und gib das Passwort ein.
4. **Schritt 4**: Binde das Zertifikat in IIS.
   - Öffne IIS Manager > Sites > Default Web Site > Bindings > Add > Type: HTTPS > Wähle das Zertifikat > Port: 443.
   - Starte die Site neu und teste: Öffne `https://localhost` (akzeptiere Warnung für selbstsigniertes Zertifikat).

**Reflexion**: Warum ist die PFX-Konvertierung für Windows notwendig, und wie kann man das Zertifikat in der Certificate Store überprüfen?

## Tipps für den Erfolg
- Führe OpenSSL in PowerShell als Administrator aus, um Berechtigungsprobleme zu vermeiden.
- Sichere private Schlüssel (`myserver.key`) und PFX-Dateien (mit starkem Passwort).
- Verwende `openssl x509 -in myserver.crt -text -noout` zur Überprüfung.
- Für Produktion: Verwenden Sie Let's Encrypt mit win-acme statt selbstsignierter Zertifikate.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie OpenSSL-Features auf Windows Server nutzen, um TLS-Zertifikate zu erstellen, einschließlich privater Schlüssel, CSRs und selbstsignierter Zertifikate, sowie deren Integration in IIS. Durch die Übungen haben Sie praktische Erfahrung mit der Windows-spezifischen Handhabung (PFX, Certificate Store) gesammelt. Diese Fähigkeiten sind essenziell für die Absicherung von Windows-basierten Webanwendungen. Üben Sie weiter, um Szenarien wie CSR-Submission an externe CAs oder Automatisierung mit PowerShell zu meistern!

**Nächste Schritte**:
- Automatisieren Sie die Zertifikatserstellung mit PowerShell und win-acme.
- Erkunden Sie NDES für Enterprise-PKI auf Windows.
- Integrieren Sie Zertifikate in ASP.NET-Anwendungen.

**Quellen**:
- Offizielle OpenSSL-Dokumentation: https://www.openssl.org/docs/
- Stack Overflow: https://stackoverflow.com/questions/2355568/create-a-openssl-certificate-on-windows
- Veeble Hosting: https://www.veeble.com/kb/generate-self-signed-certificate-with-openssl-windows-linux/
- Namecheap: https://www.namecheap.com/support/knowledgebase/article.aspx/10161/2290/generating-a-csr-on-windows-using-openssl/
- C# Corner: https://www.c-sharpcorner.com/article/creating-certificate-using-openssl-on-windows-for-ssltls-communication2/
- Teramind KB: https://kb.teramind.co/en/articles/8791235-how-to-generate-your-own-self-signed-ssl-certificates-for-use-with-an-on-premise-deployments
- DigiCert: https://knowledge.digicert.com/solution/generate-a-certificate-signing-request-using-openssl-on-microsoft-windows-system
- Microsoft Learn: https://learn.microsoft.com/en-us/azure/application-gateway/self-signed-certificates
- Devolutions Blog: https://blog.devolutions.net/2020/07/tutorial-how-to-generate-secure-self-signed-server-and-client-certificates-with-openssl/
- SocketTools: https://sockettools.com/kb/creating-certificate-using-openssl/
- SSL.com: https://www.ssl.com/how-to/manually-generate-a-certificate-signing-request-csr-using-openssl/