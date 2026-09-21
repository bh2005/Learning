# Ausblick: Post-Quantum-Kryptografie

## Einführung
Alle bisherigen Kapitel dieser Reihe – RSA, ECC/X25519, Ed25519 – beruhen auf mathematischen Problemen (Faktorisierung großer Zahlen, diskreter Logarithmus auf elliptischen Kurven), die für klassische Computer praktisch unlösbar sind. Ein ausreichend leistungsfähiger **Quantencomputer** könnte diese Probleme mit dem sogenannten Shor-Algorithmus jedoch effizient lösen und damit RSA und ECC vollständig brechen. Diese abschließende Anleitung ist bewusst ein **Ausblick statt einer tiefen Praxisanleitung**: Sie erklärt, warum das Thema schon heute relevant ist, obwohl kryptografisch relevante Quantencomputer noch nicht existieren, und macht mit den aktuell standardisierten Verfahren vertraut.

**Voraussetzungen**:
- Kenntnisse aus den vorherigen Kapiteln dieser Reihe (insbesondere [03_asymmetrische_verschluesselung_und_schluesseltausch.md](03_asymmetrische_verschluesselung_und_schluesseltausch.md)).
- Ein aktuelles Linux-System mit `openssl` (für Übung 1; ältere Versionen liefern hier einfach ein leeres Ergebnis, was auch ein gültiges Lernresultat ist).

## Grundlegende Konzepte

- **"Harvest now, decrypt later"**: Ein Angreifer kann heute verschlüsselten Datenverkehr aufzeichnen und speichern, ohne ihn entschlüsseln zu können – um ihn erst in einigen Jahren mit einem dann verfügbaren Quantencomputer nachträglich zu entschlüsseln. Für Daten mit langer Vertraulichkeitsanforderung (Staatsgeheimnisse, Gesundheitsdaten, langfristige Geschäftsgeheimnisse) ist das schon **heute** ein reales Risiko, auch ohne existierenden Quantencomputer.
- **Was betroffen ist**: Vor allem asymmetrische Verfahren (RSA, ECC/DH für Schlüsseltausch und Signaturen). Symmetrische Verfahren wie AES sind deutlich weniger betroffen – ein Quantencomputer (Grover-Algorithmus) halbiert effektiv die Schlüssellänge, AES-256 bleibt daher mit effektiv ~128 Bit Sicherheit ausreichend robust.
- **NIST-Standardisierung**: Nach einem mehrjährigen, offenen Auswahlverfahren hat das NIST 2024 die ersten Post-Quantum-Standards veröffentlicht:
  - **ML-KEM** (FIPS 203, basierend auf CRYSTALS-Kyber) – für Schlüsseltausch/Verschlüsselung, der Nachfolger für die Rolle von ECDH/RSA-Schlüsseltausch.
  - **ML-DSA** (FIPS 204, basierend auf CRYSTALS-Dilithium) – für digitale Signaturen, der Nachfolger für die Rolle von Ed25519/RSA-Signaturen.
  - **SLH-DSA** (FIPS 205, basierend auf SPHINCS+) – ein zweites, konservativeres Signaturverfahren auf anderer mathematischer Basis, als Absicherung falls ML-DSA sich doch als angreifbar erweisen sollte.
- **Hybrid-Ansatz**: Aktuelle Empfehlung (u. a. von Browsern, OpenSSH und TLS-Implementierungen bereits umgesetzt) ist **nicht**, klassische Verfahren sofort zu ersetzen, sondern sie mit PQC-Verfahren zu **kombinieren** (z. B. X25519 + ML-KEM gemeinsam). Ein Angreifer müsste dann sowohl das klassische als auch das PQC-Verfahren brechen – das schützt vor unentdeckten Schwächen in den noch jungen PQC-Algorithmen, ohne auf deren Schutz gegen Quantenangriffe zu verzichten.

## Übungen zum Verinnerlichen

### Übung 1: Post-Quantum-Unterstützung im eigenen System prüfen
**Ziel**: Feststellen, ob die vorhandene OpenSSL-Version bereits PQC-Algorithmen unterstützt.

1. Prüfe die installierte OpenSSL-Version:
   ```bash
   openssl version
   ```
2. Prüfe, ob KEM-Algorithmen (Key Encapsulation Mechanisms) gelistet werden:
   ```bash
   openssl list -kem-algorithms
   ```
   Neuere OpenSSL-Versionen zeigen hier u. a. `ML-KEM-512`, `ML-KEM-768` oder `ML-KEM-1024`. Erscheint nichts oder ein Fehler, unterstützt die installierte Version noch keine nativen PQC-Algorithmen – dann ist das Ergebnis selbst die Lernerfahrung: Adoption von PQC ist noch im Rollout und hängt stark von der Softwareversion ab.
3. Falls verfügbar, sieh dir probeweise ein ML-KEM-Schlüsselpaar an:
   ```bash
   openssl genpkey -algorithm ML-KEM-768 -out mlkem_test.pem 2>/dev/null && openssl pkey -in mlkem_test.pem -text -noout | head -20
   ```

**Reflexion**: Was bedeutet es für die Migration ganzer Organisationen, wenn PQC-Unterstützung nicht in jeder installierten Software-Version gleichermaßen vorhanden ist?

### Übung 2: Harvest-now-decrypt-later einordnen (Recherche/Diskussion)
**Ziel**: Das eigene Umfeld auf PQC-Relevanz einschätzen – ohne dass dafür bereits PQC-fähige Software nötig ist.

1. Überlege für 2–3 Arten von Daten in einem typischen Unternehmensnetzwerk (siehe auch die allgemeine Übersicht der wichtigsten Unternehmensdienste), wie lange diese jeweils vertraulich bleiben müssen: z. B. eine interne Chat-Nachricht von heute vs. ein langfristiger Forschungs- oder Konstruktionsplan.
2. Recherchiere, welche gängige Software in den letzten Jahren bereits Hybrid-PQC standardmäßig oder optional aktiviert hat (Stichworte: "Chrome X25519Kyber768", "OpenSSH sntrup761x25519" bzw. neuere "mlkem768x25519").
3. Notiere in 3–4 Sätzen: Für welche der eigenen (oder fiktiven) Daten aus Schritt 1 wäre "harvest now, decrypt later" ein reales Risiko, und für welche eher nicht?

**Reflexion**: Warum reicht es nicht, mit der PQC-Migration zu warten, bis ein Quantencomputer, der RSA/ECC brechen kann, tatsächlich existiert?

## Tipps für den Erfolg
- PQC ist kein Ersatz für gute Kryptografie-Grundlagen aus den vorherigen Kapiteln – es kommt on top, sobald die verwendete Software/Bibliothek es unterstützt.
- Bei der Systemplanung schon jetzt auf **Krypto-Agilität** achten: Systeme so gestalten, dass sich Algorithmen austauschen lassen, ohne die gesamte Architektur umbauen zu müssen.
- Hybrid-Verfahren (klassisch + PQC) sind aktuell der pragmatische Stand der Technik – nicht vorschnell rein-PQC einsetzen, solange die Verfahren noch relativ neu sind.

## Fazit
Post-Quantum-Kryptografie ist kein Zukunftsthema mehr, sondern mit den NIST-Standards ML-KEM, ML-DSA und SLH-DSA bereits Realität – die praktische Verbreitung in Alltagssoftware läuft aber noch an. Wer heute Systeme mit langfristigem Vertraulichkeitsbedarf betreibt, sollte "harvest now, decrypt later" ernst nehmen und Hybrid-Verfahren im Blick behalten, sobald die eingesetzte Software sie unterstützt.

Damit ist die Reihe zu moderner Kryptografie abgeschlossen: von Hashing über symmetrische und asymmetrische Verschlüsselung, digitale Signaturen und Passwort-Hashing bis zum Ausblick auf Post-Quantum-Verfahren. Für die praktische Anwendung dieser Bausteine in echten TLS-Zertifikaten geht es weiter in [13_TLS_Verschlüsselung](../13_TLS_Verschlüsselung/).

**Quellen**:
- NIST FIPS 203 (ML-KEM): https://csrc.nist.gov/pubs/fips/203/final
- NIST FIPS 204 (ML-DSA): https://csrc.nist.gov/pubs/fips/204/final
- NIST FIPS 205 (SLH-DSA): https://csrc.nist.gov/pubs/fips/205/final
- NIST Post-Quantum Cryptography Project: https://csrc.nist.gov/projects/post-quantum-cryptography
