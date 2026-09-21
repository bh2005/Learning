# Praxisorientierte Anleitung: Symmetrische Verschlüsselung mit AES-GCM

## Einführung
Im [Kryptografie-Einstieg](../13_TLS_Verschlüsselung/02_kryptographie_einstieg.md) wurde AES-256-**CBC** verwendet. CBC verschlüsselt Daten zuverlässig, sagt aber nichts darüber aus, ob die verschlüsselten Daten unterwegs manipuliert wurden – dafür bräuchte man zusätzlich einen HMAC (siehe [01_hashing_und_integritaet.md](01_hashing_und_integritaet.md)). Moderne Systeme verwenden deshalb **AES-GCM**, einen sogenannten **AEAD-Modus** (Authenticated Encryption with Associated Data), der Verschlüsselung und Integritätsprüfung in einem einzigen Schritt kombiniert.

**Voraussetzungen**:
- Ein Linux-System mit `openssl` (Version 1.1.1+) und Python 3.
- `pip3 install cryptography`.
- Kenntnisse aus [01_hashing_und_integritaet.md](01_hashing_und_integritaet.md).

## Grundlegende Konzepte

- **AEAD (Authenticated Encryption with Associated Data)**: Ein Verschlüsselungsmodus, der beim Entschlüsseln automatisch erkennt, ob der Geheimtext (oder mitgesendete Zusatzdaten) verändert wurde – die Entschlüsselung schlägt dann kontrolliert fehl, statt stillschweigend falsche Daten zu liefern.
- **Nonce/IV**: Ein Initialisierungswert, der bei GCM **pro Verschlüsselung mit demselben Schlüssel einzigartig** sein muss. Wird eine Nonce mit demselben Schlüssel wiederverwendet, bricht die Sicherheit von GCM vollständig zusammen – das ist der häufigste reale Implementierungsfehler.
- **Auth Tag**: Ein zusätzlicher Wert, den GCM bei der Verschlüsselung erzeugt und der bei der Entschlüsselung geprüft wird, um Manipulation zu erkennen.
- **Warum nicht mehr CBC/ECB**: ECB verrät durch identische Chiffretext-Blöcke bei identischen Klartext-Blöcken Strukturinformationen (klassisches Beispiel: ein ECB-verschlüsseltes Bild, in dem noch Konturen erkennbar sind). CBC ist ohne zusätzlichen MAC anfällig für Padding-Oracle-Angriffe und Manipulation des Geheimtexts ohne Erkennung.

## Übungen zum Verinnerlichen

### Übung 1: AES-GCM mit OpenSSL
**Ziel**: Eine Datei mit AES-256-GCM verschlüsseln und die eingebaute Integritätsprüfung erleben.

1. Erstelle eine Testdatei und verschlüssle sie:
   ```bash
   echo "Vertrauliche Information" > geheim.txt
   openssl enc -aes-256-gcm -salt -pbkdf2 -in geheim.txt -out geheim.txt.enc -k meinpasswort
   ```
2. Entschlüssle sie wieder:
   ```bash
   openssl enc -aes-256-gcm -d -pbkdf2 -in geheim.txt.enc -out entschluesselt.txt -k meinpasswort
   cat entschluesselt.txt
   ```
3. Manipuliere nun testweise ein Byte der verschlüsselten Datei und versuche erneut zu entschlüsseln:
   ```bash
   cp geheim.txt.enc geheim_manipuliert.enc
   printf '\xff' | dd of=geheim_manipuliert.enc bs=1 seek=20 count=1 conv=notrunc
   openssl enc -aes-256-gcm -d -pbkdf2 -in geheim_manipuliert.enc -out sollte_fehlschlagen.txt -k meinpasswort
   ```
   Die Entschlüsselung sollte mit einem Fehler abbrechen, statt (wie bei reinem CBC) einfach kaputte Daten auszugeben.

**Reflexion**: Was wäre bei reinem AES-CBC ohne zusätzlichen HMAC beim selben Manipulationsversuch passiert?

### Übung 2: AES-GCM in Python – und der Nonce-Wiederverwendungs-Fehler
**Ziel**: Den korrekten Umgang mit Nonces verstehen und den häufigsten Implementierungsfehler selbst nachvollziehen.

1. Erstelle ein Python-Skript:
   ```bash
   nano aes_gcm_beispiel.py
   ```
   ```python
   import os
   from cryptography.hazmat.primitives.ciphers.aead import AESGCM

   schluessel = AESGCM.generate_key(bit_length=256)
   aesgcm = AESGCM(schluessel)

   def verschluessle(klartext: bytes) -> tuple[bytes, bytes]:
       nonce = os.urandom(12)  # 96 Bit - Standard fuer GCM, PRO NACHRICHT NEU erzeugen
       geheimtext = aesgcm.encrypt(nonce, klartext, associated_data=None)
       return nonce, geheimtext

   nonce1, ct1 = verschluessle(b"Erste Nachricht")
   nonce2, ct2 = verschluessle(b"Zweite Nachricht")
   print(f"Nonce 1: {nonce1.hex()}")
   print(f"Nonce 2: {nonce2.hex()}")

   # Korrekte Entschluesselung
   klartext1 = aesgcm.decrypt(nonce1, ct1, associated_data=None)
   print(f"Entschluesselt: {klartext1.decode()}")
   ```
2. Führe das Skript mehrfach aus und beobachte, dass sich die Nonces bei jedem Lauf unterscheiden.
3. Baue absichtlich den Fehler ein: Verwende `nonce1` auch für die Verschlüsselung von `ct2` (also dieselbe Nonce zweimal mit demselben Schlüssel) und recherchiere, warum genau das in der Praxis (z. B. bei einigen historischen VPN- oder WLAN-Implementierungen) zu realen Angriffen geführt hat.

**Reflexion**: Warum reicht es bei GCM nicht, die Nonce nur "zufällig genug" zu wählen, sondern warum muss zusätzlich sichergestellt sein, dass sie pro Schlüssel nie zweimal vorkommt?

## Tipps für den Erfolg
- Nutze für Nonces bei GCM entweder einen kryptografisch sicheren Zufallsgenerator (`os.urandom`) mit ausreichend Nachrichtenvolumen im Blick, oder einen garantiert eindeutigen Zähler pro Schlüssel.
- Rotiere Schlüssel, statt eine unbegrenzte Zahl an Nachrichten mit demselben Schlüssel zu verschlüsseln – das reduziert das Risiko einer Nonce-Kollision zusätzlich.
- In der Praxis: Bibliotheken wie `cryptography` oder Protokolle wie TLS 1.3 kümmern sich um die korrekte Nonce-Verwaltung – von Hand AES-GCM zu implementieren ist ein guter Lerneffekt, aber in Produktivsystemen sollte man auf etablierte Protokolle statt Eigenbau setzen.

## Fazit
AES-GCM vereint Verschlüsselung und Integritätsprüfung in einem AEAD-Modus und ist heute der Standardmodus für symmetrische Verschlüsselung (auch in TLS 1.3). Der kritische Punkt ist die korrekte, einmalige Verwendung jeder Nonce pro Schlüssel. Im nächsten Schritt geht es um asymmetrische Verschlüsselung und modernen Schlüsseltausch mit elliptischen Kurven.

**Nächste Schritte**: Weiter mit [03_asymmetrische_verschluesselung_und_schluesseltausch.md](03_asymmetrische_verschluesselung_und_schluesseltausch.md).

**Quellen**:
- NIST SP 800-38D (GCM-Spezifikation): https://csrc.nist.gov/publications/detail/sp/800-38d/final
- Python `cryptography`-Dokumentation (AEAD): https://cryptography.io/en/latest/hazmat/primitives/aead/
