# HomeLab PKI Präsentation

## Willkommen
- Überblick über die Public Key Infrastructure (PKI)
- Einrichtung in der HomeLab-Umgebung
- Erstellt von: HomeLab Team

---

## Was ist eine PKI?
- **Definition**: System zur Verwaltung digitaler Zertifikate
- **Komponenten**:
  - Root CA
  - Intermediate CA
  - Zertifikate und CRLs
- **Einsatz**: VPNs, Webserver, E-Mail-Sicherheit

---

## Einrichtung in der HomeLab
- **Server**: Debian 13 VM (`pki.homelab.local`, `192.168.30.123`)
- **Tools**: OpenSSL
- **Struktur**:
  ```bash
  /root/ca/
  ├── root/
  │   ├── certs/
  │   ├── private/
  │   └── ...
  ├── intermediate/
  │   ├── certs/
  │   ├── private/
  │   └── ...
  ```

---

## Beispiel: Zertifikat für Webserver
- **Schritte**:
  1. Generiere Schlüssel: `openssl genrsa`
  2. Erstelle CSR: `openssl req`
  3. Signiere mit Intermediate CA: `openssl ca`
- **Nutzung**: HTTPS für `webserver.homelab.local`

---

## Fazit
- **Vorteile**:
  - Sichere Kommunikation
  - Flexible Zertifikatsverwaltung
- **Nächste Schritte**:
  - Integration in OPNsense
  - Erstellung von SAN-Zertifikaten
- Fragen?

---