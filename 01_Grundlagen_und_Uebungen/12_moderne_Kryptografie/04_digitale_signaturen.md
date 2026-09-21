# Praxisorientierte Anleitung: Digitale Signaturen mit Ed25519

## Einführung
Während [Übung 3 im vorherigen Kapitel](03_asymmetrische_verschluesselung_und_schluesseltausch.md) Vertraulichkeit über einen Schlüsseltausch hergestellt hat, geht es bei **digitalen Signaturen** um etwas anderes: den Beweis, dass eine Nachricht wirklich von einer bestimmten Person/Instanz stammt (Authentizität) und seit der Signatur nicht verändert wurde (Integrität) – ohne dass dafür ein gemeinsames Geheimnis nötig ist. Diese Anleitung nutzt **Ed25519**, das moderne Signaturverfahren, das heute u. a. SSH, TLS-Zertifikate, Software-Signierung (z. B. Paketmanager) und `git commit -S` nutzen können, als schnelle und robuste Alternative zu klassischem RSA.

**Voraussetzungen**:
- Ein Linux-System mit `openssl` (Version 1.1.1+) und Python 3.
- `pip3 install cryptography`.
- Kenntnisse aus [01_hashing_und_integritaet.md](01_hashing_und_integritaet.md) (Hashing ist Teil jeder Signatur).

## Grundlegende Konzepte

- **Prinzip einer digitalen Signatur**: Der Absender hasht die Nachricht und verschlüsselt (vereinfacht gesagt) den Hash mit seinem **privaten** Schlüssel → das ist die Signatur. Jeder mit dem **öffentlichen** Schlüssel kann prüfen, ob die Signatur zur Nachricht passt – aber nur der Besitzer des privaten Schlüssels konnte sie erzeugen.
- **RSA-Signaturen vs. Ed25519**: RSA-Signaturen sind größer (z. B. 384 Byte bei RSA-3072) und die Erzeugung ist langsamer. Ed25519-Signaturen sind konstant klein (64 Byte), schnell zu erzeugen und zu prüfen, und das Verfahren ist von Grund auf so entworfen, dass typische Implementierungsfehler (z. B. schwache Zufallszahlen bei der Signaturerzeugung, ein bekanntes historisches RSA/DSA-Problem) strukturell ausgeschlossen sind.
- **Signieren ≠ Verschlüsseln**: Eine Signatur macht eine Nachricht nicht vertraulich – sie bleibt lesbar. Wer Vertraulichkeit **und** Authentizität braucht, kombiniert Verschlüsselung (siehe vorherige Kapitel) mit einer Signatur.
- **Praxisbeispiele**: SSH-Schlüssel (`ssh-keygen -t ed25519`), signierte Git-Commits, Code-Signing, signierte Software-Updates/Pakete.

## Übungen zum Verinnerlichen

### Übung 1: Ed25519-Signatur mit OpenSSL
**Ziel**: Eine Datei signieren und die Signatur verifizieren – inklusive Erkennung einer nachträglichen Manipulation.

1. Erzeuge ein Ed25519-Schlüsselpaar:
   ```bash
   openssl genpkey -algorithm ed25519 -out signatur_private.pem
   openssl pkey -in signatur_private.pem -pubout -out signatur_public.pem
   ```
2. Signiere eine Datei:
   ```bash
   echo "Diese Nachricht ist authentisch." > nachricht.txt
   openssl pkeyutl -sign -inkey signatur_private.pem -rawin -in nachricht.txt -out nachricht.sig
   ```
3. Verifiziere die Signatur mit dem öffentlichen Schlüssel:
   ```bash
   openssl pkeyutl -verify -pubin -inkey signatur_public.pem -rawin -in nachricht.txt -sigfile nachricht.sig
   ```
   Ausgabe sollte `Signature Verified Successfully` sein.
4. Ändere die Nachricht und prüfe erneut:
   ```bash
   echo "Diese Nachricht wurde veraendert." > nachricht.txt
   openssl pkeyutl -verify -pubin -inkey signatur_public.pem -rawin -in nachricht.txt -sigfile nachricht.sig
   ```
   Die Verifikation muss jetzt fehlschlagen.

**Reflexion**: Welche der beiden Dateien (privater oder öffentlicher Schlüssel) muss unbedingt geheim bleiben, und welche kann bedenkenlos veröffentlicht werden?

### Übung 2: Signieren und Verifizieren in Python
**Ziel**: Den kompletten Ablauf – Schlüsselerzeugung, Signieren, Verifizieren – programmatisch nachvollziehen.

1. Erstelle ein Python-Skript:
   ```bash
   nano ed25519_beispiel.py
   ```
   ```python
   from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
   from cryptography.exceptions import InvalidSignature

   privater_schluessel = Ed25519PrivateKey.generate()
   oeffentlicher_schluessel = privater_schluessel.public_key()

   nachricht = b"Freigabe fuer Deployment Version 2.1"
   signatur = privater_schluessel.sign(nachricht)
   print(f"Signatur ({len(signatur)} Bytes): {signatur.hex()}")

   # Verifikation mit der korrekten Nachricht
   try:
       oeffentlicher_schluessel.verify(signatur, nachricht)
       print("Signatur gueltig - Nachricht ist authentisch und unveraendert.")
   except InvalidSignature:
       print("UNGUELTIGE Signatur!")

   # Verifikation mit manipulierter Nachricht
   manipulierte_nachricht = b"Freigabe fuer Deployment Version 9.9"
   try:
       oeffentlicher_schluessel.verify(signatur, manipulierte_nachricht)
       print("Signatur gueltig")
   except InvalidSignature:
       print("UNGUELTIGE Signatur - Manipulation erkannt!")
   ```
2. Führe das Skript aus und beobachte beide Verifikations-Ergebnisse.

**Reflexion**: Ein Paketmanager (z. B. für Linux-Pakete) prüft heruntergeladene Pakete gegen eine Signatur des Herausgebers. Welchen Angriff verhindert das konkret, den eine reine SHA-256-Prüfsumme auf der Download-Seite **nicht** verhindern würde?

## Tipps für den Erfolg
- Ed25519 für neue Projekte bevorzugen, wo das Format es zulässt (SSH-Keys, moderne TLS-Bibliotheken, eigene Anwendungen); RSA nur bei Kompatibilitätszwang mit älteren Systemen.
- Private Signaturschlüssel genauso schützen wie Verschlüsselungsschlüssel (Zugriffsrechte, ggf. Hardware-Token/HSM für produktive Signing-Infrastruktur).
- Signaturen immer über die **gesamte** relevante Nachricht prüfen, nicht nur über einen Teil – sonst können unsignierte Teile nachträglich manipuliert werden.

## Fazit
Digitale Signaturen mit Ed25519 liefern schnelle, kompakte und robuste Authentizitäts- und Integritätsnachweise – die Grundlage für signierte Software, sichere SSH-Anmeldung und vertrauenswürdige Zertifikate. Die letzte praktische Anleitung dieser Reihe wendet Hashing auf ein Alltagsproblem an, bei dem einfache Hash-Funktionen bewusst *nicht* geeignet sind: das sichere Speichern von Passwörtern.

**Nächste Schritte**: Weiter mit [05_passwort_hashing.md](05_passwort_hashing.md).

**Quellen**:
- RFC 8032 (EdDSA/Ed25519): https://datatracker.ietf.org/doc/html/rfc8032
- Python `cryptography`-Dokumentation (Ed25519): https://cryptography.io/en/latest/hazmat/primitives/asymmetric/ed25519/
