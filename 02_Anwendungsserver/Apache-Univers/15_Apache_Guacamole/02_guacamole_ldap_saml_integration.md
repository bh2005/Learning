# Praxisorientierte Anleitung: Integration von Apache Guacamole mit LDAP oder SAML für Unternehmens-Authentifizierung auf Debian

## Einführung
Die Integration von **Apache Guacamole** mit **LDAP** oder **SAML** ermöglicht eine zentrale Unternehmens-Authentifizierung, um sichere Fernzugriffe zu verwalten. **LDAP** (Lightweight Directory Access Protocol) ist ideal für Active Directory oder OpenLDAP-Umgebungen, während **SAML** (Security Assertion Markup Language) Single-Sign-On (SSO) mit Identity-Providern wie Azure AD oder Okta unterstützt. Diese Anleitung baut auf einer bestehenden Guacamole-Installation auf und zeigt, wie Sie LDAP- oder SAML-Authentifizierung konfigurieren. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, Guacamole für skalierbare Unternehmens-Authentifizierung einzurichten. Diese Anleitung ist ideal für Administratoren, die zentrale Zugriffssteuerung implementieren möchten.

**Voraussetzungen:**
- Ein Debian-System (z. B. Debian 11 oder 12) mit installiertem Apache Guacamole und Tomcat 9
- Root- oder Sudo-Zugriff
- Ein LDAP-Server (z. B. Active Directory oder OpenLDAP) oder SAML-IdP (z. B. Azure AD, Okta)
- Grundlegende Kenntnisse der Linux-Kommandozeile und Authentifizierungssysteme
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie IntelliJ IDEA)

## Grundlegende Konzepte und Techniken
Hier sind die wichtigsten Konzepte und Techniken, die wir behandeln:

1. **LDAP-Integration**:
   - **guacamole-auth-ldap**: Extension für LDAP-Bind-Authentifizierung
   - **Bind-Mechanismus**: Guacamole bindet mit Benutzerdaten an den LDAP-Server und fragt Berechtigungen ab
   - **Konfiguration**: In `guacamole.properties` mit Server-Details und Suchfiltern
2. **SAML-Integration**:
   - **guacamole-auth-saml**: Extension für SAML 2.0 SSO
   - **IdP-Konfiguration**: Guacamole als Service Provider (SP) beim Identity Provider registrieren
   - **Redirect-Flow**: Benutzer werden zum IdP umgeleitet, SAML-Assertion wird verarbeitet
3. **Gemeinsame Konfiguration**:
   - Extensions in `/etc/guacamole/extensions/` platzieren
   - Tomcat-Neustart für Änderungen

## Übungen zum Verinnerlichen

### Übung 1: LDAP-Extension installieren und konfigurieren
**Ziel**: Lernen, wie man die LDAP-Extension installiert und mit einem LDAP-Server verbindet.

1. **Schritt 1**: Lade und installiere die LDAP-Extension.
   ```bash
   cd /tmp
   wget https://archive.apache.org/dist/guacamole/1.5.5/binary/guacamole-auth-ldap-1.5.5.tar.gz
   tar -xzf guacamole-auth-ldap-1.5.5.tar.gz
   sudo cp guacamole-auth-ldap-1.5.5/guacamole-auth-ldap-1.5.5.jar /etc/guacamole/extensions/
   ```
2. **Schritt 2**: Konfiguriere LDAP in `guacamole.properties`.
   ```bash
   sudo nano /etc/guacamole/guacamole.properties
   ```
   Füge folgende Einstellungen hinzu (passen Sie an Ihren LDAP-Server an, z. B. Active Directory):
   ```properties
   # LDAP-Server-Details
   ldap-hostname: your-ldap-server.example.com
   ldap-port: 389
   ldap-encryption-method: none  # Oder 'starttls' für LDAPS
   ldap-user-base-dn: ou=users,dc=example,dc=com
   ldap-username-attribute: uid  # Oder sAMAccountName für AD
   ldap-search-bind-dn: cn=guac-service,ou=service,dc=example,dc=com
   ldap-search-bind-password: your-bind-password
   ldap-user-search-filter: (&(objectClass=person)(!(objectCategory=computer)))
   ldap-group-base-dn: ou=groups,dc=example,dc=com
   ldap-config-base-dn: ou=configs,dc=example,dc=com
   ```
3. **Schritt 3**: Symlink erstellen und Tomcat neu starten.
   ```bash
   sudo ln -s /etc/guacamole/guacamole.properties /usr/local/tomcat/webapps/guacamole/WEB-INF/
   sudo systemctl restart tomcat9
   ```
4. **Schritt 4**: Teste die LDAP-Authentifizierung.
   - Öffne `http://localhost:8080/guacamole` und versuche, dich mit LDAP-Benutzerdaten anzumelden.
   - Überprüfe Logs: `sudo tail -f /var/log/tomcat9/catalina.out` für Fehler.

**Reflexion**: Warum ist der Bind-Mechanismus sicher, und wie können Suchfilter die Benutzerbeschränkung verbessern?

### Übung 2: SAML-Extension installieren und konfigurieren
**Ziel**: Verstehen, wie man die SAML-Extension installiert und mit einem IdP (z. B. Azure AD) verbindet.

1. **Schritt 1**: Lade und installiere die SAML-Extension.
   ```bash
   cd /tmp
   wget https://archive.apache.org/dist/guacamole/1.5.5/binary/guacamole-auth-saml-1.5.5.tar.gz
   tar -xzf guacamole-auth-saml-1.5.5.tar.gz
   sudo cp guacamole-auth-saml-1.5.5/guacamole-auth-saml-1.5.5.jar /etc/guacamole/extensions/
   ```
2. **Schritt 2**: Konfiguriere SAML in `guacamole.properties`.
   ```bash
   sudo nano /etc/guacamole/guacamole.properties
   ```
   Füge folgende Einstellungen hinzu (passen Sie an Ihren IdP an, z. B. Azure AD):
   ```properties
   # SAML-IdP-Details (Beispiel für Azure AD)
   saml-idp-url: https://login.microsoftonline.com/{tenant-id}/saml2
   saml-entity-id: https://your-guacamole.example.com
   saml-callback-url: https://your-guacamole.example.com/guacamole/
   saml-username-attribute: http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name
   saml-groups-attribute: http://schemas.microsoft.com/ws/2008/06/identity/claims/groups
   # Optionale Signatur (falls benötigt)
   saml-keystore-path: /etc/guacamole/saml-keystore.jks
   saml-keystore-password: your-keystore-password
   ```
   - Erstellen Sie ein Keystore (optional): 
   ```bash
   keytool -genkey -alias guac -keyalg RSA -keystore /etc/guacamole/saml-keystore.jks
   ```
3. **Schritt 3**: IdP-Seite konfigurieren (Beispiel: Azure AD).
   - In Azure Portal: **Enterprise Applications** > **New Application** > **Non-gallery** > Name: Guacamole.
   - SAML-Settings: 
     - **Identifier (Entity ID)**: `https://your-guacamole.example.com`
     - **Reply URL**: `https://your-guacamole.example.com/guacamole/`
   - Lade die **Federation Metadata XML** herunter und konfiguriere `saml-idp-metadata-url` in `guacamole.properties` mit der URL.
4. **Schritt 4**: Symlink erstellen und Tomcat neu starten.
   ```bash
   sudo ln -s /etc/guacamole/guacamole.properties /usr/local/tomcat/webapps/guacamole/WEB-INF/
   sudo systemctl restart tomcat9
   ```
5. **Schritt 5**: Teste die SAML-Authentifizierung.
   - Öffne `http://localhost:8080/guacamole` und wähle SAML-Login.
   - Du wirst zum IdP umgeleitet; nach erfolgreicher Authentifizierung zurück zu Guacamole.
   - Überprüfe Logs: `sudo tail -f /var/log/tomcat9/catalina.out`.

**Reflexion**: Wie verbessert SAML SSO die Benutzererfahrung, und welche Rolle spielt die Entity-ID in der SP-Konfiguration?

### Übung 3: Hybrid-Authentifizierung (LDAP + SAML) und Test
**Ziel**: Lernen, wie man LDAP und SAML kombiniert und die Integration testet.

1. **Schritt 1**: Konfiguriere hybride Authentifizierung in `guacamole.properties`.
   ```bash
   sudo nano /etc/guacamole/guacamole.properties
   ```
   Füge hinzu (nach den LDAP/SAML-Einstellungen):
   ```properties
   # Authentifizierungsreihenfolge (LDAP zuerst, dann SAML)
   authentication-priority: ldap,saml
   ```
2. **Schritt 2**: Erstelle Testbenutzer/Gruppen.
   - In LDAP: Erstelle einen Testbenutzer und weise Gruppen zu.
   - In SAML-IdP: Weise Rollen zu (z. B. Admin-Gruppe).
3. **Schritt 3**: Tomcat neu starten und testen.
   ```bash
   sudo systemctl restart tomcat9
   ```
   - Teste LDAP-Login mit LDAP-Benutzerdaten.
   - Teste SAML-Login mit IdP-Anmeldung.
   - Überprüfe Berechtigungen: Erstelle Verbindungen und weise sie Gruppen zu.
4. **Schritt 4**: Logs analysieren.
   ```bash
   sudo tail -f /var/log/tomcat9/catalina.out | grep -E "(LDAP|SAML)"
   ```

**Reflexion**: Wie ermöglicht die Prioritätskonfiguration Fallbacks, und welche Sicherheitsüberlegungen gelten für hybride Setups?

## Tipps für den Erfolg
- Überprüfe Logs in `/var/log/tomcat9/catalina.out` und `/var/log/guacd/` bei Auth-Fehlern.
- Verwende LDAPS (Port 636) oder SAML mit HTTPS für sichere Verbindungen.
- Teste mit Tools wie `curl` für API-Tests: `curl -u admin:password http://localhost:5984/_session`.
- Für Produktion: Verwende eine dedizierte Datenbank für Benutzer (z. B. MySQL) und integrieren Sie 2FA.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Apache Guacamole mit LDAP und SAML für Unternehmens-Authentifizierung integrieren. Durch die Übungen haben Sie praktische Erfahrung mit Extensions, Konfigurationen und hybriden Setups gesammelt. Diese Fähigkeiten sind essenziell für sichere, skalierbare Remote-Zugriffe. Üben Sie weiter, um fortgeschrittene Features wie Clustering zu meistern!

**Nächste Schritte**:
- Integrieren Sie Guacamole mit 2FA (z. B. TOTP) für zusätzliche Sicherheit.
- Erkunden Sie Guacamole-Extensions für Datenbank-Authentifizierung.
- Richten Sie einen Guacamole-Cluster für Hochverfügbarkeit ein.

**Quellen**:
- Offizielle Apache Guacamole-Dokumentation: https://guacamole.apache.org/doc/gug/ldap-auth.html
- SAML-Konfiguration: https://guacamole.apache.org/doc/gug/saml-auth.html
- DigitalOcean Guacamole-Tutorial: https://www.digitalocean.com/community/tutorials/how-to-install-apache-guacamole-on-ubuntu-20-04