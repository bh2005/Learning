# Praxisorientierte Anleitung: Einstieg in Kryptographie und Verschlüsselung auf Debian

## Einführung
Kryptographie ist die Wissenschaft der Sicherung von Informationen durch Umwandlung in ein Format, das nur von autorisierten Benutzern gelesen werden kann. Sie umfasst Techniken wie Verschlüsselung, Hashing und digitale Signaturen, die in der modernen Informationssicherheit eine zentrale Rolle spielen. Diese Anleitung führt Sie in die Anwendung grundlegender kryptographischer Techniken auf einem Debian-System ein, einschließlich symmetrischer und asymmetrischer Verschlüsselung sowie Hashing. Sie lernen, wie Sie mit OpenSSL und GPG Daten verschlüsseln und entschlüsseln sowie eine Python-Anwendung für kryptographische Operationen erstellen. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, Daten sicher zu schützen und Integrität zu gewährleisten. Diese Anleitung ist ideal für Einsteiger in die Kryptographie, die praktische Erfahrungen sammeln möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Python 3 installiert
- Mindestens 2 GB RAM und ausreichend Festplattenspeicher (mindestens 5 GB frei)
- Grundlegende Kenntnisse der Linux-Kommandozeile und Python
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie VS Code)

## Grundlegende Kryptographie-Konzepte und Tools
Hier sind die wichtigsten Konzepte und Tools, die wir behandeln:

1. **Kryptographie-Konzepte**:
   - **Symmetrische Verschlüsselung**: Nutzt denselben Schlüssel zum Ver- und Entschlüsseln (z. B. AES)
   - **Asymmetrische Verschlüsselung**: Nutzt ein Schlüsselpaar (privater und öffentlicher Schlüssel, z. B. RSA)
   - **Hashing**: Erzeugt einen festen Fingerabdruck von Daten (z. B. SHA-256)
   - **Digitale Signaturen**: Gewährleisten Authentizität und Integrität
2. **Wichtige Tools**:
   - **OpenSSL**: Vielseitiges Tool für Verschlüsselung, Zertifikate und Hashing
   - **GPG (GnuPG)**: Tool für asymmetrische Verschlüsselung und Signaturen
   - **Python-Bibliotheken**: `cryptography` für programmgesteuerte Kryptographie
3. **Wichtige Befehle**:
   - `openssl`: Führt Verschlüsselungs- und Hashing-Operationen aus
   - `gpg`: Ver- und Entschlüsselt Daten sowie erstellt Signaturen
   - `python3`: Führt Python-Skripte für kryptographische Aufgaben aus

## Übungen zum Verinnerlichen

### Übung 1: Symmetrische Verschlüsselung mit OpenSSL
**Ziel**: Lernen, wie man Dateien mit AES (symmetrische Verschlüsselung) verschlüsselt und entschlüsselt.

1. **Schritt 1**: Installiere OpenSSL (falls nicht bereits vorhanden).
   ```bash
   sudo apt update
   sudo apt install -y openssl
   ```
2. **Schritt 2**: Erstelle eine Testdatei.
   ```bash
   echo "Geheime Nachricht" > secret.txt
   ```
3. **Schritt 3**: Verschlüssle die Datei mit AES-256-CBC.
   ```bash
   openssl enc -aes-256-cbc -salt -in secret.txt -out secret.txt.enc -k meinpasswort
   ```
   - `-aes-256-cbc`: Verschlüsselungsalgorithmus
   - `-salt`: Fügt Zufälligkeit hinzu
   - `-k meinpasswort`: Passwort für die Verschlüsselung
4. **Schritt 4**: Entschlüssle die Datei.
   ```bash
   openssl enc -aes-256-cbc -d -in secret.txt.enc -out decrypted.txt -k meinpasswort
   ```
   Überprüfe den Inhalt:
   ```bash
   cat decrypted.txt
   ```
   Die Ausgabe sollte sein: `Geheime Nachricht`.

**Reflexion**: Warum ist symmetrische Verschlüsselung schnell, aber wie könnte die sichere Übertragung des Schlüssels problematisch sein?

### Übung 2: Asymmetrische Verschlüsselung mit GPG
**Ziel**: Verstehen, wie man ein GPG-Schlüsselpaar erstellt, Dateien verschlüsselt und entschlüsselt.

1. **Schritt 1**: Installiere GnuPG.
   ```bash
   sudo apt install -y gnupg
   ```
2. **Schritt 2**: Erstelle ein GPG-Schlüsselpaar.
   ```bash
   gpg --full-generate-key
   ```
   - Wähle RSA (Standard) und 2048 Bit.
   - Gib einen Namen (z. B. `Test User`), eine E-Mail (z. B. `test@example.com`) und ein Passwort ein.
   - Liste die Schlüssel auf:
     ```bash
     gpg --list-keys
     ```
3. **Schritt 3**: Verschlüssle eine Datei mit dem öffentlichen Schlüssel.
   ```bash
   echo "Top Secret" > topsecret.txt
   gpg --encrypt --recipient test@example.com topsecret.txt
   ```
   Dies erstellt `topsecret.txt.gpg`.
4. **Schritt 4**: Entschlüssle die Datei mit dem privaten Schlüssel.
   ```bash
   gpg --decrypt topsecret.txt.gpg > decrypted_topsecret.txt
   ```
   Gib das Passwort ein. Überprüfe den Inhalt:
   ```bash
   cat decrypted_topsecret.txt
   ```
   Die Ausgabe sollte sein: `Top Secret`.

**Reflexion**: Wie unterscheidet sich asymmetrische Verschlüsselung von symmetrischer, und warum ist sie für sichere Kommunikation geeignet?

### Übung 3: Kryptographie mit Python und Hashing
**Ziel**: Lernen, wie man mit der Python-Bibliothek `cryptography` verschlüsselt und Hashes erstellt.

1. **Schritt 1**: Installiere die `cryptography`-Bibliothek.
   ```bash
   pip3 install cryptography
   ```
2. **Schritt 2**: Erstelle ein Python-Skript für symmetrische Verschlüsselung und Hashing.
   ```bash
   nano crypto_example.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from cryptography.fernet import Fernet
   from cryptography.hazmat.primitives import hashes
   from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
   import base64
   import os

   # Symmetrische Verschlüsselung
   key = Fernet.generate_key()
   fernet = Fernet(key)
   message = "Geheime Python-Nachricht".encode()
   encrypted = fernet.encrypt(message)
   decrypted = fernet.decrypt(encrypted)
   print(f"Verschlüsselt: {encrypted}")
   print(f"Entschlüsselt: {decrypted.decode()}")

   # Hashing
   digest = hashes.Hash(hashes.SHA256())
   digest.update(message)
   hash_value = digest.finalize()
   print(f"SHA-256 Hash: {hash_value.hex()}")
   ```
3. **Schritt 3**: Führe das Skript aus.
   ```bash
   python3 crypto_example.py
   ```
   Die Ausgabe zeigt die verschlüsselte Nachricht, die entschlüsselte Nachricht und den SHA-256-Hash.

**Reflexion**: Wie vereinfacht die `cryptography`-Bibliothek kryptographische Operationen, und warum ist Hashing für die Datenintegrität wichtig?

## Tipps für den Erfolg
- Überprüfe die OpenSSL- und GPG-Dokumentation bei Problemen (`man openssl`, `man gpg`).
- Sichere Passwörter und Schlüssel in einer Produktionsumgebung mit einem Passwort-Manager oder Vault.
- Verwende `openssl version` oder `gpg --version`, um sicherzustellen, dass die Tools aktuell sind.
- Teste mit kleinen Datenmengen, bevor du größere Dateien verschlüsselst.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie grundlegende kryptographische Techniken auf einem Debian-System anwenden, einschließlich symmetrischer Verschlüsselung mit OpenSSL, asymmetrischer Verschlüsselung mit GPG und programmgesteuerter Kryptographie mit Python. Durch die Übungen haben Sie praktische Erfahrung mit Verschlüsselung, Entschlüsselung und Hashing gesammelt. Diese Fähigkeiten sind die Grundlage für die Absicherung von Daten und Kommunikation. Üben Sie weiter, um komplexere Szenarien wie digitale Signaturen oder Zertifikate zu meistern!

**Nächste Schritte**:
- Erkunden Sie fortgeschrittene OpenSSL-Features wie die Erstellung von Zertifikaten für TLS.
- Integrieren Sie GPG in E-Mail-Clients für sichere Kommunikation.
- Entwickeln Sie Python-Anwendungen mit komplexeren kryptographischen Protokollen.

**Quellen**:
- OpenSSL-Dokumentation: https://www.openssl.org/docs/
- GnuPG-Dokumentation: https://www.gnupg.org/documentation/
- Python Cryptography-Dokumentation: https://cryptography.io/en/latest/
- DigitalOcean OpenSSL-Tutorial: https://www.digitalocean.com/community/tutorials/openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs