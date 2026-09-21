# Praxisorientierte Anleitung: Sicheres Passwort-Hashing mit Argon2

## Einführung
In [01_hashing_und_integritaet.md](01_hashing_und_integritaet.md) wurde SHA-256 als moderner, sicherer Hash-Algorithmus vorgestellt – für **Passwörter** ist SHA-256 (und jede andere "normale" Hash-Funktion) trotzdem die falsche Wahl. Der Grund: SHA-256 ist *absichtlich* extrem schnell, das ist bei Integritätsprüfungen ein Vorteil, bei Passwörtern aber ein Sicherheitsproblem, da ein Angreifer mit gestohlenen Hashes Milliarden Passwörter pro Sekunde durchprobieren kann. Für Passwörter braucht man **absichtlich langsame**, speicherintensive Hash-Funktionen wie **Argon2** (aktuelle OWASP-Empfehlung) oder **bcrypt**.

**Voraussetzungen**:
- Ein Linux-System mit Python 3.
- `pip3 install argon2-cffi bcrypt`.

## Grundlegende Konzepte

- **Warum SHA-256 für Passwörter ungeeignet ist**: Handelsübliche GPUs berechnen Milliarden von SHA-256-Hashes pro Sekunde. Bei einem Datenleck mit SHA-256-gehashten Passwörtern lassen sich schwache/häufige Passwörter (z. B. via Rainbow-Tables oder Brute-Force) in kurzer Zeit zurückrechnen.
- **Salt**: Ein zufälliger Wert pro Passwort, der mit gehasht wird. Verhindert, dass zwei Nutzer mit demselben Passwort denselben Hash haben, und macht vorberechnete Rainbow-Tables wirkungslos. Moderne Bibliotheken (Argon2, bcrypt) erzeugen und verwalten den Salt automatisch.
- **Absichtliche Langsamkeit ("Key Stretching")**: Argon2 und bcrypt sind konfigurierbar langsam (Zeit-, Speicher- und Parallelitäts-Parameter), sodass ein einzelner Hash-Vorgang für den echten Login kaum spürbar ist (Millisekunden), ein Brute-Force-Angriff mit Millionen Versuchen aber unpraktikabel wird.
- **Argon2id**: Die von OWASP empfohlene Variante von Argon2 (Gewinner der Password Hashing Competition 2015). "id" kombiniert Schutz gegen GPU-Angriffe (hoher Speicherbedarf) mit Schutz gegen Seitenkanalangriffe.
- **bcrypt**: Älter als Argon2, aber immer noch weit verbreitet und sicher, solange ein ausreichender Kostenfaktor (Work Factor) verwendet wird. Nachteil gegenüber Argon2: geringere Kontrolle über den Speicherbedarf, was es etwas anfälliger für spezialisierte Hardware (GPU/ASIC) macht.

## Übungen zum Verinnerlichen

### Übung 1: Warum ein einfacher SHA-256-Hash für Passwörter nicht reicht
**Ziel**: Die Geschwindigkeit von SHA-256 im Vergleich zu Argon2 praktisch erleben.

1. Miss die Zeit für 100.000 SHA-256-Hashes:
   ```bash
   python3 -c "
   import hashlib, time
   start = time.time()
   for i in range(100_000):
       hashlib.sha256(f'passwort{i}'.encode()).hexdigest()
   print(f'SHA-256: {time.time() - start:.3f} Sekunden fuer 100.000 Hashes')
   "
   ```
2. Miss zum Vergleich die Zeit für nur 100 Argon2-Hashes (bewusst absichtlich langsam):
   ```bash
   python3 -c "
   from argon2 import PasswordHasher
   import time
   ph = PasswordHasher()
   start = time.time()
   for i in range(100):
       ph.hash(f'passwort{i}')
   print(f'Argon2: {time.time() - start:.3f} Sekunden fuer 100 Hashes')
   "
   ```

**Reflexion**: Rechne grob hoch, wie viel länger ein Angreifer für dieselbe Anzahl an Rateversuchen mit Argon2 statt SHA-256 bräuchte. Warum ist das für den echten Login-Vorgang trotzdem kein Problem?

### Übung 2: Passwörter korrekt speichern und prüfen
**Ziel**: Den vollständigen, korrekten Ablauf für Passwort-Speicherung und -Prüfung mit Argon2 umsetzen.

1. Erstelle ein Python-Skript:
   ```bash
   nano passwort_hashing.py
   ```
   ```python
   from argon2 import PasswordHasher
   from argon2.exceptions import VerifyMismatchError

   ph = PasswordHasher()  # nutzt sichere Default-Parameter (Argon2id)

   # Registrierung: Passwort wird gehasht gespeichert, NIE im Klartext
   passwort = "MeinSicheresPasswort123!"
   gespeicherter_hash = ph.hash(passwort)
   print(f"Gespeicherter Hash: {gespeicherter_hash}")

   # Login-Versuch mit korrektem Passwort
   try:
       ph.verify(gespeicherter_hash, "MeinSicheresPasswort123!")
       print("Login erfolgreich!")
   except VerifyMismatchError:
       print("Falsches Passwort!")

   # Login-Versuch mit falschem Passwort
   try:
       ph.verify(gespeicherter_hash, "FalschesPasswort")
       print("Login erfolgreich!")
   except VerifyMismatchError:
       print("Falsches Passwort - wie erwartet abgelehnt.")
   ```
2. Führe das Skript mehrfach aus und vergleiche den `gespeicherter_hash`-Wert zwischen den Läufen – er unterscheidet sich jedes Mal, obwohl das Passwort gleich bleibt (wegen des automatisch generierten Salts), trotzdem funktioniert `verify()` zuverlässig.

**Reflexion**: Der Hash sieht bei jedem Lauf anders aus, obwohl das Passwort identisch ist. Wieso kann `ph.verify()` trotzdem korrekt erkennen, ob das eingegebene Passwort richtig war?

## Tipps für den Erfolg
- Niemals eigene Krypto-Verfahren für Passwort-Hashing erfinden – etablierte, geprüfte Bibliotheken (Argon2, bcrypt) verwenden.
- Niemals Passwörter im Klartext loggen, auch nicht temporär in Debug-Ausgaben.
- Passwort-Hashing-Parameter (Zeit-/Speicherkosten) regelmäßig an aktuelle Hardware anpassen – was 2020 langsam genug war, kann 2026 auf neuerer Hardware zu schnell knackbar sein.
- Zusätzlich zu gutem Hashing: Rate-Limiting und Multi-Faktor-Authentifizierung für Logins einsetzen, um Brute-Force-Versuche gegen den Login selbst (nicht nur gegen gestohlene Hashes) zu erschweren.

## Fazit
Passwörter benötigen bewusst langsame, salted Hash-Verfahren wie Argon2id statt schneller kryptografischer Hash-Funktionen wie SHA-256. Damit endet der praktische Teil dieser Reihe zu moderner Kryptografie – die letzte Anleitung wirft einen Ausblick auf ein Thema, das gerade erst an Bedeutung gewinnt: Post-Quantum-Kryptografie.

**Nächste Schritte**: Weiter mit [06_post_quantum_kryptografie_ausblick.md](06_post_quantum_kryptografie_ausblick.md).

**Quellen**:
- OWASP Password Storage Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html
- Argon2-cffi-Dokumentation: https://argon2-cffi.readthedocs.io/
