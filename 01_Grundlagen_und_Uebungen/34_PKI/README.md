# PKI – Eigene Public Key Infrastructure betreiben

Diese Reihe zeigt, wie man eine eigene **Public Key Infrastructure (PKI)** von Grund auf mit OpenSSL aufbaut und produktiv nutzt: Root- und Intermediate-CA, Zertifikate ausstellen und widerrufen, Integration in OPNsense-Firewalls für zertifikatbasiertes IPsec, sowie Mehrfach-Hostnamen über Subject Alternative Names (SANs).

## Warum manuell mit OpenSSL, statt gleich zu automatisieren?
Alle Anleitungen hier stellen Zertifikate **manuell per Kommandozeile** aus. Das ist bewusst so gewählt: Wer versteht, wie Root CA, Intermediate CA, CSR, Signierung und CRL im Detail zusammenspielen, kann anschließend viel besser einschätzen, was ein automatisiertes System eigentlich für ihn erledigt. Für den produktiven Betrieb – gerade bei vielen Zertifikaten oder kurzen Laufzeiten – lohnt sich danach der Umstieg auf eine automatisierte, ACME-fähige interne CA: siehe [13_TLS_Verschlüsselung/20_private_acme_ca_step_ca.md](../13_TLS_Verschlüsselung/20_private_acme_ca_step_ca.md).

**Hinweis zu VPN-Grundlagen**: Reine VPN-Themen ohne PKI-Bezug (WireGuard, PSK-basierte Site-to-Site-VPNs) liegen unter [33_VPN](../33_VPN/). Diese PKI-Reihe hier setzt zertifikatbasierte VPN-Authentifizierung (IPsec) als Anwendungsfall ein, siehe [02_pki_opnsense_integration.md](02_pki_opnsense_integration.md) und [05_certificate_opnsense_integration.md](05_certificate_opnsense_integration.md).

## Lernpfad

| # | Datei | Thema |
|---|---|---|
| 1 | [01_pki_setup_guide.md](01_pki_setup_guide.md) | Grundlagen: Root CA und Intermediate CA von Grund auf einrichten, erstes Zertifikat signieren, Backup automatisieren |
| 2 | [02_pki_opnsense_integration.md](02_pki_opnsense_integration.md) | Zertifikate in OPNsense importieren: IPsec-Site-to-Site-VPN zwischen zwei Standorten und IPsec-Remote-Access-VPN mit Client-Zertifikaten |
| 3 | [03_pki_crl_setup_guide.md](03_pki_crl_setup_guide.md) | Certificate Revocation List (CRL): Zertifikate widerrufen und die Sperrliste in OPNsense einbinden |
| 4 | [04_csr_and_certificate_creation_guide.md](04_csr_and_certificate_creation_guide.md) | CSR und Zertifikat für einen Webserver erstellen, Integration in Nginx |
| 5 | [05_certificate_opnsense_integration.md](05_certificate_opnsense_integration.md) | Ein bestehendes Zertifikat mehrfach nutzen: gleichzeitig für IPsec-VPN und die OPNsense-Weboberfläche (HTTPS) |
| 6 | [06_san_certificate_creation_guide.md](06_san_certificate_creation_guide.md) | SAN-Zertifikate (mehrere Hostnamen/IPs in einem Zertifikat) |

Die Nummerierung entspricht keiner strikten Abhängigkeitskette – 1 ist die Grundlage für alle anderen, 3 baut auf einem in 2 erstellten Client-Zertifikat auf, und 5/6 setzen die PKI aus 1 voraus, sind aber sonst weitgehend unabhängig voneinander. Wer sich zuerst nur für "wie erstelle ich ein Zertifikat" statt VPN-Integration interessiert, kann nach 1 direkt zu 4 springen.

## Angenommene HomeLab-Umgebung
Alle Anleitungen verwenden durchgängig dieselbe Beispielumgebung (IPs/Namen bei Bedarf an die eigene Umgebung anpassen):

| Rolle | Hostname | IP |
|---|---|---|
| PKI-Server (Debian-VM) | `pki.homelab.local` | `192.168.30.123` |
| OPNsense Standort A | `fw1.homelab.local` | `192.168.30.1` (LAN `192.168.1.0/24`) |
| OPNsense Standort B | `fw2.homelab.local` | `192.168.40.1` (LAN `192.168.2.0/24`) |
| Backup-Ziel (TrueNAS) | – | `192.168.30.100` |

## Voraussetzungen
- Eine Debian-VM (z. B. Proxmox VE, siehe [20_Proxmox](../20_Proxmox/)) für den PKI-Server.
- Zwei OPNsense-Firewalls für die VPN-Übungen (können auch als virtuelle Instanzen laufen, siehe [Homelab-SOHO/03_opnsense_homelab_installation_guide.md](../20_Proxmox/Homelab-SOHO/03_opnsense_homelab_installation_guide.md)).
- Grundkenntnisse in OpenSSL und Linux-Kommandozeile.

**Quellen**:
- OpenSSL-Dokumentation: https://www.openssl.org/docs/
- OPNsense-Dokumentation: https://docs.opnsense.org/manual/vpnet.html
- Jamie Nguyen: OpenSSL Certificate Authority (ausführliche Referenz zum hier verwendeten Verzeichnislayout): https://jamielinux.com/docs/openssl-certificate-authority/
