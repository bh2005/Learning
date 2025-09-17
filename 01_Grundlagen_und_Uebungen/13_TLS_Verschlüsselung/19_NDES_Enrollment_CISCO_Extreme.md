# Praxisorientierte Anleitung: NDES-Enrollment mit einem echten Client für Microsoft Intune

## Einführung
Der **Network Device Enrollment Service (NDES)** ermöglicht die Ausstellung von Zertifikaten über das **Simple Certificate Enrollment Protocol (SCEP)** an Geräte, die keine Domänen-Anmeldeinformationen besitzen, wie Netzwerkgeräte (z. B. Router, Switches) oder Software-Clients. In Kombination mit **Microsoft Intune** wird NDES verwendet, um Zertifikate sicher an verwaltete Geräte zu verteilen, z. B. für WiFi- oder VPN-Authentifizierung. Diese Anleitung ergänzt die vorherigen Abschnitte zur Einrichtung, Automatisierung und sicheren Konfiguration von NDES, indem sie einen praktischen Anwendungsfall für das Zertifikats-Enrollment mit einem echten Gerät – hier ein **Cisco-Router** – demonstriert. Ziel ist es, Administratoren zu zeigen, wie die NDES-Integration in der Praxis mit einem Netzwerkgerät umgesetzt wird, inklusive der Konfiguration des Geräts und der Validierung in Intune.

**Voraussetzungen:**
- Windows Server 2019 oder höher mit NDES und AD CS installiert
- Intune Certificate Connector konfiguriert
- Cisco-Router (z. B. Cisco ISR mit IOS 15.x oder höher) mit CLI-Zugriff
- NDES-URL extern erreichbar (z. B. via Entra Application Proxy: `https://ndes.contoso.com/certsrv/mscep/`)
- Root-CA-Zertifikat (`.cer`) exportiert und verfügbar
- SCEP-Zertifikat-Profil in Intune erstellt (siehe vorherige Anleitungen)
- Grundkenntnisse in Cisco IOS CLI und PKI
- Texteditor (z. B. VS Code) für Konfigurationsdateien

## Grundlegende Konzepte
Hier sind die Kernkonzepte für das NDES-Enrollment mit einem Cisco-Router:

1. **NDES-Enrollment**:
   - Der Cisco-Router verwendet das SCEP-Protokoll, um ein Zertifikat von NDES anzufordern.
   - Die NDES-URL und das Root-CA-Zertifikat werden im Router konfiguriert.
   - Ein Challenge-Password (optional, je nach NDES-Konfiguration) authentifiziert die Anfrage.
2. **Intune-Integration**:
   - Intune verteilt das Root-CA-Zertifikat und das SCEP-Profil an verwaltete Geräte.
   - Für nicht-verwaltete Geräte (wie Router) wird die Konfiguration manuell vorgenommen, aber NDES verarbeitet die Anfrage.
3. **Wichtige Cisco IOS-Befehle**:
   - `crypto pki trustpoint`: Definiert die CA und Enrollment-Parameter.
   - `crypto pki authenticate`: Importiert das Root-CA-Zertifikat.
   - `crypto pki enroll`: Startet den SCEP-Enrollment-Prozess.
4. **Sicherheitsaspekte**:
   - Verwenden Sie HTTPS für die NDES-URL und ein starkes TLS-Zertifikat (siehe vorherige Anleitung).
   - Schützen Sie das Challenge-Password und überprüfen Sie die Zertifikatskette.

## Übung: NDES-Enrollment mit einem Cisco-Router
**Ziel**: Konfigurieren Sie einen Cisco-Router, um ein Zertifikat über NDES und Intune zu beziehen, und validieren Sie die Ausstellung.

1. **Schritt 1**: Vorbereitung des Cisco-Routers.
   - Stellen Sie eine Verbindung zur CLI des Routers her (z. B. via SSH oder Konsole).
   - Aktivieren Sie den Konfigurationsmodus:
     ```
     enable
     configure terminal
     ```
   - Stellen Sie sicher, dass der Router eine IP-Adresse hat und die NDES-URL erreichbar ist:
     ```
     ping ndes.contoso.com
     ```

2. **Schritt 2**: Root-CA-Zertifikat importieren.
   - Kopieren Sie das Root-CA-Zertifikat (z. B. `ca.crt`) auf den Router (z. B. via TFTP oder USB).
   - Definieren Sie einen Trustpoint für die CA:
     ```
     crypto pki trustpoint NDES-CA
     enrollment url https://ndes.contoso.com/certsrv/mscep/
     revocation-check none  ! Optional, wenn CRL nicht verwendet wird
     ```
   - Authentifizieren Sie die CA, indem Sie das Root-CA-Zertifikat importieren:
     ```
     crypto pki authenticate NDES-CA
     ```
   - Fügen Sie das Root-CA-Zertifikat ein (Base64-Format, via Copy-Paste oder TFTP):
     ```
     -----BEGIN CERTIFICATE-----
     <Base64-Zertifikat von ca.crt>
     -----END CERTIFICATE-----
     ```
   - Bestätigen Sie mit `yes` und überprüfen Sie:
     ```
     show crypto pki trustpoints
     ```

3. **Schritt 3**: Zertifikat über SCEP anfordern.
   - Konfigurieren Sie die Enrollment-Parameter im Trustpoint:
     ```
     crypto pki trustpoint NDES-CA
     enrollment mode ra
     serial-number none
     fqdn router1.contoso.com
     subject-name CN=router1.contoso.com,OU=Network,O=Contoso
     password MySCEPPassword  ! Challenge-Password, falls erforderlich
     rsakeypair Router1-Key 2048
     ```
   - Starten Sie den Enrollment-Prozess:
     ```
     crypto pki enroll NDES-CA
     ```
   - Geben Sie das Challenge-Password ein (falls konfiguriert) und bestätigen Sie. Der Router sendet eine SCEP-Anfrage an NDES und erhält das Zertifikat.

4. **Schritt 4**: Validieren Sie das Zertifikat.
   - Überprüfen Sie das installierte Zertifikat auf dem Router:
     ```
     show crypto pki certificates
     ```
   - Überprüfen Sie in Intune, ob das Zertifikat ausgestellt wurde:
     - Gehen Sie zu **Devices > All devices > [Gerät] > Certificates** (falls der Router als Gerät in Intune registriert ist).
   - Auf dem NDES-Server: Prüfen Sie die Logs im Event Viewer (`Applications and Services Logs > Microsoft > Windows > CertificateServices-Deployment`).
   - Optional: Testen Sie die Authentifizierung (z. B. für IPsec):
     ```
     crypto map VPN-MAP 10 ipsec-isakmp
     set peer 192.168.1.1
     set transform-set ESP-AES-256-SHA
     match address VPN-ACL
     set pfs group14
     set ikev2 profile IKEV2-PROFILE
     crypto ikev2 profile IKEV2-PROFILE
     authentication local rsa-sig
     pki trustpoint NDES-CA
     ```
**Reflexion**: Wie vereinfacht die manuelle Konfiguration eines Cisco-Routers das Verständnis des SCEP-Prozesses, und welche Herausforderungen könnten bei Geräten ohne Intune-Verwaltung auftreten?

## Tipps für den Erfolg
- **Sicherheit**: Verwenden Sie ein starkes Challenge-Password und speichern Sie es sicher (z. B. in einem Passwort-Manager oder Azure Key Vault).
- **Netzwerk**: Stellen Sie sicher, dass der Router die NDES-URL über HTTPS (Port 443) erreicht. Testen Sie mit `ping` oder `telnet ndes.contoso.com 443`.
- **Fehlerbehandlung**: Überprüfen Sie NDES-Logs bei Fehlern (z. B. falsches Password oder nicht vertrauenswürdige CA).
- **Automatisierung**: Für mehrere Router können Sie Skripte (z. B. mit Ansible oder Python) verwenden, um die CLI-Befehle zu automatisieren.
- **Alternative Geräte**: Für MikroTik-Router nutzen Sie ähnliche Schritte via `certificate scep-client` (siehe MikroTik-Dokumentation).

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie einen Cisco-Router konfigurieren, um ein Zertifikat über NDES und Intune via SCEP zu beziehen. Der praktische Anwendungsfall zeigt, wie die NDES-Infrastruktur mit echten Netzwerkgeräten interagiert und wie Intune die Zertifikatsverwaltung erleichtert. Dieses Wissen können Sie auf andere Geräte (z. B. MikroTik, Fortinet) oder Software-Clients anwenden, um eine skalierbare PKI-Lösung zu implementieren.

### Schritte für NDES-Enrollment mit einem Extreme Networks Switch
1. **Vorbereitung**:
   - Stelle eine Verbindung zur CLI des Switches her (via SSH oder Konsole) und aktiviere den Konfigurationsmodus:
     ```
     enable
     configure
     ```
   - Überprüfe die Erreichbarkeit der SCEP-URL (`https://ndes.contoso.com/certsrv/mscep/`) mit:
     ```
     ping ndes.contoso.com
     ```

2. **Root-CA-Zertifikat importieren**:
   - Kopiere das Root-CA-Zertifikat (z. B. `ca.crt`) auf den Switch via TFTP oder SCP.
   - Erstelle einen Trustpoint und importiere das Root-CA-Zertifikat:
     ```
     create certificates local switch1.contoso.com
     create certificates request switch1.contoso.com country US state CA locality San Francisco organization Contoso ou Network
     create certificates trust switch1.contoso.com
     tftp 1 192.168.1.100 ca.crt  # Ersetze die TFTP-IP
     ```

3. **Zertifikat über SCEP anfordern**:
   - Konfiguriere den SCEP-Client für NDES:
     ```
     configure certificates scep-client add name NDES-Client url https://ndes.contoso.com/certsrv/mscep/ challenge MySCEPPassword
     ```
   - Starte das Enrollment:
     ```
     enroll certificates using scep-client NDES-Client local switch1.contoso.com
     ```
   - Gib das Challenge-Password ein (falls erforderlich), und der Switch fordert das Zertifikat von NDES an.

4. **Validierung**:
   - Überprüfe das installierte Zertifikat:
     ```
     show certificates
     ```
   - Prüfe in Intune (falls der Switch registriert ist) oder in den NDES-Logs (`Applications and Services Logs > Microsoft > Windows > CertificateServices-Deployment`).
   - Teste optional die Zertifikatsnutzung, z. B. für 802.1X-Authentifizierung:
     ```
     configure stpd add vlan default ports all protocol-mode dot1d
     enable stpd ports all dot1x
     configure dot1x add trusted-ports all
     configure netlogin add port all vlan default
     configure netlogin add port all forward
     enable netlogin ports all
     ```

### Unterschiede zum Cisco-Router
- **CLI-Befehle**: Die Cisco IOS-Befehle (`crypto pki trustpoint`, `crypto pki enroll`) unterscheiden sich von den EXOS-Befehlen (`create certificates`, `configure certificates scep-client`). EXOS ist spezifisch für Extreme Networks und verwendet eine andere Syntax.
- **CSR-Generierung**: Bei EXOS wird die CSR (Certificate Signing Request) explizit mit `create certificates request` erstellt, während Cisco dies implizit während des Enrollment-Prozesses handhabt.
- **Flexibilität**: EXOS bietet spezifische SCEP-Client-Befehle, die die Konfiguration intuitiver machen können, insbesondere für 802.1X oder Netzwerk-Authentifizierung. Cisco ist jedoch flexibler für komplexe VPN- oder IPsec-Szenarien.
- **Vorteile von EXOS**: EXOS hat eine einfachere Struktur für Zertifikatsmanagement, was die Integration mit NDES für Switches erleichtert. Die CLI ist weniger komplex als Cisco IOS für grundlegende PKI-Aufgaben.

### Tipps
- **Netzwerkzugriff**: Stelle sicher, dass der Switch die NDES-URL über HTTPS (Port 443) erreicht. Teste mit `telnet ndes.contoso.com 443` oder `ping`.
- **Fehlerbehandlung**: Bei Fehlern (z. B. „Invalid Challenge Password“) überprüfe die NDES-Logs und stelle sicher, dass die Root-CA korrekt importiert wurde.
- **Automatisierung**: Für mehrere Switches kannst du die Konfiguration mit Skripten (z. B. Python mit `pexpect` oder Ansible) automatisieren.
- **Dokumentation**: Siehe die Extreme Networks EXOS-Dokumentation (im Originaldokument verlinkt: https://documentation.extremenetworks.com/exos_31.5/GUID-8E5C4F5A-4B5E-4E5F-8F5A-5B5E4F5A5B5E.shtml).

### Fazit
Das NDES-Enrollment mit einem Extreme Networks Switch ist absolut machbar und folgt einem ähnlichen Prinzip wie bei einem Cisco-Router, jedoch mit EXOS-spezifischen Befehlen. Die bereitgestellte Anleitung deckt alle notwendigen Schritte ab, und die EXOS-CLI erleichtert die Konfiguration für Switches, insbesondere für Szenarien wie 802.1X. Wenn du weitere Details oder Hilfe bei spezifischen Fehlern benötigst, lass es mich wissen!

**Nächste Schritte**:
- Testen Sie das Enrollment mit anderen Geräten (z. B. MikroTik mit `/certificate add name=scep-client scep-url=https://ndes.contoso.com/certsrv/mscep/`).
- Automatisieren Sie die Konfiguration für mehrere Geräte mit Skripting-Tools.
- Integrieren Sie Zertifikats-Überwachung in Intune, um Ablaufdaten zu tracken.

**Quellen**:
- Microsoft Learn: https://learn.microsoft.com/en-us/mem/intune/protect/certificates-scep-configure
- Cisco IOS PKI Configuration: https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/sec_conn_pki/configuration/15-mt/sec-pki-15-mt-book/sec-cfg-pki.html
- SecureW2 NDES Guide: https://www.securew2.com/blog/ndes-scep-server-configuration
- Microsoft Endpoint Manager: https://msendpointmgr.com/2020/06/15/how-to-renew-ndes-service-certificates-for-usage-with-microsoft-intune/