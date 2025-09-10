# Praxisorientierte Anleitung: Grundlegende Linux-Kommandozeilenbefehle für Benutzerverwaltung, Sicherheits- und Berechtigungsmanagement sowie Auditing und Logging

## Einführung
Die Linux-Kommandozeile bietet leistungsstarke Werkzeuge zur Verwaltung von Benutzern, Berechtigungen und zur Sicherstellung der Systemsicherheit. Diese Anleitung konzentriert sich auf die Schwerpunkte **Benutzerverwaltung**, **Sicherheits- und Berechtigungsmanagement** sowie **Auditing und Logging**, um Benutzeraktivitäten zu überwachen und Sicherheitsvorfälle zu analysieren. Durch praktische Übungen lernst du, die wichtigsten Befehle direkt anzuwenden und zu verinnerlichen, um ein Linux-System sicher und effizient zu verwalten.

Voraussetzungen:
- Ein Linux-System (z. B. Ubuntu, Debian oder eine virtuelle Maschine).
- Ein Terminal (z. B. über `Ctrl + T` oder ein Terminal-Programm wie `bash`).
- Administratorrechte (`sudo`) für die meisten Befehle, insbesondere bei Benutzer- und Sicherheitsverwaltung.
- Grundlegendes Verständnis von Dateien, Verzeichnissen und Benutzerkonten.
- Sichere Testumgebung (z. B. virtuelle Maschine), um Änderungen ohne Risiko auszuprobieren.

## Grundlegende Befehle
Hier sind die wichtigsten Linux-Befehle, die wir in dieser Anleitung behandeln, aufgeteilt nach den Schwerpunkten:

1. **Benutzerverwaltung**:
   - `useradd`: Erstellt einen neuen Benutzer.
   - `usermod`: Modifiziert Benutzerkonten (z. B. Gruppenzugehörigkeit, Shell).
   - `userdel`: Löscht einen Benutzer.
   - `passwd`: Ändert das Passwort eines Benutzers.
   - `id`: Zeigt Benutzer- und Gruppeninformationen an.
   - `su`: Wechselt zu einem anderen Benutzerkonto.
   - `groupadd`: Erstellt eine neue Gruppe.
2. **Sicherheits- und Berechtigungsmanagement**:
   - `chmod`: Ändert Datei- und Verzeichnisberechtigungen.
   - `chown`: Ändert den Eigentümer oder die Gruppe von Dateien/Verzeichnissen.
   - `chattr`: Setzt erweiterte Dateiattribute (z. B. Schutz vor Änderungen).
   - `lsattr`: Zeigt erweiterte Dateiattribute an.
   - `setfacl`: Setzt Zugriffssteuerungslisten (ACLs) für feingranulare Berechtigungen.
   - `getfacl`: Zeigt Zugriffssteuerungslisten an.
   - `umask`: Legt Standardberechtigungen für neu erstellte Dateien fest.
3. **Auditing und Logging**:
   - `last`: Zeigt die letzten Anmeldungen von Benutzern an.
   - `who`: Zeigt aktuell angemeldete Benutzer.
   - `journalctl`: Zeigt System- und Benutzerlogs an.
   - `auditctl`: Konfiguriert das Audit-Subsystem für detaillierte Überwachung (benötigt `auditd`).
4. **Sonstige nützliche Befehle**:
   - `man`: Zeigt die Hilfeseite eines Befehls an.
   - `sudo`: Führt Befehle mit Administratorrechten aus.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Benutzerverwaltung
**Ziel**: Lerne, wie du Benutzer und Gruppen erstellst, modifizierst und löschst.

1. **Schritt 1**: Erstelle eine neue Gruppe namens `team` (benötigt `sudo`):
   ```bash
   sudo groupadd team
   ```
2. **Schritt 2**: Erstelle einen neuen Benutzer `testuser` mit einem Home-Verzeichnis und weise ihn der Gruppe `team` zu (benötigt `sudo`):
   ```bash
   sudo useradd -m -g team testuser
   ```
   Die Option `-m` erstellt ein Home-Verzeichnis, `-g team` setzt die primäre Gruppe.
3. **Schritt 3**: Setze ein Passwort für `testuser` (benötigt `sudo`):
   ```bash
   sudo passwd testuser
   ```
   Gib ein neues Passwort ein und bestätige es.
4. **Schritt 4**: Überprüfe die Benutzer- und Gruppenzugehörigkeit von `testuser`:
   ```bash
   id testuser
   ```
   Notiere die Benutzer-ID (UID), Gruppen-ID (GID) und Gruppenzugehörigkeiten.
5. **Schritt 5**: Füge `testuser` einer zusätzlichen Gruppe hinzu, z. B. `sudo` (benötigt `sudo`):
   ```bash
   sudo usermod -aG sudo testuser
   ```
   Die Option `-aG` fügt die Gruppe hinzu, ohne bestehende Gruppen zu überschreiben. Überprüfe mit:
   ```bash
   id testuser
   ```
6. **Schritt 6**: Wechsle temporär zum Benutzer `testuser`:
   ```bash
   su - testuser
   ```
   Führe `whoami` aus, um zu bestätigen, und verlasse die Sitzung mit `exit`.
7. **Schritt 7**: Lösche den Benutzer `testuser` und sein Home-Verzeichnis (benötigt `sudo`):
   ```bash
   sudo userdel -r testuser
   ```
   Die Option `-r` entfernt das Home-Verzeichnis.

**Reflexion**: Was passiert, wenn du `userdel` ohne `-r` ausführst? Schaue in der Manpage nach (`man userdel`) und überlege, warum du `usermod -aG` statt nur `-G` verwenden solltest.

### Übung 2: Sicherheits- und Berechtigungsmanagement
**Ziel**: Lerne, wie du Berechtigungen und erweiterte Sicherheitsattribute für Dateien und Verzeichnisse setzt.

1. **Schritt 1**: Erstelle ein Testverzeichnis und eine Datei:
   ```bash
   mkdir test_dir
   echo "Wichtige Daten" > test_dir/daten.txt
   ```
2. **Schritt 2**: Ändere die Berechtigungen von `daten.txt`, sodass nur der Eigentümer Lese- und Schreibrechte hat:
   ```bash
   chmod 600 test_dir/daten.txt
   ```
   Überprüfe mit:
   ```bash
   ls -l test_dir
   ```
   Du solltest `-rw-------` sehen.
3. **Schritt 3**: Ändere den Eigentümer von `daten.txt` zu `testuser` und der Gruppe `team` (benötigt `sudo`, erstelle `testuser` wie in Übung 1, falls nicht vorhanden):
   ```bash
   sudo chown testuser:team test_dir/daten.txt
   ```
   Überprüfe mit:
   ```bash
   ls -l test_dir
   ```
4. **Schritt 4**: Setze ein erweitertes Attribut, um `daten.txt` vor Löschung zu schützen (benötigt `sudo`):
   ```bash
   sudo chattr +i test_dir/daten.txt
   ```
   Überprüfe die Attribute:
   ```bash
   lsattr test_dir/daten.txt
   ```
   Du solltest `----i---------` sehen. Versuche, die Datei zu löschen:
   ```bash
   rm test_dir/daten.txt
   ```
   Beachte die Fehlermeldung.
5. **Schritt 5**: Entferne das Attribut (benötigt `sudo`):
   ```bash
   sudo chattr -i test_dir/daten.txt
   ```
   Überprüfe erneut mit `lsattr`.
6. **Schritt 6**: Setze eine Zugriffssteuerungsliste (ACL), um einem anderen Benutzer (z. B. `testuser2`, erstelle ihn wie `testuser`) Lesezugriff zu geben (benötigt `sudo`):
   ```bash
   sudo setfacl -m u:testuser2:r test_dir/daten.txt
   ```
   Überprüfe die ACL:
   ```bash
   getfacl test_dir/daten.txt
   ```
7. **Schritt 7**: Setze eine Standard-`umask` für neue Dateien (z. B. nur Eigentümerrechte):
   ```bash
   umask 077
   ```
   Erstelle eine neue Datei und überprüfe die Berechtigungen:
   ```bash
   touch test_dir/neue_datei.txt
   ls -l test_dir
   ```

**Reflexion**: Was bedeutet das `i`-Attribut von `chattr`? Warum sind ACLs nützlich im Vergleich zu Standardberechtigungen (`chmod`)? Schaue in `man chattr` und `man setfacl`.

### Übung 3: Auditing und Logging
**Ziel**: Lerne, wie du Benutzeraktivitäten überwachst und Systemlogs analysierst.

1. **Schritt 1**: Zeige die letzten Anmeldungen auf dem System an:
   ```bash
   last
   ```
   Notiere die Benutzer, Anmeldezeiten und Herkunft (z. B. `pts/0` für Terminal).
2. **Schritt 2**: Zeige aktuell angemeldete Benutzer an:
   ```bash
   who
   ```
   Vergleiche die Ausgabe mit `last`.
3. **Schritt 3**: Zeige die letzten 10 Zeilen der Systemlogs an:
   ```bash
   journalctl -n 10
   ```
   Die Option `-n 10` begrenzt die Ausgabe auf 10 Zeilen.
4. **Schritt 4**: Filtere Logs nach Aktivitäten des Benutzers `testuser` (benötigt `sudo`):
   ```bash
   sudo journalctl _UID=$(id -u testuser)
   ```
   Notiere relevante Einträge (z. B. Anmeldungen oder Befehle).
5. **Schritt 5**: Installiere das Audit-Subsystem, falls nicht vorhanden (benötigt `sudo`):
   ```bash
   sudo apt install auditd
   ```
   Starte den Audit-Dienst:
   ```bash
   sudo systemctl start auditd
   ```
6. **Schritt 6**: Füge eine Audit-Regel hinzu, um Zugriffe auf `daten.txt` zu überwachen (benötigt `sudo`):
   ```bash
   sudo auditctl -w test_dir/daten.txt -p war -k daten-zugriff
   ```
   Die Optionen: `-w` (Dateipfad), `-p war` (write, access, read), `-k` (Schlüssel für Filterung).
   Simuliere einen Zugriff:
   ```bash
   cat test_dir/daten.txt
   ```
   Überprüfe die Audit-Logs:
   ```bash
   sudo ausearch -k daten-zugriff
   ```

**Reflexion**: Wie unterscheiden sich `last` und `who` in ihrer Ausgabe? Wann würdest du `auditctl` statt `journalctl` verwenden, um Sicherheitsvorfälle zu untersuchen?

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um die Befehle zu verinnerlichen.
- **Experimentiere sicher**: Verwende `man <befehl>`, um Optionen zu verstehen, bevor du sie ausprobierst. Teste Benutzer- und Sicherheitsänderungen in einer sicheren Umgebung (z. B. virtuelle Maschine).
- **Fehler sind normal**: Lies Fehlermeldungen sorgfältig und nutze `man` oder Online-Ressourcen.
- **Vorsicht bei `sudo`**: Befehle wie `useradd`, `chown`, `chattr` oder `auditctl` können das System verändern. Überprüfe immer, was du tust.
- **Logs analysieren**: Nutze `journalctl` und `ausearch` zur Fehlersuche bei Sicherheits- oder Benutzerproblemen.
- **Berechtigungen verstehen**: Experimentiere mit `chmod`, `setfacl` und `umask`, um feingranulare Zugriffe zu steuern.

## Fazit
Durch diese Übungen hast du grundlegende Linux-Kommandozeilenbefehle für die Benutzerverwaltung, Sicherheits- und Berechtigungsmanagement sowie Auditing und Logging angewendet. Wiederhole die Übungen und experimentiere mit weiteren Optionen (z. B. `usermod -L` zum Sperren eines Kontos, `setfacl -R` für rekursive ACLs oder `auditctl -a` für erweiterte Audit-Regeln), um deine Fähigkeiten weiter zu verbessern.