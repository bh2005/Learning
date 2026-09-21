# Praxisorientierte Anleitung: Asymmetrische Verschlüsselung und Schlüsseltausch mit ECC

## Einführung
Der [Kryptografie-Einstieg](../13_TLS_Verschlüsselung/02_kryptographie_einstieg.md) hat RSA über GPG genutzt. RSA funktioniert und ist weit verbreitet, verliert aber gegenüber **Elliptic Curve Cryptography (ECC)** zunehmend an Boden: Für ein vergleichbares Sicherheitsniveau braucht RSA deutlich größere Schlüssel (RSA-3072 ≈ ECC-256 Bit an Sicherheit) und ist bei Schlüsselerzeugung, Signatur und Schlüsseltausch spürbar langsamer. Diese Anleitung führt in moderne ECC-Verfahren ein: **X25519** für Schlüsseltausch (Diffie-Hellman auf elliptischen Kurven) und legt die Grundlage für **Ed25519**-Signaturen (nächste Anleitung).

**Voraussetzungen**:
- Ein Linux-System mit `openssl` (Version 1.1.1+) und Python 3.
- `pip3 install cryptography`.
- Kenntnisse aus den vorherigen beiden Anleitungen dieser Reihe.

## Grundlegende Konzepte

- **Asymmetrische Kryptografie**: Jeder Teilnehmer besitzt ein Schlüsselpaar aus privatem und öffentlichem Schlüssel. Was mit dem einen verschlüsselt bzw. signiert wird, kann nur mit dem jeweils anderen entschlüsselt bzw. verifiziert werden.
- **RSA**: Basiert auf der Schwierigkeit, große Zahlen zu faktorisieren. Sicher, aber mit wachsenden Schlüssellängen (aktuell mind. 2048, besser 3072 Bit) zunehmend langsam und mit größeren Schlüsseln/Signaturen.
- **ECC (Elliptic Curve Cryptography)**: Basiert auf der Schwierigkeit des diskreten Logarithmus-Problems auf elliptischen Kurven. Liefert bei viel kleineren Schlüsseln (256 Bit) ein Sicherheitsniveau vergleichbar mit RSA-3072, bei deutlich schnellerer Berechnung.
- **Diffie-Hellman (DH) / ECDH**: Ein Verfahren, mit dem zwei Parteien über einen unsicheren Kanal ein gemeinsames Geheimnis vereinbaren können, **ohne** es jemals zu übertragen. ECDH ist die Variante auf elliptischen Kurven; X25519 ist eine besonders effiziente und gegen Implementierungsfehler robuste Kurve dafür (u. a. Standard in TLS 1.3, WireGuard, Signal).
- **Perfect Forward Secrecy (PFS)**: Wird für jede Sitzung ein neues, temporäres DH-Schlüsselpaar erzeugt, bleibt der Sitzungsschlüssel geheim, selbst wenn der langfristige private Schlüssel später kompromittiert wird – vergangene Kommunikation lässt sich dann nicht nachträglich entschlüsseln.

## Übungen zum Verinnerlichen

### Übung 1: X25519-Schlüsselaustausch mit OpenSSL
**Ziel**: Zwei Schlüsselpaare erzeugen und ein gemeinsames Geheimnis ableiten, ohne den privaten Schlüssel zu übertragen.

1. Erzeuge zwei Schlüsselpaare (simuliert Alice und Bob):
   ```bash
   openssl genpkey -algorithm X25519 -out alice_private.pem
   openssl pkey -in alice_private.pem -pubout -out alice_public.pem

   openssl genpkey -algorithm X25519 -out bob_private.pem
   openssl pkey -in bob_private.pem -pubout -out bob_public.pem
   ```
2. Leite auf beiden "Seiten" das gemeinsame Geheimnis ab – Alice nutzt ihren privaten und Bobs öffentlichen Schlüssel, Bob umgekehrt:
   ```bash
   openssl pkeyutl -derive -inkey alice_private.pem -peerkey bob_public.pem -out alice_shared.bin
   openssl pkeyutl -derive -inkey bob_private.pem -peerkey alice_public.pem -out bob_shared.bin
   ```
3. Vergleiche die beiden abgeleiteten Geheimnisse:
   ```bash
   cmp alice_shared.bin bob_shared.bin && echo "Identisch - Schluesseltausch erfolgreich!"
   ```

**Reflexion**: Nur die beiden öffentlichen Schlüssel wurden zwischen Alice und Bob ausgetauscht. Warum reicht das aus, damit beide zum selben gemeinsamen Geheimnis kommen, ein Angreifer, der nur die öffentlichen Schlüssel abhört, aber nicht?

### Übung 2: ECDH in Python nachvollziehen
**Ziel**: Denselben Ablauf programmatisch verstehen und mit einer symmetrischen Verschlüsselung kombinieren.

1. Erstelle ein Python-Skript:
   ```bash
   nano ecdh_beispiel.py
   ```
   ```python
   from cryptography.hazmat.primitives.asymmetric.x25519 import X25519PrivateKey
   from cryptography.hazmat.primitives.kdf.hkdf import HKDF
   from cryptography.hazmat.primitives import hashes
   from cryptography.hazmat.primitives.ciphers.aead import AESGCM
   import os

   # Schluesselpaare erzeugen (simuliert zwei Kommunikationspartner)
   alice_privat = X25519PrivateKey.generate()
   alice_oeffentlich = alice_privat.public_key()

   bob_privat = X25519PrivateKey.generate()
   bob_oeffentlich = bob_privat.public_key()

   # Beide Seiten leiten unabhaengig dasselbe Geheimnis ab
   alice_geheimnis = alice_privat.exchange(bob_oeffentlich)
   bob_geheimnis = bob_privat.exchange(alice_oeffentlich)
   assert alice_geheimnis == bob_geheimnis

   # Das rohe DH-Geheimnis wird per HKDF in einen AES-Schluessel ueberfuehrt
   # (ein rohes DH-Ergebnis direkt als Schluessel zu nutzen, gilt als unsauber)
   aes_schluessel = HKDF(
       algorithm=hashes.SHA256(), length=32, salt=None, info=b"ecdh-beispiel",
   ).derive(alice_geheimnis)

   aesgcm = AESGCM(aes_schluessel)
   nonce = os.urandom(12)
   geheimtext = aesgcm.encrypt(nonce, b"Nachricht ueber ECDH-Kanal", None)
   print(f"Gemeinsames Geheimnis erfolgreich abgeleitet und genutzt: {geheimtext.hex()}")
   ```
2. Führe das Skript aus und beobachte, dass `alice_geheimnis == bob_geheimnis` ohne Fehler durchläuft.

**Reflexion**: Warum wird das rohe ECDH-Ergebnis hier nicht direkt als AES-Schlüssel verwendet, sondern zusätzlich durch eine Key Derivation Function (HKDF) geschickt?

## Tipps für den Erfolg
- X25519 statt klassischer NIST-Kurven (z. B. P-256) bevorzugen, wenn die Wahl offensteht – X25519 ist einfacher korrekt zu implementieren und weniger anfällig für bestimmte Seitenkanal- und Implementierungsfehler.
- Für neue Systeme: RSA nur noch dort, wo Interoperabilität mit älteren Systemen es zwingend erfordert; sonst ECC (X25519/Ed25519) bevorzugen.
- DH/ECDH liefert nur Vertraulichkeit für das ausgetauschte Geheimnis, keine Authentizität – ohne zusätzliche Signatur oder Zertifikate kann ein Man-in-the-Middle sich als Gegenstelle ausgeben (siehe Zertifikate/PKI in [34_PKI](../34_PKI/)).

## Fazit
ECC-basierter Schlüsseltausch (X25519/ECDH) ist heute Standard für performanten, sicheren Schlüsseltausch – von TLS 1.3 bis WireGuard. Wichtig ist, das Ergebnis über eine KDF zu verarbeiten, statt es roh zu verwenden. Als Nächstes folgt der Gegenpart zum Schlüsseltausch: digitale Signaturen mit Ed25519.

**Nächste Schritte**: Weiter mit [04_digitale_signaturen.md](04_digitale_signaturen.md).

**Quellen**:
- RFC 7748 (X25519/X448): https://datatracker.ietf.org/doc/html/rfc7748
- Python `cryptography`-Dokumentation (X25519): https://cryptography.io/en/latest/hazmat/primitives/asymmetric/x25519/
