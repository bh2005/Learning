# Praxisorientierte Anleitung: Hashing und Integrität

## Einführung
Diese Reihe zu **moderner Kryptografie** baut auf dem Einstieg in [13_TLS_Verschlüsselung/02_kryptographie_einstieg.md](../13_TLS_Verschlüsselung/02_kryptographie_einstieg.md) auf und geht tiefer auf die Bausteine ein, mit denen moderne Systeme tatsächlich arbeiten. Diese erste Anleitung behandelt **Hash-Funktionen**: wie sie funktionieren, warum ältere Algorithmen wie MD5 und SHA-1 nicht mehr verwendet werden sollten, und wie man mit **HMAC** nicht nur die Integrität, sondern auch die Authentizität einer Nachricht prüft.

**Voraussetzungen**:
- Ein Linux-System (z. B. Debian 12/13) mit `openssl` und Python 3.
- Grundkenntnisse der Linux-Kommandozeile.
- `pip3 install cryptography` (falls noch nicht installiert).

## Grundlegende Konzepte

- **Hash-Funktion**: Bildet beliebig große Eingabedaten auf einen Ausgabewert fester Länge (den "Fingerabdruck" oder Digest) ab. Gute Hash-Funktionen sind **deterministisch** (gleiche Eingabe → gleiche Ausgabe), **einweg** (aus dem Hash lässt sich die Eingabe nicht rekonstruieren) und **kollisionsresistent** (es ist praktisch unmöglich, zwei unterschiedliche Eingaben mit demselben Hash zu finden).
- **MD5 und SHA-1 gelten als gebrochen**: Für beide sind praktikable Kollisionsangriffe bekannt. Sie dürfen für Integritätsprüfungen und erst recht nicht für Signaturen mehr verwendet werden – allenfalls noch für nicht-sicherheitsrelevante Zwecke wie z. B. Duplikaterkennung.
- **SHA-256 / SHA-3**: Aktueller Standard. SHA-256 (Teil der SHA-2-Familie) ist am weitesten verbreitet, SHA-3 nutzt eine andere interne Konstruktion (Keccak) als zusätzliche Absicherung, falls jemals eine strukturelle Schwäche in SHA-2 gefunden würde.
- **HMAC (Hash-based Message Authentication Code)**: Kombiniert einen geheimen Schlüssel mit einer Hash-Funktion. Ein einfacher Hash beweist nur, dass Daten unverändert sind – jeder kann ihn neu berechnen. HMAC beweist zusätzlich, dass die Nachricht von jemandem mit dem geheimen Schlüssel stammt (Authentizität), nicht nur, dass sie unverändert ist (Integrität).

## Übungen zum Verinnerlichen

### Übung 1: Warum MD5 und SHA-1 nicht mehr sicher sind
**Ziel**: Den Unterschied zwischen den Hash-Algorithmen praktisch sehen.

1. Erzeuge Hashes derselben Datei mit verschiedenen Algorithmen:
   ```bash
   echo "Testnachricht" > nachricht.txt
   openssl dgst -md5 nachricht.txt
   openssl dgst -sha1 nachricht.txt
   openssl dgst -sha256 nachricht.txt
   ```
2. Ändere die Datei minimal (ein Zeichen) und wiederhole die Hashes:
   ```bash
   echo "Testnachricht!" > nachricht.txt
   openssl dgst -sha256 nachricht.txt
   ```
   Beobachte: Schon eine winzige Änderung der Eingabe führt zu einem komplett anderen Hash (**Avalanche-Effekt**).
3. Lies kurz nach, was ein "Kollisionsangriff" bedeutet (z. B. Stichwort "SHAttered attack" für SHA-1).

**Reflexion**: Wenn zwei Dateien mit MD5 denselben Hash erzeugen können (Kollision), was bedeutet das konkret für eine Software, die MD5 zur Integritätsprüfung von Downloads nutzt?

### Übung 2: HMAC – Integrität und Authentizität mit Python
**Ziel**: Verstehen, warum ein einfacher Hash nicht ausreicht, um die Herkunft einer Nachricht zu belegen.

1. Erstelle ein Python-Skript:
   ```bash
   nano hmac_beispiel.py
   ```
   ```python
   import hmac
   import hashlib

   geheimer_schluessel = b"unser-gemeinsames-geheimnis"
   nachricht = b"Ueberweisung: 500 EUR an Konto 12345"

   # Ein einfacher Hash - jeder kann ihn nachrechnen
   einfacher_hash = hashlib.sha256(nachricht).hexdigest()
   print(f"SHA-256 Hash: {einfacher_hash}")

   # HMAC - nur mit Kenntnis des Schluessels nachvollziehbar
   mac = hmac.new(geheimer_schluessel, nachricht, hashlib.sha256).hexdigest()
   print(f"HMAC-SHA256: {mac}")

   # Verifikation auf der Empfaengerseite
   empfangene_nachricht = b"Ueberweisung: 500 EUR an Konto 12345"
   erwarteter_mac = hmac.new(geheimer_schluessel, empfangene_nachricht, hashlib.sha256).hexdigest()
   print("Gueltig!" if hmac.compare_digest(mac, erwarteter_mac) else "UNGUELTIG!")
   ```
2. Führe das Skript aus:
   ```bash
   python3 hmac_beispiel.py
   ```
3. Ändere in der Nachricht den Betrag ("500 EUR" → "5000 EUR") **nur** in der `empfangene_nachricht`-Zeile und führe es erneut aus. Die Verifikation muss fehlschlagen.

**Reflexion**: Ein Angreifer kennt den Inhalt der Nachricht und den zugehörigen einfachen SHA-256-Hash, aber nicht den geheimen Schlüssel. Kann er die Nachricht unbemerkt verändern und einen passenden neuen Hash berechnen? Kann er das bei HMAC?

## Tipps für den Erfolg
- Verwende `hmac.compare_digest()` statt `==` zum Vergleich von MACs/Hashes – ein normaler String-Vergleich kann durch Timing-Unterschiede Informationen preisgeben (Timing-Angriff).
- Für neue Systeme: SHA-256 oder SHA-3 als Minimum, HMAC-SHA256 wenn Authentizität statt nur Integrität gefordert ist.
- MD5/SHA-1 nur noch dort einsetzen (falls überhaupt), wo keinerlei Sicherheitsanforderung besteht.

## Fazit
Hash-Funktionen sind der Grundbaustein für Integritätsprüfung, HMAC erweitert das Konzept um Authentizität. Die Wahl des richtigen Algorithmus (SHA-256/SHA-3 statt MD5/SHA-1) ist der einfachste, aber oft übersehene Schritt zu mehr Sicherheit. Im nächsten Schritt geht es um symmetrische Verschlüsselung mit AES-GCM, die Verschlüsselung und Integritätsprüfung in einem Schritt kombiniert.

**Nächste Schritte**: Weiter mit [02_symmetrische_verschluesselung_aes_gcm.md](02_symmetrische_verschluesselung_aes_gcm.md).

**Quellen**:
- NIST FIPS 180-4 (Secure Hash Standard): https://csrc.nist.gov/publications/detail/fips/180/4/final
- Python `hmac`-Dokumentation: https://docs.python.org/3/library/hmac.html
