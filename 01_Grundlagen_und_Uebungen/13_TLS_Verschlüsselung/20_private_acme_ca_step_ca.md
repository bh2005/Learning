# Praxisorientierte Anleitung: Private ACME-CA im internen Netzwerk mit step-ca

## Einführung
Öffentliche ACME-CAs wie Let's Encrypt (siehe [11_acme_automation.md](11_acme_automation.md)) benötigen eine öffentlich auflösbare Domain und externe Erreichbarkeit für die Challenge-Validierung. Für interne Dienste – private Hostnamen, interne IP-Bereiche, Systeme ohne Internetzugang – funktioniert das nicht. Die Lösung ist eine **eigene, interne Certificate Authority, die selbst das ACME-Protokoll spricht**. [step-ca](https://smallstep.com/docs/step-ca/) (Open Source, Smallstep) ist dafür eine verbreitete Wahl: Es implementiert einen ACME-Server, sodass alle Standard-ACME-Clients (Certbot, acme.sh, win-acme, Ansible-`acme`-Module) ohne Anpassung funktionieren – man zeigt ihnen einfach auf die interne CA statt auf `acme-v02.api.letsencrypt.org`. Das ersetzt die manuelle OpenSSL-CA-Verwaltung aus [04_pki_setup_guide.md](../34_PKI/04_pki_setup_guide.md) durch automatisierte Ausstellung und Erneuerung, ohne die Kontrolle über eine interne Root/Intermediate-CA aufzugeben.

**Voraussetzungen**:
- Ein Linux-Server (z. B. Debian 12/13) als dedizierter CA-Host, idealerweise ohne weitere Dienste.
- Interne DNS-Auflösung für den CA-Hostnamen (z. B. `ca.homelab.local`).
- Grundkenntnisse in PKI-Konzepten (Root/Intermediate CA, siehe [04_pki_setup_guide.md](../34_PKI/04_pki_setup_guide.md)) und im ACME-Protokoll (siehe [11_acme_automation.md](11_acme_automation.md)).
- Root-/Sudo-Zugriff auf CA-Host und die Clients, die Zertifikate beziehen sollen.

## Grundlegende Konzepte

- **step-ca**: Der CA-Server-Prozess, hostet sowohl eine klassische Registrierungsstelle (API) als auch einen ACME-Endpoint.
- **Root CA**: Bleibt idealerweise offline bzw. wird nur zur Erstellung der Intermediate CA verwendet.
- **Intermediate CA**: Signiert im laufenden Betrieb die von step-ca ausgestellten Zertifikate; ihr Schlüssel liegt auf dem CA-Host.
- **ACME-Provisioner**: Eine in step-ca konfigurierte "Ausstellungs-Policy", die festlegt, dass Anfragen über das ACME-Protokoll akzeptiert werden (analog zu einem Provisioner für andere Auth-Methoden wie JWK oder OIDC).
- **Trust Distribution**: Da die interne CA keiner öffentlichen Root-CA-Liste angehört, muss das Root-CA-Zertifikat aktiv auf allen Clients als vertrauenswürdig hinterlegt werden (Trust Store), sonst schlagen TLS-Verbindungen mit "unknown CA" fehl.

## Übungen zum Verinnerlichen

### Übung 1: step-ca installieren und initialisieren
**Ziel**: Eine lauffähige interne CA mit Root- und Intermediate-Zertifikat aufsetzen.

1. Installiere step-ca und das `step`-CLI-Tool (siehe aktuelle Anleitung unter https://smallstep.com/docs/step-ca/installation für dein Betriebssystem, da sich Paketnamen/Versionen ändern können).
2. Initialisiere die CA:
   ```bash
   step ca init \
     --name "Homelab Internal CA" \
     --dns "ca.homelab.local" \
     --address ":443" \
     --provisioner "admin@homelab.local"
   ```
   Dabei werden Root- und Intermediate-Zertifikat sowie die zugehörigen privaten Schlüssel erzeugt und passphrasegeschützt abgelegt.
3. Starte den CA-Dienst:
   ```bash
   step-ca $(step path)/config/ca.json
   ```
   Für Produktivbetrieb als systemd-Service einrichten, damit die CA nach einem Neustart automatisch verfügbar ist.

**Reflexion**: Warum sollte der private Schlüssel der Root CA nach der Erstellung der Intermediate CA idealerweise offline/getrennt aufbewahrt werden?

### Übung 2: ACME-Provisioner aktivieren
**Ziel**: step-ca so konfigurieren, dass sie ACME-Anfragen entgegennimmt.

1. Füge einen ACME-Provisioner hinzu:
   ```bash
   step ca provisioner add acme --type ACME
   ```
2. CA neu laden bzw. neustarten, damit die Konfiguration aktiv wird.
3. Der ACME-Directory-Endpoint ist danach erreichbar unter:
   ```
   https://ca.homelab.local/acme/acme/directory
   ```

### Übung 3: Root-CA-Zertifikat an Clients verteilen
**Ziel**: Clients dazu bringen, der internen CA zu vertrauen.

1. Exportiere das Root-CA-Zertifikat vom CA-Host:
   ```bash
   step ca root root_ca.crt
   ```
2. Auf Linux-Clients importieren:
   ```bash
   cp root_ca.crt /usr/local/share/ca-certificates/homelab-root-ca.crt
   update-ca-certificates
   ```
3. Auf Windows-Clients importieren:
   ```powershell
   certutil -addstore -f "Root" root_ca.crt
   ```
4. In größeren Umgebungen die Verteilung automatisieren, z. B. über Ansible oder Gruppenrichtlinien, statt jeden Client manuell zu pflegen.

**Reflexion**: Was passiert, wenn ein Client das Root-CA-Zertifikat nicht importiert hat, aber trotzdem ein Zertifikat der internen CA per ACME bezieht?

### Übung 4: Zertifikat per Standard-ACME-Client beziehen
**Ziel**: Mit einem gewöhnlichen ACME-Client (hier Certbot) ein Zertifikat von der internen CA statt von Let's Encrypt beziehen.

1. Certbot installieren (siehe [11_acme_automation.md](11_acme_automation.md)).
2. Zertifikat anfordern und dabei explizit den internen ACME-Server angeben:
   ```bash
   sudo certbot certonly --standalone \
     --server https://ca.homelab.local/acme/acme/directory \
     -d internal-app.homelab.local
   ```
3. Prüfen, ob das ausgestellte Zertifikat von der internen Intermediate CA signiert wurde:
   ```bash
   openssl x509 -in /etc/letsencrypt/live/internal-app.homelab.local/cert.pem -noout -issuer
   ```

### Übung 5: Automatisierte Erneuerung einrichten
**Ziel**: Wiederkehrende Erneuerung wie bei öffentlichem ACME, nur gegen die interne CA.

1. Certbot bringt die Renewal-Konfiguration bereits mit (`--server` wird in `renewal/*.conf` gespeichert):
   ```bash
   sudo certbot renew --dry-run
   ```
2. Kurze Zertifikatslaufzeiten (z. B. 7–30 Tage) sind bei einer privaten CA problemlos möglich, da die Erneuerung vollautomatisch läuft – das reduziert den Schaden bei einem kompromittierten Zertifikat deutlich gegenüber klassischen 1-Jahres-Zertifikaten.

**Reflexion**: Welchen Sicherheitsvorteil bringt eine kurze Zertifikatslaufzeit in Kombination mit vollautomatischer ACME-Erneuerung?

## Best Practices

- **CA-Verfügbarkeit absichern**: Fällt step-ca aus, können keine Zertifikate mehr erneuert werden – bei kurzen Laufzeiten sollte die CA daher redundant oder zumindest mit Monitoring betrieben werden.
- **Root-Key-Backup**: Der Root-CA-Schlüssel muss sicher und getrennt vom laufenden CA-Host gesichert werden (z. B. verschlüsselt, offline) – sein Verlust bedeutet den Verlust der gesamten Vertrauenskette.
- **Trust-Distribution automatisieren**: Manuelles Verteilen des Root-Zertifikats skaliert nicht; Configuration-Management (Ansible, GPO) übernehmen lassen.
- **Zugriff auf den ACME-Endpoint einschränken**: Der ACME-Endpoint sollte nur aus dem internen Netz erreichbar sein, nicht aus dem Internet.
- **Monitoring**: CA-Erreichbarkeit und Zertifikatsablauf-Trends überwachen (z. B. mit Checkmk), damit ein CA-Ausfall auffällt, bevor Zertifikate reihenweise ablaufen.

## Fazit
Eine private ACME-CA wie step-ca schließt die Lücke, die öffentliche ACME-Anbieter für interne Infrastruktur offenlassen: automatisierte, kurzlebige Zertifikate ganz ohne manuelle CSR-Prozesse, mit denselben Standard-Tools, die auch für öffentliche Zertifikate verwendet werden. Der Aufwand verschiebt sich von der Zertifikatsausstellung hin zum Betrieb und der Absicherung der CA selbst sowie der Verteilung des Vertrauensankers an alle Clients.

**Quellen**:
- https://smallstep.com/docs/step-ca/
- https://datatracker.ietf.org/doc/html/rfc8555 (ACME-Protokoll)
